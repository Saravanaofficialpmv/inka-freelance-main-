import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/subscription_plan.dart';

class UserSubscriptionState {
  final SubscriptionTier tier;
  final BillingCycle billingCycle;
  final DateTime? expiryDate;
  final bool autoRenew;

  const UserSubscriptionState({
    this.tier = SubscriptionTier.free,
    this.billingCycle = BillingCycle.monthly,
    this.expiryDate,
    this.autoRenew = true,
  });

  bool get isFree => tier == SubscriptionTier.free;
  bool get isPro => tier == SubscriptionTier.pro;
  bool get isFreelancerPlus => tier == SubscriptionTier.freelancerPlus;
  bool get isProOrHigher => tier == SubscriptionTier.pro || tier == SubscriptionTier.freelancerPlus;

  SubscriptionPlan get plan => SubscriptionPlan.allPlans.firstWhere(
        (p) => p.tier == tier,
        orElse: () => SubscriptionPlan.allPlans.first,
      );

  UserSubscriptionState copyWith({
    SubscriptionTier? tier,
    BillingCycle? billingCycle,
    DateTime? expiryDate,
    bool? autoRenew,
  }) {
    return UserSubscriptionState(
      tier: tier ?? this.tier,
      billingCycle: billingCycle ?? this.billingCycle,
      expiryDate: expiryDate ?? this.expiryDate,
      autoRenew: autoRenew ?? this.autoRenew,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tier': tier.name,
      'billingCycle': billingCycle.name,
      'expiryDate': expiryDate?.toIso8601String(),
      'autoRenew': autoRenew,
    };
  }

  factory UserSubscriptionState.fromMap(Map<String, dynamic> map) {
    SubscriptionTier parseTier(String? val) {
      if (val == 'pro') return SubscriptionTier.pro;
      if (val == 'freelancerPlus') return SubscriptionTier.freelancerPlus;
      return SubscriptionTier.free;
    }

    BillingCycle parseCycle(String? val) {
      if (val == 'yearly') return BillingCycle.yearly;
      return BillingCycle.monthly;
    }

    return UserSubscriptionState(
      tier: parseTier(map['tier'] as String?),
      billingCycle: parseCycle(map['billingCycle'] as String?),
      expiryDate: map['expiryDate'] != null ? DateTime.tryParse(map['expiryDate'] as String) : null,
      autoRenew: map['autoRenew'] as bool? ?? true,
    );
  }
}

final subscriptionProvider = StateNotifierProvider<SubscriptionNotifier, UserSubscriptionState>((ref) {
  return SubscriptionNotifier();
});

class SubscriptionNotifier extends StateNotifier<UserSubscriptionState> {
  static const String _boxName = 'subscription_prefs';
  static const String _boxKey = 'user_subscription';

  SubscriptionNotifier() : super(const UserSubscriptionState()) {
    _loadFromLocal();
  }

  void _loadFromLocal() {
    try {
      if (Hive.isBoxOpen(_boxName)) {
        final box = Hive.box(_boxName);
        final raw = box.get(_boxKey);
        if (raw is Map) {
          state = UserSubscriptionState.fromMap(Map<String, dynamic>.from(raw));
        }
      }
    } catch (_) {}
  }

  Future<void> upgradePlan({
    required SubscriptionTier newTier,
    required BillingCycle cycle,
  }) async {
    final now = DateTime.now();
    final expiry = cycle == BillingCycle.monthly
        ? DateTime(now.year, now.month + 1, now.day)
        : DateTime(now.year + 1, now.month, now.day);

    state = UserSubscriptionState(
      tier: newTier,
      billingCycle: cycle,
      expiryDate: expiry,
      autoRenew: true,
    );

    await _persist();
  }

  Future<void> cancelSubscription() async {
    state = const UserSubscriptionState(tier: SubscriptionTier.free);
    await _persist();
  }

  Future<void> _persist() async {
    try {
      if (Hive.isBoxOpen(_boxName)) {
        final box = Hive.box(_boxName);
        await box.put(_boxKey, state.toMap());
      }
    } catch (_) {}
  }
}
