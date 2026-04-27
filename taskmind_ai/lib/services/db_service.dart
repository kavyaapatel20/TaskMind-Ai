import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';

class DbService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addTask(TaskModel task) async {
    await _db.collection('tasks').doc(task.id).set(task.toMap());
  }

  Future<void> updateTask(TaskModel task) async {
    await _db.collection('tasks').doc(task.id).update(task.toMap());
  }

  Future<void> deleteTask(String id) async {
    await _db.collection('tasks').doc(id).delete();
  }

  Stream<List<TaskModel>> getTasks(String userId) {
    return _db
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final tasks = snapshot.docs
              .map((doc) => TaskModel.fromMap(doc.id, doc.data()))
              .toList();
          tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
          return tasks;
        });
  }
}
