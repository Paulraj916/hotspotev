import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../components/detail_row.dart';
import '../components/detail_row_tags.dart';
import '../models/hotspot_model.dart';
import '../models/nearby_chargers_model.dart';
import '../theme/hotspot_theme.dart';
import '../viewmodels/hotspot_viewmodel.dart';
import '../viewmodels/nearby_chargers_viewmodel.dart';

void showMarkerDetailsBottomSheet({
  required BuildContext context,
  SuggestedHotspot? hotspot,
  ExistingCharger? charger,
  double? distance,
  String? sourceHotspotName,
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
          return _MarkerDetailsContent(
            hotspot: hotspot,
            charger: charger,
            distance: distance,
            sourceHotspotName: sourceHotspotName,
            scrollController: scrollController,
          );
        },
      );
    },
  );
}

class _MarkerDetailsContent extends StatefulWidget {
  final SuggestedHotspot? hotspot;
  final ExistingCharger? charger;
  final double? distance;
  final String? sourceHotspotName;
  final ScrollController scrollController;

  const _MarkerDetailsContent({
    this.hotspot,
    this.charger,
    this.distance,
    this.sourceHotspotName,
    required this.scrollController,
  });

  @override
  _MarkerDetailsContentState createState() => _MarkerDetailsContentState();
}

class _MarkerDetailsContentState extends State<_MarkerDetailsContent> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 44, 44, 44),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        controller: widget.scrollController,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context, widget.hotspot, widget.charger),
              if (widget.hotspot != null)
                _buildToggle(context, widget.hotspot!),
              const SizedBox(height: 10),
              Text(
                widget.hotspot?.formattedAddress ??
                    widget.charger?.formattedAddress ??
                    'N/A',
                style: const TextStyle(
                  color: HotspotTheme.backgroundColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _buildRatingRow(widget.hotspot, widget.charger),
              if (widget.hotspot != null) ..._buildHotspotDetails(widget.hotspot!),
              if (widget.charger != null)
                ..._buildChargerDetails(
                    widget.charger!, widget.distance, widget.sourceHotspotName),
              const SizedBox(height: 10),
              _buildGoogleMapsLink(context, widget.hotspot, widget.charger),
              if (widget.hotspot != null) _buildPhotosSection(widget.hotspot!),
            ],
          ),
        ),
      ),
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

  Widget _buildToggle(BuildContext context, SuggestedHotspot hotspot) {
    final hotspotViewModel = context.watch<HotspotViewModel>();
    final nearbyChargersViewModel = context.read<NearbyChargersViewModel>();
    final isNearbyMode = hotspotViewModel.isNearbyChargersMode &&
        hotspotViewModel.currentHotspot?.id == hotspot.id;

    return Stack(
      alignment: Alignment.center,
      children: [
        CustomToggleButton(
          isNearbyMode: isNearbyMode,
          onToggle: (value) async {
            if (value) {
              setState(() {
                _isLoading = true;
              });
              try {
                final source = Source(
                  latitude: hotspot.lat ?? 0.0,
                  longitude: hotspot.lng ?? 0.0,
                  locationName: hotspot.displayName,
                );
                final evChargers =
                    hotspotViewModel.hotspotResponse?.existingCharger ?? [];
                await nearbyChargersViewModel.fetchNearbyChargers(
                  source: source,
                  evChargers: evChargers,
                );
                hotspotViewModel.toggleNearbyChargersMode(
                  isEnabled: true,
                  hotspot: hotspot,
                  response: nearbyChargersViewModel.nearbyChargersResponse,
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to fetch nearby chargers: $e')),
                );
              } finally {
                setState(() {
                  _isLoading = false;
                });
              }
            } else {
              hotspotViewModel.toggleNearbyChargersMode(isEnabled: false);
            }
          },
        ),
        if (_isLoading)
          const CircularProgressIndicator(
            color: HotspotTheme.accentColor,
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
            'Hotspot Score: ',
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
        const SizedBox(height: 10),
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

  List<Widget> _buildChargerDetails(
    ExistingCharger charger,
    double? distance,
    String? sourceHotspotName,
  ) {
    return [
      const SizedBox(height: 5),
      DetailRow(
        label: 'Max Charge Rate',
        value: charger.evChargeOptions.maxChargeRate?.toString() ?? 'N/A',
      ),
      DetailRow(
        label: 'Connector Count',
        value: charger.evChargeOptions.connectorCount.toString(),
      ),
      if (distance != null && sourceHotspotName != null) ...[
        const SizedBox(height: 10),
        Text(
          'Distance from $sourceHotspotName: ${distance.toStringAsFixed(2)} km',
          style: const TextStyle(
            color: HotspotTheme.backgroundColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
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
                  final stream =
                      imageProvider.resolve(const ImageConfiguration());
                  stream.addListener(
                    ImageStreamListener(
                      (info, synchronousCall) => completer.complete(true),
                      onError: (exception, stackTrace) =>
                          completer.complete(false),
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
}

// Custom Toggle Button Widget
class CustomToggleButton extends StatelessWidget {
  final bool isNearbyMode;
  final ValueChanged<bool> onToggle;

  const CustomToggleButton({
    super.key,
    required this.isNearbyMode,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: HotspotTheme.backgroundGrey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: HotspotTheme.primaryColor.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: isNearbyMode ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.45,
                height: 46,
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: HotspotTheme.accentColor,
                  borderRadius: BorderRadius.circular(23),
                  boxShadow: [
                    BoxShadow(
                      color: HotspotTheme.accentColor.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => onToggle(false),
                    child: Center(
                      child: Text(
                        'Show All',
                        style: TextStyle(
                          color: isNearbyMode
                              ? HotspotTheme.primaryColor.withOpacity(0.7)
                              : HotspotTheme.textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => onToggle(true),
                    child: Center(
                      child: Text(
                        'Show Nearby',
                        style: TextStyle(
                          color: isNearbyMode
                              ? HotspotTheme.textColor
                              : HotspotTheme.primaryColor.withOpacity(0.7),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}