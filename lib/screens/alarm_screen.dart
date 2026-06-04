import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/alarm.dart';
import '../providers/alarm_provider.dart';
import '../widgets/glass_card.dart';
import 'add_edit_alarm_screen.dart';

class AlarmScreen extends StatelessWidget {
  const AlarmScreen({super.key});

  void _navigateToAddEdit(BuildContext context, [Alarm? alarm]) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            AddEditAlarmScreen(alarm: alarm),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.cyanAccent : Colors.deepPurpleAccent;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background Graffiti overlay with opacity/blur
          Positioned.fill(
            child: Image.asset(
              'assets/images/graffiti.jpg',
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(isDark ? 0.75 : 0.45),
              colorBlendMode: BlendMode.dstATop,
            ),
          ),
          
          SafeArea(
            child: Consumer<AlarmProvider>(
              builder: (context, provider, child) {
                final alarms = provider.alarms;

                return CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      pinned: true,
                      title: const Text(
                        'Alarms',
                        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                      centerTitle: true,
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    
                    if (alarms.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: GlassCard(
                            opacity: isDark ? 0.2 : 0.35,
                            borderRadius: 24,
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.alarm_off,
                                  size: 72,
                                  color: (isDark ? Colors.white60 : Colors.black54),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "No Alarms Set",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: (isDark ? Colors.white.withOpacity(0.8) : Colors.black87),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Tap the + button to add one",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: (isDark ? Colors.white.withOpacity(0.55) : Colors.black54),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final alarm = alarms[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: Dismissible(
                                  key: Key(alarm.id),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: const Icon(Icons.delete, color: Colors.white, size: 28),
                                  ),
                                  onDismissed: (direction) {
                                    provider.deleteAlarm(alarm.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Alarm "${alarm.label}" deleted'),
                                        action: SnackBarAction(
                                          label: 'Undo',
                                          textColor: primaryColor,
                                          onPressed: () {
                                            provider.addAlarm(alarm);
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                  child: GestureDetector(
                                    onTap: () => _navigateToAddEdit(context, alarm),
                                    child: GlassCard(
                                      opacity: isDark ? 0.25 : 0.45,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      alarm.timeFormatted.split(' ')[0],
                                                      style: TextStyle(
                                                        fontSize: 32,
                                                        fontWeight: FontWeight.bold,
                                                        color: alarm.isActive
                                                            ? (isDark ? Colors.white : Colors.black87)
                                                            : (isDark ? Colors.white38 : Colors.black38),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      alarm.timeFormatted.split(' ')[1],
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                        color: alarm.isActive
                                                            ? primaryColor
                                                            : (isDark ? Colors.white38 : Colors.black38),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    if (alarm.label.isNotEmpty) ...[
                                                      Text(
                                                        alarm.label,
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.w600,
                                                          color: alarm.isActive
                                                              ? (isDark ? Colors.white70 : Colors.black87)
                                                              : (isDark ? Colors.white38 : Colors.black38),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        "•",
                                                        style: TextStyle(
                                                          color: alarm.isActive
                                                              ? (isDark ? Colors.white54 : Colors.black54)
                                                              : (isDark ? Colors.white38 : Colors.black38),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                    ],
                                                    Text(
                                                      alarm.repeatDaysFormatted,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: alarm.isActive
                                                            ? (isDark ? Colors.white54 : Colors.black54)
                                                            : (isDark ? Colors.white38 : Colors.black38),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Switch(
                                            value: alarm.isActive,
                                            activeColor: primaryColor,
                                            activeTrackColor: primaryColor.withOpacity(0.3),
                                            inactiveThumbColor: isDark ? Colors.white24 : Colors.grey,
                                            inactiveTrackColor: isDark ? Colors.white10 : Colors.grey.shade300,
                                            onChanged: (value) {
                                              provider.toggleAlarm(alarm.id);
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                            childCount: alarms.length,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEdit(context),
        backgroundColor: primaryColor,
        foregroundColor: isDark ? Colors.black : Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}
