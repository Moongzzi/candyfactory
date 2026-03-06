import 'dart:convert';

import 'package:http/http.dart' as http;

import '../Common/session_store.dart';
import '../constants/supabase_config.dart';

class GamePlayApiService {
  static const bool _enableGameLogApi = bool.fromEnvironment(
    'ENABLE_GAME_LOG_API',
    defaultValue: true,
  );

  bool _disableGameLogApis = false;

  Future<String?> startGame({required String gameCode}) async {
    if (!_enableGameLogApi) {
      return null;
    }

    if (_disableGameLogApis) {
      return null;
    }

    final uri = Uri.parse(
      '${SupabaseConfig.projectUrl}/rest/v1/rpc/start_game',
    );
    final meta = _buildMeta();

    final response = await http.post(
      uri,
      headers: {
        ...SupabaseConfig.defaultHeaders,
        'Prefer': 'return=representation',
      },
      body: jsonEncode({'p_game_code': gameCode, 'p_meta': meta}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _extractLogId(response.body);
    }

    final message = _extractErrorMessage(response.body);
    if (_isAuthFailure(statusCode: response.statusCode, message: message)) {
      _disableGameLogApis = true;
      return null;
    }

    // Fallback: try direct insert when RPC is unavailable for this role.
    return _insertGameLogDirectly(gameCode: gameCode, meta: meta);
  }

  Future<void> finishGame({
    required String gameCode,
    required int score,
    String? logId,
  }) async {
    final safeScore = score < 0 ? 0 : score;
    final meta = _buildMeta(extra: {'score': safeScore});

    if (!_enableGameLogApi) {
      await _addCandiesDirectly(delta: safeScore);
      return;
    }

    if (_disableGameLogApis) {
      await _addCandiesDirectly(delta: safeScore);
      return;
    }

    if (logId != null && logId.isNotEmpty) {
      final uri = Uri.parse(
        '${SupabaseConfig.projectUrl}/rest/v1/rpc/finish_game',
      );
      final response = await http.post(
        uri,
        headers: {
          ...SupabaseConfig.defaultHeaders,
          'Prefer': 'return=representation',
        },
        body: jsonEncode({
          'p_log_id': logId,
          'p_candies_delta': safeScore,
          'p_meta': meta,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      }

      final message = _extractErrorMessage(response.body);
      if (_isAuthFailure(statusCode: response.statusCode, message: message)) {
        _disableGameLogApis = true;
        await _addCandiesDirectly(delta: safeScore);
        return;
      }
    }

    // Fallback paths for projects that don't use RPC auth flows yet.
    await Future.wait([
      _addCandiesDirectly(delta: safeScore),
      _finishGameLogDirectly(
        logId: logId,
        gameCode: gameCode,
        score: safeScore,
        meta: meta,
      ),
    ]);
  }

  Map<String, dynamic> _buildMeta({Map<String, dynamic>? extra}) {
    final nickname = SessionStore.nickname.value;
    return <String, dynamic>{'nickname': nickname, if (extra != null) ...extra};
  }

  String? _extractLogId(String body) {
    if (body.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(body);

      if (decoded is String && decoded.isNotEmpty) {
        return decoded;
      }

      if (decoded is Map<String, dynamic>) {
        final logId = decoded['log_id'] ?? decoded['id'];
        if (logId is String && logId.isNotEmpty) {
          return logId;
        }
      }

      if (decoded is List && decoded.isNotEmpty) {
        final first = decoded.first;
        if (first is String && first.isNotEmpty) {
          return first;
        }
        if (first is Map<String, dynamic>) {
          final logId = first['log_id'] ?? first['id'];
          if (logId is String && logId.isNotEmpty) {
            return logId;
          }
        }
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  Future<String?> _insertGameLogDirectly({
    required String gameCode,
    required Map<String, dynamic> meta,
  }) async {
    final profile = await _fetchCurrentProfile();
    if (profile == null) {
      return null;
    }

    final uri = SupabaseConfig.restUri(
      'game_log',
      queryParameters: {'select': 'id'},
    );

    final response = await http.post(
      uri,
      headers: {
        ...SupabaseConfig.defaultHeaders,
        'Prefer': 'return=representation',
      },
      body: jsonEncode({
        'user_id': profile.id,
        'game_code': gameCode,
        'started_at': DateTime.now().toUtc().toIso8601String(),
        'candies_delta': 0,
        'meta': meta,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = _extractErrorMessage(response.body);
      if (_isAuthFailure(statusCode: response.statusCode, message: message)) {
        _disableGameLogApis = true;
      }
      return null;
    }

    return _extractLogId(response.body);
  }

  Future<void> _finishGameLogDirectly({
    required String? logId,
    required String gameCode,
    required int score,
    required Map<String, dynamic> meta,
  }) async {
    if (logId != null && logId.isNotEmpty) {
      final uri = SupabaseConfig.restUri(
        'game_log',
        queryParameters: {'id': 'eq.$logId'},
      );
      await http.patch(
        uri,
        headers: SupabaseConfig.defaultHeaders,
        body: jsonEncode({
          'ended_at': DateTime.now().toUtc().toIso8601String(),
          'candies_delta': score,
          'meta': meta,
        }),
      );
      return;
    }

    final profile = await _fetchCurrentProfile();
    if (profile == null) {
      return;
    }

    final uri = SupabaseConfig.restUri('game_log');
    await http.post(
      uri,
      headers: SupabaseConfig.defaultHeaders,
      body: jsonEncode({
        'user_id': profile.id,
        'game_code': gameCode,
        'started_at': DateTime.now().toUtc().toIso8601String(),
        'ended_at': DateTime.now().toUtc().toIso8601String(),
        'candies_delta': score,
        'meta': meta,
      }),
    );
  }

  bool _isAuthFailure({required int statusCode, required String message}) {
    if (statusCode == 401 || statusCode == 403) {
      return true;
    }

    final normalized = message.toLowerCase();
    return normalized.contains('not authenticated') ||
        normalized.contains('permission denied') ||
        normalized.contains('jwt');
  }

  String _extractErrorMessage(String responseBody) {
    if (responseBody.trim().isEmpty) {
      return '';
    }

    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message']?.toString() ?? '';
        final details = decoded['details']?.toString() ?? '';
        final hint = decoded['hint']?.toString() ?? '';
        return [
          message,
          details,
          hint,
        ].where((part) => part.isNotEmpty).join(' ').trim();
      }
      return decoded.toString();
    } catch (_) {
      return responseBody;
    }
  }

  Future<void> _addCandiesDirectly({required int delta}) async {
    if (delta <= 0) {
      return;
    }

    final profile = await _fetchCurrentProfile();
    if (profile == null) {
      return;
    }

    final uri = SupabaseConfig.restUri(
      'user_profile',
      queryParameters: {'id': 'eq.${profile.id}'},
    );

    await http.patch(
      uri,
      headers: SupabaseConfig.defaultHeaders,
      body: jsonEncode({'total_candies': profile.totalCandies + delta}),
    );
  }

  Future<_CurrentProfile?> _fetchCurrentProfile() async {
    final nickname = SessionStore.nickname.value?.trim();
    if (nickname == null || nickname.isEmpty) {
      return null;
    }

    final uri = SupabaseConfig.restUri(
      'user_profile',
      queryParameters: {
        'select': 'id,total_candies',
        'nickname': 'eq.$nickname',
        'limit': '1',
      },
    );

    final response = await http.get(
      uri,
      headers: SupabaseConfig.defaultHeaders,
    );
    if (response.statusCode != 200) {
      return null;
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List || decoded.isEmpty) {
      return null;
    }

    final row = decoded.first;
    if (row is! Map<String, dynamic>) {
      return null;
    }

    final id = row['id']?.toString();
    if (id == null || id.isEmpty) {
      return null;
    }

    final candies = row['total_candies'];
    final totalCandies = candies is num ? candies.toInt() : 0;

    return _CurrentProfile(id: id, totalCandies: totalCandies);
  }
}

class _CurrentProfile {
  const _CurrentProfile({required this.id, required this.totalCandies});

  final String id;
  final int totalCandies;
}
