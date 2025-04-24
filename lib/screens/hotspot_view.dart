// hotspot_view.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hotspot/analytics_helper/useranalytics.dart';
import 'package:hotspot/theme/hotspot_theme.dart';
import 'package:hotspot/models/nearby_chargers_model.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../components/filter_bottom_sheet.dart';
import '../components/marker_details_bottom_sheet.dart';
import '../components/suggested_list_dialog.dart';
import '../config/constants.dart';
import '../screens/analytics_view.dart';
import '../screens/login_screen.dart';
import '../viewmodels/hotspot_viewmodel.dart';

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
        onSuggestedTap: (hotspot) {
          showMarkerDetailsBottomSheet(
            context: context,
            hotspot: hotspot,
          );
          AnalyticsHelper.logEvent('Hotspot Marker Clicked',
              {'place_id': hotspot.id, 'place_name': hotspot.displayName});
        },
        onExistingTap: (charger) {
          final isNearbyMode = viewModel.isNearbyChargersMode;
          double? distance;
          String? sourceHotspotName;
          if (isNearbyMode && viewModel.nearbyChargersResponse != null) {
            final destination =
                viewModel.nearbyChargersResponse!.destination.firstWhere(
              (d) => d.id == 'existing_${charger.id}',
              orElse: () => Destination(
                id: '',
                locationName: '',
                placeId: '',
                latitude: 0.0,
                longitude: 0.0,
                distance: 0.0,
              ),
            );
            distance = destination.distance;
            sourceHotspotName = viewModel.currentHotspot?.displayName;
          }
          AnalyticsHelper.logEvent('Charger Marker Clicked',
              {'charger_id': charger.id, 'charger_name': charger.displayName});
          showMarkerDetailsBottomSheet(
            context: context,
            charger: charger,
            distance: distance,
            sourceHotspotName: sourceHotspotName,
          );
        },
      );
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
    return prefs.getString('userEmail') ?? 'admin@gmail.com';
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
        CameraUpdate.newLatLngZoom(viewModel.selectedLocation!, 12),
      );
      AnalyticsHelper.logEvent('Searched Place', {
        'latitude': viewModel.selectedLocation?.latitude,
        'longitude': viewModel.selectedLocation?.longitude
      });
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

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    AnalyticsHelper.logEvent('User Logout', {
      'email': prefs.getString("email"),
    });
    AnalyticsHelper.resetUser();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: Container(
          color: HotspotTheme.backgroundGrey
              .withOpacity(0.95), // Subtle background
          child: FutureBuilder<String?>(
            future: _getUserEmail(),
            builder: (context, snapshot) {
              final email = snapshot.data ?? 'No email found';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drawer Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0).copyWith(
                        top: MediaQuery.of(context).padding.top +
                            16), // Respect top padding
                    decoration: BoxDecoration(
                      color: HotspotTheme.textColor, // Same header color
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Avatar Placeholder
                        CircleAvatar(
                          radius: 32,
                          backgroundColor:
                              HotspotTheme.buttonTextColor.withOpacity(0.2),
                          child: Text(
                            email[0], // First letter of "User"
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: HotspotTheme.buttonTextColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // User Name
                        Text(
                          email,
                          style: TextStyle(
                            color: HotspotTheme.buttonTextColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                  // Divider for separation
                  Divider(
                    color: HotspotTheme.textColor.withOpacity(0.2),
                    thickness: 1,
                    height: 1,
                  ),
                  // Expanded to take up remaining space and push Logout to the bottom
                  Expanded(
                    child: Container(), // Empty container to fill space
                  ),
                  // Logout Button at the bottom
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 16.0),
                    child: GestureDetector(
                      onTap: () {
                        _logout();

                        Navigator.pop(context);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12.0, horizontal: 16.0),
                        decoration: BoxDecoration(
                          color: HotspotTheme.accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: HotspotTheme.accentColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.logout,
                              color: HotspotTheme.accentColor,
                              size: 22,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Logout',
                              style: TextStyle(
                                color: HotspotTheme.buttonTextColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
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
      ),
      body: SafeArea(
        child: Consumer<HotspotViewModel>(
          builder: (context, viewModel, child) {
            return Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: Constants.initialPosition,
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
                      _buildSearchBar(context),
                      if (_placeSuggestions.isNotEmpty) _buildSuggestionsList(),
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
                        _mapType == MapType.normal
                            ? Icons.satellite
                            : Icons.map,
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
                      onPressed: () => showSuggestedListDialog(
                          context, viewModel, _tabController, _controller),
                      child: const Icon(Icons.list,
                          color: HotspotTheme.accentColor),
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
                        AnalyticsHelper.logEvent('Analytics Button Clicked', {
                          'button_name': 'Analytics Button',
                          'screen': 'Analytics Screen'
                        });
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
                      onPressed: () =>
                          showFilterBottomSheet(context, viewModel),
                      child: const Icon(Icons.filter_list,
                          color: HotspotTheme.accentColor),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 10,
                    child: Card(
                      color: Colors.white.withOpacity(0.85),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Vertical Hotspot Score Bar with Labels
                                Stack(
                                  alignment: Alignment.centerLeft,
                                  children: [
                                    // Gradient Bar
                                    RotatedBox(
                                      quarterTurns:
                                          3, // Rotate 270 degrees to make it vertical
                                      child: Container(
                                        width:
                                            150, // Height of the bar when rotated
                                        height: 20, // Thickness of the bar
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Colors.green, // Low (bottom)
                                              Colors.yellow, // Medium (middle)
                                              Colors.red, // High (top)
                                            ],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                    // Labels positioned along the bar
                                    SizedBox(
                                      height:
                                          150, // Match the height of the rotated bar
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: const [
                                          Padding(
                                            padding: EdgeInsets.only(left: 30),
                                            child: Text(
                                              'HIGH \nSCORE: 10',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(left: 30),
                                            child: Text(
                                              'MEDIUM \nSCORE: 5',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(left: 30),
                                            child: Text(
                                              'LOW \nSCORE: 0',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Existing Charger Legend Item
                            _buildLegendItem(
                                HotspotTheme.chargerColor, 'LOCAL\nCHARGERS'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                if (viewModel.selectedLocation != null &&
                    !viewModel.isNearbyChargersMode)
                  _buildRadiusAdjuster(viewModel),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          child: Text(
            "⚡",
            textAlign: TextAlign.center,
          ),
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Card(
      color: HotspotTheme.textColor,
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: HotspotTheme.accentColor),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: 'Open menu',
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: TextField(
                cursorColor: HotspotTheme.primaryColor,
                controller: _searchController,
                style: const TextStyle(color: HotspotTheme.buttonTextColor),
                textAlignVertical: TextAlignVertical.center,
                decoration: const InputDecoration(
                  hintText: 'Search location',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  suffixIcon:
                      Icon(Icons.search, color: HotspotTheme.accentColor),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList() {
    return Card(
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
                style: const TextStyle(color: HotspotTheme.buttonTextColor),
              ),
              onTap: () {
                FocusScope.of(context).unfocus();
                _selectPlace(suggestion['place_id']);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildRadiusAdjuster(HotspotViewModel viewModel) {
    return Positioned(
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
                    'Radius (km)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: HotspotTheme.primaryColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear,
                        color: HotspotTheme.primaryColor),
                    onPressed: viewModel.clearSelectionForAdjustRadius,
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('1 km',
                      style: TextStyle(color: HotspotTheme.buttonTextColor)),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        valueIndicatorTextStyle: const TextStyle(
                          color: HotspotTheme.textColor, // <-- Label text color
                        ),
                      ),
                      child: Slider(
                        value: viewModel.radius,
                        min: 1.0,
                        max: 50.0,
                        divisions: 49,
                        label: '${viewModel.radius.toStringAsFixed(1)} km',
                        activeColor: HotspotTheme.accentColor,
                        onChanged: viewModel.updateRadius,
                      ),
                    ),
                  ),
                  const Text('50 km',
                      style: TextStyle(color: HotspotTheme.buttonTextColor)),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed:
                      viewModel.isLoading ? null : viewModel.fetchHotspots,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HotspotTheme.accentColor,
                    foregroundColor: HotspotTheme.textColor,
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
                            color: HotspotTheme.accentColor,
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
    );
  }
}
