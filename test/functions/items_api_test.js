// WBS 2.14 / WBS 2.9 — GET /items Cloud Function tests
//
// Run: cd test/functions && npm test
//
// Strategy: mock firebase-admin and firebase-functions so that the items
// handler is extracted directly. A lightweight req/res pair replaces Express
// so no HTTP server is needed.
//
// Module system: CommonJS, matching functions/index.js. Uses jest.doMock +
// jest.resetModules + require() so each test re-loads the function module
// with a freshly built Firestore mock chain.

"use strict";

const TEST_API_KEY = "test-key-xyz";

// ── Helpers ────────────────────────────────────────────────────────────────────

function makeTimestamp(isoString) {
    return {toDate: () => new Date(isoString)};
}

function makeQuerySnap(docs) {
    return {
        docs: docs.map((data, i) => ({
            id: `item-${i}`,
            data: () => data,
        })),
    };
}

function makeReq({method = "GET", apiKey = TEST_API_KEY, query = {}} = {}) {
    return {
        method,
        get: (header) => (header === "x-api-key" ? apiKey : undefined),
        query: {limit: "10", ...query},
    };
}

function makeRes() {
    return {
        _status: null,
        _body: null,
        status(code) {
            this._status = code;
            return this;
        },
        json(body) {
            this._body = body;
            return this;
        },
    };
}

const SENSITIVE_DOC = {
    title: "Student ID card",
    category: "founder",
    status: "active",
    location: "ECC lobby",
    imageUrls: ["https://example.com/img.jpg"],
    isSensitive: true,
    description: "SECRET — should be redacted",
    contact: "SECRET — should be redacted",
    createdAt: makeTimestamp("2025-01-01T00:00:00Z"),
    occurredAt: makeTimestamp("2024-12-31T10:00:00Z"),
    expiresAt: makeTimestamp("2025-01-15T00:00:00Z"),
    itemCategory: "id_card",
};

const GENERAL_DOC = {
    title: "Brown leather wallet",
    category: "founder",
    status: "active",
    location: "Library 2F",
    imageUrls: [],
    isSensitive: false,
    description: "No cash inside",
    contact: "0812345678",
    createdAt: makeTimestamp("2025-02-01T00:00:00Z"),
    occurredAt: makeTimestamp("2025-01-31T15:00:00Z"),
    expiresAt: null,
    itemCategory: "wallet",
};

// ── Test suite ─────────────────────────────────────────────────────────────────

describe("GET /items", () => {
    let handler;
    let getMock;
    let whereMock;

    beforeEach(() => {
        jest.resetModules();

        getMock = jest.fn();
        whereMock = jest.fn();
        const queryMock = {
            where: whereMock.mockReturnThis(),
            limit: jest.fn().mockReturnThis(),
            get: getMock,
        };
        const dbMock = {collection: jest.fn().mockReturnValue(queryMock)};

        jest.doMock("firebase-admin/app", () => ({
            initializeApp: jest.fn(),
        }));
        jest.doMock("firebase-admin/firestore", () => ({
            getFirestore: jest.fn().mockReturnValue(dbMock),
            FieldValue: {serverTimestamp: jest.fn()},
        }));
        jest.doMock("firebase-admin/auth", () => ({
            getAuth: jest.fn(),
        }));
        jest.doMock("firebase-admin/storage", () => ({
            getStorage: jest.fn(),
        }));
        jest.doMock("firebase-admin/messaging", () => ({
            getMessaging: jest.fn(),
        }));
        jest.doMock("firebase-functions/v2/https", () => ({
            onRequest: jest.fn((_config, fn) => fn),
            onCall: jest.fn((_config, fn) => fn),
            HttpsError: class HttpsError extends Error {},
        }));
        jest.doMock("firebase-functions/v2/scheduler", () => ({
            onSchedule: jest.fn((_, fn) => fn),
        }));
        jest.doMock("firebase-functions/v2/firestore", () => ({
            onDocumentCreated: jest.fn((_, fn) => fn),
            onDocumentUpdated: jest.fn((_, fn) => fn),
        }));
        jest.doMock("firebase-functions/params", () => ({
            defineSecret: jest.fn().mockReturnValue({value: () => TEST_API_KEY}),
        }));

        handler = require("../../functions/index.js").items;
    });

    afterEach(() => {
        jest.resetModules();
        jest.clearAllMocks();
    });

    // ── WBS 2.14 — sensitive field redaction ────────────────────────────────

    test(
        "01 — sensitive item: description and contact are empty strings, " +
        "imageUrls is empty, isSensitive is true",
        async () => {
            getMock.mockResolvedValue(makeQuerySnap([SENSITIVE_DOC]));

            const res = makeRes();
            await handler(makeReq(), res);

            expect(res._status).toBe(200);
            const item = res._body[0];

            // Sensitive payload — all three fields are empty (not absent)
            expect(item.description).toBe("");
            expect(item.contact).toBe("");
            expect(item.imageUrls).toEqual([]);
            expect(item.isSensitive).toBe(true);

            // Non-sensitive fields still present
            expect(item.title).toBe("Student ID card");
            expect(item.location).toBe("ECC lobby");
            expect(item.status).toBe("active");
            expect(item.category).toBe("founder");
            expect(item.createdAt).toBe("2025-01-01T00:00:00.000Z");
            expect(item.expiresAt).toBe("2025-01-15T00:00:00.000Z");
        },
    );

    test(
        "02 — non-sensitive item: full description, contact and imageUrls present",
        async () => {
            getMock.mockResolvedValue(makeQuerySnap([GENERAL_DOC]));

            const res = makeRes();
            await handler(makeReq(), res);

            expect(res._status).toBe(200);
            const item = res._body[0];

            expect(item.description).toBe("No cash inside");
            expect(item.contact).toBe("0812345678");
            expect(item.isSensitive).toBe(false);
            expect(item.expiresAt).toBeNull();
        },
    );

    test("03 — invalid API key → 401 Unauthorized", async () => {
        const res = makeRes();
        await handler(makeReq({apiKey: "wrong-key"}), res);

        expect(res._status).toBe(401);
    });

    test("04 — non-GET method (POST) → 405 Method Not Allowed", async () => {
        const res = makeRes();
        await handler(makeReq({method: "POST"}), res);

        expect(res._status).toBe(405);
    });

    test(
        "05 — mixed feed: sensitive item has empty fields; general item has full fields",
        async () => {
            getMock.mockResolvedValue(makeQuerySnap([SENSITIVE_DOC, GENERAL_DOC]));

            const res = makeRes();
            await handler(makeReq(), res);

            expect(res._status).toBe(200);
            expect(res._body).toHaveLength(2);

            const [sensitiveItem, generalItem] = res._body;

            expect(sensitiveItem.isSensitive).toBe(true);
            expect(sensitiveItem.description).toBe("");
            expect(sensitiveItem.contact).toBe("");
            expect(sensitiveItem.imageUrls).toEqual([]);

            expect(generalItem.isSensitive).toBe(false);
            expect(generalItem.description).toBe("No cash inside");
            expect(generalItem.contact).toBe("0812345678");
        },
    );

    // ── WBS 2.9 — new fields & query filters ────────────────────────────────

    test(
        "06 — response includes occurredAt and itemCategory for each item",
        async () => {
            getMock.mockResolvedValue(makeQuerySnap([GENERAL_DOC]));

            const res = makeRes();
            await handler(makeReq(), res);

            expect(res._status).toBe(200);
            const item = res._body[0];

            expect(item.occurredAt).toBe("2025-01-31T15:00:00.000Z");
            expect(item.itemCategory).toBe("wallet");
        },
    );

    test(
        "07 — itemCategory is null when absent from Firestore doc",
        async () => {
            const docWithoutCategory = {...GENERAL_DOC};
            delete docWithoutCategory.itemCategory;
            getMock.mockResolvedValue(makeQuerySnap([docWithoutCategory]));

            const res = makeRes();
            await handler(makeReq(), res);

            expect(res._status).toBe(200);
            expect(res._body[0].itemCategory).toBeNull();
        },
    );

    test(
        "08 — ?category=founder adds category where-clause to Firestore query",
        async () => {
            getMock.mockResolvedValue(makeQuerySnap([GENERAL_DOC]));

            const res = makeRes();
            await handler(makeReq({query: {category: "founder"}}), res);

            expect(res._status).toBe(200);
            const whereCalls = whereMock.mock.calls;
            const categoryFilter = whereCalls.find(
                ([field, , value]) => field === "category" && value === "founder",
            );
            expect(categoryFilter).toBeDefined();
        },
    );

    test(
        "09 — ?keyword=wallet adds title range where-clauses to Firestore query",
        async () => {
            getMock.mockResolvedValue(makeQuerySnap([GENERAL_DOC]));

            const res = makeRes();
            await handler(makeReq({query: {keyword: "wallet"}}), res);

            expect(res._status).toBe(200);
            const whereCalls = whereMock.mock.calls;
            const titleGte = whereCalls.find(
                ([field, op]) => field === "title" && op === ">=",
            );
            expect(titleGte).toBeDefined();
        },
    );

    test(
        "10 — valid API key with active items returns 200 and an array",
        async () => {
            getMock.mockResolvedValue(makeQuerySnap([GENERAL_DOC]));

            const res = makeRes();
            await handler(makeReq(), res);

            expect(res._status).toBe(200);
            expect(Array.isArray(res._body)).toBe(true);
            expect(res._body.length).toBeGreaterThan(0);
        },
    );
});
