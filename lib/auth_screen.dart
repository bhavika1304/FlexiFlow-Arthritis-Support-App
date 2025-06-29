import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';
import 'package:flexi_flow/data/achievements_service.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback toggleTheme;

  const AuthScreen({super.key, required this.toggleTheme});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  bool stayLoggedIn = false;
  final _formKey = GlobalKey<FormState>();
  final AchievementsService _achievementsService = AchievementsService();

  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController emailUsernameController = TextEditingController();

  bool showPassword = false;
  bool showConfirmPassword = false;

  String username = '';
  String email = '';
  String fullName = '';
  String arthritisType = 'RA';
  bool doesExercise = false;
  String error = '';

  @override
  void initState() {
    super.initState();
    checkAutoLogin();
  }

  Future<void> checkAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final autoLogin = prefs.getBool('stayLoggedIn') ?? false;
    if (autoLogin && FirebaseAuth.instance.currentUser != null) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage(toggleTheme: widget.toggleTheme)),
        );
      }
    }
  }

  Future<void> _handleSuccessfulLogin() async {
    final didCheckin = await _achievementsService.recordDailyCheckin();
    
    if (didCheckin && mounted) {
      final currentStreak = await _achievementsService.getCurrentStreak();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.local_fire_department, color: Colors.orange),
              const SizedBox(width: 8),
              Text('+1 Daily Login! Current streak: $currentStreak days'),
            ],
          ),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Colors.deepPurple,
        ),
      );
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('stayLoggedIn', stayLoggedIn);
  }

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    emailUsernameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate();
    if (!isValid!) return;
    _formKey.currentState?.save();

    try {
      if (isLogin) {
        String loginEmail = '';

        if (emailUsernameController.text.contains('@')) {
          loginEmail = emailUsernameController.text.trim();
        } else {
          final userSnapshot = await FirebaseFirestore.instance
              .collection('Users')
              .where('username', isEqualTo: emailUsernameController.text.trim())
              .get();

          if (userSnapshot.docs.isEmpty) {
            setState(() => error = 'No account found for this username.');
            return;
          }

          loginEmail = userSnapshot.docs.first['email'];
        }

        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: loginEmail,
          password: passwordController.text.trim(),
        );

        await _handleSuccessfulLogin();
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage(toggleTheme: widget.toggleTheme)),
          );
        }
      } else {
        final usernameSnapshot = await FirebaseFirestore.instance
            .collection('Users')
            .where('username', isEqualTo: username)
            .get();

        if (usernameSnapshot.docs.isNotEmpty) {
          setState(() => error = 'Username already taken. Choose another.');
          return;
        }

        final authResult = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: passwordController.text.trim(),
        );

        await FirebaseFirestore.instance.collection('Users').doc(authResult.user!.uid).set({
          'full_name': fullName,
          'username': username,
          'email': email,
          'arthritis_type': arthritisType,
          'does_exercise': doesExercise,
          'created_at': Timestamp.now(),
          'takes_medicines': false, // Default value
        });

        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Signup Successful!'),
            content: const Text('Please login with your credentials.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    isLogin = true;
                    emailUsernameController.text = email;
                  });
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => error = e.message ?? 'Something went wrong');
    }
  }

  bool _validatePassword(String value) {
    final passwordRegex = RegExp(r'^(?=.*[0-9])(?=.*[!@#\$&*~]).{8,}$');
    return passwordRegex.hasMatch(value);
  }

  Future<void> _showTermsPopup() async {
    bool termsAccepted = false;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms and Conditions'),
        content: const Text(
          "• We respect your data privacy.\n"
          "• Your health data will be stored securely.\n"
          "• FlexiFlow is for educational support, not medical advice.\n"
          "• By continuing, you allow data storage for progress tracking.\n"
          "• You can delete your account anytime.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              termsAccepted = true;
              Navigator.pop(context);
            },
            child: const Text('Accept'),
          ),
        ],
      ),
    );

    if (termsAccepted) {
      _submit();
    } else {
      setState(() => error = 'You must accept Terms to continue.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('FlexiFlow Login'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: widget.toggleTheme,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.purple.shade200],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Text(
                            isLogin ? 'Login' : 'Sign Up',
                            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                          ),
                          const SizedBox(height: 30),
                          if (!isLogin) ...[
                            _buildTextField('Full Name', Icons.person, (value) => fullName = value!.trim()),
                            const SizedBox(height: 16),
                            _buildTextField('Username', Icons.account_circle, (value) => username = value!.trim()),
                            const SizedBox(height: 16),
                            _buildTextField('Email', Icons.email, (value) => email = value!.trim(), isEmail: true),
                            const SizedBox(height: 16),
                          ],
                          if (isLogin)
                            _buildTextField('Email or Username', Icons.person, (value) => null, controller: emailUsernameController),
                          const SizedBox(height: 16),
                          _buildPasswordField('Password', passwordController, showPassword, () {
                            setState(() => showPassword = !showPassword);
                          }),
                          const SizedBox(height: 16),
                          if (!isLogin) ...[
                            _buildPasswordField('Confirm Password', confirmPasswordController, showConfirmPassword, () {
                              setState(() => showConfirmPassword = !showConfirmPassword);
                            }, confirm: true),
                            const SizedBox(height: 20),
                            _buildDropdown(),
                            const SizedBox(height: 16),
                            SwitchListTile(
                              value: doesExercise,
                              onChanged: (value) => setState(() => doesExercise = value),
                              title: const Text('Do you already exercise?'),
                              activeColor: Colors.deepPurple,
                            ),
                          ],
                          if (error.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(error, style: const TextStyle(color: Colors.red)),
                          ],
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: isLogin ? _submit : _showTermsPopup,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            child: Text(
                              isLogin ? 'Login' : 'Sign Up',
                              style: const TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextButton(
                            onPressed: () => setState(() => isLogin = !isLogin),
                            child: Text(
                              isLogin ? 'Create an account' : 'Already have an account? Login',
                              style: const TextStyle(color: Colors.deepPurple),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, Function(String?) onSave,
      {bool isEmail = false, int maxLines = 1, TextEditingController? controller}) {
    return TextFormField(
      key: ValueKey(label),
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      onSaved: onSave,
      maxLines: maxLines,
      validator: (value) => value!.isEmpty ? 'Enter $label' : null,
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller, bool show, VoidCallback toggleVisibility, {bool confirm = false}) {
    return TextFormField(
      controller: controller,
      key: ValueKey(label),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.lock, color: Colors.deepPurple),
        suffixIcon: IconButton(
          icon: Icon(show ? Icons.visibility_off : Icons.visibility),
          onPressed: toggleVisibility,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
      obscureText: !show,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Enter $label';
        }
        if (!confirm && !_validatePassword(value)) {
          return 'Password must be 8+ chars, number, special char';
        }
        if (confirm && value != passwordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: arthritisType,
      decoration: InputDecoration(
        labelText: 'Arthritis Type',
        prefixIcon: const Icon(Icons.local_hospital, color: Colors.deepPurple),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
      items: ['RA', 'OA', 'SpA', 'Other'].map((type) {
        return DropdownMenuItem(value: type, child: Text(type));
      }).toList(),
      onChanged: (value) => setState(() => arthritisType = value!),
      onSaved: (value) => arthritisType = value!,
    );
  }
}