// WBS 2.16 — onNewRequest & onRequestStatusChange Cloud Function unit tests
'use strict';

process.env.FUNCTIONS_EMULATOR = 'true';

// ── Mocks ─────────────────────────────────────────────────────────────────────
// onDocumentCreated / onDocumentUpdated return the handler directly so that
// exports.onNewRequest and exports.onRequestStatusChange are callable functions.

jest.mock('firebase-admin/app', () => ({ initializeApp: jest.fn() }));

jest.mock('firebase-admin/auth', () => ({ getAuth: jest.fn() }));

jest.mock('firebase-admin/storage', () => ({
  getStorage: jest.fn(() => ({
    bucket: jest.fn(() => ({
      file: jest.fn(() => ({ save: jest.fn().mockResolvedValue(undefined) })),
      name: 'test-bucket',
    })),
  })),
}));

jest.mock('firebase-functions/params', () => ({
  defineSecret: jest.fn(() => ({ value: jest.fn(() => 'test-secret') })),
}));

jest.mock('firebase-functions/v2/https', () => ({
  onRequest: jest.fn((_opts, handler) => handler),
  onCall: jest.fn((_opts, handler) => handler),
  HttpsError: class HttpsError extends Error {
    constructor(code, msg) { super(msg); this.code = code; }
  },
}));

jest.mock('firebase-functions/v2/scheduler', () => ({
  onSchedule: jest.fn(() => ({})),
}));

// Return handlers directly — unlike walkin.test.js which wraps them in {}.
jest.mock('firebase-functions/v2/firestore', () => ({
  onDocumentCreated: jest.fn((_opts, handler) => handler),
  onDocumentUpdated: jest.fn((_opts, handler) => handler),
}));

jest.mock('firebase-admin/firestore', () => ({
  getFirestore: jest.fn(),
  FieldValue: {
    serverTimestamp: jest.fn(() => '__SERVER_TS__'),
    arrayUnion: jest.fn((...args) => ({ _type: 'arrayUnion', values: args })),
    arrayRemove: jest.fn((...args) => ({ _type: 'arrayRemove', values: args })),
  },
}));

jest.mock('firebase-admin/messaging', () => ({
  getMessaging: jest.fn(),
}));

// ── Module under test ─────────────────────────────────────────────────────────

const adminFirestore = require('firebase-admin/firestore');
const adminMessaging = require('firebase-admin/messaging');
const { onNewRequest, onRequestStatusChange } = require('../index');

// ── Helpers ───────────────────────────────────────────────────────────────────

const mockSendEach = jest.fn();
const mockDocUpdate = jest.fn().mockResolvedValue(undefined);
const mockDocSet = jest.fn().mockResolvedValue(undefined);

/**
 * Build a path-keyed Firestore mock.
 * Call setDoc(path, data) before each test to prime the read stubs.
 */
function makeFirestore(docs = {}) {
  const makeDocRef = (path) => ({
    get: jest.fn(() => Promise.resolve({
      exists: path in docs,
      data: () => docs[path] ?? null,
    })),
    update: jest.fn((data) => mockDocUpdate(path, data)),
    set: jest.fn((data) => mockDocSet(path, data)),
  });

  return {
    doc: jest.fn((path) => makeDocRef(path)),
    collection: jest.fn((col) => ({
      doc: jest.fn((id) => makeDocRef(`${col}/${id}`)),
      add: jest.fn().mockResolvedValue({ id: 'new-doc' }),
    })),
  };
}

/** Create a fake onDocumentCreated event (new request document). */
function makeCreatedEvent({ requestData, itemId = 'item-001', requestId = 'req-001' }) {
  return {
    data: { data: () => requestData },
    params: { itemId, requestId },
  };
}

/** Create a fake onDocumentUpdated event (request status change). */
function makeUpdatedEvent({ beforeData, afterData, itemId = 'item-001', requestId = 'req-001' }) {
  return {
    data: {
      before: { data: () => beforeData },
      after: { data: () => afterData },
    },
    params: { itemId, requestId },
  };
}

// ── Setup ─────────────────────────────────────────────────────────────────────

beforeEach(() => {
  mockSendEach.mockClear();
  mockDocUpdate.mockClear();
  mockDocSet.mockClear();
  adminMessaging.getMessaging.mockReturnValue({ sendEachForMulticast: mockSendEach });
});

// ── onNewRequest ──────────────────────────────────────────────────────────────

describe('onNewRequest — WBS 2.16', () => {
  test(
    '01 source "app", notificationsEnabled true, one valid token → ' +
    'FCM sendEachForMulticast called with correct T1 payload',
    async () => {
      if (!onNewRequest || typeof onNewRequest !== 'function') {
        throw new Error('onNewRequest not yet implemented in index.js (WBS 2.16)');
      }

      const db = makeFirestore({
        'items/item-001': {
          userId: 'uid-poster',
          title: 'Brown leather wallet',
          category: 'founder',
        },
        'users/uid-poster': {
          fcmTokens: ['tok-poster-1'],
          notificationsEnabled: true,
        },
      });
      adminFirestore.getFirestore.mockReturnValue(db);
      mockSendEach.mockResolvedValue({ responses: [{ success: true }] });

      const event = makeCreatedEvent({
        requestData: {
          requesterId: 'uid-visitor',
          requesterName: 'Pun Wongsakorn',
          type: 'claim',
          source: 'app',
        },
      });

      await onNewRequest(event);

      expect(mockSendEach).toHaveBeenCalledTimes(1);
      const payload = mockSendEach.mock.calls[0][0];
      expect(payload.tokens).toEqual(['tok-poster-1']);
      expect(payload.notification.title).toBe('New Claim Request');
      expect(payload.notification.body).toContain('Pun Wongsakorn');
      expect(payload.notification.body).toContain('Brown leather wallet');
      expect(payload.data.type).toBe('claimRequest');
      expect(payload.data.itemId).toBe('item-001');
      expect(payload.data.requestId).toBe('req-001');

      // In-app notification doc must also be written (Notification Center).
      const setCall = mockDocSet.mock.calls.find(
        ([path]) => path === 'users/uid-poster/notifications/req_req-001',
      );
      expect(setCall).toBeDefined();
      const setData = setCall[1];
      expect(setData.type).toBe('claimRequest');
      expect(setData.recipientId).toBe('uid-poster');
      expect(setData.itemId).toBe('item-001');
      expect(setData.itemTitle).toBe('Brown leather wallet');
      expect(setData.requesterName).toBe('Pun Wongsakorn');
      expect(setData.isRead).toBe(false);
    },
  );

  test(
    '02 walk-in item (userId="walkin", no matching user doc) → ' +
    'FCM is NOT called and no notification doc is written',
    async () => {
      if (!onNewRequest || typeof onNewRequest !== 'function') {
        throw new Error('onNewRequest not yet implemented in index.js (WBS 2.16)');
      }

      // Walk-in items have userId='walkin' and no corresponding users/walkin doc,
      // so the function exits at the userSnap.exists check.
      const db = makeFirestore({
        'items/item-001': { userId: 'walkin', title: 'Keys', category: 'founder' },
      });
      adminFirestore.getFirestore.mockReturnValue(db);

      const event = makeCreatedEvent({
        requestData: {
          requesterId: 'uid-visitor',
          requesterName: 'Alice',
          type: 'claim',
        },
      });

      await onNewRequest(event);

      expect(mockSendEach).not.toHaveBeenCalled();
      expect(mockDocSet).not.toHaveBeenCalled();
    },
  );

  test(
    '03 Poster has notificationsEnabled false → FCM is NOT called',
    async () => {
      if (!onNewRequest || typeof onNewRequest !== 'function') {
        throw new Error('onNewRequest not yet implemented in index.js (WBS 2.16)');
      }

      const db = makeFirestore({
        'items/item-001': { userId: 'uid-poster', title: 'Laptop', category: 'founder' },
        'users/uid-poster': { fcmTokens: ['tok-1'], notificationsEnabled: false },
      });
      adminFirestore.getFirestore.mockReturnValue(db);

      const event = makeCreatedEvent({
        requestData: {
          requesterId: 'uid-visitor',
          requesterName: 'Alice',
          type: 'claim',
          source: 'app',
        },
      });

      await onNewRequest(event);

      expect(mockSendEach).not.toHaveBeenCalled();
    },
  );

  test(
    '04 FCM returns messaging/registration-token-not-registered for one token → ' +
    'arrayRemove called for stale token; other tokens still attempted',
    async () => {
      if (!onNewRequest || typeof onNewRequest !== 'function') {
        throw new Error('onNewRequest not yet implemented in index.js (WBS 2.16)');
      }

      const db = makeFirestore({
        'items/item-001': { userId: 'uid-poster', title: 'Wallet', category: 'founder' },
        'users/uid-poster': {
          fcmTokens: ['tok-stale', 'tok-valid'],
          notificationsEnabled: true,
        },
      });
      adminFirestore.getFirestore.mockReturnValue(db);
      mockSendEach.mockResolvedValue({
        responses: [
          { success: false, error: { code: 'messaging/registration-token-not-registered' } },
          { success: true },
        ],
      });

      const event = makeCreatedEvent({
        requestData: {
          requesterId: 'uid-visitor',
          requesterName: 'Bob',
          type: 'claim',
          source: 'app',
        },
      });

      await onNewRequest(event);

      // FCM was still attempted with both tokens
      expect(mockSendEach).toHaveBeenCalledTimes(1);

      // Stale token must be removed from Firestore
      const updateCalls = mockDocUpdate.mock.calls;
      const userUpdateCall = updateCalls.find(([path]) => path === 'users/uid-poster');
      expect(userUpdateCall).toBeDefined();
      const updateData = userUpdateCall[1];
      expect(updateData.fcmTokens._type).toBe('arrayRemove');
      expect(updateData.fcmTokens.values).toContain('tok-stale');
    },
  );
});

// ── onRequestStatusChange ─────────────────────────────────────────────────────

describe('onRequestStatusChange — WBS 2.16', () => {
  test(
    '05 status pending → approved → FCM called for Visitor with T3 payload',
    async () => {
      if (!onRequestStatusChange || typeof onRequestStatusChange !== 'function') {
        throw new Error('onRequestStatusChange not yet implemented in index.js (WBS 2.16)');
      }

      const db = makeFirestore({
        'items/item-001': { title: 'Brown leather wallet', category: 'founder' },
        'users/uid-visitor': { fcmTokens: ['tok-visitor-1'], notificationsEnabled: true },
      });
      adminFirestore.getFirestore.mockReturnValue(db);
      mockSendEach.mockResolvedValue({ responses: [{ success: true }] });

      const event = makeUpdatedEvent({
        beforeData: {
          status: 'pending',
          requesterId: 'uid-visitor',
          requesterName: 'Pun',
        },
        afterData: {
          status: 'approved',
          requesterId: 'uid-visitor',
          requesterName: 'Pun',
        },
      });

      await onRequestStatusChange(event);

      expect(mockSendEach).toHaveBeenCalledTimes(1);
      const payload = mockSendEach.mock.calls[0][0];
      expect(payload.tokens).toEqual(['tok-visitor-1']);
      expect(payload.notification.title).toBe('Your request was approved');
      expect(payload.notification.body).toContain('Brown leather wallet');
      expect(payload.data.type).toBe('requestApproved');
      expect(payload.data.itemId).toBe('item-001');
      expect(payload.data.requestId).toBe('req-001');

      // In-app notification doc for the requester.
      const setCall = mockDocSet.mock.calls.find(
        ([path]) => path === 'users/uid-visitor/notifications/req_req-001_approved',
      );
      expect(setCall).toBeDefined();
      expect(setCall[1].type).toBe('requestApproved');
      expect(setCall[1].recipientId).toBe('uid-visitor');
    },
  );

  test(
    '06 status pending → rejected → FCM called for Visitor with T4 payload',
    async () => {
      if (!onRequestStatusChange || typeof onRequestStatusChange !== 'function') {
        throw new Error('onRequestStatusChange not yet implemented in index.js (WBS 2.16)');
      }

      const db = makeFirestore({
        'items/item-001': { title: 'AirPods', category: 'founder' },
        'users/uid-visitor': { fcmTokens: ['tok-visitor-2'], notificationsEnabled: true },
      });
      adminFirestore.getFirestore.mockReturnValue(db);
      mockSendEach.mockResolvedValue({ responses: [{ success: true }] });

      const event = makeUpdatedEvent({
        beforeData: { status: 'pending', requesterId: 'uid-visitor', requesterName: 'Alice' },
        afterData: { status: 'rejected', requesterId: 'uid-visitor', requesterName: 'Alice' },
      });

      await onRequestStatusChange(event);

      expect(mockSendEach).toHaveBeenCalledTimes(1);
      const payload = mockSendEach.mock.calls[0][0];
      expect(payload.tokens).toEqual(['tok-visitor-2']);
      expect(payload.notification.title).toBe('Your request was declined');
      expect(payload.notification.body).toContain('AirPods');
      expect(payload.data.type).toBe('requestDeclined');
    },
  );

  test(
    '07 status approved → resolved (non-qualifying change) → FCM is NOT called',
    async () => {
      if (!onRequestStatusChange || typeof onRequestStatusChange !== 'function') {
        throw new Error('onRequestStatusChange not yet implemented in index.js (WBS 2.16)');
      }

      const db = makeFirestore({
        'items/item-001': { title: 'Keys', category: 'founder' },
        'users/uid-visitor': { fcmTokens: ['tok-v'], notificationsEnabled: true },
      });
      adminFirestore.getFirestore.mockReturnValue(db);

      const event = makeUpdatedEvent({
        beforeData: { status: 'approved', requesterId: 'uid-visitor' },
        afterData: { status: 'resolved', requesterId: 'uid-visitor' },
      });

      await onRequestStatusChange(event);

      expect(mockSendEach).not.toHaveBeenCalled();
    },
  );
});

// ── Integration tests (manual / E2E) ─────────────────────────────────────────

describe('Integration — WBS 2.16 (manual verification required)', () => {
  test.skip(
    'I1 submit a Claim Request → Poster\'s device receives push notification ' +
    'with title "New Claim Request" and correct body',
    () => {
      // Requires: physical device with FCM, deployed Cloud Functions,
      // Firebase project connected. Run manually against the emulator suite
      // or a staging environment.
    },
  );

  test.skip(
    'I2 tap incoming notification → app navigates to /item/{itemId} ' +
    'via FirebaseMessaging.onMessageOpenedApp stream',
    () => {
      // Requires: physical device, deployed app, GoRouter wired to
      // FirebaseMessaging.onMessageOpenedApp and getInitialMessage().
    },
  );
});
