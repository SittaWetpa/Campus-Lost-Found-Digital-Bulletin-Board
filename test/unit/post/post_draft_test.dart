// WBS 1.4 — PostDraft validate() and toItem() invariants.
//
// Mirrors the rules in screens-forms.jsx submit() that previously lived
// inline in PostFormScreen._submit():
//   1. Sensitive  ⟹ description + contact = null
//   2. Sensitive  ⟹ expiresAt = createdAt + 14 days; otherwise null
//   3. Secret Q/A allowed only when founder && !sensitive && flag on
//   4. Validation: title/location always required; description/contact
//      required when !sensitive; secretAnswer required when secretQuestion
//      set (founder + non-sensitive + flag on)
//   5. Seeker can never be sensitive (mock toggles isSensitive = false on
//      category change; toItem() also coerces this defensively)

import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/post/domain/entities/post_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ── validate() ──────────────────────────────────────────────────────────

  group('PostDraft.validate()', () {
    PostDraft seekerBase() => PostDraft(
          category: ItemCategory.seeker,
          title: 'Lost wallet',
          location: 'LIB-1',
          occurredAt: DateTime(2026, 5, 1),
          description: 'Brown leather',
          contact: '0812345678',
        );

    PostDraft founderBase() => PostDraft(
          category: ItemCategory.founder,
          title: 'Found keys',
          location: 'ECC',
          occurredAt: DateTime(2026, 5, 1),
          description: 'Bunch of three',
          contact: '0812345678',
        );

    test('valid seeker draft → no errors', () {
      expect(
        seekerBase().validate(secretQuestionEnabled: true),
        isEmpty,
      );
    });

    test('empty title → {title: Required}', () {
      final draft = seekerBase().copyWith(title: '   ');
      expect(
        draft.validate(secretQuestionEnabled: true),
        {'title': 'Required'},
      );
    });

    test('non-sensitive + empty description → {description: Required}', () {
      final draft = seekerBase().copyWith(description: '');
      expect(
        draft.validate(secretQuestionEnabled: true),
        {'description': 'Required'},
      );
    });

    test('sensitive founder + empty description → no description error', () {
      final draft = founderBase().copyWith(
        isSensitive: true,
        description: '',
        contact: '',
      );
      final errs = draft.validate(secretQuestionEnabled: true);
      expect(errs.containsKey('description'), isFalse);
      expect(errs.containsKey('contact'), isFalse);
    });

    test('empty location → {location: Required}', () {
      final draft = seekerBase().copyWith(location: '');
      expect(
        draft.validate(secretQuestionEnabled: true),
        {'location': 'Required'},
      );
    });

    test('non-sensitive + empty contact → {contact: Required}', () {
      final draft = seekerBase().copyWith(contact: '');
      expect(
        draft.validate(secretQuestionEnabled: true),
        {'contact': 'Required'},
      );
    });

    test(
      'founder + non-sensitive + secretQuestion set + empty answer + flag on '
      '→ {secretAnswer: ...}',
      () {
        final draft = founderBase().copyWith(
          secretQuestion: 'What brand?',
          secretAnswer: '',
        );
        final errs = draft.validate(secretQuestionEnabled: true);
        expect(errs.containsKey('secretAnswer'), isTrue);
      },
    );

    test(
      'founder + non-sensitive + secretQuestion set + empty answer + flag OFF '
      '→ no secretAnswer error',
      () {
        final draft = founderBase().copyWith(
          secretQuestion: 'What brand?',
          secretAnswer: '',
        );
        final errs = draft.validate(secretQuestionEnabled: false);
        expect(errs.containsKey('secretAnswer'), isFalse);
      },
    );

    test(
      'sensitive founder + secretQuestion set → no secretAnswer error '
      '(secret Q hidden when sensitive)',
      () {
        final draft = founderBase().copyWith(
          isSensitive: true,
          description: '',
          contact: '',
          secretQuestion: 'What brand?',
          secretAnswer: '',
        );
        final errs = draft.validate(secretQuestionEnabled: true);
        expect(errs.containsKey('secretAnswer'), isFalse);
      },
    );

    test(
      'seeker + secretQuestion set + empty answer → no secretAnswer error '
      '(secret Q is founder-only)',
      () {
        final draft = seekerBase().copyWith(
          secretQuestion: 'What brand?',
          secretAnswer: '',
        );
        final errs = draft.validate(secretQuestionEnabled: true);
        expect(errs.containsKey('secretAnswer'), isFalse);
      },
    );
  });

  // ── toItem() invariants ────────────────────────────────────────────────

  group('PostDraft.toItem()', () {
    final fixedNow = DateTime(2026, 5, 1, 10, 0);

    PostDraft sensitiveFounder() => PostDraft(
          category: ItemCategory.founder,
          title: 'Student ID found',
          location: 'ECC',
          occurredAt: fixedNow,
          isSensitive: true,
          description: 'should be nulled',
          contact: 'should be nulled',
        );

    test(
      'sensitive founder → description, contact null and expiresAt = '
      'createdAt + 14 days',
      () {
        final item = sensitiveFounder().toItem(
          id: '',
          userId: 'u1',
          createdAt: fixedNow,
          secretQuestionEnabled: true,
        );

        expect(item.isSensitive, isTrue);
        expect(item.description, isNull);
        expect(item.contact, isNull);
        expect(item.expiresAt, isNotNull);
        expect(
          item.expiresAt!.difference(fixedNow),
          const Duration(days: 14),
        );
      },
    );

    test('non-sensitive → expiresAt is null', () {
      final draft = PostDraft(
        category: ItemCategory.founder,
        title: 'Found wallet',
        location: 'LIB-1',
        occurredAt: fixedNow,
        description: 'Brown',
        contact: '0812345678',
      );
      final item = draft.toItem(
        id: '',
        userId: 'u1',
        createdAt: fixedNow,
        secretQuestionEnabled: true,
      );
      expect(item.expiresAt, isNull);
      expect(item.isSensitive, isFalse);
    });

    test(
      'seeker + isSensitive=true → output is coerced to non-sensitive '
      '(only founder posts can be sensitive)',
      () {
        final draft = PostDraft(
          category: ItemCategory.seeker,
          title: 'Lost wallet',
          location: 'LIB-1',
          occurredAt: fixedNow,
          isSensitive: true,
          description: 'Brown',
          contact: '0812345678',
        );
        final item = draft.toItem(
          id: '',
          userId: 'u1',
          createdAt: fixedNow,
          secretQuestionEnabled: true,
        );
        expect(item.isSensitive, isFalse);
        expect(item.expiresAt, isNull);
        expect(item.description, 'Brown');
        expect(item.contact, '0812345678');
      },
    );

    test('seeker → secretQuestion/Answer are null in output', () {
      final draft = PostDraft(
        category: ItemCategory.seeker,
        title: 'Lost wallet',
        location: 'LIB-1',
        occurredAt: fixedNow,
        description: 'Brown',
        contact: '0812345678',
        secretQuestion: 'leaked',
        secretAnswer: 'leaked',
      );
      final item = draft.toItem(
        id: '',
        userId: 'u1',
        createdAt: fixedNow,
        secretQuestionEnabled: true,
      );
      expect(item.secretQuestion, isNull);
      expect(item.secretAnswer, isNull);
    });

    test(
      'founder + sensitive → secretQuestion/Answer are null in output',
      () {
        final draft = sensitiveFounder().copyWith(
          secretQuestion: 'leaked',
          secretAnswer: 'leaked',
        );
        final item = draft.toItem(
          id: '',
          userId: 'u1',
          createdAt: fixedNow,
          secretQuestionEnabled: true,
        );
        expect(item.secretQuestion, isNull);
        expect(item.secretAnswer, isNull);
      },
    );

    test(
      'founder + non-sensitive + flag OFF → secretQuestion/Answer are null',
      () {
        final draft = PostDraft(
          category: ItemCategory.founder,
          title: 'Found wallet',
          location: 'LIB-1',
          occurredAt: fixedNow,
          description: 'Brown',
          contact: '0812345678',
          secretQuestion: 'What brand?',
          secretAnswer: 'Fossil',
        );
        final item = draft.toItem(
          id: '',
          userId: 'u1',
          createdAt: fixedNow,
          secretQuestionEnabled: false,
        );
        expect(item.secretQuestion, isNull);
        expect(item.secretAnswer, isNull);
      },
    );

    test(
      'founder + non-sensitive + flag ON + Q/A set → both persisted, trimmed',
      () {
        final draft = PostDraft(
          category: ItemCategory.founder,
          title: 'Found wallet',
          location: 'LIB-1',
          occurredAt: fixedNow,
          description: 'Brown',
          contact: '0812345678',
          secretQuestion: '  What brand?  ',
          secretAnswer: '  Fossil  ',
        );
        final item = draft.toItem(
          id: '',
          userId: 'u1',
          createdAt: fixedNow,
          secretQuestionEnabled: true,
        );
        expect(item.secretQuestion, 'What brand?');
        expect(item.secretAnswer, 'Fossil');
      },
    );

    test('id and userId are passed through to the Item', () {
      final draft = PostDraft(
        category: ItemCategory.seeker,
        title: 'Lost wallet',
        location: 'LIB-1',
        occurredAt: fixedNow,
        description: 'Brown',
        contact: '0812345678',
      );
      final item = draft.toItem(
        id: 'existing-id',
        userId: 'user-42',
        createdAt: fixedNow,
        secretQuestionEnabled: true,
      );
      expect(item.id, 'existing-id');
      expect(item.userId, 'user-42');
    });
  });

  // ── factories ──────────────────────────────────────────────────────────

  group('PostDraft.fromItem()', () {
    test('useMyNumber is true when item.contact == myTelephone', () {
      final item = Item(
        id: 'i1',
        title: 'Found wallet',
        description: 'Brown',
        category: ItemCategory.founder,
        status: ItemStatus.active,
        location: 'LIB-1',
        contact: '0812345678',
        imageUrls: const [],
        userId: 'u1',
        createdAt: DateTime(2026, 5, 1),
        occurredAt: DateTime(2026, 5, 1),
      );
      final draft = PostDraft.fromItem(item, myTelephone: '0812345678');
      expect(draft.useMyNumber, isTrue);
    });

    test('useMyNumber is false when item.contact differs from myTelephone',
        () {
      final item = Item(
        id: 'i1',
        title: 'Found wallet',
        description: 'Brown',
        category: ItemCategory.founder,
        status: ItemStatus.active,
        location: 'LIB-1',
        contact: '0899999999',
        imageUrls: const [],
        userId: 'u1',
        createdAt: DateTime(2026, 5, 1),
        occurredAt: DateTime(2026, 5, 1),
      );
      final draft = PostDraft.fromItem(item, myTelephone: '0812345678');
      expect(draft.useMyNumber, isFalse);
    });

    test('null fields on Item become empty strings on draft', () {
      final item = Item(
        id: 'i1',
        title: 'Sensitive ID',
        description: null,
        category: ItemCategory.founder,
        status: ItemStatus.active,
        location: 'ECC',
        contact: null,
        imageUrls: const [],
        userId: 'u1',
        createdAt: DateTime(2026, 5, 1),
        occurredAt: DateTime(2026, 5, 1),
        isSensitive: true,
      );
      final draft = PostDraft.fromItem(item, myTelephone: '0812345678');
      expect(draft.description, '');
      expect(draft.contact, '');
      expect(draft.secretQuestion, '');
      expect(draft.secretAnswer, '');
    });
  });
}
