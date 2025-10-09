/// Enum representing types of authentication supported by this library.
enum AuthType {
  /// No authentication.
  unauthorized,

  /// Browser-based authentication.
  browser,

  /// YTM instance is using a non-default OAuth client (id & secret).
  oauthCustomClient,

  /// Allows fully formed OAuth headers to ignore browser auth refresh flow.
  oauthCustomFull,
}
