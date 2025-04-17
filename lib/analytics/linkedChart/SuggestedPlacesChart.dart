// SuggestedPlacesChart.dart
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hotspot/models/hotspot_model.dart';
import 'package:hotspot/theme/hotspot_theme.dart';

class SuggestedPlacesChart extends StatefulWidget {
  final List<SuggestedHotspot> suggestedStations;
  final Function(int, SuggestedHotspot) onBarSelected;

  const SuggestedPlacesChart({
    required this.suggestedStations,
    required this.onBarSelected,
    super.key,
  });

  @override
  State<SuggestedPlacesChart> createState() => _SuggestedPlacesChartState();
}

class _SuggestedPlacesChartState extends State<SuggestedPlacesChart> {
  int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    // Sort suggested stations by rating
    final sortedSuggested = [...widget.suggestedStations]
      ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));

    final maxY = sortedSuggested.isNotEmpty
        ? sortedSuggested.map((s) => s.rating ?? 0).reduce(max) + 1
        : 5.0;

    // Calculate appropriate width based on number of items
    final chartWidth = max((sortedSuggested.length + 1) * 50.0,
        MediaQuery.of(context).size.width - 64);
    print("---------------$chartWidth");
    return SizedBox(
      height: 300,
      child: Container(
        width: double.infinity,
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
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
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
                  touchCallback:
                      (FlTouchEvent event, BarTouchResponse? response) {
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
                        // widget.onBarSelected(-1, SuggestedHotspot()); // Deselect callback
                      } else {
                        selectedIndex = index;
                        widget.onBarSelected(
                            index, sortedSuggested[index]); // Select callback
                      }
                    });
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
