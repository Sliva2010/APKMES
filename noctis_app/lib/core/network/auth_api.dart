// Клиент REST-эндпоинтов аутентификации.
import 'dart:convert';
import 'dart:io';

import 'backend_config.dart';

class AuthApi {
  AuthApi();

  final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 10);

  Future<void> startPhone(String phone) async {
    if (!BackendConfig.isConfigured) return;
    final HttpClientRequest req =
        await _client.postUrl(Uri.parse(BackendConfig.httpUrl('/api/v1/auth/phone/start')));
    req.headers.contentType = ContentType.json;
    req.add(utf8.encode(jsonEncode(<String, String>{'phone': phone})));
    final HttpClientResponse resp = await req.close();
    await resp.drain<void>();
    if (resp.statusCode >= 400) {
      throw HttpException('start_phone_failed: ${resp.statusCode}');
    }
  }

  Future<TokenPair> verifyPhone(String phone, String code) async {
    if (!BackendConfig.isConfigured) {
      throw const _OfflineDemo();
    }
    final HttpClientRequest req = await _client
        .postUrl(Uri.parse(BackendConfig.httpUrl('/api/v1/auth/phone/verify')));
    req.headers.contentType = ContentType.json;
    req.add(utf8.encode(jsonEncode(<String, String>{
      'phone': phone,
      'code': code,
    })));
    final HttpClientResponse resp = await req.close();
    final String body = await utf8.decoder.bind(resp).join();
    if (resp.statusCode >= 400) {
      throw HttpException('verify_failed: ${resp.statusCode} $body');
    }
    final Map<String, dynamic> data = jsonDecode(body) as Map<String, dynamic>;
    return TokenPair(
      access: data['access'] as String? ?? '',
      refresh: data['refresh'] as String? ?? '',
      userId: (data['user_id'] as num?)?.toInt() ?? 0,
    );
  }

  void close() => _client.close(force: true);
}

class TokenPair {
  const TokenPair({
    required this.access,
    required this.refresh,
    required this.userId,
  });

  final String access;
  final String refresh;
  final int userId;
}

class _OfflineDemo implements Exception {
  const _OfflineDemo();
}
