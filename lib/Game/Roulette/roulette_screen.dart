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
  late final AnimationController _controller;
  late Animation<double> _rotation;
  double _currentRotation = 0.0;
  bool _isSpinning = false;
  bool _showResult = false;
  bool _isApplyingResultApi = false;
  String _resultLabel = '';

  final List<String> _segments = <String>[
    '-10',
    '+5',
    '+10',
    '꽝',
    '-50',
    '꽝',
    '+5',
    '+10',
    '-30',
    '+300',
  ];

  // Tune each slice probability by changing this list (same order as _segments).
  final List<int> _segmentWeights = <int>[
    896, // -10
    1282, // +5
    1154, // +10
    1795, // 꽝
    385, // -50
    1538, // 꽝
    1282, // +5
    1154, // +10
    513, // -30
    1, // +300 (0.01% = 1/10000)
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

  int _resultToDelta(String value) {
    if (value == '꽝') {
      return 0;
    }

    return int.tryParse(value) ?? 0;
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

    final resultDelta = _resultToDelta(_resultLabel);

    try {
      // Roulette play cost is always applied first.
      await _gamePlayApiService.applyCandiesDelta(
        delta: -10,
        gameCode: 'game1',
        extraMeta: {'phase': 'spin_cost', 'result_label': _resultLabel},
      );
      await _gamePlayApiService.applyCandiesDelta(
        delta: resultDelta,
        gameCode: 'game1',
        extraMeta: {'phase': 'spin_result', 'result_label': _resultLabel},
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

    final shouldSpin = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: const Text('캔디 포인트 10점을 활용하여 룰렛을 돌립니다.'),
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
