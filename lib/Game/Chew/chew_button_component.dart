import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/foundation.dart';

import 'chew_types.dart';

/// Chew direction button component.
class ChewButtonComponent extends SpriteComponent with TapCallbacks {
  ChewButtonComponent({
    required this.type,
    required Sprite sprite,
    required this.onPressed,
  }) : super(sprite: sprite, anchor: Anchor.topLeft);

  final ChewType type;
  final VoidCallback onPressed;

  @override
  void onTapDown(TapDownEvent event) {
    onPressed();
    event.handled = true;
  }
}
