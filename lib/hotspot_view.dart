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
import 'main.dart';
import 'login_screen.dart'; // Import LoginScreen for navigation
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences

class HotspotMapScreen extends StatefulWidget {
  const HotspotMapScreen({super.key});

  @override
  State<HotspotMapScreen> createState() => _HotspotMapScreenState();
}

class _HotspotMapScreenState extends State<HotspotMapScreen>
    with TickerProviderStateMixin {
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
      final viewModel = context.read<HotspotViewModel>();
      viewModel.setTapCallbacks(
        onSuggestedTap: (hotspot) =>
            _showMarkerDetailsBottomSheet(hotspot: hotspot),
        onExistingTap: (charger) =>
            _showMarkerDetailsBottomSheet(charger: charger),
      );
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

  Future<String?> _getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userEmail') ?? 'admin@gmail.com'; // Fallback email
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
      _mapType = _mapType == MapType.normal ? MapType.hybrid : MapType.normal;
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
                color: HotspotTheme.textColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    color: HotspotTheme.primaryColor,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: HotspotTheme.textColor,
                      unselectedLabelColor:
                          HotspotTheme.textColor.withOpacity(0.7),
                      indicatorColor: HotspotTheme.textColor,
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
                          itemCount:
                              viewModel.getFilteredSuggestedHotspots().length,
                          itemBuilder: (context, index) {
                            final hotspot =
                                viewModel.getFilteredSuggestedHotspots()[index];
                            return ListTile(
                              title: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      hotspot.displayName,
                                      style: const TextStyle(
                                        color: HotspotTheme.primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
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
                                            color:
                                                HotspotTheme.buttonTextColor),
                                      ),
                                      Expanded(
                                        child: LinearProgressIndicator(
                                          value:
                                              (hotspot.totalWeight ?? 0) / 10,
                                          backgroundColor: Colors.grey[300],
                                          color: HotspotTheme.accentColor,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${hotspot.totalWeight?.toStringAsFixed(1) ?? 'N/A'}',
                                        style: const TextStyle(
                                            color:
                                                HotspotTheme.buttonTextColor),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      const Text(
                                        'Rating: ',
                                        style: TextStyle(
                                            color:
                                                HotspotTheme.buttonTextColor),
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
                                        color: HotspotTheme.buttonTextColor),
                                  ),
                                ],
                              ),
                              onTap: () => _showSuggestedDetailsDialog(hotspot),
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
                                style: const TextStyle(
                                  color: HotspotTheme.backgroundColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'Rating: ',
                                        style: TextStyle(
                                            color:
                                                HotspotTheme.buttonTextColor),
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
                                        color: HotspotTheme.buttonTextColor),
                                  ),
                                ],
                              ),
                              onTap: () => _showEVStationDetailsDialog(charger),
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
          backgroundColor: HotspotTheme.textColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                          color: HotspotTheme.accentColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        hotspot.totalWeight?.toStringAsFixed(1) ?? 'N/A',
                        style: const TextStyle(
                            color: HotspotTheme.buttonTextColor),
                      ),
                    ],
                  ),
                  _buildDetailRowTags('Types', hotspot.types),
                  GestureDetector(
                    onTap: () => _launchUrl(hotspot.googleMapsUri),
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
                              style:
                                  TextStyle(color: HotspotTheme.primaryColor),
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
                          return Center(
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
                              style: TextStyle(
                                  color: HotspotTheme.buttonTextColor),
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

  void _showEVStationDetailsDialog(ExistingCharger charger) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: HotspotTheme.textColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            charger.displayName,
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
                  _buildDetailRow(
                    'Max Charge Rate',
                    charger.evChargeOptions.maxChargeRate?.toString() ?? 'N/A',
                  ),
                  _buildDetailRow(
                    'Connector Count',
                    charger.evChargeOptions.connectorCount.toString(),
                  ),
                  _buildDetailRow(
                      'Type', charger.evChargeOptions.type ?? 'N/A'),
                  GestureDetector(
                    onTap: () => _launchUrl(charger.googleMapsUri),
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

  void _showMarkerDetailsBottomSheet({
    SuggestedHotspot? hotspot,
    ExistingCharger? charger,
  }) {
    // Ensure at least one of hotspot or charger is non-null
    if (hotspot == null && charger == null) {
      return; // Or show an error message if appropriate
    }

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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              hotspot?.displayName ??
                                  charger?.displayName ??
                                  '',
                              style: const TextStyle(
                                color: HotspotTheme.primaryColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
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
                      Text(
                        hotspot?.formattedAddress ??
                            charger?.formattedAddress ??
                            'N/A',
                        style: TextStyle(
                          color: HotspotTheme.backgroundColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      // _buildDetailRow(
                      //     'Address',
                      //     hotspot?.formattedAddress ??
                      //         charger?.formattedAddress ??
                      //         'N/A'),
                      Row(
                        children: [
                          const Text(
                            'Rating: ',
                            style: TextStyle(
                              color: HotspotTheme.backgroundColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
                          if (hotspot != null) ...[
                            Text(
                              '    (${hotspot?.userRatingCount})',
                              style: TextStyle(
                                color: HotspotTheme.backgroundColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ]
                        ],
                      ),
                      if (hotspot != null) ...[
                        SizedBox(
                          height: 10,
                        ),
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
                              style: const TextStyle(
                                  color: HotspotTheme.buttonTextColor),
                            ),
                          ],
                        ),
                        _buildDetailRowTags('Types', hotspot.types),
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
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '• ',
                                    style: TextStyle(
                                        color: HotspotTheme.primaryColor),
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
                      ],
                      if (charger != null) ...[
                        _buildDetailRow(
                          'Max Charge Rate',
                          charger.evChargeOptions.maxChargeRate?.toString() ??
                              'N/A',
                        ),
                        _buildDetailRow(
                          'Connector Count',
                          charger.evChargeOptions.connectorCount.toString(),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color:
                                    HotspotTheme.primaryColor.withOpacity(0.1),
                                border: Border.all(
                                    color: HotspotTheme.primaryColor),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                charger.evChargeOptions.type ?? 'N/A',
                                style: const TextStyle(
                                  color: HotspotTheme.primaryColor,
                                  fontSize: 12,
                                ),
                              ),
                            )
                          ].toList(),
                        ),
                      ],
                      SizedBox(
                        height: 10,
                      ),
                      GestureDetector(
                        onTap: () => _launchUrl(hotspot?.googleMapsUri ??
                            charger?.googleMapsUri ??
                            ''),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
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
                                color: HotspotTheme.backgroundColor,
                              ),
                            ],
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
                                return Center(
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
                                    style: TextStyle(
                                        color: HotspotTheme.buttonTextColor),
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
    bool tempShowSuggested = viewModel.showSuggested;
    bool tempShowExisting = viewModel.showExisting;
    RangeValues tempScoreRange = viewModel.scoreRange;
    RangeValues tempRatingRange = viewModel.ratingRange;

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
                color: HotspotTheme.textColor,
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
                      title: const Text(
                        'Show Suggested Hotspots',
                        style: TextStyle(color: HotspotTheme.buttonTextColor),
                      ),
                      value: tempShowSuggested,
                      activeColor: HotspotTheme.accentColor,
                      onChanged: (value) {
                        setState(() {
                          tempShowSuggested = value!;
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text(
                        'Show Existing Chargers',
                        style: TextStyle(color: HotspotTheme.buttonTextColor),
                      ),
                      value: tempShowExisting,
                      activeColor: HotspotTheme.accentColor,
                      onChanged: (value) {
                        setState(() {
                          tempShowExisting = value!;
                        });
                      },
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Score Range (0-10)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: HotspotTheme.backgroundColor,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            tempScoreRange.start.toStringAsFixed(1),
                            style: const TextStyle(
                                color: HotspotTheme.buttonTextColor),
                          ),
                          Text(
                            tempScoreRange.end.toStringAsFixed(1),
                            style: const TextStyle(
                                color: HotspotTheme.buttonTextColor),
                          ),
                        ],
                      ),
                    ),
                    RangeSlider(
                      values: tempScoreRange,
                      min: 0,
                      max: 10,
                      divisions: 10,
                      activeColor: HotspotTheme.accentColor,
                      labels: RangeLabels(
                        tempScoreRange.start.toStringAsFixed(1),
                        tempScoreRange.end.toStringAsFixed(1),
                      ),
                      onChanged: (values) {
                        setState(() {
                          tempScoreRange = values;
                        });
                      },
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Rating Range (0-5)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: HotspotTheme.backgroundColor,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            tempRatingRange.start.toStringAsFixed(1),
                            style: const TextStyle(
                                color: HotspotTheme.buttonTextColor),
                          ),
                          Text(
                            tempRatingRange.end.toStringAsFixed(1),
                            style: const TextStyle(
                                color: HotspotTheme.buttonTextColor),
                          ),
                        ],
                      ),
                    ),
                    RangeSlider(
                      values: tempRatingRange,
                      min: 0,
                      max: 5,
                      divisions: 40,
                      activeColor: HotspotTheme.accentColor,
                      labels: RangeLabels(
                        tempRatingRange.start.toStringAsFixed(1),
                        tempRatingRange.end.toStringAsFixed(1),
                      ),
                      onChanged: (values) {
                        setState(() {
                          tempRatingRange = values;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          viewModel.setFilters(
                            showSuggested: tempShowSuggested,
                            showExisting: tempShowExisting,
                            scoreRange: tempScoreRange,
                            ratingRange: tempRatingRange,
                          );
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HotspotTheme.accentColor,
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
          SizedBox(
            height: 10,
          ),
          Text(
            '$label: ',
            style: const TextStyle(
              color: HotspotTheme.backgroundColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: HotspotTheme.buttonTextColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRowTags(String label, List<String> values) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: values.map((type) {
              final formatted = type
                  .split('_')
                  .map((word) =>
                      word[0].toUpperCase() + word.substring(1).toLowerCase())
                  .join(' ');

              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: HotspotTheme.primaryColor.withOpacity(0.1),
                  border: Border.all(color: HotspotTheme.primaryColor),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  formatted,
                  style: const TextStyle(
                    color: HotspotTheme.backgroundColor,
                    fontSize: 12,
                  ),
                ),
              );
            }).toList(),
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

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }


@override
Widget build(BuildContext context) {
  return Scaffold(
    drawer: Drawer(
      child: FutureBuilder<String?>(
        future: _getUserEmail(),
        builder: (context, snapshot) {
          final email = snapshot.data ?? 'No email found';
          return Column(
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(
                  'User',
                  style: TextStyle(color: HotspotTheme.buttonTextColor),
                ),
                accountEmail: Text(
                  email,
                  style: TextStyle(color: HotspotTheme.buttonTextColor),
                ),
                decoration: BoxDecoration(
                  color: HotspotTheme.textColor,
                ),
              ),
              Expanded(child: Container()), // Spacer to push logout to bottom
              ListTile(
                leading: Icon(Icons.logout, color: HotspotTheme.accentColor),
                title: Text(
                  'Logout',
                  style: TextStyle(color: HotspotTheme.textColor),
                ),
                onTap: () {
                  _logout();
                  Navigator.pop(context); // Close drawer
                },
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    ),
    body: SafeArea(
      child: Consumer<HotspotViewModel>(
        builder: (context, viewModel, child) {
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
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                myLocationButtonEnabled: false,
              ),
              Positioned(
                top: 10,
                left: 7,
                right: 7,
                child: Column(
                  children: [
                    Card(
                      color: HotspotTheme.textColor,
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.menu,
                                color: HotspotTheme.accentColor),
                            onPressed: () {
                              Scaffold.of(context).openDrawer();
                            },
                            tooltip: 'Open menu',
                          ),
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: TextField(
                                controller: _searchController,
                                style: const TextStyle(
                                    color: HotspotTheme.buttonTextColor),
                                textAlignVertical: TextAlignVertical.center,
                                decoration: const InputDecoration(
                                  hintText: 'Search location...',
                                  hintStyle: TextStyle(color: Colors.grey),
                                  border: InputBorder.none,
                                  suffixIcon: Icon(Icons.search,
                                      color: HotspotTheme.accentColor),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_placeSuggestions.isNotEmpty)
                      Card(
                        color: HotspotTheme.textColor,
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          width: double.infinity,
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _placeSuggestions.length,
                            itemBuilder: (context, index) {
                              final suggestion = _placeSuggestions[index];
                              return ListTile(
                                title: Text(
                                  suggestion['description'],
                                  style: const TextStyle(
                                      color: HotspotTheme.buttonTextColor),
                                ),
                                onTap: () {
                                  FocusScope.of(context).unfocus();
                                  _selectPlace(suggestion['place_id']);
                                },
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (viewModel.showActionButtons) ...[
                Positioned(
                  bottom: 20,
                  right: 7,
                  child: FloatingActionButton(
                    heroTag: 'clear',
                    mini: true,
                    backgroundColor: HotspotTheme.textColor,
                    onPressed: () {
                      viewModel.clearSelection();
                    },
                    child: const Icon(Icons.remove_circle_outline,
                        color: HotspotTheme.accentColor),
                  ),
                ),
                Positioned(
                  bottom: 70,
                  right: 7,
                  child: FloatingActionButton(
                    heroTag: 'mapType',
                    onPressed: _toggleMapType,
                    mini: true,
                    backgroundColor: HotspotTheme.textColor,
                    child: Icon(
                      _mapType == MapType.normal ? Icons.satellite : Icons.map,
                      color: HotspotTheme.accentColor,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 120,
                  right: 7,
                  child: FloatingActionButton(
                    heroTag: 'list',
                    mini: true,
                    backgroundColor: HotspotTheme.textColor,
                    onPressed: () => _showSuggestedListDialog(viewModel),
                    child:
                        const Icon(Icons.list, color: HotspotTheme.accentColor),
                  ),
                ),
                Positioned(
                  bottom: 170,
                  right: 7,
                  child: FloatingActionButton(
                    heroTag: 'analytics',
                    mini: true,
                    backgroundColor: HotspotTheme.textColor,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AnalyticsScreen()),
                      );
                    },
                    child: const Icon(Icons.analytics,
                        color: HotspotTheme.accentColor),
                  ),
                ),
                Positioned(
                  bottom: 220,
                  right: 7,
                  child: FloatingActionButton(
                    heroTag: 'filter',
                    mini: true,
                    backgroundColor: HotspotTheme.textColor,
                    onPressed: () => _showFilterBottomSheet(viewModel),
                    child: const Icon(Icons.filter_list,
                        color: HotspotTheme.accentColor),
                  ),
                ),
              ],
              // Positioned(
              //   bottom: 350,
              //   right: 7,
              //   child: FloatingActionButton(
              //     heroTag: 'logout',
              //     mini: true,
              //     backgroundColor: HotspotTheme.textColor,
              //     onPressed: () {
              //       _logout();
              //       viewModel.clearSelection();
              //     },
              //     child: const Icon(Icons.logout, color: HotspotTheme.accentColor),
              //   ),
              // ),
              if (viewModel.selectedLocation != null)
                Positioned(
                  bottom: 20,
                  left: 7,
                  right: 7,
                  child: Card(
                    color: HotspotTheme.textColor,
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
                                  style: TextStyle(
                                      color: HotspotTheme.buttonTextColor)),
                              Expanded(
                                child: Slider(
                                  value: viewModel.radius,
                                  min: 1.0,
                                  max: 50.0,
                                  divisions: 49,
                                  label:
                                      '${viewModel.radius.toStringAsFixed(1)} km',
                                  activeColor: HotspotTheme.accentColor,
                                  onChanged: viewModel.updateRadius,
                                ),
                              ),
                              const Text('50 km',
                                  style: TextStyle(
                                      color: HotspotTheme.buttonTextColor)),
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
                                backgroundColor: HotspotTheme.accentColor,
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
    ),
  );
}

}
