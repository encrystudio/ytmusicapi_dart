// ignore_for_file: public_member_api_docs

import 'package:ytmusicapi_dart/models/objects/album.dart';
import 'package:ytmusicapi_dart/models/objects/artist.dart';
import 'package:ytmusicapi_dart/models/objects/playlist.dart';
import 'package:ytmusicapi_dart/models/objects/song.dart';
import 'package:ytmusicapi_dart/models/objects/video.dart';
import 'package:ytmusicapi_dart/type_alias.dart';

class YtBaseObject {
  final String? id;
  final String title;
  final YtObjectType type;

  YtBaseObject({required this.id, required this.title, required this.type});

  factory YtBaseObject.fromJson(JsonMap jsonData, String id, String title) {
    return YtBaseObject(
      id: jsonData[id] as String?,
      title: jsonData[title] as String,
      type: YtObjectType.OBJECT,
    );
  }

  @override
  String toString() => 'YtBaseObject(id: $id, title: $title, type: $type)';
}

class YtThumbnail {
  final String url;
  final int width;
  final int height;

  int get resolution => width * height;

  YtThumbnail({required this.url, required this.width, required this.height});

  @override
  String toString() =>
      'YtThumbnail(url: $url, width: $width, height: $height, resolution: $resolution)';
}

class YtThumbnailData {
  final List<YtThumbnail> thumbnails;

  YtThumbnailData({required List<YtThumbnail> thumbnails})
    : assert(thumbnails.isNotEmpty, 'Thumbnail list cannot be empty'),
      thumbnails = List.unmodifiable(
        List<YtThumbnail>.of(thumbnails)
          ..sort((a, b) => a.resolution.compareTo(b.resolution)),
      );

  YtThumbnail get lowRes => thumbnails.first;

  YtThumbnail get highRes => thumbnails.last;
  factory YtThumbnailData.fromJson(List<JsonMap> jsonData) {
    final thumbnails =
        jsonData
            .map(
              (thumb) => YtThumbnail(
                url: thumb['url'] as String,
                width: thumb['width'] as int,
                height: thumb['height'] as int,
              ),
            )
            .toList();

    return YtThumbnailData(thumbnails: thumbnails);
  }

  @override
  String toString() => 'YtThumbnailData(lowRes: $lowRes, highRes: $highRes)';
}

enum YtAlbumType {
  SINGLE('Single'),

  EP('EP'),

  ALBUM('Album');

  final String value;

  const YtAlbumType(this.value);

  static YtAlbumType fromValue(String value) {
    return YtAlbumType.values.firstWhere(
      (e) => e.value.toLowerCase() == value.toLowerCase(),
      orElse: () => throw FormatException('Invalid value: $value'),
    );
  }
}

enum YtPlaylistType {
  PLAYLIST('Playlists'),

  FEATURED_PLAYLIST('Featured playlists'),

  COMMUNITY_PLAYLIST('Community playlists');

  final String value;

  const YtPlaylistType(this.value);

  static YtPlaylistType fromValue(String value) {
    return YtPlaylistType.values.firstWhere(
      (e) => e.value == value,
      orElse: () {
        if (value == 'Top result') {
          return YtPlaylistType.PLAYLIST;
        }
        throw FormatException('Invalid value: $value');
      },
    );
  }
}

enum YtObjectType { ALBUM, ARTIST, SONG, VIDEO, PLAYLIST, OBJECT }

List<YtBaseObject> searchResultToDart(List<dynamic> results) {
  return results
      .where(
        (result) =>
            !['episode', 'podcast'].contains((result as JsonMap)['resultType']),
      )
      .map((result) {
        final resultType = (result as JsonMap)['resultType'];
        switch (resultType) {
          case 'album':
            return YtAlbum.fromJson(result);
          case 'artist':
            return YtArtist.fromJson(result);
          case 'playlist':
            return YtPlaylist.fromJson(result);
          case 'song':
            return YtSong.fromJson(result);
          case 'video':
            return YtVideo.fromJson(result);
          default:
            throw UnsupportedError('Unknown resultType: $resultType');
        }
      })
      .toList();
}
