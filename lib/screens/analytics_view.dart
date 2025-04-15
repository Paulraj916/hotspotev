// analytics_view.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hotspot/analytics/ConnectorTypeBarChart.dart';
import 'package:hotspot/analytics/ConnectorTypeBatteryPowerBarChart.dart';
import 'package:hotspot/analytics/EVStationRatingVsReviewChart.dart';
import 'package:hotspot/analytics/EVStationStackedBarChart.dart';
import 'package:hotspot/analytics/EVStationTreemap.dart';
import 'package:hotspot/analytics/NearbyDistanceBarChart.dart';
import 'package:hotspot/analytics/RatingBarChartEV.dart';
import 'package:hotspot/analytics/RatingBarChartSuggested.dart';
import 'package:hotspot/analytics/SuggestedPlacesInteractiveChart.dart';
import 'package:hotspot/analytics/SuggestedRatingVsReviewChart.dart';
import 'package:hotspot/analytics/WeightVsRatingBarChart.dart';
import 'package:hotspot/analytics/linkedChart/NearbyChargersChart.dart';
import 'package:hotspot/analytics/linkedChart/SuggestedPlacesChart.dart';
import 'package:hotspot/models/nearby_chargers_model.dart';
import 'package:provider/provider.dart';
import '../viewmodels/hotspot_viewmodel.dart';
import '../models/hotspot_model.dart';
import '../main.dart';
import '../viewmodels/nearby_chargers_viewmodel.dart';

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
                    height: 450,
                  ),
                  const SizedBox(height: 20),
                  _buildChartContainer(
                    context,
                    title: 'EV Station Brands by Connector Type',
                    chart: EVStationStackedBarChart(evStations: evStations),
                    legendItems: [
                      LegendItem(color: Colors.green, label: 'ccs2'),
                      LegendItem(color: Colors.orange, label: 'chademo'),
                      LegendItem(color: Colors.purple, label: 'type 2'),
                      LegendItem(color: Colors.blue, label: 'other'),
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
                  _buildChartContainer(context,
                      title: 'Score vs Rating (Suggested)',
                      chart: WeightVsRatingBarChart(
                        suggestedStations: suggestedStations,
                      ),
                      legendItems: [
                        LegendItem(color: Colors.cyan, label: 'Total Weight'),
                        LegendItem(color: Colors.blue, label: 'Rating'),
                      ],
                      height: 380),
                  const SizedBox(height: 20),
                  _buildChartContainer(context,
                      title:
                          'Nearby Distance (km) Between Suggested and Existing Chargers',
                      chart: NearbyDistanceBarChart(
                        suggestedStations: suggestedStations,
                      ),
                      legendItems: [
                        LegendItem(color: Colors.red, label: 'Distance (km)'),
                      ],
                      height: 450),
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
                    title: 'Suggested Places (Click to See Nearby Chargers)',
                    chart: SuggestedPlacesChart(
                      suggestedStations: suggestedStations,
                      onBarSelected: (index, station) {
                        if (index >= 0) {
                          // Fetch nearby chargers
                          final source = Source(
                            latitude: station.lat ?? 0.0,
                            longitude: station.lng ?? 0.0,
                            locationName: station.displayName,
                          );
                          nearbyChargersViewModel.fetchNearbyChargers(
                            source: source,
                            evChargers: evStations,
                          );
                        } else {
                          // Clear selection
                          nearbyChargersViewModel.clear();
                        }
                      },
                    ),
                    legendItems: [
                      LegendItem(color: Colors.cyan, label: 'Suggested Place'),
                      LegendItem(color: Colors.amber, label: 'Selected Place'),
                    ],
                    height: 350,
                  ),
                  const SizedBox(height: 20),
                  _buildChartContainer(
                    context,
                    title: 'Nearby Chargers for Selected Place',
                    chart: NearbyChargersChart(
                      viewModel: nearbyChargersViewModel,
                      selectedStationName: nearbyChargersViewModel
                          .nearbyChargersResponse?.source.locationName,
                    ),
                    legendItems: [
                      LegendItem(color: Colors.purple, label: 'Nearby Charger'),
                    ],
                    height: 350,
                  ),
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
              color: HotspotTheme.backgroundColor, // Apply theme text color
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            color: HotspotTheme.backgroundGrey, // Change card color to grey
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
      final data = chart.countStationsByBrandAndConnector();
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
        color:
            HotspotTheme.textColor.withOpacity(0.8), // Apply theme background
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
                      color: HotspotTheme
                          .buttonTextColor, // Apply theme text color
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

class LegendItem {
  final Color color;
  final String label;
  LegendItem({required this.color, required this.label});
}
