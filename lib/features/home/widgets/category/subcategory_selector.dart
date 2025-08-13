import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noxxi/core/theme/app_colors.dart';
import 'package:noxxi/features/home/services/category_state_manager.dart';

class SubcategorySelector extends StatelessWidget {
  final List<CategoryItem> subcategories;
  final String? selectedSubcategoryId;
  final Function(String?) onSubcategorySelected;
  final bool isLoading;

  const SubcategorySelector({
    super.key,
    required this.subcategories,
    required this.selectedSubcategoryId,
    required this.onSubcategorySelected,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (subcategories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: subcategories.length + 1, // +1 for "All" option
        itemBuilder: (context, index) {
          if (index == 0) {
            // "All" option
            final isSelected = selectedSubcategoryId == null;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                label: Text(
                  'All',
                  style: GoogleFonts.sora(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? Colors.white : AppColors.darkText,
                  ),
                ),
                selected: isSelected,
                onSelected: (_) => onSubcategorySelected(null),
                backgroundColor: Colors.white,
                selectedColor: AppColors.primaryAccent,
                side: BorderSide(
                  color: isSelected ? AppColors.primaryAccent : AppColors.border,
                  width: 1,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            );
          }

          final subcategory = subcategories[index - 1];
          final isSelected = selectedSubcategoryId == subcategory.id;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(
                subcategory.name,
                style: GoogleFonts.sora(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.white : AppColors.darkText,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => onSubcategorySelected(subcategory.id),
              backgroundColor: Colors.white,
              selectedColor: AppColors.primaryAccent,
              side: BorderSide(
                color: isSelected ? AppColors.primaryAccent : AppColors.border,
                width: 1,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          );
        },
      ),
    );
  }
}