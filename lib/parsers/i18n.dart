import 'package:ytmusicapi_dart/navigation.dart';
import 'package:ytmusicapi_dart/parsers/browsing.dart';
import 'package:ytmusicapi_dart/parsers/podcasts.dart';
import 'package:ytmusicapi_dart/type_alias.dart';

// ignore: public_member_api_docs
const EN_LOCALE = {
  'album': 'album',
  'artist': 'artist',
  'playlist': 'playlist',
  'song': 'song',
  'video': 'video',
  'station': 'station',
  'profile': 'profile',
  'podcast': 'podcast',
  'episode': 'episode',
  'single': 'single',
  'ep': 'ep',
  'albums': 'albums',
  'singles & eps': 'singles & eps',
  'shows': 'Audiobooks and shows',
  'videos': 'videos',
  'playlists': 'playlists',
  'related': 'fans might also like',
  'episodes': 'latest episodes',
  'podcasts': 'podcasts',
};

/// Translates [key] to current language. // TODO
///
/// Currently uses English for everything.
String t(String key) {
  if (EN_LOCALE.containsKey(key)) {
    return EN_LOCALE[key]!;
  }
  return key;
}

/// i18n parser.
class Parser {
  /// The current language.
  final dynamic lang;

  /// Create new [Parser].
  Parser(this.lang);

  /// Returns all search result types.
  List<String> getSearchResultTypes() {
    return [
      t('album'),
      t('artist'),
      t('playlist'),
      t('song'),
      t('video'),
      t('station'),
      t('profile'),
      t('podcast'),
      t('episode'),
    ];
  }

  /// Returns all api result types.
  List<String> getApiResultTypes() {
    return [t('single'), t('ep'), ...getSearchResultTypes()];
  }

  /// Parses content from a channel.
  JsonMap parseChannelContents(List<JsonMap> results) {
    final categories = [
      ['albums', t('albums'), parseAlbum, 'MTRIR'],
      ['singles', t('singles & eps'), parseSingle, 'MTRIR'],
      ['shows', t('shows'), parseAlbum, 'MTRIR'],
      ['videos', t('videos'), parseVideo, 'MTRIR'],
      ['playlists', t('playlists'), parsePlaylist, 'MTRIR'],
      ['related', t('related'), parseRelatedArtist, 'MTRIR'],
      ['episodes', t('episodes'), parseEpisode, 'MMRIR'],
      ['podcasts', t('podcasts'), parsePodcast, 'MTRIR'],
    ];

    final artist = <String, dynamic>{};

    for (final category in categories) {
      final categoryKey = category[0] as String;
      final categoryLocal = category[1] as String;
      final categoryParser = category[2] as JsonMap Function(JsonMap);
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
        artist[categoryKey] = JsonMap.from({'browseId': null, 'results': []});

        final navTitle = nav(data[0], CAROUSEL_TITLE) as JsonMap;
        if (navTitle.containsKey('navigationEndpoint')) {
          (artist[categoryKey] as JsonMap)['browseId'] = nav(
            data[0],
            CAROUSEL_TITLE + NAVIGATION_BROWSE_ID,
          );
          (artist[categoryKey] as JsonMap)['params'] = nav(
            data[0],
            CAROUSEL_TITLE + NAVIGATION_BROWSE + ['params'],
            nullIfAbsent: true,
          );
        }

        (artist[categoryKey] as JsonMap)['results'] = parseContentList(
          data[0]['contents'],
          categoryParser,
          key: categoryNavKey,
        );
      }
    }

    return artist;
  }
}

/// Parses [contents].
List parseContentList(
  dynamic contents,
  JsonMap Function(JsonMap) parser, {
  required String key,
}) {
  if (contents is List) {
    return contents.map((c) => parser(c as JsonMap)).toList().cast<JsonMap>();
  }
  return [];
}
