import 'dart:math';

import 'package:ytmusicapi_dart/mixins/protocol.dart';
import 'package:ytmusicapi_dart/navigation.dart';
import 'package:ytmusicapi_dart/parsers/browsing.dart';
import 'package:ytmusicapi_dart/parsers/explore.dart';
import 'package:ytmusicapi_dart/type_alias.dart';

/// Extra playlist carousel some countries return between the video charts and the artists
// ignore: non_constant_identifier_names
final COUNTRY_EXTRA_CATEGORY = {'US': 'genres', 'IN': 'languages'};

/// Chart playlists are the only carousel items linking to a "VL" playlist
bool isPlaylistCarousel(List<JsonMap> contents) {
  final browseId = nav(contents.first, [
    MTRIR,
    ...TITLE,
    ...NAVIGATION_BROWSE_ID,
  ], nullIfAbsent: true);
  return browseId is String && browseId.startsWith('VL');
}

/// Returns true if [contents] is an artist carousel
bool isArtistCarousel(List<JsonMap> contents) {
  return contents.first.containsKey(MRLIR);
}

/// Mixin for chart functionalities.
mixin ChartsMixin on MixinProtocol {
  /// Get latest charts data from YouTube Music: Artists and playlists of top videos.
  /// Unauthenticated requests return unranked artists with "rank" and "trend" set to null.
  ///
  /// US charts have an extra Genres section, IN charts an extra Languages section.
  ///
  /// - [country] ISO 3166-1 Alpha-2 country code. (Default: ``ZZ`` = Global).
  ///
  /// Returns Map containing chart video playlists (with separate daily/weekly charts if authenticated with a premium account),
  /// chart genres (US-only, not returned by every response), chart languages (IN-only) and chart artists.
  ///
  /// Example:
  /// ```json
  /// {
  ///   "countries": {
  ///     "selected": {
  ///       "text": "United States"
  ///     },
  ///     "options": ["DE", "ZZ", "ZW"]
  ///   },
  ///   "videos": [
  ///     {
  ///       "title": "Daily Top Music Videos - United States",
  ///       "playlistId": "PL4fGSI1pDJn61unMfmrUSz68RT8IFFnks",
  ///       "thumbnails": []
  ///     }
  ///   ],
  ///   "artists": [
  ///     {
  ///       "title": "YoungBoy Never Broke Again",
  ///       "browseId": "UCR28YDxjDE3ogQROaNdnRbQ",
  ///       "subscribers": "9.62M",
  ///       "thumbnails": [],
  ///       "rank": "1",
  ///       "trend": "neutral"
  ///     }
  ///   ],
  ///   "genres": [
  ///     {
  ///       "title": "Top 50 Pop Music Videos United States",
  ///       "playlistId": "PL4fGSI1pDJn77aK7sAW2AT0oOzo5inWY8",
  ///       "thumbnails": []
  ///     }
  ///   ]
  /// }
  /// ```
  Future<JsonMap> getCharts({String country = 'ZZ'}) async {
    final body = <String, dynamic>{'browseId': 'FEmusic_charts'};
    if (country.isNotEmpty) {
      body['formData'] = {
        'selectedValues': [country],
      };
    }

    final response = await sendRequest('browse', body);
    final results =
        nav(response, [...SINGLE_COLUMN_TAB, ...SECTION_LIST]) as List;

    final charts = <String, dynamic>{'countries': {}};
    final menu = nav(results[0], [
      ...MUSIC_SHELF,
      'subheaders',
      0,
      'musicSideAlignedItemRenderer',
      'startItems',
      0,
      'musicSortFilterButtonRenderer',
    ]);

    (charts['countries'] as JsonMap)['selected'] = nav(menu, TITLE);

    (charts['countries'] as JsonMap)['options'] =
        [
          for (final m in nav(response, FRAMEWORK_MUTATIONS) as Iterable)
            nav(m, [
              'payload',
              'musicFormBooleanChoice',
              'opaqueToken',
            ], nullIfAbsent: true),
        ].where((e) => e != null).toList();

    // Carousels carry no machine-readable identity, so recognize them by their
    // contents. Ignore anything else (some regions add an album chart) instead
    // of shifting the categories that come after it.
    final carousels = <List<JsonMap>>[];

    for (final section in results.skip(1)) {
      final contents = nav(section, CAROUSEL_CONTENTS, nullIfAbsent: true);
      if (contents != null) {
        carousels.add(List<JsonMap>.from(contents as List));
      }
    }

    final playlistCarousels =
        carousels.where((c) => isPlaylistCarousel(c)).toList();

    final artistCarousels =
        carousels.where((c) => isArtistCarousel(c)).toList();

    final playlistNames = <String>['videos'];

    if (COUNTRY_EXTRA_CATEGORY.containsKey(country)) {
      playlistNames.add(COUNTRY_EXTRA_CATEGORY[country]!);
    }

    // Premium sessions get daily and weekly carousels in place of the "videos" one.
    // Could also be done via an isPremium attribute on YTMusic instance
    if (playlistCarousels.length > playlistNames.length) {
      playlistNames
        ..clear()
        ..addAll([
          'daily',
          'weekly',
          if (COUNTRY_EXTRA_CATEGORY.containsKey(country))
            COUNTRY_EXTRA_CATEGORY[country]!,
        ]);
    }

    // leaves trailing names unused: YTM omits categories unpredictably,
    // e.g. "genres" is missing from some US responses
    final count = min(playlistNames.length, playlistCarousels.length);

    for (var i = 0; i < count; i++) {
      charts[playlistNames[i]] = parseContentList(
        playlistCarousels[i],
        parseChartPlaylist,
      );
    }

    if (artistCarousels.isNotEmpty) {
      charts['artists'] = parseContentList(
        artistCarousels.first,
        parseChartArtist,
        key: MRLIR,
      );
    }

    return charts;
  }
}
