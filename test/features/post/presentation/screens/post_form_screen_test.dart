// WBS 2.13 — PostFormScreen widget tests: feature-flag gating
//
// W1 — secretQuestionEnabled = false → SECRET QUESTION section hidden on Founder Post
// W2 — secretQuestionEnabled = true  → SECRET QUESTION section visible on Founder Post

import 'package:campus_lost_found/core/services/feature_flag_service.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/feed/domain/repositories/item_repository.dart';
import 'package:campus_lost_found/features/feed/presentation/providers/item_provider.dart';
import 'package:campus_lost_found/features/post/domain/repositories/post_repository.dart';
import 'package:campus_lost_found/features/post/presentation/providers/post_provider.dart';
import 'package:campus_lost_found/features/post/presentation/screens/post_form_screen.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ── mocks ─────────────────────────────────────────────────────────────────

class _MockFirebaseRemoteConfig extends Mock implements FirebaseRemoteConfig {}

class _MockPostRepository extends Mock implements PostRepository {}

class _FakeItemRepository implements ItemRepository {
  @override
  Stream<List<Item>> watchFeed() => const Stream.empty();
  @override
  Stream<Item?> watchItem(String id) => Stream.value(null);
  @override
  Future<Item?> getItemById(String id) async => null;
  @override
  Future<List<Item>> searchItems(String keyword) async => const [];
  @override
  Future<List<Item>> getSimilarFounderPosts(String keyword) async => const [];
  @override
  Stream<List<Item>> watchMyItems(String userId) => const Stream.empty();
  @override
  Future<String?> getItemSecretAnswer(String itemId) async => null;
}

// ── helpers ───────────────────────────────────────────────────────────────

/// Builds a [FeatureFlagService] backed by a stubbed [FirebaseRemoteConfig]
/// with [secretQuestionEnabled] set to [value]. All other flags are at
/// their defaults.
FeatureFlagService _serviceWith({required bool secretQuestionEnabled}) {
  final rc = _MockFirebaseRemoteConfig();
  when(() => rc.getBool('secret_question_enabled'))
      .thenReturn(secretQuestionEnabled);
  when(() => rc.getBool('sensitive_item_enabled')).thenReturn(true);
  when(() => rc.getString('security_office_contact'))
      .thenReturn('02-470-9999');
  when(() => rc.getString('sensitive_categories'))
      .thenReturn('["credit_card","id_card","passport","key","document"]');
  return FeatureFlagService(rc);
}

Widget _buildForm(FeatureFlagService flagService) {
  return ProviderScope(
    overrides: [
      featureFlagsProvider.overrideWithValue(flagService),
      // Prevent Firebase Auth stream from being accessed.
      authStateProvider.overrideWith((_) => Stream.value(null)),
      // Notifiers whose build() returns a constant — no Firebase touch.
      postRepositoryProvider.overrideWith((_) => _MockPostRepository()),
      itemRepositoryProvider.overrideWith((_) => _FakeItemRepository()),
    ],
    child: const MaterialApp(home: PostFormScreen()),
  );
}

// ── tests ─────────────────────────────────────────────────────────────────

void main() {
  // W1 ────────────────────────────────────────────────────────────────────
  testWidgets(
    'W1 — secretQuestionEnabled=false hides SECRET QUESTION section on '
    'Founder Post (default category)',
    (tester) async {
      await tester.pumpWidget(
        _buildForm(_serviceWith(secretQuestionEnabled: false)),
      );
      await tester.pumpAndSettle();

      // Default category is Founder Post (ItemCategory.founder).
      // With the flag off the entire block is skipped — neither the label
      // nor the hint texts should appear.
      expect(find.text('SECRET QUESTION (optional)'), findsNothing,
          reason: 'Label must be absent when secretQuestionEnabled is false');
      expect(
          find.text(
              'e.g. What colour is the card sleeve inside?'),
          findsNothing,
          reason: 'Hint must be absent when secretQuestionEnabled is false');
    },
  );

  // W2 ────────────────────────────────────────────────────────────────────
  testWidgets(
    'W2 — secretQuestionEnabled=true shows SECRET QUESTION section on '
    'Founder Post (default category)',
    (tester) async {
      await tester.pumpWidget(
        _buildForm(_serviceWith(secretQuestionEnabled: true)),
      );
      await tester.pumpAndSettle();

      // With the flag on and Sensitive Item deselected (default), the section
      // should be present.
      expect(find.text('SECRET QUESTION (optional)'), findsOneWidget,
          reason: 'Label must appear when secretQuestionEnabled is true');
    },
  );
}
