/// @docImport 'package:ytmusicapi_dart/mixins/playlists.dart';
library;

import 'package:ytmusicapi_dart/continuations.dart';
import 'package:ytmusicapi_dart/mixins/protocol.dart';
import 'package:ytmusicapi_dart/navigation.dart';
import 'package:ytmusicapi_dart/parsers/browsing.dart';
import 'package:ytmusicapi_dart/parsers/playlists.dart';
import 'package:ytmusicapi_dart/parsers/podcasts.dart';
import 'package:ytmusicapi_dart/type_alias.dart';

/// Mixin for podcast functionalities.
mixin PodcastsMixin on MixinProtocol {
  /// Get information about a podcast channel (episodes, podcasts).
  ///
  /// For episodes, a maximum of 10 episodes are returned, the full list of
  /// episodes can be retrieved via [getChannelEpisodes].
  ///
  /// - [channelId] channel id.
  ///
  /// Returns Map containing channel info.
  ///
  /// Example:
  /// ```json
  ///     {
  ///         "title": 'Stanford Graduate School of Business',
  ///         "thumbnails": [...]
  ///         "episodes":
  ///         {
  ///             "browseId": "UCGwuxdEeCf0TIA2RbPOj-8g",
  ///             "results":
  ///             [
  ///                 {
  ///                     "index": 0,
  ///                     "title": "The Brain Gain: The Impact of Immigration on American Innovation with Rebecca Diamond",
  ///                     "description": "Immigrants' contributions to America ...",
  ///                     "duration": "24 min",
  ///                     "videoId": "TS3Ovvk3VAA",
  ///                     "browseId": "MPEDTS3Ovvk3VAA",
  ///                     "videoType": "MUSIC_VIDEO_TYPE_PODCAST_EPISODE",
  ///                     "date": "Mar 6, 2024",
  ///                     "thumbnails": [...]
  ///                 },
  ///             ],
  ///             "params": "6gPiAUdxWUJXcFlCQ3BN..."
  ///         },
  ///         "podcasts":
  ///         {
  ///             "browseId": null,
  ///             "results":
  ///             [
  ///                 {
  ///                     "title": "Stanford GSB Podcasts",
  ///                     "channel":
  ///                     {
  ///                         "id": "UCGwuxdEeCf0TIA2RbPOj-8g",
  ///                         "name": "Stanford Graduate School of Business"
  ///                     },
  ///                     "browseId": "MPSPPLxq_lXOUlvQDUNyoBYLkN8aVt5yAwEtG9",
  ///                     "podcastId": "PLxq_lXOUlvQDUNyoBYLkN8aVt5yAwEtG9",
  ///                     "thumbnails": [...]
  ///                 }
  ///            ]
  ///         }
  ///     }
  Future<JsonMap> getChannel(String channelId) async {
    final body = {'browseId': channelId};
    const endpoint = 'browse';
    final response = await sendRequest(endpoint, body);

    final channel = <String, dynamic>{
      'title': nav(response, [...HEADER_MUSIC_VISUAL, ...TITLE_TEXT]),
      'thumbnails': nav(response, [...HEADER_MUSIC_VISUAL, ...THUMBNAILS]),
    };

    final results = nav(response, [...SINGLE_COLUMN_TAB, ...SECTION_LIST]);
    channel.addAll(parser.parseChannelContents(results as List<JsonMap>));

    return channel;
  }

  /// Get all channel episodes. This endpoint is currently unlimited.
  ///
  /// - [channelId] `channelId` of the user.
  /// - [params] Params obtained by [getChannel].
  ///
  /// Returns List of channel episodes in the format of [getChannel] `episodes` key.
  Future<List> getChannelEpisodes(String channelId, String params) async {
    final body = {'browseId': channelId, 'params': params};
    const endpoint = 'browse';
    final response = await sendRequest(endpoint, body);

    final results = nav(response, [
      ...SINGLE_COLUMN_TAB,
      ...SECTION_LIST_ITEM,
      ...GRID_ITEMS,
    ]);
    return parseContentList(results as List<JsonMap>, parseEpisode, key: MMRIR);
  }

  /// Returns podcast metadata and episodes.
  ///
  /// - [playlistId] Playlist id.
  /// - [limit] How many songs to return. `null` retrieves them all. (Default: `100`).
  ///
  /// NOTE:
  /// - To add a podcast to your library, you need to call [ratePlaylist] on it. // TODO ratePlaylist is currently missing
  ///
  /// Returns Map with podcast information.
  ///
  /// Example:
  /// ```json
  /// {
  ///   "author": {
  ///     "name": "Stanford Graduate School of Business",
  ///     "id": "UCGwuxdEeCf0TIA2RbPOj-8g"
  ///   },
  ///   "title": "Think Fast, Talk Smart: The Podcast",
  ///   "description": "Join Matt Abrahams, a lecturer of...",
  ///   "saved": false,
  ///   "episodes": [
  ///     {
  ///       "index": 0,
  ///       "title": "132. Lean Into Failure: How to Make Mistakes That Work | Think Fast, Talk Smart: Communication...",
  ///       "description": "Effective and productive teams and...",
  ///       "duration": "25 min",
  ///       "videoId": "xAEGaW2my7E",
  ///       "browseId": "MPEDxAEGaW2my7E",
  ///       "videoType": "MUSIC_VIDEO_TYPE_PODCAST_EPISODE",
  ///       "date": "Mar 5, 2024",
  ///       "thumbnails": [...]
  ///     }
  ///   ]
  /// }
  ///
  ///```
  Future<JsonMap> getPodcast(String playlistId, {int? limit = 100}) async {
    final browseId =
        playlistId.startsWith('MPSP') ? playlistId : 'MPSP$playlistId';
    final body = {'browseId': browseId};
    const endpoint = 'browse';
    final response = await sendRequest(endpoint, body);

    final twoColumns = nav(response, TWO_COLUMN_RENDERER);
    final header = nav(twoColumns, [
      ...TAB_CONTENT,
      ...SECTION_LIST_ITEM,
      ...RESPONSIVE_HEADER,
    ]);
    final podcast = parsePodcastHeader(header as JsonMap);

    final results =
        nav(twoColumns, [
              'secondaryContents',
              ...SECTION_LIST_ITEM,
              ...MUSIC_SHELF,
            ])
            as JsonMap;
    Future<List> parseFunc(contents) =>
        parseContentList(contents as List<JsonMap>, parseEpisode, key: MMRIR);
    final episodes = await parseFunc(results['contents']);

    if (results.containsKey('continuations')) {
      Future<JsonMap> requestFunc(String additionalParams) =>
          sendRequest(endpoint, body, additionalParams: additionalParams);
      final remainingLimit = limit == null ? null : (limit - episodes.length);
      episodes.addAll(
        await getContinuations(
          results,
          'musicShelfContinuation',
          remainingLimit,
          requestFunc,
          parseFunc,
        ),
      );
    }

    podcast['episodes'] = episodes;
    return podcast;
  }

  /// Retrieve episode data for a single episode.
  ///
  /// - [videoId] `browseId` (`MPED..`) or `videoId` for a single episode.
  ///
  /// NOTE:
  /// - To save an episode, you need to call [PlaylistsMixin.addPlaylistItems] to add
  ///   it to the `SE` (saved episodes) playlist.
  ///
  /// Returns Map containing information about the episode.
  ///
  /// The description elements are based on a custom class, not shown in the example below.
  ///
  /// Example:
  /// ```json
  /// {
  ///   "author": {
  ///     "name": "Stanford GSB Podcasts",
  ///     "id": "MPSPPLxq_lXOUlvQDUNyoBYLkN8aVt5yAwEtG9"
  ///   },
  ///   "title": "124. Making Meetings Me...",
  ///   "date": "Jan 16, 2024",
  ///   "duration": "25 min",
  ///   "saved": false,
  ///   "playlistId": "MPSPPLxq_lXOUlvQDUNyoBYLkN8aVt5yAwEtG9",
  ///   "description": [
  ///     {
  ///       "text": "Delve into why people hate meetings, ... Karin Reed ("
  ///     },
  ///     {
  ///       "text": "https://speakerdynamics.com/team/",
  ///       "url": "https://speakerdynamics.com/team/"
  ///     },
  ///     {
  ///       "text": ")Chapters:("
  ///     },
  ///     {
  ///       "text": "00:00",
  ///       "seconds": 0
  ///     },
  ///     {
  ///       "text": ") Introduction Host Matt Abrahams...("
  ///     },
  ///     {
  ///       "text": "01:30",
  ///       "seconds": 90
  ///     }
  ///   ]
  /// }
  /// ```
  Future<JsonMap> getEpisode(String videoId) async {
    final browseId = videoId.startsWith('MPED') ? videoId : 'MPED$videoId';
    final body = {'browseId': browseId};
    const endpoint = 'browse';
    final response = await sendRequest(endpoint, body);

    final twoColumns = nav(response, TWO_COLUMN_RENDERER);
    final header = nav(twoColumns, [
      ...TAB_CONTENT,
      ...SECTION_LIST_ITEM,
      ...RESPONSIVE_HEADER,
    ]);
    final episode = parseEpisodeHeader(header as JsonMap);

    episode['description'] = null;
    final descriptionRuns = nav(twoColumns, [
      'secondaryContents',
      ...SECTION_LIST_ITEM,
      ...DESCRIPTION_SHELF,
      'description',
      'runs',
    ], nullIfAbsent: true);
    if (descriptionRuns != null) {
      episode['description'] = Description.fromRuns(
        descriptionRuns as List<JsonMap>,
      );
    }

    return episode;
  }

  /// Get all episodes in an episodes playlist.
  ///
  /// Currently the only known playlist is the "New Episodes" auto-generated playlist.
  ///
  /// [playlistId] Playlist ID, defaults to `RDPN`, the id of the "New Episodes" playlist.
  ///
  /// Returns Map in the format of [getPodcast].
  Future<JsonMap> getEpisodesPlaylist({String playlistId = 'RDPN'}) async {
    final browseId = playlistId.startsWith('VL') ? playlistId : 'VL$playlistId';
    final body = {'browseId': browseId};
    const endpoint = 'browse';
    final response = await sendRequest(endpoint, body);

    final playlist = parsePlaylistHeader(response);

    final results =
        nav(response, [
              ...TWO_COLUMN_RENDERER,
              'secondaryContents',
              ...SECTION_LIST_ITEM,
              ...MUSIC_SHELF,
            ])
            as JsonMap;
    Future<List> parseFunc(contents) =>
        parseContentList(contents as List<JsonMap>, parseEpisode, key: MMRIR);
    playlist['episodes'] = parseFunc(results['contents']);

    return playlist;
  }
}
