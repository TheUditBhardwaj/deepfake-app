import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
class buildRecentDetections extends StatelessWidget {
  const buildRecentDetections({super.key});

  @override
  Widget build(BuildContext context) {
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
                              // SizedBox(height: 4),

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