// ignore_for_file: public_member_api_docs

import 'package:ytmusicapi_dart/enums.dart';
import 'package:ytmusicapi_dart/models/content/text_run.dart';
import 'package:ytmusicapi_dart/models/objects/album.dart';
import 'package:ytmusicapi_dart/models/objects/base.dart';
import 'package:ytmusicapi_dart/models/objects/video.dart';

class YtArtist extends YtBaseObject {
  // super.id is browseId
  String? shuffleId;
  String? radioId;
  YtThumbnails thumbnails;
  String? subscribers;

  YtArtist({
    required super.name,
    required super.id,
    required this.shuffleId,
    required this.radioId,
    required this.thumbnails,
    required this.subscribers,
  }) : super(type: YtObjectType.ARTIST);

  @override
  Map<String, dynamic> asJson() => {
    ...super.asJson(),
    'shuffleId': shuffleId,
    'radioId': radioId,
    'thumbnails': thumbnails.asJson(),
    'subscribers': subscribers,
  };

  @override
  String toString() =>
      'YtArtist('
      'name: $name, '
      'browseId: $id, '
      'shuffleId: $shuffleId, '
      'radioId: $radioId, '
      'thumbnails: $thumbnails, '
      'subscribers: $subscribers'
      ')';
}

class YtBrowsedArtist extends YtBaseObject {
  // super.id is browseId for subscribe only
  String? descriptionRaw;
  List<TextRun> descriptionRuns;
  String? views;
  String? shuffleId;
  String? radioId;
  String? subscribers;
  String? monthlyListeners;
  YtThumbnails? thumbnails;
  String? songsBrowseId;
  List<YtVideo> songsResults;
  String? albumsBrowseId;
  String? albumsParams;
  List<YtAlbum> albumsResults;
  String? singlesBrowseId;
  String? singlesParams;
  String? showsBrowseId;
  // TODO
  List<YtAlbum> singlesResults;
  String? videosBrowseId;
  List<YtVideo> videosResults;
  String? playlistsBrowseId;
  // TODO
  String? episodesBrowseId;
  // TODO
  String? podcastsBrowseId;
  // TODO
  String? relatedBrowseId;
  List<YtArtist> relatedResults;

  YtBrowsedArtist({
    required super.name,
    required super.id,
    required this.descriptionRaw,
    required this.descriptionRuns,
    required this.views,
    required this.shuffleId,
    required this.radioId,
    required this.subscribers,
    required this.monthlyListeners,
    required this.thumbnails,
    required this.songsBrowseId,
    required this.songsResults,
    required this.albumsBrowseId,
    required this.albumsParams,
    required this.albumsResults,
    required this.singlesBrowseId,
    required this.singlesParams,
    required this.singlesResults,
    required this.showsBrowseId,
    required this.videosBrowseId,
    required this.videosResults,
    required this.playlistsBrowseId,
    required this.episodesBrowseId,
    required this.podcastsBrowseId,
    required this.relatedBrowseId,
    required this.relatedResults,
  }) : super(type: YtObjectType.BROWSED_ARTIST);

  @override
  Map<String, dynamic> asJson() => {
    ...super.asJson(),
    'descriptionRaw': descriptionRaw,
    'descriptionRuns': descriptionRuns.map((r) => r.asJson()).toList(),
    'views': views,
    'shuffleId': shuffleId,
    'radioId': radioId,
    'subscribers': subscribers,
    'monthlyListeners': monthlyListeners,
    'thumbnails': thumbnails?.asJson(),
    'songsBrowseId': songsBrowseId,
    'songsResults': songsResults.map((v) => v.asJson()).toList(),
    'albumsBrowseId': albumsBrowseId,
    'albumsParams': albumsParams,
    'albumsResults': albumsResults.map((a) => a.asJson()).toList(),
    'singlesBrowseId': singlesBrowseId,
    'singlesParams': singlesParams,
    'singlesResults': singlesResults.map((a) => a.asJson()).toList(),
    'showsBrowseId': showsBrowseId,
    'videosBrowseId': videosBrowseId,
    'videosResults': videosResults.map((v) => v.asJson()).toList(),
    'playlistsBrowseId': playlistsBrowseId,
    'episodesBrowseId': episodesBrowseId,
    'podcastsBrowseId': podcastsBrowseId,
    'relatedBrowseId': relatedBrowseId,
    'relatedResults': relatedResults.map((a) => a.asJson()).toList(),
  };

  @override
  String toString() =>
      'YtBrowsedArtist('
      'name: $name, '
      'browseId: $id, '
      'descriptionRaw: $descriptionRaw, '
      'descriptionRuns: ${descriptionRuns.length} items, '
      'views: $views, '
      'shuffleId: $shuffleId, '
      'radioId: $radioId, '
      'subscribers: $subscribers, '
      'monthlyListeners: $monthlyListeners, '
      'thumbnails: $thumbnails, '
      'songsBrowseId: $songsBrowseId, '
      'songsResults: ${songsResults.length} items, '
      'albumsBrowseId: $albumsBrowseId, '
      'albumsParams: $albumsParams, '
      'albumsResults: ${albumsResults.length} items, '
      'singlesBrowseId: $singlesBrowseId, '
      'singlesParams: $singlesParams, '
      'singlesResults: ${singlesResults.length} items, '
      'showsBrowseId: $showsBrowseId, '
      'videosBrowseId: $videosBrowseId, '
      'videosResults: ${videosResults.length} items, '
      'playlistsBrowseId: $playlistsBrowseId, '
      'episodesBrowseId: $episodesBrowseId, '
      'podcastsBrowseId: $podcastsBrowseId, '
      'relatedBrowseId: $relatedBrowseId, '
      'relatedResults: ${relatedResults.length} items '
      ')';
}
