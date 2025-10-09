import 'package:ytmusicapi_dart/continuations.dart';
import 'package:ytmusicapi_dart/navigation.dart';
import 'package:ytmusicapi_dart/parsers/browsing.dart';
import 'package:ytmusicapi_dart/parsers/playlists.dart';
import 'package:ytmusicapi_dart/parsers/podcasts.dart';
import 'package:ytmusicapi_dart/parsers/songs.dart';
import 'package:ytmusicapi_dart/parsers/utils.dart';
import 'package:ytmusicapi_dart/type_alias.dart';

/// Parses artist from [results].
List parseArtists(List<JsonMap> results, {bool uploaded = false}) {
  final List artists = [];

  for (final result in results) {
    final data = result[MRLIR];
    final artist = <String, dynamic>{};
    artist['browseId'] = nav(data, NAVIGATION_BROWSE_ID);
    artist['artist'] = getItemText(data as JsonMap, 0);
    final pageType = nav(
      data,
      NAVIGATION_BROWSE + PAGE_TYPE,
      nullIfAbsent: true,
    );

    if (pageType == 'MUSIC_PAGE_TYPE_USER_CHANNEL') {
      artist['type'] = 'channel';
    } else if (pageType == 'MUSIC_PAGE_TYPE_ARTIST') {
      artist['type'] = 'artist';
    }

    parseMenuPlaylists(data, artist);

    if (uploaded) {
      artist['songs'] = (getItemText(data, 1) ?? '').split(' ')[0];
    } else {
      final subtitle = getItemText(data, 1);
      if (subtitle != null) {
        artist['subscribers'] = subtitle.split(' ')[0];
      }
    }

    artist['thumbnails'] = nav(data, THUMBNAILS, nullIfAbsent: true);
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

  final albums = parseAlbums(results['items'] as List<JsonMap>);

  if (results.containsKey('continuations')) {
    List parseFunc(List<JsonMap> contents) => parseAlbums(contents);
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
List parseAlbums(List<JsonMap> results) {
  final List albums = [];

  for (final result in results) {
    final data = result[MTRIR] as JsonMap;
    final album = <String, dynamic>{};
    album['browseId'] = nav(data, TITLE + NAVIGATION_BROWSE_ID);
    album['playlistId'] = nav(data, MENU_PLAYLIST_ID, nullIfAbsent: true);
    album['title'] = nav(data, TITLE_TEXT);
    album['thumbnails'] = nav(data, THUMBNAIL_RENDERER);

    if (data['subtitle'] != null &&
        (data['subtitle'] as JsonMap).containsKey('runs')) {
      album['type'] = nav(data, SUBTITLE);
      album.addAll(
        parseSongRuns(
          ((data['subtitle'] as JsonMap)['runs'] as List).sublist(2),
        ),
      );
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
    (results['items'] as List).sublist(1) as List<JsonMap>,
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
Future<List> parseLibraryArtists(
  JsonMap response,
  RequestFuncType requestFunc,
  int? limit,
) async {
  final results = getLibraryContents(response, MUSIC_SHELF);
  if (results == null) return [];

  final artists = parseArtists(results['contents'] as List<JsonMap>);

  if (results.containsKey('continuations')) {
    List parseFunc(List<JsonMap> contents) => parseArtists(contents);
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
            ? parsePlaylistItems(results['contents'] as List<JsonMap>)
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
