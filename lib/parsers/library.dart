import 'package:ytmusicapi_dart/continuations.dart';
import 'package:ytmusicapi_dart/enums.dart';
import 'package:ytmusicapi_dart/models/objects/album.dart';
import 'package:ytmusicapi_dart/models/objects/artist.dart';
import 'package:ytmusicapi_dart/models/objects/base.dart';
import 'package:ytmusicapi_dart/navigation.dart';
import 'package:ytmusicapi_dart/parsers/browsing.dart';
import 'package:ytmusicapi_dart/parsers/playlists.dart';
import 'package:ytmusicapi_dart/parsers/podcasts.dart';
import 'package:ytmusicapi_dart/parsers/songs.dart';
import 'package:ytmusicapi_dart/parsers/utils.dart';
import 'package:ytmusicapi_dart/type_alias.dart';

/// Parses artist from [results].
List<YtArtist> parseArtists(List<JsonMap> results, {bool uploaded = false}) {
  final artists = <YtArtist>[];

  for (final result in results) {
    final data = result[MRLIR] as JsonMap;
    final menuPlaylists = parseMenuPlaylists(data);
    final thumbnailsRaw = nav(data, THUMBNAILS, nullIfAbsent: true);
    final subtitle = getItemText(data, 1);
    final artist = YtArtist(
      name: getItemText(data, 0)!,
      id: nav(data, NAVIGATION_BROWSE_ID) as String,
      shuffleId: menuPlaylists.shuffleId,
      radioId: menuPlaylists.radioId,
      thumbnails: YtThumbnails.fromJson(
        List<JsonMap>.from(thumbnailsRaw as List),
      ),
      subscribers:
          subtitle != null && !uploaded ? subtitle.split(' ').first : null,
    );

    artists.add(artist);
  }
  return artists;
}

/// Parses albums from library.
Future<List> parseLibraryAlbums(
  JsonMap response,
  RequestFuncType requestFunc,
  int? limit,
) async {
  final results = getLibraryContents(response, GRID);
  if (results == null) return [];

  final albums = parseAlbums(List<JsonMap>.from(results['items'] as List));

  if (results.containsKey('continuations')) {
    List<YtAlbum> parseFunc(List<JsonMap> contents) => parseAlbums(contents);
    final remainingLimit = limit == null ? null : limit - albums.length;
    albums.addAll(
      await getContinuations(
        results,
        'gridContinuation',
        remainingLimit,
        requestFunc,
        parseFunc,
      ),
    );
  }

  return albums;
}

/// Parses albums from [results].
List<YtAlbum> parseAlbums(List<JsonMap> results) {
  final List<YtAlbum> albums = [];

  for (final result in results) {
    final data = result[MTRIR] as JsonMap;
    final album = YtAlbum(
      name: nav(data, TITLE_TEXT) as String,
      id: nav(data, TITLE + NAVIGATION_BROWSE_ID) as String,
      playlistId: nav(data, MENU_PLAYLIST_ID, nullIfAbsent: true) as String?,
      albumType: null,
      thumbnails: YtThumbnails.fromJson(
        List<JsonMap>.from(nav(data, THUMBNAIL_RENDERER) as List),
      ),
      artists: [],
      tracks: [],
      durationRaw: null,
      duration: null,
      isExplicit: nav(data, SUBTITLE_BADGE_LABEL, nullIfAbsent: true) != null,
      year: null,
      trackCount: null,
      description: null,
      likeStatus: null,
      relatedRecommendations: [],
      otherVersions: [],
    );

    if (data['subtitle'] != null &&
        (data['subtitle'] as JsonMap).containsKey('runs')) {
      album.albumType = YtAlbumType.tryFromName(nav(data, SUBTITLE) as String);
      for (final (songRunsItemType, value) in parseSongRuns(
        ((data['subtitle'] as JsonMap)['runs'] as List).sublist(2),
      )) {
        switch (songRunsItemType) {
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
          case SongRunsItemType.ALBUM:
            continue;
        }
      }
    }

    albums.add(album);
  }

  return albums;
}

/// Parses podcasts from library.
Future<List> parseLibraryPodcasts(
  JsonMap response,
  RequestFuncType requestFunc,
  int? limit,
) async {
  final results = getLibraryContents(response, GRID);
  if (results == null) return [];

  Future<List> parseFunc(List<JsonMap> contents) =>
      parseContentList(contents, parsePodcast);
  final podcasts = await parseFunc(
    List<JsonMap>.from((results['items'] as List).sublist(1)),
  ); // skip first "Add podcast"

  if (results.containsKey('continuations')) {
    final remainingLimit = limit == null ? null : limit - podcasts.length;
    podcasts.addAll(
      await getContinuations(
        results,
        'gridContinuation',
        remainingLimit,
        requestFunc,
        parseFunc,
      ),
    );
  }

  return podcasts;
}

/// Parses artists from library.
Future<List<YtArtist>> parseLibraryArtists(
  JsonMap response,
  RequestFuncType requestFunc,
  int? limit,
) async {
  final results = getLibraryContents(response, MUSIC_SHELF);
  if (results == null) return [];

  final artists = parseArtists(List<JsonMap>.from(results['contents'] as List));

  if (results.containsKey('continuations')) {
    List<YtArtist> parseFunc(List<JsonMap> contents) => parseArtists(contents);
    final remainingLimit = limit == null ? null : limit - artists.length;
    artists.addAll(
      await getContinuations(
        results,
        'musicShelfContinuation',
        remainingLimit,
        requestFunc,
        parseFunc,
      ),
    );
  }

  return artists;
}

/// Pops songs from random mix.
void popSongsRandomMix(JsonMap? results) {
  if (results != null &&
      results['contents'] != null &&
      (results['contents'] as List).length >= 2) {
    (results['contents'] as List).removeAt(0);
  }
}

/// Parses songs from library.
JsonMap parseLibrarySongs(JsonMap response) {
  final results = getLibraryContents(response, MUSIC_SHELF);
  popSongsRandomMix(results);
  return {
    'results': results,
    'parsed':
        results != null
            ? parsePlaylistItems(
              List<JsonMap>.from(results['contents'] as List),
            )
            : results,
  };
}

/// Parses contents from library.
JsonMap? getLibraryContents(JsonMap response, List renderer) {
  final section = nav(
    response,
    SINGLE_COLUMN_TAB + SECTION_LIST,
    nullIfAbsent: true,
  );

  JsonMap? contents;
  if (section == null) {
    final numTabs = (nav(response, [...SINGLE_COLUMN, 'tabs']) as List).length;
    final libraryTab = numTabs < 3 ? TAB_1_CONTENT : TAB_2_CONTENT;
    contents =
        nav(
              response,
              SINGLE_COLUMN + libraryTab + SECTION_LIST_ITEM + renderer,
              nullIfAbsent: true,
            )
            as JsonMap?;
  } else {
    final results = findObjectByKey(section as List, 'itemSectionRenderer');
    if (results == null) {
      contents =
          nav(
                response,
                SINGLE_COLUMN_TAB + SECTION_LIST_ITEM + renderer,
                nullIfAbsent: true,
              )
              as JsonMap?;
    } else {
      contents =
          nav(results, ITEM_SECTION + renderer, nullIfAbsent: true) as JsonMap?;
    }
  }

  return contents;
}
