import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../features/invoices/templates/invoice_template_config.dart';
import '../../features/invoices/templates/invoice_template_registry.dart';
import '../../services/firestore_service.dart';
import 'profile_provider.dart';

final templateConfigProvider =
    StateNotifierProvider<TemplateConfigNotifier, InvoiceTemplateConfig>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final profile = ref.watch(profileProvider);
  return TemplateConfigNotifier(firestoreService, profile, ref);
});

class TemplateConfigNotifier extends StateNotifier<InvoiceTemplateConfig> {
  final FirestoreService _firestoreService;
  final Ref _ref;

  TemplateConfigNotifier(this._firestoreService, dynamic profile, this._ref)
      : super(_loadInitial(profile));

  static InvoiceTemplateConfig _loadInitial(dynamic profile) {
    try {
      if (Hive.isBoxOpen('template_config')) {
        final box = Hive.box('template_config');
        final raw = box.get('current');
        if (raw is Map) {
          return InvoiceTemplateConfig.fromMap(Map<String, dynamic>.from(raw));
        }
      }
    } catch (e) {
      debugPrint('Error loading template config from Hive: $e');
    }

    // Fallback to profile's invoiceTemplate if available
    final initialId = (profile != null && profile.invoiceTemplate.isNotEmpty)
        ? profile.invoiceTemplate
        : InvoiceTemplateRegistry.defaultTemplateId;

    return InvoiceTemplateConfig(
      templateId: InvoiceTemplateRegistry.getTemplate(initialId).id,
    );
  }

  static Box? _getOpenBox() {
    try {
      if (Hive.isBoxOpen('template_config')) {
        return Hive.box('template_config');
      }
    } catch (_) {}
    return null;
  }

  /// Updates config locally in Hive immediately, synchronizes with business profile,
  /// and mirrors to Firestore.
  Future<void> updateConfig(InvoiceTemplateConfig newConfig) async {
    state = newConfig;

    try {
      final box = _getOpenBox();
      await box?.put('current', newConfig.toMap());
    } catch (e) {
      debugPrint('Error writing template config to Hive: $e');
    }

    // Keep profile.invoiceTemplate in sync
    try {
      final currentProfile = _ref.read(profileProvider);
      if (currentProfile.invoiceTemplate != newConfig.templateId) {
        final updatedProfile = currentProfile.copyWith(invoiceTemplate: newConfig.templateId);
        await _ref.read(profileProvider.notifier).updateProfile(updatedProfile);
      }
    } catch (e) {
      debugPrint('Error syncing profile template: $e');
    }

    // Background Firestore sync
    try {
      await _firestoreService.saveTemplateConfig(newConfig);
    } catch (e) {
      debugPrint('Background firestore template config error: $e');
    }
  }

  /// Updates state and Hive only (used during Firestore remote synchronization)
  Future<void> updateLocally(InvoiceTemplateConfig newConfig) async {
    state = newConfig;
    try {
      final box = _getOpenBox();
      await box?.put('current', newConfig.toMap());
    } catch (e) {
      debugPrint('Error writing local template config: $e');
    }
  }

  void resetToDefault() {
    updateConfig(InvoiceTemplateConfig.defaultConfig());
  }
}
