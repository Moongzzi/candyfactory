import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../../constants/app_assets.dart';
import '../../constants/app_colors.dart';

/// Star component with a number label.
class StarComponent extends PositionComponent with TapCallbacks {
  StarComponent({
    required this.number,
    required this.diameter,
    required this.textSize,
    required this.onTap,
  }) {
    size = Vector2.all(diameter);
    anchor = Anchor.center;
    _sprite = SpriteComponent(
      sprite: Sprite(Flame.images.fromCache(AppAssets.gameStarFlame)),
      size: Vector2.all(diameter),
      anchor: Anchor.topLeft,
    );
    add(_sprite);
    _label = TextComponent(
      text: number.toString(),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: TextStyle(
          color: AppColors.text,
          fontSize: textSize * 1.4,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    add(_label);
  }

  final int number;
  final double diameter;
  final double textSize;
  final VoidCallback onTap;

  late final SpriteComponent _sprite;
  late final TextComponent _label;
  Vector2 _velocity = Vector2.zero();
  Rect _movementBounds = Rect.zero;

  void setMovement({required Vector2 velocity, required Rect bounds}) {
    _velocity = velocity;
    _movementBounds = bounds;
  }

  void setSpeed(double speed) {
    if (_velocity.length2 == 0) {
      return;
    }
    _velocity = _velocity.normalized()..scale(speed);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_movementBounds.width <= 0 || _movementBounds.height <= 0) {
      return;
    }
    position += _velocity * dt;

    final radius = size.x / 2;
    final minX = _movementBounds.left + radius;
    final maxX = _movementBounds.right - radius;
    final minY = _movementBounds.top + radius;
    final maxY = _movementBounds.bottom - radius;

    if (position.x < minX) {
      position.x = minX;
      _velocity.x = _velocity.x.abs();
    } else if (position.x > maxX) {
      position.x = maxX;
      _velocity.x = -_velocity.x.abs();
    }

    if (position.y < minY) {
      position.y = minY;
      _velocity.y = _velocity.y.abs();
    } else if (position.y > maxY) {
      position.y = maxY;
      _velocity.y = -_velocity.y.abs();
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    onTap();
    event.handled = true;
  }

  @override
  void onMount() {
    super.onMount();
    _label.position = Vector2(size.x / 2, size.y / 2);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _label.position = Vector2(this.size.x / 2, this.size.y / 2);
  }
}
