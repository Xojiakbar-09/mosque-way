import 'package:flutter/material.dart';

class MosqueIcon extends StatelessWidget {
  const MosqueIcon({super.key, required this.size});

  final double size;
  static const asset = 'assets/icon/mosque_marker.png';

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: size,
      height: size,
      excludeFromSemantics: true,
      errorBuilder: (context, error, stackTrace) =>
          Icon(Icons.mosque_rounded, size: size),
    );
  }
}
