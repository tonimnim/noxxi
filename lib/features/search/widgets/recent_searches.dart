import 'package:flutter/material.dart';
import 'package:noxxi/core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class RecentSearches extends StatelessWidget {
  final List<String> searches;
  final Function(String) onSearchTap;
  final VoidCallback onClear;

  const RecentSearches({
    super.key,
    required this.searches,
    required this.onSearchTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    if (searches.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Searches',
                style: GoogleFonts.sora(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.darkText.withOpacity(0.7),
                ),
              ),
              GestureDetector(
                onTap: onClear,
                child: Text(
                  'Clear',
                  style: GoogleFonts.sora(
                    fontSize: 12,
                    color: AppColors.primaryAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 36,
          padding: const EdgeInsets.only(left: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: searches.length,
            itemBuilder: (context, index) {
              final search = searches[index];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: Text(
                    search,
                    style: GoogleFonts.sora(
                      fontSize: 13,
                      color: AppColors.darkText,
                    ),
                  ),
                  backgroundColor: AppColors.scaffoldBackground,
                  side: BorderSide(
                    color: AppColors.divider.withOpacity(0.5),
                    width: 1,
                  ),
                  onPressed: () => onSearchTap(search),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}