import 'package:ytmusicapi_dart/type_alias.dart';

/// Represents a line of lyrics with timestamps (in milliseconds).
class LyricLine {
  /// The song lyric text.
  final String text;

  /// Begin of the lyric in milliseconds.
  final int startTime;

  /// End of the lyric in milliseconds.
  final int endTime;

  /// A `Metadata-Id` that probably uniquely identifies each lyric line.
  final int id;

  /// Create new [LyricLine].
  LyricLine(this.text, this.startTime, this.endTime, this.id);

  /// Converts lyrics in the format from the api to a more reasonable format.
  ///
  /// - [rawLyric] The raw lyric-data returned by the mobile api.
  ///
  /// Returns [LyricLine].
  factory LyricLine.fromRaw(JsonMap rawLyric) {
    final text = rawLyric['lyricLine'] as String;
    final cueRange = rawLyric['cueRange'] as JsonMap;
    final startTime = int.parse(cueRange['startTimeMilliseconds'].toString());
    final endTime = int.parse(cueRange['endTimeMilliseconds'].toString());
    final id = int.parse((cueRange['metadata'] as JsonMap)['id'].toString());
    return LyricLine(text, startTime, endTime, id);
  }
}

/// Basic lyrics.
class Lyrics {
  /// The song lyric text.
  final String lyrics;

  /// THe source of the lyrics.
  final String? source;

  /// Wether this has timestamps.
  final bool hasTimestamps;

  /// Create new [Lyrics].
  Lyrics(this.lyrics, this.source, this.hasTimestamps);

  /// Returns this [Lyrics] instance as [JsonMap].
  JsonMap toJson() => {
    'lyrics': lyrics,
    if (source != null) 'source': source,
    'hasTimestamps': false,
  };
}

/// Basic lyrics with timestamps.
class TimedLyrics {
  /// The song lyric text.
  final List<LyricLine> lyrics;

  /// THe source of the lyrics.
  final String? source;

  /// Wether this has timestamps.
  final bool hasTimestamps;

  /// Create new [TimedLyrics].
  TimedLyrics(this.lyrics, this.source, this.hasTimestamps);

  /// Returns this [TimedLyrics] instance as [JsonMap].
  JsonMap toJson() => {
    'lyrics': lyrics,
    if (source != null) 'source': source,
    'hasTimestamps': true,
  };
}
