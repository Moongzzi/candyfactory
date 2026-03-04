import 'package:flutter/material.dart';

import '../../constants/app_assets.dart';
import '../../constants/app_sizes.dart';

/// Home button group widget.
class HomeButtonGroup extends StatelessWidget {
  const HomeButtonGroup({
    super.key,
    this.onRanking,
    this.onBigLeft,
    this.onRightTop,
    this.onRightBottom,
    this.onBottomLeft,
    this.onBottomRight,
  });

  final VoidCallback? onRanking;
  final VoidCallback? onBigLeft;
  final VoidCallback? onRightTop;
  final VoidCallback? onRightBottom;
  final VoidCallback? onBottomLeft;
  final VoidCallback? onBottomRight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final scale = maxWidth / AppSizes.designWidth;
        final spacing = AppSizes.homeButtonSpacing * scale;
        final rankingWidth = AppSizes.rankingButtonWidth * scale;
        final rankingHeight = AppSizes.rankingButtonHeight * scale;
        final leftBigWidth = AppSizes.leftBigButtonWidth * scale;
        final leftBigHeight = AppSizes.leftBigButtonHeight * scale;
        final smallWidth = AppSizes.smallButtonWidth * scale;
        final smallHeight = AppSizes.smallButtonHeight * scale;

        return Column(
          children: [
            Center(
              child: SizedBox(
                width: rankingWidth,
                height: rankingHeight,
                child: _HomeImageButton(
                  assetPath: AppAssets.homeButton1,
                  onPressed: onRanking,
                ),
              ),
            ),
            SizedBox(height: spacing),
            Center(
              child: SizedBox(
                height: leftBigHeight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: leftBigWidth,
                      height: leftBigHeight,
                      child: _HomeImageButton(
                        assetPath: AppAssets.homeButton2,
                        onPressed: onBigLeft,
                      ),
                    ),
                    SizedBox(width: spacing),
                    SizedBox(
                      width: smallWidth,
                      height: leftBigHeight,
                      child: Column(
                        children: [
                          SizedBox(
                            width: smallWidth,
                            height: smallHeight,
                            child: _HomeImageButton(
                              assetPath: AppAssets.homeButton3,
                              onPressed: onRightTop,
                            ),
                          ),
                          SizedBox(height: spacing),
                          SizedBox(
                            width: smallWidth,
                            height: smallHeight,
                            child: _HomeImageButton(
                              assetPath: AppAssets.homeButton4,
                              onPressed: onRightBottom,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: spacing),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: smallWidth,
                    height: smallHeight,
                    child: _HomeImageButton(
                      assetPath: AppAssets.homeButton5,
                      onPressed: onBottomLeft,
                    ),
                  ),
                  SizedBox(width: spacing),
                  SizedBox(
                    width: smallWidth,
                    height: smallHeight,
                    child: _HomeImageButton(
                      assetPath: AppAssets.homeButton6,
                      onPressed: onBottomRight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Internal image button tile for the home button group.
class _HomeImageButton extends StatelessWidget {
  const _HomeImageButton({required this.assetPath, this.onPressed});

  final String assetPath;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        child: Ink.image(image: AssetImage(assetPath), fit: BoxFit.fill),
      ),
    );
  }
}
