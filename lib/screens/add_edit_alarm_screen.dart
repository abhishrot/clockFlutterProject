import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/alarm.dart';
import '../providers/alarm_provider.dart';
import '../widgets/glass_card.dart';

class AddEditAlarmScreen extends StatefulWidget {
  final Alarm? alarm; // if null, we are adding a new alarm

  const AddEditAlarmScreen({super.key, this.alarm});

  @override
  State<AddEditAlarmScreen> createState() => _AddEditAlarmScreenState();
}

class _AddEditAlarmScreenState extends State<AddEditAlarmScreen> {
  late TimeOfDay _selectedTime;
  late TextEditingController _labelController;
  late List<int> _repeatDays; // 1 = Mon, 7 = Sun

  final List<String> _dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void initState() {
    super.initState();
    if (widget.alarm != null) {
      _selectedTime = TimeOfDay(hour: widget.alarm!.hour, minute: widget.alarm!.minute);
      _labelController = TextEditingController(text: widget.alarm!.label);
      _repeatDays = List<int>.from(widget.alarm!.repeatDays);
    } else {
      final now = DateTime.now();
      _selectedTime = TimeOfDay(hour: now.hour, minute: now.minute);
      _labelController = TextEditingController(text: 'Alarm');
      _repeatDays = [];
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Colors.cyanAccent,
                    onPrimary: Colors.black,
                    surface: Colors.black87,
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: Colors.deepPurple,
                    onPrimary: Colors.white,
                    surface: Colors.white70,
                    onSurface: Colors.black,
                  ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _toggleDay(int dayIndex) {
    setState(() {
      if (_repeatDays.contains(dayIndex)) {
        _repeatDays.remove(dayIndex);
      } else {
        _repeatDays.add(dayIndex);
      }
    });
  }

  void _saveAlarm() {
    final alarmProvider = Provider.of<AlarmProvider>(context, listen: false);
    final String label = _labelController.text.trim().isEmpty ? 'Alarm' : _labelController.text;

    if (widget.alarm != null) {
      // Edit
      final updated = widget.alarm!.copyWith(
        hour: _selectedTime.hour,
        minute: _selectedTime.minute,
        label: label,
        isActive: true, // Auto-activate on edit
        repeatDays: _repeatDays,
      );
      alarmProvider.updateAlarm(updated);
    } else {
      // Add
      final newAlarm = Alarm(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        hour: _selectedTime.hour,
        minute: _selectedTime.minute,
        label: label,
        isActive: true,
        repeatDays: _repeatDays,
      );
      alarmProvider.addAlarm(newAlarm);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.cyanAccent : Colors.deepPurpleAccent;

    // Formatting display time
    final period = _selectedTime.hour >= 12 ? 'PM' : 'AM';
    final displayHour = _selectedTime.hour == 0
        ? 12
        : (_selectedTime.hour > 12 ? _selectedTime.hour - 12 : _selectedTime.hour);
    final displayMinute = _selectedTime.minute.toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background Graffiti overlay with blur
          Positioned.fill(
            child: Image.asset(
              'assets/images/graffiti.jpg',
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(isDark ? 0.75 : 0.45),
              colorBlendMode: BlendMode.dstATop,
            ),
          ),
          
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  pinned: true,
                  title: Text(
                    widget.alarm != null ? 'Edit Alarm' : 'Add Alarm',
                    style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                  centerTitle: true,
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.check, size: 28),
                      color: primaryColor,
                      onPressed: _saveAlarm,
                    ),
                  ],
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 20),
                      // Time picker trigger card
                      GestureDetector(
                        onTap: () => _selectTime(context),
                        child: GlassCard(
                          opacity: isDark ? 0.25 : 0.4,
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              Text(
                                "TAP TO CHANGE TIME",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: (isDark ? Colors.white70 : Colors.black87).withOpacity(0.6),
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 15),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    "$displayHour:$displayMinute",
                                    style: TextStyle(
                                      fontSize: 64,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    period,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Repeat days card
                      GlassCard(
                        opacity: isDark ? 0.25 : 0.4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "REPEAT DAYS",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: (isDark ? Colors.white70 : Colors.black87).withOpacity(0.6),
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(7, (index) {
                                final dayNumber = index + 1; // 1 = Mon, 7 = Sun
                                final isSelected = _repeatDays.contains(dayNumber);
                                return GestureDetector(
                                  onTap: () => _toggleDay(dayNumber),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    height: 42,
                                    width: 42,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? primaryColor
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.transparent
                                            : (isDark ? Colors.white30 : Colors.black.withOpacity(0.3)),
                                        width: 1.5,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: primaryColor.withOpacity(0.4),
                                                blurRadius: 10,
                                                spreadRadius: 1,
                                              )
                                            ]
                                          : [],
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      _dayNames[index],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? (isDark ? Colors.black : Colors.white)
                                            : (isDark ? Colors.white : Colors.black87),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Label card
                      GlassCard(
                        opacity: isDark ? 0.25 : 0.4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "ALARM LABEL",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: (isDark ? Colors.white70 : Colors.black87).withOpacity(0.6),
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _labelController,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText: "Enter label",
                                hintStyle: TextStyle(
                                  color: (isDark ? Colors.white30 : Colors.black.withOpacity(0.3)),
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: (isDark ? Colors.white24 : Colors.black.withOpacity(0.24)),
                                  ),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // Save Button (additional bottom trigger)
                      ElevatedButton(
                        onPressed: _saveAlarm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 8,
                          shadowColor: primaryColor.withOpacity(0.4),
                        ),
                        child: const Text(
                          "Save Alarm",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
