import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import 'ranking_item_base.dart';

/// Ranking list item widget for default entries.
class RankingItemDefault extends StatelessWidget {
  const RankingItemDefault({
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
      background: const BoxDecoration(color: AppColors.rankingDefaultFill),
      outlineColor: AppColors.rankingDefaultOutline,
      shadowColor: AppColors.rankingDefaultShadow,
    );
  }
}
