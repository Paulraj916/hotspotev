import 'package:flutter/material.dart';

class HotspotTheme {
  static const Color primaryColor = Color.fromARGB(255,247,207,88); // Main theme color
  static const Color textColor = Colors.black87;
  static const Color secondaryTextColor = Colors.black54;
  static const Color accentColor = Color.fromARGB(255,247,207,88); // For ratings
  static const Color backgroundColor = Colors.white;
  static const Color buttonTextColor = Colors.white;
  static const Color backgroundGrey =  Color.fromARGB(255, 56, 56, 56);
  // Color.fromARGB(199, 247, 207, 88),

  // Marker-specific colors
  static const Color chargerColor = Color.fromARGB(255, 22, 119, 255); // Fixed color for EV chargers
  static const Color hotspotHighScoreColor = Color.fromARGB(255, 82, 196, 26); // Score >= 7
  static const Color hotspotMediumScoreColor = Color.fromARGB(255, 250, 173, 20); // Score >= 4
  static const Color hotspotLowScoreColor = Color.fromARGB(255, 255, 77, 79); // Score < 4
  static const Color selectedMarkerColor = Colors.blue; // Selected location marker
}