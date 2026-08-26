import 'package:flutter/material.dart';

import '../controllers/level_play_controller.dart';
import 'package:get/get.dart';

class LevelPlayView extends GetView<LevelPlayController> {
  const LevelPlayView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Level')),
      // Back navigation to Select Level uses the default AppBar back button.
      body: const Center(child: Text('TODO: puzzle board')),
    );
  }
}
