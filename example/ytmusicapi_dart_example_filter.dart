// ignore_for_file: avoid_print

import 'package:ytmusicapi_dart/enums.dart';
import 'package:ytmusicapi_dart/ytmusicapi_dart.dart';

Future<void> main() async {
  final ytmusic = await YTMusic.create();
  final results = await ytmusic.search(
    'search term',
    filter: SearchFilter.songs,
  );
  print(results);
  ytmusic.close();
}
