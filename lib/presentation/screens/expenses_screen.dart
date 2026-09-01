import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/models/expense.dart';
import '../../services/currency_tax_service.dart';
import '../providers/profile_provider.dart';
import '../viewmodels/expense_viewmodel.dart';
import '../viewmodels/invoice_viewmodel.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  String _selectedTimeframe = 'Monthly'; // 'Weekly', 'Monthly', 'Yearly'

  void _showAddExpenseModal([Expense? existingExpense]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ExpenseFormBottomSheet(
        expense: existingExpense,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(expenseProvider);
    final invoices = ref.watch(invoiceProvider);
    final profile = ref.watch(profileProvider);
    final currencyFormat = CurrencyTaxService.getCurrencyFormatter(
      currencyCode: profile.currency.isNotEmpty ? profile.currency : 'USD',
      decimalDigits: 0,
    );

    final now = DateTime.now();
    final monthName = DateFormat('MMMM').format(now);

    final totalRevenue = invoices.fold(0.0, (s, i) => s + i.total);
    final paidAmount = invoices.where((i) => i.isPaid).fold(0.0, (s, i) => s + i.total);
    final unpaidAmount = invoices.where((i) => !i.isPaid && !i.dueDate.isBefore(now)).fold(0.0, (s, i) => s + i.total);
    final overdueAmount = invoices.where((i) => !i.isPaid && i.dueDate.isBefore(now)).fold(0.0, (s, i) => s + i.total);

    final sortedExpenses = expenses.reversed.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar (Back, Title "Statistics", More "...") ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 14.0, 20.0, 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        context.go('/dashboard');
                      }
                    },
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
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 18),
                    ),
                  ),

                  const Text(
                    'Statistics',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),

                  GestureDetector(
                    onTap: () => _showAddExpenseModal(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF5722), Color(0xFFFF7A50)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF5722).withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ),

            // ── Scrollable Body ──
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Title: "Over View"
                    const Text(
                      'Over View',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Summary Banner (Orange Gradient Card) ──
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF5722), Color(0xFFFF7A50)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF5722).withValues(alpha: 0.35),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$monthName Invoicing Summary',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              // Paid
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Paid', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Text(
                                      currencyFormat.format(paidAmount),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.3)),

                              // Unpaid
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Unpaid', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            currencyFormat.format(unpaidAmount),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Text('+3.4%', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.3)),

                              // Overdue
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Overdue', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            currencyFormat.format(overdueAmount),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Text('+4%', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Analytics Curve Chart Card ──
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
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
                          // Header: Stat ($53.200) + Dropdown (Monthly v)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    currencyFormat.format(totalRevenue),
                                    style: const TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    '(2.1%)',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),

                              // Timeframe dropdown selector
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: DropdownButton<String>(
                                  value: _selectedTimeframe,
                                  underline: const SizedBox(),
                                  dropdownColor: Colors.white,
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B), size: 18),
                                  isDense: true,
                                  items: ['Weekly', 'Monthly', 'Yearly'].map((t) {
                                    return DropdownMenuItem<String>(
                                      value: t,
                                      child: Text(
                                        t,
                                        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (v) {
                                    if (v != null) setState(() => _selectedTimeframe = v);
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Custom Vector Bezier Curve Line Chart
                          SizedBox(
                            height: 180,
                            child: Row(
                              children: [
                                // Y-Axis Labels
                                const Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('60k', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                                    Text('45k', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                                    Text('30k', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                                    Text('15k', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                                    Text('0k', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                                  ],
                                ),
                                const SizedBox(width: 10),

                                // Chart Canvas & X-Axis
                                Expanded(
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: CustomPaint(
                                          painter: _StatisticsChartPainter(),
                                          size: Size.infinite,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Jan', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5)),
                                          Text('Feb', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5)),
                                          Text('Mar', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5)),
                                          Text('Apr', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5)),
                                          Text('Jun', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5)),
                                          Text('Jul', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5)),
                                          Text('Aug', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Top Spending Section ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Top Spending',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showAddExpenseModal(),
                          child: const Text(
                            '+ Add Expense',
                            style: TextStyle(
                              color: Color(0xFFFF5722),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    if (sortedExpenses.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Center(
                          child: Column(
                            children: const [
                              Icon(Icons.shopping_bag_outlined, size: 40, color: Color(0xFFCBD5E1)),
                              SizedBox(height: 12),
                              Text('No expenses recorded yet', style: TextStyle(color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                      )
                    else
                      ...sortedExpenses.map((expense) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Circular Brand/Category Icon
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(expense.category).withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getCategoryIcon(expense.category),
                                  color: _getCategoryColor(expense.category),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Description & Date
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      expense.title.isNotEmpty ? expense.title : expense.category,
                                      style: const TextStyle(
                                        color: Color(0xFF0F172A),
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat('dd MMM, yyyy').format(expense.date),
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Amount
                              Text(
                                currencyFormat.format(expense.amount),
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'software':
        return Icons.code_rounded;
      case 'equipment':
        return Icons.devices_rounded;
      case 'office':
        return Icons.business_rounded;
      case 'marketing':
        return Icons.campaign_rounded;
      case 'travel':
        return Icons.flight_rounded;
      case 'utilities':
        return Icons.bolt_rounded;
      default:
        return Icons.shopping_bag_outlined;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'software':
        return const Color(0xFF3B82F6);
      case 'equipment':
        return const Color(0xFF8B5CF6);
      case 'office':
        return const Color(0xFFFF5722);
      case 'marketing':
        return const Color(0xFFEC4899);
      case 'travel':
        return const Color(0xFF14B8A6);
      case 'utilities':
        return const Color(0xFF06B6D4);
      default:
        return const Color(0xFFFF5722);
    }
  }
}

// ── Custom Painter for Curve Line Chart ──

class _StatisticsChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Grid horizontal guide lines
    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1.0;

    for (int i = 0; i < 5; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Orange Gradient Area Fill
    final path = Path();
    path.moveTo(0, size.height * 0.85);
    path.cubicTo(
      size.width * 0.2, size.height * 0.70,
      size.width * 0.4, size.height * 0.90,
      size.width * 0.6, size.height * 0.35,
    );
    path.cubicTo(
      size.width * 0.75, size.height * 0.15,
      size.width * 0.88, size.height * 0.18,
      size.width, size.height * 0.10,
    );

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFFF5722).withValues(alpha: 0.25),
          const Color(0xFFFF5722).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    // Primary Orange Line
    final linePaint = Paint()
      ..color = const Color(0xFFFF5722)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, linePaint);

    // Secondary Mint Green Trend Line
    final greenPath = Path();
    greenPath.moveTo(0, size.height * 0.95);
    greenPath.cubicTo(
      size.width * 0.25, size.height * 0.50,
      size.width * 0.5, size.height * 0.65,
      size.width * 0.75, size.height * 0.40,
    );
    greenPath.cubicTo(
      size.width * 0.85, size.height * 0.30,
      size.width * 0.95, size.height * 0.45,
      size.width, size.height * 0.35,
    );

    final greenLinePaint = Paint()
      ..color = const Color(0xFF10B981)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawPath(greenPath, greenLinePaint);

    // Draw Data Point Highlight Dots
    final dotPaint = Paint()..color = const Color(0xFFFF5722);
    final dotOuterPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final dot1 = Offset(size.width * 0.6, size.height * 0.35);
    final dot2 = Offset(size.width * 0.75, size.height * 0.40);

    canvas.drawCircle(dot1, 4, dotPaint);
    canvas.drawCircle(dot1, 4, dotOuterPaint);

    canvas.drawCircle(dot2, 4, Paint()..color = const Color(0xFF10B981));
    canvas.drawCircle(dot2, 4, dotOuterPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Expense Form Modal ──

class _ExpenseFormBottomSheet extends ConsumerStatefulWidget {
  final Expense? expense;
  const _ExpenseFormBottomSheet({this.expense});

  @override
  ConsumerState<_ExpenseFormBottomSheet> createState() => _ExpenseFormBottomSheetState();
}

class _ExpenseFormBottomSheetState extends ConsumerState<_ExpenseFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _vendorController;
  late TextEditingController _notesController;
  late String _selectedCategory;
  late DateTime _selectedDate;

  final List<String> _categories = [
    'Software',
    'Equipment',
    'Office',
    'Marketing',
    'Travel',
    'Utilities',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.expense?.title ?? '');
    _amountController = TextEditingController(
      text: widget.expense != null ? widget.expense!.amount.toStringAsFixed(2) : '',
    );
    _vendorController = TextEditingController(text: widget.expense?.paymentMethod ?? 'UPI');
    _notesController = TextEditingController(text: widget.expense?.notes ?? '');
    _selectedCategory = widget.expense?.category ?? 'Software';
    _selectedDate = widget.expense?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _vendorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final expense = Expense(
      id: widget.expense?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      amount: amount,
      category: _selectedCategory,
      date: _selectedDate,
      paymentMethod: _vendorController.text.trim().isNotEmpty ? _vendorController.text.trim() : 'UPI',
      notes: _notesController.text.trim(),
    );

    if (widget.expense != null) {
      ref.read(expenseProvider.notifier).updateExpense(expense);
    } else {
      ref.read(expenseProvider.notifier).addExpense(expense);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.expense != null ? 'Edit Expense' : 'Add New Expense',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  if (widget.expense != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                      onPressed: () {
                        ref.read(expenseProvider.notifier).deleteExpense(widget.expense!.id);
                        Navigator.of(context).pop();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Title
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Color(0xFF0F172A)),
                decoration: const InputDecoration(
                  labelText: 'Title / Description',
                  hintText: 'e.g. Figma Subscription, MacBook Pro',
                  fillColor: Color(0xFFF8FAFC),
                  filled: true,
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 14),

              // Amount
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Color(0xFF0F172A)),
                decoration: const InputDecoration(
                  labelText: 'Amount (\$)',
                  hintText: '0.00',
                  fillColor: Color(0xFFF8FAFC),
                  filled: true,
                ),
                validator: (v) => (v == null || double.tryParse(v.trim()) == null) ? 'Please enter valid amount' : null,
              ),
              const SizedBox(height: 14),

              // Category Selector
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                dropdownColor: Colors.white,
                style: const TextStyle(color: Color(0xFF0F172A)),
                decoration: const InputDecoration(
                  labelText: 'Category',
                  fillColor: Color(0xFFF8FAFC),
                  filled: true,
                ),
                items: _categories.map((c) {
                  return DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: Color(0xFF0F172A))));
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedCategory = v);
                },
              ),
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5722),
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                  shadowColor: const Color(0xFFFF5722).withValues(alpha: 0.4),
                ),
                child: Text(
                  widget.expense != null ? 'Update Expense' : 'Save Expense',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
