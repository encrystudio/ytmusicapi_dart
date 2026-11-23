import 'package:ytmusicapi_dart/continuations.dart';
import 'package:ytmusicapi_dart/enums.dart';
import 'package:ytmusicapi_dart/exceptions.dart';
import 'package:ytmusicapi_dart/helpers.dart';
import 'package:ytmusicapi_dart/mixins/protocol.dart';
import 'package:ytmusicapi_dart/mixins/utils.dart';
import 'package:ytmusicapi_dart/models/content/enums.dart';
import 'package:ytmusicapi_dart/models/objects/base.dart';
import 'package:ytmusicapi_dart/models/objects/playlist.dart';
import 'package:ytmusicapi_dart/models/objects/video.dart';
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
  /// The `setVideoId` is the unique id of this playlist item and
  /// needed for moving/removing playlist items.
  ///
  /// Note that communityVoteStatus can be null if the information is not available (i.e. playlist does not have that setting enabled, the request is not authenticated, ...)
  Future<YtPlaylist> getPlaylist(
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

    final isOla =
        playlistId.startsWith('OLA') || playlistId.startsWith('VLOLA');
    final hasPlaylistHeader =
        nav(response, [
          ...TWO_COLUMN_RENDERER,
          ...TAB_CONTENT,
          ...SECTION_LIST_ITEM,
        ], nullIfAbsent: true) !=
        null;
    if (isOla && !hasPlaylistHeader) {
      return await parseAudioPlaylist(
        response,
        limit,
        requestFuncContinuations,
      );
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

    final owned = headerData.containsKey(EDITABLE_PLAYLIST_DETAIL_HEADER.first);
    String? id;
    PrivacyStatus privacy;

    late JsonMap header;

    if (!owned) {
      header = nav(headerData, RESPONSIVE_HEADER) as JsonMap;
      id =
          nav(header, [
                'buttons',
                1,
                'musicPlayButtonRenderer',
                'playNavigationEndpoint',
                ...WATCH_PLAYLIST_ID,
              ], nullIfAbsent: true)
              as String?;
      privacy = PrivacyStatus.PUBLIC;
    } else {
      id =
          nav(headerData, [...EDITABLE_PLAYLIST_DETAIL_HEADER, ...PLAYLIST_ID])
              as String;
      header =
          nav(headerData, [
                ...EDITABLE_PLAYLIST_DETAIL_HEADER,
                ...HEADER,
                ...RESPONSIVE_HEADER,
              ])
              as JsonMap;
      privacy =
          PrivacyStatus.fromValue(
            (((headerData[EDITABLE_PLAYLIST_DETAIL_HEADER.first]
                            as JsonMap)['editHeader']
                        as JsonMap)['musicPlaylistEditHeaderRenderer']
                    as JsonMap)['privacy']
                as String,
          )!;
    }

    final descriptionShelf =
        nav(header, ['description', ...DESCRIPTION_SHELF], nullIfAbsent: true)
            as JsonMap?;
    final description =
        descriptionShelf != null
            ? List<JsonMap>.from(
              (descriptionShelf['description'] as JsonMap)['runs'] as List,
            ).map((run) => run['text']).join()
            : null;

    final playlistHeaderMeta = parsePlaylistHeaderMeta(header);

    final playlist = YtPlaylist(
      name: playlistHeaderMeta.title,
      id: id,
      playlistType: null,
      authors: playlistHeaderMeta.authors,
      owned: owned,
      privacy: privacy,
      thumbnails: playlistHeaderMeta.thumbnails,
      description: description,
      durationRaw: playlistHeaderMeta.durationRaw,
      duration: null,
      year: null,
      itemCount: playlistHeaderMeta.itemCount,
      views: playlistHeaderMeta.views,
      items: [],
      related: [],
      suggestions: [],
    );

    final isCollaborative = playlistHeaderMeta.authors.isNotEmpty;

    for (final (songRunsItemType, value) in parseSongRuns(
      (nav(header, SUBTITLE_RUNS) as List).sublist(
        2 + (playlist.owned != null && playlist.owned! ? 2 : 0),
      ),
    )) {
      switch (songRunsItemType) {
        case SongRunsItemType.ARTISTS:
          playlist.authors = value as List<YtBaseObject>;
        case SongRunsItemType.DURATION_RAW:
          playlist.durationRaw = value as String?;
        case SongRunsItemType.DURATION_SECONDS:
          playlist.duration = value as Duration?;
        case SongRunsItemType.VIEWS:
          playlist.views = value as int?;
        case SongRunsItemType.YEAR:
          playlist.year = value as int?;
        case SongRunsItemType.ALBUM:
          continue;
      }
    }

    // suggestions and related are missing e.g. on liked songs
    List<YtPlaylist> relatedPlaylists = [];
    List<YtVideo> suggestions = [];

    if (sectionList.containsKey('continuations')) {
      var additionalParams = getContinuationParams(sectionList);
      if (playlist.owned != null &&
          playlist.owned! &&
          (suggestionsLimit > 0 || related)) {
        List<YtVideo> parseFunc(results) =>
            parsePlaylistItems(List<JsonMap>.from(results as List));
        final suggested = await requestFunc(additionalParams);
        final continuation = nav(suggested, SECTION_LIST_CONTINUATION);
        additionalParams = getContinuationParams(continuation as JsonMap);
        final suggestionsShelf = nav(continuation, [
          ...CONTENT,
          ...MUSIC_SHELF,
        ]);
        suggestions = await getContinuationContents(
          suggestionsShelf as JsonMap,
          parseFunc,
        );
        suggestions.addAll(
          await getReloadableContinuations(
            suggestionsShelf,
            'musicShelfContinuation',
            suggestionsLimit - (suggestions.length), // TODO
            requestFunc,
            parseFunc,
          ),
        );
      }
      playlist.suggestions = suggestions;

      if (related) {
        final relatedResponse = await requestFunc(additionalParams);
        final continuation = nav(
          relatedResponse,
          SECTION_LIST_CONTINUATION,
          nullIfAbsent: true,
        );
        if (continuation != null) {
          Future<List<YtPlaylist>> parseFunc(results) => parseContentList(
            List<JsonMap>.from(results as List),
            parsePlaylist,
          );
          relatedPlaylists = await getContinuationContents(
            nav(continuation, [...CONTENT, ...CAROUSEL]) as JsonMap,
            parseFunc,
          );
        }
      }
    }
    playlist.related = relatedPlaylists;

    playlist.items = [];
    final contentData =
        nav(sectionList, [...CONTENT, 'musicPlaylistShelfRenderer']) as JsonMap;
    if (contentData.containsKey('contents')) {
      playlist.items = parsePlaylistItems(
        List<JsonMap>.from(contentData['contents'] as List),
        isCollaborative: isCollaborative,
      );
      List<YtVideo> parseFunc(contents) => parsePlaylistItems(
        List<JsonMap>.from(contents as List),
        isCollaborative: isCollaborative,
      );
      playlist.items.addAll(
        await getContinuations2025(
          contentData,
          limit,
          requestFuncContinuations,
          parseFunc,
        ),
      );
    }

    playlist.duration = Duration(seconds: sumTotalDurationPlaylist(playlist));

    return playlist;
  }

  /// Gets playlist items for the 'Liked Songs' playlist.
  ///
  /// - [limit] How many items to return. (Default: `100`).
  Future<YtPlaylist> getLikedSongs({int limit = 100}) {
    checkAuth();
    return getPlaylist('LM', limit: limit);
  }

  /// Gets playlist items for the 'Liked Songs' playlist.
  ///
  /// - [limit] How many items to return. (Default: `100`).
  Future<YtPlaylist> getSavedEpisodes({int limit = 100}) =>
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

    if (response.containsKey('playlistId')) {
      return response['playlistId'] as String;
    }

    validateWriteResponse(response);
    return response;
  }

  /// Given an invite token, join a collaborative playlist and add it to your library.
  ///
  /// - [playlistId] ID of the playlist to join.
  /// If you're already a collaborator, an Unauthorized server error is raised.
  /// - [joinCollaborationToken] See [editPlaylist], or `jct` in YTM's invite URL.
  ///
  /// Returns status string or full response.
  Future<dynamic> joinCollaborativePlaylist(
    String playlistId,
    String joinCollaborationToken,
  ) async {
    checkAuth();

    final body = <String, dynamic>{
      'playlistId': validatePlaylistId(playlistId),
      'actions': [
        {
          'action': 'ACTION_JOIN_COLLABORATION',
          'joinCollaborationToken': joinCollaborationToken,
        },
      ],
    };

    const endpoint = 'browse/edit_playlist';
    final response = await sendRequest(endpoint, body);

    return response.containsKey('status')
        ? response['status'] as String
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
  /// - [collaboration] Optional. Enable or disable collaboration.
  ///                    If False and collaboration is not enabled, a Forbidden server error is raised.
  ///                    If True, a new ``joinCollaborationToken`` is returned.
  ///                    Collaborators cannot interact with private playlists.
  /// - [moveItem] Optional. Move one item before another. Items are specified by setVideoId, which is the
  ///              unique id of this playlist item. See [getPlaylist].
  /// - [addPlaylistId] Optional. Id of another playlist to add to this playlist.
  /// - [sortOrder] Optional. Change the order tracks are returned in. The default is ``MANUAL``.
  /// - [addToTop] Optional. Change the state of this playlist to add items to the top of the playlist (if `true`)
  ///              or the bottom of the playlist (if `false` - this is also the default of a new playlist).
  /// - [voteOption]: Optional. Change who can participate in community voting in this playlist.
  ///                 Note that a bad request will be thrown if voteOption is PlaylistVoteEditOptions.COLLABORATORS_ONLY
  ///                 but the playlist is not enabled for collaboration prior to the edit.
  ///
  /// Returns Status String, [collaboration] dict described below, or full response
  ///
  /// Dictionary returned when [collaboration] is true and the request is successful
  ///
  ///   {
  ///      "status": "STATUS_SUCCEEDED",
  ///      "joinCollaborationToken": "kM9wXdRj2p8v_qL3sHBkTz"
  ///   }
  Future<dynamic> editPlaylist(
    String playlistId, {
    String? title,
    String? description,
    String? privacyStatus,
    bool? collaboration,
    dynamic moveItem,
    String? addPlaylistId,
    PlaylistSortOrder? sortOrder,
    bool? addToTop,
    PlaylistVoteEditOptions? voteOption,
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

    if (collaboration != null) {
      actions.add({'action': 'ACTION_CREATE_COLLABORATION_INVITE_LINK'});
    } else if (!collaboration!) {
      actions.add({
        'action': 'ACTION_SET_CLOSED_TO_CONTRIBUTIONS',
        'closedToContributions': true,
      });
    }

    if (moveItem != null) {
      final action = {
        'action': 'ACTION_MOVE_VIDEO_BEFORE',
        'setVideoId':
            moveItem is String ? moveItem : (moveItem as List<String>).first,
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

    if (sortOrder != null) {
      actions.add({
        'action': 'ACTION_SET_PLAYLIST_VIDEO_ORDER',
        'playlistVideoOrder': sortOrder.value,
      });
    }

    if (addToTop != null) {
      actions.add({
        'action': 'ACTION_SET_ADD_TO_TOP',
        'addToTop': addToTop.toString().toLowerCase(),
      });
    }

    if (voteOption != null) {
      actions.add({
        'action': 'ACTION_SET_ALLOW_ITEM_VOTE',
        'itemVotePermission': voteOption.getArgumentForRequest(),
      });
    }

    body['actions'] = actions;
    const endpoint = 'browse/edit_playlist';
    final response = await sendRequest(endpoint, body);

    if (collaboration && response['status'] == ResponseStatus.SUCCEEDED) {
      final inviteLink = nav(response, ['collaborationInviteLink']);

      return {
        'status': response['status'],
        'joinCollaborationToken': nav(
          Uri.splitQueryString(Uri.parse(inviteLink as String).query),
          ['jct', 0],
        ),
      };
    }

    return response.containsKey('status')
        ? response['status'] as String
        : response;
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
          List<JsonMap>.from(
            response['playlistEditResults'] as List,
          ).map((r) => r['playlistEditVideoAddedResultData']).toList();
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
