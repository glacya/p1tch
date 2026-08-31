import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:get/get.dart';
import 'package:p2tch/app/services/audio_service.dart';
import 'package:p2tch/app/services/level_service.dart';

import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/theme/app_theme.dart';

Future<void> main() async {
  await SoLoud.instance.init();
  await Get.putAsync<AudioService>(() => AudioService().init());
  Get.put<LevelService>(LevelService(Get.find<AudioService>()));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'P1tch',
      theme: AppTheme.light,
      initialRoute: Routes.home,
      getPages: AppPages.pages,
      debugShowCheckedModeBanner: false,
    );
  }
}