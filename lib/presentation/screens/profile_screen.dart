import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../../core/localization/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../providers/subscription_provider.dart';
import '../widgets/tibsy_refresh_icon.dart';
import '../../core/constants/colors.dart';

enum _BadgeType { pro, advanced, beta, newItem }

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.value;
    final displayName = user?.email?.split('@').first ?? 'User';
    final businessProfile = ref.watch(profileProvider);
    final subscription = ref.watch(subscriptionProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Top Header Row (Avatar, Name, Bell, More Menu) ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        (businessProfile.businessName.isNotEmpty
                                ? businessProfile.businessName[0]
                                : displayName[0])
                            .toUpperCase(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          businessProfile.businessName.isNotEmpty
                              ? businessProfile.businessName
                              : displayName,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user?.email ?? 'Free User Account',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary, size: 24),
                    tooltip: 'Notifications',
                    onPressed: () => _showNotificationsDialog(context),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, color: AppColors.textPrimary, size: 22),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onSelected: (val) {
                      if (val == 'about') _showAdvancedSettings(context);
                      if (val == 'logout') _showLogoutConfirmDialog(context, ref);
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'about',
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded, size: 20, color: AppColors.textSecondary),
                            SizedBox(width: 12),
                            Text('About App', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout_rounded, size: 20, color: AppColors.error),
                            SizedBox(width: 12),
                            Text('Logout', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.error)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Scrollable Body with Pull to Refresh ──
            Expanded(
              child: TibsyPullToRefresh(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 120),
                onRefresh: () => syncAndRefreshEntireApp(ref),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Profile Completed Card ──
                    Builder(builder: (context) {
                      int score = 20;
                      if (businessProfile.businessName.isNotEmpty) score += 20;
                      if (businessProfile.address.isNotEmpty) score += 20;
                      if ((businessProfile.accountNo != null && businessProfile.accountNo!.isNotEmpty) ||
                          (businessProfile.upiId != null && businessProfile.upiId!.isNotEmpty)) {
                        score += 20;
                      }
                      if (businessProfile.signatureUrl != null && businessProfile.signatureUrl!.isNotEmpty) {
                        score += 20;
                      }
                      if (score > 100) score = 100;

                      final missingBank = (businessProfile.accountNo == null || businessProfile.accountNo!.isEmpty) &&
                          (businessProfile.upiId == null || businessProfile.upiId!.isEmpty);
                      final missingAddress = businessProfile.address.isEmpty;
                      final missingSignature = businessProfile.signatureUrl == null || businessProfile.signatureUrl!.isEmpty;
                      final missingCompany = businessProfile.businessName.isEmpty;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.cardBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Profile Completed',
                                        style: TextStyle(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        score == 100
                                            ? 'Great job! Your profile is 100% complete.'
                                            : 'Complete your pending action(s) to reach 100%',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '$score%',
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: score / 100,
                                backgroundColor: const Color(0xFFF1F5F9),
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                                minHeight: 6,
                              ),
                            ),
                            if (score < 100) ...[
                              const SizedBox(height: 12),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    if (missingBank)
                                      _ActionChip(
                                        label: '+ Bank',
                                        onTap: () => context.push('/bank-details'),
                                      ),
                                    if (missingAddress)
                                      _ActionChip(
                                        label: '+ Address',
                                        onTap: () => context.push('/company-details'),
                                      ),
                                    if (missingSignature)
                                      _ActionChip(
                                        label: '+ Signature',
                                        onTap: () => context.push('/signatures'),
                                      ),
                                    if (missingCompany)
                                      _ActionChip(
                                        label: '+ Company',
                                        onTap: () => context.push('/company-details'),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),

                    // ── 1. Section: Profile & Company ──
                    const _SectionHeader(title: 'Profile'),
                    _SectionCard(
                      children: [
                        _SettingsTile(
                          iconAsset: 'profilepage_icon/building.png',
                          title: 'Company Details',
                          subtitle: businessProfile.businessName.isNotEmpty
                              ? businessProfile.businessName
                              : 'Set up company name, address & tax info',
                          onTap: () => context.push('/company-details'),
                        ),
                        _SettingsTile(
                          iconAsset: 'profilepage_icon/bank-2.png',
                          title: 'Bank & UPI Details',
                          subtitle: (businessProfile.accountNo != null && businessProfile.accountNo!.isNotEmpty)
                              ? 'A/C: ****${businessProfile.accountNo!.length >= 4 ? businessProfile.accountNo!.substring(businessProfile.accountNo!.length - 4) : businessProfile.accountNo}'
                              : (businessProfile.upiId != null && businessProfile.upiId!.isNotEmpty)
                                  ? 'UPI: ${businessProfile.upiId}'
                                  : 'Add bank account and UPI QR code',
                          onTap: () => context.push('/bank-details'),
                        ),
                        _SettingsTile(
                          iconAsset: 'profilepage_icon/digital-signature.png',
                          title: 'Signatures & Stamps',
                          subtitle: (businessProfile.signatureUrl != null && businessProfile.signatureUrl!.isNotEmpty)
                              ? 'Digital signature configured'
                              : 'Draw or upload authorized signature',
                          isLast: true,
                          onTap: () => context.push('/signatures'),
                        ),
                      ],
                    ),

                    // ── 2. Section: Invoice Settings ──
                    const _SectionHeader(title: 'Invoice Settings'),
                    _SectionCard(
                      children: [
                        _SettingsTile(
                          iconAsset: 'profilepage_icon/tax-free.png',
                          title: 'Document Settings',
                          subtitle: 'Tax (${businessProfile.taxLabel.isNotEmpty ? businessProfile.taxLabel : "GST"} ${businessProfile.defaultTaxRate.toStringAsFixed(0)}%) & Currency (${businessProfile.currency})',
                          onTap: () => context.push('/document-settings'),
                        ),
                        _SettingsTile(
                          iconAsset: 'profilepage_icon/paper.png',
                          title: 'Invoice Templates',
                          subtitle: '14 professional layout designs',
                          onTap: () => context.push('/templates'),
                        ),
                        _SettingsTile(
                          icon: Icons.menu_book_outlined,
                          title: 'Notes & Terms',
                          subtitle: 'Default payment terms and notes',
                          onTap: () => context.push('/notes-terms'),
                        ),
                        _SettingsTile(
                          iconAsset: 'profilepage_icon/inventory.png',
                          title: 'Product Catalog',
                          subtitle: 'Manage items, inventory & pricing',
                          isLast: true,
                          onTap: () => context.push('/products'),
                        ),
                      ],
                    ),

                    // ── 3. Section: Preferences & Subscription ──
                    const _SectionHeader(title: 'Preferences'),
                    _SectionCard(
                      children: [
                        _SettingsTile(
                          iconAsset: 'profilepage_icon/language.png',
                          title: 'Language',
                          subtitle: languages
                              .firstWhere(
                                (l) => l.code == ref.watch(localeProvider).languageCode,
                                orElse: () => languages.first,
                              )
                              .name,
                          onTap: () => context.push('/language-settings'),
                        ),
                        _SettingsTile(
                          iconAsset: 'profilepage_icon/insurance.png',
                          title: 'Subscription Plans',
                          subtitle: subscription.isPro ? 'Inka Pro Active' : 'Explore Pro & Subscription Plans',
                          badge: subscription.isPro ? _BadgeType.pro : null,
                          isLast: true,
                          onTap: () => context.push('/subscription'),
                        ),
                      ],
                    ),

                    // ── 4. Section: Support & Legal ──
                    const _SectionHeader(title: 'Support & Legal'),
                    _SectionCard(
                      children: [
                        _SettingsTile(
                          iconAsset: 'profilepage_icon/handshake.png',
                          title: 'Help & Support',
                          subtitle: 'Contact via WhatsApp & Email',
                          onTap: () => context.push('/help-support'),
                        ),
                        _SettingsTile(
                          iconAsset: 'profilepage_icon/policy-privacy.png',
                          title: 'Privacy Policy',
                          subtitle: 'Data protection and security',
                          onTap: () => context.push('/privacy-policy'),
                        ),
                        _SettingsTile(
                          iconAsset: 'profilepage_icon/exit.png',
                          iconColor: AppColors.error,
                          titleColor: AppColors.error,
                          title: 'Logout',
                          subtitle: 'Sign out of your account',
                          isLast: true,
                          onTap: () => _showLogoutConfirmDialog(context, ref),
                        ),
                      ],
                    ),

                    // ── 5. Footer Branding ──
                    const SizedBox(height: 28),
                    Center(
                      child: Column(
                        children: [
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'inka',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              SizedBox(width: 6),
                              Text('🇮🇳', style: TextStyle(fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'App Version: 1.0.0',
                            style: TextStyle(fontSize: 12.5, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Authentic Modal Sheets & Dialogs ──

  void _showNotificationsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 12),
            const _NotificationItem(
              icon: Icons.cloud_done_rounded,
              color: AppColors.success,
              title: 'Offline Sync Active',
              subtitle: 'All local invoices and expenses are safely synchronized.',
              time: 'Just now',
            ),
            const _NotificationItem(
              icon: Icons.verified_user_rounded,
              color: AppColors.primary,
              title: 'Security Verified',
              subtitle: 'Bank and business details encrypted and stored securely.',
              time: 'Protected',
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        content: const Text(
          'Are you sure you want to sign out? Your offline data remains securely stored on this device.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) context.go('/auth');
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }


  void _showAdvancedSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context)?.translate('advanced_settings') ?? 'Advanced Settings',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.info_outline, color: AppColors.textPrimary),
              title: Text(
                AppLocalizations.of(context)?.translate('about_app') ?? 'About App',
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: const Text('Inka', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                    content: Text(
                      '${AppLocalizations.of(context)?.translate('version') ?? 'Version'} 1.0.0\nCreated using Flutter.',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          AppLocalizations.of(context)?.translate('close') ?? 'Close',
                          style: const TextStyle(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: AppColors.error),
              title: Text(
                AppLocalizations.of(context)?.translate('delete_account') ?? 'Delete Account',
                style: const TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)?.translate('contact_support_delete') ??
                          'Contact support to delete account.',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

}

// ── Reusable Component Widgets ──

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 18),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String? iconAsset;
  final IconData? icon;
  final String title;
  final String? subtitle;
  final _BadgeType? badge;
  final bool isLast;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? titleColor;

  const _SettingsTile({
    this.iconAsset,
    this.icon,
    required this.title,
    this.subtitle,
    this.badge,
    this.isLast = false,
    this.onTap,
    this.iconColor,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? const Color(0xFF1E293B);

    Widget leadingWidget;
    if (iconAsset != null) {
      leadingWidget = SizedBox(
        width: 26,
        height: 26,
        child: Center(
          child: Image.asset(
            iconAsset!,
            width: 22,
            height: 22,
            color: effectiveIconColor,
            colorBlendMode: BlendMode.srcIn,
            semanticLabel: title,
            filterQuality: FilterQuality.medium,
          ),
        ),
      );
    } else {
      leadingWidget = Icon(icon ?? Icons.circle, color: effectiveIconColor, size: 22);
    }

    return Column(
      children: [
        ListTile(
          onTap: onTap,
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: leadingWidget,
          title: Row(
            children: [
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5,
                    color: titleColor ?? AppColors.textPrimary,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                _BadgeWidget(type: badge!),
              ],
            ],
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                )
              : null,
          trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
        ),
        if (!isLast) const Divider(height: 1, indent: 58, endIndent: 16, color: Color(0xFFF1F5F9)),
      ],
    );
  }
}

class _BadgeWidget extends StatelessWidget {
  final _BadgeType type;
  const _BadgeWidget({required this.type});

  @override
  Widget build(BuildContext context) {
    Color bg;
    String label;

    switch (type) {
      case _BadgeType.newItem:
        bg = AppColors.primary;
        label = 'NEW';
        break;
      case _BadgeType.beta:
        bg = const Color(0xFF2563EB);
        label = 'BETA';
        break;
      case _BadgeType.pro:
        bg = AppColors.primary;
        label = 'PRO';
        break;
      case _BadgeType.advanced:
        bg = AppColors.warning;
        label = 'ADVANCED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ActionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String time;

  const _NotificationItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                    Text(time, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
