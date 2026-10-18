import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/navigation_utils.dart';
import '../providers/profile_provider.dart';
import '../widgets/payment_qr_sheet.dart';

class BankDetailsScreen extends ConsumerStatefulWidget {
  const BankDetailsScreen({super.key});

  @override
  ConsumerState<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends ConsumerState<BankDetailsScreen> {
  late final TextEditingController _ifscController;
  late final TextEditingController _bankNameController;
  late final TextEditingController _branchNameController;
  late final TextEditingController _accountHolderController;
  late final TextEditingController _accountNoController;
  late final TextEditingController _confirmAccountNoController;
  late final TextEditingController _openingBalanceController;
  late final TextEditingController _upiController;
  late final TextEditingController _upiNumberController;
  late final TextEditingController _notesController;

  bool _isPrimaryAccount = true;
  bool _isSaving = false;
  String? _accountMismatchError;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);

    _ifscController = TextEditingController(text: profile.ifscCode ?? '');
    _bankNameController = TextEditingController(text: profile.bankName ?? '');
    _branchNameController = TextEditingController(text: profile.branchName ?? '');
    _accountHolderController = TextEditingController(
      text: (profile.accountHolderName != null && profile.accountHolderName!.isNotEmpty)
          ? profile.accountHolderName!
          : profile.businessName,
    );
    _accountNoController = TextEditingController(text: profile.accountNo ?? '');
    _confirmAccountNoController = TextEditingController(text: profile.accountNo ?? '');
    _openingBalanceController = TextEditingController(
      text: profile.openingBalance != null && profile.openingBalance! > 0
          ? profile.openingBalance!.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '')
          : '',
    );
    _upiController = TextEditingController(text: profile.upiId ?? '');
    _upiNumberController = TextEditingController(text: profile.upiNumber ?? '');
    _notesController = TextEditingController(text: profile.bankNotes ?? '');
    _isPrimaryAccount = profile.isPrimaryAccount;

    _accountNoController.addListener(_validateAccountMatch);
    _confirmAccountNoController.addListener(_validateAccountMatch);
  }

  void _validateAccountMatch() {
    final acc = _accountNoController.text.trim();
    final confirm = _confirmAccountNoController.text.trim();
    if (confirm.isNotEmpty && acc.isNotEmpty && acc != confirm) {
      if (_accountMismatchError == null) {
        setState(() => _accountMismatchError = 'Account numbers do not match');
      }
    } else {
      if (_accountMismatchError != null) {
        setState(() => _accountMismatchError = null);
      }
    }
  }

  @override
  void dispose() {
    _ifscController.dispose();
    _bankNameController.dispose();
    _branchNameController.dispose();
    _accountHolderController.dispose();
    _accountNoController.dispose();
    _confirmAccountNoController.dispose();
    _openingBalanceController.dispose();
    _upiController.dispose();
    _upiNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Known Indian Bank codes for instantaneous offline autofill
  static const Map<String, String> _knownBankPrefixes = {
    'HDFC': 'HDFC Bank',
    'SBIN': 'State Bank of India',
    'ICIC': 'ICICI Bank',
    'UTIB': 'Axis Bank',
    'KKBK': 'Kotak Mahindra Bank',
    'PUNB': 'Punjab National Bank',
    'BARB': 'Bank of Baroda',
    'CNRB': 'Canara Bank',
    'UBIN': 'Union Bank of India',
    'IDFB': 'IDFC FIRST Bank',
    'YESB': 'Yes Bank',
    'INDB': 'IndusInd Bank',
    'FDRL': 'Federal Bank',
    'IOBA': 'Indian Overseas Bank',
  };

  void _onIfscChanged(String ifsc) {
    final clean = ifsc.trim().toUpperCase();
    if (clean.length >= 4) {
      final prefix = clean.substring(0, 4);
      if (_knownBankPrefixes.containsKey(prefix) && _bankNameController.text.trim().isEmpty) {
        setState(() {
          _bankNameController.text = _knownBankPrefixes[prefix]!;
        });
      }
    }
  }

  Future<void> _saveDetails() async {
    final ifsc = _ifscController.text.trim().toUpperCase();
    final bankName = _bankNameController.text.trim();
    final branchName = _branchNameController.text.trim();
    final accountHolder = _accountHolderController.text.trim();
    final accountNo = _accountNoController.text.trim();
    final confirmAccountNo = _confirmAccountNoController.text.trim();

    // Validations
    if (ifsc.isEmpty) {
      _showSnackbar('Bank IFSC is required', isError: true);
      return;
    }
    if (bankName.isEmpty) {
      _showSnackbar('Bank name is required', isError: true);
      return;
    }
    if (branchName.isEmpty) {
      _showSnackbar('Branch name is required', isError: true);
      return;
    }
    if (accountNo.isEmpty) {
      _showSnackbar('Bank account number is required', isError: true);
      return;
    }
    if (confirmAccountNo.isNotEmpty && accountNo != confirmAccountNo) {
      _showSnackbar('Account numbers do not match', isError: true);
      return;
    }

    double? openingBalance;
    final balText = _openingBalanceController.text.trim();
    if (balText.isNotEmpty) {
      openingBalance = double.tryParse(balText.replaceAll(',', ''));
    }

    setState(() => _isSaving = true);
    try {
      final profile = ref.read(profileProvider);
      final updated = profile.copyWith(
        ifscCode: ifsc,
        bankName: bankName,
        branchName: branchName,
        accountHolderName: accountHolder,
        accountNo: accountNo,
        openingBalance: openingBalance,
        upiId: _upiController.text.trim(),
        upiNumber: _upiNumberController.text.trim(),
        bankNotes: _notesController.text.trim(),
        isPrimaryAccount: _isPrimaryAccount,
      );

      await ref.read(profileProvider.notifier).updateProfile(updated);

      if (mounted) {
        _showSnackbar('Bank details updated successfully!');
        safeNavigateBack(context, fallbackRoute: '/profile');
      }
    } catch (e) {
      if (mounted) {
        _showSnackbar('Failed to update: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final businessProfile = ref.watch(profileProvider);
    final upiId = _upiController.text.trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A), size: 24),
          onPressed: () => safeNavigateBack(context, fallbackRoute: '/profile'),
        ),
        title: const Text(
          'Add New bank',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Bank Details Section ──
              _buildSectionTitle('Bank details'),
              _buildCardContainer(
                children: [
                  _buildFormInputField(
                    label: 'Bank IFSC',
                    isRequired: true,
                    controller: _ifscController,
                    textCapitalization: TextCapitalization.characters,
                    onChanged: _onIfscChanged,
                  ),
                  const SizedBox(height: 14),
                  _buildFormInputField(
                    label: 'Bank name',
                    isRequired: true,
                    controller: _bankNameController,
                  ),
                  const SizedBox(height: 14),
                  _buildFormInputField(
                    label: 'Branch name',
                    isRequired: true,
                    controller: _branchNameController,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── 2. Account Information Section ──
              _buildSectionTitle('Account information'),
              _buildCardContainer(
                children: [
                  _buildFormInputField(
                    label: 'Account Holder Name',
                    isRequired: false,
                    controller: _accountHolderController,
                  ),
                  const SizedBox(height: 14),
                  _buildFormInputField(
                    label: 'Bank account number',
                    isRequired: true,
                    controller: _accountNoController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 14),
                  _buildFormInputField(
                    label: 'Confirm account number',
                    isRequired: true,
                    controller: _confirmAccountNoController,
                    keyboardType: TextInputType.number,
                    errorText: _accountMismatchError,
                    suffixIcon: (_confirmAccountNoController.text.isNotEmpty &&
                            _accountNoController.text.isNotEmpty &&
                            _confirmAccountNoController.text == _accountNoController.text)
                        ? const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20)
                        : null,
                  ),
                  const SizedBox(height: 14),
                  _buildFormInputField(
                    label: 'Opening balance',
                    isRequired: false,
                    controller: _openingBalanceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── 3. UPI Details Section ──
              _buildSectionTitle('UPI details'),
              _buildCardContainer(
                children: [
                  _buildFormInputField(
                    label: 'UPI (Optional)',
                    isRequired: false,
                    controller: _upiController,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 14),
                  _buildFormInputField(
                    label: 'GPay/ PhonePe number (Optional)',
                    isRequired: false,
                    controller: _upiNumberController,
                    keyboardType: TextInputType.phone,
                  ),
                  if (upiId.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0EB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFCCBC)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.qr_code_2_rounded, color: AppColors.primary, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Dynamic UPI QR active for $upiId',
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFFC84015)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => PaymentQrSheet.show(context, profile: businessProfile),
                            child: const Text(
                              'Preview QR',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 20),

              // ── 4. Additional Options Section ──
              _buildSectionTitle('Additional options'),
              _buildCardContainer(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFormInputField(
                        label: 'Notes',
                        isRequired: false,
                        controller: _notesController,
                        maxLines: 2,
                        minLines: 1,
                      ),
                      const SizedBox(height: 6),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          '(Swift Code, Beneficiary Name) etc, notes will also be shown along with the bank details',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Set as Primary Account',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Account will be selected by default on record payment.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Switch(
                        value: _isPrimaryAccount,
                        activeThumbColor: AppColors.primary,
                        activeTrackColor: const Color(0xFFFFCCBC),
                        inactiveThumbColor: const Color(0xFFCBD5E1),
                        inactiveTrackColor: const Color(0xFFE2E8F0),
                        onChanged: (val) {
                          HapticFeedback.selectionClick();
                          setState(() => _isPrimaryAccount = val);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _isSaving ? null : _saveDetails,
            child: _isSaving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
          color: Color(0xFF475569),
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  Widget _buildCardContainer({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildFormInputField({
    required String label,
    required bool isRequired,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int maxLines = 1,
    int minLines = 1,
    String? errorText,
    Widget? suffixIcon,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      minLines: minLines,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        label: RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            children: isRequired
                ? const [
                    TextSpan(
                      text: '*',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ]
                : [],
          ),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        errorText: errorText,
        errorStyle: const TextStyle(fontSize: 11.5, color: Color(0xFFEF4444)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.6),
        ),
      ),
      onChanged: onChanged,
    );
  }
}
