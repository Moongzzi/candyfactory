import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../Common/session_store.dart';
import '../Home/widgets/logo_button.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import 'ranking_service.dart';
import 'widgets/ranking_item_default.dart';
import 'widgets/ranking_item_first.dart';
import 'widgets/ranking_item_second.dart';
import 'widgets/ranking_item_third.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  final RankingService _rankingService = RankingService();
  late Future<RankingSnapshot> _rankingFuture;

  @override
  void initState() {
    super.initState();
    _rankingFuture = _fetchRanking();
  }

  Future<RankingSnapshot> _fetchRanking() {
    return _rankingService.fetchRanking(
      myNickname: SessionStore.nickname.value,
    );
  }

  void _retryFetchRanking() {
    setState(() {
      _rankingFuture = _fetchRanking();
    });
  }

  Widget _buildMyRankingPinnedItem({
    required BuildContext context,
    required Widget child,
  }) {
    final scale = MediaQuery.of(context).size.width / AppSizes.designWidth;
    final labelPaddingX = 10.0 * scale;
    final labelPaddingY = 3.0 * scale;
    final labelRadius = 6.0 * scale;
    final labelTextSize = 12.0 * scale;
    final labelGap = 6.0 * scale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: labelPaddingX,
            vertical: labelPaddingY,
          ),
          decoration: BoxDecoration(
            color: AppColors.rankingFirstOutline,
            borderRadius: BorderRadius.circular(labelRadius),
          ),
          child: Text(
            '내 랭킹',
            style: TextStyle(
              color: AppColors.text,
              fontSize: labelTextSize,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(height: labelGap),
        child,
      ],
    );
  }

  Widget _buildRankingItem({
    required int rank,
    required String nickname,
    required int candyCount,
  }) {
    switch (rank) {
      case 1:
        return RankingItemFirst(
          rank: rank,
          nickname: nickname,
          candyCount: candyCount,
        );
      case 2:
        return RankingItemSecond(
          rank: rank,
          nickname: nickname,
          candyCount: candyCount,
        );
      case 3:
        return RankingItemThird(
          rank: rank,
          nickname: nickname,
          candyCount: candyCount,
        );
      default:
        return RankingItemDefault(
          rank: rank,
          nickname: nickname,
          candyCount: candyCount,
        );
    }
  }

  Widget _buildTopRankingSection({
    required List<RankingEntry> topEntries,
    required double itemSpacing,
  }) {
    if (topEntries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        for (var i = 0; i < topEntries.length; i++) ...[
          if (i > 0) SizedBox(height: itemSpacing),
          _buildRankingItem(
            rank: topEntries[i].rank,
            nickname: topEntries[i].nickname,
            candyCount: topEntries[i].candyCount,
          ),
        ],
      ],
    );
  }

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
                  child: FutureBuilder<RankingSnapshot>(
                    future: _rankingFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 24.0 * scale,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '랭킹을 불러오지 못했습니다.',
                                  style: TextStyle(
                                    color: AppColors.text,
                                    fontSize: 18.0 * scale,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 8.0 * scale),
                                Text(
                                  '${snapshot.error}',
                                  style: TextStyle(
                                    color: AppColors.text,
                                    fontSize: 14.0 * scale,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 16.0 * scale),
                                ElevatedButton(
                                  onPressed: _retryFetchRanking,
                                  child: const Text('다시 시도'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final ranking = snapshot.data;
                      if (ranking == null || ranking.entries.isEmpty) {
                        return Center(
                          child: Text(
                            '표시할 랭킹 데이터가 없습니다.',
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 18.0 * scale,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      }

                      final topEntries = ranking.entries.take(3).toList();
                      final restEntries = ranking.entries.skip(3).toList();
                      final myEntry = ranking.myEntry;

                      return Column(
                        children: [
                          SizedBox(height: headerSpacing),
                          LogoButton(width: logoWidth),
                          SizedBox(height: headerSpacing),
                          if (myEntry != null) ...[
                            _buildMyRankingPinnedItem(
                              context: context,
                              child: _buildRankingItem(
                                rank: myEntry.rank,
                                nickname: myEntry.nickname,
                                candyCount: myEntry.candyCount,
                              ),
                            ),
                            SizedBox(height: itemSpacing),
                          ],
                          _buildTopRankingSection(
                            topEntries: topEntries,
                            itemSpacing: itemSpacing,
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
                              itemCount: restEntries.length,
                              separatorBuilder: (context, index) =>
                                  SizedBox(height: itemSpacing),
                              itemBuilder: (context, index) {
                                final entry = restEntries[index];
                                return RankingItemDefault(
                                  rank: entry.rank,
                                  nickname: entry.nickname,
                                  candyCount: entry.candyCount,
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
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
