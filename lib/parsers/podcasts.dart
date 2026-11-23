import 'dart:collection';

import 'package:ytmusicapi_dart/models/content/enums.dart';
import 'package:ytmusicapi_dart/models/objects/album.dart';
import 'package:ytmusicapi_dart/models/objects/base.dart';
import 'package:ytmusicapi_dart/models/objects/video.dart';
import 'package:ytmusicapi_dart/navigation.dart';
import 'package:ytmusicapi_dart/parsers/utils.dart';
import 'package:ytmusicapi_dart/type_alias.dart';

// ignore: public_member_api_docs
const PROGRESS_RENDERER = ['musicPlaybackProgressRenderer'];
// ignore: public_member_api_docs
const DURATION_TEXT = ['durationText', 'runs', 1, 'text'];

/// Base description element.
class DescriptionElement {
  /// Actual description value.
  final String text;

  /// Create new [DescriptionElement].
  DescriptionElement({required this.text});

  @override
  String toString() => text;
}

/// Description link.
class Link extends DescriptionElement {
  /// Link url.
  final String url;

  /// Create new [Link].
  Link({required super.text, required this.url});
}

/// Description timestamp.
class Timestamp extends DescriptionElement {
  /// Timestamp in seconds.
  final int seconds;

  /// Create new [Timestamp].
  Timestamp({required super.text, required this.seconds});
}

/// Full description.
class Description extends ListBase<DescriptionElement> {
  final List<DescriptionElement> _elements;

  /// Create new [Description].
  Description(List<DescriptionElement> elements) : _elements = elements;

  @override
  int get length => _elements.length;

  @override
  set length(int newLength) => _elements.length = newLength;

  @override
  DescriptionElement operator [](int index) => _elements[index];

  @override
  void operator []=(int index, DescriptionElement value) =>
      _elements[index] = value;

  /// Get text representation of this [Description].
  String get text => _elements.map((e) => e.toString()).join();

  /// Create [Description] from [descriptionRuns] List.
  factory Description.fromRuns(List<JsonMap> descriptionRuns) {
    final elements = <DescriptionElement>[];

    for (final run in descriptionRuns) {
      final navigationEndpoint = nav(run, [
        'navigationEndpoint',
      ], nullIfAbsent: true);
      DescriptionElement element;

      if (navigationEndpoint != null) {
        element = DescriptionElement(text: '');
        if ((navigationEndpoint as Map).containsKey('urlEndpoint')) {
          element = Link(
            text: run['text'] as String,
            url:
                (navigationEndpoint['urlEndpoint'] as JsonMap)['url'] as String,
          );
        } else if (navigationEndpoint.containsKey('watchEndpoint')) {
          element = Timestamp(
            text: run['text'] as String,
            seconds:
                nav(navigationEndpoint, ['watchEndpoint', 'startTimeSeconds'])
                    as int,
          );
        }
      } else {
        element = DescriptionElement(
          text: (nav(run, ['text'], nullIfAbsent: true) ?? '') as String,
        );
      }

      elements.add(element);
    }

    return Description(elements);
  }
}

/// Parses base header.
JsonMap parseBaseHeader(JsonMap header) {
  final strapline = nav(header, ['straplineTextOne']);

  final author = {
    'name': nav(strapline, [...RUN_TEXT], nullIfAbsent: true),
    'id': nav(strapline, [
      'runs',
      0,
      ...NAVIGATION_BROWSE_ID,
    ], nullIfAbsent: true),
  };

  return {
    'author': (author['name'] != null && author['name'] != '') ? author : null,
    'title': nav(header, TITLE_TEXT),
    'thumbnails': nav(header, THUMBNAILS),
  };
}

/// Parses podcast header.
JsonMap parsePodcastHeader(JsonMap header) {
  final metadata = parseBaseHeader(header);
  metadata['description'] = nav(header, [
    'description',
    ...DESCRIPTION_SHELF,
    ...DESCRIPTION,
  ], nullIfAbsent: true);
  metadata['saved'] = nav(header, ['buttons', 1, ...TOGGLED_BUTTON]);
  return metadata;
}

/// Parses episode header.
JsonMap parseEpisodeHeader(JsonMap header) {
  final metadata = parseBaseHeader(header);
  metadata['date'] = nav(header, [...SUBTITLE]);
  final progressRenderer = nav(header, ['progress', ...PROGRESS_RENDERER]);
  metadata['duration'] = nav(
    progressRenderer,
    DURATION_TEXT,
    nullIfAbsent: true,
  );
  metadata['progressPercentage'] = nav(progressRenderer, [
    'playbackProgressPercentage',
  ]);
  metadata['saved'] =
      nav(header, ['buttons', 0, ...TOGGLED_BUTTON], nullIfAbsent: true) ??
      false;

  metadata['playlistId'] = null;
  final menuButtons = nav(header, ['buttons', -1, 'menuRenderer', 'items']);
  for (final button in menuButtons as Iterable) {
    if (nav(button, [MNIR, ...ICON_TYPE], nullIfAbsent: true) == 'BROADCAST') {
      metadata['playlistId'] = nav(button, [MNIR, ...NAVIGATION_BROWSE_ID]);
    }
  }

  return metadata;
}

/// Parses episode from [data].
YtVideo parseEpisode(JsonMap data) {
  final JsonMap realData;
  if (data.containsKey(MMRIR)) {
    realData = nav(data, [MMRIR]) as JsonMap;
  } else {
    realData = data;
  }
  final thumbnails = YtThumbnails.fromJson(
    List<JsonMap>.from(nav(realData, THUMBNAILS) as List),
  );
  // TODO
  // final date = nav(realData, SUBTITLE, nullIfAbsent: true);
  final durationRaw =
      nav(realData, [
            'playbackProgress',
            ...PROGRESS_RENDERER,
            ...DURATION_TEXT,
          ], nullIfAbsent: true)
          as String?;
  final title = nav(realData, TITLE_TEXT) as String;
  final description = nav(realData, DESCRIPTION, nullIfAbsent: true) as String?;
  final videoId =
      nav(realData, ['onTap', ...WATCH_VIDEO_ID], nullIfAbsent: true)
          as String?;
  final browseId =
      nav(realData, [...TITLE, ...NAVIGATION_BROWSE_ID], nullIfAbsent: true)
          as String?;
  final videoType = VideoType.tryFromValue(
    nav(realData, ['onTap', ...NAVIGATION_VIDEO_TYPE], nullIfAbsent: true)
        as String?,
  );
  final index =
      nav(realData, ['onTap', 'watchEndpoint', 'index'], nullIfAbsent: true)
          as String? ??
      '';

  return YtVideo(
    name: title,
    id: videoId,
    playlistId: browseId,
    videoType: videoType,
    views: null,
    durationRaw: durationRaw,
    duration: null,
    artists: [],
    thumbnails: thumbnails,
    year: null,
    isAvailable: null,
    isEpisode: true,
    isSong: false,
    album: null,
    trackNumber: int.tryParse(index),
    isExplicit: null,
    inLibrary: null,
    feedbackTokenAdd: null,
    feedbackTokenRemove: null,
    description: description,
  );
}

/// Parses episode from [data]
YtVideo parseEpisodeFlat(JsonMap data) {
  return YtVideo(
    name: nav(getFlexColumnItem(data, 0), TEXT_RUN_TEXT) as String,
    id: nav(data, ['playlistItemData', 'videoId']) as String,
    playlistId:
        nav(data, [
              ...PLAY_BUTTON,
              'playNavigationEndpoint',
              ...WATCH_PLAYLIST_ID,
            ])
            as String,
    videoType: VideoType.tryFromValue(
      nav(data, [
            ...PLAY_BUTTON,
            'playNavigationEndpoint',
            ...NAVIGATION_VIDEO_TYPE,
          ])
          as String,
    ),
    views: null,
    durationRaw: null,
    duration: null,
    artists: [],
    thumbnails: YtThumbnails.fromJson(
      List<JsonMap>.from(nav(data, THUMBNAILS) as List),
    ),
    year: null,
    isAvailable: null,
    isEpisode: true,
    isSong: false,
    album: parseIdName(nav(getFlexColumnItem(data, 1), TEXT_RUN) as JsonMap),
    trackNumber: null,
    isExplicit: null,
    inLibrary: null,
    feedbackTokenAdd: null,
    feedbackTokenRemove: null,
    description: null,
  );
}

/// Parses podcast from [data].
YtAlbum parsePodcast(JsonMap data) {
  final JsonMap realData;
  if (data.containsKey(MTRIR)) {
    realData = nav(data, [MTRIR]) as JsonMap;
  } else {
    realData = data;
  }
  return YtAlbum(
    name: nav(realData, TITLE_TEXT) as String,
    id: nav(realData, THUMBNAIL_OVERLAY, nullIfAbsent: true) as String?,
    playlistId: nav(realData, [...TITLE, ...NAVIGATION_BROWSE_ID]) as String,
    albumType: null,
    thumbnails: YtThumbnails.fromJson(
      List<JsonMap>.from(nav(realData, THUMBNAIL_RENDERER) as List),
    ),
    artists: [
      parseIdName(
        nav(realData, [...SUBTITLE_RUNS, 0], nullIfAbsent: true) as JsonMap?,
      ),
    ],
    tracks: [],
    durationRaw: null,
    duration: null,
    isExplicit: null,
    year: null,
    trackCount: null,
    description: null,
    likeStatus: null,
    relatedRecommendations: [],
    otherVersions: [],
  );
}
