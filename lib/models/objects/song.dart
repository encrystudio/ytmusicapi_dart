// ignore_for_file: public_member_api_docs

import 'package:ytmusicapi_dart/exceptions.dart';
import 'package:ytmusicapi_dart/models/content/enums.dart';
import 'package:ytmusicapi_dart/models/objects/base.dart';
import 'package:ytmusicapi_dart/type_alias.dart';

class YtSong extends YtBaseObject {
  final YtBaseObject? album;
  final bool inLibrary;
  final String? feedbackTokenAdd;
  final String? feedbackTokenRemove;
  final VideoType? videoType;
  final String? durationRaw;
  final Duration? duration;
  final List<YtBaseObject> artists;
  final String views;
  final bool isExplicit;
  final YtThumbnailData thumbnailData;
  final int? year;

  YtSong({
    required this.album,
    required this.inLibrary,
    required this.feedbackTokenAdd,
    required this.feedbackTokenRemove,
    required this.videoType,
    required this.durationRaw,
    required this.duration,
    required this.artists,
    required this.views,
    required this.isExplicit,
    required this.thumbnailData,
    required this.year,
    required super.id,
    required super.title,
  }) : super(type: YtObjectType.SONG);

  factory YtSong.fromJson(JsonMap jsonData) {
    if (jsonData['category'] == 'Top result') {
      throw YTMusicError('Top results cannot be parsed here.');
    }
    return YtSong(
      thumbnailData: YtThumbnailData.fromJson(
        List<JsonMap>.from(jsonData['thumbnails'] as List),
      ),
      id: jsonData['videoId'] as String,
      title: jsonData['title'] as String,
      album:
          jsonData['album'] is JsonMap
              ? YtBaseObject.fromJson(
                jsonData['album'] as JsonMap,
                'id',
                'name',
              )
              : null,
      inLibrary: jsonData['inLibrary'] as bool? ?? false,
      feedbackTokenAdd:
          (jsonData['feedbackTokens'] as JsonMap)['add'] as String?,
      feedbackTokenRemove:
          (jsonData['feedbackTokens'] as JsonMap)['remove'] as String?,
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
      views: jsonData['views'] as String,
      isExplicit: jsonData['isExplicit'] as bool,
      year:
          (jsonData['year'] is int)
              ? (jsonData['year'] as int)
              : ((jsonData['year'] is String)
                  ? (int.tryParse(jsonData['year'] as String))
                  : null),
    );
  }

  @override
  String toString() =>
      'YtSong('
      'id: $id, '
      'title: $title, '
      'album: $album, '
      'inLibrary: $inLibrary, '
      'feedbackTokenAdd: $feedbackTokenAdd, '
      'feedbackTokenRemove: $feedbackTokenRemove, '
      'videoType: $videoType, '
      'durationRaw: $durationRaw, '
      'duration: $duration, '
      'artists: $artists, '
      'views: $views, '
      'isExplicit: $isExplicit, '
      'thumbnailData: $thumbnailData, '
      'year: $year'
      ')';
}
