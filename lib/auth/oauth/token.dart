import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:open_url/open_url.dart';
import 'package:ytmusicapi_dart/auth/oauth/credentials.dart';
import 'package:ytmusicapi_dart/auth/oauth/models.dart';
import 'package:ytmusicapi_dart/type_alias.dart';

/// Base class representation of the YouTubeMusicAPI OAuth token.
class Token {
  /// Authentication scope.
  DefaultScope scope;

  /// Literal `Bearer`.
  Bearer tokenType;

  /// String to be used in authorization header.
  String accessToken;

  /// String used to obtain new access token upon expiration.
  String refreshToken;

  /// UNIX epoch timestamp in seconds.
  int expiresAt = 0;

  /// Seconds until expiration from request timestamp.
  int expiresIn = 0;

  /// Create new [Token].
  Token({
    required this.scope,
    required this.tokenType,
    required this.accessToken,
    required this.refreshToken,
    this.expiresAt = 0,
    this.expiresIn = 0,
  });

  /// Returns [JsonMap] containing underlying token values.
  JsonMap asMap() => {
    'scope': scope,
    'token_type': tokenType,
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'expires_at': expiresAt,
    'expires_in': expiresIn,
  };

  /// Returns this [Token] as Json String.
  String asJson() => jsonEncode(asMap());

  /// Returns authorization-header-ready String of [tokenType] and [accessToken].
  String asAuth() => '$tokenType $accessToken';

  /// Wether this [Token] expires in the next 60 seconds.
  bool get isExpiring => expiresIn < 60;
}

/// Wrapper for an OAuth token implementing expiration methods.
class OAuthToken extends Token {
  /// Create new [OAuthToken].
  OAuthToken({
    required super.scope,
    required super.tokenType,
    required super.accessToken,
    required super.refreshToken,
    super.expiresAt,
    super.expiresIn,
  });

  /// Wether [headers] is valid for OAuth.
  static bool isOAuth(Map<String, String> headers) {
    final keys = [
      'scope',
      'token_type',
      'access_token',
      'refresh_token',
      'expires_at',
      'expires_in',
    ];
    return keys.every((key) => headers.containsKey(key));
  }

  /// Update `access_token` and expiration attributes with a [BaseTokenMap] inplace.
  ///
  /// `expires_at` attribute set using current epoch, avoid expiration desync
  /// by passing only recently requested tokens Maps or updating values to compensate.
  void update(JsonMap freshAccess) {
    accessToken = freshAccess['access_token'] as String;
    expiresAt =
        DateTime.now().millisecondsSinceEpoch ~/ 1000 +
        (freshAccess['expires_in'] as int);
  }

  @override
  bool get isExpiring =>
      expiresAt - DateTime.now().millisecondsSinceEpoch ~/ 1000 < 60;

  /// Creates new [OAuthToken] from a Json file stored in [path].
  factory OAuthToken.fromJsonFile(String path) {
    final file = File(path);
    final jsonData = jsonDecode(file.readAsStringSync()) as JsonMap;
    return OAuthToken(
      scope: jsonData['scope'] as DefaultScope,
      tokenType: jsonData['token_type'] as Bearer,
      accessToken: jsonData['access_token'] as String,
      refreshToken: jsonData['refresh_token'] as String,
      expiresAt: jsonData['expires_at'] as int,
      expiresIn: jsonData['expires_in'] as int,
    );
  }
}

/// Compositional implementation of [Token] that automatically refreshes
/// an underlying [OAuthToken] when required (credential expiration <= 1 min)
/// upon `access_token` attribute access.
class RefreshingToken extends OAuthToken {
  /// Credentials used for  `access_token` refreshing.
  final Credentials credentials;
  // protected/property attribute enables auto writing token values to new file location via setter.
  String? _localCache;

  /// Create new [RefreshingToken].
  RefreshingToken({
    required this.credentials,
    required super.scope,
    required super.tokenType,
    required super.accessToken,
    required super.refreshToken,
    super.expiresAt,
    super.expiresIn,
    String? localCache,
  }) : _localCache = localCache;

  /// Returns path to [_localCache].
  String? get localCache => _localCache;

  /// Update attribute and dump token to new path.
  set localCache(String? path) {
    _localCache = path;
    storeToken(path: path);
  }

  /// Access token setter to auto-refresh if it is expiring.
  // TODO check if this implementation works
  @override
  String get accessToken {
    if (isExpiring) {
      credentials.refreshToken(refreshToken).then((fresh) {
        update(fresh.toJson());
        storeToken(path: _localCache);
      });
    }
    return super.accessToken;
  }

  /// Write token values to Json file at specified [path], defaulting to [_localCache].
  ///
  /// Operation does not update instance [_localCache] attribute.
  /// Automatically called when [_localCache] is set post init.
  void storeToken({String? path}) {
    final filePath = path ?? _localCache;
    if (filePath != null) {
      final file = File(filePath);
      file.writeAsStringSync(asJson(), flush: true);
    }
  }

  /// Method for CLI token creation via user inputs.
  ///
  /// - [credentials] Client credentials.
  /// - [openBrowser] Optional. Open browser to OAuth consent url automatically. (Default: `false`).
  /// - [toFile] Optional. Path to store/sync Json version of resulting token. (Default: `null`).
  static Future<RefreshingToken> promptForToken(
    OAuthCredentials credentials, {
    bool openBrowser = false,
    String? toFile,
  }) async {
    final code = await credentials.getCode();
    final url =
        '${code.toJson()['verification_url']}?user_code=${code.toJson()['user_code']}';
    if (openBrowser) {
      openUrl(url);
    }
    stdout.write(
      'Go to $url, finish the login flow and press Enter when done: ',
    );
    stdin.readLineSync();
    final rawToken = await credentials.tokenFromCode(
      code.toJson()['device_code'] as String,
    );
    final refToken = RefreshingToken(
      credentials: credentials,
      scope: DefaultScope(rawToken.scope),
      tokenType: Bearer(rawToken.tokenType),
      accessToken: rawToken.accessToken!,
      refreshToken: rawToken.refreshToken!,
      expiresAt: rawToken.expiresAt!,
      expiresIn: rawToken.expiresIn!,
    );
    refToken.update(refToken.asMap());
    if (toFile != null) refToken.localCache = toFile;
    return refToken;
  }
}
