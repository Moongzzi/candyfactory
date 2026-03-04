import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';

/// Login input field widget.
class LoginInputField extends StatelessWidget {
  const LoginInputField({
    super.key,
    required this.placeholder,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.obscureText = false,
    this.width,
    this.height,
    this.scale,
  });

  final String placeholder;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool obscureText;
  final double? width;
  final double? height;
  final double? scale;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final effectiveScale = scale ?? (screenWidth / AppSizes.designWidth);
    final targetWidth = width ?? (AppSizes.loginInputWidth * effectiveScale);
    final targetHeight = height ?? (AppSizes.loginInputHeight * effectiveScale);
    final radius = AppSizes.loginInputRadius * effectiveScale;
    final hintSize = AppSizes.loginInputHintTextSize * effectiveScale;

    return SizedBox(
      width: targetWidth,
      height: targetHeight,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        obscureText: obscureText,
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: AppColors.inputBackground,
          hintText: placeholder,
          hintStyle: TextStyle(
            color: AppColors.placeholderText,
            fontSize: hintSize,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: const BorderSide(
              color: AppColors.inputOutline,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: const BorderSide(
              color: AppColors.inputOutline,
              width: 1,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12 * effectiveScale,
            vertical: 8 * effectiveScale,
          ),
        ),
      ),
    );
  }
}
