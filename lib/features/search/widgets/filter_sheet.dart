import 'package:flutter/material.dart';
import 'package:noxxi/core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class FilterSheet extends StatefulWidget {
  final RangeValues? initialPriceRange;
  final DateTime? initialSelectedDate;
  final Function(RangeValues?, DateTime?) onApply;

  const FilterSheet({
    super.key,
    this.initialPriceRange,
    this.initialSelectedDate,
    required this.onApply,
  });

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  RangeValues? _priceRange;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _priceRange = widget.initialPriceRange;
    _selectedDate = widget.initialSelectedDate;
  }

  void _clearFilters() {
    setState(() {
      _priceRange = null;
      _selectedDate = null;
    });
  }

  void _applyFilters() {
    widget.onApply(_priceRange, _selectedDate);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildPriceRangeSection(),
          const SizedBox(height: 20),
          _buildDateSection(),
          const SizedBox(height: 24),
          _buildApplyButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Filters',
          style: GoogleFonts.sora(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.darkText,
          ),
        ),
        TextButton(
          onPressed: _clearFilters,
          child: Text(
            'Clear',
            style: GoogleFonts.sora(
              color: AppColors.primaryAccent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price Range (KSH)',
          style: GoogleFonts.sora(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 8),
        RangeSlider(
          values: _priceRange ?? const RangeValues(0, 10000),
          min: 0,
          max: 50000,
          divisions: 50,
          activeColor: AppColors.primaryAccent,
          labels: RangeLabels(
            'KSH ${(_priceRange?.start ?? 0).toStringAsFixed(0)}',
            'KSH ${(_priceRange?.end ?? 10000).toStringAsFixed(0)}',
          ),
          onChanged: (values) {
            setState(() => _priceRange = values);
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'KSH ${(_priceRange?.start ?? 0).toStringAsFixed(0)}',
              style: GoogleFonts.sora(
                fontSize: 12,
                color: AppColors.darkText.withOpacity(0.6),
              ),
            ),
            Text(
              'KSH ${(_priceRange?.end ?? 10000).toStringAsFixed(0)}',
              style: GoogleFonts.sora(
                fontSize: 12,
                color: AppColors.darkText.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Event Date',
          style: GoogleFonts.sora(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildDateChip(
              'Today',
              isSelected: _isToday(_selectedDate),
              onSelected: (selected) {
                setState(() {
                  _selectedDate = selected ? DateTime.now() : null;
                });
              },
            ),
            _buildDateChip(
              'Tomorrow',
              isSelected: _isTomorrow(_selectedDate),
              onSelected: (selected) {
                setState(() {
                  _selectedDate = selected
                      ? DateTime.now().add(const Duration(days: 1))
                      : null;
                });
              },
            ),
            _buildDateChip(
              'This Week',
              isSelected: _isThisWeek(_selectedDate),
              onSelected: (selected) {
                setState(() {
                  _selectedDate = selected
                      ? DateTime.now().add(const Duration(days: 7))
                      : null;
                });
              },
            ),
            _buildDateChip(
              'This Month',
              isSelected: _isThisMonth(_selectedDate),
              onSelected: (selected) {
                setState(() {
                  _selectedDate = selected
                      ? DateTime.now().add(const Duration(days: 30))
                      : null;
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateChip(String label, {required bool isSelected, required Function(bool) onSelected}) {
    return FilterChip(
      label: Text(
        label,
        style: GoogleFonts.sora(
          fontSize: 13,
          color: isSelected ? Colors.white : AppColors.darkText,
        ),
      ),
      selected: isSelected,
      onSelected: onSelected,
      backgroundColor: AppColors.cardBackground,
      selectedColor: AppColors.primaryAccent,
      side: BorderSide(
        color: isSelected ? AppColors.primaryAccent : AppColors.divider,
        width: 0.5,
      ),
    );
  }

  Widget _buildApplyButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _applyFilters,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryAccent,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Text(
          'Apply Filters',
          style: GoogleFonts.sora(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  bool _isToday(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  bool _isTomorrow(DateTime? date) {
    if (date == null) return false;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day;
  }

  bool _isThisWeek(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    final weekFromNow = now.add(const Duration(days: 7));
    return date.isAfter(now) && date.isBefore(weekFromNow);
  }

  bool _isThisMonth(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }
}