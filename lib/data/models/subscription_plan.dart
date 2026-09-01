import 'package:flutter/material.dart';

enum SubscriptionTier {
  free,
  pro,
  freelancerPlus,
}

enum BillingCycle {
  monthly,
  yearly,
}

class PlanFeature {
  final String title;
  final String? subtitle;
  final IconData icon;
  final bool isIncluded;

  const PlanFeature({
    required this.title,
    this.subtitle,
    required this.icon,
    this.isIncluded = true,
  });
}

class SubscriptionPlan {
  final SubscriptionTier tier;
  final String name;
  final String badge;
  final String targetAudience;
  final double monthlyPrice;
  final double yearlyPrice;
  final String description;
  final List<String> featureBullets;
  final List<PlanFeature> detailedFeatures;
  final bool isPopular;
  final Color primaryColor;

  const SubscriptionPlan({
    required this.tier,
    required this.name,
    required this.badge,
    required this.targetAudience,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.description,
    required this.featureBullets,
    required this.detailedFeatures,
    this.isPopular = false,
    required this.primaryColor,
  });

  static const List<SubscriptionPlan> allPlans = [
    // 1. FREE — Start Freelancing
    SubscriptionPlan(
      tier: SubscriptionTier.free,
      name: 'Free',
      badge: '🆓 FREE',
      targetAudience: 'For new freelancers',
      monthlyPrice: 0,
      yearlyPrice: 0,
      description: 'The free plan is genuinely useful so freelancers love the app. Create, send, and get paid forever free.',
      primaryColor: Color(0xFF64748B),
      isPopular: false,
      featureBullets: [
        'Unlimited invoice creation',
        'UPI QR code payments (GPay, PhonePe, Paytm)',
        'Basic professional PDF invoices',
        'Client management directory',
        'Payment status tracking (Pending/Paid)',
        'GST & Regional tax calculation',
        '100% Offline-first access',
      ],
      detailedFeatures: [
        PlanFeature(title: 'Unlimited Invoices', subtitle: 'Create & share unlimited invoices', icon: Icons.receipt_long_rounded),
        PlanFeature(title: 'UPI QR Payments', subtitle: 'Embed instant QR code on invoices', icon: Icons.qr_code_2_rounded),
        PlanFeature(title: 'Basic PDF Invoices', subtitle: 'Clean, printable A4 PDF templates', icon: Icons.picture_as_pdf_rounded),
        PlanFeature(title: 'Client Management', subtitle: 'Save client contacts and addresses', icon: Icons.people_rounded),
        PlanFeature(title: 'Offline Access', subtitle: 'Works seamlessly without internet', icon: Icons.wifi_off_rounded),
      ],
    ),

    // 2. PRO — For Active Freelancers ⭐
    SubscriptionPlan(
      tier: SubscriptionTier.pro,
      name: 'Pro',
      badge: '⚡ PRO',
      targetAudience: 'For active freelancers ⭐',
      monthlyPrice: 99,
      yearlyPrice: 999, // Save ~16%
      description: 'Get paid faster, look more professional, and never lose your billing data.',
      primaryColor: Color(0xFFFF533D),
      isPopular: true,
      featureBullets: [
        'Everything in Free, plus:',
        '💰 Payment reminders for overdue invoices (WhatsApp/SMS)',
        '⏰ Due-date alerts & quick 1-tap "Mark as Paid"',
        '✨ Business logo on invoices & digital signature',
        '🎨 Remove Inka branding & watermark',
        '☁️ Cloud backup & multi-device sync',
        '📊 Monthly earnings, pending & overdue insights',
      ],
      detailedFeatures: [
        PlanFeature(title: 'Get Paid Faster', subtitle: '1-Tap payment reminders on WhatsApp/SMS', icon: Icons.send_rounded),
        PlanFeature(title: 'Look More Professional', subtitle: 'Custom business logo & official signature', icon: Icons.verified_rounded),
        PlanFeature(title: 'No Inka Branding', subtitle: 'Deliver 100% white-label invoices', icon: Icons.branding_watermark_outlined),
        PlanFeature(title: 'Cloud Backup & Sync', subtitle: 'Never lose your invoices across devices', icon: Icons.cloud_sync_rounded),
        PlanFeature(title: 'Financial Analytics', subtitle: 'Monthly earnings & overdue tracking', icon: Icons.insights_rounded),
      ],
    ),

    // 3. FREELANCER PLUS — For Growing Freelancers 👑
    SubscriptionPlan(
      tier: SubscriptionTier.freelancerPlus,
      name: 'Freelancer Plus',
      badge: '👑 FREELANCER PLUS',
      targetAudience: 'For freelancers who are growing',
      monthlyPrice: 199,
      yearlyPrice: 1999, // Save ~16%
      description: 'Freelance-focused power tools and smart productivity for expanding client rosters.',
      primaryColor: Color(0xFF8B5CF6),
      isPopular: false,
      featureBullets: [
        'Everything in Pro, plus:',
        '🚀 Create quotations & estimates → convert to invoice',
        '🔄 Recurring invoices for monthly retainer clients',
        '🏢 Multiple business profiles & brands',
        '🤖 Voice AI invoice creation',
        '📥 Export financial data (CSV/Excel reports)',
        '⚡ Priority customer support',
      ],
      detailedFeatures: [
        PlanFeature(title: 'Quotations to Invoices', subtitle: 'Send estimates and convert in 1 tap', icon: Icons.request_quote_rounded),
        PlanFeature(title: 'Recurring Retainers', subtitle: 'Automate monthly client invoices', icon: Icons.autorenew_rounded),
        PlanFeature(title: 'Multiple Business Profiles', subtitle: 'Manage multiple freelance identities', icon: Icons.business_rounded),
        PlanFeature(title: 'Voice AI Creation', subtitle: 'Speak to create invoice items instantly', icon: Icons.mic_rounded),
        PlanFeature(title: 'Data Export (CSV/Excel)', subtitle: 'Export for tax filing and accountants', icon: Icons.file_download_rounded),
        PlanFeature(title: 'Priority Support', subtitle: 'Fast-track customer assistance', icon: Icons.support_agent_rounded),
      ],
    ),
  ];
}
