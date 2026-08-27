import 'package:get/get.dart';

import '../../modules/home/bindings/home_binding.dart';
import '../../modules/home/views/home_view.dart';
import '../../modules/level_category/bindings/level_category_binding.dart';
import '../../modules/level_category/views/level_category_view.dart';
import '../../modules/level_play/bindings/level_play_binding.dart';
import '../../modules/level_play/views/level_play_view.dart';
import '../../modules/level_select/bindings/level_select_binding.dart';
import '../../modules/level_select/views/level_select_view.dart';
import '../../modules/settings/bindings/settings_binding.dart';
import '../../modules/settings/views/settings_view.dart';
import 'app_routes.dart';

abstract class AppPages {
  AppPages._();

  static final pages = [
    GetPage(
      name: Routes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: Routes.levelCategory,
      page: () => const LevelCategoryView(),
      binding: LevelCategoryBinding(),
    ),
    GetPage(
      name: Routes.levelSelect,
      page: () => const LevelSelectView(),
      binding: LevelSelectBinding(),
    ),
    GetPage(
      name: Routes.levelPlay,
      page: () => const LevelPlayView(),
      binding: LevelPlayBinding(),
    ),
    GetPage(
      name: Routes.settings,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
    ),
  ];
}
