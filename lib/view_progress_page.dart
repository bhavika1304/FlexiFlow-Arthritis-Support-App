import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flexi_flow/constants.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ViewProgressPage extends StatefulWidget {
  const ViewProgressPage({super.key});

  @override
  State<ViewProgressPage> createState() => _ViewProgressPageState();
}

class _ViewProgressPageState extends State<ViewProgressPage> {
  double? averagePain;
  bool isLoading = false;
  List<Map<String, dynamic>> dailyLogs = [];

  String selectedMode = 'week'; // week or month
  String selectedRange = 'this'; // this or last

  Future<void> fetchProgress() async {
    setState(() {
      isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    final userId = user.uid;
    final url = Uri.parse('${ApiConstants.baseUrl}/view_progress?user_id=$userId&mode=$selectedMode&range=$selectedRange');

    try {
      final response = await http.get(url);
      print('Server Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          averagePain = data["average_pain"];
          dailyLogs = List<Map<String, dynamic>>.from(data["daily_logs"]);
        });
      } else {
        print("Failed to fetch progress: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching progress: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchProgress();
  }

  List<FlSpot> getPainLevelSpots() {
    List<FlSpot> spots = [];
    for (int i = 0; i < dailyLogs.length; i++) {
      spots.add(FlSpot((i + 1).toDouble(), (dailyLogs[i]["pain_level"] ?? 0).toDouble()));
    }
    return spots;
  }

  Map<String, int> getMoodCounts() {
    Map<String, int> moodCounts = {
      'happy': 0,
      'neutral': 0,
      'tired': 0,
      'normal': 0,
    };
    
    for (var log in dailyLogs) {
      String mood = (log["mood"] ?? "neutral").toLowerCase();
      if (mood.contains("good") || mood.contains("relax") || mood.contains("happy")) {
        mood = "happy";
      } else if (mood.contains("tired") || mood.contains("pain") || mood.contains("sad")) {
        mood = "tired";
      } else if (mood.contains("normal") || mood.contains("ok")) {
        mood = "normal";
      } else {
        mood = "neutral";
      }
      moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
    }
    return moodCounts;
  }

  Color getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return Colors.green;
      case 'neutral':
        return Colors.blue;
      case 'tired':
        return Colors.orange;
      case 'normal':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Your Progress", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Introduction Text
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            "Track Your Journey",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "We help you visualize your pain levels and mood patterns over time. "
                            "By tracking these metrics, you can better understand your progress and "
                            "identify trends that may help in managing your condition effectively.",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn().slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 20),

                  // Time Period Selector
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("View data for:", style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: DropdownButton<String>(
                              value: selectedMode,
                              underline: const SizedBox(),
                              items: ['week', 'month'].map((value) {
                                return DropdownMenuItem(
                                  value: value,
                                  child: Text(value.capitalize(), style: const TextStyle(color: Colors.deepPurple)),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedMode = value!;
                                });
                                fetchProgress();
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: DropdownButton<String>(
                              value: selectedRange,
                              underline: const SizedBox(),
                              items: ['this', 'last'].map((value) {
                                return DropdownMenuItem(
                                  value: value,
                                  child: Text(value.capitalize(), style: const TextStyle(color: Colors.deepPurple)),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedRange = value!;
                                });
                                fetchProgress();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn().slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 25),

                  // Average Pain Level Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text(
                            "Average Pain Level",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            averagePain != null ? averagePain!.toStringAsFixed(1) : "--",
                            style: const TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _getPainLevelColor(averagePain ?? 0),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              averagePain == null
                                  ? ""
                                  : averagePain! <= 3
                                      ? "You're doing great! 🎉"
                                      : averagePain! <= 6
                                          ? "Moderate pain. Keep exercising! 💪"
                                          : "High pain detected. Take it easy. 🛌",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn().slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 25),

                  // Pain Level Chart
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            "Pain Level Over Time",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 250,
                            child: LineChart(
                              LineChartData(
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: true,
                                  horizontalInterval: 1,
                                  getDrawingHorizontalLine: (value) {
                                    return FlLine(
                                      color: Colors.grey[300],
                                      strokeWidth: 1,
                                    );
                                  },
                                ),
                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval: 1,
                                      getTitlesWidget: (value, meta) {
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Text(
                                            'Day ${value.toInt()}',
                                            style: const TextStyle(fontSize: 10),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval: 1,
                                      getTitlesWidget: (value, meta) {
                                        return Text(
                                          value.toInt().toString(),
                                          style: const TextStyle(fontSize: 10),
                                        );
                                      },
                                    ),
                                  ),
                                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                                borderData: FlBorderData(
                                  show: true,
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: getPainLevelSpots(),
                                    isCurved: true,
                                    color: Colors.deepPurple,
                                    barWidth: 3,
                                    dotData: FlDotData(show: true),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: Colors.deepPurple.withOpacity(0.1),
                                    ),
                                  ),
                                ],
                                minY: 0,
                                maxY: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn().slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 25),

                  // Mood Distribution Chart
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            "Mood Distribution",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 250,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                gridData: FlGridData(show: false),
                                borderData: FlBorderData(
                                  show: true,
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        final moods = getMoodCounts().keys.toList();
                                        if (value.toInt() >= 0 && value.toInt() < moods.length) {
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 8),
                                            child: Text(
                                              moods[value.toInt()].capitalize(),
                                              style: const TextStyle(fontSize: 10),
                                            ),
                                          );
                                        }
                                        return const SizedBox();
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval: 1,
                                      getTitlesWidget: (value, meta) {
                                        return Text(
                                          value.toInt().toString(),
                                          style: const TextStyle(fontSize: 10),
                                        );
                                      },
                                    ),
                                  ),
                                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                                barGroups: getMoodCounts()
                                    .entries
                                    .toList()
                                    .asMap()
                                    .entries
                                    .map(
                                      (entry) => BarChartGroupData(
                                        x: entry.key,
                                        barRods: [
                                          BarChartRodData(
                                            toY: entry.value.value.toDouble(),
                                            width: 22,
                                            color: getMoodColor(entry.value.key),
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(4),
                                              topRight: Radius.circular(4),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 5,
                            children: getMoodCounts()
                                .entries
                                .map((entry) => Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: getMoodColor(entry.key),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          "${entry.key.capitalize()}: ${entry.value}",
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn().slideY(begin: 0.1, end: 0),
                ],
              ),
            ),
    );
  }

  Color _getPainLevelColor(double painLevel) {
    if (painLevel <= 3) return Colors.green;
    if (painLevel <= 6) return Colors.orange;
    return Colors.red;
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}