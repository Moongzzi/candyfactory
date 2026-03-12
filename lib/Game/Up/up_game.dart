import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../constants/app_assets.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';

class UpGame extends FlameGame with TapCallbacks, DragCallbacks {
  UpGame({this.onGameStarted, this.onGameFinished});

  final VoidCallback? onGameStarted;
  final ValueChanged<int>? onGameFinished;

  final _random = math.Random();
  bool _componentsReady = false;

  late final _UpSkyBackground _background;
  late final _UpHud _hud;
  late final SpriteComponent _player;

  final List<_UpPlatform> _platforms = <_UpPlatform>[];

  late final List<Sprite> _normalPlatformSprites;

  bool _isStarted = false;
  bool _isGameOver = false;

  double _elapsedTime = 0.0;
  int _difficultyLevel = 0;
  double _cameraY = 0.0;

  double _playerX = 0.0;
  double _playerY = 0.0;
  double _previousPlayerY = 0.0;
  double _velocityY = 0.0;
  double _targetX = 0.0;

  double _startY = 0.0;
  int _score = 0;
  int _lastLandedLevel = 0;
  int _nextPlatformLevel = 0;

  double _nextSpawnY = 0.0;

  bool get isRunning => _isStarted && !_isGameOver;
  int get score => _score;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    await images.loadAll([
      AppAssets.gameTimerBackgroundUpFlame,
      AppAssets.upCharacterFlame,
      AppAssets.upStep1Flame,
      AppAssets.upStep2Flame,
      AppAssets.upStep3Flame,
      AppAssets.upStep4Flame,
    ]);

    _background = _UpSkyBackground();
    add(_background);
    final scoreBgSprite = await loadSprite(AppAssets.gameTimerBackgroundUpFlame);

    _hud = _UpHud(
      textSize: AppSizes.upHudTextSize,
      padding: AppSizes.upHudPadding,
      timerSprite: scoreBgSprite,
    );
    add(_hud);

    _normalPlatformSprites = <Sprite>[
      Sprite(images.fromCache(AppAssets.upStep1Flame)),
      Sprite(images.fromCache(AppAssets.upStep2Flame)),
      Sprite(images.fromCache(AppAssets.upStep3Flame)),
      Sprite(images.fromCache(AppAssets.upStep4Flame)),
    ];
    _player = SpriteComponent(
      sprite: Sprite(images.fromCache(AppAssets.upCharacterFlame)),
      anchor: Anchor.topLeft,
    );
    add(_player);

    _componentsReady = true;
    _syncAllPositions();

    overlays.add('upStart');
    _hud.updateValues(0);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (_isStarted || _isGameOver) {
      _syncAllPositions();
      return;
    }

    final scale = _scale;
    final playerSize = AppSizes.upPlayerSize * scale;
    _startY = size.y * AppSizes.upStartYFactor;
    _playerX = (size.x - playerSize) / 2;
    _playerY = _startY;
    _previousPlayerY = _playerY;
    _targetX = _playerX;
    _cameraY = _playerY - (size.y * AppSizes.upCameraFollowYFactor);
    if (!_componentsReady) {
      return;
    }
    _syncAllPositions();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isRunning) {
      return;
    }

    _updatePlayerHorizontal(dt);

    _previousPlayerY = _playerY;
    _velocityY += AppSizes.upGravity * _scale * dt;
    _playerY += _velocityY * dt;
    _updateMovingPlatforms(dt);

    if (_velocityY > 0) {
      _tryLandOnPlatform();
    }

    _updateCamera();
    _updateDifficulty(dt);

    if (_isGameOver) {
      return;
    }

    _updateBlinkingPlatforms(dt);
    _spawnPlatformsIfNeeded();
    _cleanupOffscreenPlatforms();
    _syncAllPositions();

    final failY = _cameraY + size.y + (AppSizes.upFallFailPadding * _scale);
    if (_playerY > failY) {
      _endGame();
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    if (!isRunning) {
      return;
    }
    _setTargetX(event.localPosition.x);
    event.handled = true;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (!isRunning) {
      return;
    }
    _setTargetX(event.localStartPosition.x + event.localDelta.x);
    event.handled = true;
  }

  void startGame() {
    overlays.remove('upStart');
    overlays.remove('upGameOver');
    _resetGame();
    _isStarted = true;
    onGameStarted?.call();
  }

  void restartGame() {
    overlays.remove('upGameOver');
    _resetGame();
    _isStarted = true;
    onGameStarted?.call();
  }

  void _resetGame() {
    for (final platform in _platforms) {
      platform.component.removeFromParent();
    }
    _platforms.clear();

    final scale = _scale;
    final playerSize = AppSizes.upPlayerSize * scale;
    final jumpVelocity = AppSizes.upJumpVelocity * scale;

    _elapsedTime = 0.0;
    _difficultyLevel = 0;
    _isGameOver = false;

    _startY = size.y * AppSizes.upStartYFactor;
    _playerX = (size.x - playerSize) / 2;
    _playerY = _startY;
    _previousPlayerY = _playerY;
    _velocityY = -jumpVelocity;
    _targetX = _playerX;
    _score = 0;
    _lastLandedLevel = 0;
    _nextPlatformLevel = 0;

    _cameraY = _playerY - (size.y * AppSizes.upCameraFollowYFactor);

    _spawnInitialPlatforms();
    _spawnPlatformsIfNeeded();
    _syncAllPositions();
    _hud.updateValues(_score);
  }

  void _spawnInitialPlatforms() {
    final scale = _scale;
    final platformWidth = AppSizes.upPlatformWidth * scale;
    final platformHeight = AppSizes.upPlatformHeight * scale;

    final firstY = _startY + (AppSizes.upInitialPlatformYOffset * scale);
    _addPlatform(
      x: (size.x - platformWidth) / 2,
      y: firstY,
      width: platformWidth,
      height: platformHeight,
      level: _nextPlatformLevel,
      moving: false,
      speedX: 0.0,
      blinking: false,
    );
    _nextPlatformLevel += 1;

    _nextSpawnY = firstY - (AppSizes.upPlatformMinGap * scale);
  }

  void _spawnPlatformsIfNeeded() {
    final scale = _scale;
    final topLimit = _cameraY - (AppSizes.upSpawnAbovePadding * scale);
    final platformWidth = AppSizes.upPlatformWidth * scale;
    final platformHeight = AppSizes.upPlatformHeight * scale;
    final minGap = AppSizes.upPlatformMinGap * scale;
    final maxGap = AppSizes.upPlatformMaxGap * scale;

    while (_nextSpawnY > topLimit) {
      final x = _randomX(platformWidth);
      final moving = _random.nextDouble() < _movingStepChance();
      final movingSpeed = moving ? _randomMovingSpeed() : 0.0;
      final blinking = _random.nextDouble() < _blinkingStepChance();

      _addPlatform(
        x: x,
        y: _nextSpawnY,
        width: platformWidth,
        height: platformHeight,
        level: _nextPlatformLevel,
        moving: moving,
        speedX: movingSpeed,
        blinking: blinking,
      );
      _nextPlatformLevel += 1;

      final gap = minGap + _random.nextDouble() * (maxGap - minGap);
      _nextSpawnY -= gap;
    }
  }

  void _addPlatform({
    required double x,
    required double y,
    required double width,
    required double height,
    required int level,
    required bool moving,
    required double speedX,
    required bool blinking,
  }) {
    final sprite = _normalPlatformSprites[_random.nextInt(
      _normalPlatformSprites.length,
    )];
    final component = SpriteComponent(
      sprite: sprite,
      anchor: Anchor.topLeft,
      size: Vector2(width, height),
      position: Vector2(x, y - _cameraY),
    );
    add(component);
    final platform = _UpPlatform(
      component: component,
      x: x,
      y: y,
      width: width,
      height: height,
      level: level,
      moving: moving,
      speedX: speedX,
      blinking: blinking,
    );
    if (blinking) {
      platform
        ..visibleDuration = 0.9 + (_random.nextDouble() * 0.4)
        ..hiddenDuration = 0.45 + (_random.nextDouble() * 0.35);
    }
    _platforms.add(platform);
  }

  void _updateMovingPlatforms(double dt) {
    final sidePadding = AppSizes.upPlatformSidePadding * _scale;
    for (final platform in _platforms) {
      if (!platform.moving || platform.broken) {
        continue;
      }

      platform.x += platform.speedX * dt;
      final minX = sidePadding;
      final maxX = size.x - sidePadding - platform.width;
      if (maxX <= minX) {
        continue;
      }

      if (platform.x < minX) {
        platform.x = minX;
        platform.speedX = platform.speedX.abs();
      } else if (platform.x > maxX) {
        platform.x = maxX;
        platform.speedX = -platform.speedX.abs();
      }
    }
  }

  void _cleanupOffscreenPlatforms() {
    final removeY =
        _cameraY + size.y + (AppSizes.upCleanupBelowPadding * _scale);
    _platforms.removeWhere((platform) {
      if (platform.y <= removeY) {
        return false;
      }
      platform.component.removeFromParent();
      return true;
    });
  }

  void _updatePlayerHorizontal(double dt) {
    final scale = _scale;
    final playerSize = AppSizes.upPlayerSize * scale;
    final moveSpeed = AppSizes.upHorizontalSpeed * scale;
    final maxDelta = moveSpeed * dt;

    final dx = _targetX - _playerX;
    if (dx.abs() <= maxDelta) {
      _playerX = _targetX;
    } else {
      _playerX += maxDelta * dx.sign;
    }

    final minX = 0.0;
    final maxX = size.x - playerSize;
    _playerX = _playerX.clamp(minX, maxX);
  }

  void _setTargetX(double inputX) {
    final scale = _scale;
    final playerSize = AppSizes.upPlayerSize * scale;
    final target = inputX - (playerSize / 2);
    _targetX = target.clamp(0.0, size.x - playerSize);
  }

  void _tryLandOnPlatform() {
    final scale = _scale;
    final playerSize = AppSizes.upPlayerSize * scale;
    final playerLeft = _playerX + (playerSize * AppSizes.upPlayerHitboxInset);
    final playerRight =
        _playerX + playerSize - (playerSize * AppSizes.upPlayerHitboxInset);

    final previousBottom = _previousPlayerY + playerSize;
    final currentBottom = _playerY + playerSize;

    for (final platform in _platforms) {
      if (platform.broken) {
        continue;
      }
      if (!platform.isVisibleNow) {
        continue;
      }

      final platformInsetX = platform.width * AppSizes.upPlatformHitboxInsetX;
      final platformInsetTop =
          platform.height * AppSizes.upPlatformHitboxInsetTop;
      final platformTop = platform.y + platformInsetTop;
      final crossedFromAbove =
          previousBottom <= platformTop && currentBottom >= platformTop;
      if (!crossedFromAbove) {
        continue;
      }

      final platformLeft = platform.x + platformInsetX;
      final platformRight = platform.x + platform.width - platformInsetX;
      final overlap = playerRight > platformLeft && playerLeft < platformRight;
      if (!overlap) {
        continue;
      }

      _playerY = platformTop - playerSize;
      _velocityY = -(AppSizes.upJumpVelocity * scale);
      final gained = platform.level - _lastLandedLevel;
      if (gained > 0) {
        _score += (gained * 2);
        _lastLandedLevel = platform.level;
        _hud.updateValues(_score);
      }

      platform.broken = true;
      platform.component.removeFromParent();
      return;
    }
  }

  void _updateCamera() {
    final followY = size.y * AppSizes.upCameraFollowYFactor;
    final desiredCameraY = _playerY - followY;
    if (desiredCameraY < _cameraY) {
      _cameraY = desiredCameraY;
    }
  }

  void _updateDifficulty(double dt) {
    _elapsedTime += dt;
    final nextLevel = (_elapsedTime / AppSizes.upGameStartTimeSec).floor();
    if (nextLevel != _difficultyLevel) {
      _difficultyLevel = nextLevel;
    }
    _hud.updateValues(_score);
  }

  void _updateBlinkingPlatforms(double dt) {
    for (final platform in _platforms) {
      if (!platform.blinking || platform.broken) {
        continue;
      }
      platform.blinkElapsed += dt;
      final cycle = platform.visibleDuration + platform.hiddenDuration;
      if (cycle <= 0) {
        platform.isVisibleNow = true;
        continue;
      }
      final phase = platform.blinkElapsed % cycle;
      platform.isVisibleNow = phase < platform.visibleDuration;
    }
  }

  void _syncAllPositions() {
    final scale = _scale;
    final playerSize = AppSizes.upPlayerSize * scale;

    _player
      ..size = Vector2.all(playerSize)
      ..position = Vector2(_playerX, _playerY - _cameraY);

    for (final platform in _platforms) {
      platform.component.position = Vector2(platform.x, platform.y - _cameraY);
      platform.component.opacity = platform.isVisibleNow && !platform.broken
          ? 1.0
          : 0.28;
    }
  }

  void _endGame() {
    _isGameOver = true;
    _isStarted = false;
    overlays.add('upGameOver');
    onGameFinished?.call(_score);
  }

  double _randomX(double platformWidth) {
    final sidePadding = AppSizes.upPlatformSidePadding * _scale;
    final minX = sidePadding;
    final maxX = size.x - sidePadding - platformWidth;
    if (maxX <= minX) {
      return minX;
    }
    return minX + _random.nextDouble() * (maxX - minX);
  }

  double _movingStepChance() {
    final minScore = AppSizes.upMovingStepMinScore;
    final maxScore = AppSizes.upMovingStepMaxScore;
    if (_score <= minScore) {
      return AppSizes.upMovingStepMinChance;
    }
    if (_score >= maxScore) {
      return AppSizes.upMovingStepMaxChance;
    }
    final t = (_score - minScore) / (maxScore - minScore);
    return AppSizes.upMovingStepMinChance +
        (AppSizes.upMovingStepMaxChance - AppSizes.upMovingStepMinChance) * t;
  }

  double _randomMovingSpeed() {
    final minSpeed = AppSizes.upMovingStepSpeedMin * _scale;
    final maxSpeed = AppSizes.upMovingStepSpeedMax * _scale;
    final speed = minSpeed + _random.nextDouble() * (maxSpeed - minSpeed);
    return _random.nextBool() ? speed : -speed;
  }

  double _blinkingStepChance() {
    if (_difficultyLevel <= 0) {
      return 0.0;
    }
    final chance = 0.08 + (_difficultyLevel * 0.05);
    return chance.clamp(0.08, 0.45).toDouble();
  }

  double get _scale =>
      math.min(size.x / AppSizes.designWidth, size.y / AppSizes.designHeight);

  double get cameraY => _cameraY;
}

class _UpPlatform {
  _UpPlatform({
    required this.component,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.level,
    required this.moving,
    required this.speedX,
    required this.blinking,
  });

  final SpriteComponent component;
  double x;
  final double y;
  final double width;
  final double height;
  final int level;
  final bool moving;
  double speedX;
  final bool blinking;

  bool broken = false;
  bool isVisibleNow = true;
  double blinkElapsed = 0.0;
  double visibleDuration = 1.0;
  double hiddenDuration = 0.8;
}

class _UpSkyBackground extends PositionComponent with HasGameRef<UpGame> {
  _UpSkyBackground() : super(priority: -1000, anchor: Anchor.topLeft);

  final Paint _paint = Paint();

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
    position = Vector2.zero();
  }

  @override
  void render(Canvas canvas) {
    final climbed = (-gameRef.cameraY).clamp(0.0, double.infinity);
    final phase = (climbed / AppSizes.upSkyTransitionHeight).clamp(0.0, 1.0);

    final topColor = Color.lerp(
      AppColors.upSkyTop,
      AppColors.upSpaceTop,
      phase,
    )!;
    final midColor = Color.lerp(
      AppColors.upSkyMid,
      AppColors.upSpaceMid,
      phase,
    )!;
    final bottomColor = Color.lerp(
      AppColors.upSkyBottom,
      AppColors.upSpaceBottom,
      phase,
    )!;

    _paint.shader = LinearGradient(
      colors: <Color>[topColor, midColor, bottomColor],
      stops: const <double>[0.0, 0.55, 1.0],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), _paint);
  }
}

class _UpHud extends PositionComponent {
  _UpHud({
    required this.textSize,
    required this.padding,
    required this.timerSprite,
  }) : super(anchor: Anchor.topLeft) {
    _scoreBackground = SpriteComponent(
      sprite: timerSprite,
      anchor: Anchor.topLeft,
    );
    _scoreLabel = TextComponent(
      text: '0',
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: TextStyle(color: AppColors.text, fontSize: textSize),
      ),
    );
    addAll([_scoreBackground, _scoreLabel]);
  }

  final double textSize;
  final double padding;
  final Sprite timerSprite;

  late final SpriteComponent _scoreBackground;
  late final TextComponent _scoreLabel;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final scale = math.min(
      size.x / AppSizes.designWidth,
      size.y / AppSizes.designHeight,
    );
    final bgWidth = timerSprite.srcSize.x * scale;
    final bgHeight = timerSprite.srcSize.y * scale;

    position = Vector2(padding * scale, padding * scale);
    _scoreBackground
      ..size = Vector2(bgWidth, bgHeight)
      ..position = Vector2.zero();
    _scoreLabel
      ..position = Vector2(
        bgWidth / 2,
        bgHeight / 2,
      )
      ..textRenderer = TextPaint(
        style: TextStyle(color: AppColors.text, fontSize: textSize * scale),
      );
  }

  void updateValues(int score) {
    _scoreLabel.text = '$score';
  }
}
