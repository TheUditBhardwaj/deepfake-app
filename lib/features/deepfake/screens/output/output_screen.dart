import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hacachino/features/deepfake/screens/home/widgets/animated_particles.dart';
import 'package:hacachino/features/deepfake/screens/home/widgets/recent_detections.dart';
import 'package:flutter/services.dart';

import '../../deepfake_results/final_result.dart';

class ProcessingScreen extends StatefulWidget {
  final String prediction;
  final String? explanationImageUrl;
  final Map<String, dynamic> details;
  final Uint8List? explanationImage;

  const ProcessingScreen({
    Key? key,
    required this.prediction,
    required this.explanationImageUrl,
    required this.details,
    this.explanationImage,
  }) : super(key: key);

  @override
  _ProcessingScreenState createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  @override
  void initState() {
    super.initState();

    // Wait for 5 seconds (or animation time) before navigating to ResultsScreen
    Future.delayed(Duration(seconds: 5), () {
      _navigateToResultsScreen();
    });
  }

  // Navigate to the ResultsScreen with prediction data after animation
  void _navigateToResultsScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ResultsScreen(
          prediction: widget.prediction,
          explanationImageUrl: widget.explanationImageUrl,
          details: widget.details,
          explanationImage: widget.explanationImage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          'PROCESSING',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 120,
              width: 120,
              child: CoffeeLoader(),
            ),
            SizedBox(height: 40),
            Text(
              'ANALYZING VIDEO',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 15),
            Container(
              width: 250,
              child: Text(
                'This may take a few moments',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFFBDBDBD), // Light gray
                ),
              ),
            ),
            SizedBox(height: 25),
            // Shimmer effect progress bar
            Container(
              width: 200,
              child: LinearProgressIndicatorWithShimmer(),
            ),
          ],
        ),
      ),
    );
  }
}

// Shimmer effect linear progress indicator
class LinearProgressIndicatorWithShimmer extends StatefulWidget {
  @override
  _LinearProgressIndicatorWithShimmerState createState() => _LinearProgressIndicatorWithShimmerState();
}

class _LinearProgressIndicatorWithShimmerState extends State<LinearProgressIndicatorWithShimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return LinearProgressIndicator(
          backgroundColor: Colors.grey[900],
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFBF8D67).withOpacity(0.8)),
          value: _controller.value,
        );
      },
    );
  }
}

// Coffee Loader Animation Widget
class CoffeeLoader extends StatefulWidget {
  @override
  _CoffeeLoaderState createState() => _CoffeeLoaderState();
}

class _CoffeeLoaderState extends State<CoffeeLoader> with TickerProviderStateMixin {
  late AnimationController _fillController;
  late AnimationController _steamController;
  late Animation<double> _fillAnimation;
  late Animation<double> _bubbleAnimation;

  @override
  void initState() {
    super.initState();

    // Fill animation controller
    _fillController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 4),
    )..repeat();

    // Steam animation controller (faster)
    _steamController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    )..repeat(reverse: true);

    // Fill animation
    _fillAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _fillController,
      curve: Interval(0.0, 0.7, curve: Curves.easeInOut),
    ));

    // Bubble animation
    _bubbleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _fillController,
      curve: Interval(0.5, 1.0, curve: Curves.easeInOut),
    ));
  }

  @override
  void dispose() {
    _fillController.dispose();
    _steamController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_fillController, _steamController]),
      builder: (context, child) {
        return CustomPaint(
          // painter: CoffeePainter(
          //   fillLevel: _fillAnimation.value,
          //   steamValue: _steamController.value,
          //   bubbleValue: _bubbleAnimation.value,
          // ),
          size: Size(90, 110),
        );
      },
    );
  }
}
