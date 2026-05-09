const {onRequest, onCall, HttpsError} = require("firebase-functions/v2/https");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getAuth} = require("firebase-admin/auth");
const {defineSecret} = require("firebase-functions/params");
const {randomInt} = require("crypto");

initializeApp();

// API key stored in Google Secret Manager (never in the repo)
const apiKey = defineSecret("ITEMS_API_KEY");

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
                const item = {
                    id: doc.id,
                    title: data.title,
                    category: data.category,
                    status: data.status,
                    location: data.location,
                    imageUrls: data.imageUrls ?? [],
                    isSensitive: data.isSensitive ?? false,
                    createdAt: data.createdAt?.toDate().toISOString() ?? null,
                    expiresAt: data.expiresAt?.toDate().toISOString() ?? null,
                };
                if (!data.isSensitive) {
                    item.description = data.description;
                    item.contact = data.contact;
                }
                return item;
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