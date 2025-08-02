import 'package:flutter/material.dart';
import 'package:noxxi/core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class CategorySelector extends StatelessWidget {
  final String? selectedCategoryId;
  final Function(String?) onCategorySelected;
  final bool isLoading;

  const CategorySelector({
    super.key,
    this.selectedCategoryId,
    required this.onCategorySelected,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      color: AppColors.scaffoldBackground,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _CategoryItem(
            title: 'Events',
            icon: Icons.event,
            categoryId: 'events',
            isSelected: selectedCategoryId == 'events',
            onTap: () => onCategorySelected('events'),
          ),
          _CategoryItem(
            title: 'Cinema',
            icon: Icons.movie,
            categoryId: 'cinema',
            isSelected: selectedCategoryId == 'cinema',
            onTap: () => onCategorySelected('cinema'),
          ),
          _CategoryItem(
            title: 'Travel',
            icon: Icons.directions_bus,
            categoryId: 'travel',
            isSelected: selectedCategoryId == 'travel',
            onTap: () => onCategorySelected('travel'),
          ),
          _CategoryItem(
            title: 'Experiences',
            icon: Icons.explore,
            categoryId: 'experiences',
            isSelected: selectedCategoryId == 'experiences',
            onTap: () => onCategorySelected('experiences'),
          ),
        ],
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final String categoryId;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryItem({
    required this.title,
    required this.icon,
    required this.categoryId,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryAccent : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.darkText,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.sora(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primaryAccent : AppColors.darkText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}