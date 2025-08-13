import 'package:flutter/material.dart';
import 'package:noxxi/core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noxxi/features/search/services/search_service.dart';
import 'package:noxxi/features/search/widgets/search_result_card.dart';

class SearchResultsGrid extends StatelessWidget {
  final List<SearchResult> events;
  final bool isSearching;
  final String title;
  final Function(SearchResult) onEventTap;

  const SearchResultsGrid({
    super.key,
    required this.events,
    required this.isSearching,
    required this.title,
    required this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty && !isSearching) {
      return SliverFillRemaining(
        child: _buildEmptyState(),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (isSearching && index == 0) {
              return const Center(child: CircularProgressIndicator());
            }
            return SearchResultCard(
              event: events[index],
              onTap: () => onEventTap(events[index]),
            );
          },
          childCount: events.length,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppColors.darkText.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No events found',
            style: GoogleFonts.sora(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching for concerts, hotels, or spas',
            style: GoogleFonts.sora(
              fontSize: 14,
              color: AppColors.darkText.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}