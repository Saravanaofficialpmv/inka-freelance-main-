import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:inka/core/constants/colors.dart';
import '../../core/localization/app_localizations.dart';
import '../widgets/inka_brand_logo.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNextPressed() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          // Ambient soft warm background glow orbs aligned to Inka theme
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF5722).withValues(alpha: 0.08),
                    const Color(0xFFFF5722).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF7A50).withValues(alpha: 0.06),
                    const Color(0xFFFF7A50).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Top Header: Inka Logo & Skip Button ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const _InkaLogoHeader(),
                      TextButton(
                        onPressed: () => context.go('/auth'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          AppLocalizations.of(context)?.translate('skip') ?? 'Skip',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── PageView for the 3 Slides ──
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    children: const [
                      _Slide1CreateInvoices(),
                      _Slide2OfflineSync(),
                      _Slide3EverythingToGetPaid(),
                    ],
                  ),
                ),

                // ── Bottom Section: CTA Button & Page Indicator ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 6, 24, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // "Get Started" / "Continue" Pill CTA Button with Inka theme gradient
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF5722), Color(0xFFFF7A50)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF5722).withValues(alpha: 0.35),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _onNextPressed,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const SizedBox(width: 36),
                                Text(
                                  _currentPage == 2
                                      ? (AppLocalizations.of(context)?.translate('get_started') ?? 'Get Started')
                                      : 'Continue',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Animated Page Indicator Dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) {
                          final bool isActive = _currentPage == index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 6,
                            width: isActive ? 20 : 6,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFFFF5722)
                                  : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
class _InkaLogoHeader extends StatelessWidget {
  const _InkaLogoHeader();

  @override
  Widget build(BuildContext context) {
    return const InkaBrandLogo(fontSize: 22);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SLIDE 1: CREATE PROFESSIONAL INVOICES IN SECONDS
// ─────────────────────────────────────────────────────────────────────────────
class _Slide1CreateInvoices extends StatelessWidget {
  const _Slide1CreateInvoices();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          // Title
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                height: 1.15,
                letterSpacing: -0.5,
              ),
              children: [
                TextSpan(text: 'Create\nProfessional\nInvoices\n'),
                TextSpan(
                  text: 'in Seconds',
                  style: TextStyle(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Subtitle
          const Text(
            'The simple, fast and smart way to bill your clients and grow your business.',
            style: TextStyle(
              fontSize: 13.5,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),

          // Floating 3D Realistic Invoice Card Mockup (Scaled responsively)
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Soft glow behind invoice
                      Positioned(
                        top: -10,
                        left: 20,
                        right: 20,
                        bottom: -10,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Tilted Invoice Card
                      Transform.rotate(
                        angle: -0.04,
                        child: Container(
                          width: 290,
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Card Top Header
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: const [
                                  Text(
                                    'INVOICE',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.textPrimary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    '#INV-2024-001',
                                    style: TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Bill To Section
                              const Text(
                                'Bill To',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'John Smith',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const Text(
                                '+1 987 654 3210\njohn@example.com',
                                style: TextStyle(
                                  fontSize: 7.5,
                                  color: AppColors.textSecondary,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Table Header
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: const [
                                    Expanded(flex: 3, child: Text('Item', style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
                                    Expanded(flex: 1, child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                                    Expanded(flex: 2, child: Text('Amount', textAlign: TextAlign.right, style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),

                              // Table Rows
                              _invoiceRow('Web Design', '1', '\$450.00'),
                              _invoiceRow('Logo Design', '1', '\$150.00'),
                              _invoiceRow('Hosting (1 Year)', '1', '\$100.00'),

                              const Divider(color: Color(0xFFF1F5F9), height: 12),

                              // Subtotal & Tax
                              _summaryRow('Subtotal', '\$700.00'),
                              _summaryRow('Tax (18%)', '\$126.00'),
                              const SizedBox(height: 4),

                              // Total Highlight Box in Inka Orange Accent
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFECE8),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: const [
                                    Text(
                                      'Total',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFFBF360C),
                                      ),
                                    ),
                                    Text(
                                      '\$826.00',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Footer: Thank you & Stamp Seal
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Thank you!',
                                    style: TextStyle(
                                      fontFamily: 'serif',
                                      fontStyle: FontStyle.italic,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.inactive, width: 1),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.verified_outlined, size: 12, color: AppColors.primary),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Floating Lightning Shield Badge (Top Right)
                      Positioned(
                        top: -12,
                        right: 6,
                        child: Container(
                          width: 38,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF7A59), AppColors.primary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(10),
                              topRight: Radius.circular(10),
                              bottomLeft: Radius.circular(18),
                              bottomRight: Radius.circular(18),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.bolt_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _invoiceRow(String item, String qty, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5, horizontal: 4),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(item, style: const TextStyle(fontSize: 8, color: AppColors.textPrimary))),
          Expanded(flex: 1, child: Text(qty, textAlign: TextAlign.center, style: const TextStyle(fontSize: 8, color: AppColors.textSecondary))),
          Expanded(flex: 2, child: Text(amount, textAlign: TextAlign.right, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
        ],
      ),
    );
  }

  static Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 7.5, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 7.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SLIDE 2: WORKS OFFLINE. ALWAYS IN SYNC.
// ─────────────────────────────────────────────────────────────────────────────
class _Slide2OfflineSync extends StatelessWidget {
  const _Slide2OfflineSync();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          // Graphic Area with scaling
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Stack(
                    alignment: Alignment.topCenter,
                    clipBehavior: Clip.none,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 1. Floating Inka Theme Cloud with Sync Icon
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF7A59), AppColors.primary],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.35),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.sync_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),

                          // 2. Dashed Sync Beam Line
                          CustomPaint(
                            size: const Size(2, 28),
                            painter: _DashedLinePainter(color: const Color(0xFFFFAB91)),
                          ),

                          // 3. Smartphone Mockup with Inka Dark Surface Bezel
                          Container(
                            width: 205,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.darkCard,
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 30,
                                  offset: const Offset(0, 16),
                                ),
                              ],
                            ),
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Top camera notch pill
                                  Container(
                                    width: 36,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE2E8F0),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // List Items
                                  _phoneListItem(
                                    icon: Icons.receipt_long_rounded,
                                    iconColor: AppColors.primary,
                                    iconBg: const Color(0xFFFFECE8),
                                    title: 'Invoices',
                                    count: '24',
                                  ),
                                  const SizedBox(height: 8),
                                  _phoneListItem(
                                    icon: Icons.people_alt_rounded,
                                    iconColor: const Color(0xFF3B82F6),
                                    iconBg: const Color(0xFFEFF6FF),
                                    title: 'Clients',
                                    count: '32',
                                  ),
                                  const SizedBox(height: 8),
                                  _phoneListItem(
                                    icon: Icons.inventory_2_rounded,
                                    iconColor: const Color(0xFFF59E0B),
                                    iconBg: const Color(0xFFFFFBEB),
                                    title: 'Products',
                                    count: '18',
                                  ),
                                  const SizedBox(height: 8),
                                  _phoneListItem(
                                    icon: Icons.credit_card_rounded,
                                    iconColor: AppColors.success,
                                    iconBg: const Color(0xFFECFDF5),
                                    title: 'Payments',
                                    count: '12',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Small bottom cloud badge
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFECE8),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.cloud_outlined,
                              color: AppColors.primary,
                              size: 16,
                            ),
                          ),
                        ],
                      ),

                      // Floating Green Checkmark Shield (Bottom Right of phone)
                      Positioned(
                        bottom: 40,
                        right: -10,
                        child: Container(
                          width: 36,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF34D399), AppColors.success],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(10),
                              topRight: Radius.circular(10),
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.success.withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Title & Subtitle Footer
          const Text(
            'Works Offline.\nAlways in Sync.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create invoices anytime, anywhere. Your data is safely stored on your device and synced to the cloud when you\'re back online.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  static Widget _phoneListItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String count,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            count,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SLIDE 3: EVERYTHING YOU NEED TO GET PAID
// ─────────────────────────────────────────────────────────────────────────────
class _Slide3EverythingToGetPaid extends StatelessWidget {
  const _Slide3EverythingToGetPaid();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          // Graphic Area with scaling
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // Center Invoice Receipt Card
                      Container(
                        width: 230,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              blurRadius: 36,
                              spreadRadius: 4,
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Top Bar
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text(
                                  'INVOICE',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textPrimary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  '#INV-2024-001',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Bill To info
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text('Bill To', style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                                  Text('John Smith', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                  Text('+1 987 654 3210 • john@example.com', style: TextStyle(fontSize: 7, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Total Amount Banner
                            const Text(
                              'Total Amount',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              '\$826.00',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Scan & Pay label
                            const Text(
                              'Scan & Pay',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),

                            // QR Code
                            Container(
                              width: 82,
                              height: 82,
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                              ),
                              child: QrImageView(
                                data: 'upi://pay?pa=business@okhdfcbank&pn=Inka&am=826.00&cu=USD',
                                version: QrVersions.auto,
                                size: 72,
                                gapless: true,
                                padding: EdgeInsets.zero,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // UPI ID
                            const Text(
                              'UPI ID: business@okhdfcbank',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Orbiting Badge 1: Mic / Voice AI (Top Left in Inka Theme)
                      Positioned(
                        top: 20,
                        left: -18,
                        child: _floatingOrbBadge(
                          icon: Icons.mic_rounded,
                          gradientColors: [const Color(0xFFFF7A59), AppColors.primary],
                          shadowColor: AppColors.primary,
                          size: 38,
                        ),
                      ),

                      // Orbiting Badge 2: User Profile (Top Right)
                      Positioned(
                        top: 40,
                        right: -16,
                        child: _floatingOrbBadge(
                          icon: Icons.person_rounded,
                          gradientColors: [const Color(0xFF34D399), AppColors.success],
                          shadowColor: AppColors.success,
                          size: 32,
                        ),
                      ),

                      // Orbiting Badge 3: Currency / Rupee (Bottom Right)
                      Positioned(
                        bottom: 40,
                        right: -20,
                        child: _floatingOrbBadge(
                          icon: Icons.currency_rupee_rounded,
                          gradientColors: [const Color(0xFFFBBF24), AppColors.warning],
                          shadowColor: AppColors.warning,
                          size: 38,
                        ),
                      ),

                      // Orbiting Badge 4: Rocket Speed (Bottom Center)
                      Positioned(
                        bottom: -18,
                        child: _floatingOrbBadge(
                          icon: Icons.rocket_launch_rounded,
                          gradientColors: [const Color(0xFFFF7A59), AppColors.primary],
                          shadowColor: AppColors.primary,
                          size: 36,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Title & Subtitle Footer
          const Text(
            'Everything You Need\nto Get Paid',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Voice to text, UPI payments, tax calculations, client & product management and powerful insights. All in one place.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  static Widget _floatingOrbBadge({
    required IconData icon,
    required List<Color> gradientColors,
    required Color shadowColor,
    required double size,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          icon,
          color: Colors.white,
          size: size * 0.52,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DASHED LINE PAINTER FOR SLIDE 2
// ─────────────────────────────────────────────────────────────────────────────
class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const double dashHeight = 3.5;
    const double dashSpace = 3.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, math.min(startY + dashHeight, size.height)),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
