import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Disabled temporarily for web support
  }

  Future<void> scheduleNotification(int id, String title, String body, DateTime scheduledTime) async {
    // Disabled temporarily for web support
  }

  Future<void> cancelNotification(int id) async {
    // Disabled temporarily for web support
  }
}
