// EVStationStackedBarChart.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hotspot/models/hotspot_model.dart';
import 'package:hotspot/theme/hotspot_theme.dart';

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
        () => {'Type 2': 0, 'CCS2': 0, 'CHAdeMO': 0, 'Other': 0},
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
    if (type == null) return 'Other';
    switch (type) {
      case 'EV_CONNECTOR_TYPE_TYPE_2':
        return 'Type 2';
      case 'EV_CONNECTOR_TYPE_CCS_COMBO_2':
        return 'CCS2';
      case 'EV_CONNECTOR_TYPE_CHADEMO':
        return 'CHAdeMO';
      default:
        return 'Other';
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
      'CCS2': Colors.green,
      'CHAdeMO': Colors.orange,
      'Type 2': Colors.purple,
      'Other': Colors.blue,
    };

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (maxY + 5).toDouble(),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index >= brands.length) return const SizedBox.shrink();

                final brand = brands[index];
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Transform.rotate(
                    angle: -40 * 3.14159 / 180, // less aggressive rotation
                    child: Text(
                      brand,
                      style: TextStyle(
                        fontSize: 11,
                        color: HotspotTheme.backgroundColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: TextStyle(
                  color: HotspotTheme.backgroundColor,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(brands.length, (index) {
          final brand = brands[index];
          final connectorData = data[brand]!;

          double fromY = 0;
          final stackItems = connectorData.entries
              .where((entry) => entry.value > 0)
              .map((entry) {
            final toY = fromY + entry.value;
            final item = BarChartRodStackItem(
              fromY,
              toY,
              connectorColors[entry.key]!,
            );
            fromY = toY;
            return item;
          }).toList();

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: fromY,
                rodStackItems: stackItems,
                width: 18,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
            showingTooltipIndicators: [],
          );
        }),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: HotspotTheme.textColor.withOpacity(0.85),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final brand = brands[group.x.toInt()];
              final connectorData = data[brand]!;
              final totalCount =
                  connectorData.values.reduce((sum, count) => sum + count);

              final details = connectorData.entries
                  .where((entry) => entry.value > 0)
                  .map((entry) => '${entry.key}: ${entry.value}')
                  .join('\n');

              return BarTooltipItem(
                '$brand: $totalCount total\n$details',
                TextStyle(
                  color: HotspotTheme.backgroundColor,
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
