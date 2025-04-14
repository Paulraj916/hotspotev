// nearby_chargers_repository.dart
import '../api_client/api_client.dart';
import '../models/nearby_chargers_model.dart';

class NearbyChargersRepository {
  final ApiClient apiClient;

  NearbyChargersRepository(this.apiClient);

  Future<NearbyChargersResponse> fetchNearbyChargers(Map<String, dynamic> requestBody) {
    return apiClient.fetchNearbyChargers(requestBody);
  }
}