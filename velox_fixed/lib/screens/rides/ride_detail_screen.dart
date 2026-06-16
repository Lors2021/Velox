import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';
import '../../models/ride_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';

class RideDetailScreen extends StatelessWidget {
  final RideModel ride;

  const RideDetailScreen({super.key, required this.ride});

  LatLng get _center {
    if (ride.trackPoints.isEmpty) return const LatLng(55.7558, 37.6173);
    double lat = 0, lng = 0;
    for (final p in ride.trackPoints) {
      lat += p.latitude;
      lng += p.longitude;
    }
    return LatLng(
      lat / ride.trackPoints.length,
      lng / ride.trackPoints.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(Formatters.formatShortDate(ride.startTime)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Map preview
          SizedBox(
            height: 280,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(0),
                bottomRight: Radius.circular(0),
              ),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: _center,
                  initialZoom: 14,
                ),
                children: [
                  TileLayer(
                    urlTemplate: AppConstants.mapUrlTemplate,
                    tileProvider: FMTCStore(AppConstants.mapStoreKey)
                        .getTileProvider(),
                    userAgentPackageName: 'com.velox.velox',
                  ),
                  if (ride.trackPoints.length >= 2)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: ride.trackPoints,
                          color: AppTheme.accent,
                          strokeWidth: 4,
                          borderColor: AppTheme.accent.withOpacity(0.3),
                          borderStrokeWidth: 8,
                        ),
                      ],
                    ),
                  if (ride.trackPoints.isNotEmpty)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: ride.trackPoints.first,
                          width: 28,
                          height: 28,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: AppTheme.accent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.play_arrow_rounded,
                                color: Colors.black, size: 16),
                          ),
                        ),
                        Marker(
                          point: ride.trackPoints.last,
                          width: 28,
                          height: 28,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: AppTheme.danger,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.flag_rounded,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          // Stats
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    Formatters.formatDate(ride.startTime),
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.65,
                    children: [
                      _statCard('Distance',
                          Formatters.formatDistance(ride.distanceMeters),
                          Icons.straighten_rounded),
                      _statCard('Duration',
                          Formatters.formatDuration(ride.duration),
                          Icons.timer_outlined),
                      _statCard(
                          'Avg Speed',
                          '${(ride.avgSpeedMs * 3.6).toStringAsFixed(1)} km/h',
                          Icons.speed_rounded),
                      _statCard(
                          'Max Speed',
                          '${(ride.maxSpeedMs * 3.6).toStringAsFixed(1)} km/h',
                          Icons.flash_on_rounded),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.accent, size: 15),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                      letterSpacing: 0.3)),
            ],
          ),
          Text(value,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
