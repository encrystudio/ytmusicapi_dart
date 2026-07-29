import 'dart:core';

import 'package:ytmusicapi_dart/continuations.dart';
import 'package:ytmusicapi_dart/helpers.dart';
import 'package:ytmusicapi_dart/models/content/enums.dart';
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
    final avatarRenderer = nav(header, [
      'facepile',
      'avatarStackViewModel',
      'rendererContext',
    ]);

    final avatarCommand = nav(avatarRenderer, [
      'commandContext',
      'onTap',
      'innertubeCommand',
    ], nullIfAbsent: true);

    if (nav(avatarCommand, [
          'showEngagementPanelEndpoint',
          'identifier',
          'tag',
        ], nullIfAbsent: true) ==
        'PAplaylist_collaborate') {
      final avatars = List<JsonMap>.from(
        nav(header, ['facepile', 'avatarStackViewModel', 'avatars']) as List,
      );

      playlistMeta['collaborators'] = {
        'text': nav(avatarRenderer, ['accessibilityContext', 'label']),
        'avatars': [
          for (final avatar in avatars)
            (((avatar['avatarViewModel'] as JsonMap)['image']
                    as JsonMap)['sources']
                as List)[0],
        ],
      };
    } else {
      playlistMeta['author'] = {
        'name': nav(header, [
          'facepile',
          'avatarStackViewModel',
          'text',
          'content',
        ]),
        'id': nav(avatarCommand, [
          'browseEndpoint',
          'browseId',
        ], nullIfAbsent: true),
      };
    }
  }

  final secondSubtitleRuns =
      nav(header, ['secondSubtitle', 'runs'], nullIfAbsent: true) as List?;

  if (secondSubtitleRuns != null) {
    final hasViews = secondSubtitleRuns.length > 3 ? 2 : 0;
    playlistMeta['views'] =
        hasViews == 0
            ? null
            : toInt((secondSubtitleRuns[0] as JsonMap)['text'] as String);

    final hasDuration = secondSubtitleRuns.length > 1 ? 2 : 0;
    playlistMeta['duration'] =
        hasDuration == 0
            ? null
            : (secondSubtitleRuns[hasViews + hasDuration] as JsonMap)['text'];

    final songCountText =
        (secondSubtitleRuns[hasViews] as JsonMap)['text'] as String;

    final songCountSearch =
        RegExp(
          r'\d+',
        ).allMatches(songCountText).map((match) => match.group(0)!).toList();

    playlistMeta['trackCount'] =
        songCountSearch.isNotEmpty ? toInt(songCountSearch.join()) : null;
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
    ['targetId'],
  ]);

  playlist['tracks'] = [];

  if ((contentData as JsonMap).containsKey('contents')) {
    playlist['tracks'] = parsePlaylistItems(
      List<JsonMap>.from(contentData['contents'] as List),
    );

    List parseFunc(contents) =>
        parsePlaylistItems(List<JsonMap>.from(contents as List));
    (playlist['tracks'] as List).addAll(
      List<JsonMap>.from(
        await getContinuations2025(contentData, limit, requestFunc, parseFunc),
      ),
    );
  }

  playlist['trackCount'] = (playlist['tracks'] as List).length;

  try {
    playlist['title'] =
        (((playlist['tracks'] as List)[0] as JsonMap)['album']
            as JsonMap)['name'];
  } catch (_) {
    playlist['title'] =
        List<JsonMap>.from(
          ((playlist['tracks'] as List)[0] as JsonMap)['artists'] as List,
        )[0]['name'];
  }

  playlist['duration_seconds'] = sumTotalDuration(playlist);

  return playlist;
}

/// Parses items from playlist.
List<JsonMap> parsePlaylistItems(
  List<JsonMap> results, {
  bool isAlbum = false,
  bool isCollaborative = false,
}) {
  final songs = <JsonMap>[];

  for (final result in results) {
    if (!result.containsKey(MRLIR)) {
      continue;
    }

    final data = result[MRLIR] as JsonMap;
    final song = parsePlaylistItem(
      data,
      isAlbum: isAlbum,
      isCollaborative: isCollaborative,
    );

    if (song != null) {
      songs.add(song);
    }
  }

  return songs;
}

/// Parses item from playlist.
JsonMap? parsePlaylistItem(
  JsonMap data, {
  bool isAlbum = false,
  bool isCollaborative = false,
}) {
  String? videoId;
  String? setVideoId;
  String? creditsBrowseId;
  String? like;

  // If the item has a menu, find its setVideoId
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
      } else if (item.containsKey(MNIR)) {
        final maybeCreditsBrowseId =
            nav(item, [MNIR, ...NAVIGATION_BROWSE_ID], nullIfAbsent: true)
                as String?;

        if (maybeCreditsBrowseId != null &&
            maybeCreditsBrowseId.startsWith('MPTC')) {
          creditsBrowseId = maybeCreditsBrowseId;
        }
      }
    }
  }

  final songMenuData = <String, dynamic>{
    'inLibrary': null,
    'pinnedToListenAgain': null,
    ...parseSongMenuData(data),
  };

  final playButton = nav(data, PLAY_BUTTON, nullIfAbsent: true) as JsonMap?;

  if (playButton != null && playButton.containsKey('playNavigationEndpoint')) {
    videoId =
        nav(data, [
              ...PLAY_BUTTON,
              'playNavigationEndpoint',
              'watchEndpoint',
              'videoId',
            ])
            as String;

    if (data.containsKey('menu')) {
      like = nav(data, MENU_LIKE_STATUS, nullIfAbsent: true) as String?;
    }
  }

  var isAvailable = true;

  if (data.containsKey('musicItemRendererDisplayPolicy')) {
    isAvailable =
        data['musicItemRendererDisplayPolicy'] !=
        'MUSIC_ITEM_RENDERER_DISPLAY_POLICY_GREY_OUT';
  }

  final usePresetColumns = (!isAvailable || isAlbum) ? true : null;

  int? titleIndex = usePresetColumns == true ? 0 : null;
  int? artistIndex = usePresetColumns == true ? 1 : null;
  int? durationIndex;
  int? albumIndex = isCollaborative ? 3 : (usePresetColumns == true ? 2 : null);

  final userChannelIndexes = <int>[];
  int? unrecognizedIndex;

  final flexColumns = data['flexColumns'] as List;

  for (var index = 0; index < flexColumns.length; index++) {
    final flexColumnItem = getFlexColumnItem(data, index);

    final navigationEndpoint =
        nav(flexColumnItem, [
              ...TEXT_RUN,
              'navigationEndpoint',
            ], nullIfAbsent: true)
            as JsonMap?;

    if (navigationEndpoint == null) {
      final run = nav(flexColumnItem, TEXT_RUN, nullIfAbsent: true) as JsonMap?;

      if (run != null && run.containsKey('text')) {
        final parsed = parseSongRun(run);

        if (parsed['type'] == 'duration') {
          durationIndex = index;
        } else {
          unrecognizedIndex ??= index;
        }
      }

      continue;
    }

    if (navigationEndpoint.containsKey('watchEndpoint')) {
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
      } else if (pageType == 'MUSIC_PAGE_TYPE_ALBUM' ||
          pageType == 'MUSIC_PAGE_TYPE_AUDIOBOOK') {
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

  if (title == 'Song deleted') {
    return null;
  }

  final artists =
      artistIndex != null ? parseSongArtists(data, artistIndex) : null;

  final album = albumIndex != null ? parseSongAlbum(data, albumIndex) : null;

  final views = isAlbum ? getItemText(data, 2) : null;

  String? duration =
      durationIndex != null ? getItemText(data, durationIndex) : null;

  if (data.containsKey('fixedColumns')) {
    final fixedColumn = getFixedColumnItem(data, 0);

    if (nav(fixedColumn, ['text', 'simpleText'], nullIfAbsent: true) != null) {
      duration = nav(fixedColumn, ['text', 'simpleText']) as String;
    } else {
      duration = nav(fixedColumn, TEXT_RUN_TEXT) as String;
    }
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

  final votingStatus =
      nav(data, ENGAGEMENT_BAR, nullIfAbsent: true) as JsonMap?;

  final communityVoteStatus =
      votingStatus == null
          ? null
          : {
            'netVoteValue': votingStatus['votes'],
            'status': VoteStatus.fromValue(votingStatus['status'] as String),
          };

  final song = <String, dynamic>{
    'videoId': videoId,
    'title': title,
    'artists': artists,
    'album': album,
    'likeStatus': like,
    ...songMenuData,
    'thumbnails': thumbnails,
    'isAvailable': isAvailable,
    'isExplicit': isExplicit,
    'videoType': videoType,
    'views': views,
    'communityVoteStatus': communityVoteStatus,
  };

  if (isAlbum) {
    song['trackNumber'] =
        isAvailable
            ? int.parse(nav(data, ['index', 'runs', 0, 'text']) as String)
            : null;
  }

  if (duration != null && duration.isNotEmpty) {
    song['duration'] = duration;
    song['duration_seconds'] = parseDuration(duration);
  }

  if (setVideoId != null) {
    song['setVideoId'] = setVideoId;
  }

  if (creditsBrowseId != null) {
    song['creditsBrowseId'] = creditsBrowseId;
  }

  return song;
}

/// Validates the [playlistId].
String validatePlaylistId(String playlistId) {
  return playlistId.startsWith('VL') ? playlistId.substring(2) : playlistId;
}
