import 'dart:core';

import 'package:ytmusicapi_dart/continuations.dart';
import 'package:ytmusicapi_dart/enums.dart';
import 'package:ytmusicapi_dart/helpers.dart';
import 'package:ytmusicapi_dart/models/content/enums.dart';
import 'package:ytmusicapi_dart/models/objects/base.dart';
import 'package:ytmusicapi_dart/models/objects/playlist.dart';
import 'package:ytmusicapi_dart/models/objects/video.dart';
import 'package:ytmusicapi_dart/navigation.dart';
import 'package:ytmusicapi_dart/parsers/songs.dart';
import 'package:ytmusicapi_dart/parsers/utils.dart';
import 'package:ytmusicapi_dart/type_alias.dart';
import 'package:ytmusicapi_dart/utils.dart';

/// Parses playlist header.
PlaylistHeader parsePlaylistHeader(JsonMap response) {
  final editableHeader =
      nav(response, [
            ...HEADER,
            ...EDITABLE_PLAYLIST_DETAIL_HEADER,
          ], nullIfAbsent: true)
          as JsonMap?;

  final playlist = PlaylistHeader(
    owned: editableHeader != null,
    privacy: PrivacyStatus.PUBLIC,
    thumbnails: null,
    description: null,
    year: null,
  );

  JsonMap? header;

  if (editableHeader != null) {
    header = nav(editableHeader, HEADER_DETAIL) as JsonMap?;
    playlist.privacy =
        PrivacyStatus.fromValue(
          ((editableHeader['editHeader']
                      as JsonMap)['musicPlaylistEditHeaderRenderer']
                  as JsonMap)['privacy']
              as String?,
        )!;
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

  playlist.meta = parsePlaylistHeaderMeta(header!);
  final thumbnails =
      nav(header, THUMBNAIL_CROPPED, nullIfAbsent: true) as List?;
  playlist.thumbnails ??=
      thumbnails != null
          ? YtThumbnails.fromJson(List<JsonMap>.from(thumbnails))
          : null;
  playlist.description =
      nav(header, [
            'description',
            ...DESCRIPTION_SHELF,
            ...DESCRIPTION,
          ], nullIfAbsent: true)
          as String?;
  playlist.year = int.tryParse(nav(header, SUBTITLE2) as String);

  return playlist;
}

/// Parses header meta from playlist.
PlaylistHeaderMeta parsePlaylistHeaderMeta(JsonMap header) {
  final playlistMeta = PlaylistHeaderMeta(
    views: null,
    durationRaw: null,
    itemCount: null,
    title:
        ((header['title'] as JsonMap?)?['runs'] as List? ?? [])
            .map((run) => (run as JsonMap)['text'])
            .join(),
    thumbnails: YtThumbnails.fromJson(
      List<JsonMap>.from(nav(header, THUMBNAILS) as List),
    ),

    authors: [],
  );

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
      // TODO
      // final avatars = List<JsonMap>.from(
      //   nav(header, ['facepile', 'avatarStackViewModel', 'avatars']) as List,
      // );

      playlistMeta.authors = [
        YtBaseObject(
          id: null,
          name:
              nav(avatarRenderer, ['accessibilityContext', 'label']) as String,
          type: YtObjectType.OBJECT,
        ),
      ];
    } else {
      playlistMeta.authors = [
        YtBaseObject(
          id:
              nav(avatarCommand, [
                    'browseEndpoint',
                    'browseId',
                  ], nullIfAbsent: true)
                  as String?,
          name:
              nav(header, [
                    'facepile',
                    'avatarStackViewModel',
                    'text',
                    'content',
                  ])
                  as String,
          type: YtObjectType.OBJECT,
        ),
      ];
    }
  }

  final secondSubtitleRuns =
      nav(header, ['secondSubtitle', 'runs'], nullIfAbsent: true) as List?;

  if (secondSubtitleRuns != null) {
    final hasViews = secondSubtitleRuns.length > 3 ? 2 : 0;
    playlistMeta.views =
        hasViews == 0
            ? null
            : toInt((secondSubtitleRuns.first as JsonMap)['text'] as String);

    final hasDuration = secondSubtitleRuns.length > 1 ? 2 : 0;
    playlistMeta.durationRaw =
        hasDuration == 0
            ? null
            : (secondSubtitleRuns[hasViews + hasDuration] as JsonMap)['text']
                as String;

    final songCountText =
        (secondSubtitleRuns[hasViews] as JsonMap)['text'] as String;

    final songCountSearch =
        RegExp(
          r'\d+',
        ).allMatches(songCountText).map((match) => match.group(0)!).toList();

    playlistMeta.itemCount =
        songCountSearch.isNotEmpty ? toInt(songCountSearch.join()) : null;
  }

  return playlistMeta;
}

/// Parses audio playlist.
Future<YtPlaylist> parseAudioPlaylist(
  JsonMap response,
  int? limit,
  RequestFuncBodyType requestFunc,
) async {
  final sectionList = nav(response, [
    ...TWO_COLUMN_RENDERER,
    'secondaryContents',
    ...SECTION,
  ]);
  final contentData = nav(sectionList, [
    ...CONTENT,
    'musicPlaylistShelfRenderer',
  ]);

  final playlist = YtPlaylist(
    name: '',
    id:
        nav(contentData, [
              ['targetId'],
            ])
            as String?,
    playlistType: null,
    authors: [],
    owned: false,
    privacy: PrivacyStatus.PUBLIC,
    thumbnails: null,
    description: null,
    durationRaw: null,
    duration: null,
    year: null,
    itemCount: null,
    views: null,
    items: [],
    related: [],
    suggestions: [],
  );

  if ((contentData as JsonMap).containsKey('contents')) {
    playlist.items = parsePlaylistItems(
      List<JsonMap>.from(contentData['contents'] as List),
    );

    List<YtVideo> parseFunc(contents) =>
        parsePlaylistItems(List<JsonMap>.from(contents as List));
    playlist.items.addAll(
      await getContinuations2025(contentData, limit, requestFunc, parseFunc),
    );
  }

  playlist.itemCount = playlist.items.length;

  try {
    playlist.name = playlist.items.first.album!.name;
  } catch (_) {
    playlist.name = playlist.items.first.artists.first.name;
  }

  playlist.duration = Duration(seconds: sumTotalDurationPlaylist(playlist));

  return playlist;
}

/// Parses items from playlist.
List<YtVideo> parsePlaylistItems(
  List<JsonMap> results, {
  bool isAlbum = false,
  bool isCollaborative = false,
}) {
  final songs = <YtVideo>[];

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
YtVideo? parsePlaylistItem(
  JsonMap data, {
  bool isAlbum = false,
  bool isCollaborative = false,
}) {
  String? videoId;
  // TODO
  // String? setVideoId;
  // String? creditsBrowseId;
  // String? like;

  // If the item has a menu, find its setVideoId
  if (data.containsKey('menu')) {
    for (final item in List<JsonMap>.from(nav(data, MENU_ITEMS) as List)) {
      if (item.containsKey('menuServiceItemRenderer')) {
        final menuService = nav(item, MENU_SERVICE) as JsonMap;

        if (menuService.containsKey('playlistEditEndpoint')) {
          // TODO
          // setVideoId =
          //     nav(menuService, [
          //           'playlistEditEndpoint',
          //           'actions',
          //           0,
          //           'setVideoId',
          //         ], nullIfAbsent: true)
          //         as String?;

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
          // TODO
          // creditsBrowseId = maybeCreditsBrowseId;
        }
      }
    }
  }

  final songMenuData = parseSongMenuData(data);

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
      // TODO
      // like = nav(data, MENU_LIKE_STATUS, nullIfAbsent: true) as String?;
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

  String? durationRaw =
      durationIndex != null ? getItemText(data, durationIndex) : null;

  if (data.containsKey('fixedColumns')) {
    final fixedColumn = getFixedColumnItem(data, 0);

    if (nav(fixedColumn, ['text', 'simpleText'], nullIfAbsent: true) != null) {
      durationRaw = nav(fixedColumn, ['text', 'simpleText']) as String;
    } else {
      durationRaw = nav(fixedColumn, TEXT_RUN_TEXT) as String;
    }
  }
  final thumbnailsRaw = nav(data, THUMBNAILS, nullIfAbsent: true) as List?;
  final thumbnails =
      thumbnailsRaw != null
          ? YtThumbnails.fromJson(List<JsonMap>.from(thumbnailsRaw))
          : null;

  final isExplicit = nav(data, BADGE_LABEL, nullIfAbsent: true) != null;

  final videoType = VideoType.tryFromValue(
    nav(data, [
          ...MENU_ITEMS,
          0,
          MNIR,
          'navigationEndpoint',
          ...NAVIGATION_VIDEO_TYPE,
        ], nullIfAbsent: true)
        as String?,
  );

  // TODO
  // final votingStatus =
  //     nav(data, ENGAGEMENT_BAR, nullIfAbsent: true) as JsonMap?;

  // TODO
  // final communityVoteStatus =
  //     votingStatus == null
  //         ? null
  //         : {
  //           'netVoteValue': votingStatus['votes'],
  //           'status': VoteStatus.fromValue(votingStatus['status'] as String),
  //         };

  final song = YtVideo(
    name: title!,
    id: videoId,
    playlistId: null,
    videoType: videoType,
    views: views,
    durationRaw: durationRaw,
    duration: null,
    artists: artists ?? [],
    thumbnails: thumbnails,
    year: null,
    isAvailable: isAvailable,
    isSong: null,
    album: album,
    trackNumber: null,
    isExplicit: isExplicit,
    inLibrary: null,
    feedbackTokenAdd: songMenuData.feedbackTokenAdd,
    feedbackTokenRemove: songMenuData.feedbackTokenRemove,
    isEpisode: null,
    description: null,
  );

  if (isAlbum) {
    song.trackNumber =
        isAvailable
            ? int.parse(nav(data, ['index', 'runs', 0, 'text']) as String)
            : null;
  }

  if (durationRaw != null && durationRaw.isNotEmpty) {
    song.durationRaw = durationRaw;
    song.duration = parseDuration(durationRaw);
  }

  // if (setVideoId != null) {
  //   song.setVideoId = setVideoId; // TODO
  // }

  // if (creditsBrowseId != null) {
  //   song.creditsBrowseId = creditsBrowseId; // TODO
  // }

  return song;
}

/// Validates the [playlistId].
String validatePlaylistId(String playlistId) {
  return playlistId.startsWith('VL') ? playlistId.substring(2) : playlistId;
}
