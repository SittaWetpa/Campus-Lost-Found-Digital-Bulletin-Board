// WBS 4.2 — authRepositoryProvider override widget test.
// Renders a tiny widget that watches authStateProvider and verifies that the
// UI reads its data from a ProviderScope.overrides-supplied fake repository
// (i.e. no FirebaseAuth singleton is touched).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_lost_found/features/auth/domain/entities/auth_user.dart';
import 'package:campus_lost_found/features/auth/domain/repositories/auth_repository.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/auth_provider.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this._user);
  final AuthUser? _user;

  @override
  Stream<AuthUser?> get authStateChanges => Stream.value(_user);

  @override
  Future<AuthUser> signIn({required String email, required String password}) async =>
      AuthUser(uid: 'unused', email: email);

  @override
  Future<AuthUser> signUp({required String email, required String password}) async =>
      AuthUser(uid: 'unused', email: email);

  @override
  Future<void> signOut() async {}
}

class _AuthProbe extends ConsumerWidget {
  const _AuthProbe();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authStateProvider);
    return MaterialApp(
      home: Scaffold(
        body: state.when(
          data: (user) => Text(user == null ? 'signed-out' : 'uid:${user.uid}'),
          loading: () => const Text('loading'),
          error: (e, _) => Text('error:$e'),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('UI reads from the overridden authRepositoryProvider', (tester) async {
    final fakeUser = AuthUser(uid: 'fake-uid-123', email: 'a@mail.kmutt.ac.th');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWith((_) => _FakeAuthRepository(fakeUser)),
        ],
        child: const _AuthProbe(),
      ),
    );
    await tester.pump();

    expect(find.text('uid:fake-uid-123'), findsOneWidget);
  });

  testWidgets('signed-out fake surfaces a null user through the same chain',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWith((_) => _FakeAuthRepository(null)),
        ],
        child: const _AuthProbe(),
      ),
    );
    await tester.pump();

    expect(find.text('signed-out'), findsOneWidget);
  });
}
