import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/entities/feature_flags.dart';
import '../domain/repositories/feature_flag_repository.dart';

part 'feature_flag_service.g.dart';

class FeatureFlagService implements FeatureFlagRepository {
  FeatureFlagService(this._remoteConfig);

  final FirebaseRemoteConfig _remoteConfig;

  @override
  Future<void> fetchAndActivate() async {
    await _remoteConfig.setDefaults({
      'secret_question_enabled': true,
      'sensitive_item_enabled': true,
      'security_office_contact': '02-470-9820',
      'sensitive_categories':
          '["credit_card","id_card","passport","key","document"]',
    });
    await _remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval:
          kReleaseMode ? const Duration(hours: 1) : Duration.zero,
    ));
    // Failure is intentionally swallowed; in-app defaults remain active.
    try {
      await _remoteConfig.fetchAndActivate();
    } catch (_) {}
  }

  @override
  FeatureFlags get currentFlags => FeatureFlags(
        secretQuestionEnabled:
            _remoteConfig.getBool('secret_question_enabled'),
        sensitiveItemEnabled: _remoteConfig.getBool('sensitive_item_enabled'),
        securityOfficeContact:
            _remoteConfig.getString('security_office_contact'),
        sensitiveCategories: _parseSensitiveCategories(
          _remoteConfig.getString('sensitive_categories'),
        ),
      );

  // Convenience getters keep all existing call sites unchanged.
  bool get secretQuestionEnabled => currentFlags.secretQuestionEnabled;
  bool get sensitiveItemEnabled => currentFlags.sensitiveItemEnabled;
  String get securityOfficeContact => currentFlags.securityOfficeContact;

  @override
  DateTime get lastFetchTime => _remoteConfig.lastFetchTime;

  List<String> _parseSensitiveCategories(String raw) {
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.cast<String>();
    } catch (_) {
      return FeatureFlags.defaults.sensitiveCategories;
    }
  }
}

@riverpod
FeatureFlagService featureFlags(FeatureFlagsRef ref) =>
    FeatureFlagService(FirebaseRemoteConfig.instance);
