import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

// Import your pages
import 'log_pain_page.dart';
import 'log_health_page.dart';
import 'exercise_recommend_page.dart';
import 'view_progress_page.dart';
import 'community_page.dart';
import 'settings_page.dart';
import 'profile_page.dart';
import 'achievements_page.dart';
import 'dart:async';
import 'package:flexi_flow/about.dart';
import 'package:flexi_flow/contact.dart';

class HomePage extends StatefulWidget {
  final VoidCallback toggleTheme;

  const HomePage({super.key, required this.toggleTheme});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showMedicationNotification = false;
  List<Map<String, dynamic>> _pendingMedications = [];
  final User? _user = FirebaseAuth.instance.currentUser;
  late StreamSubscription<QuerySnapshot> _medicationSubscription;
  Timer? _medicationCheckTimer;
  bool _showFeedbackForm = false;
  double _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  String _greeting = '';
  String _motivationalQuote = '';
  String _dailyTip = '';

  final List<String> _morningGreetings = [
    'Rise and shine! 🌞',
    'Good morning! ☀️',
    'Morning glory! ',
    'Hello early bird! '
  ];

  final List<String> _afternoonGreetings = [
    'Hello there! ',
    'Good afternoon! ',
    'Hope you\'re having a great day! 😊',
    'Afternoon vibes! '
  ];

  final List<String> _eveningGreetings = [
    'Good evening! ',
    'Hello night owl! ',
    'Evening serenity! ',
    'Welcome to the evening! '
  ];

  final List<String> _motivationalQuotes = [
    'Small steps lead to big improvements!',
    'Your health journey matters!',
    'Every day is a new opportunity!',
    'You\'re stronger than you think!',
    'Progress, not perfection!',
    'Your effort today is tomorrow\'s strength!'
  ];

  final List<String> _dailyTips = [
    'Did you know? Gentle stretching can improve joint flexibility.',
    'Tip: Stay hydrated to help reduce joint stiffness.',
    'Remember: Listen to your body and pace yourself.',
    'Pro tip: Short, frequent movement breaks are better than long sessions.',
    'Fact: Consistent tracking helps identify patterns in your symptoms.'
  ];

  @override
  void initState() {
    super.initState();
    _updateGreeting();
    _updateMotivationalQuote();
    _updateDailyTip();
    if (_user != null) {
      _setupMedicationReminders();
      _checkPendingMedications();
      _medicationCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
        _checkPendingMedications();
      });
    }
    
    // Update greeting every minute to handle day transitions
    Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateGreeting();
    });

    // Rotate motivational quote every 5 minutes
    Timer.periodic(const Duration(minutes: 5), (timer) {
      _updateMotivationalQuote();
    });

    // Change daily tip every hour
    Timer.periodic(const Duration(hours: 1), (timer) {
      _updateDailyTip();
    });
  }

  void _updateGreeting() {
    final hour = DateTime.now().hour;
    setState(() {
      if (hour < 12) {
        _greeting = _morningGreetings[DateTime.now().second % _morningGreetings.length];
      } else if (hour < 17) {
        _greeting = _afternoonGreetings[DateTime.now().second % _afternoonGreetings.length];
      } else {
        _greeting = _eveningGreetings[DateTime.now().second % _eveningGreetings.length];
      }
    });
  }

  void _updateMotivationalQuote() {
    setState(() {
      _motivationalQuote = _motivationalQuotes[DateTime.now().minute % _motivationalQuotes.length];
    });
  }

  void _updateDailyTip() {
    setState(() {
      _dailyTip = _dailyTips[DateTime.now().hour % _dailyTips.length];
    });
  }

  @override
  void dispose() {
    _medicationSubscription.cancel();
    _medicationCheckTimer?.cancel();
    _feedbackController.dispose();
    super.dispose();
  }

  void _setupMedicationReminders() {
    _medicationSubscription = FirebaseFirestore.instance
        .collection('addmeds')
        .where('user_id', isEqualTo: _user!.uid)
        .snapshots()
        .listen((snapshot) {
      _checkPendingMedications();
    });
  }

  Future<void> _checkPendingMedications() async {
    final now = DateTime.now();
    final currentTime = DateFormat('HH:mm').format(now);
    final todayDate = DateFormat('yyyy-MM-dd').format(now);
    final yesterdayDate = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));

    try {
      final medicationsSnapshot = await FirebaseFirestore.instance
          .collection('addmeds')
          .where('user_id', isEqualTo: _user!.uid)
          .get();

      List<Map<String, dynamic>> pendingMeds = [];

      for (var doc in medicationsSnapshot.docs) {
        final medData = doc.data();
        final medName = medData['Medicine Name'] ?? 'Unknown';
        final medTime = medData['Time'] ?? '00:00';
        final status = medData['status'] ?? 'pending';
        final lastTakenDate = medData['last_taken_date'] ?? '';

        if (status == 'taken' && lastTakenDate == todayDate) continue;

        final formattedMedTime = medTime.length == 4 ? '0$medTime' : medTime;
        final timeDifference = _getTimeDifferenceInMinutes(formattedMedTime, currentTime);

        if (_isOvernightMedication(formattedMedTime, currentTime)) {
          if (lastTakenDate != yesterdayDate) {
            pendingMeds.add({
              'id': doc.id,
              'name': medName,
              'dose': medData['Dose'] ?? '',
              'time': medTime,
              'status': 'missed',
              'timeDifference': timeDifference,
            });
          }
        }
        else if (timeDifference <= 0) {
          pendingMeds.add({
            'id': doc.id,
            'name': medName,
            'dose': medData['Dose'] ?? '',
            'time': medTime,
            'status': timeDifference == 0 ? 'due' : 'overdue',
            'timeDifference': timeDifference,
          });
        }
        else if (timeDifference <= 60) {
          pendingMeds.add({
            'id': doc.id,
            'name': medName,
            'dose': medData['Dose'] ?? '',
            'time': medTime,
            'status': 'upcoming',
            'timeDifference': timeDifference,
          });
        }
      }

      pendingMeds.sort((a, b) {
        const statusOrder = {'overdue': 0, 'due': 1, 'missed': 2, 'upcoming': 3};
        return statusOrder[a['status']]!.compareTo(statusOrder[b['status']]!);
      });

      if (mounted) {
        setState(() {
          _pendingMedications = pendingMeds;
          _showMedicationNotification = pendingMeds.isNotEmpty;
        });
      }
    } catch (e) {
      print("Error checking pending medications: $e");
    }
  }

  int _getTimeDifferenceInMinutes(String medTime, String currentTime) {
    try {
      final medParts = medTime.split(':');
      final currentParts = currentTime.split(':');
      final medHour = int.parse(medParts[0]);
      final medMinute = int.parse(medParts[1]);
      final currentHour = int.parse(currentParts[0]);
      final currentMinute = int.parse(currentParts[1]);
      final medTotal = medHour * 60 + medMinute;
      final currentTotal = currentHour * 60 + currentMinute;
      return medTotal - currentTotal;
    } catch (e) {
      print("Error calculating time difference: $e");
      return 0;
    }
  }

  bool _isOvernightMedication(String medTime, String currentTime) {
    try {
      final medParts = medTime.split(':');
      final currentParts = currentTime.split(':');
      final medHour = int.parse(medParts[0]);
      final currentHour = int.parse(currentParts[0]);
      return medHour >= 20 && currentHour <= 4;
    } catch (e) {
      print("Error checking overnight medication: $e");
      return false;
    }
  }

  Future<void> _markAsTaken(String documentId, String status) async {
    final now = DateTime.now();
    final todayDate = DateFormat('yyyy-MM-dd').format(now);
    final nowTime = DateFormat('HH:mm').format(now);
    final yesterdayDate = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));

    try {
      final dateToUse = status == 'missed' ? yesterdayDate : todayDate;

      await FirebaseFirestore.instance
          .collection('addmeds')
          .doc(documentId)
          .update({
            'status': 'taken',
            'last_taken_date': dateToUse,
            'last_taken_time': nowTime,
            'timestamp': FieldValue.serverTimestamp(),
          });

      final medDoc = await FirebaseFirestore.instance
          .collection('addmeds')
          .doc(documentId)
          .get();
          
      if (medDoc.exists) {
        final medData = medDoc.data()!;
        await FirebaseFirestore.instance
            .collection('Medicine_Logs')
            .doc('${_user!.uid}_${medData['Medicine Name']}_$dateToUse')
            .set({
              'user_id': _user!.uid,
              'medicine_name': medData['Medicine Name'],
              'dose': medData['Dose'],
              'time': medData['Time'],
              'status': 'taken',
              'date': dateToUse,
              'timestamp': FieldValue.serverTimestamp(),
              'marked_at': nowTime,
            });
      }

      _checkPendingMedications();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medication marked as taken')),
        );
      }
    } catch (e) {
      print("Error marking medication as taken: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to mark medication: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _submitFeedback() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a rating')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('feedback').add({
        'userId': _user?.uid,
        'userEmail': _user?.email,
        'rating': _rating,
        'comment': _feedbackController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your feedback!')),
        );
        setState(() {
          _showFeedbackForm = false;
          _rating = 0;
          _feedbackController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit feedback: $e')),
        );
      }
    }
  }

  Widget _buildFeedbackFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        border: Border(top: BorderSide(color: Colors.deepPurple.shade100, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_showFeedbackForm)
            Row(
              children: [
                Icon(Icons.feedback_outlined, color: Colors.deepPurple, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Help us improve FlexiFlow!',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.deepPurple,
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => setState(() => _showFeedbackForm = true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(
                    'Share Feedback',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          if (_showFeedbackForm) ...[
            Row(
              children: [
                Text(
                  'We value your feedback',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.deepPurple,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => setState(() {
                    _showFeedbackForm = false;
                    _rating = 0;
                    _feedbackController.clear();
                  }),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () {
                      setState(() {
                        _rating = index + 1.0;
                      });
                    },
                  );
                }),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _feedbackController,
              decoration: InputDecoration(
                hintText: 'Tell us how we can improve (optional)...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.deepPurple.shade200),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submitFeedback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Submit Feedback',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMedicationNotification() {
    return FadeInUp(
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _getNotificationColor(),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _getNotificationBorderColor()),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.medical_services, color: _getNotificationIconColor()),
                  const SizedBox(width: 2),
                  Text(
                    _getNotificationTitle(),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: _getNotificationTitleColor(),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => setState(() => _showMedicationNotification = false),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._pendingMedications.map((med) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${med['name']} (${med['dose']})',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _markAsTaken(med['id'], med['status']),
                          child: Text(
                            'Mark as Taken',
                            style: GoogleFonts.poppins(
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _getStatusText(med['status'], med['time'], med['timeDifference']),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Color _getNotificationColor() {
    if (_pendingMedications.any((med) => med['status'] == 'overdue')) {
      return Colors.red[100]!;
    } else if (_pendingMedications.any((med) => med['status'] == 'due')) {
      return Colors.orange[100]!;
    } else if (_pendingMedications.any((med) => med['status'] == 'missed')) {
      return Colors.pink[100]!;
    }
    return Colors.yellow[100]!;
  }

  Color _getNotificationBorderColor() {
    if (_pendingMedications.any((med) => med['status'] == 'overdue')) {
      return Colors.red;
    } else if (_pendingMedications.any((med) => med['status'] == 'due')) {
      return Colors.orange;
    } else if (_pendingMedications.any((med) => med['status'] == 'missed')) {
      return Colors.pink;
    }
    return Colors.amber;
  }

  Color _getNotificationIconColor() {
    if (_pendingMedications.any((med) => med['status'] == 'overdue')) {
      return Colors.red;
    } else if (_pendingMedications.any((med) => med['status'] == 'due')) {
      return Colors.orange;
    } else if (_pendingMedications.any((med) => med['status'] == 'missed')) {
      return Colors.pink;
    }
    return Colors.amber;
  }

  Color _getNotificationTitleColor() {
    if (_pendingMedications.any((med) => med['status'] == 'overdue')) {
      return Colors.red[900]!;
    } else if (_pendingMedications.any((med) => med['status'] == 'due')) {
      return Colors.orange[900]!;
    } else if (_pendingMedications.any((med) => med['status'] == 'missed')) {
      return Colors.pink[900]!;
    }
    return Colors.amber[900]!;
  }

  String _getNotificationTitle() {
    if (_pendingMedications.any((med) => med['status'] == 'overdue')) {
      return 'Overdue Medication!';
    } else if (_pendingMedications.any((med) => med['status'] == 'due')) {
      return 'Medication Due Now!';
    } else if (_pendingMedications.any((med) => med['status'] == 'missed')) {
      return 'Missed Medication!';
    }
    return 'Upcoming Medication';
  }

  String _getStatusText(String status, String time, int timeDifference) {
    switch (status) {
      case 'overdue':
        return 'Overdue by ${-timeDifference} minutes (${time})';
      case 'due':
        return 'Due now at $time';
      case 'missed':
        return 'Missed yesterday at $time';
      case 'upcoming':
        return 'Coming up in $timeDifference minutes (${time})';
      default:
        return 'Due at $time';
    }
  }

  Widget _buildTopNavButton(BuildContext context, String title) {
    return TextButton(
      onPressed: () {
        if (title == 'About') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AboutPage()),
          );
        } else if (title == 'Contact') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ContactPage()),
          );
        }
      },
      child: Text(
        title,
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
      ),
    );
  }

  Widget _buildSettingsNavButton(BuildContext context) {
    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SettingsPage(toggleTheme: widget.toggleTheme)),
        );
      },
      child: Text(
        'Settings',
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
      ),
    );
  }

  Widget _buildHomeOption(String animation, String label, Color color, Widget page) {
    return FadeInUp(
      delay: const Duration(milliseconds: 200),
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(20),
        color: color,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _navigate(context, page),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Lottie.asset(
                    animation,
                    fit: BoxFit.contain,
                    height: 10,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigate(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade400,
        title: Row(
          children: [
            const Icon(Icons.health_and_safety, color: Colors.white),
            const SizedBox(width: 3),
            Text('FlexiFlow', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            const Spacer(),
            _buildTopNavButton(context, 'About'),
            _buildTopNavButton(context, 'Contact'),
            _buildSettingsNavButton(context),
            const SizedBox(width: 3),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage(toggleTheme: widget.toggleTheme)),
              ),
              child: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.account_circle, color: Colors.deepPurple),
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple.shade50, Colors.deepPurple.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeInDown(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _greeting,
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _motivationalQuote,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.deepPurpleAccent,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.lightbulb_outline, color: Colors.amber),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _dailyTip,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        FadeInDown(
                          delay: const Duration(milliseconds: 100),
                          child: Text(
                            'Ready to take charge of your health?',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Expanded(
                          child: GridView.count(
                            crossAxisCount: 2,
                            mainAxisSpacing: 50,
                            crossAxisSpacing: 50,
                            childAspectRatio: 2,
                            padding: const EdgeInsets.all(8),
                            children: [
                              _buildHomeOption(
                                'assets/animations/logpain.json',
                                'Log Pain',
                                Colors.redAccent.withOpacity(0.2),
                                const LogPainPage(),
                              ),
                              _buildHomeOption(
                                'assets/animations/logdietmeds.json',
                                'Log Diet/Meds',
                                Colors.tealAccent.withOpacity(0.2),
                                const LogHealthPage(),
                              ),
                              _buildHomeOption(
                                'assets/animations/exercise.json',
                                'Exercises',
                                Colors.blueAccent.withOpacity(0.2),
                                const ExerciseRecommendPage(),
                              ),
                              _buildHomeOption(
                                'assets/animations/progress.json',
                                'Progress',
                                Colors.greenAccent.withOpacity(0.2),
                                const ViewProgressPage(),
                              ),
                              _buildHomeOption(
                                'assets/animations/community.json',
                                'Community',
                                Colors.orangeAccent.withOpacity(0.2),
                                const CommunityPage(),
                              ),
                              _buildHomeOption(
                                'assets/animations/acheivements.json',
                                'Achievements',
                                Colors.purpleAccent.withOpacity(0.2),
                                const AchievementsPage(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildFeedbackFooter(),
              ],
            ),
          ),
          if (_showMedicationNotification)
            Positioned(
              bottom: _showFeedbackForm ? 180 : 20,
              left: 20,
              right: 20,
              child: _buildMedicationNotification(),
            ),
        ],
      ),
    );
  }
}