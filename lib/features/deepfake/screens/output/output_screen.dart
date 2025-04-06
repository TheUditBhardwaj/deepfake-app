import 'dart:async';
import 'dart:math' as math;
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
    Future.delayed(Duration(seconds: 7), () {
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
          painter: CoffeePainter(
            fillLevel: _fillAnimation.value,
            steamValue: _steamController.value,
            bubbleValue: _bubbleAnimation.value,
          ),
          size: Size(90, 110),
        );
      },
    );
  }
}

// Custom Painter for Coffee Cup
class CoffeePainter extends CustomPainter {
  final double fillLevel;
  final double steamValue;
  final double bubbleValue;

  CoffeePainter({
    required this.fillLevel,
    required this.steamValue,
    required this.bubbleValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cupWidth = size.width * 0.7;
    final double cupHeight = size.height * 0.7;
    final double handleWidth = size.width * 0.25;
    final double handleHeight = size.height * 0.3;
    final double steamHeight = size.height * 0.25;
    final double plateHeight = size.height * 0.05;
    final double plateWidth = size.width * 0.9;

    // Paint for cup outline
    final Paint cupPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // Paint for cup fill
    final Paint cupFillPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    // Paint for the coffee filling
    final Paint coffeePaint = Paint()
      ..color = Color(0xFFBF8D67) // Coffee brown color
      ..style = PaintingStyle.fill;

    // Paint for the plate
    final Paint platePaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    // Paint for the plate outline
    final Paint plateOutlinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Paint for the steam
    final Paint steamPaint = Paint()
      ..color = Colors.white.withOpacity(0.6 + steamValue * 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    // Paint for coffee bubbles
    final Paint bubblePaint = Paint()
      ..color = Color(0xFFD4A985)
      ..style = PaintingStyle.fill;

    // Center the cup
    final double cupLeft = (size.width - cupWidth) / 2;

    // Draw plate
    final Rect plateRect = Rect.fromLTWH(
        (size.width - plateWidth) / 2,
        steamHeight + cupHeight + 5,
        plateWidth,
        plateHeight
    );
    final RRect plateRRect = RRect.fromRectAndRadius(plateRect, Radius.circular(plateHeight / 2));
    canvas.drawRRect(plateRRect, platePaint);
    canvas.drawRRect(plateRRect, plateOutlinePaint);

    // Draw cup
    final Rect cupRect = Rect.fromLTWH(cupLeft, steamHeight, cupWidth, cupHeight);
    final RRect cupRRect = RRect.fromRectAndRadius(cupRect, Radius.circular(5.0));

    // Draw cup background/fill
    canvas.drawRRect(cupRRect, cupFillPaint);

    // Draw cup outline
    canvas.drawRRect(cupRRect, cupPaint);

    // Draw handle
    final Path handlePath = Path()
      ..moveTo(cupLeft + cupWidth, steamHeight + cupHeight * 0.3)
      ..quadraticBezierTo(
          cupLeft + cupWidth + handleWidth, steamHeight + cupHeight * 0.3 + handleHeight/2,
          cupLeft + cupWidth, steamHeight + cupHeight * 0.3 + handleHeight
      );
    canvas.drawPath(handlePath, cupPaint);

    // Draw coffee filling based on animation value
    final double fillHeight = cupHeight * fillLevel;
    if (fillHeight > 0) {
      final Rect fillRect = Rect.fromLTWH(
          cupLeft,
          steamHeight + cupHeight - fillHeight,
          cupWidth,
          fillHeight
      );
      final RRect fillRRect = RRect.fromRectAndRadius(fillRect, Radius.circular(5.0));
      canvas.drawRRect(fillRRect, coffeePaint);
    }

    // Draw coffee bubbles
    if (bubbleValue > 0.3 && fillLevel > 0.4) {
      final double bubbleY = steamHeight + cupHeight - fillHeight + 5;

      // Draw 3-5 bubbles with different sizes
      for (int i = 0; i < 5; i++) {
        if (i % 2 == 0 || bubbleValue > 0.7) {
          final double bubbleSize = 2 + (i % 3) * 1.5;
          final double bubbleX = cupLeft + cupWidth * (0.2 + i * 0.15);
          final double offset = math.sin(bubbleValue * math.pi * 2 + i) * 3;

          canvas.drawCircle(
              Offset(bubbleX, bubbleY + offset),
              bubbleSize,
              bubblePaint
          );
        }
      }
    }

    // Draw steam (animated)
    if (fillLevel > 0.6) {
      final double steamY = steamHeight + 3;
      final double steamOffset = steamValue * 5;

      // Calculate different steam curve for each line
      for (int i = 0; i < 3; i++) {
        final double xPos = cupLeft + cupWidth * (0.25 + i * 0.25);
        final double curve = math.sin((steamValue + i * 0.3) * math.pi * 2) * 4;

        Path steamPath = Path()
          ..moveTo(xPos, steamY)
          ..quadraticBezierTo(
              xPos + curve, steamY - steamHeight/2 + steamOffset/2,
              xPos, steamY - steamHeight + steamOffset
          );
        canvas.drawPath(steamPath, steamPaint);
      }
    }
  }

  @override
  bool shouldRepaint(CoffeePainter oldDelegate) =>
      oldDelegate.fillLevel != fillLevel ||
          oldDelegate.steamValue != steamValue ||
          oldDelegate.bubbleValue != bubbleValue;
}

// Placeholder colors class for the TColors reference in the ResultsScreen
class TColors {
  static const Color primary = Color(0xFFBF8D67); // Using the coffee color as primary
}

// Corrected FinalResultScreen class to match the import path
