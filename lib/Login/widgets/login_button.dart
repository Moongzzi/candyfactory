import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../constants/app_assets.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';

/// Login action button widget.
class LoginActionButton extends StatelessWidget {
  const LoginActionButton({
    super.key,
    this.width,
    this.height,
    this.scale,
    this.onPressed,
    this.isLoading = false,
  });

  final double? width;
  final double? height;
  final double? scale;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final effectiveScale =
        scale ??
        math.min(
          screen.width / AppSizes.designWidth,
          screen.height / AppSizes.designHeight,
        );
    final targetWidth =
        width ?? (AppSizes.loginActionButtonWidth * effectiveScale);
    final targetHeight =
        height ?? (AppSizes.loginActionButtonHeight * effectiveScale);
    final textSize = AppSizes.loginButtonTextSize * effectiveScale;

    return SizedBox(
      width: targetWidth,
      height: targetHeight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: Image.asset(
                  AppAssets.gradientButtonBg,
                  fit: BoxFit.fill,
                ),
              ),
              isLoading
                  ? SizedBox(
                      width: 20 * effectiveScale,
                      height: 20 * effectiveScale,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.softText,
                        ),
                      ),
                    )
                  : Text(
                      'Log In',
                      style: TextStyle(
                        color: AppColors.softText,
                        fontSize: textSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
