const badgeLabel = [
  'badges',
  0,
  'musicInlineBadgeRenderer',
  'accessibilityData',
  'accessibilityData',
  'label',
];
const cardShelfTitle = [
  'header',
  'musicCardShelfHeaderBasicRenderer',
  'title',
  'runs',
  0,
  'text',
];
const feedbackToken = ['feedbackEndpoint', 'feedbackToken'];
const iconType = ['icon', 'iconType'];
const menuItems = ['menu', 'menuRenderer', 'items'];
const menuPlaylistId = [
  'menu',
  'menuRenderer',
  'items',
  0,
  'menuNavigationItemRenderer',
  'navigationEndpoint',
  'watchPlaylistEndpoint',
  'playlistId',
];
const mnir = 'menuNavigationItemRenderer';
const mrlir = 'musicResponsiveListItemRenderer';
const List<Object> musicShelf = ['musicShelfRenderer'];
const navigationBrowseId = ['navigationEndpoint', 'browseEndpoint', 'browseId'];
const navigationPlaylistId = [
  'navigationEndpoint',
  'watchEndpoint',
  'playlistId',
];
const navigationVideoId = ['navigationEndpoint', 'watchEndpoint', 'videoId'];
const navigationVideoType = [
  'watchEndpoint',
  'watchEndpointMusicSupportedConfigs',
  'watchEndpointMusicConfig',
  'musicVideoType',
];
const playButton = [
  'overlay',
  'musicItemThumbnailOverlayRenderer',
  'content',
  'musicPlayButtonRenderer',
];
const section = ['sectionListRenderer'];
const sectionListContent = ['sectionListRenderer', 'contents'];
const subtitle = ['subtitle', 'runs', 0, 'text'];
const subtitle2 = ['subtitle', 'runs', 2, 'text'];
const textRuns = ['text', 'runs'];
const textRunText = ['text', 'runs', 0, 'text'];
const thumbnails = [
  'thumbnail',
  'musicThumbnailRenderer',
  'thumbnail',
  'thumbnails',
];
const title = ['title', 'runs', 0];
const titleText = ['title', 'runs', 0, 'text'];
const titleRunText = ['text', 'runs', 0, 'text'];
const toggleMenu = 'toggleMenuServiceItemRenderer';
const watchPid = ['watchPlaylistEndpoint', 'playlistId'];
const watchPlaylistId = ['watchEndpoint', 'playlistId'];
const watchVideoId = ['watchEndpoint', 'videoId'];

dynamic nav(
  Map<String, dynamic>? root,
  List<Object> items, {
  bool nullIfAbsent = false,
}) {
  dynamic newRoot = root;
  if (newRoot == null) {
    return null;
  }
  dynamic lastK;
  try {
    for (var k in items) {
      lastK = k;
      newRoot = newRoot[k];
    }
  } catch (e) {
    if (nullIfAbsent) {
      return null;
    }

    throw Exception(
      'Unable to find "$lastK" using path $items on $newRoot, exception: $e',
    );
  }
  return newRoot;
}

Map<String, dynamic>? findObjectByKey(
  List<dynamic> objectList,
  String key, {
  String? nested,
  bool isKey = false,
}) {
  for (var item in objectList) {
    if (nested != null && nested.trim().isNotEmpty) {
      item = item[nested];
    }
    if (item.containsKey(key)) {
      return (isKey) ? item[key] : item;
    }
  }
  return null;
}

List<Map<String, dynamic>> findObjectsByKey(
  List<dynamic> objectList,
  String key, {
  String? nested,
}) {
  List<Map<String, dynamic>> objects = [];
  for (var item in objectList) {
    if (nested != null && nested.trim().isNotEmpty) {
      item = item[nested];
    }
    if (item.containsKey(key)) {
      objects.add(item);
    }
  }
  return objects;
}
