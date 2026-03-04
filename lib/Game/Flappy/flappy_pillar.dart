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
    _hitbox = RectangleHitbox(collisionType: CollisionType.passive);
    add(_hitbox);
  }

  late final bool _isFlipped;
  late final RectangleHitbox _hitbox;

  @override
  void onMount() {
    super.onMount();
    final hitboxSize = Vector2(
      size.x * AppSizes.flappyPillarHitboxScale,
      size.y * AppSizes.flappyPillarHitboxScale,
    );
    _hitbox
      ..size = hitboxSize
      ..position = Vector2(
        (size.x - hitboxSize.x) / 2,
        (size.y - hitboxSize.y) / 2,
      );
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
  }) {
    size = Vector2(pillarSize.x, pillarSize.y * 2 + gap);
    _top = FlappyPillar(sprite: pillarSprite, flipped: true)
      ..size = pillarSize
      ..position = Vector2(0, topGapY);
    _bottom = FlappyPillar(sprite: pillarSprite, flipped: false)
      ..size = pillarSize
      ..position = Vector2(0, topGapY + gap);
    addAll([_top, _bottom]);
  }

  final Vector2 pillarSize;
  final double gap;
  final double topGapY;
  final Sprite pillarSprite;
  final double speed;

  late final FlappyPillar _top;
  late final FlappyPillar _bottom;
  bool _scored = false;

  @override
  void update(double dt) {
    super.update(dt);
    if (!gameRef.isRunning) {
      return;
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

  bool overlapsPlayerRect(Rect playerRect) {
    return _top.getWorldRect().overlaps(playerRect) ||
        _bottom.getWorldRect().overlaps(playerRect);
  }
}
