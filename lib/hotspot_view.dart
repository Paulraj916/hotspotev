// hotspot_view.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hotspot/analytics_view.dart';
import 'package:hotspot/hotspot_model.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'hotspot_viewmodel.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

// Custom Theme Data
class HotspotTheme {
  static const Color primaryColor = Color.fromARGB(255, 81, 60, 221); // Main theme color
  static const Color textColor = Colors.black87;
  static const Color secondaryTextColor = Colors.black54;
  static const Color accentColor = Colors.amber; // For ratings
  static const Color backgroundColor = Colors.white;
  static const Color buttonTextColor = Colors.white;
}

class HotspotMapScreen extends StatefulWidget {
  const HotspotMapScreen({super.key});

  @override
  State<HotspotMapScreen> createState() => _HotspotMapScreenState();
}

class _HotspotMapScreenState extends State<HotspotMapScreen> with TickerProviderStateMixin {
  Completer<GoogleMapController>? _controller;
  MapType _mapType = MapType.normal;
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(11.060068, 77.004443),
    zoom: 10,
    tilt: 0,
    bearing: 0,
  );

  final String _sessionToken = const Uuid().v4();
  List<dynamic> _placeSuggestions = [];

  @override
  void initState() {
    super.initState();
    _controller = Completer<GoogleMapController>();
    _searchController.addListener(_onSearchChanged);
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _enable3DBuildings();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _tabController.dispose();
    _controller = null;
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchController.text.isNotEmpty) {
      _fetchPlaceSuggestions(_searchController.text);
    } else {
      setState(() {
        _placeSuggestions = [];
      });
    }
  }

  Future<void> _enable3DBuildings() async {
    final controller = await _controller?.future;
    if (controller != null) {
      await controller.setMapStyle('''
      [
        {
          "featureType": "all",
          "elementType": "all",
          "stylers": [
            { "visibility": "on" }
          ]
        },
        {
          "featureType": "administrative",
          "elementType": "labels.text.fill",
          "stylers": [
            { "color": "#444444" }
          ]
        }
      ]
    ''');
    }
  }

  Future<void> _fetchPlaceSuggestions(String input) async {
    try {
      final viewModel = context.read<HotspotViewModel>();
      final suggestions =
          await viewModel.fetchPlaceSuggestions(input, _sessionToken);
      setState(() {
        _placeSuggestions = suggestions;
      });
    } catch (e) {
      print('Error fetching suggestions: $e');
    }
  }

  Future<void> _selectPlace(String placeId) async {
    try {
      final viewModel = context.read<HotspotViewModel>();
      await viewModel.selectPlace(placeId, _sessionToken);

      final controller = await _controller?.future;
      controller?.animateCamera(
          CameraUpdate.newLatLngZoom(viewModel.selectedLocation!, 12));

      setState(() {
        _searchController.clear();
        _placeSuggestions = [];
      });
    } catch (e) {
      print('Error fetching place details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load location: $e')),
      );
    }
  }

  void _toggleMapType() {
    setState(() {
      _mapType =
          _mapType == MapType.normal ? MapType.satellite : MapType.normal;
    });
  }

void _showSuggestedListDialog(HotspotViewModel viewModel) {
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
              color: HotspotTheme.backgroundColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  color: HotspotTheme.primaryColor,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: HotspotTheme.buttonTextColor,
                    unselectedLabelColor:
                        HotspotTheme.buttonTextColor.withOpacity(0.7),
                    indicatorColor: HotspotTheme.buttonTextColor,
                    tabs: [
                      Tab(
                        text:
                            'Hotspots (${viewModel.getFilteredSuggestedHotspots().length})',
                      ),
                      Tab(
                        text:
                            'EV Stations (${viewModel.getFilteredEVStations().length})',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      ListView.builder(
                        controller: scrollController,
                        itemCount: viewModel.getFilteredSuggestedHotspots().length,
                        itemBuilder: (context, index) {
                          final hotspot =
                              viewModel.getFilteredSuggestedHotspots()[index];
                          return ListTile(
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    hotspot.displayName,
                                    style: const TextStyle(
                                        color: HotspotTheme.primaryColor),
                                    overflow: TextOverflow.visible,
                                    softWrap: true,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  hotspot.isExistingChargeStationFound
                                      ? Icons.ev_station_outlined
                                      : Icons.ev_station,
                                  color: hotspot.isExistingChargeStationFound
                                      ? Colors.red
                                      : Colors.green,
                                  size: 20,
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'Score: ',
                                      style: TextStyle(
                                          color: HotspotTheme.secondaryTextColor),
                                    ),
                                    Expanded(
                                      child: LinearProgressIndicator(
                                        value: (hotspot.totalWeight ?? 0) / 10,
                                        backgroundColor: Colors.grey[300],
                                        color: HotspotTheme.primaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${hotspot.totalWeight?.toStringAsFixed(1) ?? 'N/A'}',
                                      style: const TextStyle(
                                          color: HotspotTheme.secondaryTextColor),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Text(
                                      'Rating: ',
                                      style: TextStyle(
                                          color: HotspotTheme.secondaryTextColor),
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
                                Text(
                                  'Address: ${hotspot.formattedAddress}',
                                  style: const TextStyle(
                                      color: HotspotTheme.secondaryTextColor),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _showSuggestedDetailsDialog(hotspot);
                            },
                          );
                        },
                      ),
                      ListView.builder(
                        controller: scrollController,
                        itemCount: viewModel.getFilteredEVStations().length,
                        itemBuilder: (context, index) {
                          final charger =
                              viewModel.getFilteredEVStations()[index];
                          return ListTile(
                            title: Text(
                              charger.displayName,
                              style:
                                  const TextStyle(color: HotspotTheme.primaryColor),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'Rating: ',
                                      style: TextStyle(
                                          color: HotspotTheme.secondaryTextColor),
                                    ),
                                    RatingBarIndicator(
                                      rating: charger.rating ?? 0,
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
                                Text(
                                  'Address: ${charger.formattedAddress}',
                                  style: const TextStyle(
                                      color: HotspotTheme.secondaryTextColor),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _showEVStationDetailsDialog(charger);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
  void _showSuggestedDetailsDialog(SuggestedHotspot hotspot) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            hotspot.displayName,
            style: const TextStyle(
                color: HotspotTheme.primaryColor, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow('Name', hotspot.displayName),
                  _buildDetailRow('Address', hotspot.formattedAddress),
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
                  _buildDetailRow(
                      'User Rating Count', hotspot.userRatingCount.toString()),
                  Row(
                    children: [
                      const Text(
                        'Score: ',
                        style: TextStyle(
                          color: HotspotTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: (hotspot.totalWeight ?? 0) / 10,
                          backgroundColor: Colors.grey[300],
                          color: HotspotTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        hotspot.totalWeight?.toStringAsFixed(1) ?? 'N/A',
                        style: const TextStyle(color: HotspotTheme.textColor),
                      ),
                    ],
                  ),
                  _buildDetailRow('Types', hotspot.types.join(', ')),
                  GestureDetector(
                    onTap: () => _launchUrl(hotspot.googleMapsUri),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        'Google Maps Link',
                        style: TextStyle(
                          color: Colors.blue,
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
                                style:
                                    const TextStyle(color: HotspotTheme.textColor),
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
                          return const Center(child: CircularProgressIndicator());
                        }
                        final loadResults = snapshot.data!;
                        final hasValidImage =
                            loadResults.any((success) => success);

                        if (hotspot.photo.isEmpty || !hasValidImage) {
                          return const Center(
                            child: Text(
                              'No photos available',
                              style:
                                  TextStyle(color: HotspotTheme.secondaryTextColor),
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
              child: const Text('Close',
                  style: TextStyle(color: HotspotTheme.primaryColor)),
            ),
          ],
        );
      },
    );
  }

  void _showEVStationDetailsDialog(ExistingCharger charger) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            charger.displayName,
            style: const TextStyle(
                color: HotspotTheme.primaryColor, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow('Name', charger.displayName),
                  _buildDetailRow('Address', charger.formattedAddress),
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
                        rating: charger.rating ?? 0,
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
                  _buildDetailRow(
                      'User Rating Count', charger.userRatingCount.toString()),
                  _buildDetailRow('Max Charge Rate',
                      charger.evChargeOptions.maxChargeRate?.toString() ?? 'N/A'),
                  _buildDetailRow('Connector Count',
                      charger.evChargeOptions.connectorCount.toString()),
                  _buildDetailRow('Type', charger.evChargeOptions.type ?? 'N/A'),
                  GestureDetector(
                    onTap: () => _launchUrl(charger.googleMapsUri),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        'Google Maps Link',
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close',
                  style: TextStyle(color: HotspotTheme.primaryColor)),
            ),
          ],
        );
      },
    );
  }

  void _showMarkerDetailsBottomSheet({
    SuggestedHotspot? hotspot,
    ExistingCharger? charger,
  }) {
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
                color: HotspotTheme.backgroundColor,
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            hotspot?.displayName ?? charger!.displayName,
                            style: const TextStyle(
                              color: HotspotTheme.primaryColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close,
                                color: HotspotTheme.primaryColor),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildDetailRow(
                          'Name', hotspot?.displayName ?? charger!.displayName),
                      _buildDetailRow('Address',
                          hotspot?.formattedAddress ?? charger!.formattedAddress),
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
                            rating: hotspot?.rating ?? charger!.rating ?? 0,
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
                      _buildDetailRow(
                        'User Rating Count',
                        (hotspot?.userRatingCount ?? charger!.userRatingCount)
                            .toString(),
                      ),
                      if (hotspot != null) ...[
                        Row(
                          children: [
                            const Text(
                              'Score: ',
                              style: TextStyle(
                                color: HotspotTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Expanded(
                              child: LinearProgressIndicator(
                                value: (hotspot.totalWeight ?? 0) / 10,
                                backgroundColor: Colors.grey[300],
                                color: HotspotTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              hotspot.totalWeight?.toStringAsFixed(1) ?? 'N/A',
                              style: const TextStyle(color: HotspotTheme.textColor),
                            ),
                          ],
                        ),
                        _buildDetailRow('Types', hotspot.types.join(', ')),
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
                                    style:
                                        TextStyle(color: HotspotTheme.primaryColor),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${detail.displayName} (${detail.distance}m away)',
                                      style: const TextStyle(
                                          color: HotspotTheme.textColor),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ],
                      if (charger != null) ...[
                        _buildDetailRow('Max Charge Rate',
                            charger.evChargeOptions.maxChargeRate?.toString() ??
                                'N/A'),
                        _buildDetailRow('Connector Count',
                            charger.evChargeOptions.connectorCount.toString()),
                        _buildDetailRow(
                            'Type', charger.evChargeOptions.type ?? 'N/A'),
                      ],
                      GestureDetector(
                        onTap: () => _launchUrl(
                            hotspot?.googleMapsUri ?? charger!.googleMapsUri),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            'Google Maps Link',
                            style: TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      if (hotspot != null) ...[
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
                                    child: CircularProgressIndicator());
                              }
                              final loadResults = snapshot.data!;
                              final hasValidImage =
                                  loadResults.any((success) => success);

                              if (hotspot.photo.isEmpty || !hasValidImage) {
                                return const Center(
                                  child: Text(
                                    'No photos available',
                                    style: TextStyle(
                                        color: HotspotTheme.secondaryTextColor),
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
                                        errorBuilder:
                                            (context, error, stackTrace) {
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

  void _showFilterBottomSheet(HotspotViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: HotspotTheme.backgroundColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filter Options',
                          style: TextStyle(
                            color: HotspotTheme.primaryColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close,
                              color: HotspotTheme.primaryColor),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('Show Suggested Hotspots',
                          style: TextStyle(color: HotspotTheme.textColor)),
                      value: viewModel.showSuggested,
                      activeColor: HotspotTheme.primaryColor,
                      onChanged: (value) {
                        setState(() {
                          viewModel.toggleShowSuggested(value!);
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Show Existing Chargers',
                          style: TextStyle(color: HotspotTheme.textColor)),
                      value: viewModel.showExisting,
                      activeColor: HotspotTheme.primaryColor,
                      onChanged: (value) {
                        setState(() {
                          viewModel.toggleShowExisting(value!);
                        });
                      },
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Score Range (0-10)',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: HotspotTheme.primaryColor),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(viewModel.scoreRange.start.toStringAsFixed(1),
                              style: const TextStyle(color: HotspotTheme.textColor)),
                          Text(viewModel.scoreRange.end.toStringAsFixed(1),
                              style: const TextStyle(color: HotspotTheme.textColor)),
                        ],
                      ),
                    ),
                    RangeSlider(
                      values: viewModel.scoreRange,
                      min: 0,
                      max: 10,
                      divisions: 10,
                      activeColor: HotspotTheme.primaryColor,
                      labels: RangeLabels(
                        viewModel.scoreRange.start.toStringAsFixed(1),
                        viewModel.scoreRange.end.toStringAsFixed(1),
                      ),
                      onChanged: (values) {
                        setState(() {
                          viewModel.updateScoreRange(values);
                        });
                      },
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Rating Range (0-5)',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: HotspotTheme.primaryColor),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(viewModel.ratingRange.start.toStringAsFixed(1),
                              style: const TextStyle(color: HotspotTheme.textColor)),
                          Text(viewModel.ratingRange.end.toStringAsFixed(1),
                              style: const TextStyle(color: HotspotTheme.textColor)),
                        ],
                      ),
                    ),
                    RangeSlider(
                      values: viewModel.ratingRange,
                      min: 0,
                      max: 5,
                      divisions: 40,
                      activeColor: HotspotTheme.primaryColor,
                      labels: RangeLabels(
                        viewModel.ratingRange.start.toStringAsFixed(1),
                        viewModel.ratingRange.end.toStringAsFixed(1),
                      ),
                      onChanged: (values) {
                        setState(() {
                          viewModel.updateRatingRange(values);
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HotspotTheme.primaryColor,
                          foregroundColor: HotspotTheme.buttonTextColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Apply Filters'),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: HotspotTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: HotspotTheme.textColor),
            ),
          ),
        ],
      ),
    );
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

  Widget _buildLegend(HotspotViewModel viewModel) {
    return Positioned(
      bottom: 20,
      left: 10,
      child: Card(
        color: HotspotTheme.backgroundColor.withOpacity(0.85),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Legend',
                style: TextStyle(
                  color: HotspotTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              _buildLegendItem(Colors.purple, 'EV Stations'),
              _buildLegendItem(Colors.green, 'Score ≥ 7'),
              _buildLegendItem(Colors.yellow, 'Score 4 < 7'),
              _buildLegendItem(Colors.red, 'Score < 4'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: HotspotTheme.textColor),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<HotspotViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.hotspotResponse != null) {
            viewModel.applyFilters(
              onSuggestedTap: (hotspot) => _showMarkerDetailsBottomSheet(hotspot: hotspot),
              onExistingTap: (charger) => _showMarkerDetailsBottomSheet(charger: charger),
            );
          }
      
          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: _initialPosition,
                onMapCreated: (GoogleMapController controller) {
                  if (!_controller!.isCompleted) {
                    _controller!.complete(controller);
                  }
                },
                markers: viewModel.markers,
                circles: viewModel.circles,
                mapType: _mapType,
                onTap: viewModel.onMapTap,
                zoomGesturesEnabled: true,
                scrollGesturesEnabled: true,
                tiltGesturesEnabled: true,
                rotateGesturesEnabled: true,
              ),
              Positioned(
                top: 10,
                left: 7,
                right: 7,
                child: Column(
                  children: [
                    Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: TextField(
                                controller: _searchController,
                                textAlignVertical: TextAlignVertical.center,
                                decoration: const InputDecoration(
                                  hintText: 'Search location...',
                                  border: InputBorder.none,
                                  suffixIcon: Icon(Icons.search,
                                      color: HotspotTheme.primaryColor),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            height: 56,
                            width: 40,
                            decoration: const BoxDecoration(
                              border: Border(
                                left:
                                    BorderSide(color: Colors.grey, width: 0.5),
                              ),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.filter_list,
                                  color: HotspotTheme.primaryColor),
                              onPressed: () =>
                                  _showFilterBottomSheet(viewModel),
                              tooltip: 'Filter options',
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_placeSuggestions.isNotEmpty)
                      Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: GestureDetector(
                                  onTap: () {
                                    // Dismiss the keyboard by unfocusing the TextField
                                    FocusScope.of(context).unfocus();
                                  },
                                  child: TextField(
                                    controller: _searchController,
                                    textAlignVertical: TextAlignVertical.center,
                                    decoration: const InputDecoration(
                                      hintText: 'Search location...',
                                      border: InputBorder.none,
                                      suffixIcon: Icon(Icons.search,
                                          color: HotspotTheme.primaryColor),
                                    ),
                                    onTap: () {
                                      // Prevent the keyboard from reappearing immediately
                                      FocusScope.of(context).unfocus();
                                      // Optional: You can re-focus if you want to allow editing after a second tap
                                      // Future.delayed(Duration(milliseconds: 100), () {
                                      //   FocusScope.of(context).requestFocus(FocusNode());
                                      // });
                                    },
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              height: 56,
                              width: 40,
                              decoration: const BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                      color: Colors.grey, width: 0.5),
                                ),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.filter_list,
                                    color: HotspotTheme.primaryColor),
                                onPressed: () =>
                                    _showFilterBottomSheet(viewModel),
                                tooltip: 'Filter options',
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Positioned(
                bottom: 100,
                right: 7,
                child: FloatingActionButton(
                  heroTag: 'mapType', // Unique tag
                  onPressed: _toggleMapType,
                  mini: true,
                  backgroundColor: HotspotTheme.backgroundColor,
                  child: Icon(
                    _mapType == MapType.normal ? Icons.satellite : Icons.map,
                    color: HotspotTheme.primaryColor,
                  ),
                ),
              ),
              Positioned(
                bottom: 150,
                right: 7,
                child: FloatingActionButton(
                  heroTag: 'list', // Unique tag
                  mini: true,
                  backgroundColor: HotspotTheme.backgroundColor,
                  onPressed: () => _showSuggestedListDialog(viewModel),
                  child:
                      const Icon(Icons.list, color: HotspotTheme.primaryColor),
                ),
              ),
              Positioned(
                bottom: 200,
                right: 7,
                child: FloatingActionButton(
                  heroTag: 'clear', // Unique tag
                  mini: true,
                  backgroundColor: HotspotTheme.backgroundColor,
                  onPressed: () {
                    viewModel.clearSelection();
                  },
                  child: const Icon(Icons.remove_circle_outline,
                      color: HotspotTheme.primaryColor),
                ),
              ),
              Positioned(
                bottom: 250,
                right: 7,
                child: FloatingActionButton(
                  heroTag: 'analytics', // Unique tag
                  mini: true,
                  backgroundColor: HotspotTheme.backgroundColor,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AnalyticsScreen()),
                    );
                  },
                  child: const Icon(Icons.analytics,
                      color: HotspotTheme.primaryColor),
                ),
              ),
              _buildLegend(viewModel),
              if (viewModel.selectedLocation != null)
                Positioned(
                  bottom: 20,
                  left: 7,
                  right: 7,
                  child: Card(
                    color: HotspotTheme.backgroundColor,
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Adjust Radius',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: HotspotTheme.primaryColor,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.clear,
                                    color: HotspotTheme.primaryColor),
                                onPressed:
                                    viewModel.clearSelectionForAdjustRadius,
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text('1 km',
                                  style: TextStyle(color: HotspotTheme.primaryColor)),
                              Expanded(
                                child: Slider(
                                  value: viewModel.radius,
                                  min: 1.0,
                                  max: 50.0,
                                  divisions: 49,
                                  label:
                                      '${viewModel.radius.toStringAsFixed(1)} km',
                                  activeColor: HotspotTheme.primaryColor,
                                  onChanged: viewModel.updateRadius,
                                ),
                              ),
                              const Text('50 km',
                                  style: TextStyle(color: HotspotTheme.primaryColor)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: viewModel.isLoading
                                  ? null
                                  : viewModel.fetchHotspots,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: HotspotTheme.primaryColor,
                                foregroundColor: HotspotTheme.buttonTextColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 3,
                              ),
                              child: viewModel.isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: HotspotTheme.buttonTextColor,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text(
                                      'Generate',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}