import 'package:face_mood_light_detector/app/bindings/initial_binding.dart';
import 'package:face_mood_light_detector/app/routes/app_pages.dart';
import 'package:face_mood_light_detector/shared/theme/detection_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FaceConditionDetectorApp());
}

class FaceConditionDetectorApp extends StatelessWidget {
  const FaceConditionDetectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Face Condition Detection',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF4CAF50),
        useMaterial3: true,
        brightness: Brightness.light,
        extensions: const <ThemeExtension<dynamic>>[DetectionTheme.light],
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF81C784),
        useMaterial3: true,
        brightness: Brightness.dark,
        extensions: const <ThemeExtension<dynamic>>[DetectionTheme.dark],
      ),
      initialBinding: InitialBinding(),
      initialRoute: AppPages.initial,
      getPages: AppPages.pages,
    );
  }
}
