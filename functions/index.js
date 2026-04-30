const {onRequest, onCall, HttpsError} = require("firebase-functions/v2/https");
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
                    .where("title", "<=", keyword + "");
            }

            q = q.limit(max);

            const snap = await q.get();
            const items = snap.docs.map((doc) => ({
                id: doc.id,
                ...doc.data(),
                createdAt: doc.data().createdAt?.toDate().toISOString() ?? null,
            }));

            return res.status(200).json(items);
        } catch (err) {
            console.error(err);
            return res.status(500).json({error: "Internal server error"});
        }
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