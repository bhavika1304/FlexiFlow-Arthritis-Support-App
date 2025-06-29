// ExerciseGuidePage.dart (inside the Exercises tab)

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flexi_flow/data/exercise_data.dart'; // ✅ Correct import

class ExerciseGuidePage extends StatelessWidget {
  const ExerciseGuidePage({super.key});

  void _launchVideo(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: exerciseData.length,
      itemBuilder: (context, index) {
        final exercise = exerciseData[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 4,
          child: ListTile(
            title: Text(
              exercise["name"] ?? "",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(exercise["instructions"] ?? ""),
            trailing: IconButton(
              icon: const Icon(Icons.play_circle_fill, color: Colors.deepPurple),
              onPressed: () {
                _launchVideo(exercise["video_url"] ?? "");
              },
            ),
          ),
        );
      },
    );
  }
}
