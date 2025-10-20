import 'package:ytmusicapi_dart/continuations.dart';
import 'package:ytmusicapi_dart/enums.dart';
import 'package:ytmusicapi_dart/exceptions.dart';
import 'package:ytmusicapi_dart/mixins/protocol.dart';
import 'package:ytmusicapi_dart/navigation.dart';
import 'package:ytmusicapi_dart/parsers/search.dart';
import 'package:ytmusicapi_dart/type_alias.dart';

/// Mixin for search functionalities.
mixin SearchMixin on MixinProtocol {
  /// Search YouTube music.
  ///
  /// Returns results within the provided category.
  ///
  /// - [query] Query string, i.e. 'Oasis Wonderwall'.
  /// - [filter] Filter for item types.
  ///            (Default: Default search, including all types of items).
  /// - [scope] Search scope. Allowed values: `library`, `uploads`.
  ///           (Default: Search the public YouTube Music catalogue).
  ///           Changing scope from the default will reduce the number of settable filters.
  ///           Setting a filter that is not permitted will throw an exception.
  ///           For `uploads`, no filter can be set.
  ///           For `library`, `community_playlists` and `featured_playlists` filter cannot be set.
  /// - [limit] Number of search results to return. (Default: `20`).
  /// - [ignoreSpelling] Whether to ignore YTM spelling suggestions.
  ///                    If `true`, the exact search term will be searched for,
  ///                    and will not be corrected.
  ///                    This does not have any effect when the filter is set to `uploads`.
  ///                    (Default: `false`, will use YTM's default behavior of autocorrecting the search.
  ///
  /// Returns List of results depending on filter.
  ///
  /// - `resultType` specifies the type of item (important for default search).
  ///   Albums, artists and playlists additionally contain a `browseId`, corresponding to
  ///   `albumId`, `channelId` and `playlistId` (`browseId`=`VL`+`playlistId`).
  ///
  /// Example list for default search with one result per `resultType` for brevity.
  /// Normally there are 3 results per `resultType` and an additional `thumbnails` key:
  /// ```json
  /// [
  ///   {
  ///     "category": "Top result",
  ///     "resultType": "video",
  ///     "videoId": "vU05Eksc_iM",
  ///     "title": "Wonderwall",
  ///     "artists": [
  ///       {
  ///         "name": "Oasis",
  ///         "id": "UCmMUZbaYdNH0bEd1PAlAqsA"
  ///       }
  ///     ],
  ///     "views": "1.4M",
  ///     "videoType": "MUSIC_VIDEO_TYPE_OMV",
  ///     "duration": "4:38",
  ///     "duration_seconds": 278
  ///   },
  ///   {
  ///     "category": "Songs",
  ///     "resultType": "song",
  ///     "videoId": "ZrOKjDZOtkA",
  ///     "title": "Wonderwall",
  ///     "artists": [
  ///       {
  ///         "name": "Oasis",
  ///         "id": "UCmMUZbaYdNH0bEd1PAlAqsA"
  ///       }
  ///     ],
  ///     "album": {
  ///       "name": "(What's The Story) Morning Glory? (Remastered)",
  ///       "id": "MPREb_9nqEki4ZDpp"
  ///     },
  ///     "duration": "4:19",
  ///     "duration_seconds": 259,
  ///     "isExplicit": false,
  ///     "feedbackTokens": {
  ///       "add": null,
  ///       "remove": null
  ///     }
  ///   },
  ///   {
  ///     "category": "Albums",
  ///     "resultType": "album",
  ///     "browseId": "MPREb_IInSY5QXXrW",
  ///     "playlistId": "OLAK5uy_kunInnOpcKECWIBQGB0Qj6ZjquxDvfckg",
  ///     "title": "(What's The Story) Morning Glory?",
  ///     "type": "Album",
  ///     "artist": "Oasis",
  ///     "year": "1995",
  ///     "isExplicit": false
  ///   },
  ///   {
  ///     "category": "Community playlists",
  ///     "resultType": "playlist",
  ///     "browseId": "VLPLK1PkWQlWtnNfovRdGWpKffO1Wdi2kvDx",
  ///     "title": "Wonderwall - Oasis",
  ///     "author": "Tate Henderson",
  ///     "itemCount": "174"
  ///   },
  ///   {
  ///     "category": "Videos",
  ///     "resultType": "video",
  ///     "videoId": "bx1Bh8ZvH84",
  ///     "title": "Wonderwall",
  ///     "artists": [
  ///       {
  ///         "name": "Oasis",
  ///         "id": "UCmMUZbaYdNH0bEd1PAlAqsA"
  ///       }
  ///     ],
  ///     "views": "386M",
  ///     "duration": "4:38",
  ///     "duration_seconds": 278
  ///   },
  ///   {
  ///     "category": "Artists",
  ///     "resultType": "artist",
  ///     "browseId": "UCmMUZbaYdNH0bEd1PAlAqsA",
  ///     "artist": "Oasis",
  ///     "shuffleId": "RDAOkjHYJjL1a3xspEyVkhHAsg",
  ///     "radioId": "RDEMkjHYJjL1a3xspEyVkhHAsg"
  ///   },
  ///   {
  ///     "category": "Profiles",
  ///     "resultType": "profile",
  ///     "title": "Taylor Swift Time",
  ///     "name": "@TaylorSwiftTime",
  ///     "browseId": "UCSCRK7XlVQ6fBdEl00kX6pQ",
  ///     "thumbnails": ...
  ///   }
  /// ]
  /// ```
  Future<List> search(
    String query, {
    SearchFilter? filter,
    String? scope,
    int limit = 20,
    bool ignoreSpelling = false,
  }) async {
    final body = <String, dynamic>{'query': query};
    const endpoint = 'search';
    final searchResults = <dynamic>[];

    const filters = [
      'albums',
      'artists',
      'playlists',
      'community_playlists',
      'featured_playlists',
      'songs',
      'videos',
      'profiles',
      'podcasts',
      'episodes',
    ];

    const scopes = ['library', 'uploads'];
    if (scope != null && !scopes.contains(scope)) {
      throw YTMusicUserError(
        'Invalid scope provided. Please use one of the following scopes or leave out the parameter: '
        '${scopes.join(', ')}',
      );
    }

    if (scope == 'uploads' && filter != null) {
      throw YTMusicUserError(
        'No filter can be set when searching uploads. Please unset the filter parameter when scope is set to uploads.',
      );
    }

    if (scope == 'library' &&
        filter != null &&
        (filter == SearchFilter.community_playlists ||
            filter == SearchFilter.featured_playlists)) {
      throw YTMusicUserError(
        '$filter cannot be set when searching library. Please use one of the following filters or leave out the parameter: '
        '${filters.sublist(0, 3).followedBy(filters.sublist(5)).join(', ')}',
      );
    }

    final params = getSearchParams(filter, scope, ignoreSpelling);
    if (params != null) {
      body['params'] = params;
    }

    final response = await sendRequest(endpoint, body);

    // no results
    if (!response.containsKey('contents')) return searchResults;

    dynamic results;
    if ((response['contents'] as JsonMap).containsKey(
      'tabbedSearchResultsRenderer',
    )) {
      final tabIndex =
          (scope == null || filter == null) ? 0 : scopes.indexOf(scope) + 1;
      results =
          (((((response['contents'] as JsonMap)['tabbedSearchResultsRenderer']
                          as JsonMap)['tabs']
                      as List)[tabIndex]
                  as JsonMap)['tabRenderer']
              as JsonMap)['content'];
    } else {
      results = response['contents'];
    }

    final sectionList = List<JsonMap>.from(nav(results, SECTION_LIST) as List);

    // no results
    if (sectionList.length == 1 &&
        sectionList.first.containsKey('itemSectionRenderer')) {
      return searchResults;
    }

    // set filter for parser
    String? resultType;
    final SearchFilter? realFilter;
    if (filter != null &&
        (filter == SearchFilter.playlists ||
            filter == SearchFilter.featured_playlists ||
            filter == SearchFilter.community_playlists)) {
      realFilter = SearchFilter.playlists;
    } else if (scope == 'uploads') {
      realFilter = SearchFilter.uploads;
      resultType = 'upload';
    } else {
      realFilter = filter;
    }

    for (final res in sectionList) {
      String? category;
      List<JsonMap> shelfContents;

      if (res.containsKey('musicCardShelfRenderer')) {
        final topResult = parseTopResult(
          res['musicCardShelfRenderer'] as JsonMap,
          parser.getSearchResultTypes(),
        );
        searchResults.add(topResult);

        shelfContents = List<JsonMap>.from(
          (nav(res, [
                    'musicCardShelfRenderer',
                    'contents',
                  ], nullIfAbsent: true) ??
                  [])
              as List,
        );
        if (shelfContents.isEmpty) continue;

        // if "more from youtube" is present, remove it - it's not parseable
        if (shelfContents.first.containsKey('messageRenderer')) {
          category =
              nav(shelfContents.removeAt(0), [
                    'messageRenderer',
                    ...TEXT_RUN_TEXT,
                  ])
                  as String?;
        }
      } else if (res.containsKey('musicShelfRenderer')) {
        shelfContents = List<JsonMap>.from(
          (res['musicShelfRenderer'] as JsonMap)['contents'] as List,
        );
        category =
            nav(res, MUSIC_SHELF + TITLE_TEXT, nullIfAbsent: true) as String?;

        // if we know the filter it's easy to set the result type
        // unfortunately uploads is modeled as a filter (historical reasons),
        // so we take care to not set the result type for that scope
        if (realFilter != null && scope != 'uploads') {
          resultType =
              realFilter.name
                  .substring(0, realFilter.name.length - 1)
                  .toLowerCase();
        }
      } else {
        continue;
      }

      searchResults.addAll(
        parseSearchResults(
          shelfContents,
          resultType: resultType,
          category: category,
        ),
      );

      if (realFilter != null) {
        // if filter is set, there are continuations
        Future<JsonMap> requestFunc(dynamic additionalParams) => sendRequest(
          endpoint,
          body,
          additionalParams: additionalParams as String,
        );
        List parseFunc(contents) => parseSearchResults(
          List<JsonMap>.from(contents as List),
          resultType: resultType,
          category: category,
        );

        searchResults.addAll(
          await getContinuations(
            res['musicShelfRenderer'] as JsonMap,
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

  /// Get search suggestions.
  ///
  /// - [query] Query string, i.e. 'faded'.
  /// - [detailedRuns] Whether to return detailed runs of each suggestion.
  ///                  If `true`, it returns the query that the user typed and
  ///                  the remaining suggestion along with the complete text
  ///                  (like many search services usually bold the text typed by the user).
  ///                  Default: `false`, returns the list of search suggestions in plain text.
  ///
  /// Returns a list of search suggestions. If [detailedRuns] is `false`, it returns plain text suggestions.
  /// If [detailedRuns] is `true`, it returns a list of Maps with detailed information.
  ///
  /// Example response when [query] is 'fade' and [detailedRuns] is set to `false`:
  /// ```json
  /// [
  ///   "faded",
  ///   "faded alan walker lyrics",
  ///   "faded alan walker",
  ///   "faded remix",
  ///   "faded song",
  ///   "faded lyrics",
  ///   "faded instrumental"
  /// ]
  /// ```
  ///
  /// Example response when [detailedRuns] is set to `true`:
  /// ```json
  /// [
  ///   {
  ///     "text": "faded",
  ///     "runs": [
  ///       {
  ///         "text": "fade",
  ///         "bold": true
  ///       },
  ///       {
  ///         "text": "d"
  ///       }
  ///     ],
  ///     "fromHistory": true,
  ///     "feedbackToken": "AEEJK..."
  ///   },
  ///   {
  ///     "text": "faded alan walker lyrics",
  ///     "runs": [
  ///       {
  ///         "text": "fade",
  ///         "bold": true
  ///       },
  ///       {
  ///         "text": "d alan walker lyrics"
  ///       }
  ///     ],
  ///     "fromHistory": false,
  ///     "feedbackToken": null
  ///   },
  ///   {
  ///     "text": "faded alan walker",
  ///     "runs": [
  ///       {
  ///         "text": "fade",
  ///         "bold": true
  ///       },
  ///       {
  ///         "text": "d alan walker"
  ///       }
  ///     ],
  ///     "fromHistory": false,
  ///     "feedbackToken": null
  ///   },
  ///   ...
  /// ]
  /// ```
  Future<dynamic> getSearchSuggestions(
    String query, {
    bool detailedRuns = false,
  }) async {
    final body = <String, dynamic>{'input': query};
    const endpoint = 'music/get_search_suggestions';
    final response = await sendRequest(endpoint, body);
    return parseSearchSuggestions(response, detailedRuns);
  }

  /// Remove search suggestion from the user search history.
  ///
  /// - [suggestions] The Map obtained from [getSearchSuggestions] (with `detailedRuns`=`true`).
  /// - [indices] Optional. The indices of the suggestions to be removed. (Default: remove all suggestions).
  ///
  /// Returns `true` if the operation was successful, `false` otherwise.
  Future<bool> removeSearchSuggestions(
    List<JsonMap> suggestions, {
    List<int>? indices,
  }) async {
    if (!suggestions.any((run) => run['fromHistory'] == true)) {
      throw YTMusicUserError(
        'No search result from history provided. '
        'Please run getSearchSuggestions first to retrieve suggestions.',
      );
    }

    indices ??= List.generate(suggestions.length, (i) => i);

    if (indices.any((index) => index >= suggestions.length)) {
      throw YTMusicUserError(
        'Index out of range. Index must be smaller than the length of suggestions',
      );
    }

    // filter null tokens
    final feedbackTokens =
        indices
            .map((i) => suggestions[i]['feedbackToken'])
            .where((t) => t != null)
            .toList();
    if (feedbackTokens.isEmpty) return false;

    final body = {'feedbackTokens': feedbackTokens};
    const endpoint = 'feedback';
    final response = await sendRequest(endpoint, body);

    return nav(response, [
          'feedbackResponses',
          0,
          'isProcessed',
        ], nullIfAbsent: true) ==
        true;
  }
}
