import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../data/repositories/user/user_repository.dart';
import '../../../../utils/constants/colors.dart'; // Only import TColors from here
import '../../../authentication/models/user_model.dart';
import '../output/output_screen.dart';

// Remove TColors definition from this file
// (use the one from utils/constants/colors.dart instead)

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  XFile? _pickedVideo;
  int _sequenceLength = 10; // Default sequence length
  int _maxFrames = 100; // Example maximum frame length
  String _userName = ''; // To hold the user's name
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
      _maxFrames = 100; // Simulated max frames
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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProcessingScreen()),
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
          'Hi, $_userName',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 30),

              // Modern video upload section
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Color(0xFF303030), // Dark gray
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: _pickedVideo != null
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.videocam, color: Color(0xFFE0E0E0)), // Light gray
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _pickedVideo!.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      // Video preview area
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Color(0xFF424242), // Medium dark gray
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.play_circle_outline,
                            size: 60,
                            color: Color(0xFFE0E0E0), // Light gray
                          ),
                        ),
                      ),
                    ],
                  )
                      : Column(
                    children: [
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Color(0xFF424242), // Medium dark gray
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_upload_outlined,
                              size: 60,
                              color: Color(0xFFE0E0E0), // Light gray
                            ),
                            SizedBox(height: 15),
                            Text(
                              'Tap to upload video',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFE0E0E0), // Light gray
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 30),

              // Modern action buttons - Fixed styleFrom parameter
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickVideo,
                      icon: Icon(Icons.video_collection_outlined, color: Colors.black, size: 18),
                      label: Text(
                        'SELECT',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          letterSpacing: 1,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, // Changed from primary to backgroundColor
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickedVideo != null ? _navigateToProcessingScreen : null,
                      icon: Icon(Icons.arrow_forward, color: Color(0xFF303030), size: 18),
                      label: Text(
                        'ANALYZE',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF303030),
                          letterSpacing: 1,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pickedVideo != null ? Color(0xFFE0E0E0) : Colors.grey, // Changed from primary
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 40),

              // Sequence length control with modern styling
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SEQUENCE LENGTH',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE0E0E0), // Light gray
                      letterSpacing: 1,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(0xFF303030), // Dark gray
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
                    ),
                    child: Text(
                      '$_sequenceLength frames',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 10),

              SliderTheme(
                data: SliderThemeData(
                  thumbColor: Color(0xFFE0E0E0), // Light gray
                  activeTrackColor: Color(0xFFE0E0E0), // Light gray
                  inactiveTrackColor: Color(0xFF424242), // Medium dark gray
                  trackHeight: 4,
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayColor: Color(0xFFE0E0E0).withOpacity(0.2), // Light gray with opacity
                ),
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

              // Disclaimer with minimal styling
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF303030), // Dark gray
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFFE0E0E0), size: 20), // Light gray
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Longer sequences may improve accuracy but increase processing time.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFFBDBDBD), // Light gray
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 40),

              // Recent detections with modern cards
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'RECENT DETECTIONS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE0E0E0), // Light gray
                      letterSpacing: 1,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'VIEW ALL',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE0E0E0), // Light gray
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16),

              // Modern card layout for recent detections
              Container(
                height: 220,
                child: ListView.builder(
                  physics: BouncingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  itemCount: recentDetections.length,
                  itemBuilder: (context, index) {
                    final status = recentDetections[index]['status']!;
                    final statusColor = status == 'FAKE' ? Colors.redAccent : Colors.greenAccent;

                    return Container(
                      width: 180,
                      margin: EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: Color(0xFF303030), // Dark gray
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                            child: Container(
                              height: 140,
                              width: 180,
                              color: Color(0xFF424242), // Medium dark gray
                              child: Image.asset(
                                recentDetections[index]['image']!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: status == 'FAKE' ?
                                        Colors.redAccent.withOpacity(0.2) :
                                        Colors.greenAccent.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: statusColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'ID: #${1000 + index}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFBDBDBD), // Light gray
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// Modern processing screen
