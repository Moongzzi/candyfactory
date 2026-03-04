import 'package:flutter/material.dart';

import '../../constants/app_assets.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';

/// Base layout for a ranking list item.
class RankingItemBase extends StatelessWidget {
  const RankingItemBase({
    super.key,
    required this.rank,
    required this.nickname,
    required this.candyCount,
    required this.background,
    required this.outlineColor,
    required this.shadowColor,
  });

  final int rank;
  final String nickname;
  final int candyCount;
  final BoxDecoration background;
  final Color outlineColor;
  final Color shadowColor;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / AppSizes.designWidth;
    final width = AppSizes.rankingItemWidth * scale;
    final height = AppSizes.rankingItemHeight * scale;
    final borderWidth = AppSizes.rankingItemBorderWidth * scale;
    final blur = AppSizes.rankingItemShadowBlur * scale;
    final spread = AppSizes.rankingItemShadowSpread * scale;
    final textSize = AppSizes.rankingItemTextSize * scale;
    final nameSpacing = AppSizes.rankingItemNameSpacing * scale;
    final candySpacing = AppSizes.rankingItemCandySpacing * scale;
    final horizontalPadding = AppSizes.rankingItemHorizontalPadding * scale;
    final iconSize = AppSizes.rankingItemIconSize * scale;
    final radius = AppSizes.rankingItemRadius * scale;

    return Container(
      width: width,
      height: height,
      decoration: background.copyWith(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: outlineColor, width: borderWidth),
        boxShadow: [
          BoxShadow(color: shadowColor, blurRadius: blur, spreadRadius: spread),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Row(
          children: [
            Text(
              rank.toString(),
              style: TextStyle(color: AppColors.text, fontSize: textSize),
            ),
            SizedBox(width: nameSpacing),
            Expanded(
              child: Text(
                nickname,
                style: TextStyle(color: AppColors.text, fontSize: textSize),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: candySpacing),
            Image.asset(
              AppAssets.rankingCandy,
              width: iconSize,
              height: iconSize,
              fit: BoxFit.contain,
            ),
            SizedBox(width: candySpacing),
            Text(
              _formatCandyCount(candyCount),
              style: TextStyle(color: AppColors.text, fontSize: textSize),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCandyCount(int value) {
    final text = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final indexFromRight = text.length - i;
      buffer.write(text[i]);
      if (indexFromRight > 1 && indexFromRight % 3 == 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }
}
