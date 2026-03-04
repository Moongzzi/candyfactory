import 'dart:math' as math;

import 'package:flutter/material.dart';

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
  late final AnimationController _controller;
  late Animation<double> _rotation;
  double _currentRotation = 0.0;
  bool _isSpinning = false;
  bool _showResult = false;
  String _resultLabel = '';

  final List<String> _segments = <String>[
    '꽝',
    '꽝',
    '꽝',
    '꽝',
    '+5',
    '+5',
    '+10',
    '+10',
    '-50',
    '+300',
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
  }

  void _spin() {
    if (_isSpinning) {
      return;
    }

    final random = math.Random();
    final index = random.nextInt(_segments.length);
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
                    onPressed: _spin,
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
