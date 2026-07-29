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
  OFFICIAL_SOURCE_MUSIC('MUSIC_VIDEO_TYPE_OFFICIAL_SOURCE_MUSIC'),

  /// Podcast Episode Music Video
  MUSIC_VIDEO_TYPE_PODCAST_EPISODE('MUSIC_VIDEO_TYPE_PODCAST_EPISODE');

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

/// Playlist sort order.
enum PlaylistSortOrder {
  /// MANUAL
  MANUAL(0),

  /// NEWEST_FIRST
  NEWEST_FIRST(1),

  /// NEWEST_LAST
  NEWEST_LAST(2),

  /// TOP_VOTED
  TOP_VOTED(6);

  /// Raw value.
  final int value;

  const PlaylistSortOrder(this.value);

  /// Parses [PlaylistSortOrder] from a raw [value].
  static PlaylistSortOrder? fromValue(int? value) {
    if (value == null) return null;
    return PlaylistSortOrder.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw FormatException('Invalid value: $value'),
    );
  }
}

/// Vote status.
enum VoteStatus {
  /// UPVOTED
  UPVOTED('VOTE_STATUS_UPVOTED'),

  /// DOWNVOTED
  DOWNVOTED('VOTE_STATUS_DOWNVOTED'),

  /// UNSPECIFIED
  UNSPECIFIED('VOTE_STATUS_UNSPECIFIED');

  /// Raw value.
  final String value;

  const VoteStatus(this.value);

  /// Parses [VoteStatus] from a raw [value].
  static VoteStatus? fromValue(String? value) {
    if (value == null) return null;
    return VoteStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw FormatException('Invalid value: $value'),
    );
  }
}

/// Playlist vote edit options.
enum PlaylistVoteEditOptions {
  /// EVERYONE_CAN_VOTE
  EVERYONE_CAN_VOTE('EVERYONE_CAN_VOTE'),

  /// COLLABORATORS_ONLY
  /// Only available for playlists where [collaborate] is on.
  COLLABORATORS_ONLY('COLLABORATORS_ONLY'),

  /// OFF
  OFF('OFF');

  /// Raw value.
  final String value;

  const PlaylistVoteEditOptions(this.value);

  /// Parses [PlaylistVoteEditOptions] from a raw [value].
  static PlaylistVoteEditOptions? fromValue(String? value) {
    if (value == null) return null;
    return PlaylistVoteEditOptions.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw FormatException('Invalid value: $value'),
    );
  }

  /// Get the request argument for the option
  int getArgumentForRequest() {
    switch (this) {
      case EVERYONE_CAN_VOTE:
        return 1;
      case COLLABORATORS_ONLY:
        return 2;
      case OFF:
        return 3;
    }
  }
}
