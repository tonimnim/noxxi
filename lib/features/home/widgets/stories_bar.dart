import 'package:flutter/material.dart';
import 'package:noxxi/core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noxxi/features/home/models/event_feed_item.dart';
import 'package:noxxi/features/home/widgets/performance_image.dart';
import 'package:intl/intl.dart';

/// Stories bar showing events happening today
class HappeningTodayBar extends StatelessWidget {
  final List<EventFeedItem> todayEvents;
  final Function(EventFeedItem) onEventTap;
  final bool isLoading;
  
  const HappeningTodayBar({
    super.key,
    required this.todayEvents,
    required this.onEventTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState();
    }
    
    if (todayEvents.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      color: AppColors.scaffoldBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Happening Today',
                  style: GoogleFonts.sora(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                  ),
                ),
                Icon(
                  Icons.local_fire_department,
                  size: 20,
                  color: AppColors.primaryAccent,
                ),
              ],
            ),
          ),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: todayEvents.length,
              itemBuilder: (context, index) {
                final event = todayEvents[index];
                return _StoryItem(
                  event: event,
                  onTap: () => onEventTap(event),
                  isFirst: index == 0,
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
  
  Widget _buildLoadingState() {
    return Container(
      color: AppColors.scaffoldBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Container(
              width: 120,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.darkText.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: 5,
              itemBuilder: (context, index) => const _StoryItemSkeleton(),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Individual story item
class _StoryItem extends StatelessWidget {
  final EventFeedItem event;
  final VoidCallback onTap;
  final bool isFirst;
  
  const _StoryItem({
    required this.event,
    required this.onTap,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: EdgeInsets.only(left: isFirst ? 4 : 6, right: 6),
        child: Column(
          children: [
            // Story circle with gradient border
            Container(
              width: 66,
              height: 66,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: event.isSoldOut 
                    ? LinearGradient(
                        colors: [
                          AppColors.darkText.withOpacity(0.3),
                          AppColors.darkText.withOpacity(0.3),
                        ],
                      )
                    : const LinearGradient(
                        colors: [
                          AppColors.primaryAccent,
                          Color(0xFFE3A857),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.scaffoldBackground,
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: PerformanceImage(
                    imageUrl: event.coverImageUrl,
                    fit: BoxFit.cover,
                    enableFadeIn: false, // Disable fade for small images
                    placeholder: Container(
                      color: AppColors.cardBackground,
                      child: Icon(
                        Icons.event,
                        size: 24,
                        color: AppColors.darkText.withOpacity(0.3),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Time
            Text(
              timeFormat.format(event.eventDate),
              style: GoogleFonts.sora(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: event.isSoldOut 
                    ? AppColors.error 
                    : AppColors.primaryAccent,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Title
            Text(
              event.title,
              style: GoogleFonts.sora(
                fontSize: 11,
                color: AppColors.darkText.withOpacity(0.8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Story item skeleton loader
class _StoryItemSkeleton extends StatelessWidget {
  const _StoryItemSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.darkText.withOpacity(0.1),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 40,
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.darkText.withOpacity(0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: 60,
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.darkText.withOpacity(0.05),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}