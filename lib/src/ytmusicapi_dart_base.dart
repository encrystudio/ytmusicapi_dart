import 'package:ytmusicapi_dart/src/errors.dart';
import 'package:ytmusicapi_dart/src/mixins/search.dart';
import 'package:ytmusicapi_dart/src/parsers/parser.dart';
import 'package:dio/dio.dart';

import 'constants.dart';
import 'helpers.dart';
import 'utils/case_insensitive_map.dart';
import 'enums.dart';

class YTMusic {
  late final Map<String, dynamic> _context;
  late final Dio _session;
  late final String _params;
  late final Map<String, String> _cookies;
  late final Parser parser;

  late final SearchMixin _searchMixin;

  YTMusic({
    String? user,
    Dio? dioSession,
    Language language = Language.en,
    Location? location,
  }) {
    _context = initializeContext();

    if (location != null) {
      _context['context']['client']['gl'] = location.name;
    }
    _context['context']['client']['hl'] = language.name;

    if (user != null) {
      _context['context']['user']['onBehalfOfUser'] = user;
    }

    _session = _prepareSession(dioSession);

    _params = ytmParams;

    _cookies = {"SOCS": "CAI"};

    _searchMixin = SearchMixin(this);

    parser = Parser();
  }

  Dio _prepareSession(Dio? dioSession) {
    if (dioSession != null) {
      return dioSession;
    } else {
      final session = Dio(
        BaseOptions(
          sendTimeout: Duration(seconds: 30),
          connectTimeout: Duration(seconds: 30),
          receiveTimeout: Duration(seconds: 30),
        ),
      );
      return session;
    }
  }

  Future<CaseInsensitiveMap<String>> get headers async {
    final headers = baseHeaders;

    return await headers;
  }

  Future<CaseInsensitiveMap<String>> get baseHeaders async {
    final headers = initializeHeaders();

    if (!headers.containsKey('X-Goog-Visitor-Id')) {
      headers['X-Goog-Visitor-Id'] = await getVisitorId(_sendGetRequest);
    }

    return headers;
  }

  Future<Map<String, dynamic>> sendRequest(
    String endpoint,
    Map<String, dynamic> body, {
    String additionalParams = '',
  }) async {
    body.addAll(_context);

    _session.options.headers = (await headers).toMap();
    _session.options.headers['Cookie'] = _cookies;
    final response = await _session
        .post(ytmBaseApi + endpoint + _params + additionalParams, data: body)
        .timeout(Duration(seconds: 30));

    final responseText = response.data;

    if (response.statusCode! >= 400) {
      throw YTMusicServerError(
        'Server returned HTTP ${response.statusCode}: ${response.statusMessage}. ${(responseText['error'] ?? {})['message']}',
      );
    }
    return responseText;
  }

  Future<Response> _sendGetRequest(
    String url,
    Map<String, dynamic>? params, {
    bool useBaseHeaders = false,
  }) async {
    _session.options.headers =
        useBaseHeaders ? initializeHeaders().toMap() : (await headers).toMap();
    _session.options.headers['Cookie'] = _cookies;
    return await _session.get(url, queryParameters: params);
  }

  Future<List> search(
    String query, {
    Filter? filter,
    Scope? scope,
    int limit = 20,
    bool ignoreSpelling = false,
  }) async {
    return _searchMixin.search(
      query,
      filter: filter,
      scope: scope,
      limit: limit,
      ignoreSpelling: ignoreSpelling,
    );
  }
}
