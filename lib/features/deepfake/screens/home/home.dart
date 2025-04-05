import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  XFile? _pickedVideo;
  int _sequenceLength = 10; // Default sequence length
  int _maxFrames = 100; // Example maximum frame length for the video (can be dynamic)
  List<Map<String, String>> recentDetections = [
    {"status": "FAKE", "image": "assets/images/sample1.jpg"},
    {"status": "REAL", "image": "assets/images/sample2.jpg"},
    {"status": "FAKE", "image": "assets/images/sample3.jpg"},
  ];

  // Function to pick a video from gallery
  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.gallery);

    setState(() {
      _pickedVideo = video;
      // Simulate maximum number of frames from the picked video
      _maxFrames = 100; // Can dynamically get the number of frames from video metadata
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(
          'Hi, Sophia\nLive Deep Fake Detect',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Video section
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: EdgeInsets.symmetric(vertical: 10),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _pickedVideo != null
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Picked Video: ${_pickedVideo!.name}',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 10),
                      // Video player widget or thumbnail for preview
                      Container(
                        height: 200,
                        width: double.infinity,
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.play_arrow,
                          size: 60,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  )
                      : Column(
                    children: [
                      Container(
                        height: 200,
                        width: double.infinity,
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.video_collection,
                          size: 100,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'No video selected. Please upload a video from the gallery.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),

              // Upload button with elevation and rounded edges
              Center(
                child: ElevatedButton(
                  onPressed: _pickVideo,
                  child: Text(
                    'Upload Video',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 50, vertical: 16)),
                    backgroundColor: MaterialStateProperty.all(Colors.green),
                    shape: MaterialStateProperty.all(RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    )),
                  ),
                ),
              ),
              SizedBox(height: 30),

              // Sequence length slider
              Text(
                'Sequence Length: $_sequenceLength frames',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Slider(
                min: 10,
                max: _maxFrames.toDouble(),
                value: _sequenceLength.toDouble(),
                onChanged: (value) {
                  setState(() {
                    _sequenceLength = value.toInt();
                  });
                },
              ),
              SizedBox(height: 10),

              // Disclaimer Text
              Text(
                'Note: More frames result in higher accuracy, while fewer frames may reduce accuracy.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),

              // Recent detections section
              Text(
                'Recent Detections',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              SizedBox(height: 10),
              // Horizontal list of recent detections
              Container(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: recentDetections.length,
                  itemBuilder: (context, index) {
                    return Card(
                      elevation: 3,
                      margin: EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        width: 140,
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[200],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 100,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: AssetImage(recentDetections[index]['image']!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Image $index - ${recentDetections[index]['status']}',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
