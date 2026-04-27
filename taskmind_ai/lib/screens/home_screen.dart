import 'package:flutter/material.dart';
import '../services/db_service.dart';
import '../services/auth_service.dart';
import '../models/task_model.dart';
import '../services/ai_service.dart';
import 'add_task_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _summary = "Tap to generate your personalized AI feedback.";
  bool _isLoadingSummary = false;
  bool _hasShownNotification = false;

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    if (user == null) return const Center(child: Text("Not logged in"));

    return StreamBuilder<List<TaskModel>>(
      stream: DbService().getTasks(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 80, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  const Text('Database Locked', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    'Firebase is blocking saving/loading tasks!\n\nGo to Firebase Console -> Firestore Database -> Rules.\nChange "allow read, write: if false;" to "if true;".\nThen Publish!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Technical Details:\n${snapshot.error.toString()}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        final tasks = snapshot.data ?? [];
        final completed = tasks.where((t) => t.isCompleted).toList();
        final pending = tasks.where((t) => !t.isCompleted).toList();
        final progress = tasks.isEmpty ? 0.0 : completed.length / tasks.length;
        
        final todaysTasks = pending.where((t) {
          final now = DateTime.now();
          return t.dueDate.year == now.year && t.dueDate.month == now.month && t.dueDate.day == now.day;
        }).toList();

        final tomorrowsTasks = pending.where((t) {
          final tmrw = DateTime.now().add(const Duration(days: 1));
          return t.dueDate.year == tmrw.year && t.dueDate.month == tmrw.month && t.dueDate.day == tmrw.day;
        }).toList();

        final upcomingCount = todaysTasks.length + tomorrowsTasks.length;
        if (upcomingCount > 0 && !_hasShownNotification) {
          _hasShownNotification = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('🔔 Reminder: You have $upcomingCount task(s) due today or tomorrow!'),
                backgroundColor: const Color(0xFF60EFFF),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
                duration: const Duration(seconds: 4),
              ));
            }
          });
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // AI Summary Card
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF60EFFF), Color(0xFF00FF87)]),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: const Color(0xFF60EFFF).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome, color: Colors.black87),
                          SizedBox(width: 8),
                          Text('AI Daily Insight', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                        ],
                      ),
                      _isLoadingSummary 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black87, strokeWidth: 2))
                          : InkWell(
                              onTap: () async {
                                setState(() => _isLoadingSummary = true);
                                try {
                                  final aiSummary = await AiService().dailySummary(
                                    completed.map((e) => e.title).toList(),
                                    pending.map((e) => e.title).toList(),
                                  );
                                  setState(() => _summary = aiSummary);
                                } finally {
                                  setState(() => _isLoadingSummary = false);
                                }
                              },
                              child: const Icon(Icons.refresh, color: Colors.black54),
                            ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(_summary, style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Stats Row
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      children: [
                        const Text('Completed', style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 8),
                        Text('${completed.length}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF00FF87))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                 Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      children: [
                        const Text('Pending', style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 8),
                        Text('${pending.length}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Progress Bar
            const Text('Overall Progress', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: Colors.grey.withOpacity(0.2),
                color: const Color(0xFF60EFFF),
              ),
            ),
            const SizedBox(height: 32),
            
            // Today's Tasks
            const Text("Actionable Today", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            todaysTasks.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),
                    child: const Column(
                      children: [
                         Icon(Icons.done_all, color: Color(0xFF00FF87), size: 50),
                         SizedBox(height: 16),
                         Text('All caught up!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                         Text('You have no urgent tasks for today.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : Column(
                    children: todaysTasks.map((t) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.2), shape: BoxShape.circle),
                          child: const Icon(Icons.priority_high, color: Colors.redAccent),
                        ),
                        title: Text(t.title, style: TextStyle(fontWeight: FontWeight.bold, color: t.isExpired ? Colors.redAccent : null)),
                        subtitle: t.isExpired 
                              ? const Text('OVERDUE', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12))
                              : Text(t.priority),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                           Navigator.push(context, MaterialPageRoute(builder: (_) => AddTaskScreen(task: t)));
                        },
                      ),
                    )).toList(),
                  ),
          ],
        );
      },
    );
  }
}
