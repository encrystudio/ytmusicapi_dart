import 'package:ytmusicapi_dart/mixins/protocol.dart';
import 'package:ytmusicapi_dart/navigation.dart';
import 'package:ytmusicapi_dart/parsers/browsing.dart';
import 'package:ytmusicapi_dart/parsers/explore.dart';
import 'package:ytmusicapi_dart/type_alias.dart';

/// Mixin for explore functionalities.
mixin ExploreMixin on MixinProtocol {
  /// Fetch "Moods & Genres" categories from YouTube Music.
  ///
  /// Returns Map of sections and categories.
  ///
  /// Example:
  /// ```json
  /// {
  ///   "title": "Stanford Graduate School of Business",
  ///   "thumbnails": [...],
  ///   "episodes": {
  ///     "browseId": "UCGwuxdEeCf0TIA2RbPOj-8g",
  ///     "results": [
  ///       {
  ///         "index": 0,
  ///         "title": "The Brain Gain: The Impact of Immigration on American Innovation with Rebecca Diamond",
  ///         "description": "Immigrants' contributions to America ...",
  ///         "duration": "24 min",
  ///         "videoId": "TS3Ovvk3VAA",
  ///         "browseId": "MPEDTS3Ovvk3VAA",
  ///         "videoType": "MUSIC_VIDEO_TYPE_PODCAST_EPISODE",
  ///         "date": "Mar 6, 2024",
  ///         "thumbnails": [...]
  ///       }
  ///     ],
  ///     "params": "6gPiAUdxWUJXcFlCQ3BN..."
  ///   },
  ///   "podcasts": {
  ///     "browseId": null,
  ///     "results": [
  ///       {
  ///         "title": "Stanford GSB Podcasts",
  ///         "channel": {
  ///           "id": "UCGwuxdEeCf0TIA2RbPOj-8g",
  ///           "name": "Stanford Graduate School of Business"
  ///         },
  ///         "browseId": "MPSPPLxq_lXOUlvQDUNyoBYLkN8aVt5yAwEtG9",
  ///         "podcastId": "PLxq_lXOUlvQDUNyoBYLkN8aVt5yAwEtG9",
  ///         "thumbnails": [...]
  ///       }
  ///     ]
  ///   }
  /// }
  /// ```
  Future<JsonMap> getMoodCategories() async {
    final sections = <String, dynamic>{};
    final response = await sendRequest('browse', {
      'browseId': 'FEmusic_moods_and_genres',
    });
    for (final section
        in nav(response, [...SINGLE_COLUMN_TAB, ...SECTION_LIST]) as Iterable) {
      final title = nav(section, [
        ...GRID,
        'header',
        'gridHeaderRenderer',
        ...TITLE_TEXT,
      ]);
      sections[title as String] = <JsonMap>[];
      for (final category in nav(section, GRID_ITEMS) as Iterable) {
        (sections[title] as List).add({
          'title': nav(category, CATEGORY_TITLE),
          'params': nav(category, CATEGORY_PARAMS),
        });
      }
    }
    return sections;
  }

  /// Retrieve a list of playlists for a given "Moods & Genres" category.
  ///
  /// - [params] params obtained by [getMoodCategories].
  ///
  /// Returns List of playlists in the format of [getLibraryPlaylists]. // TODO getLibraryPlaylists is currently missing
  Future<List> getMoodPlaylists(String params) async {
    final playlists = <dynamic>[];
    final response = await sendRequest('browse', {
      'browseId': 'FEmusic_moods_and_genres_category',
      'params': params,
    });

    for (final section
        in nav(response, [...SINGLE_COLUMN_TAB, ...SECTION_LIST])
            as List<JsonMap>) {
      List path = [];
      if (section.containsKey('gridRenderer')) {
        path = GRID_ITEMS;
      } else if (section.containsKey('musicCarouselShelfRenderer')) {
        path = CAROUSEL_CONTENTS;
      } else if (section.containsKey('musicImmersiveCarouselShelfRenderer')) {
        path = ['musicImmersiveCarouselShelfRenderer', 'contents'];
      }

      if (path.isNotEmpty) {
        final results = nav(section, path);
        playlists.addAll(
          await parseContentList(results as List<JsonMap>, parsePlaylist),
        );
      }
    }
    return playlists;
  }

  /// Get latest explore data from YouTube Music.
  ///
  /// The Top Songs chart is only returned when authenticated with a premium account.
  ///
  /// Returns Map containing new album releases, top songs (if authenticated with a premium account), moods & genres, popular episodes, trending tracks, and new music videos.
  ///
  /// Example:
  /// ```json
  /// {
  ///   "new_releases": [
  ///     {
  ///       "title": "Hangang",
  ///       "type": "Album",
  ///       "artists": [
  ///         {
  ///           "id": "UCpo4SbqmPXpCVA5RFj-Gq5Q",
  ///           "name": "Dept"
  ///         }
  ///       ],
  ///       "browseId": "MPREb_rGl39ZNEl95",
  ///       "audioPlaylistId": "OLAK5uy_mTZAp8a-agh1at-cVUGrwPhTJoM5GnKTk",
  ///       "thumbnails": [...],
  ///       "isExplicit": false
  ///     }
  ///   ],
  ///   "top_songs": {
  ///     "playlist": "VLPL4fGSI1pDJn6O1LS0XSdF3RyO0Rq_LDeI",
  ///     "items": [
  ///       {
  ///         "title": "Outside (Better Days)",
  ///         "videoId": "oT79YlRtXDg",
  ///         "artists": [
  ///           {
  ///             "name": "MO3",
  ///             "id": "UCdFt4Cvhr7Okaxo6hZg5K8g"
  ///           },
  ///           {
  ///             "name": "OG Bobby Billions",
  ///             "id": "UCLusb4T2tW3gOpJS1fJ-A9g"
  ///           }
  ///         ],
  ///         "thumbnails": [...],
  ///         "isExplicit": true,
  ///         "album": {
  ///           "name": "Outside (Better Days)",
  ///           "id": "MPREb_fX4Yv8frUNv"
  ///         },
  ///         "rank": "1",
  ///         "trend": "up"
  ///       }
  ///     ]
  ///   },
  ///   "moods_and_genres": [
  ///     {
  ///       "title": "Chill",
  ///       "params": "ggMPOg1uXzVuc0dnZlhpV3Ba"
  ///     }
  ///   ],
  ///   "top_episodes": [
  ///     {
  ///       "title": "132. Lean Into Failure: How to Make Mistakes That Work | Think Fast, Talk Smart: Communication...",
  ///       "description": "...",
  ///       "duration": "25 min",
  ///       "videoId": "xAEGaW2my7E",
  ///       "browseId": "MPEDxAEGaW2my7E",
  ///       "videoType": "MUSIC_VIDEO_TYPE_PODCAST_EPISODE",
  ///       "date": "Mar 5, 2024",
  ///       "thumbnails": [...],
  ///       "podcast": {
  ///         "id": "UCGwuxdEeCf0TIA2RbPOj-8g",
  ///         "name": "Stanford Graduate School of Business"
  ///       }
  ///     }
  ///   ],
  ///   "trending": {
  ///     "playlist": "VLOLAK5uy_kNWGJvgWVqlt5LsFDL9Sdluly4M8TvGkM",
  ///     "items": [
  ///       {
  ///         "title": "Permission to Dance",
  ///         "videoId": "CuklIb9d3fI",
  ///         "playlistId": "OLAK5uy_kNWGJvgWVqlt5LsFDL9Sdluly4M8TvGkM",
  ///         "artists": [
  ///           {
  ///             "name": "BTS",
  ///             "id": "UC9vrvNSL3xcWGSkV86REBSg"
  ///           }
  ///         ],
  ///         "thumbnails": [...],
  ///         "isExplicit": false,
  ///         "views": "108M"
  ///       }
  ///     ]
  ///   },
  ///   "new_videos": [
  ///     {
  ///       "title": "EVERY CHANCE I GET (Official Music Video) (feat. Lil Baby & Lil Durk)",
  ///       "videoId": "BTivsHlVcGU",
  ///       "artists": [
  ///         {
  ///           "name": "DJ Khaled",
  ///           "id": "UC0Kgvj5t_c9EMWpEDWJuR1Q"
  ///         }
  ///       ],
  ///       "playlistId": null,
  ///       "thumbnails": [...],
  ///       "views": "46M"
  ///     }
  ///   ]
  /// }
  /// ```
  Future<JsonMap> getExplore() async {
    final body = {'browseId': 'FEmusic_explore'};
    final response = await sendRequest('browse', body);
    final results = nav(response, [...SINGLE_COLUMN_TAB, ...SECTION_LIST]);

    final explore = <String, dynamic>{};

    for (final result in results as Iterable) {
      final browseId =
          nav(result, [
                ...CAROUSEL,
                ...CAROUSEL_TITLE,
                ...NAVIGATION_BROWSE_ID,
              ], nullIfAbsent: true)
              as String?;
      if (browseId == null) continue;

      final contents = nav(result, CAROUSEL_CONTENTS);

      switch (browseId) {
        case 'FEmusic_new_releases_albums':
          explore['new_releases'] = parseContentList(
            contents as List<JsonMap>,
            parseAlbum,
          );

        case 'FEmusic_moods_and_genres':
          explore['moods_and_genres'] = [
            for (final genre in nav(result, CAROUSEL_CONTENTS) as Iterable)
              {
                'title': nav(genre, CATEGORY_TITLE),
                'params': nav(genre, CATEGORY_PARAMS),
              },
          ];

        case 'FEmusic_top_non_music_audio_episodes':
          explore['top_episodes'] = parseContentList(
            contents as List<JsonMap>,
            parseChartEpisode,
            key: MMRIR,
          );

        case 'FEmusic_new_releases_videos':
          explore['new_videos'] = parseContentList(
            contents as List<JsonMap>,
            parseVideo,
          );

        default:
          if (browseId.startsWith('VLPL')) {
            explore['top_songs'] = {
              'playlist': browseId,
              'items': parseContentList(
                contents as List<JsonMap>,
                parseChartSong,
                key: MRLIR,
              ),
            };
          } else if (browseId.startsWith('VLOLA')) {
            explore['trending'] = {
              'playlist': browseId,
              'items': parseContentList(
                contents as List<JsonMap>,
                parseSongFlat,
                key: MRLIR,
              ),
            };
          }
      }
    }

    return explore;
  }
}
