import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

class DeepfakeController extends GetxController {
  late VideoPlayerController videoController;
  RxBool isVideoPlaying = false.obs;
  RxDouble detectionProgress = 0.0.obs;
  RxList<Map<String, dynamic>> fakeAreas = <Map<String, dynamic>>[].obs;
  int sequenceLength = 10; // Example default sequence length

  @override
  void onInit() {
    super.onInit();
    initializeVideoPlayer();
  }

  // Initialize the video player
  void initializeVideoPlayer() {
    videoController = VideoPlayerController.asset('assets/videos/your_video.mp4')
      ..initialize().then((_) {
        update(); // Refresh UI when video is initialized
      });

    videoController.addListener(videoListener);
  }

  // Video listener for detecting changes and updating the progress
  void videoListener() {
    if (videoController.value.isPlaying) {
      detectFakeAreas();
      updateProgress();
    }
  }

  // Simulate fake area detection
  void detectFakeAreas() {
    int currentTimeInSeconds = videoController.value.position.inSeconds;

    // Example: Fake area is detected every 10 seconds
    if (currentTimeInSeconds % 10 == 0) {
      fakeAreas.add({
        "time": currentTimeInSeconds,
        "rect": Rect.fromLTRB(100.0, 200.0, 300.0, 400.0),
      });
    }
  }

  // Update detection progress
  void updateProgress() {
    detectionProgress.value = videoController.value.position.inSeconds /
        videoController.value.duration.inSeconds;
  }

  // Toggle play/pause state of the video
  void toggleVideo() {
    if (videoController.value.isPlaying) {
      videoController.pause();
      isVideoPlaying.value = false;
    } else {
      videoController.play();
      isVideoPlaying.value = true;
    }
  }

  // Dispose resources when controller is destroyed
  @override
  void onClose() {
    videoController.removeListener(videoListener);
    videoController.dispose();
    super.onClose();
  }
}
