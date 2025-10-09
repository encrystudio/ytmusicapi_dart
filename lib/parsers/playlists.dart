import 'dart:core';

import 'package:ytmusicapi_dart/continuations.dart';
import 'package:ytmusicapi_dart/helpers.dart';
import 'package:ytmusicapi_dart/navigation.dart';
import 'package:ytmusicapi_dart/parsers/songs.dart';
import 'package:ytmusicapi_dart/parsers/utils.dart';
import 'package:ytmusicapi_dart/type_alias.dart';

/// Parses playlist header.
JsonMap parsePlaylistHeader(JsonMap response) {
  final playlist = <String, dynamic>{};

  final editableHeader =
      nav(response, [
            ...HEADER,
            ...EDITABLE_PLAYLIST_DETAIL_HEADER,
          ], nullIfAbsent: true)
          as JsonMap?;
  playlist['owned'] = editableHeader != null;
  playlist['privacy'] = 'PUBLIC';

  JsonMap? header;

  if (editableHeader != null) {
    header = nav(editableHeader, HEADER_DETAIL) as JsonMap?;
    playlist['privacy'] =
        ((editableHeader['editHeader']
                as JsonMap)['musicPlaylistEditHeaderRenderer']
            as JsonMap)['privacy'];
  } else {
    header = nav(response, HEADER_DETAIL, nullIfAbsent: true) as JsonMap?;
    header ??=
        nav(response, [
              ...TWO_COLUMN_RENDERER,
              ...TAB_CONTENT,
              ...SECTION_LIST_ITEM,
              ...RESPONSIVE_HEADER,
            ])
            as JsonMap?;
  }

  playlist.addAll(parsePlaylistHeaderMeta(header!));

  if (playlist['thumbnails'] == null) {
    playlist['thumbnails'] = nav(header, THUMBNAIL_CROPPED, nullIfAbsent: true);
  }
  playlist['description'] = nav(header, [
    'description',
    ...DESCRIPTION_SHELF,
    ...DESCRIPTION,
  ], nullIfAbsent: true);
  playlist['year'] = nav(header, SUBTITLE2);

  return playlist;
}

/// Parses header meta from playlist.
JsonMap parsePlaylistHeaderMeta(JsonMap header) {
  final playlistMeta = <String, dynamic>{
    'views': null,
    'duration': null,
    'trackCount': null,
    'title':
        ((header['title'] as JsonMap?)?['runs'] as List? ?? [])
            .map((run) => (run as JsonMap)['text'])
            .join(),
    'thumbnails': nav(header, THUMBNAILS),
  };

  if (header.containsKey('facepile')) {
    playlistMeta['author'] = {
      'name': nav(header, [
        'facepile',
        'avatarStackViewModel',
        'text',
        'content',
      ]),
      'id': nav(header, [
        'facepile',
        'avatarStackViewModel',
        'rendererContext',
        'commandContext',
        'onTap',
        'innertubeCommand',
        'browseEndpoint',
        'browseId',
      ], nullIfAbsent: true),
    };
  }

  if (((header['secondSubtitle'] as JsonMap?)?['runs'] as List?) != null) {
    final secondSubtitleRuns =
        (header['secondSubtitle'] as JsonMap)['runs'] as List;
    final hasViews = (secondSubtitleRuns.length > 3) ? 2 : 0;
    final hasDuration = (secondSubtitleRuns.length > 1) ? 2 : 0;

    playlistMeta['views'] =
        hasViews == 0
            ? null
            : toInt((secondSubtitleRuns[0] as JsonMap)['text'] as String);
    playlistMeta['duration'] =
        hasDuration == 0
            ? null
            : (secondSubtitleRuns[hasViews + hasDuration] as JsonMap)['text'];

    final songCountText =
        (secondSubtitleRuns[hasViews + 0] as JsonMap)['text'] as String;
    final songCountSearch =
        RegExp(r'\d+').allMatches(songCountText).map((m) => m[0]).join();
    playlistMeta['trackCount'] =
        songCountSearch.isEmpty ? null : toInt(songCountSearch);
  }

  return playlistMeta;
}

/// Parses audio playlist.
Future<JsonMap> parseAudioPlaylist(
  JsonMap response,
  int? limit,
  RequestFuncBodyType requestFunc,
) async {
  final playlist = <String, dynamic>{
    'owned': false,
    'privacy': 'PUBLIC',
    'description': null,
    'views': null,
    'duration': null,
    'tracks': <JsonMap>[],
    'thumbnails': <dynamic>[],
    'related': <dynamic>[],
  };

  final sectionList = nav(response, [
    ...TWO_COLUMN_RENDERER,
    'secondaryContents',
    ...SECTION,
  ]);
  final contentData = nav(sectionList, [
    ...CONTENT,
    'musicPlaylistShelfRenderer',
  ]);

  playlist['id'] = nav(contentData, [
    ...CONTENT,
    MRLIR,
    ...PLAY_BUTTON,
    'playNavigationEndpoint',
    ...WATCH_PLAYLIST_ID,
  ]);
  playlist['trackCount'] = nav(contentData, ['collapsedItemCount']);

  playlist['tracks'] = [];

  if ((contentData as JsonMap).containsKey('contents')) {
    playlist['tracks'] = parsePlaylistItems(
      contentData['contents'] as List<JsonMap>,
    );

    List parseFunc(contents) => parsePlaylistItems(contents as List<JsonMap>);
    (playlist['tracks'] as List).addAll(
      await getContinuations2025(contentData, limit, requestFunc, parseFunc),
    );
  }

  playlist['title'] =
      (((playlist['tracks'] as List)[0] as JsonMap)['album']
          as JsonMap)['name'];

  playlist['duration_seconds'] = sumTotalDuration(playlist);

  return playlist;
}

/// Parses items from playlist.
List parsePlaylistItems(
  List<JsonMap> results, {
  List<List<String>>? menuEntries,
  bool isAlbum = false,
}) {
  final songs = <JsonMap>[];

  for (final result in results) {
    if (!result.containsKey(MRLIR)) continue;

    final data = result[MRLIR];
    final song = parsePlaylistItem(
      data as JsonMap,
      menuEntries: menuEntries,
      isAlbum: isAlbum,
    );
    if (song != null) songs.add(song);
  }

  return songs;
}

/// Parses item from playlist.
JsonMap? parsePlaylistItem(
  JsonMap data, {
  List<List<String>>? menuEntries,
  bool isAlbum = false,
}) {
  String? videoId;
  String? setVideoId;
  dynamic like;
  dynamic feedbackTokens;
  dynamic libraryStatus;

  if (data.containsKey('menu')) {
    for (final item in List<JsonMap>.from(nav(data, MENU_ITEMS) as List)) {
      if (item.containsKey('menuServiceItemRenderer')) {
        final menuService = nav(item, MENU_SERVICE) as JsonMap;
        if (menuService.containsKey('playlistEditEndpoint')) {
          setVideoId =
              nav(menuService, [
                    'playlistEditEndpoint',
                    'actions',
                    0,
                    'setVideoId',
                  ], nullIfAbsent: true)
                  as String?;
          videoId =
              nav(menuService, [
                    'playlistEditEndpoint',
                    'actions',
                    0,
                    'removedVideoId',
                  ], nullIfAbsent: true)
                  as String?;
        }
      }
      if (item.containsKey(TOGGLE_MENU)) {
        feedbackTokens = parseSongMenuTokens(item);
        libraryStatus = parseSongLibraryStatus(item);
      }
    }
  }

  if (nav(data, PLAY_BUTTON, nullIfAbsent: true) != null) {
    final playBtn = nav(data, PLAY_BUTTON) as JsonMap;
    if (playBtn.containsKey('playNavigationEndpoint')) {
      videoId =
          ((playBtn['playNavigationEndpoint'] as JsonMap)['watchEndpoint']
                  as JsonMap)['videoId']
              as String?;
      if (data.containsKey('menu')) {
        like = nav(data, MENU_LIKE_STATUS, nullIfAbsent: true);
      }
    }
  }

  final isAvailable =
      !(data['musicItemRendererDisplayPolicy'] ==
          'MUSIC_ITEM_RENDERER_DISPLAY_POLICY_GREY_OUT');

  final usePresetColumns = !isAvailable || isAlbum ? true : null;

  int? titleIndex = usePresetColumns == true ? 0 : null;
  int? artistIndex = usePresetColumns == true ? 1 : null;
  int? albumIndex = usePresetColumns == true ? 2 : null;
  final userChannelIndexes = <int>[];
  int? unrecognizedIndex;

  for (var index = 0; index < (data['flexColumns'] as List).length; index++) {
    final flexColumnItem = getFlexColumnItem(data, index);
    final navigationEndpoint = nav(flexColumnItem, [
      ...TEXT_RUN,
      'navigationEndpoint',
    ], nullIfAbsent: true);

    if (navigationEndpoint == null) {
      if (nav(flexColumnItem, TEXT_RUN_TEXT, nullIfAbsent: true) != null) {
        unrecognizedIndex ??= index;
      }
      continue;
    }

    if ((navigationEndpoint as Map).containsKey('watchEndpoint')) {
      titleIndex = index;
    } else if (navigationEndpoint.containsKey('browseEndpoint')) {
      final pageType = nav(navigationEndpoint, [
        'browseEndpoint',
        'browseEndpointContextSupportedConfigs',
        'browseEndpointContextMusicConfig',
        'pageType',
      ]);

      if (pageType == 'MUSIC_PAGE_TYPE_ARTIST' ||
          pageType == 'MUSIC_PAGE_TYPE_UNKNOWN') {
        artistIndex = index;
      } else if (pageType == 'MUSIC_PAGE_TYPE_ALBUM') {
        albumIndex = index;
      } else if (pageType == 'MUSIC_PAGE_TYPE_USER_CHANNEL') {
        userChannelIndexes.add(index);
      } else if (pageType == 'MUSIC_PAGE_TYPE_NON_MUSIC_AUDIO_TRACK_PAGE') {
        titleIndex = index;
      }
    }
  }

  artistIndex ??= unrecognizedIndex;
  if (artistIndex == null && userChannelIndexes.isNotEmpty) {
    artistIndex = userChannelIndexes.last;
  }

  final title = titleIndex != null ? getItemText(data, titleIndex) : null;
  if (title == 'Song deleted') return null;

  final artists =
      artistIndex != null ? parseSongArtists(data, artistIndex) : null;
  final album = albumIndex != null ? parseSongAlbum(data, albumIndex) : null;
  final views = isAlbum ? getItemText(data, 2) : null;

  String? duration;
  if (data.containsKey('fixedColumns')) {
    final firstColumn = getFixedColumnItem(data, 0);
    duration =
        ((firstColumn?['text'] as JsonMap?)?['simpleText'] ??
                nav(firstColumn, ['text', 'simpleText']) ??
                nav(firstColumn, TEXT_RUN_TEXT))
            as String?;
  }

  final thumbnails = nav(data, THUMBNAILS, nullIfAbsent: true);
  final isExplicit = nav(data, BADGE_LABEL, nullIfAbsent: true) != null;
  final videoType = nav(data, [
    ...MENU_ITEMS,
    0,
    MNIR,
    'navigationEndpoint',
    ...NAVIGATION_VIDEO_TYPE,
  ], nullIfAbsent: true);

  final song = <String, dynamic>{
    'videoId': videoId,
    'title': title,
    'artists': artists,
    'album': album,
    'likeStatus': like,
    'inLibrary': libraryStatus,
    'thumbnails': thumbnails,
    'isAvailable': isAvailable,
    'isExplicit': isExplicit,
    'videoType': videoType,
    'views': views,
  };

  if (isAlbum) {
    song['trackNumber'] =
        isAvailable
            ? int.parse(nav(data, ['index', 'runs', 0, 'text']) as String)
            : null;
  }
  if (duration != null) {
    song['duration'] = duration;
    song['duration_seconds'] = parseDuration(duration);
  }
  if (setVideoId != null) song['setVideoId'] = setVideoId;
  if (feedbackTokens != null) song['feedbackTokens'] = feedbackTokens;

  if (menuEntries != null) {
    final menuItems = nav(data, MENU_ITEMS);
    for (final menuEntry in menuEntries) {
      final items = findObjectsByKey(menuItems as List, menuEntry[0]);
      song[menuEntry.last] = items
          .map((itm) => nav(itm, menuEntry, nullIfAbsent: true))
          .firstWhere((x) => x != null, orElse: () => null);
    }
  }

  return song;
}

/// Validates the [playlistId].
String validatePlaylistId(String playlistId) {
  return playlistId.startsWith('VL') ? playlistId.substring(2) : playlistId;
}
