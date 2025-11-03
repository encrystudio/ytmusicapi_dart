// ignore_for_file: public_member_api_docs

import 'package:ytmusicapi_dart/models/content/enums.dart';
import 'package:ytmusicapi_dart/models/objects/base.dart';
import 'package:ytmusicapi_dart/type_alias.dart';

class YtVideo extends YtBaseObject {
  final VideoType? videoType;
  final String? durationRaw;
  final Duration? duration;
  final List<YtBaseObject> artists;
  final String? views;
  final YtThumbnailData thumbnailData;
  final int? year;
  final bool isAvailable;

  YtVideo({
    required this.videoType,
    required this.durationRaw,
    required this.duration,
    required this.artists,
    required this.views,
    required this.thumbnailData,
    required this.year,
    required this.isAvailable,
    required super.id,
    required super.title,
  }) : super(type: YtObjectType.VIDEO);

  factory YtVideo.fromJson(JsonMap jsonData) {
    final String? id = jsonData['videoId'] as String?;
    return YtVideo(
      thumbnailData: YtThumbnailData.fromJson(
        List<JsonMap>.from(jsonData['thumbnails'] as List),
      ),
      id: id,
      title: jsonData['title'] as String,
      videoType: VideoType.fromValue(jsonData['videoType'] as String?),
      durationRaw: jsonData['duration'] as String?,
      duration:
          jsonData['duration_seconds'] is int
              ? Duration(seconds: jsonData['duration_seconds'] as int)
              : null,
      artists:
          List<JsonMap>.from(jsonData['artists'] as List)
              .map((artist) => YtBaseObject.fromJson(artist, 'id', 'name'))
              .toList(),
      views: jsonData['views'] as String?,
      year:
          (jsonData['year'] is int)
              ? (jsonData['year'] as int)
              : ((jsonData['year'] is String)
                  ? (int.tryParse(jsonData['year'] as String))
                  : null),
      isAvailable:
          (jsonData['isAvailable'] as bool?) == null
              ? (id != null)
              : jsonData['isAvailable'] as bool && (id != null),
    );
  }

  @override
  String toString() =>
      'YtVideo('
      'id: $id, '
      'title: $title, '
      'videoType: $videoType, '
      'durationRaw: $durationRaw, '
      'duration: $duration, '
      'artists: $artists, '
      'views: $views, '
      'thumbnailData: $thumbnailData, '
      'year: $year'
      ')';
}
