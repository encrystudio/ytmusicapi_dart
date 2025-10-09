/// OAuth client request failure.
///
/// Ensure provided `client_id` and `client_secret` are correct and YouTubeData API is enabled.
class BadOAuthClient implements Exception {
  /// Exception message.
  final String message;

  /// Create new [BadOAuthClient].
  BadOAuthClient([this.message = 'Bad OAuth client.']);

  @override
  String toString() => 'BadOAuthClient: $message';
}

/// OAuth client lacks permissions for specified token.
///
/// Token can only be refreshed by OAuth credentials used for its creation.
class UnauthorizedOAuthClient implements Exception {
  /// Exception message.
  final String message;

  /// Create new [UnauthorizedOAuthClient].
  UnauthorizedOAuthClient([this.message = 'Unauthorized OAuth client.']);

  @override
  String toString() => 'UnauthorizedOAuthClient: $message';
}
