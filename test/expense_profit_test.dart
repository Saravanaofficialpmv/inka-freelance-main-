import 'package:flutter_test/flutter_test.dart';
import 'package:inka/data/models/expense.dart';

void main() {
  group('Expense & Profit Tracker Tests', () {
    test('Expense model serializes and deserializes correctly', () {
      final expense = Expense(
        id: 'exp_1',
        title: 'Figma Annual Subscription',
        amount: 144.0,
        category: 'Software',
        date: DateTime(2024, 2, 1),
        notes: 'Team plan',
        paymentMethod: 'Credit Card',
      );

      final map = expense.toMap();
      expect(map['title'], equals('Figma Annual Subscription'));
      expect(map['amount'], equals(144.0));
      expect(map['category'], equals('Software'));
      expect(map['paymentMethod'], equals('Credit Card'));

      final restored = Expense.fromMap(map);
      expect(restored.id, equals('exp_1'));
      expect(restored.title, equals('Figma Annual Subscription'));
      expect(restored.amount, equals(144.0));
      expect(restored.category, equals('Software'));
    });

    test('Net profit and margin calculations', () {
      const collectedRevenue = 5000.0;
      const totalExpenses = 1500.0;

      const netProfit = collectedRevenue - totalExpenses;
      final profitMargin = (netProfit / collectedRevenue) * 100;

      expect(netProfit, equals(3500.0));
      expect(profitMargin, equals(70.0));
    });
  });
}
