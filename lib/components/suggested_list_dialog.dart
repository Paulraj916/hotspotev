import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../models/hotspot_model.dart';
import '../theme/hotspot_theme.dart';
import '../viewmodels/hotspot_viewmodel.dart';
import 'marker_details_bottom_sheet.dart';

void showSuggestedListDialog(
  BuildContext context,
  HotspotViewModel viewModel,
  TabController tabController,
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
                  child: _buildTabBarView(viewModel, scrollController, tabController),
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
) {
  return TabBarView(
    controller: tabController,
    children: [
      ListView.builder(
        controller: scrollController,
        itemCount: viewModel.getFilteredSuggestedHotspots().length,
        itemBuilder: (context, index) {
          final hotspot = viewModel.getFilteredSuggestedHotspots()[index];
          return _buildHotspotTile(context, hotspot);
        },
      ),
      ListView.builder(
        controller: scrollController,
        itemCount: viewModel.getFilteredEVStations().length,
        itemBuilder: (context, index) {
          final charger = viewModel.getFilteredEVStations()[index];
          return _buildEVStationTile(context, charger);
        },
      ),
    ],
  );
}

Widget _buildHotspotTile(BuildContext context, SuggestedHotspot hotspot) {
  return Container(
    margin: const EdgeInsets.only(top: 10, left: 10, right: 10),
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      color: const Color.fromARGB(255, 56, 56, 56),
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
            color: hotspot.isExistingChargeStationFound ? Colors.red : Colors.green,
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
      onTap: () => showMarkerDetailsBottomSheet(context: context, hotspot: hotspot),
    ),
  );
}

Widget _buildEVStationTile(BuildContext context, ExistingCharger charger) {
  return ListTile(
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
        Row(
          children: [
            const Text(
              'Rating: ',
              style: TextStyle(color: HotspotTheme.buttonTextColor),
            ),
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
          ],
        ),
        Text(
          'Address: ${charger.formattedAddress}',
          style: const TextStyle(color: HotspotTheme.buttonTextColor),
        ),
      ],
    ),
    onTap: () => showMarkerDetailsBottomSheet(context: context, charger: charger),
  );
}