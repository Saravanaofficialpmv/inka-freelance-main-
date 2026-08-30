import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/profile_provider.dart';
import '../../services/firestore_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _handleNavigation();
  }

  Future<void> _handleNavigation() async {
    // Show splash screen for minimum duration
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // 1. Check current Riverpod profile
      var profile = ref.read(profileProvider);

      // 2. If empty in memory, check Firestore directly to avoid false business setup prompt
      if (profile.businessName.isEmpty) {
        final firestoreService = ref.read(firestoreServiceProvider);
        final remoteProfile = await firestoreService.getBusinessProfile(userId: user.uid);
        if (remoteProfile != null && remoteProfile.businessName.isNotEmpty) {
          await ref.read(profileProvider.notifier).updateProfileLocally(remoteProfile);
          profile = remoteProfile;
        }
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
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 80, color: Color(0xFFF97316)),
            SizedBox(height: 24),
            Text(
              'Inka',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Create Professional Invoices in Seconds',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
