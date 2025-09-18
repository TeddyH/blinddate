import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';

class InterestChipInput extends StatefulWidget {
  final List<String> interests;
  final Function(List<String>) onChanged;
  final String? errorText;

  const InterestChipInput({
    super.key,
    required this.interests,
    required this.onChanged,
    this.errorText,
  });

  @override
  State<InterestChipInput> createState() => _InterestChipInputState();
}

class _InterestChipInputState extends State<InterestChipInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addInterest() {
    final interest = _controller.text.trim();
    if (interest.isNotEmpty &&
        !widget.interests.contains(interest) &&
        interest.length <= 20) {
      widget.onChanged([...widget.interests, interest]);
      _controller.clear();
    }
  }

  void _removeInterest(String interest) {
    final updatedInterests = widget.interests.where((i) => i != interest).toList();
    widget.onChanged(updatedInterests);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Interest chips
        if (widget.interests.isNotEmpty) ...[
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: widget.interests.map((interest) => Chip(
              label: Text(
                interest,
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              backgroundColor: AppColors.accent.withValues(alpha: 0.1),
              deleteIcon: Icon(
                Icons.close,
                size: 18,
                color: AppColors.accent,
              ),
              onDeleted: () => _removeInterest(interest),
              side: BorderSide(
                color: AppColors.accent.withValues(alpha: 0.3),
                width: 1,
              ),
            )).toList(),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // Input field
        TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            labelText: '관심사 추가',
            hintText: '관심사를 입력하고 추가 버튼을 누르세요',
            errorText: widget.errorText,
            suffixIcon: IconButton(
              onPressed: _addInterest,
              icon: const Icon(Icons.add),
              tooltip: '추가',
            ),
          ),
          maxLength: 20,
          onFieldSubmitted: (_) => _addInterest(),
          textInputAction: TextInputAction.done,
        ),

        const SizedBox(height: AppSpacing.sm),

        // Helper text
        Text(
          '• 관심사별로 입력 후 추가 버튼을 누르세요\n• 관심사당 최대 20자까지 입력 가능\n• 삭제하려면 태그의 X 버튼을 누르세요',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}