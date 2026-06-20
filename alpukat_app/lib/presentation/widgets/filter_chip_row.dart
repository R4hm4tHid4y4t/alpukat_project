import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Baris filter chip horizontal, contoh: Semua | Miki | Aligator
class FilterChipRow extends StatelessWidget {
  final List<FilterOption> options;
  final dynamic selectedValue;
  final ValueChanged<dynamic> onSelected;

  const FilterChipRow({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = option.value == selectedValue;

          return ChoiceChip(
            label: Text(option.label),
            selected: isSelected,
            onSelected: (_) => onSelected(option.value),
            selectedColor: AppColors.primaryGreen,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppColors.textDark,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: isSelected ? AppColors.primaryGreen : AppColors.borderColor),
            ),
          );
        },
      ),
    );
  }
}

class FilterOption {
  final String label;
  final dynamic value;
  const FilterOption({required this.label, required this.value});
}
