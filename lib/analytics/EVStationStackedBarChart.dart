// EVStationStackedBarChart.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hotspot/hotspot_model.dart';
import 'package:hotspot/main.dart';

class EVStationStackedBarChart extends StatelessWidget {
  final List<ExistingCharger> evStations;

  const EVStationStackedBarChart({required this.evStations, super.key});

  Map<String, Map<String, int>> countStationsByBrandAndConnector() {
    final Map<String, Map<String, int>> brandConnectorCount = {};

    for (var station in evStations) {
      if (station.displayName.isEmpty) continue;

      final brand = station.displayName.split(" ").first;
      final connectorType = _formatConnectorType(station.evChargeOptions.type);

      brandConnectorCount.putIfAbsent(
        brand,
        () => {'type 2': 0, 'ccs2': 0, 'chademo': 0, 'other': 0},
      );
      brandConnectorCount[brand]![connectorType] =
          (brandConnectorCount[brand]![connectorType] ?? 0) + 1;
    }

    final sortedEntries = brandConnectorCount.entries.toList()
      ..sort((a, b) {
        final totalA = a.value.values.reduce((sum, count) => sum + count);
        final totalB = b.value.values.reduce((sum, count) => sum + count);
        return totalB.compareTo(totalA);
      });

    return Map.fromEntries(sortedEntries);
  }

  String _formatConnectorType(String? type) {
    if (type == null) return 'other';
    switch (type) {
      case 'EV_CONNECTOR_TYPE_TYPE_2':
        return 'type 2';
      case 'EV_CONNECTOR_TYPE_CCS_COMBO_2':
        return 'ccs2';
      case 'EV_CONNECTOR_TYPE_CHADEMO':
        return 'chademo';
      default:
        return 'other';
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = countStationsByBrandAndConnector();
    final brands = data.keys.toList();

    int maxY = 0;
    for (var brandData in data.values) {
      final total = brandData.values.reduce((sum, count) => sum + count);
      if (total > maxY) maxY = total;
    }

    final connectorColors = {
      'ccs2': Colors.green,
      'chademo': Colors.orange,
      'type 2': Colors.purple,
      'other': Colors.blue,
    };

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (maxY + 5).toDouble(),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index < brands.length) {
                  return Transform.rotate(
                    angle: -30 * 3.14159 / 180,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 15.0),
                      child: Text(
                        (() {
                          final words = brands[index].split(' ');
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
                              HotspotTheme.textColor,
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
        barGroups: List.generate(brands.length, (index) {
          final brand = brands[index];
          final connectorData = data[brand]!;
          final connectorTypes = connectorData.keys.toList();

          double fromY = 0;
          List<BarChartRodStackItem> stackItems = [];

          for (var type in connectorTypes) {
            final count = connectorData[type]!;
            if (count > 0) {
              final toY = fromY + count;
              stackItems.add(
                BarChartRodStackItem(fromY, toY, connectorColors[type]!),
              );
              fromY = toY;
            }
          }

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: fromY,
                rodStackItems: stackItems,
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
            showingTooltipIndicators: [],
          );
        }),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor:
                HotspotTheme.textColor.withOpacity(0.8), // Apply theme
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final brand = brands[group.x.toInt()];
              final connectorData = data[brand]!;
              final totalCount =
                  connectorData.values.reduce((sum, count) => sum + count);

              String details = '';
              connectorData.forEach((type, count) {
                if (count > 0) details += '$type: $count\n';
              });

              return BarTooltipItem(
                '$brand: $totalCount total\n$details',
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
