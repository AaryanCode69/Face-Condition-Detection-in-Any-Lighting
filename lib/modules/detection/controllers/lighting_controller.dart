import 'package:face_mood_light_detector/domain/enums/lighting_condition.dart';
import 'package:get/get.dart';

class LightingController extends GetxController {
  final lightingCondition = LightingCondition.balanced.obs;
  final estimatedLux = 300.0.obs;
  final adaptationActive = false.obs;
  final suggestion = 'Lighting conditions are good.'.obs;


}
