  import 'dart:convert';
  import 'dart:typed_data';
  import 'package:flutter/material.dart';
  import 'package:flutter/services.dart';
  import 'dart:ui' as ui;

  class ResultsScreen extends StatefulWidget {
    final String prediction;
    final String? explanationImageUrl;
    final Map<String, dynamic> details;
    final Uint8List? explanationImage;

    const ResultsScreen({
      Key? key,
      required this.prediction,
      this.explanationImageUrl,
      required this.details,
      this.explanationImage,
    }) : super(key: key);

    @override
    _ResultsScreenState createState() => _ResultsScreenState();
  }

  class _ResultsScreenState extends State<ResultsScreen> with SingleTickerProviderStateMixin {
    late AnimationController _controller;
    late Animation<double> _fadeAnimation;
    late Animation<double> _slideAnimation;
    late Animation<double> _scaleAnimation;

    @override
    void initState() {
      super.initState();
      _controller = AnimationController(
        duration: Duration(milliseconds: 1500),
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
          curve: Interval(0.3, 0.8, curve: Curves.easeOut),
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
      final confidenceValue = _getConfidenceValue();

      return Scaffold(
        backgroundColor: Colors.black,
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
        ),
        body: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 100, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(isDeepfake),
                    SizedBox(height: 30),
                    _buildPredictionCard(isDeepfake, confidenceValue),
                    SizedBox(height: 30),
                    if (widget.explanationImage != null)
                      _buildExplanationSection(),
                    if (widget.details.isNotEmpty)
                      _buildDetailsSection(),
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
          position: Tween<Offset>(begin: Offset(0, -0.5), end: Offset.zero).animate(_controller),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analysis Complete',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2),
              ),
              SizedBox(height: 8),
              Text(
                isDeepfake ? 'Potential manipulation detected' : 'No manipulation detected',
                style: TextStyle(fontSize: 16, color: Colors.grey[400], letterSpacing: 0.5),
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
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDeepfake
                  ? [Colors.red[900]!.withOpacity(0.3), Colors.red[700]!.withOpacity(0.1)]
                  : [Colors.green[900]!.withOpacity(0.3), Colors.green[700]!.withOpacity(0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDeepfake ? Colors.red[700]! : Colors.green[700]!,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isDeepfake ? Icons.warning_rounded : Icons.check_circle_rounded,
                    color: isDeepfake ? Colors.red[400] : Colors.green[400],
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Text(
                    isDeepfake ? 'DEEPFAKE DETECTED' : 'AUTHENTIC CONTENT',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ],
              ),
              SizedBox(height: 20),
              _buildConfidenceIndicator(confidenceValue, isDeepfake),
            ],
          ),
        ),
      );
    }

    Widget _buildConfidenceIndicator(double confidence, bool isDeepfake) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Confidence Level',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 6,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              AnimatedContainer(
                duration: Duration(milliseconds: 1500),
                height: 6,
                width: MediaQuery.of(context).size.width * 0.8 * confidence,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDeepfake
                        ? [Colors.red[700]!, Colors.red[400]!]
                        : [Colors.green[700]!, Colors.green[400]!],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '${(confidence * 100).toStringAsFixed(1)}%',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      );
    }

    Widget _buildExplanationSection() {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: Tween<Offset>(begin: Offset(0, 0.5), end: Offset.zero).animate(_controller),
          child: Container(
            margin: EdgeInsets.only(bottom: 30),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Visual Analysis',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 15),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: widget.explanationImage != null
                      ? Image.memory(
                    widget.explanationImage!,
                    fit: BoxFit.cover,
                  )
                      : Container(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget _buildDetailsSection() {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: Tween<Offset>(begin: Offset(0, 0.5), end: Offset.zero).animate(_controller),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analysis Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 15),
                ...widget.details.entries.map((entry) => Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      ),
                      Text(
                        entry.value.toString(),
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )).toList(),
              ],
            ),
          ),
        ),
      );
    }

    double _getConfidenceValue() {
      final RegExp percentRegex = RegExp(r'(\d+\.\d+)%');
      final match = percentRegex.firstMatch(widget.prediction);
      return match != null ? double.parse(match.group(1)!) / 100 : 0.0;
    }
  }

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
      return DeepfakeResult(
        prediction: json['prediction'] ?? 'Unknown',
        confidenceScore: json['confidence_score']?.toDouble() ?? 0.0, // Ensure a default value
        gradcamImageUrl: json['gradcam_image_url'],
        explanationImage: json['explanation_image'] != null
            ? Uint8List.fromList(base64Decode(json['explanation_image']))
            : null,
        details: json['details'] ?? {},
        hasError: json['error'] ?? false,
        errorMessage: json['error_message'] ?? '',
      );
    }
  }
