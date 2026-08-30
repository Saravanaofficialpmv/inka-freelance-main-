import 'package:hive/hive.dart';

part 'business_profile.g.dart';

@HiveType(typeId: 4)
class BusinessProfile {
  @HiveField(0)
  final String businessName;

  @HiveField(1)
  final String address;

  @HiveField(2)
  final String phone;

  @HiveField(3)
  final String email;

  @HiveField(4)
  final String currency;

  @HiveField(5)
  final String? logoUrl;

  @HiveField(6)
  final String? gstNumber;

  @HiveField(7)
  final String? accountHolderName;

  @HiveField(8)
  final String? accountNo;

  @HiveField(9)
  final String? ifscCode;

  @HiveField(10)
  final String? bankName;

  @HiveField(11)
  final String? branchName;

  @HiveField(12)
  final String? upiId;

  @HiveField(13)
  final String? upiNumber;

  @HiveField(14)
  final String? signatureUrl;

  BusinessProfile({
    required this.businessName,
    required this.address,
    required this.phone,
    required this.email,
    required this.currency,
    this.logoUrl,
    this.gstNumber,
    this.accountHolderName,
    this.accountNo,
    this.ifscCode,
    this.bankName,
    this.branchName,
    this.upiId,
    this.upiNumber,
    this.signatureUrl,
  });

  factory BusinessProfile.empty() {
    return BusinessProfile(
      businessName: '',
      address: '',
      phone: '',
      email: '',
      currency: '\$',
      gstNumber: '',
      accountHolderName: '',
      accountNo: '',
      ifscCode: '',
      bankName: '',
      branchName: '',
      upiId: '',
      upiNumber: '',
      signatureUrl: '',
    );
  }

  BusinessProfile copyWith({
    String? businessName,
    String? address,
    String? phone,
    String? email,
    String? currency,
    String? logoUrl,
    String? gstNumber,
    String? accountHolderName,
    String? accountNo,
    String? ifscCode,
    String? bankName,
    String? branchName,
    String? upiId,
    String? upiNumber,
    String? signatureUrl,
  }) {
    return BusinessProfile(
      businessName: businessName ?? this.businessName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      currency: currency ?? this.currency,
      logoUrl: logoUrl ?? this.logoUrl,
      gstNumber: gstNumber ?? this.gstNumber,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      accountNo: accountNo ?? this.accountNo,
      ifscCode: ifscCode ?? this.ifscCode,
      bankName: bankName ?? this.bankName,
      branchName: branchName ?? this.branchName,
      upiId: upiId ?? this.upiId,
      upiNumber: upiNumber ?? this.upiNumber,
      signatureUrl: signatureUrl ?? this.signatureUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessName': businessName,
      'address': address,
      'phone': phone,
      'email': email,
      'currency': currency,
      'logoUrl': logoUrl,
      'gstNumber': gstNumber,
      'accountHolderName': accountHolderName,
      'accountNo': accountNo,
      'ifscCode': ifscCode,
      'bankName': bankName,
      'branchName': branchName,
      'upiId': upiId,
      'upiNumber': upiNumber,
      'signatureUrl': signatureUrl,
    };
  }

  factory BusinessProfile.fromMap(Map<String, dynamic> map) {
    return BusinessProfile(
      businessName: map['businessName'] ?? '',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      currency: map['currency'] ?? '\$',
      logoUrl: map['logoUrl'],
      gstNumber: map['gstNumber'],
      accountHolderName: map['accountHolderName'],
      accountNo: map['accountNo'],
      ifscCode: map['ifscCode'],
      bankName: map['bankName'],
      branchName: map['branchName'],
      upiId: map['upiId'],
      upiNumber: map['upiNumber'],
      signatureUrl: map['signatureUrl'],
    );
  }
}
