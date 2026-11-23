// ignore_for_file: public_member_api_docs

import 'package:ytmusicapi_dart/enums.dart';
import 'package:ytmusicapi_dart/models/content/enums.dart';
import 'package:ytmusicapi_dart/models/objects/base.dart';
import 'package:ytmusicapi_dart/models/objects/video.dart';

class YtPlaylist extends YtBaseObject {
  // super.id is browseId
  YtPlaylistType? playlistType;
  List<YtBaseObject> authors;
  bool? owned;
  PrivacyStatus? privacy;
  YtThumbnails? thumbnails;
  String? description;
  String? durationRaw;
  Duration? duration;
  int? year;
  int? itemCount;
  int? views;
  List<YtVideo> items;
  List<YtPlaylist> related;
  List<YtVideo> suggestions;

  YtPlaylist({
    required super.name,
    required super.id,
    required this.playlistType,
    required this.authors,
    required this.owned,
    required this.privacy,
    required this.thumbnails,
    required this.description,
    required this.durationRaw,
    required this.duration,
    required this.year,
    required this.itemCount,
    required this.views,
    required this.items,
    required this.related,
    required this.suggestions,
  }) : super(type: YtObjectType.PLAYLIST);

  @override
  Map<String, dynamic> asJson() => {
    ...super.asJson(),
    'playlistType': playlistType?.name,
    'authors': authors.map((a) => a.asJson()).toList(),
    'owned': owned,
    'privacy': privacy?.name,
    'thumbnails': thumbnails?.asJson(),
    'description': description,
    'durationRaw': durationRaw,
    'duration': duration?.inMilliseconds,
    'year': year,
    'itemCount': itemCount,
    'views': views,
    'items': items.map((v) => v.asJson()).toList(),
    'related': related.map((p) => p.asJson()).toList(),
    'suggestions': suggestions.map((v) => v.asJson()).toList(),
  };

  @override
  String toString() =>
      'YtPlaylist('
      'name: $name, '
      'browseId: $id, '
      'playlistType: $playlistType '
      'authors: ${authors.map((a) => a.toString()).join(', ')}, '
      'owned: $owned, '
      'privacy: $privacy, '
      'thumbnails: $thumbnails, '
      'description: $description, '
      'durationRaw: $durationRaw, '
      'duration: ${duration?.inSeconds ?? 'null '}s, '
      'year: $year, '
      'itemCount: $itemCount, '
      'views: $views, '
      'items: ${items.length} items, '
      'related: ${related.length} related, '
      'suggestions: ${suggestions.length} suggested)';
}
