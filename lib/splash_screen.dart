import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'hotspot_view.dart';
import 'login_screen.dart';
import 'main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    bool isLoggedIn = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    } catch (e) {
      print('Error accessing SharedPreferences: $e');
      // Default to false if there's an error
      isLoggedIn = false;
    }

    await Future.delayed(const Duration(seconds: 2)); // Simulate splash delay

    if (!mounted) return; // Check if widget is still mounted

    if (isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HotspotMapScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HotspotTheme.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.electric_car,
              size: 100,
              color: HotspotTheme.primaryColor,
            ),
            const SizedBox(height: 20),
            Text(
              'EV Hotspot Finder',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: HotspotTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(HotspotTheme.accentColor),
            ),
          ],
        ),
      ),
    );
  }
}