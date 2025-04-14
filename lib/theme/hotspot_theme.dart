import 'package:flutter/material.dart';

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
