// ignore_for_file: public_member_api_docs

enum ResponseStatus { SUCCEEDED }

extension ResponseStatusExtension on ResponseStatus {
  String get value {
    switch (this) {
      case ResponseStatus.SUCCEEDED:
        return 'STATUS_SUCCEEDED';
    }
  }
}

enum ArtistOrderType {
  recency('Recency'),

  popularity('Popularity'),

  alphabetical('Alphabetical order');

  final String value;

  const ArtistOrderType(this.value);
}

enum SearchFilterType {
  songs,

  videos,

  albums,

  artists,

  playlists,

  community_playlists,

  featured_playlists,

  uploads,

  profiles,

  podcasts,

  episodes,
}

enum YtAlbumType {
  SINGLE('Single'),

  EP('EP'),

  ALBUM('Album');

  final String name;

  const YtAlbumType(this.name);

  static YtAlbumType fromName(String name) {
    return YtAlbumType.values.firstWhere(
      (e) => e.name.toLowerCase() == name.toLowerCase(),
      orElse: () => throw FormatException('Invalid name: $name'),
    );
  }

  static YtAlbumType? tryFromName(String? name) {
    if (name == null) {
      return null;
    }
    try {
      return YtAlbumType.values.firstWhere(
        (e) => e.name.toLowerCase() == name.toLowerCase(),
        orElse: () => throw FormatException('Invalid name: $name'),
      );
    } catch (e) {
      return null;
    }
  }
}

enum YtPlaylistType {
  PLAYLIST('Playlists'),

  FEATURED_PLAYLIST('Featured playlists'),

  COMMUNITY_PLAYLIST('Community playlists'),

  EPISODES_PLAYLIST('Episodes playlist');

  final String name;

  const YtPlaylistType(this.name);

  static YtPlaylistType fromName(String name) {
    return YtPlaylistType.values.firstWhere(
      (e) => e.name == name,
      orElse: () {
        if (name == 'Top result') {
          return YtPlaylistType.PLAYLIST;
        }
        throw FormatException('Invalid name: $name');
      },
    );
  }
}

enum YtObjectType {
  ALBUM,
  ARTIST,
  BROWSED_ARTIST,
  VIDEO,
  PLAYLIST,
  EPISODE,
  PODCAST,
  OBJECT,
}

enum YtResultType {
  SINGLE('single'),
  EP('ep'),
  ALBUM('album'),
  ARTIST('artist'),
  PLAYLIST('playlist'),
  SONG('song'),
  VIDEO('video'),
  STATION('station'),
  PROFILE('profile'),
  PODCAST('podcast'),
  EPISODE('episode');

  final String name;

  const YtResultType(this.name);

  static YtResultType fromName(String name) {
    return YtResultType.values.firstWhere(
      (e) => e.name == name.toLowerCase(),
      orElse: () {
        throw FormatException('Invalid name: $name');
      },
    );
  }
}

enum SongRunsItemType {
  ALBUM,
  ARTISTS,
  VIEWS,
  DURATION_RAW,
  DURATION_SECONDS,
  YEAR,
}
