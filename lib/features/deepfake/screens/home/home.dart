import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';
import 'package:hacachino/features/deepfake/deepfake_results/deepfake_service.dart';
import 'package:hacachino/features/deepfake/screens/home/widgets/animated_particles.dart';
import 'package:hacachino/features/deepfake/screens/home/widgets/recent_detections.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data'; // This gives you the standard Uint8List
import 'package:hacachino/features/deepfake/deepfake_results/deepfake_results.dart';

import '../../../../data/repositories/user/user_repository.dart';
import '../../../authentication/models/user_model.dart';
import '../output/output_screen.dart';

// Custom painter to render the particles
class ParticlesPainter extends CustomPainter {
  final List<AnimatedParticle> particles;

  ParticlesPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = particle.color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(particle.position, particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlesPainter oldDelegate) => true;
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  XFile? _pickedVideo;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  int _sequenceLength = 10; // Default sequence length
  int _maxFrames = 10; // Example maximum frame length
  String _userName = ''; // To hold the user's name
  bool _isProcessing = false; // Define the _isProcessing variable

  // Animation controllers
  late AnimationController _bgAnimationController;
  late AnimationController _cardAnimationController;

  // List for animated background particles
  final List<AnimatedParticle> _particles = [];
  final int _particleCount = 20;

  // Method to pick video and start processing
  // Modify the _processVideo method in _HomeScreenState class
// Add this method to the _HomeScreenState class
// Update the _processVideo method in the HomeScreen
  Future<void> _processVideo() async {
    if (_pickedVideo == null) {
      print('No video selected');
      return;
    }

    // Show loading indicator
    setState(() {
      _isProcessing = true;
    });

    try {
      // Navigate to ProcessingScreen with the video file
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProcessingScreen(
            prediction: '',
            explanationImageUrl: null,
            details: {},
            explanationImage: null,
            videoFilePath: _pickedVideo!.path,  // Pass the video file path
            sequenceLength: _sequenceLength,    // Pass the sequence length
          ),
        ),
      );
    } catch (e) {
      print('Error processing video: $e');
      setState(() {
        _isProcessing = false;
      });
    }
  }

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
        _maxFrames = (videoController.value.duration.inMilliseconds / 33.33)
            .round(); // Approximate frame count at 30fps
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
          _userName =
              user.fullName ?? 'Guest'; // Fallback to 'Guest' if name is null
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
      _particles.add(AnimatedParticle(
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
        toolbarHeight: 80,
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
                          colors: [
                            Colors.blue.shade700,
                            Colors.purple.shade800
                          ],
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
                          _userName.isNotEmpty
                              ? _userName[0].toUpperCase()
                              : 'G',
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
              painter: ParticlesPainter(_particles),
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
                  SizedBox(height: 130), // Account for extended AppBar

                  // Video upload section with preview and animations
                  _buildVideoUploadSection(),

                  SizedBox(height: 40),

                  // Action buttons with animations
                  _buildActionButtons(),

                  SizedBox(height: 40),

                  // Recent detections section
                  buildRecentDetections(),
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
              icon: Icon(Icons.video_collection_outlined, color: Colors.black,
                  size: 18),
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
              onPressed: _pickedVideo != null
                  ? _processVideo  // Changed from _navigateToProcessingScreen to _processVideo
                  : null,
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
                    'Sequence Length',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${(_videoController!.value.duration.inSeconds / 60)
                        .floor()}:${(_videoController!.value.duration
                        .inSeconds % 60).toString().padLeft(2, '0')} minutes',
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
                min: 10,
                max: 100,
                divisions: 90,  // Fixed to match range
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
      ],
    );
  }
}