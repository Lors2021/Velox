import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../providers/ride_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/speedometer_panel.dart';
import '../../widgets/ride_controls.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  bool _centered = true;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final rideProvider = context.read<RideProvider>();
      await rideProvider.getCurrentLocation();
      if (mounted && rideProvider.currentPosition != null && _mapReady) {
        _mapController.move(rideProvider.currentPosition!, 15);
      }
    });
  }

  void _centerOnUser() async {
    final rideProvider = context.read<RideProvider>();
    final pos = rideProvider.currentPosition;
    if (pos != null && _mapReady) {
      _mapController.move(pos, 15);
      setState(() => _centered = true);
    } else {
      final newPos = await rideProvider.getCurrentLocation();
      if (newPos != null && mounted && _mapReady) {
        _mapController.move(newPos, 15);
        setState(() => _centered = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rideProvider = context.watch<RideProvider>();
    final authProvider = context.watch<AuthProvider>();
    final pos = rideProvider.currentPosition;
    final track = rideProvider.track;
    final isRiding = rideProvider.isRiding;
    final isPaused = rideProvider.status == RideStatus.paused;

    // Auto-follow position while riding
    if (isRiding && pos != null && _centered && _mapReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _mapReady) _mapController.move(pos, 15);
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: pos ?? const LatLng(55.7558, 37.6173),
              initialZoom: 14,
              onMapReady: () => setState(() => _mapReady = true),
              onPositionChanged: (_, hasGesture) {
                if (hasGesture && _centered) {
                  setState(() => _centered = false);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: AppConstants.mapUrlTemplate,
                tileProvider: NetworkTileProvider(),
                userAgentPackageName: 'com.velox.velox',
                maxNativeZoom: 19,
              ),
              if (track.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: track.toList(),
                      color: AppTheme.accent,
                      strokeWidth: 4.0,
                      borderColor: AppTheme.accent.withOpacity(0.3),
                      borderStrokeWidth: 8.0,
                    ),
                  ],
                ),
              if (pos != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: pos,
                      width: 48,
                      height: 48,
                      child: _BikeMarker(isRiding: isRiding),
                    ),
                  ],
                ),
            ],
          ),

          // Top status pill
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _StatusPill(
                isRiding: isRiding,
                isPaused: isPaused,
              ),
            ),
          ),

          // Center button
          Positioned(
            right: 16,
            bottom: (isRiding || isPaused) ? 316 : 192,
            child: FloatingActionButton.small(
              heroTag: 'center',
              backgroundColor: _centered ? AppTheme.accent : AppTheme.card,
              elevation: 4,
              onPressed: _centerOnUser,
              child: Icon(
                Icons.my_location_rounded,
                color: _centered ? Colors.black : AppTheme.textSecondary,
                size: 20,
              ),
            ),
          ),

          // Speedometer + ride controls pinned to bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (rideProvider.status != RideStatus.idle)
                  SpeedometerPanel(provider: rideProvider),
                RideControls(
                  provider: rideProvider,
                  userId: authProvider.user?.uid ?? '',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BikeMarker extends StatelessWidget {
  final bool isRiding;
  const _BikeMarker({required this.isRiding});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.accent,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accent.withOpacity(isRiding ? 0.5 : 0.2),
            blurRadius: isRiding ? 16 : 8,
            spreadRadius: isRiding ? 4 : 2,
          ),
        ],
      ),
      child: const Icon(
        Icons.directions_bike_rounded,
        color: Colors.black,
        size: 20,
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool isRiding;
  final bool isPaused;
  const _StatusPill({required this.isRiding, required this.isPaused});

  @override
  Widget build(BuildContext context) {
    final color = isRiding
        ? AppTheme.accent
        : isPaused
            ? AppTheme.warning
            : AppTheme.textMuted;
    final label = isRiding
        ? 'RECORDING'
        : isPaused
            ? 'PAUSED'
            : 'READY';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
