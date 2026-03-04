import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../Game/game_type.dart';
import '../constants/app_colors.dart';
import '../constants/app_routes.dart';
import '../constants/app_sizes.dart';
import 'widgets/button_group.dart';
import 'widgets/logo_button.dart';
import 'widgets/login_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
              final padding = AppSizes.homeScreenPadding * scale;
              final spacing = AppSizes.homeVerticalSpacing * scale;
              final logoWidth = AppSizes.homeLogoWidth * scale;
              final loginWidth = AppSizes.loginButtonWidth * scale;
              final contentWidth = AppSizes.designWidth * scale;

              return Center(
                child: SizedBox(
                  width: contentWidth,
                  child: Padding(
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LogoButton(width: logoWidth),
                        SizedBox(height: spacing),
                        LoginButton(width: loginWidth, scale: scale),
                        SizedBox(height: spacing),
                        SizedBox(
                          width: contentWidth - (padding * 2),
                          child: HomeButtonGroup(
                            // TODO: Connect navigation callbacks for each button.
                            onRanking: () => Navigator.of(
                              context,
                            ).pushNamed(AppRoutes.ranking),
                            onBigLeft: () => Navigator.of(context).pushNamed(
                              AppRoutes.game,
                              arguments: GameType.game1,
                            ),
                            onRightTop: () => Navigator.of(context).pushNamed(
                              AppRoutes.game,
                              arguments: GameType.game2,
                            ),
                            onRightBottom: () =>
                                Navigator.of(context).pushNamed(
                                  AppRoutes.game,
                                  arguments: GameType.game3,
                                ),
                            onBottomLeft: () => Navigator.of(context).pushNamed(
                              AppRoutes.game,
                              arguments: GameType.game4,
                            ),
                            onBottomRight: () =>
                                Navigator.of(context).pushNamed(
                                  AppRoutes.game,
                                  arguments: GameType.game5,
                                ),
                          ),
                        ),
                      ],
                    ),
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
