// ignore_for_file: public_member_api_docs

import 'package:ytmusicapi_dart/enums.dart';
import 'package:ytmusicapi_dart/models/content/enums.dart';
import 'package:ytmusicapi_dart/models/objects/base.dart';

class YtVideo extends YtBaseObject {
  String? playlistId;
  VideoType? videoType;
  String? views;
  String? durationRaw;
  Duration? duration;
  List<YtBaseObject> artists;
  YtThumbnails? thumbnails;
  int? year;
  bool? isAvailable;
  bool? isEpisode;
  bool? isSong;

  // Only if song
  YtBaseObject? album;
  int? trackNumber;
  bool? isExplicit;
  bool? inLibrary;
  String? feedbackTokenAdd;
  String? feedbackTokenRemove;
  // Only if episode
  String? description;

  YtVideo({
    required super.name,
    required super.id,
    required this.playlistId,
    required this.videoType,
    required this.views,
    required this.durationRaw,
    required this.duration,
    required this.artists,
    required this.thumbnails,
    required this.year,
    required this.isAvailable,
    required this.isEpisode,
    required this.isSong,
    required this.album,
    required this.trackNumber,
    required this.isExplicit,
    required this.inLibrary,
    required this.feedbackTokenAdd,
    required this.feedbackTokenRemove,
    required this.description,
  }) : super(type: YtObjectType.VIDEO);

  @override
  Map<String, dynamic> asJson() => {
    ...super.asJson(),
    'playlistId': playlistId,
    'videoType': videoType?.name,
    'views': views,
    'durationRaw': durationRaw,
    'duration': duration?.inMilliseconds,
    'artists': artists.map((a) => a.asJson()).toList(),
    'thumbnails': thumbnails?.asJson(),
    'year': year,
    'isAvailable': isAvailable,
    'isEpisode': isEpisode,
    'isSong': isSong,
    'album': album?.asJson(),
    'trackNumber': trackNumber,
    'isExplicit': isExplicit,
    'inLibrary': inLibrary,
    'feedbackTokenAdd': feedbackTokenAdd,
    'feedbackTokenRemove': feedbackTokenRemove,
    'description': description,
  };

  @override
  String toString() =>
      'YtVideo('
      'name: $name, '
      'id: $id, '
      'playlistId: $playlistId, '
      'videoType: $videoType, '
      'views: $views, '
      'durationRaw: $durationRaw, '
      'duration: $duration, '
      'artists: ${artists.map((a) => a.toString()).join(', ')}, '
      'thumbnails: $thumbnails, '
      'year: $year, '
      'isAvailable: $isAvailable, '
      'isEpisode: $isEpisode, '
      'isSong: $isSong, '
      'album: $album, '
      'trackNumber: $trackNumber, '
      'isExplicit: $isExplicit, '
      'inLibrary: $inLibrary, '
      'feedbackTokenAdd: $feedbackTokenAdd, '
      'feedbackTokenRemove: $feedbackTokenRemove, '
      'description: $description'
      ')';
}
