import 'package:flutter/material.dart';
import 'package:noxxi/core/theme/app_colors.dart';
import 'package:noxxi/features/home/widgets/animations/heart_animation.dart';
import 'package:noxxi/features/home/widgets/performance_image.dart';

/// Event card image with gradient overlay
/// Instagram-style image presentation
class EventCardImage extends StatelessWidget {
  final String imageUrl;
  final String eventTitle;
  final double aspectRatio;
  final VoidCallback? onDoubleTap;
  
  const EventCardImage({
    super.key,
    required this.imageUrl,
    required this.eventTitle,
    this.aspectRatio = 16 / 9, // Instagram-style aspect ratio
    this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Event image with double-tap animation
          HeartAnimationOverlay(
            isLiked: false, // This would come from event state
            onDoubleTap: onDoubleTap ?? () {},
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Event image
                _buildImage(),
                
                // Gradient overlay for text readability
                _buildGradientOverlay(),
                
                // Event title on image
                _buildTitleOverlay(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    return Builder(
      builder: (context) {
        // Find scroll controller from ancestor
        final scrollController = Scrollable.maybeOf(context)?.widget.controller;
        
        return PerformanceImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          scrollController: scrollController,
      placeholder: Container(
        color: AppColors.cardBackground.withOpacity(0.3),
        child: Center(
          child: Icon(
            Icons.image_outlined,
            size: 48,
            color: AppColors.darkText.withOpacity(0.2),
          ),
        ),
      ),
          errorWidget: Container(
            color: AppColors.cardBackground,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_not_supported_outlined,
                  size: 48,
                  color: AppColors.darkText.withOpacity(0.3),
                ),
                const SizedBox(height: 8),
                Text(
                  'Image not available',
                  style: TextStyle(
                    color: AppColors.darkText.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.3),
            Colors.black.withOpacity(0.7),
          ],
          stops: const [0.0, 0.5, 0.8, 1.0],
        ),
      ),
    );
  }

  Widget _buildTitleOverlay() {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Text(
        eventTitle,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          shadows: [
            Shadow(
              offset: Offset(0, 1),
              blurRadius: 3,
              color: Colors.black45,
            ),
          ],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}