import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/expense.dart';
import '../../services/firestore_service.dart';
import 'invoice_viewmodel.dart';

class ExpenseNotifier extends StateNotifier<List<Expense>> {
  final FirestoreService _firestoreService;

  ExpenseNotifier(this._firestoreService) : super([]) {
    _loadExpenses();
  }

  late final Box<Expense> _expenseBox = Hive.box<Expense>('expenses');

  void _loadExpenses() {
    state = _expenseBox.values.toList();
  }

  void refreshFromLocal() {
    state = _expenseBox.values.toList();
  }

  void clear() {
    state = [];
    _expenseBox.clear();
  }

  Future<void> addExpense(Expense expense) async {
    await _expenseBox.put(expense.id, expense);
    state = _expenseBox.values.toList();
    await _firestoreService.saveExpense(expense);
  }

  Future<void> updateExpense(Expense updatedExpense) async {
    await _expenseBox.put(updatedExpense.id, updatedExpense);
    state = _expenseBox.values.toList();
    await _firestoreService.saveExpense(updatedExpense);
  }

  Future<void> deleteExpense(String id) async {
    await _expenseBox.delete(id);
    state = _expenseBox.values.toList();
    await _firestoreService.deleteExpense(id);
  }
}

final expenseProvider = StateNotifierProvider<ExpenseNotifier, List<Expense>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return ExpenseNotifier(firestoreService);
});

/// Computes financial profit & loss metrics: Total Expenses, Net Profit, Profit Margin %
final profitLossStatsProvider = Provider((ref) {
  final expenses = ref.watch(expenseProvider);
  final invoices = ref.watch(invoiceProvider);
  final period = ref.watch(statsPeriodProvider);

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  DateTime? filterDate;
  if (period == StatsPeriod.today) {
    filterDate = today;
  } else if (period == StatsPeriod.last7Days) {
    filterDate = today.subtract(const Duration(days: 7));
  } else if (period == StatsPeriod.last30Days) {
    filterDate = today.subtract(const Duration(days: 30));
  }

  double totalExpenses = 0;
  final Map<String, double> categoryBreakdown = {};

  for (final expense in expenses) {
    if (filterDate != null && expense.date.isBefore(filterDate)) {
      continue;
    }
    totalExpenses += expense.amount;
    categoryBreakdown[expense.category] =
        (categoryBreakdown[expense.category] ?? 0) + expense.amount;
  }

  double totalRevenue = 0;
  double collectedRevenue = 0;

  for (final invoice in invoices) {
    if (filterDate != null && invoice.issueDate.isBefore(filterDate)) {
      continue;
    }
    totalRevenue += invoice.total;
    if (invoice.status == 'paid') {
      collectedRevenue += invoice.total;
    }
  }

  final double netProfit = collectedRevenue - totalExpenses;
  final double profitMargin =
      collectedRevenue > 0 ? (netProfit / collectedRevenue) * 100 : 0.0;

  return {
    'totalExpenses': totalExpenses,
    'collectedRevenue': collectedRevenue,
    'totalRevenue': totalRevenue,
    'netProfit': netProfit,
    'profitMargin': profitMargin,
    'isProfitable': netProfit >= 0,
    'categoryBreakdown': categoryBreakdown,
    'totalExpenseCount': expenses.length,
  };
});
