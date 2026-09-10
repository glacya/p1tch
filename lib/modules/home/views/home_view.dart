import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:p2tch/app/constants/color_constants.dart';

import '../../../app/routes/app_routes.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final CategoryPalette palette = CategoryColors.defaultPalette();

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            _upperWidget(palette),
            Expanded(child: Container()),
            _centerWidget(palette),
            Expanded(child: Container()),
          ],
        ),
      ),
    );
  }

  Widget _upperWidget(CategoryPalette palette) {
    return SizedBox(
      height: 40,
      child: Row(
        spacing: 10.0,
        children: [
          Expanded(child: Container()),
          IconButton(
            icon: Icon(
              Icons.info,
              color: palette.surface,
            ),
            onPressed: () => Get.toNamed(Routes.home), // TODO: Add credit box
          ),
          IconButton(
            icon: Icon(
              Icons.settings,
              color: palette.surface
            ),
            onPressed: () => Get.toNamed(Routes.settings),
          ),
          Container(),
        ],
      )
    );
  }

  Widget _centerWidget(CategoryPalette palette) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 20.0,
      children: [
        _titleTextWidget(palette),
        IconButton(
          icon: Icon(
            Icons.play_arrow,
            color: palette.text,
            size: 60.0,
          ),
          iconSize: 60.0,
          color: palette.button,
          onPressed: () => Get.toNamed(Routes.levelCategory),
        )
      ]
    );
  }

  Widget _titleTextWidget(CategoryPalette palette) {
    return Text(
      "D E E P   P I T C H",
      textAlign: TextAlign.center,
      style: TextStyle(
        color: palette.surface,
        fontSize: 90.0,
      )  
    );
  }
}
