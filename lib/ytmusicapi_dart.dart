import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:ytmusicapi_dart/auth/auth_parse.dart';
import 'package:ytmusicapi_dart/auth/oauth/credentials.dart';
import 'package:ytmusicapi_dart/auth/oauth/models.dart';
import 'package:ytmusicapi_dart/auth/oauth/token.dart';
import 'package:ytmusicapi_dart/auth/types.dart';
import 'package:ytmusicapi_dart/constants.dart';
import 'package:ytmusicapi_dart/exceptions.dart';
import 'package:ytmusicapi_dart/helpers.dart';
import 'package:ytmusicapi_dart/mixins/browsing.dart';
import 'package:ytmusicapi_dart/mixins/charts.dart';
import 'package:ytmusicapi_dart/mixins/explore.dart';
import 'package:ytmusicapi_dart/mixins/playlists.dart';
import 'package:ytmusicapi_dart/mixins/podcasts.dart';
import 'package:ytmusicapi_dart/mixins/protocol.dart';
import 'package:ytmusicapi_dart/mixins/search.dart';
import 'package:ytmusicapi_dart/mixins/watch.dart';
import 'package:ytmusicapi_dart/parsers/i18n.dart';
import 'package:ytmusicapi_dart/type_alias.dart';

/// The main class to access the YouTube Music API.
class YTMusicBase implements MixinProtocol {
  late Dio _session;
  @override
  Uri? proxy;
  final JsonMap _cookies = {'SOCS': 'CAI'};
  String? _visitorId;
  DateTime? _timeLastVisitorId;

  Map<String, String> _authHeaders = {};
  @override
  AuthType authType = AuthType.unauthorized;
  final Token? _token;

  late final JsonMap _context;
  late final String _language;
  @override
  late Parser parser;
  final String? _sapisid;
  final String? _origin;
  late final String _params;

  YTMusicBase._internal({
    required Dio session,
    required this.proxy,
    required String language,
    required Map<String, dynamic> context,
    required this.parser,
    required String params,
    required this.authType,
    String? sapisid,
    String? origin,
    Token? token,
    Map<String, String>? authHeaders,
  }) : _params = params,
       _origin = origin,
       _sapisid = sapisid,
       _language = language,
       _context = context,
       _token = token {
    _session = session;
    _authHeaders = authHeaders ?? {};
  }

  static Future<YTMusicBase> _create({
    dynamic auth,
    String? user,
    Dio? requestsSession,
    Uri? proxy,
    String language = 'en',
    String location = '',
    OAuthCredentials? oauthCredentials,
  }) async {
    final session = _prepareSession(requestsSession, proxy);

    initializeDateFormatting();

    Map<String, String> authHeaders = {};
    AuthType authType = AuthType.unauthorized;
    Token? token;

    if (auth != null) {
      final result = await parseAuthStr(auth);
      authHeaders = result.item1;
      final authPath = result.item2;
      authType = determineAuthType(authHeaders);

      if (authType == AuthType.oauthCustomClient) {
        if (oauthCredentials == null) {
          throw YTMusicUserError(
            'oauth JSON provided via auth argument, but oauthCredentials not provided.',
          );
        }
        token = RefreshingToken(
          credentials: oauthCredentials,
          localCache: authPath,

          scope: DefaultScope(authHeaders['scope']),
          tokenType: Bearer(authHeaders['token_type']),
          accessToken: authHeaders['access_token']!,
          refreshToken: authHeaders['refresh_token']!,
          expiresAt: int.parse(authHeaders['expires_at']!),
          expiresIn: int.parse(authHeaders['expires_in']!),
        );
      }
    }

    final context = initializeContext();

    if (location.isNotEmpty) {
      if (!SUPPORTED_LOCATIONS.contains(location)) {
        throw YTMusicUserError(
          'Location not supported. Check the FAQ for supported locations.',
        );
      }
      ((context['context'] as JsonMap)['client'] as JsonMap)['gl'] = location;
    }

    if (!SUPPORTED_LANGUAGES.contains(language)) {
      throw YTMusicUserError(
        "Language not supported. Supported languages are ${SUPPORTED_LANGUAGES.join(", ")}.",
      );
    }
    ((context['context'] as JsonMap)['client'] as JsonMap)['hl'] = language;

    // Locale setup (fallback to en_US)
    try {
      Intl.defaultLocale = language;
    } catch (_) {
      Intl.defaultLocale = 'en_US';
    }

    final parser = Parser(language);

    if (user != null) {
      ((context['context'] as JsonMap)['user'] as JsonMap)['onBehalfOfUser'] =
          user;
    }

    var params = YTM_PARAMS;
    String? sapisid;
    String? origin;
    if (authType == AuthType.browser) {
      params += YTM_PARAMS_KEY;
      if (!authHeaders.containsKey('cookie')) {
        throw YTMusicUserError(
          'Your cookie is missing the required value __Secure-3PAPISID',
        );
      }
      final cookie = authHeaders['cookie']!;
      sapisid = sapisidFromCookie(cookie);
      origin = authHeaders['origin'] ?? authHeaders['x-origin'];
    }

    return YTMusicBase._internal(
      session: session,
      proxy: proxy,
      language: language,
      context: context,
      parser: parser,
      params: params,
      sapisid: sapisid,
      origin: origin,
      authHeaders: authHeaders,
      token: token,
      authType: authType,
    );
  }

  static Dio _prepareSession(Dio? requestsSession, Uri? proxy) {
    if (requestsSession != null) return requestsSession;
    return Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          followRedirects: true,
          validateStatus: (status) {
            if (status == null) return false;

            switch (status.toString()[0]) {
              case '2':
                return true;
              case '3':
                return status == 302;
              default:
                return false;
            }
          },
        ),
      )
      ..httpClientAdapter = Http2Adapter(
        ConnectionManager(
          idleTimeout: const Duration(seconds: 30),
          onClientCreate: (_, config) {
            config.onBadCertificate = (_) => true;
            config.proxy = proxy;
          },
        ),
      );
  }

  Future<Map<String, String>> get _baseHeaders async {
    final headers =
        (authType == AuthType.browser || authType == AuthType.oauthCustomFull)
            ? _authHeaders
            : initializeHeaders();

    if (!headers.containsKey('X-Goog-Visitor-Id')) {
      if (_visitorId == null ||
          _timeLastVisitorId == null ||
          _timeLastVisitorId!.difference(DateTime.now()).inSeconds > 60) {
        final visitorHeaders = await getVisitorId(
          (url) => sendGetRequest(url, useBaseHeaders: true),
        );
        if (visitorHeaders['X-Goog-Visitor-Id'] != '') {
          _visitorId = visitorHeaders['X-Goog-Visitor-Id'];
          _timeLastVisitorId = DateTime.now();
        }
      }
    }
    headers.addAll({'X-Goog-Visitor-Id': _visitorId!});
    return headers;
  }

  @override
  Future<Map<String, String>> get headers async {
    final headers = Map<String, String>.from(await _baseHeaders);

    if (authType == AuthType.browser) {
      headers['authorization'] = getAuthorization('$_sapisid $_origin');
    } else if (authType == AuthType.oauthCustomClient) {
      headers['authorization'] = _token != null ? _token.asAuth() : '';
      headers['X-Goog-Request-Time'] = DateTime.now().millisecondsSinceEpoch
          .toString()
          .substring(0, 10);
    }
    return headers;
  }

  @override
  Future<JsonMap> sendRequest(
    String endpoint,
    JsonMap body, {
    String additionalParams = '',
  }) async {
    body.addAll(_context);
    final fullHeaders = JsonMap.from(await headers);
    fullHeaders['Cookie'] = _cookies;

    final response = await _session.post(
      '$YTM_BASE_API$endpoint$_params$additionalParams',
      data: body,
      options: Options(headers: fullHeaders, responseType: ResponseType.bytes),
    );
    final String responseBody;
    if ((response.data! as List)[0] == 0x1F &&
        (response.data! as List)[1] == 0x8B) {
      // decompress gzip
      final List<int> decompressed = GZipCodec().decode(
        response.data! as List<int>,
      );
      responseBody = utf8.decode(decompressed);
    } else {
      // treat as normal UTF-8 text
      responseBody = utf8.decode(response.data! as List<int>);
    }
    response.data = responseBody;

    final responseText =
        response.data.runtimeType == String
            ? jsonDecode(response.data as String)
            : response.data;
    if (response.statusCode != null && response.statusCode! >= 400) {
      final message =
          'Server returned HTTP ${response.statusCode}: ${response.statusMessage}.\n';
      final error = ((responseText as JsonMap)['error'] as JsonMap)['message'];
      throw YTMusicServerError('$message$error');
    }
    return responseText as JsonMap;
  }

  @override
  Future<Response> sendGetRequest(
    String url, {
    JsonMap? params,
    bool useBaseHeaders = false,
  }) async {
    final fullHeaders = JsonMap.from(
      useBaseHeaders ? initializeHeaders() : await headers,
    );
    fullHeaders['Cookie'] = _cookies;

    final response = await _session.get(
      url,
      queryParameters: params,
      options: Options(headers: fullHeaders, responseType: ResponseType.bytes),
    );

    final String body;
    if ((response.data! as List)[0] == 0x1F &&
        (response.data! as List)[1] == 0x8B) {
      final List<int> decompressed = GZipCodec().decode(
        response.data! as List<int>,
      );
      body = utf8.decode(decompressed);
    } else {
      body = utf8.decode(response.data! as List<int>);
    }
    response.data = body;

    return response;
  }

  /// Checks if the user has provided authorization credentials.
  ///
  /// Raises [YTMusicUserError] if the user is not authorized.
  @override
  void checkAuth() {
    if (authType == AuthType.unauthorized) {
      throw YTMusicUserError(
        'Please provide authentication before using this function',
      );
    }
  }

  @override
  Future<T> asMobile<T>(Future<T> Function() callback) async {
    final cName =
        ((_context['context'] as JsonMap)['client'] as JsonMap)['clientName'];
    final cVersion =
        ((_context['context'] as JsonMap)['client']
            as JsonMap)['clientVersion'];
    ((_context['context'] as JsonMap)['client'] as JsonMap)['clientName'] =
        'ANDROID_MUSIC';
    ((_context['context'] as JsonMap)['client'] as JsonMap)['clientVersion'] =
        '7.21.50';
    final result = await callback();
    ((_context['context'] as JsonMap)['client'] as JsonMap)['clientName'] =
        cName;
    ((_context['context'] as JsonMap)['client'] as JsonMap)['clientVersion'] =
        cVersion;
    return result;
  }

  /// Closes the session.
  void close({bool force = true}) {
    _session.close(force: force);
  }
}

/// Allows automated interactions with YouTube Music by emulating the YouTube web client's requests.
///
/// Permits both authenticated and non-authenticated requests.
/// Authentication header data must be provided on initialization.
class YTMusic extends YTMusicBase
    with
        BrowsingMixin,
        SearchMixin,
        WatchMixin,
        ChartsMixin,
        ExploreMixin,
        PlaylistsMixin,
        PodcastsMixin
// LibraryMixin, // TODO add when implemented
// UploadsMixin  // TODO add when implemented
{
  YTMusic._internal({
    required super.session,
    super.proxy,
    required super.language,
    required super.context,
    required super.parser,
    required super.params,
    required super.token,
    required super.authType,
    super.sapisid,
    super.origin,
    super.authHeaders,
  }) : super._internal();

  /// Create a new instance to interact with YouTube Music.
  ///
  /// - [auth] Optional. Provide a String, path to file, or oauth token Map.
  ///                    Authentication credentials are needed to manage your library.
  ///                    (Default: A default header is used without authentication).
  /// - [user] Optional. Specify a user ID string to use in requests.
  ///                    This is needed if you want to send requests on behalf of a brand account.
  ///                    Otherwise the default account is used.
  /// - [requestsSession] A [Dio] session object or `null` to create one.
  ///                     Default sessions have a request timeout of 30s.
  /// - [proxy] Optional. Proxy configuration.
  /// - [language] Optional. Can be used to change the language of returned data.
  /// - [location] Optional. Can be used to change the location of the user.
  /// - [oauthCredentials] Optional. Used to specify a different oauth client.
  static Future<YTMusic> create({
    dynamic auth,
    String? user,
    Dio? requestsSession,
    Uri? proxy,
    String language = 'en',
    String location = '',
    OAuthCredentials? oauthCredentials,
  }) async {
    final base = await YTMusicBase._create(
      auth: auth,
      user: user,
      requestsSession: requestsSession,
      proxy: proxy,
      language: language,
      location: location,
      oauthCredentials: oauthCredentials,
    );

    return YTMusic._internal(
      session: base._session,
      proxy: base.proxy,
      language: base._language,
      context: base._context,
      parser: base.parser,
      params: base._params,
      sapisid: base._sapisid,
      origin: base._origin,
      authHeaders: base._authHeaders,
      token: base._token,
      authType: base.authType,
    );
  }
}
