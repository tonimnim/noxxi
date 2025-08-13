import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noxxi/core/theme/app_colors.dart';

class EmptyTicketsState extends StatelessWidget {
  final bool isActiveTab;
  final VoidCallback onRefresh;
  
  const EmptyTicketsState({
    super.key,
    required this.isActiveTab,
    required this.onRefresh,
  });
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isActiveTab ? Icons.confirmation_number : Icons.history,
                size: 40,
                color: AppColors.primaryAccent.withOpacity(0.6),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              isActiveTab ? 'No Active Tickets' : 'No Past Tickets',
              style: GoogleFonts.sora(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Description
            Text(
              isActiveTab 
                  ? 'Your upcoming event tickets will appear here'
                  : 'Your used and expired tickets will appear here',
              style: GoogleFonts.sora(
                fontSize: 14,
                color: AppColors.darkText.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Browse Events Button (only for active tab)
            if (isActiveTab) ...[
              ElevatedButton(
                onPressed: () {
                  // Navigate to home tab in bottom navigation
                  if (context.findAncestorStateOfType<NavigatorState>() != null) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.explore,
                      size: 20,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Browse Events',
                      style: GoogleFonts.sora(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Refresh Button for used tickets
              TextButton.icon(
                onPressed: onRefresh,
                icon: Icon(
                  Icons.refresh,
                  color: AppColors.primaryAccent,
                ),
                label: Text(
                  'Refresh',
                  style: GoogleFonts.sora(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryAccent,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}