import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_motion.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  const CustomBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final bottomMargin = bottomInset > 0 ? bottomInset + 4 : 16.0;
    final bool reducedMotion = AppMotion.isReducedMotion(context);

    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, bottomMargin),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          // Ambient deep dark shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
          // Subtle top rim highlight
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xEB16181D), // Dark slate translucent glass
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
                width: 1.2,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const int itemCount = 5;
                final double totalWidth = constraints.maxWidth;
                final double itemWidth = totalWidth / itemCount;
                final bool hasActiveIndex = currentIndex >= 0 && currentIndex < itemCount;

                return Stack(
                  children: [
                    // ── Smooth Sliding Active Indicator Pill ──
                    if (hasActiveIndex)
                      AnimatedPositioned(
                        left: currentIndex * itemWidth,
                        top: 0,
                        bottom: 0,
                        width: itemWidth,
                        duration: reducedMotion ? Duration.zero : AppMotion.navigation,
                        curve: AppMotion.entrance,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.28),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.06),
                                blurRadius: 6,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // ── 5 Tab Navigation Items ──
                    Row(
                      children: [
                        // 1. Home
                        Expanded(
                          child: _NavItem(
                            iconAsset: 'assets/icons/nav/home-4.png',
                            label: 'Home',
                            isActive: currentIndex == 0,
                            onTap: () => GoRouter.of(context).go('/dashboard'),
                          ),
                        ),

                        // 2. Invoices
                        Expanded(
                          child: _NavItem(
                            iconAsset: 'assets/icons/nav/bill.png',
                            label: 'Invoices',
                            isActive: currentIndex == 1,
                            onTap: () => GoRouter.of(context).go('/history'),
                          ),
                        ),

                        // 3. Clients
                        Expanded(
                          child: _NavItem(
                            iconAsset: 'assets/icons/nav/rating.png',
                            label: 'Clients',
                            isActive: currentIndex == 2,
                            onTap: () => GoRouter.of(context).go('/clients-tab'),
                          ),
                        ),

                        // 4. Stats / Expenses
                        Expanded(
                          child: _NavItem(
                            iconAsset: 'assets/icons/nav/graph.png',
                            label: 'Stats',
                            isActive: currentIndex == 3,
                            onTap: () => GoRouter.of(context).go('/expenses'),
                          ),
                        ),

                        // 5. Settings
                        Expanded(
                          child: _NavItem(
                            iconAsset: 'assets/icons/nav/settings.png',
                            label: 'Settings',
                            isActive: currentIndex == 4,
                            onTap: () => GoRouter.of(context).go('/profile'),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String iconAsset;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.iconAsset,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool reducedMotion = AppMotion.isReducedMotion(context);
    final itemColor = isActive ? Colors.white : Colors.white.withValues(alpha: 0.65);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isActive ? 1.08 : 1.0,
              duration: reducedMotion ? Duration.zero : AppMotion.iconTransition,
              curve: AppMotion.subtleSpring,
              child: AnimatedOpacity(
                duration: reducedMotion ? Duration.zero : AppMotion.iconState,
                opacity: isActive ? 1.0 : 0.65,
                child: Image.asset(
                  iconAsset,
                  width: 21,
                  height: 21,
                  color: Colors.white,
                  colorBlendMode: BlendMode.srcIn,
                  semanticLabel: label,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: AnimatedDefaultTextStyle(
                duration: reducedMotion ? Duration.zero : AppMotion.standard,
                curve: AppMotion.stateChange,
                style: TextStyle(
                  color: itemColor,
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: -0.2,
                ),
                child: Text(label),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
