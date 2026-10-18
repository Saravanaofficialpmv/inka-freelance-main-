import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/colors.dart';
import '../../services/currency_tax_service.dart';
import '../../services/currency_conversion_service.dart';
import '../providers/profile_provider.dart';

class BusinessSetupScreen extends ConsumerStatefulWidget {
  const BusinessSetupScreen({super.key});

  @override
  ConsumerState<BusinessSetupScreen> createState() => _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends ConsumerState<BusinessSetupScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isSubmitting = false;

  // ── Level 1: Business Identity & Contact ──
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  String _selectedCurrency = 'USD';
  String? _selectedLogoPath;

  // ── Level 2: Tax, Registration & Defaults ──
  String _selectedTaxScheme = 'GST';
  final _taxIdController = TextEditingController();
  final _taxRateController = TextEditingController(text: '18.0');
  bool _isTaxInclusive = false;
  String _selectedTemplate = 'modern';

  // ── Level 3: Bank, UPI & Payment Settlement ──
  final _accountHolderController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNoController = TextEditingController();
  final _ifscController = TextEditingController();
  final _branchController = TextEditingController();
  final _upiIdController = TextEditingController();
  final _upiNumberController = TextEditingController();

  final List<String> _taxSchemes = ['GST', 'VAT', 'Sales Tax', 'HST', 'TVA', 'None'];

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (_) {}

    if (profile.businessName.isNotEmpty) {
      // Pre-fill Level 1
      _nameController.text = profile.businessName;
      _emailController.text = profile.email;
      _phoneController.text = profile.phone;
      _addressController.text = profile.address;
      _selectedCurrency = profile.currency;
      _selectedLogoPath = profile.logoUrl;

      // Pre-fill Level 2
      _selectedTaxScheme = profile.taxLabel.isNotEmpty ? profile.taxLabel : 'GST';
      _taxIdController.text = profile.taxIdNumber ?? profile.gstNumber ?? '';
      _taxRateController.text = profile.defaultTaxRate.toString();
      _isTaxInclusive = profile.isTaxInclusive;
      _selectedTemplate = profile.invoiceTemplate;

      // Pre-fill Level 3
      _accountHolderController.text = profile.accountHolderName ?? '';
      _bankNameController.text = profile.bankName ?? '';
      _accountNoController.text = profile.accountNo ?? '';
      _ifscController.text = profile.ifscCode ?? '';
      _branchController.text = profile.branchName ?? '';
      _upiIdController.text = profile.upiId ?? '';
      _upiNumberController.text = profile.upiNumber ?? '';
    } else {
      if (user?.email != null && user!.email!.isNotEmpty) {
        _emailController.text = user.email!;
      }
      if (user?.displayName != null && user!.displayName!.isNotEmpty) {
        _nameController.text = user.displayName!;
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _taxIdController.dispose();
    _taxRateController.dispose();
    _accountHolderController.dispose();
    _bankNameController.dispose();
    _accountNoController.dispose();
    _ifscController.dispose();
    _branchController.dispose();
    _upiIdController.dispose();
    _upiNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedLogoPath = image.path);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── Step Navigation & Validations ──
  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    );
  }

  bool _validateLevel1() {
    if (_nameController.text.trim().isEmpty) {
      _showError('Please enter your business or freelancer name');
      return false;
    }
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('Please enter your official business email');
      return false;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      _showError('Please enter a valid email address');
      return false;
    }
    if (_phoneController.text.trim().isEmpty) {
      _showError('Please enter your phone number');
      return false;
    }
    if (_addressController.text.trim().isEmpty) {
      _showError('Please enter your business address');
      return false;
    }
    return true;
  }

  bool _validateLevel2() {
    final rate = double.tryParse(_taxRateController.text.trim());
    if (rate == null || rate < 0 || rate > 100) {
      _showError('Please enter a valid tax percentage between 0 and 100');
      return false;
    }
    return true;
  }

  Future<void> _completeSetup({bool skipBankDetails = false}) async {
    setState(() => _isSubmitting = true);

    try {
      final double taxRate = double.tryParse(_taxRateController.text.trim()) ?? 0.0;
      final existing = ref.read(profileProvider);

      final oldCurrency = existing.currency;
      final currencyChanged = _selectedCurrency.isNotEmpty &&
          oldCurrency.isNotEmpty &&
          _selectedCurrency.toUpperCase() != oldCurrency.toUpperCase();

      if (currencyChanged) {
        final recordCounts = CurrencyConversionService.getExistingRecordCounts();
        final totalRecords = recordCounts.values.fold<int>(0, (sum, count) => sum + count);
        if (totalRecords > 0) {
          await CurrencyConversionService.convertAllData(
            fromCurrency: oldCurrency,
            toCurrency: _selectedCurrency,
            ref: ref,
          );
        }
      }

      final updatedProfile = ref.read(profileProvider).copyWith(
        businessName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        currency: _selectedCurrency,
        logoUrl: _selectedLogoPath,
        taxLabel: _selectedTaxScheme,
        gstNumber: _taxIdController.text.trim(),
        taxIdNumber: _taxIdController.text.trim(),
        defaultTaxRate: taxRate,
        isTaxInclusive: _isTaxInclusive,
        invoiceTemplate: _selectedTemplate,
        accountHolderName: skipBankDetails ? '' : _accountHolderController.text.trim(),
        bankName: skipBankDetails ? '' : _bankNameController.text.trim(),
        accountNo: skipBankDetails ? '' : _accountNoController.text.trim(),
        ifscCode: skipBankDetails ? '' : _ifscController.text.trim(),
        branchName: skipBankDetails ? '' : _branchController.text.trim(),
        upiId: skipBankDetails ? '' : _upiIdController.text.trim(),
        upiNumber: skipBankDetails ? '' : _upiNumberController.text.trim(),
      );

      await ref.read(profileProvider.notifier).updateProfile(updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Business profile configured successfully!'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to save profile: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'Business Setup',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.cardBorder, height: 1),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── 3-Level Progress Header ──
            _buildStepIndicator(),

            // ── Multi-Step Page View ──
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildLevel1Identity(),
                  _buildLevel2TaxAndDefaults(),
                  _buildLevel3Payouts(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step Indicator Widget ──
  Widget _buildStepIndicator() {
    final steps = [
      {'title': 'Identity', 'subtitle': 'Level 1', 'icon': Icons.storefront_rounded},
      {'title': 'Tax & Legal', 'subtitle': 'Level 2', 'icon': Icons.receipt_long_rounded},
      {'title': 'Payouts', 'subtitle': 'Level 3', 'icon': Icons.account_balance_rounded},
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        children: [
          Row(
            children: List.generate(steps.length, (index) {
              final isDone = index < _currentStep;
              final isCurrent = index == _currentStep;

              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          // Allow stepping backward anytime
                          if (index < _currentStep) {
                            _goToStep(index);
                          } else if (index == 1 && _currentStep == 0) {
                            if (_validateLevel1()) _goToStep(1);
                          } else if (index == 2 && _currentStep == 1) {
                            if (_validateLevel2()) _goToStep(2);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? AppColors.primary.withValues(alpha: 0.08)
                                : isDone
                                    ? const Color(0xFFF1F5F9)
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isCurrent
                                  ? AppColors.primary
                                  : isDone
                                      ? const Color(0xFFCBD5E1)
                                      : const Color(0xFFE2E8F0),
                              width: isCurrent ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: isDone
                                      ? AppColors.success
                                      : isCurrent
                                          ? AppColors.primary
                                          : const Color(0xFF94A3B8),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: isDone
                                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                                      : Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  steps[index]['title'] as String,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                                    color: isCurrent
                                        ? AppColors.primary
                                        : isDone
                                            ? AppColors.textPrimary
                                            : AppColors.textMuted,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (index < steps.length - 1)
                      Container(
                        width: 8,
                        height: 1.5,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        color: isDone ? AppColors.success : const Color(0xFFE2E8F0),
                      ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'LEVEL ${_currentStep + 1} OF 3: ${(steps[_currentStep]['title'] as String).toUpperCase()}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${((_currentStep + 1) / 3 * 100).toInt()}% Completed',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // ── LEVEL 1: BUSINESS IDENTITY & CONTACT ──
  // ════════════════════════════════════════════════════════════════
  Widget _buildLevel1Identity() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        _buildSectionHeader(
          icon: Icons.storefront_rounded,
          title: 'Business Identity & Contact',
          subtitle: 'These details are mandatory for legal branding and invoice communication.',
        ),
        const SizedBox(height: 20),

        // Logo Picker
        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickLogo,
                child: Container(
                  height: 96,
                  width: 96,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.cardBorder, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    image: _selectedLogoPath != null
                        ? DecorationImage(
                            image: FileImage(File(_selectedLogoPath!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _selectedLogoPath == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_rounded, color: AppColors.primary, size: 28),
                            SizedBox(height: 6),
                            Text(
                              'Add Logo',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : null,
                ),
              ),
              if (_selectedLogoPath != null)
                TextButton(
                  onPressed: () => setState(() => _selectedLogoPath = null),
                  child: const Text(
                    'Remove Logo',
                    style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Official Business Logo (Optional)',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Business Name
        _buildInputField(
          controller: _nameController,
          label: 'Business / Freelancer Name *',
          hint: 'e.g. Acme Studio / Sarah Jenkins',
          icon: Icons.business_rounded,
        ),
        const SizedBox(height: 16),

        // Currency Selector (Top 10 Major Currencies)
        _buildCurrencyPicker(),
        const SizedBox(height: 16),

        // Email
        _buildInputField(
          controller: _emailController,
          label: 'Official Business Email *',
          hint: 'contact@business.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),

        // Phone
        _buildInputField(
          controller: _phoneController,
          label: 'Phone / WhatsApp Number *',
          hint: '+1 234 567 890',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),

        // Address
        _buildInputField(
          controller: _addressController,
          label: 'Registered Business Address *',
          hint: 'Street, City, State/Province, ZIP, Country',
          icon: Icons.location_on_outlined,
          maxLines: 2,
        ),
        const SizedBox(height: 28),

        // Next Button
        _buildActionButton(
          label: 'Next: Tax & Legal Rules →',
          onPressed: () {
            if (_validateLevel1()) {
              _goToStep(1);
            }
          },
        ),
      ],
    ),
  );
}

  // ════════════════════════════════════════════════════════════════
  // ── LEVEL 2: TAX, REGISTRATION & DEFAULTS ──
  // ════════════════════════════════════════════════════════════════
  Widget _buildLevel2TaxAndDefaults() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        _buildSectionHeader(
          icon: Icons.receipt_long_rounded,
          title: 'Tax, Registration & Invoicing Defaults',
          subtitle: 'Mandatory rules to ensure your invoices meet local tax & commercial compliance.',
        ),
        const SizedBox(height: 20),

        // Tax Scheme Selector
        const Text(
          'TAX SCHEME / REGION *',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _taxSchemes.map((scheme) {
            final isSelected = _selectedTaxScheme == scheme;
            return ChoiceChip(
              label: Text(scheme),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedTaxScheme = scheme;
                    if (scheme == 'None') {
                      _taxRateController.text = '0.0';
                    } else if (scheme == 'GST') {
                      _taxRateController.text = '18.0';
                    } else if (scheme == 'VAT') {
                      _taxRateController.text = '20.0';
                    } else if (scheme == 'Sales Tax') {
                      _taxRateController.text = '8.25';
                    }
                  });
                }
              },
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 13,
              ),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.cardBorder,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Tax ID Number
        _buildInputField(
          controller: _taxIdController,
          label: _getTaxIdLabel(),
          hint: _getTaxIdHint(),
          icon: Icons.badge_outlined,
        ),
        const SizedBox(height: 16),

        // Tax Rate (%)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _buildInputField(
                controller: _taxRateController,
                label: 'Default Tax Rate (%) *',
                hint: '0.0',
                icon: Icons.percent_rounded,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'QUICK PRESETS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: ['0%', '5%', '12%', '18%', '20%'].map((rateStr) {
                      final val = rateStr.replaceAll('%', '');
                      return GestureDetector(
                        onTap: () => setState(() => _taxRateController.text = val),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Text(
                            rateStr,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Tax Mode: Inclusive vs Exclusive
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tax Inclusive Pricing',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isTaxInclusive
                          ? 'Item rates already include tax (Retail / B2C)'
                          : 'Tax is added on top of item rates (Standard B2B)',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isTaxInclusive,
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                onChanged: (val) => setState(() => _isTaxInclusive = val),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Invoice Template Selector
        const Text(
          'DEFAULT INVOICE TEMPLATE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: ['modern', 'minimal', 'emerald', 'classic'].map((tmpl) {
            final isSelected = _selectedTemplate == tmpl;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTemplate = tmpl),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.cardBorder,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      tmpl.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 28),

        // Back and Next Row
        Row(
          children: [
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: () => _goToStep(0),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.cardBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('← Back', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _buildActionButton(
                label: 'Next: Payouts & Banking →',
                onPressed: () {
                  if (_validateLevel2()) {
                    _goToStep(2);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

  // ════════════════════════════════════════════════════════════════
  // ── LEVEL 3: BANK, UPI & PAYMENT SETTLEMENT ──
  // ════════════════════════════════════════════════════════════════
  Widget _buildLevel3Payouts() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        _buildSectionHeader(
          icon: Icons.account_balance_rounded,
          title: 'Bank & UPI Payment Settlement',
          subtitle: 'Mandatory for getting paid. Inka uses these details to render bank transfer instructions and instant UPI QR codes on all invoices.',
        ),
        const SizedBox(height: 20),

        // ── Bank Coordinates Card ──
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.account_balance_rounded, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Direct Bank Transfer Coordinates',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _accountHolderController,
                label: 'Beneficiary / Account Holder Name',
                hint: 'e.g. John Doe / Acme Studio Ltd',
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      controller: _bankNameController,
                      label: 'Bank Name',
                      hint: 'e.g. Chase / HDFC Bank',
                      icon: Icons.account_balance_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInputField(
                      controller: _branchController,
                      label: 'Branch Name',
                      hint: 'e.g. Downtown / Main',
                      icon: Icons.location_city_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildInputField(
                controller: _accountNoController,
                label: 'Bank Account Number',
                hint: 'e.g. 50100234567890',
                icon: Icons.numbers_rounded,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),
              _buildInputField(
                controller: _ifscController,
                label: 'IFSC / SWIFT / Routing Code',
                hint: 'e.g. HDFC0001234 / CHASUS33',
                icon: Icons.password_rounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Instant UPI & QR Pay Card ──
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'INSTANT QR',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 10),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'UPI & Digital Payment QR',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Providing a UPI ID enables automated, high-resolution QR codes on PDF invoices so clients can pay instantly with any scanner app.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _upiIdController,
                label: 'UPI ID / VPA',
                hint: 'e.g. freelancer@okhdfcbank / pay@upi',
                icon: Icons.qr_code_rounded,
              ),
              const SizedBox(height: 14),
              _buildInputField(
                controller: _upiNumberController,
                label: 'UPI Registered Phone Number',
                hint: 'e.g. +91 98765 43210 (GPay / PhonePe)',
                icon: Icons.phone_android_rounded,
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Complete Action Button
        _buildActionButton(
          label: _isSubmitting ? 'Saving Profile...' : 'Complete Setup & Launch Dashboard 🚀',
          onPressed: _isSubmitting ? () {} : () => _completeSetup(),
        ),
        const SizedBox(height: 10),

        // Optional Skip Bank Details
        Center(
          child: TextButton(
            onPressed: _isSubmitting ? null : () => _completeSetup(skipBankDetails: true),
            child: const Text(
              'I\'ll add bank details later',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

  // ════════════════════════════════════════════════════════════════
  // ── HELPER UI BUILDERS ──
  // ════════════════════════════════════════════════════════════════
  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencyPicker() {
    final currencies = CurrencyTaxService.top10Currencies;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PRIMARY BILLING CURRENCY *',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCurrency,
              isExpanded: true,
              dropdownColor: Colors.white,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
              items: currencies.map((c) {
                return DropdownMenuItem<String>(
                  value: c.code,
                  child: Row(
                    children: [
                      Text(c.flag, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          '${c.name} (${c.code} • ${c.symbol})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCurrency = val);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 11,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.normal),
              prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _getTaxIdLabel() {
    switch (_selectedTaxScheme) {
      case 'GST':
        return 'GSTIN (GST Identification Number)';
      case 'VAT':
        return 'VAT Registration Number';
      case 'Sales Tax':
        return 'State Tax Permit / EIN';
      case 'HST':
        return 'CRA Business Number (HST)';
      case 'TVA':
        return 'Numéro de TVA';
      default:
        return 'Business / Tax Registration ID (Optional)';
    }
  }

  String _getTaxIdHint() {
    switch (_selectedTaxScheme) {
      case 'GST':
        return 'e.g. 29ABCDE1234F1Z5';
      case 'VAT':
        return 'e.g. GB 123 4567 89 / DE 123456789';
      case 'Sales Tax':
        return 'e.g. 12-3456789';
      case 'HST':
        return 'e.g. 123456789RT0001';
      default:
        return 'Registration or Legal Tax Identifier';
    }
  }
}
