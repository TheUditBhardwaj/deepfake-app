import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'dart:math' as math;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import 'dart:typed_data';

class ProcessingScreen extends StatefulWidget {
  final String prediction;
  final String? explanationImageUrl;
  final Map<String, dynamic> details;
  final Uint8List? explanationImage;
  final String? videoFilePath;
  final File? videoFile;
  final int sequenceLength;

  const ProcessingScreen({
    Key? key,
    required this.prediction,
    required this.explanationImageUrl,
    required this.details,
    required this.explanationImage,
    this.videoFilePath,
    this.videoFile,
    this.sequenceLength = 3,
  }) : super(key: key);

  @override
  _ProcessingScreenState createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> with SingleTickerProviderStateMixin {
  bool _isProcessing = true;
  String _prediction = '';
  Uint8List? _explanationImage;
  String _analysisDetails = '';
  double _progress = 0.0;
  String _statusMessage = 'Preparing video for analysis...';
  String _errorDetails = '';
  bool _hasServerError = false;

  // For animation
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Create a rotation animation
    _rotationAnimation = Tween<double>(begin: 0, end: 2 * math.pi)
        .animate(_animationController);

    // Start processing
    _processVideo();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _processVideo() async {
    try {
      // Get the video from the previous screen
      final File? videoFile = await _getVideoFromPrevious();

      if (videoFile == null) {
        _showError('No video file available for processing');
        return;
      }

      // Update status
      setState(() {
        _statusMessage = 'Preparing video frames...';
        _progress = 0.2;
      });

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://805a2790255acc61ac.gradio.live/gradio_api/call/process_prediction'),
      );

      // Add request headers if needed
      request.headers.addAll({
        'Accept': 'application/json',
        'Connection': 'keep-alive',
      });

      // Add the video file
      final videoStream = http.ByteStream(videoFile.openRead());
      final videoLength = await videoFile.length();

      print('Video file size: ${videoLength / 1024 / 1024} MB');

      final multipartFile = http.MultipartFile(
        'video_file',
        videoStream,
        videoLength,
        filename: path.basename(videoFile.path),
        contentType: MediaType('video', 'mp4'),
      );

      request.files.add(multipartFile);

      // Add sequence length parameter
      request.fields['sequence_length'] = widget.sequenceLength.toString();

      // Update status
      setState(() {
        _statusMessage = 'Uploading video...';
        _progress = 0.4;
      });

      // Send the request with timeout
      final streamedResponse = await request.send().timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          throw TimeoutException('Request timed out after 5 minutes. The server might be overloaded.');
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      // Debug response
      print('Status code: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body length: ${response.body.length}');
      print('Response body prefix: ${response.body.substring(0, math.min(100, response.body.length))}');

      // Check if request was successful
      if (response.statusCode == 200) {
        // Update status
        setState(() {
          _statusMessage = 'Processing results...';
          _progress = 0.9;
        });

        try {
          // Parse the response
          final List<dynamic> result = json.decode(response.body);

          // Extract data from the response
          final String predictionResult = result[0].toString();
          String? explanationImageBase64 = result[1].toString();
          final String analysisDetails = result[2].toString();

          // Convert base64 image to bytes if not null and not empty
          Uint8List? explanationImageBytes;
          if (explanationImageBase64 != null &&
              explanationImageBase64.isNotEmpty &&
              explanationImageBase64 != "null") {
            try {
              explanationImageBytes = base64Decode(explanationImageBase64);
            } catch (e) {
              print('Error decoding image: $e');
            }
          }

          // Update the UI with results
          setState(() {
            _isProcessing = false;
            _prediction = predictionResult;
            _explanationImage = explanationImageBytes;
            _analysisDetails = analysisDetails;
            _progress = 1.0;
          });
        } catch (e) {
          _showError('Error parsing server response: $e');
        }
      } else {
        // Try to extract error details from response
        String errorMessage = 'Error processing video (Status ${response.statusCode})';
        try {
          final errorData = json.decode(response.body);
          if (errorData != null && errorData is Map) {
            if (errorData.containsKey('error')) {
              errorMessage += ': ${errorData['error']}';
            } else if (errorData.containsKey('message')) {
              errorMessage += ': ${errorData['message']}';
            }
          }
        } catch (e) {
          // If parsing fails, include a portion of the raw response
          if (response.body.isNotEmpty) {
            errorMessage += '\nResponse: ${response.body.substring(0, math.min(200, response.body.length))}';
          }
        }

        setState(() {
          _hasServerError = true;
          _errorDetails = 'Status: ${response.statusCode}\n'
              'Headers: ${response.headers}\n'
              'Body: ${response.body.substring(0, math.min(500, response.body.length))}';
        });

        _showError(errorMessage);
      }
    } on SocketException catch (e) {
      _showError('Network error: Please check your internet connection. (${e.message})');
    } on TimeoutException catch (e) {
      _showError('Request timed out: $e');
    } catch (e) {
      _showError('Error: $e');
    }
  }

  Future<File?> _getVideoFromPrevious() async {
    // Check if video file path was provided
    if (widget.videoFilePath != null && widget.videoFilePath!.isNotEmpty) {
      final file = File(widget.videoFilePath!);
      if (await file.exists()) {
        return file;
      } else {
        print('File at path ${widget.videoFilePath} does not exist');
      }
    }

    // If no file path or file doesn't exist, try using the file directly
    if (widget.videoFile != null) {
      if (await widget.videoFile!.exists()) {
        return widget.videoFile;
      } else {
        print('Provided video file does not exist');
      }
    }

    return null;
  }

  void _showError(String message) {
    setState(() {
      _isProcessing = false;
      _statusMessage = message;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'DETAILS',
          textColor: Colors.white,
          onPressed: () {
            // Show a dialog with more detailed error information
            if (_hasServerError) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Error Details'),
                  content: SingleChildScrollView(
                    child: Text(_errorDetails),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('CLOSE'),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }

  void _retryProcessing() {
    setState(() {
      _isProcessing = true;
      _progress = 0.0;
      _statusMessage = 'Preparing video for analysis...';
      _hasServerError = false;
      _errorDetails = '';
    });
    _processVideo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _isProcessing ? 'Processing Video' : 'Analysis Results',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_hasServerError)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _retryProcessing,
              tooltip: 'Retry',
            ),
        ],
      ),
      body: _isProcessing ? _buildProcessingView() : _buildResultsView(),
    );
  }

  Widget _buildProcessingView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Animated loading indicator
          AnimatedBuilder(
            animation: _rotationAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationAnimation.value,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: SweepGradient(
                      colors: [
                        Colors.blue.shade700.withOpacity(0.0),
                        Colors.blue.shade700.withOpacity(0.1),
                        Colors.blue.shade700.withOpacity(0.3),
                        Colors.blue.shade700.withOpacity(0.5),
                        Colors.blue.shade700.withOpacity(0.7),
                        Colors.blue.shade700.withOpacity(0.9),
                        Colors.blue.shade700,
                      ],
                      stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 0.9, 1.0],
                      tileMode: TileMode.clamp,
                    ),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1117),
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 40),

          // Status message
          Text(
            _statusMessage,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Progress bar
          Container(
            width: double.infinity,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              widthFactor: _progress,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade700, Colors.blue.shade500],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Progress percentage
          Text(
            '${(_progress * 100).toInt()}%',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 40),

          // Tips during processing
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a1a),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.05),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.amber[400], size: 20),
                    const SizedBox(width: 10),
                    const Text(
                      'Processing Tips',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Analysis time depends on video length and complexity. Our AI is looking for inconsistencies in facial movements, unnatural lighting, and digital artifacts.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsView() {
    // Calculate the prediction confidence color
    Color confidenceColor = Colors.grey;
    if (_prediction.toLowerCase().contains('real')) {
      confidenceColor = Colors.green;
    } else if (_prediction.toLowerCase().contains('fake')) {
      confidenceColor = Colors.red;
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Result header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF303030), Color(0xFF1a1a1a)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: confidenceColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: confidenceColor.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    _prediction.toLowerCase().contains('real')
                        ? Icons.check_circle_outline
                        : Icons.error_outline,
                    color: confidenceColor,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Analysis Result',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _prediction.isEmpty ? 'Analysis failed' : _prediction,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Explanation visualization
          if (_explanationImage != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Explanation Visualization',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1a1a1a),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(
                      _explanationImage!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This visualization shows the regions of the video that were analyzed for potential manipulation.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),

          const SizedBox(height: 30),

          // Analysis details
          const Text(
            'Analysis Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a1a),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.05),
                width: 1,
              ),
            ),
            child: Text(
              _analysisDetails.isNotEmpty ? _analysisDetails : _hasServerError ?
              'Analysis failed. Please check network connection and try again.' :
              'No detailed analysis available.',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                height: 1.6,
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.replay, size: 18),
                  label: const Text(
                    'ANALYZE ANOTHER',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _hasServerError ? _retryProcessing : () {
                    // Implement share functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sharing feature coming soon!')),
                    );
                  },
                  icon: Icon(_hasServerError ? Icons.refresh : Icons.share, size: 18),
                  label: Text(
                    _hasServerError ? 'RETRY ANALYSIS' : 'SHARE RESULTS',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hasServerError ? Colors.orange : Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: _hasServerError ?
                    Colors.orange.withOpacity(0.5) :
                    Colors.blue.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}