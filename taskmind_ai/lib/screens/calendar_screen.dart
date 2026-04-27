import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/db_service.dart';
import '../services/auth_service.dart';
import '../models/task_model.dart';
import 'add_task_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    if (user == null) return const Center(child: Text("Not logged in"));

    return StreamBuilder<List<TaskModel>>(
      stream: DbService().getTasks(user.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final tasks = snapshot.data ?? [];
        
        final selectedTasks = tasks.where((t) {
            if (_selectedDay == null) return false;
            return t.dueDate.year == _selectedDay!.year &&
                   t.dueDate.month == _selectedDay!.month &&
                   t.dueDate.day == _selectedDay!.day;
        }).toList();

        return Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: TableCalendar<TaskModel>(
                firstDay: DateTime.utc(2020, 10, 16),
                lastDay: DateTime.utc(2030, 3, 14),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                eventLoader: (day) {
                  return tasks.where((t) => t.dueDate.year == day.year && t.dueDate.month == day.month && t.dueDate.day == day.day).toList();
                },
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(color: const Color(0xFF60EFFF).withOpacity(0.5), shape: BoxShape.circle),
                  selectedDecoration: const BoxDecoration(color: Color(0xFF60EFFF), shape: BoxShape.circle),
                  markerDecoration: const BoxDecoration(color: Color(0xFF00FF87), shape: BoxShape.circle),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Align(alignment: Alignment.centerLeft, child: Text('Tasks on this date:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
            ),
            Expanded(
              child: selectedTasks.isEmpty 
                  ? const Center(child: Text('No tasks scheduled for this day.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: selectedTasks.length,
                      itemBuilder: (context, index) {
                        final t = selectedTasks[index];
                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            leading: Icon(t.isCompleted ? Icons.check_circle : Icons.circle_outlined, color: t.isCompleted ? Colors.green : Colors.grey),
                            title: Text(t.title, style: TextStyle(decoration: t.isCompleted ? TextDecoration.lineThrough : null)),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => AddTaskScreen(task: t)));
                            },
                          ),
                        );
                      },
                    ),
            )
          ],
        );
      },
    );
  }
}
