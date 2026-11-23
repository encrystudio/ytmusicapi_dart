// ignore_for_file: public_member_api_docs

import 'package:ytmusicapi_dart/enums.dart';
import 'package:ytmusicapi_dart/models/content/enums.dart';
import 'package:ytmusicapi_dart/models/objects/base.dart';

/// Simple Tuple2 class for returning two values
class Tuple2<T1, T2> {
  final T1 item1;
  final T2 item2;
  Tuple2(this.item1, this.item2);
}

/// Simple Tuple3 class for returning three values
class Tuple3<T1, T2, T3> {
  final T1 item1;
  final T2 item2;
  final T3 item3;
  Tuple3(this.item1, this.item2, this.item3);
}

class YtNamedRow {
  final String? name;
  final List<YtBaseObject> contents;

  YtNamedRow({required this.name, required this.contents});

  Map<String, dynamic> asJson() => {
    'name': name,
    'contents': contents.map((c) => c.asJson()).toList(),
  };

  @override
  String toString() =>
      'YtNamedRow('
      'name: $name, '
      'contents: $contents)';
}

class PlaylistHeader {
  late PlaylistHeaderMeta meta;
  bool owned;
  PrivacyStatus privacy;
  YtThumbnails? thumbnails;
  String? description;
  int? year;

  PlaylistHeader({
    required this.owned,
    required this.privacy,
    required this.thumbnails,
    required this.description,
    required this.year,
  });
}

class PlaylistHeaderMeta {
  int? views;
  String? durationRaw;
  int? itemCount;
  String title;
  YtThumbnails thumbnails;
  List<YtBaseObject> authors;

  PlaylistHeaderMeta({
    required this.views,
    required this.durationRaw,
    required this.itemCount,
    required this.title,
    required this.thumbnails,
    required this.authors,
  });
}

class ChartRanking {
  final String? rank;
  final String? trend;

  ChartRanking({required this.rank, required this.trend});
}

class YtTopResult {
  YtSearchResult result;
  String? undercardsTitle;
  List<YtBaseObject> undercards;

  YtTopResult({
    required this.result,
    required this.undercardsTitle,
    required this.undercards,
  });
}

class YtSearchResult {
  late YtBaseObject result;
  YtResultType? type;
  String? category;

  YtSearchResult({required this.type, required this.category});
}

class MenuPlaylists {
  final String? shuffleId;
  final String? radioId;

  MenuPlaylists({required this.shuffleId, required this.radioId});
}

class SongMenuData {
  bool? inLibrary;
  bool? pinnedToListenAgain;
  String? listenAgainFeedbackTokenPin;
  String? listenAgainFeedbackTokenUnpin;
  String? feedbackTokenAdd;
  String? feedbackTokenRemove;
  String? feedbackToken;

  SongMenuData();
}

extension StringNumericExtension on String {
  bool isNumeric() => int.tryParse(this) != null;
}

extension StringAsciiExtension on String {
  bool get isAscii => codeUnits.every((c) => c <= 0x7F);
}
