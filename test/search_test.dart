// ignore_for_file: avoid_dynamic_calls

import 'package:test/test.dart';
import 'package:ytmusicapi_dart/enums.dart';
import 'package:ytmusicapi_dart/parsers/search.dart';
import 'package:ytmusicapi_dart/type_alias.dart';
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
          final results = await instance.search(query);

          expect(results.length, greaterThanOrEqualTo(5));
          expect(
            results.every((r) => r.containsKey('resultType') as bool),
            isTrue,
          );

          for (final r in results) {
            if (r['resultType'] == 'album') {
              expect(r['playlistId'], isNotNull);
            }
          }

          final allApiResultTypes = API_RESULT_TYPES.map(
            (e) => e.toLowerCase(),
          );
          final anyInvalid = results.any((result) {
            if (result.containsKey('artists') as bool) {
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
            'title': 'The Marshall Mathers LP',
            'artists': [
              {'name': 'Eminem', 'id': 'UCedvOgsKFzcK3hA5taf3KoQ'},
            ],
            'type': 'Album',
            'resultType': 'album',
          },
        ),
        (
          'Seven Martin Garrix',
          {
            'title': 'Seven',
            'artists': [
              {'name': 'Martin Garrix', 'id': 'UCqJnSdHjKtfsrHi9aI-9d3g'},
            ],
            'type': 'EP',
            'resultType': 'album',
          },
        ),
      ];

      for (final c in cases) {
        final query = c.$1;
        final expected = c.$2;
        final results = await yt.search(query, filter: SearchFilter.albums);
        expect(
          results.any((r) => _mapContainsAll(r as JsonMap, expected)),
          isTrue,
        );
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
      final results = await ytLocal.search('ABBA');
      expect(
        results.every((r) => ALL_RESULT_TYPES.contains(r['resultType'])),
        isTrue,
      );

      final albumCount =
          results.where((r) => r['resultType'] == 'album').length;
      expect(albumCount, lessThanOrEqualTo(10));

      final songResults = await ytLocal.search(
        'ABBA',
        filter: SearchFilter.songs,
      );
      expect(songResults.every((r) => r['resultType'] == 'song'), isTrue);
    });

    test('search filters', () async {
      const query = 'hip hop playlist';
      final resultsSongs = await yt.search(query, filter: SearchFilter.songs);
      expect(resultsSongs.length, greaterThan(10));
      expect(resultsSongs.every((r) => r['views'] != ''), isTrue);
      expect(
        resultsSongs.every((r) => (r['artists'] as List).isNotEmpty),
        isTrue,
      );
      expect(resultsSongs.every((r) => r['resultType'] == 'song'), isTrue);

      final resultsVideos = await yt.search(query, filter: SearchFilter.videos);
      expect(resultsVideos.length, greaterThan(10));
      for (final r in resultsVideos) {
        if (r['videoType'] != 'MUSIC_VIDEO_TYPE_PODCAST_EPISODE') {
          expect(r['views'], isNotEmpty);
        }
      }
      expect(resultsVideos.every((r) => r['resultType'] == 'video'), isTrue);
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
