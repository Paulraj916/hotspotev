import 'dart:async'; // Added for Completer
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:url_launcher/url_launcher.dart';

import '../components/detail_row.dart';
import '../components/detail_row_tags.dart';
import '../models/hotspot_model.dart';
import '../theme/hotspot_theme.dart';

void showSuggestedDetailsDialog(BuildContext context, SuggestedHotspot hotspot) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: HotspotTheme.textColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          hotspot.displayName,
          style: const TextStyle(
            color: HotspotTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                DetailRow(label: 'Address', value: hotspot.formattedAddress),
                Row(
                  children: [
                    const Text(
                      'Rating: ',
                      style: TextStyle(
                        color: HotspotTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    RatingBarIndicator(
                      rating: hotspot.rating ?? 0,
                      itemBuilder: (context, _) => const Icon(
                        Icons.star,
                        color: HotspotTheme.accentColor,
                      ),
                      itemCount: 5,
                      itemSize: 20.0,
                      unratedColor: Colors.grey[300],
                    ),
                  ],
                ),
                DetailRow(
                  label: 'User Rating Count',
                  value: hotspot.userRatingCount.toString(),
                ),
                Row(
                  children: [
                    const Text(
                      'Hotspot Score: ',
                      style: TextStyle(
                        color: HotspotTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: (hotspot.totalWeight ?? 0) / 10,
                        backgroundColor: Colors.grey[300],
                        color: HotspotTheme.accentColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      hotspot.totalWeight?.toStringAsFixed(1) ?? 'N/A',
                      style: const TextStyle(color: HotspotTheme.buttonTextColor),
                    ),
                  ],
                ),
                DetailRowTags(label: 'Types', values: hotspot.types),
                GestureDetector(
                  onTap: () => _launchUrl(context, hotspot.googleMapsUri),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      'Google Maps Link',
                      style: TextStyle(
                        color: HotspotTheme.accentColor,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                if (hotspot.isExistingChargeStationFound &&
                    hotspot.nearestChargeStationDetail != null &&
                    hotspot.nearestChargeStationDetail!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'Nearest Charging Stations:',
                    style: TextStyle(
                      color: HotspotTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ...hotspot.nearestChargeStationDetail!.map((detail) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '• ',
                            style: TextStyle(color: HotspotTheme.primaryColor),
                          ),
                          Expanded(
                            child: Text(
                              '${detail.displayName} (${detail.distance}m away)',
                              style: const TextStyle(
                                  color: HotspotTheme.buttonTextColor),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
                const SizedBox(height: 10),
                const Text(
                  'Photos:',
                  style: TextStyle(
                    color: HotspotTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                  height: 100,
                  child: FutureBuilder<List<bool>>(
                    future: Future.wait(
                      hotspot.photo.map((url) => _checkImage(url)),
                    ),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: HotspotTheme.accentColor,
                          ),
                        );
                      }
                      final loadResults = snapshot.data!;
                      final hasValidImage =
                          loadResults.any((success) => success);

                      if (hotspot.photo.isEmpty || !hasValidImage) {
                        return const Center(
                          child: Text(
                            'No photos available',
                            style: TextStyle(color: HotspotTheme.buttonTextColor),
                          ),
                        );
                      }

                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: hotspot.photo.length,
                        itemBuilder: (context, index) {
                          if (!loadResults[index]) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                hotspot.photo[index],
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: HotspotTheme.primaryColor),
            ),
          ),
        ],
      );
    },
  );
}

Future<void> _launchUrl(BuildContext context, String url) async {
  final Uri uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not launch $url')),
    );
  }
}

Future<bool> _checkImage(String url) async {
  try {
    final completer = Completer<bool>();
    final imageProvider = NetworkImage(url);
    final stream = imageProvider.resolve(const ImageConfiguration());

    stream.addListener(
      ImageStreamListener(
        (info, synchronousCall) {
          completer.complete(true);
        },
        onError: (exception, stackTrace) {
          completer.complete(false);
        },
      ),
    );

    return await completer.future;
  } catch (_) {
    return false;
  }
}