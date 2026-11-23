import 'package:ytmusicapi_dart/models/objects/artist.dart';
import 'package:ytmusicapi_dart/models/objects/base.dart';
import 'package:ytmusicapi_dart/models/objects/playlist.dart';
import 'package:ytmusicapi_dart/models/objects/video.dart';
import 'package:ytmusicapi_dart/navigation.dart';
import 'package:ytmusicapi_dart/parsers/browsing.dart';
import 'package:ytmusicapi_dart/parsers/podcasts.dart';
import 'package:ytmusicapi_dart/parsers/utils.dart';
import 'package:ytmusicapi_dart/type_alias.dart';
import 'package:ytmusicapi_dart/utils.dart';

// ignore: public_member_api_docs
const Map<String, String> TRENDS = {
  'ARROW_DROP_UP': 'up',
  'ARROW_DROP_DOWN': 'down',
  'ARROW_CHART_NEUTRAL': 'neutral',
};

/// Parses a song from the charts [data].
(YtVideo, ChartRanking) parseChartSong(JsonMap data) {
  final parsed = parseSongFlat(data, withPlaylistId: true);
  return (parsed, parseRanking(data));
}

/// Parses the trending item
YtBaseObject parseTrendingItem(JsonMap data) {
  final videoType = nav(data, [
    ...PLAY_BUTTON,
    'playNavigationEndpoint',
    ...NAVIGATION_VIDEO_TYPE,
  ]);

  if (videoType == 'MUSIC_VIDEO_TYPE_PODCAST_EPISODE') {
    return parseEpisodeFlat(data);
  }

  return parseSongFlat(data, withPlaylistId: true);
}

/// Parses a playlist from the charts [data].
YtPlaylist parseChartPlaylist(JsonMap data) {
  return YtPlaylist(
    name: nav(data, TITLE_TEXT) as String,
    id: (nav(data, [...TITLE, ...NAVIGATION_BROWSE_ID]) as String).substring(2),
    playlistType: null,
    authors: [],
    owned: null,
    privacy: null,
    thumbnails: YtThumbnails.fromJson(
      List<JsonMap>.from(nav(data, THUMBNAIL_RENDERER) as List),
    ),
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
}

/// Parses an episode from the charts [data].
YtVideo parseChartEpisode(JsonMap data) {
  final episode = parseEpisode(data);
  episode.trackNumber = null;
  episode.album = parseIdName(
    nav(data, ['secondTitle', 'runs', 0]) as JsonMap?,
  );
  episode.durationRaw =
      nav(data, [
            'playbackProgress',
            ...PROGRESS_RENDERER,
            ...DURATION_TEXT,
          ], nullIfAbsent: true)
          as String?;
  return episode;
}

/// Parses an artist from the charts [data].
(YtArtist, ChartRanking) parseChartArtist(JsonMap data) {
  dynamic subscribers = getFlexColumnItem(data, 1);
  if (subscribers != null) {
    subscribers = (nav(subscribers, TEXT_RUN_TEXT) as String).split(' ').first;
  }

  final parsed = YtArtist(
    name: nav(getFlexColumnItem(data, 0), TEXT_RUN_TEXT) as String,
    id: nav(data, NAVIGATION_BROWSE_ID) as String,
    shuffleId: null,
    radioId: null,
    thumbnails: YtThumbnails.fromJson(
      List<JsonMap>.from(nav(data, THUMBNAILS) as List),
    ),
    subscribers: subscribers as String?,
  );

  return (parsed, parseRanking(data, nullIfAbsent: true));
}

/// Parses a ranking from the charts [data].
ChartRanking parseRanking(JsonMap data, {bool nullIfAbsent = false}) {
  final trendIconType = nav(data, [
    'customIndexColumn',
    'musicCustomIndexColumnRenderer',
    ...ICON_TYPE,
  ], nullIfAbsent: nullIfAbsent);

  return ChartRanking(
    rank:
        nav(data, [
              'customIndexColumn',
              'musicCustomIndexColumnRenderer',
              ...TEXT_RUN_TEXT,
            ], nullIfAbsent: nullIfAbsent)
            as String?,
    trend: trendIconType != null ? TRENDS[trendIconType] : null,
  );
}
