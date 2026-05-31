/**
 * WBS 2.8 — itemCategory Firestore rules tests.
 *
 * Verifies that the `itemCategory` field is required on item creation and must
 * be one of the 8 valid taxonomy values.
 *
 * HOW TO RUN
 * ----------
 *   Prerequisites:
 *     firebase emulators:start --only firestore,auth   (in another terminal)
 *
 *   Run:
 *     cd test/firestore_rules
 *     npm install
 *     npm test
 */

import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from '@firebase/rules-unit-testing';
import { serverTimestamp } from 'firebase/firestore';
import { readFileSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const RULES_PATH = resolve(__dirname, '../../firestore.rules');
const PROJECT_ID = 'campus-lost-found-cat-test';

let testEnv;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      host: '127.0.0.1',
      port: 8080,
      rules: readFileSync(RULES_PATH, 'utf8'),
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

afterEach(async () => {
  await testEnv.clearFirestore();
});

const POSTER_UID = 'uid-poster-cat';

const validBase = () => ({
  title: 'Found item',
  description: 'Description',
  category: 'founder',
  status: 'active',
  location: 'Library',
  contact: '0812345678',
  imageUrls: [],
  userId: POSTER_UID,
  isSensitive: false,
  createdAt: serverTimestamp(), // WBS 5.2: must equal request.time
});

describe('WBS 2.8 — itemCategory field validation on create', () => {
  test('create without itemCategory is denied', async () => {
    const authDb = testEnv.authenticatedContext(POSTER_UID).firestore();
    await assertFails(
      authDb.collection('items').doc('item-no-cat').set({
        ...validBase(),
        // intentionally omit itemCategory
      }),
    );
  });

  test('create with invalid itemCategory value is denied', async () => {
    const authDb = testEnv.authenticatedContext(POSTER_UID).firestore();
    await assertFails(
      authDb.collection('items').doc('item-bad-cat').set({
        ...validBase(),
        itemCategory: 'invalid_value',
      }),
    );
  });

  test('create with valid itemCategory "electronics" is allowed', async () => {
    const authDb = testEnv.authenticatedContext(POSTER_UID).firestore();
    await assertSucceeds(
      authDb.collection('items').doc('item-electronics').set({
        ...validBase(),
        itemCategory: 'electronics',
      }),
    );
  });

  test('create with valid itemCategory "bag_wallet" is allowed', async () => {
    const authDb = testEnv.authenticatedContext(POSTER_UID).firestore();
    await assertSucceeds(
      authDb.collection('items').doc('item-bag').set({
        ...validBase(),
        itemCategory: 'bag_wallet',
      }),
    );
  });

  test('create with valid itemCategory "other" is allowed', async () => {
    const authDb = testEnv.authenticatedContext(POSTER_UID).firestore();
    await assertSucceeds(
      authDb.collection('items').doc('item-other').set({
        ...validBase(),
        itemCategory: 'other',
      }),
    );
  });
});
