import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:p2tch/app/constants/color_constants.dart';
import 'package:p2tch/app/models/category.dart';
import 'package:p2tch/app/theme/app_theme.dart';

import '../../../app/routes/app_routes.dart';
import '../controllers/level_select_controller.dart';

class LevelSelectView extends GetView<LevelSelectController> {
  const LevelSelectView({super.key});

  static const double _buttonSize = 120.0;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LevelSelectController>(
      builder: (controller) {
        // Falls back to the core (departure) palette while loading/erroring,
        // since controller.category isn't known yet at that point.
        final palette = CategoryColors.palettes[controller.category?.categoryId] ??
            CategoryColors.palettes['departure']!;

        final Widget body;
        if (controller.isLoading) {
          body = const Center(child: CircularProgressIndicator());
        } else if (controller.errorMessage != null) {
          body = Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(controller.errorMessage!),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: controller.retry,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        } else {
          final category = controller.category!;
          body = Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              width: 6 * _buttonSize,
              height: 5 * _buttonSize,
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 5,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  // for (var levelId = 1; levelId <= category.levels; levelId++)
                  //   _levelButton(category, levelId, palette),
                  for (var levelId = 1; levelId <= 20; levelId++)
                    _levelButton(category, 1, palette)
                ],
              ),
            ),
          );
        }

        return Theme(
          data: themeFromPalette(palette),
          child: Scaffold(
            appBar: AppBar(title: const Text('Select Level')),
            body: body,
          ),
        );
      },
    );
  }

  Widget _levelButton(Category category, int levelId, CategoryPalette palette) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(_buttonSize / 10)),
        color: palette.button,
      ),
      width: _buttonSize,
      height: _buttonSize,
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(5)),
        onTap: () => Get.toNamed(
          Routes.levelPlay,
          arguments: <String, dynamic>{
            'category': category.categoryId,
            'id': levelId,
          },
        ),
        child: Center(
          child: Text(
            '$levelId',
            style: TextStyle(color: palette.buttonText),
          ),
        ),
      ),
    );
  }
}