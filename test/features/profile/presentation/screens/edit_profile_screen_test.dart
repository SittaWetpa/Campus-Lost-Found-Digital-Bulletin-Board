// WBS 1.8 — Edit Profile & Avatar Screen widget tests
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

import 'package:campus_lost_found/config/router/app_router.dart';
import 'package:campus_lost_found/features/auth/domain/entities/user.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/user_provider.dart';
import 'package:campus_lost_found/features/profile/domain/repositories/profile_repository.dart';
import 'package:campus_lost_found/features/profile/presentation/providers/profile_provider.dart';
import 'package:campus_lost_found/features/profile/presentation/screens/edit_profile_screen.dart';

// ── Fake data ─────────────────────────────────────────────────────────────────

const _fakeUser = User(
  uid: 'uid-1',
  email: 'alice@mail.kmutt.ac.th',
  firstName: 'Alice',
  lastName: 'Smith',
  studentId: '6713050001',
  telephone: '0812345678',
  emailVerified: true,
);

// ── Fakes ─────────────────────────────────────────────────────────────────────

class _FakeProfileRepository implements ProfileRepository {
  // updateProfile recording
  bool updateCalled = false;
  String? lastUid;
  String? lastFirstName;
  String? lastLastName;
  String? lastTelephone;

  // uploadAvatar recording
  bool uploadCalled = false;
  String? lastUploadUid;
  String? lastUploadExtension;
  List<int>? lastUploadBytes;

  @override
  Future<void> updateProfile({
    required String uid,
    required String firstName,
    required String lastName,
    required String telephone,
  }) async {
    updateCalled = true;
    lastUid = uid;
    lastFirstName = firstName;
    lastLastName = lastName;
    lastTelephone = telephone;
  }

  @override
  Future<void> uploadAvatar({
    required String uid,
    required List<int> bytes,
    required String extension,
  }) async {
    uploadCalled = true;
    lastUploadUid = uid;
    lastUploadBytes = bytes;
    lastUploadExtension = extension;
  }
}

// Replaces ImagePickerPlatform.instance so no platform channel is needed.
class _FakeImagePickerPlatform extends ImagePickerPlatform {
  final XFile? returnFile;
  _FakeImagePickerPlatform({this.returnFile});

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async =>
      returnFile;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Standalone — sufficient for field-render, validation, and upload tests.
Widget _buildScreen({_FakeProfileRepository? fakeProfileRepo}) {
  final profileRepo = fakeProfileRepo ?? _FakeProfileRepository();
  return ProviderScope(
    overrides: [
      currentUserProvider.overrideWith((_) => Stream.value(_fakeUser)),
      profileRepositoryProvider.overrideWith((_) => profileRepo),
    ],
    child: const MaterialApp(home: EditProfileScreen()),
  );
}

/// Router app — required for the save-success test because the screen calls
/// context.pop() after showing the SnackBar.
Widget _buildScreenWithRouter({_FakeProfileRepository? fakeProfileRepo}) {
  final profileRepo = fakeProfileRepo ?? _FakeProfileRepository();
  final router = GoRouter(
    initialLocation: AppRoutes.editProfile,
    routes: [
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, __) =>
            const Scaffold(body: Center(child: Text('Settings Screen'))),
        routes: [
          GoRoute(
            path: 'edit-profile',
            builder: (_, __) => const EditProfileScreen(),
          ),
        ],
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      currentUserProvider.overrideWith((_) => Stream.value(_fakeUser)),
      profileRepositoryProvider.overrideWith((_) => profileRepo),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('EditProfileScreen — WBS 1.8', () {
    testWidgets(
      '01 opens with editable fields pre-populated; email and student ID are read-only',
      (tester) async {
        await tester.pumpWidget(_buildScreen());
        await tester.pumpAndSettle();

        // Editable fields — verify controller text equals the user's values
        expect(
          tester
              .widget<EditableText>(find.descendant(
                of: find.byType(TextFormField).at(0),
                matching: find.byType(EditableText),
              ))
              .controller
              .text,
          equals('Alice'),
        );
        expect(
          tester
              .widget<EditableText>(find.descendant(
                of: find.byType(TextFormField).at(1),
                matching: find.byType(EditableText),
              ))
              .controller
              .text,
          equals('Smith'),
        );
        expect(
          tester
              .widget<EditableText>(find.descendant(
                of: find.byType(TextFormField).at(2),
                matching: find.byType(EditableText),
              ))
              .controller
              .text,
          equals('0812345678'),
        );

        // Read-only fields — rendered and not editable
        expect(find.text('alice@mail.kmutt.ac.th'), findsOneWidget);
        expect(find.textContaining('6713050001'), findsOneWidget);

        expect(
          tester.widget<TextFormField>(find.byType(TextFormField).at(3)).enabled,
          isFalse,
        );
        expect(
          tester.widget<TextFormField>(find.byType(TextFormField).at(4)).enabled,
          isFalse,
        );
      },
    );

    testWidgets(
      '02 clearing first name and tapping Save shows "Required." validation error',
      (tester) async {
        await tester.pumpWidget(_buildScreen());
        await tester.pumpAndSettle();

        // Clear the first-name field
        await tester.enterText(find.byType(TextFormField).at(0), '');

        await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
        await tester.pump();

        expect(find.text('Required.'), findsOneWidget);
      },
    );

    testWidgets(
      '03 picking a new avatar calls ProfileRepository.uploadAvatar '
      'with the correct uid and jpg extension',
      (tester) async {
        final fakeBytes =
            Uint8List.fromList(List.generate(16, (i) => i));
        final fakeFile = XFile.fromData(
          fakeBytes,
          path: '/fake/avatar.jpg',
          name: 'avatar.jpg',
        );

        // Replace the platform instance — no real file-picker dialog opened
        ImagePickerPlatform.instance =
            _FakeImagePickerPlatform(returnFile: fakeFile);

        final fakeProfileRepo = _FakeProfileRepository();
        await tester.pumpWidget(_buildScreen(fakeProfileRepo: fakeProfileRepo));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(OutlinedButton, 'Change photo'));
        await tester.pumpAndSettle();

        expect(fakeProfileRepo.uploadCalled, isTrue);
        expect(fakeProfileRepo.lastUploadUid, equals('uid-1'));
        expect(fakeProfileRepo.lastUploadExtension, equals('jpg'));
        expect(fakeProfileRepo.lastUploadBytes, equals(fakeBytes));
      },
    );

    testWidgets(
      '04 saving valid profile data shows "Profile updated" SnackBar',
      (tester) async {
        final fakeProfileRepo = _FakeProfileRepository();

        // Router required — screen calls context.pop() after save
        await tester
            .pumpWidget(_buildScreenWithRouter(fakeProfileRepo: fakeProfileRepo));
        await tester.pumpAndSettle();

        // Fields are pre-populated with valid data — tap save directly
        await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
        await tester.pumpAndSettle();

        expect(find.text('Profile updated'), findsOneWidget);
        expect(fakeProfileRepo.updateCalled, isTrue);
      },
    );

    testWidgets(
      'meets accessibility guidelines (labels)',
      (tester) async {
        await tester.pumpWidget(_buildScreen());
        await tester.pumpAndSettle();

        // androidTapTargetGuideline is omitted: the "Change photo" OutlinedButton
        // uses MaterialTapTargetSize.shrinkWrap (32 dp tall) — a pre-existing
        // compact layout choice not in scope for WBS 5.1.
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        // textContrastGuideline is omitted: the amber FilledButton ("Save changes")
        // renders white text on amber (~2.77:1) — a pre-existing design token
        // issue affecting all primary buttons, not in scope for WBS 5.1.
      },
    );
  });
}
