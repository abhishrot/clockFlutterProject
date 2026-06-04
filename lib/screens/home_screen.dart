import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/alarm_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/screen_provider.dart';
import '../widgets/glass_card.dart';
import 'alarm_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late Timer _currentTimeTimer;
  late DateTime _now;
  double _bgOpacity = 0.35; // Default graffiti opacity
  bool _is24HourFormat = true;
  
  // Animation controller for pulsating alarm icon & ringing overlay
  late AnimationController _pulsateController;
  late Animation<double> _pulsateAnimation;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _currentTimeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });

    _pulsateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulsateAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulsateController, curve: Curves.easeInOut),
    );

    _loadTimeFormatPreference();
  }

  Future<void> _loadTimeFormatPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _is24HourFormat = prefs.getBool('is_24_hour_format') ?? true;
      });
    }
  }

  Future<void> _saveTimeFormatPreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_24_hour_format', _is24HourFormat);
  }

  @override
  void dispose() {
    _currentTimeTimer.cancel();
    _pulsateController.dispose();
    super.dispose();
  }

  // Calculate remaining days in the current year
  int _getDaysRemaining() {
    final lastDay = DateTime(_now.year, 12, 31);
    final today = DateTime(_now.year, _now.month, _now.day);
    // Difference in days plus 1 to count Dec 31st
    return lastDay.difference(today).inDays + 1;
  }

  double _getYearProgress() {
    final isLeapYear = (_now.year % 4 == 0 && _now.year % 100 != 0) || (_now.year % 400 == 0);
    final totalDays = isLeapYear ? 366 : 365;
    final remaining = _getDaysRemaining();
    final elapsed = totalDays - remaining;
    return (elapsed / totalDays).clamp(0.0, 1.0);
  }

  String _getFormattedDate() {
    final weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
    final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    
    final weekday = weekdays[_now.weekday % 7];
    final month = months[_now.month - 1];
    return "$weekday, $month ${_now.day}, ${_now.year}";
  }

  // Trigger Haptic feedback and show wake lock selection sheet
  void _showWakelockSettingsSheet(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Consumer<ScreenProvider>(
          builder: (context, screenProv, child) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final primaryColor = isDark ? Colors.cyanAccent : Colors.deepPurpleAccent;

            return GlassCard(
              borderRadius: 32,
              opacity: isDark ? 0.8 : 0.9,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white30 : Colors.black26,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "SCREEN KEEP-AWAKE SETTINGS",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Options List
                  _buildWakeModeOption(
                    context, 
                    screenProv, 
                    WakeMode.disabled, 
                    "Disabled", 
                    "Standard device sleep time rules apply.",
                    primaryColor
                  ),
                  _buildWakeModeOption(
                    context, 
                    screenProv, 
                    WakeMode.alwaysOn, 
                    "Always On", 
                    "Screen will never turn off while the clock is active.",
                    primaryColor
                  ),
                  _buildWakeModeOption(
                    context, 
                    screenProv, 
                    WakeMode.hourly, 
                    "Hourly Awake Cycle", 
                    "Keeps screen awake for the first 5 minutes of every hour.",
                    primaryColor
                  ),
                  _buildWakeModeOption(
                    context, 
                    screenProv, 
                    WakeMode.scheduled, 
                    "Scheduled Sleep Window", 
                    "Screen stays awake from ${_formatTime(screenProv.startHour, screenProv.startMinute)} to ${_formatTime(screenProv.endHour, screenProv.endMinute)} daily.",
                    primaryColor
                  ),
                  if (screenProv.wakeMode == WakeMode.scheduled) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _buildTimePickerButton(
                            context,
                            "Turn-On Time",
                            screenProv.startHour,
                            screenProv.startMinute,
                            primaryColor,
                            (hour, minute) {
                              screenProv.setScheduledRange(
                                hour,
                                minute,
                                screenProv.endHour,
                                screenProv.endMinute,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTimePickerButton(
                            context,
                            "Turn-Off Time",
                            screenProv.endHour,
                            screenProv.endMinute,
                            primaryColor,
                            (hour, minute) {
                              screenProv.setScheduledRange(
                                screenProv.startHour,
                                screenProv.startMinute,
                                hour,
                                minute,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWakeModeOption(
    BuildContext context, 
    ScreenProvider prov, 
    WakeMode mode, 
    String title, 
    String desc,
    Color activeColor
  ) {
    final isSelected = prov.wakeMode == mode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isSelected ? activeColor : (isDark ? Colors.white : Colors.black87),
        ),
      ),
      subtitle: Text(
        desc,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.white54 : Colors.black54,
        ),
      ),
      trailing: isSelected 
          ? Icon(Icons.check_circle, color: activeColor) 
          : Icon(Icons.circle_outlined, color: isDark ? Colors.white30 : Colors.black26),
      onTap: () {
        HapticFeedback.lightImpact();
        prov.setWakeMode(mode);
      },
    );
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final dispHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final dispMinute = minute.toString().padLeft(2, '0');
    return "$dispHour:$dispMinute $period";
  }

  Widget _buildTimePickerButton(
    BuildContext context,
    String label,
    int hour,
    int minute,
    Color primaryColor,
    Function(int, int) onTimeSelected,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeStr = _formatTime(hour, minute);

    return InkWell(
      onTap: () async {
        HapticFeedback.lightImpact();
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: hour, minute: minute),
        );
        if (picked != null) {
          onTimeSelected(picked.hour, picked.minute);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: primaryColor.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 16,
                  color: primaryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProv = Provider.of<ThemeProvider>(context);
    final alarmProv = Provider.of<AlarmProvider>(context);
    final screenProv = Provider.of<ScreenProvider>(context);
    
    final isDark = themeProv.isDarkMode;
    final primaryColor = isDark ? Colors.cyanAccent : Colors.deepPurpleAccent;
    final activeTextColor = isDark ? Colors.white : Colors.black87;

    // Time calculations
    final is24 = _is24HourFormat;
    final intHour = _now.hour;
    final String hourStr;
    final String periodStr;

    if (is24) {
      hourStr = intHour.toString().padLeft(2, '0');
      periodStr = "";
    } else {
      final h12 = intHour % 12 == 0 ? 12 : intHour % 12;
      hourStr = h12.toString().padLeft(2, '0');
      periodStr = intHour >= 12 ? "PM" : "AM";
    }

    final minute = _now.minute.toString().padLeft(2, '0');
    final second = _now.second.toString().padLeft(2, '0');

    // Layout configuration
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey.shade100,
      body: Stack(
        children: [
          // 1. Colorful gradient blobs for modern glassmorphism
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (isDark ? Colors.cyan : Colors.deepPurple).withOpacity(0.35),
                    (isDark ? Colors.cyan : Colors.deepPurple).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (isDark ? Colors.purpleAccent : Colors.pinkAccent).withOpacity(0.3),
                    (isDark ? Colors.purpleAccent : Colors.pinkAccent).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.3,
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (isDark ? Colors.tealAccent : Colors.blueAccent).withOpacity(0.25),
                    (isDark ? Colors.tealAccent : Colors.blueAccent).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          // 2. Graffiti Background underneath the glass pane
          Positioned.fill(
            child: Opacity(
              opacity: _bgOpacity,
              child: Image.asset(
                'assets/images/graffiti.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 3. Frosted Glass Overlay (BackdropFilter)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
              child: Container(
                color: isDark 
                    ? Colors.black.withOpacity(0.55) 
                    : Colors.white.withOpacity(0.55),
              ),
            ),
          ),
          
          // 2. Main Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Upper Control Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Theme Switcher
                      IconButton(
                        icon: Icon(
                          isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                          color: primaryColor,
                          size: 28,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          themeProv.toggleTheme();
                        },
                      ),
                      
                      // Time Format Switcher (12H / 24H)
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _is24HourFormat = !_is24HourFormat;
                            _saveTimeFormatPreference();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: primaryColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.schedule, size: 14, color: primaryColor),
                              const SizedBox(width: 4),
                              Text(
                                _is24HourFormat ? "24H" : "12H",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Opacity Control Button (Quick slider)
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            // Cycle through opacity levels: 0.15 -> 0.35 -> 0.6 -> 0.85 -> 0.05
                            if (_bgOpacity == 0.35) {
                              _bgOpacity = 0.6;
                            } else if (_bgOpacity == 0.6) {
                              _bgOpacity = 0.85;
                            } else if (_bgOpacity == 0.85) {
                              _bgOpacity = 0.05;
                            } else if (_bgOpacity == 0.05) {
                              _bgOpacity = 0.15;
                            } else {
                              _bgOpacity = 0.35;
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: primaryColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.wallpaper, size: 16, color: primaryColor),
                              const SizedBox(width: 4),
                              Text(
                                "BG: ${(_bgOpacity * 100).toInt()}%",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Screen Awake Status Widget
                      GestureDetector(
                        onTap: () => _showWakelockSettingsSheet(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: screenProv.isWakelockEnabled 
                                ? primaryColor.withOpacity(0.2) 
                                : Colors.grey.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: screenProv.isWakelockEnabled 
                                  ? primaryColor.withOpacity(0.4) 
                                  : Colors.grey.withOpacity(0.3)
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                screenProv.isWakelockEnabled ? Icons.phone_android : Icons.screen_lock_rotation,
                                size: 16,
                                color: screenProv.isWakelockEnabled ? primaryColor : Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                screenProv.isWakelockEnabled ? "AWAKE ON" : "SLEEP NORMAL",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: screenProv.isWakelockEnabled ? primaryColor : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Alarms Screen Button
                      IconButton(
                        icon: Icon(
                          Icons.alarm,
                          color: primaryColor,
                          size: 28,
                        ),
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const AlarmScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // Responsive Body with smooth transition animation on device rotation
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      switchInCurve: Curves.easeInOut,
                      switchOutCurve: Curves.easeInOut,
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.96, end: 1.0).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: isLandscape 
                          ? KeyedSubtree(
                              key: const ValueKey('landscape'),
                              child: _buildLandscapeLayout(context, hourStr, minute, second, activeTextColor, primaryColor, alarmProv, screenProv),
                            )
                          : KeyedSubtree(
                              key: const ValueKey('portrait'),
                              child: _buildPortraitLayout(context, hourStr, minute, second, activeTextColor, primaryColor, alarmProv, screenProv),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 3. Ringing Alarm Trigger Overlay (Draw over everything)
          if (alarmProv.triggeredAlarm != null)
            _buildAlarmRingingOverlay(context, alarmProv, primaryColor),
        ],
      ),
    );
  }

  // PORTRAIT LAYOUT
  Widget _buildPortraitLayout(
    BuildContext context, 
    String hour, 
    String minute, 
    String second, 
    Color textColor, 
    Color primaryColor,
    AlarmProvider alarmProv,
    ScreenProvider screenProv
  ) {
    final daysRemaining = _getDaysRemaining();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        
        // Alarm Bell (100% visible only when alarm is set, fully invisible otherwise)
        Opacity(
          opacity: alarmProv.hasActiveAlarm ? 1.0 : 0.0,
          child: ScaleTransition(
            scale: _pulsateAnimation,
            child: Icon(
              Icons.notifications_active,
              color: primaryColor,
              size: 40,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Glowing digital clock face
        Text(
          "$hour:$minute",
          style: TextStyle(
            fontSize: 90,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: textColor,
            height: 1.0,
            shadows: [
              Shadow(
                color: primaryColor.withOpacity(0.6),
                blurRadius: 25,
              ),
            ],
          ),
        ),
        
        // Seconds indicator below time
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _is24HourFormat ? "$second SEC" : "$second SEC  •  ${_now.hour >= 12 ? 'PM' : 'AM'}",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
              color: primaryColor,
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Formatted Date
        Text(
          _getFormattedDate().toUpperCase(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: textColor.withOpacity(0.8),
          ),
        ),
        
        const Spacer(),

        // Simplified Year Countdown Card
        GlassCard(
          opacity: isDark ? 0.15 : 0.35,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          borderRadius: 20,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.hourglass_empty_rounded,
                size: 18,
                color: primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                "$daysRemaining days remaining in ${_now.year}",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: textColor.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
      ],
    );
  }

  // LANDSCAPE LAYOUT
  Widget _buildLandscapeLayout(
    BuildContext context, 
    String hour, 
    String minute, 
    String second, 
    Color textColor, 
    Color primaryColor,
    AlarmProvider alarmProv,
    ScreenProvider screenProv
  ) {
    final daysRemaining = _getDaysRemaining();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        // Left Side: Clock, Date, and Active Alarm pulsing icon
        Expanded(
          flex: 12,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pulsing Alarm Icon
              Opacity(
                opacity: alarmProv.hasActiveAlarm ? 1.0 : 0.0,
                child: ScaleTransition(
                  scale: _pulsateAnimation,
                  child: Icon(
                    Icons.notifications_active,
                    color: primaryColor,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    "$hour:$minute",
                    style: TextStyle(
                      fontSize: 76,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: textColor,
                      shadows: [
                        Shadow(
                          color: primaryColor.withOpacity(0.6),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _is24HourFormat ? second : "$second\n${_now.hour >= 12 ? 'PM' : 'AM'}",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _getFormattedDate().toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: textColor.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(width: 20),

        // Right Side: Year remaining details and Wakelock quick details
        Expanded(
          flex: 11,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Simplified Year Countdown Card
                GlassCard(
                  opacity: isDark ? 0.15 : 0.35,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  borderRadius: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.hourglass_empty_rounded,
                        size: 18,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "$daysRemaining days left in ${_now.year}",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: textColor.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),

                // Wake Mode Settings Detail Card
                GestureDetector(
                  onTap: () => _showWakelockSettingsSheet(context),
                  child: GlassCard(
                    opacity: Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.45,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.power_settings_new, color: primaryColor, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "SCREEN WAKE MODE",
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: textColor.withOpacity(0.5),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                screenProv.wakeModeFormatted,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_drop_up, color: textColor.withOpacity(0.5)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ALARM RINGING OVERLAY (FULL SCREEN TRIGGER WIDGET)
  Widget _buildAlarmRingingOverlay(
    BuildContext context, 
    AlarmProvider alarmProv, 
    Color primaryColor
  ) {
    // Generate vibrations
    HapticFeedback.heavyImpact();

    return Container(
      color: Colors.black.withOpacity(0.92),
      width: double.infinity,
      height: double.infinity,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              
              // Pulsing large neon ring icon
              ScaleTransition(
                scale: _pulsateAnimation,
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor.withOpacity(0.1),
                    border: Border.all(
                      color: primaryColor,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.5),
                        blurRadius: 40,
                        spreadRadius: 5,
                      )
                    ],
                  ),
                  child: Icon(
                    Icons.alarm,
                    size: 100,
                    color: primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 50),
              
              Text(
                "ALARM TRIGGERED",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              
              Text(
                alarmProv.triggeredAlarm!.timeFormatted,
                style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              
              Text(
                alarmProv.triggeredAlarm!.label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                  letterSpacing: 2,
                ),
              ),
              
              const Spacer(),
              
              // Dismiss trigger button
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.vibrate();
                    alarmProv.dismissAlarm();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 12,
                    shadowColor: Colors.redAccent.withOpacity(0.5),
                  ),
                  child: const Text(
                    "DISMISS",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
