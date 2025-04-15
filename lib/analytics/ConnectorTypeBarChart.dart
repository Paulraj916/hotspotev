import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hotspot/models/hotspot_model.dart';
import 'package:hotspot/main.dart';

class ConnectorTypeBarChart extends StatelessWidget {
  final List<ExistingCharger> evStations;
  final Map<String, int> data;

  ConnectorTypeBarChart({required this.evStations, super.key})
      : data = _countConnectorTypes(evStations);

  static Map<String, int> _countConnectorTypes(
      List<ExistingCharger> evStations) {
    final Map<String, int> connectorCount = {
      'type 2': 0,
      'ccs2': 0,
      'chademo': 0,
      'other': 0,
      '16a or 3pin': 0,
    };

    for (var station in evStations) {
      final type = station.evChargeOptions.type;
      if (type != null) {
        final formattedType = type == 'EV_CONNECTOR_TYPE_TYPE_2'
            ? 'type 2'
            : type == 'EV_CONNECTOR_TYPE_CCS_COMBO_2'
                ? 'ccs2'
                : type == 'EV_CONNECTOR_TYPE_CHADEMO'
                    ? 'chademo'
                    : 'other';
        connectorCount[formattedType] =
            (connectorCount[formattedType] ?? 0) + 1;
      }
    }
    return connectorCount;
  }

  @override
  Widget build(BuildContext context) {
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final types = sortedEntries.map((e) => e.key).toList();
    final counts = sortedEntries.map((e) => e.value).toList();
    final maxY = counts.isNotEmpty ? counts.reduce(max).toDouble() * 1.3 : 5;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (maxY+5).toDouble(),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < types.length) {
                  return Transform.rotate(
                    angle: -45 * 3.14159 / 180,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        types[index],
                        style: TextStyle(
                          fontSize: 12,
                          color: HotspotTheme.backgroundColor, // Apply theme text color
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 40,
            ),
          ),
          leftTitles: AxisTitles(
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
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(
          types.length,
          (index) => BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: counts[index].toDouble(),
                color: Colors.blueAccent,
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: HotspotTheme.textColor.withOpacity(0.8), // Apply theme
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final type = types[group.x.toInt()];
              final count = counts[group.x.toInt()];
              return BarTooltipItem(
                '$type: $count',
                TextStyle(
                  color: HotspotTheme.backgroundColor, // Contrast with tooltip background
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
