import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

enum WakeMode { disabled, alwaysOn, hourly, scheduled }

class ScreenProvider with ChangeNotifier {
  static const String _modeKey = "wake_mode";
  static const String _startHourKey = "wake_start_hour";
  static const String _startMinuteKey = "wake_start_minute";
  static const String _endHourKey = "wake_end_hour";
  static const String _endMinuteKey = "wake_end_minute";

  WakeMode _wakeMode = WakeMode.disabled;
  int _startHour = 22; // default 10 PM
  int _startMinute = 0;
  int _endHour = 7;    // default 7 AM
  int _endMinute = 0;

  Timer? _checkTimer;
  bool _isWakelockEnabled = false;

  WakeMode get wakeMode => _wakeMode;
  int get startHour => _startHour;
  int get startMinute => _startMinute;
  int get endHour => _endHour;
  int get endMinute => _endMinute;
  bool get isWakelockEnabled => _isWakelockEnabled;

  ScreenProvider() {
    _loadPreferences().then((_) {
      _startMonitoring();
    });
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    // Re-enable normal screen sleep on dispose
    _setWakelock(false);
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final modeStr = prefs.getString(_modeKey) ?? WakeMode.disabled.name;
    _wakeMode = WakeMode.values.firstWhere(
      (m) => m.name == modeStr,
      orElse: () => WakeMode.disabled,
    );
    _startHour = prefs.getInt(_startHourKey) ?? 22;
    _startMinute = prefs.getInt(_startMinuteKey) ?? 0;
    _endHour = prefs.getInt(_endHourKey) ?? 7;
    _endMinute = prefs.getInt(_endMinuteKey) ?? 0;
    notifyListeners();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, _wakeMode.name);
    await prefs.setInt(_startHourKey, _startHour);
    await prefs.setInt(_startMinuteKey, _startMinute);
    await prefs.setInt(_endHourKey, _endHour);
    await prefs.setInt(_endMinuteKey, _endMinute);
  }

  void setWakeMode(WakeMode mode) {
    _wakeMode = mode;
    _savePreferences();
    _evaluateWakelockState();
    notifyListeners();
  }

  void setScheduledRange(int startH, int startM, int endH, int endM) {
    _startHour = startH;
    _startMinute = startM;
    _endHour = endH;
    _endMinute = endM;
    _savePreferences();
    _evaluateWakelockState();
    notifyListeners();
  }

  void _startMonitoring() {
    _evaluateWakelockState();
    // Check every 15 seconds to apply correct wakelock state
    _checkTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _evaluateWakelockState();
    });
  }

  void _evaluateWakelockState() {
    final now = DateTime.now();
    bool shouldEnable = false;

    switch (_wakeMode) {
      case WakeMode.disabled:
        shouldEnable = false;
        break;
      case WakeMode.alwaysOn:
        shouldEnable = true;
        break;
      case WakeMode.hourly:
        // Keep awake for first 5 minutes of every hour
        shouldEnable = now.minute < 5;
        break;
      case WakeMode.scheduled:
        shouldEnable = _isTimeInRange(now.hour, now.minute);
        break;
    }

    _setWakelock(shouldEnable);
  }

  bool _isTimeInRange(int currentHour, int currentMinute) {
    final current = currentHour * 60 + currentMinute;
    final start = _startHour * 60 + _startMinute;
    final end = _endHour * 60 + _endMinute;

    if (start <= end) {
      // Normal interval within the same day, e.g., 9:00 to 17:00
      return current >= start && current <= end;
    } else {
      // Overnight interval, e.g., 22:00 to 7:00 (crosses midnight)
      return current >= start || current <= end;
    }
  }

  Future<void> _setWakelock(bool enable) async {
    if (_isWakelockEnabled == enable) return;

    try {
      if (enable) {
        await WakelockPlus.enable();
        _isWakelockEnabled = true;
        debugPrint("Wakelock enabled");
      } else {
        await WakelockPlus.disable();
        _isWakelockEnabled = false;
        debugPrint("Wakelock disabled");
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error updating wakelock: $e");
    }
  }

  String get wakeModeFormatted {
    switch (_wakeMode) {
      case WakeMode.disabled:
        return "Disabled (Standard Sleep)";
      case WakeMode.alwaysOn:
        return "Always On";
      case WakeMode.hourly:
        return "Wake First 5 Mins of Every Hour";
      case WakeMode.scheduled:
        final startPeriod = _startHour >= 12 ? 'PM' : 'AM';
        final startH = _startHour == 0 ? 12 : (_startHour > 12 ? _startHour - 12 : _startHour);
        final startM = _startMinute.toString().padLeft(2, '0');

        final endPeriod = _endHour >= 12 ? 'PM' : 'AM';
        final endH = _endHour == 0 ? 12 : (_endHour > 12 ? _endHour - 12 : _endHour);
        final endM = _endMinute.toString().padLeft(2, '0');

        return "Awake: $startH:$startM $startPeriod - $endH:$endM $endPeriod";
    }
  }
}
