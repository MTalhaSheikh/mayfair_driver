import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_texts.dart';
import '../../core/app_theme.dart';
import '../../utils/map_launcher.dart';

class TripPointsCard extends StatelessWidget {
  final String pickupTitle;
  final String pickupSubtitle;
  final String dropoffTitle;
  final String dropoffSubtitle;
  final double? miles;
  final int? mins;

  // Optional coordinates — when provided, a map icon is shown on each row.
  final double? pickupLat;
  final double? pickupLng;
  final double? dropoffLat;
  final double? dropoffLng;

  const TripPointsCard({
    super.key,
    required this.pickupTitle,
    required this.pickupSubtitle,
    required this.dropoffTitle,
    required this.dropoffSubtitle,
    this.miles,
    this.mins,
    this.pickupLat,
    this.pickupLng,
    this.dropoffLat,
    this.dropoffLng,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: AppColors.softCardShadow,
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _PointRow(
            markerColor: AppColors.markerGreen,
            markerShape: _MarkerShape.circle,
            label: AppTexts.pickupPoint,
            title: pickupTitle,
            subtitle: pickupSubtitle,
            showConnector: true,
            onMapTap: (pickupLat != null && pickupLng != null)
                ? () => showMapChooser(
                      context,
                      lat: pickupLat!,
                      lng: pickupLng!,
                      label: pickupTitle,
                    )
                : null,
          ),
          const SizedBox(height: 14),
          _PointRow(
            markerColor: AppColors.markerRed,
            markerShape: _MarkerShape.square,
            label: AppTexts.dropOffPoint,
            title: dropoffTitle,
            subtitle: dropoffSubtitle,
            showConnector: false,
            onMapTap: (dropoffLat != null && dropoffLng != null)
                ? () => showMapChooser(
                      context,
                      lat: dropoffLat!,
                      lng: dropoffLng!,
                      label: dropoffTitle,
                    )
                : null,
          ),
          if (miles != null || mins != null) ...[
            const SizedBox(height: 16),
            const Divider(color: AppColors.divider),
            const SizedBox(height: 12),
            Row(
              children: [
                if (miles != null) ...[
                  const Icon(
                    Icons.pin_drop_outlined,
                    size: 18,
                    color: AppColors.portalOlive,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${miles!.toStringAsFixed(1)} ${AppTexts.miles}',
                    style: AppTheme.metaText,
                  ),
                ],
                const Spacer(),
                if (mins != null) ...[
                  const Icon(
                    Icons.timer_outlined,
                    size: 18,
                    color: AppColors.portalOlive,
                  ),
                  const SizedBox(width: 10),
                  Text(_formatDuration(mins!), style: AppTheme.metaText),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

String _formatDuration(int totalMinutes) {
  if (totalMinutes < 60) {
    return '~$totalMinutes ${AppTexts.mins}';
  }

  final int hours = totalMinutes ~/ 60;
  final int minutes = totalMinutes % 60;

  if (minutes == 0) {
    return '~$hours ${hours == 1 ? "hr" : "hrs"}';
  }

  return '~$hours ${hours == 1 ? "hr" : "hrs"} $minutes ${AppTexts.mins}';
}

enum _MarkerShape { circle, square }

class _PointRow extends StatelessWidget {
  final Color markerColor;
  final _MarkerShape markerShape;
  final String label;
  final String title;
  final String subtitle;
  final bool showConnector;
  final VoidCallback? onMapTap;

  const _PointRow({
    required this.markerColor,
    required this.markerShape,
    required this.label,
    required this.title,
    required this.subtitle,
    required this.showConnector,
    this.onMapTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 34,
          child: Column(
            children: [
              _Marker(color: markerColor, shape: markerShape),
              if (showConnector) ...[
                const SizedBox(height: 4),
                Container(width: 2, height: 44, color: AppColors.divider),
              ],
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.locationLabel.copyWith(
                  color: AppColors.portalOlive,
                ),
              ),
              const SizedBox(height: 4),
              Text(title, style: AppTheme.locationTitle),
              const SizedBox(height: 2),
              Text(subtitle, style: AppTheme.locationSubtitle),
            ],
          ),
        ),
        // Map icon button — only shown when coordinates are available
        if (onMapTap != null) ...[
          const SizedBox(width: 8),
          Padding(
            padding: EdgeInsets.only(top: showConnector ? 0 : 2),
            child: InkWell(
              onTap: onMapTap,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.portalOlive.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.navigation_rounded,
                  size: 18,
                  color: AppColors.portalOlive,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Marker extends StatelessWidget {
  final Color color;
  final _MarkerShape shape;

  const _Marker({required this.color, required this.shape});

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: shape == _MarkerShape.circle
            ? BoxShape.circle
            : BoxShape.rectangle,
        borderRadius: shape == _MarkerShape.square
            ? BorderRadius.circular(4)
            : null,
        border: Border.all(color: color, width: 2),
        color: Colors.white,
      ),
    );

    if (shape == _MarkerShape.circle) {
      return Stack(
        alignment: Alignment.center,
        children: [
          box,
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ],
      );
    }
    return box;
  }
}
