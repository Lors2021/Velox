import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ride_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/ride_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import 'ride_detail_screen.dart';

class RideHistoryScreen extends StatelessWidget {
  const RideHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rideProvider = context.watch<RideProvider>();
    final rides = rideProvider.rideHistory;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('RIDE HISTORY'),
        actions: [
          if (rides.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${rides.length} rides',
                  style: const TextStyle(
                      color: AppTheme.textMuted, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
      body: rideProvider.isLoadingHistory
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accent))
          : rides.isEmpty
              ? _EmptyState()
              : RefreshIndicator(
                  color: AppTheme.accent,
                  backgroundColor: AppTheme.card,
                  onRefresh: () async {
                    final uid =
                        context.read<AuthProvider>().user?.uid ?? '';
                    await context
                        .read<RideProvider>()
                        .loadRideHistory(uid);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: rides.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _RideTile(ride: rides[i]),
                  ),
                ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.card,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.border),
            ),
            child: const Icon(Icons.directions_bike_rounded,
                size: 40, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 20),
          const Text(
            'No rides yet',
            style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 17,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start your first ride on the Map tab',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _RideTile extends StatelessWidget {
  final RideModel ride;
  const _RideTile({required this.ride});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RideDetailScreen(ride: ride)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Formatters.formatDate(ride.startTime),
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: AppTheme.accent.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.directions_bike_rounded,
                          color: AppTheme.accent, size: 11),
                      const SizedBox(width: 4),
                      const Text(
                        'RIDE',
                        style: TextStyle(
                          color: AppTheme.accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _metric(Icons.straighten_rounded,
                    Formatters.formatDistance(ride.distanceMeters),
                    'Distance'),
                const SizedBox(width: 24),
                _metric(
                    Icons.speed_rounded,
                    '${(ride.avgSpeedMs * 3.6).toStringAsFixed(1)} km/h',
                    'Avg Speed'),
                const SizedBox(width: 24),
                _metric(
                    Icons.timer_outlined,
                    Formatters.formatDuration(ride.duration),
                    'Duration'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(IconData icon, String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.accent, size: 13),
            const SizedBox(width: 4),
            Text(value,
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label,
            style:
                const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
      ],
    );
  }
}
