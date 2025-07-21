import 'package:ytmusicapi_dart/src/continuations.dart';
import 'package:ytmusicapi_dart/src/errors.dart';
import 'package:ytmusicapi_dart/src/parsers/parser.dart';
import 'package:dio/dio.dart';

import 'constants.dart';
import 'helpers.dart';
import 'parsers/search.dart';
import 'utils/case_insensitive_map.dart';
import 'enums.dart';
import 'navigation.dart';

class YTMusic {
  late final Map<String, dynamic> context;
  late final Dio _session;
  late final String params;
  late final Map<String, String> cookies;
  late final Parser parser;

  YTMusic({
    String? user,
    Dio? dioSession,
    Language language = Language.en,
    Location? location,
  }) {
    context = initializeContext();

    if (location != null) {
      context['context']['client']['gl'] = location.name;
    }
    context['context']['client']['hl'] = language.name;

    if (user != null) {
      context['context']['user']['onBehalfOfUser'] = user;
    }

    _session = _prepareSession(dioSession);

    params = ytmParams;

    cookies = {"SOCS": "CAI"};

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

  Future<Map<String, dynamic>> _sendRequest(
    String endpoint,
    Map<String, dynamic> body, {
    String additionalParams = '',
  }) async {
    body.addAll(context);

    _session.options.headers = (await headers).toMap();
    _session.options.headers['Cookie'] = cookies;
    final response = await _session
        .post(ytmBaseApi + endpoint + params + additionalParams, data: body)
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
    _session.options.headers['Cookie'] = cookies;
    return await _session.get(url, queryParameters: params);
  }

  String? getSearchParams(Filter? filter, Scope? scope, bool ignoreSpelling) {
    final filteredParam1 = 'EgWKAQ';
    String? params;
    var param1 = '';
    var param2 = '';
    var param3 = '';

    if (filter == null && scope == null && !ignoreSpelling) {
      return null;
    }

    if (scope == Scope.UPLOADS) {
      params = 'agIYAw%3D%3D';
    }

    if (scope == Scope.LIBRARY) {
      if (filter != null) {
        param1 = filteredParam1;
        param2 = _getParam2(filter);
        param3 = 'AWoKEAUQCRADEAoYBA%3D%3D';
      } else {
        params = 'agIYBA%3D%3D';
      }
    }

    if (scope == null && filter != null) {
      if (filter == Filter.PLAYLISTS) {
        params = 'Eg-KAQwIABAAGAAgACgB';
        if (!ignoreSpelling) {
          params += 'MABqChAEEAMQCRAFEAo%3D';
        } else {
          params += 'MABCAggBagoQBBADEAkQBRAK';
        }
      } else if (filter == Filter.COMMUNITY_PLAYLISTS ||
          filter == Filter.FEATURED_PLAYLISTS) {
        param1 = 'EgeKAQQoA';
        if (filter == Filter.FEATURED_PLAYLISTS) {
          param2 = 'Dg';
        } else {
          param2 = 'EA';
        }

        if (!ignoreSpelling) {
          param3 = 'BagwQDhAKEAMQBBAJEAU%3D';
        } else {
          param3 = 'BQgIIAWoMEA4QChADEAQQCRAF';
        }
      } else {
        param1 = filteredParam1;
        param2 = _getParam2(filter);
        if (!ignoreSpelling) {
          param3 = 'AWoMEA4QChADEAQQCRAF';
        } else {
          param3 = 'AUICCAFqDBAOEAoQAxAEEAkQBQ%3D%3D';
        }
      }
    }

    if (scope == null && filter == null && ignoreSpelling) {
      params = 'EhGKAQ4IARABGAEgASgAOAFAAUICCAE%3D';
    }

    return params ?? (param1 + param2 + param3);
  }

  String _getParam2(Filter filter) {
    switch (filter) {
      case Filter.SONGS:
        return 'II';
      case Filter.VIDEOS:
        return 'IQ';
      case Filter.ALBUMS:
        return 'IY';
      case Filter.ARTISTS:
        return 'Ig';
      case Filter.PLAYLISTS:
        return 'Io';
      case Filter.PROFILES:
        return 'JY';
      case Filter.PODCASTS:
        return 'JQ';
      case Filter.EPISODES:
        return 'JI';
      default:
        throw UnsupportedError('Filter not supported $filter');
    }
  }

  Future<List> search(
    String query, {
    Filter? filter,
    Scope? scope,
    int limit = 20,
    bool ignoreSpelling = false,
  }) async {
    if (scope == Scope.UPLOADS && filter != null) {
      throw YTMusicUserError(
        'No filter can be set when searching uploads. Please unset the filter parameter when scope is set to uploads.',
      );
    }

    if (scope == Scope.LIBRARY &&
        (filter == Filter.COMMUNITY_PLAYLISTS ||
            filter == Filter.FEATURED_PLAYLISTS)) {
      throw YTMusicUserError(
        '$filter cannot be set when searching library. Please use one of the following filters or leave out the parameter: ALBUMS, ARTISTS, PLAYLISTS, SONGS, VIDEOS, PROFILES, PODCASTS, EPISODES',
      );
    }

    final Map<String, dynamic> body = {'query': query};
    final endpoint = 'search';
    var searchResults = [];

    var params = getSearchParams(filter, scope, ignoreSpelling);

    if (params != null) {
      body['params'] = params;
    }

    final response = await _sendRequest(endpoint, body);

    if (!response.containsKey('contents')) {
      return searchResults;
    }

    var tabIndex = 0;
    Map<String, dynamic> results;

    if (response['contents'].containsKey('tabbedSearchResultsRenderer')) {
      tabIndex =
          (scope == null || filter != null)
              ? 0
              : (scope == Scope.LIBRARY ? 1 : 2);
      results =
          response['contents']['tabbedSearchResultsRenderer']['tabs'][tabIndex]['tabRenderer']['content'];
    } else {
      results = response['contents'];
    }

    List<dynamic> sectionList = nav(results, sectionListContent)!;

    if (sectionList.length == 1 &&
        sectionList.contains('itemSectionRenderer')) {
      return searchResults;
    }

    dynamic resultType;
    var filterForParser = (filter != null) ? filter.name : '';
    if (filterForParser.toLowerCase().contains('playlists')) {
      filterForParser = 'playlists';
    } else if (scope == Scope.UPLOADS) {
      filterForParser = 'uploads';
      resultType = 'upload';
    }

    for (var res in sectionList) {
      dynamic category;
      List<dynamic>? shelfContents;

      if (res.containsKey('musicCardShelfRenderer')) {
        var topResult = parseTopResult(
          res['musicCardShelfRenderer'],
          parser.getSearchResultTypes(),
        );
        searchResults.add(topResult);
        shelfContents = nav(res, [
          "musicCardShelfRenderer",
          "contents",
        ], nullIfAbsent: true);
        if (shelfContents == null) {
          continue;
        }
        if (shelfContents[0].containsKey('messageRenderer')) {
          category = nav(shelfContents.removeAt(0), [
            'messageRenderer',
            titleRunText,
          ]);
        }
      } else if (res.containsKey('musicShelfRenderer')) {
        shelfContents = res['musicShelfRenderer']['contents'];
        category = nav(res, musicShelf + titleText, nullIfAbsent: true);

        if (filterForParser.isNotEmpty && scope != Scope.UPLOADS) {
          resultType =
              filterForParser
                  .substring(0, filterForParser.length - 1)
                  .toLowerCase();
        }
      } else {
        continue;
      }

      var apiSearchResultTypes = parser.getApiResultTypes();

      searchResults.addAll(
        parseSearchResults(
          shelfContents!,
          apiSearchResultTypes,
          resultType,
          category,
        ),
      );

      if (filter != null) {
        requestFunc(String additionalParams) {
          return _sendRequest(
            endpoint,
            body,
            additionalParams: additionalParams,
          );
        }

        parseFunc(List<dynamic> contents) {
          return parseSearchResults(
            contents,
            apiSearchResultTypes,
            resultType,
            category,
          );
        }

        searchResults.addAll(
          await getContinuations(
            res['musicShelfRenderer'],
            'musicShelfContinuation',
            limit - searchResults.length,
            requestFunc,
            parseFunc,
          ),
        );
      }
    }
    return searchResults;
  }
}
