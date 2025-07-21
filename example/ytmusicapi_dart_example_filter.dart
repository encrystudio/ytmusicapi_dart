import 'package:ytmusicapi_dart/ytmusicapi_dart.dart';

Future<void> main() async {
  final ytmusic = YTMusic();
  final results = await ytmusic.search('search term', filter: Filter.SONGS);
  print(results);
}
