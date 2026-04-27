import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shows a bottom sheet letting the user pick Google Maps or Waze,
/// then opens the chosen app with navigation to [lat],[lng].
Future<void> showMapChooser(
  BuildContext context, {
  required double lat,
  required double lng,
  required String label,
}) async {
  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _MapChooserSheet(lat: lat, lng: lng, label: label),
  );
}

class _MapChooserSheet extends StatelessWidget {
  final double lat;
  final double lng;
  final String label;

  const _MapChooserSheet({
    required this.lat,
    required this.lng,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Navigate to',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            _AppTile(
              icon: 'G',
              iconColor: Colors.white,
              iconBg: const Color(0xFF4285F4),
              title: 'Google Maps',
              subtitle: 'Open in Google Maps',
              onTap: () {
                Navigator.pop(context);
                _openGoogleMaps(lat, lng, label);
              },
            ),
            const SizedBox(height: 12),
            _AppTile(
              icon: 'W',
              iconColor: Colors.white,
              iconBg: const Color(0xFF05C8F7),
              title: 'Waze',
              subtitle: 'Open in Waze',
              onTap: () {
                Navigator.pop(context);
                _openWaze(lat, lng);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AppTile extends StatelessWidget {
  final String icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AppTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F6F1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                icon,
                style: TextStyle(
                  color: iconColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _openGoogleMaps(double lat, double lng, String label) async {
  final encoded = Uri.encodeComponent(label);
  final uri = Uri.parse(
    'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=$encoded&travelmode=driving',
  );
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    Get.snackbar(
      'Cannot open',
      'Google Maps is not available on this device',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}

Future<void> _openWaze(double lat, double lng) async {
  final uri = Uri.parse('waze://?ll=$lat,$lng&navigate=yes');
  final fallback = Uri.parse(
    'https://waze.com/ul?ll=$lat,$lng&navigate=yes',
  );
  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      await launchUrl(fallback, mode: LaunchMode.externalApplication);
    }
  } catch (_) {
    try {
      await launchUrl(fallback, mode: LaunchMode.externalApplication);
    } catch (_) {
      Get.snackbar(
        'Cannot open',
        'Waze is not available on this device',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
