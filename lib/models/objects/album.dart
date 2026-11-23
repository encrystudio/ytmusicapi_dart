// ignore_for_file: public_member_api_docs

import 'package:ytmusicapi_dart/enums.dart';
import 'package:ytmusicapi_dart/models/content/enums.dart';
import 'package:ytmusicapi_dart/models/objects/base.dart';
import 'package:ytmusicapi_dart/models/objects/video.dart';

class YtAlbum extends YtBaseObject {
  // super.id is browseId
  String? playlistId;
  YtAlbumType? albumType;
  YtThumbnails thumbnails;
  List<YtBaseObject> artists;
  List<YtVideo> tracks;
  String? durationRaw;
  Duration? duration;
  bool? isExplicit;
  int? year;
  int? trackCount;
  String? description;
  LikeStatus? likeStatus;
  List<YtAlbum> relatedRecommendations;
  List<YtAlbum> otherVersions;

  YtAlbum({
    required super.name,
    required super.id,
    required this.playlistId,
    required this.albumType,
    required this.thumbnails,
    required this.artists,
    required this.tracks,
    required this.durationRaw,
    required this.duration,
    required this.isExplicit,
    required this.year,
    required this.trackCount,
    required this.description,
    required this.likeStatus,
    required this.relatedRecommendations,
    required this.otherVersions,
  }) : super(type: YtObjectType.ALBUM);

  @override
  Map<String, dynamic> asJson() => {
    ...super.asJson(),
    'playlistId': playlistId,
    'albumType': albumType?.name,
    'thumbnails': thumbnails.asJson(),
    'artists': artists.map((a) => a.asJson()).toList(),
    'tracks': tracks.map((t) => t.asJson()).toList(),
    'durationRaw': durationRaw,
    'duration': duration?.inMilliseconds,
    'isExplicit': isExplicit,
    'year': year,
    'trackCount': trackCount,
    'description': description,
    'likeStatus': likeStatus?.name,
    'relatedRecommendations':
        relatedRecommendations.map((a) => a.asJson()).toList(),
    'otherVersions': otherVersions.map((a) => a.asJson()).toList(),
  };

  @override
  String toString() =>
      'YtAlbum('
      'name: $name, '
      'browseId: $id, '
      'playlistId: $playlistId, '
      'albumType: $albumType '
      'thumbnails: $thumbnails, '
      'artists: ${artists.map((a) => a.toString()).join(', ')}, '
      'tracks: ${tracks.length} tracks, '
      'durationRaw: $durationRaw, '
      'duration: ${duration?.inSeconds ?? 'null '}s, '
      'isExplicit: $isExplicit, '
      'year: $year'
      'trackCount: $trackCount'
      'description: $description'
      'likeStatus: $likeStatus'
      'relatedRecommendations: ${relatedRecommendations.length} albums, '
      'otherVersions: ${otherVersions.length} albums, '
      ')';
}
