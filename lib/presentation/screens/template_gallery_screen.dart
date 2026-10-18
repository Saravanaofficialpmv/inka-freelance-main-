import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/navigation_utils.dart';
import '../../services/pdf_service.dart';
import '../providers/profile_provider.dart';
import '../widgets/bouncing_button.dart';
import '../widgets/celebration_sparkle.dart';

class TemplateGalleryScreen extends ConsumerStatefulWidget {
  const TemplateGalleryScreen({super.key});

  @override
  ConsumerState<TemplateGalleryScreen> createState() =>
      _TemplateGalleryScreenState();
}

class _TemplateGalleryScreenState extends ConsumerState<TemplateGalleryScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  String _selectedTemplateId = 'modern';
  int _selectedTabIndex = 0; // 0: Invoice, 1: Purchase, 2: Quotation

  final List<String> _tabs = ['Invoice', 'Purchase', 'Quotation'];

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    _selectedTemplateId = profile.invoiceTemplate.isNotEmpty
        ? profile.invoiceTemplate
        : 'modern';

    final initialIndex = PdfService.availableTemplates
        .indexWhere((t) => t.id == _selectedTemplateId);
    _currentPage = initialIndex != -1 ? initialIndex : 0;
    _pageController = PageController(
      initialPage: _currentPage,
      viewportFraction: 0.82,
    );
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

  void _handleSave() {
    final profile = ref.read(profileProvider);
    final updated = profile.copyWith(invoiceTemplate: _selectedTemplateId);
    ref.read(profileProvider.notifier).updateProfile(updated);

    final templateName = PdfService.availableTemplates
        .firstWhere((t) => t.id == _selectedTemplateId,
            orElse: () => PdfService.availableTemplates.first)
        .name;

    final typeName = _tabs[_selectedTabIndex];
    CelebrationSparkle.show(
      context,
      message: '$templateName set as default for ${typeName}s! 🎉',
    );

    safeNavigateBack(context, fallbackRoute: '/profile', result: _selectedTemplateId);
  }

  void _showZoomPreview(BuildContext context, PdfTemplateOption template) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 3.5,
                child: Image.asset(
                  template.assetPreview,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final templates = PdfService.availableTemplates;
    final currentTemplate = templates[_currentPage];

    return Scaffold(
      backgroundColor: const Color(0xFF14161D), // Dark studio canvas
      appBar: AppBar(
        backgroundColor: const Color(0xFF14161D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => safeNavigateBack(context, fallbackRoute: '/profile'),
        ),
        title: const Text(
          'Templates',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Type Tabs (Invoice, Purchase, Quotation) ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Row(
                children: List.generate(_tabs.length, (idx) {
                  final isSelected = _selectedTabIndex == idx;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedTabIndex = idx);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 20),
                      padding: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isSelected
                                ? const Color(0xFF3B82F6)
                                : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                      ),
                      child: Text(
                        _tabs[idx],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 10),

            // ── Dynamic Template Title Header & Tag ──
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Column(
                key: ValueKey(currentTemplate.id),
                children: [
                  Text(
                    currentTemplate.name.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      currentTemplate.tag,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Swipeable PageView Carousel ──
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: templates.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (ctx, index) {
                  final template = templates[index];
                  final isCurrentActive = profile.invoiceTemplate == template.id;

                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double value = 1.0;
                      if (_pageController.position.haveDimensions) {
                        value = (_pageController.page! - index);
                        value = (1 - (value.abs() * 0.12)).clamp(0.85, 1.0);
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
                      isDefault: isCurrentActive,
                      onTap: () => _showZoomPreview(context, template),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 14),

            // ── Dot Indicators (14 templates) ──
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(templates.length, (idx) {
                final isSelected = _currentPage == idx;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  width: isSelected ? 18 : 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF3B82F6)
                        : Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),

            const SizedBox(height: 18),

            // ── Bottom "Save changes" CTA Button ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: BouncingButton(
                  onTap: _handleSave,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Save changes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Template Preview Card with High-Res Cropped Sheet ──
  Widget _buildTemplateCard({
    required PdfTemplateOption template,
    required bool isDefault,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF232731), // Dark container frame
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDefault
                ? const Color(0xFF10B981)
                : Colors.white.withValues(alpha: 0.12),
            width: isDefault ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── High Resolution Bill Template Asset Preview ──
              Image.asset(
                template.assetPreview,
                fit: BoxFit.contain,
                alignment: Alignment.topCenter,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long_rounded, size: 48, color: Colors.blueGrey[400]),
                      const SizedBox(height: 12),
                      Text(
                        template.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Tap to Inspect hint pill at top right ──
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.zoom_in_rounded, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Preview',
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

              // ── Selected Green Checkmark Circle Badge ──
              if (isDefault)
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF10B981),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 20,
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
