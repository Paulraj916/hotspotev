// nearby_chargers_model.dart
import 'package:hotspot/models/hotspot_model.dart';

class NearbyChargersRequest {
  final Source source;
  final List<ExistingCharger> evChargers;

  NearbyChargersRequest({required this.source, required this.evChargers});

  Map<String, dynamic> toJson() {
    return {
      'source': source.toJson(),
      'evChargers': evChargers.map((charger) => charger.toJson()).toList(),
    };
  }
}

class Source {
  final double latitude;
  final double longitude;
  final String locationName;

  Source({
    required this.latitude,
    required this.longitude,
    required this.locationName,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
    };
  }

  factory Source.fromJson(Map<String, dynamic> json) {
    return Source(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      locationName: json['locationName'] as String? ?? 'Unknown',
    );
  }
}

class NearbyChargersResponse {
  final Source source;
  final List<Destination> destination;

  NearbyChargersResponse({required this.source, required this.destination});

  factory NearbyChargersResponse.fromJson(Map<String, dynamic> json) {
    return NearbyChargersResponse(
      source: Source.fromJson(json['source'] as Map<String, dynamic>),
      destination: (json['destination'] as List<dynamic>? ?? [])
          .map((e) => Destination.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Destination {
  final String id;
  final String locationName;
  final String placeId;
  final double latitude;
  final double longitude;
  final double distance;

  Destination({
    required this.id,
    required this.locationName,
    required this.placeId,
    required this.latitude,
    required this.longitude,
    required this.distance,
  });

  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      id: json['id'] as String? ?? '',
      locationName: json['locationName'] as String? ?? 'Unknown',
      placeId: json['placeId'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}