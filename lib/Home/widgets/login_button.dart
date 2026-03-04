import 'package:flutter/material.dart';

import '../../constants/app_assets.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../../constants/app_sizes.dart';

/// Home login button widget.
class LoginButton extends StatelessWidget {
  const LoginButton({super.key, this.width, this.scale, this.onPressed});

  final double? width;
  final double? scale;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final effectiveScale = scale ?? (screenWidth / AppSizes.designWidth);
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
