import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';

import '../game_play_api_service.dart';
import '../../constants/app_assets.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../Home/widgets/logo_button.dart';

class RouletteScreen extends StatefulWidget {
  const RouletteScreen({super.key});

  @override
  State<RouletteScreen> createState() => _RouletteScreenState();
}

class _RouletteScreenState extends State<RouletteScreen>
    with SingleTickerProviderStateMixin {
  final GamePlayApiService _gamePlayApiService = GamePlayApiService();
  static const int _spinCost = 100;
  static const List<Color> _weightChartColors = <Color>[
    Color(0xFF2A9D8F),
    Color(0xFFE76F51),
    Color(0xFFF4A261),
    Color(0xFF264653),
    Color(0xFFE9C46A),
    Color(0xFF457B9D),
    Color(0xFF8AB17D),
    Color(0xFF6D597A),
  ];

  late final AnimationController _controller;
  late Animation<double> _rotation;
  double _currentRotation = 0.0;
  bool _isSpinning = false;
  bool _showResult = false;
  bool _isApplyingResultApi = false;
  String _resultLabel = '';

  final List<String> _segments = <String>[
    '+100',
    '+300',
    '-500',
    '꽝',
    '-1000',
    '꽝',
    '+500',
    '+100',
    '+1000',
    'x3',
  ];

  // Tune each slice probability by changing this list (same order as _segments).
  final List<int> _segmentWeights = <int>[
    887, // +100
    1269, // +300
    1143, // -500
    1777, // 꽝
    381, // -1000
    1523, // 꽝
    1269, // +500
    1143, // +100
    508, // +1000
    100, // x3 (1% = 100/10000)
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: (AppSizes.rouletteSpinDurationSec * 1000).round(),
      ),
    );
    _rotation = Tween<double>(begin: 0.0, end: 0.0).animate(_controller);
    _controller.addStatusListener(_handleAnimationStatus);
  }

  @override
  void dispose() {
    _controller
      ..removeStatusListener(_handleAnimationStatus)
      ..dispose();
    super.dispose();
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) {
      return;
    }

    setState(() {
      _isSpinning = false;
      _showResult = true;
    });

    unawaited(_applyResultPointApis());
  }

  Future<int> _resolveResultDelta(String value) async {
    if (value == '꽝') {
      return 0;
    }

    final trimmed = value.trim();
    if (trimmed.startsWith('x') || trimmed.startsWith('X')) {
      final factor = int.tryParse(trimmed.substring(1));
      if (factor == null || factor <= 1) {
        return 0;
      }
      final currentCandies = await _gamePlayApiService.getCurrentCandies();
      if (currentCandies == null) {
        throw Exception('x3 보상 계산을 위한 캔디 조회에 실패했습니다.');
      }
      if (currentCandies <= 0) {
        return 0;
      }
      return currentCandies * (factor - 1);
    }

    return int.tryParse(trimmed) ?? 0;
  }

  int _pickWeightedIndex(math.Random random) {
    if (_segmentWeights.length != _segments.length) {
      return random.nextInt(_segments.length);
    }

    var totalWeight = 0;
    for (final weight in _segmentWeights) {
      if (weight > 0) {
        totalWeight += weight;
      }
    }

    if (totalWeight <= 0) {
      return random.nextInt(_segments.length);
    }

    var point = random.nextInt(totalWeight);
    for (var i = 0; i < _segmentWeights.length; i++) {
      final weight = _segmentWeights[i];
      if (weight <= 0) {
        continue;
      }
      if (point < weight) {
        return i;
      }
      point -= weight;
    }

    return _segments.length - 1;
  }

  Future<void> _applyResultPointApis() async {
    if (_isApplyingResultApi) {
      return;
    }

    setState(() {
      _isApplyingResultApi = true;
    });

    final requestedDelta = await _resolveResultDelta(_resultLabel);
    var resultDelta = requestedDelta;

    // Keep total candies from going below zero to avoid backend 400 errors.
    if (resultDelta < 0) {
      final currentCandies = await _gamePlayApiService.getCurrentCandies();
      if (currentCandies == null) {
        throw Exception('결과 반영 전 캔디 조회에 실패했습니다.');
      }
      final minDelta = -currentCandies;
      if (resultDelta < minDelta) {
        resultDelta = minDelta;
      }
    }

    try {
      await _gamePlayApiService.applyCandiesDelta(
        delta: resultDelta,
        gameCode: 'game1',
        extraMeta: {
          'phase': 'spin_result',
          'result_label': _resultLabel,
          'requested_delta': requestedDelta,
          'applied_delta': resultDelta,
        },
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: const Text('포인트 반영 중 오류가 발생했습니다. 다시 시도해 주세요.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('확인'),
              ),
            ],
          );
        },
      );
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _isApplyingResultApi = false;
      });
    }
  }

  Future<void> _spin() async {
    if (_isSpinning || _isApplyingResultApi) {
      return;
    }

    final currentCandies = await _gamePlayApiService.getCurrentCandies();
    if (!mounted) {
      return;
    }

    if (currentCandies == null) {
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: const Text('캔디 포인트를 조회하지 못했습니다. 잠시 후 다시 시도해 주세요.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('확인'),
              ),
            ],
          );
        },
      );
      return;
    }

    if (currentCandies < _spinCost) {
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: const Text('캔디 포인트가 100개 미만이라 룰렛을 돌릴 수 없습니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('확인'),
              ),
            ],
          );
        },
      );
      return;
    }

    final shouldSpin = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: const Text('캔디 포인트 100점을 사용해 룰렛을 돌립니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('돌리기'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
          ],
        );
      },
    );

    if (shouldSpin != true || !mounted) {
      return;
    }

    setState(() {
      _isApplyingResultApi = true;
    });
    try {
      await _gamePlayApiService.applyCandiesDelta(
        delta: -_spinCost,
        gameCode: 'game1',
        extraMeta: {'phase': 'spin_cost'},
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: const Text('캔디 포인트 차감에 실패했습니다. 다시 시도해 주세요.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('확인'),
              ),
            ],
          );
        },
      );
      setState(() {
        _isApplyingResultApi = false;
      });
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _isApplyingResultApi = false;
    });

    final random = math.Random();
    final index = _pickWeightedIndex(random);
    _resultLabel = _segments[index];

    final slice = (2 * math.pi) / _segments.length;
    final targetAngle = -index * slice + AppSizes.rouletteWheelAngleOffset;
    final turns =
        AppSizes.rouletteSpinTurnsMin +
        random.nextInt(
          AppSizes.rouletteSpinTurnsMax - AppSizes.rouletteSpinTurnsMin + 1,
        );
    final normalized = _currentRotation % (2 * math.pi);
    var delta = (2 * math.pi * turns) + (targetAngle - normalized);
    if (delta < 0) {
      delta += 2 * math.pi;
    }
    final endRotation = _currentRotation + delta;

    _rotation = Tween<double>(
      begin: _currentRotation,
      end: endRotation,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    setState(() {
      _isSpinning = true;
      _showResult = false;
    });

    _controller
      ..reset()
      ..forward();
    _currentRotation = endRotation;
  }

  void _closeResult() {
    setState(() {
      _showResult = false;
    });
  }

  List<_WeightEntry> _buildMergedWeightEntries() {
    final merged = <String, int>{};
    for (var i = 0; i < _segments.length; i++) {
      final label = _segments[i];
      final weight = i < _segmentWeights.length ? _segmentWeights[i] : 0;
      merged[label] = (merged[label] ?? 0) + math.max(0, weight);
    }

    return merged.entries
        .where((entry) => entry.value > 0)
        .map((entry) => _WeightEntry(label: entry.key, weight: entry.value))
        .toList(growable: false);
  }

  Future<void> _showWeightHelpDialog() async {
    final entries = _buildMergedWeightEntries();
    if (entries.isEmpty) {
      return;
    }

    final total = entries.fold<int>(0, (sum, entry) => sum + entry.weight);
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('룰렛 가중치 안내'),
          content: SizedBox(
            width: 320,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: SizedBox(
                      width: 220,
                      height: 220,
                      child: CustomPaint(
                        painter: _RouletteWeightPiePainter(
                          entries: entries,
                          colors: _weightChartColors,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (var i = 0; i < entries.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _weightChartColors[
                                  i % _weightChartColors.length],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entries[i].label,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '${((entries[i].weight / total) * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final scale = math.min(
            constraints.maxWidth / AppSizes.designWidth,
            constraints.maxHeight / AppSizes.designHeight,
          );
          final wheelSize = AppSizes.rouletteWheelSize * scale;
          final pinWidth =
              AppSizes.roulettePinWidth * scale * AppSizes.roulettePinScale;
          final pinHeight =
              AppSizes.roulettePinHeight * scale * AppSizes.roulettePinScale;
            final logoWidth = AppSizes.rouletteLogoWidth * scale;
            final logoTopPadding = AppSizes.rouletteLogoTopPadding * scale;
          final buttonSize = AppSizes.rouletteSpinButtonSize * scale;
          final buttonTextSize = AppSizes.rouletteSpinButtonTextSize * scale;
          final labelRadius = AppSizes.rouletteLabelRadius * scale;
          final labelTextSize = AppSizes.rouletteLabelTextSize * scale;
          final labelInset = AppSizes.rouletteLabelInset * scale;
          final resultWidth = AppSizes.rouletteResultWidth * scale;
          final resultHeight = AppSizes.rouletteResultHeight * scale;
          final resultTextSize = AppSizes.rouletteResultTextSize * scale;
          final resultButtonWidth = AppSizes.rouletteResultButtonWidth * scale;
          final resultButtonHeight =
              AppSizes.rouletteResultButtonHeight * scale;
          final resultSpacing = AppSizes.rouletteResultSpacing * scale;

          return Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: Image.asset(AppAssets.gameBackground1, fit: BoxFit.fill),
              ),
              AnimatedBuilder(
                animation: _rotation,
                builder: (context, child) {
                  return Transform.rotate(angle: _rotation.value, child: child);
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      AppAssets.ruletBackground,
                      width: wheelSize,
                      height: wheelSize,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(
                      width: wheelSize,
                      height: wheelSize,
                      child: CustomPaint(
                        painter: _RouletteLabelPainter(
                          labels: _segments,
                          radius: labelRadius,
                          inset: labelInset,
                          textSize: labelTextSize,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top:
                    (constraints.maxHeight - wheelSize) / 2 -
                    (pinHeight * AppSizes.roulettePinOverlap),
                child: Image.asset(
                  AppAssets.ruletPin,
                  width: pinWidth,
                  height: pinHeight,
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                top: logoTopPadding,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Center(
                    child: LogoButton(width: logoWidth),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: buttonSize,
                  height: buttonSize,
                  child: ElevatedButton(
                    onPressed: (_isSpinning || _isApplyingResultApi)
                        ? null
                        : _spin,
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size.zero,
                      fixedSize: Size(buttonSize, buttonSize),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: const CircleBorder(),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      '돌리기',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: buttonTextSize),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 16 * scale,
                bottom: 16 * scale,
                child: SafeArea(
                  child: SizedBox(
                    width: 52 * scale,
                    height: 52 * scale,
                    child: FloatingActionButton(
                      heroTag: 'roulette_help_button',
                      onPressed: _showWeightHelpDialog,
                      backgroundColor: const Color(0xFFFFFFFF),
                      foregroundColor: const Color(0xFF111111),
                      mini: true,
                      child: const Icon(Icons.help_outline),
                    ),
                  ),
                ),
              ),
              if (_showResult)
                Positioned.fill(
                  child: Container(
                    color: AppColors.starGameOverlayScrim,
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.asset(
                            AppAssets.ruletResult,
                            width: resultWidth,
                            height: resultHeight,
                            fit: BoxFit.contain,
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _resultLabel,
                                style: TextStyle(fontSize: resultTextSize),
                              ),
                              SizedBox(height: resultSpacing),
                              SizedBox(
                                width: resultButtonWidth,
                                height: resultButtonHeight,
                                child: ElevatedButton(
                                  onPressed: _closeResult,
                                  child: const Text('확인'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _WeightEntry {
  const _WeightEntry({required this.label, required this.weight});

  final String label;
  final int weight;
}

class _RouletteWeightPiePainter extends CustomPainter {
  _RouletteWeightPiePainter({required this.entries, required this.colors});

  final List<_WeightEntry> entries;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty || colors.isEmpty) {
      return;
    }

    final total = entries.fold<int>(0, (sum, entry) => sum + entry.weight);
    if (total <= 0) {
      return;
    }

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    var startAngle = -math.pi / 2;

    for (var i = 0; i < entries.length; i++) {
      final sweepAngle = (entries[i].weight / total) * (math.pi * 2);
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;
      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);
      startAngle += sweepAngle;
    }

    final holePaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.38, holePaint);
  }

  @override
  bool shouldRepaint(covariant _RouletteWeightPiePainter oldDelegate) {
    return oldDelegate.entries != entries || oldDelegate.colors != colors;
  }
}

class _RouletteLabelPainter extends CustomPainter {
  _RouletteLabelPainter({
    required this.labels,
    required this.radius,
    required this.inset,
    required this.textSize,
  });

  final List<String> labels;
  final double radius;
  final double inset;
  final double textSize;

  @override
  void paint(Canvas canvas, Size size) {
    if (labels.isEmpty) {
      return;
    }
    final center = Offset(size.width / 2, size.height / 2);
    final slice = (2 * math.pi) / labels.length;
    final baseAngle = -math.pi / 2 + AppSizes.rouletteWheelAngleOffset;

    final useRadius = math.max(0.0, radius - inset);
    for (var i = 0; i < labels.length; i++) {
      final angle =
          baseAngle + (slice * (i + AppSizes.rouletteLabelAngleOffset));
      final textPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: const Color(0xFFFFFFFF),
            fontSize: textSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final position = Offset(
        center.dx + (useRadius * math.cos(angle)),
        center.dy + (useRadius * math.sin(angle)),
      );
      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(angle + math.pi);
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _RouletteLabelPainter oldDelegate) {
    return oldDelegate.labels != labels ||
        oldDelegate.radius != radius ||
        oldDelegate.inset != inset ||
        oldDelegate.textSize != textSize;
  }
}
