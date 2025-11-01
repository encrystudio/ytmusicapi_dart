import 'package:ytmusicapi_dart/continuations.dart';
import 'package:ytmusicapi_dart/exceptions.dart';
import 'package:ytmusicapi_dart/helpers.dart';
import 'package:ytmusicapi_dart/mixins/protocol.dart';
import 'package:ytmusicapi_dart/mixins/utils.dart';
import 'package:ytmusicapi_dart/navigation.dart';
import 'package:ytmusicapi_dart/parsers/browsing.dart';
import 'package:ytmusicapi_dart/parsers/playlists.dart';
import 'package:ytmusicapi_dart/parsers/songs.dart';
import 'package:ytmusicapi_dart/type_alias.dart';

/// Mixin for playlist functionalities.
mixin PlaylistsMixin on MixinProtocol {
  /// Returns a list of playlist items.
  ///
  /// - [playlistId] Playlist id.
  /// - [limit] How many songs to return. `null` retrieves them all. (Default: `100`).
  /// - [related] Whether to fetch 10 related playlists or not. (Default: `false`).
  /// - [suggestionsLimit] How many suggestions to return. The result is a list of
  ///                      suggested playlist items (videos) contained in a `suggestions` key.
  ///                      7 items are retrieved in each internal request. (Default: `0`).
  ///
  /// Returns Map with information about the playlist.
  /// The key `tracks` contains a List of `playlistItem` Maps
  ///
  /// The result is in the following format:
  /// ```json
  /// {
  ///   "id": "PLQwVIlKxHM6qv-o99iX9R85og7IzF9YS_",
  ///   "privacy": "PUBLIC",
  ///   "title": "New EDM This Week 03/13/2020",
  ///   "thumbnails": [...],
  ///   "description": "Weekly r/EDM new release roundup. Created with github.com/sigma67/spotifyplaylist_to_gmusic",
  ///   "author": {
  ///     "name": "sigmatics",
  ///     "id": "..."
  ///   },
  ///   "year": "2020",
  ///   "duration": "6+ hours",
  ///   "duration_seconds": 52651,
  ///   "trackCount": 237,
  ///   "suggestions": [
  ///     {
  ///       "videoId": "HLCsfOykA94",
  ///       "title": "Mambo (GATTÜSO Remix)",
  ///       "artists": [
  ///         {
  ///           "name": "Nikki Vianna",
  ///           "id": "UCMW5eSIO1moVlIBLQzq4PnQ"
  ///         }
  ///       ],
  ///       "album": {
  ///         "name": "Mambo (GATTÜSO Remix)",
  ///         "id": "MPREb_jLeQJsd7U9w"
  ///       },
  ///       "likeStatus": "LIKE",
  ///       "thumbnails": [...],
  ///       "isAvailable": true,
  ///       "isExplicit": false,
  ///       "duration": "3:32",
  ///       "duration_seconds": 212,
  ///       "setVideoId": "to_be_updated_by_client"
  ///     }
  ///   ],
  ///   "related": [
  ///     {
  ///       "title": "Presenting MYRNE",
  ///       "playlistId": "RDCLAK5uy_mbdO3_xdD4NtU1rWI0OmvRSRZ8NH4uJCM",
  ///       "thumbnails": [...],
  ///       "description": "Playlist • YouTube Music"
  ///     }
  ///   ],
  ///   "tracks": [
  ///     {
  ///       "videoId": "bjGppZKiuFE",
  ///       "title": "Lost",
  ///       "artists": [
  ///         {
  ///           "name": "Guest Who",
  ///           "id": "UCkgCRdnnqWnUeIH7EIc3dBg"
  ///         },
  ///         {
  ///           "name": "Kate Wild",
  ///           "id": "UCwR2l3JfJbvB6aq0RnnJfWg"
  ///         }
  ///       ],
  ///       "album": {
  ///         "name": "Lost",
  ///         "id": "MPREb_PxmzvDuqOnC"
  ///       },
  ///       "duration": "2:58",
  ///       "duration_seconds": 178,
  ///       "setVideoId": "748EE8...",
  ///       "likeStatus": "INDIFFERENT",
  ///       "thumbnails": [...],
  ///       "isAvailable": true,
  ///       "isExplicit": false,
  ///       "videoType": "MUSIC_VIDEO_TYPE_OMV",
  ///       "feedbackTokens": {
  ///         "add": "AB9zfpJxtvrU...",
  ///         "remove": "AB9zfpKTyZ..."
  ///       }
  ///     }
  ///   ]
  /// }
  ///
  /// ```
  /// The `setVideoId` is the unique id of this playlist item and
  /// needed for moving/removing playlist items.
  Future<JsonMap> getPlaylist(
    String playlistId, {
    int? limit = 100,
    bool related = false,
    int suggestionsLimit = 0,
  }) async {
    // checkAuth(); // TODO this was in original code, can be removed?
    final browseId = playlistId.startsWith('VL') ? playlistId : 'VL$playlistId';
    final JsonMap body = {'browseId': browseId};
    const endpoint = 'browse';
    Future<JsonMap> requestFunc(String additionalParams) =>
        sendRequest(endpoint, body, additionalParams: additionalParams);

    final response = await requestFunc('');

    Future<JsonMap> requestFuncContinuations(JsonMap body) =>
        sendRequest(endpoint, body);

    if (playlistId.startsWith('OLA') || playlistId.startsWith('VLOLA')) {
      return parseAudioPlaylist(response, limit, requestFuncContinuations);
    }

    final headerData =
        nav(response, [
              ...TWO_COLUMN_RENDERER,
              ...TAB_CONTENT,
              ...SECTION_LIST_ITEM,
            ])
            as JsonMap;
    final sectionList =
        nav(response, [...TWO_COLUMN_RENDERER, 'secondaryContents', ...SECTION])
            as JsonMap;

    final playlist = <String, dynamic>{};
    playlist['owned'] = headerData.containsKey(
      EDITABLE_PLAYLIST_DETAIL_HEADER[0],
    );

    late JsonMap header;

    if (!(playlist['owned'] as bool)) {
      header = nav(headerData, RESPONSIVE_HEADER) as JsonMap;
      playlist['id'] = nav(header, [
        'buttons',
        1,
        'musicPlayButtonRenderer',
        'playNavigationEndpoint',
        ...WATCH_PLAYLIST_ID,
      ], nullIfAbsent: true);
      playlist['privacy'] = 'PUBLIC';
    } else {
      playlist['id'] = nav(headerData, [
        ...EDITABLE_PLAYLIST_DETAIL_HEADER,
        ...PLAYLIST_ID,
      ]);
      header =
          nav(headerData, [
                ...EDITABLE_PLAYLIST_DETAIL_HEADER,
                ...HEADER,
                ...RESPONSIVE_HEADER,
              ])
              as JsonMap;
      playlist['privacy'] =
          (((headerData[EDITABLE_PLAYLIST_DETAIL_HEADER[0]]
                      as JsonMap)['editHeader']
                  as JsonMap)['musicPlaylistEditHeaderRenderer']
              as JsonMap)['privacy'];
    }

    final descriptionShelf =
        nav(header, ['description', ...DESCRIPTION_SHELF], nullIfAbsent: true)
            as JsonMap?;
    playlist['description'] =
        descriptionShelf != null
            ? ((descriptionShelf['description'] as JsonMap)['runs']
                    as List<JsonMap>)
                .map((run) => run['text'])
                .join()
            : null;

    playlist.addAll(parsePlaylistHeaderMeta(header));

    playlist.addAll(
      parseSongRuns(
        (nav(header, SUBTITLE_RUNS) as List).sublist(
          2 + ((playlist['owned'] as bool) ? 2 : 0),
        ),
      ),
    );

    // suggestions and related are missing e.g. on liked songs
    playlist['related'] = [];

    if (sectionList.containsKey('continuations')) {
      var additionalParams = getContinuationParams(sectionList);
      if ((playlist['owned'] as bool) && (suggestionsLimit > 0 || related)) {
        List parseFunc(results) => parsePlaylistItems(results as List<JsonMap>);
        final suggested = await requestFunc(additionalParams);
        final continuation = nav(suggested, SECTION_LIST_CONTINUATION);
        additionalParams = getContinuationParams(continuation as JsonMap);
        final suggestionsShelf = nav(continuation, [
          ...CONTENT,
          ...MUSIC_SHELF,
        ]);
        playlist['suggestions'] = getContinuationContents(
          suggestionsShelf as JsonMap,
          parseFunc,
        );
        (playlist['suggestions'] as List).addAll(
          await getReloadableContinuations(
            suggestionsShelf,
            'musicShelfContinuation',
            suggestionsLimit -
                ((playlist['suggestions'] as List).length), // TODO
            requestFunc,
            parseFunc,
          ),
        );
      }

      if (related) {
        final relatedResponse = await requestFunc(additionalParams);
        final continuation = nav(
          relatedResponse,
          SECTION_LIST_CONTINUATION,
          nullIfAbsent: true,
        );
        if (continuation != null) {
          Future<List> parseFunc(results) =>
              parseContentList(results as List<JsonMap>, parsePlaylist);
          playlist['related'] = getContinuationContents(
            nav(continuation, [...CONTENT, ...CAROUSEL]) as JsonMap,
            parseFunc,
          );
        }
      }
    }

    playlist['tracks'] = [];
    final contentData =
        nav(sectionList, [...CONTENT, 'musicPlaylistShelfRenderer']) as JsonMap;
    if (contentData.containsKey('contents')) {
      playlist['tracks'] = parsePlaylistItems(
        contentData['contents'] as List<JsonMap>,
      );
      List parseFunc(contents) => parsePlaylistItems(contents as List<JsonMap>);
      (playlist['tracks'] as List).addAll(
        await getContinuations2025(
          contentData,
          limit,
          requestFuncContinuations,
          parseFunc,
        ),
      );
    }

    playlist['duration_seconds'] = sumTotalDuration(playlist);

    return playlist;
  }

  /// Gets playlist items for the 'Liked Songs' playlist.
  ///
  /// - [limit] How many items to return. (Default: `100`).
  ///
  /// Returns List of `playlistItem` Maps. See [getPlaylist].
  Future<JsonMap> getLikedSongs({int limit = 100}) =>
      getPlaylist('LM', limit: limit);

  /// Gets playlist items for the 'Liked Songs' playlist.
  ///
  /// - [limit] How many items to return. (Default: `100`).
  ///
  /// Returns List of `playlistItem` Maps. See [getPlaylist].
  Future<JsonMap> getSavedEpisodes({int limit = 100}) =>
      getPlaylist('SE', limit: limit);

  /// Creates a new empty playlist and returns its id.
  ///
  /// - [title] Playlist title.
  /// - [description] Playlist description.
  /// - [privacyStatus] Playlists can be `PUBLIC`, `PRIVATE`, or `UNLISTED`. (Default: `PRIVATE`).
  /// - [videoIds] IDs of songs to create the playlist with.
  /// - [sourcePlaylist] Another playlist whose songs should be added to the new playlist.
  ///
  /// Returns ID of the YouTube playlist or full response if there was an error.
  Future<dynamic> createPlaylist(
    String title,
    String description, {
    String privacyStatus = 'PRIVATE',
    List<String>? videoIds,
    String? sourcePlaylist,
  }) async {
    checkAuth();

    final invalidCharacters = [
      '<',
      '>',
    ]; // ytmusic will crash if these are part of the title
    final invalidFound =
        invalidCharacters.where((c) => title.contains(c)).toList();
    if (invalidFound.isNotEmpty) {
      throw YTMusicUserError(
        '$title contains invalid characters: ${invalidFound.join(', ')}',
      );
    }

    final body = <String, dynamic>{
      'title': title,
      'description': htmlToTxt(description), // YT does not allow HTML tags
      'privacyStatus': privacyStatus,
    };

    if (videoIds != null) body['videoIds'] = videoIds;
    if (sourcePlaylist != null) body['sourcePlaylistId'] = sourcePlaylist;

    const endpoint = 'playlist/create';
    final response = await sendRequest(endpoint, body);
    return response.containsKey('playlistId')
        ? response['playlistId']
        : response;
  }

  /// Edit `title`, `description` or `privacyStatus` of a playlist.
  ///
  /// You may also move an item within a playlist or append another playlist to this playlist.
  ///
  /// - [playlistId] Playlist id.
  /// - [title] Optional. New title for the playlist.
  /// - [description] Optional. New description for the playlist.
  /// - [privacyStatus] Optional. New privacy status for the playlist.
  /// - [moveItem] Optional. Move one item before another. Items are specified by setVideoId, which is the
  ///              unique id of this playlist item. See [getPlaylist].
  /// - [addPlaylistId] Optional. Id of another playlist to add to this playlist.
  /// - [addToTop] Optional. Change the state of this playlist to add items to the top of the playlist (if `true`)
  ///              or the bottom of the playlist (if `false` - this is also the default of a new playlist).
  ///
  /// Returns status String or full response.
  Future<dynamic> editPlaylist(
    String playlistId, {
    String? title,
    String? description,
    String? privacyStatus,
    dynamic moveItem,
    String? addPlaylistId,
    bool? addToTop,
  }) async {
    checkAuth();
    final body = <String, dynamic>{
      'playlistId': validatePlaylistId(playlistId),
    };
    final actions = <JsonMap>[];

    if (title != null) {
      actions.add({
        'action': 'ACTION_SET_PLAYLIST_NAME',
        'playlistName': title,
      });
    }
    if (description != null) {
      actions.add({
        'action': 'ACTION_SET_PLAYLIST_DESCRIPTION',
        'playlistDescription': description,
      });
    }
    if (privacyStatus != null) {
      actions.add({
        'action': 'ACTION_SET_PLAYLIST_PRIVACY',
        'playlistPrivacy': privacyStatus,
      });
    }

    if (moveItem != null) {
      final action = {
        'action': 'ACTION_MOVE_VIDEO_BEFORE',
        'setVideoId':
            moveItem is String ? moveItem : (moveItem as List<String>)[0],
      };
      if (moveItem is List && moveItem.length > 1) {
        action['movedSetVideoIdSuccessor'] = (moveItem as List<String>)[1];
      }
      actions.add(action);
    }

    if (addPlaylistId != null) {
      actions.add({
        'action': 'ACTION_ADD_PLAYLIST',
        'addedFullListId': addPlaylistId,
      });
    }
    if (addToTop != null) {
      actions.add({
        'action': 'ACTION_SET_ADD_TO_TOP',
        'addToTop': addToTop.toString(),
      });
    }

    body['actions'] = actions;
    const endpoint = 'browse/edit_playlist';
    final response = await sendRequest(endpoint, body);
    return response.containsKey('status') ? response['status'] : response;
  }

  /// Delete a playlist.
  ///
  /// - [playlistId] Playlist id.
  ///
  /// Returns status String or full response.
  Future<dynamic> deletePlaylist(String playlistId) async {
    checkAuth();
    final body = {'playlistId': validatePlaylistId(playlistId)};
    const endpoint = 'playlist/delete';
    final response = await sendRequest(endpoint, body);
    return response.containsKey('status') ? response['status'] : response;
  }

  /// Add songs to an existing playlist.
  ///
  /// - [playlistId] Playlist id.
  /// - [videoIds] List of Video ids.
  /// - [sourcePlaylist] Playlist id of a playlist to add to the current playlist (no duplicate check).
  /// - [duplicates] If `true`, duplicates will be added. If `false`, an error will be returned if there are duplicates (no items are added to the playlist).
  ///
  /// Returns status String and a Map containing the new `setVideoId` for each `videoId` or full response.
  Future<dynamic> addPlaylistItems(
    String playlistId, {
    List<String>? videoIds,
    String? sourcePlaylist,
    bool duplicates = false,
  }) async {
    checkAuth();
    final body = {'playlistId': validatePlaylistId(playlistId), 'actions': []};

    if ((videoIds == null || videoIds.isEmpty) && sourcePlaylist == null) {
      throw YTMusicUserError(
        'You must provide either videoIds or a source_playlist to add to the playlist',
      );
    }

    if (videoIds != null) {
      for (final videoId in videoIds) {
        final action = {'action': 'ACTION_ADD_VIDEO', 'addedVideoId': videoId};
        if (duplicates) action['dedupeOption'] = 'DEDUPE_OPTION_SKIP';
        (body['actions']! as List).add(action);
      }
    }

    if (sourcePlaylist != null) {
      (body['actions']! as List).add({
        'action': 'ACTION_ADD_PLAYLIST',
        'addedFullListId': sourcePlaylist,
      });
      // add an empty ACTION_ADD_VIDEO because otherwise
      // YTM doesn't return the Map that maps videoIds to their new setVideoIds
      if (videoIds == null) {
        (body['actions']! as List).add({
          'action': 'ACTION_ADD_VIDEO',
          'addedVideoId': null,
        });
      }
    }

    const endpoint = 'browse/edit_playlist';
    final response = await sendRequest(endpoint, body);

    if (response.containsKey('status') &&
        (response['status'] as JsonMap).containsKey('SUCCEEDED')) {
      final resultMap =
          (response['playlistEditResults'] as List<JsonMap>)
              .map((r) => r['playlistEditVideoAddedResultData'])
              .toList();
      return {'status': response['status'], 'playlistEditResults': resultMap};
    } else {
      return response;
    }
  }

  /// Remove songs from an existing playlist.
  ///
  /// - [playlistId] Playlist id.
  /// - [videos] List of PlaylistItems, see [getPlaylist].
  ///            Must contain `videoId` and `setVideoId`.
  ///
  /// Returns status String or full response.
  Future<dynamic> removePlaylistItems(
    String playlistId,
    List<JsonMap> videos,
  ) async {
    checkAuth();
    final filtered =
        videos
            .where(
              (v) => v.containsKey('videoId') && v.containsKey('setVideoId'),
            )
            .toList();
    if (filtered.isEmpty) {
      throw YTMusicUserError(
        'Cannot remove songs, because setVideoId is missing. Do you own this playlist?',
      );
    }

    final body = {'playlistId': validatePlaylistId(playlistId), 'actions': []};
    for (final video in filtered) {
      (body['actions']! as List).add({
        'setVideoId': video['setVideoId'],
        'removedVideoId': video['videoId'],
        'action': 'ACTION_REMOVE_VIDEO',
      });
    }

    const endpoint = 'browse/edit_playlist';
    final response = await sendRequest(endpoint, body);
    return response.containsKey('status') ? response['status'] : response;
  }
}
