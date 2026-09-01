import 'package:flutter_test/flutter_test.dart';
import 'package:inka/data/models/project.dart';

void main() {
  group('Project Management Model & Logic Tests', () {
    test('Project model calculations work correctly', () {
      final now = DateTime.now();
      final project = Project(
        id: 'proj_1',
        projectName: 'Fintech Mobile App',
        clientId: 'client_101',
        clientName: 'Alpha Capital',
        description: 'Complete UI redesign and Flutter implementation',
        budget: 10000.0,
        receivedAmount: 4000.0,
        status: 'Active',
        startDate: now.subtract(const Duration(days: 10)),
        deadline: now.add(const Duration(days: 20)),
        createdAt: now.subtract(const Duration(days: 10)),
      );

      expect(project.remainingAmount, equals(6000.0));
      expect(project.progressRatio, equals(0.4));
      expect(project.progressPercentage, equals(40));
      expect(project.isOverdue, isFalse);
    });

    test('Overdue detection works accurately', () {
      final now = DateTime.now();
      final overdueProject = Project(
        id: 'proj_2',
        projectName: 'Landing Page',
        clientId: 'client_102',
        clientName: 'Beta Corp',
        budget: 2000.0,
        receivedAmount: 1000.0,
        status: 'Active',
        startDate: now.subtract(const Duration(days: 30)),
        deadline: now.subtract(const Duration(days: 5)),
        createdAt: now.subtract(const Duration(days: 30)),
      );

      expect(overdueProject.isOverdue, isTrue);

      final completedProject = overdueProject.copyWith(status: 'Completed');
      expect(completedProject.isOverdue, isFalse);
    });

    test('Serialization and deserialization', () {
      final now = DateTime.now();
      final project = Project(
        id: 'proj_3',
        projectName: 'SaaS Platform',
        clientId: 'client_103',
        clientName: 'Starlight Media',
        description: 'Multi-tenant subscription backend',
        budget: 15000.0,
        receivedAmount: 7500.0,
        status: 'Planning',
        startDate: now,
        deadline: now.add(const Duration(days: 60)),
        createdAt: now,
      );

      final map = project.toMap();
      expect(map['projectName'], equals('SaaS Platform'));
      expect(map['budget'], equals(15000.0));
      expect(map['receivedAmount'], equals(7500.0));
      expect(map['status'], equals('Planning'));

      final restored = Project.fromMap(map);
      expect(restored.id, equals('proj_3'));
      expect(restored.clientName, equals('Starlight Media'));
      expect(restored.remainingAmount, equals(7500.0));
      expect(restored.progressPercentage, equals(50));
    });
  });
}
