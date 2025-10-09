import 'package:ytmusicapi_dart/mixins/protocol.dart';
import 'package:ytmusicapi_dart/navigation.dart';
import 'package:ytmusicapi_dart/parsers/browsing.dart';
import 'package:ytmusicapi_dart/parsers/explore.dart';
import 'package:ytmusicapi_dart/type_alias.dart';
import 'package:ytmusicapi_dart/utils.dart';

/// Mixin for chart functionalities.
mixin ChartsMixin on MixinProtocol {
  /// Get latest charts data from YouTube Music: Artists and playlists of top videos.
  ///
  /// US charts have an extra Genres section with some Genre charts.
  ///
  /// - [country] ISO 3166-1 Alpha-2 country code. (Default: ``ZZ`` = Global).
  ///
  /// Returns Map containing chart video playlists (with separate daily/weekly charts if authenticated with a premium account),
  /// chart genres (US-only), and chart artists.
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

    final chartsCategories = <Tuple3<String, RequestFuncBodyType, String>>[
      Tuple3('videos', parseChartPlaylist, MTRIR),
      if (country == 'US') Tuple3('genres', parseChartPlaylist, MTRIR),
      Tuple3('artists', parseChartArtist, MRLIR),
    ];

    // use result length to determine if the daily/weekly chart categories are present
    if ((results.length - 1) > chartsCategories.length) {
      // daily and weekly replace the "videos" playlist carousel
      final dailyWeekly = [
        Tuple3('daily', parseChartPlaylist, MTRIR),
        Tuple3('weekly', parseChartPlaylist, MTRIR),
      ];
      chartsCategories
        ..removeAt(0)
        ..insertAll(0, dailyWeekly);
    }

    for (var i = 0; i < chartsCategories.length; i++) {
      final name = chartsCategories[i].item1;
      final parseFunc = chartsCategories[i].item2;
      final key = chartsCategories[i].item3;
      charts[name] = parseContentList(
        nav(results[1 + i], CAROUSEL_CONTENTS) as List<JsonMap>,
        parseFunc,
        key: key,
      );
    }
    return charts;
  }
}
