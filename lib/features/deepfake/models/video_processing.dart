import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../deepfake_results/deepfake_service.dart';
import '../deepfake_results/final_result.dart'; // You'll need to add this package

class VideoProcessingScreen extends StatefulWidget {
  const VideoProcessingScreen({Key? key}) : super(key: key);

  @override
  _VideoProcessingScreenState createState() => _VideoProcessingScreenState();
}

class _VideoProcessingScreenState extends State<VideoProcessingScreen> {
  File? _videoFile;
  bool _isLoading = false;
  final DeepfakeService _deepfakeService = DeepfakeService();
  final int _sequenceLength = 20; // Default sequence length, adjust as needed
  String _statusMessage = '';

  Future<void> _pickVideo() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedVideo = await picker.pickVideo(source: ImageSource.gallery);

      if (pickedVideo != null) {
        setState(() {
          _videoFile = File(pickedVideo.path);
          _statusMessage = 'Video selected. Ready to analyze.';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error selecting video: $e';
      });
    }
  }

  Future<void> _analyzeVideo() async {
    if (_videoFile == null) {
      setState(() {
        _statusMessage = 'Please select a video first';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Analyzing video...';
    });

    try {
      // Call API service
      final result = await _deepfakeService.analyzeVideo(_videoFile!, _sequenceLength);

      if (!mounted) return;

      if (result.hasError) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Analysis failed: ${result.errorMessage}';
        });
      } else {
        // Navigate to results screen
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

        setState(() {
          _isLoading = false;
          _statusMessage = 'Analysis complete';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error analyzing video: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Deepfake Detection', style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Video preview or placeholder
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: _videoFile != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Center(child: Text('Video Selected', style: TextStyle(color: Colors.white))),
                )
                    : Icon(Icons.videocam, size: 50, color: Colors.grey[700]),
              ),
              SizedBox(height: 30),

              // Status message
              if (_statusMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Text(
                    _statusMessage,
                    style: TextStyle(color: Colors.grey[400]),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Select video button
              ElevatedButton.icon(
                icon: Icon(Icons.video_library),
                label: Text('Select Video'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isLoading ? null : _pickVideo,
              ),
              SizedBox(height: 15),

              // Analyze button
              ElevatedButton.icon(
                icon: _isLoading
                    ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Icon(Icons.search),
                label: Text(_isLoading ? 'Analyzing...' : 'Analyze Video'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isLoading ? null : _analyzeVideo,
              ),
            ],
          ),
        ),
      ),
    );
  }
}