import 'package:flutter_test/flutter_test.dart';
import 'package:zeroscroll/features/limits/domain/focus_schedule.dart';

void main() {
  group('FocusSchedule & Overnight Window Calculations', () {
    test('same-day daytime schedule matches within configured hours', () {
      final schedule = FocusSchedule(
        id: 'work_focus',
        name: 'Work Focus',
        startHour: 9,
        startMinute: 0,
        endHour: 17,
        endMinute: 0,
        weekdays: [
          DateTime.monday,
          DateTime.tuesday,
          DateTime.wednesday,
          DateTime.thursday,
          DateTime.friday,
        ],
      );

      // Wednesday 10:30 AM -> active
      final wednesdayMorning = DateTime(2026, 9, 30, 10, 30); // 2026-09-30 is Wednesday
      expect(schedule.isActiveAt(wednesdayMorning), isTrue);

      // Wednesday 8:59 AM -> inactive
      final wednesdayEarly = DateTime(2026, 9, 30, 8, 59);
      expect(schedule.isActiveAt(wednesdayEarly), isFalse);

      // Wednesday 5:01 PM -> inactive
      final wednesdayAfter = DateTime(2026, 9, 30, 17, 1);
      expect(schedule.isActiveAt(wednesdayAfter), isFalse);

      // Saturday 12:00 PM -> inactive (not a weekday)
      final saturdayNoon = DateTime(2026, 10, 3, 12, 0); // 2026-10-03 is Saturday
      expect(schedule.isActiveAt(saturdayNoon), isFalse);
    });

    test('overnight schedule crossing midnight matches pre- and post-midnight correctly', () {
      // Monday overnight focus: 22:00 (10 PM) to 06:00 (6 AM)
      final nightSchedule = FocusSchedule(
        id: 'night_sleep',
        name: 'Night Sleep',
        startHour: 22,
        startMinute: 0,
        endHour: 6,
        endMinute: 0,
        weekdays: [DateTime.monday],
      );

      // 1. Monday 23:30 (11:30 PM) -> should be ACTIVE
      final mondayNight = DateTime(2026, 9, 28, 23, 30); // Monday
      expect(nightSchedule.isActiveAt(mondayNight), isTrue);

      // 2. Tuesday 03:15 (3:15 AM) -> should be ACTIVE (second half of Monday night)
      final tuesdayEarly = DateTime(2026, 9, 29, 3, 15); // Tuesday morning
      expect(nightSchedule.isActiveAt(tuesdayEarly), isTrue);

      // 3. Tuesday 06:30 (6:30 AM) -> should be INACTIVE (window ended at 06:00)
      final tuesdayMorning = DateTime(2026, 9, 29, 6, 30);
      expect(nightSchedule.isActiveAt(tuesdayMorning), isFalse);

      // 4. Sunday 23:00 -> should be INACTIVE (Sunday wasn't selected)
      final sundayNight = DateTime(2026, 9, 27, 23, 0);
      expect(nightSchedule.isActiveAt(sundayNight), isFalse);
    });

    test('disabled schedule never reports active', () {
      final schedule = FocusSchedule(
        id: 'disabled',
        name: 'Paused',
        startHour: 0,
        startMinute: 0,
        endHour: 23,
        endMinute: 59,
        weekdays: [1, 2, 3, 4, 5, 6, 7],
        isEnabled: false,
      );

      expect(schedule.isActiveAt(DateTime.now()), isFalse);
    });

    test('serializes and deserializes cleanly to/from JSON', () {
      final original = FocusSchedule(
        id: 'test_123',
        name: 'Deep Reading',
        startHour: 20,
        startMinute: 30,
        endHour: 22,
        endMinute: 0,
        weekdays: [DateTime.saturday, DateTime.sunday],
        isEnabled: true,
      );

      final json = original.toJson();
      final restored = FocusSchedule.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.startHour, 20);
      expect(restored.startMinute, 30);
      expect(restored.endHour, 22);
      expect(restored.endMinute, 0);
      expect(restored.weekdays, [DateTime.saturday, DateTime.sunday]);
      expect(restored.isEnabled, isTrue);
      expect(restored.weekdaysFormatted, 'Weekends (Sat–Sun)');
      expect(restored.timeFormatted, '20:30 – 22:00');
    });
  });
}
