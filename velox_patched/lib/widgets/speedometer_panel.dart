import 'package:flutter/material.dart';
import '../providers/ride_provider.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';

class SpeedometerPanel extends StatelessWidget {
  final RideProvider provider;

  const SpeedometerPanel({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppTheme.surface.withOpacity(0.97),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Big current speed
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                provider.currentSpeedKmh.toStringAsFixed(1),
                style: const TextStyle(
                  color: AppTheme.accent,
                  fontSize: 60,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  letterSpacing: -2,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 10, left: 6),
                child: Text(
                  'km/h',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 15,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _stat('AVG', '${provider.avgSpeedKmh.toStringAsFixed(1)} km/h'),
              _vDivider(),
              _stat('MAX', '${provider.maxSpeedKmh.toStringAsFixed(1)} km/h'),
              _vDivider(),
              _stat('DIST', Formatters.formatDistance(provider.distanceMeters)),
              _vDivider(),
              _stat('TIME', Formatters.formatDuration(provider.elapsed)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 9,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _vDivider() =>
      Container(width: 1, height: 28, color: AppTheme.border);
}
