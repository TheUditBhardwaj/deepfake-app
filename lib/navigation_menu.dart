import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hacachino/features/deepfake/models/video_processing.dart';
import 'package:hacachino/features/deepfake/screens/home/home.dart';
import 'package:hacachino/utils/constants/colors.dart';
import 'package:hacachino/utils/helpers/helper_functions.dart';
import 'package:iconsax/iconsax.dart';

import 'features/deepfake/screens/chatbot/chatbot_screen.dart';
import 'features/deepfake/screens/live/live_detect.dart';
import 'features/personalization/screens/settings/settings.dart';

// Root navigation menu with bottom navigation
class NavigationMenu extends StatelessWidget {
  const NavigationMenu({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize NavigationController using Get.put() to make sure it's available
    final controller = Get.put(NavigationController());
    final darkMode = THelperFunctions.isDarkMode(context);
    return Scaffold(
      bottomNavigationBar: Obx(() {
        return NavigationBar(
          height: 70,  // Height of the bottom navigation bar
          elevation: 0,
          selectedIndex: controller.selectedIndex.value,
          onDestinationSelected: (index) => controller.selectedIndex.value = index,
          backgroundColor: darkMode ? TColors.black : Colors.white,
          indicatorColor: darkMode
              ? TColors.white.withOpacity(0.1)
              : TColors.black.withOpacity(0.1),
          destinations: const [
            NavigationDestination(
              icon: Icon(Iconsax.home, size: 30),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Iconsax.airdrop, size: 30),
              label: 'Chat bot',
            ),
            NavigationDestination(
              icon: Icon(Iconsax.camera, size: 30),
              label: 'Live',
            ),
            NavigationDestination(
              icon: Icon(Iconsax.user, size: 30),
              label: 'Settings',
            ),
          ],
        );
      }),
      body: Obx(() {
        return controller.screens[controller.selectedIndex.value];
      }),
    );
  }
}

class NavigationController extends GetxController {
  final Rx<int> selectedIndex = 0.obs;  // To keep track of the selected tab index

  // List of screens to be displayed based on the selected tab
  final screens = [
    HomeScreen(),
    ChatbotScreen(),
    // LiveDeepfakeDetectionScreen(),
    VideoProcessingScreen(),
    SettingsScreen(),
  ];
}
