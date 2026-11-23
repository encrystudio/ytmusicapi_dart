import 'dart:async';
import 'dart:core';

import 'package:ytmusicapi_dart/enums.dart';
import 'package:ytmusicapi_dart/models/content/enums.dart';
import 'package:ytmusicapi_dart/models/objects/album.dart';
import 'package:ytmusicapi_dart/models/objects/artist.dart';
import 'package:ytmusicapi_dart/models/objects/base.dart';
import 'package:ytmusicapi_dart/models/objects/playlist.dart';
import 'package:ytmusicapi_dart/models/objects/video.dart';
import 'package:ytmusicapi_dart/navigation.dart';
import 'package:ytmusicapi_dart/parsers/albums.dart';
import 'package:ytmusicapi_dart/parsers/artists.dart';
import 'package:ytmusicapi_dart/parsers/podcasts.dart';
import 'package:ytmusicapi_dart/parsers/songs.dart';
import 'package:ytmusicapi_dart/parsers/utils.dart';
import 'package:ytmusicapi_dart/type_alias.dart';
import 'package:ytmusicapi_dart/utils.dart';

/// Parse various contents from [rows].
List<YtNamedRow> parseMixedContent(List<JsonMap> rows) {
  final items = <YtNamedRow>[];

  for (final row in rows) {
    final contents = <YtBaseObject>[];
    String? title;

    if (row.containsKey(DESCRIPTION_SHELF.first)) {
      final results = nav(row, DESCRIPTION_SHELF);
      title = nav(results, ['header', ...RUN_TEXT]) as String;
      // contents = nav(results, DESCRIPTION) as List; // TODO
    } else {
      final results = row.values.first;
      if (!(results as JsonMap).containsKey('contents')) {
        continue;
      }
      // some carousel headers only carry a strapline (e.g. "MORE FROM") instead of a title
      title =
          nav(results, [...CAROUSEL_TITLE, 'text'], nullIfAbsent: true)
              as String? ??
          nav(results, [...CAROUSEL_STRAPLINE, 'text'], nullIfAbsent: true)
              as String?;

      for (final result in results['contents'] as Iterable) {
        final data = nav(result, [MTRIR], nullIfAbsent: true);
        YtBaseObject? content;

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
          } else if (pageType == 'MUSIC_PAGE_TYPE_ALBUM' ||
              pageType == 'MUSIC_PAGE_TYPE_AUDIOBOOK') {
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

    items.add(YtNamedRow(name: title, contents: contents));
  }

  return items;
}

/// Parses from [results] using [parseFunc] and [key].
Future<List<T>> parseContentList<T>(
  List<JsonMap> results,
  FutureOr<T> Function(JsonMap) parseFunc, {
  String key = MTRIR,
}) async {
  final contents = <T>[];
  for (final result in results) {
    contents.add(await parseFunc(result[key] as JsonMap));
  }
  return contents;
}

/// Parses album or single subtitles
YtAlbum parseAlbumSingleSubtitle(JsonMap result, YtAlbum albumOrSingle) {
  final typeOrYear = nav(result, SUBTITLE, nullIfAbsent: true) as String?;

  if (typeOrYear != null) {
    if (typeOrYear.isNumeric()) {
      albumOrSingle.year = int.tryParse(typeOrYear);
    } else {
      albumOrSingle.albumType = YtAlbumType.tryFromName(typeOrYear);

      final year = nav(result, SUBTITLE2, nullIfAbsent: true) as String?;

      if (year != null && year.isNumeric()) {
        albumOrSingle.year = int.tryParse(year);
      }
    }
  }

  return albumOrSingle;
}

/// Parses a [YtAlbum] from [result].
YtAlbum parseAlbum(JsonMap result) {
  final subtitleRuns = List<JsonMap>.from(
    (nav(result, ['subtitle', 'runs'], nullIfAbsent: true) ?? []) as List,
  );

  final album = YtAlbum(
    name: nav(result, TITLE_TEXT) as String,
    id: nav(result, [...TITLE, ...NAVIGATION_BROWSE_ID]) as String,
    playlistId: parseAlbumPlaylistIdIfExists(
      nav(result, THUMBNAIL_OVERLAY_NAVIGATION, nullIfAbsent: true) as JsonMap?,
    ),
    albumType: null,
    thumbnails: YtThumbnails.fromJson(
      List<JsonMap>.from(nav(result, THUMBNAIL_RENDERER) as List),
    ),
    artists: [
      for (final x in subtitleRuns)
        if (x.containsKey('navigationEndpoint')) parseIdName(x),
    ],
    duration: null,
    isExplicit: nav(result, SUBTITLE_BADGE_LABEL, nullIfAbsent: true) != null,
    year: null,
    tracks: [],
    durationRaw: null,
    trackCount: null,
    description: null,
    likeStatus: null,
    relatedRecommendations: [],
    otherVersions: [],
  );

  return parseAlbumSingleSubtitle(result, album);
}

/// Parses a single from [result].
YtAlbum parseSingle(JsonMap result) {
  final single = YtAlbum(
    name: nav(result, TITLE_TEXT) as String,
    id: nav(result, [...TITLE, ...NAVIGATION_BROWSE_ID]) as String,
    playlistId: null,
    albumType: null,
    thumbnails: YtThumbnails.fromJson(
      List<JsonMap>.from(nav(result, THUMBNAIL_RENDERER) as List),
    ),
    artists: [],
    duration: null,
    isExplicit: null,
    year: null,
    tracks: [],
    durationRaw: null,
    trackCount: null,
    description: null,
    likeStatus: null,
    relatedRecommendations: [],
    otherVersions: [],
  );

  return parseAlbumSingleSubtitle(result, single);
}

/// Parses a song from [result].
YtVideo parseSong(JsonMap result) {
  final song = YtVideo(
    name: nav(result, TITLE_TEXT) as String,
    id: nav(result, NAVIGATION_VIDEO_ID) as String,
    playlistId:
        nav(result, NAVIGATION_PLAYLIST_ID, nullIfAbsent: true) as String?,
    videoType: null,
    views: null,
    durationRaw: null,
    duration: null,
    artists: [],
    thumbnails: YtThumbnails.fromJson(
      List<JsonMap>.from(nav(result, THUMBNAIL_RENDERER) as List),
    ),
    year: null,
    isAvailable: null,
    isSong: true,
    album: null,
    isExplicit: null,
    inLibrary: null,
    feedbackTokenAdd: null,
    feedbackTokenRemove: null,
    trackNumber: null,
    isEpisode: false,
    description: null,
  );
  for (final (songRunsItemType, value) in parseSongRuns(
    nav(result, SUBTITLE_RUNS) as List,
    skipTypeSpec: true,
  )) {
    switch (songRunsItemType) {
      case SongRunsItemType.ALBUM:
        song.album = value as YtBaseObject?;
      case SongRunsItemType.ARTISTS:
        song.artists = value as List<YtBaseObject>;
      case SongRunsItemType.DURATION_RAW:
        song.durationRaw = value as String?;
      case SongRunsItemType.DURATION_SECONDS:
        song.duration = value as Duration?;
      case SongRunsItemType.VIEWS:
        song.views = value as String?;
      case SongRunsItemType.YEAR:
        song.year = value as int?;
    }
  }
  return song;
}

/// Parses a song from [data].
YtVideo parseSongFlat(JsonMap data, {bool withPlaylistId = false}) {
  final columns = [
    for (var i = 0; i < (data['flexColumns'] as List).length; i++)
      getFlexColumnItem(data, i),
  ];

  final song = YtVideo(
    name: nav(columns.first, TEXT_RUN_TEXT) as String,
    id:
        nav(columns.first, [
              ...TEXT_RUN,
              ...NAVIGATION_VIDEO_ID,
            ], nullIfAbsent: true)
            as String?,
    playlistId: null,
    videoType: VideoType.tryFromValue(
      nav(data, [
            ...PLAY_BUTTON,
            'playNavigationEndpoint',
            ...NAVIGATION_VIDEO_TYPE,
          ], nullIfAbsent: true)
          as String?,
    ),
    views: null,
    durationRaw: null,
    duration: null,
    artists: [],
    thumbnails: YtThumbnails.fromJson(
      List<JsonMap>.from(nav(data, THUMBNAILS) as List),
    ),
    year: null,
    isAvailable: null,
    isSong: true,
    album: null,
    isExplicit: nav(data, BADGE_LABEL, nullIfAbsent: true) != null,
    inLibrary: null,
    feedbackTokenAdd: null,
    feedbackTokenRemove: null,
    trackNumber: null,
    isEpisode: false,
    description: null,
  );

  if (withPlaylistId) {
    song.playlistId =
        nav(data, [
              ...PLAY_BUTTON,
              'playNavigationEndpoint',
              ...WATCH_PLAYLIST_ID,
            ])
            as String;
  }

  final runs = nav(columns[1], TEXT_RUNS) as List;

  for (final (songRunsItemType, value) in parseSongRuns(
    runs,
    skipTypeSpec: true,
  )) {
    switch (songRunsItemType) {
      case SongRunsItemType.ALBUM:
        song.album = value as YtBaseObject?;
      case SongRunsItemType.ARTISTS:
        song.artists = value as List<YtBaseObject>;
      case SongRunsItemType.DURATION_RAW:
        song.durationRaw = value as String?;
      case SongRunsItemType.DURATION_SECONDS:
        song.duration = value as Duration?;
      case SongRunsItemType.VIEWS:
        song.views = value as String?;
      case SongRunsItemType.YEAR:
        song.year = value as int?;
    }
  }

  if (columns.length > 2 &&
      columns[2] != null &&
      (nav(columns[2], TEXT_RUN) as JsonMap).containsKey(
        'navigationEndpoint',
      )) {
    song.album = YtBaseObject(
      id: nav(columns[2], [...TEXT_RUN, ...NAVIGATION_BROWSE_ID]) as String,
      name: nav(columns[2], TEXT_RUN_TEXT) as String,
      type: YtObjectType.OBJECT,
    );
  }

  return song;
}

/// Parses a video from [result].
YtVideo parseVideo(JsonMap result) {
  final JsonMap realResult;
  if (result.containsKey(MTRIR)) {
    realResult = nav(result, [MTRIR]) as JsonMap;
  } else {
    realResult = result;
  }
  final runs = nav(realResult, SUBTITLE_RUNS);
  final artistsLen = getDotSeparatorIndex(runs as List);
  var videoId =
      nav(realResult, NAVIGATION_VIDEO_ID, nullIfAbsent: true) as String?;
  if (videoId == null) {
    for (final entry in nav(realResult, MENU_ITEMS) as Iterable) {
      final candidate =
          nav(entry, [...MENU_SERVICE, ...QUEUE_VIDEO_ID], nullIfAbsent: true)
              as String?;
      if (candidate != null) {
        videoId = candidate;
        break;
      }
    }
  }

  return YtVideo(
    name: nav(realResult, TITLE_TEXT) as String,
    id: videoId,
    playlistId:
        nav(realResult, NAVIGATION_PLAYLIST_ID, nullIfAbsent: true) as String?,
    videoType: null,
    views: (List<JsonMap>.from(runs).last['text'] as String).split(' ').first,
    durationRaw: null,
    duration: null,
    artists: parseArtistsRuns(runs.sublist(0, artistsLen)),
    thumbnails: YtThumbnails.fromJson(
      List<JsonMap>.from(
        nav(realResult, THUMBNAIL_RENDERER, nullIfAbsent: true) as List,
      ),
    ),
    year: null,
    isAvailable: null,
    isSong: false,
    album: null,
    isExplicit: null,
    inLibrary: null,
    feedbackTokenAdd: null,
    feedbackTokenRemove: null,
    trackNumber: null,
    isEpisode: false,
    description: null,
  );
}

/// Parses a playlist from [data].
YtPlaylist parsePlaylist(JsonMap data) {
  final JsonMap realData;
  if (data.containsKey(MTRIR)) {
    realData = nav(data, [MTRIR]) as JsonMap;
  } else {
    realData = data;
  }

  final playlist = YtPlaylist(
    name:
        nav(realData, TITLE_TEXT, nullIfAbsent: true) as String? ??
        '(no title)', // rare but possible for playlist title to be missing
    id: (nav(realData, [...TITLE, ...NAVIGATION_BROWSE_ID]) as String)
        .substring(2),
    playlistType: null,
    authors: [],
    thumbnails: YtThumbnails.fromJson(
      List<JsonMap>.from(nav(realData, THUMBNAIL_RENDERER) as List),
    ),
    description: null,
    duration: null,
    year: null,
    itemCount: null,
    owned: null,
    privacy: null,
    durationRaw: null,
    views: null,
    items: [],
    related: [],
    suggestions: [],
  );

  final subtitle = realData['subtitle'] as JsonMap;
  if (subtitle.containsKey('runs')) {
    playlist.description =
        (subtitle['runs'] as List)
            .map((run) => (run as JsonMap)['text'])
            .join();
    if ((subtitle['runs'] as List).length == 3 &&
        RegExp(r'\d+ ').hasMatch(nav(realData, SUBTITLE2) as String)) {
      playlist.itemCount =
          (nav(realData, SUBTITLE2) as String).split(' ').first as int;
      playlist.authors = parseArtistsRuns(
        (subtitle['runs'] as List).sublist(0, 1),
      );
    }
  }

  return playlist;
}

/// Parses related artists from [data].
YtArtist parseRelatedArtist(JsonMap data) {
  final JsonMap realData;
  if (data.containsKey(MTRIR)) {
    realData = nav(data, [MTRIR]) as JsonMap;
  } else {
    realData = data;
  }
  var subscribers = nav(realData, SUBTITLE, nullIfAbsent: true) as String?;
  if (subscribers != null) {
    subscribers = subscribers.split(' ').first;
  }
  return YtArtist(
    name: nav(realData, TITLE_TEXT) as String,
    id: nav(realData, [...TITLE, ...NAVIGATION_BROWSE_ID]) as String,
    shuffleId: null,
    radioId: null,
    thumbnails: YtThumbnails.fromJson(
      List<JsonMap>.from(nav(realData, THUMBNAIL_RENDERER) as List),
    ),
    subscribers: subscribers,
  );
}

/// Parses watch playlist from [data].
YtPlaylist parseWatchPlaylist(JsonMap data) {
  return YtPlaylist(
    name: nav(data, TITLE_TEXT) as String,
    id: nav(data, NAVIGATION_WATCH_PLAYLIST_ID) as String,
    playlistType: null,
    authors: [],
    thumbnails: YtThumbnails.fromJson(
      List<JsonMap>.from(nav(data, THUMBNAIL_RENDERER) as List),
    ),
    description: null,
    duration: null,
    year: null,
    itemCount: null,
    owned: null,
    privacy: null,
    durationRaw: null,
    views: null,
    items: [],
    related: [],
    suggestions: [],
  );
}
