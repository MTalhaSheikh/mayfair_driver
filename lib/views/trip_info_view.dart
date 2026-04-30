import 'package:flutter/material.dart';
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
                    const SizedBox(width: 48), // balance back button
                  ],
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tripInfoController.scheduledLabel.value,
                          style: AppTheme.tripTime,
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
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SlideActionButton(
                    label: tripInfoController.stageTitle,
                    leadingIcon: _stageIcon(tripInfoController.stage.value),
                    isLoading: tripInfoController.isUpdatingStatus.value,
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

