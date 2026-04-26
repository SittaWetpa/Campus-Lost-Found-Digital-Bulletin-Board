import 'package:flutter_test/flutter_test.dart';

import 'package:campus_lost_found/config/router/app_router.dart';

void main() {
  // -------------------------------------------------------------------------
  // AppRoutes — path constants
  // -------------------------------------------------------------------------
  group('AppRoutes constants', () {
    test('login', () => expect(AppRoutes.login, '/login'));
    test('register', () => expect(AppRoutes.register, '/register'));
    test('feed', () => expect(AppRoutes.feed, '/feed'));
    test('otpVerify', () => expect(AppRoutes.otpVerify, '/otp-verify'));
    test('post', () => expect(AppRoutes.post, '/post'));
    test('myPosts', () => expect(AppRoutes.myPosts, '/my-posts'));
    test('settings', () => expect(AppRoutes.settings, '/settings'));
    test('itemDetail route pattern', () => expect(AppRoutes.itemDetail, '/item/:id'));
    test('editPost route pattern', () => expect(AppRoutes.editPost, '/post/:id/edit'));
    test('editProfile', () => expect(AppRoutes.editProfile, '/settings/edit-profile'));
  });

  // -------------------------------------------------------------------------
  // AppRoutes.isPublic — auth guard classification
  // -------------------------------------------------------------------------
  group('AppRoutes.isPublic', () {
    group('public routes (no auth required)', () {
      test('/login is public', () => expect(AppRoutes.isPublic('/login'), isTrue));
      test('/register is public', () => expect(AppRoutes.isPublic('/register'), isTrue));
      test('/otp-verify is public', () => expect(AppRoutes.isPublic('/otp-verify'), isTrue));
    });

    group('private routes (auth required)', () {
      test('/feed is not public', () => expect(AppRoutes.isPublic('/feed'), isFalse));
      test('/my-posts is not public', () => expect(AppRoutes.isPublic('/my-posts'), isFalse));
      test('/settings is not public', () => expect(AppRoutes.isPublic('/settings'), isFalse));
      test('/post is not public', () => expect(AppRoutes.isPublic('/post'), isFalse));
      test('/item/abc is not public', () => expect(AppRoutes.isPublic('/item/abc'), isFalse));
      test('/post/abc/edit is not public', () => expect(AppRoutes.isPublic('/post/abc/edit'), isFalse));
      test('/settings/edit-profile is not public',
          () => expect(AppRoutes.isPublic('/settings/edit-profile'), isFalse));
    });
  });

  // -------------------------------------------------------------------------
  // AppRoutes path builders — typed string interpolation
  // -------------------------------------------------------------------------
  group('AppRoutes path builders', () {
    group('itemDetailPath', () {
      test('interpolates id', () {
        expect(AppRoutes.itemDetailPath('abc123'), '/item/abc123');
      });
      test('interpolates id with dashes', () {
        expect(AppRoutes.itemDetailPath('item-with-dashes'), '/item/item-with-dashes');
      });
      test('empty string id', () {
        expect(AppRoutes.itemDetailPath(''), '/item/');
      });
    });

    group('editPostPath', () {
      test('interpolates id', () {
        expect(AppRoutes.editPostPath('xyz'), '/post/xyz/edit');
      });
      test('interpolates numeric id', () {
        expect(AppRoutes.editPostPath('99'), '/post/99/edit');
      });
    });
  });

  // -------------------------------------------------------------------------
  // ItemDetailRoute — typed value object
  // -------------------------------------------------------------------------
  group('ItemDetailRoute', () {
    test('location equals itemDetailPath(id)', () {
      const route = ItemDetailRoute(id: 'abc123');
      expect(route.location, AppRoutes.itemDetailPath('abc123'));
    });

    test('location for different id', () {
      const route = ItemDetailRoute(id: 'some-item-id');
      expect(route.location, '/item/some-item-id');
    });

    test('two routes with same id have equal locations', () {
      const a = ItemDetailRoute(id: 'x');
      const b = ItemDetailRoute(id: 'x');
      expect(a.location, equals(b.location));
    });

    test('two routes with different ids have different locations', () {
      const a = ItemDetailRoute(id: 'x');
      const b = ItemDetailRoute(id: 'y');
      expect(a.location, isNot(equals(b.location)));
    });
  });

  // -------------------------------------------------------------------------
  // EditPostRoute — typed value object
  // -------------------------------------------------------------------------
  group('EditPostRoute', () {
    test('location equals editPostPath(id)', () {
      const route = EditPostRoute(id: 'xyz');
      expect(route.location, AppRoutes.editPostPath('xyz'));
    });

    test('location for numeric id', () {
      const route = EditPostRoute(id: '42');
      expect(route.location, '/post/42/edit');
    });

    test('two routes with same id have equal locations', () {
      const a = EditPostRoute(id: 'p');
      const b = EditPostRoute(id: 'p');
      expect(a.location, equals(b.location));
    });

    test('two routes with different ids have different locations', () {
      const a = EditPostRoute(id: 'p1');
      const b = EditPostRoute(id: 'p2');
      expect(a.location, isNot(equals(b.location)));
    });
  });
}
