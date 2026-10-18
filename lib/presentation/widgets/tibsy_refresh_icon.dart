import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/firestore_service.dart';
import '../providers/auth_provider.dart';
import '../providers/client_provider.dart';
import '../providers/product_provider.dart';
import '../providers/profile_provider.dart';
import '../viewmodels/expense_viewmodel.dart';
import '../viewmodels/invoice_viewmodel.dart';
import '../viewmodels/project_viewmodel.dart';
import '../viewmodels/time_tracker_viewmodel.dart';
import '../providers/sync_status_provider.dart';
export 'tibsy_pull_to_refresh.dart';

/// Centralized function to sync Firestore cloud data and refresh all local providers
Future<void> syncAndRefreshEntireApp(WidgetRef ref) async {
  final syncNotifier = ref.read(syncStatusProvider.notifier);
  syncNotifier.markSynchronizing();

  bool syncSuccess = true;
  try {
    final user = ref.read(authProvider).value;
    if (user != null) {
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.syncAllData(user.uid);
    }
  } catch (_) {
    syncSuccess = false;
  }

  try {
    ref.read(invoiceProvider.notifier).refreshFromLocal();
    ref.read(profileProvider.notifier).loadFromLocal();
    ref.read(clientProvider.notifier).refreshFromLocal();
    ref.read(projectProvider.notifier).refreshFromLocal();
    ref.read(productsProvider.notifier).refreshFromLocal();
    ref.read(expenseProvider.notifier).refreshFromLocal();
    ref.read(timeEntriesProvider.notifier).refreshFromLocal();
  } catch (_) {}

  await Future.delayed(const Duration(milliseconds: 300));
  if (syncSuccess) {
    syncNotifier.markSynced();
  } else {
    syncNotifier.markFailed();
  }
}

/// Animated Tibsy GIF used as a vibrant custom refresh icon
class TibsyRefreshIcon extends StatelessWidget {
  final double size;
  final BoxFit fit;

  const TibsyRefreshIcon({
    super.key,
    this.size = 28,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: Image.asset(
        'assets/images/tibsy-dp-3.gif',
        width: size,
        height: size,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/images/tibsy-dp-2.gif',
            width: size,
            height: size,
            fit: fit,
            errorBuilder: (c, e, s) => Icon(
              Icons.refresh_rounded,
              size: size * 0.8,
              color: const Color(0xFFFF5722),
            ),
          );
        },
      ),
    );
  }
}

/// Interactive Refresh Button that displays the animated Tibsy GIF
/// and triggers full data sync & local reload across all providers.
class TibsyRefreshButton extends ConsumerStatefulWidget {
  final VoidCallback? onRefreshed;
  final double size;
  final double iconSize;
  final String? tooltip;

  const TibsyRefreshButton({
    super.key,
    this.onRefreshed,
    this.size = 42,
    this.iconSize = 28,
    this.tooltip = 'Sync & Refresh',
  });

  @override
  ConsumerState<TibsyRefreshButton> createState() => _TibsyRefreshButtonState();
}

class _TibsyRefreshButtonState extends ConsumerState<TibsyRefreshButton>
    with SingleTickerProviderStateMixin {
  bool _isRefreshing = false;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _triggerRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    _animController.repeat();

    await syncAndRefreshEntireApp(ref);
    await Future.delayed(const Duration(milliseconds: 200));

    if (mounted) {
      _animController.stop();
      _animController.reset();
      setState(() => _isRefreshing = false);
      widget.onRefreshed?.call();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              TibsyRefreshIcon(size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Synced',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTap: _isRefreshing ? null : _triggerRefresh,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: _isRefreshing ? const Color(0xFF0F172A) : const Color(0xFFE5E7EB),
            width: _isRefreshing ? 1.4 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: RotationTransition(
            turns: _animController,
            child: TibsyRefreshIcon(size: widget.iconSize),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(
        message: widget.tooltip!,
        child: button,
      );
    }
    return button;
  }
}
