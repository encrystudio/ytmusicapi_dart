// ignore_for_file: public_member_api_docs

import 'package:ytmusicapi_dart/models/objects/base.dart';
import 'package:ytmusicapi_dart/type_alias.dart';

class YtAlbum extends YtBaseObject {
  final List<YtBaseObject> artists;
  final Duration? duration;
  final bool? isExplicit;
  final String playlistId;
  final YtThumbnailData thumbnailData;
  final YtAlbumType albumType;
  final int? year;

  YtAlbum({
    required this.artists,
    required this.duration,
    required this.isExplicit,
    required this.playlistId,
    required this.thumbnailData,
    required this.albumType,
    required this.year,
    required super.id,
    required super.title,
  }) : super(type: YtObjectType.ALBUM);

  factory YtAlbum.fromJson(JsonMap jsonData, {YtAlbumType? type}) {
    return YtAlbum(
      thumbnailData: YtThumbnailData.fromJson(
        List<JsonMap>.from(jsonData['thumbnails'] as List),
      ),
      albumType:
          type ??
          YtAlbumType.fromValue(
            jsonData['type'] as String? ?? jsonData['resultType'] as String,
          ),
      id: jsonData['browseId'] as String,
      title: jsonData['title'] as String,
      artists:
          List<JsonMap>.from(jsonData['artists'] as List)
              .map((artist) => YtBaseObject.fromJson(artist, 'id', 'name'))
              .toList(),

      duration: jsonData['duration'] as Duration?,
      isExplicit: jsonData['isExplicit'] as bool?,
      playlistId:
          jsonData['playlistId'] as String? ??
          jsonData['audioPlaylistId'] as String,
      year:
          ((jsonData['year'] is String)
              ? (int.tryParse(jsonData['year'] as String))
              : (jsonData['year'] as int?)),
    );
  }

  @override
  String toString() =>
      'YtAlbum('
      'id: $id, '
      'title: $title, '
      'artists: ${artists.map((a) => a.toString()).join(', ')}, '
      'albumType: $albumType '
      'duration: ${duration?.inSeconds ?? "null"}s, '
      'isExplicit: $isExplicit, '
      'playlistId: $playlistId, '
      'thumbnailData: $thumbnailData, '
      'year: $year'
      ')';
}
