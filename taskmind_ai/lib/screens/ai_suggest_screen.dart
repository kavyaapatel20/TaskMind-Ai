import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../services/db_service.dart';
import '../services/auth_service.dart';
import '../models/task_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AiSuggestScreen extends StatefulWidget {
  const AiSuggestScreen({super.key});

  @override
  State<AiSuggestScreen> createState() => _AiSuggestScreenState();
}

class _AiSuggestScreenState extends State<AiSuggestScreen> {
  final _goalCtrl = TextEditingController();
  bool _isLoading = false;
  List<String> _suggestedTasks = [];

  void _getSuggestions() async {
    if (_goalCtrl.text.isEmpty) return;
    setState(() {
      _isLoading = true;
      _suggestedTasks = [];
    });
    
    try {
      final suggestionsText = await AiService().suggestTasks(_goalCtrl.text);
      // AI usually returns "- step 1 \n - step 2". Let's parse it somewhat safely.
      final lines = suggestionsText.split('\n');
      final parsed = lines.where((l) => l.trim().isNotEmpty).map((l) {
        if (l.trim().startsWith('-')) return l.trim().substring(1).trim();
        if (RegExp(r'^\d+\.').hasMatch(l.trim())) return l.trim().replaceFirst(RegExp(r'^\d+\.\s*'), '').trim();
        return l;
      }).toList();
      
      setState(() => _suggestedTasks = parsed);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addSuggestedTask(String title) async {
    final user = AuthService().currentUser;
    if (user == null) return;

    final task = TaskModel(
      id: FirebaseFirestore.instance.collection('tasks').doc().id,
      userId: user.uid,
      title: title,
      description: 'Auto-suggested from goal: ${_goalCtrl.text}',
      dueDate: DateTime.now(),
      priority: 'Medium',
      isCompleted: false,
    );
    await DbService().addTask(task);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added: $title')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade900,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: const BackButton(color: Color(0xFF60EFFF)),
        title: const Text('AI Task Suggestion', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 50, spreadRadius: 10)]),
          child: ClipRRect(
            child: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _goalCtrl,
                      decoration: InputDecoration(
                        labelText: 'What is your goal?',
                        hintText: 'e.g., Prepare for job interview',
                        filled: true,
                        fillColor: Colors.grey.withOpacity(0.1),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _getSuggestions,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF60EFFF),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Suggest Tasks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    const SizedBox(height: 24),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Expanded(
                            child: ListView.builder(
                              itemCount: _suggestedTasks.length,
                              itemBuilder: (context, index) {
                                final taskTitle = _suggestedTasks[index];
                                return Card(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  child: ListTile(
                                    title: Text(taskTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    trailing: Container(
                                      decoration: BoxDecoration(color: const Color(0xFF00FF87).withOpacity(0.2), shape: BoxShape.circle),
                                      child: IconButton(
                                        icon: const Icon(Icons.add, color: Color(0xFF00FF87)),
                                        onPressed: () => _addSuggestedTask(taskTitle),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
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

