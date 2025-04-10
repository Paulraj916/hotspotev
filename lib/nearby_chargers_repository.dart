// nearby_chargers_repository.dart
import 'api_client.dart';
import 'nearby_chargers_model.dart';

class NearbyChargersRepository {
  final ApiClient apiClient;

  NearbyChargersRepository(this.apiClient);

  Future<NearbyChargersResponse> fetchNearbyChargers(Map<String, dynamic> requestBody) {
    return apiClient.fetchNearbyChargers(requestBody);
  }
}