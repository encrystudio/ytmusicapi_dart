import 'package:ytmusicapi_dart/navigation.dart';
import 'package:ytmusicapi_dart/parsers/constants.dart';
import 'package:ytmusicapi_dart/type_alias.dart';

/// Parses menu playlists.
void parseMenuPlaylists(JsonMap data, JsonMap result) {
  final menuItems = nav(data, MENU_ITEMS, nullIfAbsent: true);
  if (menuItems == null) return;

  final watchMenu = List<JsonMap>.from(
    findObjectsByKey(menuItems as List, MNIR),
  );
  for (final item in watchMenu.map((x) => x[MNIR])) {
    final icon = nav(item, ICON_TYPE);
    String? watchKey;
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
    watchId ??= nav(item, [
      'navigationEndpoint',
      'watchEndpoint',
      'playlistId',
    ], nullIfAbsent: true);
    if (watchId != null) {
      result[watchKey] = watchId;
    }
  }
}

/// Get text of an item.
String? getItemText(
  JsonMap item,
  int index, {
  int runIndex = 0,
  bool noneIfAbsent = false,
}) {
  final column = getFlexColumnItem(item, index);
  if (column == null) return null;
  final runs = (column['text'] as JsonMap)['runs'] as List;
  if (noneIfAbsent && runs.length < runIndex + 1) return null;

  return (runs[runIndex] as JsonMap)['text'] as String;
}

/// Get flex column.
JsonMap? getFlexColumnItem(JsonMap item, int index) {
  final flexColumns = item['flexColumns'] as List;
  if (flexColumns.length <= index) return null;
  final column =
      (flexColumns[index]
              as JsonMap)['musicResponsiveListItemFlexColumnRenderer']
          as JsonMap;
  if (!column.containsKey('text') ||
      !(column['text'] as JsonMap).containsKey('runs')) {
    return null;
  }

  return column;
}

/// Get fixed column item.
JsonMap? getFixedColumnItem(JsonMap item, int index) {
  final fixedColumns = item['fixedColumns'] as List;
  final column =
      (fixedColumns[index]
              as JsonMap)['musicResponsiveListItemFixedColumnRenderer']
          as JsonMap;
  if (!column.containsKey('text') ||
      !(column['text'] as JsonMap).containsKey('runs')) {
    return null;
  }

  return column;
}

/// Get index of dot separator.
int getDotSeparatorIndex(List runs) {
  final index = runs.indexOf(DOT_SEPARATOR_RUN);
  return index >= 0 ? index : runs.length;
}

/// Parses [duration] in seconds.
int? parseDuration(String? duration) {
  if (duration == null || duration.trim().isEmpty) return null;
  final durationSplit = duration.trim().split(':');
  if (durationSplit.any((d) => int.tryParse(d.replaceAll(',', '')) == null)) {
    return null;
  }

  final multipliers = [1, 60, 3600];
  final seconds = <int>[];
  for (var i = 0; i < durationSplit.length; i++) {
    final value = int.parse(durationSplit[durationSplit.length - 1 - i]);
    seconds.add(value * multipliers[i]);
  }
  return seconds.reduce((a, b) => a + b);
}

/// Parses id and name.
JsonMap parseIdName(JsonMap? subRun) {
  return {
    'id': nav(subRun, NAVIGATION_BROWSE_ID, nullIfAbsent: true),
    'name': nav(subRun, ['text'], nullIfAbsent: true),
  };
}
