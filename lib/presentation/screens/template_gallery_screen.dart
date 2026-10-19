import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/theme_helper.dart';
import '../../core/utils/navigation_utils.dart';
import '../../features/invoices/templates/invoice_template_config.dart';
import '../../features/invoices/templates/invoice_template_registry.dart';
import '../../services/pdf_service.dart';
import '../providers/template_config_provider.dart';
import '../widgets/bouncing_button.dart';
import '../widgets/celebration_sparkle.dart';
import '../widgets/template_generated_preview.dart';

class TemplateGalleryScreen extends ConsumerStatefulWidget {
  const TemplateGalleryScreen({super.key});

  @override
  ConsumerState<TemplateGalleryScreen> createState() =>
      _TemplateGalleryScreenState();
}

class _TemplateGalleryScreenState extends ConsumerState<TemplateGalleryScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  // Local working copy of appearance settings
  late String _selectedTemplateId;
  late String _selectedColorHex;
  late InvoiceDensity _selectedDensity;
  late InvoicePageFormatType _selectedPageFormat;
  late bool _showLogo;
  late bool _showSignature;
  late bool _showQrCode;
  late bool _showBankDetails;
  late bool _showContactDetails;
  late bool _showNotesAndTerms;

  late InvoiceTemplateConfig _savedConfig;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _savedConfig = ref.read(templateConfigProvider);
    _initFromConfig(_savedConfig);

    final initialIndex = PdfService.availableTemplates.indexWhere(
      (t) => t.id == _selectedTemplateId,
    );
    _currentPage = initialIndex != -1 ? initialIndex : 0;
    _pageController = PageController(
      initialPage: _currentPage,
      viewportFraction: 0.82,
    );
  }

  void _initFromConfig(InvoiceTemplateConfig config) {
    _selectedTemplateId = config.templateId;
    _selectedColorHex = config.accentColorHex;
    _selectedDensity = config.density;
    _selectedPageFormat = config.pageFormat;
    _showLogo = config.showLogo;
    _showSignature = config.showSignature;
    _showQrCode = config.showQrCode;
    _showBankDetails = config.showBankDetails;
    _showContactDetails = config.showContactDetails;
    _showNotesAndTerms = config.showNotesAndTerms;
  }

  bool get _hasUnsavedChanges {
    return _selectedTemplateId != _savedConfig.templateId ||
        _selectedColorHex != _savedConfig.accentColorHex ||
        _selectedDensity != _savedConfig.density ||
        _selectedPageFormat != _savedConfig.pageFormat ||
        _showLogo != _savedConfig.showLogo ||
        _showSignature != _savedConfig.showSignature ||
        _showQrCode != _savedConfig.showQrCode ||
        _showBankDetails != _savedConfig.showBankDetails ||
        _showContactDetails != _savedConfig.showContactDetails ||
        _showNotesAndTerms != _savedConfig.showNotesAndTerms;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _currentPage = index;
      _selectedTemplateId = PdfService.availableTemplates[index].id;
    });
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final updated = InvoiceTemplateConfig(
      templateId: _selectedTemplateId,
      accentColorHex: _selectedColorHex,
      density: _selectedDensity,
      pageFormat: _selectedPageFormat,
      showLogo: _showLogo,
      showSignature: _showSignature,
      showQrCode: _showQrCode,
      showBankDetails: _showBankDetails,
      showContactDetails: _showContactDetails,
      showNotesAndTerms: _showNotesAndTerms,
    );

    // Save to Hive locally and mirror to profile + Firestore
    await ref.read(templateConfigProvider.notifier).updateConfig(updated);
    _savedConfig = updated;

    if (!mounted) return;
    setState(() => _isSaving = false);

    final templateName = InvoiceTemplateRegistry.getTemplate(
      _selectedTemplateId,
    ).name;
    final savedMsg =
        AppLocalizations.of(context)?.translate('settings_saved') ??
        '$templateName saved as default invoice design! 🎉';

    CelebrationSparkle.show(context, message: savedMsg);

    safeNavigateBack(
      context,
      fallbackRoute: '/profile',
      result: _selectedTemplateId,
    );
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          AppLocalizations.of(context)?.translate('unsaved_changes_title') ??
              'Unsaved Changes',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          AppLocalizations.of(context)?.translate('unsaved_changes_msg') ??
              'You have unsaved changes. Do you want to discard them?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              AppLocalizations.of(context)?.translate('cancel') ??
                  'Keep Editing',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              AppLocalizations.of(context)?.translate('discard') ?? 'Discard',
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    return discard ?? false;
  }

  void _showZoomPreview(BuildContext context, PdfTemplateOption template) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Zoom Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      template.icon,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            template.name,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Text(
                            'Pinch to zoom & inspect vector details',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: AppColors.textSecondary,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // High-Definition Vector Document Preview
              Flexible(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 5.0,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          template.assetPreview,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (context, error, stackTrace) {
                            return TemplateGeneratedPreview(
                              templateId: template.id,
                              isZoomed: true,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final templates = PdfService.availableTemplates;
    final currentTemplate = templates[_currentPage];

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          safeNavigateBack(context, fallbackRoute: '/profile');
        }
      },
      child: Scaffold(
        backgroundColor: context.scaffoldBg,
        appBar: AppBar(
          backgroundColor: context.scaffoldBg,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
            onPressed: () async {
              if (await _onWillPop() && context.mounted) {
                safeNavigateBack(context, fallbackRoute: '/profile');
              }
            },
          ),
          title: Text(
            AppLocalizations.of(context)?.translate('invoice_appearance') ??
                'Invoice Appearance',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 19,
              letterSpacing: -0.3,
            ),
          ),
          actions: [
            if (_hasUnsavedChanges)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Text(
                      'Unsaved',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Dynamic Template Title Header & Tag ──
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 6,
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: Column(
                            key: ValueKey(currentTemplate.id),
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    currentTemplate.icon,
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    currentTemplate.name.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.textPrimary,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFE2E8F0),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      currentTemplate.tag,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                  if (_selectedTemplateId ==
                                      currentTemplate.id) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.successBg,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.success.withValues(
                                            alpha: 0.5,
                                          ),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.check_circle_rounded,
                                            size: 12,
                                            color: AppColors.success,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            AppLocalizations.of(
                                                  context,
                                                )?.translate('selected') ??
                                                'Selected',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.success,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                currentTemplate.subtitle,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // ── Swipeable PageView Carousel for 14 Templates ──
                      SizedBox(
                        height: 350,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: templates.length,
                          onPageChanged: _onPageChanged,
                          itemBuilder: (ctx, index) {
                            final template = templates[index];
                            final isCurrentActive =
                                _selectedTemplateId == template.id;

                            return AnimatedBuilder(
                              animation: _pageController,
                              builder: (context, child) {
                                double value = 1.0;
                                if (_pageController.position.haveDimensions) {
                                  value = (_pageController.page! - index);
                                  value = (1 - (value.abs() * 0.12)).clamp(
                                    0.85,
                                    1.0,
                                  );
                                } else {
                                  value = index == _currentPage ? 1.0 : 0.90;
                                }

                                return Center(
                                  child: Transform.scale(
                                    scale: value,
                                    child: child,
                                  ),
                                );
                              },
                              child: _buildTemplateCard(
                                template: template,
                                isSelected: isCurrentActive,
                                onSelect: () {
                                  HapticFeedback.selectionClick();
                                  setState(
                                    () => _selectedTemplateId = template.id,
                                  );
                                },
                                onZoom: () =>
                                    _showZoomPreview(context, template),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ── Dot Indicators ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(templates.length, (idx) {
                          final isSelected = _currentPage == idx;
                          return GestureDetector(
                            onTap: () {
                              _pageController.animateToPage(
                                idx,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 2.5,
                              ),
                              width: isSelected ? 18 : 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : const Color(0xFFCBD5E1),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 24),

                      // ── Appearance Customization Sections ──
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Reference Design Specifications
                            _buildSectionTitle(
                              context,
                              icon: Icons.auto_awesome_rounded,
                              title: 'Reference Design Specifications',
                            ),
                            const SizedBox(height: 12),
                            _buildReferenceSpecCard(context, currentTemplate),

                            const SizedBox(height: 24),

                            // 3. Compact Template Page Format (Only shown if compact_thermal is chosen)
                            if (_selectedTemplateId == 'compact_thermal') ...[
                              const SizedBox(height: 24),
                              _buildSectionTitle(
                                context,
                                icon: Icons.receipt_long_rounded,
                                title:
                                    AppLocalizations.of(
                                      context,
                                    )?.translate('page_format') ??
                                    'Page Format',
                              ),
                              const SizedBox(height: 12),
                              _buildPageFormatSelector(context),
                            ],

                            const SizedBox(height: 24),

                            // 4. Optional Sections Visibility
                            _buildSectionTitle(
                              context,
                              icon: Icons.visibility_outlined,
                              title:
                                  AppLocalizations.of(
                                    context,
                                  )?.translate('optional_sections') ??
                                  'Optional Sections',
                            ),
                            const SizedBox(height: 12),
                            _buildOptionalSectionToggles(context),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Sticky Bottom Action Bar ──
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: const Border(
                    top: BorderSide(
                      color: Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    if (_hasUnsavedChanges) ...[
                      OutlinedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          setState(() => _initFromConfig(_savedConfig));
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: const BorderSide(
                            color: Color(0xFFCBD5E1),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)?.translate('cancel') ??
                              'Reset',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: BouncingButton(
                          onTap: _handleSave,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF5722), Color(0xFFFF7A50)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: _isSaving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        AppLocalizations.of(
                                              context,
                                            )?.translate('save_changes') ??
                                            'Save Changes',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section Title Helper ──
  Widget _buildSectionTitle(
    BuildContext context, {
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  // ── Reference Design Specifications Card ──
  Widget _buildReferenceSpecCard(
    BuildContext context,
    PdfTemplateOption template,
  ) {
    final isSelected = _selectedTemplateId == template.id;
    final color = Color(
      int.parse(template.primaryColorHex.replaceFirst('#', '0xFF')),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    template.icon,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      template.subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  template.tag,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),
          Row(
            children: [
              const Text(
                'Reference Specification: ',
                style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
              ),
              Text(
                template.assetPreview.split('/').last,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Text(
                'Reference Header Accent: ',
                style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
              ),
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFCBD5E1), width: 0.8),
                ),
              ),
              Text(
                template.primaryColorHex,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (!isSelected)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedTemplateId = template.id;
                    _selectedColorHex = template.primaryColorHex;
                  });
                },
                icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                label: const Text('Use This Layout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  elevation: 0,
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.5),
                  width: 0.8,
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: AppColors.success,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Selected As Default Template',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Page Format Selector (For Compact Template) ──
  Widget _buildPageFormatSelector(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedPageFormat = InvoicePageFormatType.a4);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedPageFormat == InvoicePageFormatType.a4
                      ? AppColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  AppLocalizations.of(context)?.translate('standard_a4') ??
                      'Standard A4',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: _selectedPageFormat == InvoicePageFormatType.a4
                        ? FontWeight.w800
                        : FontWeight.w500,
                    color: _selectedPageFormat == InvoicePageFormatType.a4
                        ? Colors.white
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(
                  () => _selectedPageFormat = InvoicePageFormatType.thermalRoll,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color:
                      _selectedPageFormat == InvoicePageFormatType.thermalRoll
                      ? AppColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  AppLocalizations.of(context)?.translate('thermal_roll') ??
                      'Thermal Roll (80mm)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        _selectedPageFormat == InvoicePageFormatType.thermalRoll
                        ? FontWeight.w800
                        : FontWeight.w500,
                    color:
                        _selectedPageFormat == InvoicePageFormatType.thermalRoll
                        ? Colors.white
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Optional Section Toggles ──
  Widget _buildOptionalSectionToggles(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _buildToggleRow(
            context,
            icon: Icons.image_outlined,
            title:
                AppLocalizations.of(context)?.translate('logo') ??
                'Business Logo',
            value: _showLogo,
            onChanged: (val) => setState(() => _showLogo = val),
          ),
          _divider(),
          _buildToggleRow(
            context,
            icon: Icons.draw_outlined,
            title:
                AppLocalizations.of(context)?.translate('signature') ??
                'Authorized Signature',
            value: _showSignature,
            onChanged: (val) => setState(() => _showSignature = val),
          ),
          _divider(),
          _buildToggleRow(
            context,
            icon: Icons.qr_code_2_rounded,
            title:
                AppLocalizations.of(context)?.translate('payment_qr_code') ??
                'Payment QR Code',
            value: _showQrCode,
            onChanged: (val) => setState(() => _showQrCode = val),
          ),
          _divider(),
          _buildToggleRow(
            context,
            icon: Icons.account_balance_outlined,
            title:
                AppLocalizations.of(
                  context,
                )?.translate('bank_details_visibility') ??
                'Bank Details',
            value: _showBankDetails,
            onChanged: (val) => setState(() => _showBankDetails = val),
          ),
          _divider(),
          _buildToggleRow(
            context,
            icon: Icons.contact_mail_outlined,
            title:
                AppLocalizations.of(context)?.translate('contact_details') ??
                'Contact Details',
            value: _showContactDetails,
            onChanged: (val) => setState(() => _showContactDetails = val),
          ),
          _divider(),
          _buildToggleRow(
            context,
            icon: Icons.notes_rounded,
            title:
                AppLocalizations.of(context)?.translate('notes_and_terms') ??
                'Notes & Terms',
            value: _showNotesAndTerms,
            onChanged: (val) => setState(() => _showNotesAndTerms = val),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return const Divider(
      height: 1,
      indent: 46,
      endIndent: 16,
      color: Color(0xFFF1F5F9),
    );
  }

  Widget _buildToggleRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  // ── Template Preview Card ──
  Widget _buildTemplateCard({
    required PdfTemplateOption template,
    required bool isSelected,
    required VoidCallback onSelect,
    required VoidCallback onZoom,
  }) {
    return GestureDetector(
      onTap: onSelect,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: isSelected ? 2.5 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.22)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: isSelected ? 18 : 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // High-Definition Generated Invoice Preview
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(4),
                child: Image.asset(
                  template.assetPreview,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) {
                    return TemplateGeneratedPreview(
                      templateId: template.id,
                      isZoomed: false,
                    );
                  },
                ),
              ),

              // Tap to Zoom Inspect pill at top right
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: onZoom,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.zoom_in_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                        SizedBox(width: 3),
                        Text(
                          'Zoom',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Selected Badge
              if (isSelected)
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'ACTIVE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
