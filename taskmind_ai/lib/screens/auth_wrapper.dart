import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'welcome_screen.dart';
import 'main_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _showPostAuthSplash = false;
  User? _lastUser;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().userStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F2027),
            body: Center(child: CircularProgressIndicator(color: Color(0xFF00FF87))),
          );
        }

        final currentUser = snapshot.data;

        // User just logged in
        if (currentUser != null && _lastUser == null) {
          _lastUser = currentUser;
          _showPostAuthSplash = true;
          // Hold the splash for 2.5 seconds, then transition to dashboard natively
          Timer(const Duration(milliseconds: 2500), () {
            if (mounted) setState(() => _showPostAuthSplash = false);
          });
        } 
        // User just logged out
        else if (currentUser == null) {
          _lastUser = null;
          _showPostAuthSplash = false;
        }

        if (currentUser != null) {
          if (_showPostAuthSplash) {
            return const PostAuthSplash();
          }
          return const MainScreen();
        }

        return const WelcomeScreen();
      },
    );
  }
}

class PostAuthSplash extends StatelessWidget {
  const PostAuthSplash({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final name = user?.displayName ?? user?.email?.split('@')[0] ?? '';

    return Scaffold(
      backgroundColor: Colors.blueGrey.shade900,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline, color: Color(0xFF00FF87), size: 100),
                const SizedBox(height: 24),
                Text(
                  'Welcome, ${name.toUpperCase()}!',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Preparing your dashboard...',
                  style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.7)),
                ),
                const SizedBox(height: 48),
                const CircularProgressIndicator(color: Color(0xFF60EFFF)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
