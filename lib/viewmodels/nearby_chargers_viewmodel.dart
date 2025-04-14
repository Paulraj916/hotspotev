// nearby_chargers_viewmodel.dart
import 'package:flutter/material.dart';
import '../models/nearby_chargers_model.dart';
import '../repository/nearby_chargers_repository.dart';
import '../models/hotspot_model.dart';

class NearbyChargersViewModel extends ChangeNotifier {
  final NearbyChargersRepository repository;

  NearbyChargersViewModel(this.repository);

  NearbyChargersResponse? _nearbyChargersResponse;
  bool _isLoading = false;

  NearbyChargersResponse? get nearbyChargersResponse => _nearbyChargersResponse;
  bool get isLoading => _isLoading;

  Future<void> fetchNearbyChargers({
    required Source source,
    required List<ExistingCharger> evChargers,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final request = NearbyChargersRequest(source: source, evChargers: evChargers);
      _nearbyChargersResponse = await repository.fetchNearbyChargers(request.toJson());
    } catch (e) {
      print('Error fetching nearby chargers: $e');
      _nearbyChargersResponse = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  void clear() {
    _nearbyChargersResponse = null;
    notifyListeners();
  }
}