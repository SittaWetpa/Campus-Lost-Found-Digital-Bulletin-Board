const {onRequest} = require("firebase-functions/v2/https");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {defineSecret} = require("firebase-functions/params");

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
