import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/state_views/state_views.dart';

class StateShowcaseScreen extends ConsumerStatefulWidget {
  const StateShowcaseScreen({super.key});

  @override
  ConsumerState<StateShowcaseScreen> createState() => _StateShowcaseScreenState();
}

class _StateShowcaseScreenState extends ConsumerState<StateShowcaseScreen> {
  int _selectedTab = 0;

  final List<String> _stateNames = [
    'Empty State',
    'Loading State',
    'Error State',
    'No Internet',
    'Slow Network',
    'No Search Results',
    'Permission Denied',
    'Session Expired',
    'Form Validation',
    'Success State',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'UI State Components',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _stateNames.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (ctx, index) {
                final isSelected = _selectedTab == index;
                return ChoiceChip(
                  label: Text(_stateNames[index]),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedTab = index),
                  selectedColor: const Color(0xFFFF5722),
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 12.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFFFF5722) : const Color(0xFFE2E8F0),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: _buildSelectedStateBody(),
    );
  }

  Widget _buildSelectedStateBody() {
    switch (_selectedTab) {
      case 0:
        return AppEmptyState(
          icon: Icons.receipt_long_rounded,
          title: 'No Invoices Yet',
          subtitle: 'Create your first invoice to bill clients, track payments, and download PDFs.',
          actionLabel: 'Create First Invoice',
          onAction: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Action: Navigating to Create Invoice')),
            );
          },
        );

      case 1:
        return const AppLoadingState(
          message: 'Syncing your invoices with Cloud Storage...',
        );

      case 2:
        return AppErrorState(
          title: 'Unable to Load Invoices',
          message: 'We could not reach the server. Your offline local copies are safe.',
          onRetry: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Retrying request...')),
            );
          },
        );

      case 3:
        return Column(
          children: [
            const AppOfflineBanner(),
            Expanded(
              child: AppNoInternetView(
                onRetry: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reconnected to network!')),
                  );
                },
              ),
            ),
          ],
        );

      case 4:
        return Column(
          children: [
            AppSlowNetworkBanner(
              onDismiss: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Banner dismissed')),
                );
              },
            ),
            const Expanded(
              child: Center(
                child: Text('Content is loading steadily in background...'),
              ),
            ),
          ],
        );

      case 5:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SearchEmptyState(
              query: 'Acme Widget 2026',
              onClear: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Search query cleared')),
                );
              },
              itemType: 'products or clients',
            ),
          ),
        );

      case 6:
        return Center(
          child: ElevatedButton.icon(
            onPressed: () {
              AppPermissionDeniedDialog.show(
                context,
                permissionName: 'Microphone',
                featureName: 'voice-to-invoice dictation',
                icon: Icons.mic_off_rounded,
              );
            },
            icon: const Icon(Icons.security_rounded, color: Colors.white),
            label: const Text('Simulate Permission Denied Dialog'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5722),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        );

      case 7:
        return Center(
          child: ElevatedButton.icon(
            onPressed: () {
              AppSessionExpiredDialog.show(context);
            },
            icon: const Icon(Icons.lock_clock_rounded, color: Colors.white),
            label: const Text('Simulate Session Expired Dialog'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        );

      case 8:
        return const _FormValidationDemoView();

      case 9:
        return Center(
          child: ElevatedButton.icon(
            onPressed: () {
              AppSuccessSheet.show(
                context,
                title: 'Invoice Created! 🎉',
                subtitle: 'Invoice #INV-2026-042 has been generated and saved locally.',
                primaryButtonLabel: 'View & Download PDF',
                onPrimaryAction: () {
                  Navigator.of(context).pop();
                },
                secondaryButtonLabel: 'Back to Dashboard',
                onSecondaryAction: () {
                  Navigator.of(context).pop();
                },
              );
            },
            icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
            label: const Text('Trigger Success State Sheet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

class _FormValidationDemoView extends StatefulWidget {
  const _FormValidationDemoView();

  @override
  State<_FormValidationDemoView> createState() => _FormValidationDemoViewState();
}

class _FormValidationDemoViewState extends State<_FormValidationDemoView> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _priceCtrl.dispose();
    _discountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Interactive Validation Test',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tests regex formatting, positive pricing bounds, and discount clamping.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                hintText: 'user@example.com',
                border: OutlineInputBorder(),
              ),
              validator: AppValidators.validateEmail,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: '+1 555-0199',
                border: OutlineInputBorder(),
              ),
              validator: AppValidators.validatePhone,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Product Price (> 0)',
                hintText: '49.99',
                border: OutlineInputBorder(),
              ),
              validator: (v) => AppValidators.validatePrice(v, 'Unit Price'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _discountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Discount (must not exceed subtotal \$100)',
                hintText: '15.00',
                border: OutlineInputBorder(),
              ),
              validator: (v) => AppValidators.validateDiscount(v, 100.0),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All validations passed successfully! ✅'),
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5722),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'Validate Form',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
