/// @docImport 'package:ytmusicapi_dart/mixins/playlists.dart';
/// @docImport 'package:ytmusicapi_dart/mixins/search.dart';
/// @docImport 'package:ytmusicapi_dart/mixins/watch.dart';
library;

import 'dart:async';

import 'package:ytmusicapi_dart/constants.dart';
import 'package:ytmusicapi_dart/continuations.dart';
import 'package:ytmusicapi_dart/enums.dart';
import 'package:ytmusicapi_dart/helpers.dart';
import 'package:ytmusicapi_dart/mixins/protocol.dart';
import 'package:ytmusicapi_dart/mixins/utils.dart';
import 'package:ytmusicapi_dart/models/lyrics.dart';
import 'package:ytmusicapi_dart/models/objects/album.dart';
import 'package:ytmusicapi_dart/models/objects/artist.dart';
import 'package:ytmusicapi_dart/models/objects/base.dart';
import 'package:ytmusicapi_dart/models/objects/playlist.dart';
import 'package:ytmusicapi_dart/models/objects/video.dart';
import 'package:ytmusicapi_dart/navigation.dart';
import 'package:ytmusicapi_dart/parsers/albums.dart';
import 'package:ytmusicapi_dart/parsers/browsing.dart';
import 'package:ytmusicapi_dart/parsers/library.dart';
import 'package:ytmusicapi_dart/parsers/playlists.dart';
import 'package:ytmusicapi_dart/type_alias.dart';
import 'package:ytmusicapi_dart/utils.dart';

/// Mixin for browsing functionalities.
mixin BrowsingMixin on MixinProtocol {
  /// Get the home page.
  ///
  /// The home page is structured as titled rows, returning 3 rows of music suggestions at a time.
  /// Content varies and may contain artist, album, song or playlist suggestions, sometimes mixed within the same row.
  ///
  /// - [limit] Number of rows on the home page to return. (Default: `3`).
  Future<List<YtNamedRow>> getHome({int limit = 3}) async {
    const endpoint = 'browse';
    final body = <String, dynamic>{'browseId': 'FEmusic_home'};
    final response = await sendRequest(endpoint, body);

    final results = nav(response, SINGLE_COLUMN_TAB + SECTION_LIST);
    final home = parseMixedContent(List<JsonMap>.from(results as List));

    final sectionList =
        nav(response, [...SINGLE_COLUMN_TAB, 'sectionListRenderer']) as JsonMap;
    if (sectionList.containsKey('continuations')) {
      Future<JsonMap> requestFunc(String additionalParams) =>
          sendRequest(endpoint, body, additionalParams: additionalParams);

      home.addAll(
        await getContinuations(
          sectionList,
          'sectionListContinuation',
          limit - home.length,
          requestFunc,
          parseMixedContent,
        ),
      );
    }

    return home;
  }

  /// Get information about an artist and their top releases (songs,
  /// albums, singles, videos, and related artists).
  ///
  /// The top lists contain pointers for getting the full list of releases.
  ///
  /// Each of these content keys in the response contains
  /// `results` and possibly `browseId` and `params`:
  ///
  /// - For songs/videos, pass the `browseId` to [PlaylistsMixin.getPlaylist].
  /// - For albums/singles/shows, pass `browseId` and `params` to [getArtistAlbums].
  ///
  /// Arguments:
  /// - [channelId] channel id of the artist.
  ///
  /// WARNING:
  /// - The returned channelId is not the same as the one passed to the function.
  ///   It should be used only with [subscribeArtist]. // TODO subscribeArtist is currently missing
  ///
  ///  The difference between description and descriptionRuns is that description is just the raw text of the description and does not have any knowledge of the hyperlinks in the description.
  Future<YtBrowsedArtist> getArtist(String channelId) async {
    final String cleanChannelId;
    if (channelId.startsWith('MPLA')) {
      cleanChannelId = channelId.substring(4);
    } else {
      cleanChannelId = channelId;
    }
    const endpoint = 'browse';
    final body = JsonMap.from({'browseId': cleanChannelId});
    final response = await sendRequest(endpoint, body);

    final results = List<JsonMap>.from(
      nav(response, SINGLE_COLUMN_TAB + SECTION_LIST) as List,
    );
    final header =
        JsonMap.from(
              response['header']! as JsonMap,
            )['musicImmersiveHeaderRenderer']
            as JsonMap? ??
        JsonMap.from(
              response['header']! as JsonMap,
            )['musicVisualHeaderRenderer']
            as JsonMap;

    final subscriptionButton =
        (header['subscriptionButton']! as JsonMap)['subscribeButtonRenderer']
            as JsonMap;

    final artist = YtBrowsedArtist(
      name: nav(header, TITLE_TEXT) as String,
      id: subscriptionButton['channelId'] as String?,
      descriptionRaw: null,
      descriptionRuns: [],
      views: null,
      shuffleId: null,
      radioId: null,
      subscribers: null,
      monthlyListeners: null,
      thumbnails: null,
      songsBrowseId: null,
      songsResults: [],
      albumsBrowseId: null,
      albumsParams: null,
      albumsResults: [],
      singlesBrowseId: null,
      singlesParams: null,
      singlesResults: [],
      showsBrowseId: null,
      videosBrowseId: null,
      videosResults: [],
      playlistsBrowseId: null,
      episodesBrowseId: null,
      podcastsBrowseId: null,
      relatedBrowseId: null,
      relatedResults: [],
    );

    final descriptionShelf = findObjectByKey(
      results,
      DESCRIPTION_SHELF.first as String,
      isKey: true,
    );

    if (descriptionShelf != null) {
      final parsedDescriptionRuns = parseDescriptionRuns(
        nav(descriptionShelf, DESCRIPTION_RUN_LIST),
      );
      final description = parsedDescriptionRuns.$1;
      final descriptionRuns = parsedDescriptionRuns.$2;
      artist.descriptionRaw = description;
      artist.descriptionRuns = descriptionRuns;
      artist.views =
          descriptionShelf.containsKey('subheader')
              ? (((descriptionShelf['subheader']! as JsonMap)['runs']! as List)
                          .first
                      as JsonMap)['text']
                  as String?
              : null;
    }

    artist.shuffleId =
        nav(header, [
              'playButton',
              'buttonRenderer',
              ...NAVIGATION_PLAYLIST_ID,
            ], nullIfAbsent: true)
            as String?;
    artist.radioId =
        nav(header, [
              'startRadioButton',
              'buttonRenderer',
              ...NAVIGATION_PLAYLIST_ID,
            ], nullIfAbsent: true)
            as String?;
    artist.subscribers =
        nav(subscriptionButton, [
              'subscriberCountText',
              'runs',
              0,
              'text',
            ], nullIfAbsent: true)
            as String?;
    artist.monthlyListeners =
        nav(header, [
              'monthlyListenerCount',
              'runs',
              0,
              'text',
            ], nullIfAbsent: true)
            as String?;
    artist.monthlyListeners = artist.monthlyListeners?.replaceAll(
      ' monthly audience',
      '',
    );
    final thumbnailsRaw = nav(header, THUMBNAILS, nullIfAbsent: true);
    artist.thumbnails =
        thumbnailsRaw != null
            ? YtThumbnails.fromJson(List<JsonMap>.from(thumbnailsRaw as List))
            : null;

    if (results.isNotEmpty && results.first.containsKey('musicShelfRenderer')) {
      // API sometimes does not return songs
      final musicShelf = nav(results.first, MUSIC_SHELF) as JsonMap;
      if ((nav(musicShelf, TITLE) as JsonMap).containsKey(
        'navigationEndpoint',
      )) {
        artist.songsBrowseId =
            nav(musicShelf, TITLE + NAVIGATION_BROWSE_ID) as String;
      }
      artist.songsResults = parsePlaylistItems(
        List<JsonMap>.from(musicShelf['contents'] as List),
      );
    }
    parser.parseChannelContents(results, artist);
    return artist;
  }

  /// Get the full list of an artist's albums, singles or shows.
  ///
  /// - [channelId] `browseId` of the artist as returned by [getArtist].
  /// - [params] Params obtained by [getArtist].
  /// - [limit] Number of albums to return. `null` retrieves them all. (Default: `100`).
  /// - [order] Order of albums to return. (Default: default order).
  // TODO getLibraryAlbums is currently missing
  Future<List<YtAlbum>> getArtistAlbums(
    String channelId,
    String params, {
    int? limit = 100,
    ArtistOrderType? order,
  }) async {
    const endpoint = 'browse';
    final body = <String, dynamic>{'browseId': channelId, 'params': params};
    var response = await sendRequest(endpoint, body);

    Future<JsonMap> requestFunc(String additionalParams) =>
        sendRequest(endpoint, body, additionalParams: additionalParams);

    List<YtAlbum> parseFunc(List<JsonMap> contents) => parseAlbums(contents);

    JsonMap results;
    if (order != null) {
      // pick the correct continuation from response depending on the order chosen
      final sortOptions =
          nav(response, [
                ...SINGLE_COLUMN_TAB,
                ...SECTION,
                ...HEADER_SIDE,
                'endItems',
                0,
                'musicSortFilterButtonRenderer',
                'menu',
                'musicMultiSelectMenuRenderer',
                'options',
              ])
              as List;
      final continuation =
          sortOptions
                  .where(
                    (option) =>
                        (nav(option, [...MULTI_SELECT, ...TITLE_TEXT])
                                as String)
                            .toLowerCase() ==
                        order.value.toLowerCase(),
                  )
                  .map(
                    (option) => nav(option, [
                      ...MULTI_SELECT,
                      'selectedCommand',
                      'commandExecutorCommand',
                      'commands',
                      -1,
                      'browseSectionListReloadEndpoint',
                    ]),
                  )
                  .cast<dynamic>()
                  .firstWhere((result) => result != null, orElse: () => null)
              as JsonMap?;
      // if a valid order was provided, request continuation and replace original response
      if (continuation != null) {
        final additionalParams = getReloadableContinuationParams({
          'continuations': [continuation['continuation']],
        });
        response = await requestFunc(additionalParams);

        results =
            nav(response, [...SECTION_LIST_CONTINUATION, ...CONTENT])
                as JsonMap;
      } else {
        throw Exception('Invalid order parameter $order');
      }
    } else {
      // just use the results from the first request
      results =
          nav(response, [...SINGLE_COLUMN_TAB, ...SECTION_LIST_ITEM])
              as JsonMap;
    }

    final contents =
        nav(results, GRID_ITEMS, nullIfAbsent: true) ??
        nav(results, CAROUSEL_CONTENTS);
    final albums = parseAlbums(List<JsonMap>.from(contents as List));

    final remainingResults = nav(results, GRID, nullIfAbsent: true) as JsonMap;
    if (remainingResults.containsKey('continuations')) {
      final remainingLimit = limit == null ? null : limit - albums.length;
      albums.addAll(
        await getContinuations(
          remainingResults,
          'gridContinuation',
          remainingLimit,
          requestFunc,
          parseFunc,
        ),
      );
    }

    return albums;
  }

  /// Retrieve a user's page. A user may own videos or playlists.
  ///
  /// Use [getUserPlaylists] to retrieve all playlists:
  /// ```dart
  /// final result = getUser(channelId);
  /// getUserPlaylists(channelId, result['playlists']['params']);
  /// ```
  ///
  /// Similarly, use [getUserVideos] to retrieve all videos:
  /// ```dart
  /// getUserVideos(channelId, result['videos']['params']);
  /// ```
  ///
  /// - [channelId] `channelId` of the user.
  Future<YtBrowsedArtist> getUser(String channelId) async {
    const endpoint = 'browse';
    final body = <String, dynamic>{'browseId': channelId};
    final response = await sendRequest(endpoint, body);

    final user = YtBrowsedArtist(
      name: nav(response, [...HEADER_MUSIC_VISUAL, ...TITLE_TEXT]) as String,
      id: null,
      descriptionRaw: null,
      descriptionRuns: [],
      views: null,
      shuffleId: null,
      radioId: null,
      subscribers: null,
      monthlyListeners: null,
      thumbnails: null,
      songsBrowseId: null,
      songsResults: [],
      albumsBrowseId: null,
      albumsParams: null,
      albumsResults: [],
      singlesBrowseId: null,
      singlesParams: null,
      singlesResults: [],
      showsBrowseId: null,
      videosBrowseId: null,
      videosResults: [],
      playlistsBrowseId: null,
      episodesBrowseId: null,
      podcastsBrowseId: null,
      relatedBrowseId: null,
      relatedResults: [],
    );
    final results = nav(response, [...SINGLE_COLUMN_TAB, ...SECTION_LIST]);
    parser.parseChannelContents(List<JsonMap>.from(results as List), user);

    return user;
  }

  /// Retrieve a list of playlists for a given user.
  ///
  /// Call this function again with the returned `params` to get the full list.
  ///
  /// - [channelId] `channelId` of the user.
  /// - [params] `params` obtained by [getUser].
  // TODO getLibraryPlaylists is currently missing
  Future<List<YtPlaylist>> getUserPlaylists(
    String channelId,
    String params,
  ) async {
    const endpoint = 'browse';
    final body = {'browseId': channelId, 'params': params};
    final response = await sendRequest(endpoint, body);

    final results = nav(response, [
      ...SINGLE_COLUMN_TAB,
      ...SECTION_LIST_ITEM,
      ...GRID_ITEMS,
    ], nullIfAbsent: true);
    if (results == null) return [];

    return await parseContentList(
      List<JsonMap>.from(results as List),
      parsePlaylist,
    );
  }

  /// Retrieve a list of videos for a given user.
  ///
  /// Call this function again with the returned `params` to get the full list.
  ///
  /// - [channelId] `channelId` of the user.
  /// - [params] `params` obtained by [getUser].
  Future<List<YtVideo>> getUserVideos(String channelId, String params) async {
    const endpoint = 'browse';
    final body = {'browseId': channelId, 'params': params};
    final response = await sendRequest(endpoint, body);

    final results = nav(response, [
      ...SINGLE_COLUMN_TAB,
      ...SECTION_LIST_ITEM,
      ...GRID_ITEMS,
    ], nullIfAbsent: true);
    if (results == null) return [];

    return await parseContentList(
      List<JsonMap>.from(results as List),
      parseVideo,
    );
  }

  /// Get an album's `browseId` based on its [audioPlaylistId].
  ///
  /// - [audioPlaylistId] id of the audio playlist (starting with `OLAK5uy_`).
  ///
  /// Returns `browseId` (starting with `MPREb_`).
  Future<String?> getAlbumBrowseId(String audioPlaylistId) async {
    final params = {'list': audioPlaylistId};
    final response = await sendGetRequest(
      '$YTM_DOMAIN/playlist',
      params: params,
    );
    final decoded = decodeEscapes(response.data as String, replaceQuot: true);

    final match = RegExp('"MPRE.+?"').firstMatch(decoded);
    return match?.group(0)?.replaceAll('"', '');
  }

  /// Get information and tracks of an album.
  ///
  /// - [browseId] `browseId` of the album, for example returned by [SearchMixin.search].
  ///
  /// For the distinction between description and descriptionRuns please refer to getArtist.
  Future<YtAlbum> getAlbum(String browseId, {JsonMap? requestData}) async {
    if (browseId.isEmpty || !browseId.startsWith('MPRE')) {
      throw Exception('Invalid album browseId provided, must start with MPRE.');
    }
    final body = <String, dynamic>{'browseId': browseId};
    const endpoint = 'browse';
    final response = requestData ?? await sendRequest(endpoint, body);

    final album = parseAlbumHeader2024(response);

    final results = JsonMap.from(
      nav(response, [
            ...TWO_COLUMN_RENDERER,
            'secondaryContents',
            ...SECTION_LIST_ITEM,
            ...MUSIC_SHELF,
          ])
          as Map,
    );
    album.tracks = parsePlaylistItems(
      List<JsonMap>.from(results['contents'] as List),
      isAlbum: true,
    );

    final secondaryCarousels =
        nav(response, [
              ...TWO_COLUMN_RENDERER,
              'secondaryContents',
              ...SECTION_LIST,
            ], nullIfAbsent: true)
            as List? ??
        [];
    for (final section in secondaryCarousels.skip(1)) {
      final carousel = nav(section, CAROUSEL) as JsonMap;
      final key =
          {
            'COLLECTION_STYLE_ITEM_SIZE_SMALL': 'related_recommendations',
            'COLLECTION_STYLE_ITEM_SIZE_MEDIUM': 'other_versions',
          }[carousel['itemSize']]!;
      if (key == 'related_recommendations') {
        album.relatedRecommendations = await parseContentList(
          List<JsonMap>.from(carousel['contents'] as List),
          parseAlbum,
        );
      } else if (key == 'other_versions') {
        album.otherVersions = await parseContentList(
          List<JsonMap>.from(carousel['contents'] as List),
          parseAlbum,
        );
      }
    }

    album.duration = Duration(seconds: sumTotalDurationAlbum(album));
    for (var i = 0; i < album.tracks.length; i++) {
      album.tracks[i].album = YtBaseObject(
        id: album.id,
        name: album.name,
        type: YtObjectType.OBJECT,
      );
      album.tracks[i].artists =
          album.tracks[i].artists.isNotEmpty
              ? album.tracks[i].artists
              : album.artists;
    }
    return album;
  }

  /// Get credits for a song. Top-level entries are limited to ``performed_by``,
  /// ``written_by``, ``produced_by`` and ``music_metadata_provided_by``.
  /// If YouTube returns additional data, it will be returned in ``other_sections``.
  ///
  /// - [browseId] `browseId` for the credits of a song, for example returned as ``creditsBrowseId`` in the tracks of [getAlbum]
  /// Returns a Map with credit sections.
  ///
  /// Example::
  ///
  /// {
  ///   "performed_by": {
  ///     "localized_title": "Performed by",
  ///     "data": [
  ///       "Eminem",
  ///       "Beyoncé"
  ///     ]
  ///   },
  ///   "written_by": {
  ///     "localized_title": "Written by",
  ///     "data": [
  ///       "Marshall Mathers",
  ///       "Beyoncé Knowles",
  ///       "Holly Hafermann"
  ///     ]
  ///   },
  ///   "produced_by": {
  ///     "localized_title": "Produced by",
  ///     "data": [
  ///       "Rick Rubin"
  ///     ]
  ///   },
  ///   "music_metadata_provided_by": {
  ///     "localized_title": "Music metadata provided by"
  ///     "data": [
  ///       "Eminem Catalog PS"
  ///     ]
  ///   },
  ///   "other_sections": [
  ///     {
  ///       "localized_title": "Piano",
  ///       "data": [
  ///         "Skylar Grey"
  ///       ]
  ///     }
  ///   ]
  /// }
  Future<JsonMap> getSongCredits(String browseId) async {
    if (browseId.isEmpty || !browseId.startsWith('MPTC')) {
      throw Exception(
        'Invalid song credits browseId provided, must start with MPTC.',
      );
    }
    final body = {'browseId': browseId};
    const endpoint = 'browse';
    final response = await sendRequest(endpoint, body);

    final credits = <String, dynamic>{'other_sections': []};
    final sections = List<JsonMap>.from(
      nav(response, CREDITS_SECTIONS) as List,
    );
    final localizedSectionMap = parser.getSongCreditSectionMap();
    for (final section in sections) {
      final sectionContent = section['dismissableDialogContentSectionRenderer'];
      final sectionLocalName = nav(sectionContent, TITLE_TEXT);
      final sectionSnakeCaseName =
          localizedSectionMap[sectionLocalName] as String?;
      final subtitleRuns = List<JsonMap>.from(
        nav(sectionContent, SUBTITLE_RUNS) as List? ?? [],
      );

      final sectionData = {
        'localized_title': sectionLocalName,
        'data': [
          for (var i = 0; i < subtitleRuns.length; i += 2)
            subtitleRuns[i]['text'],
        ],
      };

      if (sectionSnakeCaseName != null) {
        credits[sectionSnakeCaseName] = sectionData;
      } else {
        (credits['other_sections'] as List).add(sectionData);
      }
    }
    return credits;
  }

  /// Returns metadata and streaming information about a song or video.
  ///
  /// - [videoId] Video id.
  /// - [signatureTimestamp] Provide the current YouTube `signatureTimestamp`.
  ///     If not provided, a default value will be used, which might result in invalid streaming URLs.
  ///
  /// Returns Map with song metadata.
  ///
  /// Example:
  /// ```json
  /// {
  ///   "playabilityStatus": {
  ///     "status": "OK",
  ///     "playableInEmbed": true,
  ///     "audioOnlyPlayability": {
  ///       "audioOnlyPlayabilityRenderer": {
  ///         "trackingParams": "CAEQx2kiEwiuv9X5i5H1AhWBvlUKHRoZAHk=",
  ///         "audioOnlyAvailability": "FEATURE_AVAILABILITY_ALLOWED"
  ///       }
  ///     },
  ///     "miniplayer": {
  ///       "miniplayerRenderer": {
  ///         "playbackMode": "PLAYBACK_MODE_ALLOW"
  ///       }
  ///     },
  ///     "contextParams": "Q0FBU0FnZ0M="
  ///   },
  ///   "streamingData": {
  ///     "expiresInSeconds": "21540",
  ///     "adaptiveFormats": [
  ///       {
  ///         "itag": 140,
  ///         "url": "https://rr1---sn-h0jelnez.c.youtube.com/videoplayback?expire=1641080272...",
  ///         "mimeType": "audio/mp4; codecs=\"mp4a.40.2\"",
  ///         "bitrate": 131007,
  ///         "initRange": {
  ///           "start": "0",
  ///           "end": "667"
  ///         },
  ///         "indexRange": {
  ///           "start": "668",
  ///           "end": "999"
  ///         },
  ///         "lastModified": "1620321966927796",
  ///         "contentLength": "3967382",
  ///         "quality": "tiny",
  ///         "projectionType": "RECTANGULAR",
  ///         "averageBitrate": 129547,
  ///         "highReplication": true,
  ///         "audioQuality": "AUDIO_QUALITY_MEDIUM",
  ///         "approxDurationMs": "245000",
  ///         "audioSampleRate": "44100",
  ///         "audioChannels": 2,
  ///         "loudnessDb": -1.3000002
  ///       }
  ///     ]
  ///   },
  ///   "playbackTracking": {
  ///     "videostatsPlaybackUrl": {
  ///       "baseUrl": "https://s.youtube.com/api/stats/playback?cl=491307275&docid=AjXQiKP5kMs&ei=Nl2HY-6MH5WE8gPjnYnoDg&fexp=1714242%2C9405963%2C23804281%2C23858057%2C23880830%2C23880833%2C23882685%2C23918597%2C23934970%2C23946420%2C23966208%2C23983296%2C23998056%2C24001373%2C24002022%2C24002025%2C24004644%2C24007246%2C24034168%2C24036947%2C24077241%2C24080738%2C24120820%2C24135310%2C24135692%2C24140247%2C24161116%2C24162919%2C24164186%2C24169501%2C24175560%2C24181174%2C24187043%2C24187377%2C24187854%2C24191629%2C24197450%2C24199724%2C24200839%2C24209349%2C24211178%2C24217535%2C24219713%2C24224266%2C24241378%2C24248091%2C24248956%2C24255543%2C24255545%2C24262346%2C24263796%2C24265426%2C24267564%2C24268142%2C24279196%2C24280220%2C24283426%2C24283493%2C24287327%2C24288045%2C24290971%2C24292955%2C24293803%2C24299747%2C24390674%2C24391018%2C24391537%2C24391709%2C24392268%2C24392363%2C24392401%2C24401557%2C24402891%2C24403794%2C24406605%2C24407200%2C24407665%2C24407914%2C24408220%2C24411766%2C24413105%2C24413820%2C24414162%2C24415866%2C24416354%2C24420756%2C24421162%2C24425861%2C24428962%2C24590921%2C39322504%2C39322574%2C39322694%2C39322707&ns=yt&plid=AAXusD4TIOMjS5N4&el=detailpage&len=246&of=Jx1iRksbq-rB9N1KSijZLQ&osid=MWU2NzBjYTI%3AAOeUNAagU8UyWDUJIki5raGHy29-60-yTA&uga=29&vm=CAEQABgEOjJBUEV3RWxUNmYzMXNMMC1MYVpCVnRZTmZWMWw1OWVZX2ZOcUtCSkphQ245VFZwOXdTQWJbQVBta0tETEpWNXI1SlNIWEJERXdHeFhXZVllNXBUemt5UHR4WWZEVzFDblFUSmdla3BKX2R0dXk3bzFORWNBZmU5YmpYZnlzb3doUE5UU0FoVGRWa0xIaXJqSWgB",
  ///       "headers": [
  ///         {
  ///           "headerType": "USER_AUTH"
  ///         },
  ///         {
  ///           "headerType": "VISITOR_ID"
  ///         },
  ///         {
  ///           "headerType": "PLUS_PAGE_ID"
  ///         }
  ///       ]
  ///     },
  ///     "videostatsDelayplayUrl": { (as above) },
  ///     "videostatsWatchtimeUrl": { (as above) },
  ///     "ptrackingUrl": { (as above) },
  ///     "qoeUrl": { (as above) },
  ///     "atrUrl": { (as above) },
  ///     "videostatsScheduledFlushWalltimeSeconds": [10, 20, 30],
  ///     "videostatsDefaultFlushIntervalSeconds": 40
  ///   },
  ///   "videoDetails": {
  ///     "videoId": "AjXQiKP5kMs",
  ///     "title": "Sparks",
  ///     "lengthSeconds": "245",
  ///     "channelId": "UCvCk2zFqkCYzpnSgWfx0qOg",
  ///     "isOwnerViewing": false,
  ///     "isCrawlable": false,
  ///     "thumbnail": {
  ///       "thumbnails": []
  ///     },
  ///     "allowRatings": true,
  ///     "viewCount": "12",
  ///     "author": "Thomas Bergersen",
  ///     "isPrivate": true,
  ///     "isUnpluggedCorpus": false,
  ///     "musicVideoType": "MUSIC_VIDEO_TYPE_PRIVATELY_OWNED_TRACK",
  ///     "isLiveContent": false
  ///   },
  ///   "microformat": {
  ///     "microformatDataRenderer": {
  ///       "urlCanonical": "https://music.youtube.com/watch?v=AjXQiKP5kMs",
  ///       "title": "Sparks - YouTube Music",
  ///       "description": "Uploaded to YouTube via YouTube Music Sparks",
  ///       "thumbnail": {
  ///         "thumbnails": [
  ///           {
  ///             "url": "https://i.ytimg.com/vi/AjXQiKP5kMs/hqdefault.jpg",
  ///             "width": 480,
  ///             "height": 360
  ///           }
  ///         ]
  ///       },
  ///       "siteName": "YouTube Music",
  ///       "appName": "YouTube Music",
  ///       "androidPackage": "com.google.android.apps.youtube.music",
  ///       "iosAppStoreId": "1017492454",
  ///       "iosAppArguments": "https://music.youtube.com/watch?v=AjXQiKP5kMs",
  ///       "ogType": "video.other",
  ///       "urlApplinksIos": "vnd.youtube.music://music.youtube.com/watch?v=AjXQiKP5kMs&feature=applinks",
  ///       "urlApplinksAndroid": "vnd.youtube.music://music.youtube.com/watch?v=AjXQiKP5kMs&feature=applinks",
  ///       "urlTwitterIos": "vnd.youtube.music://music.youtube.com/watch?v=AjXQiKP5kMs&feature=twitter-deep-link",
  ///       "urlTwitterAndroid": "vnd.youtube.music://music.youtube.com/watch?v=AjXQiKP5kMs&feature=twitter-deep-link",
  ///       "twitterCardType": "player",
  ///       "twitterSiteHandle": "@YouTubeMusic",
  ///       "schemaDotOrgType": "http://schema.org/VideoObject",
  ///       "noindex": true,
  ///       "unlisted": true,
  ///       "paid": false,
  ///       "familySafe": true,
  ///       "pageOwnerDetails": {
  ///         "name": "Music Library Uploads",
  ///         "externalChannelId": "UCvCk2zFqkCYzpnSgWfx0qOg",
  ///         "youtubeProfileUrl": "http://www.youtube.com/channel/UCvCk2zFqkCYzpnSgWfx0qOg"
  ///       },
  ///       "videoDetails": {
  ///         "externalVideoId": "AjXQiKP5kMs",
  ///         "durationSeconds": "246",
  ///         "durationIso8601": "PT4M6S"
  ///       },
  ///       "linkAlternates": [
  ///         {
  ///           "hrefUrl": "android-app://com.google.android.youtube/http/youtube.com/watch?v=AjXQiKP5kMs"
  ///         },
  ///         {
  ///           "hrefUrl": "ios-app://544007664/http/youtube.com/watch?v=AjXQiKP5kMs"
  ///         },
  ///         {
  ///           "hrefUrl": "https://www.youtube.com/oembed?format=json&url=https%3A%2F%2Fmusic.youtube.com%2Fwatch%3Fv%3DAjXQiKP5kMs",
  ///           "title": "Sparks",
  ///           "alternateType": "application/json+oembed"
  ///         },
  ///         {
  ///           "hrefUrl": "https://www.youtube.com/oembed?format=xml&url=https%3A%2F%2Fmusic.youtube.com%2Fwatch%3Fv%3DAjXQiKP5kMs",
  ///           "title": "Sparks",
  ///           "alternateType": "text/xml+oembed"
  ///         }
  ///       ],
  ///       "viewCount": "12",
  ///       "publishDate": "1969-12-31",
  ///       "category": "Music",
  ///       "uploadDate": "1969-12-31"
  ///     }
  ///   }
  /// }
  /// ```
  Future<JsonMap> getSong(String videoId, {int? signatureTimestamp}) async {
    const endpoint = 'player';
    signatureTimestamp ??= getDatestamp() - 1;

    final params = <String, dynamic>{
      'playbackContext': {
        'contentPlaybackContext': {'signatureTimestamp': signatureTimestamp},
      },
      'video_id': videoId,
    };
    final response = await sendRequest(endpoint, params);
    response.keys
        .where(
          (k) =>
              ![
                'videoDetails',
                'playabilityStatus',
                'streamingData',
                'microformat',
                'playbackTracking',
              ].contains(k),
        )
        .toList()
        .forEach(response.remove);

    return response;
  }

  /// Gets related content for a song. Equivalent to the content
  /// shown in the "Related" tab of the watch panel.
  ///
  /// - [browseId] The `related` key  in the [WatchMixin.getWatchPlaylist] response.
  Future<List<YtNamedRow>> getSongRelated(String browseId) async {
    if (browseId.isEmpty) throw Exception('Invalid browseId provided.');
    final response = await sendRequest('browse', {'browseId': browseId});
    final sections = nav(response, ['contents', ...SECTION_LIST]);
    return parseMixedContent(List<JsonMap>.from(sections as List));
  }

  /// Returns lyrics of a song or video. When [timestamps] is set, lyrics are returned with timestamps, if available.
  ///
  /// - [browseId] Lyrics `browseId` obtained from [WatchMixin.getWatchPlaylist] (starts with `MPLYt...`).
  /// - [timestamps] Optional. Whether to return bare lyrics or lyrics with timestamps, if available. (Default: `false`).
  ///
  /// Returns Map with song lyrics or `null`, if no lyrics were found.
  ///
  /// The `hasTimestamps`-key determines the format of the data.
  ///
  /// Example when [timestamps] = `false`, or no timestamps are available:
  /// ```dart
  /// {
  ///   'lyrics': "Today is gonna be the day\\nThat they're gonna throw it back to you\\n",
  ///   'source': 'Source: LyricFind',
  ///   'hasTimestamps': false
  /// }
  /// ```
  ///
  /// Example when [timestamps] = `true` and timestamps are available:
  /// ```dart
  // {
  ///   'lyrics': [
  ///     LyricLine('I was a liar', 9200, 10630, 1),
  ///     LyricLine('I gave in to the fire', 10680, 12540, 2),
  ///   ],
  ///   'source': 'Source: LyricFind',
  ///   'hasTimestamps': true,
  /// }
  /// ```
  Future<JsonMap?> getLyrics(String browseId, {bool timestamps = false}) async {
    if (browseId.isEmpty) {
      throw Exception(
        'Invalid browseId provided. This song might not have lyrics.',
      );
    }

    final response =
        timestamps
            ? await asMobile(
              () => sendRequest('browse', {'browseId': browseId}),
            )
            : await sendRequest('browse', {'browseId': browseId});

    if (timestamps) {
      final data =
          nav(response, TIMESTAMPED_LYRICS, nullIfAbsent: true) as JsonMap?;
      if (data == null || !data.containsKey('timedLyricsData')) return null;

      return TimedLyrics(
        (data['timedLyricsData'] as List)
            .map((line) => LyricLine.fromRaw(line as JsonMap))
            .toList(),
        data['sourceMessage'] as String?,
        true,
      ).toJson();
    } else {
      final lyricsStr = nav(response, [
        'contents',
        ...SECTION_LIST_ITEM,
        ...DESCRIPTION_SHELF,
        ...DESCRIPTION,
      ], nullIfAbsent: true);
      if (lyricsStr == null) return null;

      return Lyrics(
        lyricsStr as String,
        nav(response, [
              'contents',
              ...SECTION_LIST_ITEM,
              ...DESCRIPTION_SHELF,
              ...['description'],
              ...RUN_TEXT,
            ], nullIfAbsent: timestamps)
            as String?,
        false,
      ).toJson();
    }
  }

  /// Extract the URL for the `base.js` script from YouTube Music.
  ///
  /// Returns URL to `base.js`.
  ///
  /// TODO this might not work everytime, investigate.
  Future<String> getBaseJsUrl() async {
    final response = await sendGetRequest(YTM_DOMAIN);
    final match = RegExp(
      r'jsUrl"\s*:\s*"([^"]+)"',
    ).firstMatch(decodeEscapes(response.data as String));
    if (match == null) {
      throw Exception('Could not identify the URL for base.js player.');
    }
    return '$YTM_DOMAIN${match.group(1)}';
  }

  /// Fetch the `base.js` script from YouTube Music and parse out the
  /// `signatureTimestamp` for use with [getSong].
  ///
  /// - [url] Optional. Provide the URL of the `base.js` script.
  ///         If this isn't specified, a call will be made to [getBaseJsUrl].
  ///
  /// Returns `signatureTimestamp` String.
  Future<int> getSignatureTimestamp({String? url}) async {
    url ??= await getBaseJsUrl();
    final response = await sendGetRequest(url);
    final match = RegExp(
      r'signatureTimestamp[:=](\d+)',
    ).firstMatch(decodeEscapes(response.data as String));
    if (match == null) {
      throw Exception('Unable to identify the signatureTimestamp.');
    }
    return int.parse(match.group(1)!);
  }

  /// Fetches suggested artists from taste profile (music.youtube.com/tasteprofile). Must be authenticated.
  ///
  /// Tasteprofile allows users to pick artists to update their recommendations.
  /// Only returns a list of suggested artists, not the actual list of selected entries.
  ///
  /// Returns Map with artist and their selection & impression value
  ///
  /// Example:
  /// ```dart
  /// {
  ///   'Drake': {
  ///     'selectionValue': 'tastebuilder_selection=/m/05mt_q',
  ///     'impressionValue': 'tastebuilder_impression=/m/05mt_q',
  ///   },
  /// }
  /// ```
  Future<JsonMap> getTasteProfile() async {
    checkAuth();
    final response = await sendRequest('browse', {
      'browseId': 'FEmusic_tastebuilder',
    });
    final profiles = List<JsonMap>.from(
      nav(response, TASTE_PROFILE_ITEMS) as List,
    );

    final tasteProfiles = <String, dynamic>{};
    for (final itemList in profiles) {
      for (final item
          in (itemList['tastebuilderItemListRenderer']
              as Map<String, List<JsonMap>>)['contents']!) {
        final artist =
            List<JsonMap>.from(
              nav(item['tastebuilderItemRenderer'], TASTE_PROFILE_ARTIST)
                  as List,
            ).first['text'];
        tasteProfiles[artist as String] = {
          'selectionValue':
              (item['tastebuilderItemRenderer']
                  as Map<String, JsonMap>)['selectionFormValue'],
          'impressionValue':
              (item['tastebuilderItemRenderer']
                  as Map<String, JsonMap>)['impressionFormValue'],
        };
      }
    }
    return tasteProfiles;
  }

  /// Favorites artists to see more recommendations from the artist.
  ///
  /// Use [getTasteProfile] to see which artists are available to be recommended.
  ///
  /// - [artists] A List with names of artists, must be contained in the [tasteProfile].
  /// - [tasteProfile] `tasteprofile` result from [getTasteProfile].
  ///                  Pass this if you call [getTasteProfile] anyway to save an extra request.
  Future<void> setTasteProfile(
    List<String> artists, {
    JsonMap? tasteProfile,
  }) async {
    tasteProfile ??= await getTasteProfile();
    final formData = {
      'impressionValues':
          tasteProfile.keys
              .map(
                (k) =>
                    (tasteProfile!
                        as Map<String, JsonMap>)[k]!['impressionValue'],
              )
              .toList(),
      'selectedValues': [],
    };

    for (final artist in artists) {
      if (!tasteProfile.containsKey(artist)) {
        throw Exception('The artist $artist was not present in taste!');
      }
      formData['selectedValues']!.add(
        (tasteProfile[artist] as JsonMap)['selectionValue'],
      );
    }

    await sendRequest('browse', {
      'browseId': 'FEmusic_home',
      'formData': formData,
    });
  }
}
