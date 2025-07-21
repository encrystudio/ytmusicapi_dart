import 'dart:math';

import '../navigation.dart';

int? parseDuration(String? duration) {
  if (duration == null || duration.isEmpty || duration.trim().isEmpty) {
    return null;
  }

  var durationSplit = duration.trim().split(":");
  for (var d in durationSplit) {
    if (!isDigit(d)) {
      return null;
    }
  }

  List<String> parts = duration.split(':').reversed.toList();
  int seconds = 0;

  for (int i = 0; i < parts.length; i++) {
    seconds += int.parse(parts[i]) * pow(60, i).toInt();
  }

  return seconds;
}

bool isDigit(String s) {
  return RegExp(r'^\d+$').hasMatch(s);
}

Map<String, dynamic>? getFlexColumnItem(Map<String, dynamic> item, int index) {
  if (item['flexColumns'].length <= index ||
      !item['flexColumns'][index]['musicResponsiveListItemFlexColumnRenderer']
          .containsKey('text') ||
      !item['flexColumns'][index]['musicResponsiveListItemFlexColumnRenderer']['text']
          .containsKey('runs')) {
    return null;
  }
  return item['flexColumns'][index]['musicResponsiveListItemFlexColumnRenderer'];
}

String? getItemText(
  Map<String, dynamic> item,
  int index, {
  int runIndex = 0,
  bool nullIfAbsent = false,
}) {
  var column = getFlexColumnItem(item, index);

  if (column == null) {
    return null;
  }
  if (nullIfAbsent && column['text']['runs'].length < runIndex + 1) {
    return null;
  }

  return column['text']['runs'][runIndex]['text'];
}

void parseMenuPlaylists(
  Map<String, dynamic> data,
  Map<String, dynamic> result,
) {
  var menuItems_ = nav(data, menuItems, nullIfAbsent: true);
  if (menuItems_ == null) {
    return;
  }
  var watchMenu = findObjectsByKey(menuItems_, mnir);
  var watchMenuMnir = [];
  for (var element in watchMenu) {
    watchMenuMnir.add(element[mnir]);
  }
  for (var item in watchMenuMnir) {
    var watchKey = '';
    var icon = nav(item, iconType);
    if (icon == 'MUSIC_SHUFFLE') {
      watchKey = 'shuffleId';
    } else if (icon == 'MIX') {
      watchKey = 'radioId';
    } else {
      continue;
    }

    var watchId = nav(item, [
      'navigationEndpoint',
      'watchPlaylistEndpoint',
      'playlistId',
    ], nullIfAbsent: true);
    if (watchMenu.isNotEmpty) {
      watchId = nav(item, [
        'navigationEndpoint',
        'watchEndpoint',
        'playlistId',
      ], nullIfAbsent: true);
    }
    if (watchId != null) {
      result[watchKey] = watchId;
    }
  }
}

Map<String, dynamic> parseIdName(Map<String, dynamic>? subRun) {
  return {
    'id': nav(subRun, navigationBrowseId, nullIfAbsent: true),
    'name': nav(subRun, ['text'], nullIfAbsent: true),
  };
}
