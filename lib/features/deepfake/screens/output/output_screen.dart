import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../utils/constants/colors.dart';

class ProcessingScreen extends StatefulWidget {
  @override
  _ProcessingScreenState createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  @override
  void initState() {
    super.initState();

    // Simulate a processing delay before showing results (e.g., 3 seconds)
    Future.delayed(Duration(seconds: 3), () {
      // Once processing is complete, navigate to results screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ResultsScreen()), // Navigate to the results screen after processing
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Processing Video'),
        backgroundColor: TColors.primary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated GIF placeholder
            Image.asset(
              'assets/images/animations/cofee.gif', // Replace with your own GIF image path
              height: 150, // Adjust height of the gif as per need
              width: 150, // Adjust width of the gif as per need
            ),
            SizedBox(height: 20),
            Text(
              'Processing the video...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: TColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Results screen to display the outcome after processing
class ResultsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Results'),
        backgroundColor: TColors.primary,
      ),
      body: Center(
        child: Text(
          'Here are the results of your video processing!',
          style: TextStyle(fontSize: 18, color: TColors.primary),
        ),
      ),
    );
  }
}
