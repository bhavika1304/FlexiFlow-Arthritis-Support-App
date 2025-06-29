import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SavedRecommendationsPage extends StatefulWidget {
  const SavedRecommendationsPage({super.key});

  @override
  State<SavedRecommendationsPage> createState() => _SavedRecommendationsPageState();
}

class _SavedRecommendationsPageState extends State<SavedRecommendationsPage> {
  bool isLoading = true;
  List<Map<String, dynamic>> savedExercises = [];

  @override
  void initState() {
    super.initState();
    fetchSavedRecommendations();
  }

  Future<void> fetchSavedRecommendations() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();

    if (doc.exists) {
      final data = doc.data();
      setState(() {
        savedExercises = List<Map<String, dynamic>>.from(data?['saved_recommendations'] ?? []);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> deleteExercise(int index) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      savedExercises.removeAt(index);
    });

    await FirebaseFirestore.instance.collection('Users').doc(user.uid).update({
      'saved_recommendations': savedExercises,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exercise deleted successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Saved Recommendations"),
        backgroundColor: Colors.deepPurple,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : savedExercises.isEmpty
              ? const Center(child: Text('No saved recommendations yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: savedExercises.length,
                  itemBuilder: (context, index) {
                    final exercise = savedExercises[index];
                    final title = exercise['title'] ?? 'Unknown Exercise';
                    final recommendedAt = exercise['recommended_at'] ?? 'Unknown Time';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(title),
                        subtitle: Text('Recommended At: $recommendedAt'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteExercise(index),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
