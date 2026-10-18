# 03. Data Models — Business Profile

The `BusinessProfile` model (`lib/data/models/business_profile.dart`, Hive TypeId: 4) stores the user's business metadata, bank details, tax identifiers, branding assets, and default billing terms.

---

## 📐 Entity Schema

```dart
@HiveType(typeId: 4)
class BusinessProfile extends HiveObject {
  @HiveField(0)  final String businessName;       // Company or freelancer trade name
  @HiveField(1)  final String address;            // Street address, city, state, postal code
  @HiveField(2)  final String phone;              // Business contact phone number
  @HiveField(3)  final String email;              // Business communication email
  @HiveField(4)  final String currency;           // Currency symbol (default: '₹' or '$')
  @HiveField(5)  final String? logoUrl;           // Local file path or cloud URI of company logo
  @HiveField(6)  final String? gstNumber;         // GSTIN / Tax Identification Number
  @HiveField(7)  final String? accountHolderName; // Bank account beneficiary name
  @HiveField(8)  final String? accountNo;         // Bank account number
  @HiveField(9)  final String? ifscCode;          // Bank IFSC, Routing, or SWIFT code
  @HiveField(10) final String? bankName;          // Financial institution name
  @HiveField(11) final String? branchName;        // Branch office location
  @HiveField(12) final String? upiId;             // UPI Virtual Payment Address (e.g. name@okhdfcbank)
  @HiveField(13) final String? upiNumber;         // Phone/UPI linked number
  @HiveField(14) final String? signatureUrl;      // File path of saved digital signature image
  @HiveField(15) final String? defaultNotes;      // Reusable default footer notes & terms
  @HiveField(16) final String? invoicePrefix;     // Default invoice number prefix (e.g. 'INV-')
  @HiveField(17) final double? defaultTaxRate;    // Default tax rate percentage (e.g. 18.0)
}
```

---

## ⚙️ Persistence & State Management
- **Hive Box**: `business_profile` (Key: `'current_profile'`)
- **Riverpod Provider**: `profileProvider` (`lib/presentation/providers/profile_provider.dart`)
- **Firestore Document**: `/users/{uid}/profile/business`
