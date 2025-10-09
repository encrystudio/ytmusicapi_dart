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
  JsonMap? feedbackTokens;
  String? likeStatus;
  bool? libraryStatus;

  for (final item in List<JsonMap>.from(nav(data, MENU_ITEMS) as List)) {
    if (item.containsKey(TOGGLE_MENU)) {
      libraryStatus = parseSongLibraryStatus(item);
      final service =
          (item[TOGGLE_MENU] as JsonMap?)!['defaultServiceEndpoint'] as JsonMap;

      if (service.containsKey('feedbackEndpoint')) {
        feedbackTokens = parseSongMenuTokens(item);
      }

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
    'feedbackTokens': feedbackTokens,
    'likeStatus': likeStatus,
    'inLibrary': libraryStatus,
    'videoType': nav(data, [
      'navigationEndpoint',
      ...NAVIGATION_VIDEO_TYPE,
    ], nullIfAbsent: true),
  };

  final longBylineText = nav(data, ['longBylineText']) as JsonMap?;
  if (longBylineText != null) {
    final songInfo = parseSongRuns(longBylineText['runs'] as List);
    track.addAll(songInfo);
  }

  return track;
}

/// Gets the browse ID for a given [tabId] in a [watchNextRenderer].
String? getTabBrowseId(JsonMap watchNextRenderer, int tabId) {
  final tabRenderer =
      ((watchNextRenderer['tabs'] as List)[tabId] as JsonMap?)!['tabRenderer']
          as JsonMap;

  if (!tabRenderer.containsKey('unselectable')) {
    return ((tabRenderer['endpoint'] as JsonMap)['browseEndpoint']
            as JsonMap)['browseId']
        as String;
  } else {
    return null;
  }
}
