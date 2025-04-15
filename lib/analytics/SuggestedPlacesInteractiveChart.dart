// SuggestedPlacesInteractiveChart.dart
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hotspot/models/hotspot_model.dart';
import 'package:hotspot/main.dart';
import 'package:hotspot/models/nearby_chargers_model.dart';
import 'package:hotspot/viewmodels/nearby_chargers_viewmodel.dart';

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
            mainAxisSize: MainAxisSize.min,
            children: [
              // First chart - Suggested Places
              Card(
                color: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildSuggestedPlacesChart(sortedSuggested),
                ),
              ),

              const SizedBox(height: 16),
              
              // Second chart - Nearby Chargers or placeholder
              Card(
                color: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          selectedIndex != null
                              ? 'Nearby Chargers for ${sortedSuggested[selectedIndex!].displayName}'
                              : 'Nearby Chargers',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: HotspotTheme.textColor,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 300,
                        child: selectedIndex != null
                            ? widget.nearbyChargersViewModel.isLoading
                                ? Center(
                                    child: CircularProgressIndicator(
                                      color: HotspotTheme.accentColor,
                                    ),
                                  )
                                : widget.nearbyChargersViewModel.nearbyChargersResponse !=
                                        null
                                    ? _buildNearbyChargersChart()
                                    : Center(
                                        child: Text(
                                          'No nearby chargers data available.',
                                          style: TextStyle(
                                            color: HotspotTheme.textColor,
                                          ),
                                        ),
                                      )
                            : _buildPlaceholderChart(),
                      ),
                    ],
                  ),
                ),
              ),
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

    // Calculate appropriate width based on number of items
    final chartWidth = max(sortedSuggested.length * 50.0, MediaQuery.of(context).size.width - 64);

    return SizedBox(
      height: 300,
      child: SingleChildScrollView(
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
                      value.toString(),
                      style: TextStyle(
                        color: HotspotTheme.backgroundColor,
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
                              color: HotspotTheme.backgroundColor,
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
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                          color: selectedIndex == entry.key ? Colors.amber : Colors.cyan,
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
                  tooltipBgColor: HotspotTheme.textColor.withOpacity(0.8),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final station = sortedSuggested[group.x.toInt()];
                    return BarTooltipItem(
                      '${station.displayName}\nRating: ${station.rating ?? "N/A"}',
                      TextStyle(
                        color: HotspotTheme.backgroundColor,
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
        ),
      ),
    );
  }

  void _fetchNearbyChargers(int index, List<SuggestedHotspot> sortedSuggested) {
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

  Widget _buildPlaceholderChart() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Icon(
          Icons.bar_chart,
          size: 64,
          color: HotspotTheme.primaryColor.withOpacity(0.3),
        ),
        const SizedBox(height: 16),
        Text(
          'Select a suggested place above to view nearby chargers',
          textAlign: TextAlign.start,
          style: TextStyle(
            color: HotspotTheme.textColor.withOpacity(0.6),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildNearbyChargersChart() {
    final response = widget.nearbyChargersViewModel.nearbyChargersResponse!;
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

    // Sort destinations by distance (ascending)
    final sortedDestinations = [...response.destination]
      ..sort((a, b) => a.distance.compareTo(b.distance));

    final maxY = sortedDestinations.isNotEmpty
        ? sortedDestinations.map((d) => d.distance).reduce(max) + 5
        : 5.0;
        
    // Calculate appropriate width based on number of items
    final chartWidth = max(sortedDestinations.length * 50.0, MediaQuery.of(context).size.width - 64);

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
      ),
    );
  }
}