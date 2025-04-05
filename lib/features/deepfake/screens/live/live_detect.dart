import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import 'controller/deepfake_controller.dart';

class LiveDeepfakeDetectionScreen extends StatelessWidget {
  final DeepfakeController controller = Get.put(DeepfakeController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Live Deepfake Detection'),
        backgroundColor: Color(0xFF4b68ff),
        centerTitle: true,
      ),
      body: GetBuilder<DeepfakeController>( // Use GetBuilder to update the UI reactively
        builder: (_) {
          return Column(
            children: [
              controller.videoController.value.isInitialized
                  ? Stack(
                children: [
                  // Video Player Widget
                  AspectRatio(
                    aspectRatio: controller.videoController.value.aspectRatio,
                    child: VideoPlayer(controller.videoController),
                  ),
                  // Fake Area Overlay (rectangles showing detected fake areas)
                  ...controller.fakeAreas.map((area) {
                    return Positioned.fromRect(
                      rect: area['rect'],
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.red,
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              )
                  : Center(
                child: CircularProgressIndicator(),
              ),
              SizedBox(height: 20),
              // Detection progress bar
              LinearProgressIndicator(
                value: controller.detectionProgress.value,
                color: Colors.green,
                backgroundColor: Colors.grey[300],
              ),
              SizedBox(height: 20),
              // Play/Pause Button
              ElevatedButton(
                onPressed: controller.toggleVideo,
                child: Text(
                  controller.isVideoPlaying.value ? 'Pause Video' : 'Play Video',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4b68ff),
                  padding: EdgeInsets.symmetric(horizontal: 60, vertical: 15),
                ),
              ),
              SizedBox(height: 20),
              // Sequence Length Slider (to adjust video sequence length)
              Text(
                'Sequence Length: ${controller.sequenceLength} frames',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Slider(
                min: 10,
                max: 100,
                value: controller.sequenceLength.toDouble(),
                onChanged: (value) {
                  controller.sequenceLength = value.toInt();
                  controller.update(); // Update controller when sequence length changes
                },
                activeColor: Color(0xFF4b68ff),
                inactiveColor: Colors.grey[300],
              ),
            ],
          );
        },
      ),
    );
  }
}
