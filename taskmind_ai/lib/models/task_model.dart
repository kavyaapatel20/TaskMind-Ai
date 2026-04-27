import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  String id;
  String userId;
  String title;
  String description;
  DateTime dueDate;
  String priority; // Low, Medium, High
  bool isCompleted;

  bool get isExpired {
    if (isCompleted) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.isBefore(today);
  }

  TaskModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.priority,
    required this.isCompleted,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'dueDate': Timestamp.fromDate(dueDate),
      'priority': priority,
      'isCompleted': isCompleted,
    };
  }

  factory TaskModel.fromMap(String id, Map<String, dynamic> map) {
    return TaskModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      dueDate: map['dueDate'] != null ? (map['dueDate'] as Timestamp).toDate() : DateTime.now(),
      priority: map['priority'] ?? 'Low',
      isCompleted: map['isCompleted'] ?? false,
    );
  }
}
