<!-- markdownlint-disable MD024 -->

# Dart YTMusicAPI

_ytmusicapi_dart_ is a Dart library to send requests to the YouTube Music API. It emulates YouTube Music web client requests.

## Disclaimer

This library is not affiliated with, endorsed by or sponsored by YouTube Music. The authors are not responsible for any misuse of this library.

## Features

### Browsing

- search (with filters)

## Missing Features

These features from [sigma67's ytmusicapi](https://github.com/sigma67/ytmusicapi) are not yet implemented (feel free to implement them and open a PR):

### Browsing

- suggestions
- get artist information and releases (songs, videos, albums, singles, related artists)
- get user information (videos, playlists)
- get albums
- get song metadata
- get watch playlists (next songs when you press play/radio/shuffle in YouTube Music)
- get song lyrics

### Exploring music

- get moods and genres playlists
- get latest charts (globally and per country)

### Library management

- get library contents: playlists, songs, artists, albums and subscriptions, podcasts, channels
- add/remove library content: rate songs, albums and playlists, subscribe/unsubscribe artists
- get and modify play history

### Playlists

- create and delete playlists
- modify playlists: edit metadata, add/move/remove tracks
- get playlist contents
- get playlist suggestions

### Podcasts

- get podcasts
- get episodes
- get channels
- get episodes playlists

### Uploads

- upload songs and remove them again
- list uploaded songs, artists and albums

### Localization

- regions
- languages

## Getting started

Add this to your pubspec.yaml file:

```yaml
dependencies:
  ytmusicapi_dart: ^1.0.0
```

Or run this command:

```sh
dart pub add ytmusicapi_dart
```

It is possible that YouTube restricts the access to the API after some time. If that happens, you will get an error message. Try again later.

## Usage

```dart
import 'package:ytmusicapi_dart/ytmusicapi_dart.dart';

Future<void> main() async {
  final ytmusic = YTMusic();
  final results = await ytmusic.search('search term');
  print(results);
}
```

More examples can be found in the [example folder](/example/).

## Additional information

This package is highly inspired by [sigma67's ytmusicapi](https://github.com/sigma67/ytmusicapi), which licensed under MIT license, just like this package.
For additional information, check its repository.
For now, this package is only a port of it so I will not add new features that are not part of [sigma67's ytmusicapi](https://github.com/sigma67/ytmusicapi).
If you want to help (I would appreciate it), implement more functionality from there or fix bugs listed in [the todo file](/TODO.md) or the _issues_ section and open a PR here.

Thanks to [sigma67](https://github.com/sigma67) for the great work!
