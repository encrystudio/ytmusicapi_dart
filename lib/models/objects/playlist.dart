// ignore_for_file: public_member_api_docs

import 'package:ytmusicapi_dart/models/objects/base.dart';
import 'package:ytmusicapi_dart/type_alias.dart';

class YtPlaylist extends YtBaseObject {
  final String author;
  final Duration? duration;
  final YtThumbnailData thumbnailData;
  final YtPlaylistType playlistType;
  final int? year;
  // TODO itemCount currently missing since parsing might be wrong

  YtPlaylist({
    required this.author,
    required this.duration,
    required this.thumbnailData,
    required this.playlistType,
    required this.year,
    required super.id,
    required super.title,
  }) : super(type: YtObjectType.PLAYLIST);

  factory YtPlaylist.fromJson(JsonMap jsonData) {
    return YtPlaylist(
      thumbnailData: YtThumbnailData.fromJson(
        List<JsonMap>.from(jsonData['thumbnails'] as List),
      ),
      playlistType: YtPlaylistType.fromValue(
        jsonData['category'] as String? ?? 'Playlists',
      ),
      id: jsonData['browseId'] as String? ?? jsonData['playlistId'] as String,
      title: jsonData['title'] as String,
      author:
          (jsonData['author'] is String)
              ? jsonData['author'] as String
              : (List<JsonMap>.from(jsonData['author'] as List)
                  .map(
                    (author) =>
                        YtBaseObject.fromJson(author, 'id', 'name').title,
                  )
                  .join(', ')),

      duration: jsonData['duration'] as Duration?,
      year:
          (jsonData['year'] as int?) ??
          ((jsonData['year'] is String)
              ? (int.tryParse(jsonData['year'] as String))
              : null),
    );
  }

  @override
  String toString() =>
      'YtPlaylist('
      'id: $id, '
      'title: $title, '
      'author: $author, '
      'playlistType: $playlistType '
      'duration: ${duration?.inSeconds ?? "null"}s, '
      'thumbnailData: $thumbnailData, '
      'year: $year'
      ')';
}
