import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../Common/session_store.dart';
import '../Game/game_type.dart';
import '../constants/app_colors.dart';
import '../constants/app_routes.dart';
import '../constants/app_sizes.dart';
import 'widgets/button_group.dart';
import 'widgets/logo_button.dart';
import 'widgets/login_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _requireLoginAndNavigate(
    BuildContext context, {
    required VoidCallback onLoggedIn,
  }) async {
    if (SessionStore.nickname.value != null) {
      onLoggedIn();
      return;
    }

    final shouldGoLogin = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: const Text('로그인이 필요합니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );

    if (shouldGoLogin == true && context.mounted) {
      Navigator.of(context).pushNamed(AppRoutes.login);
    }
  }

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
                        ValueListenableBuilder<String?>(
                          valueListenable: SessionStore.nickname,
                          builder: (context, nickname, _) {
                            return LoginButton(
                              width: loginWidth,
                              scale: scale,
                              label: nickname ?? 'Log In',
                              onPressed: () async {
                                if (nickname == null) {
                                  Navigator.of(
                                    context,
                                  ).pushNamed(AppRoutes.login);
                                  return;
                                }

                                final shouldLogout = await showDialog<bool>(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      content: const Text('로그아웃 하시겠습니까?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                          child: const Text('취소'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(true),
                                          child: const Text('확인'),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (shouldLogout == true) {
                                  SessionStore.logout();
                                }
                              },
                            );
                          },
                        ),
                        SizedBox(height: spacing),
                        SizedBox(
                          width: contentWidth - (padding * 2),
                          child: HomeButtonGroup(
                            onRanking: () => _requireLoginAndNavigate(
                              context,
                              onLoggedIn: () => Navigator.of(
                                context,
                              ).pushNamed(AppRoutes.ranking),
                            ),
                            onBigLeft: () => _requireLoginAndNavigate(
                              context,
                              onLoggedIn: () => Navigator.of(context).pushNamed(
                                AppRoutes.game,
                                arguments: GameType.game1,
                              ),
                            ),
                            onRightTop: () => _requireLoginAndNavigate(
                              context,
                              onLoggedIn: () => Navigator.of(context).pushNamed(
                                AppRoutes.game,
                                arguments: GameType.game2,
                              ),
                            ),
                            onRightBottom: () => _requireLoginAndNavigate(
                              context,
                              onLoggedIn: () => Navigator.of(context).pushNamed(
                                AppRoutes.game,
                                arguments: GameType.game3,
                              ),
                            ),
                            onBottomLeft: () => _requireLoginAndNavigate(
                              context,
                              onLoggedIn: () => Navigator.of(context).pushNamed(
                                AppRoutes.game,
                                arguments: GameType.game4,
                              ),
                            ),
                            onBottomRight: () => _requireLoginAndNavigate(
                              context,
                              onLoggedIn: () => Navigator.of(context).pushNamed(
                                AppRoutes.game,
                                arguments: GameType.game5,
                              ),
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
