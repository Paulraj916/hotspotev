// Rating vs. Normalized Review Count for EV Stations
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hotspot/models/hotspot_model.dart';
import 'package:hotspot/main.dart';

class EVStationRatingVsReviewChart extends StatelessWidget {
  final List<ExistingCharger> evStations;

  const EVStationRatingVsReviewChart({required this.evStations, super.key});

  @override
  Widget build(BuildContext context) {
    final sortedStations = [...evStations]
      ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));

    final maxRating = sortedStations.isNotEmpty
        ? sortedStations.map((s) => s.rating ?? 0).reduce(max) + 1
        : 5.0;

    final maxReviewCount = sortedStations.isNotEmpty
        ? sortedStations.map((s) => s.userRatingCount ?? 0).reduce(max) + 1
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
                    color: HotspotTheme.textColor, // Apply theme text color
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
                  if (index < sortedStations.length) {
                    final firstWord = (() {
                      final words =
                          sortedStations[index].displayName.split(' ');
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
                                .textColor, // Apply theme text color
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
          barGroups: sortedStations.asMap().entries.map((entry) {
            final station = entry.value;

            final normalizedReviewCount =
                station.userRatingCount != null && station.userRatingCount! > 0
                    ? min((station.userRatingCount! / maxReviewCount) * 5, 5.0)
                    : 0.0;

            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: station.rating ?? 0,
                  color: Colors.purple,
                  width: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
                BarChartRodData(
                  toY: normalizedReviewCount,
                  color: Colors.purpleAccent,
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
                final station = sortedStations[group.x.toInt()];
                final String metricName =
                    rodIndex == 0 ? 'Rating' : 'Review Count';
                final dynamic value = rodIndex == 0
                    ? (station.rating ?? 'N/A')
                    : (station.userRatingCount ?? 'N/A');

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
