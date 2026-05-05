import 'package:edu_gym/screens/video/player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../responsive.dart';

class PortraitPlayer extends StatelessWidget {
  const PortraitPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Responsive.isTablet? 0.3.sh :0.25.sh,
      width: double.infinity,
      color: Colors.black,
      child: const Player(isTrailer: false,),
    );;
  }
}
