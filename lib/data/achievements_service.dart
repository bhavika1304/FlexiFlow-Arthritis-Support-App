import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AchievementsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<bool> recordDailyCheckin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    final streaksRef = _firestore.collection('streaks').doc(user.uid);

    try {
      return await _firestore.runTransaction<bool>((transaction) async {
        final streaksDoc = await transaction.get(streaksRef);

        // Initialize if doesn't exist
        if (!streaksDoc.exists) {
          transaction.set(streaksRef, {
            'username': user.uid,
            'checkinDates': [today],
            'currentStreak': 1,
            'lastCheckin': now,
            'lastUpdated': now,
            'longestStreak': 1,
            'totalCheckins': 1,
          });
          _checkForBadgeUnlocks(user.uid, 1, 1, now.weekday);
          return true;
        }

        final data = streaksDoc.data()!;
        final checkinDates = List<String>.from(data['checkinDates'] ?? []);
        
        // Check if already checked in today
        if (checkinDates.contains(today)) {
          return false;
        }

        // Calculate new streak
        final yesterday = DateFormat('yyyy-MM-dd')
            .format(now.subtract(const Duration(days: 1)));
        final isConsecutive = checkinDates.contains(yesterday);
        
        int currentStreak = data['currentStreak'] ?? 0;
        int longestStreak = data['longestStreak'] ?? 0;
        int totalCheckins = data['totalCheckins'] ?? 0;

        currentStreak = isConsecutive ? currentStreak + 1 : 1;
        if (currentStreak > longestStreak) {
          longestStreak = currentStreak;
        }

        // Update streaks document
        transaction.update(streaksRef, {
          'checkinDates': FieldValue.arrayUnion([today]),
          'currentStreak': currentStreak,
          'lastCheckin': now,
          'lastUpdated': now,
          'longestStreak': longestStreak,
          'totalCheckins': totalCheckins + 1,
        });

        // Check for badge unlocks
        await _checkForBadgeUnlocks(
          user.uid, 
          currentStreak, 
          totalCheckins + 1,
          now.weekday,
        );

        return true;
      });
    } catch (e) {
      print('Error recording daily check-in: $e');
      return false;
    }
  }

  Future<void> _checkForBadgeUnlocks(
    String uid, 
    int streak, 
    int totalCheckins,
    int weekday,
  ) async {
    final badgesRef = _firestore.collection('userBadges').doc(uid);
    final badgesDoc = await badgesRef.get();
    final currentBadges = badgesDoc.exists 
        ? List<String>.from(badgesDoc.data()?['badge_name'] ?? []) 
        : [];

    final newBadges = <String>[];
    final now = Timestamp.now();

    // First check-in badge
    if (totalCheckins == 1 && !currentBadges.contains('firststep')) {
      newBadges.add('firststep');
    }

    // 7-day streak badge
    if (streak >= 7 && !currentBadges.contains('1week')) {
      newBadges.add('1week');
    }

    // 30-day streak badge
    if (streak >= 30 && !currentBadges.contains('monthly')) {
      newBadges.add('monthly');
    }

    // Weekend hero badge (check if today is weekend)
    if ((weekday == DateTime.saturday || weekday == DateTime.sunday) && 
        !currentBadges.contains('hero')) {
      newBadges.add('hero');
    }

    if (newBadges.isNotEmpty) {
      await badgesRef.set({
        'badge_name': FieldValue.arrayUnion(newBadges),
        'date_earned': FieldValue.arrayUnion(
          List.filled(newBadges.length, now)),
      }, SetOptions(merge: true));
    }
  }

  Future<Map<String, dynamic>> getStreakData() async {
    final user = _auth.currentUser;
    if (user == null) return {};

    try {
      final doc = await _firestore
          .collection('streaks')
          .doc(user.uid)
          .get();
          
      return doc.data() ?? {
        'currentStreak': 0,
        'longestStreak': 0,
        'totalCheckins': 0,
        'checkinDates': [],
      };
    } catch (e) {
      print('Error getting streak data: $e');
      return {
        'currentStreak': 0,
        'longestStreak': 0,
        'totalCheckins': 0,
        'checkinDates': [],
      };
    }
  }

  Future<List<Map<String, dynamic>>> getUserBadges() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final doc = await _firestore
          .collection('userBadges')
          .doc(user.uid)
          .get();
          
      if (!doc.exists) return [];
      
      final badges = List<String>.from(doc.data()?['badge_name'] ?? []);
      final dates = List<Timestamp>.from(doc.data()?['date_earned'] ?? []);
      
      return List.generate(badges.length, (index) {
        return {
          'name': badges[index],
          'date': dates[index],
        };
      });
    } catch (e) {
      print('Error getting user badges: $e');
      return [];
    }
  }

  Future<int> getCurrentStreak() async {
    final data = await getStreakData();
    return data['currentStreak'] ?? 0;
  }

  Future<int> getLongestStreak() async {
    final data = await getStreakData();
    return data['longestStreak'] ?? 0;
  }

  Future<int> getTotalCheckins() async {
    final data = await getStreakData();
    return data['totalCheckins'] ?? 0;
  }
}