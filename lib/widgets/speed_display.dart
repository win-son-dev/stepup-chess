import 'package:flutter/material.dart';

/// Displays the current walking speed styled as a road speed-limit sign —
/// a white circle with a red border and the speed number inside.
class SpeedDisplay extends StatelessWidget {
  final double speed;

  /// Diameter of the sign circle.
  final double size;

  const SpeedDisplay({
    super.key,
    required this.speed,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final borderWidth = size * 0.08;
    final numFontSize = size * 0.34;
    final labelFontSize = size * 0.18;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: const Color(0xFFCC0000), width: borderWidth),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            speed.toStringAsFixed(0),
            style: TextStyle(
              fontSize: numFontSize,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              height: 1.0,
            ),
          ),
          Text(
            'spm',
            style: TextStyle(
              fontSize: labelFontSize,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
