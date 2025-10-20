// ignore_for_file: public_member_api_docs

import 'package:ytmusicapi_dart/exceptions.dart';
import 'package:ytmusicapi_dart/models/objects/base.dart';
import 'package:ytmusicapi_dart/type_alias.dart';

class YtArtist extends YtBaseObject {
  final String? shuffleId;
  final String? radioId;
  final YtThumbnailData thumbnailData;

  YtArtist({
    required super.id,
    required super.title,
    required this.shuffleId,
    required this.radioId,
    required this.thumbnailData,
  }) : super(type: YtObjectType.ARTIST);

  factory YtArtist.fromJson(JsonMap jsonData) {
    if (jsonData['category'] == 'Top result') {
      throw YTMusicError('Top results cannot be parsed here.');
    }
    return YtArtist(
      id:
          jsonData['browseId'] as String? ??
          ((jsonData['artists'] as List)[0] as JsonMap)['id'] as String,
      title:
          jsonData['artist'] as String? ??
          ((jsonData['artists'] as List)[0] as JsonMap)['name'] as String,
      shuffleId: jsonData['shuffleId'] as String?,
      radioId: jsonData['radioId'] as String?,
      thumbnailData: YtThumbnailData.fromJson(
        List<JsonMap>.from(jsonData['thumbnails'] as List),
      ),
    );
  }

  @override
  String toString() =>
      'YtArtist('
      'id: $id, '
      'title: $title, '
      'shuffleId: $shuffleId, '
      'radioId: $radioId, '
      'thumbnailData: $thumbnailData'
      ')';
}
