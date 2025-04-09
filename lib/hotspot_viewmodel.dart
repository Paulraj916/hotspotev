// hotspot_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'hotspot_model.dart';
import 'hotspot_repository.dart';

class HotspotViewModel extends ChangeNotifier {
  final HotspotRepository repository;

  HotspotViewModel(this.repository);

  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  LatLng? _selectedLocation;
  double _radius = 5.0;
  bool _isLoading = false;
  HotspotResponse? _hotspotResponse;

  bool _showSuggested = true;
  bool _showExisting = true;
  RangeValues _scoreRange = const RangeValues(0, 10);
  RangeValues _ratingRange = const RangeValues(0, 5);

  HotspotResponse? get hotspotResponse =>  _hotspotResponse;

  Set<Marker> get markers => _markers;
  Set<Circle> get circles => _circles;
  LatLng? get selectedLocation => _selectedLocation;
  double get radius => _radius;
  bool get isLoading => _isLoading;
  bool get showSuggested => _showSuggested;
  bool get showExisting => _showExisting;
  RangeValues get scoreRange => _scoreRange;
  RangeValues get ratingRange => _ratingRange;

  void onMapTap(LatLng position) {
    _selectedLocation = position;
    _markers.removeWhere((marker) => marker.markerId.value == 'selected');
    _circles.clear(); // Clear previous circle
    _markers.add(
      Marker(
        markerId: const MarkerId('selected'),
        position: position,
        infoWindow: const InfoWindow(title: 'Selected Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );
    _updateRadiusCircle(); // Add new circle
    notifyListeners();
  }

  void updateRadius(double value) {
    _radius = value;
    _updateRadiusCircle(); // Update circle when radius changes
    notifyListeners();
  }

  void clearSelection() {
    _markers.clear();
    _circles.clear();
    _selectedLocation = null;
    _radius = 5.0;
    _hotspotResponse = null; // Clear fetched data as well
    notifyListeners();
  }

  void clearSelectionForAdjustRadius() {
    // _markers.clear();
    _markers.removeWhere((marker) => marker.markerId.value == 'selected'); 
    _circles.clear();
    _selectedLocation = null;
    _radius = 5.0;
    notifyListeners();
  }

  void _updateRadiusCircle() {
    if (_selectedLocation == null) return; // Don’t add circle if no location
    _circles.clear(); // Clear previous circle
    _circles.add(
      Circle(
        circleId: const CircleId('radius'),
        center: _selectedLocation!,
        radius: _radius * 1000, // Convert km to meters
        fillColor: const Color.fromARGB(255, 54, 26, 237).withOpacity(0.2),
        strokeColor: const Color.fromARGB(255, 54, 26, 237),
        strokeWidth: 2,
      ),
    );
  }

  Future<void> fetchHotspots() async {
    if (_selectedLocation == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      _hotspotResponse = await repository.fetchHotspots(
        _selectedLocation!.latitude,
        _selectedLocation!.longitude,
        _radius * 1000,
      );
      applyFilters();
      // Re-add the selected marker and circle after fetching
      _markers.add(
        Marker(
          markerId: const MarkerId('selected'),
          position: _selectedLocation!,
          infoWindow: const InfoWindow(title: 'Selected Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
        ),
      );
      _updateRadiusCircle(); // Ensure circle is added back
      // Keep _selectedLocation intact for radius adjustments
    } catch (e) {
      print('Error fetching hotspots: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void applyFilters({
    Function(SuggestedHotspot)? onSuggestedTap,
    Function(ExistingCharger)? onExistingTap,
  }) {
    if (_hotspotResponse == null) return;

    // Preserve the 'selected' marker
    _markers.removeWhere((marker) => marker.markerId.value != 'selected');
    // Don’t clear _circles here; let _updateRadiusCircle manage it

    if (_showSuggested) {
      for (var hotspot in _hotspotResponse!.suggested) {
        if (hotspot.lat != null &&
            hotspot.lng != null &&
            (hotspot.totalWeight ?? 0) >= _scoreRange.start &&
            (hotspot.totalWeight ?? 0) <= _scoreRange.end &&
            (hotspot.rating ?? 0) >= _ratingRange.start &&
            (hotspot.rating ?? 0) <= _ratingRange.end) {
          _markers.add(
            Marker(
              markerId: MarkerId('suggested_${hotspot.id}'),
              position: LatLng(hotspot.lat!, hotspot.lng!),
              infoWindow: InfoWindow(
                title: hotspot.displayName,
                snippet: 'Score: ${hotspot.totalWeight ?? 'N/A'}, Rating: ${hotspot.rating ?? 'N/A'}',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                _getMarkerColor(hotspot.totalWeight ?? 0),
              ),
              onTap: onSuggestedTap != null ? () => onSuggestedTap(hotspot) : null,
            ),
          );
        }
      }
    }

    if (_showExisting) {
      for (var charger in _hotspotResponse!.existingCharger) {
        if (charger.lat != null &&
            charger.lng != null &&
            (charger.rating ?? 0) >= _ratingRange.start &&
            (charger.rating ?? 0) <= _ratingRange.end) {
          _markers.add(
            Marker(
              markerId: MarkerId('existing_${charger.id}'),
              position: LatLng(charger.lat!, charger.lng!),
              infoWindow: InfoWindow(
                title: charger.displayName,
                snippet: 'Rating: ${charger.rating ?? 'N/A'}',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
              onTap: onExistingTap != null ? () => onExistingTap(charger) : null,
            ),
          );
        }
      }
    }
    // Re-add the radius circle if there’s a selected location
    if (_selectedLocation != null) {
      _updateRadiusCircle();
    }
    // notifyListeners();
  }

  double _getMarkerColor(double score) {
    if (score >= 7) return BitmapDescriptor.hueGreen;
    if (score >= 4) return BitmapDescriptor.hueYellow;
    return BitmapDescriptor.hueRed;
  }

  void toggleShowSuggested(bool value) {
    _showSuggested = value;
    applyFilters();
  }

  void toggleShowExisting(bool value) {
    _showExisting = value;
    applyFilters();
  }

  void updateScoreRange(RangeValues values) {
    _scoreRange = values;
    applyFilters();
  }

  void updateRatingRange(RangeValues values) {
    _ratingRange = values;
    applyFilters();
  }

  List<SuggestedHotspot> getSortedSuggestedHotspots() {
    if (_hotspotResponse == null) return [];
    final sortedList = List<SuggestedHotspot>.from(_hotspotResponse!.suggested);
    sortedList.sort((a, b) => (b.totalWeight ?? 0).compareTo(a.totalWeight ?? 0));
    return sortedList;
  }

  List<ExistingCharger> getSortedEVStations() {
    if (_hotspotResponse == null) return [];
    final sortedList = List<ExistingCharger>.from(_hotspotResponse!.existingCharger);
    sortedList.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
    return sortedList;
  }

  List<SuggestedHotspot> getFilteredSuggestedHotspots() {
    if (_hotspotResponse == null) return [];
    return getSortedSuggestedHotspots().where((hotspot) {
      return _showSuggested &&
          (hotspot.totalWeight ?? 0) >= _scoreRange.start &&
          (hotspot.totalWeight ?? 0) <= _scoreRange.end &&
          (hotspot.rating ?? 0) >= _ratingRange.start &&
          (hotspot.rating ?? 0) <= _ratingRange.end;
    }).toList();
  }

  List<ExistingCharger> getFilteredEVStations() {
    if (_hotspotResponse == null) return [];
    return getSortedEVStations().where((charger) {
      return _showExisting &&
          (charger.rating ?? 0) >= _ratingRange.start &&
          (charger.rating ?? 0) <= _ratingRange.end;
    }).toList();
  }

  // Methods for place suggestions (from previous refactor)
  Future<List<dynamic>> fetchPlaceSuggestions(String input, String sessionToken) async {
    try {
      return await repository.fetchPlaceSuggestions(input, sessionToken);
    } catch (e) {
      print('Error fetching suggestions: $e');
      rethrow;
    }
  }

  Future<void> selectPlace(String placeId, String sessionToken) async {
    try {
      final position = await repository.selectPlace(placeId, sessionToken);
      onMapTap(position);
    } catch (e) {
      print('Error selecting place: $e');
      rethrow;
    }
  }
}