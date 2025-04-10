// hotspot_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hotspot/main.dart';
import 'hotspot_model.dart';
import 'hotspot_repository.dart';
import 'dart:math';
import 'dart:ui';

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

  Function(SuggestedHotspot)? _onSuggestedTap;
  Function(ExistingCharger)? _onExistingTap;

  HotspotResponse? get hotspotResponse => _hotspotResponse;

  Set<Marker> get markers => _markers;
  Set<Circle> get circles => _circles;
  LatLng? get selectedLocation => _selectedLocation;
  double get radius => _radius;
  bool get isLoading => _isLoading;
  bool get showSuggested => _showSuggested;
  bool get showExisting => _showExisting;
  RangeValues get scoreRange => _scoreRange;
  RangeValues get ratingRange => _ratingRange;

  Future<BitmapDescriptor> getCustomMarker(double score,
      {bool isCharger = false}) async {
    Color primaryColor;
if (isCharger) {
  primaryColor = const Color.fromARGB(255, 81, 45, 198); // Deep Purple for chargers
} else if (score >= 7) {
  primaryColor = const Color.fromARGB(255, 46, 201, 62); // Forest Green for high scores
} else if (score >= 4) {
  primaryColor = const Color.fromARGB(255, 255, 179, 0); // Amber Yellow for medium scores
} else {
  primaryColor = const Color.fromARGB(255, 235, 64, 52); // Bright Red for low scores
}

    final double width = 150;
    final double height = 150;
    final double strokeWidth = 25.0;
    final size = 100;

    final pictureRecorder = PictureRecorder();
    final canvas = Canvas(pictureRecorder);

    final double borderWidth = size * 0.1;
    final borderPaint = Paint()..color = Colors.white;
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
      // Draw a charge icon (lightning bolt)
      final iconPainter = TextPainter(
        text: const TextSpan(
          text: '⚡', // Lightning bolt symbol
          style: TextStyle(
            color: Colors.white,
            fontSize: 40,
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
      // Draw score text for hotspots
      final text = score.toStringAsFixed(1);
      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
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

  void setTapCallbacks({
    Function(SuggestedHotspot)? onSuggestedTap,
    Function(ExistingCharger)? onExistingTap,
  }) {
    _onSuggestedTap = onSuggestedTap;
    _onExistingTap = onExistingTap;
  }

  void onMapTap(LatLng position) {
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
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      );
      _updateRadiusCircle();
    } catch (e) {
      print('Error fetching hotspots: $e');
    }
    await Future.delayed(const Duration(seconds: 1));
    _isLoading = false;
    // clearSelectionForAdjustRadius();
    notifyListeners();
    
  }

  void applyFilters({
    Function(SuggestedHotspot)? onSuggestedTap,
    Function(ExistingCharger)? onExistingTap,
  }) async {
    if (_hotspotResponse == null) return;
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
              onTap:
                  onSuggestedTap != null ? () => onSuggestedTap(hotspot) : null,
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
    _markers = newMarkers;

    if (_selectedLocation != null) {
      _updateRadiusCircle();
    }
    notifyListeners();
  }

  double _getMarkerColor(double score) {
    if (score >= 7) return BitmapDescriptor.hueGreen;
    if (score >= 4) return BitmapDescriptor.hueYellow;
    return BitmapDescriptor.hueRed;
  }

  void setFilters({
    required bool showSuggested,
    required bool showExisting,
    required RangeValues scoreRange,
    required RangeValues ratingRange,
  }) {
    _showSuggested = showSuggested;
    _showExisting = showExisting;
    _scoreRange = scoreRange;
    _ratingRange = ratingRange;
    applyFilters(
      onSuggestedTap: _onSuggestedTap,
      onExistingTap: _onExistingTap,
    );
  }

  void toggleShowSuggested(bool value) {
    _showSuggested = value;
    notifyListeners();
  }

  void toggleShowExisting(bool value) {
    _showExisting = value;
    notifyListeners();
  }

  void updateScoreRange(RangeValues values) {
    _scoreRange = values;
    notifyListeners();
  }

  void updateRatingRange(RangeValues values) {
    _ratingRange = values;
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
      String input, String sessionToken) async {
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
