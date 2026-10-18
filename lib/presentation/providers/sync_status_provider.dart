import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SyncState {
  locallySaved,
  syncPending,
  synchronizing,
  synced,
  offline,
  syncFailed,
}

class SyncStatusNotifier extends StateNotifier<SyncState> {
  DateTime? _lastSyncedAt;

  SyncStatusNotifier() : super(SyncState.synced);

  DateTime? get lastSyncedAt => _lastSyncedAt;

  void markLocallySaved() {
    state = SyncState.locallySaved;
  }

  void markPending() {
    state = SyncState.syncPending;
  }

  void markSynchronizing() {
    state = SyncState.synchronizing;
  }

  void markSynced() {
    _lastSyncedAt = DateTime.now();
    state = SyncState.synced;
  }

  void markOffline() {
    state = SyncState.offline;
  }

  void markFailed() {
    state = SyncState.syncFailed;
  }
}

final syncStatusProvider = StateNotifierProvider<SyncStatusNotifier, SyncState>((ref) {
  return SyncStatusNotifier();
});
