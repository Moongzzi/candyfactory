import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/game.dart';

import '../../constants/app_assets.dart';
import '../../constants/app_sizes.dart';
import 'star_component.dart';
import 'star_hud.dart';

/// Star collecting game using Flame.
class StarGame extends FlameGame {
  StarGame() : super();

  final _random = math.Random();
  late final StarHud _hud;
  SpriteComponent? _background;

  int _nextExpected = 1;
  int _nextSpawnNumber = AppSizes.starGameInitialCount + 1;
  int _score = 0;
  double _timeLeft = AppSizes.starGameStartTimeSec;
  bool _isStarted = false;
  bool _isGameOver = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await images.loadAll([
      AppAssets.gameBackground2Flame,
      AppAssets.gameTimerBackgroundStarFlame,
      AppAssets.gameStarFlame,
    ]);
    final sprite = await loadSprite(AppAssets.gameBackground2Flame);
    final timerSprite = await loadSprite(
      AppAssets.gameTimerBackgroundStarFlame,
    );
    _background = SpriteComponent(sprite: sprite, size: size, priority: -1000)
      ..anchor = Anchor.topLeft;
    add(_background!);
    _hud = StarHud(
      textSize: AppSizes.starGameHudTextSize,
      padding: AppSizes.starGameHudPadding,
      spacing: AppSizes.starGameHudSpacing,
      timerSprite: timerSprite,
      maxTime: AppSizes.starGameStartTimeSec,
    );
    add(_hud);
    overlays.add('start');
    _hud.updateValues(0, 0);
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
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_isStarted || _isGameOver) {
      return;
    }
    _timeLeft = (_timeLeft - dt).clamp(0.0, double.infinity);
    if (_timeLeft <= 0) {
      _endGame();
    }
    _hud.updateValues(_timeLeft, _score);
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
    final leftPad = AppSizes.starGameSpawnSidePadding * scale;
    final rightPad = AppSizes.starGameSpawnSidePadding * scale;
    final topPad = AppSizes.starGameSpawnTopPadding * scale;
    final bottomPad = AppSizes.starGameSpawnBottomPadding * scale;

    final minX = leftPad + (diameter / 2);
    final maxX = size.x - rightPad - (diameter / 2);
    final minY = topPad + (diameter / 2);
    final maxY = size.y - bottomPad - (diameter / 2);

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

    _score += 1;
    _timeLeft += AppSizes.starGameAddTimeSec;
    _nextExpected += 1;

    _spawnStar(_nextSpawnNumber);
    _nextSpawnNumber += 1;
  }

  void _endGame() {
    _isGameOver = true;
    _isStarted = false;
    overlays.add('gameOver');
  }

  void startGame() {
    overlays.remove('start');
    overlays.remove('gameOver');
    _resetGame();
    _isStarted = true;
  }

  void restartGame() {
    overlays.remove('gameOver');
    _resetGame();
    _isStarted = true;
  }

  void _resetGame() {
    _clearStars();
    _nextExpected = 1;
    _nextSpawnNumber = AppSizes.starGameInitialCount + 1;
    _score = 0;
    _timeLeft = AppSizes.starGameStartTimeSec;
    _isGameOver = false;
    _spawnInitialStars();
    _hud.updateValues(_timeLeft, _score);
  }

  void _clearStars() {
    final stars = children.whereType<StarComponent>().toList();
    for (final star in stars) {
      star.removeFromParent();
    }
  }
}
