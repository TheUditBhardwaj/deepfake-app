import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../deepfake_results/deepfake_service.dart';
import '../deepfake_results/final_result.dart';

class VideoProcessingScreen extends StatefulWidget {
  const VideoProcessingScreen({Key? key}) : super(key: key);

  @override
  _VideoProcessingScreenState createState() => _VideoProcessingScreenState();
}

class _VideoProcessingScreenState extends State<VideoProcessingScreen> {
  File? _videoFile;
  bool _isLoading = false;
  final DeepfakeService _deepfakeService = DeepfakeService();
  final int _sequenceLength = 10;
  String _userName = "Ajay Kumar Dewangan"; // User name from the UI

  Future<void> _pickVideo() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedVideo = await picker.pickVideo(source: ImageSource.gallery);

      if (pickedVideo != null) {
        setState(() {
          _videoFile = File(pickedVideo.path);
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _analyzeVideo() async {
    if (_videoFile == null) {
      // Show a snackbar or toast instead of updating status message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a video first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _deepfakeService.analyzeVideo(_videoFile!, );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (result.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analysis failed: ${result.errorMessage}'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultsScreen(
              prediction: result.prediction,
              explanationImageUrl: result.gradcamImageUrl,
              details: result.details,
              explanationImage: result.explanationImage,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error analyzing video: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF080A0F),
      body: SafeArea(
        child: Column(
          children: [
            // Top section with user greeting and notification
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF6C3CE9), Color(0xFF3B43E2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Icon(Icons.arrow_downward, color: Colors.white),
                        ),
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hi, $_userName',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Ready to analyze?',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.notifications_outlined, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Main content - Video selection card
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      // Video selection card
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Color(0xFF1D1F26),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          children: [
                            Container(
                              height: 240,
                              margin: EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: Color(0xFF14161D),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: Color(0xFF1C92E9),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.video_library_outlined,
                                        color: Colors.white,
                                        size: 36,
                                      ),
                                    ),
                                    SizedBox(height: 20),
                                    Text(
                                      'Select a video to analyze',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      "We'll scan it for any potential manipulations",
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _pickVideo,
                              icon: Icon(Icons.video_library_outlined),
                              label: Text('SELECT'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _analyzeVideo,
                              child: _isLoading
                                  ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                                  : Icon(Icons.arrow_forward),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF555555),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 32),

                      // Recent detections section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF6C3CE9),
                                ),
                                child: Icon(Icons.history, color: Colors.white),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'RECENT DETECTIONS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              // Handle view all
                            },
                            child: Row(
                              children: [
                                Text(
                                  'VIEW ALL',
                                  style: TextStyle(
                                    color: Color(0xFF3B86CA),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Icon(Icons.chevron_right, color: Color(0xFF3B86CA)),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16),

                      // Recent detection items
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetectionItem(
                              'FAKE',
                              '2 hours ago',
                              'assets/dog_image.jpg',
                              Colors.red,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildDetectionItem(
                              'REAL',
                              'Yesterday',
                              'assets/dog_image.jpg',
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom navigation

          ],
        ),
      ),
    );
  }

  Widget _buildDetectionItem(String status, String time, String imagePath, Color statusColor) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Color(0xFF1D1F26),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: Colors.grey[600],
                    size: 36,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  time,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: statusColor, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                status == 'FAKE' ? Icons.warning : Icons.check_circle,
                color: statusColor,
                size: 16,
              ),
              SizedBox(width: 4),
              Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Detection details',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          'Tap to view full analysis',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: isActive ? Colors.white : Colors.grey,
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}