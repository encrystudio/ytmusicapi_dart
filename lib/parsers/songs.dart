import 'dart:core';

import 'package:ytmusicapi_dart/enums.dart';
import 'package:ytmusicapi_dart/models/content/enums.dart';
import 'package:ytmusicapi_dart/models/objects/base.dart';
import 'package:ytmusicapi_dart/navigation.dart';
import 'package:ytmusicapi_dart/parsers/artists.dart';
import 'package:ytmusicapi_dart/parsers/utils.dart';
import 'package:ytmusicapi_dart/type_alias.dart';
import 'package:ytmusicapi_dart/utils.dart';

/// Parses artists of a song.
List<YtBaseObject> parseSongArtists(JsonMap data, int index) {
  final flexItem = getFlexColumnItem(data, index);

  if (flexItem == null || flexItem.isEmpty) {
    return [];
  } else {
    final runs = (flexItem['text'] as JsonMap)['runs'] as List;
    return parseArtistsRuns(runs);
  }
}

/// leading views word ("조회수 17억회", "播放次數：4505") or bidi mark (ur), up to the first digit
final viewsPrefix = RegExp(r'^\D*?[\s:\uff1a\u200e-\u200f\u202a-\u202e]');

/// Parses views
String? parseViews(String text) {
  String localText = text;
  // only for non-latin scripts: "Maroon 5" is indistinguishable from a prefixed count
  var prefixed = 0;

  if (!RegExp('[a-zA-Z]').hasMatch(localText)) {
    final match = viewsPrefix.firstMatch(localText);

    if (match != null) {
      localText = localText.substring(match.end);
      prefixed = 1;
    }
  }

  if (!RegExp(r'^\d').hasMatch(localText)) {
    return null;
  }

  // a bare ASCII token like "2Pac" is an artist, not a view count with a stripped word
  if (prefixed == 0 && localText.isAscii && !localText.contains(' ')) {
    return null;
  }

  // note: \xa0 glues number and magnitude ("1,7\xa0Mrd. Aufrufe"), but some locales use
  // it before the views word too ("88\xa0k\xa0vues"); CJK has no separator ("3406万回視聴")
  final head = localText.split(' ').first.split('\xa0');

  return head.take(2).join('\xa0');
}

/// Parses information from artist [runs].
List parseSongArtistsRuns(List runs) {
  final artists = <JsonMap>[];
  for (var j = 0; j < (runs.length / 2).ceil(); j++) {
    final run = runs[j * 2] as JsonMap;
    artists.add({
      'name': run['text'],
      'id': nav(run, NAVIGATION_BROWSE_ID, nullIfAbsent: true),
    });
  }
  return artists;
}

/// Parses song [run].
JsonMap parseSongRun(JsonMap run) {
  final text = run['text'];
  if (run.containsKey('navigationEndpoint')) {
    final item = {
      'name': text,
      'id': nav(run, NAVIGATION_BROWSE_ID, nullIfAbsent: true),
    };
    final id = item['id'] as String?;
    if (id != null &&
        (id.startsWith('MPRE') || id.contains('release_detail'))) {
      return {'type': 'album', 'data': item};
    } else {
      return {'type': 'artist', 'data': item};
    }
  } else {
    final durationReg = RegExp(r'^(\d+:)*\d+:\d+$');
    final yearReg = RegExp(r'^\d{4}$');

    if (durationReg.hasMatch(text as String)) {
      return {'type': 'durationRaw', 'data': text};
    } else if (yearReg.hasMatch(text)) {
      return {'type': 'year', 'data': text};
    } else if (parseViews(text) != null) {
      return {'type': 'views', 'data': parseViews(text)};
    } else if (!YtResultType.values.any(
      (type) => type.name == text.toLowerCase(),
    )) {
      return {
        'type': 'artist',
        'data': {'name': text, 'id': null},
      };
    } else {
      return {'type': 'other', 'data': null};
    }
  }
}

/// Parses song [runs].
List<(SongRunsItemType, dynamic)> parseSongRuns(
  List runs, {
  bool skipTypeSpec = false,
}) {
  final parsed = <(SongRunsItemType, dynamic)>[];

  final List realRuns;
  if (skipTypeSpec &&
      runs.length > 2 &&
      !(runs.first as JsonMap).containsKey('navigationEndpoint') &&
      parseSongRun(runs.first as JsonMap)['type'] == 'artist' &&
      runs[1] == DOT_SEPARATOR_RUN &&
      [
        'artist',
        'duration',
        'views',
        'year',
      ].contains(parseSongRun(runs[2] as JsonMap)['type'])) {
    realRuns = runs.sublist(2);
  } else {
    realRuns = runs;
  }

  for (var i = 0; i < realRuns.length; i++) {
    if (i % 2 != 0) continue; // uneven items are separators
    final parsedRun = parseSongRun(realRuns[i] as JsonMap);
    final data = parsedRun['data'];
    switch (parsedRun['type']) {
      case 'album':
        parsed.add((
          SongRunsItemType.ALBUM,
          YtBaseObject(
            id: (data as JsonMap)['id'] as String?,
            name: data['name'] as String,
            type: YtObjectType.OBJECT,
          ),
        ));
      case 'artist':
        parsed.add((
          SongRunsItemType.ARTISTS,
          [
            YtBaseObject(
              id: (data as JsonMap)['id'] as String?,
              name: data['name'] as String,
              type: YtObjectType.OBJECT,
            ),
          ],
        ));
      case 'views':
        parsed.add((SongRunsItemType.VIEWS, data as String?));
      case 'durationRaw':
        parsed.add((
          SongRunsItemType.DURATION_SECONDS,
          parseDuration(data as String?),
        ));
        parsed.add((SongRunsItemType.DURATION_RAW, data));
      case 'year':
        parsed.add((SongRunsItemType.YEAR, int.tryParse(data as String)));
    }
  }

  return parsed;
}

/// Parses album of a song.
YtBaseObject? parseSongAlbum(JsonMap data, int index) {
  final flexItem = getFlexColumnItem(data, index);
  if (flexItem == null) return null;
  final browseId =
      nav(flexItem, [...TEXT_RUN, NAVIGATION_BROWSE_ID], nullIfAbsent: true)
          as String?;
  return YtBaseObject(
    id: browseId,
    name: getItemText(data, index)!,
    type: YtObjectType.OBJECT,
  );
}

/// Returns a map with data from the provided song's context menu.
///
/// Example:
///     {
///       "inLibrary": true,
///       "feedbackTokens": {
///         "add": "...",
///         "remove": "..."
///       },
///       "pinnedToListenAgain": true,
///       "listenAgainFeedbackTokens": {
///         "pin": "...",
///         "unpin": "..."
///       }
///     }
SongMenuData parseSongMenuData(JsonMap data) {
  final songData = SongMenuData();
  if (!data.containsKey('menu')) {
    return songData;
  }

  for (final item in nav(data, MENU_ITEMS) as List) {
    final menuItem =
        (nav(item, [TOGGLE_MENU], nullIfAbsent: true) ??
                nav(item, ['menuServiceItemRenderer'], nullIfAbsent: true))
            as JsonMap?;

    if (menuItem == null) {
      continue;
    }

    songData.inLibrary ??= false;
    songData.pinnedToListenAgain ??= false;

    final currentIconType =
        nav(menuItem, ['defaultIcon', 'iconType'], nullIfAbsent: true) ??
        nav(menuItem, ['icon', 'iconType'], nullIfAbsent: true);

    String? feedbackToken(String endpointType) {
      return nav(menuItem, [
            endpointType,
            ...FEEDBACK_TOKEN,
          ], nullIfAbsent: true)
          as String?;
    }

    // YTM signals the current state with isToggled instead of swapping the default/toggled icons
    final isToggled = menuItem['isToggled'] == true;

    switch (currentIconType) {
      case 'KEEP': // pin to listen again
        songData.pinnedToListenAgain = isToggled;
        songData.listenAgainFeedbackTokenPin = feedbackToken(
          'defaultServiceEndpoint',
        );
        songData.listenAgainFeedbackTokenUnpin = feedbackToken(
          'toggledServiceEndpoint',
        );

      case 'KEEP_OFF': // unpin from listen again
        songData.pinnedToListenAgain = true;
        songData.listenAgainFeedbackTokenPin = feedbackToken(
          'toggledServiceEndpoint',
        );
        songData.listenAgainFeedbackTokenUnpin = feedbackToken(
          'defaultServiceEndpoint',
        );

      case 'BOOKMARK_BORDER': // add to library
        songData.inLibrary = isToggled;
        songData.feedbackTokenAdd = feedbackToken('defaultServiceEndpoint');
        songData.feedbackTokenRemove = feedbackToken('toggledServiceEndpoint');

      case 'BOOKMARK': // remove from library
        songData.inLibrary = true;
        songData.feedbackTokenAdd = feedbackToken('toggledServiceEndpoint');
        songData.feedbackTokenRemove = feedbackToken('defaultServiceEndpoint');

      case 'REMOVE_FROM_HISTORY':
        songData.feedbackToken = feedbackToken('serviceEndpoint');
    }
  }

  return songData;
}

/// Parses like status.
LikeStatus parseLikeStatus(JsonMap service) {
  final status = ['LIKE', 'INDIFFERENT'];
  final idx =
      status.indexOf((service['likeEndpoint'] as JsonMap)['status'] as String) -
      1;
  return LikeStatus.fromValue(status[idx < 0 ? 0 : idx]);
}
