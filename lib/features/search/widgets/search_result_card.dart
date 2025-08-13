import 'package:flutter/material.dart';
import 'package:noxxi/core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noxxi/features/search/services/search_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

/// Pinterest-style event card for search results
/// Optimized for two-column grid layout
class SearchResultCard extends StatelessWidget {
  final SearchResult event;
  final VoidCallback onTap;

  const SearchResultCard({
    super.key,
    required this.event,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Image
            _buildEventImage(),
            
            // Event Details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    event.title,
                    style: GoogleFonts.sora(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Date
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 12,
                        color: AppColors.darkText.withOpacity(0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(event.eventDate),
                        style: GoogleFonts.sora(
                          fontSize: 11,
                          color: AppColors.darkText.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Venue
                  if (event.venueName != null) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: AppColors.darkText.withOpacity(0.5),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.venueName!,
                            style: GoogleFonts.sora(
                              fontSize: 11,
                              color: AppColors.darkText.withOpacity(0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  
                  // Price and Availability
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Price
                      Text(
                        event.priceDisplay,
                        style: GoogleFonts.sora(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryAccent,
                        ),
                      ),
                      
                      // Availability indicator
                      if (event.soldPercentage > 80)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Selling Fast',
                            style: GoogleFonts.sora(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppColors.error,
                            ),
                          ),
                        ),
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

  Widget _buildEventImage() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: AspectRatio(
        aspectRatio: 1.0, // Square images for Pinterest style
        child: event.imageUrl != null
            ? CachedNetworkImage(
                imageUrl: event.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.divider.withOpacity(0.3),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primaryAccent.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.divider.withOpacity(0.3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_not_supported_outlined,
                        size: 32,
                        color: AppColors.darkText.withOpacity(0.3),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.categoryName ?? 'Event',
                        style: GoogleFonts.sora(
                          fontSize: 10,
                          color: AppColors.darkText.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Container(
                color: _getCategoryColor(event.categoryName),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getCategoryIcon(event.categoryName),
                        size: 40,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        event.categoryName ?? 'Event',
                        style: GoogleFonts.sora(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);
    
    // Today
    if (date.year == now.year && 
        date.month == now.month && 
        date.day == now.day) {
      return 'Today ${DateFormat('HH:mm').format(date)}';
    }
    
    // Tomorrow
    if (difference.inDays == 1) {
      return 'Tomorrow ${DateFormat('HH:mm').format(date)}';
    }
    
    // This week
    if (difference.inDays > 0 && difference.inDays < 7) {
      return DateFormat('EEE, HH:mm').format(date);
    }
    
    // This month
    if (date.year == now.year && date.month == now.month) {
      return DateFormat('MMM d').format(date);
    }
    
    // This year
    if (date.year == now.year) {
      return DateFormat('MMM d').format(date);
    }
    
    // Next year
    return DateFormat('MMM d, yyyy').format(date);
  }

  Color _getCategoryColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'music':
      case 'concert':
        return const Color(0xFF9C27B0); // Purple
      case 'sports':
        return const Color(0xFF4CAF50); // Green
      case 'business':
      case 'conference':
        return const Color(0xFF2196F3); // Blue
      case 'food':
      case 'dining':
        return const Color(0xFFFF9800); // Orange
      case 'art':
      case 'culture':
        return const Color(0xFFE91E63); // Pink
      case 'tech':
        return const Color(0xFF00BCD4); // Cyan
      case 'travel':
      case 'tourism':
        return const Color(0xFF009688); // Teal
      case 'cinema':
      case 'movies':
        return const Color(0xFFF44336); // Red
      case 'experiences':
        return const Color(0xFF795548); // Brown
      default:
        return AppColors.primaryAccent;
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'music':
      case 'concert':
        return Icons.music_note;
      case 'sports':
        return Icons.sports_basketball;
      case 'business':
      case 'conference':
        return Icons.business_center;
      case 'food':
      case 'dining':
        return Icons.restaurant;
      case 'art':
      case 'culture':
        return Icons.palette;
      case 'tech':
        return Icons.computer;
      case 'travel':
      case 'tourism':
        return Icons.flight;
      case 'cinema':
      case 'movies':
        return Icons.movie;
      case 'experiences':
        return Icons.star;
      default:
        return Icons.event;
    }
  }
}