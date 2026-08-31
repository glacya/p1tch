import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:p2tch/app/utils/locale_utils.dart';

import '../../../app/routes/app_routes.dart';
import '../controllers/level_category_controller.dart';

class LevelCategoryView extends GetView<LevelCategoryController> {
  const LevelCategoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Category')),
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

          final localeKeyValue = currentLocaleKey();

          // SingleChildScrollView + a plain Column (no Expanded/Flexible
          // children) renders statically when everything fits and only
          // scrolls once content overflows - no item-count branching needed.
          return Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  for (final category in controller.categories)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 16,
                      ),
                      child: ElevatedButton(
                        onPressed: () => Get.toNamed(
                          Routes.levelSelect,
                          arguments: <String, dynamic>{
                            'categoryId': category.categoryId,
                          },
                        ),
                        child: Text(category.nameFor(localeKeyValue)),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
