import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';

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
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  int _sequenceLength = 10; // Default sequence length
  int _maxFrames = 100; // Example maximum frame length
  String _userName = ''; // To hold the user's name

  // Animation controllers
  late AnimationController _bgAnimationController;
  late AnimationController _cardAnimationController;

  // List for animated background particles
  final List<_AnimatedParticle> _particles = [];
  final int _particleCount = 20;

  List<Map<String, dynamic>> recentDetections = [
    {
      "status": "FAKE",
      "image": "assets/images/recent_detections/Rectangle_6.png",
      "date": "2 hours ago"
    },
    {
      "status": "REAL",
      "image": "assets/images/recent_detections/Rectangle_6.png",
      "date": "Yesterday"
    },
    {
      "status": "FAKE",
      "image": "assets/images/recent_detections/Rectangle_6.png",
      "date": "3 days ago"
    },
  ];

  // Function to pick a video from gallery
  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.gallery);

    if (video != null) {
      _initVideoPlayer(video);
      // Trigger haptic feedback when video is selected
      HapticFeedback.mediumImpact();
    }
  }

  // Initialize video player with the selected video
  Future<void> _initVideoPlayer(XFile video) async {
    final videoController = VideoPlayerController.file(File(video.path));

    await videoController.initialize();

    if (mounted) {
      setState(() {
        _pickedVideo = video;
        _videoController?.dispose();
        _videoController = videoController;
        _isVideoInitialized = true;
        _maxFrames = (videoController.value.duration.inMilliseconds / 33.33).round(); // Approximate frame count at 30fps
      });

      // Start a spring animation for the video container
      _cardAnimationController.forward(from: 0.0);
    }
  }

  // Fetch the user's name from Firebase Firestore
  Future<void> _getUserData() async {
    try {
      UserModel user = await UserRepository.instance.fetchUserDetails();
      if (mounted) {
        setState(() {
          _userName = user.fullName ?? 'Guest'; // Fallback to 'Guest' if name is null
        });
      }
    } catch (e) {
      print("Error fetching user details: $e");
    }
  }

  // Initialize background particles
  void _initParticles() {
    _particles.clear();
    for (int i = 0; i < _particleCount; i++) {
      _particles.add(_AnimatedParticle(
        position: Offset(
          math.Random().nextDouble() * MediaQuery.of(context).size.width,
          math.Random().nextDouble() * MediaQuery.of(context).size.height,
        ),
        size: (math.Random().nextDouble() * 6) + 2,
        speed: (math.Random().nextDouble() * 1.5) + 0.5,
        color: Colors.white.withOpacity(math.Random().nextDouble() * 0.2),
      ));
    }
  }

  @override
  void initState() {
    super.initState();
    _getUserData(); // Fetch user data on initialization

    // Initialize animation controllers
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 10000),
    )..repeat();

    _cardAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    // Add listener to rebuild for particle animation
    _bgAnimationController.addListener(() {
      setState(() {
        // This will rebuild the widget with updated particle positions
      });
    });

    // Set system UI overlay style for more immersive experience
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    // Execute after first frame is rendered to get the context size
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initParticles();
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _bgAnimationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  // Toggle video playback
  void _toggleVideoPlayback() {
    if (_videoController != null) {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();

      } else {
        _videoController!.play();
      }
      setState(() {});
    }
  }

  // Navigate to the next screen (for results)
  void _navigateToProcessingScreen() {
    // Play animation before navigating
    HapticFeedback.mediumImpact();

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ProcessingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var begin = Offset(1.0, 0.0);
          var end = Offset.zero;
          var curve = Curves.easeInOutCubic;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: Duration(milliseconds: 500),
      ),
    );
  }

  // Update particles position based on animation value
  void _updateParticles() {
    for (var particle in _particles) {
      // Move particles upward with varying speeds
      particle.position = Offset(
          particle.position.dx,
          (particle.position.dy - particle.speed) % MediaQuery.of(context).size.height
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Update particles on each build
    _updateParticles();

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 70,
        title: Row(
          children: [
            AnimatedBuilder(
                animation: _bgAnimationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _bgAnimationController.value * 2 * math.pi,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade700, Colors.purple.shade800],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(3),
                      child: CircleAvatar(
                        backgroundColor: Color(0xFF212121),
                        radius: 20,
                        child: Text(
                          _userName.isNotEmpty ? _userName[0].toUpperCase() : 'G',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, $_userName',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Ready to analyze?',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          Hero(
            tag: 'notification_button',
            child: Container(
              margin: EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF3a3a3a), Color(0xFF282828)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () {
                  HapticFeedback.lightImpact();
                },
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Animated background with particles
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0D1117),
                  Color(0xFF111827),
                  Color(0xFF161B22),
                ],
              ),
            ),
            child: CustomPaint(
              painter: _ParticlesPainter(_particles),
              child: Container(),
            ),
          ),

          // Main content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 100), // Account for extended AppBar

                  // Video upload section with preview and animations
                  _buildVideoUploadSection(),

                  SizedBox(height: 30),

                  // Action buttons with animations
                  _buildActionButtons(),

                  SizedBox(height: 40),

                  // Recent detections section
                  _buildRecentDetections(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildVideoUploadSection() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: AnimatedBuilder(
        animation: _cardAnimationController,
        builder: (context, child) {
          final scale = 1.0 + 0.05 * _cardAnimationController.value *
              (1 - _cardAnimationController.value) * 4; // Spring effect

          return Transform.scale(
            scale: scale,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF303030), Color(0xFF1a1a1a)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 30,
                    offset: Offset(0, 5),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.03),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: _pickedVideo != null && _isVideoInitialized
                    ? _buildVideoPreview()
                    : _buildVideoUploadPlaceholder(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButtons() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 40 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                _pickVideo();
              },
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
                backgroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                shadowColor: Colors.white.withOpacity(0.3),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _pickedVideo != null ? _navigateToProcessingScreen : null,
              icon: Icon(Icons.arrow_forward, size: 18),
              label: Text(
                'ANALYZE',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _pickedVideo != null
                    ? Colors.blue[700]
                    : Color(0xFF424242),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: _pickedVideo != null ? 8 : 0,
                shadowColor: _pickedVideo != null
                    ? Colors.blue.withOpacity(0.5)
                    : Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }

// Add these methods inside the _HomeScreenState class
  Widget _buildVideoPreview() {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.2),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.05),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(_videoController!),
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: _toggleVideoPlayback,
                      child: AnimatedOpacity(
                        opacity: _videoController!.value.isPlaying ? 0.0 : 0.7,
                        duration: Duration(milliseconds: 300),
                        child: Container(
                          color: Colors.black.withOpacity(0.5),
                          child: Icon(
                            _videoController!.value.isPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_fill,
                            size: 64,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Video',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${(_videoController!.value.duration.inSeconds / 60).floor()}:${(_videoController!.value.duration.inSeconds % 60).toString().padLeft(2, '0')} minutes',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(Icons.refresh, color: Colors.blue[300]),
                onPressed: () {
                  _pickVideo();
                  HapticFeedback.lightImpact();
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _sequenceLength.toDouble(),
                min: 5,
                max: _maxFrames.toDouble(),
                divisions: 19,
                activeColor: Colors.blue[700],
                inactiveColor: Colors.grey[800],
                onChanged: (value) {
                  setState(() {
                    _sequenceLength = value.toInt();
                  });
                },
                label: 'Sequence Length: $_sequenceLength frames',
              ),
            ),
            SizedBox(width: 12),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Text(
                '$_sequenceLength',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVideoUploadPlaceholder() {
    return Column(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.05),
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: _pickVideo,
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.blue[700]!, Colors.blue[900]!],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.video_library_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Select a video to analyze',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'We\'ll scan it for any potential manipulations',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 20),
        Text(
          'Looking for signs of face manipulation',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey[300],
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildFeatureTag('Facial movements'),
            SizedBox(width: 5),
            _buildFeatureTag('Audio sync'),
            SizedBox(width: 5),
            _buildFeatureTag('Artifacts'),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureTag(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[300],
        ),
      ),
    );
  }

  Widget _buildRecentDetections() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 60 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.purple.shade700, Colors.purple.shade900],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(Icons.history, color: Colors.white, size: 18),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'RECENT DETECTIONS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: Row(
                  children: [
                    Text(
                      'VIEW ALL',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[400],
                        letterSpacing: 0.5,
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.blue[400], size: 16),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Container(
            height: 240,
            child: ListView.builder(
              physics: BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              itemCount: recentDetections.length,
              itemBuilder: (context, index) {
                final status = recentDetections[index]['status']!;
                final statusColor = status == 'FAKE' ? Colors.redAccent : Colors.greenAccent;
                final statusBgColor = status == 'FAKE'
                    ? Colors.redAccent.withOpacity(0.15)
                    : Colors.greenAccent.withOpacity(0.15);

                return TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 1200 + (index * 200)),
                  curve: Curves.easeOutQuint,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(100 * (1 - value), 0),
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    width: 190,
                    margin: EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF303030), Color(0xFF1a1a1a)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 15,
                          offset: Offset(0, 8),
                        ),
                        BoxShadow(
                          color: status == 'FAKE'
                              ? Colors.red.withOpacity(0.1)
                              : Colors.green.withOpacity(0.1),
                          blurRadius: 20,
                          offset: Offset(0, 0),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withOpacity(0.03),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(24),
                                topRight: Radius.circular(24),
                              ),
                              child: Container(
                                height: 140,
                                width: 210,
                                color: Color(0xFF424242),
                                child: Image.asset(
                                  recentDetections[index]['image']!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  recentDetections[index]['date']!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: statusBgColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: statusColor.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          status == 'FAKE' ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                                          color: statusColor,
                                          size: 14,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          status,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: statusColor,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'Detection details',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                              // SizedBox(height: 4),
                              Text(
                                'Tap to view full analysis and report',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
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
    );
  }
}

class _AnimatedParticle {
  Offset position;
  final double size;
  final double speed;
  final Color color;

  _AnimatedParticle({
    required this.position,
    required this.size,
    required this.speed,
    required this.color,
  });
}


class _ParticlesPainter extends CustomPainter {
  final List<_AnimatedParticle> particles;

  _ParticlesPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();

    for (var particle in particles) {
      paint.color = particle.color;
      canvas.drawCircle(particle.position, particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}



