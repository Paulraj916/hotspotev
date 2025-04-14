import 'package:flutter/material.dart';

import '../theme/hotspot_theme.dart';
import '../viewmodels/hotspot_viewmodel.dart';

void showFilterBottomSheet(BuildContext context, HotspotViewModel viewModel) {
  bool tempShowSuggested = viewModel.showSuggested;
  bool tempShowExisting = viewModel.showExisting;
  RangeValues tempScoreRange = viewModel.scoreRange;
  RangeValues tempRatingRange = viewModel.ratingRange;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: HotspotTheme.textColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 16),
                  _buildCheckboxes(
                    tempShowSuggested: tempShowSuggested,
                    tempShowExisting: tempShowExisting,
                    onSuggestedChanged: (value) =>
                        setState(() => tempShowSuggested = value!),
                    onExistingChanged: (value) =>
                        setState(() => tempShowExisting = value!),
                  ),
                  _buildScoreRangeSlider(
                    tempScoreRange: tempScoreRange,
                    onChanged: (values) => setState(() => tempScoreRange = values),
                  ),
                  _buildRatingRangeSlider(
                    tempRatingRange: tempRatingRange,
                    onChanged: (values) =>
                        setState(() => tempRatingRange = values),
                  ),
                  const SizedBox(height: 16),
                  _buildApplyButton(
                    context: context,
                    viewModel: viewModel,
                    showSuggested: tempShowSuggested,
                    showExisting: tempShowExisting,
                    scoreRange: tempScoreRange,
                    ratingRange: tempRatingRange,
                  ),
                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _buildHeader(BuildContext context) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Text(
        'Filter Options',
        style: TextStyle(
          color: HotspotTheme.primaryColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      IconButton(
        icon: const Icon(Icons.close, color: HotspotTheme.primaryColor),
        onPressed: () => Navigator.pop(context),
      ),
    ],
  );
}

Widget _buildCheckboxes({
  required bool tempShowSuggested,
  required bool tempShowExisting,
  required ValueChanged<bool?> onSuggestedChanged,
  required ValueChanged<bool?> onExistingChanged,
}) {
  return Column(
    children: [
      CheckboxListTile(
        title: const Text(
          'Show Suggested Hotspots',
          style: TextStyle(color: HotspotTheme.buttonTextColor),
        ),
        value: tempShowSuggested,
        activeColor: HotspotTheme.accentColor,
        onChanged: onSuggestedChanged,
      ),
      CheckboxListTile(
        title: const Text(
          'Show Existing Chargers',
          style: TextStyle(color: HotspotTheme.buttonTextColor),
        ),
        value: tempShowExisting,
        activeColor: HotspotTheme.accentColor,
        onChanged: onExistingChanged,
      ),
    ],
  );
}

Widget _buildScoreRangeSlider({
  required RangeValues tempScoreRange,
  required ValueChanged<RangeValues> onChanged,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(
          'Score Range (0-10)',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: HotspotTheme.backgroundColor,
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              tempScoreRange.start.toStringAsFixed(1),
              style: const TextStyle(color: HotspotTheme.buttonTextColor),
            ),
            Text(
              tempScoreRange.end.toStringAsFixed(1),
              style: const TextStyle(color: HotspotTheme.buttonTextColor),
            ),
          ],
        ),
      ),
      RangeSlider(
        values: tempScoreRange,
        min: 0,
        max: 10,
        divisions: 10,
        activeColor: HotspotTheme.accentColor,
        labels: RangeLabels(
          tempScoreRange.start.toStringAsFixed(1),
          tempScoreRange.end.toStringAsFixed(1),
        ),
        onChanged: onChanged,
      ),
    ],
  );
}

Widget _buildRatingRangeSlider({
  required RangeValues tempRatingRange,
  required ValueChanged<RangeValues> onChanged,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(
          'Rating Range (0-5)',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: HotspotTheme.backgroundColor,
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              tempRatingRange.start.toStringAsFixed(1),
              style: const TextStyle(color: HotspotTheme.buttonTextColor),
            ),
            Text(
              tempRatingRange.end.toStringAsFixed(1),
              style: const TextStyle(color: HotspotTheme.buttonTextColor),
            ),
          ],
        ),
      ),
      RangeSlider(
        values: tempRatingRange,
        min: 0,
        max: 5,
        divisions: 40,
        activeColor: HotspotTheme.accentColor,
        labels: RangeLabels(
          tempRatingRange.start.toStringAsFixed(1),
          tempRatingRange.end.toStringAsFixed(1),
        ),
        onChanged: onChanged,
      ),
    ],
  );
}

Widget _buildApplyButton({
  required BuildContext context,
  required HotspotViewModel viewModel,
  required bool showSuggested,
  required bool showExisting,
  required RangeValues scoreRange,
  required RangeValues ratingRange,
}) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: () {
        viewModel.setFilters(
          showSuggested: showSuggested,
          showExisting: showExisting,
          scoreRange: scoreRange,
          ratingRange: ratingRange,
        );
        Navigator.pop(context);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: HotspotTheme.accentColor,
        foregroundColor: HotspotTheme.buttonTextColor,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: const Text('Apply Filters'),
    ),
  );
}