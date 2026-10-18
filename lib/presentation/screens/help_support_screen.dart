import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/navigation_utils.dart';
import '../../core/localization/app_localizations.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const String _supportPhone = '+91 98765 43210';
  static const String _supportEmail = 'support@inka.com';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => safeNavigateBack(context, fallbackRoute: '/profile'),
        ),
        title: Text(
          AppLocalizations.of(context)?.translate('help_support') ?? 'Help & Support',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.cardBorder, height: 1),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Header Card ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.support_agent_rounded, size: 32, color: AppColors.primary),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'We\'re here to help',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Have questions or need assistance? Reach out to our dedicated support team.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Contact Channels ──
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'Direct Contact',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.2),
              ),
            ),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF22C55E), size: 24),
                      ),
                      title: const Text('WhatsApp Support', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                      subtitle: const Text(_supportPhone, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      trailing: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF22C55E),
                          side: const BorderSide(color: Color(0xFF22C55E)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Clipboard.setData(const ClipboardData(text: _supportPhone));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('WhatsApp number copied to clipboard!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: const Text('Copy'),
                      ),
                    ),
                    const Divider(height: 1, indent: 76, endIndent: 20, color: Color(0xFFF1F5F9)),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.email_outlined, color: AppColors.primary, size: 24),
                      ),
                      title: const Text('Email Support', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                      subtitle: const Text(_supportEmail, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      trailing: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Clipboard.setData(const ClipboardData(text: _supportEmail));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Support email copied to clipboard!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: const Text('Copy'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Frequently Asked Questions ──
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'Frequently Asked Questions',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.2),
              ),
            ),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                children: const [
                  ExpansionTile(
                    title: Text('Does Inka work offline?', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          'Yes! All clients, products, expenses, and invoices are stored securely on your local device. Once reconnected to the internet, everything synchronizes automatically.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                  Divider(height: 1, indent: 20, endIndent: 20, color: Color(0xFFF1F5F9)),
                  ExpansionTile(
                    title: Text('How do I share invoices via WhatsApp?', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          'From the invoice preview screen, tap "Share Invoice" and choose WhatsApp. Inka will attach the professional PDF and prepare a pre-filled message with total amount and payment details.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                  Divider(height: 1, indent: 20, endIndent: 20, color: Color(0xFFF1F5F9)),
                  ExpansionTile(
                    title: Text('Where are generated PDFs saved?', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          'PDFs are generated on-the-fly and saved to your application documents directory. You can download, print, or share them at any time from the Invoices tab.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }
}
