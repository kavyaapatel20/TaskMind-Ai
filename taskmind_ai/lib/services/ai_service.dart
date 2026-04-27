import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  final String _apiKey = 'YOUR_OPENAI_API_KEY_HERE'; // Replace with valid API key
  final String _endpoint = 'https://api.openai.com/v1/chat/completions';

  Future<String> suggestTasks(String goal) async {
    return await _mockOrRealApi(
        "Suggest 3 simple task steps to achieve this goal: $goal");
  }

  Future<List<String>> breakDownTask(String taskTitle) async {
    String response = await _mockOrRealApi(
        "Break down this task into 3 subtasks separated by a bar (|): $taskTitle");
    return response.split('|').map((e) => e.trim()).toList();
  }

  Future<String> suggestPriority(String taskTitle) async {
    String response = await _mockOrRealApi(
        "What should be the priority (Low, Medium, High) for this task? Reply with just the word: $taskTitle");
    if (response.toLowerCase().contains("high")) return "High";
    if (response.toLowerCase().contains("medium")) return "Medium";
    return "Low";
  }

  Future<String> dailySummary(List<String> completed, List<String> pending) async {
    return await _mockOrRealApi(
        "Give a short 2-sentence encouraging daily summary. Completed: ${completed.join(",")}. Pending: ${pending.join(",")}");
  }

  Future<String> _mockOrRealApi(String prompt) async {
    if (_apiKey == 'YOUR_OPENAI_API_KEY_HERE') {
      await Future.delayed(const Duration(seconds: 1));
      if (prompt.contains("Suggest 3 simple task steps")) {
        return "- Step 1: Initialize the project\n- Step 2: Build the core features\n- Step 3: Test and deploy";
      } else if (prompt.contains("Break down this task")) {
        // We use the prompt text to provide a somewhat contextual breakdown
        String context = "Draft the initial outline | Review the core concepts | Complete final execution";
        if (prompt.toLowerCase().contains("code") || prompt.toLowerCase().contains("app")) {
           context = "Define architecture | Write business logic | Perform unit testing";
        } else if (prompt.toLowerCase().contains("study") || prompt.toLowerCase().contains("read")) {
           context = "Highlight key terms | Summarize chapters | Take a practice quiz";
        }
        return context;
      } else if (prompt.contains("priority")) {
        return "Medium";
      } else if (prompt.contains("daily summary")) {
        return "You made excellent progress today! Keep that momentum going strong.";
      }
      return "Mock AI response";
    }

    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].toString().trim();
      } else {
        return "Failed to fetch AI suggestion.";
      }
    } catch (e) {
      return "Error connecting to AI service.";
    }
  }
}
