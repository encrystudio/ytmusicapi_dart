import 'dart:core';

import 'package:ytmusicapi_dart/navigation.dart';
import 'package:ytmusicapi_dart/parsers/albums.dart';
import 'package:ytmusicapi_dart/parsers/podcasts.dart';
import 'package:ytmusicapi_dart/parsers/songs.dart';
import 'package:ytmusicapi_dart/parsers/utils.dart';
import 'package:ytmusicapi_dart/type_alias.dart';

/// Parse various contents from [rows].
List parseMixedContent(List<JsonMap> rows) {
  final items = <dynamic>[];

  for (final row in rows) {
    List contents;
    dynamic title;

    if (row.containsKey(DESCRIPTION_SHELF[0])) {
      final results = nav(row, DESCRIPTION_SHELF);
      title = nav(results, ['header', ...RUN_TEXT]);
      contents = nav(results, DESCRIPTION) as List;
    } else {
      final results = row.values.first;
      if (!(results as JsonMap).containsKey('contents')) {
        continue;
      }
      title = nav(results, [...CAROUSEL_TITLE, 'text']);
      contents = [];

      for (final result in results['contents'] as Iterable) {
        final data = nav(result, [MTRIR], nullIfAbsent: true);
        JsonMap? content;

        if (data != null) {
          final pageType = nav(data, [
            ...TITLE,
            ...NAVIGATION_BROWSE,
            ...PAGE_TYPE,
          ], nullIfAbsent: true);
          if (pageType == null) {
            if (nav(data, NAVIGATION_WATCH_PLAYLIST_ID, nullIfAbsent: true) !=
                null) {
              content = parseWatchPlaylist(data as JsonMap);
            } else {
              content = parseSong(data as JsonMap);
            }
          } else if (pageType == 'MUSIC_PAGE_TYPE_ALBUM') {
            content = parseAlbum(data as JsonMap);
          } else if (pageType == 'MUSIC_PAGE_TYPE_ARTIST' ||
              pageType == 'MUSIC_PAGE_TYPE_USER_CHANNEL') {
            content = parseRelatedArtist(data as JsonMap);
          } else if (pageType == 'MUSIC_PAGE_TYPE_PLAYLIST') {
            content = parsePlaylist(data as JsonMap);
          } else if (pageType == 'MUSIC_PAGE_TYPE_PODCAST_SHOW_DETAIL_PAGE') {
            content = parsePodcast(data as JsonMap);
          }
        } else if ((nav(result, [MRLIR], nullIfAbsent: true)) != null) {
          content = parseSongFlat(
            nav(result, [MRLIR], nullIfAbsent: true) as JsonMap,
          );
        } else if ((nav(result, [MMRIR], nullIfAbsent: true)) != null) {
          content = parseEpisode(
            nav(result, [MMRIR], nullIfAbsent: true) as JsonMap,
          );
        } else {
          continue;
        }

        if (content != null) {
          contents.add(content);
        }
      }
    }

    items.add({'title': title, 'contents': contents});
  }

  return items;
}

/// Parses from [results] using [parseFunc] and [key].
Future<List> parseContentList(
  List<JsonMap> results,
  RequestFuncBodyType parseFunc, {
  String key = MTRIR,
}) async {
  final contents = <JsonMap>[];
  for (final result in results) {
    contents.add(await parseFunc(result[key] as JsonMap));
  }
  return contents;
}

/// Parses an album from [result].
JsonMap parseAlbum(JsonMap result) {
  final JsonMap realResult;
  if (result.containsKey(MTRIR)) {
    realResult = nav(result, [MTRIR]) as JsonMap;
  } else {
    realResult = result;
  }
  final artists =
      List<JsonMap>.from(
            (nav(realResult, ['subtitle', 'runs'], nullIfAbsent: true) ?? [])
                as List,
          ) // TODO should nullIfAbsent be true?
          .where((x) => x.containsKey('navigationEndpoint'))
          .map((x) => parseIdName(x as JsonMap?))
          .toList();

  final album = <String, dynamic>{
    'title': nav(realResult, TITLE_TEXT),
    'type': 'Album',
    'artists': artists,
    'browseId': nav(realResult, [...TITLE, ...NAVIGATION_BROWSE_ID]),
    'audioPlaylistId': parseAlbumPlaylistIdIfExists(
      nav(realResult, THUMBNAIL_OVERLAY_NAVIGATION, nullIfAbsent: true)
          as JsonMap?,
    ),
    'thumbnails': nav(realResult, THUMBNAIL_RENDERER),
    'isExplicit':
        nav(realResult, SUBTITLE_BADGE_LABEL, nullIfAbsent: true) != null,
  };

  const validTypes = {'Album', 'Single', 'EP'};
  final yearRegex = RegExp(r'^\d+$');

  final subtitle = nav(realResult, SUBTITLE, nullIfAbsent: true) as String?;
  final subtitle2 = nav(realResult, SUBTITLE2, nullIfAbsent: true) as String?;

  final type = [
    subtitle,
    subtitle2,
  ].firstWhere((s) => s != null && validTypes.contains(s), orElse: () => null);
  if (type != null) album['type'] = type;

  final year = [
    subtitle,
    subtitle2,
  ].firstWhere((s) => s != null && yearRegex.hasMatch(s), orElse: () => null);
  if (year != null) album['year'] = year;

  return album;
}

/// Parses a single from [result].
JsonMap parseSingle(JsonMap result) {
  final JsonMap realResult;
  if (result.containsKey(MTRIR)) {
    realResult = nav(result, [MTRIR]) as JsonMap;
  } else {
    realResult = result;
  }
  return {
    'title': nav(realResult, TITLE_TEXT),
    'type': nav(realResult, SUBTITLE, nullIfAbsent: true),
    'year': nav(realResult, SUBTITLE2, nullIfAbsent: true),
    'browseId': nav(realResult, [...TITLE, ...NAVIGATION_BROWSE_ID]),
    'audioPlaylistId': parseAlbumPlaylistIdIfExists(
      nav(realResult, THUMBNAIL_OVERLAY_NAVIGATION, nullIfAbsent: true)
          as JsonMap?,
    ),
    'artists':
        List<JsonMap>.from(
              (nav(realResult, ['subtitle', 'runs'], nullIfAbsent: true) ?? [])
                  as List,
            ) // TODO should nullIfAbsent be true?
            .where((x) => x.containsKey('navigationEndpoint'))
            .map((x) => parseIdName(x as JsonMap?))
            .toList(),
    'thumbnails': nav(realResult, THUMBNAIL_RENDERER),
  };
}

/// Parses a song from [result].
JsonMap parseSong(JsonMap result) {
  final song = <String, dynamic>{
    'title': nav(result, TITLE_TEXT),
    'videoId': nav(result, NAVIGATION_VIDEO_ID),
    'playlistId': nav(result, NAVIGATION_PLAYLIST_ID, nullIfAbsent: true),
    'thumbnails': nav(result, THUMBNAIL_RENDERER),
  };
  song.addAll(
    parseSongRuns(nav(result, SUBTITLE_RUNS) as List, skipTypeSpec: true),
  );
  return song;
}

/// Parses a song from [data].
JsonMap parseSongFlat(JsonMap data) {
  final columns = List.generate(
    (data['flexColumns'] as List).length,
    (i) => getFlexColumnItem(data, i),
  );

  final song = <String, dynamic>{
    'title': nav(columns[0], TEXT_RUN_TEXT),
    'videoId': nav(columns[0], [
      ...TEXT_RUN,
      ...NAVIGATION_VIDEO_ID,
    ], nullIfAbsent: true),
    'thumbnails': nav(data, THUMBNAILS),
    'isExplicit': nav(data, BADGE_LABEL, nullIfAbsent: true) != null,
  };

  final runs = nav(columns[1], TEXT_RUNS);
  song.addAll(parseSongRuns(runs as List, skipTypeSpec: true));

  if (columns.length > 2 &&
      columns[2] != null &&
      (nav(columns[2], TEXT_RUN) as JsonMap).containsKey(
        'navigationEndpoint',
      )) {
    song['album'] = {
      'name': nav(columns[2], TEXT_RUN_TEXT),
      'id': nav(columns[2], [...TEXT_RUN, ...NAVIGATION_BROWSE_ID]),
    };
  }

  return song;
}

/// Parses a video from [result].
JsonMap parseVideo(JsonMap result) {
  final JsonMap realResult;
  if (result.containsKey(MTRIR)) {
    realResult = nav(result, [MTRIR]) as JsonMap;
  } else {
    realResult = result;
  }
  final runs = nav(realResult, SUBTITLE_RUNS);
  final artistsLen = getDotSeparatorIndex(runs as List);
  var videoId = nav(realResult, NAVIGATION_VIDEO_ID, nullIfAbsent: true);
  if (videoId == null) {
    for (final entry in nav(realResult, MENU_ITEMS) as Iterable) {
      final candidate = nav(entry, [
        ...MENU_SERVICE,
        ...QUEUE_VIDEO_ID,
      ], nullIfAbsent: true);
      if (candidate != null) {
        videoId = candidate;
        break;
      }
    }
  }
  return {
    'title': nav(realResult, TITLE_TEXT),
    'videoId': videoId,
    'artists': parseSongArtistsRuns(runs.sublist(0, artistsLen)),
    'playlistId': nav(realResult, NAVIGATION_PLAYLIST_ID, nullIfAbsent: true),
    'thumbnails': nav(realResult, THUMBNAIL_RENDERER, nullIfAbsent: true),
    'views': (List<JsonMap>.from(runs).last['text'] as String).split(' ')[0],
  };
}

/// Parses a playlist from [data].
JsonMap parsePlaylist(JsonMap data) {
  final JsonMap realData;
  if (data.containsKey(MTRIR)) {
    realData = nav(data, [MTRIR]) as JsonMap;
  } else {
    realData = data;
  }
  final playlist = <String, dynamic>{
    'title': nav(realData, TITLE_TEXT, nullIfAbsent: true),
    'playlistId': (nav(realData, [...TITLE, ...NAVIGATION_BROWSE_ID]) as String)
        .substring(2),
    'thumbnails': nav(realData, THUMBNAIL_RENDERER),
  };

  final subtitle = realData['subtitle'] as JsonMap;
  if (subtitle.containsKey('runs')) {
    playlist['description'] =
        (subtitle['runs'] as List)
            .map((run) => (run as JsonMap)['text'])
            .join();
    if ((subtitle['runs'] as List).length == 3 &&
        RegExp(r'\d+ ').hasMatch(nav(realData, SUBTITLE2) as String)) {
      playlist['count'] = (nav(realData, SUBTITLE2) as String).split(' ')[0];
      playlist['author'] = parseSongArtistsRuns(
        (subtitle['runs'] as List).sublist(0, 1),
      );
    }
  }

  return playlist;
}

/// Parses related artists from [data].
JsonMap parseRelatedArtist(JsonMap data) {
  final JsonMap realData;
  if (data.containsKey(MTRIR)) {
    realData = nav(data, [MTRIR]) as JsonMap;
  } else {
    realData = data;
  }
  var subscribers = nav(realData, SUBTITLE, nullIfAbsent: true);
  if (subscribers != null) {
    subscribers = (subscribers as String).split(' ')[0];
  }
  return {
    'title': nav(realData, TITLE_TEXT),
    'browseId': nav(realData, [...TITLE, ...NAVIGATION_BROWSE_ID]),
    'subscribers': subscribers,
    'thumbnails': nav(realData, THUMBNAIL_RENDERER),
  };
}

/// Parses watch playlist from [data].
JsonMap parseWatchPlaylist(JsonMap data) {
  return {
    'title': nav(data, TITLE_TEXT),
    'playlistId': nav(data, NAVIGATION_WATCH_PLAYLIST_ID),
    'thumbnails': nav(data, THUMBNAIL_RENDERER),
  };
}
