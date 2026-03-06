import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../constants/supabase_config.dart';

enum LoginOutcome { signedUp, loggedIn, wrongPassword }

class LoginResult {
  const LoginResult({required this.outcome, required this.nickname});

  final LoginOutcome outcome;
  final String nickname;
}

class LoginSchemaException implements Exception {
  const LoginSchemaException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LoginService {
  static const String _table = 'user_profile';

  Future<LoginResult> loginOrSignup({
    required String nickname,
    required String password,
  }) async {
    final trimmedNickname = nickname.trim();
    if (trimmedNickname.isEmpty || password.isEmpty) {
      throw ArgumentError('닉네임과 비밀번호를 입력해주세요.');
    }

    final users = await _fetchUsersByNickname(trimmedNickname);

    if (users.isEmpty) {
      return _signup(trimmedNickname, password);
    }

    final user = users.first;
    final passwordHash = user['password_hash'] as String?;
    if (passwordHash == null || passwordHash.isEmpty) {
      throw const LoginSchemaException(
        'DB 스키마에 password_hash 컬럼이 필요합니다. user_profile에 password_hash(TEXT) 컬럼을 추가해주세요.',
      );
    }

    final matches = _verifyPassword(password, passwordHash);
    if (!matches) {
      return LoginResult(
        outcome: LoginOutcome.wrongPassword,
        nickname: trimmedNickname,
      );
    }

    return LoginResult(outcome: LoginOutcome.loggedIn, nickname: trimmedNickname);
  }

  Future<List<dynamic>> _fetchUsersByNickname(String nickname) async {
    final uri = SupabaseConfig.restUri(
      _table,
      queryParameters: {
        'select': 'id,nickname,password_hash',
        'nickname': 'eq.$nickname',
        'limit': '1',
      },
    );

    final response = await http.get(uri, headers: SupabaseConfig.defaultHeaders);
    if (response.statusCode != 200) {
      throw Exception(_extractErrorMessage(response.body));
    }

    return jsonDecode(response.body) as List<dynamic>;
  }

  Future<LoginResult> _signup(String nickname, String password) async {
    final passwordHash = _hashPassword(password);

    final uri = SupabaseConfig.restUri(
      _table,
      queryParameters: {'select': 'nickname'},
    );

    final response = await http.post(
      uri,
      headers: {
        ...SupabaseConfig.defaultHeaders,
        'Prefer': 'return=representation',
      },
      body: jsonEncode({
        'nickname': nickname,
        'password_hash': passwordHash,
        'total_candies': 0,
      }),
    );

    if (response.statusCode != 201) {
      final message = _extractErrorMessage(response.body);
      if (_isMissingIdDefaultError(message)) {
        throw const LoginSchemaException(
          'user_profile.id 컬럼에 자동 생성 기본값이 없습니다. Supabase SQL Editor에서 id 기본값(IDENTITY 또는 gen_random_uuid())을 설정해주세요.',
        );
      }
      if (_isInvalidRegexError(message)) {
        throw const LoginSchemaException(
          'DB의 CHECK 제약식 또는 정책에 잘못된 정규식(예: \\#)이 있습니다. user_profile 관련 제약식/정책의 정규식을 점검해주세요.',
        );
      }
      if (_isNicknameFormatConstraintError(message)) {
        throw const LoginSchemaException(
          '닉네임 형식이 올바르지 않습니다. 1~10자, 한글/영문/숫자만 입력해주세요.',
        );
      }
      if (_isUserProfileIdForeignKeyError(message)) {
        throw const LoginSchemaException(
          '현재 user_profile.id가 users 테이블을 참조하는 외래키로 묶여 있어 신규 가입이 차단됩니다. Supabase에서 user_profile_id_fkey 제약을 제거하거나 Auth 기반 가입으로 전환해주세요.',
        );
      }
      throw Exception(message);
    }

    return LoginResult(outcome: LoginOutcome.signedUp, nickname: nickname);
  }

  String _extractErrorMessage(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
      final message = decoded['message']?.toString() ?? '';
      final details = decoded['details']?.toString() ?? '';
      final hint = decoded['hint']?.toString() ?? '';
      final parts = [message, details, hint]
          .where((part) => part.isNotEmpty)
          .toList();
      if (parts.isNotEmpty) {
        return parts.join('\n');
      }
      return responseBody;
    } catch (_) {
      return responseBody;
    }
  }

  bool _isMissingIdDefaultError(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('null value in column "id"') &&
        normalized.contains('violates not-null constraint');
  }

  bool _isInvalidRegexError(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('invalid regular expression') &&
        normalized.contains('invalid escape');
  }

  bool _isNicknameFormatConstraintError(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('user_profile_nickname_format_chk') ||
      normalized.contains('nickname_format_chk') ||
      (normalized.contains('violates check constraint') &&
        (normalized.contains('nickname') ||
          normalized.contains('format_chk')));
  }

  bool _isUserProfileIdForeignKeyError(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('user_profile_id_fkey') ||
        (normalized.contains('violates foreign key constraint') &&
            normalized.contains('key is not present in table "users"'));
  }

  String _hashPassword(String password) {
    final digest = sha256.convert(utf8.encode(password));
    return 'sha256:$digest';
  }

  bool _verifyPassword(String rawPassword, String storedHash) {
    // Legacy compatibility: treat old bcrypt values as non-matching on web
    // and avoid runtime regex errors from incompatible implementations.
    if (storedHash.startsWith(r'$2')) {
      return false;
    }

    if (storedHash.startsWith('sha256:')) {
      return _hashPassword(rawPassword) == storedHash;
    }

    return false;
  }
}
