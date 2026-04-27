import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/detail_controller.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../models/trip_model.dart';
import '../utils/phone_launcher.dart';
import 'widgets/trip_points_card.dart';
import 'widgets/passenger_contact_card.dart';

class DetailView extends StatelessWidget {
  const DetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final DetailController controller = Get.find<DetailController>();

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      body: SafeArea(
        child: Obx(
          () => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                // AppBar (custom)
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const Spacer(),
                    Text('Trip Details', style: AppTheme.sectionTitle),
                    const Spacer(),
                    const SizedBox(width: 48), // balance back button
                  ],
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date and time
                        Text(
                          controller.scheduledLabel.value,
                          style: AppTheme.tripTime,
                        ),
                        const SizedBox(height: 10),

                        // Trip points card
                        TripPointsCard(
                          pickupTitle: controller.pickupTitle.value,
                          pickupSubtitle: controller.pickupSubtitle.value,
                          dropoffTitle: controller.dropoffTitle.value,
                          dropoffSubtitle: controller.dropoffSubtitle.value,
                          miles: controller.distanceMiles.value,
                          mins: controller.durationMins.value,
                          pickupLat: controller.trip.pickupLat,
                          pickupLng: controller.trip.pickupLng,
                          dropoffLat: controller.trip.dropoffLat,
                          dropoffLng: controller.trip.dropoffLng,
                        ),
                        const SizedBox(height: 10),

                        // Customer contact card (only show for in-progress trips)
                        if (controller.trip.tripStatus == TripStatus.inProgress)
                          PassengerContactCard(
                            name: controller.customerName.value,
                            phone: controller.customerPhone.value,
                            onCall: () =>
                                launchPhoneDialer(controller.customerPhone.value),
                          ),

                        if (controller.trip.tripStatus == TripStatus.inProgress)
                          const SizedBox(height: 10),

                        // Flight Number Card
                        if (controller.flightNumber.value.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(
                                  color: AppColors.pillShadow,
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 35,
                                  height: 35,
                                  decoration: BoxDecoration(
                                    color: AppColors.portalOlive.withOpacity(
                                      0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.flight_outlined,
                                    color: AppColors.portalOlive,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Flight Number',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      controller.flightNumber.value,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                        if (controller.flightNumber.value.isNotEmpty)
                          const SizedBox(height: 10),

                        // Notes Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.pillShadow,
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 35,
                                height: 35,
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.note_outlined,
                                  color: Colors.amber,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Notes',
                                    style: AppTheme.titleMedium,
                                  ),
                                  Text(
                                    controller.notes.value,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color:
                                          controller.notes.value ==
                                              'No notes'
                                          ? AppColors.textSecondary
                                          : AppColors.textPrimary,
                                      fontStyle:
                                          controller.notes.value ==
                                              'No notes'
                                          ? FontStyle.italic
                                          : FontStyle.normal,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
