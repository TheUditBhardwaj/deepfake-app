import 'package:flutter/cupertino.dart';

class AnimatedParticle {
  Offset position;
  final double size;
  final double speed;
  final Color color;

  AnimatedParticle({
    required this.position,
    required this.size,
    required this.speed,
    required this.color,
  });
}


class ParticlesPainter extends CustomPainter {
  final List<AnimatedParticle> particles;

  ParticlesPainter(this.particles);

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

