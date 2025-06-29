import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flexi_flow/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';

class ExerciseRecommendPage extends StatefulWidget {
  const ExerciseRecommendPage({super.key});

  @override
  State<ExerciseRecommendPage> createState() => _ExerciseRecommendPageState();
}

class _ExerciseRecommendPageState extends State<ExerciseRecommendPage> {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  double painLevel = 5;
  String selectedMood = 'neutral';
  String selectedJoint = 'knee';
  String selectedArthritisType = 'OA';

  bool isLoading = false;
  List<dynamic> recommendations = [];

  Future<void> fetchRecommendations() async {
    setState(() {
      isLoading = true;
      recommendations = [];
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to get recommendations')),
      );
      setState(() => isLoading = false);
      return;
    }

    final url = Uri.parse('${ApiConstants.baseUrl}/recommend');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "pain_level": painLevel.toInt(),
          "mood": selectedMood,
          "joint": selectedJoint,
          "arthritis_type": selectedArthritisType,
          "user_id": user.uid,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          recommendations = data["recommendations"];
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.animateTo(
            MediaQuery.of(context).size.height * 0.6,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _submitFeedback(int exerciseId, double rating) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final url = Uri.parse('${ApiConstants.baseUrl}/feedback');
    double reward = rating / 5.0;

    final contextData = {
      "pain_level": painLevel.toInt(),
      "mood": selectedMood,
      "joint": selectedJoint,
      "arthritis_type": selectedArthritisType,
      "user_id": user.uid,
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "context": contextData,
          "exercise_id": exerciseId,
          "reward": reward,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thanks for your feedback!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting feedback: $e')),
      );
    }
  }

  void _showFeedbackDialog(BuildContext context, dynamic exercise) {
    double rating = 3;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Rate ${exercise["name"]}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Slider(
                value: rating,
                min: 1,
                max: 5,
                divisions: 4,
                activeColor: Colors.deepPurple,
                onChanged: (value) {
                  setState(() {
                    rating = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    _submitFeedback(exercise["id"], rating);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Submit Feedback",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Exercise Recommendations",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background Animation - Positioned to be visible but not overwhelming
          // Replace the Positioned widget for the animation with this:
Positioned.fill(
  child: Center(
    child: SizedBox(
      width: MediaQuery.of(context).size.width * 0.8,
      height: MediaQuery.of(context).size.height * 0.5,
      child: Lottie.asset(
        'animations/recommendation.json',
        fit: BoxFit.contain,
        alignment: Alignment.center,
      ),
    ),
  ),
),

          // Semi-transparent overlay for better text visibility
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                  ],
                ),
              ),
            ),
          ),

          // Main Content
          SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(20, 100, 20, 40),
            child: Column(
              children: [
                // Input Card
                Card(
                  elevation: 4,
                  color: Colors.white.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Personalized Exercise Recommendations",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Pain Level: ${painLevel.toInt()}/10",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Slider(
                            value: painLevel,
                            min: 0,
                            max: 10,
                            divisions: 10,
                            activeColor: Colors.deepPurple,
                            label: painLevel.round().toString(),
                            onChanged: (value) {
                              setState(() {
                                painLevel = value;
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                          DropdownButtonFormField<String>(
                            value: selectedMood,
                            items: ['happy', 'neutral', 'sad'].map((mood) {
                              return DropdownMenuItem(
                                value: mood,
                                child: Text(mood),
                              );
                            }).toList(),
                            decoration: const InputDecoration(
                              labelText: "Current Mood",
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              setState(() {
                                selectedMood = value!;
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                          DropdownButtonFormField<String>(
                            value: selectedJoint,
                            items: ['knee', 'wrist', 'hip', 'shoulder', 'hand', 'ankle', 'foot', 'elbow', 'neck', 'spine']
                                .map((joint) {
                              return DropdownMenuItem(
                                value: joint,
                                child: Text(joint),
                              );
                            }).toList(),
                            decoration: const InputDecoration(
                              labelText: "Affected Joint",
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              setState(() {
                                selectedJoint = value!;
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                          DropdownButtonFormField<String>(
                            value: selectedArthritisType,
                            items: ['OA', 'RA', 'SpA'].map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              );
                            }).toList(),
                            decoration: const InputDecoration(
                              labelText: "Arthritis Type",
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              setState(() {
                                selectedArthritisType = value!;
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  fetchRecommendations();
                                }
                              },
                              child: isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                      "Get Recommendations",
                                      style: TextStyle(color: Colors.white),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Recommendations Section
                if (recommendations.isNotEmpty)
                  Card(
                    elevation: 4,
                    color: Colors.white.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Recommended Exercises",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...recommendations.map((ex) => Column(
                                children: [
                                  const Divider(),
                                  ListTile(
                                    title: Text(
                                      ex["name"],
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: ex["tags"] != null ? Text(ex["tags"]) : null,
                                    trailing: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.deepPurple,
                                      ),
                                      onPressed: () {
                                        _showFeedbackDialog(context, ex);
                                      },
                                      child: const Text(
                                        "Done",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              )),
                        ],
                      ),
                    ),
                  )
                else if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  const SizedBox(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}