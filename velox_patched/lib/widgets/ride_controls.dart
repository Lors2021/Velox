import 'package:flutter/material.dart';
import '../providers/ride_provider.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';

class RideControls extends StatelessWidget {
  final RideProvider provider;
  final String userId;

  const RideControls({
    super.key,
    required this.provider,
    required this.userId,
  });

  Future<void> _handleFinish(BuildContext context) async {
    // Confirm before finishing
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text('Finish ride?',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('This will stop recording and let you save.',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continue',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Finish', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final ride = await provider.finishRide(userId);
    if (ride == null || !context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.check_circle_rounded,
                color: AppTheme.accent, size: 52),
            const SizedBox(height: 12),
            const Text(
              'RIDE COMPLETE',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            // Summary row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _summStat('Distance',
                    Formatters.formatDistance(ride.distanceMeters)),
                _summStat(
                    'Duration', Formatters.formatDuration(ride.duration)),
                _summStat('Avg Speed',
                    '${(ride.avgSpeedMs * 3.6).toStringAsFixed(1)} km/h'),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                await provider.saveRide(ride);
                provider.resetRide();
              },
              icon: const Icon(Icons.save_rounded),
              label: const Text('SAVE RIDE'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                provider.resetRide();
              },
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppTheme.danger),
              label: const Text('DISCARD',
                  style: TextStyle(color: AppTheme.danger)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.danger),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = provider.status;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: _buildButtons(context, status),
    );
  }

  Widget _buildButtons(BuildContext context, RideStatus status) {
    if (status == RideStatus.idle) {
      return SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton.icon(
          onPressed: provider.startRide,
          icon: const Icon(Icons.play_arrow_rounded, size: 28),
          label: const Text('START RIDE',
              style: TextStyle(fontSize: 16, letterSpacing: 1.5)),
        ),
      );
    }

    if (status == RideStatus.finished) {
      return const SizedBox(height: 60);
    }

    return Row(
      children: [
        if (status == RideStatus.active)
          Expanded(
            child: SizedBox(
              height: 60,
              child: OutlinedButton.icon(
                onPressed: provider.pauseRide,
                icon: const Icon(Icons.pause_rounded),
                label: const Text('PAUSE'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.warning,
                  side: const BorderSide(color: AppTheme.warning),
                ),
              ),
            ),
          ),
        if (status == RideStatus.paused)
          Expanded(
            child: SizedBox(
              height: 60,
              child: ElevatedButton.icon(
                onPressed: provider.resumeRide,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('RESUME'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.warning,
                  foregroundColor: Colors.black,
                ),
              ),
            ),
          ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 60,
            child: ElevatedButton.icon(
              onPressed: () => _handleFinish(context),
              icon: const Icon(Icons.stop_rounded),
              label: const Text('FINISH'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.danger,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _summStat(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 15)),
        const SizedBox(height: 2),
        Text(label,
            style:
                const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
      ],
    );
  }
}
