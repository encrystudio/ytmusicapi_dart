import 'package:test/test.dart';
import 'package:ytmusicapi_dart/exceptions.dart';
import 'package:ytmusicapi_dart/locales/locales.dart';
import 'package:ytmusicapi_dart/parsers/i18n.dart';

void main() {
  group('Locale Tests', () {
    test(
      'LOCALES.from_lang returns correct locale for supported languages',
      () {
        expect(LOCALES.from_lang('en'), equals(LOCALES.LOCALE_EN));
        expect(LOCALES.from_lang('de'), equals(LOCALES.LOCALE_DE));
        expect(LOCALES.from_lang('fr'), equals(LOCALES.LOCALE_FR));
        expect(LOCALES.from_lang('es'), equals(LOCALES.LOCALE_ES));
        expect(LOCALES.from_lang('it'), equals(LOCALES.LOCALE_IT));
        expect(LOCALES.from_lang('ja'), equals(LOCALES.LOCALE_JA));
        expect(LOCALES.from_lang('ko'), equals(LOCALES.LOCALE_KO));
        expect(LOCALES.from_lang('zh_tw'), equals(LOCALES.LOCALE_ZH_TW));
        expect(LOCALES.from_lang('zh_cn'), equals(LOCALES.LOCALE_ZH_CN));
      },
    );

    test(
      'LOCALES.from_lang throws YTMusicUserError for unsupported language',
      () {
        expect(
          () => LOCALES.from_lang('unsupported'),
          throwsA(isA<YTMusicUserError>()),
        );
      },
    );

    test('Parser translates keys correctly for English locale', () {
      final parser = Parser('en');
      expect(parser.t('album'), equals('album'));
      expect(parser.t('artist'), equals('artist'));
      expect(parser.t('song'), equals('song'));
    });

    test('Parser translates English keys to German', () {
      final parser = Parser('de');
      expect(parser.t('album'), equals('album'));
      expect(parser.t('artist'), equals('künstler'));
      expect(parser.t('song'), equals('titel'));
    });

    test('Parser translates English keys to French', () {
      final parser = Parser('fr');
      expect(parser.t('album'), equals('album'));
      expect(parser.t('artist'), equals('artiste'));
      expect(parser.t('song'), equals('titre'));
        });

    test('Parser returns key if translation not found', () {
      final parser = Parser('en');
      expect(parser.t('nonexistent_key'), equals('nonexistent_key'));
    });

    test('Parser.getSearchResultTypes returns all types in English', () {
      final parser = Parser('en');
      final types = parser.getSearchResultTypes();
      expect(types, contains('album'));
      expect(types, contains('artist'));
      expect(types, contains('song'));
      expect(types, contains('playlist'));
      expect(types, contains('video'));
      expect(types.length, equals(9));
    });

    test('Parser.getApiResultTypes includes search types and single/ep', () {
      final parser = Parser('en');
      final types = parser.getApiResultTypes();
      expect(types, contains('single'));
      expect(types, contains('ep'));
      expect(types, contains('album'));
      expect(types.length, equals(11));
    });

    test('All locale enums have translations map', () {
      for (final locale in LOCALES.values) {
        expect(locale.translations, isNotEmpty);
        expect(locale.translations, isA<Map<String, String>>());
      }
    });

    test('LOCALE_EN has all required translation keys', () {
      final requiredKeys = [
        'album',
        'artist',
        'playlist',
        'song',
        'video',
        'station',
        'profile',
        'podcast',
        'episode',
        'single',
        'ep',
        'albums',
        'singles & eps',
        'shows',
        'videos',
        'playlists',
        'related',
        'episodes',
        'podcasts',
      ];
      for (final key in requiredKeys) {
        expect(LOCALES.LOCALE_EN.translations.containsKey(key), isTrue);
      }
    });
  });
}
