import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flexi_flow/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LogHealthPage extends StatefulWidget {
  const LogHealthPage({super.key});

  @override
  State<LogHealthPage> createState() => _LogHealthPageState();
}

class _LogHealthPageState extends State<LogHealthPage> with SingleTickerProviderStateMixin {
  // Controllers
  final TextEditingController foodController = TextEditingController();
  final TextEditingController mealTimeController = TextEditingController();
  final TextEditingController dietCommentsController = TextEditingController();
  final TextEditingController medNameController = TextEditingController();
  final TextEditingController medDoseController = TextEditingController();
  final TextEditingController medTimeController = TextEditingController();

  // State variables
  TimeOfDay? selectedTime;
  bool isSavingDiet = false;
  bool isLoadingMedicines = true;
  bool takesMedicines = false;
  List<Map<String, dynamic>> todayMedicines = [];
  Map<String, String> medicineStatus = {};
  bool isEditingMedicine = false;
  int? editingMedicineIndex;
  Map<String, String> medicineDocIds = {};
  final user = FirebaseAuth.instance.currentUser;
  bool _hasLoggedBefore = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
    _checkFirstLog();
    fetchTodayMedicines();
  }

  @override
  void dispose() {
    _animationController.dispose();
    foodController.dispose();
    mealTimeController.dispose();
    dietCommentsController.dispose();
    medNameController.dispose();
    medDoseController.dispose();
    medTimeController.dispose();
    super.dispose();
  }

  Future<void> _checkFirstLog() async {
    if (user == null) return;
    final dietLogs = await FirebaseFirestore.instance
        .collection('Diet_Log')
        .where('user_id', isEqualTo: user!.uid)
        .limit(1)
        .get();
    final medLogs = await FirebaseFirestore.instance
        .collection('Medicine_Logs')
        .where('user_id', isEqualTo: user!.uid)
        .limit(1)
        .get();
    setState(() {
      _hasLoggedBefore = dietLogs.docs.isNotEmpty || medLogs.docs.isNotEmpty;
    });
  }

  Future<void> fetchTodayMedicines() async {
    if (user == null) return;
    setState(() => isLoadingMedicines = true);

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user!.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          takesMedicines = userDoc.data()?['takes_medicines'] ?? false;
          todayMedicines = List<Map<String, dynamic>>.from(
              userDoc.data()?['medicine_list'] ?? []);
        });
      }

      final addmedsQuery = await FirebaseFirestore.instance
          .collection('addmeds')
          .where('user_id', isEqualTo: user!.uid)
          .get();

      for (final doc in addmedsQuery.docs) {
        medicineDocIds[doc['Medicine Name'] as String] = doc.id;
      }

      await _checkMedicineStatusForToday();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading medicines: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.deepPurple,
        ),
      );
    } finally {
      setState(() => isLoadingMedicines = false);
    }
  }

  Future<void> _checkMedicineStatusForToday() async {
    if (user == null) return;
    final todayDate = DateTime.now().toIso8601String().split('T')[0];
    
    for (var medicine in todayMedicines) {
      final docId = '${user!.uid}_${medicine['name']}_$todayDate';
      final doc = await FirebaseFirestore.instance.collection('Medicine_Logs').doc(docId).get();
      
      if (doc.exists) {
        setState(() {
          medicineStatus[medicine['name'] as String] = doc['status'] as String;
        });
      }
    }
  }

  Future<void> markMedicineStatus(String medicineName, String status) async {
    if (user == null || !mounted) return;

    final todayDate = DateTime.now().toIso8601String().split('T')[0];
    final currentTime = DateFormat('HH:mm').format(DateTime.now());
    final docId = '${user!.uid}_$medicineName\_$todayDate';

    try {
      await FirebaseFirestore.instance.collection('Medicine_Logs').doc(docId).set({
        'user_id': user!.uid,
        'medicine_name': medicineName,
        'date': todayDate,
        'status': status,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (status.toLowerCase() == 'taken') {
        final addmedsQuery = await FirebaseFirestore.instance
            .collection('addmeds')
            .where('user_id', isEqualTo: user!.uid)
            .where('Medicine Name', isEqualTo: medicineName)
            .limit(1)
            .get();

        if (addmedsQuery.docs.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('addmeds')
              .doc(addmedsQuery.docs.first.id)
              .update({
            'status': 'taken',
            'last_taken_date': todayDate,
            'last_taken_time': currentTime,
          });
        }
      }

      if (mounted) {
        setState(() {
          medicineStatus[medicineName] = status;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Marked "$medicineName" as ${status.capitalize()}'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: Colors.deepPurple,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.deepPurple,
          ),
        );
      }
    }
  }

  Future<void> saveDiet() async {
    if (user == null || !mounted) return;
    setState(() => isSavingDiet = true);

    final url = Uri.parse('${ApiConstants.baseUrl}/log_diet');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": user!.uid,
          "food": foodController.text.trim(),
          "meal_time": mealTimeController.text.trim(),
          "comments": dietCommentsController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        await FirebaseFirestore.instance.collection('Diet_Log').add({
          'user_id': user!.uid,
          'timestamp': FieldValue.serverTimestamp(),
          'food': foodController.text.trim(),
          'meal_time': mealTimeController.text.trim(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Diet log saved successfully!"),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              backgroundColor: Colors.deepPurple,
            ),
          );
          foodController.clear();
          mealTimeController.clear();
          dietCommentsController.clear();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Failed to save diet log"),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.deepPurple,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Error saving diet log"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.deepPurple,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSavingDiet = false);
      }
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.deepPurple,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
        medTimeController.text = "${picked.hour}:${picked.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _addOrUpdateMedicine() async {
    if (user == null || !mounted) return;
    
    if (medNameController.text.isEmpty || 
        medDoseController.text.isEmpty || 
        medTimeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all medicine fields"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.deepPurple,
        ),
      );
      return;
    }

    final newMedicine = {
      'name': medNameController.text.trim(),
      'dose': medDoseController.text.trim(),
      'time': medTimeController.text.trim(),
    };

    if (isEditingMedicine && editingMedicineIndex != null) {
      final oldMedicineName = todayMedicines[editingMedicineIndex!]['name'] as String;
      
      setState(() => todayMedicines[editingMedicineIndex!] = newMedicine);
      
      if (medicineDocIds.containsKey(oldMedicineName)) {
        await FirebaseFirestore.instance
            .collection('addmeds')
            .doc(medicineDocIds[oldMedicineName])
            .update({
          'Medicine Name': newMedicine['name'],
          'Dose': newMedicine['dose'],
          'Time': newMedicine['time'],
        });
        
        if (oldMedicineName != newMedicine['name']) {
          medicineDocIds[newMedicine['name'] as String] = medicineDocIds.remove(oldMedicineName)!;
        }
      }
    } else {
      setState(() {
        todayMedicines.add(newMedicine);
        takesMedicines = true;
      });
      
      final docRef = await FirebaseFirestore.instance.collection('addmeds').add({
        'user_id': user!.uid,
        'Medicine Name': newMedicine['name'],
        'Dose': newMedicine['dose'],
        'Time': newMedicine['time'],
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      medicineDocIds[newMedicine['name'] as String] = docRef.id;
    }

    await FirebaseFirestore.instance.collection('Users').doc(user!.uid).update({
      'takes_medicines': true,
      'medicine_list': todayMedicines,
    });

    _clearMedicineForm();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditingMedicine ? "Medicine updated!" : "Medicine added!"),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Colors.deepPurple,
        ),
      );
    }
  }

  void _clearMedicineForm() {
    medNameController.clear();
    medDoseController.clear();
    medTimeController.clear();
    selectedTime = null;
    setState(() {
      isEditingMedicine = false;
      editingMedicineIndex = null;
    });
  }

  void _editMedicine(int index) {
    final medicine = todayMedicines[index];
    medNameController.text = medicine['name'] as String;
    medDoseController.text = medicine['dose'] as String;
    medTimeController.text = medicine['time'] as String;
    
    final timeParts = (medicine['time'] as String).split(':');
    if (timeParts.length == 2) {
      selectedTime = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );
    }
    
    setState(() {
      isEditingMedicine = true;
      editingMedicineIndex = index;
    });
    
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 500),
    );
  }

  Future<void> _deleteMedicine(int index) async {
    if (user == null || !mounted) return;
    
    final medicineName = todayMedicines[index]['name'] as String;
    
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Medicine"),
        content: Text("Are you sure you want to delete $medicineName?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
            style: TextButton.styleFrom(
              backgroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      if (medicineDocIds.containsKey(medicineName)) {
        await FirebaseFirestore.instance
            .collection('addmeds')
            .doc(medicineDocIds[medicineName])
            .delete();
        medicineDocIds.remove(medicineName);
      }
      
      setState(() {
        todayMedicines.removeAt(index);
        takesMedicines = todayMedicines.isNotEmpty;
      });
      
      await FirebaseFirestore.instance.collection('Users').doc(user!.uid).update({
        'takes_medicines': todayMedicines.isNotEmpty,
        'medicine_list': todayMedicines,
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$medicineName deleted"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.deepPurple,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Health Logger", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Diet Section
              _buildDietSection(),
              const SizedBox(height: 24),
              
              // Medicine Section
              _buildMedicineSection(),
              
              // Medicine List
              if (isLoadingMedicines)
                const Center(child: CircularProgressIndicator())
              else if (!takesMedicines)
                _buildNoMedicinesCard()
              else
                _buildMedicineList(),
            ].animate(interval: 50.ms).slideY(begin: 0.1, end: 0),
          ),
        ),
      ),
    );
  }

  Widget _buildDietSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.restaurant, color: Colors.deepPurple[300]),
                const SizedBox(width: 8),
                const Text(
                  "Log Your Meal",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: foodController,
              decoration: InputDecoration(
                labelText: "What did you eat?",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.fastfood),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: mealTimeController,
              decoration: InputDecoration(
                labelText: "Meal Time",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.access_time),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: dietCommentsController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: "Any comments?",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.comment),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isSavingDiet ? null : saveDiet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: isSavingDiet
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save, size: 20, color: Colors.white),
                label: Text(
                  isSavingDiet ? "Saving..." : "Save Meal Log",
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicineSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medical_services, color: Colors.deepPurple[300]),
                const SizedBox(width: 8),
                Text(
                  isEditingMedicine ? "Edit Medicine" : "Add Medicine",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: medNameController,
              decoration: InputDecoration(
                labelText: "Medicine Name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.medication),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: medDoseController,
              decoration: InputDecoration(
                labelText: "Dosage",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.exposure),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: medTimeController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: "Time to Take",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.schedule),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: () => _selectTime(context),
                ),
              ),
              onTap: () => _selectTime(context),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isEditingMedicine)
                  TextButton(
                    onPressed: _clearMedicineForm,
                    child: const Text("Cancel"),
                  ),
                ElevatedButton.icon(
                  onPressed: _addOrUpdateMedicine,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  icon: Icon(
                    isEditingMedicine ? Icons.update : Icons.add,
                    size: 20,
                    color: Colors.white,
                  ),
                  label: Text(
                    isEditingMedicine ? "Update" : "Add",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoMedicinesCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.medical_services_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              "No Medicines Tracked",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Add your medicines above to track them",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicineList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            "Today's Medicines",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: todayMedicines.length,
          itemBuilder: (context, index) {
            final medicine = todayMedicines[index];
            final name = medicine['name'] as String;
            final dose = medicine['dose'] as String;
            final time = medicine['time'] as String;
            final currentStatus = medicineStatus[name];

            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _editMedicine(index),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Status Indicator
                      Container(
                        width: 8,
                        height: 40,
                        decoration: BoxDecoration(
                          color: currentStatus == null
                              ? Colors.orange
                              : currentStatus.toLowerCase().trim() == 'taken'
                                  ? Colors.green
                                  : Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Medicine Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$dose • $time',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Action Buttons
                      if (currentStatus == null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.white),
                              onPressed: () => markMedicineStatus(name, 'taken'),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: () => markMedicineStatus(name, 'missed'),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                            ),
                          ],
                        )
                      else
                        Icon(
                          currentStatus.toLowerCase().trim() == 'taken'
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: currentStatus.toLowerCase().trim() == 'taken'
                              ? Colors.green
                              : Colors.red,
                          size: 28,
                        ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn().slideX(
              begin: -0.1,
              curve: Curves.easeOut,
            );
          },
        ),
      ],
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}