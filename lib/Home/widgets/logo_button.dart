import 'package:flutter/material.dart';

import '../../constants/app_assets.dart';
import '../../constants/app_routes.dart';

/// Home logo button widget with a subtle glass shine effect.
class LogoButton extends StatefulWidget {
  const LogoButton({super.key, required this.width});

  final double width;

  @override
  State<LogoButton> createState() => _LogoButtonState();
}

class _LogoButtonState extends State<LogoButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _shine;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
    _shine = CurvedAnimation(parent: _controller, curve: Curves.linear);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed(AppRoutes.home),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(AppAssets.logo, fit: BoxFit.contain),
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _shine,
                  builder: (context, child) {
                    final t = _shine.value;
                    // Move the highlight fully off-screen before reset.
                    final dx = -2.0 + (4.0 * t);
                    return ShaderMask(
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          begin: Alignment(-1.1 + dx, -0.3),
                          end: Alignment(0.1 + dx, 0.3),
                          colors: const [
                            Colors.transparent,
                            Color(0x33FFFFFF),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.srcATop,
                      child: child,
                    );
                  },
                  child: Image.asset(AppAssets.logo, fit: BoxFit.contain),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
