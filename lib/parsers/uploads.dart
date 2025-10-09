import 'package:ytmusicapi_dart/navigation.dart';
import 'package:ytmusicapi_dart/parsers/songs.dart';
import 'package:ytmusicapi_dart/parsers/utils.dart';
import 'package:ytmusicapi_dart/type_alias.dart';

/// Parses uploaded items.
List parseUploadedItems(List<JsonMap> results) {
  final songs = <JsonMap>[];

  for (final result in results) {
    final data = result[MRLIR] as JsonMap;
    if (!data.containsKey('menu')) continue;

    final entityId = nav(data, [
      ...MENU_ITEMS,
      -1,
      MNIR,
      'navigationEndpoint',
      'confirmDialogEndpoint',
      'content',
      'confirmDialogRenderer',
      'confirmButton',
      'buttonRenderer',
      'command',
      'musicDeletePrivatelyOwnedEntityCommand',
      'entityId',
    ]);

    final videoId =
        (((nav(data, [...MENU_ITEMS, 0, ...MENU_SERVICE])
                    as JsonMap)['queueAddEndpoint']
                as JsonMap)['queueTarget']
            as JsonMap)['videoId'];

    final title = getItemText(data, 0);
    final like = nav(data, MENU_LIKE_STATUS);
    final thumbnails =
        data.containsKey('thumbnail') ? nav(data, THUMBNAILS) : null;

    String? duration;
    if (data.containsKey('fixedColumns')) {
      duration = nav(getFixedColumnItem(data, 0), TEXT_RUN_TEXT) as String?;
    }

    final song = {
      'entityId': entityId,
      'videoId': videoId,
      'title': title,
      'duration': duration,
      'duration_seconds': parseDuration(duration),
      'artists': parseSongArtists(data, 1),
      'album': parseSongAlbum(data, 2),
      'likeStatus': like,
      'thumbnails': thumbnails,
    };

    songs.add(song);
  }

  return songs;
}
