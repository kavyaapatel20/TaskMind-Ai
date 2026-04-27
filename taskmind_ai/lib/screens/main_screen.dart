import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'tasks_screen.dart';
import 'profile_screen.dart';
import 'pomodoro_screen.dart';
import 'calendar_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const TasksScreen(),
    const PomodoroScreen(),
    const CalendarScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade900,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          decoration: BoxDecoration(
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 50, spreadRadius: 10)],
          ),
          child: ClipRRect(
            child: Scaffold(
              appBar: AppBar(
                title: const Row(
                  children: [
                     Icon(Icons.bolt, color: Color(0xFF60EFFF)),
                     SizedBox(width: 8),
                     Text('TaskMind AI', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none, color: Colors.amber),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No new notifications today!')));
                    },
                  )
                ],
              ),
              body: _screens[_currentIndex],
              bottomNavigationBar: NavigationBarTheme(
                data: NavigationBarThemeData(
                  labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  indicatorColor: const Color(0xFF60EFFF).withOpacity(0.2),
                ),
                child: NavigationBar(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
                  destinations: const [
                    NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard, color: Color(0xFF60EFFF)), label: 'Home'),
                    NavigationDestination(icon: Icon(Icons.task_alt), selectedIcon: Icon(Icons.check_circle, color: Color(0xFF60EFFF)), label: 'Tasks'),
                    NavigationDestination(icon: Icon(Icons.timer_outlined), selectedIcon: Icon(Icons.timer, color: Color(0xFF60EFFF)), label: 'Focus'),
                    NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month, color: Color(0xFF60EFFF)), label: 'Calendar'),
                    NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: Color(0xFF60EFFF)), label: 'Profile'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
