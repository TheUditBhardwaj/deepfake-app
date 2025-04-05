import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../utils/constants/colors.dart';



class ProcessingScreen extends StatelessWidget {
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 60,
              width: 60,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE0E0E0)), // Light gray
                strokeWidth: 2,
              ),
            ),
            SizedBox(height: 30),
            Text(
              'ANALYZING VIDEO',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'This may take a few moments',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFFBDBDBD), // Light gray
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
