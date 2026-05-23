import 'package:flutter/material.dart';

/// Citizen-observed water depth on flood report forms.
enum WaterLevelChoice {
  low,
  medium,
  high,
}

extension WaterLevelChoiceX on WaterLevelChoice {
  String get pickerLabel => switch (this) {
        WaterLevelChoice.low => 'Low · ankle-deep or less',
        WaterLevelChoice.medium => 'Medium · shin to knee depth',
        WaterLevelChoice.high => 'High · knee+ or flowing fast',
      };

  /// Short titles for segmented control.
  String get compactLabel => switch (this) {
        WaterLevelChoice.low => 'Low',
        WaterLevelChoice.medium => 'Med',
        WaterLevelChoice.high => 'High',
      };

  IconData get icon => switch (this) {
        WaterLevelChoice.low => Icons.water_damage_outlined,
        WaterLevelChoice.medium => Icons.waves_outlined,
        WaterLevelChoice.high => Icons.flash_on_outlined,
      };
}
