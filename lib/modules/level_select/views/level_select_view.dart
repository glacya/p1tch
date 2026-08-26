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
      body: Center(
        // TODO: replace with a real level list once levels are modeled.
        child: ElevatedButton(
          onPressed: () => Get.toNamed(Routes.levelPlay),
          child: const Text('Level 1'),
        ),
      ),
    );
  }
}
