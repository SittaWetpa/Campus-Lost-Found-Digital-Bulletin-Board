import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_provider.g.dart';

enum ConnectivityStatus { online, offline }

@riverpod
Stream<ConnectivityStatus> connectivityStatus(ConnectivityStatusRef ref) {
  return Connectivity().onConnectivityChanged.map(
    (results) => results.any((r) => r != ConnectivityResult.none)
        ? ConnectivityStatus.online
        : ConnectivityStatus.offline,
  );
}

@riverpod
bool isOffline(IsOfflineRef ref) {
  final status = ref.watch(connectivityStatusProvider).valueOrNull;
  return status == ConnectivityStatus.offline;
}
