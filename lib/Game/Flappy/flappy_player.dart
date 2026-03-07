import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../../constants/app_sizes.dart';
import 'flappy_game.dart';
import 'flappy_pillar.dart';

class FlappyPlayer extends SpriteComponent
    with CollisionCallbacks, HasGameRef<FlappyGame> {
  FlappyPlayer({required Sprite sprite})
    : super(sprite: sprite, anchor: Anchor.center) {
    _hitbox = RectangleHitbox(collisionType: CollisionType.active)
      ..anchor = Anchor.center;
    if (AppSizes.flappyShowCollisionDebug) {
      debugMode = true;
      _hitbox.debugMode = true;
    }
    add(_hitbox);
  }

  late final RectangleHitbox _hitbox;

  double velocityY = 0.0;

  void reset({required Vector2 position, required double size}) {
    this.size = Vector2.all(size);
    this.position = position;
    final hitboxSize = Vector2(
      size * AppSizes.flappyPlayerHitboxScale,
      size * AppSizes.flappyPlayerHitboxScale,
    );
    _hitbox
      ..size = hitboxSize
      ..position = Vector2(this.size.x / 2, this.size.y / 2);
    velocityY = 0.0;
  }

  void jump(double impulse) {
    velocityY = -impulse;
  }

  void applyPhysics(double dt, double gravity) {
    velocityY += gravity * dt;
    position.y += velocityY * dt;
  }

  void clampToTop(double topLimit) {
    if (position.y - (size.y / 2) < topLimit) {
      position.y = topLimit + (size.y / 2);
      velocityY = 0.0;
    }
  }

  void clampToFloor(double floorLimit) {
    position.y = floorLimit - (size.y / 2);
    velocityY = 0.0;
  }

  Rect getWorldRect() {
    final anchorOffset = Vector2(anchor.x * size.x, anchor.y * size.y);
    final topLeft = absolutePosition - anchorOffset;
    final rect = Rect.fromLTWH(topLeft.x, topLeft.y, size.x, size.y);
    final insetX = rect.width * (1 - AppSizes.flappyPlayerHitboxScale) / 2;
    final insetY = rect.height * (1 - AppSizes.flappyPlayerHitboxScale) / 2;
    return Rect.fromLTWH(
      rect.left + insetX,
      rect.top + insetY,
      rect.width - (insetX * 2),
      rect.height - (insetY * 2),
    );
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (!gameRef.isRunning) {
      return;
    }
    final isPillar = other is FlappyPillar || other.parent is FlappyPillar;
    if (isPillar) {
      gameRef.handlePlayerHit();
    }
  }
}
