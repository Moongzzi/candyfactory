import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';

/// HUD for Chew game time and score.
class ChewHud extends PositionComponent {
  ChewHud({
    required this.textSize,
    required this.padding,
    required this.timerSprite,
    required this.maxTime,
  }) : super(anchor: Anchor.topLeft) {
    _timerBackground = SpriteComponent(
      sprite: timerSprite,
      anchor: Anchor.topLeft,
    );
    _timerFill = _TimerFillComponent();
    _scoreLabel = TextComponent(
      text: '0',
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: TextStyle(color: AppColors.text, fontSize: textSize),
      ),
    );
    addAll([_timerBackground, _timerFill, _scoreLabel]);
  }

  final double textSize;
  final double padding;
  final Sprite timerSprite;
  final double maxTime;

  late final SpriteComponent _timerBackground;
  late final _TimerFillComponent _timerFill;
  late final TextComponent _scoreLabel;
  double _fillRatio = 1.0;
  double _trackWidth = 0;
  double _trackHeight = 0;
  double _insetLeft = 0;
  double _insetVertical = 0;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final scale = math.min(
      size.x / AppSizes.designWidth,
      size.y / AppSizes.designHeight,
    );
    final timerWidth = AppSizes.starGameTimerWidth * scale;
    final timerHeight = AppSizes.starGameTimerHeight * scale;
    final scoreLeft = AppSizes.starGameScoreInsetLeft * scale;
    final scoreTop = AppSizes.starGameScoreInsetTop * scale;
    final scoreBoxWidth = AppSizes.starGameScoreBoxWidth * scale;
    final scoreBoxHeight = AppSizes.starGameScoreBoxHeight * scale;
    final insetLeft = AppSizes.starGameTimerInsetLeft * scale;
    final insetRight = AppSizes.starGameTimerInsetRight * scale;
    final insetVertical = AppSizes.starGameTimerInsetVertical * scale;
    _trackWidth = timerWidth - insetLeft - insetRight;
    _trackHeight = timerHeight - (insetVertical * 2);
    _insetLeft = insetLeft;
    _insetVertical = insetVertical;
    final pad = padding * scale;

    position = Vector2(pad, pad);
    _timerBackground
      ..size = Vector2(timerWidth, timerHeight)
      ..position = Vector2.zero();
    final fillWidth = _trackWidth * _fillRatio;
    _timerFill.updateFill(
      position: Vector2(_insetLeft, _insetVertical),
      size: Vector2(fillWidth, _trackHeight),
      gradientRect: Rect.fromLTWH(0, 0, _trackWidth, _trackHeight),
    );
    _scoreLabel
      ..position = Vector2(
        scoreLeft + (scoreBoxWidth / 2),
        scoreTop + (scoreBoxHeight / 2),
      )
      ..textRenderer = TextPaint(
        style: TextStyle(color: AppColors.text, fontSize: textSize * scale),
      );
  }

  void updateValues(double timeLeft, int score) {
    _fillRatio = (timeLeft / maxTime).clamp(0.0, 1.0);
    final width = _trackWidth * _fillRatio;
    _timerFill.updateFill(
      position: Vector2(_insetLeft, _insetVertical),
      size: Vector2(width, _trackHeight),
      gradientRect: Rect.fromLTWH(0, 0, _trackWidth, _trackHeight),
    );
    _scoreLabel.text = '$score';
  }
}

class _TimerFillComponent extends PositionComponent {
  _TimerFillComponent() : super(anchor: Anchor.topLeft);

  final Paint _paint = Paint();
  Rect _gradientRect = Rect.zero;

  void updateFill({
    required Vector2 position,
    required Vector2 size,
    required Rect gradientRect,
  }) {
    this.position = position;
    this.size = size;
    _gradientRect = gradientRect;
  }

  @override
  void render(Canvas canvas) {
    if (size.x <= 0 || size.y <= 0) {
      return;
    }
    _paint.shader = LinearGradient(
      colors: AppColors.webGradientColors,
      stops: AppColors.webGradientStops,
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ).createShader(_gradientRect);
    canvas.drawRect(Offset.zero & Size(size.x, size.y), _paint);
  }
}
