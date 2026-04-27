import 'package:flutter/material.dart';
import '../services/db_service.dart';
import '../services/auth_service.dart';
import '../models/task_model.dart';
import 'add_task_screen.dart';
import 'ai_suggest_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  String _selectedPriority = 'All';
  final List<String> _filters = ['All', 'High', 'Medium', 'Low'];

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    if (user == null) return const Center(child: Text("Not logged in"));

    return Stack(
      children: [
        Column(
          children: [
            // Filter Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters.map((filter) {
                    final isSelected = _selectedPriority == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(filter, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.black : Colors.white, fontSize: 14)),
                        selected: isSelected,
                        selectedColor: const Color(0xFF60EFFF),
                        backgroundColor: Colors.blueGrey.shade700,
                        showCheckmark: false, // Cleaner look without checkmark
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? const Color(0xFF60EFFF) : Colors.transparent)),
                        onSelected: (bool selected) {
                          if (selected) {
                            setState(() => _selectedPriority = filter);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            
            // Task List
            Expanded(
              child: StreamBuilder<List<TaskModel>>(
                stream: DbService().getTasks(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const SizedBox(); // Home screen handles the UI for this error
                  }

                  var tasks = snapshot.data ?? [];
                  
                  // Apply filter logically
                  if (_selectedPriority != 'All') {
                    tasks = tasks.where((t) => t.priority == _selectedPriority).toList();
                  }

                  if (tasks.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_add, size: 80, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                          const SizedBox(height: 24),
                          const Text('No tasks found.', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('Tap the + button to create a task,\nor switch priority filters!', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Transform.scale(
                            scale: 1.2,
                            child: Checkbox(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              activeColor: const Color(0xFF00FF87),
                              checkColor: Colors.black,
                              value: task.isCompleted,
                              onChanged: (val) {
                                task.isCompleted = val ?? false;
                                DbService().updateTask(task);
                              },
                            ),
                          ),
                          title: Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                              color: task.isCompleted ? Colors.grey : null,
                            ),
                          ),
                          subtitle: Row(
                            children: [
                              if (task.isExpired)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.8), borderRadius: BorderRadius.circular(8)),
                                  child: const Text('OVERDUE', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: task.priority == 'High' ? Colors.redAccent.withOpacity(0.2) : Colors.blueAccent.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(task.priority, style: TextStyle(fontSize: 12, color: task.priority == 'High' ? Colors.redAccent : Colors.blueAccent)),
                                ),
                              Text('By ${task.dueDate.toLocal().toString().split(' ')[0]}', style: TextStyle(fontSize: 12, color: task.isExpired ? Colors.redAccent : Colors.grey)),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => DbService().deleteTask(task.id),
                          ),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => AddTaskScreen(task: task)));
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        
        // Floating action buttons
        Positioned(
          bottom: 20,
          right: 20,
          child: Column(
            children: [
              FloatingActionButton.small(
                heroTag: 'ai_btn',
                backgroundColor: const Color(0xFF60EFFF),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AiSuggestScreen()));
                },
                child: const Icon(Icons.auto_awesome, color: Colors.black),
              ),
              const SizedBox(height: 16),
              FloatingActionButton(
                heroTag: 'add_btn',
                backgroundColor: const Color(0xFF00FF87),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTaskScreen()));
                },
                child: const Icon(Icons.add, color: Colors.black, size: 30),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
