import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Figma spec section F, exact values: 55px tall, 12px radius, 1px
/// #E8E6DF border, search icon left, hint text centered in the field.
class SearchBarField extends StatefulWidget {
  const SearchBarField({
    super.key,
    required this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onCleared,
    this.placeholder = 'Search Vegetables, Fruits...',
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onCleared;
  final String placeholder;

  @override
  State<SearchBarField> createState() => _SearchBarFieldState();
}

class _SearchBarFieldState extends State<SearchBarField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChanged);
    super.dispose();
  }

  void _handleTextChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSpacing.searchBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/icons/icon_search.svg',
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(AppColors.placeholder, BlendMode.srcIn),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              label: 'Search catalog',
              textField: true,
              child: TextField(
                controller: widget.controller,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                textAlign: TextAlign.start,
                style: AppTextStyles.caption.copyWith(color: AppColors.primaryText),
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: widget.placeholder,
                  hintStyle: AppTextStyles.caption,
                ),
              ),
            ),
          ),
          if (widget.controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                widget.controller.clear();
                widget.onCleared?.call();
              },
              child: const Icon(Icons.close, size: 18, color: AppColors.placeholder),
            ),
        ],
      ),
    );
  }
}
