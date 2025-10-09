import 'package:ytmusicapi_dart/continuations.dart';
import 'package:ytmusicapi_dart/exceptions.dart';
import 'package:ytmusicapi_dart/mixins/protocol.dart';
import 'package:ytmusicapi_dart/navigation.dart';
import 'package:ytmusicapi_dart/parsers/playlists.dart';
import 'package:ytmusicapi_dart/parsers/watch.dart';
import 'package:ytmusicapi_dart/type_alias.dart';

/// Mixin for watch functionalities.
mixin WatchMixin on MixinProtocol {
  /// Get a watch list of tracks. This watch playlist appears when you press
  /// play on a track in YouTube Music.
  ///
  /// Please note that the `INDIFFERENT` `likeStatus` of tracks returned by this
  /// endpoint may be either `INDIFFERENT` or `DISLIKE`, due to ambiguous data
  /// returned by YouTube Music.
  ///
  /// - [videoId] `videoId` of the played video.
  /// - [playlistId] `playlistId` of the played playlist or album.
  /// - [limit] Minimum number of watch playlist items to return.
  /// - [radio] Get a radio playlist (changes each time).
  /// - [shuffle] Shuffle the input playlist. Only works when the `playlistId`
  ///             parameter is set at the same time. Does not work if [radio]=`true`.
  ///
  /// Returns List of watch playlist items. The counterpart key is optional and
  /// only appears if a song has a corresponding video counterpart (UI song/video switcher).
  ///
  /// Example:
  /// ```json
  /// {
  ///   "tracks": [
  ///     {
  ///       "videoId": "9mWr4c_ig54",
  ///       "title": "Foolish Of Me (feat. Jonathan Mendelsohn)",
  ///       "length": "3:07",
  ///       "thumbnail": [
  ///         {
  ///           "url": "https://lh3.googleusercontent.com/ulK2YaLtOW0PzcN7ufltG6e4ae3WZ9Bvg8CCwhe6LOccu1lCKxJy2r5AsYrsHeMBSLrGJCNpJqXgwczk=w60-h60-l90-rj",
  ///           "width": 60,
  ///           "height": 60
  ///         }...
  ///       ],
  ///       "feedbackTokens": {
  ///         "add": "AB9zfpIGg9XN4u2iJ...",
  ///         "remove": "AB9zfpJdzWLcdZtC..."
  ///       },
  ///       "likeStatus": "INDIFFERENT",
  ///       "videoType": "MUSIC_VIDEO_TYPE_ATV",
  ///       "artists": [
  ///         {
  ///           "name": "Seven Lions",
  ///           "id": "UCYd2yzYRx7b9FYnBSlbnknA"
  ///         },
  ///         {
  ///           "name": "Jason Ross",
  ///           "id": "UCVCD9Iwnqn2ipN9JIF6B-nA"
  ///         },
  ///         {
  ///           "name": "Crystal Skies",
  ///           "id": "UCTJZESxeZ0J_M7JXyFUVmvA"
  ///         }
  ///       ],
  ///       "album": {
  ///         "name": "Foolish Of Me",
  ///         "id": "MPREb_C8aRK1qmsDJ"
  ///       },
  ///       "year": "2020",
  ///       "counterpart": {
  ///         "videoId": "E0S4W34zFMA",
  ///         "title": "Foolish Of Me [ABGT404] (feat. Jonathan Mendelsohn)",
  ///         "length": "3:07",
  ///         "thumbnail": [...],
  ///         "feedbackTokens": null,
  ///         "likeStatus": "LIKE",
  ///         "artists": [
  ///           {
  ///             "name": "Jason Ross",
  ///             "id": null
  ///           },
  ///           {
  ///             "name": "Seven Lions",
  ///             "id": null
  ///           },
  ///           {
  ///             "name": "Crystal Skies",
  ///             "id": null
  ///           }
  ///         ],
  ///         "views": "6.6K"
  ///       }
  ///     }
  ///   ],...
  ///   "playlistId": "RDAMVM4y33h81phKU",
  ///   "lyrics": "MPLYt_HNNclO0Ddoc-17"
  /// }
  /// ```
  Future<JsonMap> getWatchPlaylist({
    String? videoId,
    String? playlistId,
    int limit = 25,
    bool radio = false,
    bool shuffle = false,
  }) async {
    final body = <String, dynamic>{
      'enablePersistentPlaylistPanel': true,
      'isAudioOnly': true,
      'tunerSettingValue': 'AUTOMIX_SETTING_NORMAL',
    };

    if (videoId == null && playlistId == null) {
      throw YTMusicUserError(
        'You must provide either a video id, a playlist id, or both',
      );
    }

    if (videoId != null) {
      body['videoId'] = videoId;
      playlistId ??= 'RDAMVM$videoId';

      if (!radio && !shuffle) {
        body['watchEndpointMusicSupportedConfigs'] = {
          'watchEndpointMusicConfig': {
            'hasPersistentPlaylistPanel': true,
            'musicVideoType': 'MUSIC_VIDEO_TYPE_ATV',
          },
        };
      }
    }

    var isPlaylist = false;
    if (playlistId != null) {
      final playlistIdValidated = validatePlaylistId(playlistId);
      isPlaylist =
          playlistIdValidated.startsWith('PL') ||
          playlistIdValidated.startsWith('OLA');
      body['playlistId'] = playlistIdValidated;
    }

    if (shuffle && playlistId != null) {
      body['params'] = 'wAEB8gECKAE%3D';
    }
    if (radio) {
      body['params'] = 'wAEB';
    }

    const endpoint = 'next';
    final response = await sendRequest(endpoint, body);

    final watchNextRenderer = nav(response, [
      'contents',
      'singleColumnMusicWatchNextResultsRenderer',
      'tabbedRenderer',
      'watchNextTabbedResultsRenderer',
    ]);

    final lyricsBrowseId = getTabBrowseId(watchNextRenderer as JsonMap, 1);
    final relatedBrowseId = getTabBrowseId(watchNextRenderer, 2);

    final results =
        nav(watchNextRenderer, [
              ...TAB_CONTENT,
              'musicQueueRenderer',
              'content',
              'playlistPanelRenderer',
            ], nullIfAbsent: true)
            as JsonMap?;

    if (results == null) {
      var msg = 'No content returned by the server.';
      if (playlistId != null) {
        msg +=
            '\nEnsure you have access to $playlistId - a private playlist may cause this.';
      }
      throw YTMusicServerError(msg);
    }

    final playlistIterable = (results['contents'] as List)
        .map(
          (x) => nav(x, [
            'playlistPanelVideoRenderer',
            ...NAVIGATION_PLAYLIST_ID,
          ], nullIfAbsent: true),
        )
        .where((x) => x != null && x != false);

    final playlist = playlistIterable.isEmpty ? null : playlistIterable.first;

    final tracks = parseWatchPlaylist(
      List<JsonMap>.from(results['contents'] as List),
    );

    if (results.containsKey('continuations')) {
      Future<JsonMap> requestFunc(dynamic additionalParams) => sendRequest(
        endpoint,
        body,
        additionalParams: additionalParams as String,
      );
      List parseFunc(dynamic contents) =>
          parseWatchPlaylist(List<JsonMap>.from(contents as List));

      tracks.addAll(
        await getContinuations(
          results,
          'playlistPanelContinuation',
          limit - tracks.length,
          requestFunc,
          parseFunc,
          additionalParams: isPlaylist ? '' : 'Radio',
        ),
      );
    }

    return {
      'tracks': tracks,
      'playlistId': playlist,
      'lyrics': lyricsBrowseId,
      'related': relatedBrowseId,
    };
  }
}
