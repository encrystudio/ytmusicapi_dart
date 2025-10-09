// ignore_for_file: public_member_api_docs

import 'dart:convert';

import 'package:ytmusicapi_dart/type_alias.dart';

const List CONTENT = ['contents', 0];
const List RUN_TEXT = ['runs', 0, 'text'];
const List TAB_CONTENT = ['tabs', 0, 'tabRenderer', 'content'];
const List TAB_1_CONTENT = ['tabs', 1, 'tabRenderer', 'content'];
const List TAB_2_CONTENT = ['tabs', 2, 'tabRenderer', 'content'];
const List TWO_COLUMN_RENDERER = ['contents', 'twoColumnBrowseResultsRenderer'];
const List SINGLE_COLUMN = ['contents', 'singleColumnBrowseResultsRenderer'];
const List SINGLE_COLUMN_TAB = [...SINGLE_COLUMN, ...TAB_CONTENT];
const List SECTION = ['sectionListRenderer'];
const List SECTION_LIST = [...SECTION, 'contents'];
const List SECTION_LIST_ITEM = [...SECTION, ...CONTENT];
const List RESPONSIVE_HEADER = ['musicResponsiveHeaderRenderer'];
const List ITEM_SECTION = ['itemSectionRenderer', ...CONTENT];
const List MUSIC_SHELF = ['musicShelfRenderer'];
const List GRID = ['gridRenderer'];
const List GRID_ITEMS = [...GRID, 'items'];
const List MENU = ['menu', 'menuRenderer'];
const List MENU_ITEMS = [...MENU, 'items'];
const List MENU_LIKE_STATUS = [
  ...MENU,
  'topLevelButtons',
  0,
  'likeButtonRenderer',
  'likeStatus',
];
const List MENU_SERVICE = ['menuServiceItemRenderer', 'serviceEndpoint'];
const String TOGGLE_MENU = 'toggleMenuServiceItemRenderer';
const List OVERLAY_RENDERER = [
  'musicItemThumbnailOverlayRenderer',
  'content',
  'musicPlayButtonRenderer',
];
const List PLAY_BUTTON = ['overlay', ...OVERLAY_RENDERER];
const List NAVIGATION_BROWSE = ['navigationEndpoint', 'browseEndpoint'];
const List NAVIGATION_BROWSE_ID = [...NAVIGATION_BROWSE, 'browseId'];
const List PAGE_TYPE = [
  'browseEndpointContextSupportedConfigs',
  'browseEndpointContextMusicConfig',
  'pageType',
];
const List WATCH_VIDEO_ID = ['watchEndpoint', 'videoId'];
const List PLAYLIST_ID = ['playlistId'];
const List WATCH_PLAYLIST_ID = ['watchEndpoint', ...PLAYLIST_ID];
const List NAVIGATION_VIDEO_ID = ['navigationEndpoint', ...WATCH_VIDEO_ID];
const List QUEUE_VIDEO_ID = ['queueAddEndpoint', 'queueTarget', 'videoId'];
const List NAVIGATION_PLAYLIST_ID = [
  'navigationEndpoint',
  ...WATCH_PLAYLIST_ID,
];
const List WATCH_PID = ['watchPlaylistEndpoint', ...PLAYLIST_ID];
const List NAVIGATION_WATCH_PLAYLIST_ID = ['navigationEndpoint', ...WATCH_PID];
const List NAVIGATION_VIDEO_TYPE = [
  'watchEndpoint',
  'watchEndpointMusicSupportedConfigs',
  'watchEndpointMusicConfig',
  'musicVideoType',
];
const List ICON_TYPE = ['icon', 'iconType'];
const List TOGGLED_BUTTON = ['toggleButtonRenderer', 'isToggled'];
const List TITLE = ['title', 'runs', 0];
const List TITLE_TEXT = ['title', ...RUN_TEXT];
const List TEXT_RUNS = ['text', 'runs'];
const List TEXT_RUN = [...TEXT_RUNS, 0];
const List TEXT_RUN_TEXT = [...TEXT_RUN, 'text'];
const List SUBTITLE = ['subtitle', ...RUN_TEXT];
const List SUBTITLE_RUNS = ['subtitle', 'runs'];
const List SUBTITLE_RUN = [...SUBTITLE_RUNS, 0];
const List SUBTITLE2 = [...SUBTITLE_RUNS, 2, 'text'];
const List SUBTITLE3 = [...SUBTITLE_RUNS, 4, 'text'];
const List THUMBNAIL = ['thumbnail', 'thumbnails'];
const List THUMBNAILS = ['thumbnail', 'musicThumbnailRenderer', ...THUMBNAIL];
const List THUMBNAIL_RENDERER = [
  'thumbnailRenderer',
  'musicThumbnailRenderer',
  ...THUMBNAIL,
];
const List THUMBNAIL_OVERLAY_NAVIGATION = [
  'thumbnailOverlay',
  ...OVERLAY_RENDERER,
  'playNavigationEndpoint',
];
const List THUMBNAIL_OVERLAY = [...THUMBNAIL_OVERLAY_NAVIGATION, ...WATCH_PID];
const List THUMBNAIL_CROPPED = [
  'thumbnail',
  'croppedSquareThumbnailRenderer',
  ...THUMBNAIL,
];
const List FEEDBACK_TOKEN = ['feedbackEndpoint', 'feedbackToken'];
const List BADGE_PATH = [
  0,
  'musicInlineBadgeRenderer',
  'accessibilityData',
  'accessibilityData',
  'label',
];
const List BADGE_LABEL = ['badges', ...BADGE_PATH];
const List SUBTITLE_BADGE_LABEL = ['subtitleBadges', ...BADGE_PATH];
const List CATEGORY_TITLE = [
  'musicNavigationButtonRenderer',
  'buttonText',
  ...RUN_TEXT,
];
const List CATEGORY_PARAMS = [
  'musicNavigationButtonRenderer',
  'clickCommand',
  'browseEndpoint',
  'params',
];
const String MMRIR = 'musicMultiRowListItemRenderer';
const String MRLIR = 'musicResponsiveListItemRenderer';
const String MTRIR = 'musicTwoRowItemRenderer';
const String MNIR = 'menuNavigationItemRenderer';
const List TASTE_PROFILE_ITEMS = [
  'contents',
  'tastebuilderRenderer',
  'contents',
];
const List TASTE_PROFILE_ARTIST = ['title', 'runs'];
const List SECTION_LIST_CONTINUATION = [
  'continuationContents',
  'sectionListContinuation',
];
const List MENU_PLAYLIST_ID = [
  ...MENU_ITEMS,
  0,
  MNIR,
  ...NAVIGATION_WATCH_PLAYLIST_ID,
];
const List MULTI_SELECT = ['musicMultiSelectMenuItemRenderer'];
const List HEADER = ['header'];
const List HEADER_DETAIL = [...HEADER, 'musicDetailHeaderRenderer'];
const List EDITABLE_PLAYLIST_DETAIL_HEADER = [
  'musicEditablePlaylistDetailHeaderRenderer',
];
const List HEADER_EDITABLE_DETAIL = [
  ...HEADER,
  ...EDITABLE_PLAYLIST_DETAIL_HEADER,
];
const List HEADER_SIDE = [...HEADER, 'musicSideAlignedItemRenderer'];
const List HEADER_MUSIC_VISUAL = [...HEADER, 'musicVisualHeaderRenderer'];
const List DESCRIPTION_SHELF = ['musicDescriptionShelfRenderer'];
const List DESCRIPTION = ['description', ...RUN_TEXT];
const List CAROUSEL = ['musicCarouselShelfRenderer'];
const List IMMERSIVE_CAROUSEL = ['musicImmersiveCarouselShelfRenderer'];
const List CAROUSEL_CONTENTS = [...CAROUSEL, 'contents'];
const List CAROUSEL_TITLE = [
  ...HEADER,
  'musicCarouselShelfBasicHeaderRenderer',
  ...TITLE,
];
const List CARD_SHELF_TITLE = [
  ...HEADER,
  'musicCardShelfHeaderBasicRenderer',
  ...TITLE_TEXT,
];
const List FRAMEWORK_MUTATIONS = [
  'frameworkUpdates',
  'entityBatchUpdate',
  'mutations',
];
const List TIMESTAMPED_LYRICS = [
  'contents',
  'elementRenderer',
  'newElement',
  'type',
  'componentType',
  'model',
  'timedLyricsModel',
  'lyricsData',
];

/// Access a nested object in root by item sequence.
dynamic nav(dynamic root, List items, {bool nullIfAbsent = false}) {
  if (root == null) return null;
  try {
    dynamic current = root;
    for (final k in items) {
      if (current is JsonMap) {
        current = current[k];
      } else if (current is List) {
        if (k is int && k < 0) {
          current = current.last;
        } else if (k is int && k < current.length) {
          current = current[k];
        } else {
          throw Exception('Invalid index $k for list');
        }
      } else {
        throw Exception('Invalid navigation at key $k on $current');
      }
    }
    return current;
  } catch (e) {
    if (nullIfAbsent) return null;
    throw Exception(
      'Unable to find using path $items on ${json.encode(root)}, exception: $e',
    );
  }
}

/// Finds and returns an Object inside [objectList] by its [key].
JsonMap? findObjectByKey(
  List objectList,
  String key, {
  String? nested,
  bool isKey = false,
}) {
  for (final item in objectList) {
    var current = item as JsonMap;
    if (nested != null) {
      current = current[nested] as JsonMap;
    }
    if (current.containsKey(key)) {
      return (isKey ? current[key] : current) as JsonMap?;
    }
  }
  return null;
}

/// Finds and returns Objects inside [objectList] by its [key].
List findObjectsByKey(List objectList, String key, {String? nested}) {
  final List objects = [];
  for (final item in objectList) {
    var current = item as JsonMap;
    if (nested != null) {
      current = current[nested] as JsonMap;
    }
    if (current.containsKey(key)) {
      objects.add(current);
    }
  }
  return objects;
}
