import 'package:flutter/material.dart';
import 'package:noxxi/core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

/// Event card actions - Get Tickets button and heart (add to cart) + share
class EventCardActions extends StatelessWidget {
  final String eventId;
  final String eventTitle;
  final String priceRange;
  final bool isInCart;
  final bool isSoldOut;
  final VoidCallback onGetTickets;
  final VoidCallback onToggleCart;
  final VoidCallback? onShare;
  
  const EventCardActions({
    super.key,
    required this.eventId,
    required this.eventTitle,
    required this.priceRange,
    required this.isInCart,
    required this.isSoldOut,
    required this.onGetTickets,
    required this.onToggleCart,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Price display
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  priceRange,
                  style: GoogleFonts.sora(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryAccent,
                  ),
                ),
                if (isSoldOut)
                  Text(
                    'SOLD OUT',
                    style: GoogleFonts.sora(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
              ],
            ),
          ),
          
          // Action buttons
          Row(
            children: [
              // Get Tickets button
              _buildGetTicketsButton(context),
              
              const SizedBox(width: 8),
              
              // Heart (Add to Cart) button
              _buildCartButton(),
              
              const SizedBox(width: 8),
              
              // Share button
              _buildShareButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGetTicketsButton(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ElevatedButton(
        onPressed: isSoldOut ? null : onGetTickets,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          disabledBackgroundColor: AppColors.darkText.withOpacity(0.2),
        ),
        child: Text(
          isSoldOut ? 'Sold Out' : 'Get Tickets',
          style: GoogleFonts.sora(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildCartButton() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isInCart 
            ? AppColors.primaryAccent.withOpacity(0.1)
            : AppColors.darkText.withOpacity(0.05),
        shape: BoxShape.circle,
        border: Border.all(
          color: isInCart 
              ? AppColors.primaryAccent
              : AppColors.darkText.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: IconButton(
        onPressed: onToggleCart,
        icon: Icon(
          isInCart ? Icons.favorite : Icons.favorite_border,
          color: isInCart 
              ? AppColors.primaryAccent
              : AppColors.darkText.withOpacity(0.7),
          size: 20,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildShareButton() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.darkText.withOpacity(0.05),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.darkText.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: IconButton(
        onPressed: onShare ?? () => _handleShare(),
        icon: Icon(
          Icons.share_outlined,
          color: AppColors.darkText.withOpacity(0.7),
          size: 20,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }

  void _handleShare() {
    // Default share implementation
    final shareText = 'Check out "$eventTitle" on Noxxi!\n\n'
        '$priceRange\n\n'
        'Get your tickets now: https://noxxi.app/events/$eventId';
    
    Share.share(
      shareText,
      subject: eventTitle,
    );
  }
}