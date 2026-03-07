import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../constants/app_assets.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../../constants/app_sizes.dart';

/// Home login button widget.
class LoginButton extends StatelessWidget {
  const LoginButton({
    super.key,
    this.width,
    this.scale,
    this.onPressed,
    this.label = 'Log In',
  });

  final double? width;
  final double? scale;
  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final effectiveScale =
        scale ??
        math.min(
          screen.width / AppSizes.designWidth,
          screen.height / AppSizes.designHeight,
        );
    final targetWidth = width ?? (AppSizes.loginButtonWidth * effectiveScale);
    final height = AppSizes.loginButtonHeight * effectiveScale;
    final textSize = AppSizes.loginButtonTextSize * effectiveScale;
    final handleTap =
        onPressed ?? () => Navigator.of(context).pushNamed(AppRoutes.login);

    return SizedBox(
      width: targetWidth,
      height: height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: handleTap,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: Image.asset(
                  AppAssets.gradientButtonBg,
                  fit: BoxFit.fill,
                ),
              ),
              Text(
                label,
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
