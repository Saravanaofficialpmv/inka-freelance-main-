import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tibsy_refresh_icon.dart';

/// A locked Sliver refresh control that displays the animated Tibsy GIF
/// and pins at the top until data synchronization is fully complete.
class TibsySliverRefreshControl extends ConsumerWidget {
  final Future<void> Function()? onRefresh;
  final double refreshTriggerPullDistance;
  final double refreshIndicatorExtent;

  const TibsySliverRefreshControl({
    super.key,
    this.onRefresh,
    this.refreshTriggerPullDistance = 80.0,
    this.refreshIndicatorExtent = 68.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isDesktopWeb = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;

    if (isDesktopWeb) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return CupertinoSliverRefreshControl(
      refreshTriggerPullDistance: refreshTriggerPullDistance,
      refreshIndicatorExtent: refreshIndicatorExtent,
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        if (onRefresh != null) {
          await onRefresh!();
        } else {
          await syncAndRefreshEntireApp(ref);
        }
        HapticFeedback.lightImpact();
        // Small delay to ensure smooth UI transition before collapse
        await Future.delayed(const Duration(milliseconds: 350));
      },
      builder: (
        BuildContext context,
        RefreshIndicatorMode refreshState,
        double pulledExtent,
        double refreshTriggerPullDistance,
        double refreshIndicatorExtent,
      ) {
        final double progress = (pulledExtent / refreshTriggerPullDistance).clamp(0.0, 1.0);
        final bool isArmed = refreshState == RefreshIndicatorMode.armed;
        final bool isRefreshing = refreshState == RefreshIndicatorMode.refresh;
        final bool isDone = refreshState == RefreshIndicatorMode.done;
        final bool isHighlighted = isArmed || isRefreshing || isDone;

        if (pulledExtent <= 0.0 && !isRefreshing && !isDone) {
          return const SizedBox.shrink();
        }

        return Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Opacity(
            opacity: (isRefreshing || isDone) ? 1.0 : (progress * 1.3).clamp(0.0, 1.0),
            child: Transform.scale(
              scale: (isRefreshing || isDone)
                  ? 1.0
                  : (0.75 + (progress * 0.25)).clamp(0.0, 1.05),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isHighlighted
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFE2E8F0),
                    width: isHighlighted ? 1.4 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const TibsyRefreshIcon(size: 26),
                    const SizedBox(width: 10),
                    Text(
                      isDone
                          ? 'Synced'
                          : (isRefreshing
                              ? 'Syncing...'
                              : (isArmed
                                  ? 'Release to refresh'
                                  : 'Pull to refresh')),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: isHighlighted
                            ? const Color(0xFF0F172A)
                            : const Color(0xFF64748B),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Drop-in pull-to-refresh container that wraps content with locked Cupertino
/// overscroll physics and displays the custom Tibsy animated indicator.
class TibsyPullToRefresh extends StatelessWidget {
  final Widget child;
  final Future<void> Function()? onRefresh;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;

  const TibsyPullToRefresh({
    super.key,
    required this.child,
    this.onRefresh,
    this.controller,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDesktopWeb = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;

    if (isDesktopWeb) {
      return SingleChildScrollView(
        controller: controller,
        padding: padding,
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        child: child,
      );
    }

    return CustomScrollView(
      controller: controller,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        TibsySliverRefreshControl(onRefresh: onRefresh),
        SliverPadding(
          padding: padding ?? EdgeInsets.zero,
          sliver: SliverToBoxAdapter(child: child),
        ),
      ],
    );
  }
}
