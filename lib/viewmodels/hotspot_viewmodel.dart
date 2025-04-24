// hotspot_viewmodel.dart
import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hotspot/analytics_helper/useranalytics.dart';
import 'package:hotspot/main.dart';
import 'package:hotspot/theme/hotspot_theme.dart';
import '../models/hotspot_model.dart';
import '../models/nearby_chargers_model.dart'; // Import nearby chargers model
import '../repository/hotspot_repository.dart';

class HotspotViewModel extends ChangeNotifier {
  final HotspotRepository repository;

  HotspotViewModel(this.repository);

  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  LatLng? _selectedLocation;
  double _radius = 5.0;
  bool _isLoading = false;
  HotspotResponse? _hotspotResponse;
  bool _showActionButtons = false;
  bool _showSuggested = true;
  bool _showExisting = true;
  RangeValues _scoreRange = const RangeValues(0, 10);
  RangeValues _ratingRange = const RangeValues(0, 5);
  bool _isNearbyChargersMode = false; // New: Track toggle state
  SuggestedHotspot? _currentHotspot; // New: Track current suggested hotspot
  NearbyChargersResponse?
      _nearbyChargersResponse; // New: Store nearby chargers data

  Function(SuggestedHotspot)? _onSuggestedTap;
  Function(ExistingCharger)? _onExistingTap;

  // Getters
  bool get isNearbyChargersMode => _isNearbyChargersMode;
  SuggestedHotspot? get currentHotspot => _currentHotspot;
  NearbyChargersResponse? get nearbyChargersResponse => _nearbyChargersResponse;
  HotspotResponse? get hotspotResponse => _hotspotResponse;
  Set<Marker> get markers => _markers;
  Set<Circle> get circles => _circles;
  LatLng? get selectedLocation => _selectedLocation;
  double get radius => _radius;
  bool get isLoading => _isLoading;
  bool get showActionButtons => _showActionButtons;
  bool get showSuggested => _showSuggested;
  bool get showExisting => _showExisting;
  RangeValues get scoreRange => _scoreRange;
  RangeValues get ratingRange => _ratingRange;

  // Toggle nearby chargers mode
  void toggleNearbyChargersMode({
    required bool isEnabled,
    SuggestedHotspot? hotspot,
    NearbyChargersResponse? response,
  }) {
    _isNearbyChargersMode = isEnabled;
    _currentHotspot = isEnabled ? hotspot : null;
    _nearbyChargersResponse = isEnabled ? response : null;
    applyFilters(
      onSuggestedTap: _onSuggestedTap,
      onExistingTap: _onExistingTap,
    );
    notifyListeners();
  }

  Future<BitmapDescriptor> getCustomMarker(
    double score, {
    bool isCharger = false,
    double sizeMultiplier = 1.0,
  }) async {
    Color primaryColor;
    if (isCharger) {
      primaryColor = HotspotTheme.chargerColor;
    } else {
      // Normalize the score to a value between 0 and 1 (for gradient interpolation)
      final normalizedScore = (score.clamp(0, 10) / 10); // Score from 0 to 10

      // Interpolate between green (0), yellow (5), and red (10)
      if (normalizedScore <= 0.5) {
        // Interpolate between green (0) and yellow (0.5)
        primaryColor = Color.lerp(
          Colors.green,
          const Color.fromARGB(255, 255, 193, 59),
          normalizedScore * 2, // Scale 0-0.5 to 0-1 for interpolation
        )!;
      } else {
        // Interpolate between yellow (0.5) and red (1.0)
        primaryColor = Color.lerp(
          const Color.fromARGB(255, 255, 193, 59),
          Colors.red,
          (normalizedScore - 0.5) * 2, // Scale 0.5-1.0 to 0-1 for interpolation
        )!;
      }
    }

    final baseSize = 150.0;
    final width = baseSize * sizeMultiplier;
    final height = baseSize * sizeMultiplier;
    final strokeWidth = 25.0 * sizeMultiplier;
    final size = 100.0 * sizeMultiplier;

    final pictureRecorder = PictureRecorder();
    final canvas = Canvas(pictureRecorder);

    final double borderWidth = size * 0.1;
    final circlePaint = Paint()..color = primaryColor;

    Paint paint = Paint()
      ..color = primaryColor.withOpacity(0.18)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    Offset center = Offset(width / 2, height / 2);
    double radius = min(width / 2, height / 2) - (strokeWidth / 2);

    canvas.drawCircle(
      center,
      size / 2 - borderWidth,
      circlePaint,
    );

    canvas.drawCircle(center, radius, paint);

    if (isCharger) {
      final iconPainter = TextPainter(
        text: TextSpan(
          text: '⚡',
          style: TextStyle(
            color: Colors.white,
            fontSize: 40 * sizeMultiplier,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      iconPainter.layout();
      final iconOffset = Offset(
        center.dx - iconPainter.width / 2,
        center.dy - iconPainter.height / 2,
      );
      iconPainter.paint(canvas, iconOffset);
    } else {
      final text = score.toStringAsFixed(1);
      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 30 * sizeMultiplier,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      final textOffset = Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      );
      textPainter.paint(canvas, textOffset);
    }

    final img = await pictureRecorder
        .endRecording()
        .toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ImageByteFormat.png);
    final BitmapDescriptor bitmap =
        BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
    return bitmap;
  }

  void bounceMarker(String markerId, double score,
      {bool isCharger = false}) async {
    // ... (Existing bounceMarker implementation unchanged)
    const bounceCount = 1;
    const bounceDuration = Duration(milliseconds: 800);

    for (int i = 0; i < bounceCount * 2; i++) {
      final sizeMultiplier = i % 2 == 0 ? 1.1 : 1.0;
      final marker = _markers.firstWhere(
        (m) => m.markerId.value == markerId,
        orElse: () => throw Exception('Marker not found'),
      );

      final newIcon = await getCustomMarker(
        score,
        isCharger: isCharger,
        sizeMultiplier: sizeMultiplier,
      );

      _markers.removeWhere((m) => m.markerId.value == markerId);
      _markers.add(
        marker.copyWith(
          iconParam: newIcon,
        ),
      );

      notifyListeners();
      await Future.delayed(bounceDuration);
    }
  }

  void setTapCallbacks({
    Function(SuggestedHotspot)? onSuggestedTap,
    Function(ExistingCharger)? onExistingTap,
  }) {
    _onSuggestedTap = onSuggestedTap;
    _onExistingTap = onExistingTap;
  }

  void onMapTap(LatLng position) {
    // Reset nearby chargers mode when selecting a new location
    if (_isNearbyChargersMode) {
      toggleNearbyChargersMode(isEnabled: false);
    }
    _selectedLocation = position;
    _markers.removeWhere((marker) => marker.markerId.value == 'selected');
    _circles.clear();
    _markers.add(
      Marker(
        markerId: const MarkerId('selected'),
        position: position,
        infoWindow: const InfoWindow(title: 'Selected Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ),
    );
    _updateRadiusCircle();
    notifyListeners();
  }

  void updateRadius(double value) {
    _radius = value;
    _updateRadiusCircle();
    notifyListeners();
  }

  void clearSelection() {
    _markers.clear();
    _circles.clear();
    _selectedLocation = null;
    _radius = 5.0;
    _hotspotResponse = null;
    _showActionButtons = false;
    _isNearbyChargersMode = false; // Reset toggle
    _currentHotspot = null;
    _nearbyChargersResponse = null;
    notifyListeners();
  }

  void clearSelectionForAdjustRadius() {
    _markers.removeWhere((marker) => marker.markerId.value == 'selected');
    _circles.clear();
    _selectedLocation = null;
    _radius = 5.0;
    notifyListeners();
  }

  void _updateRadiusCircle() {
    if (_selectedLocation == null) return;
    _circles.clear();
    _circles.add(
      Circle(
        circleId: const CircleId('radius'),
        center: _selectedLocation!,
        radius: _radius * 1000,
        fillColor: const Color.fromARGB(255, 255, 187, 0).withOpacity(0.2),
        strokeColor: HotspotTheme.textColor,
        strokeWidth: 2,
      ),
    );
  }

  Future<void> fetchHotspots() async {
    if (_selectedLocation == null) return;
    AnalyticsHelper.logEvent('Generate Button Clicked',
        {'button_name': 'Generate Button', 'screen': 'Home Screen'});
    _isLoading = true;
    notifyListeners();

    try {
      _hotspotResponse = await repository.fetchHotspots(
        _selectedLocation!.latitude,
        _selectedLocation!.longitude,
        _radius * 1000,
      );
      applyFilters(
        onSuggestedTap: _onSuggestedTap,
        onExistingTap: _onExistingTap,
      );
      _markers.add(
        Marker(
          markerId: const MarkerId('selected'),
          position: _selectedLocation!,
          infoWindow: const InfoWindow(title: 'Selected Location'),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      );
      _updateRadiusCircle();
      _showActionButtons = true;
    } catch (e) {
      print('Error fetching hotspots: $e');
    }
    await Future.delayed(const Duration(seconds: 1));
    _isLoading = false;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 1));
    clearSelectionForAdjustRadius();
  }

  void applyFilters({
    Function(SuggestedHotspot)? onSuggestedTap,
    Function(ExistingCharger)? onExistingTap,
  }) async {
    final newMarkers = <Marker>{};

    Marker? selectedMarker;
    try {
      selectedMarker = _markers.firstWhere(
        (marker) => marker.markerId.value == 'selected',
      );
    } catch (e) {
      selectedMarker = null;
    }
    if (selectedMarker != null) {
      newMarkers.add(selectedMarker);
    }

    if (_isNearbyChargersMode &&
        _currentHotspot != null &&
        _nearbyChargersResponse != null) {
      // Show only the current hotspot
      if (_currentHotspot!.lat != null && _currentHotspot!.lng != null) {
        final score = _currentHotspot!.totalWeight ?? 0;
        final BitmapDescriptor customIcon =
            await getCustomMarker(score, isCharger: false);
        newMarkers.add(
          Marker(
            markerId: MarkerId('suggested_${_currentHotspot!.id}'),
            position: LatLng(_currentHotspot!.lat!, _currentHotspot!.lng!),
            infoWindow: InfoWindow(
              title: _currentHotspot!.displayName,
              snippet:
                  'Score: ${_currentHotspot!.totalWeight ?? 'N/A'}, Rating: ${_currentHotspot!.rating ?? 'N/A'}',
            ),
            icon: customIcon,
            onTap: onSuggestedTap != null
                ? () => onSuggestedTap(_currentHotspot!)
                : null,
          ),
        );
      }

      // Show nearby chargers with distance in tooltip
      for (var destination in _nearbyChargersResponse!.destination) {
        final BitmapDescriptor customIcon =
            await getCustomMarker(0, isCharger: true);
        newMarkers.add(
          Marker(
            markerId: MarkerId('nearby_${destination.id}'),
            position: LatLng(destination.latitude, destination.longitude),
            infoWindow: InfoWindow(
              title: destination.locationName,
              snippet:
                  'Distance: ${destination.distance.toStringAsFixed(2)} km',
            ),
            icon: customIcon,
            onTap: onExistingTap != null
                ? () {
                    // Find matching ExistingCharger
                    final charger =
                        _hotspotResponse?.existingCharger.firstWhere(
                      (c) =>
                          c.id == destination.id.replaceFirst('existing_', ''),
                      orElse: () => ExistingCharger(
                        name: destination.locationName,
                        id: destination.id,
                        displayName: destination.locationName,
                        formattedAddress: 'Unknown',
                        lat: destination.latitude,
                        lng: destination.longitude,
                        userRatingCount: 0,
                        googleMapsUri: '',
                        evChargeOptions: EVChargeOptions(
                          connectorCount: 0,
                          count: 0,
                        ),
                      ),
                    );
                    onExistingTap(charger!);
                  }
                : null,
          ),
        );
      }
    } else {
      // Normal mode
      if (_hotspotResponse == null) return;

      if (_showSuggested) {
        for (var hotspot in _hotspotResponse!.suggested) {
          final score = hotspot.totalWeight ?? 0;
          final rating = hotspot.rating ?? 0;
          if (hotspot.lat != null &&
              hotspot.lng != null &&
              score >= _scoreRange.start &&
              score <= _scoreRange.end &&
              rating >= _ratingRange.start &&
              rating <= _ratingRange.end) {
            final BitmapDescriptor customIcon =
                await getCustomMarker(score, isCharger: false);
            newMarkers.add(
              Marker(
                markerId: MarkerId('suggested_${hotspot.id}'),
                position: LatLng(hotspot.lat!, hotspot.lng!),
                infoWindow: InfoWindow(
                  title: hotspot.displayName,
                  snippet:
                      'Score: ${hotspot.totalWeight ?? 'N/A'}, Rating: ${hotspot.rating ?? 'N/A'}',
                ),
                icon: customIcon,
                onTap: onSuggestedTap != null
                    ? () => onSuggestedTap(hotspot)
                    : null,
              ),
            );
          }
        }
      }

      if (_showExisting) {
        for (var charger in _hotspotResponse!.existingCharger) {
          final rating = charger.rating ?? 0;
          if (charger.lat != null &&
              charger.lng != null &&
              rating >= _ratingRange.start &&
              rating <= _ratingRange.end) {
            final BitmapDescriptor customIcon =
                await getCustomMarker(rating, isCharger: true);
            newMarkers.add(
              Marker(
                markerId: MarkerId('existing_${charger.id}'),
                position: LatLng(charger.lat!, charger.lng!),
                infoWindow: InfoWindow(
                  title: charger.displayName,
                  snippet: 'Rating: ${charger.rating ?? 'N/A'}',
                ),
                icon: customIcon,
                onTap:
                    onExistingTap != null ? () => onExistingTap(charger) : null,
              ),
            );
          }
        }
      }
    }

    _markers = newMarkers;

    if (_selectedLocation != null && !_isNearbyChargersMode) {
      _updateRadiusCircle();
    } else {
      _circles.clear();
    }
    notifyListeners();
  }

  void setFilters({
    required bool showSuggested,
    required bool showExisting,
    required RangeValues scoreRange,
    required RangeValues ratingRange,
  }) {
    if (!_isNearbyChargersMode) {
      _showSuggested = showSuggested;
      _scoreRange = scoreRange;
    }
    _showExisting = showExisting;
    _ratingRange = ratingRange;
    applyFilters(
      onSuggestedTap: _onSuggestedTap,
      onExistingTap: _onExistingTap,
    );
  }

  void toggleShowSuggested(bool value) {
    if (!_isNearbyChargersMode) {
      _showSuggested = value;
      applyFilters(
        onSuggestedTap: _onSuggestedTap,
        onExistingTap: _onExistingTap,
      );
    }
    notifyListeners();
  }

  void toggleShowExisting(bool value) {
    _showExisting = value;
    applyFilters(
      onSuggestedTap: _onSuggestedTap,
      onExistingTap: _onExistingTap,
    );
    notifyListeners();
  }

  void updateScoreRange(RangeValues values) {
    if (!_isNearbyChargersMode) {
      _scoreRange = values;
      applyFilters(
        onSuggestedTap: _onSuggestedTap,
        onExistingTap: _onExistingTap,
      );
    }
    notifyListeners();
  }

  void updateRatingRange(RangeValues values) {
    _ratingRange = values;
    applyFilters(
      onSuggestedTap: _onSuggestedTap,
      onExistingTap: _onExistingTap,
    );
    notifyListeners();
  }

  List<SuggestedHotspot> getSortedSuggestedHotspots() {
    if (_hotspotResponse == null) return [];
    final sortedList = List<SuggestedHotspot>.from(_hotspotResponse!.suggested);
    sortedList
        .sort((a, b) => (b.totalWeight ?? 0).compareTo(a.totalWeight ?? 0));
    return sortedList;
  }

  List<ExistingCharger> getSortedEVStations() {
    if (_hotspotResponse == null) return [];
    final sortedList =
        List<ExistingCharger>.from(_hotspotResponse!.existingCharger);
    sortedList.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
    return sortedList;
  }

  List<SuggestedHotspot> getFilteredSuggestedHotspots() {
    if (_hotspotResponse == null) return [];
    return getSortedSuggestedHotspots().where((hotspot) {
      final score = hotspot.totalWeight ?? 0;
      final rating = hotspot.rating ?? 0;
      return _showSuggested &&
          score >= _scoreRange.start &&
          score <= _scoreRange.end &&
          rating >= _ratingRange.start &&
          rating <= _ratingRange.end;
    }).toList();
  }

  List<ExistingCharger> getFilteredEVStations() {
    if (_hotspotResponse == null) return [];
    return getSortedEVStations().where((charger) {
      final rating = charger.rating ?? 0;
      return _showExisting &&
          rating >= _ratingRange.start &&
          rating <= _ratingRange.end;
    }).toList();
  }

  Future<List<dynamic>> fetchPlaceSuggestions(
    String input,
    String sessionToken,
  ) async {
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
