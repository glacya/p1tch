import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:p2tch/app/constants/color_constants.dart';
import 'package:p2tch/app/models/category.dart';
import 'package:p2tch/app/utils/locale_utils.dart';

import '../../../app/routes/app_routes.dart';
import '../controllers/level_category_controller.dart';

class LevelCategoryView extends GetView<LevelCategoryController> {
  const LevelCategoryView({super.key});

  static const double _buttonSize = 100.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<LevelCategoryController>(
        builder: (controller) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
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
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                _upperWidget(),
                Expanded(child: Container()),
                _centerWidget(controller.categories),
                Expanded(child: Container()),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _upperWidget() {
    final palette = CategoryColors.defaultPalette();

    return SizedBox(
      height: 40,
      child: Row(
        spacing: 10.0,
        children: [
          Container(),
          IconButton(
            icon: Icon(
              Icons.chevron_left,
              color: palette.surface,
            ),
            onPressed: () => Get.back(),
          ),
          Expanded(child: Container())
        ],
      )
    );
  }

  Widget _centerWidget(List<Category> categories) {
    return SingleChildScrollView(
        child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 12.0,
        children: controller.categories.map((c) => _categoryButton(c)).toList(),
      )
    );
  }

  Widget _categoryButton(Category category) {
    final palette = CategoryColors.palettes[category.categoryId]!;
    final localeKeyValue = currentLocaleKey();

    return Container(
      width: _buttonSize * 4.0,
      height: _buttonSize,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(_buttonSize / 10)),
        color: palette.button,
      ),
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(_buttonSize / 10)),
        onTap: () => Get.toNamed(
          Routes.levelSelect,
          arguments: <String, dynamic>{
            'categoryId': category.categoryId,
          },
        ),
        child: Center(
          child: Text(
            category.nameFor(localeKeyValue),
            style: TextStyle(color: palette.buttonText),
          ),
        ),
      )
    );
  }
}
