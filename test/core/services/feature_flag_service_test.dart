// WBS 2.13 — FeatureFlagService unit tests
//
// U1 — secretQuestionEnabled: mocked RC returns false → getter returns false
// U2 — secretQuestionEnabled: mocked RC returns true  → getter returns true
// U3 — fetchAndActivate() throws (no network) → currentFlags falls back to defaults
// U4 — sensitive_categories JSON is malformed → falls back to defaults list

import 'package:campus_lost_found/core/domain/entities/feature_flags.dart';
import 'package:campus_lost_found/core/services/feature_flag_service.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebaseRemoteConfig extends Mock implements FirebaseRemoteConfig {}

// Stubs the three getters that currentFlags reads; returns defaults for
// everything else so individual tests can focus on one key at a time.
_MockFirebaseRemoteConfig _defaultMock() {
  final rc = _MockFirebaseRemoteConfig();
  when(() => rc.getBool('secret_question_enabled')).thenReturn(true);
  when(() => rc.getBool('sensitive_item_enabled')).thenReturn(true);
  when(() => rc.getString('security_office_contact'))
      .thenReturn('02-470-9820');
  when(() => rc.getString('sensitive_categories'))
      .thenReturn('["credit_card","id_card","passport","key","document"]');
  when(() => rc.setDefaults(any())).thenAnswer((_) async {});
  when(() => rc.setConfigSettings(any())).thenAnswer((_) async {});
  when(() => rc.fetchAndActivate()).thenAnswer((_) async => false);
  return rc;
}

void main() {
  setUpAll(() {
    registerFallbackValue(RemoteConfigSettings(
      fetchTimeout: Duration.zero,
      minimumFetchInterval: Duration.zero,
    ));
  });

  group('FeatureFlagService — WBS 2.13', () {
    // U1 ──────────────────────────────────────────────────────────────────
    test(
      'U1 — secretQuestionEnabled returns false when RC returns false',
      () {
        final rc = _defaultMock();
        when(() => rc.getBool('secret_question_enabled')).thenReturn(false);

        final service = FeatureFlagService(rc);

        expect(service.secretQuestionEnabled, isFalse);
        expect(service.currentFlags.secretQuestionEnabled, isFalse);
      },
    );

    // U2 ──────────────────────────────────────────────────────────────────
    test(
      'U2 — secretQuestionEnabled returns true when RC returns true',
      () {
        final rc = _defaultMock();
        when(() => rc.getBool('secret_question_enabled')).thenReturn(true);

        final service = FeatureFlagService(rc);

        expect(service.secretQuestionEnabled, isTrue);
        expect(service.currentFlags.secretQuestionEnabled, isTrue);
      },
    );

    // U3 ──────────────────────────────────────────────────────────────────
    test(
      'U3 — fetchAndActivate() swallows network failure; currentFlags '
      'returns in-app default values',
      () async {
        final rc = _defaultMock();
        // Override fetchAndActivate to simulate network failure.
        when(() => rc.fetchAndActivate())
            .thenThrow(Exception('network unavailable'));

        final service = FeatureFlagService(rc);

        // Must not throw.
        await expectLater(service.fetchAndActivate(), completes);

        // After a failed fetch, Remote Config returns values from setDefaults
        // (which mirror FeatureFlags.defaults). Verify the convenience getters
        // still return the defaults by checking the mocked RC returns them.
        expect(service.secretQuestionEnabled,
            FeatureFlags.defaults.secretQuestionEnabled);
        expect(service.sensitiveItemEnabled,
            FeatureFlags.defaults.sensitiveItemEnabled);
        expect(service.securityOfficeContact,
            FeatureFlags.defaults.securityOfficeContact);
      },
    );

    // U4 ──────────────────────────────────────────────────────────────────
    test(
      'U4 — malformed JSON for sensitive_categories falls back to defaults',
      () {
        final rc = _defaultMock();
        when(() => rc.getString('sensitive_categories'))
            .thenReturn('not-valid-json');

        final service = FeatureFlagService(rc);

        expect(
          service.currentFlags.sensitiveCategories,
          FeatureFlags.defaults.sensitiveCategories,
        );
      },
    );
  });
}
