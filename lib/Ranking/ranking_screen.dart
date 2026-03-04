import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../Home/widgets/logo_button.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import 'widgets/ranking_item_default.dart';
import 'widgets/ranking_item_first.dart';
import 'widgets/ranking_item_second.dart';
import 'widgets/ranking_item_third.dart';

class RankingScreen extends StatelessWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.webGradientColors,
            stops: AppColors.webGradientStops,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final maxHeight = constraints.maxHeight;
              final scale = math.min(
                maxWidth / AppSizes.designWidth,
                maxHeight / AppSizes.designHeight,
              );
              final logoWidth = AppSizes.rankingLogoWidth * scale;
              final headerSpacing = AppSizes.rankingHeaderSpacing * scale;
              final itemSpacing = AppSizes.rankingItemSpacing * scale;
              final bottomPadding = 30.0 * scale;
              final sidePadding =
                  ((AppSizes.designWidth - AppSizes.rankingItemWidth) / 2) *
                  scale;

              return Center(
                child: SizedBox(
                  width: AppSizes.designWidth * scale,
                  child: Column(
                    children: [
                      SizedBox(height: headerSpacing),
                      LogoButton(width: logoWidth),
                      SizedBox(height: headerSpacing),
                      RankingItemFirst(
                        rank: 1,
                        nickname: '옥옥옥옥옥',
                        candyCount: 123456,
                      ),
                      SizedBox(height: itemSpacing),
                      RankingItemSecond(
                        rank: 2,
                        nickname: 'SweetFox',
                        candyCount: 98765,
                      ),
                      SizedBox(height: itemSpacing),
                      RankingItemThird(
                        rank: 3,
                        nickname: 'CandyCat',
                        candyCount: 54321,
                      ),
                      SizedBox(height: itemSpacing),
                      Expanded(
                        child: ListView.separated(
                          padding: EdgeInsets.fromLTRB(
                            sidePadding,
                            0,
                            sidePadding,
                            bottomPadding,
                          ),
                          itemCount: 10,
                          separatorBuilder: (context, index) =>
                              SizedBox(height: itemSpacing),
                          itemBuilder: (context, index) {
                            // TODO: Replace dummy ranking data with API results.
                            final rank = index + 4;
                            return RankingItemDefault(
                              rank: rank,
                              nickname: 'Player $rank',
                              candyCount: 1000 - (rank * 3),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
