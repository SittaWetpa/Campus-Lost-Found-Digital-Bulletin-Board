// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$notificationDatasourceHash() =>
    r'dc23d1a37d49bde6a2575ce721722d248ef82b02';

/// See also [notificationDatasource].
@ProviderFor(notificationDatasource)
final notificationDatasourceProvider =
    AutoDisposeProvider<NotificationRemoteDatasource>.internal(
  notificationDatasource,
  name: r'notificationDatasourceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$notificationDatasourceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef NotificationDatasourceRef
    = AutoDisposeProviderRef<NotificationRemoteDatasource>;
String _$notificationRepositoryHash() =>
    r'34a1c6280c8ea71012b2bd40cb7284947d5cdea5';

/// See also [notificationRepository].
@ProviderFor(notificationRepository)
final notificationRepositoryProvider =
    AutoDisposeProvider<NotificationRepository>.internal(
  notificationRepository,
  name: r'notificationRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$notificationRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef NotificationRepositoryRef
    = AutoDisposeProviderRef<NotificationRepository>;
String _$myNotificationsHash() => r'6bbef38293c6935ea2a10b72c53d22ddc706bfa9';

/// Notifications for the currently signed-in user, ordered by createdAt desc.
///
/// Copied from [myNotifications].
@ProviderFor(myNotifications)
final myNotificationsProvider =
    AutoDisposeStreamProvider<List<AppNotification>>.internal(
  myNotifications,
  name: r'myNotificationsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$myNotificationsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef MyNotificationsRef
    = AutoDisposeStreamProviderRef<List<AppNotification>>;
String _$myUnreadNotificationCountHash() =>
    r'8f1252498aaed14b5d240e946032fab8dc183bbe';

/// Unread count for the currently signed-in user — drives the nav badge.
///
/// Copied from [myUnreadNotificationCount].
@ProviderFor(myUnreadNotificationCount)
final myUnreadNotificationCountProvider =
    AutoDisposeStreamProvider<int>.internal(
  myUnreadNotificationCount,
  name: r'myUnreadNotificationCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$myUnreadNotificationCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef MyUnreadNotificationCountRef = AutoDisposeStreamProviderRef<int>;
String _$notificationActionNotifierHash() =>
    r'944b681b38c4d5deab60f896ef6a67dd380ec745';

/// See also [NotificationActionNotifier].
@ProviderFor(NotificationActionNotifier)
final notificationActionNotifierProvider = AutoDisposeNotifierProvider<
    NotificationActionNotifier, AsyncValue<void>>.internal(
  NotificationActionNotifier.new,
  name: r'notificationActionNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$notificationActionNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$NotificationActionNotifier = AutoDisposeNotifier<AsyncValue<void>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
