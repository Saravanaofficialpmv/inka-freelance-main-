import 'package:flutter_test/flutter_test.dart';
import 'package:inka/data/models/subscription_plan.dart';
import 'package:inka/presentation/providers/subscription_provider.dart';

void main() {
  group('Subscription & Pricing Plans Tests', () {
    test('Free plan is ₹0 and contains core invoicing features', () {
      final freePlan = SubscriptionPlan.allPlans.firstWhere((p) => p.tier == SubscriptionTier.free);
      expect(freePlan.monthlyPrice, 0.0);
      expect(freePlan.yearlyPrice, 0.0);
      expect(freePlan.featureBullets, contains('Unlimited invoice creation'));
      expect(freePlan.featureBullets, contains('UPI QR code payments (GPay, PhonePe, Paytm)'));
      expect(freePlan.featureBullets, contains('100% Offline-first access'));
    });

    test('Pro plan is ₹99/mo and contains active freelancer power features', () {
      final proPlan = SubscriptionPlan.allPlans.firstWhere((p) => p.tier == SubscriptionTier.pro);
      expect(proPlan.monthlyPrice, 99.0);
      expect(proPlan.yearlyPrice, 999.0);
      expect(proPlan.isPopular, isTrue);
      expect(proPlan.targetAudience, contains('For active freelancers'));
      expect(proPlan.featureBullets.any((b) => b.contains('Payment reminders')), isTrue);
      expect(proPlan.featureBullets.any((b) => b.contains('Business logo')), isTrue);
      expect(proPlan.featureBullets.any((b) => b.contains('Cloud backup')), isTrue);
    });

    test('Freelancer Plus plan is ₹199/mo and contains growing freelancer tools', () {
      final plusPlan = SubscriptionPlan.allPlans.firstWhere((p) => p.tier == SubscriptionTier.freelancerPlus);
      expect(plusPlan.monthlyPrice, 199.0);
      expect(plusPlan.yearlyPrice, 1999.0);
      expect(plusPlan.targetAudience, contains('For freelancers who are growing'));
      expect(plusPlan.name, 'Freelancer Plus');
      expect(plusPlan.featureBullets.any((b) => b.contains('Recurring invoices')), isTrue);
      expect(plusPlan.featureBullets.any((b) => b.contains('Multiple business profiles')), isTrue);
      expect(plusPlan.featureBullets.any((b) => b.contains('Voice AI')), isTrue);
    });

    test('UserSubscriptionState serialization and deserialization', () {
      const state = UserSubscriptionState(
        tier: SubscriptionTier.pro,
        billingCycle: BillingCycle.yearly,
        autoRenew: true,
      );

      final map = state.toMap();
      final restored = UserSubscriptionState.fromMap(map);

      expect(restored.tier, SubscriptionTier.pro);
      expect(restored.billingCycle, BillingCycle.yearly);
      expect(restored.isPro, isTrue);
      expect(restored.isProOrHigher, isTrue);
      expect(restored.isFree, isFalse);
    });
  });
}
