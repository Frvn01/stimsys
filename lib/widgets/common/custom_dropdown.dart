import 'package:flutter/material.dart';
import 'dart:ui';

class CustomDropdown<T> extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final T? value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final bool enabled;
  final String Function(T)? itemLabelBuilder;

  const CustomDropdown({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
    this.enabled = true,
    this.itemLabelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(enabled ? 0.05 : 0.02)
                    : Colors.black.withOpacity(enabled ? 0.02 : 0.01),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(enabled ? 0.1 : 0.05)
                      : Colors.black.withOpacity(enabled ? 0.08 : 0.04),
                ),
              ),
              child: DropdownButtonFormField<T>(
                initialValue: value,
                hint: Text(
                  hint,
                  style: TextStyle(
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                ),
                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    icon,
                    size: 18,
                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                items: items.map((item) {
                  return DropdownMenuItem<T>(
                    value: item,
                    child: Text(
                      itemLabelBuilder?.call(item) ?? item.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: enabled ? onChanged : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}