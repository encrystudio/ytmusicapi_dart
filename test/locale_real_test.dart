// ignore_for_file: avoid_dynamic_calls
import 'package:test/test.dart';
import 'package:ytmusicapi_dart/ytmusicapi_dart.dart';

void main() {
  group('locale test in real API queries', () {
    test('search returns results in different languages', () async {
      final languages = ['en', 'de', 'fr', 'es', 'it', 'ja', 'ko'];

      for (final lang in languages) {
        final yt = await YTMusic.create(language: lang);
        final results = await yt.search('music');

        expect(results.isNotEmpty, isTrue);
        expect(
          results.every(
            (r) => (r as Map<String, dynamic>).containsKey('resultType'),
          ),
          isTrue,
          reason: 'missing resultType for $lang',
        );

        yt.close();
      }
    });

    test('home loads in different languages', () async {
      final languages = ['en', 'de', 'fr'];

      for (final lang in languages) {
        final yt = await YTMusic.create(language: lang);
        final home = await yt.getHome();

        expect(home.isNotEmpty, isTrue);
        for (final section in home) {
          expect(section.containsKey('title'), isTrue);
          expect(section.containsKey('contents'), isTrue);
        }

        yt.close();
      }
    });

    test('search suggestions work in different languages', () async {
      final languages = ['en', 'es', 'fr'];

      for (final lang in languages) {
        final yt = await YTMusic.create(language: lang);
        final suggestions = await yt.getSearchSuggestions('test');

        expect(suggestions, isNotNull);
        expect(suggestions, isA<List>());

        yt.close();
      }
    });

    test('parser translations are consistent', () async {
      final languages = ['en', 'de', 'fr', 'es', 'it'];

      for (final lang in languages) {
        final yt = await YTMusic.create(language: lang);
        final types = yt.parser.getSearchResultTypes();

        expect(types.length, equals(9));
        expect(types, isNotEmpty);
        expect(types.every((t) => t.isNotEmpty), isTrue);

        yt.close();
      }
    });
  });
}
