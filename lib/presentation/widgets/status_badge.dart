import 'package:flutter/material.dart';

enum InvoiceStatusType { paid, pending, overdue, draft }

class StatusBadge extends StatelessWidget {
  final String status;
  final DateTime? dueDate;
  final VoidCallback? onTap;
  final bool showIcon;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const StatusBadge({
    super.key,
    required this.status,
    this.dueDate,
    this.onTap,
    this.showIcon = true,
    this.fontSize = 12.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 11, vertical: 4.5),
  });

  InvoiceStatusType get statusType {
    final s = status.toLowerCase();
    if (s == 'paid') return InvoiceStatusType.paid;
    if (s == 'overdue' || (dueDate != null && dueDate!.isBefore(DateTime.now()) && s != 'paid')) {
      return InvoiceStatusType.overdue;
    }
    if (s == 'draft') return InvoiceStatusType.draft;
    return InvoiceStatusType.pending;
  }

  @override
  Widget build(BuildContext context) {
    Color baseColor;
    String label;
    IconData icon;

    switch (statusType) {
      case InvoiceStatusType.paid:
        baseColor = const Color(0xFF10B981); // Emerald
        label = 'Paid';
        icon = Icons.check_circle_rounded;
        break;
      case InvoiceStatusType.overdue:
        baseColor = const Color(0xFFEF4444); // Crimson
        label = 'Overdue';
        icon = Icons.error_outline_rounded;
        break;
      case InvoiceStatusType.draft:
        baseColor = const Color(0xFF64748B); // Slate
        label = 'Draft';
        icon = Icons.edit_note_rounded;
        break;
      case InvoiceStatusType.pending:
        baseColor = const Color(0xFFF59E0B); // Warm Amber
        label = 'Pending';
        icon = Icons.schedule_rounded;
        break;
    }

    final badge = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: baseColor.withValues(alpha: 0.28),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: baseColor.withValues(alpha: 0.20),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showIcon) ...[
            Icon(icon, size: fontSize + 1.5, color: baseColor),
            const SizedBox(width: 4.5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: baseColor,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: badge,
      );
    }

    return badge;
  }
}
