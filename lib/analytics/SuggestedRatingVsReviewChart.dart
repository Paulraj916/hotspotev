// Rating vs. Normalized Review Count for Suggested Places
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hotspot/models/hotspot_model.dart';
import 'package:hotspot/theme/hotspot_theme.dart';

class SuggestedRatingVsReviewChart extends StatelessWidget {
  final List<SuggestedHotspot> suggestedStations;

  const SuggestedRatingVsReviewChart(
      {required this.suggestedStations, super.key});

  @override
  Widget build(BuildContext context) {
    final sortedSuggested = [...suggestedStations]
      ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));

    // final maxRating = sortedSuggested.isNotEmpty
    //     ? sortedSuggested.map((s) => s.rating ?? 0).reduce(max) + 1
    //     : 5.0;

    final maxReviewCount = sortedSuggested.isNotEmpty
        ? sortedSuggested.map((s) => s.userRatingCount ).reduce(max) + 1
        : 5.0;

    return SizedBox(
      height: 350,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 7.5,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              // axisNameWidget: Text(
              //   'Rating & Normalized Review Count (0-5)',
              //   style: TextStyle(
              //     fontSize: 12,
              //     color: HotspotTheme.textColor, // Apply theme text color
              //   ),
              // ),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Text(
                  value.toString(),
                  style: TextStyle(
                    color: HotspotTheme.backgroundColor, // Apply theme text color
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < sortedSuggested.length) {
                    final firstWord = (() {
                      final words =
                          sortedSuggested[index].displayName.split(' ');
                      final firstWord = words.isNotEmpty ? words[0] : '';
                      final secondWord = words.length > 1
                          ? words[1].substring(0, words[1].length.clamp(0, 12))
                          : '';
                      return '$firstWord\n$secondWord';
                    })();
                    return Transform.rotate(
                      angle: -30 * 3.14159 / 180,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 15.0),
                        child: Text(
                          firstWord,
                          style: TextStyle(
                            fontSize: 12,
                            color: HotspotTheme
                                .backgroundColor, // Apply theme text color
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 40,
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: sortedSuggested.asMap().entries.map((entry) {
            final station = entry.value;

            final normalizedReviewCount =
                station.userRatingCount > 0
                    ? min((station.userRatingCount / maxReviewCount) * 5, 5.0)
                    : 0.0;

            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: station.rating ?? 0,
                  color: Colors.cyan,
                  width: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
                BarChartRodData(
                  toY: normalizedReviewCount,
                  color: Colors.cyanAccent,
                  width: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
              barsSpace: 4,
            );
          }).toList(),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor:
                  HotspotTheme.textColor.withOpacity(0.8), // Apply theme
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final station = sortedSuggested[group.x.toInt()];
                final String metricName =
                    rodIndex == 0 ? 'Rating' : 'Review Count';
                final dynamic value = rodIndex == 0
                    ? (station.rating ?? 'N/A')
                    : (station.userRatingCount );

                return BarTooltipItem(
                  '${station.displayName}\n$metricName: $value',
                  TextStyle(
                    color: HotspotTheme
                        .backgroundColor, // Contrast with tooltip background
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
