// api_client.dart
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'hotspot_model.dart';

class ApiClient {
  static const String baseUrl = 'https://hotspot-backend-three.vercel.app';
  static const String googlePlacesBaseUrl = 'https://maps.googleapis.com/maps/api/place';
  final String apiKey = "AIzaSyAOcbvs0MtHhAiHevyu63o1kkp7OXHfVRY"; // Consider securing this

  Future<HotspotResponse> getHotspots(double lat, double lng, double radius) async {
    final url = Uri.parse(
      '$baseUrl/api/places?latitude=$lat&longitude=$lng&radius=$radius',
    );
    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return HotspotResponse.fromJson(data);
    } else {
      throw Exception('Failed to load hotspots: ${response.statusCode}');
    }
  }

  Future<List<dynamic>> fetchPlaceSuggestions(String input, String sessionToken) async {
    final url = Uri.parse(
      '$googlePlacesBaseUrl/autocomplete/json?input=$input&key=$apiKey&sessiontoken=$sessionToken',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body)['predictions'] as List<dynamic>;
    } else {
      throw Exception('Failed to fetch suggestions: ${response.statusCode}');
    }
  }

  Future<LatLng> selectPlace(String placeId, String sessionToken) async {
    final url = Uri.parse(
      '$googlePlacesBaseUrl/details/json?place_id=$placeId&fields=geometry&key=$apiKey&sessiontoken=$sessionToken',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final lat = data['result']['geometry']['location']['lat'] as double;
      final lng = data['result']['geometry']['location']['lng'] as double;
      return LatLng(lat, lng);
    } else {
      throw Exception('Failed to fetch place details: ${response.statusCode}');
    }
  }
}