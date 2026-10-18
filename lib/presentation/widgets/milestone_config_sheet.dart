import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/colors.dart';
import '../../core/theme/theme_helper.dart';
import '../../data/models/payment_milestone.dart';
import '../../services/currency_tax_service.dart';
import '../../services/interactive_invoice_service.dart';

class MilestoneConfigSheet extends StatefulWidget {
  final double totalAmount;
  final String currencyCode;
  final List<PaymentMilestone> initialMilestones;
  final ValueChanged<List<PaymentMilestone>> onSave;

  const MilestoneConfigSheet({
    super.key,
    required this.totalAmount,
    this.currencyCode = 'USD',
    this.initialMilestones = const [],
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required double totalAmount,
    String currencyCode = 'USD',
    List<PaymentMilestone> initialMilestones = const [],
    required ValueChanged<List<PaymentMilestone>> onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MilestoneConfigSheet(
        totalAmount: totalAmount,
        currencyCode: currencyCode,
        initialMilestones: initialMilestones,
        onSave: onSave,
      ),
    );
  }

  @override
  State<MilestoneConfigSheet> createState() => _MilestoneConfigSheetState();
}

class _MilestoneConfigSheetState extends State<MilestoneConfigSheet> {
  late List<PaymentMilestone> _milestones;

  @override
  void initState() {
    super.initState();
    if (widget.initialMilestones.isNotEmpty) {
      _milestones = List.from(widget.initialMilestones);
    } else {
      // Default to 40 / 30 / 30 split
      _milestones = InteractiveInvoiceService.generate40_30_30Split(
        totalAmount: widget.totalAmount > 0 ? widget.totalAmount : 1000.0,
      );
    }
  }

  double get _totalPercentage => _milestones.fold(0.0, (sum, m) => sum + m.percentage);
  bool get _isValid => (_totalPercentage - 100.0).abs() < 0.5;

  void _applyPreset(int presetIndex) {
    HapticFeedback.selectionClick();
    setState(() {
      final amount = widget.totalAmount > 0 ? widget.totalAmount : 1000.0;
      if (presetIndex == 0) {
        _milestones = InteractiveInvoiceService.generate50_50Split(totalAmount: amount);
      } else if (presetIndex == 1) {
        _milestones = InteractiveInvoiceService.generate40_30_30Split(totalAmount: amount);
      } else {
        _milestones = InteractiveInvoiceService.generate30_40_30Split(totalAmount: amount);
      }
    });
  }

  void _addMilestone() {
    HapticFeedback.lightImpact();
    final remainingPct = (100.0 - _totalPercentage).clamp(5.0, 100.0);
    final amount = (widget.totalAmount * (remainingPct / 100));

    setState(() {
      _milestones.add(
        PaymentMilestone(
          id: 'ms_${DateTime.now().millisecondsSinceEpoch}_${_milestones.length + 1}',
          title: 'Milestone ${_milestones.length + 1}',
          percentage: remainingPct,
          amount: amount,
          dueDate: DateTime.now().add(Duration(days: (_milestones.length + 1) * 14)),
          status: _milestones.isEmpty ? 'active' : 'pending',
        ),
      );
    });
  }

  void _removeMilestone(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _milestones.removeAt(index);
    });
  }

  void _handleSave() {
    if (!_isValid) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Total milestone percentage must equal 100% (currently ${_totalPercentage.toStringAsFixed(1)}%).'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    widget.onSave(_milestones);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = CurrencyTaxService.getCurrencyFormatter(
      currencyCode: widget.currencyCode,
      decimalDigits: 2,
    );
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: context.cardBorder),
      ),
      padding: EdgeInsets.only(
        bottom: bottomInset + (bottomInset > 0 ? 16 : bottomPadding + 16),
        left: 20,
        right: 20,
        top: 14,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: context.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.splitscreen_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Tranches & Milestones',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: context.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Split ${currencyFormat.format(widget.totalAmount)} into structured payment steps',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Preset Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildPresetChip('50% / 50% Split', 0),
                const SizedBox(width: 8),
                _buildPresetChip('40% / 30% / 30% (Recommended)', 1),
                const SizedBox(width: 8),
                _buildPresetChip('30% / 40% / 30% Sprint', 2),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Percentage Tracker Status Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _isValid
                  ? const Color(0xFF10B981).withValues(alpha: 0.1)
                  : const Color(0xFFEF4444).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isValid
                    ? const Color(0xFF10B981).withValues(alpha: 0.3)
                    : const Color(0xFFEF4444).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isValid ? 'Total Split: 100% (Balanced)' : 'Total Split: ${_totalPercentage.toStringAsFixed(1)}% (Must equal 100%)',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: _isValid ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                ),
                Icon(
                  _isValid ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                  size: 16,
                  color: _isValid ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Milestones List
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: _milestones.length,
              itemBuilder: (ctx, index) {
                final milestone = _milestones[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.surfaceHighlight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.cardBorder),
                  ),
                  child: Row(
                    children: [
                      // Step Number Badge
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: index == 0
                              ? AppColors.primary
                              : (milestone.isPaid ? const Color(0xFF10B981) : context.cardBorder),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: milestone.isPaid
                              ? const Icon(Icons.check, size: 16, color: Colors.white)
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: index == 0 ? Colors.white : context.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Title & Amount
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              milestone.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                                color: context.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${milestone.percentage.toStringAsFixed(0)}% • ${currencyFormat.format(milestone.amount)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: context.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Delete action
                      if (_milestones.length > 2)
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFFEF4444), size: 20),
                          onPressed: () => _removeMilestone(index),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Add Custom Step Button
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _addMilestone,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Milestone Step', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 12),
              // Clear Tranches Button
              OutlinedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  widget.onSave([]);
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF64748B),
                  side: BorderSide(color: context.cardBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
                child: const Text('Clear Tranches', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Save & Apply Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isValid ? _handleSave : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text(
                'Apply Tranches to Invoice',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(String label, int presetIndex) {
    return GestureDetector(
      onTap: () => _applyPreset(presetIndex),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: context.surfaceHighlight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.cardBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
        ),
      ),
    );
  }
}
