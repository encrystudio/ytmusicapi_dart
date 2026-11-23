// ignore_for_file: public_member_api_docs

import 'package:ytmusicapi_dart/enums.dart';
import 'package:ytmusicapi_dart/type_alias.dart';

class YtBaseObject {
  String? id;
  String name;
  final YtObjectType type;

  YtBaseObject({required this.id, required this.name, required this.type});

  factory YtBaseObject.fromJson(
    JsonMap jsonData,
    String idKey,
    String nameKey,
  ) {
    return YtBaseObject(
      id: jsonData[idKey] as String?,
      name: jsonData[nameKey] as String,
      type: YtObjectType.OBJECT,
    );
  }

  Map<String, dynamic> asJson() => {'id': id, 'name': name, 'type': type.name};

  @override
  String toString() => 'YtBaseObject(id: $id, title: $name, type: $type)';
}

class YtThumbnail {
  final String url;
  final int width;
  final int height;

  int get resolution => width * height;

  YtThumbnail({required this.url, required this.width, required this.height});

  Map<String, dynamic> asJson() => {
    'url': url,
    'width': width,
    'height': height,
    'resolution': resolution,
  };

  @override
  String toString() =>
      'YtThumbnail(url: $url, width: $width, height: $height, resolution: $resolution)';
}

class YtThumbnails {
  final List<YtThumbnail> thumbnails;

  YtThumbnails({required List<YtThumbnail> thumbnails})
    : assert(thumbnails.isNotEmpty, 'Thumbnail list cannot be empty'),
      thumbnails = List.unmodifiable(
        List<YtThumbnail>.of(thumbnails)
          ..sort((a, b) => a.resolution.compareTo(b.resolution)),
      );

  YtThumbnail get lowRes => thumbnails.first;

  YtThumbnail get highRes => thumbnails.last;

  factory YtThumbnails.fromJson(List<JsonMap> jsonData) {
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
    assert(thumbnails.isNotEmpty, 'Thumbnail list cannot be empty');

    return YtThumbnails(thumbnails: thumbnails);
  }

  Map<String, dynamic> asJson() => {
    'thumbnails': thumbnails.map((t) => t.asJson()).toList(),
  };

  @override
  String toString() =>
      'YtThumbnailData(lowRes: $lowRes, highRes: $highRes, count: ${thumbnails.length})';
}
