import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../core/theme/theme_helper.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/subscription_provider.dart';
import '../screens/create_invoice_screen.dart';
import 'inka_brand_logo.dart';

class WebSidebar extends ConsumerWidget {
  final String currentLocation;
  final int currentIndex;

  const WebSidebar({
    super.key,
    required this.currentLocation,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final profile = ref.watch(profileProvider);
    final subState = ref.watch(subscriptionProvider);
    final user = authState.value;

    final String displayName = profile.businessName.isNotEmpty
        ? profile.businessName
        : (user?.displayName ?? user?.email?.split('@').first ?? 'saravana');
    final String email = user?.email ?? profile.email;

    final String initials = displayName.trim().isNotEmpty
        ? (displayName.trim().length >= 2
            ? displayName.trim().substring(0, 2).toUpperCase()
            : displayName.trim()[0].toUpperCase())
        : 'SA';

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: context.cardBg,
        border: Border(
          right: BorderSide(color: context.cardBorder, width: 1.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Inka App Brand & Plan Pill ──
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 16, 12),
            child: Row(
              children: [
                const InkaBrandLogo(fontSize: 22),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.accentOrange],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    subState.isProOrHigher ? 'PRO' : 'FREE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── 2. Workspace User / Business Row ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.iconBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.35), width: 1),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      displayName.toLowerCase(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => CreateInvoiceScreen.showAsBottomSheet(context),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Icon(Icons.add_rounded, size: 14, color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── 3. Search Box with Quick Add ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 9),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.search_rounded, size: 15, color: Color(0xFF94A3B8)),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Search by title or to...',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => CreateInvoiceScreen.showAsBottomSheet(context),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.accentOrange],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.28),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── 4. Primary Navigation ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                _AppSidebarItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Home',
                  isActive: currentLocation.startsWith('/dashboard'),
                  onTap: () => context.go('/dashboard'),
                ),
                _AppSidebarItem(
                  icon: Icons.star_outline_rounded,
                  activeIcon: Icons.star_rounded,
                  label: 'Starred',
                  isActive: currentLocation.startsWith('/history') || currentLocation.startsWith('/preview'),
                  onTap: () => context.go('/history'),
                ),
                _AppSidebarItem(
                  icon: Icons.grid_view_outlined,
                  activeIcon: Icons.grid_view_rounded,
                  label: 'Browse',
                  isActive: currentLocation.startsWith('/projects') ||
                      currentLocation.startsWith('/add-project') ||
                      currentLocation.startsWith('/edit-project') ||
                      currentLocation.startsWith('/project-details'),
                  onTap: () => context.go('/projects'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── 5. Spaces Section Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 16, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Spaces',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.4,
                  ),
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => CreateInvoiceScreen.showAsBottomSheet(context),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.iconBg,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Icon(Icons.add_rounded, size: 13, color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  _AppSidebarItem(
                    icon: Icons.receipt_long_outlined,
                    activeIcon: Icons.receipt_long_rounded,
                    label: 'Invoices',
                    isActive: currentLocation.startsWith('/history'),
                    onTap: () => context.go('/history'),
                  ),
                  _AppSidebarItem(
                    icon: Icons.people_outline_rounded,
                    activeIcon: Icons.people_alt_rounded,
                    label: 'Clients',
                    isActive: currentLocation.startsWith('/clients-tab') ||
                        currentLocation.startsWith('/clients') ||
                        currentLocation.startsWith('/client-details'),
                    onTap: () => context.go('/clients-tab'),
                  ),
                  _AppSidebarItem(
                    icon: Icons.inventory_2_outlined,
                    activeIcon: Icons.inventory_2_rounded,
                    label: 'Products',
                    isActive: currentLocation.startsWith('/products'),
                    onTap: () => context.go('/products'),
                  ),
                  _AppSidebarItem(
                    icon: Icons.bar_chart_rounded,
                    activeIcon: Icons.bar_chart_rounded,
                    label: 'Expenses & Stats',
                    isActive: currentLocation.startsWith('/expenses'),
                    onTap: () => context.go('/expenses'),
                  ),
                  _AppSidebarItem(
                    icon: Icons.settings_outlined,
                    activeIcon: Icons.settings_rounded,
                    label: 'Settings',
                    isActive: currentLocation.startsWith('/profile') ||
                        currentLocation.startsWith('/company-details') ||
                        currentLocation.startsWith('/bank-details') ||
                        currentLocation.startsWith('/signatures') ||
                        currentLocation.startsWith('/document-settings') ||
                        currentLocation.startsWith('/templates') ||
                        currentLocation.startsWith('/notes-terms') ||
                        currentLocation.startsWith('/currency-settings') ||
                        currentLocation.startsWith('/language-settings') ||
                        currentLocation.startsWith('/subscription') ||
                        currentLocation.startsWith('/help-support') ||
                        currentLocation.startsWith('/privacy-policy'),
                    onTap: () => context.go('/profile'),
                  ),
                ],
              ),
            ),
          ),

          // ── 6. Bottom User Footer ──
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: context.cardBorder, width: 1),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.go('/profile'),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.iconBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.35), width: 1),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                           color: AppColors.primary,
                           fontWeight: FontWeight.w800,
                           fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        email.isNotEmpty ? email : (subState.isProOrHigher ? 'Pro plan' : 'Free plan'),
                        style: TextStyle(
                          fontSize: 10.5,
                          color: context.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.logout_rounded, size: 18, color: context.textMuted),
                  tooltip: 'Sign Out',
                  splashRadius: 16,
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
                        content: const Text('Are you sure you want to sign out?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Sign Out', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ref.read(authProvider.notifier).signOut();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppSidebarItem extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _AppSidebarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_AppSidebarItem> createState() => _AppSidebarItemState();
}

class _AppSidebarItemState extends State<_AppSidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isActive;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7.5),
            decoration: BoxDecoration(
              color: active
                  ? AppColors.primary.withValues(alpha: 0.10)
                  : (_isHovered ? const Color(0xFFF8FAFC) : Colors.transparent),
              borderRadius: BorderRadius.circular(9),
              border: active
                  ? Border.all(color: AppColors.primary.withValues(alpha: 0.22), width: 0.8)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  active ? widget.activeIcon : widget.icon,
                  size: 17,
                  color: active
                      ? AppColors.primary
                      : (_isHovered ? AppColors.textPrimary : const Color(0xFF64748B)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active
                          ? AppColors.primary
                          : (_isHovered ? AppColors.textPrimary : const Color(0xFF475569)),
                    ),
                  ),
                ),
                if (active)
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
