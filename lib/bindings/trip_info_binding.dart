import 'package:get/get.dart';
import 'package:mayfair_driver/controllers/detail_controller.dart';

import '../controllers/trip_info_controller.dart';

class TripInfoBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TripInfoController>(() => TripInfoController());
    Get.lazyPut<DetailController>(() => DetailController());
  }
}

