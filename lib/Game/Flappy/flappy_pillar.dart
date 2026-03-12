import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../../constants/app_sizes.dart';
import 'flappy_game.dart';

class FlappyPillar extends SpriteComponent
    with CollisionCallbacks, HasGameRef<FlappyGame> {
  FlappyPillar({required Sprite sprite, required bool flipped})
    : super(sprite: sprite, anchor: Anchor.topLeft) {
    _isFlipped = flipped;
    if (flipped) {
      scale = Vector2(1, -1);
    }
    _bodyHitbox = RectangleHitbox(collisionType: CollisionType.passive);
    _capHitbox = RectangleHitbox(collisionType: CollisionType.passive);
    if (AppSizes.flappyShowCollisionDebug) {
      debugMode = true;
      _bodyHitbox.debugMode = true;
      _capHitbox.debugMode = true;
    }
    addAll([_bodyHitbox, _capHitbox]);
  }

  late final bool _isFlipped;
  late final RectangleHitbox _bodyHitbox;
  late final RectangleHitbox _capHitbox;

  @override
  void onMount() {
    super.onMount();
    final bodyHitboxSize = Vector2(
      size.x * AppSizes.flappyPillarHitboxScale,
      size.y * AppSizes.flappyPillarHitboxScale,
    );
    _bodyHitbox
      ..size = bodyHitboxSize
      ..position = Vector2(
        (size.x - bodyHitboxSize.x) / 2,
        (size.y - bodyHitboxSize.y) / 2,
      );

    final capHitboxSize = Vector2(
      size.x * AppSizes.flappyPillarCapHitboxWidthScale,
      size.y * AppSizes.flappyPillarCapHitboxHeightScale,
    );
    _capHitbox
      ..size = capHitboxSize
      ..position = Vector2((size.x - capHitboxSize.x) / 2, 0);
  }

  Rect getWorldRect() {
    final anchorOffset = Vector2(anchor.x * size.x, anchor.y * size.y);
    final base = absolutePosition - anchorOffset;
    final top = _isFlipped ? base.y - size.y : base.y;
    return Rect.fromLTWH(base.x, top, size.x, size.y);
  }
}

class FlappyPillarPair extends PositionComponent with HasGameRef<FlappyGame> {
  FlappyPillarPair({
    required this.pillarSize,
    required this.gap,
    required this.topGapY,
    required this.pillarSprite,
    required this.speed,
    required this.oscillationAmplitude,
    required this.oscillationFrequency,
    required this.oscillationPhase,
  }) {
    size = Vector2(pillarSize.x, pillarSize.y * 2 + gap);
    _currentTopGapY = topGapY;
    _top = FlappyPillar(sprite: pillarSprite, flipped: true)
      ..size = pillarSize
      ..position = Vector2(0, _currentTopGapY);
    _bottom = FlappyPillar(sprite: pillarSprite, flipped: false)
      ..size = pillarSize
      ..position = Vector2(0, _currentTopGapY + gap);
    addAll([_top, _bottom]);
  }

  final Vector2 pillarSize;
  final double gap;
  final double topGapY;
  final Sprite pillarSprite;
  final double oscillationAmplitude;
  final double oscillationFrequency;
  final double oscillationPhase;

  double speed;

  late final FlappyPillar _top;
  late final FlappyPillar _bottom;
  bool _scored = false;
  double _elapsed = 0.0;
  double _currentTopGapY = 0.0;

  void setSpeed(double value) {
    speed = value;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!gameRef.isRunning) {
      return;
    }
    _elapsed += dt;
    if (oscillationAmplitude > 0 && oscillationFrequency > 0) {
      final wave = math.sin(
        ((_elapsed * oscillationFrequency) + oscillationPhase) * math.pi * 2,
      );
      _currentTopGapY = topGapY + (wave * oscillationAmplitude);
      _top.position.y = _currentTopGapY;
      _bottom.position.y = _currentTopGapY + gap;
    }
    position.x -= speed * dt;
    if (position.x + pillarSize.x < 0) {
      removeFromParent();
    }
  }

  bool checkScore(double playerX) {
    if (_scored) {
      return false;
    }
    if (position.x + pillarSize.x < playerX) {
      _scored = true;
      return true;
    }
    return false;
  }

  bool overlapsPlayerRect(Rect playerRect) =>
      _top.getWorldRect().overlaps(playerRect) ||
      _bottom.getWorldRect().overlaps(playerRect);
}
