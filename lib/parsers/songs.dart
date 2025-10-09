import 'dart:core';

import 'package:ytmusicapi_dart/navigation.dart';
import 'package:ytmusicapi_dart/parsers/constants.dart';
import 'package:ytmusicapi_dart/parsers/search.dart';
import 'package:ytmusicapi_dart/parsers/utils.dart';
import 'package:ytmusicapi_dart/type_alias.dart';

/// Parses artists of a song.
List parseSongArtists(JsonMap data, int index) {
  final flexItem = getFlexColumnItem(data, index);
  if (flexItem == null) return [];
  final runs = (flexItem['text'] as JsonMap)['runs'] as List;
  return parseSongArtistsRuns(runs);
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
    // note: YT uses non-breaking space \xa0 to separate number and magnitude
    final viewsReg = RegExp(r'^\d([^ ])* [^ ]*$');
    final durationReg = RegExp(r'^(\d+:)*\d+:\d+$');
    final yearReg = RegExp(r'^\d{4}$');

    if (viewsReg.hasMatch(text as String)) {
      return {'type': 'views', 'data': text.split(' ')[0]};
    } else if (durationReg.hasMatch(text)) {
      return {'type': 'duration', 'data': text};
    } else if (yearReg.hasMatch(text)) {
      return {'type': 'year', 'data': text};
    } else if (!API_RESULT_TYPES.contains(text.toLowerCase())) {
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
JsonMap parseSongRuns(List runs, {bool skipTypeSpec = false}) {
  final parsed = <String, dynamic>{};

  final List realRuns;
  if (skipTypeSpec &&
      runs.length > 2 &&
      parseSongRun(runs[0] as JsonMap)['type'] == 'artist' &&
      runs[1] == DOT_SEPARATOR_RUN &&
      parseSongRun(runs[2] as JsonMap)['type'] == 'artist') {
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
        parsed['album'] = data;
      case 'artist':
        parsed['artists'] ??= <JsonMap>[];
        (parsed['artists'] as List).add(data);
      case 'views':
        parsed['views'] = data;
      case 'duration':
        parsed['duration'] = data;
        parsed['duration_seconds'] = parseDuration(data as String?);
      case 'year':
        parsed['year'] = data;
    }
  }

  return parsed;
}

/// Parses album of a song.
JsonMap? parseSongAlbum(JsonMap data, int index) {
  final flexItem = getFlexColumnItem(data, index);
  if (flexItem == null) return null;
  final browseId = nav(flexItem, [
    ...TEXT_RUN,
    NAVIGATION_BROWSE_ID,
  ], nullIfAbsent: true);
  return {'name': getItemText(data, index), 'id': browseId};
}

/// Parses library status of a song.
bool parseSongLibraryStatus(JsonMap item) {
  final libraryStatus = nav(item, [
    TOGGLE_MENU,
    'defaultIcon',
    'iconType',
  ], nullIfAbsent: true);
  return libraryStatus == 'LIBRARY_SAVED';
}

/// Parses menu tokens of a song.
Map<String, String?> parseSongMenuTokens(JsonMap item) {
  final toggleMenu = item[TOGGLE_MENU] as JsonMap;
  String? libraryAddToken =
      nav(toggleMenu, [
            'defaultServiceEndpoint',
            ...FEEDBACK_TOKEN,
          ], nullIfAbsent: true)
          as String?;
  String? libraryRemoveToken =
      nav(toggleMenu, [
            'toggledServiceEndpoint',
            ...FEEDBACK_TOKEN,
          ], nullIfAbsent: true)
          as String?;

  final inLibrary = parseSongLibraryStatus(item);
  if (inLibrary) {
    final temp = libraryAddToken;
    libraryAddToken = libraryRemoveToken;
    libraryRemoveToken = temp;
  }

  return {'add': libraryAddToken, 'remove': libraryRemoveToken};
}

/// Parses like status.
String parseLikeStatus(JsonMap service) {
  final status = ['LIKE', 'INDIFFERENT'];
  final idx =
      status.indexOf((service['likeEndpoint'] as JsonMap)['status'] as String) -
      1;
  return status[idx < 0 ? 0 : idx];
}
