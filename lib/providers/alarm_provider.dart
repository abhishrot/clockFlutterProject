import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/alarm.dart';

class AlarmProvider with ChangeNotifier {
  static const String _alarmsKey = "user_alarms";
  List<Alarm> _alarms = [];
  Alarm? _triggeredAlarm;
  Timer? _alarmCheckTimer;
  String? _lastTriggeredKey; // To avoid triggering multiple times in the same minute
  
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<Alarm> get alarms => _alarms;
  Alarm? get triggeredAlarm => _triggeredAlarm;

  bool get hasActiveAlarm => _alarms.any((alarm) => alarm.isActive);

  AlarmProvider() {
    _loadAlarms();
    _startAlarmCheck();
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
  }

  @override
  void dispose() {
    _alarmCheckTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final String? alarmsJson = prefs.getString(_alarmsKey);
    if (alarmsJson != null) {
      try {
        final List<dynamic> decodedList = jsonDecode(alarmsJson);
        _alarms = decodedList.map((item) => Alarm.fromJson(item)).toList();
        notifyListeners();
      } catch (e) {
        debugPrint("Error loading alarms: $e");
      }
    }
  }

  Future<void> _saveAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedList = jsonEncode(_alarms.map((a) => a.toJson()).toList());
    await prefs.setString(_alarmsKey, encodedList);
    notifyListeners();
  }

  void addAlarm(Alarm alarm) {
    _alarms.add(alarm);
    _saveAlarms();
  }

  void updateAlarm(Alarm updatedAlarm) {
    final index = _alarms.indexWhere((a) => a.id == updatedAlarm.id);
    if (index != -1) {
      _alarms[index] = updatedAlarm;
      _saveAlarms();
    }
  }

  void deleteAlarm(String id) {
    _alarms.removeWhere((a) => a.id == id);
    _saveAlarms();
  }

  void toggleAlarm(String id) {
    final index = _alarms.indexWhere((a) => a.id == id);
    if (index != -1) {
      _alarms[index] = _alarms[index].copyWith(isActive: !_alarms[index].isActive);
      _saveAlarms();
    }
  }

  void dismissAlarm() {
    _triggeredAlarm = null;
    _audioPlayer.stop();
    notifyListeners();
  }

  void _startAlarmCheck() {
    _alarmCheckTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkAlarms();
    });
  }

  void _checkAlarms() {
    if (_triggeredAlarm != null) return; // Already ringing

    final now = DateTime.now();
    // Unique key for the current minute: "YYYY-MM-DD HH:MM"
    final currentMinuteKey = "${now.year}-${now.month}-${now.day} ${now.hour}:${now.minute}";

    if (_lastTriggeredKey == currentMinuteKey) {
      return; // Already checked/triggered in this minute
    }

    for (var alarm in _alarms) {
      if (alarm.isActive && alarm.hour == now.hour && alarm.minute == now.minute) {
        // Check repeat days
        // DateTime.weekday: 1 = Monday, 7 = Sunday
        if (alarm.repeatDays.isEmpty || alarm.repeatDays.contains(now.weekday)) {
          _triggeredAlarm = alarm;
          _lastTriggeredKey = currentMinuteKey;
          _audioPlayer.play(AssetSource('sounds/alarm.mp3'));

          // If the alarm is one-time (no repeats), turn it off after it triggers
          if (alarm.repeatDays.isEmpty) {
            final index = _alarms.indexWhere((a) => a.id == alarm.id);
            if (index != -1) {
              _alarms[index] = _alarms[index].copyWith(isActive: false);
              _saveAlarms();
            }
          }
          
          notifyListeners();
          break; // Trigger one alarm at a time
        }
      }
    }
  }
}
