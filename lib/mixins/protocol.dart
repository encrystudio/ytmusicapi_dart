import 'package:dio/dio.dart';
import 'package:ytmusicapi_dart/auth/types.dart';
import 'package:ytmusicapi_dart/parsers/i18n.dart';
import 'package:ytmusicapi_dart/type_alias.dart';

/// Abstract class defining the functions available to mixins.
abstract class MixinProtocol {
  /// Get the authentication type.
  AuthType get authType;

  /// Get the i18n parser.
  Parser get parser;

  /// Get the proxy configuration.
  Uri? get proxy;

  /// Check if client is authenticated.
  void checkAuth();

  /// Send a POST request to YouTube Music.
  Future<JsonMap> sendRequest(
    String endpoint,
    JsonMap body, {
    String additionalParams = '',
  });

  /// Send a GET request to YouTube Music.
  Future<Response> sendGetRequest(String url, {JsonMap? params});

  /// Set client temporary as YouTube Music Mobile app for sending request.
  Future<T> asMobile<T>(Future<T> Function() callback);

  /// Headers property for requests.
  Future<Map<String, String>> get headers;
}
