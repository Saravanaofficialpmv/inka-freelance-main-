import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_motion.dart';
import '../../core/constants/colors.dart';
import 'custom_bottom_nav.dart';
import 'web_sidebar.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/subscription_provider.dart';
import '../screens/create_invoice_screen.dart';
import 'notifications_sheet.dart';

class NavShell extends ConsumerWidget {
  final Widget child;
  final GoRouterState state;
  const NavShell({super.key, required this.child, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = state.matchedLocation;
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final bool reducedMotion = AppMotion.isReducedMotion(context);
    int currentIndex = 0;

    if (location.startsWith('/dashboard')) {
      currentIndex = 0;
    } else if (location.startsWith('/history') || location.startsWith('/preview')) {
      currentIndex = 1;
    } else if (location.startsWith('/clients') ||
        location.startsWith('/client-details') ||
        location.startsWith('/clients-tab')) {
      currentIndex = 2;
    } else if (location.startsWith('/expenses')) {
      currentIndex = 3;
    } else if (location.startsWith('/profile') ||
        location.startsWith('/company-details') ||
        location.startsWith('/bank-details') ||
        location.startsWith('/signatures') ||
        location.startsWith('/document-settings') ||
        location.startsWith('/templates') ||
        location.startsWith('/notes-terms') ||
        location.startsWith('/currency-settings') ||
        location.startsWith('/language-settings') ||
        location.startsWith('/subscription') ||
        location.startsWith('/help-support') ||
        location.startsWith('/privacy-policy') ||
        location.startsWith('/products')) {
      currentIndex = 4;
    } else {
      currentIndex = -1;
    }

    final Widget animatedContent = AnimatedSwitcher(
      duration: reducedMotion ? Duration.zero : AppMotion.navigation,
      switchInCurve: AppMotion.entrance,
      switchOutCurve: AppMotion.stateChange,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          fit: StackFit.expand,
          alignment: Alignment.topLeft,
          children: <Widget>[
            ...previousChildren,
            ?currentChild,
          ],
        );
      },
      transitionBuilder: (child, animation) {
        if (reducedMotion) return child;
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.015, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: AppMotion.entrance)),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(location),
        child: child,
      ),
    );

    if (isWide) {
      return Scaffold(
        backgroundColor: AppColors.background, // Miro-inspired outer frame background
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WebSidebar(
              currentLocation: location,
              currentIndex: currentIndex,
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(4, 10, 14, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.border,
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _WebCanvasTopBar(currentLocation: location),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFF1F3F5)),
                    Expanded(
                      child: animatedContent,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Stack(
        children: [
          animatedContent,
          if (currentIndex >= 0)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: CustomBottomNav(currentIndex: currentIndex),
            ),
        ],
      ),
    );
  }
}

class _WebCanvasTopBar extends ConsumerWidget {
  final String currentLocation;
  const _WebCanvasTopBar({required this.currentLocation});

  String _getPageTitle(String location) {
    if (location.startsWith('/dashboard')) return 'Dashboard';
    if (location.startsWith('/history') || location.startsWith('/preview')) return 'Invoices';
    if (location.startsWith('/projects') ||
        location.startsWith('/add-project') ||
        location.startsWith('/edit-project') ||
        location.startsWith('/project-details')) {
      return 'Projects';
    }
    if (location.startsWith('/clients') || location.startsWith('/client-details') || location.startsWith('/clients-tab')) {
      return 'Clients';
    }
    if (location.startsWith('/products')) return 'Products';
    if (location.startsWith('/expenses')) return 'Expenses & Stats';
    if (location.startsWith('/settings') || location.startsWith('/profile')) return 'Settings';
    if (location.startsWith('/subscription')) return 'Subscription';
    return 'Dashboard';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final profile = ref.watch(profileProvider);
    final subState = ref.watch(subscriptionProvider);
    final user = authState.value;

    final String displayName = profile.businessName.isNotEmpty
        ? profile.businessName
        : (user?.displayName ?? user?.email?.split('@').first ?? 'saravana');

    final String initials = displayName.trim().isNotEmpty
        ? (displayName.trim().length >= 2
            ? displayName.trim().substring(0, 2).toUpperCase()
            : displayName.trim()[0].toUpperCase())
        : 'SA';

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      color: Colors.white,
      child: Row(
        children: [
          // ── Left: Page Title & Plan Pill ──
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: AppMotion.standard,
                switchInCurve: AppMotion.entrance,
                switchOutCurve: AppMotion.stateChange,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, 0.15),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  _getPageTitle(currentLocation),
                  key: ValueKey<String>(_getPageTitle(currentLocation)),
                  style: const TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: () => context.go('/subscription'),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.iconBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.25), width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        subState.isProOrHigher ? 'Pro plan' : 'Free plan',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 12),

          // ── Right: Action Buttons & Icons ──
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. Invite members button
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppColors.textPrimary,
                            content: Row(
                              children: [
                                Icon(Icons.check_circle, color: AppColors.success, size: 18),
                                SizedBox(width: 10),
                                Text('Workspace invite link copied to clipboard!'),
                              ],
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.person_add_outlined, size: 14, color: AppColors.textPrimary),
                      label: const Text(
                        'Invite members',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFF9FAFB),
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),

                    const SizedBox(width: 10),

                    // 2. Inka Orange CTA: "+ Create Invoice"
                    ElevatedButton.icon(
                      onPressed: () => CreateInvoiceScreen.showAsBottomSheet(context),
                      icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                      label: const Text(
                        'Create Invoice',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),

                    const SizedBox(width: 12),

                    // 3. Subscription & Perks icon
                    IconButton(
                      onPressed: () => context.go('/subscription'),
                      icon: const Icon(Icons.card_giftcard_outlined, size: 20, color: AppColors.textSecondary),
                      tooltip: 'Subscription & Perks',
                      splashRadius: 18,
                    ),

                    // 4. Notification bell icon
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          onPressed: () => NotificationsSheet.show(context),
                          icon: const Icon(Icons.notifications_none_rounded, size: 21, color: AppColors.textSecondary),
                          tooltip: 'Notifications & Activity',
                          splashRadius: 18,
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 4),

                    // 5. User Avatar with Inka Orange tint
                    InkWell(
                      onTap: () => context.go('/profile'),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.iconBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.35), width: 1.2),
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
