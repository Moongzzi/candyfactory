import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import '../../constants/app_assets.dart';
import '../../constants/app_sizes.dart';
import 'star_component.dart';
import 'star_hud.dart';

/// Star collecting game using Flame.
class StarGame extends FlameGame {
  StarGame({this.onGameStarted, this.onGameFinished}) : super();

  final VoidCallback? onGameStarted;
  final ValueChanged<int>? onGameFinished;

  final _random = math.Random();
  late final StarHud _hud;
  SpriteComponent? _background;

  int _nextExpected = 1;
  int _nextSpawnNumber = AppSizes.starGameInitialCount + 1;
  int _score = 0;
  double _elapsedTime = 0.0;
  int _difficultyLevel = 0;
  bool _isStarted = false;
  bool _isGameOver = false;
  Rect _playArea = Rect.zero;

  static const double _baseStarSpeed = 45.0;
  static const double _speedGainPerLevel = 22.0;
  static const double _maxStarSpeed = 190.0;

  int get score => _score;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await images.loadAll([
      AppAssets.gameBackground2Flame,
      AppAssets.gameTimerBackgroundStarFlame,
      AppAssets.gameStarFlame,
    ]);
    final sprite = await loadSprite(AppAssets.gameBackground2Flame);
    final scoreBgSprite = await loadSprite(
      AppAssets.gameTimerBackgroundStarFlame,
    );
    _background = SpriteComponent(sprite: sprite, size: size, priority: -1000)
      ..anchor = Anchor.topLeft;
    add(_background!);
    _hud = StarHud(
      textSize: AppSizes.starGameHudTextSize,
      padding: AppSizes.starGameHudPadding,
      timerSprite: scoreBgSprite,
    );
    add(_hud);
    overlays.add('start');
    _hud.updateValues(0);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (_background == null) {
      return;
    }
    _background!
      ..size = size
      ..position = Vector2.zero();
    _playArea = _buildPlayArea();
    _updateStarDifficulty();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_isStarted || _isGameOver) {
      return;
    }
    _elapsedTime += dt;
    final nextLevel = (_elapsedTime / AppSizes.starGameStartTimeSec).floor();
    if (nextLevel != _difficultyLevel) {
      _difficultyLevel = nextLevel;
      _updateStarDifficulty();
    }
    _hud.updateValues(_score);
  }

  Rect _buildPlayArea() {
    final scale = math.min(
      size.x / AppSizes.designWidth,
      size.y / AppSizes.designHeight,
    );
    final leftPad = AppSizes.starGameSpawnSidePadding * scale;
    final rightPad = AppSizes.starGameSpawnSidePadding * scale;
    final topPad = AppSizes.starGameSpawnTopPadding * scale;
    final bottomPad = AppSizes.starGameSpawnBottomPadding * scale;
    return Rect.fromLTRB(
      leftPad,
      topPad,
      size.x - rightPad,
      size.y - bottomPad,
    );
  }

  double _currentStarSpeed() {
    final speed = _baseStarSpeed + (_speedGainPerLevel * _difficultyLevel);
    return speed.clamp(_baseStarSpeed, _maxStarSpeed);
  }

  void _updateStarDifficulty() {
    final speed = _currentStarSpeed();
    for (final star in children.whereType<StarComponent>()) {
      star
        ..setMovement(velocity: _randomVelocity(speed), bounds: _playArea)
        ..setSpeed(speed);
    }
  }

  Vector2 _randomVelocity(double speed) {
    final angle = _random.nextDouble() * (math.pi * 2);
    return Vector2(math.cos(angle) * speed, math.sin(angle) * speed);
  }

  void _spawnInitialStars() {
    for (var i = 1; i <= AppSizes.starGameInitialCount; i++) {
      _spawnStar(i);
    }
  }

  void _spawnStar(int number) {
    final scale = math.min(
      size.x / AppSizes.designWidth,
      size.y / AppSizes.designHeight,
    );
    final diameter = AppSizes.starGameStarDiameter * scale;
    final textSize = AppSizes.starGameNumberTextSize * scale;
    final minX = _playArea.left + (diameter / 2);
    final maxX = _playArea.right - (diameter / 2);
    final minY = _playArea.top + (diameter / 2);
    final maxY = _playArea.bottom - (diameter / 2);

    final safeMinX = math.min(minX, maxX);
    final safeMaxX = math.max(minX, maxX);
    final safeMinY = math.min(minY, maxY);
    final safeMaxY = math.max(minY, maxY);

    final x = safeMinX + _random.nextDouble() * (safeMaxX - safeMinX);
    final y = safeMinY + _random.nextDouble() * (safeMaxY - safeMinY);

    final star =
        StarComponent(
            number: number,
            diameter: diameter,
            textSize: textSize,
            onTap: () => _handleStarTap(number),
          )
          ..position = Vector2(x, y)
          ..setMovement(
            velocity: _randomVelocity(_currentStarSpeed()),
            bounds: _playArea,
          )
          ..priority = -number;

    add(star);
  }

  void _handleStarTap(int number) {
    if (!_isStarted || _isGameOver) {
      return;
    }

    if (number != _nextExpected) {
      _endGame();
      return;
    }

    final star = children.whereType<StarComponent>().firstWhere(
      (element) => element.number == number,
    );
    star.removeFromParent();

    _score += 2;
    _nextExpected += 1;

    _spawnStar(_nextSpawnNumber);
    _nextSpawnNumber += 1;
  }

  void _endGame() {
    _isGameOver = true;
    _isStarted = false;
    overlays.add('gameOver');
    onGameFinished?.call(_score);
  }

  void startGame() {
    overlays.remove('start');
    overlays.remove('gameOver');
    _resetGame();
    _isStarted = true;
    onGameStarted?.call();
  }

  void restartGame() {
    overlays.remove('gameOver');
    _resetGame();
    _isStarted = true;
    onGameStarted?.call();
  }

  void _resetGame() {
    _clearStars();
    _nextExpected = 1;
    _nextSpawnNumber = AppSizes.starGameInitialCount + 1;
    _score = 0;
    _elapsedTime = 0.0;
    _difficultyLevel = 0;
    _isGameOver = false;
    _playArea = _buildPlayArea();
    _spawnInitialStars();
    _hud.updateValues(_score);
  }

  void _clearStars() {
    final stars = children.whereType<StarComponent>().toList();
    for (final star in stars) {
      star.removeFromParent();
    }
  }
}
