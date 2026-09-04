import 'package:flutter/material.dart';

class AppSlowNetworkBanner extends StatelessWidget {
  final VoidCallback? onDismiss;

  const AppSlowNetworkBanner({super.key, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFEFF6FF),
        border: Border(
          bottom: BorderSide(color: Color(0xFFBFDBFE), width: 1),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.network_check_rounded, size: 16, color: Color(0xFF2563EB)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Slow connection detected. Cloud sync is continuing in background.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E40AF),
              ),
            ),
          ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF6B7280)),
            ),
        ],
      ),
    );
  }
}
