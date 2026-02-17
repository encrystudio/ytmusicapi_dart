<!-- markdownlint-disable MD024 -->

# Dart YTMusicAPI

_ytmusicapi_dart_ is a Dart library to send requests to the YouTube Music API. It emulates YouTube Music web client requests.

> [!IMPORTANT]
> Dart YTMusicAPI is currently in early development.
> It is not yet feature-complete and may be unstable.
> We highly recommend wrapping most API calls in a `try-catch` block to prevent unexpected crashes or runtime errors.

## Disclaimer

This project and its authors are **not affiliated with, endorsed by, or sponsored by YouTube, Google LLC, or any of their affiliates or subsidiaries**.
**YouTube, YouTube Music**, and all related trademarks, logos, and brand names are the property of their respective owners.

This library is provided **for educational and research purposes only**.
The authors and contributors **assume no responsibility or liability** for any misuse of this software, violation of YouTube’s Terms of Service, or any other damages or consequences arising from its use. **Use at your own risk**.

## Getting started

Add this to your pubspec.yaml file:

```yaml
dependencies:
  ytmusicapi_dart: ^2.0.0
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
  final ytmusic = await YTMusic.create();
  final results = await ytmusic.search('search term');
  print(results);
  ytmusic.close();
}
```

More examples can be found in the [example folder](/example/).

## Features

> [!WARNING]
> Some features require authentication, which is currently not tested.

| State            | Callable in code   | Has tests          | Passed all tests   | Stable             | Notes                                                |
| ---------------- | ------------------ | ------------------ | ------------------ | ------------------ | ---------------------------------------------------- |
| Stable           | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: | Tested enough to be considered stable                |
| Tested           | :white_check_mark: | :white_check_mark: | :white_check_mark: | :x:                | Ported and passed all available tests                |
| Available        | :white_check_mark: | :x:                | :x:                | :x:                | Partially ported, usage not recommended but possible |
| Missing Features | :x:                | :x:                | :x:                | :x:                | Not implemented yet                                  |

### Stable

No feature is considered stable enough yet.

### Tested

#### Browsing

- search (including all filters) and suggestions
- get artist information and releases (songs, videos, albums, singles, related artists)
- get user information (videos, playlists)
- get albums
- get watch playlists (next songs when you press play/radio/shuffle in YouTube Music)
- get song lyrics


#### Localization
- all supported languages

### Available

#### Browsing

- get user information (videos, playlists)

#### Exploring music

- get moods and genres playlists
- get latest charts (globally and per country)

#### Playlists

- create and delete playlists
- modify playlists: edit metadata, add/move/remove tracks
- get playlist contents
- get playlist suggestions

#### Podcasts

- get podcasts
- get episodes
- get channels
- get episodes playlists

#### Localization

- regions
- all supported language

### Missing Features

These features from [sigma67's ytmusicapi](https://github.com/sigma67/ytmusicapi) are not implemented yet (feel free to implement them and open a PR):

#### Library management

- get library contents: playlists, songs, artists, albums and subscriptions, podcasts, channels
- add/remove library content: rate songs, albums and playlists, subscribe/unsubscribe artists
- get and modify play history

#### Uploads

- upload songs and remove them again
- list uploaded songs, artists and albums

## Additional information

This package is highly inspired by and ported to Dart from [sigma67's ytmusicapi](https://github.com/sigma67/ytmusicapi), which is licensed under the MIT license, just like this package.
For additional information, check [the repository](https://github.com/sigma67/ytmusicapi).
For now, this package is only a port of it so I will not add new features that are not part of [sigma67's ytmusicapi](https://github.com/sigma67/ytmusicapi).
If you want to help (I would appreciate it), implement more functionality from there or fix bugs listed in [the todo file](/TODO.md) or the _issues_ section and open a PR here.

Thanks to [sigma67](https://github.com/sigma67) for the great work!
