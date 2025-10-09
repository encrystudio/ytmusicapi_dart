import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:ytmusicapi_dart/auth/oauth/exceptions.dart';
import 'package:ytmusicapi_dart/auth/oauth/models.dart';
import 'package:ytmusicapi_dart/constants.dart';
import 'package:ytmusicapi_dart/exceptions.dart';
import 'package:ytmusicapi_dart/type_alias.dart';

/// Base class representation of YouTubeMusicAPI OAuth Credentials.
abstract class Credentials {
  /// OAuth client ID.
  final String clientId;

  /// OAuth client secret.
  final String clientSecret;

  /// Create new [Credentials].
  Credentials(this.clientId, this.clientSecret);

  /// Method for obtaining a new user auth code. First step of token creation.
  Future<AuthCodeMap> getCode();

  /// Method for verifying user auth code and conversion into a [RefreshableTokenMap].
  Future<RefreshableTokenMap> tokenFromCode(String deviceCode);

  /// Method for requesting a new access token for a given [refreshToken]. Token must have been created by the same OAuth client.
  Future<BaseTokenMap> refreshToken(String refreshToken);
}

/// Class for handling OAuth credential retrieval and refreshing.
class OAuthCredentials extends Credentials {
  late final Dio _dio;

  /// Create new [OAuthCredentials].
  ///
  /// - [clientId] Optional. Set the GoogleAPI [clientId] used for auth flows. Requires [clientSecret] also be provided if set.
  /// - [clientSecret] Optional. Corresponding secret for provided [clientId].
  /// - [dio] Optional. Connection pooling with an active session.
  /// - [options] Optional. Modify the session with Dio [BaseOptions].
  /// - [proxies] Optional. Modify the session with proxy parameters.
  OAuthCredentials({
    required String clientId,
    required String clientSecret,
    Dio? dio,
    BaseOptions? options,
    Map<String, String>? proxies,
  }) : super(clientId, clientSecret) {
    _dio = dio ?? Dio(options ?? BaseOptions());

    if (proxies != null && proxies.isNotEmpty) {
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.findProxy = (uri) {
          if (uri.scheme == 'http' && proxies.containsKey('http')) {
            return "PROXY ${proxies['http']}";
          } else if (uri.scheme == 'https' && proxies.containsKey('https')) {
            return "PROXY ${proxies['https']}";
          }
          return 'DIRECT';
        };
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      };
    }
  }

  /// Method for obtaining a new user auth code. First step of token creation.
  @override
  Future<AuthCodeMap> getCode() async {
    final codeResponse = await _sendRequest(OAUTH_CODE_URL, {
      'scope': OAUTH_SCOPE,
    });
    return AuthCodeMap.fromJson(codeResponse);
  }

  /// Method for sending post requests to [url] with required `client_id` and `User-Agent` modifications declared in [data].
  Future<JsonMap> _sendRequest(String url, JsonMap data) async {
    data['client_id'] = clientId;

    try {
      final response = await _dio.post(
        url,
        data: data,
        options: Options(headers: {'User-Agent': OAUTH_USER_AGENT}),
      );

      return response.data is JsonMap
          ? response.data as JsonMap
          : JsonMap.from(jsonDecode(response.data as String) as JsonMap);
    } on DioException catch (e) {
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final responseData = e.response!.data as JsonMap;

        if (statusCode == 401) {
          final issue = responseData['error'];
          if (issue == 'unauthorized_client') {
            throw UnauthorizedOAuthClient(
              'Token refresh error. Most likely client/token mismatch.',
            );
          } else if (issue == 'invalid_client') {
            throw BadOAuthClient(
              'OAuth client failure. Most likely client_id and client_secret mismatch or YouTubeData API is not enabled.',
            );
          } else {
            throw YTMusicServerError(
              'OAuth request error. status_code: $statusCode, url: $url, content: $responseData',
            );
          }
        }
      }

      rethrow;
    }
  }

  /// Method for verifying user auth code and conversion into a [RefreshableTokenMap].
  @override
  Future<RefreshableTokenMap> tokenFromCode(String deviceCode) async {
    final response = await _sendRequest(OAUTH_TOKEN_URL, {
      'client_secret': clientSecret,
      'grant_type': 'http://oauth.net/grant_type/device/1.0',
      'code': deviceCode,
    });
    return RefreshableTokenMap.fromJson(response);
  }

  /// Method for requesting a new access token for a given [refreshToken]. Token must have been created by the same OAuth client.
  @override
  Future<BaseTokenMap> refreshToken(String refreshToken) async {
    final response = await _sendRequest(OAUTH_TOKEN_URL, {
      'client_secret': clientSecret,
      'grant_type': 'refresh_token',
      'refresh_token': refreshToken,
    });
    return BaseTokenMap.fromJson(response);
  }
}
