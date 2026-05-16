const {onRequest, onCall, HttpsError} = require("firebase-functions/v2/https");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {onDocumentCreated, onDocumentUpdated} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const {getStorage} = require("firebase-admin/storage");
const {getAuth} = require("firebase-admin/auth");
const {getMessaging} = require("firebase-admin/messaging");
const {defineSecret} = require("firebase-functions/params");
const {randomInt} = require("crypto");

initializeApp();

// Secrets stored in Google Secret Manager (never in the repo)
const apiKey = defineSecret("ITEMS_API_KEY");
const recaptchaSecret = defineSecret("RECAPTCHA_SECRET");

// ── Walk-in rate limiter (in-memory; 5 submissions / IP / hour) ──────────────
// Note: resets per function instance — use Firestore-based limiting for
// high-traffic production deployments.
const _walkinRateMap = new Map();
function _checkWalkinRate(ip) {
    const now = Date.now();
    const rec = _walkinRateMap.get(ip);
    if (!rec || rec.resetAt < now) {
        _walkinRateMap.set(ip, {count: 1, resetAt: now + 3_600_000});
        return true;
    }
    if (rec.count >= 5) return false;
    rec.count++;
    return true;
}

const SENSITIVE_CATS = new Set([
    "student_id", "national_id", "bank_card", "passport", "key", "document",
]);

const HOSTING_ORIGINS = [
    "https://campus-lost-found-e58a7.web.app",
    "https://campus-lost-found-e58a7.firebaseapp.com",
];

function setCorsHeaders(req, res) {
    const origin = req.headers.origin || "";
    if (HOSTING_ORIGINS.includes(origin)) {
        res.set("Access-Control-Allow-Origin", origin);
    }
    res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
    res.set("Access-Control-Allow-Headers", "Content-Type");
}

exports.items = onRequest(
    {region: "asia-southeast1", secrets: [apiKey]},
    async (req, res) => {
        // API key check
        const providedKey = req.get("x-api-key");
        if (!providedKey || providedKey !== apiKey.value()) {
            return res.status(401).json({error: "Unauthorized"});
        }

        if (req.method !== "GET") {
            return res.status(405).json({error: "Method not allowed"});
        }

        try {
            const {category, keyword, limit} = req.query;
            const max = Math.min(parseInt(limit, 10) || 20, 100);

            let q = getFirestore()
                .collection("items")
                .where("status", "==", "active");

            if (category === "seeker" || category === "founder") {
                q = q.where("category", "==", category);
            }
            if (keyword) {
                q = q.where("title", ">=", keyword)
                    .where("title", "<=", keyword + "");
            }

            q = q.limit(max);

            const snap = await q.get();
            const items = snap.docs.map((doc) => {
                const data = doc.data();
                const sensitive = data.isSensitive ?? false;
                return {
                    id: doc.id,
                    title: data.title,
                    category: data.category,
                    status: data.status,
                    location: data.location,
                    description: sensitive ? "" : (data.description ?? ""),
                    contact: sensitive ? "" : (data.contact ?? ""),
                    imageUrls: sensitive ? [] : (data.imageUrls ?? []),
                    isSensitive: sensitive,
                    createdAt: data.createdAt?.toDate().toISOString() ?? null,
                    occurredAt: data.occurredAt?.toDate().toISOString() ?? null,
                    expiresAt: data.expiresAt?.toDate().toISOString() ?? null,
                    itemCategory: data.itemCategory ?? null,
                };
            });

            return res.status(200).json(items);
        } catch (err) {
            console.error(err);
            return res.status(500).json({error: "Internal server error"});
        }
    },
);

// WBS 2.14 — daily Cloud Function that expires sensitive posts after 14 days.
// Requires composite index: isSensitive ASC, status ASC, expiresAt ASC.
exports.autoExpireSensitivePosts = onSchedule(
    {schedule: "every 24 hours", region: "asia-southeast1"},
    async () => {
        const db = getFirestore();
        const now = new Date();
        const snap = await db.collection("items")
            .where("isSensitive", "==", true)
            .where("status", "==", "active")
            .where("expiresAt", "<=", now)
            .get();

        if (snap.empty) return;
        const batch = db.batch();
        snap.docs.forEach((doc) => batch.update(doc.ref, {status: "expired"}));
        await batch.commit();
        console.log(`Expired ${snap.size} sensitive posts.`);
    },
);

// WBS 2.4.1 — Request Resubmit Policy enforcement.
// Firestore rules cannot count or aggregate documents, so this post-create
// trigger validates the policy and deletes invalid requests. The same logic
// runs client-side in canResubmit; this trigger is the defense-in-depth layer.
exports.onRequestCreatePolicyCheck = onDocumentCreated(
    {
        document: "items/{itemId}/requests/{requestId}",
        region: "asia-southeast1",
    },
    async (event) => {
        const snap = event.data;
        if (!snap) return;
        const data = snap.data();
        const requesterId = data.requesterId;
        if (!requesterId) return;

        const {itemId, requestId} = event.params;
        const db = getFirestore();

        const itemSnap = await db.doc(`items/${itemId}`).get();
        const itemData = itemSnap.exists ? itemSnap.data() : {};
        const sq = itemData.secretQuestion;
        const hasSecretQuestion = typeof sq === "string" && sq.length > 0;

        const historySnap = await db
            .collection(`items/${itemId}/requests`)
            .where("requesterId", "==", requesterId)
            .orderBy("createdAt", "desc")
            .get();

        let pendingOrApproved = false;
        const rejected = [];
        for (const doc of historySnap.docs) {
            if (doc.id === requestId) continue;
            const status = doc.data().status;
            if (status === "pending" || status === "approved") {
                pendingOrApproved = true;
            } else if (status === "rejected") {
                rejected.push(doc);
            }
        }

        let violation = null;
        if (pendingOrApproved) {
            violation = "already_active";
        } else if (hasSecretQuestion && rejected.length >= 3) {
            violation = "permanent_block";
        } else if (rejected.length > 0) {
            const recent = rejected[0].data();
            const createdAt = recent.createdAt &&
                typeof recent.createdAt.toDate === "function" ?
                recent.createdAt.toDate() : null;
            if (createdAt) {
                const retryMs = createdAt.getTime() + 6 * 60 * 60 * 1000;
                if (retryMs > Date.now()) violation = "cooldown";
            }
        }

        if (!violation) return;

        await snap.ref.delete();
        await db.collection("policy_audit").add({
            wbs: "2.4.1",
            itemId,
            requestId,
            requesterId,
            reason: violation,
            hasSecretQuestion,
            rejectedCount: rejected.length,
            timestamp: new Date(),
        });
        console.log(
            `WBS 2.4.1 - deleted invalid request ${requestId} ` +
            `on item ${itemId} (reason: ${violation})`,
        );
    },
);

exports.sendOtp = onCall(
    {region: "asia-southeast1"},
    async (request) => {
        if (!request.auth) {
            throw new HttpsError("unauthenticated", "Authentication required.");
        }
        const uid = request.auth.uid;
        const db = getFirestore();

        const userRecord = await getAuth().getUser(uid);
        const email = userRecord.email;

        const code = String(randomInt(100000, 1000000));
        const now = new Date();
        const expiresAt = new Date(now.getTime() + 10 * 60 * 1000);

        const existing = await db.collection("otp_verifications").doc(uid).get();
        if (existing.exists) {
            const ageSeconds = (Date.now() - existing.data().createdAt.toDate().getTime()) / 1000;
            if (ageSeconds < 60) {
                throw new HttpsError("resource-exhausted", "Please wait before requesting another OTP.");
            }
        }

        await db.collection("otp_verifications").doc(uid).set({
            code,
            expiresAt,
            attempts: 0,
            createdAt: now,
        });

        await db.collection("mail").add({
            to: [email],
            message: {
                subject: "Campus Lost & Found — Email Verification",
                text: `Your verification code is: ${code}\n\nThis code expires in 10 minutes.`,
                html: `<p>Your verification code is: <strong style="font-size:24px">${code}</strong></p><p>This code expires in 10 minutes. Do not share it with anyone.</p>`,
            },
        });

        return {sent: true};
    },
);

exports.verifyOtp = onCall(
    {region: "asia-southeast1"},
    async (request) => {
        if (!request.auth) {
            throw new HttpsError("unauthenticated", "Authentication required.");
        }
        const uid = request.auth.uid;
        const {code} = request.data;

        if (!code || typeof code !== "string" || !/^\d{6}$/.test(code)) {
            throw new HttpsError("invalid-argument", "Invalid OTP format.");
        }

        const db = getFirestore();
        const otpRef = db.collection("otp_verifications").doc(uid);
        const userRef = db.collection("users").doc(uid);

        let verificationResult = null;

        try {
            verificationResult = await db.runTransaction(async (tx) => {
                const otpDoc = await tx.get(otpRef);

                if (!otpDoc.exists) {
                    throw new HttpsError("not-found", "No OTP found. Please request a new one.");
                }

                const data = otpDoc.data();

                if (data.expiresAt.toDate() < new Date()) {
                    tx.delete(otpRef);
                    throw new HttpsError("deadline-exceeded", "OTP has expired. Please request a new one.");
                }

                if (data.code !== code) {
                    const newAttempts = data.attempts + 1;
                    if (newAttempts >= 5) {
                        tx.delete(otpRef);
                        throw new HttpsError("resource-exhausted", "No more attempts. Please request a new OTP.");
                    }
                    tx.update(otpRef, {attempts: newAttempts});
                    const remaining = 5 - newAttempts;
                    throw new HttpsError(
                        "invalid-argument",
                        `Incorrect code. ${remaining} attempt${remaining !== 1 ? "s" : ""} remaining.`,
                    );
                }

                tx.delete(otpRef);
                return {verified: true};
            });
        } catch (err) {
            throw err;
        }

        await userRef.update({emailVerified: true});

        return verificationResult;
    },
);

// ── WBS 2.15 — QR Walk-in submission ─────────────────────────────────────────
// POST /api/walkin (routed via Firebase Hosting rewrite from walkin/index.html)
// Body (JSON): { token, category, title, location, description?, photoDataUrl? }
// Returns: { success: true, refId: string }
exports.walkin = onRequest(
    {region: "asia-southeast1", secrets: [recaptchaSecret]},
    async (req, res) => {
        setCorsHeaders(req, res);
        if (req.method === "OPTIONS") return res.status(204).send("");
        if (req.method !== "POST") {
            return res.status(405).json({error: "Method not allowed"});
        }

        // Rate limit
        const ip = ((req.headers["x-forwarded-for"] || req.ip || "unknown")
            .split(",")[0]).trim();
        if (!_checkWalkinRate(ip)) {
            return res.status(429).json({
                error: "Too many submissions. Please try again later.",
            });
        }

        const {token, category, title, location, description, photoDataUrl} =
            req.body || {};

        // Field validation
        if (!category || typeof category !== "string") {
            return res.status(400).json({error: "Missing or invalid category"});
        }
        if (!title || typeof title !== "string" ||
            title.trim().length < 2 || title.trim().length > 100) {
            return res.status(400).json({error: "Missing or invalid title"});
        }
        if (!location || typeof location !== "string" ||
            location.trim().length < 2 || location.trim().length > 200) {
            return res.status(400).json({error: "Missing or invalid location"});
        }

        // reCAPTCHA v3 verification (skipped in emulator for local testing)
        const isEmulator = process.env.FUNCTIONS_EMULATOR === "true";
        if (!isEmulator) {
            if (!token) {
                return res.status(400).json({error: "reCAPTCHA token required"});
            }
            try {
                const secret = recaptchaSecret.value();
                const verifyRes = await fetch(
                    "https://www.google.com/recaptcha/api/siteverify" +
                    `?secret=${secret}&response=${token}`,
                    {method: "POST"},
                );
                const verifyData = await verifyRes.json();
                const passed = verifyData.success &&
                    (verifyData.score === undefined || verifyData.score >= 0.3);
                if (!passed) {
                    return res.status(400).json({error: "reCAPTCHA check failed"});
                }
            } catch (err) {
                console.error("reCAPTCHA error:", err);
                return res.status(500).json({error: "reCAPTCHA verification error"});
            }
        }

        // Optional photo upload (base64 data URL → Firebase Storage)
        let imageUrls = [];
        if (photoDataUrl && typeof photoDataUrl === "string" &&
            photoDataUrl.startsWith("data:image/")) {
            try {
                const commaIdx = photoDataUrl.indexOf(",");
                const meta = photoDataUrl.slice(0, commaIdx);
                const base64Data = photoDataUrl.slice(commaIdx + 1);
                const ext = meta.includes("jpeg") || meta.includes("jpg") ?
                    "jpg" : "png";
                const buffer = Buffer.from(base64Data, "base64");
                const fileName = `walkin/${Date.now()}.${ext}`;
                const bucket = getStorage().bucket();
                const file = bucket.file(fileName);
                await file.save(buffer, {
                    metadata: {contentType: `image/${ext}`},
                    public: true,
                });
                imageUrls = [
                    `https://storage.googleapis.com/${bucket.name}/${fileName}`,
                ];
            } catch (photoErr) {
                console.error("Photo upload error:", photoErr);
                // Non-fatal — continue without photo
            }
        }

        // Write Firestore document (Admin SDK bypasses security rules)
        const isSensitive = SENSITIVE_CATS.has(category);
        const refId = "QR" + Date.now().toString(36).toUpperCase().slice(-6);
        try {
            await getFirestore().collection("items").add({
                title: title.trim(),
                description: typeof description === "string" ?
                    description.trim() : "",
                category: "founder",          // walk-in = found item
                itemCategory: category,
                status: "active",
                location: location.trim(),
                contact: "",
                imageUrls,
                userId: "walkin",
                source: "qr_walk_in",
                isSensitive,
                createdAt: FieldValue.serverTimestamp(),
                occurredAt: FieldValue.serverTimestamp(),
                walkinRefId: refId,
            });
        } catch (dbErr) {
            console.error("Firestore write error:", dbErr);
            return res.status(500).json({error: "Failed to save submission"});
        }

        return res.status(201).json({success: true, refId});
    },
);

// ── WBS 2.16 — Push Notifications ────────────────────────────────────────────

// Helper: remove stale FCM tokens reported by FCM as unregistered.
async function _pruneStaleTokens(db, userPath, tokens, responses) {
    const stale = responses
        .map((r, i) => (!r.success &&
            r.error?.code === "messaging/registration-token-not-registered"
            ? tokens[i] : null))
        .filter(Boolean);
    if (stale.length > 0) {
        await db.doc(userPath).update({
            fcmTokens: FieldValue.arrayRemove(...stale),
        });
    }
}

// Helper: write an in-app notification document. Idempotent via deterministic id —
// safe under at-least-once trigger delivery.
async function _writeNotificationDoc(db, recipientId, notificationId, data) {
    await db
        .doc(`users/${recipientId}/notifications/${notificationId}`)
        .set({
            ...data,
            isRead: false,
            createdAt: FieldValue.serverTimestamp(),
        });
}

// T1 / T2 — notify item poster when a new request arrives (app-sourced only).
exports.onNewRequest = onDocumentCreated(
    {
        document: "items/{itemId}/requests/{requestId}",
        region: "asia-southeast1",
    },
    async (event) => {
        const reqData = event.data.data();
        const {itemId, requestId} = event.params;

        const db = getFirestore();

        const itemSnap = await db.doc(`items/${itemId}`).get();
        if (!itemSnap.exists) return;
        const item = itemSnap.data();

        const userPath = `users/${item.userId}`;
        const userSnap = await db.doc(userPath).get();
        if (!userSnap.exists) return;
        const user = userSnap.data();

        // notificationsEnabled defaults to true (per CLAUDE.md) — only an
        // explicit `false` opts out. Users who registered before WBS 2.16
        // have no such field and must still receive notifications.
        if (user.notificationsEnabled === false) return;

        const isClaim = reqData.type === "claim";
        const notifTitle = isClaim ? "New Claim Request" : "New Found Report";
        const notifBody = isClaim
            ? `${reqData.requesterName} submitted a claim for ${item.title}`
            : `${reqData.requesterName} reported finding ${item.title}`;
        const dataType = isClaim ? "claimRequest" : "foundReport";

        // Write the in-app notification doc first — even if FCM push fails
        // (or there are no tokens), the recipient will still see it in the
        // Notification Center. Deterministic id dedupes against retries.
        await _writeNotificationDoc(db, item.userId, `req_${requestId}`, {
            type: dataType,
            recipientId: item.userId,
            itemId,
            itemTitle: item.title,
            requesterName: reqData.requesterName,
            requestId,
        });

        const tokens = user.fcmTokens || [];
        if (tokens.length === 0) return;
        const result = await getMessaging().sendEachForMulticast({
            tokens,
            notification: {title: notifTitle, body: notifBody},
            data: {type: dataType, itemId, requestId},
        });

        await _pruneStaleTokens(db, userPath, tokens, result.responses);
    },
);

// Daily auto-archive — delete in-app notifications that have been read for ≥ 30 days.
// Requires the collection-group index on notifications(isRead ASC, createdAt ASC).
exports.autoArchiveReadNotifications = onSchedule(
    {schedule: "every 24 hours", region: "asia-southeast1"},
    async () => {
        const db = getFirestore();
        const cutoff = new Date();
        cutoff.setDate(cutoff.getDate() - 30);

        const snap = await db.collectionGroup("notifications")
            .where("isRead", "==", true)
            .where("createdAt", "<", cutoff)
            .get();

        if (snap.empty) return;

        // Firestore batches max out at 500 writes.
        const commits = [];
        let batch = db.batch();
        let count = 0;
        for (const doc of snap.docs) {
            batch.delete(doc.ref);
            count++;
            if (count === 500) {
                commits.push(batch.commit());
                batch = db.batch();
                count = 0;
            }
        }
        if (count > 0) commits.push(batch.commit());
        await Promise.all(commits);
        console.log(
            `autoArchiveReadNotifications: deleted ${snap.size} read notifications.`,
        );
    },
);

// T3 / T4 — notify requester when their request status changes to approved/rejected.
exports.onRequestStatusChange = onDocumentUpdated(
    {
        document: "items/{itemId}/requests/{requestId}",
        region: "asia-southeast1",
    },
    async (event) => {
        const before = event.data.before.data();
        const after = event.data.after.data();
        const {itemId, requestId} = event.params;

        if (before.status === after.status) return;
        if (after.status !== "approved" && after.status !== "rejected") return;

        const db = getFirestore();

        const itemSnap = await db.doc(`items/${itemId}`).get();
        if (!itemSnap.exists) return;
        const item = itemSnap.data();

        const requesterId = after.requesterId;
        if (!requesterId) return;

        const userPath = `users/${requesterId}`;
        const userSnap = await db.doc(userPath).get();
        if (!userSnap.exists) return;
        const user = userSnap.data();

        // Default `true` — only an explicit opt-out blocks the notification.
        if (user.notificationsEnabled === false) return;

        const isApproved = after.status === "approved";
        const notifTitle = isApproved
            ? "Your request was approved"
            : "Your request was declined";
        const notifBody = isApproved
            ? `Your request for ${item.title} has been approved`
            : `Your request for ${item.title} has been declined`;
        const dataType = isApproved ? "requestApproved" : "requestDeclined";

        // Deterministic id per (requestId, status) so the approve-then-reopen-then-
        // approve case (should it ever arise) doesn't overwrite the prior record.
        await _writeNotificationDoc(
            db,
            requesterId,
            `req_${requestId}_${after.status}`,
            {
                type: dataType,
                recipientId: requesterId,
                itemId,
                itemTitle: item.title,
                // requesterName intentionally omitted — T3/T4 are self-directed.
                requestId,
            },
        );

        const tokens = user.fcmTokens || [];
        if (tokens.length === 0) return;
        const result = await getMessaging().sendEachForMulticast({
            tokens,
            notification: {title: notifTitle, body: notifBody},
            data: {type: dataType, itemId, requestId},
        });

        await _pruneStaleTokens(db, userPath, tokens, result.responses);
    },
);