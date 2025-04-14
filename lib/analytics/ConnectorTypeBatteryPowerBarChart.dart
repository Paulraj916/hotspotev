import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hotspot/models/hotspot_model.dart';
import 'package:hotspot/main.dart';

class ConnectorTypeBatteryPowerBarChart extends StatelessWidget {
  final List<ExistingCharger> evStations;
  final Map<String, List<double>> data;

  ConnectorTypeBatteryPowerBarChart({required this.evStations, super.key})
      : data = _groupByConnectorTypeAndPower(evStations);

  static Map<String, List<double>> _groupByConnectorTypeAndPower(
      List<ExistingCharger> evStations) {
    final Map<String, List<double>> connectorPower = {
      'type 2': [],
      'ccs2': [],
      'chademo': [],
      'other': [],
      '16a or 3pin': [],
    };

    for (var station in evStations) {
      final type = station.evChargeOptions.type;
      final power = station.evChargeOptions.maxChargeRate?.toDouble() ?? 0;
      if (type != null) {
        final formattedType = type == 'EV_CONNECTOR_TYPE_TYPE_2'
            ? 'type 2'
            : type == 'EV_CONNECTOR_TYPE_CCS_COMBO_2'
                ? 'ccs2'
                : type == 'EV_CONNECTOR_TYPE_CHADEMO'
                    ? 'chademo'
                    : 'other';
        connectorPower[formattedType]!.add(power);
      }
    }
    return connectorPower;
  }

  @override
  Widget build(BuildContext context) {
    final sortedEntries = data.entries.toList()
      ..sort((a, b) {
        final avgA = a.value.isNotEmpty
            ? a.value.reduce((x, y) => x + y) / a.value.length
            : 0;
        final avgB = b.value.isNotEmpty
            ? b.value.reduce((x, y) => x + y) / b.value.length
            : 0;
        return avgB.compareTo(avgA);
      });

    final types = sortedEntries.map((e) => e.key).toList();
    final maxPower =
        sortedEntries.expand((e) => e.value).fold<double>(0, max) + 10;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxPower * 1.2,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index % 2 == 0 && (index ~/ 2) < types.length) {
                  return Transform.rotate(
                    angle: -45 * 3.14159 / 180,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 15.0),
                      child: Text(
                        (() {
                          final words = types[index ~/ 2].split(' ');
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
                value.toString(),
                style: TextStyle(
                  color: HotspotTheme.textColor, // Apply theme text color
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
        barGroups: sortedEntries.asMap().entries.map((entry) {
          final powers = entry.value.value;
          final avgPower = powers.isNotEmpty
              ? powers.reduce((a, b) => a + b) / powers.length
              : 0;
          return BarChartGroupData(
            x: entry.key * 2,
            barsSpace: 10,
            barRods: [
              BarChartRodData(
                toY: avgPower.toDouble(),
                color: Colors.cyan,
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
              BarChartRodData(
                toY: powers.length.toDouble(),
                color: Colors.cyanAccent,
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList(),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor:
                HotspotTheme.textColor.withOpacity(0.8), // Apply theme
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final type = types[group.x.toInt() ~/ 2];
              final powers = data[type]!;
              final avgPower = powers.isNotEmpty
                  ? powers.reduce((a, b) => a + b) / powers.length
                  : 0;
              final metric = rodIndex == 0 ? 'Avg Power (kW)' : 'Count';
              final value =
                  rodIndex == 0 ? avgPower.toStringAsFixed(1) : powers.length;
              return BarTooltipItem(
                '$type\n$metric: $value',
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
