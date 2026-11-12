import 'package:flutter/material.dart';

/// FR-05: Safe / Warning / Critical plant status from sensor vs thresholds.
enum PlantLevel { safe, warning, critical }

PlantLevel levelForValue(num value, num? min, num? max) {
  if (min == null && max == null) return PlantLevel.safe;
  final lo = min ?? double.negativeInfinity;
  final hi = max ?? double.infinity;
  if (value < lo || value > hi) return PlantLevel.critical;
  final span = (hi - lo).abs();
  final margin = span <= 0 ? 1.0 : span * 0.15;
  if (value < lo + margin || value > hi - margin) return PlantLevel.warning;
  return PlantLevel.safe;
}

PlantLevel worstLevel(Iterable<PlantLevel> levels) {
  var worst = PlantLevel.safe;
  for (final level in levels) {
    if (level == PlantLevel.critical) return PlantLevel.critical;
    if (level == PlantLevel.warning) worst = PlantLevel.warning;
  }
  return worst;
}

PlantLevel overallPlantLevel(Map<String, dynamic> latest, Map<String, dynamic> plant) {
  final soil = (latest['soilMoisture'] ?? 0) as num;
  final temp = (latest['temperature'] ?? 0) as num;
  final light = (latest['light'] ?? 0) as num;
  return worstLevel([
    levelForValue(soil, plant['minMoisture'] as num?, plant['maxMoisture'] as num?),
    levelForValue(temp, plant['minTemp'] as num?, plant['maxTemp'] as num?),
    levelForValue(light, plant['minLight'] as num?, plant['maxLight'] as num?),
  ]);
}

String plantLevelLabel(PlantLevel level) {
  switch (level) {
    case PlantLevel.safe:
      return 'Safe';
    case PlantLevel.warning:
      return 'Warning';
    case PlantLevel.critical:
      return 'Critical';
  }
}

Color plantLevelColor(PlantLevel level) {
  switch (level) {
    case PlantLevel.safe:
      return Colors.green;
    case PlantLevel.warning:
      return Colors.orange;
    case PlantLevel.critical:
      return Colors.red;
  }
}
