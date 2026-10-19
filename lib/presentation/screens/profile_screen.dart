import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/subscription_provider.dart';
import '../widgets/tibsy_refresh_icon.dart';
import '../../core/constants/colors.dart';
import '../../core/theme/theme_helper.dart';
import '../../data/models/business_profile.dart';
import '../../services/currency_tax_service.dart';
import '../providers/template_config_provider.dart';
import '../../features/invoices/templates/invoice_template_registry.dart';
import '../../core/localization/app_localizations.dart';

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
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    if (isWide) {
      return Material(
        color: const Color(0xFFF7F8FA),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
          physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildHeaderAvatar(context, user, businessProfile, displayName),
                      const SizedBox(width: 16),
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
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.email ?? 'Free User Account',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: (subscription.isPro ? AppColors.primary : const Color(0xFF64748B)).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: (subscription.isPro ? AppColors.primary : const Color(0xFF64748B)).withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          subscription.isPro ? 'Pro Active' : 'Free Plan',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: subscription.isPro ? AppColors.primary : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildProfileCards(context, ref, businessProfile, subscription, displayName),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Top Header Row (Avatar, Name, Bell, More Menu) ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
              child: Row(
                children: [
                  _buildHeaderAvatar(context, user, businessProfile, displayName),
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
                ],
              ),
            ),

            // ── Scrollable Body with Pull to Refresh ──
            Expanded(
              child: TibsyPullToRefresh(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 120),
                onRefresh: () => syncAndRefreshEntireApp(ref),
                child: _buildProfileCards(context, ref, businessProfile, subscription, displayName),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCards(
    BuildContext context,
    WidgetRef ref,
    BusinessProfile businessProfile,
    UserSubscriptionState subscription,
    String displayName,
  ) {
    final templateConfig = ref.watch(templateConfigProvider);
    final selectedTemplate = InvoiceTemplateRegistry.getTemplate(templateConfig.templateId);

    return Column(
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
              color: context.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: context.isDarkMode ? 0.25 : 0.03),
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
                          Text(
                            'Profile Completed',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimary,
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
                            onTap: () => context.go('/bank-details'),
                          ),
                        if (missingAddress)
                          _ActionChip(
                            label: '+ Address',
                            onTap: () => context.go('/company-details'),
                          ),
                        if (missingSignature)
                          _ActionChip(
                            label: '+ Signature',
                            onTap: () => context.go('/signatures'),
                          ),
                        if (missingCompany)
                          _ActionChip(
                            label: '+ Company',
                            onTap: () => context.go('/company-details'),
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
              icon: Icons.business_outlined,
              title: 'Company Details',
              subtitle: businessProfile.businessName.isNotEmpty
                  ? businessProfile.businessName
                  : 'Set up company name, address & tax info',
              onTap: () => context.go('/company-details'),
            ),
            _SettingsTile(
              icon: Icons.account_balance_outlined,
              title: 'Bank & UPI Details',
              subtitle: (businessProfile.accountNo != null && businessProfile.accountNo!.isNotEmpty)
                  ? 'A/C: ****${businessProfile.accountNo!.length >= 4 ? businessProfile.accountNo!.substring(businessProfile.accountNo!.length - 4) : businessProfile.accountNo}'
                  : (businessProfile.upiId != null && businessProfile.upiId!.isNotEmpty)
                      ? 'UPI: ${businessProfile.upiId}'
                      : 'Add bank account and UPI QR code',
              onTap: () => context.go('/bank-details'),
            ),
            _SettingsTile(
              icon: Icons.draw_outlined,
              title: 'Signatures & Stamps',
              subtitle: (businessProfile.signatureUrl != null && businessProfile.signatureUrl!.isNotEmpty)
                  ? 'Digital signature configured'
                  : 'Draw or upload authorized signature',
              isLast: true,
              onTap: () => context.go('/signatures'),
            ),
          ],
        ),

        // ── 2. Section: Invoice Settings ──
        const _SectionHeader(title: 'Invoice Settings'),
        _SectionCard(
          children: [
            _SettingsTile(
              icon: Icons.tune_outlined,
              title: 'Document Settings',
              subtitle: 'Tax (${businessProfile.taxLabel.isNotEmpty ? businessProfile.taxLabel : "GST"} ${businessProfile.defaultTaxRate.toStringAsFixed(0)}%) & Currency (${businessProfile.currency.isNotEmpty ? businessProfile.currency : "USD"})',
              onTap: () => context.go('/document-settings'),
            ),
            _SettingsTile(
              icon: Icons.palette_outlined,
              title: 'Invoice Templates',
              subtitle: '${AppLocalizations.of(context)?.translate('invoice_appearance_desc') ?? "Customize how your invoices look"} • ${selectedTemplate.name}',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24,
                    height: 32,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFCBD5E1), width: 0.8),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      selectedTemplate.assetPreview,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      AppLocalizations.of(context)?.translate('change_template') ?? 'Change',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: context.textMuted, size: 20),
                ],
              ),
              onTap: () => context.go('/templates'),
            ),
            _SettingsTile(
              icon: Icons.description_outlined,
              title: 'Notes & Terms',
              subtitle: 'Default payment terms and notes',
              onTap: () => context.go('/notes-terms'),
            ),
            _SettingsTile(
              icon: Icons.inventory_2_outlined,
              title: 'Product Catalog',
              subtitle: 'Manage items, inventory & pricing',
              isLast: true,
              onTap: () => context.go('/products'),
            ),
          ],
        ),

        // ── 3. Section: Preferences & Subscription ──
        const _SectionHeader(title: 'Preferences'),
        _SectionCard(
          children: [
            _SettingsTile(
              icon: Icons.monetization_on_outlined,
              title: 'Currency',
              subtitle: '${CurrencyTaxService.findCurrency(businessProfile.currency).name} (${CurrencyTaxService.findCurrency(businessProfile.currency).symbol})',
              onTap: () => context.go('/currency-settings'),
            ),
            _SettingsTile(
              icon: Icons.translate_rounded,
              title: 'Language',
              subtitle: 'English, Tamil, Hindi, Spanish',
              onTap: () => context.go('/language-settings'),
            ),
            _SettingsTile(
              icon: Icons.workspace_premium_outlined,
              title: 'Subscription Plans',
              subtitle: subscription.isPro ? 'Inka Pro Active' : 'Explore Pro & Subscription Plans',
              badge: subscription.isPro ? _BadgeType.pro : null,
              isLast: true,
              onTap: () => context.go('/subscription'),
            ),
          ],
        ),

        // ── 4. Section: Support & Legal ──
        const _SectionHeader(title: 'Support & Legal'),
        _SectionCard(
          children: [
            _SettingsTile(
              icon: Icons.support_agent_outlined,
              title: 'Help & Support',
              subtitle: 'Contact via WhatsApp & Email',
              onTap: () => context.go('/help-support'),
            ),
            _SettingsTile(
              icon: Icons.shield_outlined,
              title: 'Privacy Policy',
              subtitle: 'Data protection and security',
              onTap: () => context.go('/privacy-policy'),
            ),
            _SettingsTile(
              icon: Icons.logout_rounded,
              title: 'Logout',
              subtitle: 'Sign out of your account',
              onTap: () => _showLogoutConfirmDialog(context, ref),
            ),
            _SettingsTile(
              icon: Icons.delete_forever_outlined,
              iconColor: AppColors.error,
              titleColor: AppColors.error,
              title: 'Delete Account',
              subtitle: 'Permanently delete account and all data',
              isLast: true,
              onTap: () => _showDeleteAccountDialog(
                context,
                ref,
                businessProfile.businessName.trim().isNotEmpty
                    ? businessProfile.businessName.trim()
                    : displayName,
              ),
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
    );
  }

  // ── Authentic Modal Sheets & Dialogs ──

  void _showLogoutConfirmDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        content: const Text(
          'Are you sure you want to sign out? Your offline data remains securely stored on this device.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogCtx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) {
                context.go('/auth');
              }
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(
    BuildContext context,
    WidgetRef ref,
    String requiredConfirmationName,
  ) {
    final expected = requiredConfirmationName.trim();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        String enteredName = '';
        bool isDeleting = false;
        String? errorMessage;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final matches = enteredName.trim().toLowerCase() == expected.toLowerCase();

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              title: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_forever_rounded,
                      color: AppColors.error,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Delete Account',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'This action is permanent and cannot be undone. All your business records, invoices, clients, products, expenses, and signatures will be completely deleted from our database and this device.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Please enter your business name to confirm:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF991B1B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            expected,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF7F1D1D),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      key: const ValueKey('delete_account_confirm_field'),
                      enabled: !isDeleting,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Enter "$expected"',
                        hintStyle: TextStyle(
                          color: AppColors.textMuted.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.cardBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: matches ? AppColors.success : AppColors.error,
                            width: 1.5,
                          ),
                        ),
                        suffixIcon: matches
                            ? const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20)
                            : null,
                      ),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      onChanged: (val) {
                        setDialogState(() {
                          enteredName = val;
                          errorMessage = null;
                        });
                      },
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        errorMessage!,
                        style: const TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.of(dialogCtx).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                  ),
                ),
                ElevatedButton(
                  key: const ValueKey('delete_account_confirm_btn'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    disabledBackgroundColor: AppColors.error.withValues(alpha: 0.35),
                    elevation: matches && !isDeleting ? 2 : 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: (matches && !isDeleting)
                      ? () async {
                          setDialogState(() {
                            isDeleting = true;
                            errorMessage = null;
                          });
                          try {
                            await ref.read(authProvider.notifier).deleteAccount();
                            if (dialogCtx.mounted) {
                              Navigator.of(dialogCtx).pop();
                            }
                            if (context.mounted) {
                              context.go('/auth');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Your account and all business records have been permanently deleted.'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          } catch (e) {
                            if (dialogCtx.mounted) {
                              setDialogState(() {
                                isDeleting = false;
                                errorMessage = e.toString().replaceFirst('Exception: ', '');
                              });
                            }
                          }
                        }
                      : null,
                  child: isDeleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Permanently Delete',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildHeaderAvatar(
    BuildContext context,
    User? user,
    BusinessProfile businessProfile,
    String displayName,
  ) {
    return GestureDetector(
      onTap: () => context.go('/company-details'),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: _buildAvatarImage(user, businessProfile, displayName),
      ),
    );
  }

  Widget _buildAvatarImage(
    User? user,
    BusinessProfile businessProfile,
    String displayName,
  ) {
    // 1. Business logo (uploaded in Company Details or Onboarding setup)
    final logo = businessProfile.logoUrl?.trim();
    if (logo != null && logo.isNotEmpty) {
      if (logo.startsWith('http://') || logo.startsWith('https://')) {
        return Image.network(
          logo,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildUserPhotoOrInitial(user, businessProfile, displayName),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return _buildInitial(businessProfile, displayName);
          },
        );
      } else if (!kIsWeb) {
        try {
          final file = File(logo);
          if (file.existsSync()) {
            return Image.file(
              file,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildUserPhotoOrInitial(user, businessProfile, displayName),
            );
          }
        } catch (_) {}
      }
    }

    // 2. User profile photo (Google / Firebase Auth)
    return _buildUserPhotoOrInitial(user, businessProfile, displayName);
  }

  Widget _buildUserPhotoOrInitial(
    User? user,
    BusinessProfile businessProfile,
    String displayName,
  ) {
    final photo = user?.photoURL?.trim();
    if (photo != null && photo.isNotEmpty) {
      return Image.network(
        photo,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildInitial(businessProfile, displayName),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _buildInitial(businessProfile, displayName);
        },
      );
    }
    return _buildInitial(businessProfile, displayName);
  }

  Widget _buildInitial(BusinessProfile businessProfile, String displayName) {
    final initial = (businessProfile.businessName.isNotEmpty
            ? businessProfile.businessName[0]
            : (displayName.isNotEmpty ? displayName[0] : 'U'))
        .toUpperCase();
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: AppColors.primary,
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
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: context.textPrimary,
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
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDarkMode ? 0.25 : 0.02),
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
  final IconData? icon;
  final String title;
  final String? subtitle;
  final _BadgeType? badge;
  final bool isLast;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? titleColor;
  final Widget? trailing;

  const _SettingsTile({
    this.icon,
    required this.title,
    this.subtitle,
    this.badge,
    this.isLast = false,
    this.onTap,
    this.iconColor,
    this.titleColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? (context.isDarkMode ? const Color(0xFFCBD5E1) : const Color(0xFF1E293B));
    final leadingWidget = Icon(icon ?? Icons.circle_outlined, color: effectiveIconColor, size: 22);

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: ListTile(
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
                    color: titleColor ?? context.textPrimary,
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
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textSecondary,
                  ),
                )
              : null,
          trailing: trailing ?? Icon(Icons.chevron_right, color: context.textMuted, size: 20),
        ),
      ),
        if (!isLast) Divider(height: 1, indent: 58, endIndent: 16, color: context.cardBorder),
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

