// WBS 2.14 — REST API redaction test for GET /items
//
// Run: cd test/functions && npm test
//
// Strategy: mock firebase-admin and firebase-functions so that the items
// handler is extracted directly. A lightweight req/res pair replaces Express
// so no HTTP server is needed.
//
// Test cases (from wbs_dictionary.md §2.14):
//   01 — sensitive item → response omits contact and description,
//          includes isSensitive: true
//   02 — non-sensitive item → response includes contact and description
//   03 — invalid API key → 401
//   04 — non-GET method → 405

import {jest} from "@jest/globals";

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
    const res = {
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
    return res;
}

// ── Test suite ─────────────────────────────────────────────────────────────────

describe("GET /items — WBS 2.14 sensitive field redaction", () => {
    let handler;
    let getMock;

    beforeEach(async () => {
        getMock = jest.fn();
        const queryMock = {
            where: jest.fn().mockReturnThis(),
            limit: jest.fn().mockReturnThis(),
            get: getMock,
        };
        const dbMock = {collection: jest.fn().mockReturnValue(queryMock)};

        jest.unstable_mockModule("firebase-admin/app", () => ({
            initializeApp: jest.fn(),
        }));
        jest.unstable_mockModule("firebase-admin/firestore", () => ({
            getFirestore: jest.fn().mockReturnValue(dbMock),
        }));
        jest.unstable_mockModule("firebase-admin/auth", () => ({
            getAuth: jest.fn(),
        }));
        // onRequest receives (config, fn) — return fn so exports.items === fn.
        jest.unstable_mockModule("firebase-functions/v2/https", () => ({
            onRequest: jest.fn((_config, fn) => fn),
            onCall: jest.fn(),
            HttpsError: class HttpsError extends Error {},
        }));
        jest.unstable_mockModule("firebase-functions/v2/scheduler", () => ({
            onSchedule: jest.fn((_, fn) => fn),
        }));
        jest.unstable_mockModule("firebase-functions/params", () => ({
            defineSecret: jest.fn().mockReturnValue({value: () => TEST_API_KEY}),
        }));

        const mod = await import("../../functions/index.js");
        handler = mod.items;
    });

    afterEach(() => {
        jest.resetModules();
        jest.clearAllMocks();
    });

    // ── WBS 2.14 Test case 7 ────────────────────────────────────────────────

    test(
        "01 — sensitive item: response omits contact and description, " +
        "includes isSensitive: true and expiresAt as ISO string",
        async () => {
            getMock.mockResolvedValue(
                makeQuerySnap([
                    {
                        title: "Student ID card",
                        category: "founder",
                        status: "active",
                        location: "ECC lobby",
                        imageUrls: ["https://example.com/img.jpg"],
                        isSensitive: true,
                        description: "SECRET — should be redacted",
                        contact: "SECRET — should be redacted",
                        createdAt: makeTimestamp("2025-01-01T00:00:00Z"),
                        expiresAt: makeTimestamp("2025-01-15T00:00:00Z"),
                    },
                ]),
            );

            const res = makeRes();
            await handler(makeReq(), res);

            expect(res._status).toBe(200);
            expect(Array.isArray(res._body)).toBe(true);

            const item = res._body[0];

            // Sensitive payload contract
            expect(item.contact).toBeUndefined();
            expect(item.description).toBeUndefined();
            expect(item.isSensitive).toBe(true);

            // Non-sensitive fields must still be present
            expect(item.title).toBe("Student ID card");
            expect(item.location).toBe("ECC lobby");
            expect(item.status).toBe("active");
            expect(item.category).toBe("founder");
            expect(item.createdAt).toBe("2025-01-01T00:00:00.000Z");
            expect(item.expiresAt).toBe("2025-01-15T00:00:00.000Z");
        },
    );

    test(
        "02 — non-sensitive item: response includes contact and description",
        async () => {
            getMock.mockResolvedValue(
                makeQuerySnap([
                    {
                        title: "Brown leather wallet",
                        category: "founder",
                        status: "active",
                        location: "Library 2F",
                        imageUrls: [],
                        isSensitive: false,
                        description: "No cash inside",
                        contact: "0812345678",
                        createdAt: makeTimestamp("2025-02-01T00:00:00Z"),
                        expiresAt: null,
                    },
                ]),
            );

            const res = makeRes();
            await handler(makeReq(), res);

            expect(res._status).toBe(200);
            const item = res._body[0];

            expect(item.description).toBe("No cash inside");
            expect(item.contact).toBe("0812345678");
            expect(item.isSensitive).toBe(false);
            // expiresAt is null for non-sensitive items
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
        "05 — mixed feed (one sensitive, one general): sensitive item " +
        "has redacted fields; general item has full fields",
        async () => {
            getMock.mockResolvedValue(
                makeQuerySnap([
                    {
                        title: "Passport",
                        category: "founder",
                        status: "active",
                        location: "CB1",
                        imageUrls: [],
                        isSensitive: true,
                        description: "REDACTED",
                        contact: "REDACTED",
                        createdAt: makeTimestamp("2025-03-01T00:00:00Z"),
                        expiresAt: makeTimestamp("2025-03-15T00:00:00Z"),
                    },
                    {
                        title: "Blue backpack",
                        category: "founder",
                        status: "active",
                        location: "Canteen",
                        imageUrls: [],
                        isSensitive: false,
                        description: "Has a broken zipper",
                        contact: "0898765432",
                        createdAt: makeTimestamp("2025-03-02T00:00:00Z"),
                        expiresAt: null,
                    },
                ]),
            );

            const res = makeRes();
            await handler(makeReq(), res);

            expect(res._status).toBe(200);
            expect(res._body).toHaveLength(2);

            const [sensitiveItem, generalItem] = res._body;

            expect(sensitiveItem.isSensitive).toBe(true);
            expect(sensitiveItem.description).toBeUndefined();
            expect(sensitiveItem.contact).toBeUndefined();

            expect(generalItem.isSensitive).toBe(false);
            expect(generalItem.description).toBe("Has a broken zipper");
            expect(generalItem.contact).toBe("0898765432");
        },
    );
});
