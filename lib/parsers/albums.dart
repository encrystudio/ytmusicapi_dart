import 'package:ytmusicapi_dart/enums.dart';
import 'package:ytmusicapi_dart/helpers.dart';
import 'package:ytmusicapi_dart/models/content/enums.dart';
import 'package:ytmusicapi_dart/models/objects/album.dart';
import 'package:ytmusicapi_dart/models/objects/base.dart';
import 'package:ytmusicapi_dart/navigation.dart';
import 'package:ytmusicapi_dart/parsers/artists.dart';
import 'package:ytmusicapi_dart/parsers/songs.dart';
import 'package:ytmusicapi_dart/type_alias.dart';

/// Parse the information in an album header in 2025 format.
YtAlbum parseAlbumHeader2024(JsonMap response) {
  final header =
      nav(response, [
            ...TWO_COLUMN_RENDERER,
            ...TAB_CONTENT,
            ...SECTION_LIST_ITEM,
            ...RESPONSIVE_HEADER,
          ])
          as JsonMap;

  final album = YtAlbum(
    name: nav(header, TITLE_TEXT) as String,
    id: null,
    playlistId: null,
    albumType: YtAlbumType.tryFromName(nav(header, SUBTITLE) as String),
    thumbnails: YtThumbnails.fromJson(
      List<JsonMap>.from(nav(header, THUMBNAILS) as List),
    ),
    artists: [],
    tracks: [],
    durationRaw: null,
    duration: null,
    isExplicit: nav(header, SUBTITLE_BADGE_LABEL, nullIfAbsent: true) != null,
    trackCount: null,
    likeStatus: null,
    description: null,
    year: null,
    relatedRecommendations: [],
    otherVersions: [],
  );

  final (description, descriptionRuns) = parseDescriptionRuns(
    nav(header, [
      'description',
      ...DESCRIPTION_SHELF,
      ...DESCRIPTION_RUN_LIST,
    ], nullIfAbsent: true),
  );

  album.description = description;
  // album.descriptionRuns = descriptionRuns; // TODO

  final albumInfo = parseSongRuns(
    ((header['subtitle'] as JsonMap)['runs'] as List).sublist(2),
  );

  final straplineRuns = nav(header, [
    'straplineTextOne',
    'runs',
  ], nullIfAbsent: true);

  albumInfo.removeWhere((item) => item.$1 == SongRunsItemType.ARTISTS);
  if (straplineRuns != null) {
    albumInfo.add((
      SongRunsItemType.ARTISTS,
      parseArtistsRuns(straplineRuns as List),
    ));
  }

  for (final (songRunsItemType, value) in albumInfo) {
    switch (songRunsItemType) {
      case SongRunsItemType.ALBUM:
        continue;
      case SongRunsItemType.ARTISTS:
        album.artists = value as List<YtBaseObject>;
      case SongRunsItemType.DURATION_RAW:
        album.durationRaw = value as String?;
      case SongRunsItemType.DURATION_SECONDS:
        album.duration = value as Duration?;
      case SongRunsItemType.VIEWS:
        continue; // TODO
      case SongRunsItemType.YEAR:
        album.year = value as int?;
    }
  }

  if (((header['secondSubtitle'] as JsonMap)['runs'] as List).length > 1) {
    album.trackCount = toInt(
      (((header['secondSubtitle'] as JsonMap)['runs'] as List).first
              as JsonMap)['text']
          as String,
    );
    album.durationRaw =
        (((header['secondSubtitle'] as JsonMap)['runs'] as List)[2]
                as JsonMap)['text']
            as String;
  } else {
    album.durationRaw =
        (((header['secondSubtitle'] as JsonMap)['runs'] as List).first
                as JsonMap)['text']
            as String;
  }

  // add to library/uploaded
  final buttons = header['buttons'];
  album.playlistId =
      nav(findObjectByKey(buttons as List, 'musicPlayButtonRenderer'), [
            'musicPlayButtonRenderer',
            'playNavigationEndpoint',
            ...WATCH_PID,
          ], nullIfAbsent: true)
          as String?;

  // remove this once A/B testing is finished and it is no longer covered
  album.playlistId ??=
      nav(findObjectByKey(buttons, 'musicPlayButtonRenderer'), [
            'musicPlayButtonRenderer',
            'playNavigationEndpoint',
            ...WATCH_PLAYLIST_ID,
          ], nullIfAbsent: true)
          as String?;

  final service = nav(findObjectByKey(buttons, 'toggleButtonRenderer'), [
    'toggleButtonRenderer',
    'defaultServiceEndpoint',
  ], nullIfAbsent: true);

  album.likeStatus = LikeStatus.INDIFFERENT;
  if (service != null) {
    album.likeStatus = parseLikeStatus(service as JsonMap);
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
