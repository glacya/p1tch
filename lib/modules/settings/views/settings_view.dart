import 'package:flutter/material.dart';

import '../controllers/settings_controller.dart';
import 'package:get/get.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      // Back navigation to Home uses the default AppBar back button.
      body: const Center(child: Text('TODO: settings')),
    );
  }
}
