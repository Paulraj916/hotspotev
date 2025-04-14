// NearbyChargersChart.dart
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hotspot/main.dart';
import 'package:hotspot/models/nearby_chargers_model.dart';
import 'package:hotspot/viewmodels/nearby_chargers_viewmodel.dart';

class NearbyChargersChart extends StatelessWidget {
  final NearbyChargersViewModel viewModel;
  final String? selectedStationName;

  const NearbyChargersChart({
    required this.viewModel,
    this.selectedStationName,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (viewModel.isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: HotspotTheme.accentColor,
        ),
      );
    }

    if (viewModel.nearbyChargersResponse == null) {
      return _buildPlaceholderChart();
    }

    final response = viewModel.nearbyChargersResponse!;
    if (response.destination.isEmpty) {
      return Center(
        child: Text(
          'No nearby chargers found.',
          style: TextStyle(
            color: HotspotTheme.textColor,
          ),
        ),
      );
    }

    return _buildNearbyChargersChart(response);
  }

  Widget _buildPlaceholderChart() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.bar_chart,
          size: 64,
          color: HotspotTheme.primaryColor.withOpacity(0.3),
        ),
        const SizedBox(height: 16),
        Text(
          'Select a suggested place above to view nearby chargers',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: HotspotTheme.textColor.withOpacity(0.6),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildNearbyChargersChart(NearbyChargersResponse response) {
    // Sort destinations by distance (ascending)
    final sortedDestinations = [...response.destination]
      ..sort((a, b) => a.distance.compareTo(b.distance));

    final maxY = sortedDestinations.isNotEmpty
        ? sortedDestinations.map((d) => d.distance).reduce(max) + 5
        : 5.0;
        
    // Calculate appropriate width based on number of items
    final chartWidth = max(sortedDestinations.length * 50.0, 300.0);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: SizedBox(
        width: chartWidth,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY + 5,
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) => Text(
                    value.toStringAsFixed(0),
                    style: TextStyle(
                      color: HotspotTheme.textColor,
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
                      final firstWord = (() {
                        final words = charger.locationName.split(' ');
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
                              color: HotspotTheme.textColor,
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
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                tooltipBgColor: HotspotTheme.textColor.withOpacity(0.8),
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final dest = sortedDestinations[group.x.toInt()];
                  return BarTooltipItem(
                    '${dest.locationName}\nDistance: ${dest.distance.toStringAsFixed(2)} km',
                    TextStyle(
                      color: HotspotTheme.backgroundColor,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}