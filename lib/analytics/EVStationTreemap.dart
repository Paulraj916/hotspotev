import 'package:flutter/material.dart';
import 'package:hotspot/main.dart';
import 'package:syncfusion_flutter_treemap/treemap.dart';

class EVStationTreemap extends StatelessWidget {
  final Map<String, int> data;
  const EVStationTreemap({required this.data, super.key});

  @override
  Widget build(BuildContext context) {
    // Check if data is empty
    if (data.isEmpty) {
      // Return a placeholder widget when there's no data
      return Container(
        decoration: BoxDecoration(
          color: HotspotTheme.backgroundGrey,
          border: Border.all(color: const Color.fromARGB(255, 95, 95, 95)!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bar_chart_outlined,
                size: 48,
                color: HotspotTheme.primaryColor.withOpacity(0.7),
              ),
              const SizedBox(height: 16),
              Text(
                'No EV station data available',
                style: TextStyle(
                  color: HotspotTheme.backgroundColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Data will appear here when available',
                style: TextStyle(
                  color: HotspotTheme.backgroundColor.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Proceed with original code for non-empty data
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
                              color: HotspotTheme.textColor,
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
                                    color: HotspotTheme.textColor,
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
                                    color: HotspotTheme.textColor,
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
                                    color: HotspotTheme.textColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  tile.weight.toInt().toString(),
                                  style: TextStyle(
                                    color: HotspotTheme.textColor,
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
        color: HotspotTheme.primaryColor.withOpacity(0.8),
        borderWidth: 1,
        borderColor: HotspotTheme.accentColor,
      ),
    );
  }
}

class BrandData {
  final String brand;
  final int count;
  BrandData({required this.brand, required this.count});
}