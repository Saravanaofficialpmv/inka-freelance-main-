import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../viewmodels/invoice_viewmodel.dart';
import '../providers/profile_provider.dart';
import '../../data/models/business_profile.dart';
import '../../core/localization/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../providers/subscription_provider.dart';
import '../widgets/currency_tax_sheet.dart';
import '../widgets/payment_qr_sheet.dart';
import '../../services/currency_tax_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.value;
    final displayName = user?.email?.split('@').first ?? 'User';
    final businessProfile = ref.watch(profileProvider);
    final invoices = ref.watch(invoiceProvider);
    final totalInvoices = invoices.length;
    final totalRevenue = invoices.fold(0.0, (sum, item) => sum + item.total);
    final subscription = ref.watch(subscriptionProvider);
    final currencyFormat = CurrencyTaxService.getCurrencyFormatter(currencyCode: businessProfile.currency, decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)?.translate('profile') ?? 'Profile',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                    GestureDetector(
                      onTap: () => _showAdvancedSettings(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.more_horiz, color: Color(0xFF0F172A), size: 20),
                      ),
                    )
                  ],
                ),
              ),
            ),

            // ── Business Profile Card ──
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: const Color(0xFFFFECE8),
                            child: Text(
                              (businessProfile.businessName.isNotEmpty ? businessProfile.businessName[0] : displayName[0]).toUpperCase(),
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFFF5722)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  businessProfile.businessName.isNotEmpty ? businessProfile.businessName : 'Set Business Name',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                ),
                                Text(
                                  user?.email ?? 'Free User Account',
                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _showEditBusinessDialog(context, ref, businessProfile),
                            icon: const Icon(Icons.edit_note, color: Color(0xFFFF5722), size: 28),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(color: Color(0xFFE2E8F0)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(label: 'Total Rev', value: currencyFormat.format(totalRevenue)),
                          _StatItem(label: 'Invoices', value: '$totalInvoices'),
                          GestureDetector(
                            onTap: () => context.push('/subscription'),
                            child: _StatItem(
                              label: 'Plan',
                              value: subscription.plan.name,
                              color: const Color(0xFFFF5722),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),

            // ── Main Options ──
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Subscription & Pricing Plans Tile
                      _ProfileTile(
                        icon: Icons.workspace_premium_rounded,
                        title: 'Plan: ${subscription.plan.name} (${subscription.plan.badge})',
                        subtitle: subscription.isFree
                            ? 'Tap to explore Pro (₹99/mo) & Freelancer Plus'
                            : 'Active subscription • Tap to manage',
                        onTap: () => context.push('/subscription'),
                      ),
                      _ProfileTile(
                        icon: Icons.business_outlined, 
                        title: AppLocalizations.of(context)?.translate('business_settings') ?? 'Business Information', 
                        subtitle: businessProfile.businessName.isNotEmpty ? AppLocalizations.of(context)?.translate('global_settings') ?? 'Global settings for your invoices' : AppLocalizations.of(context)?.translate('setup_business') ?? 'Set up your business profile',
                        onTap: () => _showEditBusinessDialog(context, ref, businessProfile),
                      ),
                      _ProfileTile(
                        icon: Icons.people_outline_rounded, 
                        title: AppLocalizations.of(context)?.translate('clients') ?? 'Clients Directory', 
                        subtitle: 'Manage client contacts and details',
                        onTap: () => context.push('/clients'),
                      ),
                      _ProfileTile(
                        icon: Icons.inventory_2_outlined, 
                        title: AppLocalizations.of(context)?.translate('product_catalog') ?? 'Services & Catalog', 
                        subtitle: AppLocalizations.of(context)?.translate('manage_inventory') ?? 'Manage items and services',
                        onTap: () => context.push('/products'),
                      ),
                      _ProfileTile(
                        icon: Icons.account_balance_outlined, 
                        title: AppLocalizations.of(context)?.translate('bank_details') ?? 'Bank & UPI Payments', 
                        subtitle: (businessProfile.upiId != null && businessProfile.upiId!.isNotEmpty)
                            ? 'UPI: ${businessProfile.upiId}'
                            : (businessProfile.accountNo != null && businessProfile.accountNo!.length >= 4)
                                ? 'A/C: ****${businessProfile.accountNo!.substring(businessProfile.accountNo!.length - 4)}'
                                : AppLocalizations.of(context)?.translate('manage_bank') ?? 'Manage bank and UPI QR details',
                        onTap: () => _showEditBankDetailsDialog(context, ref, businessProfile),
                      ),
                      _ProfileTile(
                        icon: Icons.draw_outlined, 
                        title: AppLocalizations.of(context)?.translate('signatures') ?? 'Signatures & Stamps', 
                        subtitle: businessProfile.signatureUrl != null && businessProfile.signatureUrl!.isNotEmpty ? 'Default signature set' : AppLocalizations.of(context)?.translate('manage_signatures') ?? 'Manage your business signatures',
                        onTap: () => _showEditSignaturesDialog(context, ref, businessProfile),
                      ),
                      _ProfileTile(
                        icon: Icons.currency_exchange_rounded, 
                        title: 'Currency (${businessProfile.currency})', 
                        subtitle: 'Change display and invoice currency',
                        onTap: () => CurrencySelectionBottomSheet.show(context, businessProfile),
                      ),
                      _ProfileTile(
                        icon: Icons.percent_rounded, 
                        title: 'Tax & Compliance (${businessProfile.taxLabel})', 
                        subtitle: '${businessProfile.taxLabel} • ${businessProfile.defaultTaxRate}% standard rate',
                        onTap: () => TaxSettingsBottomSheet.show(context, businessProfile),
                      ),
                      _ProfileTile(
                        icon: Icons.language, 
                        title: AppLocalizations.of(context)?.translate('language') ?? 'Language', 
                        subtitle: languages.firstWhere((l) => l.code == ref.watch(localeProvider).languageCode).name, 
                        isLast: true,
                        onTap: () => _showLanguageDialog(context, ref),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Bottom Options ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _ProfileTile(
                        icon: Icons.help_outline, 
                        title: AppLocalizations.of(context)?.translate('help_support') ?? 'Help & Support',
                        onTap: () => _showSupportDialog(context),
                      ),
                      _ProfileTile(
                        icon: Icons.privacy_tip_outlined, 
                        title: AppLocalizations.of(context)?.translate('privacy_policy') ?? 'Privacy Policy',
                        onTap: () => _showPrivacyPolicy(context),
                      ),
                      _ProfileTile(
                        icon: Icons.description_outlined, 
                        title: AppLocalizations.of(context)?.translate('terms_conditions') ?? 'Terms & Conditions',
                        onTap: () => _showTermsDialog(context),
                      ),
                      _ProfileTile(
                        icon: Icons.logout, 
                        title: AppLocalizations.of(context)?.translate('logout') ?? 'Logout', 
                        isLast: true,
                        onTap: () async {
                          await ref.read(authProvider.notifier).signOut();
                          if (context.mounted) context.go('/auth');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Language', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 20),
            ...languages.map((lang) => ListTile(
              leading: Text(lang.flag, style: const TextStyle(fontSize: 24)),
              title: Text(lang.name, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
              trailing: ref.watch(localeProvider).languageCode == lang.code 
                ? const Icon(Icons.check_circle, color: Color(0xFFFF5722)) 
                : null,
              onTap: () {
                ref.read(localeProvider.notifier).setLocale(Locale(lang.code));
                Navigator.pop(ctx);
              },
            )),
            const SizedBox(height: 16),
          ],
        ),
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
            Text(AppLocalizations.of(context)?.translate('advanced_settings') ?? 'Advanced Settings', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Color(0xFF0F172A)),
              title: Text(AppLocalizations.of(context)?.translate('about_app') ?? 'About App', style: const TextStyle(color: Color(0xFF0F172A))),
              onTap: () {
                Navigator.pop(context);
                showDialog(context: context, builder: (_) => AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text('Inka', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
                  content: Text('${AppLocalizations.of(context)?.translate('version') ?? 'Version'} 1.0.0\nCreated using Flutter.', style: const TextStyle(color: Color(0xFF64748B))),
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)?.translate('close') ?? 'Close', style: const TextStyle(color: Color(0xFFFF5722))))],
                ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
              title: Text(AppLocalizations.of(context)?.translate('delete_account') ?? 'Delete Account', style: const TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)?.translate('contact_support_delete') ?? 'Contact support to delete account.')));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(AppLocalizations.of(context)?.translate('help_support') ?? 'Help & Support', style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
      content: const Text('Contact us at: support@inka.com', style: TextStyle(color: Color(0xFF64748B))),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)?.translate('close') ?? 'Close', style: const TextStyle(color: Color(0xFFFF5722))))],
    ));
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(AppLocalizations.of(context)?.translate('privacy_policy') ?? 'Privacy Policy', style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
      content: const Text('Your data is securely synced via our backend.', style: TextStyle(color: Color(0xFF64748B))),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)?.translate('close') ?? 'Close', style: const TextStyle(color: Color(0xFFFF5722))))],
    ));
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(AppLocalizations.of(context)?.translate('terms_conditions') ?? 'Terms & Conditions', style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
      content: const Text('By using Inka, you agree to our standard terms.', style: TextStyle(color: Color(0xFF64748B))),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)?.translate('close') ?? 'Close', style: const TextStyle(color: Color(0xFFFF5722))))],
    ));
  }

  void _showEditSignaturesDialog(BuildContext context, WidgetRef ref, BusinessProfile profile) {
    String? selectedSignPath = profile.signatureUrl;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (stfCtx, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(stfCtx).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppLocalizations.of(context)?.translate('signatures') ?? 'Signatures', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  TextButton.icon(
                    onPressed: () async {
                      try {
                        final picker = ImagePicker();
                        final image = await picker.pickImage(source: ImageSource.gallery);
                        if (image != null) {
                          setModalState(() {
                            selectedSignPath = image.path;
                          });
                        }
                      } catch (e) {
                         debugPrint('Image pick error: $e');
                      }
                    },
                    icon: const Icon(Icons.add, size: 18, color: Color(0xFFFF5722)),
                    label: Text(AppLocalizations.of(context)?.translate('add_new') ?? 'Add New', style: const TextStyle(color: Color(0xFFFF5722), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const Text('Manage your business signatures', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
              const SizedBox(height: 24),
              
              if (selectedSignPath != null && selectedSignPath!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Official Signature', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            SizedBox(height: 4),
                            Text('Active on all invoices', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      Container(
                        width: 100,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: (!kIsWeb && selectedSignPath != null && selectedSignPath!.isNotEmpty && File(selectedSignPath!).existsSync())
                          ? Image.file(File(selectedSignPath!), fit: BoxFit.contain)
                          : const Icon(Icons.draw, color: Colors.grey),
                      ),
                      IconButton(
                        onPressed: () => setModalState(() => selectedSignPath = ''),
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                      ),
                    ],
                  ),
                )
              else
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: const [
                        Icon(Icons.draw_outlined, size: 48, color: Color(0xFFCBD5E1)),
                        SizedBox(height: 8),
                        Text('No signature added', style: TextStyle(color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    final newProfile = profile.copyWith(signatureUrl: selectedSignPath);
                    ref.read(profileProvider.notifier).updateProfile(newProfile);
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5722),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(AppLocalizations.of(context)?.translate('save_changes') ?? 'Save Changes', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditBankDetailsDialog(BuildContext context, WidgetRef ref, BusinessProfile profile) {
    final holderNameController = TextEditingController(text: profile.accountHolderName);
    final accountNoController = TextEditingController(text: profile.accountNo);
    final confirmAccountNoController = TextEditingController(text: profile.accountNo);
    final ifscController = TextEditingController(text: profile.ifscCode);
    final bankNameController = TextEditingController(text: profile.bankName);
    final branchNameController = TextEditingController(text: profile.branchName);
    final upiIdController = TextEditingController(text: profile.upiId);
    final upiNumberController = TextEditingController(text: profile.upiNumber);

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (stfCtx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(stfCtx).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)?.translate('bank_details') ?? 'Bank Details', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const Text('Configure payment information', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                const SizedBox(height: 20),
                
                _buildFieldLabel(AppLocalizations.of(context)?.translate('account_holder') ?? 'Account Holder'),
                _buildTextField(holderNameController, 'Name as per bank'),
                
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel(AppLocalizations.of(context)?.translate('account_number') ?? 'Account Number'),
                          _buildTextField(accountNoController, AppLocalizations.of(context)?.translate('account_number') ?? 'Account No.', isObscure: true),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Confirm Number'),
                          _buildTextField(confirmAccountNoController, 'Confirm No.'),
                        ],
                      ),
                    ),
                  ],
                ),
                
                _buildFieldLabel('IFSC Code'),
                Row(
                  children: [
                    Expanded(child: _buildTextField(ifscController, 'Bank IFSC')),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        if (ifscController.text.length > 4) {
                          setModalState(() {
                            bankNameController.text = 'STATE BANK OF INDIA';
                            branchNameController.text = 'MAIN BRANCH';
                          });
                        }
                      },
                      child: const Text('Fetch', style: TextStyle(color: Color(0xFFFF5722), fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                
                _buildFieldLabel('Bank Name'),
                _buildTextField(bankNameController, 'Name of the bank'),
                
                _buildFieldLabel(AppLocalizations.of(context)?.translate('upi_id') ?? 'UPI ID (Optional)'),
                _buildTextField(upiIdController, 'e.g. user@bank'),
                const SizedBox(height: 12),

                // Test & Generate Payment QR Button
                OutlinedButton.icon(
                  onPressed: () {
                    final currentProfile = profile.copyWith(
                      upiId: upiIdController.text,
                      accountHolderName: holderNameController.text,
                    );
                    PaymentQrSheet.show(context, profile: currentProfile);
                  },
                  icon: const Icon(Icons.qr_code_2_rounded, size: 18, color: Color(0xFFFF5722)),
                  label: const Text('Generate & Test Payment QR', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF5722))),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFF5722)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                ),
                
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      if (accountNoController.text != confirmAccountNoController.text) {
                        ScaffoldMessenger.of(stfCtx).showSnackBar(const SnackBar(content: Text('Account numbers do not match')));
                        return;
                      }
                      final newProfile = profile.copyWith(
                        accountHolderName: holderNameController.text,
                        accountNo: accountNoController.text,
                        ifscCode: ifscController.text,
                        bankName: bankNameController.text,
                        branchName: branchNameController.text,
                        upiId: upiIdController.text,
                        upiNumber: upiNumberController.text,
                      );
                      ref.read(profileProvider.notifier).updateProfile(newProfile);
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5722),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(AppLocalizations.of(context)?.translate('save') ?? 'Save Details', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, top: 10.0),
      child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {bool isObscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          fillColor: const Color(0xFFF8FAFC),
          filled: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF5722), width: 1.5)),
        ),
      ),
    );
  }

  void _showEditBusinessDialog(BuildContext context, WidgetRef ref, BusinessProfile profile) {
    final nameController = TextEditingController(text: profile.businessName);
    final addressController = TextEditingController(text: profile.address);
    final phoneController = TextEditingController(text: profile.phone);
    final emailController = TextEditingController(text: profile.email);
    final gstController = TextEditingController(text: profile.gstNumber);
    String selectedCurrency = profile.currency;
    String? selectedLogoPath = profile.logoUrl;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)?.translate('business_settings') ?? 'Business Settings', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              const SizedBox(height: 4),
              const Text('This information will appear on your invoices', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
              const SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final image = await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      setModalState(() {
                        selectedLogoPath = image.path;
                      });
                    }
                  },
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      image: selectedLogoPath != null 
                        ? DecorationImage(image: FileImage(File(selectedLogoPath!)), fit: BoxFit.cover) 
                        : null,
                    ),
                    child: selectedLogoPath == null 
                      ? const Icon(Icons.add_a_photo_outlined, color: Color(0xFF64748B))
                      : null,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(child: Text('Tap to upload logo', style: TextStyle(color: Color(0xFF64748B), fontSize: 12))),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  labelText: 'Business Name',
                  labelStyle: const TextStyle(color: Color(0xFF64748B)),
                  fillColor: const Color(0xFFF8FAFC),
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFF5722), width: 1.5)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: addressController,
                maxLines: 2,
                style: const TextStyle(color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  labelText: 'Address',
                  labelStyle: const TextStyle(color: Color(0xFF64748B)),
                  fillColor: const Color(0xFFF8FAFC),
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFF5722), width: 1.5)),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: phoneController,
                      style: const TextStyle(color: Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        labelText: 'Phone',
                        labelStyle: const TextStyle(color: Color(0xFF64748B)),
                        fillColor: const Color(0xFFF8FAFC),
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFF5722), width: 1.5)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextField(
                      controller: emailController,
                      style: const TextStyle(color: Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: const TextStyle(color: Color(0xFF64748B)),
                        fillColor: const Color(0xFFF8FAFC),
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFF5722), width: 1.5)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: selectedCurrency,
                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 16),
                dropdownColor: Colors.white,
                decoration: InputDecoration(
                  labelText: 'Currency',
                  labelStyle: const TextStyle(color: Color(0xFF64748B)),
                  fillColor: const Color(0xFFF8FAFC),
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFF5722), width: 1.5)),
                ),
                items: ['\$', '₹', '€', '£', '¥'].map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: Color(0xFF0F172A))))).toList(),
                onChanged: (v) => selectedCurrency = v!,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: gstController,
                style: const TextStyle(color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  labelText: 'GST Number (Optional)',
                  labelStyle: const TextStyle(color: Color(0xFF64748B)),
                  fillColor: const Color(0xFFF8FAFC),
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFF5722), width: 1.5)),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    final newProfile = profile.copyWith(
                      businessName: nameController.text,
                      address: addressController.text,
                      phone: phoneController.text,
                      email: emailController.text,
                      currency: selectedCurrency,
                      logoUrl: selectedLogoPath,
                      gstNumber: gstController.text,
                    );
                    ref.read(profileProvider.notifier).updateProfile(newProfile);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5722),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Save Business Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

// ── StatItem: Clean White Card Item ──
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({required this.label, required this.value, this.color = const Color(0xFF0F172A)});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5)),
      ],
    );
  }
}

// ── ProfileTile: Clean White List Tile ──
class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isLast;
  final VoidCallback? onTap;

  const _ProfileTile({required this.icon, required this.title, this.subtitle, this.isLast = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          leading: Icon(icon, color: const Color(0xFF64748B)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5, color: Color(0xFF0F172A))),
          subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)) : null,
          trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
        ),
        if (!isLast) const Divider(height: 1, indent: 64, endIndent: 20, color: Color(0xFFE2E8F0)),
      ],
    );
  }
}
