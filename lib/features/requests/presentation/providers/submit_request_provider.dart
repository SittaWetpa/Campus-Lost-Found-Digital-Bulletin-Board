import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_lost_found/features/feed/presentation/providers/item_provider.dart';
import 'package:campus_lost_found/features/requests/domain/usecases/submit_claim_request_use_case.dart';
import 'package:campus_lost_found/features/requests/domain/usecases/submit_found_report_use_case.dart';
import 'package:campus_lost_found/features/requests/presentation/providers/item_request_provider.dart';

// ── Claim Request ─────────────────────────────────────────────────────────────

final submitClaimRequestProvider = AutoDisposeNotifierProvider<
    SubmitClaimRequestNotifier, AsyncValue<void>>(
  SubmitClaimRequestNotifier.new,
);

class SubmitClaimRequestNotifier
    extends AutoDisposeNotifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> submit(SubmitClaimRequestParams params) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => SubmitClaimRequestUseCase(
            ref.read(itemRequestRepositoryProvider),
            ref.read(itemRepositoryProvider),
          ).call(params),
    );
    if (!state.hasError) {
      // Force a fresh subscription so the just-written doc surfaces immediately.
      // Without this, the existing snapshot can briefly exclude the new request
      // while its serverTimestamp is still resolving against orderBy('createdAt').
      ref.invalidate(
        watchMyRequestForItemProvider(params.itemId, params.requesterId),
      );
      ref.invalidate(watchRequestsForItemProvider(params.itemId));
    }
  }
}

// ── Found Report ──────────────────────────────────────────────────────────────

final submitFoundReportProvider = AutoDisposeNotifierProvider<
    SubmitFoundReportNotifier, AsyncValue<void>>(
  SubmitFoundReportNotifier.new,
);

class SubmitFoundReportNotifier
    extends AutoDisposeNotifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> submit(SubmitFoundReportParams params) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => SubmitFoundReportUseCase(ref.read(itemRequestRepositoryProvider))
          .call(params),
    );
    if (!state.hasError) {
      ref.invalidate(
        watchMyRequestForItemProvider(params.itemId, params.requesterId),
      );
      ref.invalidate(watchRequestsForItemProvider(params.itemId));
    }
  }
}
