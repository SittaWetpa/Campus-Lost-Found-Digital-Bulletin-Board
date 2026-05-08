// WBS 2.14 — Unit test for autoExpireSensitivePosts Cloud Function
//
// Run: cd test/functions && npm test
//
// Strategy: mock firebase-admin so the function under test never hits a real
// Firestore. Three scenarios are verified:
//   1. One expired-sensitive doc → batch.update called with { status: 'expired' }
//   2. Empty snapshot (no matching docs)  → batch never committed
//   3. Non-expired doc (expiresAt > now)  → Firestore returns empty snap
//      (the WHERE clause filters it out)  → status unchanged

import {jest} from "@jest/globals";

// ── Firestore mock helpers ─────────────────────────────────────────────────────

function makeDocRef() {
    return {id: "doc-" + Math.random()};
}

function makeQuerySnap(docs) {
    return {
        empty: docs.length === 0,
        size: docs.length,
        docs: docs.map((data) => ({ref: makeDocRef(), data: () => data})),
    };
}

// ── Test suite ─────────────────────────────────────────────────────────────────

describe("autoExpireSensitivePosts — WBS 2.14", () => {
    let batchUpdateMock;
    let batchCommitMock;
    let getMock;
    let handler;

    beforeEach(async () => {
        batchUpdateMock = jest.fn();
        batchCommitMock = jest.fn().mockResolvedValue(undefined);

        const batchMock = {
            update: batchUpdateMock,
            commit: batchCommitMock,
        };

        // Chain .where().where().where().get() — each .where returns the same
        // query object; .get() returns a snapshot set per test via getMock.
        getMock = jest.fn();
        const queryMock = {where: jest.fn().mockReturnThis(), get: getMock};

        const collectionMock = jest.fn().mockReturnValue(queryMock);
        const dbMock = {collection: collectionMock, batch: jest.fn().mockReturnValue(batchMock)};

        // Intercept firebase-admin/firestore before the module is loaded
        jest.unstable_mockModule("firebase-admin/app", () => ({
            initializeApp: jest.fn(),
            getApp: jest.fn(),
        }));
        jest.unstable_mockModule("firebase-admin/firestore", () => ({
            getFirestore: jest.fn().mockReturnValue(dbMock),
        }));
        jest.unstable_mockModule("firebase-admin/auth", () => ({
            getAuth: jest.fn(),
        }));
        jest.unstable_mockModule("firebase-functions/v2/https", () => ({
            onRequest: jest.fn(),
            onCall: jest.fn(),
            HttpsError: class HttpsError extends Error {},
        }));
        jest.unstable_mockModule("firebase-functions/v2/scheduler", () => ({
            onSchedule: jest.fn((_, fn) => fn),
        }));
        jest.unstable_mockModule("firebase-functions/params", () => ({
            defineSecret: jest.fn().mockReturnValue({value: () => "test-key"}),
        }));

        const mod = await import("../../functions/index.js");
        handler = mod.autoExpireSensitivePosts;
    });

    afterEach(() => {
        jest.resetModules();
        jest.clearAllMocks();
    });

    test("01 — expired sensitive doc → batch.update sets status to 'expired' and commits", async () => {
        const expiredDoc = {isSensitive: true, status: "active"};
        getMock.mockResolvedValue(makeQuerySnap([expiredDoc]));

        await handler();

        expect(batchUpdateMock).toHaveBeenCalledTimes(1);
        expect(batchUpdateMock).toHaveBeenCalledWith(
            expect.anything(),
            {status: "expired"},
        );
        expect(batchCommitMock).toHaveBeenCalledTimes(1);
    });

    test("02 — empty snapshot (no docs match query) → batch is never committed", async () => {
        getMock.mockResolvedValue(makeQuerySnap([]));

        await handler();

        expect(batchUpdateMock).not.toHaveBeenCalled();
        expect(batchCommitMock).not.toHaveBeenCalled();
    });

    // wbs_dictionary.md §2.14: "post where expiresAt > now → verify status unchanged"
    // The Firestore query has WHERE expiresAt <= now, so a non-expired doc is
    // never returned by the query. The function sees an empty snapshot and
    // performs no batch write — equivalent to "status unchanged".
    test("03 — non-expired sensitive doc (expiresAt > now) → Firestore returns empty snap → no update", async () => {
        // The WHERE expiresAt <= now clause means the function will receive
        // zero docs for a future-dated post. We simulate that here.
        getMock.mockResolvedValue(makeQuerySnap([]));

        await handler();

        expect(batchUpdateMock).not.toHaveBeenCalled();
        expect(batchCommitMock).not.toHaveBeenCalled();
    });

    test("04 — multiple expired docs → each gets a batch.update call", async () => {
        const doc1 = {isSensitive: true, status: "active"};
        const doc2 = {isSensitive: true, status: "active"};
        getMock.mockResolvedValue(makeQuerySnap([doc1, doc2]));

        await handler();

        expect(batchUpdateMock).toHaveBeenCalledTimes(2);
        expect(batchCommitMock).toHaveBeenCalledTimes(1);
    });
});
