import 'package:ytmusicapi_dart/navigation.dart';
import 'package:ytmusicapi_dart/parsers/songs.dart';
import 'package:ytmusicapi_dart/type_alias.dart';

/// Parses a list of watch playlist [results] into a list of track maps.
List parseWatchPlaylist(List<JsonMap> results) {
  final List tracks = [];
  const String PPVWR = 'playlistPanelVideoWrapperRenderer';
  const String PPVR = 'playlistPanelVideoRenderer';

  for (var result in results) {
    JsonMap? counterpart;
    if (result.containsKey(PPVWR)) {
      counterpart =
          ((((result[PPVWR] as JsonMap?)!['counterpart'] as List)[0]
                      as JsonMap)['counterpartRenderer']
                  as JsonMap)[PPVR]
              as JsonMap?;
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

    if (counterpart != null) {
      track['counterpart'] = parseWatchTrack(counterpart);
    }

    tracks.add(track);
  }

  return tracks;
}

/// Parses an individual track from a watch playlist.
JsonMap parseWatchTrack(JsonMap data) {
  String? likeStatus;

  for (final item in List<JsonMap>.from(nav(data, MENU_ITEMS) as List)) {
    if (item.containsKey(TOGGLE_MENU)) {
      final service =
          (item[TOGGLE_MENU] as JsonMap)['defaultServiceEndpoint'] as JsonMap;

      if (service.containsKey('likeEndpoint')) {
        likeStatus = parseLikeStatus(service);
      }
    }
  }

  final track = <String, dynamic>{
    'videoId': data['videoId'],
    'title': nav(data, TITLE_TEXT),
    'length': nav(data, ['lengthText', 'runs', 0, 'text'], nullIfAbsent: true),
    'thumbnail': nav(data, THUMBNAIL),
    'likeStatus': likeStatus,
    'videoType': nav(data, [
      'navigationEndpoint',
      ...NAVIGATION_VIDEO_TYPE,
    ], nullIfAbsent: true),
  };

  track.addAll({
    'inLibrary': null,
    'feedbackTokens': null,
    'pinnedToListenAgain': null,
    'listenAgainFeedbackTokens': null,
    ...parseSongMenuData(data),
  });

  final longBylineText = nav(data, ['longBylineText']) as JsonMap?;

  if (longBylineText != null) {
    final songInfo = parseSongRuns(longBylineText['runs'] as List);
    track.addAll(songInfo);
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
