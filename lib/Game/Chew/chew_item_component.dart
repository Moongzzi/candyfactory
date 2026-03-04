import 'package:flame/components.dart';

import 'chew_types.dart';

/// Chew item component displayed in the center row.
class ChewItemComponent extends SpriteComponent {
  ChewItemComponent({required this.type, required Sprite sprite})
    : super(sprite: sprite, anchor: Anchor.center);

  final ChewType type;
}
