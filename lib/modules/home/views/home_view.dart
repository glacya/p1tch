import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../dev/audio_spike_view.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Puzzle Game')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Get.toNamed(Routes.levelCategory),
              child: const Text('Play'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Get.toNamed(Routes.settings),
              child: const Text('Settings'),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Get.to(() => const AudioSpikeView()),
              child: const Text('Audio Spike (temp)'),
            ),
          ],
        ),
      ),
    );
  }
}
