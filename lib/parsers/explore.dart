import 'package:ytmusicapi_dart/navigation.dart';
import 'package:ytmusicapi_dart/parsers/browsing.dart';
import 'package:ytmusicapi_dart/parsers/podcasts.dart';
import 'package:ytmusicapi_dart/parsers/utils.dart';
import 'package:ytmusicapi_dart/type_alias.dart';

// ignore: public_member_api_docs
const Map<String, String> TRENDS = {
  'ARROW_DROP_UP': 'up',
  'ARROW_DROP_DOWN': 'down',
  'ARROW_CHART_NEUTRAL': 'neutral',
};

/// Parses a song from the charts [data].
JsonMap parseChartSong(JsonMap data) {
  final parsed = parseSongFlat(data, withPlaylistId: true);
  parsed.addAll(parseRanking(data));
  return parsed;
}

/// Parses the trending item
JsonMap parseTrendingItem(JsonMap data) {
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
JsonMap parseChartPlaylist(JsonMap data) {
  return {
    'title': nav(data, TITLE_TEXT),
    'playlistId': (nav(data, [...TITLE, ...NAVIGATION_BROWSE_ID]) as String)
        .substring(2),
    'thumbnails': nav(data, THUMBNAIL_RENDERER),
  };
}

/// Parses an episode from the charts [data].
JsonMap parseChartEpisode(JsonMap data) {
  final episode = parseEpisode(data);
  episode.remove('index');
  episode['podcast'] = parseIdName(
    nav(data, ['secondTitle', 'runs', 0]) as JsonMap?,
  );
  episode['duration'] = nav(data, [
    'playbackProgress',
    ...PROGRESS_RENDERER,
    ...DURATION_TEXT,
  ], nullIfAbsent: true);
  return episode;
}

/// Parses an artist from the charts [data].
JsonMap parseChartArtist(JsonMap data) {
  dynamic subscribers = getFlexColumnItem(data, 1);
  if (subscribers != null) {
    subscribers = (nav(subscribers, TEXT_RUN_TEXT) as String).split(' ')[0];
  }

  final parsed = <String, dynamic>{
    'title': nav(getFlexColumnItem(data, 0), TEXT_RUN_TEXT),
    'browseId': nav(data, NAVIGATION_BROWSE_ID),
    'subscribers': subscribers,
    'thumbnails': nav(data, THUMBNAILS),
  };

  parsed.addAll(parseRanking(data, nullIfAbsent: true));
  return parsed;
}

/// Parses a ranking from the charts [data].
JsonMap parseRanking(JsonMap data, {bool nullIfAbsent = false}) {
  final trendIconType = nav(data, [
    'customIndexColumn',
    'musicCustomIndexColumnRenderer',
    ...ICON_TYPE,
  ], nullIfAbsent: nullIfAbsent);

  return {
    'rank': nav(data, [
      'customIndexColumn',
      'musicCustomIndexColumnRenderer',
      ...TEXT_RUN_TEXT,
    ], nullIfAbsent: nullIfAbsent),
    'trend': trendIconType != null ? TRENDS[trendIconType] : null,
  };
}
