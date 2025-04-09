// analytics_view.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'hotspot_viewmodel.dart';
import 'hotspot_model.dart';
import 'hotspot_view.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: HotspotTheme.primaryColor),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      title: const Text(
        'Analytics',
        style: TextStyle(
          color: HotspotTheme.textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: HotspotTheme.backgroundColor,
      elevation: 0,
    ),
    body: Consumer<HotspotViewModel>(
      builder: (context, viewModel, child) {
        final hotspotResponse = viewModel.hotspotResponse;
        final evStations = hotspotResponse?.existingCharger ?? [];
        final suggestedStations = hotspotResponse?.suggested ?? [];

        if (hotspotResponse == null) {
          return const Center(
            child: Text(
              'No data available yet.\nPlease select in finder.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.black),
            ),
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildChartContainer(
                  context,
                  title: 'EV Station Brands',
                  chart: EVStationBarChart(data: countStationsByBrand(evStations)),
                  legendItems: [LegendItem(color: Colors.blue, label: 'EV Stations')],
                ),
                const SizedBox(height: 20),
                _buildChartContainer(
                  context,
                  title: 'Suggested Stations Ratings',
                  chart: RatingBarChartSuggested(
                      suggestedStations: suggestedStations),
                  legendItems: [
                    LegendItem(color: Colors.cyan, label: 'Suggested'),
                    LegendItem(color: Colors.purple, label: 'EV Stations'),
                  ],
                ),
                const SizedBox(height: 20),
                _buildChartContainer(
                  context,
                  title: 'EV Stations Ratings',
                  chart: RatingBarChartEV(
                       evStations: evStations),
                  legendItems: [
                    LegendItem(color: Colors.cyan, label: 'Suggested'),
                    LegendItem(color: Colors.purple, label: 'EV Stations'),
                  ],
                ),
                const SizedBox(height: 20),
                _buildChartContainer(
                  context,
                  title: 'Total Weight vs Rating (Suggested)',
                  chart: WeightVsRatingBarChart(suggestedStations: suggestedStations),
                  legendItems: [
                    LegendItem(color: Colors.cyan, label: 'Total Weight'),
                    LegendItem(color: Colors.blue, label: 'Rating'),
                  ],
                ),
                const SizedBox(height: 20),
                _buildChartContainer(
                  context,
                  title: 'Nearby Distance (m) Between Suggested and Existing Chargers',
                  chart: NearbyDistanceBarChart(suggestedStations: suggestedStations),
                  legendItems: [LegendItem(color: Colors.red, label: 'Distance (m)')],
                ),
                const SizedBox(height: 20),
                _buildChartContainer(
                  context,
                  title: 'EV Connector Type Count',
                  chart: ConnectorTypeBarChart(evStations: evStations),
                  legendItems: [
                    LegendItem(color: Colors.blueAccent, label: 'Connector Count'),
                  ],
                ),
                const SizedBox(height: 20),
                _buildChartContainer(
                  context,
                  title: 'EV Connector Type vs Peak Power',
                  chart: ConnectorTypeBatteryPowerBarChart(evStations: evStations),
                  legendItems: [
                    LegendItem(color: Colors.cyan, label: 'Avg Battery Power (kW)'),
                    LegendItem(color: Colors.cyanAccent, label: 'Count'),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    ),
  );
}
  Widget _buildChartContainer(BuildContext context,
    {required String title, required Widget chart, List<LegendItem>? legendItems}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
              fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Card(
          color: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Stack(
            children: [
              Container(
                height: 300,
                width: double.infinity, // Full width of the card
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: _calculateChartWidth(context,chart),
                    child: chart,
                  ),
                ),
              ),
              if (legendItems != null && legendItems.isNotEmpty)
                Positioned(
                  top: 8,
                  right: 8,
                  child: _buildLegend(legendItems),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

double _calculateChartWidth(BuildContext context, Widget chart) {
  // Base bar width from BarChartRodData - consistent sizing
  const double baseBarWidth = 20.0;
  
  // Get screen width using the recommended approach
  final screenWidth = MediaQuery.of(context).size.width;
  
  // Fixed spacing between bars for consistent neat appearance
  const double fixedBarSpacing = 24.0; // Consistent spacing between bars
  const double groupSpacing = 36.0;    // Additional spacing between groups for grouped charts
  const double edgePadding = 16.0;     // Padding at the edges
  
  // Min width ensures the chart uses at least 90% of screen
  final minWidth = screenWidth * 0.9;
  
  // Calculate width based on chart type and data - prioritizing consistent spacing
  if (chart is EVStationBarChart) {
    final itemCount = chart.data.length;
    return max(
      minWidth,
      (itemCount * baseBarWidth) + ((itemCount - 1) * fixedBarSpacing) + (2 * edgePadding)
    );
  } else if (chart is RatingBarChartSuggested) {
    final totalStations = chart.suggestedStations.length;
    return max(
      minWidth,
      (totalStations * baseBarWidth) + ((totalStations - 1) * fixedBarSpacing) + (2 * edgePadding)
    );
  }
  else if (chart is RatingBarChartEV) {
    final totalStations = chart.evStations.length;
    return max(
      minWidth,
      (totalStations * baseBarWidth) + ((totalStations - 1) * fixedBarSpacing) + (2 * edgePadding)
    );
  } else if (chart is WeightVsRatingBarChart) {
    final groupCount = chart.suggestedStations.length;
    // Two bars per group with consistent spacing between groups
    return max(
      minWidth,
      (groupCount * 2 * baseBarWidth) + // Two bars per group
      (groupCount * fixedBarSpacing) +  // Spacing within groups
      ((groupCount - 1) * groupSpacing) + // Spacing between groups
      (2 * edgePadding)
    );
  } else if (chart is NearbyDistanceBarChart) {
    final itemCount = chart.suggestedStations
        .where((s) => s.nearestChargeStationDetail != null && s.nearestChargeStationDetail!.isNotEmpty)
        .length;
    return max(
      minWidth,
      (itemCount * baseBarWidth) + ((itemCount - 1) * fixedBarSpacing) + (2 * edgePadding)
    );
  } else if (chart is ConnectorTypeBarChart) {
    final itemCount = chart.data.length;
    return max(
      minWidth,
      (itemCount * baseBarWidth) + ((itemCount - 1) * fixedBarSpacing) + (2 * edgePadding)
    );
  } else if (chart is ConnectorTypeBatteryPowerBarChart) {
    final groupCount = chart.data.length;
    // Two bars per group with consistent spacing between groups
    return max(
      minWidth,
      (groupCount * 2 * baseBarWidth) + // Two bars per group
      (groupCount * fixedBarSpacing) +  // Spacing within groups
      ((groupCount - 1) * groupSpacing) + // Spacing between groups
      (2 * edgePadding)
    );
  }
  
  return minWidth; // Default fallback
}  
  
  Map<String, int> countStationsByBrand(List<ExistingCharger> evStations) {
    final Map<String, int> brandCount = {};
    for (var station in evStations) {
      final name = station.displayName;
      if (name.isNotEmpty) {
        final brand = name.split(" ").first;
        brandCount[brand] = (brandCount[brand] ?? 0) + 1;
      }
    }
    return brandCount;
  }
}

class EVStationBarChart extends StatelessWidget {
  final Map<String, int> data;

  const EVStationBarChart({required this.data, super.key});

  @override
Widget build(BuildContext context) {
  final Map<String, int> sortedData = Map.fromEntries(
    data.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
  );
  final brands = sortedData.keys.toList();
  final counts = sortedData.values.toList();

  return BarChart(
    BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: counts.isNotEmpty
          ? counts.reduce((a, b) => a > b ? a : b).toDouble() + 6
          : 5,
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
                      brands[index],
                      style: const TextStyle(fontSize: 12),
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
          sideTitles: SideTitles(showTitles: true, reservedSize: 40),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      // gridData: FlGridData(show: false),
      barGroups: List.generate(
        brands.length,
        (index) => BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: counts[index].toDouble(),
              color: Colors.blue,
              width: 20,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
          showingTooltipIndicators: [],
        ),
      ),
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          tooltipBgColor: Color.fromARGB(255, 81, 60, 221).withOpacity(0.8),
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final count = counts[group.x.toInt()];
            final fullName = sortedData.keys.toList()[group.x.toInt()];
            return BarTooltipItem(
              '$fullName: $count',
              const TextStyle(color: Colors.white, fontSize: 12),
            );
          },
        ),
      ),
    ),
  );
}}

class RatingBarChartSuggested extends StatelessWidget {
  final List<SuggestedHotspot> suggestedStations;

  const RatingBarChartSuggested({
    required this.suggestedStations,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final sortedSuggested = [...suggestedStations]
      ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));

    final allRatings = sortedSuggested.map((s) => s.rating ?? 0).toList();

    final maxY = allRatings.isNotEmpty
        ? allRatings.reduce((a, b) => a > b ? a : b) + 2
        : 5;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY.toDouble(),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                String label = '';
                if (index < sortedSuggested.length) {
                  label = sortedSuggested[index].displayName;
                }
                final firstWord = label.split(' ').first;
                return Transform.rotate(
                  angle: -30 * 3.14159 / 180,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 15.0),
                    child: Text(
                      firstWord,
                      style: const TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                );
              },
              reservedSize: 80,
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: sortedSuggested.asMap().entries.map(
          (entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.rating ?? 0,
                  color: Colors.cyan,
                  width: 20,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          },
        ).toList(),
      ),
    );
  }
}

class RatingBarChartEV extends StatelessWidget {
  final List<ExistingCharger> evStations;

  const RatingBarChartEV({
    required this.evStations,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final sortedEV = [...evStations]
      ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));

    final allRatings = sortedEV.map((e) => e.rating ?? 0).toList();

    final maxY = allRatings.isNotEmpty
        ? allRatings.reduce((a, b) => a > b ? a : b) + 2
        : 5;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY.toDouble(),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                String label = '';
                if (index < sortedEV.length) {
                  label = sortedEV[index].displayName;
                }
                final firstWord = label.split(' ').first;
                return Transform.rotate(
                  angle: -30 * 3.14159 / 180,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 15.0),
                    child: Text(
                      firstWord,
                      style: const TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                );
              },
              reservedSize: 80,
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: sortedEV.asMap().entries.map(
          (entry) => BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.rating ?? 0,
                color: Colors.purple,
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ).toList(),
      ),
    );
  }
}


class WeightVsRatingBarChart extends StatelessWidget {
  final List<SuggestedHotspot> suggestedStations;

  const WeightVsRatingBarChart({required this.suggestedStations, super.key});

  @override
Widget build(BuildContext context) {
  final maxValue = suggestedStations.isNotEmpty
      ? suggestedStations
              .map((s) => (s.totalWeight ?? 0) > (s.rating ?? 0)
                  ? s.totalWeight ?? 0
                  : s.rating ?? 0)
              .reduce((a, b) => a > b ? a : b) +
          1
      : 10;

  return BarChart(
    BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: maxValue.toDouble() + 2,
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: true, reservedSize: 40),
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
                      suggestedStations[index ~/ 2].displayName.split(' ').first,
                      style: const TextStyle(fontSize: 12),
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
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      barGroups: suggestedStations.asMap().entries.map(
        (entry) {
          final index = entry.key;
          final station = entry.value;
          return BarChartGroupData(
            x: index * 2,
            barsSpace: 10,
            barRods: [
              BarChartRodData(
                toY: station.totalWeight ?? 0,
                color: Colors.cyan,
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
              BarChartRodData(
                toY: station.rating ?? 0,
                color: Colors.blue,
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        },
      ).toList(),
    ),
  );
}}

class NearbyDistanceBarChart extends StatelessWidget {
  final List<SuggestedHotspot> suggestedStations;

  const NearbyDistanceBarChart({required this.suggestedStations, super.key});

  @override
Widget build(BuildContext context) {
  final sortedStations = suggestedStations
      .where((station) =>
          station.nearestChargeStationDetail != null &&
          station.nearestChargeStationDetail!.isNotEmpty)
      .toList()
    ..sort((a, b) => b.nearestChargeStationDetail!.first.distance
        .compareTo(a.nearestChargeStationDetail!.first.distance));

  final distances = sortedStations
      .map((station) => station.nearestChargeStationDetail!.first.distance.toDouble())
      .toList();

  final maxY = distances.isNotEmpty
      ? distances.reduce((a, b) => a > b ? a : b) * 1.3
      : 5;

  return BarChart(
    BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: maxY.toDouble(),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (double value, TitleMeta meta) {
              final index = value.toInt();
              if (index < sortedStations.length) {
                return Transform.rotate(
                  angle: -45 * 3.14159 / 180,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Text(
                      sortedStations[index].displayName.split(' ').first,
                      style: const TextStyle(fontSize: 12),
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
          sideTitles: SideTitles(showTitles: true, reservedSize: 40),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      barGroups: sortedStations.asMap().entries.map((entry) {
        final index = entry.key;
        final station = entry.value;
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: station.nearestChargeStationDetail!.first.distance.toDouble(),
              color: Colors.red,
              width: 20,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        );
      }).toList(),
    ),
  );
}}


class ConnectorTypeBarChart extends StatelessWidget {
  final List<ExistingCharger> evStations;
  final Map<String, int> data;

  ConnectorTypeBarChart({required this.evStations, super.key})
      : data = _countConnectorTypes(evStations);

  static Map<String, int> _countConnectorTypes(List<ExistingCharger> evStations) {
    final Map<String, int> connectorCount = {
      'type 2': 0,
      'ccs2': 0,
      'chademo': 0,
      'other': 0,
      '16a or 3pin': 0, // Placeholder
    };

    for (var station in evStations) {
      final type = station.evChargeOptions.type;
      if (type != null) {
        print("${station.id}: $type");
        String formattedType;
        switch (type) {
          case 'EV_CONNECTOR_TYPE_TYPE_2':
            formattedType = 'type 2';
            break;
          case 'EV_CONNECTOR_TYPE_CCS_COMBO_2':
            formattedType = 'ccs2';
            break;
          case 'EV_CONNECTOR_TYPE_CHADEMO':
            formattedType = 'chademo';
            break;
          default:
            formattedType = 'other';
        }
        connectorCount[formattedType] = (connectorCount[formattedType] ?? 0) + 1;
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

  return BarChart(
    BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: counts.isNotEmpty
          ? counts.reduce((a, b) => a > b ? a : b).toDouble() * 1.3
          : 5,
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (double value, TitleMeta meta) {
              final index = value.toInt();
              if (index < types.length) {
                return Transform.rotate(
                  angle: -45 * 3.14159 / 180,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      types[index],
                      style: const TextStyle(fontSize: 12),
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
          sideTitles: SideTitles(showTitles: true, reservedSize: 40),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
    ),
  );
}}

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
      String formattedType;
      if (type != null) {
        switch (type) {
          case 'EV_CONNECTOR_TYPE_TYPE_2':
            formattedType = 'type 2';
            break;
          case 'EV_CONNECTOR_TYPE_CCS_COMBO_2':
            formattedType = 'ccs2';
            break;
          case 'EV_CONNECTOR_TYPE_CHADEMO':
            formattedType = 'chademo';
            break;
          // case 'EV_CONNECTOR_TYPE_OTHER':
          //   formattedType = 'other';
          //   break;
          default:
            formattedType = 'other';
        }
        connectorPower[formattedType]!.add(power);
      }
    }
    return connectorPower;
  }

  @override
Widget build(BuildContext context) {
  final sortedEntries = data.entries.toList()
    ..sort((a, b) {
      final avgA =
          a.value.isNotEmpty ? a.value.reduce((x, y) => x + y) / a.value.length : 0;
      final avgB =
          b.value.isNotEmpty ? b.value.reduce((x, y) => x + y) / b.value.length : 0;
      return avgB.compareTo(avgA);
    });

  final types = sortedEntries.map((e) => e.key).toList();
  final maxPower = sortedEntries
          .expand((e) => e.value)
          .fold<double>(0, (max, power) => power > max ? power : max) +
      10;

  return BarChart(
    BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: maxPower * 1.2,
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (double value, TitleMeta meta) {
              final index = value.toInt();
              if (index % 2 == 0 && (index ~/ 2) < types.length) {
                return Transform.rotate(
                  angle: -45 * 3.14159 / 180,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 15.0),
                    child: Text(
                      types[index ~/ 2],
                      style: const TextStyle(fontSize: 12),
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
          sideTitles: SideTitles(showTitles: true, reservedSize: 40),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      barGroups: sortedEntries.asMap().entries.map(
        (entry) {
          final index = entry.key;
          final powers = entry.value.value;
          final avgPower =
              powers.isNotEmpty ? powers.reduce((a, b) => a + b) / powers.length : 0;
          final count = powers.length.toDouble();
          return BarChartGroupData(
            x: index * 2,
            barsSpace: 10,
            barRods: [
              BarChartRodData(
                toY: avgPower.toDouble(),
                color: Colors.cyan,
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
              BarChartRodData(
                toY: count,
                color: Colors.cyanAccent,
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        },
      ).toList(),
    ),
  );
}}

// Helper class for legend items
class LegendItem {
  final Color color;
  final String label;

  LegendItem({required this.color, required this.label});
}

Widget _buildLegend(List<LegendItem> items) {
  return Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.8),
      borderRadius: BorderRadius.circular(8),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: item.color,
                    shape: BoxShape.circle,
                  ),
                ),
                Text(
                  item.label,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ],
            ),
          )
          .toList(),
    ),
  );
}
