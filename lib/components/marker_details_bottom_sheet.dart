// markers_details_bottom_sheet.dart
import 'dart:async'; // Added for Completer
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:url_launcher/url_launcher.dart';

import '../components/detail_row.dart';
import '../components/detail_row_tags.dart';
import '../models/hotspot_model.dart';
import '../theme/hotspot_theme.dart';

void showMarkerDetailsBottomSheet({
  required BuildContext context,
  SuggestedHotspot? hotspot,
  ExistingCharger? charger,
}) {
  if (hotspot == null && charger == null) return;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: HotspotTheme.textColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(context, hotspot, charger),
                    const SizedBox(height: 10),
                    Text(
                      hotspot?.formattedAddress ?? charger?.formattedAddress ?? 'N/A',
                      style: const TextStyle(
                        color: HotspotTheme.backgroundColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildRatingRow(hotspot, charger),
                    if (hotspot != null) ..._buildHotspotDetails(hotspot),
                    if (charger != null) ..._buildChargerDetails(charger),
                    const SizedBox(height: 10),
                    _buildGoogleMapsLink(context, hotspot, charger),
                    if (hotspot != null) _buildPhotosSection(hotspot),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _buildHeader(
  BuildContext context,
  SuggestedHotspot? hotspot,
  ExistingCharger? charger,
) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Flexible(
        child: Text(
          hotspot?.displayName ?? charger?.displayName ?? '',
          style: const TextStyle(
            color: HotspotTheme.primaryColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      IconButton(
        icon: const Icon(Icons.close, color: HotspotTheme.primaryColor),
        onPressed: () => Navigator.pop(context),
      ),
    ],
  );
}

Widget _buildRatingRow(SuggestedHotspot? hotspot, ExistingCharger? charger) {
  return Row(
    children: [
      RatingBarIndicator(
        rating: hotspot?.rating ?? charger?.rating ?? 0,
        itemBuilder: (context, _) => const Icon(
          Icons.star,
          color: HotspotTheme.accentColor,
        ),
        itemCount: 5,
        itemSize: 20.0,
        unratedColor: Colors.grey[300],
      ),
        Text(
          ' ${hotspot?.rating ?? charger?.rating ?? 0} (${hotspot?.userRatingCount ?? charger?.userRatingCount ?? 0})',
          style: const TextStyle(
            color: HotspotTheme.backgroundColor,
            fontWeight: FontWeight.bold,
          ),
        ),
    ],
  );
}

List<Widget> _buildHotspotDetails(SuggestedHotspot hotspot) {
  return [
    const SizedBox(height: 10),
    Row(
      children: [
        const Text(
          'Score: ',
          style: TextStyle(
            color: HotspotTheme.backgroundColor,
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
      SizedBox(height: 10,),
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
                  style: const TextStyle(color: HotspotTheme.buttonTextColor),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    ],
  ];
}

List<Widget> _buildChargerDetails(ExistingCharger charger) {
  return [
    SizedBox(height: 5,),
    DetailRow(
      label: 'Max Charge Rate',
      value: charger.evChargeOptions.maxChargeRate?.toString() ?? 'N/A',
    ),
    DetailRow(
      label: 'Connector Count',
      value: charger.evChargeOptions.connectorCount.toString(),
    ),
    const SizedBox(height: 10),
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: HotspotTheme.primaryColor.withOpacity(0.1),
            border: Border.all(color: HotspotTheme.primaryColor),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            charger.evChargeOptions.type ?? 'Type: N/A',
            style: const TextStyle(
              color: HotspotTheme.primaryColor,
              fontSize: 12,
            ),
          ),
        ),
      ],
    ),
  ];
}

Widget _buildGoogleMapsLink(
  BuildContext context,
  SuggestedHotspot? hotspot,
  ExistingCharger? charger,
) {
  return GestureDetector(
    onTap: () async {
      final url = hotspot?.googleMapsUri ?? charger?.googleMapsUri ?? '';
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $url')),
        );
      }
    },
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Google Maps Link',
          style: TextStyle(
            color: HotspotTheme.backgroundColor,
            decoration: TextDecoration.underline,
          ),
        ),
        const SizedBox(width: 6),
        Icon(
          Icons.north_east,
          size: 14,
          color: HotspotTheme.accentColor,
        ),
      ],
    ),
  );
}

Widget _buildPhotosSection(SuggestedHotspot hotspot) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
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
            hotspot.photo.map((url) async {
              try {
                final completer = Completer<bool>();
                final imageProvider = NetworkImage(url);
                final stream = imageProvider.resolve(const ImageConfiguration());
                stream.addListener(
                  ImageStreamListener(
                    (info, synchronousCall) => completer.complete(true),
                    onError: (exception, stackTrace) => completer.complete(false),
                  ),
                );
                return await completer.future;
              } catch (_) {
                return false;
              }
            }),
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
            final hasValidImage = loadResults.any((success) => success);

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
                if (!loadResults[index]) return const SizedBox.shrink();
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
  );
}