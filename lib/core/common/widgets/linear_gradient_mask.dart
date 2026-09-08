import 'package:edu_gym/core/theme/app_color.dart';
import 'package:flutter/material.dart';

class LinearGradientMask extends StatelessWidget {
  const LinearGradientMask({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColor.primary,
            Color(0xFFFFD700), // Gold/Lighter yellow
          ],
        ).createShader(bounds);
      },
      child: child,
    );
  }
}
