import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hacachino/utils/constants/colors.dart';
import 'package:image_picker/image_picker.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  XFile? _pickedVideo;
  int _sequenceLength = 10; // Default sequence length
  int _maxFrames = 100; // Example maximum frame length for the video (can be dynamic)
  List<Map<String, String>> recentDetections = [
    {"status": "FAKE", "image": "assets/images/recent_detections/Rectangle_6.png"},
    {"status": "REAL", "image": "assets/images/recent_detections/Rectangle_6.png"},
    {"status": "FAKE", "image": "assets/images/recent_detections/Rectangle_6.png"},
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
        backgroundColor: TColors.primary,
        title: Text(
          'Hi, Sophia\nLive Deep Fake Detect',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
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
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
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
                      SizedBox(height: 15),
                      // Video player widget or thumbnail for preview
                      AnimatedContainer(
                        duration: Duration(seconds: 1),
                        height: 250,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          Icons.play_arrow,
                          size: 80,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  )
                      : Column(
                    children: [
                      AnimatedContainer(
                        duration: Duration(seconds: 1),
                        height: 250,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          Icons.video_collection,
                          size: 100,
                          color: Colors.teal,
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
                child: AnimatedContainer(
                  duration: Duration(seconds: 1),
                  padding: EdgeInsets.symmetric(horizontal: 60, vertical: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.teal, Colors.green],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withOpacity(0.6),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: Offset(0, 3), // Shadow position
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _pickVideo,
                    child: Text(
                      'Upload Video',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    style: ButtonStyle(
                      padding: MaterialStateProperty.all(EdgeInsets.all(0)),
                      backgroundColor: MaterialStateProperty.all(Colors.transparent),
                      shape: MaterialStateProperty.all(RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      )),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 30),

              // Sequence length slider
              Text(
                'Sequence Length: $_sequenceLength frames',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                child: Slider(
                  min: 10,
                  max: _maxFrames.toDouble(),
                  value: _sequenceLength.toDouble(),
                  onChanged: (value) {
                    setState(() {
                      _sequenceLength = value.toInt();
                    });
                  },
                ),
              ),
              SizedBox(height: 10),

              // Disclaimer Text with animated fade-in
              AnimatedOpacity(
                opacity: 1.0,
                duration: Duration(milliseconds: 500),
                child: Text(
                  'Disclaimer: Longer sequence lengths may enhance prediction accuracy but could increase processing time. '
                      'Shorter sequences offer faster results with a potential trade-off in accuracy.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
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
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: recentDetections.length,
                  itemBuilder: (context, index) {
                    return AnimatedContainer(
                      duration: Duration(seconds: 1),
                      margin: EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[200],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              recentDetections[index]['image']!,
                              height: 130,
                              width: 180,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Image $index - ${recentDetections[index]['status']}',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ],
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
