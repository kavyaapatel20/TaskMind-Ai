import 'dart:async';
import 'package:flutter/material.dart';

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  int _userHours = 0;
  int _userMinutes = 25;
  int _userSeconds = 0;
  
  late int _secondsRemaining;
  Timer? _timer;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _recalculateTotal();
  }

  void _recalculateTotal() {
    _secondsRemaining = (_userHours * 3600) + (_userMinutes * 60) + _userSeconds;
    if (_secondsRemaining == 0) _secondsRemaining = 1; // Prevent zero division
  }

  int get _totalSeconds => (_userHours * 3600) + (_userMinutes * 60) + _userSeconds == 0 ? 1 : (_userHours * 3600) + (_userMinutes * 60) + _userSeconds;

  void _startTimer() {
    if (_secondsRemaining <= 0) _recalculateTotal();
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _stopTimer();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Focus Session Complete! Take a break.', style: TextStyle(fontWeight: FontWeight.bold))));
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _stopTimer();
    setState(() => _recalculateTotal());
  }

  String get _formattedTime {
    final h = (_secondsRemaining ~/ 3600).toString().padLeft(2, '0');
    final m = ((_secondsRemaining % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return h == '00' ? '$m:$s' : '$h:$m:$s';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer, size: 80, color: Color(0xFF60EFFF)),
              const SizedBox(height: 16),
              const Text('Focus Mode', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (!_isRunning) Text('Customize your session time below.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 24),
              
              if (!_isRunning)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      // Hours
                      Expanded(
                        child: Column(
                          children: [
                            const Text('Hours', style: TextStyle(fontWeight: FontWeight.bold)),
                            DropdownButton<int>(
                              value: _userHours,
                              isExpanded: true,
                              items: List.generate(24, (i) => DropdownMenuItem(value: i, child: Center(child: Text('$i')))),
                              onChanged: (val) {
                                setState(() {
                                  _userHours = val ?? 0;
                                  _recalculateTotal();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Minutes
                      Expanded(
                        child: Column(
                          children: [
                            const Text('Mins', style: TextStyle(fontWeight: FontWeight.bold)),
                            DropdownButton<int>(
                              value: _userMinutes,
                              isExpanded: true,
                              items: List.generate(60, (i) => DropdownMenuItem(value: i, child: Center(child: Text('$i')))),
                              onChanged: (val) {
                                setState(() {
                                  _userMinutes = val ?? 0;
                                  _recalculateTotal();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Seconds
                      Expanded(
                        child: Column(
                          children: [
                            const Text('Secs', style: TextStyle(fontWeight: FontWeight.bold)),
                            DropdownButton<int>(
                              value: _userSeconds,
                              isExpanded: true,
                              items: List.generate(60, (i) => DropdownMenuItem(value: i, child: Center(child: Text('$i')))),
                              onChanged: (val) {
                                setState(() {
                                  _userSeconds = val ?? 0;
                                  _recalculateTotal();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              if (_isRunning) const SizedBox(height: 60), 
              
              const SizedBox(height: 32),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 250,
                    height: 250,
                    child: CircularProgressIndicator(
                      value: _secondsRemaining / _totalSeconds,
                      strokeWidth: 12,
                      backgroundColor: Colors.grey.withOpacity(0.2),
                      color: const Color(0xFF60EFFF),
                    ),
                  ),
                  Text(
                    _formattedTime,
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: 2),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FloatingActionButton.large(
                    heroTag: 'play_pause',
                    backgroundColor: _isRunning ? Colors.redAccent : const Color(0xFF00FF87),
                    onPressed: _isRunning ? _stopTimer : _startTimer,
                    child: Icon(_isRunning ? Icons.pause : Icons.play_arrow, color: Colors.black, size: 36),
                  ),
                  const SizedBox(width: 24),
                  FloatingActionButton(
                    heroTag: 'refresh',
                    backgroundColor: Theme.of(context).cardColor,
                    onPressed: _resetTimer,
                    child: Icon(Icons.refresh, color: Theme.of(context).iconTheme.color),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
