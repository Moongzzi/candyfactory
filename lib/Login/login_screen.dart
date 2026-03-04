import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../Home/widgets/logo_button.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import 'widgets/input_field.dart';
import 'widgets/login_button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.webGradientColors,
            stops: AppColors.webGradientStops,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final maxHeight = constraints.maxHeight;
              final scale = math.min(
                maxWidth / AppSizes.designWidth,
                maxHeight / AppSizes.designHeight,
              );
              final panelWidth = AppSizes.loginPanelWidth * scale;
              final panelHeight = AppSizes.loginPanelHeight * scale;
              final logoWidth = AppSizes.loginLogoWidth * scale;
              final logoSpacing = AppSizes.loginLogoSpacing * scale;
              final inputSpacing = AppSizes.loginInputSpacing * scale;
              final buttonSpacing = AppSizes.loginButtonSpacing * scale;

              return Center(
                child: Container(
                  width: panelWidth,
                  height: panelHeight,
                  decoration: BoxDecoration(
                    color: AppColors.loginPanelBackground,
                    border: Border.all(
                      color: AppColors.loginPanelOutline,
                      width: AppSizes.loginPanelBorderWidth * scale,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      LogoButton(width: logoWidth),
                      SizedBox(height: logoSpacing),
                      LoginInputField(placeholder: '닉네임', scale: scale),
                      SizedBox(height: inputSpacing),
                      LoginInputField(
                        placeholder: '비밀번호',
                        scale: scale,
                        obscureText: true,
                      ),
                      SizedBox(height: buttonSpacing),
                      LoginActionButton(scale: scale),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
