import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/colors.dart';
import '../providers/profile_provider.dart';
import '../../services/firestore_service.dart';
import '../widgets/inka_brand_logo.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _controller.forward();
    _handleNavigation();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleNavigation() async {
    try {
      // Show splash screen for smooth branded entrance
      await Future.delayed(const Duration(milliseconds: 1800));
      if (!mounted) return;

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // 1. Check current Riverpod profile
        var profile = ref.read(profileProvider);

        // 2. If empty in memory, check Firestore with timeout
        if (profile.businessName.isEmpty) {
          try {
            final firestoreService = ref.read(firestoreServiceProvider);
            final remoteProfile = await firestoreService
                .getBusinessProfile(userId: user.uid)
                .timeout(const Duration(seconds: 3));
            if (remoteProfile != null && remoteProfile.businessName.isNotEmpty) {
              await ref.read(profileProvider.notifier).updateProfileLocally(remoteProfile);
              profile = remoteProfile;
            }
          } catch (_) {}
        }

        if (!mounted) return;

        if (profile.businessName.isEmpty) {
          context.go('/business-setup');
        } else {
          context.go('/dashboard');
        }
      } else {
        context.go('/onboarding');
      }
    } catch (e) {
      if (mounted) context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),

                      // ── Official Inka Slash Logo ──
                      const InkaBrandLogo(
                        fontSize: 60,
                      ),
                      const SizedBox(height: 18),

                      // ── Tagline ──
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          'CREATE  •  SHARE  •  GET PAID',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),

                      const Spacer(),

                      // ── Minimal Loading Indicator & Footer ──
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF5722)),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
