import 'dart:typed_data';
import 'package:flutter/material.dart';

class ProcessingScreen extends StatelessWidget {
  final String prediction;           // 'Fake' or 'Real'
  final String? explanationImageUrl; // Explanation image URL (if available)
  final Map<String, dynamic> details; // Additional details (optional)
  final Uint8List? explanationImage; // Explanation image data (if available)

  const ProcessingScreen({
    super.key,
    required this.prediction,
    this.explanationImageUrl,
    required this.details,
    this.explanationImage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Prediction Results', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Prediction: $prediction',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              SizedBox(height: 20),
              Text(
                'Confidence: ${(details['confidence'] ?? 0.0).toStringAsFixed(2)}%',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              SizedBox(height: 20),
              if (explanationImage != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Explanation Image:',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        explanationImage!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
              if (details.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20),
                    Text(
                      'Additional Details:',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    SizedBox(height: 10),
                    ...details.entries.map(
                          (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          '${entry.key}: ${entry.value}',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
