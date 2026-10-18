import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sync_status_provider.dart';
import 'tibsy_refresh_icon.dart';

/// Production-ready micro-interaction badge visualizing persistence and cloud sync state.
class SyncStatusBadge extends ConsumerWidget {
  final VoidCallback? onTap;

  const SyncStatusBadge({super.key, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncStatusProvider);

    Color color;
    String label;
    IconData icon;

    switch (status) {
      case SyncState.synced:
        color = const Color(0xFF10B981);
        label = 'Synced';
        icon = Icons.cloud_done_rounded;
        break;
      case SyncState.synchronizing:
        color = const Color(0xFF0284C7);
        label = 'Syncing...';
        icon = Icons.sync_rounded;
        break;
      case SyncState.locallySaved:
        color = const Color(0xFF0284C7);
        label = 'Saved locally';
        icon = Icons.check_circle_outline_rounded;
        break;
      case SyncState.syncPending:
        color = const Color(0xFFF59E0B);
        label = 'Sync pending';
        icon = Icons.cloud_queue_rounded;
        break;
      case SyncState.offline:
        color = const Color(0xFF64748B);
        label = 'Offline';
        icon = Icons.cloud_off_rounded;
        break;
      case SyncState.syncFailed:
        color = const Color(0xFFEF4444);
        label = 'Sync error';
        icon = Icons.error_outline_rounded;
        break;
    }

    return GestureDetector(
      onTap: () async {
        if (onTap != null) {
          onTap!();
        } else {
          await syncAndRefreshEntireApp(ref);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
          child: Row(
            key: ValueKey(label),
            mainAxisSize: MainAxisSize.min,
            children: [
              status == SyncState.synchronizing
                  ? SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.8,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    )
                  : Icon(icon, size: 12, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
