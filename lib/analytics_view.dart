import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:syncfusion_flutter_treemap/treemap.dart';
import 'hotspot_viewmodel.dart';
import 'hotspot_model.dart';
import 'hotspot_view.dart';
import 'main.dart';
import 'nearby_chargers_viewmodel.dart'; // Import new view model
import 'nearby_chargers_model.dart'; // Import new model

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: HotspotTheme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Analytics',
          style: TextStyle(
            // color: HotspotTheme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: HotspotTheme.textColor,
        foregroundColor: HotspotTheme.primaryColor,
        elevation: 0,
      ),
      backgroundColor: HotspotTheme.textColor, // Apply theme background
      body: Consumer2<HotspotViewModel, NearbyChargersViewModel>(
        builder: (context, viewModel, nearbyChargersViewModel, child) {
          final hotspotResponse = viewModel.hotspotResponse;
          final evStations = hotspotResponse?.existingCharger ?? [];
          final suggestedStations = hotspotResponse?.suggested ?? [];

          if (hotspotResponse == null) {
            return Center(
              child: Text(
                'No data available yet.\nPlease select in finder.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: HotspotTheme.primaryColor, // Apply theme text color
                ),
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
                    title: 'EV Station Brands Treemap',
                    chart: EVStationTreemap(
                      data: countStationsByBrand(evStations),
                    ),
                    legendItems: [],
                    height: 400,
                  ),
                  const SizedBox(height: 20),
                  _buildChartContainer(
                    context,
                    title: 'EV Station Brands by Connector Type',
                    chart: EVStationStackedBarChart(evStations: evStations),
                    legendItems: [
                      LegendItem(color: Colors.blue, label: 'other'),
                      LegendItem(color: Colors.green, label: 'ccs2'),
                      LegendItem(color: Colors.orange, label: 'chademo'),
                      LegendItem(color: Colors.purple, label: 'type 2'),
                    ],
                    height: 350,
                  ),
                  const SizedBox(height: 20),
                  _buildChartContainer(
                    context,
                    title: 'Suggested Stations Ratings',
                    chart: RatingBarChartSuggested(
                      suggestedStations: suggestedStations,
                    ),
                    legendItems: [
                      LegendItem(color: Colors.cyan, label: 'Suggested'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildChartContainer(
                    context,
                    title: 'EV Stations Ratings',
                    chart: RatingBarChartEV(evStations: evStations),
                    legendItems: [
                      LegendItem(color: Colors.purple, label: 'EV Stations'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildChartContainer(
                    context,
                    title: 'Total Weight vs Rating (Suggested)',
                    chart: WeightVsRatingBarChart(
                      suggestedStations: suggestedStations,
                    ),
                    legendItems: [
                      LegendItem(color: Colors.cyan, label: 'Total Weight'),
                      LegendItem(color: Colors.blue, label: 'Rating'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildChartContainer(
                    context,
                    title:
                        'Nearby Distance (m) Between Suggested and Existing Chargers',
                    chart: NearbyDistanceBarChart(
                      suggestedStations: suggestedStations,
                    ),
                    legendItems: [
                      LegendItem(color: Colors.red, label: 'Distance (m)'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildChartContainer(
                    context,
                    title: 'EV Connector Type Count',
                    chart: ConnectorTypeBarChart(evStations: evStations),
                    legendItems: [
                      LegendItem(
                        color: Colors.blueAccent,
                        label: 'Connector Count',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildChartContainer(
                    context,
                    title: 'EV Connector Type vs Peak Power',
                    chart: ConnectorTypeBatteryPowerBarChart(
                      evStations: evStations,
                    ),
                    legendItems: [
                      LegendItem(
                        color: Colors.cyan,
                        label: 'Avg Battery Power (kW)',
                      ),
                      LegendItem(color: Colors.cyanAccent, label: 'Count'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildChartContainer(
                    context,
                    title: 'Rating vs. Review Count (Suggested Places)',
                    chart: SuggestedRatingVsReviewChart(
                      suggestedStations: suggestedStations,
                    ),
                    legendItems: [
                      LegendItem(color: Colors.cyan, label: 'Rating'),
                      LegendItem(
                        color: Colors.cyanAccent,
                        label: 'Normalized \nReview Count',
                      ),
                    ],
                    height: 350,
                  ),
                  const SizedBox(height: 20),
                  _buildChartContainer(
                    context,
                    title: 'Rating vs. Review Count (EV Stations)',
                    chart: EVStationRatingVsReviewChart(
                      evStations: evStations,
                    ),
                    legendItems: [
                      LegendItem(color: Colors.purple, label: 'Rating'),
                      LegendItem(
                        color: Colors.purpleAccent,
                        label: 'Normalized \nReview Count',
                      ),
                    ],
                    height: 350,
                  ),
                  const SizedBox(height: 20),
                  _buildChartContainer(
                    context,
                    title:
                        'Interactive Suggested Places (Click to See Nearby Chargers)',
                    chart: SuggestedPlacesInteractiveChart(
                      suggestedStations: suggestedStations,
                      evStations: evStations,
                      nearbyChargersViewModel: nearbyChargersViewModel,
                    ),
                    legendItems: [
                      LegendItem(color: Colors.cyan, label: 'Suggested Place'),
                      LegendItem(color: Colors.amber, label: 'Selected Place'),
                      LegendItem(color: Colors.purple, label: 'Nearby Charger'),
                    ],
                    height: 700, // Adjusted height for both charts
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChartContainer(
    BuildContext context, {
    required String title,
    required Widget chart,
    List<LegendItem>? legendItems,
    double? height,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              color: HotspotTheme.primaryColor, // Apply theme text color
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            color: Colors.white, // Change card color to grey
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                chart is EVStationTreemap
                    ? Container(
                        height: height ?? 400,
                        width: double.infinity,
                        padding: const EdgeInsets.all(16.0),
                        child: chart,
                      )
                    : Container(
                        height: height ?? 300,
                        width: double.infinity,
                        padding: const EdgeInsets.all(16.0),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: _calculateChartWidth(context, chart),
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

  double _calculateChartWidth(BuildContext context, Widget chart) {
    const double baseBarWidth = 20.0;
    final screenWidth = MediaQuery.of(context).size.width;
    const double fixedBarSpacing = 24.0,
        groupSpacing = 36.0,
        edgePadding = 16.0;
    final minWidth = screenWidth * 0.9;

    if (chart is SuggestedPlacesInteractiveChart) {
      final itemCount = chart.suggestedStations.length;
      return max(
        minWidth,
        (itemCount * baseBarWidth) +
            ((itemCount - 1) * fixedBarSpacing) +
            (2 * edgePadding),
      );
    } else if (chart is SuggestedRatingVsReviewChart) {
      final groupCount = chart.suggestedStations.length;
      return max(
        minWidth,
        (groupCount * 2 * baseBarWidth) +
            (groupCount * fixedBarSpacing) +
            ((groupCount - 1) * groupSpacing) +
            (2 * edgePadding),
      );
    } else if (chart is EVStationRatingVsReviewChart) {
      final groupCount = chart.evStations.length;
      return max(
        minWidth,
        (groupCount * 2 * baseBarWidth) +
            (groupCount * fixedBarSpacing) +
            ((groupCount - 1) * groupSpacing) +
            (2 * edgePadding),
      );
    } else if (chart is EVStationStackedBarChart) {
      final data = chart._countStationsByBrandAndConnector();
      return max(
        minWidth,
        (data.length * baseBarWidth) +
            ((data.length - 1) * fixedBarSpacing) +
            (2 * edgePadding),
      );
    } else if (chart is RatingBarChartSuggested) {
      final totalStations = chart.suggestedStations.length;
      return max(
        minWidth,
        (totalStations * baseBarWidth) +
            ((totalStations - 1) * fixedBarSpacing) +
            (2 * edgePadding),
      );
    } else if (chart is RatingBarChartEV) {
      final totalStations = chart.evStations.length;
      return max(
        minWidth,
        (totalStations * baseBarWidth) +
            ((totalStations - 1) * fixedBarSpacing) +
            (2 * edgePadding),
      );
    } else if (chart is WeightVsRatingBarChart) {
      final groupCount = chart.suggestedStations.length;
      return max(
        minWidth,
        (groupCount * 2 * baseBarWidth) +
            (groupCount * fixedBarSpacing) +
            ((groupCount - 1) * groupSpacing) +
            (2 * edgePadding),
      );
    } else if (chart is NearbyDistanceBarChart) {
      final itemCount = chart.suggestedStations
          .where((s) =>
              s.nearestChargeStationDetail != null &&
              s.nearestChargeStationDetail!.isNotEmpty)
          .length;
      return max(
        minWidth,
        (itemCount * baseBarWidth) +
            ((itemCount - 1) * fixedBarSpacing) +
            (2 * edgePadding),
      );
    } else if (chart is ConnectorTypeBarChart) {
      return max(
        minWidth,
        (chart.data.length * baseBarWidth) +
            ((chart.data.length - 1) * fixedBarSpacing) +
            (2 * edgePadding),
      );
    } else if (chart is ConnectorTypeBatteryPowerBarChart) {
      final groupCount = chart.data.length;
      return max(
        minWidth,
        (groupCount * 2 * baseBarWidth) +
            (groupCount * fixedBarSpacing) +
            ((groupCount - 1) * groupSpacing) +
            (2 * edgePadding),
      );
    } else if (chart is EVStationTreemap) {
      return max(minWidth * 1.5, 600);
    }

    return minWidth;
  }

  Widget _buildLegend(List<LegendItem> items) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: HotspotTheme.backgroundColor.withOpacity(0.8), // Apply theme background
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
                mainAxisSize: MainAxisSize.min,
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
                    style: TextStyle(
                      fontSize: 12,
                      color: HotspotTheme.textColor, // Apply theme text color
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class EVStationStackedBarChart extends StatelessWidget {
  final List<ExistingCharger> evStations;

  const EVStationStackedBarChart({required this.evStations, super.key});

  Map<String, Map<String, int>> _countStationsByBrandAndConnector() {
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
    final data = _countStationsByBrandAndConnector();
    final brands = data.keys.toList();

    int maxY = 0;
    for (var brandData in data.values) {
      final total = brandData.values.reduce((sum, count) => sum + count);
      if (total > maxY) maxY = total;
    }

    final connectorColors = {
      'other': Colors.blue,
      'ccs2': Colors.green,
      'chademo': Colors.orange,
      'type 2': Colors.purple,
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
                        brands[index],
                        style: TextStyle(
                          fontSize: 12,
                          color: HotspotTheme.textColor, // Apply theme text color
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
            tooltipBgColor: HotspotTheme.primaryColor.withOpacity(0.8), // Apply theme
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

class EVStationTreemap extends StatelessWidget {
  final Map<String, int> data;
  const EVStationTreemap({required this.data, super.key});

  @override
  Widget build(BuildContext context) {
    final List<BrandData> brandDataList = data.entries
        .map((entry) => BrandData(brand: entry.key, count: entry.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    final List<Color> colors = [
      Colors.blue[100]!,
      Colors.green[100]!,
      Colors.purple[100]!,
      Colors.cyan[100]!,
      Colors.pink[100]!,
      Colors.yellow[100]!,
      Colors.teal[100]!,
      Colors.orange[100]!,
    ];

    return SfTreemap(
      dataCount: brandDataList.length,
      weightValueMapper: (int index) => brandDataList[index].count.toDouble(),
      levels: [
        TreemapLevel(
          groupMapper: (int index) => brandDataList[index].brand,
          labelBuilder: (BuildContext context, TreemapTile tile) {
            return LayoutBuilder(builder: (context, constraints) {
              final isLargeTile =
                  constraints.maxWidth > 60 && constraints.maxHeight > 40;
              final isTinyTile =
                  constraints.maxWidth < 40 || constraints.maxHeight < 30;

              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: isTinyTile
                      ? FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "${tile.group[0]}: ${tile.weight.toInt()}",
                            style: TextStyle(
                              color: HotspotTheme.textColor, // Apply theme text color
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : isLargeTile
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  tile.group,
                                  style: TextStyle(
                                    color: HotspotTheme.textColor, // Apply theme text color
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  tile.weight.toInt().toString(),
                                  style: TextStyle(
                                    color: HotspotTheme.textColor, // Apply theme text color
                                    fontSize: 11,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  tile.group.length > 6
                                      ? '${tile.group.substring(0, 4)}..'
                                      : tile.group,
                                  style: TextStyle(
                                    color: HotspotTheme.textColor, // Apply theme text color
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  tile.weight.toInt().toString(),
                                  style: TextStyle(
                                    color: HotspotTheme.textColor, // Apply theme text color
                                    fontSize: 9,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                ),
              );
            });
          },
          colorValueMapper: (TreemapTile tile) {
            final index =
                brandDataList.indexWhere((data) => data.brand == tile.group);
            return colors[index % colors.length];
          },
        ),
      ],
      tooltipSettings: TreemapTooltipSettings(
        color: HotspotTheme.primaryColor.withOpacity(0.8), // Apply theme
        borderWidth: 1,
        borderColor: HotspotTheme.accentColor, // Apply theme
      ),
    );
  }
}

class BrandData {
  final String brand;
  final int count;
  BrandData({required this.brand, required this.count});
}

class RatingBarChartSuggested extends StatelessWidget {
  final List<SuggestedHotspot> suggestedStations;
  const RatingBarChartSuggested({required this.suggestedStations, super.key});

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
        maxY: (maxY+5).toDouble(),
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
                      style: TextStyle(
                        fontSize: 12,
                        color: HotspotTheme.textColor, // Apply theme text color
                      ),
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
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: sortedSuggested
            .asMap()
            .entries
            .map(
              (entry) => BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: entry.value.rating ?? 0,
                    color: Colors.cyan,
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
            tooltipBgColor: HotspotTheme.primaryColor.withOpacity(0.8), // Apply theme
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final station = sortedSuggested[group.x.toInt()];
              return BarTooltipItem(
                '${station.displayName}\nRating: ${station.rating ?? "N/A"}',
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

class RatingBarChartEV extends StatelessWidget {
  final List<ExistingCharger> evStations;
  const RatingBarChartEV({required this.evStations, super.key});

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
        maxY: (maxY+5).toDouble(),
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
                      style: TextStyle(
                        fontSize: 12,
                        color: HotspotTheme.textColor, // Apply theme text color
                      ),
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
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: sortedEV
            .asMap()
            .entries
            .map(
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
            )
            .toList(),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: HotspotTheme.primaryColor.withOpacity(0.8), // Apply theme
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final station = sortedEV[group.x.toInt()];
              return BarTooltipItem(
                '${station.displayName}\nRating: ${station.rating ?? "N/A"}',
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
        maxY: maxValue.toDouble() + 2,
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
                        suggestedStations[index ~/ 2]
                            .displayName
                            .split(' ')
                            .first,
                        style: TextStyle(
                          fontSize: 12,
                          color: HotspotTheme.textColor, // Apply theme text color
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
            tooltipBgColor: HotspotTheme.primaryColor.withOpacity(0.8), // Apply theme
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final station = suggestedStations[group.x.toInt() ~/ 2];
              final metric = rodIndex == 0 ? 'Total Weight' : 'Rating';
              final value = rodIndex == 0
                  ? (station.totalWeight ?? 'N/A')
                  : (station.rating ?? 'N/A');
              return BarTooltipItem(
                '${station.displayName}\n$metric: $value',
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
      ..sort((a, b) => b.nearestChargeStationDetail!.first.distance
          .compareTo(a.nearestChargeStationDetail!.first.distance));

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
        maxY: (maxY+5).toDouble(),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < sortedStations.length) {
                  return Transform.rotate(
                    angle: -45 * 3.14159 / 180,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Text(
                        sortedStations[index].displayName.split(' ').first,
                        style: TextStyle(
                          fontSize: 12,
                          color: HotspotTheme.textColor, // Apply theme text color
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
            tooltipBgColor: HotspotTheme.primaryColor.withOpacity(0.8), // Apply theme
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final station = sortedStations[group.x.toInt()];
              return BarTooltipItem(
                '${station.displayName}\nDistance: ${station.nearestChargeStationDetail!.first.distance.toStringAsFixed(2)} m',
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
                          color: HotspotTheme.textColor, // Apply theme text color
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
            tooltipBgColor: HotspotTheme.primaryColor.withOpacity(0.8), // Apply theme
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
                        types[index ~/ 2],
                        style: TextStyle(
                          fontSize: 12,
                          color: HotspotTheme.textColor, // Apply theme text color
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
            tooltipBgColor: HotspotTheme.primaryColor.withOpacity(0.8), // Apply theme
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

class LegendItem {
  final Color color;
  final String label;
  LegendItem({required this.color, required this.label});
}

class SuggestedPlacesInteractiveChart extends StatefulWidget {
  final List<SuggestedHotspot> suggestedStations;
  final List<ExistingCharger> evStations;
  final NearbyChargersViewModel nearbyChargersViewModel;

  const SuggestedPlacesInteractiveChart({
    required this.suggestedStations,
    required this.evStations,
    required this.nearbyChargersViewModel,
    super.key,
  });

  @override
  State<SuggestedPlacesInteractiveChart> createState() =>
      _SuggestedPlacesInteractiveChartState();
}

class _SuggestedPlacesInteractiveChartState
    extends State<SuggestedPlacesInteractiveChart> {
  int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    // Create the sorted list here to use across the build method
    final sortedSuggested = [...widget.suggestedStations]
      ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));

    return LayoutBuilder(
      builder: (context, constraints) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.maxHeight,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Use min to avoid unnecessary stretching
            children: [
              // Main chart showing suggested places
              _buildSuggestedPlacesChart(sortedSuggested),

              // Loading indicator or Nearby Chargers chart based on API response
              if (selectedIndex != null) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                  child: Text(
                    'Nearby Chargers for ${sortedSuggested[selectedIndex!].displayName}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: HotspotTheme.textColor, // Apply theme text color
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                widget.nearbyChargersViewModel.isLoading
                    ? Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(
                          color: HotspotTheme.accentColor, // Apply theme accent
                        ),
                      )
                    : widget.nearbyChargersViewModel.nearbyChargersResponse !=
                            null
                        ? _buildNearbyChargersChart()
                        : Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'No nearby chargers data available.',
                              style: TextStyle(
                                color: HotspotTheme.textColor, // Apply theme text color
                              ),
                            ),
                          ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSuggestedPlacesChart(List<SuggestedHotspot> sortedSuggested) {
    final maxY = sortedSuggested.isNotEmpty
        ? sortedSuggested.map((s) => s.rating ?? 0).reduce(max) + 1
        : 5.0;

    return SizedBox(
      height: 300,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY+5,
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
                        style: TextStyle(
                          fontSize: 12,
                          color: HotspotTheme.textColor, // Apply theme text color
                        ),
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
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: sortedSuggested
              .asMap()
              .entries
              .map(
                (entry) => BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.rating ?? 0,
                      color: selectedIndex == entry.key
                          ? Colors.amber
                          : Colors.cyan,
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
              tooltipBgColor: HotspotTheme.primaryColor.withOpacity(0.8), // Apply theme
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final station = sortedSuggested[group.x.toInt()];
                return BarTooltipItem(
                  '${station.displayName}\nRating: ${station.rating ?? "N/A"}',
                  TextStyle(
                    color: HotspotTheme.backgroundColor, // Contrast with tooltip background
                    fontSize: 12,
                  ),
                );
              },
            ),
            touchCallback: (FlTouchEvent event, BarTouchResponse? response) {
              // Only respond to tap up events for smoother interaction
              if (!(event is FlTapUpEvent) ||
                  response == null ||
                  response.spot == null) {
                return;
              }

              final index = response.spot!.touchedBarGroupIndex;
              setState(() {
                if (selectedIndex == index) {
                  // Deselect if tapping the same bar again
                  selectedIndex = null;
                  widget.nearbyChargersViewModel.clear();
                } else {
                  selectedIndex = index;
                  _fetchNearbyChargers(index, sortedSuggested);
                }
              });
            },
          ),
        ),
      ),
    );
  }

  void _fetchNearbyChargers(
      int index, List<SuggestedHotspot> sortedSuggested) {
    final selectedStation = sortedSuggested[index];

    final source = Source(
      latitude: selectedStation.lat ?? 0.0,
      longitude: selectedStation.lng ?? 0.0,
      locationName: selectedStation.displayName,
    );
    final evChargers = widget.evStations;

    widget.nearbyChargersViewModel.fetchNearbyChargers(
      source: source,
      evChargers: evChargers,
    );
  }

  Widget _buildNearbyChargersChart() {
    final response = widget.nearbyChargersViewModel.nearbyChargersResponse!;
    if (response.destination.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'No nearby chargers found.',
          style: TextStyle(
            color: HotspotTheme.textColor, // Apply theme text color
          ),
        ),
      );
    }

    // Sort destinations by distance (ascending)
    final sortedDestinations = [...response.destination]
      ..sort((a, b) => a.distance.compareTo(b.distance));

    final maxY = sortedDestinations.isNotEmpty
        ? sortedDestinations.map((d) => d.distance).reduce(max) + 5
        : 5.0;

    return SizedBox(
      height: 300,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY+5,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Text(
                  value.toStringAsFixed(0),
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
                  if (index < sortedDestinations.length) {
                    final charger = sortedDestinations[index];
                    final firstWord = charger.locationName.split(' ').first;
                    return Transform.rotate(
                      angle: -30 * 3.14159 / 180,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 15.0),
                        child: Text(
                          firstWord,
                          style: TextStyle(
                            fontSize: 12,
                            color: HotspotTheme.textColor, // Apply theme text color
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
                reservedSize: 80,
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: sortedDestinations.asMap().entries.map((entry) {
            final dest = entry.value;
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: dest.distance,
                  color: Colors.purple,
                  width: 20,
                  borderRadius: BorderRadius.circular(4),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY,
                    color: Colors.grey.withOpacity(0.1),
                  ),
                ),
              ],
            );
          }).toList(),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: HotspotTheme.primaryColor.withOpacity(0.8), // Apply theme
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final dest = sortedDestinations[group.x.toInt()];
                return BarTooltipItem(
                  '${dest.locationName}\nDistance: ${dest.distance.toStringAsFixed(2)} km',
                  TextStyle(
                    color: HotspotTheme.backgroundColor, // Contrast with tooltip background
                    fontSize: 12,
                  ),
                );
              },
            ),
            touchCallback: (FlTouchEvent event, BarTouchResponse? response) {
              if (event is FlTapUpEvent &&
                  response != null &&
                  response.spot != null) {
                // Handle tap event if needed
                setState(() {
                  // Your state update logic here if needed
                });
              }
            },
          ),
        ),
      ),
    );
  }
}

// Rating vs. Normalized Review Count for Suggested Places
class SuggestedRatingVsReviewChart extends StatelessWidget {
  final List<SuggestedHotspot> suggestedStations;

  const SuggestedRatingVsReviewChart(
      {required this.suggestedStations, super.key});

  @override
  Widget build(BuildContext context) {
    final sortedSuggested = [...suggestedStations]
      ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));

    final maxRating = sortedSuggested.isNotEmpty
        ? sortedSuggested.map((s) => s.rating ?? 0).reduce(max) + 1
        : 5.0;

    final maxReviewCount = sortedSuggested.isNotEmpty
        ? sortedSuggested.map((s) => s.userRatingCount ?? 0).reduce(max) + 1
        : 5.0;

    return SizedBox(
      height: 350,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxRating > 5 ? maxRating : 5,
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
                  if (index < sortedSuggested.length) {
                    final firstWord =
                        sortedSuggested[index].displayName.split(' ').first;
                    return Transform.rotate(
                      angle: -30 * 3.14159 / 180,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 15.0),
                        child: Text(
                          firstWord,
                          style: TextStyle(
                            fontSize: 12,
                            color: HotspotTheme.textColor, // Apply theme text color
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
                station.userRatingCount != null && station.userRatingCount! > 0
                    ? min((station.userRatingCount! / maxReviewCount) * 5, 5.0)
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
              tooltipBgColor: HotspotTheme.primaryColor.withOpacity(0.8), // Apply theme
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final station = sortedSuggested[group.x.toInt()];
                final String metricName =
                    rodIndex == 0 ? 'Rating' : 'Review Count';
                final dynamic value = rodIndex == 0
                    ? (station.rating ?? 'N/A')
                    : (station.userRatingCount ?? 'N/A');

                return BarTooltipItem(
                  '${station.displayName}\n$metricName: $value',
                  TextStyle(
                    color: HotspotTheme.backgroundColor, // Contrast with tooltip background
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

// Rating vs. Normalized Review Count for EV Stations
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
          maxY: maxRating > 5 ? maxRating : 5,
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
                    final firstWord =
                        sortedStations[index].displayName.split(' ').first;
                    return Transform.rotate(
                      angle: -30 * 3.14159 / 180,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 15.0),
                        child: Text(
                          firstWord,
                          style: TextStyle(
                            fontSize: 12,
                            color: HotspotTheme.textColor, // Apply theme text color
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
              tooltipBgColor: HotspotTheme.primaryColor.withOpacity(0.8), // Apply theme
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
                    color: HotspotTheme.backgroundColor, // Contrast with tooltip background
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