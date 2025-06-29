import 'dart:convert';
import 'package:http/http.dart' as http;
import 'constants.dart';

class ApiService {
  final String baseUrl = ApiConstants.baseUrl;

  Future<Map<String, dynamic>> getAnalytics() async {
    final response = await http.get(
      Uri.parse('$baseUrl${ApiConstants.analyticsEndpoint}'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load analytics');
    }
  }

  Future<void> recordDownload() async {
    final response = await http.post(
      Uri.parse('$baseUrl${ApiConstants.recordDownloadEndpoint}'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to record download');
    }
  }

  Future<void> submitRating(int rating) async {
    final response = await http.post(
      Uri.parse('$baseUrl${ApiConstants.submitRatingEndpoint}'),
      body: {'rating': rating.toString()},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to submit rating');
    }
  }

  Future<void> submitComment(String username, String text) async {
    final response = await http.post(
      Uri.parse('$baseUrl${ApiConstants.submitCommentEndpoint}'),
      body: {'username': username, 'text': text},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to submit comment');
    }
  }
}