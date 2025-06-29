import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth_screen.dart';
import 'saved_recommendations_page.dart';

class ProfilePage extends StatefulWidget {
  final VoidCallback toggleTheme;

  const ProfilePage({super.key, required this.toggleTheme});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  String fullName = '';
  String username = '';
  String arthritisType = 'RA';
  String medications = '';
  bool doesExercise = false;
  bool isLoading = true;
  bool takesMedicines = false;
  List<Map<String, dynamic>> medicineList = [];
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _medicationsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchProfileData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _medicationsController.dispose();
    super.dispose();
  }

  Future<void> fetchProfileData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          fullName = data['full_name'] ?? '';
          username = data['username'] ?? '';
          arthritisType = data['arthritis_type'] ?? 'RA';
          medications = data['medications'] ?? '';
          doesExercise = data['does_exercise'] ?? false;
          takesMedicines = data['takes_medicines'] ?? false;
          medicineList = List<Map<String, dynamic>>.from(data['medicine_list'] ?? []);
          
          _fullNameController.text = fullName;
          _usernameController.text = username;
          _medicationsController.text = medications;
          
          isLoading = false;
        });
      }
    }
  }

  Future<void> updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userRef = FirebaseFirestore.instance.collection('Users').doc(user.uid);

        Map<String, dynamic> updateData = {
          'full_name': fullName,
          'username': username,
          'arthritis_type': arthritisType,
          'medications': medications,
          'does_exercise': doesExercise,
          'takes_medicines': takesMedicines,
          'last_updated': FieldValue.serverTimestamp(),
        };

        if (takesMedicines) {
          updateData['medicine_list'] = medicineList;
        } else {
          updateData['medicine_list'] = [];
        }

        await userRef.update(updateData);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully!'),
            backgroundColor: Colors.deepPurple,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> logout() async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout", style: TextStyle(color: Colors.deepPurple)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('stayLoggedIn');
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => AuthScreen(toggleTheme: widget.toggleTheme)),
          (route) => false,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account Permanently"),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("This action cannot be undone!"),
            SizedBox(height: 10),
            Text("All your data will be permanently deleted."),
            SizedBox(height: 10),
            Text("We're sorry to see you go. 😢"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete Account", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(child: CircularProgressIndicator()),
          );

          await FirebaseFirestore.instance.collection('Users').doc(user.uid).delete();
          await user.delete();

          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();

          if (!mounted) return;
          Navigator.of(context).pop();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Account deleted successfully. Goodbye!"),
              duration: Duration(seconds: 2),
            ),
          );

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => AuthScreen(toggleTheme: widget.toggleTheme)),
            (route) => false,
          );
        }
      } catch (e) {
        if (!mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error deleting account: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addMedicine() {
    String medName = '';
    String dose = '';
    TimeOfDay? time;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Add Medicine", style: TextStyle(color: Colors.deepPurple)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: "Medicine Name",
                        labelStyle: TextStyle(color: Colors.deepPurple[700]),
                        prefixIcon: Icon(Icons.medical_services, color: Colors.deepPurple),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.deepPurple),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.deepPurple),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      ),
                      onChanged: (value) => medName = value,
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: "Dose",
                        labelStyle: TextStyle(color: Colors.deepPurple[700]),
                        prefixIcon: Icon(Icons.medication, color: Colors.deepPurple),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.deepPurple),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.deepPurple),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      ),
                      onChanged: (value) => dose = value,
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: Colors.deepPurple,
                                  onPrimary: Colors.white,
                                  onSurface: Colors.black,
                                ),
                                textButtonTheme: TextButtonThemeData(
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.deepPurple,
                                  ),
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setStateDialog(() => time = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.deepPurple),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              time != null 
                                ? time!.format(context) 
                                : "Select Time",
                              style: TextStyle(
                                color: time != null
                                  ? Colors.black
                                  : Colors.grey[600],
                              ),
                            ),
                            Icon(
                              Icons.access_time,
                              color: Colors.deepPurple,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Colors.deepPurple)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (medName.isNotEmpty && dose.isNotEmpty && time != null) {
                      setState(() {
                        medicineList.add({
                          'name': medName,
                          'dose': dose,
                          'time': "${time!.hour}:${time!.minute}",
                        });
                      });
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                  ),
                  child: const Text("Add", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteMedicine(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to remove this medicine?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.deepPurple)),
          ),
          TextButton(
            onPressed: () {
              setState(() => medicineList.removeAt(index));
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _viewSavedRecommendations() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SavedRecommendationsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6, color: Colors.white),
            onPressed: widget.toggleTheme,
            tooltip: 'Toggle Theme',
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: _viewSavedRecommendations,
            tooltip: 'Saved Recommendations',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'logout') logout();
              if (value == 'delete') _deleteAccount();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.deepPurple),
                  title: Text('Logout'),
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete Account'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Section
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Personal Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple[800],
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _fullNameController,
                              decoration: InputDecoration(
                                labelText: 'Full Name',
                                labelStyle: TextStyle(color: Colors.deepPurple[700]),
                                prefixIcon: Icon(Icons.person, color: Colors.deepPurple),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.deepPurple),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.deepPurple),
                                ),
                              ),
                              onSaved: (value) => fullName = value!.trim(),
                              validator: (value) => value!.isEmpty ? 'Enter your name' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _usernameController,
                              decoration: InputDecoration(
                                labelText: 'Username',
                                labelStyle: TextStyle(color: Colors.deepPurple[700]),
                                prefixIcon: Icon(Icons.account_circle, color: Colors.deepPurple),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.deepPurple),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.deepPurple),
                                ),
                              ),
                              onSaved: (value) => username = value!.trim(),
                              validator: (value) => value!.isEmpty ? 'Enter username' : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Health Information Section
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Health Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple[800],
                              ),
                            ),
                            const SizedBox(height: 20),
                            DropdownButtonFormField<String>(
                              value: arthritisType,
                              decoration: InputDecoration(
                                labelText: 'Arthritis Type',
                                labelStyle: TextStyle(color: Colors.deepPurple[700]),
                                prefixIcon: Icon(Icons.local_hospital, color: Colors.deepPurple),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.deepPurple),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.deepPurple),
                                ),
                              ),
                              dropdownColor: Colors.white,
                              items: ['RA', 'OA', 'SpA', 'Other']
                                  .map((type) => DropdownMenuItem(
                                        value: type,
                                        child: Text(type),
                                      ))
                                  .toList(),
                              onChanged: (value) => setState(() => arthritisType = value!),
                              onSaved: (value) => arthritisType = value!,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _medicationsController,
                              decoration: InputDecoration(
                                labelText: 'Medications',
                                labelStyle: TextStyle(color: Colors.deepPurple[700]),
                                prefixIcon: Icon(Icons.medication, color: Colors.deepPurple),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.deepPurple),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.deepPurple),
                                ),
                              ),
                              maxLines: 2,
                              onSaved: (value) => medications = value!.trim(),
                            ),
                            const SizedBox(height: 16),
                            SwitchListTile(
                              value: doesExercise,
                              onChanged: (value) => setState(() => doesExercise = value),
                              activeColor: Colors.deepPurple,
                              title: const Text('Do you exercise regularly?'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Medicine Management Section
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Medicine Management',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple[800],
                                  ),
                                ),
                                const Spacer(),
                                Switch(
                                  value: takesMedicines,
                                  onChanged: (value) {
                                    setState(() {
                                      takesMedicines = value;
                                      if (!takesMedicines) {
                                        medicineList.clear();
                                      }
                                    });
                                  },
                                  activeColor: Colors.deepPurple,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'I am taking regular medicines',
                              style: TextStyle(
                                color: Colors.deepPurple[700],
                              ),
                            ),
                            if (takesMedicines) ...[
                              const SizedBox(height: 20),
                              if (medicineList.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.medication_liquid,
                                        size: 50,
                                        color: Colors.deepPurple.withOpacity(0.3),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'No medicines added yet',
                                        style: TextStyle(
                                          color: Colors.deepPurple.withOpacity(0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (medicineList.isNotEmpty)
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: medicineList.length,
                                  separatorBuilder: (context, index) =>
                                      Divider(height: 1, color: Colors.deepPurple[100]),
                                  itemBuilder: (context, index) {
                                    final med = medicineList[index];
                                    final timeParts = med['time'].split(':');
                                    final time = TimeOfDay(
                                      hour: int.parse(timeParts[0]),
                                      minute: int.parse(timeParts[1]),
                                    );
                                    
                                    return ListTile(
                                      leading: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: Colors.deepPurple.withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.medical_services,
                                          color: Colors.deepPurple,
                                        ),
                                      ),
                                      title: Text(
                                        med['name'],
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                      subtitle: Text(
                                        '${med['dose']} • ${time.format(context)}',
                                      ),
                                      trailing: IconButton(
                                        icon: Icon(Icons.delete, color: Colors.deepPurple),
                                        onPressed: () => _deleteMedicine(index),
                                      ),
                                    );
                                  },
                                ),
                              const SizedBox(height: 10),
                              ElevatedButton.icon(
                                onPressed: _addMedicine,
                                icon: const Icon(Icons.add, color: Colors.white),
                                label: const Text('Add Medicine', style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurple,
                                  minimumSize: const Size.fromHeight(50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Save Button
                    ElevatedButton(
                      onPressed: updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}