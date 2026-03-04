import 'package:flutter/material.dart';

import '../../constants/app_assets.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';

/// Login action button widget.
class LoginActionButton extends StatelessWidget {
  const LoginActionButton({super.key, this.width, this.height, this.scale});

  final double? width;
  final double? height;
  final double? scale;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final effectiveScale = scale ?? (screenWidth / AppSizes.designWidth);
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
          onTap: () {
            // TODO: Trigger login API request.
          },
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
