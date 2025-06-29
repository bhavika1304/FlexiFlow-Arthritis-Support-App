import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> 
    with TickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _rotateController;
  late ConfettiController _confettiController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _showGlow = false;
  Timer? _glowTimer;
  Map<String, dynamic> _streakData = {
    'currentStreak': 0,
    'longestStreak': 0,
    'totalCheckins': 0,
  };

  @override
  void initState() {
    super.initState();
    
    // Initialize all animation controllers
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeInOut,
      ),
    );
    
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    
    // Load streak data
    _loadStreakData();
    
    // Setup periodic glow effect
    _setupGlowEffect();
  }

  Future<void> _loadStreakData() async {
    if (user == null) return;
    
    final doc = await FirebaseFirestore.instance
        .collection('streaks')
        .doc(user!.uid)
        .get();
        
    if (doc.exists) {
      setState(() {
        _streakData = {
          'currentStreak': doc['currentStreak'] ?? 0,
          'longestStreak': doc['longestStreak'] ?? 0,
          'totalCheckins': doc['totalCheckins'] ?? 0,
        };
      });
    }
  }

  void _setupGlowEffect() {
    _glowTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() => _showGlow = true);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _showGlow = false);
        });
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotateController.dispose();
    _confettiController.dispose();
    _audioPlayer.dispose();
    _glowTimer?.cancel();
    super.dispose();
  }

  String _getBadgeAnimation(String badgeName) {
    switch (badgeName) {
      case 'firststep':
        return 'assets/animations/firststep.json';
      case '1week':
        return 'assets/animations/1week.json';
      case 'hero':
        return 'assets/animations/hero.json';
      case 'monthly':
        return 'assets/animations/monthly.json';
      default:
        return 'assets/animations/firststep.json';
    }
  }

  String _getBadgeTitle(String badgeName) {
    switch (badgeName) {
      case 'firststep':
        return 'BEGINNER';
      case '1week':
        return 'WEEKLY STREAK';
      case 'hero':
        return 'WEEKEND HERO';
      case 'monthly':
        return 'MONTHLY MASTER';
      default:
        return 'ACHIEVER';
    }
  }

  Color _getBadgeColor(String badgeName) {
    switch (badgeName) {
      case 'firststep':
        return Colors.blue;
      case '1week':
        return Colors.green;
      case 'hero':
        return Colors.orange;
      case 'monthly':
        return Colors.purple;
      default:
        return Colors.deepPurple;
    }
  }

  Widget _buildStreakSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 100.0, left: 20, right: 20),
      child: Card(
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: Colors.deepPurple.withOpacity(0.7),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Text(
                'YOUR STREAKS',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.8),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStreakStat('Current', _streakData['currentStreak']),
                  _buildStreakStat('Longest', _streakData['longestStreak']),
                  _buildStreakStat('Total', _streakData['totalCheckins']),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreakStat(String label, int value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeCard(String badgeName, DateTime dateEarned) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Card(
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: _getBadgeColor(badgeName).withOpacity(0.2),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                decoration: _showGlow
                    ? BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _getBadgeColor(badgeName).withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      )
                    : null,
                child: Lottie.asset(
                  _getBadgeAnimation(badgeName),
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                ),
              ),
              Text(
                _getBadgeTitle(badgeName),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getBadgeColor(badgeName),
                ),
              ),
              Text(
                'Earned: ${dateEarned.day}/${dateEarned.month}/${dateEarned.year}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/keepgoing.json',
            width: 200,
            height: 200,
          ),
          const SizedBox(height: 20),
          Text(
            'No achievements yet!',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Keep working to earn your first badge',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("YOUR TROPHY CASE"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.deepPurple.shade800,
                Colors.purple.shade600,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              Colors.deepPurple.shade900,
              Colors.black,
            ],
            stops: const [0.1, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Background elements
            Positioned(
              top: -50,
              right: -50,
              child: RotationTransition(
                turns: _rotateController,
                child: Opacity(
                  opacity: 0.1,
                  child: Icon(
                    Icons.star,
                    size: 300,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
            ),
            
            // Confetti layer
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: true,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple,
                  Colors.yellow,
                ],
                numberOfParticles: 30,
                maxBlastForce: 25,
                minBlastForce: 15,
                emissionFrequency: 0.05,
              ),
            ),

            // Content
            Column(
              children: [
                // Streak display section
                _buildStreakSection(),
                
                // Badges display section
               Expanded(
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('userBadges')
                        .doc(user?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      // Add error handling
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      // Handle loading state
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      // Handle case where document doesn't exist
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return _buildEmptyState();
                      }

                      final data = snapshot.data!.data() as Map<String, dynamic>;
                      
                      // Debug print to check what's being received
                      debugPrint('Firestore data: $data');

                      // More robust data handling
                      final badgeNames = data['badge_name'] is List 
                          ? List<String>.from(data['badge_name'] ?? [])
                          : [];
                          
                      final datesEarned = data['date_earned'] is List
                          ? List<Timestamp>.from(data['date_earned']?.map((d) => 
                              d is Timestamp ? d : Timestamp.now()) ?? [])
                          : [];

                      // Debug print to check parsed data
                      debugPrint('Badges count: ${badgeNames.length}');
                      debugPrint('Dates count: ${datesEarned.length}');

                      if (badgeNames.isEmpty) {
                        return _buildEmptyState();
                      }

                      // Create pairs ensuring we don't get index errors
                      final badgesWithDates = <Map<String, dynamic>>[];
                      for (int i = 0; i < badgeNames.length; i++) {
                        badgesWithDates.add({
                          'name': badgeNames[i],
                          'date': i < datesEarned.length 
                              ? datesEarned[i].toDate() 
                              : DateTime.now(),
                        });
                      }

                      return Padding(
                        padding: const EdgeInsets.only(top: 20.0),
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                            childAspectRatio: 0.8,
                          ),
                          itemCount: badgesWithDates.length,
                          itemBuilder: (context, index) {
                            final badge = badgesWithDates[index];
                            return _buildBadgeCard(badge['name'], badge['date']);
                          },
                        ),
                      );
                    },
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