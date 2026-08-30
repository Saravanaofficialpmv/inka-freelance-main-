import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inka/core/constants/colors.dart';
import '../../core/localization/app_localizations.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  const CustomBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A).withValues(alpha: 0.95), // Solid dark translucent pill
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavItem(
            icon: Icons.home_filled,
            label: AppLocalizations.of(context)?.translate('dashboard') ?? 'Dashboard',
            isActive: currentIndex == 0,
            onTap: () => GoRouter.of(context).go('/dashboard'),
          ),
          _NavItem(
            icon: Icons.history_rounded,
            label: AppLocalizations.of(context)?.translate('history') ?? 'History',
            isActive: currentIndex == 1,
            onTap: () => GoRouter.of(context).go('/history'),
          ),
          _NavItem(
            icon: Icons.add_circle_outline_rounded,
            label: AppLocalizations.of(context)?.translate('create') ?? 'Create',
            isActive: currentIndex == 2,
            onTap: () => GoRouter.of(context).go('/create-invoice'),
          ),
          _NavItem(
            icon: Icons.person_outline_rounded,
            label: AppLocalizations.of(context)?.translate('profile') ?? 'Profile',
            isActive: currentIndex == 3,
            onTap: () => GoRouter.of(context).go('/profile'),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : Colors.white60,
              size: 22,
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


