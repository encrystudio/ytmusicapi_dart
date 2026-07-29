import 'package:ytmusicapi_dart/navigation.dart';
import 'package:ytmusicapi_dart/type_alias.dart';

/// Returns artist names and IDs. Skips every other run to avoid separators.
List<JsonMap> parseArtistsRuns(List<dynamic> runs) {
  final artists = <JsonMap>[];

  for (var j = 0; j < (runs.length / 2).floor() + 1; j++) {
    final run = runs[j * 2] as JsonMap;

    artists.add({
      'name': run['text'],
      'id': nav(run, NAVIGATION_BROWSE_ID, nullIfAbsent: true),
    });
  }

  return artists;
}
