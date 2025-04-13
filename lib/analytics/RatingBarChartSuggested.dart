import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hotspot/hotspot_model.dart';
import 'package:hotspot/main.dart';

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
        maxY: (maxY + 5).toDouble(),
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
                if (index < sortedSuggested.length) {
                  final name = sortedSuggested[index].displayName;
                  final words = name.split(' ');
                  final firstWord = words.isNotEmpty ? words[0] : '';
                  final secondWord = words.length > 1
                      ? words[1].substring(0, words[1].length.clamp(0, 12))
                      : '';
                  final label = '$firstWord\n$secondWord';

                  return Transform.rotate(
                    angle: -45 * 3.14159 / 180,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 15.0),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          color: HotspotTheme.textColor,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  );
                } else {
                  return const SizedBox.shrink();
                }
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
            tooltipBgColor:
                HotspotTheme.textColor.withOpacity(0.8), // Apply theme
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final station = sortedSuggested[group.x.toInt()];
              return BarTooltipItem(
                '${station.displayName}\nRating: ${station.rating ?? "N/A"}',
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
