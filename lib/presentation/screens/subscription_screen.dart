import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/navigation_utils.dart';
import '../../data/models/subscription_plan.dart';
import '../providers/subscription_provider.dart';
import '../widgets/inka_brand_logo.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  BillingCycle _billingCycle = BillingCycle.monthly;

  void _handlePlanSelect(SubscriptionPlan plan, UserSubscriptionState currentSub) {
    if (plan.tier == currentSub.tier) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You are already on the ${plan.name} plan.'),
          backgroundColor: Colors.white,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (plan.tier == SubscriptionTier.free) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          title: const Text('Downgrade to Free Plan?', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          content: const Text(
            'You will keep basic unlimited invoicing, but premium features like logo branding, signature, and automatic reminders will be disabled.',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(subscriptionProvider.notifier).cancelSubscription();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Downgraded to Free plan.'),
                    backgroundColor: Colors.white,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
              child: const Text('Downgrade', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    // Upgrade Confirmation Dialog / Simulator
    final priceStr = _billingCycle == BillingCycle.monthly
        ? '₹${plan.monthlyPrice.toInt()}/month'
        : '₹${plan.yearlyPrice.toInt()}/year';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFECE8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                plan.badge,
                style: const TextStyle(color: Color(0xFFFF5722), fontWeight: FontWeight.w900, fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Upgrade to ${plan.name}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            Text(
              'Billed at $priceStr (${_billingCycle == BillingCycle.yearly ? 'Yearly' : 'Monthly'})',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13.5, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  for (final bullet in plan.featureBullets.take(3))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Color(0xFFFF5722), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(bullet, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ref.read(subscriptionProvider.notifier).upgradePlan(newTier: plan.tier, cycle: _billingCycle);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🎉 Congratulations! You are now on the ${plan.name} plan.'),
                      backgroundColor: const Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5722),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  'Activate ${plan.name} ($priceStr)',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentSub = ref.watch(subscriptionProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 14.0, 20.0, 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => safeNavigateBack(context, fallbackRoute: '/profile'),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF0F172A)),
                    ),
                  ),
                  const Text(
                    'Plans & Pricing',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Column(
                  children: [
                    const InkaBrandLogo(fontSize: 26),
                    const SizedBox(height: 16),
                    const Text(
                      'Simple, Transparent Pricing',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: Color(0xFF0F172A),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Basic invoicing is 100% free forever. Upgrade to get paid faster and grow your freelance business.',
                      style: TextStyle(fontSize: 13.5, color: Color(0xFF64748B), height: 1.35),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // ── Monthly / Yearly Cycle Switcher ──
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildCycleButton(
                            title: 'Monthly',
                            cycle: BillingCycle.monthly,
                          ),
                          _buildCycleButton(
                            title: 'Yearly (Save ~16%)',
                            cycle: BillingCycle.yearly,
                            isBestValue: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Plan Cards ──
                    for (final plan in SubscriptionPlan.allPlans)
                      _buildPlanCard(plan, currentSub),

                    const SizedBox(height: 12),

                    // ── Inka Freelancer Guarantee Note ──
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lightbulb_rounded, color: Color(0xFFFF5722), size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Our Promise to Freelancers 💡',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF0F172A)),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'We will never lock basic invoicing behind a paywall. A freelancer should always be able to Create Invoice → Share Invoice → Get Paid for free. Paid plans simply help you get paid faster, look more professional, and scale your business.',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan, UserSubscriptionState currentSub) {
    final isCurrent = plan.tier == currentSub.tier;
    final isPopular = plan.isPopular;
    final price = _billingCycle == BillingCycle.monthly ? plan.monthlyPrice : plan.yearlyPrice;
    final periodStr = plan.monthlyPrice == 0
        ? 'Forever'
        : (_billingCycle == BillingCycle.monthly ? '/ month' : '/ year');

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isCurrent
              ? const Color(0xFFFF5722)
              : (isPopular ? const Color(0xFFFF5722) : const Color(0xFFE2E8F0)),
          width: isCurrent || isPopular ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isPopular ? const Color(0xFFFF5722).withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPopular || isCurrent)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: isCurrent ? const Color(0xFF0F172A) : const Color(0xFFFF5722),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: Text(
                isCurrent ? 'ACTIVE PLAN' : 'MOST POPULAR FOR ACTIVE FREELANCERS ⭐',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.name,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          plan.targetAudience,
                          style: const TextStyle(color: Color(0xFFFF5722), fontSize: 12.5, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '₹${price.toInt()}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFFF5722),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          periodStr,
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  plan.description,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.35),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 16),

                // Bullet Points
                for (final feature in plan.featureBullets)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 17,
                          color: Color(0xFFFF5722),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            feature,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: feature.startsWith('Everything') ? FontWeight.w800 : FontWeight.w500,
                              color: const Color(0xFF0F172A),
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // CTA Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => _handlePlanSelect(plan, currentSub),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCurrent
                          ? const Color(0xFFF1F5F9)
                          : (isPopular ? const Color(0xFFFF5722) : const Color(0xFF0F172A)),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      isCurrent
                          ? 'Current Plan'
                          : (plan.tier == SubscriptionTier.free ? 'Stay on Free' : 'Upgrade to ${plan.name}'),
                      style: TextStyle(
                        color: isCurrent ? const Color(0xFF64748B) : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCycleButton({
    required String title,
    required BillingCycle cycle,
    bool isBestValue = false,
  }) {
    final isSelected = _billingCycle == cycle;
    return GestureDetector(
      onTap: () => setState(() => _billingCycle = cycle),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF5722) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF64748B),
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}
