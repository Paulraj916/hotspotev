import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'hotspot_view.dart';
import '../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

Future<void> _login() async {
  print('Login button pressed.');
  setState(() {
    _isLoading = true;
  });

  const String correctEmail = 'admin@gmail.com';
  const String correctPassword = 'hello123';

  final String email = _emailController.text.trim();
  final String password = _passwordController.text.trim();
  print('Email entered: "$email", Password entered: "$password"');

  if (email == correctEmail && password == correctPassword) {
    print('Credentials match. Attempting to save login state...');
    try {
      final prefs = await SharedPreferences.getInstance();
      print('SharedPreferences instance obtained.');
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userEmail', email); // Save email
      print('Login state saved: isLoggedIn = true, userEmail = $email');

      if (!mounted) {
        print('Widget not mounted, aborting navigation.');
        return;
      }

      print('Navigating to HotspotMapScreen...');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HotspotMapScreen()),
      );
    } catch (e) {
      print('Error with SharedPreferences: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving login state: $e',
              style: TextStyle(color: HotspotTheme.buttonTextColor),
            ),
            backgroundColor: HotspotTheme.hotspotLowScoreColor,
          ),
        );
      }
    }
  } else {
    print('Credentials do not match.');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Invalid email or password',
            style: TextStyle(color: HotspotTheme.buttonTextColor),
          ),
          backgroundColor: HotspotTheme.hotspotLowScoreColor,
        ),
      );
    }
  }

  if (mounted) {
    setState(() {
      _isLoading = false;
    });
  }
}
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HotspotTheme.textColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                Icon(
                  Icons.electric_car,
                  size: 80,
                  color: HotspotTheme.primaryColor,
                ),
                const SizedBox(height: 20),
                Text(
                  'Welcome to EV Hotspot',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: HotspotTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _emailController,
                  style: TextStyle(color: HotspotTheme.buttonTextColor),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: HotspotTheme.buttonTextColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: HotspotTheme.accentColor),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  style: TextStyle(color: HotspotTheme.buttonTextColor),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: HotspotTheme.buttonTextColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: HotspotTheme.accentColor),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HotspotTheme.accentColor,
                      foregroundColor: HotspotTheme.buttonTextColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(
                            color: HotspotTheme.buttonTextColor,
                          )
                        : const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
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