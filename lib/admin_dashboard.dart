import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AdminDashboard extends StatefulWidget {
  final VoidCallback toggleTheme;
  final VoidCallback onLogout;

  const AdminDashboard({
    super.key,
    required this.toggleTheme,
    required this.onLogout,
  });

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _feedback = [];
  List<Map<String, dynamic>> _comments = [];
  double _averageRating = 0;
  int _totalRatings = 0;
  int _totalComments = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      // Fetch feedback sorted by newest first
      final feedbackQuery = await _firestore.collection('feedback')
          .orderBy('timestamp', descending: true)
          .limit(50) // Limit to 50 most recent
          .get();

      // Fetch comments sorted by newest first
      final commentsQuery = await _firestore.collection('comments')
          .orderBy('timestamp', descending: true)
          .limit(50) // Limit to 50 most recent
          .get();

      // Calculate average rating
      double totalRating = 0;
      final feedbackList = feedbackQuery.docs.map((doc) {
        final data = doc.data();
        totalRating += (data['rating'] ?? 0).toDouble();
        return {
          ...data,
          'id': doc.id,
        };
      }).toList();

      final commentsList = commentsQuery.docs.map((doc) {
        final data = doc.data();
        return {
          ...data,
          'id': doc.id,
        };
      }).toList();

      setState(() {
        _feedback = feedbackList;
        _comments = commentsList;
        _totalRatings = feedbackList.length;
        _totalComments = commentsList.length;
        _averageRating = _totalRatings > 0 ? totalRating / _totalRatings : 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Feedback Dashboard'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: widget.onLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Overview
                  _buildStatsOverview(),
                  const SizedBox(height: 24),
                  
                  // Recent Feedback
                  Text(
                    'Recent User Feedback',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._feedback.map((feedback) => 
                    _buildFeedbackCard(feedback)
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.1, end: 0, duration: 300.ms)
                  ).toList(),
                  
                  // Recent Comments
                  const SizedBox(height: 24),
                  Text(
                    'Recent User Comments',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._comments.map((comment) => 
                    _buildCommentCard(comment)
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.1, end: 0, duration: 300.ms)
                  ).toList(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsOverview() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Average Rating', '${_averageRating.toStringAsFixed(1)}/5', Icons.star),
                _buildStatItem('Total Ratings', _totalRatings.toString(), Icons.rate_review),
                _buildStatItem('Total Comments', _totalComments.toString(), Icons.comment),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: _averageRating / 5,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getRatingColor(_averageRating),
              ),
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0, duration: 300.ms);
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Colors.deepPurple),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackCard(Map<String, dynamic> feedback) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getRatingColor(feedback['rating']),
                  child: Text(
                    feedback['rating'].toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feedback['userEmail'] ?? 'Anonymous',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatTimestamp(feedback['timestamp']),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (feedback['comment']?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                feedback['comment'],
                style: GoogleFonts.poppins(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCommentCard(Map<String, dynamic> comment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.deepPurple,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment['username'] ?? 'Anonymous',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatTimestamp(comment['timestamp']),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              comment['text'] ?? '',
              style: GoogleFonts.poppins(),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4) return Colors.green;
    if (rating >= 2.5) return Colors.amber;
    return Colors.red;
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    
    try {
      if (timestamp is Timestamp) {
        return DateFormat('MMM d, y - h:mm a').format(timestamp.toDate());
      } else if (timestamp is String) {
        return DateFormat('MMM d, y - h:mm a').format(DateTime.parse(timestamp));
      }
      return '';
    } catch (e) {
      return '';
    }
  }
}