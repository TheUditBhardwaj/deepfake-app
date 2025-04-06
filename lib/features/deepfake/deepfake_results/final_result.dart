import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart'; // Correct import

class ResultsScreen extends StatefulWidget {
  final String prediction;
  final String? explanationImageUrl;
  final Map<String, dynamic> details;
  final Uint8List? explanationImage;
  final double confidenceScore;

  const ResultsScreen({
    Key? key,
    required this.prediction,
    this.explanationImageUrl,
    required this.details,
    this.explanationImage,
    this.confidenceScore = 0.0,
  }) : super(key: key);

  @override
  _ResultsScreenState createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  bool _isImageExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.2, 0.7, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDeepfake = widget.prediction.toLowerCase().contains('deepfake');
    final confidenceValue = widget.confidenceScore > 0
        ? widget.confidenceScore
        : _getConfidenceValue();

    return Scaffold(
      backgroundColor: Color(0xFF121212), // Darker background for better contrast
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: Colors.white),
            onPressed: () {
              HapticFeedback.mediumImpact();
              // Add share functionality here
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Sharing result...'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 60, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isDeepfake),
                  SizedBox(height: 30),
                  _buildPredictionCard(isDeepfake, confidenceValue),
                  SizedBox(height: 30),
                  if (widget.explanationImage != null || widget.explanationImageUrl != null)
                    _buildExplanationSection(),
                  SizedBox(height: 20),
                  if (widget.details.isNotEmpty)
                    _buildDetailsSection(),
                  SizedBox(height: 40),
                  _buildActionButtons(isDeepfake),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isDeepfake) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: Tween<Offset>(begin: Offset(0, -0.3), end: Offset.zero).animate(_controller),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDeepfake ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isDeepfake ? Icons.warning_rounded : Icons.verified_rounded,
                    color: isDeepfake ? Colors.red[400] : Colors.green[400],
                    size: 28,
                  ),
                ),
                SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analysis Complete',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      isDeepfake ? 'Potential manipulation detected' : 'No manipulation detected',
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[400],
                          letterSpacing: 0.3
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionCard(bool isDeepfake, double confidenceValue) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDeepfake
                ? [Colors.red[900]!.withOpacity(0.4), Colors.red[800]!.withOpacity(0.2)]
                : [Colors.green[900]!.withOpacity(0.4), Colors.green[800]!.withOpacity(0.2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDeepfake ? Colors.red[700]! : Colors.green[700]!,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDeepfake ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
              blurRadius: 15,
              spreadRadius: -5,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDeepfake
                        ? Colors.red[900]!.withOpacity(0.5)
                        : Colors.green[900]!.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isDeepfake ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                        color: isDeepfake ? Colors.red[300] : Colors.green[300],
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Text(
                        isDeepfake ? 'DEEPFAKE DETECTED' : 'AUTHENTIC CONTENT',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            _buildConfidenceIndicator(confidenceValue, isDeepfake),
            SizedBox(height: 16),
            Text(
              isDeepfake
                  ? 'This content shows signs of artificial manipulation or generation.'
                  : 'This content appears to be authentic without signs of manipulation.',
              style: TextStyle(color: Colors.grey[300], fontSize: 14, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceIndicator(double confidence, bool isDeepfake) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Confidence Level',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            Text(
              '${(confidence * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 8,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0.0, end: confidence),
              duration: Duration(milliseconds: 1500),
              builder: (context, double value, child) {
                return Container(
                  height: 8,
                  width: MediaQuery.of(context).size.width * 0.8 * value,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDeepfake
                          ? [Colors.red[700]!, Colors.red[400]!]
                          : [Colors.green[700]!, Colors.green[400]!],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExplanationSection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero).animate(_controller),
        child: Container(
          margin: EdgeInsets.only(bottom: 5),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Visual Analysis',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isImageExpanded = !_isImageExpanded;
                      });
                    },
                    child: Icon(
                      _isImageExpanded ? Icons.fullscreen_exit : Icons.fullscreen,
                      color: Colors.grey[400],
                      size: 22,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),
              GestureDetector(
                onTap: () {
                  _showFullScreenImage();
                },
                child: Hero(
                  tag: 'explanation_image',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      height: _isImageExpanded ? 300 : 200,
                      width: double.infinity,
                      child: _buildExplanationImage(),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Tap image to view fullscreen analysis',
                style: TextStyle(color: Colors.grey[500], fontSize: 12, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExplanationImage() {
    // First prioritize memory image if available
    if (widget.explanationImage != null) {
      return Image.memory(
        widget.explanationImage!,
        fit: BoxFit.cover,
      );
    }
    // Then try to load from URL if available
    else if (widget.explanationImageUrl != null) {
      return CachedNetworkImage(
        imageUrl: widget.explanationImageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[900],
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              strokeWidth: 2,
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[900],
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: Colors.red[300], size: 30),
                SizedBox(height: 8),
                Text(
                  'Failed to load image',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }
    // Fallback if neither is available
    else {
      return Container(
        color: Colors.grey[900],
        child: Center(
          child: Text(
            'No analysis image available',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ),
      );
    }
  }

  void _showFullScreenImage() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        pageBuilder: (BuildContext context, _, __) {
          return Scaffold(
            backgroundColor: Colors.black.withOpacity(0.9),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.white),
            ),
            body: Center(
              child: InteractiveViewer(
                panEnabled: true,
                boundaryMargin: EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 4,
                child: Hero(
                  tag: 'explanation_image',
                  child: widget.explanationImage != null
                      ? Image.memory(widget.explanationImage!)
                      : widget.explanationImageUrl != null
                      ? CachedNetworkImage(
                    imageUrl: widget.explanationImageUrl!,
                    placeholder: (context, url) => Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  )
                      : Container(
                    color: Colors.grey[900],
                    child: Center(
                      child: Text(
                        'No image available',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailsSection() {
    final sortedEntries = widget.details.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero).animate(_controller),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analysis Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              SizedBox(height: 15),
              ...sortedEntries.map((entry) => Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDetailLabel(entry.key),
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _formatDetailValue(entry.value),
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500
                      ),
                    ),
                    SizedBox(height: 12),
                    Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                  ],
                ),
              )).toList(),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDetailLabel(String key) {
    // Convert snake_case or camelCase to Title Case with spaces
    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}')
        .replaceAll('_', ' ')
        .trim()
        .split(' ')
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
        .join(' ');
  }

  String _formatDetailValue(dynamic value) {
    if (value is double) {
      return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
    } else {
      return value.toString();
    }
  }

  Widget _buildActionButtons(bool isDeepfake) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.white.withOpacity(0.07),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
              ),
              child: Text(
                'Back to Scanner',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                // Add functionality to report or save the result
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Report submitted')),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                backgroundColor: isDeepfake ? Colors.red[700] : Colors.green[700],
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                isDeepfake ? 'Report Deepfake' : 'Verify Result',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getConfidenceValue() {
    // First try to extract percentage from prediction string
    final RegExp percentRegex = RegExp(r'(\d+\.\d+)%');
    final match = percentRegex.firstMatch(widget.prediction);
    if (match != null) {
      return double.parse(match.group(1)!) / 100;
    }

    // If no match in the prediction string, check details for confidence value
    if (widget.details.containsKey('confidence') && widget.details['confidence'] is num) {
      double confidence = (widget.details['confidence'] as num).toDouble();
      // Ensure the confidence is between 0 and 1
      return confidence > 1 ? confidence / 100 : confidence;
    }

    // Default fallback
    return 0.85;
  }
}

// Updated DeepfakeResult class to better handle images from FastAPI
class DeepfakeResult {
  final String prediction;
  final double confidenceScore;
  final String? gradcamImageUrl;
  final Uint8List? explanationImage;
  final Map<String, dynamic> details;
  final bool hasError;
  final String errorMessage;

  // Constructor
  DeepfakeResult({
    required this.prediction,
    required this.confidenceScore,
    this.gradcamImageUrl,
    this.explanationImage,
    this.details = const {},
    this.hasError = false,
    this.errorMessage = '',
  });

  // Factory constructor to create DeepfakeResult from API response
  factory DeepfakeResult.fromApiResponse(Map<String, dynamic> json) {
    // Handle explanation image from FastAPI (could be base64 string or URL)
    Uint8List? explanationImageBytes;
    String? explanationImageUrl;

    if (json['explanation_image'] != null) {
      if (json['explanation_image'] is String) {
        try {
          // Try to decode as base64
          explanationImageBytes = Uint8List.fromList(base64Decode(json['explanation_image']));
        } catch (e) {
          // If not base64, treat as URL
          explanationImageUrl = json['explanation_image'];
        }
      }
    } else if (json['gradcam_image'] != null) {
      try {
        // Try to decode as base64
        explanationImageBytes = Uint8List.fromList(base64Decode(json['gradcam_image']));
      } catch (e) {
        // If not base64, might be URL or something else
        explanationImageUrl = json['gradcam_image_url'] ?? json['gradcam_image'];
      }
    }

    // Get confidence score from various possible fields
    double confidenceScore = 0.0;
    if (json['confidence_score'] != null) {
      confidenceScore = json['confidence_score']?.toDouble() ?? 0.0;
    } else if (json['confidence'] != null) {
      confidenceScore = json['confidence']?.toDouble() ?? 0.0;
    } else if (json['score'] != null) {
      confidenceScore = json['score']?.toDouble() ?? 0.0;
    }

    // Normalize confidence score if needed
    if (confidenceScore > 1.0) {
      confidenceScore = confidenceScore / 100;
    }

    return DeepfakeResult(
      prediction: json['prediction'] ?? 'Unknown',
      confidenceScore: confidenceScore,
      gradcamImageUrl: json['gradcam_image_url'] ?? explanationImageUrl,
      explanationImage: explanationImageBytes,
      details: json['details'] ?? {},
      hasError: json['error'] ?? false,
      errorMessage: json['error_message'] ?? '',
    );
  }
}

// Example usage in a service class
class DeepfakeDetectionService {
  // Function to fetch results from FastAPI
  Future<DeepfakeResult> analyzeImage(Uint8List imageBytes) async {
    try {
      // Implement your FastAPI call here using http or dio package
      // For example (pseudo-code):
      /*
      final response = await http.post(
        Uri.parse('https://your-fastapi-url.com/analyze'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'image': base64Encode(imageBytes),
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return DeepfakeResult.fromApiResponse(jsonResponse);
      } else {
        return DeepfakeResult(
          prediction: 'Error',
          confidenceScore: 0.0,
          hasError: true,
          errorMessage: 'Failed to get response: ${response.statusCode}',
        );
      }
      */

      // For now, return a placeholder
      return DeepfakeResult(
        prediction: 'Deepfake',
        confidenceScore: 0.89,
        details: {
          'facial_artifacts': 'Detected',
          'noise_patterns': 'Inconsistent',
          'light_consistency': 'Poor',
          'generation_model': 'StyleGAN-3',
          'analysis_time': '2.3 seconds'
        },
      );
    } catch (e) {
      return DeepfakeResult(
        prediction: 'Error',
        confidenceScore: 0.0,
        hasError: true,
        errorMessage: e.toString(),
      );
    }
  }
}