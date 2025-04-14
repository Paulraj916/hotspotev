import 'package:flutter/material.dart';

import '../theme/hotspot_theme.dart';

class DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const DetailRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Text(
            '$label: ',
            style: const TextStyle(
              color: HotspotTheme.backgroundColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: HotspotTheme.buttonTextColor),
            ),
          ),
        ],
      ),
    );
  }
}