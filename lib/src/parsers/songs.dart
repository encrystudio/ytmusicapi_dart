import '../navigation.dart';
import '_utils.dart';

Map<String, dynamic> parseSongRuns(List<dynamic> runs) {
  Map<String, dynamic> parsed = {'artists': []};
  for (var element in runs.indexed) {
    var i = element.$1;
    var run = element.$2;
    if (i.isOdd) {
      continue;
    }

    var text = run['text'];

    if (run.containsKey('navigationEndpoint')) {
      // artist or album
      var item = {
        'name': text,
        'id': nav(
          run,
          navigationBrowseId,
          nullIfAbsent: text != null && text.isNotEmpty,
        ),
      };

      if (item['id'] != null &&
          (item['id'].startsWith("MPRE") ||
              item['id'].contains('release_detail'))) {
        // album
        parsed['album'] = item;
      } else {
        // artist
        parsed['artists'].add(item);
      }
    } else {
      if (RegExp(r'^\d([^ ])* [^ ]*$').hasMatch(text) && (i > 0)) {
        parsed['views'] = text.split(" ")[0];
      } else if (RegExp(r'^(\d+:)*\d+:\d+$').hasMatch(text)) {
        parsed['duration'] = text;
        parsed['duration_seconds'] = parseDuration(text);
      } else if (RegExp(r'^\d{4}$').hasMatch(text)) {
        parsed['year'] = text;
      } else {
        // artist without id
        parsed['artists'].add({'name': text, 'id': null});
      }
    }
  }

  return parsed;
}

List<Map<String, dynamic>> parseSongArtistsRuns(
  List<Map<String, dynamic>> runs,
) {
  List<Map<String, dynamic>> artists = [];

  for (var j = 0; j <= (runs.length ~/ 2); j++) {
    artists.add({
      'name': runs[j * 2]['text'],
      'id': nav(runs[j * 2], navigationBrowseId, nullIfAbsent: true),
    });
  }
  return artists;
}

bool parseSongLibraryStatus(Map<String, dynamic> item) {
  var libraryStatus = nav(item, [
    toggleMenu,
    'defaultIcon',
    'iconType',
  ], nullIfAbsent: true);

  return libraryStatus == 'LIBRARY_SAVED';
}

Map<String, String?> parseSongMenuTokens(Map<String, dynamic> item) {
  var toggleMenu_ = item[toggleMenu];

  var libraryAddToken = nav(
    toggleMenu_,
    ['defaultServiceEndpoint'] + feedbackToken,
    nullIfAbsent: toggleMenu_ != null,
  );
  var libraryRemoveToken = nav(
    toggleMenu_,
    ['toggledServiceEndpoint'] + feedbackToken,
    nullIfAbsent: toggleMenu_ != null,
  );

  var inLibrary = parseSongLibraryStatus(item);

  if (inLibrary) {
    var tmp = libraryAddToken;
    libraryAddToken = libraryRemoveToken;
    libraryRemoveToken = tmp;
  }

  return {'add': libraryAddToken, 'remove': libraryRemoveToken};
}
