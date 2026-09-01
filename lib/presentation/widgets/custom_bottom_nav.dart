import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  const CustomBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(28, 0, 28, 24),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFF9BD71B).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Home
          _NavItem(
            icon: Icons.home_rounded,
            isActive: currentIndex == 0,
            onTap: () => GoRouter.of(context).go('/dashboard'),
          ),
          // Invoices
          _NavItem(
            icon: Icons.description_outlined,
            isActive: currentIndex == 1,
            onTap: () => GoRouter.of(context).go('/history'),
          ),
          // Clients
          _NavItem(
            icon: Icons.people_outline_rounded,
            isActive: currentIndex == 2,
            onTap: () => GoRouter.of(context).go('/clients-tab'),
          ),
          // Expenses / Wallet
          _NavItem(
            icon: Icons.account_balance_wallet_outlined,
            isActive: currentIndex == 3,
            onTap: () => GoRouter.of(context).go('/expenses'),
          ),
          // Settings (Profile)
          _NavItem(
            icon: Icons.settings_outlined,
            isActive: currentIndex == 4,
            onTap: () => GoRouter.of(context).go('/profile'),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0D3B3E) : Colors.transparent, // Dark Teal active circle from mockup
          shape: BoxShape.circle,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF0D3B3E).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Icon(
            icon,
            color: isActive ? Colors.white : const Color(0xFF64748B),
            size: 22,
          ),
        ),
      ),
    );
  }
}
