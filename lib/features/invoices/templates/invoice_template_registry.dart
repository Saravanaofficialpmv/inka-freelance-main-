import 'branded_custom_template.dart';
import 'compact_thermal_template.dart';
import 'creative_modern_template.dart';
import 'dark_theme_template.dart';
import 'elegant_premium_template.dart';
import 'invoice_template.dart';
import 'minimal_clean_template.dart';
import 'modern_professional_template.dart';
import 'professional_classic_template.dart';
import 'retail_shop_template.dart';
import 'service_consultancy_template.dart';

/// Central registry for all 10 distinct invoice templates in Inka.
class InvoiceTemplateRegistry {
  static final List<InvoiceTemplate> allTemplates = [
    MinimalCleanTemplate(),
    ModernProfessionalTemplate(),
    ElegantPremiumTemplate(),
    CreativeModernTemplate(),
    ProfessionalClassicTemplate(),
    DarkThemeTemplate(),
    RetailShopTemplate(),
    ServiceConsultancyTemplate(),
    CompactThermalTemplate(),
    BrandedCustomTemplate(),
  ];

  static const String defaultTemplateId = 'minimal_clean';

  /// Resolves an invoice template by ID with safe backward compatibility
  /// for legacy database identifiers.
  static InvoiceTemplate getTemplate(String? id) {
    if (id == null || id.trim().isEmpty) {
      return allTemplates.firstWhere((t) => t.id == defaultTemplateId);
    }

    final normalized = id.trim().toLowerCase();

    // Direct match
    for (final template in allTemplates) {
      if (template.id == normalized) {
        return template;
      }
    }

    // Reference templates & legacy fallback mapping
    switch (normalized) {
      case 'template_billto_shipto':
      case 'billto_shipto':
        return allTemplates.firstWhere((t) => t.id == 'retail_shop');
      case 'template_classic':
        return allTemplates.firstWhere((t) => t.id == 'elegant_premium');
      case 'classic':
        return allTemplates.firstWhere((t) => t.id == 'professional_classic');
      case 'template_compact':
      case 'compact':
        return allTemplates.firstWhere((t) => t.id == 'compact_thermal');
      case 'template_elegant':
      case 'elegant':
      case 'minimal':
        return allTemplates.firstWhere((t) => t.id == 'minimal_clean');
      case 'template_elegant_images':
      case 'elegant_images':
        return allTemplates.firstWhere((t) => t.id == 'elegant_premium');
      case 'template_evergreen':
      case 'evergreen':
        return allTemplates.firstWhere((t) => t.id == 'retail_shop');
      case 'template_genz':
      case 'genz':
        return allTemplates.firstWhere((t) => t.id == 'creative_modern');
      case 'template_legend':
      case 'legend':
        return allTemplates.firstWhere((t) => t.id == 'retail_shop');
      case 'template_modern':
      case 'modern':
      case 'emerald':
        return allTemplates.firstWhere((t) => t.id == 'modern_professional');
      case 'template_mrp_discount':
      case 'mrp_discount':
      case 'retail':
        return allTemplates.firstWhere((t) => t.id == 'retail_shop');
      case 'template_professional':
      case 'professional':
        return allTemplates.firstWhere((t) => t.id == 'professional_classic');
      case 'template_service':
      case 'service':
        return allTemplates.firstWhere((t) => t.id == 'creative_modern');
      case 'template_service_2':
      case 'service_2':
        return allTemplates.firstWhere((t) => t.id == 'service_consultancy');
      case 'template_vintage':
      case 'vintage':
        return allTemplates.firstWhere((t) => t.id == 'professional_classic');
      case 'branded':
        return allTemplates.firstWhere((t) => t.id == 'branded_custom');
      default:
        return allTemplates.firstWhere((t) => t.id == defaultTemplateId);
    }
  }

  /// Checks if a template ID is explicitly registered.
  static bool isValidTemplateId(String? id) {
    if (id == null) return false;
    final normalized = id.trim().toLowerCase();
    return allTemplates.any((t) => t.id == normalized);
  }
}
