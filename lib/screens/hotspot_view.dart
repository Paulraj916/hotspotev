import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
import '../theme/hotspot_theme.dart';
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
        onSuggestedTap: (hotspot) => showMarkerDetailsBottomSheet(
          context: context,
          hotspot: hotspot,
        ),
        onExistingTap: (charger) => showMarkerDetailsBottomSheet(
          context: context,
          charger: charger,
        ),
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

  // Handle search input changes
  void _onSearchChanged() {
    if (_searchController.text.isNotEmpty) {
      _fetchPlaceSuggestions(_searchController.text);
    } else {
      setState(() {
        _placeSuggestions = [];
      });
    }
  }

  // Fetch user email from SharedPreferences
  Future<String?> _getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userEmail') ?? 'admin@gmail.com';
  }

  // Fetch place suggestions from view model
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

  // Select a place and update map
  Future<void> _selectPlace(String placeId) async {
    try {
      final viewModel = context.read<HotspotViewModel>();
      await viewModel.selectPlace(placeId, _sessionToken);
      final controller = await _controller?.future;
      controller?.animateCamera(
        CameraUpdate.newLatLngZoom(viewModel.selectedLocation!, 12),
      );
      setState(() {
        _placeSuggestions = [];
      });
    } catch (e) {
      print('Error fetching place details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load location: $e')),
      );
    }
  }

  // Toggle between normal and hybrid map types
  void _toggleMapType() {
    setState(() {
      _mapType = _mapType == MapType.normal ? MapType.hybrid : MapType.normal;
    });
  }

  // Logout and navigate to login screen
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
                const Spacer(),
                ListTile(
                  leading: Icon(Icons.logout, color: HotspotTheme.accentColor),
                  title: Text(
                    'Logout',
                    style: TextStyle(color: HotspotTheme.textColor),
                  ),
                  onTap: () {
                    _logout();
                    Navigator.pop(context);
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
                      onPressed: () =>
                          showSuggestedListDialog(context, viewModel, _tabController),
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
                      onPressed: () => showFilterBottomSheet(context, viewModel),
                      child: const Icon(Icons.filter_list,
                          color: HotspotTheme.accentColor),
                    ),
                  ),
                ],
                if (viewModel.selectedLocation != null)
                  _buildRadiusAdjuster(viewModel),
              ],
            );
          },
        ),
      ),
    );
  }

  // Build search bar widget
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
                controller: _searchController,
                style: const TextStyle(color: HotspotTheme.buttonTextColor),
                textAlignVertical: TextAlignVertical.center,
                decoration: const InputDecoration(
                  hintText: 'Search location...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  suffixIcon: Icon(Icons.search, color: HotspotTheme.accentColor),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build place suggestions list
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

  // Build radius adjuster card
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
                    'Adjust Radius',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: HotspotTheme.primaryColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear, color: HotspotTheme.primaryColor),
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
                  const Text('50 km',
                      style: TextStyle(color: HotspotTheme.buttonTextColor)),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: viewModel.isLoading ? null : viewModel.fetchHotspots,
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
    );
  }
}