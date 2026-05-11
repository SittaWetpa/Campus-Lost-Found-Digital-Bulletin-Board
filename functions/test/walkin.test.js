// WBS 2.15 — walkin Cloud Function unit tests
'use strict';

// Skip reCAPTCHA for all tests except case 04 which overrides this per-test.
process.env.FUNCTIONS_EMULATOR = 'true';

// ── Mocks (hoisted by Jest before any require) ────────────────────────────────

jest.mock('firebase-admin/app', () => ({ initializeApp: jest.fn() }));

jest.mock('firebase-admin/firestore', () => ({
  getFirestore: jest.fn(),
  FieldValue: { serverTimestamp: jest.fn(() => '__SERVER_TS__') },
}));

jest.mock('firebase-admin/storage', () => ({
  getStorage: jest.fn(() => ({
    bucket: jest.fn(() => ({
      file: jest.fn(() => ({ save: jest.fn().mockResolvedValue(undefined) })),
      name: 'test-bucket',
    })),
  })),
}));

jest.mock('firebase-admin/auth', () => ({ getAuth: jest.fn() }));

jest.mock('firebase-functions/params', () => ({
  defineSecret: jest.fn(() => ({ value: jest.fn(() => 'test-secret') })),
}));

// onRequest returns the handler directly so exports.walkin is the async fn.
jest.mock('firebase-functions/v2/https', () => ({
  onRequest: jest.fn((_opts, handler) => handler),
  onCall: jest.fn((_opts, handler) => handler),
  HttpsError: class HttpsError extends Error {
    constructor(code, msg) {
      super(msg);
      this.code = code;
    }
  },
}));

jest.mock('firebase-functions/v2/scheduler', () => ({
  onSchedule: jest.fn(() => ({})),
}));

jest.mock('firebase-functions/v2/firestore', () => ({
  onDocumentCreated: jest.fn(() => ({})),
  onDocumentUpdated: jest.fn(() => ({})),
}));

// ── Module under test ─────────────────────────────────────────────────────────

const adminFirestore = require('firebase-admin/firestore');
const { walkin } = require('../index');

// ── Helpers ───────────────────────────────────────────────────────────────────

const mockAdd = jest.fn().mockResolvedValue({ id: 'new-doc-id' });

function makeReqRes({ method = 'POST', body = {}, ip = '127.0.0.1', headers = {} } = {}) {
  const req = {
    method,
    body,
    ip,
    headers: { 'content-type': 'application/json', ...headers },
  };
  const res = {
    _status: 200,
    _body: null,
    status(code) { this._status = code; return this; },
    json(body) { this._body = body; return this; },
    send(body) { this._body = body; return this; },
    set: jest.fn().mockReturnThis(),
  };
  return { req, res };
}

// ── Setup ─────────────────────────────────────────────────────────────────────

beforeEach(() => {
  mockAdd.mockClear();
  adminFirestore.getFirestore.mockReturnValue({
    collection: jest.fn().mockReturnValue({ add: mockAdd }),
  });
});

// ── Tests ─────────────────────────────────────────────────────────────────────

describe('walkin Cloud Function — WBS 2.15', () => {
  test(
    '01 valid submission creates Firestore doc with source "qr_walk_in", ' +
    'status "active", category "founder"',
    async () => {
      const { req, res } = makeReqRes({
        body: { category: 'wallet', title: 'Brown wallet', location: 'Library' },
        ip: '10.0.0.1',
      });
      await walkin(req, res);

      expect(res._status).toBe(201);
      expect(res._body.success).toBe(true);
      expect(typeof res._body.refId).toBe('string');

      expect(mockAdd).toHaveBeenCalledTimes(1);
      const saved = mockAdd.mock.calls[0][0];
      expect(saved.source).toBe('qr_walk_in');
      expect(saved.status).toBe('active');
      expect(saved.category).toBe('founder');
      expect(saved.title).toBe('Brown wallet');
      expect(saved.location).toBe('Library');
    },
  );

  test('02a missing category returns 400 without writing to Firestore', async () => {
    const { req, res } = makeReqRes({
      body: { title: 'Keys', location: 'Cafeteria' },
      ip: '10.0.0.2',
    });
    await walkin(req, res);

    expect(res._status).toBe(400);
    expect(res._body.error).toMatch(/category/i);
    expect(mockAdd).not.toHaveBeenCalled();
  });

  test('02b missing title returns 400 without writing to Firestore', async () => {
    const { req, res } = makeReqRes({
      body: { category: 'key', location: 'Cafeteria' },
      ip: '10.0.0.3',
    });
    await walkin(req, res);

    expect(res._status).toBe(400);
    expect(res._body.error).toMatch(/title/i);
    expect(mockAdd).not.toHaveBeenCalled();
  });

  test('02c missing location returns 400 without writing to Firestore', async () => {
    const { req, res } = makeReqRes({
      body: { category: 'key', title: 'House keys' },
      ip: '10.0.0.4',
    });
    await walkin(req, res);

    expect(res._status).toBe(400);
    expect(res._body.error).toMatch(/location/i);
    expect(mockAdd).not.toHaveBeenCalled();
  });

  test('03 6th submission from the same IP within the hour returns 429', async () => {
    // Unique IP used only in this test so in-memory rate map is clean.
    const ip = '10.255.255.1';
    const body = { category: 'wallet', title: 'Brown wallet', location: 'Library' };

    for (let i = 0; i < 5; i++) {
      const { req, res } = makeReqRes({ body, ip });
      await walkin(req, res);
      expect(res._status).toBe(201);
    }

    const { req, res } = makeReqRes({ body, ip });
    await walkin(req, res);
    expect(res._status).toBe(429);
    expect(mockAdd).toHaveBeenCalledTimes(5); // 6th was blocked before Firestore write
  });

  test('04 invalid reCAPTCHA token is rejected with 400 in non-emulator mode', async () => {
    const origEnv = process.env.FUNCTIONS_EMULATOR;
    process.env.FUNCTIONS_EMULATOR = '';

    global.fetch = jest.fn().mockResolvedValue({
      json: async () => ({ success: false, score: 0.1 }),
    });

    try {
      const { req, res } = makeReqRes({
        body: {
          token: 'invalid-token',
          category: 'wallet',
          title: 'Brown wallet',
          location: 'Library',
        },
        ip: '10.0.0.5',
      });
      await walkin(req, res);

      expect(res._status).toBe(400);
      expect(res._body.error).toMatch(/recaptcha/i);
      expect(mockAdd).not.toHaveBeenCalled();
    } finally {
      process.env.FUNCTIONS_EMULATOR = origEnv;
      delete global.fetch;
    }
  });

  test('05 sensitive category sets isSensitive: true in Firestore document', async () => {
    const { req, res } = makeReqRes({
      body: { category: 'national_id', title: 'National ID card', location: 'Front gate' },
      ip: '10.0.0.6',
    });
    await walkin(req, res);

    expect(res._status).toBe(201);
    const saved = mockAdd.mock.calls[0][0];
    expect(saved.isSensitive).toBe(true);
  });
});
