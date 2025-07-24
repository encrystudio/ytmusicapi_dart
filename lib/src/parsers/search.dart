import 'package:ytmusicapi_dart/src/navigation.dart';
import 'package:ytmusicapi_dart/src/parsers/_utils.dart';

import '../helpers.dart';
import 'songs.dart';

const allResultTypes = [
  'album',
  'artist',
  'playlist',
  'song',
  'video',
  'station',
  'profile',
  'podcast',
  'episode',
];

String? getSearchResultType(
  String resultTypeLocal,
  List<String> resultTypesLocal,
) {
  String resultType = '';
  if (resultTypeLocal.isEmpty) {
    return null;
  }
  resultTypeLocal = resultTypeLocal.toLowerCase();
  if (!resultTypesLocal.contains(resultTypeLocal)) {
    resultType = 'album';
  } else {
    resultType = allResultTypes[resultTypesLocal.indexOf(resultTypeLocal)];
  }
  return resultType;
}

Map<String, dynamic> parseTopResult(
  Map<String, dynamic> data,
  List<String> searchResultTypes,
) {
  var resultType = getSearchResultType(nav(data, subtitle), searchResultTypes);
  var searchResult = {
    'category': nav(data, cardShelfTitle),
    'resultType': resultType,
  };
  if (resultType == 'artist') {
    String? subscribers = nav(data, subtitle2, nullIfAbsent: true);
    if (subscribers != null && subscribers.isNotEmpty) {
      searchResult['subscribers'] = subscribers.split(" ")[0];
    }

    var artistInfo = parseSongRuns(nav(data, ['title', 'runs']));
    searchResult.addAll(artistInfo);
  }

  if (resultType == 'song' || resultType == 'video') {
    var onTap = data['onTap'];
    if (onTap != null) {
      searchResult['videoId'] = nav(onTap, watchVideoId);
      searchResult['videoType'] = nav(onTap, navigationVideoType);
    }
  }

  if (resultType == 'song' || resultType == 'video' || resultType == 'album') {
    searchResult['videoId'] = nav(data, [
      "onTap",
      'watchEndpoint',
      'videoId',
    ], nullIfAbsent: true);
    searchResult['videoType'] = nav(data, [
      "onTap",
      'watchEndpoint',
      'watchEndpointMusicSupportedConfigs',
      'watchEndpointMusicConfig',
      'musicVideoType',
    ], nullIfAbsent: true);

    searchResult['title'] = nav(data, titleText);
    var runs = nav(data, ['subtitle', 'runs']);
    var songInfo = parseSongRuns(runs.sublist(2));
    searchResult.addAll(songInfo);
  }

  if (resultType == 'album') {
    searchResult['browseId'] = nav(
      data,
      title + navigationBrowseId,
      nullIfAbsent: true,
    );
    var buttonCommand = nav(data, [
      'buttons',
      0,
      'buttonRenderer',
      'command',
    ], nullIfAbsent: true);
    searchResult['playlistId'] = parseAlbumPlaylistIdIfExists(buttonCommand);
  }

  if (resultType == 'playlist') {
    searchResult['playlistId'] = nav(data, menuPlaylistId);
    searchResult['title'] = nav(data, titleText);
    searchResult['author'] = parseSongArtistsRuns(
      nav(data, ['subtitle', 'runs']).sublist(2).cast<Map<String, dynamic>>(),
    );
  }

  searchResult['thumbnails'] = nav(data, thumbnails, nullIfAbsent: true);
  return searchResult;
}

String? parseAlbumPlaylistIdIfExists(Map<String, dynamic>? data) {
  return data != null
      ? nav(data, watchPid, nullIfAbsent: true) ??
          nav(data, watchPlaylistId, nullIfAbsent: true)
      : null;
}

List<dynamic> parseSearchResults(
  List<dynamic> results,
  List<String> apiSearchResultTypes,
  String? resultType,
  String? category,
) {
  List<Map<String, dynamic>> parsed = [];

  for (var result in results) {
    parsed.add(
      parseSearchResult(
        result[mrlir],
        apiSearchResultTypes,
        resultType,
        category,
      ),
    );
  }

  return parsed;
}

Map<String, dynamic> parseSearchResult(
  Map<String, dynamic> data,
  List<String> apiSearchResultTypes,
  String? resultType,
  String? category,
) {
  var defaultOffset =
      ((resultType == null || resultType.isEmpty) || resultType == 'album')
          ? 2
          : 0;
  Map<String, dynamic> searchResult = {'category': category};
  var videoType = nav(
    data,
    playButton + ['playNavigationEndpoint'] + navigationVideoType,
    nullIfAbsent: true,
  );

  // determine result type based on browseId
  if (resultType == null || resultType.isEmpty) {
    var browseId = nav(data, navigationBrowseId, nullIfAbsent: true);
    if (browseId != null) {
      var mapping = {
        'VM': 'playlist',
        'RD': 'playlist',
        'VL': 'playlist',
        'MPLA': 'artist',
        'MPRE': 'album',
        'MPSP': 'podcast',
        'MPED': 'episode',
        'UC': 'artist',
      };

      resultType =
          mapping.entries.firstWhere((e) => browseId.startsWith(e.key)).value;
    } else {
      resultType = (videoType == 'MUSIC_VIDEO_TYPE_ATV') ? 'song' : 'video';
    }
  }

  searchResult['resultType'] = resultType;

  if (resultType != 'artist') {
    searchResult['title'] = getItemText(data, 0);
  }

  if (resultType == 'artist') {
    searchResult['artist'] = getItemText(data, 0);
    parseMenuPlaylists(data, searchResult);
  } else if (resultType == 'album') {
    searchResult['type'] = getItemText(data, 1);
    var playNavigation = nav(
      data,
      playButton + ['playNavigationEndpoint'],
      nullIfAbsent: true,
    );
    searchResult['playlistId'] = parseAlbumPlaylistIdIfExists(playNavigation);
  } else if (resultType == 'playlist') {
    var flexItem = nav(getFlexColumnItem(data, 1), textRuns);
    var hasAuthor = (flexItem.length == defaultOffset + 3) ? 1 : 0;
    var itemText = getItemText(
      data,
      1,
      runIndex: defaultOffset + hasAuthor * 2,
    );
    searchResult['itemCount'] =
        ((itemText != null && itemText.isNotEmpty) ? itemText : '').split(
          ' ',
        )[0];
    if ((searchResult['itemCount'] != null &&
            searchResult['itemCount']!.isNotEmpty) &&
        isDigit(searchResult['itemCount']!)) {
      searchResult['itemCount'] = toInt(searchResult['itemCount']);
    }
    searchResult['author'] =
        hasAuthor == 0 ? null : getItemText(data, 1, runIndex: defaultOffset);
  } else if (resultType == 'station') {
    searchResult['videoId'] = nav(data, navigationVideoId);
    searchResult['playlistId'] = nav(data, navigationVideoId);
  } else if (resultType == 'profile') {
    searchResult['name'] = getItemText(
      data,
      1,
      runIndex: 2,
      nullIfAbsent: true,
    );
  } else if (resultType == 'song') {
    searchResult['album'] = null;
    if (data.containsKey('menu')) {
      var toggleMenuData = findObjectByKey(nav(data, menuItems), toggleMenu);
      if (toggleMenuData != null) {
        searchResult['inLibrary'] = parseSongLibraryStatus(toggleMenuData);
        searchResult['feedbackTokens'] = parseSongMenuTokens(toggleMenuData);
      }
    }
  } else if (resultType == 'upload') {
    var browseId = nav(data, navigationBrowseId, nullIfAbsent: true);
    if (browseId == null) {
      // song result
      var flexItems = [
        nav(getFlexColumnItem(data, 0), ['text', 'runs'], nullIfAbsent: true),
        nav(getFlexColumnItem(data, 1), ['text', 'runs'], nullIfAbsent: true),
      ];
      if (flexItems[0] != null) {
        searchResult['videoId'] = nav(
          flexItems[0][0],
          navigationVideoId,
          nullIfAbsent: true,
        );
        searchResult['playlistId'] = nav(
          flexItems[0][0],
          navigationPlaylistId,
          nullIfAbsent: true,
        );
      }
      if (flexItems[1] != null) {
        searchResult.addAll(parseSongRuns(flexItems[1]));
      }
      searchResult['resultType'] = 'song';
    } else {
      // artist or album result
      searchResult['browseId'] = browseId;
      if (searchResult['browseId']!.contains('artist')) {
        searchResult['resultType'] = 'artist';
      } else {
        var flexItem2 = getFlexColumnItem(data, 1);
        List<String> runs = [];
        if (flexItem2 != null) {
          var textRuns2 = flexItem2["text"]["runs"];
          for (int i = 0; i < textRuns2.length; i += 2) {
            runs.add(textRuns2[i]["text"]);
          }
        }
        if (runs.length > 1) {
          searchResult['artist'] = runs[1];
        }
        if (runs.length > 2) {
          // date may be missing
          searchResult['releaseDate'] = runs[2];
        }
        searchResult['resultType'] = 'album';
      }
    }
  }

  if (['song', 'video', 'episode'].contains(resultType)) {
    searchResult['videoId'] = nav(
      data,
      playButton + ['playNavigationEndpoint', 'watchEndpoint', 'videoId'],
      nullIfAbsent: true,
    );
    searchResult['videoType'] = videoType;
  }

  if (['song', 'video', 'album'].contains(resultType)) {
    searchResult['duration'] = null;
    searchResult['year'] = null;
    var flexItem = getFlexColumnItem(data, 1);
    var runs = flexItem!['text']['runs'];
    var flexItem2 = getFlexColumnItem(data, 2);
    if (flexItem2 != null) {
      runs.addAll([
        {'text': ''},
      ]); // item is a dummy separator
      runs.addAll(flexItem2['text']['runs']);
      // ignore the first run if it is a type specifier (like "Single" or "Album")
      var runsOffset =
          (runs[0].length == 1 &&
                  apiSearchResultTypes.contains(runs[0]['text'].toLowerCase()))
              ? 2
              : 0;
      var songInfo = parseSongRuns(runs.sublist(runsOffset));
      searchResult.addAll(songInfo);
    }
  }
  if ([
    'artist',
    'album',
    'playlist',
    'profile',
    'podcast',
  ].contains(resultType)) {
    searchResult['browseId'] = nav(
      data,
      navigationBrowseId,
      nullIfAbsent: true,
    );
  }

  if (['song', 'album'].contains(resultType)) {
    searchResult['isExplicit'] =
        (nav(data, badgeLabel, nullIfAbsent: true) != null);
  }

  if (resultType == 'episode') {
    var flexItem = getFlexColumnItem(data, 1);
    var hasDate = (nav(flexItem, textRuns).length > 1) ? 1 : 0;
    searchResult['live'] =
        (nav(data, ['badges', 0, 'liveBadgeRenderer'], nullIfAbsent: true) !=
            null);
    if (hasDate == 1) {
      searchResult['date'] = nav(flexItem, textRunText);
    }

    searchResult['podcast'] = parseIdName(
      nav(flexItem, ['text', 'runs', hasDate * 2]),
    );
  }

  searchResult['thumbnail'] = nav(data, thumbnails, nullIfAbsent: true);

  return searchResult;
}
