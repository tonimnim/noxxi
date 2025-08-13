import 'package:flutter/material.dart';
import 'package:noxxi/core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onClear;
  final VoidCallback onFilterTap;
  final bool hasActiveFilters;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.onClear,
    required this.onFilterTap,
    this.hasActiveFilters = false,
  });

  @override
  Widget build(BuildContext context) {
    // Simple container with the EXACT same color as the screen
    return Container(
      height: 80,
      color: const Color(0xFFFCF9F7),  // Exact light cream color
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          // Search Field
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFFCF9F7),  // Same light cream
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFD4926B).withOpacity(0.2),  // Very light brown border
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // Search Icon
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 8),
                    child: Icon(
                      Icons.search,
                      color: const Color(0xFFC67C4E).withOpacity(0.5),  // Light brown icon
                      size: 20,
                    ),
                  ),
                  
                  // Input Field
                  Expanded(
                    child: TextField(
                      controller: controller,
                      style: GoogleFonts.sora(
                        fontSize: 14,
                        color: const Color(0xFF313131),  // Dark text for readability
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search events, venues, hotels...',
                        hintStyle: GoogleFonts.sora(
                          fontSize: 14,
                          color: const Color(0xFF313131).withOpacity(0.4),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  
                  // Clear Button
                  if (controller.text.isNotEmpty)
                    GestureDetector(
                      onTap: onClear,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Icon(
                          Icons.close,
                          color: const Color(0xFFC67C4E).withOpacity(0.5),
                          size: 18,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Filter Button
          GestureDetector(
            onTap: onFilterTap,
            child: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: hasActiveFilters 
                    ? const Color(0xFFC67C4E).withOpacity(0.1)  // Light brown tint when active
                    : const Color(0xFFFCF9F7),  // Same cream color
                shape: BoxShape.circle,
                border: Border.all(
                  color: hasActiveFilters
                      ? const Color(0xFFC67C4E).withOpacity(0.3)
                      : const Color(0xFFD4926B).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.tune,
                color: hasActiveFilters
                    ? const Color(0xFFC67C4E)  // Brown when active
                    : const Color(0xFFC67C4E).withOpacity(0.5),  // Light brown
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}