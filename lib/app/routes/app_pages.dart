import 'package:face_mood_light_detector/app/bindings/detection_binding.dart';
import 'package:face_mood_light_detector/app/bindings/settings_binding.dart';
import 'package:face_mood_light_detector/app/routes/app_routes.dart';
import 'package:face_mood_light_detector/modules/dashboard/views/dashboard_view.dart';
import 'package:face_mood_light_detector/modules/settings/views/settings_view.dart';
import 'package:get/get.dart';

class AppPages {
  const AppPages._();

  static const initial = AppRoutes.dashboard;

  static final pages = <GetPage<dynamic>>[
    GetPage<dynamic>(
      name: AppRoutes.dashboard,
      page: DashboardView.new,
      binding: DetectionBinding(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.settings,
      page: SettingsView.new,
      binding: SettingsBinding(),
    ),
  ];
}
