import 'package:ytmusicapi_dart/type_alias.dart';

/// Authentication scope.
class DefaultScope {
  /// Url to authentication.
  final String value;

  /// Create new [DefaultScope] using [scope].
  DefaultScope(String? scope)
    : value = scope ?? 'https://www.googleapis.com/auth/youtube';
}

/// Literal `Bearer`.
class Bearer {
  /// Literal `Bearer`.
  final String value;

  /// Literal `Bearer`.
  Bearer(String? scope) : value = scope ?? 'Bearer';
}

/// Limited token. Does not provide a refresh token. Commonly obtained via a token refresh.
class BaseTokenMap {
  /// String to be used in authorization header.
  final String? accessToken;

  /// Seconds until expiration from request timestamp.
  final int? expiresIn;

  /// Should be 'https://www.googleapis.com/auth/youtube'.
  final String? scope;

  /// Should be 'Bearer'.
  final String? tokenType;

  /// Create new [BaseTokenMap].
  BaseTokenMap({this.accessToken, this.expiresIn, this.scope, this.tokenType});

  /// Create new [BaseTokenMap] from a [JsonMap].
  factory BaseTokenMap.fromJson(JsonMap json) => BaseTokenMap(
    accessToken: json['access_token'] as String?,
    expiresIn: json['expires_in'] as int?,
    scope: json['scope'] as String?,
    tokenType: json['token_type'] as String?,
  );

  /// Returns this [BaseTokenMap] instance as [JsonMap].
  JsonMap toJson() => {
    if (accessToken != null) 'access_token': accessToken,
    if (expiresIn != null) 'expires_in': expiresIn,
    if (scope != null) 'scope': scope,
    if (tokenType != null) 'token_type': tokenType,
  };
}

/// Entire token. Including refresh. Obtained through token setup.
class RefreshableTokenMap extends BaseTokenMap {
  /// UNIX epoch timestamp in seconds.
  final int? expiresAt;

  /// String used to obtain new access token upon expiration.
  final String? refreshToken;

  /// Create new [RefreshableTokenMap].
  RefreshableTokenMap({
    super.accessToken,
    super.expiresIn,
    super.scope,
    super.tokenType,
    this.expiresAt,
    this.refreshToken,
  });

  /// Create new [RefreshableTokenMap] from a [JsonMap].
  factory RefreshableTokenMap.fromJson(JsonMap json) => RefreshableTokenMap(
    accessToken: json['access_token'] as String?,
    expiresIn: json['expires_in'] as int?,
    scope: json['scope'] as String?,
    tokenType: json['token_type'] as String?,
    expiresAt: json['expires_at'] as int?,
    refreshToken: json['refresh_token'] as String?,
  );

  /// Returns this [RefreshableTokenMap] instance as [JsonMap].
  @override
  JsonMap toJson() => {
    ...super.toJson(),
    if (expiresAt != null) 'expires_at': expiresAt,
    if (refreshToken != null) 'refresh_token': refreshToken,
  };
}

/// Keys for the Json object obtained via code response during auth flow.
class AuthCodeMap {
  /// Code obtained via user confirmation and OAuth consent.
  final String? deviceCode;

  /// Alphanumeric code user is prompted to enter as confirmation. Formatted as XXX-XXX-XXX.
  final String? userCode;

  /// Seconds from original request timestamp.
  final int? expiresIn;

  /// (?) "5" (?)
  final int? interval;

  /// Base URL for OAuth consent screen for user signin/confirmation.
  final String? verificationUrl;

  /// Create new [AuthCodeMap].
  AuthCodeMap({
    this.deviceCode,
    this.userCode,
    this.expiresIn,
    this.interval,
    this.verificationUrl,
  });

  /// Create new [AuthCodeMap] from a [JsonMap].
  factory AuthCodeMap.fromJson(JsonMap json) => AuthCodeMap(
    deviceCode: json['device_code'] as String?,
    userCode: json['user_code'] as String?,
    expiresIn: json['expires_in'] as int?,
    interval: json['interval'] as int?,
    verificationUrl: json['verification_url'] as String?,
  );

  /// Returns this [AuthCodeMap] instance as [JsonMap].
  JsonMap toJson() => {
    if (deviceCode != null) 'device_code': deviceCode,
    if (userCode != null) 'user_code': userCode,
    if (expiresIn != null) 'expires_in': expiresIn,
    if (interval != null) 'interval': interval,
    if (verificationUrl != null) 'verification_url': verificationUrl,
  };
}
