import 'package:flutter/material.dart';
import 'dart:math';

class BottlePainter extends CustomPainter {
  final Color bottleColor;
  final Color capColor;
  
  BottlePainter({
    this.bottleColor = const Color(0xFF8B4513),
    this.capColor = const Color(0xFF654321),
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;
    
    final center = Offset(size.width / 2, size.height / 2);
    final bottleWidth = size.width * 0.3;
    final bottleHeight = size.height * 0.7;
    
    // Bottle body
    paint.color = bottleColor;
    final bottleRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: bottleWidth,
        height: bottleHeight,
      ),
      const Radius.circular(8),
    );
    canvas.drawRRect(bottleRect, paint);
    
    // Bottle neck
    final neckWidth = bottleWidth * 0.4;
    final neckHeight = size.height * 0.2;
    final neckRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy - bottleHeight / 2 - neckHeight / 2),
        width: neckWidth,
        height: neckHeight,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(neckRect, paint);
    
    // Bottle cap
    paint.color = capColor;
    final capRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy - bottleHeight / 2 - neckHeight - 8),
        width: neckWidth * 1.2,
        height: 16,
      ),
      const Radius.circular(8),
    );
    canvas.drawRRect(capRect, paint);
    
    // Bottle label
    paint.color = Colors.white.withOpacity(0.8);
    final labelRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: bottleWidth * 0.8,
        height: bottleHeight * 0.3,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(labelRect, paint);
    
    // Bottle highlight
    paint.color = Colors.white.withOpacity(0.3);
    final highlightRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        center.dx - bottleWidth / 2 + 4,
        center.dy - bottleHeight / 2 + 8,
        bottleWidth * 0.2,
        bottleHeight * 0.6,
      ),
      const Radius.circular(2),
    );
    canvas.drawRRect(highlightRect, paint);
    
    // Pointer (bottle mouth direction)
    paint.color = Colors.red;
    paint.style = PaintingStyle.fill;
    
    final pointerPath = Path();
    final pointerTip = Offset(center.dx, center.dy - bottleHeight / 2 - neckHeight - 24);
    pointerPath.moveTo(pointerTip.dx, pointerTip.dy);
    pointerPath.lineTo(pointerTip.dx - 8, pointerTip.dy + 16);
    pointerPath.lineTo(pointerTip.dx + 8, pointerTip.dy + 16);
    pointerPath.close();
    
    canvas.drawPath(pointerPath, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SpinBottleWidget extends StatefulWidget {
  final VoidCallback? onSpinComplete;
  final bool isSpinning;
  final int selectedPlayerIndex;
  
  const SpinBottleWidget({
    super.key,
    this.onSpinComplete,
    this.isSpinning = false,
    this.selectedPlayerIndex = 0,
  });

  @override
  State<SpinBottleWidget> createState() => _SpinBottleWidgetState();
}

class _SpinBottleWidgetState extends State<SpinBottleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onSpinComplete?.call();
      }
    });
  }
  
  @override
  void didUpdateWidget(SpinBottleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpinning && !oldWidget.isSpinning) {
      _startSpin();
    }
  }
  
  void _startSpin() {
    final random = Random();
    final baseRotations = 3 + random.nextDouble() * 2; // 3-5 full rotations
    final playerCount = 4; // Assume max 4 players
    final targetAngle = (widget.selectedPlayerIndex * (2 * pi / playerCount)) + (baseRotations * 2 * pi);
    
    _animation = Tween<double>(
      begin: 0,
      end: targetAngle,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    
    _controller.reset();
    _controller.forward();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _animation.value,
          child: Container(
            width: 120,
            height: 120,
            child: CustomPaint(
              painter: BottlePainter(),
              size: const Size(120, 120),
            ),
          ),
        );
      },
    );
  }
}