import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'auth_screen.dart';
import 'admin_dashboard.dart';

class WalkthroughScreen extends StatefulWidget {
  final VoidCallback toggleTheme;

  const WalkthroughScreen({super.key, required this.toggleTheme});

  @override
  State<WalkthroughScreen> createState() => _WalkthroughScreenState();
}

class _WalkthroughScreenState extends State<WalkthroughScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  // Admin credentials
  final String _adminUsername = 'admin';
  final String _adminPassword = 'admin123';

  final List<Map<String, String>> walkthroughItems = [
    {
      "title": "Log and Track Symptoms",
      "description": "Easily record daily symptoms to monitor your arthritis journey with detailed tracking and history.",
      "animation": "assets/animations/log_animation.json",
    },
    {
      "title": "Personalized Recommendations",
      "description": "Get smart suggestions tailored specifically to your condition, symptoms, and needs.",
      "animation": "assets/animations/recomm.json",
    },
    {
      "title": "RA, SpA, OA Friendly",
      "description": "Comprehensive support designed for people with Rheumatoid Arthritis, Spondyloarthritis, or Osteoarthritis.",
      "animation": "assets/animations/friendly_support.json",
    },
  ];

  void _showAdminLoginDialog() {
    final TextEditingController usernameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Admin Login', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                prefixIcon: const Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                prefixIcon: const Icon(Icons.lock),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.deepPurple)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              if (usernameController.text == _adminUsername &&
                  passwordController.text == _adminPassword) {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminDashboard(
                      toggleTheme: widget.toggleTheme,
                      onLogout: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invalid credentials'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Login', style: TextStyle(color: Colors.white)),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flexi Flow', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings, size: 28),
            onPressed: _showAdminLoginDialog,
            tooltip: 'Admin Login',
          ),
          IconButton(
            icon: const Icon(Icons.brightness_6, size: 28),
            onPressed: widget.toggleTheme,
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
      body: SizedBox(
        height: screenHeight,
        width: screenWidth,
        child: Column(
          children: [
            // Animation takes 50% of screen height
            SizedBox(
              height: screenHeight * 0.5,
              child: PageView.builder(
                controller: _pageController,
                itemCount: walkthroughItems.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemBuilder: (context, index) {
                  final item = walkthroughItems[index];
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Lottie.asset(
                        item["animation"]!,
                        height: screenHeight * 0.4, // 40% of screen height
                        width: screenWidth * 0.9,   // 90% of screen width
                        fit: BoxFit.contain,
                      ),
                    ],
                  );
                },
              ),
            ),

            // Content area takes remaining space
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: walkthroughItems.length,
                itemBuilder: (context, index) {
                  final item = walkthroughItems[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          item["title"]!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          item["description"]!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Page indicator and button
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    walkthroughItems.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 6.0),
                      width: _currentIndex == index ? 24.0 : 10.0,
                      height: 10.0,
                      decoration: BoxDecoration(
                        color: _currentIndex == index ? Colors.deepPurple : Colors.grey,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.only(bottom: 40.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      minimumSize: Size(screenWidth * 0.1, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    onPressed: () {
                      if (_currentIndex == walkthroughItems.length - 1) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AuthScreen(toggleTheme: widget.toggleTheme),
                          ),
                        );
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Text(
                      _currentIndex == walkthroughItems.length - 1 ? "Get Started" : "Next",
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}