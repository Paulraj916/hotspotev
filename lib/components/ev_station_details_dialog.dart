import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:url_launcher/url_launcher.dart';

import '../components/detail_row.dart';
import '../models/hotspot_model.dart';
import '../theme/hotspot_theme.dart';

void showEVStationDetailsDialog(BuildContext context, ExistingCharger charger) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: HotspotTheme.textColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          charger.displayName,
          style: const TextStyle(
            color: HotspotTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                DetailRow(label: 'Name', value: charger.displayName),
                DetailRow(label: 'Address', value: charger.formattedAddress),
                Row(
                  children: [
                    const Text(
                      'Rating: ',
                      style: TextStyle(
                        color: HotspotTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
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
                DetailRow(
                  label: 'User Rating Count',
                  value: charger.userRatingCount.toString(),
                ),
                DetailRow(
                  label: 'Max Charge Rate',
                  value: charger.evChargeOptions.maxChargeRate?.toString() ?? 'N/A',
                ),
                DetailRow(
                  label: 'Connector Count',
                  value: charger.evChargeOptions.connectorCount.toString(),
                ),
                DetailRow(
                  label: 'Type',
                  value: charger.evChargeOptions.type ?? 'N/A',
                ),
                GestureDetector(
                  onTap: () => _launchUrl(context, charger.googleMapsUri),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      'Google Maps Link',
                      style: TextStyle(
                        color: HotspotTheme.accentColor,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: HotspotTheme.primaryColor),
            ),
          ),
        ],
      );
    },
  );
}

Future<void> _launchUrl(BuildContext context, String url) async {
  final Uri uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not launch $url')),
    );
  }
}