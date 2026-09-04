import 'package:flutter_test/flutter_test.dart';
import 'package:inka/data/models/client.dart';
import 'package:inka/data/models/time_entry.dart';

void main() {
  group('Professional Freelancer Time Tracking Tests', () {
    final client = Client(
      id: 'c_client_1',
      name: 'Acme Digital Labs',
      phone: '+1 555 789 0123',
      email: 'billing@acmedigital.com',
      address: '500 Innovation Way',
    );

    test('TimeEntry calculates hours, amounts and formatted duration correctly', () {
      final entry = TimeEntry(
        id: 'te_1',
        client: client,
        projectTitle: 'Flutter App Development',
        hourlyRate: 75.0,
        durationSeconds: 9000, // 2.5 hours = 2 hours 30 mins
        date: DateTime(2024, 3, 1),
      );

      expect(entry.billableHours, equals(2.5));
      expect(entry.totalAmount, equals(187.5)); // 2.5 * 75
      expect(entry.formattedDuration, equals('02:30:00'));
      expect(entry.isBilled, isFalse);
    });

    test('Timer crash recovery correctly calculates elapsed seconds from timestamps', () {
      final pastStartTime = DateTime.now().subtract(const Duration(minutes: 45));
      final runningEntry = TimeEntry(
        id: 'te_running_1',
        client: client,
        projectTitle: 'Backend Architecture',
        hourlyRate: 80.0,
        durationSeconds: 300, // 5 minutes prior duration
        startTime: pastStartTime,
        isRunning: true,
        date: pastStartTime,
      );

      // Should compute approx (300 + 45*60) = 3000 seconds
      expect(runningEntry.currentElapsedSeconds, greaterThanOrEqualTo(2995));
      expect(runningEntry.currentElapsedSeconds, lessThanOrEqualTo(3005));
    });

    test('TimeEntry serialization with project ID, timestamps, and isRunning', () {
      final now = DateTime.now();
      final entry = TimeEntry(
        id: 'te_2',
        client: client,
        projectId: 'proj_100',
        projectTitle: 'Brand Strategy Workshop',
        hourlyRate: 100.0,
        durationSeconds: 3600, // 1 hr
        date: now,
        startTime: now,
        endTime: now.add(const Duration(hours: 1)),
        isRunning: false,
        isBilled: false,
      );

      final map = entry.toMap();
      expect(map['projectTitle'], equals('Brand Strategy Workshop'));
      expect(map['projectId'], equals('proj_100'));
      expect(map['hourlyRate'], equals(100.0));
      expect(map['durationSeconds'], equals(3600));
      expect(map['isRunning'], isFalse);

      final restored = TimeEntry.fromMap(map);
      expect(restored.id, equals('te_2'));
      expect(restored.projectId, equals('proj_100'));
      expect(restored.totalAmount, equals(100.0));

      final billedEntry = restored.copyWith(isBilled: true, invoiceId: 'inv_99');
      expect(billedEntry.isBilled, isTrue);
      expect(billedEntry.invoiceId, equals('inv_99'));
    });

    test('Midnight boundary condition inclusion test', () {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day, 0, 0, 0);
      final endOfToday = startOfToday.add(const Duration(days: 1));
      final midnightEntry = TimeEntry(
        id: 'te_midnight',
        client: client,
        projectTitle: 'Midnight Maintenance',
        hourlyRate: 100.0,
        durationSeconds: 1800,
        date: startOfToday,
      );

      final isIncluded = !midnightEntry.date.isBefore(startOfToday) && midnightEntry.date.isBefore(endOfToday);
      expect(isIncluded, isTrue);
    });
  });
}
