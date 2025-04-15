// suggested_list_dialog.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/hotspot_model.dart';
import '../theme/hotspot_theme.dart';
import '../viewmodels/hotspot_viewmodel.dart';
import 'marker_details_bottom_sheet.dart';

void showSuggestedListDialog(
  BuildContext context,
  HotspotViewModel viewModel,
  TabController tabController,
  Completer<GoogleMapController>? controller,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: HotspotTheme.textColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                _buildTabBar(viewModel, tabController),
                Expanded(
                  child: _buildTabBarView(
                    viewModel,
                    scrollController,
                    tabController,
                    controller,
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Widget _buildTabBar(HotspotViewModel viewModel, TabController tabController) {
  return Container(
    color: HotspotTheme.textColor,
    child: TabBar(
      controller: tabController,
      labelColor: HotspotTheme.primaryColor,
      unselectedLabelColor: HotspotTheme.primaryColor,
      indicatorColor: HotspotTheme.primaryColor,
      dividerColor: HotspotTheme.textColor,
      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
      tabs: [
        Tab(
          text: 'Hotspots (${viewModel.getFilteredSuggestedHotspots().length})',
        ),
        Tab(
          text: 'EV Stations (${viewModel.getFilteredEVStations().length})',
        ),
      ],
    ),
  );
}

Widget _buildTabBarView(
  HotspotViewModel viewModel,
  ScrollController scrollController,
  TabController tabController,
  Completer<GoogleMapController>? controller,
) {
  return TabBarView(
    controller: tabController,
    children: [
      ListView.builder(
        controller: scrollController,
        itemCount: viewModel.getFilteredSuggestedHotspots().length,
        itemBuilder: (context, index) {
          final hotspot = viewModel.getFilteredSuggestedHotspots()[index];
          return _buildHotspotTile(context, hotspot, controller, viewModel);
        },
      ),
      ListView.builder(
        controller: scrollController,
        itemCount: viewModel.getFilteredEVStations().length,
        itemBuilder: (context, index) {
          final charger = viewModel.getFilteredEVStations()[index];
          return _buildEVStationTile(context, charger, controller, viewModel);
        },
      ),
    ],
  );
}

Widget _buildHotspotTile(
  BuildContext context,
  SuggestedHotspot hotspot,
  Completer<GoogleMapController>? controller,
  HotspotViewModel viewModel,
) {
  return Container(
    margin: const EdgeInsets.only(top: 10, left: 10, right: 10),
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      color: HotspotTheme.backgroundGrey,
      borderRadius: BorderRadius.circular(10),
    ),
    child: ListTile(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              hotspot.displayName,
              style: const TextStyle(
                color: HotspotTheme.backgroundColor,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.visible,
              softWrap: true,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            hotspot.isExistingChargeStationFound
                ? Icons.ev_station_outlined
                : Icons.ev_station,
            color: hotspot.isExistingChargeStationFound
                ? Colors.red
                : Colors.green,
            size: 20,
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Text(
            hotspot.formattedAddress,
            style: const TextStyle(color: HotspotTheme.buttonTextColor),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              RatingBarIndicator(
                rating: hotspot.rating ?? 0,
                itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: HotspotTheme.accentColor,
                ),
                itemCount: 5,
                itemSize: 20.0,
                unratedColor: Colors.grey[300],
              ),
              Text(
                '  ${hotspot.rating} (${hotspot.userRatingCount})',
                style: const TextStyle(color: HotspotTheme.buttonTextColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'Score: ',
                style: TextStyle(color: HotspotTheme.buttonTextColor),
              ),
              Expanded(
                child: LinearProgressIndicator(
                  value: (hotspot.totalWeight ?? 0) / 10,
                  backgroundColor: Colors.grey[300],
                  color: HotspotTheme.accentColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${hotspot.totalWeight?.toStringAsFixed(1) ?? 'N/A'}',
                style: const TextStyle(color: HotspotTheme.buttonTextColor),
              ),
            ],
          ),
        ],
      ),
      onTap: () async {
        final mapController = await controller?.future;
        final position = LatLng(hotspot.lat ?? 0.0, hotspot.lng ?? 0.0);

        // Zoom to the hotspot
        mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(position, 20),
        );

        // Trigger marker bounce
        viewModel.bounceMarker('suggested_${hotspot.id}', hotspot.totalWeight ?? 0);

        // Show details
        showMarkerDetailsBottomSheet(context: context, hotspot: hotspot);
      },
    ),
  );
}

Widget _buildEVStationTile(
  BuildContext context,
  ExistingCharger charger,
  Completer<GoogleMapController>? controller,
  HotspotViewModel viewModel,
) {
  return Container(
    margin: const EdgeInsets.only(top: 10, left: 10, right: 10),
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      color: HotspotTheme.backgroundGrey,
      borderRadius: BorderRadius.circular(10),
    ),
    child: ListTile(
      title: Text(
        charger.displayName,
        style: const TextStyle(
          color: HotspotTheme.backgroundColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Text(
            charger.formattedAddress,
            style: const TextStyle(color: HotspotTheme.buttonTextColor),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              RatingBarIndicator(
                rating: charger.rating ?? 0,
                itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: HotspotTheme.accentColor,
                ),
                itemCount: 5,
                itemSize: 20.0,
                unratedColor: Colors.grey[300],
              ),
              Text(
                '  ${charger.rating} (${charger.userRatingCount})',
                style: const TextStyle(color: HotspotTheme.buttonTextColor),
              ),
            ],
          ),
        ],
      ),
      onTap: () async {
        final mapController = await controller?.future;
        final position = LatLng(charger.lat ?? 0.0, charger.lng ?? 0.0);

        // Zoom to the charger
        mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(position, 20),
        );

        // Trigger marker bounce
        viewModel.bounceMarker('existing_${charger.id}', charger.rating ?? 0, isCharger: true);

        // Show details
        showMarkerDetailsBottomSheet(context: context, charger: charger);
      },
    ),
  );
}