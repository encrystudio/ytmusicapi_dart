import 'dart:convert';

import 'package:ytmusicapi_dart/ytmusicapi_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Search tests', () {
    final ytmusic = YTMusic();

    setUp(() {
      // Additional setup goes here.
    });

    test('Search', () async {
      var result = await ytmusic.search('NCS');
      print(json.encode(result));
      expect(result.isNotEmpty, isTrue);
    });

    test('Filter Albums', () async {
      var result = await ytmusic.search('NCS', filter: Filter.ALBUMS);
      print(json.encode(result));
      expect(result.isNotEmpty, isTrue);
    });

    test('Filter Artists', () async {
      var result = await ytmusic.search('NCS', filter: Filter.ARTISTS);
      print(json.encode(result));
      expect(result.isNotEmpty, isTrue);
    });

    test('Filter Community Playlists', () async {
      var result = await ytmusic.search(
        'NCS',
        filter: Filter.COMMUNITY_PLAYLISTS,
      );
      print(json.encode(result));
      expect(result.isNotEmpty, isTrue);
    });

    test('Filter Episodes', () async {
      var result = await ytmusic.search('NCS', filter: Filter.EPISODES);
      print(json.encode(result));
      expect(result.isNotEmpty, isTrue);
    });

    test('Filter Featured Playlists', () async {
      var result = await ytmusic.search(
        'EDM',
        filter: Filter.FEATURED_PLAYLISTS,
      );
      print(json.encode(result));
      expect(result.isNotEmpty, isTrue);
    });

    test('Filter Playlists', () async {
      var result = await ytmusic.search('NCS', filter: Filter.PLAYLISTS);
      print(json.encode(result));
      expect(result.isNotEmpty, isTrue);
    });

    test('Filter Podcasts', () async {
      var result = await ytmusic.search('NCS', filter: Filter.PODCASTS);
      print(json.encode(result));
      expect(result.isNotEmpty, isTrue);
    });

    test('Filter Profiles', () async {
      var result = await ytmusic.search('NCS', filter: Filter.PROFILES);
      print(json.encode(result));
      expect(result.isNotEmpty, isTrue);
    });

    test('Filter Songs', () async {
      var result = await ytmusic.search('NCS', filter: Filter.SONGS);
      print(json.encode(result));
      expect(result.isNotEmpty, isTrue);
    });

    test('Filter Videos', () async {
      var result = await ytmusic.search('NCS', filter: Filter.VIDEOS);
      print(json.encode(result));
      expect(result.isNotEmpty, isTrue);
    });
  });
}
