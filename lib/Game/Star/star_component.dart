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
