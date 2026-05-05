import 'package:cached_network_image/cached_network_image.dart';
import 'package:edu_gym/core/common/widgets/custom_shimmer.dart';
import 'package:edu_gym/modal/module.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ModuleSearchCard extends StatelessWidget {
  final Module module;
  const ModuleSearchCard({super.key, required this.module});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15.r),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          children: [
            // Image
            CachedNetworkImage(
              imageUrl: module.moduleImage,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              placeholder: (context, url) => const CustomShimmer(),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey.shade200,
                child: const Icon(Icons.image),
              ),
            ),
            
            // Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),
            ),

            // Title Overlay (bottom left)
            Positioned(
              bottom: 8.h,
              left: 10.w,
              right: 10.w,
              child: Text(
                module.moduleTitle,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Lock Icon (top right) if is_free is 0
            if (module.alreadyOwned == false) // Simple check for free status or ownership
              Positioned(
                top: 8.h,
                right: 8.w,
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock,
                    color: Colors.white,
                    size: 14.sp,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
