import 'package:flutter/material.dart';

class Alarm {
  final String id;
  final int hour;
  final int minute;
  final String label;
  final bool isActive;
  final List<int> repeatDays; // 1 = Monday, 7 = Sunday

  Alarm({
    required this.id,
    required this.hour,
    required this.minute,
    required this.label,
    this.isActive = true,
    required this.repeatDays,
  });

  TimeOfDay get time => TimeOfDay(hour: hour, minute: minute);

  Alarm copyWith({
    String? id,
    int? hour,
    int? minute,
    String? label,
    bool? isActive,
    List<int>? repeatDays,
  }) {
    return Alarm(
      id: id ?? this.id,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      label: label ?? this.label,
      isActive: isActive ?? this.isActive,
      repeatDays: repeatDays ?? this.repeatDays,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hour': hour,
      'minute': minute,
      'label': label,
      'isActive': isActive,
      'repeatDays': repeatDays,
    };
  }

  factory Alarm.fromJson(Map<String, dynamic> json) {
    return Alarm(
      id: json['id'] as String,
      hour: json['hour'] as int,
      minute: json['minute'] as int,
      label: json['label'] as String,
      isActive: json['isActive'] as bool,
      repeatDays: List<int>.from(json['repeatDays'] as List),
    );
  }

  String get timeFormatted {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  String get repeatDaysFormatted {
    if (repeatDays.isEmpty) return 'Once';
    if (repeatDays.length == 7) return 'Every day';
    if (repeatDays.length == 5 &&
        repeatDays.contains(1) &&
        repeatDays.contains(2) &&
        repeatDays.contains(3) &&
        repeatDays.contains(4) &&
        repeatDays.contains(5)) {
      return 'Weekdays';
    }
    if (repeatDays.length == 2 &&
        repeatDays.contains(6) &&
        repeatDays.contains(7)) {
      return 'Weekends';
    }

    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final sortedDays = List<int>.from(repeatDays)..sort();
    return sortedDays.map((d) => dayNames[d - 1]).join(', ');
  }
}
