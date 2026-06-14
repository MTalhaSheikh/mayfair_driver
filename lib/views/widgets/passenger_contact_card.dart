import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import 'pickup_sign_screen.dart';

class PassengerContactCard extends StatelessWidget {
  final String name;
  final String phone;
  final VoidCallback? onChat;
  final VoidCallback? onCall;

  const PassengerContactCard({
    super.key,
    required this.name,
    required this.phone,
    this.onChat,
    this.onCall,
  });

  void _copyValue(BuildContext context, String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    Get.snackbar(
      'Copied',
      '$label copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      backgroundColor: AppColors.portalOlive,
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
    );
  }

  void _showCopyOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.person_outline, color: AppColors.portalOlive),
                title: const Text('Copy Name'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _copyValue(context, 'Name', name);
                },
              ),
              ListTile(
                leading: const Icon(Icons.call_outlined, color: AppColors.portalOlive),
                title: const Text('Copy Phone Number'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _copyValue(context, 'Phone number', phone);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.softCardShadow,
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.portalOlive, width: 2),
              color: const Color(0xFFE5E7EB),
            ),
            child: const Icon(Icons.person, color: Colors.black54, size: 20),
          ),
          const SizedBox(width: 14),

          // Long press on name+phone area to choose: copy name or copy number
          Expanded(
            child: GestureDetector(
              onLongPress: () => _showCopyOptions(context),
              child: Container(
                color: Colors.transparent, // needed for gesture to work
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTheme.locationTitle),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(phone, style: AppTheme.welcomeSubtitle),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.copy,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Pickup sign button
          _IconButton(
            icon: Icons.contact_page_outlined,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PickupSignScreen(
                  passengerName: name,
                  companyName: 'MayFair Limousine',
                ),
                  fullscreenDialog: true,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          _IconButton(icon: Icons.call_outlined, onTap: onCall),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _IconButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Color(0xFFF3F4F6),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 20),
      ),
    );
  }
}