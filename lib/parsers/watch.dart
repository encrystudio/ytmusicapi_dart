import 'package:ytmusicapi_dart/enums.dart';
import 'package:ytmusicapi_dart/models/content/enums.dart';
import 'package:ytmusicapi_dart/models/objects/base.dart';
import 'package:ytmusicapi_dart/models/objects/video.dart';
import 'package:ytmusicapi_dart/navigation.dart';
import 'package:ytmusicapi_dart/parsers/songs.dart';
import 'package:ytmusicapi_dart/type_alias.dart';

/// Parses a list of watch playlist [results] into a list of track maps.
List<YtVideo> parseWatchPlaylist(List<JsonMap> results) {
  final tracks = <YtVideo>[];
  const PPVWR = 'playlistPanelVideoWrapperRenderer';
  const PPVR = 'playlistPanelVideoRenderer';

  for (var result in results) {
    if (result.containsKey(PPVWR)) {
      result = (result[PPVWR] as JsonMap?)!['primaryRenderer'] as JsonMap;
    }

    if (!result.containsKey(PPVR)) {
      continue;
    }

    final data = result[PPVR] as JsonMap;

    if (data.containsKey('unplayableText')) {
      continue;
    }

    final track = parseWatchTrack(data);

    tracks.add(track);
  }

  return tracks;
}

/// Parses an individual track from a watch playlist.
YtVideo parseWatchTrack(JsonMap data) {
  // TODO
  // LikeStatus? likeStatus;

  for (final item in List<JsonMap>.from(nav(data, MENU_ITEMS) as List)) {
    if (item.containsKey(TOGGLE_MENU)) {
      final service =
          (item[TOGGLE_MENU] as JsonMap)['defaultServiceEndpoint'] as JsonMap;

      if (service.containsKey('likeEndpoint')) {
        // TODO
        // likeStatus = parseLikeStatus(service);
      }
    }
  }

  final songMenuData = parseSongMenuData(data);

  final track = YtVideo(
    name: nav(data, TITLE_TEXT) as String,
    id: data['videoId'] as String?,
    playlistId: null,
    videoType: VideoType.tryFromValue(
      nav(data, [
            'navigationEndpoint',
            ...NAVIGATION_VIDEO_TYPE,
          ], nullIfAbsent: true)
          as String?,
    ),
    views: null,
    durationRaw:
        nav(data, ['lengthText', 'runs', 0, 'text'], nullIfAbsent: true)
            as String?,
    duration: null,
    artists: [],
    thumbnails: YtThumbnails.fromJson(
      List<JsonMap>.from(nav(data, THUMBNAIL) as List),
    ),
    year: null,
    isAvailable: null,
    isEpisode: null,
    isSong: null,
    album: null,
    trackNumber: null,
    isExplicit: null,
    inLibrary: songMenuData.inLibrary,
    feedbackTokenAdd: songMenuData.feedbackTokenAdd,
    feedbackTokenRemove: songMenuData.feedbackTokenRemove,
    description: null,
  );

  final longBylineText = nav(data, ['longBylineText']) as JsonMap?;

  if (longBylineText != null) {
    final songInfo = parseSongRuns(longBylineText['runs'] as List);
    for (final (songRunsItemType, value) in songInfo) {
      switch (songRunsItemType) {
        case SongRunsItemType.ALBUM:
          track.album = value as YtBaseObject;
        case SongRunsItemType.ARTISTS:
          track.artists = value as List<YtBaseObject>;
        case SongRunsItemType.DURATION_RAW:
          track.durationRaw = value as String?;
        case SongRunsItemType.DURATION_SECONDS:
          track.duration = value as Duration?;
        case SongRunsItemType.VIEWS:
          track.views = value as String?;
        case SongRunsItemType.YEAR:
          track.year = value as int?;
      }
    }
  }

  return track;
}

/// Gets the browse IDs in a [watchNextRenderer].
Map<String, String> getTabBrowseIds(JsonMap watchNextRenderer) {
  final browseIds = <String, String>{};

  for (final tab in List<JsonMap>.from(watchNextRenderer['tabs'] as List)) {
    if ((tab['tabRenderer'] as JsonMap).containsKey('unselectable')) {
      continue;
    }

    final browseEndpoint =
        nav(tab, [
              'tabRenderer',
              'endpoint',
              'browseEndpoint',
            ], nullIfAbsent: true)
            as JsonMap?;

    if (browseEndpoint != null) {
      final pageType = nav(browseEndpoint, PAGE_TYPE) as String;

      browseIds[pageType] = browseEndpoint['browseId'] as String;
    }
  }

  return browseIds;
}
