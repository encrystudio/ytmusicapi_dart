import 'package:ytmusicapi_dart/enums.dart';
import 'package:ytmusicapi_dart/models/objects/base.dart';
import 'package:ytmusicapi_dart/navigation.dart';
import 'package:ytmusicapi_dart/type_alias.dart';

/// Returns artist names and IDs. Skips every other run to avoid separators.
List<YtBaseObject> parseArtistsRuns(List<dynamic> runs) {
  final artists = <YtBaseObject>[];

  for (var j = 0; j < (runs.length / 2).floor() + 1; j++) {
    final run = runs[j * 2] as JsonMap;

    artists.add(
      YtBaseObject(
        id: nav(run, NAVIGATION_BROWSE_ID, nullIfAbsent: true) as String?,
        name: run['text'] as String,
        type: YtObjectType.OBJECT,
      ),
    );
  }

  return artists;
}
