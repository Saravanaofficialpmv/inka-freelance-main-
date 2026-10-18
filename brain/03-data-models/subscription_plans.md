# 03. Data Models — Subscription Plans & Monetization

Inka defines structured monetization tiers in `lib/data/models/subscription_plan.dart` to support feature gating and tiered billing capabilities.

---

## 💎 Subscription Tiers

```dart
enum SubscriptionTier {
  free,           // Starter plan for early freelancers
  pro,            // Professional plan with unmetered invoicing & templates
  freelancerPlus, // Enterprise/Agency tier with team & multi-business support
}

enum BillingCycle {
  monthly,
  yearly,
}
```

---

## 📊 Tier Comparison Table

| Feature / Limit | Free Tier | Pro Tier | Freelancer Plus |
| :--- | :--- | :--- | :--- |
| **Price (Monthly / Yearly)** | $0 / Free | $4.99 / $49.99 | $9.99 / $99.99 |
| **Monthly Invoices** | Up to 5 invoices | Unlimited | Unlimited |
| **PDF Templates** | 2 Basic templates | All 10+ Premium templates | All + Custom Branding |
| **Dynamic UPI QR Code** | Included | Included | Included |
| **Client Management** | Up to 10 clients | Unlimited | Unlimited |
| **Time Tracking** | Basic stopwatch | Full project time tracking | Advanced reporting & exports |
| **Cloud Auto-Sync** | Manual / standard | Real-time multi-device | Real-time + automated backups |
| **Watermark** | Subtle "Powered by Inka" | Removed | Removed |

---

## ⚙️ State Management
- **Hive Box**: `subscription_prefs`
- **Riverpod Provider**: `subscriptionProvider` (`lib/presentation/providers/subscription_provider.dart`)
- **UI Screen**: `SubscriptionScreen` (`lib/presentation/screens/subscription_screen.dart`)
