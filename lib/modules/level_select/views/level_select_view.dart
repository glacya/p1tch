import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../controllers/level_select_controller.dart';

class LevelSelectView extends GetView<LevelSelectController> {
  const LevelSelectView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Level')),
      body: GetBuilder<LevelSelectController>(
        builder: (controller) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.errorMessage != null) {
            return Center(
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
          }

          final category = controller.category!;
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 5,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: [
                  for (var levelId = 1; levelId <= category.levels; levelId++)
                    ElevatedButton(
                      onPressed: () => Get.toNamed(
                        Routes.levelPlay,
                        arguments: <String, dynamic>{
                          // The level file's folder id (e.g. "departure"),
                          // not the localized display name - LevelService
                          // uses this to build the asset path directly.
                          'category': category.categoryId,
                          'id': levelId,
                        },
                      ),
                      child: Text('$levelId'),
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
