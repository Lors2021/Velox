import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class RideModel {
  final String id;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration duration;
  final double distanceMeters;
  final double avgSpeedMs;
  final double maxSpeedMs;
  final List<LatLng> trackPoints;

  const RideModel({
    required this.id,
    required this.userId,
    required this.startTime,
    this.endTime,
    required this.duration,
    required this.distanceMeters,
    required this.avgSpeedMs,
    required this.maxSpeedMs,
    required this.trackPoints,
  });

  factory RideModel.fromMap(Map<String, dynamic> map, String id) {
    final List<dynamic> points = map['trackPoints'] ?? [];
    return RideModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: map['endTime'] != null
          ? (map['endTime'] as Timestamp).toDate()
          : null,
      duration: Duration(seconds: (map['durationSeconds'] as num?)?.toInt() ?? 0),
      distanceMeters: (map['distanceMeters'] as num?)?.toDouble() ?? 0,
      avgSpeedMs: (map['avgSpeedMs'] as num?)?.toDouble() ?? 0,
      maxSpeedMs: (map['maxSpeedMs'] as num?)?.toDouble() ?? 0,
      trackPoints: points
          .map((p) => LatLng(
                (p['lat'] as num).toDouble(),
                (p['lng'] as num).toDouble(),
              ))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'durationSeconds': duration.inSeconds,
      'distanceMeters': distanceMeters,
      'avgSpeedMs': avgSpeedMs,
      'maxSpeedMs': maxSpeedMs,
      'trackPoints': trackPoints
          .map((p) => {'lat': p.latitude, 'lng': p.longitude})
          .toList(),
    };
  }
}
