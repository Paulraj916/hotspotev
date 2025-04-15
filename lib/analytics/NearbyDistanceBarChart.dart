import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hotspot/models/hotspot_model.dart';
import 'package:hotspot/main.dart';

class NearbyDistanceBarChart extends StatelessWidget {
  final List<SuggestedHotspot> suggestedStations;
  const NearbyDistanceBarChart({required this.suggestedStations, super.key});

  @override
  Widget build(BuildContext context) {
    final sortedStations = suggestedStations
        .where((s) =>
            s.nearestChargeStationDetail != null &&
            s.nearestChargeStationDetail!.isNotEmpty)
        .toList()
      ..sort((a, b) => a.nearestChargeStationDetail!.first.distance
          .compareTo(b.nearestChargeStationDetail!.first.distance));

    final maxY = sortedStations.isNotEmpty
        ? sortedStations
                .map((s) =>
                    s.nearestChargeStationDetail!.first.distance.toDouble())
                .reduce(max) *
            1.3
        : 5;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (maxY + 5).toDouble(),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < sortedStations.length) {
                  final words = sortedStations[index].displayName.split(' ');
                  final firstWord = words.isNotEmpty ? words[0] : '';
                  final secondWord = words.length > 1
                      ? words[1].substring(0, words[1].length.clamp(0, 12))
                      : '';
                  final label = '$firstWord\n$secondWord';

                  return Transform.rotate(
                    angle: -50 * 3.14159 / 180,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          color: HotspotTheme.backgroundColor,
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
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                (value/1000).toString(),
                style: TextStyle(
                  color: HotspotTheme.backgroundColor, // Apply theme text color
                  fontSize: 12,
                ),
              ),
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: sortedStations
            .asMap()
            .entries
            .map(
              (entry) => BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: entry.value.nearestChargeStationDetail!.first.distance
                        .toDouble(),
                    color: Colors.red,
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
              final station = sortedStations[group.x.toInt()];
              return BarTooltipItem(
                '${station.displayName}\nDistance: ${((station.nearestChargeStationDetail!.first.distance)/1000).toStringAsFixed(2)} km',
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
