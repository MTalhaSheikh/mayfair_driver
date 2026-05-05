import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Checks the App Store / Play Store for a newer version and shows
/// a dialog if one is found. Call [checkForUpdate] on app resume or login.
class AppUpdateService {
  // ── App store links — fill in your real IDs ──────────────────────────────
  static const String _appStoreId   = '1092167591';      // iOS numeric ID
  static const String _playStoreId  = 'com.Shoaib.mayfairdrivers'; // Android package name

  /// Returns true if a newer version is available.
  Future<void> checkForUpdate({bool silent = false}) async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version; // e.g. "1.2.3"

      if (Platform.isIOS) {
        await _checkIos(currentVersion);
      } else if (Platform.isAndroid) {
        await _checkAndroid(currentVersion);
      }
    } catch (e) {
      debugPrint('AppUpdateService: check failed — $e');
    }
  }

  // ── iOS: hit iTunes lookup API ────────────────────────────────────────────
  Future<void> _checkIos(String currentVersion) async {
    final url = Uri.parse(
      'https://itunes.apple.com/lookup?id=$_appStoreId&country=us',
    );
    final response = await http.get(url).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return;

    final body = json.decode(response.body) as Map<String, dynamic>;
    final results = body['results'] as List<dynamic>?;
    if (results == null || results.isEmpty) return;

    final storeVersion = results[0]['version'] as String?;
    if (storeVersion == null) return;

    if (_isNewer(storeVersion, currentVersion)) {
      _showUpdateDialog(
        storeVersion: storeVersion,
        storeUrl: 'https://apps.apple.com/app/id$_appStoreId',
      );
    }
  }

  // ── Android: scrape Play Store page for current version ───────────────────
  Future<void> _checkAndroid(String currentVersion) async {
    final url = Uri.parse(
      'https://play.google.com/store/apps/details?id=$_playStoreId&hl=en',
    );
    final response = await http.get(url).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return;

    // Extract version from Play Store HTML
    final regex = RegExp(r'\[\[\["(\d+\.\d+\.\d+)"');
    final match = regex.firstMatch(response.body);
    final storeVersion = match?.group(1);
    if (storeVersion == null) return;

    if (_isNewer(storeVersion, currentVersion)) {
      _showUpdateDialog(
        storeVersion: storeVersion,
        storeUrl: 'https://play.google.com/store/apps/details?id=$_playStoreId',
      );
    }
  }

  // ── Compare semver strings ────────────────────────────────────────────────
  bool _isNewer(String storeVersion, String currentVersion) {
    try {
      final store   = storeVersion.split('.').map(int.parse).toList();
      final current = currentVersion.split('.').map(int.parse).toList();

      for (int i = 0; i < 3; i++) {
        final s = i < store.length   ? store[i]   : 0;
        final c = i < current.length ? current[i] : 0;
        if (s > c) return true;
        if (s < c) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ── Dialog ────────────────────────────────────────────────────────────────
  void _showUpdateDialog({
    required String storeVersion,
    required String storeUrl,
  }) {
    if (!Get.isOverlaysOpen) {
      Get.dialog(
        _UpdateDialog(storeVersion: storeVersion, storeUrl: storeUrl),
        barrierDismissible: false,
      );
    }
  }
}

class _UpdateDialog extends StatelessWidget {
  final String storeVersion;
  final String storeUrl;

  const _UpdateDialog({
    required this.storeVersion,
    required this.storeUrl,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.system_update_rounded, color: Color(0xFF8B7355)),
          SizedBox(width: 10),
          Text(
            'Update Available',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Version $storeVersion is now available. Update now to get the latest features and improvements.',
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ],
      ),
      actions: [
        // "Later" — dismissible so driver can finish current trip
        TextButton(
          onPressed: () => Get.back(),
          child: const Text(
            'Later',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            Get.back();
            final uri = Uri.parse(storeUrl);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B7355),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Update Now'),
        ),
      ],
    );
  }
}
