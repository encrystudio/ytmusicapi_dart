import 'dart:convert';
import 'dart:io';

import 'package:ytmusicapi_dart/auth/oauth/token.dart';
import 'package:ytmusicapi_dart/auth/types.dart';
import 'package:ytmusicapi_dart/exceptions.dart';
import 'package:ytmusicapi_dart/type_alias.dart';
import 'package:ytmusicapi_dart/utils.dart';

/// Returns parsed header Map based on [auth], optionally path to file if [auth] was a path to a file.
///
/// - [auth] user-provided auth String or Map.
Future<Tuple2<Map<String, String>, String?>> parseAuthStr(dynamic auth) async {
  String? authPath;
  Map<String, String> headers;

  if (auth is String) {
    if (auth.startsWith('{')) {
      final inputJson = jsonDecode(auth) as JsonMap;
      headers = inputJson.map((k, v) => MapEntry(k, v.toString()));
    } else if (File(auth).existsSync()) {
      authPath = auth;
      final inputJson = jsonDecode(File(auth).readAsStringSync()) as JsonMap;
      headers = inputJson.map((k, v) => MapEntry(k, v.toString()));
    } else {
      throw YTMusicUserError('Invalid auth JSON string or file path provided.');
    }
  } else if (auth is JsonMap) {
    headers = auth.map((k, v) => MapEntry(k, v.toString()));
  } else {
    throw YTMusicUserError('Invalid auth type provided.');
  }

  return Tuple2(headers, authPath);
}

/// Determine the type of auth based on [authHeaders].
///
/// - [authHeaders] auth headers Map.
///
/// Returns [AuthType] enum.
AuthType determineAuthType(Map<String, String> authHeaders) {
  var authType = AuthType.oauthCustomClient;

  if (OAuthToken.isOAuth(authHeaders)) {
    authType = AuthType.oauthCustomClient;
  }

  if (authHeaders.containsKey('authorization')) {
    final authorization = authHeaders['authorization']!;
    if (authorization.contains('SAPISIDHASH')) {
      authType = AuthType.browser;
    } else if (authorization.startsWith('Bearer')) {
      authType = AuthType.oauthCustomFull;
    }
  }
  return authType;
}
