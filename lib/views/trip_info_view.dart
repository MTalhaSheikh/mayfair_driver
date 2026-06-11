import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mayfair_driver/controllers/detail_controller.dart';
import '../controllers/trip_info_controller.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../utils/phone_launcher.dart';
import '../views/widgets/passenger_contact_card.dart';
import '../views/widgets/slide_action_button.dart';
import '../views/widgets/trip_points_card.dart';

class TripInfoView extends StatelessWidget {
  const TripInfoView({super.key});

  @override
  Widget build(BuildContext context) {
    final TripInfoController tripInfoController = Get.find<TripInfoController>();
    final DetailController detailController = Get.find<DetailController>();

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
                    Text(
                      tripInfoController.stageTitle,
                      style: AppTheme.sectionTitle,
                    ),
                    const Spacer(),
                    // Copy all trip details button
                    IconButton(
                      onPressed: () {
                        final buffer = StringBuffer();
                        buffer.writeln('=== TRIP DETAILS ===');
                        buffer.writeln('Date & Time: ${tripInfoController.scheduledLabel.value}');
                        buffer.writeln('');
                        buffer.writeln('PICKUP');
                        buffer.writeln('${tripInfoController.pickupTitle.value}');
                        if (tripInfoController.pickupSubtitle.value.isNotEmpty)
                          buffer.writeln('${tripInfoController.pickupSubtitle.value}');
                        buffer.writeln('');
                        buffer.writeln('DROP-OFF');
                        buffer.writeln('${tripInfoController.dropoffTitle.value}');
                        if (tripInfoController.dropoffSubtitle.value.isNotEmpty)
                          buffer.writeln('${tripInfoController.dropoffSubtitle.value}');
                        buffer.writeln('');
                        if (tripInfoController.distanceMiles.value > 0)
                          buffer.writeln('Distance: ${tripInfoController.distanceMiles.value.toStringAsFixed(1)} miles');
                        if (tripInfoController.durationMins.value > 0) {
                          final hrs = tripInfoController.durationMins.value ~/ 60;
                          final mins = tripInfoController.durationMins.value % 60;
                          if (hrs > 0)
                            buffer.writeln('Duration: ~${hrs}h ${mins}m');
                          else
                            buffer.writeln('Duration: ~${mins} mins');
                        }
                        if (tripInfoController.passengerName.value.isNotEmpty &&
                            tripInfoController.passengerName.value != 'Customer') {
                          buffer.writeln('');
                          buffer.writeln('PASSENGER');
                          buffer.writeln('Name: ${tripInfoController.passengerName.value}');
                          if (tripInfoController.passengerPhone.value.isNotEmpty &&
                              tripInfoController.passengerPhone.value != 'No phone')
                            buffer.writeln('Phone: ${tripInfoController.passengerPhone.value}');
                        }

                        if (tripInfoController.notes.value.isNotEmpty &&
                            tripInfoController.notes.value != 'No notes') {
                          buffer.writeln('');
                          buffer.writeln('Notes: ${tripInfoController.notes.value}');
                        }

                        Clipboard.setData(ClipboardData(text: buffer.toString()));
                        Get.snackbar(
                          'Copied!',
                          'Trip details copied to clipboard',
                          snackPosition: SnackPosition.BOTTOM,
                          duration: const Duration(seconds: 2),
                          backgroundColor: AppColors.portalOlive,
                          colorText: Colors.white,
                          margin: const EdgeInsets.all(12),
                          borderRadius: 12,
                          icon: const Icon(Icons.check_circle, color: Colors.white),
                        );
                      },
                      icon: const Icon(Icons.copy_outlined),
                      tooltip: 'Copy trip details',
                    ),
                  ],
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onLongPress: () {
                            Clipboard.setData(ClipboardData(
                                text: tripInfoController.scheduledLabel.value));
                            Get.snackbar(
                              'Copied',
                              'Date & time copied to clipboard',
                              snackPosition: SnackPosition.BOTTOM,
                              duration: const Duration(seconds: 2),
                              backgroundColor: AppColors.portalOlive,
                              colorText: Colors.white,
                              margin: const EdgeInsets.all(12),
                              borderRadius: 12,
                            );
                          },
                          child: Text(
                            tripInfoController.scheduledLabel.value,
                            style: AppTheme.tripTime,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TripPointsCard(
                          pickupTitle: tripInfoController.pickupTitle.value,
                          pickupSubtitle: tripInfoController.pickupSubtitle.value,
                          dropoffTitle: tripInfoController.dropoffTitle.value,
                          dropoffSubtitle: tripInfoController.dropoffSubtitle.value,
                          miles: tripInfoController.distanceMiles.value,
                          mins: tripInfoController.durationMins.value,
                          pickupLat: tripInfoController.trip.pickupLat,
                          pickupLng: tripInfoController.trip.pickupLng,
                          dropoffLat: tripInfoController.trip.dropoffLat,
                          dropoffLng: tripInfoController.trip.dropoffLng,
                        ),
                        const SizedBox(height: 10),
                        PassengerContactCard(
                          name: tripInfoController.passengerName.value,
                          phone: tripInfoController.passengerPhone.value,
                          onChat: () {},
                          onCall: () => launchPhoneDialer(
                              tripInfoController.passengerPhone.value),
                        ),
                        const SizedBox(height: 10),


                        // Flight Number Card
                        if (detailController.flightNumber.value.isNotEmpty)
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
                            child: GestureDetector(
                              onLongPress: () {
                                Clipboard.setData(ClipboardData(
                                    text: detailController.flightNumber.value));
                                Get.snackbar(
                                  'Copied',
                                  'Flight number copied to clipboard',
                                  snackPosition: SnackPosition.BOTTOM,
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: AppColors.portalOlive,
                                  colorText: Colors.white,
                                  margin: const EdgeInsets.all(12),
                                  borderRadius: 12,
                                );
                              },
                              child: Row(
                                children: [
                                  Container(
                                    width: 35,
                                    height: 35,
                                    decoration: BoxDecoration(
                                      color: AppColors.portalOlive.withOpacity(0.1),
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
                                        detailController.flightNumber.value,
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
                          ),

                           if (detailController.notes.value.isNotEmpty)
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
                          child: GestureDetector(
                            onLongPress: () {
                              if (detailController.notes.value.isNotEmpty &&
                                  detailController.notes.value != 'No notes') {
                                Clipboard.setData(ClipboardData(
                                    text: detailController.notes.value));
                                Get.snackbar(
                                  'Copied',
                                  'Notes copied to clipboard',
                                  snackPosition: SnackPosition.BOTTOM,
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: AppColors.portalOlive,
                                  colorText: Colors.white,
                                  margin: const EdgeInsets.all(12),
                                  borderRadius: 12,
                                );
                              }
                            },
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
                                      detailController.notes.value,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color:
                                            detailController.notes.value ==
                                                'No notes'
                                            ? AppColors.textSecondary
                                            : AppColors.textPrimary,
                                        fontStyle:
                                            detailController.notes.value ==
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
                        ),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SlideActionButton(
                    label: tripInfoController.stageTitle,
                    leadingIcon: _stageIcon(tripInfoController.stage.value),
                    // isLoading: tripInfoController.isUpdatingStatus.value,
                    isLoading: false,
                    onCompleted: () {
                      tripInfoController.advanceStage();
                    },
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

IconData _stageIcon(TripProgressStage stage) {
  switch (stage) {
    case TripProgressStage.onTheWay:
      return Icons.directions_car_filled_outlined;
    case TripProgressStage.pickPassenger:
      return Icons.location_on_outlined;
    case TripProgressStage.arrived:
      return Icons.emoji_people_outlined;
    case TripProgressStage.finishedTrip:
      return Icons.luggage_outlined;
  }
}