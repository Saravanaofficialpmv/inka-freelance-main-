import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../../data/models/invoice.dart';
import '../viewmodels/invoice_viewmodel.dart';
import '../providers/profile_provider.dart';
import '../../data/models/business_profile.dart';
import 'package:inka/core/constants/colors.dart';
import '../../core/localization/app_localizations.dart';
import '../providers/locale_provider.dart';

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
    final currencyFormat = NumberFormat.simpleCurrency(decimalDigits: 0, name: businessProfile.currency);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppLocalizations.of(context)?.translate('profile') ?? 'Profile', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black)),
                    GestureDetector(
                      onTap: () {
                        _showAdvancedSettings(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.more_horiz, color: Colors.black, size: 20),
                      ),
                    )
                  ],
                ),
              ),
            ),

            // ── Business Profile Card ──
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            child: Text(
                              (businessProfile.businessName.isNotEmpty ? businessProfile.businessName[0] : displayName[0]).toUpperCase(),
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  businessProfile.businessName.isNotEmpty ? businessProfile.businessName : 'Set Business Name',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                                Text(
                                  user?.email ?? 'Free User Account',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _showEditBusinessDialog(context, ref, businessProfile),
                            icon: const Icon(Icons.edit_note, color: AppColors.primary, size: 28),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(label: 'Total Rev', value: currencyFormat.format(totalRevenue)),
                          _StatItem(label: 'Invoices', value: '$totalInvoices'),
                          const _StatItem(label: 'Status', value: 'Premium', color: AppColors.primary),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),

            // ── Main Options ──
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                  child: Column(
                    children: [
                      _ProfileTile(
                        icon: Icons.business_outlined, 
                        title: AppLocalizations.of(context)?.translate('business_settings') ?? 'Business Information', 
                        subtitle: businessProfile.businessName.isNotEmpty ? AppLocalizations.of(context)?.translate('global_settings') ?? 'Global settings for your invoices' : AppLocalizations.of(context)?.translate('setup_business') ?? 'Set up your business profile',
                        onTap: () => _showEditBusinessDialog(context, ref, businessProfile),
                      ),
                      _ProfileTile(
                        icon: Icons.receipt_long_outlined, 
                        title: AppLocalizations.of(context)?.translate('invoices') ?? 'Invoices Summary', 
                        subtitle: 'View detailed performance',
                        onTap: () => context.go('/history'),
                      ),
                      _ProfileTile(
                        icon: Icons.draw_outlined, 
                        title: AppLocalizations.of(context)?.translate('signatures') ?? 'Signatures & Stamps', 
                        subtitle: businessProfile.signatureUrl != null && businessProfile.signatureUrl!.isNotEmpty ? 'Default signature set' : AppLocalizations.of(context)?.translate('manage_signatures') ?? 'Manage your business signatures',
                        onTap: () => _showEditSignaturesDialog(context, ref, businessProfile),
                      ),
                      _ProfileTile(
                        icon: Icons.account_balance_outlined, 
                        title: AppLocalizations.of(context)?.translate('bank_details') ?? 'Bank & Digital Payments', 
                        subtitle: (businessProfile.accountNo != null && businessProfile.accountNo!.length >= 4)
                          ? 'A/C: ****${businessProfile.accountNo!.substring(businessProfile.accountNo!.length - 4)}'
                          : (businessProfile.accountNo != null && businessProfile.accountNo!.isNotEmpty)
                            ? 'A/C: ${businessProfile.accountNo}'
                            : AppLocalizations.of(context)?.translate('manage_bank') ?? 'Manage bank and UPI details',
                        onTap: () => _showEditBankDetailsDialog(context, ref, businessProfile),
                      ),
                      _ProfileTile(
                        icon: Icons.inventory_2_outlined, 
                        title: AppLocalizations.of(context)?.translate('product_catalog') ?? 'Product Catalog', 
                        subtitle: AppLocalizations.of(context)?.translate('manage_inventory') ?? 'Manage items and services',
                        onTap: () => context.push('/products'),
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
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 160),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
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
            const Text('Select Language', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 24),
            ...languages.map((lang) => ListTile(
              leading: Text(lang.flag, style: const TextStyle(fontSize: 24)),
              title: Text(lang.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: ref.watch(localeProvider).languageCode == lang.code 
                ? const Icon(Icons.check_circle, color: AppColors.primary) 
                : null,
              onTap: () {
                ref.read(localeProvider.notifier).setLocale(Locale(lang.code));
                Navigator.pop(ctx);
              },
            )),
            const SizedBox(height: 24),
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
            Text(AppLocalizations.of(context)?.translate('advanced_settings') ?? 'Advanced Settings', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.black),
              title: Text(AppLocalizations.of(context)?.translate('about_app') ?? 'About App', style: const TextStyle(color: Colors.black)),
              onTap: () {
                Navigator.pop(context);
                showDialog(context: context, builder: (_) => AlertDialog(
                  title: const Text('Inka'),
                  content: Text('${AppLocalizations.of(context)?.translate('version') ?? 'Version'} 1.0.0\nCreated using Flutter.'),
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)?.translate('close') ?? 'Close'))],
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
      title: Text(AppLocalizations.of(context)?.translate('help_support') ?? 'Help & Support'),
      content: const Text('Contact us at: support@inka.com'),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)?.translate('close') ?? 'Close'))],
    ));
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text(AppLocalizations.of(context)?.translate('privacy_policy') ?? 'Privacy Policy'),
      content: const Text('Your data is securely synced via our backend.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)?.translate('close') ?? 'Close'))],
    ));
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text(AppLocalizations.of(context)?.translate('terms_conditions') ?? 'Terms & Conditions'),
      content: const Text('By using Inka, you agree to our standard terms.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)?.translate('close') ?? 'Close'))],
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
                  Text(AppLocalizations.of(context)?.translate('signatures') ?? 'Signatures', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
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
                    icon: const Icon(Icons.add, size: 18, color: AppColors.primary),
                    label: Text(AppLocalizations.of(context)?.translate('add_new') ?? 'Add New', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const Text('Manage your business signatures', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 24),
              
              if (selectedSignPath != null && selectedSignPath!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Official Signature', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                            const SizedBox(height: 4),
                            const Text('Active on all invoices', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Container(
                        width: 100,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
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
                      children: [
                        Icon(Icons.draw_outlined, size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 8),
                        const Text('No signature added', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    final newProfile = profile.copyWith(signatureUrl: selectedSignPath);
                    ref.read(profileProvider.notifier).updateProfile(newProfile);
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
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
                Text(AppLocalizations.of(context)?.translate('bank_details') ?? 'Bank Details', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
                const Text('Configure payment information', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 24),
                
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
                      child: const Text('Fetch', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                
                _buildFieldLabel('Bank Name'),
                _buildTextField(bankNameController, 'Name of the bank'),
                
                _buildFieldLabel(AppLocalizations.of(context)?.translate('upi_id') ?? 'UPI ID (Optional)'),
                _buildTextField(upiIdController, 'e.g. user@bank'),
                
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
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
                      backgroundColor: Colors.black,
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
      padding: const EdgeInsets.only(bottom: 8.0, top: 12.0),
      child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {bool isObscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        style: const TextStyle(color: Colors.black, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black26, fontSize: 13),
          fillColor: AppColors.background,
          filled: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
          color: Colors.white, // WHITE background for the modal
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Black text on white background
              Text(AppLocalizations.of(context)?.translate('business_settings') ?? 'Business Settings', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 4),
              const Text('This information will appear on your invoices', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 24),
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
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      image: selectedLogoPath != null 
                        ? DecorationImage(image: FileImage(File(selectedLogoPath!)), fit: BoxFit.cover) 
                        : null,
                    ),
                    child: selectedLogoPath == null 
                      ? const Icon(Icons.add_a_photo, color: AppColors.textSecondary)
                      : null,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(child: Text('Tap to upload logo', style: TextStyle(color: AppColors.textSecondary, fontSize: 12))),
              const SizedBox(height: 24),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.black), // Black text while typing
                decoration: InputDecoration(
                  labelText: 'Business Name',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  fillColor: AppColors.background,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                maxLines: 2,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'Address',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  fillColor: AppColors.background,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: phoneController,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        labelText: 'Phone',
                        labelStyle: const TextStyle(color: AppColors.textSecondary),
                        fillColor: AppColors.background,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: emailController,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: const TextStyle(color: AppColors.textSecondary),
                        fillColor: AppColors.background,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedCurrency,
                style: const TextStyle(color: Colors.black, fontSize: 16),
                dropdownColor: Colors.white,
                decoration: InputDecoration(
                  labelText: 'Currency',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  fillColor: AppColors.background,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                items: ['\$', '₹', '€', '£', '¥'].map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: Colors.black)))).toList(),
                onChanged: (v) => selectedCurrency = v!,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: gstController,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'GST Number (Optional)',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  fillColor: AppColors.background,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
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
                    backgroundColor: AppColors.primary, // Orange button
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

// ── StatItem: White card → Black text ──
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({required this.label, required this.value, this.color = Colors.black});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }
}

// ── ProfileTile: White card → Black text ──
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
          leading: Icon(icon, color: AppColors.textSecondary),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black)),
          subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)) : null,
          trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ),
        if (!isLast) const Divider(height: 1, indent: 64, endIndent: 20),
      ],
    );
  }
}

// ══════════════════════════════════════════════
// Invoice History Screen
// ══════════════════════════════════════════════

class InvoicesHistoryScreen extends ConsumerStatefulWidget {
  const InvoicesHistoryScreen({super.key});

  @override
  ConsumerState<InvoicesHistoryScreen> createState() => _InvoicesHistoryScreenState();
}

class _InvoicesHistoryScreenState extends ConsumerState<InvoicesHistoryScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final invoices = ref.watch(invoiceProvider);
    final profile = ref.watch(profileProvider);
    final currencyFormat = NumberFormat.simpleCurrency(name: profile.currency, decimalDigits: 0);
    final filteredInvoices = invoices.where((inv) => 
      inv.client.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      inv.invoiceNumber.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    final now = DateTime.now();
    final todayCount = invoices.where((inv) => 
      inv.issueDate.year == now.year && 
      inv.issueDate.month == now.month && 
      inv.issueDate.day == now.day
    ).length;

    return Scaffold(
      backgroundColor: AppColors.background, // #F4F4F4 soft grey
      body: SafeArea(
        child: Column(
          children: [
            // ── Header (light bg → black text) ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context)?.translate('invoices') ?? 'Invoices', style: const TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold)),
                      if (todayCount > 0)
                        Text(
                          (AppLocalizations.of(context)?.translate('today_count') ?? '{count} Today').replaceFirst('{count}', todayCount.toString()),
                          style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () => context.push('/create-invoice'),
                    icon: const Icon(Icons.add, color: AppColors.primary, size: 20),
                    label: Text(AppLocalizations.of(context)?.translate('create_new') ?? 'Create New', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
            
            // ── Search Bar (white card, black text input) ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(color: Colors.black), // Black text while typing
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)?.translate('search') ?? 'Search for Invoice',
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                    suffixIcon: const Icon(Icons.tune, color: AppColors.textSecondary),
                    border: InputBorder.none,
                    hintStyle: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // ── Invoice List ──
            Expanded(
              child: filteredInvoices.isEmpty
                ? Center(child: Text(AppLocalizations.of(context)?.translate('no_history') ?? 'No history found', style: const TextStyle(color: AppColors.textSecondary)))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 140),
                    itemCount: filteredInvoices.length,
                    itemBuilder: (context, index) {
                      final invoice = filteredInvoices[index];
                      return _InvoiceCard(invoice: invoice, currencyFormat: currencyFormat);
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── InvoiceCard: White card → Black text ──
class _InvoiceCard extends ConsumerWidget {
  final Invoice invoice;
  final NumberFormat currencyFormat;
  const _InvoiceCard({required this.invoice, required this.currencyFormat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Color statusColor;
    String statusKey;
    
    switch (invoice.status) {
      case 'paid':
        statusColor = AppColors.success;
        statusKey = 'paid';
        break;
      case 'overdue':
        statusColor = AppColors.error;
        statusKey = 'overdue';
        break;
      case 'pending':
      default:
        statusColor = AppColors.warning;
        statusKey = 'pending';
        break;
    }

    final statusText = AppLocalizations.of(context)?.translate(statusKey) ?? statusKey.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, // White card
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(invoice.client.name[0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(invoice.client.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                    Text(invoice.client.email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => ref.read(invoiceProvider.notifier).togglePaymentStatus(invoice.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1), 
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(invoice.status == 'paid' ? Icons.check_circle_rounded : Icons.pending_actions_rounded, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(statusText, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _InvoiceDetail(label: AppLocalizations.of(context)?.translate('amount') ?? 'Amount', value: currencyFormat.format(invoice.total)),
              _InvoiceDetail(
                label: AppLocalizations.of(context)?.translate('no') ?? 'No', 
                value: invoice.invoiceNumber.length >= 6 
                  ? '#${invoice.invoiceNumber.substring(invoice.invoiceNumber.length - 6)}'
                  : '#${invoice.invoiceNumber}'
              ),
              _InvoiceDetail(label: AppLocalizations.of(context)?.translate('date') ?? 'Date', value: DateFormat('dd MMM yyyy').format(invoice.issueDate)),
            ],
          )
        ],
      ),
    );
  }
}

// ── InvoiceDetail: White card → Black text ──
class _InvoiceDetail extends StatelessWidget {
  final String label;
  final String value;
  const _InvoiceDetail({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black)),
      ],
    );
  }
}
