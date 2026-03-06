import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import '../../constants/app_assets.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import 'chew_button_component.dart';
import 'chew_hud.dart';
import 'chew_item_component.dart';
import 'chew_types.dart';

/// Chew game implementation.
class ChewGame extends FlameGame {
  ChewGame({this.onGameStarted, this.onGameFinished});

  final VoidCallback? onGameStarted;
  final ValueChanged<int>? onGameFinished;

  final _random = math.Random();
  final List<ChewItemComponent> _items = <ChewItemComponent>[];
  final Map<ChewType, ChewDirection> _directionMap =
      <ChewType, ChewDirection>{};
  final Map<ChewType, ChewButtonComponent> _buttons =
      <ChewType, ChewButtonComponent>{};

  SpriteComponent? _background;
  late final ChewHud _hud;

  double _timeLeft = AppSizes.chewGameStartTimeSec;
  int _score = 0;
  bool _isStarted = false;
  bool _isGameOver = false;

  int get score => _score;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    await images.loadAll([
      AppAssets.gameBackground3Flame,
      AppAssets.gameTimerBackgroundChewFlame,
      AppAssets.chewAppleFlame,
      AppAssets.chewBerryFlame,
      AppAssets.chewGrapeFlame,
      AppAssets.chewPeachFlame,
      AppAssets.chewButtonAppleFlame,
      AppAssets.chewButtonBerryFlame,
      AppAssets.chewButtonGrapeFlame,
      AppAssets.chewButtonPeachFlame,
    ]);

    final backgroundSprite = await loadSprite(AppAssets.gameBackground3Flame);
    final timerSprite = await loadSprite(
      AppAssets.gameTimerBackgroundChewFlame,
    );
    _background = SpriteComponent(
      sprite: backgroundSprite,
      size: size,
      anchor: Anchor.topLeft,
      priority: -1000,
      paint: Paint()..color = AppColors.chewGameBackgroundTint,
    );
    add(_background!);

    _hud = ChewHud(
      textSize: AppSizes.chewGameHudTextSize,
      padding: AppSizes.chewGameHudPadding,
      timerSprite: timerSprite,
      maxTime: AppSizes.chewGameStartTimeSec,
    );
    add(_hud);

    _assignDirections();
    _createButtons();
    _createInitialItems();
    _layoutAll();
    overlays.add('chewStart');
    _hud.updateValues(0, 0);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (_background != null) {
      _background!
        ..size = size
        ..position = Vector2.zero();
    }
    _layoutAll();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_isStarted || _isGameOver) {
      return;
    }
    _timeLeft = (_timeLeft - dt).clamp(0.0, double.infinity);
    if (_timeLeft <= 0) {
      _endGame();
    }
    _hud.updateValues(_timeLeft, _score);
  }

  void _assignDirections() {
    _directionMap.clear();
    final shuffled = List<ChewAsset>.from(chewAssets)..shuffle(_random);
    for (var i = 0; i < shuffled.length; i++) {
      _directionMap[shuffled[i].type] = i < 2
          ? ChewDirection.left
          : ChewDirection.right;
    }
  }

  void _createButtons() {
    _buttons.clear();
    for (final asset in chewAssets) {
      final sprite = Sprite(images.fromCache(asset.buttonFlamePath));
      final button = ChewButtonComponent(
        type: asset.type,
        sprite: sprite,
        onPressed: () => _handleButtonTap(asset.type),
      );
      _buttons[asset.type] = button;
      add(button);
    }
  }

  void _createInitialItems() {
    _items.clear();
    for (var i = 0; i < AppSizes.chewGameRowCount; i++) {
      _items.add(_createRandomItem());
    }
  }

  ChewItemComponent _createRandomItem() {
    final asset = chewAssets[_random.nextInt(chewAssets.length)];
    final sprite = Sprite(images.fromCache(asset.itemFlamePath));
    final item = ChewItemComponent(type: asset.type, sprite: sprite);
    add(item);
    return item;
  }

  void _layoutAll() {
    if (size.x == 0 || size.y == 0) {
      return;
    }
    _layoutItems();
    _layoutButtons();
  }

  void _layoutItems() {
    final scale = math.min(
      size.x / AppSizes.designWidth,
      size.y / AppSizes.designHeight,
    );
    final topPad = AppSizes.chewGameTopPadding * scale;
    final bottomPad = AppSizes.chewGameBottomPadding * scale;
    final minSize = AppSizes.chewGameItemMinSize * scale;
    final maxSize = AppSizes.chewGameItemMaxSize * scale;

    final areaHeight = size.y - topPad - bottomPad;
    final yMin = topPad + (areaHeight * AppSizes.chewGameRowTopFactor);
    final yMax = topPad + (areaHeight * AppSizes.chewGameRowBottomFactor);
    final count = _items.length;
    final centerX = size.x / 2;

    for (var i = 0; i < count; i++) {
      final t = count == 1 ? 1.0 : i / (count - 1);
      final itemSize = minSize + (maxSize - minSize) * t;

      final x = centerX;
      final eased = math.pow(t, 1.8).toDouble();
      final y = yMin + (yMax - yMin) * eased;

      final item = _items[i];
      item
        ..size = Vector2.all(itemSize)
        ..scale = Vector2.all(1)
        ..position = Vector2(x, y)
        ..priority = i;
    }
  }

  void _layoutButtons() {
    final scale = math.min(
      size.x / AppSizes.designWidth,
      size.y / AppSizes.designHeight,
    );
    final bottomPad = AppSizes.chewGameBottomPadding * scale;
    final sidePad = AppSizes.chewGameSidePadding * scale;
    final spacing = AppSizes.chewGameButtonSpacing * scale;

    final bottomTop = size.y - bottomPad;
    final columnWidth = (size.x - (sidePad * 2) - spacing) / 2;
    final columnHeight = bottomPad - spacing;
    final buttonHeight = columnHeight / 2;

    final leftTypes = _directionMap.entries
        .where((entry) => entry.value == ChewDirection.left)
        .map((entry) => entry.key)
        .toList();
    final rightTypes = _directionMap.entries
        .where((entry) => entry.value == ChewDirection.right)
        .map((entry) => entry.key)
        .toList();

    for (var i = 0; i < leftTypes.length; i++) {
      final type = leftTypes[i];
      final button = _buttons[type];
      if (button == null) {
        continue;
      }
      button
        ..size = Vector2(columnWidth, buttonHeight)
        ..position = Vector2(
          sidePad,
          bottomTop + (i * (buttonHeight + spacing)),
        )
        ..priority = 1000;
    }

    for (var i = 0; i < rightTypes.length; i++) {
      final type = rightTypes[i];
      final button = _buttons[type];
      if (button == null) {
        continue;
      }
      button
        ..size = Vector2(columnWidth, buttonHeight)
        ..position = Vector2(
          sidePad + columnWidth + spacing,
          bottomTop + (i * (buttonHeight + spacing)),
        )
        ..priority = 1000;
    }
  }

  void _handleButtonTap(ChewType type) {
    if (!_isStarted || _isGameOver) {
      return;
    }
    if (_items.isEmpty) {
      return;
    }

    final current = _items.last;
    final isCorrect = current.type == type;
    if (!isCorrect) {
      _endGame();
      return;
    }

    _score += 1;
    _timeLeft += AppSizes.chewGameAddTimeSec;

    current.removeFromParent();
    _items.removeLast();

    _items.insert(0, _createRandomItem());
    _layoutItems();
  }

  void _endGame() {
    _isGameOver = true;
    _isStarted = false;
    overlays.add('chewGameOver');
    onGameFinished?.call(_score);
  }

  void startGame() {
    overlays.remove('chewStart');
    overlays.remove('chewGameOver');
    _resetGame();
    _isStarted = true;
    onGameStarted?.call();
  }

  void restartGame() {
    overlays.remove('chewGameOver');
    _resetGame();
    _isStarted = true;
    onGameStarted?.call();
  }

  void _resetGame() {
    for (final item in _items) {
      item.removeFromParent();
    }
    _items.clear();
    _assignDirections();
    _createInitialItems();
    _timeLeft = AppSizes.chewGameStartTimeSec;
    _score = 0;
    _isGameOver = false;
    _layoutAll();
    _hud.updateValues(_timeLeft, _score);
  }
}
