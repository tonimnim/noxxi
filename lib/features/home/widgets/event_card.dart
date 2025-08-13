import 'package:flutter/material.dart';
import 'package:noxxi/core/theme/app_colors.dart';
import 'package:noxxi/features/home/models/event_feed_item.dart';
import 'package:noxxi/features/home/widgets/event_card_image.dart';
import 'package:noxxi/features/home/widgets/event_card_header.dart';
import 'package:noxxi/features/home/widgets/event_card_actions.dart';

/// Instagram-style event card
/// Combines image, header, and actions into a complete card
class EventCard extends StatelessWidget {
  final EventFeedItem event;
  final VoidCallback onTap;
  final VoidCallback onToggleCart;
  final VoidCallback? onShare;
  final VoidCallback? onDoubleTap;
  
  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
    required this.onToggleCart,
    this.onShare,
    this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              offset: const Offset(0, 4),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event image with title overlay
              EventCardImage(
                imageUrl: event.coverImageUrl,
                eventTitle: event.title,
                onDoubleTap: onDoubleTap ?? onToggleCart,
              ),
              
              // Date/time and venue info
              EventCardHeader(
                eventDate: event.eventDate,
                venueName: event.venueName,
                venueAddress: event.venueAddress,
                city: event.city,
              ),
              
              // Divider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 1,
                  color: AppColors.darkText.withOpacity(0.1),
                ),
              ),
              
              // Actions: Get tickets, heart (cart), share
              EventCardActions(
                eventId: event.id,
                eventTitle: event.title,
                priceRange: event.priceRange,
                isInCart: event.isInCart,
                isSoldOut: event.isSoldOut,
                onGetTickets: onTap,
                onToggleCart: onToggleCart,
                onShare: onShare,
              ),
            ],
          ),
        ),
      ),
    );
  }
}