import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_routes.dart';
import '../constants/app_sizes.dart';
import 'Chew/chew_game.dart';
import 'Roulette/roulette_screen.dart';
import 'Star/star_game.dart';
import 'Flappy/flappy_game.dart';
import 'game_type.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final gameType = args is GameType ? args : GameType.game1;

    switch (gameType) {
      case GameType.game1:
        return const RouletteScreen();
      case GameType.game2:
        final game = StarGame();
        return Scaffold(
          body: GameWidget(
            game: game,
            initialActiveOverlays: const ['start'],
            overlayBuilderMap: {
              'start': (context, _) => _StarStartOverlay(game: game),
              'gameOver': (context, _) => _StarGameOverOverlay(game: game),
            },
          ),
        );
      case GameType.game3:
        final game = ChewGame();
        return Scaffold(
          body: GameWidget(
            game: game,
            initialActiveOverlays: const ['chewStart'],
            overlayBuilderMap: {
              'chewStart': (context, _) => _ChewStartOverlay(game: game),
              'chewGameOver': (context, _) => _ChewGameOverOverlay(game: game),
            },
          ),
        );
      case GameType.game4:
        final game = FlappyGame();
        return Scaffold(
          body: GameWidget(
            game: game,
            initialActiveOverlays: const ['flappyStart'],
            overlayBuilderMap: {
              'flappyStart': (context, _) => _FlappyStartOverlay(game: game),
              'flappyGameOver': (context, _) =>
                  _FlappyGameOverOverlay(game: game),
            },
          ),
        );
      default:
        return Scaffold(
          body: Center(
            child: Text('Game: ${gameType.name}', textAlign: TextAlign.center),
          ),
        );
    }
  }
}

class _StarStartOverlay extends StatelessWidget {
  const _StarStartOverlay({required this.game});

  final StarGame game;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / AppSizes.designWidth;
    final buttonWidth = AppSizes.starGameOverlayButtonWidth * scale;
    final buttonHeight = AppSizes.starGameOverlayButtonHeight * scale;
    final spacing = AppSizes.starGameOverlaySpacing * scale;
    final textSize = AppSizes.starGameOverlayTextSize * scale;

    return Container(
      color: AppColors.starGameOverlayScrim,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: buttonWidth,
              height: buttonHeight,
              child: ElevatedButton(
                onPressed: () => Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false),
                child: Text('홈으로', style: TextStyle(fontSize: textSize)),
              ),
            ),
            SizedBox(height: spacing),
            SizedBox(
              width: buttonWidth,
              height: buttonHeight,
              child: ElevatedButton(
                onPressed: game.startGame,
                child: Text('게임 시작', style: TextStyle(fontSize: textSize)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StarGameOverOverlay extends StatelessWidget {
  const _StarGameOverOverlay({required this.game});

  final StarGame game;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / AppSizes.designWidth;
    final buttonWidth = AppSizes.starGameOverlayButtonWidth * scale;
    final buttonHeight = AppSizes.starGameOverlayButtonHeight * scale;
    final spacing = AppSizes.starGameOverlaySpacing * scale;
    final textSize = AppSizes.starGameOverlayTextSize * scale;

    return Container(
      color: AppColors.starGameOverlayScrim,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: buttonWidth,
              height: buttonHeight,
              child: ElevatedButton(
                onPressed: () => Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false),
                child: Text('홈으로', style: TextStyle(fontSize: textSize)),
              ),
            ),
            SizedBox(height: spacing),
            SizedBox(
              width: buttonWidth,
              height: buttonHeight,
              child: ElevatedButton(
                onPressed: game.restartGame,
                child: Text('다시 하기', style: TextStyle(fontSize: textSize)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChewGameOverOverlay extends StatelessWidget {
  const _ChewGameOverOverlay({required this.game});

  final ChewGame game;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / AppSizes.designWidth;
    final buttonWidth = AppSizes.chewGameOverlayButtonWidth * scale;
    final buttonHeight = AppSizes.chewGameOverlayButtonHeight * scale;
    final spacing = AppSizes.chewGameOverlaySpacing * scale;
    final textSize = AppSizes.chewGameOverlayTextSize * scale;

    return Container(
      color: AppColors.chewGameOverlayScrim,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: buttonWidth,
              height: buttonHeight,
              child: ElevatedButton(
                onPressed: () => Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false),
                child: Text('홈으로', style: TextStyle(fontSize: textSize)),
              ),
            ),
            SizedBox(height: spacing),
            SizedBox(
              width: buttonWidth,
              height: buttonHeight,
              child: ElevatedButton(
                onPressed: game.restartGame,
                child: Text('다시 하기', style: TextStyle(fontSize: textSize)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChewStartOverlay extends StatelessWidget {
  const _ChewStartOverlay({required this.game});

  final ChewGame game;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / AppSizes.designWidth;
    final buttonWidth = AppSizes.chewGameOverlayButtonWidth * scale;
    final buttonHeight = AppSizes.chewGameOverlayButtonHeight * scale;
    final spacing = AppSizes.chewGameOverlaySpacing * scale;
    final textSize = AppSizes.chewGameOverlayTextSize * scale;

    return Container(
      color: AppColors.chewGameOverlayScrim,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: buttonWidth,
              height: buttonHeight,
              child: ElevatedButton(
                onPressed: () => Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false),
                child: Text('홈으로', style: TextStyle(fontSize: textSize)),
              ),
            ),
            SizedBox(height: spacing),
            SizedBox(
              width: buttonWidth,
              height: buttonHeight,
              child: ElevatedButton(
                onPressed: game.startGame,
                child: Text('게임 시작', style: TextStyle(fontSize: textSize)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlappyStartOverlay extends StatelessWidget {
  const _FlappyStartOverlay({required this.game});

  final FlappyGame game;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / AppSizes.designWidth;
    final buttonWidth = AppSizes.flappyOverlayButtonWidth * scale;
    final buttonHeight = AppSizes.flappyOverlayButtonHeight * scale;
    final spacing = AppSizes.flappyOverlaySpacing * scale;
    final textSize = AppSizes.flappyOverlayTextSize * scale;

    return Container(
      color: AppColors.starGameOverlayScrim,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: buttonWidth,
              height: buttonHeight,
              child: ElevatedButton(
                onPressed: () => Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false),
                child: Text('홈으로', style: TextStyle(fontSize: textSize)),
              ),
            ),
            SizedBox(height: spacing),
            SizedBox(
              width: buttonWidth,
              height: buttonHeight,
              child: ElevatedButton(
                onPressed: game.startGame,
                child: Text('게임 시작', style: TextStyle(fontSize: textSize)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlappyGameOverOverlay extends StatelessWidget {
  const _FlappyGameOverOverlay({required this.game});

  final FlappyGame game;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / AppSizes.designWidth;
    final buttonWidth = AppSizes.flappyOverlayButtonWidth * scale;
    final buttonHeight = AppSizes.flappyOverlayButtonHeight * scale;
    final spacing = AppSizes.flappyOverlaySpacing * scale;
    final textSize = AppSizes.flappyOverlayTextSize * scale;

    return Container(
      color: AppColors.starGameOverlayScrim,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: buttonWidth,
              height: buttonHeight,
              child: ElevatedButton(
                onPressed: () => Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false),
                child: Text('홈으로', style: TextStyle(fontSize: textSize)),
              ),
            ),
            SizedBox(height: spacing),
            SizedBox(
              width: buttonWidth,
              height: buttonHeight,
              child: ElevatedButton(
                onPressed: game.restartGame,
                child: Text('다시 하기', style: TextStyle(fontSize: textSize)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
