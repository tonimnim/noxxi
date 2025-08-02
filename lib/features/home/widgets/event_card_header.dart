import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:noxxi/core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

/// Event card header with date/time pill and venue info
class EventCardHeader extends StatelessWidget {
  final DateTime eventDate;
  final String venueName;
  final String? venueAddress;
  final String? city;
  
  const EventCardHeader({
    super.key,
    required this.eventDate,
    required this.venueName,
    this.venueAddress,
    this.city,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date and time pill
          _buildDateTimePill(),
          
          const SizedBox(height: 12),
          
          // Venue information
          _buildVenueInfo(),
        ],
      ),
    );
  }

  Widget _buildDateTimePill() {
    final now = DateTime.now();
    final isToday = eventDate.year == now.year &&
        eventDate.month == now.month &&
        eventDate.day == now.day;
    
    final isTomorrow = eventDate.difference(now).inDays == 1 &&
        eventDate.day == now.add(const Duration(days: 1)).day;

    String dateText;
    if (isToday) {
      dateText = 'Today';
    } else if (isTomorrow) {
      dateText = 'Tomorrow';
    } else {
      dateText = DateFormat('EEE, MMM d').format(eventDate);
    }
    
    final timeText = DateFormat('h:mm a').format(eventDate);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isToday 
                ? AppColors.primaryAccent 
                : AppColors.darkText.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: isToday ? Colors.white : AppColors.darkText,
              ),
              const SizedBox(width: 6),
              Text(
                '$dateText • $timeText',
                style: GoogleFonts.sora(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isToday ? Colors.white : AppColors.darkText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVenueInfo() {
    final locationText = _buildLocationText();
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.location_on_outlined,
          size: 18,
          color: AppColors.darkText.withOpacity(0.7),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                venueName,
                style: GoogleFonts.sora(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (locationText.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  locationText,
                  style: GoogleFonts.sora(
                    fontSize: 12,
                    color: AppColors.darkText.withOpacity(0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _buildLocationText() {
    final parts = <String>[];
    if (venueAddress != null && venueAddress!.isNotEmpty) {
      parts.add(venueAddress!);
    }
    if (city != null && city!.isNotEmpty) {
      parts.add(city!);
    }
    return parts.join(', ');
  }
}