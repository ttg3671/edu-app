import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../responsive.dart';

class PortraitVideo extends StatefulWidget {
  final double? height;
  final Widget player;
  const PortraitVideo({super.key, required this.player, this.height});

  @override
  State<PortraitVideo> createState() => _PortraitVideoState();
}

class _PortraitVideoState extends State<PortraitVideo> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setPortraitOrientation();
    });
  }

  void _setPortraitOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  Widget build(BuildContext context) {
    final isFullHeight = widget.height == double.infinity;
    
    Widget content = Container(
      height: widget.height ?? (MediaQuery.sizeOf(context).height * (!Responsive.isTablet? 0.25 : 0.35)),
      width: double.infinity,
      color: Colors.black,
      child: widget.player,
    );

    return PopScope(
      canPop: true,
      child: isFullHeight ? content : SafeArea(child: content),
    );
  }
}