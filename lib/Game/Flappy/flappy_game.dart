import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import '../../constants/app_assets.dart';
import '../../constants/app_sizes.dart';
import 'flappy_hud.dart';
import 'flappy_pillar.dart';
import 'flappy_player.dart';

class FlappyGame extends FlameGame with HasCollisionDetection, TapCallbacks {
  FlappyGame({this.onGameStarted, this.onGameFinished});

  final VoidCallback? onGameStarted;
  final ValueChanged<int>? onGameFinished;

  final _random = math.Random();
  SpriteComponent? _background;
  late final FlappyHud _hud;
  FlappyPlayer? _player;
  final List<FlappyPillarPair> _pillars = <FlappyPillarPair>[];

  bool _isStarted = false;
  bool _isGameOver = false;
  bool _timerStarted = false;
  int _score = 0;
  double _timeLeft = AppSizes.flappyGameStartTimeSec;
  double _spawnTimer = 0.0;

  double _scale = 1.0;
  double _gravity = 0.0;
  double _jumpImpulse = 0.0;
  double _pillarSpeed = 0.0;
  double _pillarGap = 0.0;
  double _topPadding = 0.0;
  double _bottomPadding = 0.0;
  double _floorPadding = 0.0;
  double _playerSize = 0.0;
  double _spawnInterval = 0.0;
  double _playerStartX = 0.0;
  double _playerStartY = 0.0;
  double _pillarMinHeight = 0.0;

  int get score => _score;

  bool get isRunning => _isStarted && !_isGameOver;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (AppSizes.flappyShowCollisionDebug) {
      debugMode = true;
    }
    await images.loadAll([
      AppAssets.gameBackground4Flame,
      AppAssets.gameTimerBackgroundFlappyFlame,
      AppAssets.flappyPillarFlame,
      AppAssets.flappyCharacterFlame,
    ]);

    final backgroundSprite = await loadSprite(AppAssets.gameBackground4Flame);
    final timerSprite = await loadSprite(
      AppAssets.gameTimerBackgroundFlappyFlame,
    );
    _background = SpriteComponent(
      sprite: backgroundSprite,
      size: size,
      anchor: Anchor.topLeft,
      priority: -1000,
    );
    add(_background!);

    _hud = FlappyHud(
      textSize: AppSizes.flappyHudTextSize,
      padding: AppSizes.flappyHudPadding,
      timerSprite: timerSprite,
      maxTime: AppSizes.flappyGameStartTimeSec,
    );
    add(_hud);

    final playerSprite = Sprite(
      images.fromCache(AppAssets.flappyCharacterFlame),
    );
    _player = FlappyPlayer(sprite: playerSprite);
    add(_player!);

    overlays.add('flappyStart');
    _hud.updateValues(_timeLeft, _score);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _scale = math.min(
      size.x / AppSizes.designWidth,
      size.y / AppSizes.designHeight,
    );
    _gravity = AppSizes.flappyGravity * _scale;
    _jumpImpulse = AppSizes.flappyJumpImpulse * _scale;
    _pillarSpeed = AppSizes.flappyPillarSpeed * _scale;
    _pillarGap = AppSizes.flappyPillarGap * _scale;
    _topPadding = AppSizes.flappyTopPadding * _scale;
    _bottomPadding = AppSizes.flappyBottomPadding * _scale;
    _floorPadding = AppSizes.flappyFloorPadding * _scale;
    _playerSize = AppSizes.flappyPlayerSize * _scale;
    _spawnInterval = AppSizes.flappySpawnInterval;
    _playerStartX = size.x * AppSizes.flappyPlayerStartX;
    _playerStartY = size.y * AppSizes.flappyPlayerStartY;
    _pillarMinHeight = AppSizes.flappyPillarMinHeight * _scale;

    if (_background != null) {
      _background!
        ..size = size
        ..position = Vector2.zero();
    }

    if (_player == null) {
      return;
    }
    if (!isRunning) {
      _player!.reset(
        position: Vector2(_playerStartX, _playerStartY),
        size: _playerSize,
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isRunning) {
      return;
    }

    final player = _player;
    if (player == null) {
      return;
    }
    player.applyPhysics(dt, _gravity);
    player.clampToTop(0.0);

    final floorY = size.y - _floorPadding;
    if (player.position.y + (player.size.y / 2) >= floorY) {
      player.clampToFloor(floorY);
      _endGame();
      return;
    }

    _spawnTimer += dt;
    if (_spawnTimer >= _spawnInterval) {
      _spawnTimer -= _spawnInterval;
      _spawnPillarPair();
    }

    final playerX = player.position.x;
    for (final pillar in List<FlappyPillarPair>.from(_pillars)) {
      if (pillar.isRemoving) {
        _pillars.remove(pillar);
        continue;
      }
      if (pillar.checkScore(playerX)) {
        _score += 3;
      }
      if (!_timerStarted && pillar.position.x <= size.x) {
        _timerStarted = true;
      }
    }

    if (_timerStarted) {
      _timeLeft = (_timeLeft - dt).clamp(0.0, double.infinity);
      if (_timeLeft <= 0) {
        _endGame();
        return;
      }
    }

    _hud.updateValues(_timeLeft, _score);
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    if (!isRunning) {
      return;
    }
    _player?.jump(_jumpImpulse);
    event.handled = true;
  }

  void handlePlayerHit() {
    if (!isRunning) {
      return;
    }
    _endGame();
  }

  void startGame() {
    overlays.remove('flappyStart');
    overlays.remove('flappyGameOver');
    _resetGame();
    _isStarted = true;
    onGameStarted?.call();
  }

  void restartGame() {
    overlays.remove('flappyGameOver');
    _resetGame();
    _isStarted = true;
    onGameStarted?.call();
  }

  void _resetGame() {
    for (final pillar in _pillars) {
      pillar.removeFromParent();
    }
    _pillars.clear();
    _spawnTimer = AppSizes.flappySpawnInterval - AppSizes.flappyFirstSpawnDelay;
    _score = 0;
    _timeLeft = AppSizes.flappyGameStartTimeSec;
    _timerStarted = false;
    _isGameOver = false;

    _player?.reset(
      position: Vector2(_playerStartX, _playerStartY),
      size: _playerSize,
    );
    _hud.updateValues(_timeLeft, _score);
  }

  void _endGame() {
    _isGameOver = true;
    _isStarted = false;
    overlays.add('flappyGameOver');
    onGameFinished?.call(_score);
  }

  void _spawnPillarPair() {
    final availableHeight = size.y - _topPadding - _bottomPadding - _pillarGap;
    if (availableHeight <= 0) {
      return;
    }
    double topHeight;
    final maxTop = availableHeight - _pillarMinHeight;
    if (maxTop < _pillarMinHeight) {
      topHeight = math.max(availableHeight / 2, _pillarMinHeight);
    } else {
      topHeight =
          _pillarMinHeight + _random.nextDouble() * (maxTop - _pillarMinHeight);
    }
    final pillarSprite = Sprite(images.fromCache(AppAssets.flappyPillarFlame));
    final pillarSize = pillarSprite.srcSize.clone();
    final pair = FlappyPillarPair(
      pillarSize: pillarSize,
      gap: _pillarGap,
      topGapY: _topPadding + topHeight,
      pillarSprite: pillarSprite,
      speed: _pillarSpeed,
    )..position = Vector2(size.x + pillarSize.x, 0);

    _pillars.add(pair);
    add(pair);
  }
}
