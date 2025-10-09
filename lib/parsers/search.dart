import 'package:ytmusicapi_dart/helpers.dart';
import 'package:ytmusicapi_dart/navigation.dart';
import 'package:ytmusicapi_dart/parsers/albums.dart';
import 'package:ytmusicapi_dart/parsers/songs.dart';
import 'package:ytmusicapi_dart/parsers/utils.dart';
import 'package:ytmusicapi_dart/type_alias.dart';

// ignore: public_member_api_docs
const ALL_RESULT_TYPES = [
  'album',
  'artist',
  'playlist',
  'song',
  'video',
  'station',
  'profile',
  'podcast',
  'episode',
];

// ignore: public_member_api_docs
const API_RESULT_TYPES = ['single', 'ep', ...ALL_RESULT_TYPES];

/// Get type of the search result.
String? getSearchResultType(
  String? resultTypeLocal,
  List<String> resultTypesLocal,
) {
  if (resultTypeLocal == null || resultTypeLocal.isEmpty) return null;

  final lowerType = resultTypeLocal.toLowerCase();
  String resultType;

  if (!resultTypesLocal.contains(lowerType)) {
    resultType = 'album';
  } else {
    resultType = ALL_RESULT_TYPES[resultTypesLocal.indexOf(lowerType)];
  }

  return resultType;
}

/// Parses the top result from [data].
JsonMap parseTopResult(JsonMap data, List<String> searchResultTypes) {
  final resultType = getSearchResultType(
    nav(data, SUBTITLE) as String?,
    searchResultTypes,
  );
  final category =
      nav(data, CARD_SHELF_TITLE, nullIfAbsent: true) ?? 'Top result';
  final searchResult = <String, dynamic>{
    'category': category,
    'resultType': resultType,
  };

  if (resultType == 'artist') {
    final subscribers = nav(data, SUBTITLE2, nullIfAbsent: true) as String?;
    if (subscribers != null) {
      searchResult['subscribers'] = subscribers.split(' ')[0];
    }

    final artistInfo = parseSongRuns(nav(data, ['title', 'runs']) as List);
    searchResult.addAll(artistInfo);
  }

  if (resultType == 'song' || resultType == 'video') {
    final onTap = data['onTap'];
    if (onTap != null) {
      searchResult['videoId'] = nav(onTap, WATCH_VIDEO_ID);
      searchResult['videoType'] = nav(onTap, NAVIGATION_VIDEO_TYPE);
    }
  }

  if (['song', 'video', 'album'].contains(resultType)) {
    searchResult['videoId'] = nav(data, [
      'onTap',
      ...WATCH_VIDEO_ID,
    ], nullIfAbsent: true);
    searchResult['videoType'] = nav(data, [
      'onTap',
      ...NAVIGATION_VIDEO_TYPE,
    ], nullIfAbsent: true);
    searchResult['title'] = nav(data, TITLE_TEXT);

    final runs = nav(data, ['subtitle', 'runs']) as List;
    final songInfo = parseSongRuns(runs.sublist(2));
    searchResult.addAll(songInfo);
  }

  if (resultType == 'album') {
    searchResult['browseId'] = nav(
      data,
      TITLE + NAVIGATION_BROWSE_ID,
      nullIfAbsent: true,
    );
    final buttonCommand = nav(data, [
      'buttons',
      0,
      'buttonRenderer',
      'command',
    ], nullIfAbsent: true);
    searchResult['playlistId'] = parseAlbumPlaylistIdIfExists(
      buttonCommand as JsonMap?,
    );
  }

  if (resultType == 'playlist') {
    searchResult['playlistId'] = nav(data, MENU_PLAYLIST_ID);
    searchResult['title'] = nav(data, TITLE_TEXT);
    searchResult['author'] = parseSongArtistsRuns(
      (nav(data, ['subtitle', 'runs']) as List).sublist(2),
    );
  }

  if (resultType == 'episode') {
    searchResult['videoId'] = nav(data, [
      ...THUMBNAIL_OVERLAY_NAVIGATION,
      ...WATCH_VIDEO_ID,
    ]);
    searchResult['videoType'] = nav(data, [
      ...THUMBNAIL_OVERLAY_NAVIGATION,
      ...NAVIGATION_VIDEO_TYPE,
    ]);
    final runs = (nav(data, SUBTITLE_RUNS) as List).sublist(2);
    searchResult['date'] = (runs[0] as JsonMap)['text'];
    searchResult['podcast'] = parseIdName(runs[2] as JsonMap?);
  }

  searchResult['thumbnails'] = nav(data, THUMBNAILS, nullIfAbsent: true);
  return searchResult;
}

/// Parses a search result from [data].
JsonMap parseSearchResult(JsonMap data, String? resultType, String? category) {
  final defaultOffset = ((resultType == null || resultType == 'album') ? 2 : 0);
  final searchResult = <String, dynamic>{'category': category};

  final videoType = nav(data, [
    ...PLAY_BUTTON,
    'playNavigationEndpoint',
    ...NAVIGATION_VIDEO_TYPE,
  ], nullIfAbsent: true);

  final String realResultType;
  // Determine result type based on browseId
  if (resultType == null) {
    final browseId =
        nav(data, NAVIGATION_BROWSE_ID, nullIfAbsent: true) as String?;
    if (browseId != null) {
      final mapping = {
        'VM': 'playlist',
        'RD': 'playlist',
        'VL': 'playlist',
        'MPLA': 'artist',
        'MPRE': 'album',
        'MPSP': 'podcast',
        'MPED': 'episode',
        'UC': 'artist',
      };
      realResultType =
          mapping.entries
              .firstWhere(
                (e) => browseId.startsWith(e.key),
                orElse: () => const MapEntry('', ''),
              )
              .value;
    } else {
      realResultType =
          {
            'MUSIC_VIDEO_TYPE_ATV': 'song',
            'MUSIC_VIDEO_TYPE_PODCAST_EPISODE': 'episode',
          }[videoType ?? ''] ??
          'video';
    }
  } else {
    realResultType = resultType;
  }

  searchResult['resultType'] = realResultType;

  if (realResultType != 'artist') searchResult['title'] = getItemText(data, 0);

  if (realResultType == 'artist') {
    searchResult['artist'] = getItemText(data, 0);
    parseMenuPlaylists(data, searchResult);
  } else if (realResultType == 'album') {
    searchResult['type'] = getItemText(data, 1);
    final playNavigation = nav(data, [
      ...PLAY_BUTTON,
      'playNavigationEndpoint',
    ], nullIfAbsent: true);
    searchResult['playlistId'] = parseAlbumPlaylistIdIfExists(
      playNavigation as JsonMap?,
    );
  } else if (realResultType == 'playlist') {
    final flexItem = nav(getFlexColumnItem(data, 1), TEXT_RUNS) as List;
    final hasAuthor = flexItem.length == defaultOffset + 3;
    searchResult['itemCount'] =
        (getItemText(data, 1, runIndex: defaultOffset + (hasAuthor ? 2 : 0)) ??
                '')
            .split(' ')[0];
    if (searchResult['itemCount'] != null &&
        (num.tryParse(searchResult['itemCount'] as String) != null)) {
      searchResult['itemCount'] = toInt(searchResult['itemCount'] as String);
    }
    searchResult['author'] =
        hasAuthor ? getItemText(data, 1, runIndex: defaultOffset) : null;
  } else if (realResultType == 'station') {
    searchResult['videoId'] = nav(data, NAVIGATION_VIDEO_ID);
    searchResult['playlistId'] = nav(data, NAVIGATION_PLAYLIST_ID);
  } else if (realResultType == 'profile') {
    searchResult['name'] = getItemText(
      data,
      1,
      runIndex: 2,
      noneIfAbsent: true,
    );
  } else if (realResultType == 'song') {
    searchResult['album'] = null;
    if (data.containsKey('menu')) {
      final toggleMenu = findObjectByKey(
        nav(data, MENU_ITEMS) as List,
        TOGGLE_MENU,
      );
      if (toggleMenu != null) {
        searchResult['inLibrary'] = parseSongLibraryStatus(toggleMenu);
        searchResult['feedbackTokens'] = parseSongMenuTokens(toggleMenu);
      }
    }
  } else if (realResultType == 'upload') {
    final browseId = nav(data, NAVIGATION_BROWSE_ID, nullIfAbsent: true);
    if (browseId == null) {
      final flexItems = [
        nav(getFlexColumnItem(data, 0), ['text', 'runs'], nullIfAbsent: true),
        nav(getFlexColumnItem(data, 1), ['text', 'runs'], nullIfAbsent: true),
      ];
      if (flexItems[0] != null) {
        searchResult['videoId'] = nav(
          (flexItems[0] as List)[0],
          NAVIGATION_VIDEO_ID,
          nullIfAbsent: true,
        );
        searchResult['playlistId'] = nav(
          (flexItems[0] as List)[0],
          NAVIGATION_PLAYLIST_ID,
          nullIfAbsent: true,
        );
      }
      if (flexItems[1] != null) {
        searchResult.addAll(parseSongRuns(flexItems[1] as List));
      }
      searchResult['resultType'] = 'song';
    } else {
      searchResult['browseId'] = browseId;
      if ((searchResult['browseId'] as String).contains('artist')) {
        searchResult['resultType'] = 'artist';
      } else {
        final flexItem2 = getFlexColumnItem(data, 1);
        final runs =
            flexItem2 != null
                ? List.generate(
                  ((flexItem2['text'] as JsonMap)['runs'] as List).length,
                  (i) {
                    final run =
                        ((flexItem2['text'] as JsonMap)['runs'] as List)[i];
                    return i.isEven ? (run as JsonMap)['text'] : null;
                  },
                ).whereType<String>().toList()
                : <String>[];
        if (runs.length > 1) searchResult['artist'] = runs[1];
        if (runs.length > 2) searchResult['releaseDate'] = runs[2];
        searchResult['resultType'] = 'album';
      }
    }
  }

  if (['song', 'video', 'episode'].contains(realResultType)) {
    searchResult['videoId'] = nav(data, [
      ...PLAY_BUTTON,
      'playNavigationEndpoint',
      'watchEndpoint',
      'videoId',
    ], nullIfAbsent: true);
    searchResult['videoType'] = videoType;
  }

  if (['song', 'video', 'album'].contains(realResultType)) {
    searchResult['duration'] = null;
    searchResult['year'] = null;
    final flexItem = getFlexColumnItem(data, 1);
    final runs = (flexItem!['text'] as JsonMap)['runs'] as List;
    final flexItem2 = getFlexColumnItem(data, 2);
    if (flexItem2 != null) {
      runs.addAll([
        {'text': ''},
        ...(flexItem2['text'] as JsonMap)['runs'] as Iterable,
      ]);
    }
    final songInfo = parseSongRuns(runs, skipTypeSpec: true);
    searchResult.addAll(songInfo);
  }

  if ([
    'artist',
    'album',
    'playlist',
    'profile',
    'podcast',
  ].contains(realResultType)) {
    searchResult['browseId'] = nav(
      data,
      NAVIGATION_BROWSE_ID,
      nullIfAbsent: true,
    );
  }

  if (['song', 'album'].contains(realResultType)) {
    searchResult['isExplicit'] =
        nav(data, BADGE_LABEL, nullIfAbsent: true) != null;
  }

  if (realResultType == 'episode') {
    final flexItem = getFlexColumnItem(data, 1);
    final runs = (nav(flexItem, TEXT_RUNS) as List).sublist(defaultOffset);
    final hasDate = runs.length > 1 ? 1 : 0;
    searchResult['live'] =
        nav(data, ['badges', 0, 'liveBadgeRenderer'], nullIfAbsent: true) !=
        null;
    if (hasDate > 0) searchResult['date'] = (runs[0] as JsonMap)['text'];
    searchResult['podcast'] = parseIdName(runs[hasDate * 2] as JsonMap?);
  }

  searchResult['thumbnails'] = nav(data, THUMBNAILS, nullIfAbsent: true);
  return searchResult;
}

/// Parses search [results].
List parseSearchResults(
  List<JsonMap> results, {
  String? resultType,
  String? category,
}) {
  return results
      .map(
        (result) =>
            parseSearchResult(result[MRLIR] as JsonMap, resultType, category),
      )
      .toList();
}

/// Get search params for given [filter], [scope] and [ignoreSpelling].
String? getSearchParams(String? filter, String? scope, bool ignoreSpelling) {
  const filteredParam1 = 'EgWKAQ';
  String? params;
  late String param1;
  late String param2;
  late String param3;

  if (filter == null && scope == null && !ignoreSpelling) return params;

  if (scope == 'uploads') params = 'agIYAw%3D%3D';
  if (scope == 'library') {
    if (filter != null) {
      param1 = filteredParam1;
      param2 = _getParam2(filter);
      param3 = 'AWoKEAUQCRADEAoYBA%3D%3D';
    } else {
      params = 'agIYBA%3D%3D';
    }
  }

  if (scope == null && filter != null) {
    if (filter == 'playlists') {
      params = 'Eg-KAQwIABAAGAAgACgB';
      params +=
          ignoreSpelling
              ? 'MABCAggBagoQBBADEAkQBRAK'
              : 'MABqChAEEAMQCRAFEAo%3D';
    } else if (filter.contains('playlists')) {
      param1 = 'EgeKAQQoA';
      param2 = filter == 'featured_playlists' ? 'Dg' : 'EA';
      param3 =
          ignoreSpelling
              ? 'BQgIIAWoMEA4QChADEAQQCRAF'
              : 'BagwQDhAKEAMQBBAJEAU%3D';
    } else {
      param1 = filteredParam1;
      param2 = _getParam2(filter);
      param3 =
          ignoreSpelling
              ? 'AUICCAFqDBAOEAoQAxAEEAkQBQ%3D%3D'
              : 'AWoMEA4QChADEAQQCRAF';
    }
  }

  if (scope == null && filter == null && ignoreSpelling) {
    params = 'EhGKAQ4IARABGAEgASgAOAFAAUICCAE%3D';
  }

  return params ?? (param1 + param2 + param3);
}

String _getParam2(String filter) {
  const filterParams = {
    'songs': 'II',
    'videos': 'IQ',
    'albums': 'IY',
    'artists': 'Ig',
    'playlists': 'Io',
    'profiles': 'JY',
    'podcasts': 'JQ',
    'episodes': 'JI',
  };
  return filterParams[filter]!;
}

/// Parses search suggestions.
List parseSearchSuggestions(JsonMap results, bool detailedRuns) {
  final contents =
      (((results['contents'] as List?)?[0]
                  as JsonMap?)?['searchSuggestionsSectionRenderer']
              as JsonMap?)?['contents']
          as List?;
  if (contents == null || contents.isEmpty) return [];

  final suggestions = <dynamic>[];

  for (final rawSuggestion in List<JsonMap>.from(contents)) {
    JsonMap suggestionContent;
    String? feedbackToken;
    if (rawSuggestion.containsKey('historySuggestionRenderer')) {
      suggestionContent = rawSuggestion['historySuggestionRenderer'] as JsonMap;
      feedbackToken =
          nav(suggestionContent, [
                'serviceEndpoint',
                'feedbackEndpoint',
                'feedbackToken',
              ], nullIfAbsent: true)
              as String?;
    } else {
      suggestionContent = rawSuggestion['searchSuggestionRenderer'] as JsonMap;
    }

    final text =
        ((suggestionContent['navigationEndpoint'] as JsonMap)['searchEndpoint']
            as JsonMap)['query'];
    final runs = (suggestionContent['suggestion'] as JsonMap)['runs'];

    if (detailedRuns) {
      suggestions.add({
        'text': text,
        'runs': runs,
        'fromHistory': feedbackToken != null,
        'feedbackToken': feedbackToken,
      });
    } else {
      suggestions.add(text);
    }
  }

  return suggestions;
}
