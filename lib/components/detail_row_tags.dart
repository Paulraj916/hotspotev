// detail_row_tags.dart
import 'package:flutter/material.dart';

import '../theme/hotspot_theme.dart';

class DetailRowTags extends StatelessWidget {
  final String label;
  final List<String> values;

  const DetailRowTags({super.key, required this.label, required this.values});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: values.map((type) {
              final formatted = type
                  .split('_')
                  .map((word) =>
                      word[0].toUpperCase() + word.substring(1).toLowerCase())
                  .join(' ');
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: HotspotTheme.primaryColor.withOpacity(0.1),
                  border: Border.all(color: HotspotTheme.primaryColor),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  formatted,
                  style: const TextStyle(
                    color: HotspotTheme.backgroundColor,
                    fontSize: 12,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}