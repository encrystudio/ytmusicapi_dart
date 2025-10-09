// ignore_for_file: avoid_dynamic_calls

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:ytmusicapi_dart/enums.dart';
import 'package:ytmusicapi_dart/models/lyrics.dart';
import 'package:ytmusicapi_dart/type_alias.dart';
import 'package:ytmusicapi_dart/ytmusicapi_dart.dart';

void main() {
  late YTMusic yt;
  const String sampleAlbum = 'MPREb_4pL8gzRtw1p';
  const String sampleVideo = 'hpSrLjc5SMs';
  setUp(() async {
    yt = await YTMusic.create();
  });

  group('Browsing Tests', () {
    test('get home', () async {
      final result = await yt.getHome();
      expect(result.length, greaterThanOrEqualTo(2));

      // ensure we aren't parsing specifiers like "Song" as artist names
      for (final section in result) {
        for (final item in section['contents'] as Iterable) {
          if (item != null && (item['artists']?.length ?? 0) > 1 as bool) {
            final artist = item['artists'][0];
            expect(
              artist['id'] != null ||
                  !yt.parser.getApiResultTypes().contains(
                    artist['name'].toLowerCase(),
                  ),
              true,
            );
          }
        }
      }

      // ensure all links are supported by parseMixedContent
      for (final section in result) {
        for (final item in section['contents'] as Iterable) {
          expect(item, isNotNull);
        }
      }
    });

    test('get artist', () async {
      final results = await yt.getArtist('MPLAUCmMUZbaYdNH0bEd1PAlAqsA');
      expect(results.length, equals(16));
      expect(results['shuffleId'], isNotNull);
      expect(results['radioId'], isNotNull);

      // test correctness of related artists
      final related = results['related']['results'] as List;
      final valid = related.where(
        (x) =>
            x.keys.toSet().containsAll({
                  'browseId',
                  'subscribers',
                  'title',
                  'thumbnails',
                })
                as bool,
      );
      expect(valid.length, equals(related.length));

      final resultsNoYear = await yt.getArtist(
        'UCLZ7tlKC06ResyDmEStSrOw',
      ); // no album year
      expect(resultsNoYear.length, greaterThanOrEqualTo(11));
    });

    test('get artist shows', () {
      // TODO requires authentication - add tests when implemented
      expect(true, isTrue, skip: true);
    });

    test('get artist albums', () async {
      final artist = await yt.getArtist('UCAeLFBCQS7FvI8PvBrWvSBg');
      final albumResults = await yt.getArtistAlbums(
        artist['albums']['browseId'] as String,
        artist['albums']['params'] as String,
      );
      for (final result in albumResults) {
        expect(
          result.containsKey('artists'),
          isFalse,
        ); // artist info is omitted from the results
      }
      expect(albumResults.length, equals(100));
      final singleResults = await yt.getArtistAlbums(
        artist['singles']['browseId'] as String,
        artist['singles']['params'] as String,
      );
      expect(singleResults.length, equals(100));

      final resultsUnsorted = await yt.getArtistAlbums(
        artist['albums']['browseId'] as String,
        artist['albums']['params'] as String,
        limit: null,
      );
      expect(resultsUnsorted.length, greaterThanOrEqualTo(300));

      final resultsSorted = await yt.getArtistAlbums(
        artist['albums']['browseId'] as String,
        artist['albums']['params'] as String,
        limit: null,
        order: ArtistOrderType.alphabetical,
      );

      expect(resultsSorted.length, greaterThanOrEqualTo(300));
      expect(resultsSorted != resultsUnsorted, isTrue);
    });

    test('get user', () async {
      final result = await yt.getUser('UC44hbeRoCZVVMVg5z0FfIww');
      expect(result.length, equals(3));
    });

    test('get user playlists', () {
      // TODO requires authentication - add tests when implemented
      expect(true, isTrue, skip: true);
    });

    test('get user videos', () {
      // TODO requires authentication - add tests when implemented
      expect(true, isTrue, skip: true);
    });

    test('get album browse id', () async {
      final browseId = await yt.getAlbumBrowseId(
        'OLAK5uy_nMr9h2VlS-2PULNz3M3XVXQj_P3C2bqaY',
      );
      expect(browseId, equals(sampleAlbum));
    });

    test('get album browse id issue 470', () async {
      final escapedBrowseId = await yt.getAlbumBrowseId(
        'OLAK5uy_nbMYyrfeg5ZgknoOsOGBL268hGxtcbnDM',
      );
      expect(escapedBrowseId!.length, equals(17));
    });

    test('get album 2024', () async {
      final file = File('test/data/2024_03_get_album.json');
      final jsonMap = jsonDecode(await file.readAsString()) as JsonMap;
      final album = await yt.getAlbum('MPREabc', requestData: jsonMap);
      expect(album['tracks'].length, equals(19));
      expect(album['artists'].length, equals(1));
      expect(album.length, equals(14));
      for (final track in album['tracks'] as Iterable) {
        expect(track['title'], isNotNull);
        expect(track['title'], isA<String>());
        expect(track['artists'].length, greaterThan(0));
        for (final artist in track['artists'] as Iterable) {
          expect(artist.containsKey('name'), isTrue);
          expect(artist['name'], isNotNull);
          expect(artist['name'], isA<String>());
        }
      }
    });

    test('get album', () async {
      // TODO requires authentication - add tests when implemented
      expect(true, isTrue, skip: true);
      final album = await yt.getAlbum('MPREb_BQZvl3BFGay');
      expect(album['audioPlaylistId'], isNotNull);
      expect(album['tracks'].length, equals(7));
      expect(album['tracks'][0]['artists'].length, equals(1));
      final album2 = await yt.getAlbum('MPREb_7HdnOQMfJ3w');
      expect(album2['likeStatus'], isNotNull);
      expect(album2['audioPlaylistId'], isNotNull);
      expect(album2['tracks'][0]['artists'].length, equals(2));
      final album3 = await yt.getAlbum(
        'MPREb_G21w42zx0qJ',
      ); // album with track (#13) disabled/greyed out
      expect(album3['likeStatus'], isNotNull);
      expect(album3['audioPlaylistId'], isNotNull);
      expect(album3['tracks'][12]['trackNumber'], equals(13));
      expect(album3['tracks'][12]['isAvailable'], isTrue);
    });

    test('get album errors', () {
      expect(
        () async => await yt.getAlbum('asdf'),
        throwsA(
          predicate((e) => e.toString().contains('Invalid album browseId')),
        ),
      );
    });

    test('get album without artist', () async {
      final album = await yt.getAlbum(
        'MPREb_n1AxZ9F8rF7',
      ); // soundtrack album with no artist info
      expect(album['artists'], isNull);
      expect(album['audioPlaylistId'], isNotNull);
      expect(album['tracks'].length, equals(11));
    });

    test('get album other versions', () {
      // TODO requires authentication - add tests when implemented
      expect(true, isTrue, skip: true);
    });

    test('get song', () async {
      // TODO private upload requires authentication
      expect(true, isTrue, skip: true);
      final song = await yt.getSong(sampleVideo);
      expect(
        song['streamingData']['adaptiveFormats'].length,
        greaterThanOrEqualTo(10),
      );
    });

    test('get song related content', () {
      // TODO requires authentication - add tests when implemented
      expect(true, isTrue, skip: true);
    });

    test('get lyrics', () async {
      final playlist = await yt.getWatchPlaylist(videoId: sampleVideo);
      // test normal lyrics
      final normalLyrics = await yt.getLyrics(playlist['lyrics'] as String);
      expect(normalLyrics, isNotNull);
      expect(normalLyrics!['lyrics'], isA<String>());
      expect(normalLyrics['hasTimestamps'], isFalse);

      // test lyrics with timestamps
      final timestamped = await yt.getLyrics(
        playlist['lyrics'] as String,
        timestamps: true,
      );
      expect(timestamped, isNotNull);
      expect(timestamped!['lyrics'].length, greaterThanOrEqualTo(1));
      expect(timestamped['hasTimestamps'], isTrue);

      // check the LyricLine object
      final line = timestamped['lyrics'][0];
      expect(line, isA<LyricLine>());
      expect(line.text, isA<String>());
      expect(line.startTime <= line.endTime, isTrue);
      expect(line.id, isA<int>());
    });

    test('get signatureTimestamp', () async {
      final sig = await yt.getSignatureTimestamp();
      expect(sig, isNotNull);
    });

    test('set tasteprofile', () {
      // TODO requires brand account
      expect(true, isTrue, skip: true);
    });

    test('get tasteprofile', () {
      // TODO requires authentication - add tests when implemented
      expect(true, isTrue, skip: true);
    });

    test('get search suggestions', () async {
      final result = await yt.getSearchSuggestions('fade');
      expect(result.length, greaterThanOrEqualTo(0));

      final resultDetailed = await yt.getSearchSuggestions(
        'fade',
        detailedRuns: true,
      );
      expect(resultDetailed.length, greaterThanOrEqualTo(0));

      // TODO requires brand account
      expect(true, isTrue, skip: true);

      // TODO requires authentication - add tests when implemented
      expect(true, isTrue, skip: true);
    });
  });
}
