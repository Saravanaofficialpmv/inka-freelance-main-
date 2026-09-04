import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/profile_provider.dart';
import '../../core/localization/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BusinessSetupScreen extends ConsumerStatefulWidget {
  const BusinessSetupScreen({super.key});

  @override
  ConsumerState<BusinessSetupScreen> createState() => _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends ConsumerState<BusinessSetupScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  String _selectedCurrency = 'USD';
  String? _selectedLogoPath;

  static const Map<String, String> _currencyMap = {
    'USD': '\$ USD (US Dollar)',
    'INR': '₹ INR (Indian Rupee)',
    'EUR': '€ EUR (Euro)',
    'GBP': '£ GBP (British Pound)',
    'JPY': '¥ JPY (Japanese Yen)',
    'CAD': '\$ CAD (Canadian Dollar)',
    'AUD': '\$ AUD (Australian Dollar)',
    'AED': 'AED (UAE Dirham)',
  };

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    final user = FirebaseAuth.instance.currentUser;
    if (profile.businessName.isNotEmpty) {
      _nameController.text = profile.businessName;
      _addressController.text = profile.address;
      _phoneController.text = profile.phone;
      _emailController.text = profile.email;
      _selectedCurrency = profile.currency;
      if (_selectedCurrency == '\$') _selectedCurrency = 'USD';
      if (_selectedCurrency == '₹') _selectedCurrency = 'INR';
      if (_selectedCurrency == '€') _selectedCurrency = 'EUR';
      if (_selectedCurrency == '£') _selectedCurrency = 'GBP';
      if (_selectedCurrency == '¥') _selectedCurrency = 'JPY';
      if (!_currencyMap.containsKey(_selectedCurrency)) {
        _selectedCurrency = 'USD';
      }
      _selectedLogoPath = profile.logoUrl;
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
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedLogoPath = image.path;
      });
    }
  }

  Future<void> _saveAndContinue() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your business name')),
      );
      return;
    }

    final existingProfile = ref.read(profileProvider);
    final newProfile = existingProfile.copyWith(
      businessName: _nameController.text.trim(),
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      currency: _selectedCurrency,
      logoUrl: _selectedLogoPath,
    );

    await ref.read(profileProvider.notifier).updateProfile(newProfile);
    if (mounted) {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppLocalizations.of(context)?.translate('setup_business') ?? 'Set Up Your Business',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Complete your freelance profile to brand invoices.',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              
              // Logo Picker
              Center(
                child: GestureDetector(
                  onTap: _pickLogo,
                  child: Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
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
                            fit: BoxFit.cover
                          ) 
                        : null,
                    ),
                    child: _selectedLogoPath == null 
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, color: Color(0xFFFF5722), size: 30),
                            SizedBox(height: 6),
                            Text(
                              'Add Logo',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFFFF5722),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : null,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              _buildInputField(
                label: 'Business / Freelancer Name',
                hint: 'e.g. Acme Studio',
                controller: _nameController,
                icon: Icons.business_outlined,
              ),
              const SizedBox(height: 16),

              _buildInputField(
                label: 'Business Email',
                hint: 'contact@business.com',
                controller: _emailController,
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              _buildInputField(
                label: 'Phone Number',
                hint: '+1 234 567 890',
                controller: _phoneController,
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              _buildInputField(
                label: 'Physical Address',
                hint: '123 Business St, City, Country',
                controller: _addressController,
                icon: Icons.location_on_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DEFAULT CURRENCY',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCurrency,
                        isExpanded: true,
                        dropdownColor: Colors.white,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 15),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedCurrency = newValue;
                            });
                          }
                        },
                        items: _currencyMap.entries
                            .map<DropdownMenuItem<String>>((entry) {
                          return DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(entry.value, style: const TextStyle(color: Color(0xFF0F172A))),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),

              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _saveAndContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5722),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Save and Get Started',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.bold,
            fontSize: 11,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14.5),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 19),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFFF5722), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
