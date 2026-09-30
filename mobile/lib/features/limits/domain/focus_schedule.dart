
/// Represents a scheduled focus window during which app access is locked
/// and notifications are silenced.
class FocusSchedule {
  const FocusSchedule({
    required this.id,
    required this.name,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.weekdays,
    this.isEnabled = true,
  });

  final String id;
  final String name;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  /// Days of the week (1 = Monday, 7 = Sunday, matching [DateTime.monday] .. [DateTime.sunday]).
  final List<int> weekdays;
  final bool isEnabled;

  /// Returns true if [dateTime] falls within this focus schedule.
  bool isActiveAt(DateTime dateTime) {
    if (!isEnabled || weekdays.isEmpty) return false;

    final currentTotalMinutes = dateTime.hour * 60 + dateTime.minute;
    final startTotalMinutes = startHour * 60 + startMinute;
    final endTotalMinutes = endHour * 60 + endMinute;

    // Case 1: Same-day window (e.g. 09:00 to 17:00)
    if (startTotalMinutes <= endTotalMinutes) {
      if (weekdays.contains(dateTime.weekday)) {
        return currentTotalMinutes >= startTotalMinutes &&
            currentTotalMinutes < endTotalMinutes;
      }
      return false;
    }

    // Case 2: Overnight window crossing midnight (e.g. 22:00 to 06:00)
    // Part A: Pre-midnight (e.g. 22:00 to 23:59) -> belongs to today's schedule
    if (currentTotalMinutes >= startTotalMinutes) {
      return weekdays.contains(dateTime.weekday);
    }

    // Part B: Post-midnight (e.g. 00:00 to 05:59) -> belongs to yesterday's schedule
    if (currentTotalMinutes < endTotalMinutes) {
      final yesterdayWeekday = dateTime.weekday == DateTime.monday
          ? DateTime.sunday
          : dateTime.weekday - 1;
      return weekdays.contains(yesterdayWeekday);
    }

    return false;
  }

  String get timeFormatted {
    final startH = startHour.toString().padLeft(2, '0');
    final startM = startMinute.toString().padLeft(2, '0');
    final endH = endHour.toString().padLeft(2, '0');
    final endM = endMinute.toString().padLeft(2, '0');
    return '$startH:$startM – $endH:$endM';
  }

  String get weekdaysFormatted {
    if (weekdays.length == 7) return 'Every day';
    if (weekdays.length == 5 &&
        !weekdays.contains(DateTime.saturday) &&
        !weekdays.contains(DateTime.sunday)) {
      return 'Weekdays (Mon–Fri)';
    }
    if (weekdays.length == 2 &&
        weekdays.contains(DateTime.saturday) &&
        weekdays.contains(DateTime.sunday)) {
      return 'Weekends (Sat–Sun)';
    }

    const shortDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final sorted = List<int>.from(weekdays)..sort();
    return sorted.map((d) => shortDays[d - 1]).join(', ');
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'startHour': startHour,
        'startMinute': startMinute,
        'endHour': endHour,
        'endMinute': endMinute,
        'weekdays': weekdays,
        'isEnabled': isEnabled,
      };

  factory FocusSchedule.fromJson(Map<String, dynamic> json) {
    return FocusSchedule(
      id: json['id'] as String,
      name: json['name'] as String,
      startHour: json['startHour'] as int,
      startMinute: json['startMinute'] as int,
      endHour: json['endHour'] as int,
      endMinute: json['endMinute'] as int,
      weekdays: (json['weekdays'] as List<dynamic>).map((e) => e as int).toList(),
      isEnabled: json['isEnabled'] as bool? ?? true,
    );
  }

  FocusSchedule copyWith({
    String? id,
    String? name,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
    List<int>? weekdays,
    bool? isEnabled,
  }) {
    return FocusSchedule(
      id: id ?? this.id,
      name: name ?? this.name,
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      endHour: endHour ?? this.endHour,
      endMinute: endMinute ?? this.endMinute,
      weekdays: weekdays ?? this.weekdays,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}
