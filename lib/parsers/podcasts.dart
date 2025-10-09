import 'dart:collection';

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
JsonMap parseEpisode(JsonMap data) {
  final JsonMap realData;
  if (data.containsKey(MMRIR)) {
    realData = nav(data, [MMRIR]) as JsonMap;
  } else {
    realData = data;
  }
  final thumbnails = nav(realData, THUMBNAILS);
  final date = nav(realData, SUBTITLE, nullIfAbsent: true);
  final duration = nav(realData, [
    'playbackProgress',
    ...PROGRESS_RENDERER,
    ...DURATION_TEXT,
  ], nullIfAbsent: true);
  final title = nav(realData, TITLE_TEXT);
  final description = nav(realData, DESCRIPTION, nullIfAbsent: true);
  final videoId = nav(realData, [
    'onTap',
    ...WATCH_VIDEO_ID,
  ], nullIfAbsent: true);
  final browseId = nav(realData, [
    ...TITLE,
    ...NAVIGATION_BROWSE_ID,
  ], nullIfAbsent: true);
  final videoType = nav(realData, [
    'onTap',
    ...NAVIGATION_VIDEO_TYPE,
  ], nullIfAbsent: true);
  final index = nav(realData, [
    'onTap',
    'watchEndpoint',
    'index',
  ], nullIfAbsent: true);

  return {
    'index': index,
    'title': title,
    'description': description,
    'duration': duration,
    'videoId': videoId,
    'browseId': browseId,
    'videoType': videoType,
    'date': date,
    'thumbnails': thumbnails,
  };
}

/// Parses podcast from [data].
JsonMap parsePodcast(JsonMap data) {
  final JsonMap realData;
  if (data.containsKey(MTRIR)) {
    realData = nav(data, [MTRIR]) as JsonMap;
  } else {
    realData = data;
  }
  return {
    'title': nav(realData, TITLE_TEXT),
    'channel': parseIdName(
      nav(realData, [...SUBTITLE_RUNS, 0], nullIfAbsent: true) as JsonMap?,
    ),
    'browseId': nav(realData, [...TITLE, ...NAVIGATION_BROWSE_ID]),
    'podcastId': nav(realData, THUMBNAIL_OVERLAY, nullIfAbsent: true),
    'thumbnails': nav(realData, THUMBNAIL_RENDERER),
  };
}
