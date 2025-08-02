import 'package:flutter/material.dart';
import 'package:noxxi/core/theme/app_colors.dart';

/// Skeleton loader for event cards
class EventCardSkeleton extends StatefulWidget {
  const EventCardSkeleton({super.key});

  @override
  State<EventCardSkeleton> createState() => _EventCardSkeletonState();
}

class _EventCardSkeletonState extends State<EventCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image skeleton
            AspectRatio(
              aspectRatio: 16 / 9,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(-1.0 + _animation.value, 0),
                        end: Alignment(-0.5 + _animation.value, 0),
                        colors: [
                          AppColors.cardBackground.withOpacity(0.8),
                          AppColors.scaffoldBackground,
                          AppColors.cardBackground.withOpacity(0.8),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Content skeleton
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date pill skeleton
                  _buildSkeletonBox(width: 120, height: 28),
                  const SizedBox(height: 12),
                  
                  // Venue skeleton
                  Row(
                    children: [
                      _buildSkeletonBox(width: 16, height: 16),
                      const SizedBox(width: 8),
                      _buildSkeletonBox(width: 150, height: 16),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildSkeletonBox(width: 100, height: 14),
                ],
              ),
            ),
            
            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildSkeletonBox(width: double.infinity, height: 1),
            ),
            
            // Actions skeleton
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSkeletonBox(width: 80, height: 20),
                  Row(
                    children: [
                      _buildSkeletonBox(width: 100, height: 40),
                      const SizedBox(width: 8),
                      _buildSkeletonBox(width: 40, height: 40, isCircle: true),
                      const SizedBox(width: 8),
                      _buildSkeletonBox(width: 40, height: 40, isCircle: true),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonBox({
    required double width,
    required double height,
    bool isCircle = false,
  }) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: isCircle ? null : BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + _animation.value, 0),
              end: Alignment(-0.5 + _animation.value, 0),
              colors: [
                AppColors.darkText.withOpacity(0.05),
                AppColors.darkText.withOpacity(0.1),
                AppColors.darkText.withOpacity(0.05),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Event feed skeleton loader
class EventFeedSkeleton extends StatelessWidget {
  final int itemCount;
  
  const EventFeedSkeleton({
    super.key,
    this.itemCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) => const EventCardSkeleton(),
    );
  }
}