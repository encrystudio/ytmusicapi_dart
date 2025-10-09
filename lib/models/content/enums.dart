/// Privacy status of an item.
enum PrivacyStatus {
  /// Public on YouTube.
  PUBLIC('PUBLIC'),

  /// Private on YouTube.
  PRIVATE('PRIVATE'),

  /// Unlisted on YouTube.
  UNLISTED('UNLISTED');

  /// Raw value.
  final String value;

  const PrivacyStatus(this.value);

  /// Parses [PrivacyStatus] from a raw [value].
  static PrivacyStatus? fromValue(String? value) {
    if (value == null) return null;
    return PrivacyStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw FormatException('Invalid value: $value'),
    );
  }
}

/// Like status of an item.
enum LikeStatus {
  /// Liked on YouTube.
  LIKE('LIKE'),

  /// Disliked on YouTube.
  DISLIKE('DISLIKE'),

  /// Indifferent on YouTube.
  INDIFFERENT('INDIFFERENT');

  /// Raw value.
  final String value;

  const LikeStatus(this.value);

  /// Parses [LikeStatus] from a raw [value].
  static LikeStatus fromValue(String? value) {
    if (value == null) return LikeStatus.INDIFFERENT;
    return LikeStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw FormatException('Invalid value: $value'),
    );
  }
}

/// Video Type on YouTube.
enum VideoType {
  /// OMV Music Video.
  OMV('MUSIC_VIDEO_TYPE_OMV'),

  /// UGC Music Video.
  UGC('MUSIC_VIDEO_TYPE_UGC'),

  /// ATV Music Video.
  ATV('MUSIC_VIDEO_TYPE_ATV'),

  /// Official Source Music Video.
  OFFICIAL_SOURCE_MUSIC('MUSIC_VIDEO_TYPE_OFFICIAL_SOURCE_MUSIC');

  /// Raw value.
  final String value;

  const VideoType(this.value);

  /// Parses [VideoType] from a raw [value].
  static VideoType? fromValue(String? value) {
    if (value == null) return null;
    return VideoType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw FormatException('Invalid value: $value'),
    );
  }
}
