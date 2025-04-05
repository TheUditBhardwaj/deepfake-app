import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../data/repositories/user/user_repository.dart';
import '../../../../utils/constants/colors.dart';
import '../../../authentication/models/user_model.dart';
import '../output/output_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  XFile? _pickedVideo;
  int _sequenceLength = 10; // Default sequence length
  int _maxFrames = 100; // Example maximum frame length for the video (can be dynamic)
  String _userName = ''; // To hold the user's name fetched from Firebase
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
      _maxFrames = 100; // Simulated max frames (can be dynamically fetched)
    });
  }

  // Fetch the user's name from Firebase Firestore
  Future<void> _getUserData() async {
    try {
      UserModel user = await UserRepository.instance.fetchUserDetails();
      setState(() {
        _userName = user.fullName ?? 'Guest'; // Fallback to 'Guest' if name is null
      });
    } catch (e) {
      print("Error fetching user details: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _getUserData(); // Fetch user data on initialization
  }

  // Navigate to the next screen (for results)
  void _navigateToProcessingScreen() {
    // Placeholder for navigating to the processing screen
    // You will implement this screen later with actual video processing results
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProcessingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: TColors.primary, // Using the custom primary color from TColors
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Hi, $_userName', // Dynamically displaying the user's name
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: TColors.white),
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: TColors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Video section with polished and elevated design
              AnimatedContainer(
                duration: Duration(seconds: 1),
                curve: Curves.easeInOut,
                margin: EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: TColors.white, // Use the white color from TColors
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _pickedVideo != null
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Picked Video: ${_pickedVideo!.name}',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 15),
                      // Video player widget or thumbnail for preview
                      AnimatedContainer(
                        duration: Duration(seconds: 1),
                        height: 250,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: TColors.lightGrey,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.play_arrow,
                          size: 80,
                          color: TColors.primary, // Use the primary color for icons
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
                          color: TColors.lightGrey,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.video_collection,
                          size: 100,
                          color: TColors.primary, // Use the primary color here as well
                        ),
                      ),
                      SizedBox(height: 15),
                      Text(
                        'No video selected. Please upload a video from the gallery.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                ),
              ),

              // Row for the upload and send buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Upload Video Button (Smaller size)
                  AnimatedContainer(
                    duration: Duration(seconds: 1),
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10), // Reduced padding
                    decoration: BoxDecoration(
                      color: TColors.primary, // Using the custom primary color for the button's background
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: TColors.primary.withOpacity(0.6),
                          spreadRadius: 2,
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _pickVideo,
                      style: ButtonStyle(
                        padding: MaterialStateProperty.all(EdgeInsets.all(0)),
                        backgroundColor: MaterialStateProperty.all(TColors.primary), // Set background to primary color
                        shape: MaterialStateProperty.all(RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        )),
                        elevation: MaterialStateProperty.all(0), // Remove elevation for a flat look
                        side: MaterialStateProperty.all(BorderSide.none), // Remove any border outline
                        overlayColor: MaterialStateProperty.all(TColors.primary.withOpacity(0.2)), // Hover effect
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.video_collection,
                            color: TColors.white,
                            size: 18, // Smaller icon size
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Upload Video',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: TColors.white), // Smaller text size
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(width: 15), // Reduced space between the buttons

                  // Send Button (Smaller size)
                  AnimatedContainer(
                    duration: Duration(seconds: 1),
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10), // Reduced padding
                    decoration: BoxDecoration(
                      color: TColors.primary, // Using the custom primary color for the button's background
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: TColors.primary.withOpacity(0.6),
                          spreadRadius: 2,
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _pickedVideo != null ? _navigateToProcessingScreen : null,
                      style: ButtonStyle(
                        padding: MaterialStateProperty.all(EdgeInsets.all(0)),
                        backgroundColor: MaterialStateProperty.all(TColors.primary), // Set background to primary color
                        shape: MaterialStateProperty.all(RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        )),
                        elevation: MaterialStateProperty.all(0), // Remove elevation for a flat look
                        side: MaterialStateProperty.all(BorderSide.none), // Remove any border outline
                        overlayColor: MaterialStateProperty.all(TColors.primary.withOpacity(0.2)), // Hover effect
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.send,
                            color: TColors.white,
                            size: 18, // Smaller icon size
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Send Video',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: TColors.white), // Smaller text size
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 50),

              // Sequence length slider with more attractive styling
              Text(
                'Sequence Length: $_sequenceLength frames',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut, // Smooth transition for changes
                child: Slider(
                  min: 10,
                  inactiveColor: Colors.grey,
                  thumbColor: TColors.primary,
                  activeColor: TColors.primary,
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

              // Disclaimer text with smooth fade-in and contrast
              AnimatedOpacity(
                opacity: 1.0,
                duration: Duration(milliseconds: 500),
                child: Text(
                  'Disclaimer: Longer sequence lengths may enhance prediction accuracy but could increase processing time. '
                      'Shorter sequences offer faster results with a potential trade-off in accuracy.',
                  style: TextStyle(fontSize: 14, color: TColors.darkGrey), // Use the dark grey color
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 30),

              // Recent detections section with smooth animations and cards
              Text(
                'Recent Detections',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: TColors.black),
              ),
              SizedBox(height: 10),
              Container(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: recentDetections.length,
                  itemBuilder: (context, index) {
                    return AnimatedContainer(
                      duration: Duration(seconds: 1),
                      margin: EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: TColors.grey,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 1,
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.asset(
                              recentDetections[index]['image']!,
                              height: 150,
                              width: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Image $index - ${recentDetections[index]['status']}',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
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

