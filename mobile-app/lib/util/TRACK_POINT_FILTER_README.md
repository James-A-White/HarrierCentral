# TrackPoint Filtering and Interpolation

## Overview

The `TrackPointFilter` class provides GPS track point filtering and interpolation to clean up location data from mobile devices. GPS data often contains inaccuracies due to:

- Poor GPS signal (high accuracy values, e.g., 30-50m)
- Sudden position jumps (GPS drift)
- Duplicate or too-frequent points
- Physical impossibilities (unrealistic velocities)

## Features

- **Accuracy Filtering**: Removes points with GPS accuracy values above a threshold
- **Velocity Filtering**: Detects and removes points that would require impossible speeds
- **Time Delta Filtering**: Removes duplicate points that are too close in time
- **Interpolation**: Replaces bad points with interpolated positions between good points
- **Statistics**: Provides detailed statistics about the filtering operation

## Usage

### Basic Usage

```dart
import 'package:harrier_central/util/track_point_filter.dart';
import 'package:harrier_central/data/models/user_positions/user_positions.dart';

// Create a filter with default settings
final filter = TrackPointFilter();

// Filter your track points
final cleanedPoints = filter.filterAndInterpolate(myTrackPoints);
```

### Custom Settings

```dart
final filter = TrackPointFilter(
  maxAccuracyMeters: 30.0,              // Maximum acceptable GPS accuracy
  maxVelocityMetersPerSecond: 15.0,     // Maximum realistic velocity (~54 km/h)
  minTimeDeltaMs: 500,                  // Minimum time between points
);
```

### Integration with RunTrackerMapController

The filter is automatically applied when loading positions in `RunTrackerMapController`:

```dart
Future<void> loadPositions({bool reset = false}) async {
  final data = await api.fetchPositions(...);
  
  // Filter and clean track points for each user
  final cleanedUsers = data.users.map((user) {
    if (user.positions.length < 2) return user;
    
    final filteredPositions = _trackFilter.filterAndInterpolate(user.positions);
    return user.copyWith(positions: filteredPositions);
  }).toList();
  
  userPositions.assignAll(cleanedUsers);
}
```

### Getting Filter Statistics

```dart
final stats = filter.getFilterStats(originalPoints, filteredPoints);
print(stats);
// Output: FilterStats(original: 100, filtered: 95, removed: 5, 
//         badAccuracy: 3, badVelocity: 1, tooClose: 1)
```

## Configuration Guidelines

### maxAccuracyMeters
- **5m**: Excellent GPS accuracy (indoors with good signal)
- **10m**: Good GPS accuracy (outdoors, normal conditions)
- **30m**: Default threshold - filters poor quality points
- **50m+**: Very poor accuracy, should be filtered

### maxVelocityMetersPerSecond
- **5 m/s** (~18 km/h): Walking/jogging
- **10 m/s** (~36 km/h): Fast running
- **15 m/s** (~54 km/h): Default - covers fast running to slow cycling
- **20 m/s** (~72 km/h): Cycling
- **30 m/s** (~108 km/h): Vehicle speeds

### minTimeDeltaMs
- **500ms**: Default - filters rapid-fire duplicate points
- **1000ms**: One point per second (good for slower activities)
- **100ms**: High frequency tracking (e.g., racing apps)

## Algorithm Details

The filter operates in two passes:

### Pass 1: Accuracy and Time Filtering
1. Removes points with `accuracy > maxAccuracyMeters`
2. Removes points with time delta `< minTimeDeltaMs` from previous point

### Pass 2: Velocity Filtering
1. Calculates velocity between consecutive good points
2. Removes points requiring velocities `> maxVelocityMetersPerSecond`
3. Only compares against the last known good point (ignores bad intermediates)

### Interpolation
1. For each gap of bad points between good points:
   - Creates interpolated points at the original timestamps
   - Linear interpolation for lat/lng
   - Averages accuracy values
   - Preserves the `type` field from original points

## Testing

Run the comprehensive test suite:

```bash
flutter test test/track_point_filter_test.dart
```

Tests cover:
- Keeping good accuracy points
- Filtering poor accuracy points
- Filtering excessive velocities
- Filtering duplicate timestamps
- Multiple consecutive bad points
- Type field preservation
- Empty and edge cases

## Performance Considerations

- Time complexity: O(n) where n is the number of points
- Space complexity: O(n) for the output list
- Suitable for real-time filtering of location updates
- No external dependencies beyond latlong2 for distance calculations

## Future Enhancements

Potential improvements:
- Kalman filtering for smoother tracks
- Adaptive thresholds based on activity type
- Outlier detection using standard deviation
- Consideration of altitude changes
- Direction-aware filtering
