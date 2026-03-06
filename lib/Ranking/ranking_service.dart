import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/supabase_config.dart';

class RankingEntry {
  const RankingEntry({
    required this.rank,
    required this.nickname,
    required this.candyCount,
  });

  final int rank;
  final String nickname;
  final int candyCount;
}

class RankingSnapshot {
  const RankingSnapshot({required this.entries, required this.myEntry});

  final List<RankingEntry> entries;
  final RankingEntry? myEntry;
}

class RankingService {
  static const String _table = 'user_profile';

  Future<RankingSnapshot> fetchRanking({String? myNickname}) async {
    final uri = SupabaseConfig.restUri(
      _table,
      queryParameters: {
        'select': 'nickname,total_candies',
        'order': 'total_candies.desc,nickname.asc',
      },
    );

    final response = await http.get(
      uri,
      headers: SupabaseConfig.defaultHeaders,
    );
    if (response.statusCode != 200) {
      throw Exception(_extractErrorMessage(response.body));
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List<dynamic>) {
      throw Exception('랭킹 데이터를 불러오지 못했습니다.');
    }

    final parsed = <_RawProfile>[];
    for (final item in decoded) {
      if (item is! Map<String, dynamic>) {
        continue;
      }

      final nickname = item['nickname']?.toString().trim();
      if (nickname == null || nickname.isEmpty) {
        continue;
      }

      final candiesValue = item['total_candies'];
      final candyCount = candiesValue is num ? candiesValue.toInt() : 0;
      parsed.add(_RawProfile(nickname: nickname, candyCount: candyCount));
    }

    final rankedEntries = _assignCompetitionRanks(parsed);

    RankingEntry? myEntry;
    final targetNickname = myNickname?.trim();
    if (targetNickname != null && targetNickname.isNotEmpty) {
      for (final entry in rankedEntries) {
        if (entry.nickname == targetNickname) {
          myEntry = entry;
          break;
        }
      }
    }

    return RankingSnapshot(entries: rankedEntries, myEntry: myEntry);
  }

  List<RankingEntry> _assignCompetitionRanks(List<_RawProfile> profiles) {
    final result = <RankingEntry>[];

    var previousCandyCount = -1;
    var currentRank = 0;

    for (var index = 0; index < profiles.length; index++) {
      final profile = profiles[index];
      final position = index + 1;

      if (profile.candyCount != previousCandyCount) {
        currentRank = position;
        previousCandyCount = profile.candyCount;
      }

      result.add(
        RankingEntry(
          rank: currentRank,
          nickname: profile.nickname,
          candyCount: profile.candyCount,
        ),
      );
    }

    return result;
  }

  String _extractErrorMessage(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
      final message = decoded['message']?.toString() ?? '';
      final details = decoded['details']?.toString() ?? '';
      final hint = decoded['hint']?.toString() ?? '';
      final parts = [
        message,
        details,
        hint,
      ].where((part) => part.isNotEmpty).toList();
      if (parts.isNotEmpty) {
        return parts.join('\n');
      }
      return responseBody;
    } catch (_) {
      return responseBody;
    }
  }
}

class _RawProfile {
  const _RawProfile({required this.nickname, required this.candyCount});

  final String nickname;
  final int candyCount;
}
