import 'package:flutter/material.dart';

/// Supported layout density levels for invoice rendering.
enum InvoiceDensity {
  compact,
  normal,
  spacious;

  static InvoiceDensity fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'compact':
        return InvoiceDensity.compact;
      case 'spacious':
        return InvoiceDensity.spacious;
      case 'normal':
      default:
        return InvoiceDensity.normal;
    }
  }

  String get nameString {
    switch (this) {
      case InvoiceDensity.compact:
        return 'compact';
      case InvoiceDensity.spacious:
        return 'spacious';
      case InvoiceDensity.normal:
        return 'normal';
    }
  }
}

/// Supported page formats for templates that support alternative roll formats.
enum InvoicePageFormatType {
  a4,
  thermalRoll;

  static InvoicePageFormatType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'thermalroll':
      case 'thermal_roll':
      case 'thermal':
      case 'receipt':
        return InvoicePageFormatType.thermalRoll;
      case 'a4':
      default:
        return InvoicePageFormatType.a4;
    }
  }

  String get nameString {
    switch (this) {
      case InvoicePageFormatType.thermalRoll:
        return 'thermal_roll';
      case InvoicePageFormatType.a4:
        return 'a4';
    }
  }
}

/// Curated brand colors for invoice accent elements.
class InvoiceBrandColor {
  final String name;
  final String hex;
  final Color color;

  const InvoiceBrandColor({
    required this.name,
    required this.hex,
    required this.color,
  });

  static const List<InvoiceBrandColor> curatedPalette = [
    InvoiceBrandColor(name: 'Inka Coral', hex: '#FF533D', color: Color(0xFFFF533D)),
    InvoiceBrandColor(name: 'Deep Navy', hex: '#1E3A8A', color: Color(0xFF1E3A8A)),
    InvoiceBrandColor(name: 'Royal Blue', hex: '#2563EB', color: Color(0xFF2563EB)),
    InvoiceBrandColor(name: 'Violet', hex: '#7C3AED', color: Color(0xFF7C3AED)),
    InvoiceBrandColor(name: 'Warm Orange', hex: '#EA580C', color: Color(0xFFEA580C)),
    InvoiceBrandColor(name: 'Charcoal Black', hex: '#18181B', color: Color(0xFF18181B)),
    InvoiceBrandColor(name: 'Teal', hex: '#0D9488', color: Color(0xFF0D9488)),
    InvoiceBrandColor(name: 'Burgundy', hex: '#991B1B', color: Color(0xFF991B1B)),
  ];

  static InvoiceBrandColor find(String? hex) {
    if (hex == null || hex.isEmpty) return curatedPalette.first;
    final clean = hex.toUpperCase();
    return curatedPalette.firstWhere(
      (c) => c.hex.toUpperCase() == clean,
      orElse: () => InvoiceBrandColor(name: 'Custom', hex: hex, color: Color(int.parse(hex.replaceFirst('#', '0xFF')))),
    );
  }
}

/// Complete configuration for invoice styling, density, and section visibility.
class InvoiceTemplateConfig {
  final String templateId;
  final String accentColorHex;
  final InvoiceDensity density;
  final InvoicePageFormatType pageFormat;
  final bool showLogo;
  final bool showSignature;
  final bool showQrCode;
  final bool showBankDetails;
  final bool showContactDetails;
  final bool showNotesAndTerms;

  const InvoiceTemplateConfig({
    this.templateId = 'minimal_clean',
    this.accentColorHex = '#FF533D',
    this.density = InvoiceDensity.normal,
    this.pageFormat = InvoicePageFormatType.a4,
    this.showLogo = true,
    this.showSignature = true,
    this.showQrCode = true,
    this.showBankDetails = true,
    this.showContactDetails = true,
    this.showNotesAndTerms = true,
  });

  factory InvoiceTemplateConfig.defaultConfig() {
    return const InvoiceTemplateConfig();
  }

  InvoiceTemplateConfig copyWith({
    String? templateId,
    String? accentColorHex,
    InvoiceDensity? density,
    InvoicePageFormatType? pageFormat,
    bool? showLogo,
    bool? showSignature,
    bool? showQrCode,
    bool? showBankDetails,
    bool? showContactDetails,
    bool? showNotesAndTerms,
  }) {
    return InvoiceTemplateConfig(
      templateId: templateId ?? this.templateId,
      accentColorHex: accentColorHex ?? this.accentColorHex,
      density: density ?? this.density,
      pageFormat: pageFormat ?? this.pageFormat,
      showLogo: showLogo ?? this.showLogo,
      showSignature: showSignature ?? this.showSignature,
      showQrCode: showQrCode ?? this.showQrCode,
      showBankDetails: showBankDetails ?? this.showBankDetails,
      showContactDetails: showContactDetails ?? this.showContactDetails,
      showNotesAndTerms: showNotesAndTerms ?? this.showNotesAndTerms,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'templateId': templateId,
      'accentColorHex': accentColorHex,
      'density': density.nameString,
      'pageFormat': pageFormat.nameString,
      'showLogo': showLogo,
      'showSignature': showSignature,
      'showQrCode': showQrCode,
      'showBankDetails': showBankDetails,
      'showContactDetails': showContactDetails,
      'showNotesAndTerms': showNotesAndTerms,
    };
  }

  factory InvoiceTemplateConfig.fromMap(Map<String, dynamic>? map) {
    if (map == null) return InvoiceTemplateConfig.defaultConfig();
    return InvoiceTemplateConfig(
      templateId: map['templateId'] as String? ?? 'minimal_clean',
      accentColorHex: map['accentColorHex'] as String? ?? '#FF533D',
      density: InvoiceDensity.fromString(map['density'] as String?),
      pageFormat: InvoicePageFormatType.fromString(map['pageFormat'] as String?),
      showLogo: map['showLogo'] as bool? ?? true,
      showSignature: map['showSignature'] as bool? ?? true,
      showQrCode: map['showQrCode'] as bool? ?? true,
      showBankDetails: map['showBankDetails'] as bool? ?? true,
      showContactDetails: map['showContactDetails'] as bool? ?? true,
      showNotesAndTerms: map['showNotesAndTerms'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvoiceTemplateConfig &&
          runtimeType == other.runtimeType &&
          templateId == other.templateId &&
          accentColorHex == other.accentColorHex &&
          density == other.density &&
          pageFormat == other.pageFormat &&
          showLogo == other.showLogo &&
          showSignature == other.showSignature &&
          showQrCode == other.showQrCode &&
          showBankDetails == other.showBankDetails &&
          showContactDetails == other.showContactDetails &&
          showNotesAndTerms == other.showNotesAndTerms;

  @override
  int get hashCode =>
      templateId.hashCode ^
      accentColorHex.hashCode ^
      density.hashCode ^
      pageFormat.hashCode ^
      showLogo.hashCode ^
      showSignature.hashCode ^
      showQrCode.hashCode ^
      showBankDetails.hashCode ^
      showContactDetails.hashCode ^
      showNotesAndTerms.hashCode;
}
