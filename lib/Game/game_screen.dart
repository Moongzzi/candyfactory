import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_routes.dart';
import '../constants/app_sizes.dart';
import 'Chew/chew_game.dart';
import 'Roulette/roulette_screen.dart';
import 'Star/star_game.dart';
import 'Flappy/flappy_game.dart';
import 'Up/up_game.dart';
import 'game_play_api_service.dart';
import 'game_type.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final GamePlayApiService _gamePlayApiService = GamePlayApiService();
  final Map<GameType, String> _activeLogIds = <GameType, String>{};
  final Map<GameType, bool> _roundActive = <GameType, bool>{};

  String _gameCode(GameType gameType) {
    switch (gameType) {
      case GameType.game2:
        return 'game2';
      case GameType.game3:
        return 'game3';
      case GameType.game4:
        return 'game4';
      case GameType.game5:
        return 'game5';
      default:
        return gameType.name;
    }
  }

  void _onGameStart(GameType gameType) {
    _roundActive[gameType] = true;
    _activeLogIds.remove(gameType);
    unawaited(_sendGameStart(gameType));
  }

  void _onGameFinish(GameType gameType, int score) {
    _roundActive[gameType] = false;
    unawaited(_sendGameFinish(gameType, score));
  }

  Future<void> _sendGameStart(GameType gameType) async {
    final logId = await _gamePlayApiService.startGame(
      gameCode: _gameCode(gameType),
    );
    if (logId == null || logId.isEmpty) {
      return;
    }
    if (_roundActive[gameType] != true) {
      return;
    }
    _activeLogIds[gameType] = logId;
  }

  Future<void> _sendGameFinish(GameType gameType, int score) async {
    final logId = _activeLogIds.remove(gameType);
    await _gamePlayApiService.finishGame(
      gameCode: _gameCode(gameType),
      score: score,
      logId: logId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final gameType = args is GameType ? args : GameType.game1;

    switch (gameType) {
      case GameType.game1:
        return const RouletteScreen();
      case GameType.game2:
        final game = StarGame(
          onGameStarted: () => _onGameStart(GameType.game2),
          onGameFinished: (score) => _onGameFinish(GameType.game2, score),
        );
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
        final game = ChewGame(
          onGameStarted: () => _onGameStart(GameType.game3),
          onGameFinished: (score) => _onGameFinish(GameType.game3, score),
        );
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
        final game = FlappyGame(
          onGameStarted: () => _onGameStart(GameType.game4),
          onGameFinished: (score) => _onGameFinish(GameType.game4, score),
        );
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
      case GameType.game5:
        final game = UpGame(
          onGameStarted: () => _onGameStart(GameType.game5),
          onGameFinished: (score) => _onGameFinish(GameType.game5, score),
        );
        return Scaffold(
          body: GameWidget(
            game: game,
            initialActiveOverlays: const ['upStart'],
            overlayBuilderMap: {
              'upStart': (context, _) => _UpStartOverlay(game: game),
              'upGameOver': (context, _) => _UpGameOverOverlay(game: game),
            },
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

class _UpStartOverlay extends StatelessWidget {
  const _UpStartOverlay({required this.game});

  final UpGame game;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / AppSizes.designWidth;
    final buttonWidth = AppSizes.upOverlayButtonWidth * scale;
    final buttonHeight = AppSizes.upOverlayButtonHeight * scale;
    final spacing = AppSizes.upOverlaySpacing * scale;
    final textSize = AppSizes.upOverlayTextSize * scale;

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

class _UpGameOverOverlay extends StatelessWidget {
  const _UpGameOverOverlay({required this.game});

  final UpGame game;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / AppSizes.designWidth;
    final buttonWidth = AppSizes.upOverlayButtonWidth * scale;
    final buttonHeight = AppSizes.upOverlayButtonHeight * scale;
    final spacing = AppSizes.upOverlaySpacing * scale;
    final textSize = AppSizes.upOverlayTextSize * scale;

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
