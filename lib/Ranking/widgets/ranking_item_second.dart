import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import 'ranking_item_base.dart';

/// Ranking list item widget for 2nd place.
class RankingItemSecond extends StatelessWidget {
  const RankingItemSecond({
    super.key,
    required this.rank,
    required this.nickname,
    required this.candyCount,
  });

  final int rank;
  final String nickname;
  final int candyCount;

  @override
  Widget build(BuildContext context) {
    return RankingItemBase(
      rank: rank,
      nickname: nickname,
      candyCount: candyCount,
      background: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.0, -0.6),
          radius: 1.6,
          colors: [AppColors.rankingSecondInner, AppColors.rankingSecondOuter],
        ),
      ),
      outlineColor: AppColors.rankingSecondOutline,
      shadowColor: AppColors.rankingSecondShadow,
    );
  }
}
