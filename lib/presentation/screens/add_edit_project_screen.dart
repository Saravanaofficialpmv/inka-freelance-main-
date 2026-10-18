import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/utils/navigation_utils.dart';
import '../../data/models/client.dart';
import '../../data/models/project.dart';
import '../providers/client_provider.dart';
import '../viewmodels/project_viewmodel.dart';

class AddEditProjectScreen extends ConsumerStatefulWidget {
  final Project? project;

  const AddEditProjectScreen({super.key, this.project});

  @override
  ConsumerState<AddEditProjectScreen> createState() => _AddEditProjectScreenState();
}

class _AddEditProjectScreenState extends ConsumerState<AddEditProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _clientNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _budgetController;
  late TextEditingController _receivedAmountController;

  Client? _selectedClient;
  late String _status;
  late DateTime _startDate;
  late DateTime _deadline;

  static const List<String> _statuses = [
    'Planning',
    'Active',
    'Completed',
    'On Hold',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.project;
    _nameController = TextEditingController(text: p?.projectName ?? '');
    _clientNameController = TextEditingController(text: p?.clientName ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _budgetController = TextEditingController(text: p != null && p.budget > 0 ? p.budget.toStringAsFixed(0) : '');
    _receivedAmountController = TextEditingController(text: p != null && p.receivedAmount > 0 ? p.receivedAmount.toStringAsFixed(0) : '0');
    _status = p?.status ?? 'Active';
    _startDate = p?.startDate ?? DateTime.now();
    _deadline = p?.deadline ?? DateTime.now().add(const Duration(days: 30));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _clientNameController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    _receivedAmountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _deadline,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF5722),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
            dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_deadline.isBefore(_startDate)) {
            _deadline = _startDate.add(const Duration(days: 14));
          }
        } else {
          _deadline = picked;
        }
      });
    }
  }

  void _saveProject() {
    if (!_formKey.currentState!.validate()) return;

    final clientName = _selectedClient?.name ?? (_clientNameController.text.trim().isNotEmpty ? _clientNameController.text.trim() : (widget.project?.clientName ?? ''));
    final clientId = _selectedClient?.id ?? (widget.project?.clientId ?? 'client_${DateTime.now().millisecondsSinceEpoch}');
    final budget = double.tryParse(_budgetController.text.trim()) ?? 0.0;
    final received = double.tryParse(_receivedAmountController.text.trim()) ?? 0.0;
    if (budget < 0 || received < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget and received amounts cannot be negative.')),
      );
      return;
    }

    final isEdit = widget.project != null;
    final project = Project(
      id: isEdit ? widget.project!.id : 'proj_${DateTime.now().millisecondsSinceEpoch}',
      projectName: _nameController.text.trim(),
      clientId: clientId,
      clientName: clientName.isNotEmpty ? clientName : 'Independent Project',
      description: _descriptionController.text.trim(),
      budget: budget,
      receivedAmount: received,
      status: _status,
      startDate: _startDate,
      deadline: _deadline,
      createdAt: isEdit ? widget.project!.createdAt : DateTime.now(),
    );

    if (isEdit) {
      ref.read(projectProvider.notifier).updateProject(project);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Updated "${project.projectName}" successfully!'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      ref.read(projectProvider.notifier).addProject(project);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Created project "${project.projectName}"!'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    safeNavigateBack(context, fallbackRoute: '/projects');
  }

  @override
  Widget build(BuildContext context) {
    final clients = ref.watch(clientsProvider);
    final isEdit = widget.project != null;
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 14.0, 20.0, 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => safeNavigateBack(context, fallbackRoute: '/projects'),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF0F172A)),
                    ),
                  ),
                  Text(
                    isEdit ? 'Edit Project' : 'New Project',
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),

            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // Project Name Card
                    _buildSectionCard(
                      title: 'Project Information',
                      children: [
                        const Text('Project Name', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A))),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _nameController,
                          style: const TextStyle(color: Color(0xFF0F172A)),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Project name is required' : null,
                          decoration: _inputDecoration(hintText: 'e.g. Mobile App Redesign, Fintech Website'),
                        ),
                        const SizedBox(height: 14),

                        // Select Existing Client Dropdown
                        const Text('Assign Client', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A))),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<Client>(
                          initialValue: _selectedClient,
                          dropdownColor: Colors.white,
                          style: const TextStyle(color: Color(0xFF0F172A)),
                          hint: const Text('Choose Client', style: TextStyle(color: Color(0xFF94A3B8))),
                          items: clients
                              .map((c) => DropdownMenuItem(value: c, child: Text(c.name, style: const TextStyle(color: Color(0xFF0F172A)))))
                              .toList(),
                          onChanged: (c) {
                            setState(() {
                              _selectedClient = c;
                              if (c != null) _clientNameController.text = c.name;
                            });
                          },
                          decoration: _inputDecoration(),
                        ),
                        const SizedBox(height: 10),

                        // Or Type Custom Client
                        TextFormField(
                          controller: _clientNameController,
                          style: const TextStyle(color: Color(0xFF0F172A)),
                          decoration: _inputDecoration(hintText: 'Or enter client / organization name'),
                        ),
                        const SizedBox(height: 14),

                        // Description
                        const Text('Description & Scope', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A))),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 3,
                          style: const TextStyle(color: Color(0xFF0F172A)),
                          decoration: _inputDecoration(hintText: 'Key deliverables, milestones, tech stack...'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Financials Card
                    _buildSectionCard(
                      title: 'Budget & Billing',
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Total Budget', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A))),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _budgetController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    style: const TextStyle(color: Color(0xFF0F172A)),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) return 'Budget is required';
                                      if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
                                      return null;
                                    },
                                    decoration: _inputDecoration(hintText: 'e.g. 5000'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Amount Received', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A))),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _receivedAmountController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    style: const TextStyle(color: Color(0xFF0F172A)),
                                    decoration: _inputDecoration(hintText: 'e.g. 1500'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Status Card
                    _buildSectionCard(
                      title: 'Project Status',
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _statuses.map((status) {
                            final isSelected = _status == status;
                            return ChoiceChip(
                              label: Text(status),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) setState(() => _status = status);
                              },
                              selectedColor: const Color(0xFFFF5722),
                              backgroundColor: const Color(0xFFF8FAFC),
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : const Color(0xFF64748B),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                fontSize: 12.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                  color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Timeline Card
                    _buildSectionCard(
                      title: 'Timeline & Dates',
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _pickDate(isStart: true),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Start Date', style: TextStyle(color: Color(0xFF64748B), fontSize: 11.5)),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFFFF5722)),
                                          const SizedBox(width: 6),
                                          Text(
                                            dateFormat.format(_startDate),
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _pickDate(isStart: false),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Deadline', style: TextStyle(color: Color(0xFF64748B), fontSize: 11.5)),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.flag_rounded, size: 14, color: Color(0xFFFF5722)),
                                          const SizedBox(width: 6),
                                          Text(
                                            dateFormat.format(_deadline),
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _saveProject,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5722),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                          elevation: 0,
                        ),
                        child: Text(
                          isEdit ? 'Save Changes' : 'Create Project',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFFF5722), width: 1.5),
      ),
    );
  }
}
