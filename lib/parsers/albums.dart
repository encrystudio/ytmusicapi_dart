import 'package:ytmusicapi_dart/helpers.dart';
import 'package:ytmusicapi_dart/navigation.dart';
import 'package:ytmusicapi_dart/parsers/podcasts.dart';
import 'package:ytmusicapi_dart/parsers/songs.dart';
import 'package:ytmusicapi_dart/type_alias.dart';

/// Parse the information in an album header.
JsonMap parseAlbumHeader(JsonMap response) {
  final header = nav(response, HEADER_DETAIL) as JsonMap;
  final album = <String, dynamic>{
    'title': nav(header, TITLE_TEXT),
    'type': nav(header, SUBTITLE),
    'thumbnails': nav(header, THUMBNAIL_CROPPED),
    'isExplicit': nav(header, SUBTITLE_BADGE_LABEL, nullIfAbsent: true) != null,
  };

  if (header.containsKey('description')) {
    album['description'] =
        (((header['description'] as JsonMap)['runs'] as List)[0]
            as JsonMap)['text'];
  }

  final albumInfo = parseSongRuns(
    ((header['subtitle'] as JsonMap)['runs'] as List).sublist(2),
  );
  album.addAll(albumInfo);

  if (((header['secondSubtitle'] as JsonMap)['runs'] as List).length > 1) {
    album['trackCount'] = toInt(
      (((header['secondSubtitle'] as JsonMap)['runs'] as List)[0]
              as JsonMap)['text']
          as String,
    );
    album['duration'] =
        (((header['secondSubtitle'] as JsonMap)['runs'] as List)[2]
            as JsonMap)['text'];
  } else {
    album['duration'] =
        (((header['secondSubtitle'] as JsonMap)['runs'] as List)[0]
            as JsonMap)['text'];
  }

  // add to library/uploaded
  final menu = nav(header, MENU) as JsonMap;
  final toplevel = menu['topLevelButtons'];
  album['audioPlaylistId'] = nav(toplevel, [
    0,
    'buttonRenderer',
    ...NAVIGATION_WATCH_PLAYLIST_ID,
  ], nullIfAbsent: true);
  if (album['audioPlaylistId'] == null) {
    album['audioPlaylistId'] = nav(toplevel, [
      0,
      'buttonRenderer',
      ...NAVIGATION_PLAYLIST_ID,
    ], nullIfAbsent: true);
  }
  final service = nav(toplevel, [
    1,
    'buttonRenderer',
    'defaultServiceEndpoint',
  ], nullIfAbsent: true);
  if (service != null) {
    album['likeStatus'] = parseLikeStatus(service as JsonMap);
  }

  return album;
}

/// Parse the information in an album header in 2025 format.
JsonMap parseAlbumHeader2024(JsonMap response) {
  final header =
      nav(response, [
            ...TWO_COLUMN_RENDERER,
            ...TAB_CONTENT,
            ...SECTION_LIST_ITEM,
            ...RESPONSIVE_HEADER,
          ])
          as JsonMap;
  final album = <String, dynamic>{
    'title': nav(header, TITLE_TEXT),
    'type': nav(header, SUBTITLE),
    'thumbnails': nav(header, THUMBNAILS),
    'isExplicit': nav(header, SUBTITLE_BADGE_LABEL, nullIfAbsent: true) != null,
  };

  album['description'] = nav(header, [
    'description',
    ...DESCRIPTION_SHELF,
    ...DESCRIPTION,
  ], nullIfAbsent: true);

  final albumInfo = parseSongRuns(
    ((header['subtitle'] as JsonMap)['runs'] as List).sublist(2),
  );
  final baseAuthor = parseBaseHeader(header)['author'];
  albumInfo['artists'] = baseAuthor != null ? [baseAuthor] : null;
  album.addAll(albumInfo);
  if (((header['secondSubtitle'] as JsonMap)['runs'] as List).length > 1) {
    album['trackCount'] = toInt(
      (((header['secondSubtitle'] as JsonMap)['runs'] as List)[0]
              as JsonMap)['text']
          as String,
    );
    album['duration'] =
        (((header['secondSubtitle'] as JsonMap)['runs'] as List)[2]
            as JsonMap)['text'];
  } else {
    album['duration'] =
        (((header['secondSubtitle'] as JsonMap)['runs'] as List)[0]
            as JsonMap)['text'];
  }

  // add to library/uploaded
  final buttons = header['buttons'];
  album['audioPlaylistId'] = nav(
    findObjectByKey(buttons as List, 'musicPlayButtonRenderer'),
    ['musicPlayButtonRenderer', 'playNavigationEndpoint', ...WATCH_PID],
    nullIfAbsent: true,
  );

  // remove this once A/B testing is finished and it is no longer covered
  if (album['audioPlaylistId'] == null) {
    album['audioPlaylistId'] = nav(
      findObjectByKey(buttons, 'musicPlayButtonRenderer'),
      [
        'musicPlayButtonRenderer',
        'playNavigationEndpoint',
        ...WATCH_PLAYLIST_ID,
      ],
      nullIfAbsent: true,
    );
  }

  final service = nav(findObjectByKey(buttons, 'toggleButtonRenderer'), [
    'toggleButtonRenderer',
    'defaultServiceEndpoint',
  ], nullIfAbsent: true);

  album['likeStatus'] = 'INDIFFERENT';
  if (service != null) {
    album['likeStatus'] = parseLikeStatus(service as JsonMap);
  }

  return album;
}

/// Parses the `playlistId` of an album.
String? parseAlbumPlaylistIdIfExists(JsonMap? data) {
  // the content of the data changes based on whether the user is authenticated or not
  if (data == null) return null;
  return (nav(data, WATCH_PID, nullIfAbsent: true) ??
          nav(data, WATCH_PLAYLIST_ID, nullIfAbsent: true))
      as String?;
}
