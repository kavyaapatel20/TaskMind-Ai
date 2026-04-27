import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/theme_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = AuthService().currentUser;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 32),
        Center(
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF60EFFF), width: 3),
            ),
            child: const CircleAvatar(
              radius: 60,
              backgroundColor: Colors.black12,
              child: Icon(Icons.person, size: 60, color: Color(0xFF60EFFF)),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              user?.displayName ?? user?.email?.split('@')[0].toUpperCase() ?? 'USER',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
              onPressed: () {
                final ctrl = TextEditingController(text: user?.displayName ?? '');
                showDialog(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Update Name'),
                    content: TextField(
                      controller: ctrl,
                      decoration: const InputDecoration(hintText: 'Enter your name'),
                      autofocus: true,
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () async {
                          if (ctrl.text.isNotEmpty) {
                            await user?.updateDisplayName(ctrl.text.trim());
                            // Force refresh of the UI
                            if (context.mounted) {
                              Navigator.pop(c);
                              // Simple reload
                              (context as Element).markNeedsBuild();
                            }
                          }
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          user?.email ?? 'Unknown Email',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
          ),
          child: Column(
            children: [
              ListTile(
                title: const Text('Account Status'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFF00FF87).withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                  child: const Text('PRO', style: TextStyle(color: Color(0xFF00FF87), fontWeight: FontWeight.bold)),
                ),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Dark Mode'),
                secondary: const Icon(Icons.dark_mode, color: Color(0xFF60EFFF)),
                activeThumbColor: const Color(0xFF60EFFF),
                value: themeProvider.isDarkMode,
                onChanged: (val) {
                  themeProvider.toggleTheme(val);
                },
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Log Out'),
                leading: const Icon(Icons.logout, color: Colors.blueAccent),
                textColor: Colors.blueAccent,
                onTap: () async {
                  await AuthService().signOut();
                },
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Delete Account'),
                leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                textColor: Colors.redAccent,
                onTap: () async {
                  await showDialog(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('Delete Account?'),
                      content: const Text('This is permanent and cannot be undone.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(c);
                            try {
                              await AuthService().currentUser?.delete();
                              await AuthService().signOut();
                            } catch (e) {
                              if (e.toString().contains('requires-recent-login')) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                  content: Text('Firebase Rule: You must log out and log back in right now to verify your identity before deleting.'),
                                  backgroundColor: Colors.amber,
                                  duration: Duration(seconds: 5),
                                ));
                                // Automatically sign them out so they can log in again.
                                await AuthService().signOut();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                              }
                            }
                          },
                          child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    )
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
