/// Base error class.
/// Shall only be raised if none of the subclasses below are fitting.
class YTMusicError implements Exception {
  /// The message of this error.
  final String? message;

  /// Create new [YTMusicError].
  YTMusicError([this.message]);

  @override
  String toString() => message ?? 'YTMusicError';
}

/// Error caused by invalid usage of YTMusicAPI.
class YTMusicUserError extends YTMusicError {
  /// Create new [YTMusicUserError].
  YTMusicUserError([super.message]);

  @override
  String toString() => message ?? 'YTMusicUserError';
}

/// Error caused by the YouTube Music backend.
class YTMusicServerError extends YTMusicError {
  /// Create new [YTMusicServerError].
  YTMusicServerError([super.message]);

  @override
  String toString() => message ?? 'YTMusicServerError';
}
