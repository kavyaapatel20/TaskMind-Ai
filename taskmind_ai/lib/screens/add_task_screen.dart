import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../services/db_service.dart';
import '../services/auth_service.dart';
import '../services/ai_service.dart';

class AddTaskScreen extends StatefulWidget {
  final TaskModel? task;
  const AddTaskScreen({super.key, this.task});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime _dueDate = DateTime.now();
  String _priority = 'Low';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _titleCtrl.text = widget.task!.title;
      _descCtrl.text = widget.task!.description;
      _dueDate = widget.task!.dueDate;
      _priority = widget.task!.priority;
    }
  }

  void _saveTask() async {
    if (_titleCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title is required')));
      return;
    }
    setState(() => _isLoading = true);
    
    final user = AuthService().currentUser;
    if (user == null) return;

    final taskId = widget.task?.id ?? FirebaseFirestore.instance.collection('tasks').doc().id;

    final task = TaskModel(
      id: taskId,
      userId: user.uid,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      dueDate: _dueDate,
      priority: _priority,
      isCompleted: widget.task?.isCompleted ?? false,
    );

    try {
      if (widget.task == null) {
        await DbService().addTask(task);
      } else {
        await DbService().updateTask(task);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save task: Database rules might be blocking saving!')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _suggestPriority() async {
    if (_titleCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Type a title first')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final p = await AiService().suggestPriority(_titleCtrl.text);
      if (['Low', 'Medium', 'High'].contains(p)) {
        setState(() => _priority = p);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI Priority set!')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _breakDownTask() async {
    if (_titleCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Type a title first')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final subtasks = await AiService().breakDownTask(_titleCtrl.text);
      if (subtasks.isNotEmpty) {
        String newDesc = "AI Recommended Breakdown:\n\n";
        for (int i = 0; i < subtasks.length; i++) {
          newDesc += "✅ Step ${i+1}: ${subtasks[i].trim()}\n";
        }
        setState(() => _descCtrl.text = newDesc);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task broken down successfully!')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade900,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: const BackButton(color: Color(0xFF60EFFF)),
        title: Text(widget.task == null ? 'Create Task' : 'Edit Task', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 50, spreadRadius: 10)]),
          child: ClipRRect(
            child: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Task Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _titleCtrl,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Task Title',
                      filled: true,
                      fillColor: Colors.grey.withOpacity(0.1),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descCtrl,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: 'Description or Subtasks',
                      alignLabelWithHint: true,
                      filled: true,
                      fillColor: Colors.grey.withOpacity(0.1),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // AI Action Row
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF60EFFF).withOpacity(0.2), foregroundColor: const Color(0xFF60EFFF), elevation: 0),
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Priority'),
                    onPressed: _isLoading ? null : _suggestPriority,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FF87).withOpacity(0.2), foregroundColor: const Color(0xFF00FF87), elevation: 0),
                    icon: const Icon(Icons.list_alt),
                    label: const Text('Breakdown'),
                    onPressed: _isLoading ? null : _breakDownTask,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Configuration
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Due Date', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${_dueDate.day}/${_dueDate.month}/${_dueDate.year}', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 16)),
                    trailing: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), shape: BoxShape.circle),
                      child: Icon(Icons.calendar_month, color: Theme.of(context).colorScheme.primary),
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _dueDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) setState(() => _dueDate = date);
                    },
                  ),
                  const Divider(height: 30),
                  DropdownButtonFormField<String>(
                    initialValue: _priority,
                    decoration: InputDecoration(
                      labelText: 'Priority Level',
                      filled: true,
                      fillColor: Colors.grey.withOpacity(0.1),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down),
                    items: ['Low', 'Medium', 'High'].map((p) {
                      return DropdownMenuItem(value: p, child: Text(p, style: TextStyle(fontWeight: FontWeight.bold, color: p == 'High' ? Colors.redAccent : null)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _priority = val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _saveTask,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Save Task', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
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
