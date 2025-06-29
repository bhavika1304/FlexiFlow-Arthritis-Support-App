import 'package:flutter/material.dart';
import 'api_service.dart';

class FeedbackWidget extends StatefulWidget {
  final String username;

  FeedbackWidget({required this.username});

  @override
  _FeedbackWidgetState createState() => _FeedbackWidgetState();
}

class _FeedbackWidgetState extends State<FeedbackWidget> {
  final ApiService _apiService = ApiService();
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Rate our app:', style: TextStyle(fontSize: 16)),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return IconButton(
              icon: Icon(
                index < _rating ? Icons.star : Icons.star_border,
                size: 30,
                color: Colors.amber,
              ),
              onPressed: () => setState(() => _rating = index + 1),
            );
          }),
        ),
        SizedBox(height: 16),
        TextField(
          controller: _commentController,
          decoration: InputDecoration(
            labelText: 'Leave a comment (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        SizedBox(height: 16),
        Center(
          child: _isSubmitting
              ? CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _submitFeedback,
                  child: Text('Submit Feedback'),
                ),
        ),
      ],
    );
  }

  Future<void> _submitFeedback() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _apiService.submitRating(_rating);
      
      if (_commentController.text.isNotEmpty) {
        await _apiService.submitComment(widget.username, _commentController.text);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Thank you for your feedback!')),
      );
      
      setState(() {
        _rating = 0;
        _commentController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit feedback: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}