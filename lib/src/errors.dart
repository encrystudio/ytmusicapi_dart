class YTMusicUserError implements Exception {
  String message;
  YTMusicUserError(this.message);
}

class YTMusicServerError implements Exception {
  String message;
  YTMusicServerError(this.message);
}
