import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hotspot/hotspot_model.dart';
import 'package:hotspot/main.dart';

class WeightVsRatingBarChart extends StatelessWidget {
  final List<SuggestedHotspot> suggestedStations;
  const WeightVsRatingBarChart({required this.suggestedStations, super.key});

  @override
  Widget build(BuildContext context) {
    final maxValue = suggestedStations.isNotEmpty
        ? suggestedStations
                .map((s) => max((s.totalWeight ?? 0), (s.rating ?? 0)))
                .reduce((a, b) => max(a, b)) +
            1
        : 10;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 13,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
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
                if (index % 2 == 0 && index ~/ 2 < suggestedStations.length) {
                  return Transform.rotate(
                    angle: -30 * 3.14159 / 180,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Text(
                        (() {
                          final words = suggestedStations[index ~/ 2]
                              .displayName
                              .split(' ');
                          final firstWord = words.isNotEmpty ? words[0] : '';
                          final secondWord = words.length > 1
                              ? words[1]
                                  .substring(0, words[1].length.clamp(0, 12))
                              : '';
                          return '$firstWord\n$secondWord';
                        })(),
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              HotspotTheme.textColor, // Apply theme text color
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 60,
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: suggestedStations
            .asMap()
            .entries
            .map(
              (entry) => BarChartGroupData(
                x: entry.key * 2,
                barsSpace: 10,
                barRods: [
                  BarChartRodData(
                    toY: entry.value.totalWeight ?? 0,
                    color: Colors.cyan,
                    width: 20,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  BarChartRodData(
                    toY: entry.value.rating ?? 0,
                    color: Colors.blue,
                    width: 20,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            )
            .toList(),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor:
                HotspotTheme.textColor.withOpacity(0.8), // Apply theme
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final station = suggestedStations[group.x.toInt() ~/ 2];
              final metric = rodIndex == 0 ? 'Total Weight' : 'Rating';
              final value = rodIndex == 0
                  ? (station.totalWeight ?? 'N/A')
                  : (station.rating ?? 'N/A');
              return BarTooltipItem(
                '${station.displayName}\n$metric: $value',
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
    );
  }
}
