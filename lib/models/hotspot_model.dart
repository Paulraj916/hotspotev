// hotspot_model.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HotspotResponse {
  final List<SuggestedHotspot> suggested;
  final List<ExistingCharger> existingCharger;

  HotspotResponse({required this.suggested, required this.existingCharger});

  factory HotspotResponse.fromJson(Map<String, dynamic> json) {
    return HotspotResponse(
      suggested: (json['suggestedStations'] as List<dynamic>? ?? [])
          .map((e) => SuggestedHotspot.fromJson(e as Map<String, dynamic>))
          .toList(),
      existingCharger: (json['evstations'] as List<dynamic>? ?? [])
          .map((e) => ExistingCharger.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SuggestedHotspot {
  final String name;
  final String id;
  final String displayName;
  final List<String> types;
  final String formattedAddress;
  final double? lat;
  final double? lng;
  final double? rating;
  final int userRatingCount;
  final List<String> photo;
  final String googleMapsUri;
  final double? totalWeight;
  final bool isExistingChargeStationFound; // New field
  final List<NearestChargeStationDetail>? nearestChargeStationDetail; // New field

  SuggestedHotspot({
    required this.name,
    required this.id,
    required this.displayName,
    required this.types,
    required this.formattedAddress,
    this.lat,
    this.lng,
    this.rating,
    required this.userRatingCount,
    required this.photo,
    required this.googleMapsUri,
    this.totalWeight,
    required this.isExistingChargeStationFound,
    this.nearestChargeStationDetail,
  });

  factory SuggestedHotspot.fromJson(Map<String, dynamic> json) {
    return SuggestedHotspot(
      name: json['name'] as String? ?? 'Unknown',
      id: json['id'] as String? ?? 'Unknown',
      displayName: json['locationName'] as String? ?? 'Unknown',
      types: (json['types'] as List<dynamic>? ?? []).map((e) => e as String).toList(),
      formattedAddress: json['address'] as String? ?? 'Unknown',
      lat: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      lng: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      userRatingCount: json['userRatingCount'] as int? ?? 0,
      photo: (json['photo'] as List<dynamic>? ?? []).map((e) => e as String).toList(),
      googleMapsUri: json['googleMapsUri'] as String? ?? '',
      totalWeight: json['totalWeight'] != null ? (json['totalWeight'] as num).toDouble() : null,
      isExistingChargeStationFound: json['isExistingChargeStationFound'] as bool? ?? false,
      nearestChargeStationDetail: (json['nearestChargeStationDetail'] as List<dynamic>?)
          ?.map((e) => NearestChargeStationDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class NearestChargeStationDetail {
  final LatLng location;
  final String markerID;
  final String displayName;
  final int distance;

  NearestChargeStationDetail({
    required this.location,
    required this.markerID,
    required this.displayName,
    required this.distance,
  });

  factory NearestChargeStationDetail.fromJson(Map<String, dynamic> json) {
    return NearestChargeStationDetail(
      location: LatLng(
        (json['location']['latitude'] as num?)?.toDouble() ?? 0.0,
        (json['location']['longitude'] as num?)?.toDouble() ?? 0.0,
      ),
      markerID: json['markerID'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'Unknown',
      distance: (json['distance'] as num?)?.toInt() ?? 0,
    );
  }
}

class ExistingCharger {
  final String name;
  final String id;
  final String displayName;
  final String formattedAddress;
  final double? lat; // Made nullable
  final double? lng; // Made nullable
  final double? rating; // Made nullable
  final int userRatingCount;
  final String googleMapsUri;
  final EVChargeOptions evChargeOptions;

  ExistingCharger({
    required this.name,
    required this.id,
    required this.displayName,
    required this.formattedAddress,
    this.lat,
    this.lng,
    this.rating,
    required this.userRatingCount,
    required this.googleMapsUri,
    required this.evChargeOptions,
  });

  factory ExistingCharger.fromJson(Map<String, dynamic> json) {
    return ExistingCharger(
      name: json['name'] as String? ?? 'Unknown',
      id: json['id'] as String? ?? 'Unknown',
      displayName: json['locationName'] as String? ?? 'Unknown',
      formattedAddress: json['address'] as String? ?? 'Unknown',
      lat: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      lng: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      userRatingCount: json['userRatingCount'] as int? ?? 0,
      googleMapsUri: json['googleMapsUri'] as String? ?? '',
      evChargeOptions: EVChargeOptions.fromJson(json['evChargeOptions'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'id': id,
      'locationName': displayName,
      'address': formattedAddress,
      'latitude': lat,
      'longitude': lng,
      'rating': rating,
      'userRatingCount': userRatingCount,
      'googleMapsUri': googleMapsUri,
      'evChargeOptions': evChargeOptions,
    };
  }
}

class EVChargeOptions {
  final int connectorCount;
  final int? maxChargeRate;
  final String? type;
  final int count;
  final int? availableCount;
  final int? outOfServiceCount;

  EVChargeOptions({
    required this.connectorCount,
    this.maxChargeRate,
    this.type,
    required this.count,
    this.availableCount,
    this.outOfServiceCount,
  });

  factory EVChargeOptions.fromJson(Map<String, dynamic> json) {
    return EVChargeOptions(
      connectorCount: json['connectorcount'] != null ? (json['connectorcount'] as num).toInt() : 0,
      maxChargeRate: json['maxchargerate'] != null ? (json['maxchargerate'] as num).toInt() : null,
      type: json['type'] as String?,
      count: json['count'] != null ? (json['count'] as num).toInt() : 0,
      availableCount: json['avaliablecount'] != null ? (json['avaliablecount'] as num).toInt() : null,
      outOfServiceCount: json['outofserviveCount'] != null ? (json['outofserviveCount'] as num).toInt() : null,
    );
  }
    Map<String, dynamic> toJson() {
    return {
      'connectorcount': connectorCount,
      'maxchargerate': maxChargeRate,
      'type': type,
      'count': count,
      'avaliablecount': availableCount,
      'outofserviveCount': outOfServiceCount,
    };
  }
}