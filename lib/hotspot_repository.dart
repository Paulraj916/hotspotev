import 'hotspot_model.dart';
import 'api_client.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HotspotRepository {
  final ApiClient apiClient;

  HotspotRepository(this.apiClient);

  Future<HotspotResponse> fetchHotspots(double lat, double lng, double radius) {
    return apiClient.getHotspots(lat, lng, radius);
  }

  Future<List<dynamic>> fetchPlaceSuggestions(String input, String sessionToken) {
    return apiClient.fetchPlaceSuggestions(input, sessionToken);
  }

  Future<LatLng> selectPlace(String placeId, String sessionToken) {
    return apiClient.selectPlace(placeId, sessionToken);
  }
}