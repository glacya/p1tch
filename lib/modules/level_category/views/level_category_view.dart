import 'package:flutter/material.dart';

import '../../../app/routes/app_routes.dart';
import '../controllers/level_category_controller.dart';
import 'package:get/get.dart';

class LevelCategoryView extends GetView<LevelCategoryController> {
  const LevelCategoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Category')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => Get.toNamed(Routes.levelSelect),
          child: const Text('Category 1'),
        ),
      ),
    );
  }
}
