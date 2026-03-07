import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'Common/web_blocked_screen.dart';
import 'Game/game_screen.dart';
import 'Home/home_screen.dart';
import 'Login/login_screen.dart';
import 'Ranking/ranking_screen.dart';
import 'constants/app_routes.dart';

void main() {
  runApp(const CandyFactoryApp());
}

class CandyFactoryApp extends StatelessWidget {
  const CandyFactoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '옥끼의 사탕공장',
      theme: ThemeData(fontFamily: 'EF_AONE'),
      initialRoute: AppRoutes.home,
      builder: (context, child) {
        if (kIsWeb) {
          final shortestSide = MediaQuery.of(context).size.shortestSide;
          final isMobileWeb = shortestSide < 600;
          if (!isMobileWeb) {
            return const WebBlockedScreen();
          }
        }

        return child ?? const SizedBox.shrink();
      },
      routes: {
        AppRoutes.home: (context) => const HomeScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.ranking: (context) => const RankingScreen(),
        AppRoutes.game: (context) => const GameScreen(),
      },
    );
  }
}
