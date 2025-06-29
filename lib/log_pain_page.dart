import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flexi_flow/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/animation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


class LogPainPage extends StatefulWidget {
  const LogPainPage({super.key});

  @override
  State<LogPainPage> createState() => _LogPainPageState();
}

class _LogPainPageState extends State<LogPainPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  double painLevel = 5;
  String notes = "";
  bool isLoading = false;
  final user = FirebaseAuth.instance.currentUser;
  bool _hasLoggedBefore = false;
  
  // Animation controllers
  late AnimationController _titleController;
  late AnimationController _painSliderController;
  late AnimationController _notesController;
  late AnimationController _buttonController;
  late Animation<double> _buttonScaleAnimation;
  late Animation<Color?> _painColorAnimation;

  @override
  void initState() {
    super.initState();
    _checkFirstLog();
    
    // Initialize animation controllers
    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _painSliderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _notesController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _buttonScaleAnimation = TweenSequence<double>(
      [
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.95), weight: 50),
        TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 50),
      ],
    ).animate(
      CurvedAnimation(
        parent: _buttonController,
        curve: Curves.easeInOut,
      ),
    );
    
    _painColorAnimation = ColorTween(
      begin: Colors.green,
      end: Colors.red,
    ).animate(
      CurvedAnimation(
        parent: _painSliderController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Start animations in sequence
    Future.delayed(const Duration(milliseconds: 200), () {
      _titleController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      _painSliderController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      _notesController.forward();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _painSliderController.dispose();
    _notesController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  Future<void> _checkFirstLog() async {
    if (user == null) return;
    final logs = await FirebaseFirestore.instance
        .collection('Pain_Logs')
        .where('user_id', isEqualTo: user!.uid)
        .limit(1)
        .get();
    setState(() {
      _hasLoggedBefore = logs.docs.isNotEmpty;
    });
  }

  Future<void> submitPainLog() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      isLoading = true;
    });

    // Play button press animation
    await _buttonController.forward();
    await _buttonController.reverse();

    if (user == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    final url = Uri.parse('${ApiConstants.baseUrl}/log_pain');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": user!.uid,
          "pain_level": painLevel.toInt(),
          "notes": notes,
        }),
      );

      if (response.statusCode == 200) {
        await FirebaseFirestore.instance.collection('Pain_Logs').add({
          'user_id': user!.uid,
          'timestamp': FieldValue.serverTimestamp(),
          'pain_level': painLevel,
          'notes': notes,
        });

        // Show success dialog with built-in animation
        await showDialog(
          context: context,
          builder: (context) => ScaleTransition(
            scale: CurvedAnimation(
              parent: ModalRoute.of(context)!.animation!,
              curve: Curves.easeOutBack,
            ),
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.deepPurple.shade50,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 80,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Log Submitted!',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Your pain log has been recorded successfully.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'OK',
                    style: GoogleFonts.poppins(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit pain log: ${response.statusCode}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildPainIndicator(double value) {
    return AnimatedBuilder(
      animation: _painColorAnimation,
      builder: (context, child) {
        return Column(
          children: [
            Container(
              height: 30,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: LinearGradient(
                  colors: [
                    Colors.green,
                    Colors.yellow,
                    Colors.orange,
                    Colors.red,
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
                ),
              ),
              child: Align(
                alignment: Alignment(value / 10 * 2 - 1, 0),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _getPainColor(value),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _getPainColor(value).withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      value.round().toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('0', style: TextStyle(color: Colors.green.shade800)),
                Text('5', style: TextStyle(color: Colors.orange.shade800)),
                Text('10', style: TextStyle(color: Colors.red.shade800)),
              ],
            ),
          ],
        );
      },
    );
  }

  Color _getPainColor(double value) {
    return Color.lerp(Colors.green, Colors.red, value / 10)!;
  }

  Widget _buildPainIcon(double value) {
    if (value < 3) return Icon(Icons.sentiment_very_satisfied, color: Colors.green, size: 30);
    if (value < 6) return Icon(Icons.sentiment_neutral, color: Colors.orange, size: 30);
    if (value < 9) return Icon(Icons.sentiment_dissatisfied, color: Colors.orangeAccent, size: 30);
    return Icon(Icons.sentiment_very_dissatisfied, color: Colors.red, size: 30);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with back button
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(-1, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _titleController,
                    curve: Curves.easeOutQuint,
                  )),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        color: Colors.deepPurple,
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Log Your Pain",
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // First-time user welcome
                if (!_hasLoggedBefore)
                  FadeTransition(
                    opacity: _titleController,
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.deepPurple.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildPainIcon(painLevel),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Welcome to pain tracking! Regular logging helps us provide better insights.",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.deepPurple.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Pain level section
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.5),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _painSliderController,
                    curve: Curves.easeOutBack,
                  )),
                  child: Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    shadowColor: Colors.deepPurple.withOpacity(0.2),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              AnimatedBuilder(
                                animation: _painSliderController,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: 1 + 0.2 * _painSliderController.value,
                                    child: _buildPainIcon(painLevel),
                                  );
                                },
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "Pain Level",
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildPainIndicator(painLevel),
                          const SizedBox(height: 20),
                          Slider(
                            value: painLevel,
                            min: 0,
                            max: 10,
                            divisions: 10,
                            activeColor: Colors.deepPurple,
                            inactiveColor: Colors.deepPurple.shade200,
                            thumbColor: Colors.white,
                            onChanged: (value) {
                              setState(() {
                                painLevel = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Notes section
                FadeTransition(
                  opacity: _notesController,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.5),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _notesController,
                      curve: Curves.easeOutBack,
                    )),
                    child: Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      shadowColor: Colors.deepPurple.withOpacity(0.2),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.notes,
                                  color: Colors.deepPurple,
                                  size: 30,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  "Additional Notes",
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              maxLines: 5,
                              decoration: InputDecoration(
                                hintText: "Describe your pain, symptoms, triggers, or anything else...",
                                hintStyle: GoogleFonts.poppins(),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.deepPurple.shade50,
                              ),
                              style: GoogleFonts.poppins(),
                              onChanged: (value) {
                                notes = value;
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Please describe your pain";
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Submit button
                ScaleTransition(
                  scale: _buttonScaleAnimation,
                  child: FadeTransition(
                    opacity: _notesController,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : submitPainLog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                        shadowColor: Colors.deepPurple.withOpacity(0.3),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.medical_services),
                                const SizedBox(width: 10),
                                Text(
                                  "Submit Pain Log",
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}