import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'hotspot_view.dart';
import 'hotspot_viewmodel.dart';
import 'hotspot_repository.dart';
import 'api_client.dart';
import 'splash_screen.dart';
import 'nearby_chargers_viewmodel.dart'; // Import new view model
import 'nearby_chargers_repository.dart'; // Import new repository

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => ApiClient()),
        Provider(create: (context) => HotspotRepository(context.read<ApiClient>())),
        Provider(create: (context) => NearbyChargersRepository(context.read<ApiClient>())),
        ChangeNotifierProvider(
          create: (context) => HotspotViewModel(context.read<HotspotRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => NearbyChargersViewModel(context.read<NearbyChargersRepository>()),
        ),
      ],
      child: MyApp(),
    ),
  );
}

class HotspotTheme {
  static const Color primaryColor = Color.fromARGB(255, 255, 191, 0); // Main theme color
  static const Color textColor = Colors.black87;
  static const Color secondaryTextColor = Colors.black54;
  static const Color accentColor = Colors.amber; // For ratings
  static const Color backgroundColor = Colors.white;
  static const Color buttonTextColor = Colors.white;

  // Marker-specific colors
  static const Color chargerColor = Colors.purple; // Fixed color for EV chargers
  static const Color hotspotHighScoreColor = Colors.green; // Score >= 7
  static const Color hotspotMediumScoreColor = Colors.yellow; // Score >= 4
  static const Color hotspotLowScoreColor = Colors.red; // Score < 4
  static const Color selectedMarkerColor = Colors.blue; // Selected location marker
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black),
      bodyMedium: TextStyle(color: Colors.black54),
    ),
  );

  final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.deepPurple,
    scaffoldBackgroundColor: Colors.black,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.deepPurple,
      foregroundColor: Colors.white,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EV',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const SplashScreen(), // Set SplashScreen as home
    );
  }
}