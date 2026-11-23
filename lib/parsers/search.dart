import 'package:ytmusicapi_dart/enums.dart';
import 'package:ytmusicapi_dart/exceptions.dart';
import 'package:ytmusicapi_dart/models/content/enums.dart';
import 'package:ytmusicapi_dart/models/objects/album.dart';
import 'package:ytmusicapi_dart/models/objects/artist.dart';
import 'package:ytmusicapi_dart/models/objects/base.dart';
import 'package:ytmusicapi_dart/models/objects/playlist.dart';
import 'package:ytmusicapi_dart/models/objects/video.dart';
import 'package:ytmusicapi_dart/navigation.dart';
import 'package:ytmusicapi_dart/parsers/albums.dart';
import 'package:ytmusicapi_dart/parsers/artists.dart';
import 'package:ytmusicapi_dart/parsers/songs.dart';
import 'package:ytmusicapi_dart/parsers/utils.dart';
import 'package:ytmusicapi_dart/type_alias.dart';
import 'package:ytmusicapi_dart/utils.dart';

/// Get type of the search result.
YtResultType? getSearchResultType(String? resultTypeLocal) {
  if (resultTypeLocal == null || resultTypeLocal.isEmpty) return null;

  final lowerType = resultTypeLocal.toLowerCase();
  YtResultType resultType;

  if (!YtResultType.values.any((type) => type.name == lowerType)) {
    resultType = YtResultType.ALBUM;
  } else {
    resultType = YtResultType.fromName(lowerType);
  }

  return resultType;
}

/// Parses the top result from [data].
YtTopResult? parseTopResult(JsonMap data) {
  final resultType = getSearchResultType(nav(data, SUBTITLE) as String?);
  if (resultType == null) {
    return null;
  }
  final category =
      nav(data, CARD_SHELF_TITLE, nullIfAbsent: true) as String? ??
      'Top result';
  final thumbnails =
      nav(data, THUMBNAILS, nullIfAbsent: true) != null
          ? YtThumbnails.fromJson(
            List<JsonMap>.from(
              nav(data, THUMBNAILS, nullIfAbsent: true) as List,
            ),
          )
          : null;

  YtBaseObject? resultObject;

  switch (resultType) {
    case YtResultType.ALBUM || YtResultType.EP || YtResultType.SINGLE:
      final buttonCommand = nav(data, [
        'buttons',
        0,
        'buttonRenderer',
        'command',
      ], nullIfAbsent: true);
      final runs = nav(data, ['subtitle', 'runs']) as List;
      List<(SongRunsItemType, dynamic)> songInfo;
      if (runs.length >= 2) {
        songInfo = parseSongRuns(runs.sublist(2));
      } else {
        songInfo = parseSongRuns(runs);
      }
      resultObject = YtAlbum(
        name: nav(data, TITLE_TEXT) as String,
        id:
            nav(data, TITLE + NAVIGATION_BROWSE_ID, nullIfAbsent: true)
                as String?,
        playlistId: parseAlbumPlaylistIdIfExists(buttonCommand as JsonMap?),
        albumType: YtAlbumType.tryFromName(resultType.name),
        thumbnails: thumbnails!,
        artists: [],
        tracks: [],
        durationRaw: null,
        duration: null,
        isExplicit: nav(data, SUBTITLE_BADGE_LABEL, nullIfAbsent: true) != null,
        year: null,
        trackCount: null,
        description: null,
        likeStatus: null,
        relatedRecommendations: [],
        otherVersions: [],
      );
      resultObject as YtAlbum;
      for (final (songRunsItemType, value) in songInfo) {
        switch (songRunsItemType) {
          case SongRunsItemType.ALBUM:
            continue;
          case SongRunsItemType.ARTISTS:
            resultObject.artists = value as List<YtBaseObject>;
          case SongRunsItemType.DURATION_RAW:
            resultObject.durationRaw = value as String?;
          case SongRunsItemType.DURATION_SECONDS:
            resultObject.duration = value as Duration?;
          case SongRunsItemType.VIEWS:
            continue;
          case SongRunsItemType.YEAR:
            resultObject.year = value as int?;
        }
      }
    case YtResultType.ARTIST:
      final subscribers = nav(data, SUBTITLE2, nullIfAbsent: true) as String?;
      // TODO
      resultObject = YtArtist(
        name: '',
        id: null,
        shuffleId: null,
        radioId: null,
        thumbnails: thumbnails!,
        subscribers: subscribers?.split(' ').first,
      );

    case YtResultType.PLAYLIST:
      resultObject = YtPlaylist(
        name: nav(data, TITLE_TEXT) as String,
        id: nav(data, MENU_PLAYLIST_ID) as String,
        playlistType: null,
        authors: parseArtistsRuns(
          (nav(data, ['subtitle', 'runs']) as List).sublist(2),
        ),
        owned: null,
        privacy: null,
        thumbnails: thumbnails,
        description: null,
        durationRaw: null,
        duration: null,
        year: null,
        itemCount: null,
        views: null,
        items: [],
        related: [],
        suggestions: [],
      );
    case YtResultType.SONG || YtResultType.VIDEO || YtResultType.EPISODE:
      final runs = nav(data, ['subtitle', 'runs']) as List;
      List<(SongRunsItemType, dynamic)> songInfo;
      if (runs.length >= 2) {
        songInfo = parseSongRuns(runs.sublist(2));
      } else {
        songInfo = parseSongRuns(runs);
      }
      final onTap = data['onTap'];
      resultObject = YtVideo(
        name: nav(data, TITLE_TEXT) as String,
        id:
            resultType == YtResultType.EPISODE
                ? nav(data, [
                      ...THUMBNAIL_OVERLAY_NAVIGATION,
                      ...WATCH_VIDEO_ID,
                    ])
                    as String
                : (onTap != null ? nav(onTap, WATCH_VIDEO_ID) as String : null),
        playlistId: null,
        videoType:
            resultType == YtResultType.EPISODE
                ? VideoType.tryFromValue(
                  nav(data, [
                        ...THUMBNAIL_OVERLAY_NAVIGATION,
                        ...NAVIGATION_VIDEO_TYPE,
                      ])
                      as String,
                )
                : (onTap != null
                    ? VideoType.tryFromValue(
                      nav(onTap, NAVIGATION_VIDEO_TYPE) as String,
                    )
                    : null),
        views: null,
        durationRaw: null,
        duration: null,
        artists:
            resultType == YtResultType.EPISODE
                ? [
                  parseIdName(
                    (nav(data, SUBTITLE_RUNS) as List).sublist(2)[2]
                        as JsonMap?,
                  ),
                ]
                : [],
        thumbnails: thumbnails,
        year: null,
        isAvailable: null,
        isEpisode: resultType == YtResultType.EPISODE,
        isSong: resultType == YtResultType.SONG,
        album: null,
        trackNumber: null,
        isExplicit: nav(data, SUBTITLE_BADGE_LABEL, nullIfAbsent: true) != null,
        inLibrary: null,
        feedbackTokenAdd: null,
        feedbackTokenRemove: null,
        description: null,
      );
      resultObject as YtVideo;
      for (final (songRunsItemType, value) in songInfo) {
        switch (songRunsItemType) {
          case SongRunsItemType.ALBUM:
            resultObject.album = value as YtBaseObject?;
          case SongRunsItemType.ARTISTS:
            resultObject.artists = value as List<YtBaseObject>;
          case SongRunsItemType.DURATION_RAW:
            resultObject.durationRaw = value as String?;
          case SongRunsItemType.DURATION_SECONDS:
            resultObject.duration = value as Duration?;
          case SongRunsItemType.VIEWS:
            resultObject.views = value as String?;
          case SongRunsItemType.YEAR:
            resultObject.year = value as int?;
        }
      }
    case YtResultType.STATION:
      // TODO
      return null;
    case YtResultType.PROFILE:
      // TODO
      return null;
    case YtResultType.PODCAST:
      // TODO
      return null;
  }

  final searchResult = YtTopResult(
    result: YtSearchResult(type: resultType, category: category)
      ..result = resultObject,
    undercardsTitle: null, // TODO
    undercards: [], // TODO
  );

  return searchResult;
}

/// Parses a search result from [data].
YtSearchResult? parseSearchResult(
  JsonMap data,
  YtResultType? resultType,
  String? category,
) {
  final defaultOffset =
      ((resultType == null || resultType == YtResultType.ALBUM) ? 2 : 0);
  final searchResult = YtSearchResult(type: null, category: category);

  final videoType =
      nav(data, [
            ...PLAY_BUTTON,
            'playNavigationEndpoint',
            ...NAVIGATION_VIDEO_TYPE,
          ], nullIfAbsent: true)
          as String?;

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
    realResultType = resultType.name;
  }

  searchResult.type = YtResultType.fromName(realResultType);
  if (searchResult.type == null) {
    return null;
  }

  final thumbnails =
      nav(data, THUMBNAILS, nullIfAbsent: true) != null
          ? YtThumbnails.fromJson(
            List<JsonMap>.from(
              nav(data, THUMBNAILS, nullIfAbsent: true) as List,
            ),
          )
          : null;

  switch (searchResult.type!) {
    case YtResultType.EP || YtResultType.SINGLE || YtResultType.ALBUM:
      searchResult.type = YtResultType.fromName(
        (YtAlbumType.tryFromName(getItemText(data, 1)) ?? searchResult.type!)
            .name,
      );
      final playNavigation = nav(data, [
        ...PLAY_BUTTON,
        'playNavigationEndpoint',
      ], nullIfAbsent: true);
      final flexItem = getFlexColumnItem(data, 1);
      if (flexItem == null) {
        throw YTMusicError('Expected flex column item at index 1');
      }
      final runs = (flexItem['text'] as JsonMap)['runs'] as List;
      final flexItem2 = getFlexColumnItem(data, 2);
      if (flexItem2 != null) {
        runs.addAll([
          {'text': ''},
          ...(flexItem2['text'] as JsonMap)['runs'] as Iterable,
        ]);
      }
      searchResult.result = YtAlbum(
        name: getItemText(data, 0)!,
        id: nav(data, NAVIGATION_BROWSE_ID, nullIfAbsent: true) as String?,
        playlistId: parseAlbumPlaylistIdIfExists(playNavigation as JsonMap?),
        albumType: YtAlbumType.tryFromName(getItemText(data, 1)),
        thumbnails: thumbnails!,
        artists: [],
        tracks: [],
        durationRaw: null,
        duration: null,
        isExplicit: nav(data, BADGE_LABEL, nullIfAbsent: true) != null,
        year: null,
        trackCount: null,
        description: null,
        likeStatus: null,
        relatedRecommendations: [],
        otherVersions: [],
      );
      final songInfo = parseSongRuns(runs, skipTypeSpec: true);
      for (final (songRunsItemType, value) in songInfo) {
        switch (songRunsItemType) {
          case SongRunsItemType.ALBUM:
            continue;
          case SongRunsItemType.ARTISTS:
            (searchResult.result as YtAlbum).artists =
                value as List<YtBaseObject>;
          case SongRunsItemType.DURATION_RAW:
            (searchResult.result as YtAlbum).durationRaw = value as String?;
          case SongRunsItemType.DURATION_SECONDS:
            (searchResult.result as YtAlbum).duration = value as Duration?;
          case SongRunsItemType.VIEWS:
            continue;
          case SongRunsItemType.YEAR:
            (searchResult.result as YtAlbum).year = value as int?;
        }
      }

    case YtResultType.ARTIST:
      final menuPlaylists = parseMenuPlaylists(data);
      searchResult.result = YtArtist(
        name: getItemText(data, 0)!,
        id: nav(data, NAVIGATION_BROWSE_ID, nullIfAbsent: true) as String?,
        shuffleId: menuPlaylists.shuffleId,
        radioId: menuPlaylists.radioId,
        thumbnails: thumbnails!,
        subscribers: null,
      );

    case YtResultType.PLAYLIST:
      final flexItem = nav(getFlexColumnItem(data, 1), TEXT_RUNS) as List;

      final hasAuthor = flexItem.length == defaultOffset + 3;

      final itemInfoText =
          (getItemText(data, 1, runIndex: hasAuthor ? 2 : 0) ?? '').split(' ');

      searchResult.result = YtPlaylist(
        name: getItemText(data, 0)!,
        id: nav(data, NAVIGATION_BROWSE_ID, nullIfAbsent: true) as String?,
        playlistType: null,
        authors:
            !hasAuthor
                ? []
                : [
                  YtBaseObject(
                    id: null,
                    name: getItemText(data, 1, runIndex: defaultOffset)!,
                    type: YtObjectType.OBJECT,
                  ),
                ],
        owned: null,
        privacy: null,
        thumbnails: thumbnails,
        description: null,
        durationRaw: null,
        duration: null,
        year: null,
        itemCount:
            itemInfoText.length >= 2 && itemInfoText[1] == 'songs'
                ? int.tryParse(itemInfoText.first)
                : null,
        views: null,
        items: [],
        related: [],
        suggestions: [],
      );
    case YtResultType.SONG || YtResultType.VIDEO || YtResultType.EPISODE:
      SongMenuData? songMenuData;
      if (searchResult.type == YtResultType.SONG) {
        songMenuData = parseSongMenuData(data);
      }

      searchResult.result = YtVideo(
        name: getItemText(data, 0)!,
        id:
            nav(data, [
                  ...PLAY_BUTTON,
                  'playNavigationEndpoint',
                  'watchEndpoint',
                  'videoId',
                ], nullIfAbsent: true)
                as String?,
        playlistId: null,
        videoType: VideoType.tryFromValue(videoType),
        views: null,
        durationRaw: null,
        duration: null,
        artists: [],
        thumbnails: thumbnails,
        year: null,
        isAvailable: null,
        isEpisode: searchResult.type == YtResultType.EPISODE,
        isSong: searchResult.type == YtResultType.SONG,
        album: null,
        trackNumber: null,
        isExplicit: nav(data, BADGE_LABEL, nullIfAbsent: true) != null,
        inLibrary: songMenuData?.inLibrary,
        feedbackTokenAdd: songMenuData?.feedbackTokenAdd,
        feedbackTokenRemove: songMenuData?.feedbackTokenRemove,
        description: null,
      );
      if (searchResult.type != YtResultType.EPISODE) {
        final flexItem = getFlexColumnItem(data, 1);
        if (flexItem == null) {
          throw YTMusicError('Expected flex column item at index 1');
        }
        final runs = (flexItem['text'] as JsonMap)['runs'] as List;
        final flexItem2 = getFlexColumnItem(data, 2);
        if (flexItem2 != null) {
          runs.addAll([
            {'text': ''},
            ...(flexItem2['text'] as JsonMap)['runs'] as Iterable,
          ]);
        }
        final songInfo = parseSongRuns(runs, skipTypeSpec: true);
        for (final (songRunsItemType, value) in songInfo) {
          switch (songRunsItemType) {
            case SongRunsItemType.ALBUM:
              (searchResult.result as YtVideo).album = value as YtBaseObject;
            case SongRunsItemType.ARTISTS:
              (searchResult.result as YtVideo).artists =
                  value as List<YtBaseObject>;
            case SongRunsItemType.DURATION_RAW:
              (searchResult.result as YtVideo).durationRaw = value as String?;
            case SongRunsItemType.DURATION_SECONDS:
              (searchResult.result as YtVideo).duration = value as Duration?;
            case SongRunsItemType.VIEWS:
              (searchResult.result as YtVideo).views = value as String?;
            case SongRunsItemType.YEAR:
              (searchResult.result as YtVideo).year = value as int?;
          }
        }
      }
      if (searchResult.type == YtResultType.EPISODE) {
        final flexItem = getFlexColumnItem(data, 1);
        final runs = (nav(flexItem, TEXT_RUNS) as List).sublist(defaultOffset);
        final hasDate = runs.length > 1 ? 1 : 0;
        (searchResult.result as YtVideo).artists = [
          parseIdName(runs[hasDate * 2] as JsonMap?),
        ];
      }

    case YtResultType.STATION:
      // TODO
      return null;
    case YtResultType.PROFILE:
      // TODO
      return null;

    case YtResultType.PODCAST:
      // TODO
      return null;
  }

  return searchResult;
}

/// Parses search [results].
List<YtSearchResult> parseSearchResults(
  List<JsonMap> results, {
  YtResultType? resultType,
  String? category,
}) {
  return List<YtSearchResult>.from(
    results
        .map(
          (result) =>
              parseSearchResult(result[MRLIR] as JsonMap, resultType, category),
        )
        .toList()
      ..removeWhere((e) => e == null),
  );
}

/// Get search params for given [filter], [scope] and [ignoreSpelling].
String? getSearchParams(
  SearchFilterType? filter,
  String? scope,
  bool ignoreSpelling,
) {
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
    if (filter == SearchFilterType.playlists) {
      params = 'Eg-KAQwIABAAGAAgACgB';
      params +=
          ignoreSpelling
              ? 'MABCAggBagoQBBADEAkQBRAK'
              : 'MABqChAEEAMQCRAFEAo%3D';
    } else if (filter == SearchFilterType.playlists ||
        filter == SearchFilterType.featured_playlists ||
        filter == SearchFilterType.community_playlists) {
      param1 = 'EgeKAQQoA';
      param2 = filter == SearchFilterType.featured_playlists ? 'Dg' : 'EA';
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

String _getParam2(SearchFilterType filter) {
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
  return filterParams[filter.name]!;
}

/// Parses search suggestions.
List parseSearchSuggestions(JsonMap results, bool detailedRuns) {
  final contents =
      (((results['contents'] as List?)?.first
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
