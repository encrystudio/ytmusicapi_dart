import 'package:ytmusicapi_dart/models/objects/album.dart';
import 'package:ytmusicapi_dart/models/objects/artist.dart';
import 'package:ytmusicapi_dart/models/objects/video.dart';
import 'package:ytmusicapi_dart/navigation.dart';
import 'package:ytmusicapi_dart/parsers/browsing.dart';
import 'package:ytmusicapi_dart/parsers/podcasts.dart';
import 'package:ytmusicapi_dart/type_alias.dart';

/// Parser.
class Parser {
  /// Returns all song credit sections.
  Map<String, dynamic> getSongCreditSectionMap() {
    return {
      'performed_by': 'performed_by',
      'written_by': 'written_by',
      'produced_by': 'produced_by',
      'music_metadata_provided_by': 'music_metadata_provided_by',
    };
  }

  /// Parses content from a channel.
  void parseChannelContents(List<JsonMap> results, YtBrowsedArtist artist) {
    final categories = [
      ['albums', 'albums', parseAlbum, MTRIR],
      ['singles', 'singles & eps', parseSingle, MTRIR],
      ['shows', 'shows', parseAlbum, MTRIR],
      ['videos', 'videos', parseVideo, MTRIR],
      ['playlists', 'playlists', parsePlaylist, MTRIR],
      ['related', 'related', parseRelatedArtist, MTRIR],
      ['episodes', 'episodes', parseEpisode, MMRIR],
      ['podcasts', 'podcasts', parsePodcast, MTRIR],
    ];

    final artistMap = <String, dynamic>{};

    for (final category in categories) {
      final categoryKey = category.first as String;
      final categoryLocal = category[1] as String;
      final categoryParser = category[2] as dynamic Function(JsonMap);
      final categoryNavKey = category[3] as String;

      final data =
          List<JsonMap>.from(
            results.where(
              (r) =>
                  r.containsKey('musicCarouselShelfRenderer') &&
                  ((nav(r, CAROUSEL + CAROUSEL_TITLE) as JsonMap)['text']
                              as String)
                          .toLowerCase() ==
                      categoryLocal.toLowerCase(),
            ),
          ).map((r) => r['musicCarouselShelfRenderer'] as JsonMap).toList();

      if (data.isNotEmpty) {
        artistMap[categoryKey] = JsonMap.from({
          'browseId': null,
          'results': [],
        });

        final navTitle = nav(data.first, CAROUSEL_TITLE) as JsonMap;
        if (navTitle.containsKey('navigationEndpoint')) {
          (artistMap[categoryKey] as JsonMap)['browseId'] = nav(
            data.first,
            CAROUSEL_TITLE + NAVIGATION_BROWSE_ID,
          );
          (artistMap[categoryKey] as JsonMap)['params'] = nav(
            data.first,
            CAROUSEL_TITLE + NAVIGATION_BROWSE + ['params'],
            nullIfAbsent: true,
          );
        }

        (artistMap[categoryKey] as JsonMap)['results'] = parseContentList(
          List<JsonMap>.from(data.first['contents'] as List),
          categoryParser,
          key: categoryNavKey,
        );
      }
    }
    artist.albumsBrowseId =
        (artistMap['albums'] as JsonMap?)?['browseId'] as String?;
    artist.albumsParams =
        (artistMap['albums'] as JsonMap?)?['params'] as String?;
    artist.albumsResults =
        (artistMap['albums'] as JsonMap?)?['results'] is List
            ? List<YtAlbum>.from(
              (artistMap['albums'] as JsonMap)['results'] as List,
            )
            : [];
    artist.singlesBrowseId =
        (artistMap['singles'] as JsonMap?)?['browseId'] as String?;
    artist.singlesParams =
        (artistMap['singles'] as JsonMap?)?['params'] as String?;
    artist.singlesResults =
        (artistMap['singles'] as JsonMap?)?['results'] is List
            ? List<YtAlbum>.from(
              (artistMap['singles'] as JsonMap)['results'] as List,
            )
            : [];
    artist.showsBrowseId =
        (artistMap['shows'] as JsonMap?)?['browseId'] as String?;
    artist.videosBrowseId =
        (artistMap['videos'] as JsonMap)['browseId'] as String?;
    artist.videosResults = List<YtVideo>.from(
      (artistMap['videos'] as JsonMap)['results'] as List,
    );
    artist.playlistsBrowseId =
        (artistMap['playlists'] as JsonMap?)?['browseId'] as String?;
    artist.relatedBrowseId =
        (artistMap['related'] as JsonMap?)?['browseId'] as String?;
    artist.relatedResults =
        ((artistMap['related'] as JsonMap?)?['results'] is List)
            ? List<YtArtist>.from(
              (artistMap['related'] as JsonMap)['results'] as List,
            )
            : [];
    artist.episodesBrowseId =
        (artistMap['episodes'] as JsonMap?)?['browseId'] as String?;
    artist.podcastsBrowseId =
        (artistMap['podcasts'] as JsonMap?)?['browseId'] as String?;
  }
}

/// Parses [contents].
List<T> parseContentList<T>(
  List<JsonMap> results,
  T Function(JsonMap) parseFunc, {
  String key = MTRIR,
}) {
  final List<T> contents = [];
  for (final result in results) {
    contents.add(parseFunc(result[key] as JsonMap));
  }
  return contents;
}
