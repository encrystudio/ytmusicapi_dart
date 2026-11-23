// ignore_for_file: avoid_dynamic_calls

import 'package:test/test.dart';
import 'package:ytmusicapi_dart/enums.dart';
import 'package:ytmusicapi_dart/ytmusicapi_dart.dart';

void main() {
  late YTMusic yt;

  setUp(() async {
    yt = await YTMusic.create();
  });

  group('Search Tests', () {
    test('search exceptions', () {
      const query = 'edm playlist';

      expect(
        () async => await yt.search(query, scope: 'upload'),
        throwsA(
          predicate((e) => e.toString().contains('Invalid scope provided')),
        ),
      );
    });

    final queries = ['Monekes', 'llwlwl', 'heun'];
    final ytInstances = <String, YTMusic Function()>{'yt': () => yt};

    for (final query in queries) {
      for (final entry in ytInstances.entries) {
        test('search queries: ${entry.key} / $query', () async {
          final instance = entry.value();
          final results = (await instance.search(query)).map((e) => e.asJson());

          expect(results.length, greaterThanOrEqualTo(5));
          expect(results.every((r) => r.containsKey('type')), isTrue);

          for (final r in results) {
            if (r['type'] == 'album') {
              expect(r['playlistId'], isNotNull);
            }
          }

          final allApiResultTypes = YtResultType.values.map(
            (e) => e.name.toLowerCase(),
          );
          final anyInvalid = results.any((result) {
            if (result.containsKey('artists')) {
              for (final artist in result['artists'] as Iterable) {
                if (allApiResultTypes.contains(artist['name'].toLowerCase())) {
                  return true;
                }
              }
            }
            return false;
          });
          expect(anyInvalid, isFalse);
        });
      }
    }

    test('search album artists', () async {
      final cases = [
        (
          'Eminem The Marshall Mathers LP',
          {
            'name': 'The Marshall Mathers LP',
            'artists': [
              {'name': 'Eminem', 'id': 'UCedvOgsKFzcK3hA5taf3KoQ'},
            ],
            'albumType': 'Album',
            'type': 'ALBUM',
          },
        ),
        (
          'Seven Martin Garrix',
          {
            'name': 'Seven',
            'artists': [
              {'name': 'Martin Garrix', 'id': 'UCqJnSdHjKtfsrHi9aI-9d3g'},
            ],
            'albumType': 'EP',
            'type': 'ALBUM',
          },
        ),
      ];

      for (final c in cases) {
        final query = c.$1;
        final expected = c.$2;
        final results = (await yt.search(
          query,
          filter: SearchFilterType.albums,
        )).map((e) => e.asJson());
        expect(results.any((r) => _mapContainsAll(r, expected)), isTrue);
      }
    });

    test('search ignore spelling', () async {
      final results = await yt.search(
        'Martin Stig Andersen - Deteriation',
        ignoreSpelling: true,
      );
      expect(results, isNotEmpty);
    });

    test('search localized', () async {
      final ytLocal = await YTMusic.create(location: 'IT');
      final results = (await ytLocal.search('ABBA')).map((e) => e.asJson());
      expect(
        results.every(
          (r) => YtResultType.values
              .map((e) => e.name.toLowerCase())
              .contains(r['type'].toLowerCase()),
        ),
        isTrue,
      );

      final albumCount = results.where((r) => r['type'] == 'album').length;
      expect(albumCount, lessThanOrEqualTo(10));

      final songResults = (await ytLocal.search(
        'ABBA',
        filter: SearchFilterType.songs,
      )).map((e) => e.asJson());
      expect(
        songResults.every(
          (r) => r['type'].toLowerCase() == 'video' && r['isSong'] as bool,
        ),
        isTrue,
      );
    });

    test('search filters', () async {
      const query = 'hip hop playlist';
      final resultsSongs = (await yt.search(
        query,
        filter: SearchFilterType.songs,
      )).map((e) => e.asJson());
      expect(resultsSongs.length, greaterThan(10));
      expect(resultsSongs.every((r) => r['views'] != ''), isTrue);
      expect(
        resultsSongs.every((r) => (r['artists'] as List).isNotEmpty),
        isTrue,
      );
      expect(
        resultsSongs.every(
          (r) => r['type'].toLowerCase() == 'video' && r['isSong'] as bool,
        ),
        isTrue,
      );

      final resultsVideos = (await yt.search(
        query,
        filter: SearchFilterType.videos,
      )).map((e) => e.asJson());
      expect(resultsVideos.length, greaterThan(10));
      for (final r in resultsVideos) {
        if (r['videoType'] != 'MUSIC_VIDEO_TYPE_PODCAST_EPISODE') {
          expect(r['views'], isNotEmpty);
        }
      }
      expect(
        resultsVideos.every((r) => r['type'].toLowerCase() == 'video'),
        isTrue,
      );
    });

    test('remove search suggestions valid', () {
      // TODO requires authentication - add tests when implemented
      expect(true, isTrue, skip: true);
    });

    test('remove search suggestions errors', () {
      // TODO requires authentication - add tests when implemented
      expect(true, isTrue, skip: true);
    });
  });
}

/// Utility to check if all key-value pairs in [subset] exist in [map]
bool _mapContainsAll(Map map, Map subset) {
  for (final entry in subset.entries) {
    final key = entry.key;
    final value = entry.value;

    if (!map.containsKey(key)) return false;

    final target = map[key];

    if (!_deepEquals(target, value)) return false;
  }
  return true;
}

/// Better equals function to handle nested structures
bool _deepEquals(dynamic a, dynamic b) {
  // Handle nulls
  if (a == null || b == null) return a == b;

  // Handle numbers (e.g., 1 == 1.0)
  if (a is num && b is num) return a == b;

  // Handle strings, bools, etc.
  if (a is String && b is String) return a == b;
  if (a is bool && b is bool) return a == b;

  // Handle lists
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (!_deepEquals(a[i], b[i])) return false;
    }
    return true;
  }

  // Handle maps
  if (a is Map && b is Map) {
    for (final key in b.keys) {
      if (!a.containsKey(key)) return false;
      if (!_deepEquals(a[key], b[key])) return false;
    }
    return true;
  }

  // Fallback to regular equality
  return a == b;
}
