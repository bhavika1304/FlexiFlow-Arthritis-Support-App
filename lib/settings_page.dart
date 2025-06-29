// lib/pages/settings_page.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ Needed for Firestore
import 'package:shared_preferences/shared_preferences.dart';
import '../auth_screen.dart';
import '../constants.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

class SettingsPage extends StatefulWidget {
  final VoidCallback toggleTheme;

  const SettingsPage({super.key, required this.toggleTheme});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notificationsEnabled = true;
  bool darkModeEnabled = false;
  String? username; // ✅ now username instead of userId
  bool isResetting = false;

  @override
  void initState() {
    super.initState();
    initializeNotifications();
    fetchUserProfile(); // 🔥
  }

  Future<void> initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> fetchUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          username = doc.data()?['username'] ?? 'Unknown User';
        });
      } else {
        setState(() {
          username = 'Unknown User';
        });
      }
    }
  }

  Future<void> resetProgress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      isResetting = true;
    });

    try {
      final userId = user.uid;
      final painUrl = Uri.parse('${ApiConstants.baseUrl}/reset_pain_logs?user_id=$userId');
      await http.delete(painUrl);

      final dietUrl = Uri.parse('${ApiConstants.baseUrl}/reset_diet_logs?user_id=$userId');
      await http.delete(dietUrl);

      final medUrl = Uri.parse('${ApiConstants.baseUrl}/reset_medicine_logs?user_id=$userId');
      await http.delete(medUrl);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Progress reset successfully!")),
      );
    } catch (e) {
      print("Error resetting progress: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to reset progress.")),
      );
    } finally {
      setState(() {
        isResetting = false;
      });
    }
  }

  Future<void> contactUs() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@flexiflow.com',
      query: 'subject=Support Request&body=Hi FlexiFlow Team,',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open email app.')),
      );
    }
  }

  Future<void> logout() async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('stayLoggedIn');
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => AuthScreen(toggleTheme: widget.toggleTheme)),
          (route) => false,
        );
      } catch (e) {
        print("Error during logout: $e");
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logout failed. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.deepPurple,
      ),
      body: username == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  "Profile",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text("Username"),
                    subtitle: Text(username ?? "-"), // ✅ show username here
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  "App Settings",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text("Enable Notifications"),
                  value: notificationsEnabled,
                  activeColor: Colors.deepPurple,
                  onChanged: (value) {
                    setState(() {
                      notificationsEnabled = value;
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text("Dark Mode"),
                  value: darkModeEnabled,
                  activeColor: Colors.deepPurple,
                  onChanged: (value) {
                    setState(() {
                      darkModeEnabled = value;
                    });
                    widget.toggleTheme();
                  },
                ),

                const SizedBox(height: 20),

                const Text(
                  "Account Actions",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.restart_alt),
                  title: const Text("Reset Progress"),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Confirm Reset"),
                        content: const Text("Are you sure you want to reset all your logs? This cannot be undone."),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              resetProgress();
                            },
                            child: const Text("Reset", style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text("Logout"),
                  onTap: logout,
                ),

                const SizedBox(height: 20),

                const Text(
                  "Help & Support",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text("App Instructions"),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("How to Use FlexiFlow"),
                        content: const Text(
                          "➔ Log your daily pain, diet, and medicines.\n"
                          "➔ Explore recommended exercises.\n"
                          "➔ View your progress weekly/monthly.\n"
                          "➔ Connect with others in the community!",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Close"),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text("Contact Us"),
                  subtitle: const Text("support@flexiflow.com"),
                  onTap: contactUs,
                ),

                const SizedBox(height: 20),

                const Text(
                  "About",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text("About FlexiFlow"),
                  subtitle: const Text("FlexiFlow helps arthritis patients stay active, track pain, and live better lives."),
                ),
                ListTile(
                  leading: const Icon(Icons.verified_user),
                  title: const Text("App Version"),
                  subtitle: const Text("v1.0.0"),
                ),
              ],
            ),
    );
  }
}
