import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';

class FlappyHud extends PositionComponent {
  FlappyHud({
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
    final pad = padding * scale;

    position = Vector2(pad, pad);
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
