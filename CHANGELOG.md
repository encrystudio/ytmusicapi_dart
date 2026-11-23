# Changelog

## 3.0.0-rc.1

- Added `YtAlbumType`, `YtPlaylistType`, `YtObjectType`, `YtResultType`, and `SongRunsItemType` enums (including `fromName` / `tryFromName` helpers) in `lib/enums.dart`.
- Added `sumTotalDurationPlaylist` and `sumTotalDurationAlbum` helpers in `lib/helpers.dart` using typed `YtPlaylist` and `YtAlbum` models.
- **Breaking:** Typed continuation helpers (`getContinuations2025`, `getReloadableContinuations`, `getContinuations`, `getValidatedContinuations`, `getParsedContinuationItems`, `getContinuationContents`) with generic `<T>` and `FutureOr<List<T>> Function(List<JsonMap>)` callbacks in `lib/continuations.dart`.
- **Breaking:** Updated `BrowsingMixin` methods in `lib/mixins/browsing.dart` (`getHome`, `getArtist`, `getArtistAlbums`, `getUser`, `getUserPlaylists`, `getUserVideos`) to return strongly typed models (`YtNamedRow`, `YtBrowsedArtist`, `YtAlbum`, `YtPlaylist`, `YtVideo`) instead of untyped `List` or `JsonMap` structures.
- Replaced `sumTotalDuration` in `lib/helpers.dart` with `sumTotalDurationPlaylist` and `sumTotalDurationAlbum` reading `duration?.inSeconds` from typed track items.
- Updated `lib/auth/auth_parse.dart` to import `models/content/enums.dart` instead of `auth/types.dart`.
- Standardized list/header indexing in `lib/auth/browser.dart` and `lib/helpers.dart` to use `.first` where appropriate.
- Suppressed `public_member_api_docs` lints in `lib/enums.dart`.
- **Breaking:** Deleted `lib/auth/types.dart` and the `AuthType` enum.

## 2.4.1

- Removed `print` statement in `YtSong`

## 2.4.0

- Applied changes from [upstream](https://github.com/sigma67/ytmusicapi)
- Some names changed, please refer to the code for new names. Example:
- `SearchFilter` -> `SearchFilterType`

## 2.3.0

- Added `YtSong.isAvailable` and `YtVideo.isAvailable` fields to indicate if the content is currently available.
- Improved `id` parsing in `YtSong` and `YtVideo`; returns `null` instead of `''` when an ID is missing.
- These changes may break existing code that relied on empty strings for missing IDs or assumed all content is available.

## 2.2.8

- Fixed type cast in `getPlaylist()` for improved stability.

## 2.2.7

- Fixed type casts for improved stability.

## 2.2.6

- Added `isExplicit` parsing to `parseAlbums()`.

## 2.2.5

- Fixed issue where the `YtAlbum` Dart object would throw an error when the album JSON lacked an `artists` key. The parsing logic now defaults to an empty list.

## 2.2.4

- Fixed `title` field extraction in `parseAudioPlaylist()` to correctly handle cases where the tracks have no album.

## 2.2.3

- Removed `checkAuth()` call from `getPlaylist()`.
- Fixed playlist parsing logic to ensure more reliable extraction of playlist metadata and items.

## 2.2.2

- Added `audioPlaylistId` and `artists` fields to singles from channel content.

## 2.2.1

- Added `audioPlaylistId` as a valid JSON key for the `playlistId` property in the `YtAlbum` Dart object to improve compatibility with data parsed from the artist page `related` section.

## 2.2.0

- Improved parsing logic for `type` and `year` fields in album and single channel contents. The parsing is now more accurate and consistent, but the results may differ from previous versions and could potentially break existing implementations.

## 2.1.6

- Added `YtAlbumType.SINGLE`.

## 2.1.5

- Added possibility to pass `YtAlbumType` directly to a `YtAlbum` if it is already known, allowing more efficient construction.

## 2.1.4

- Added `title` as a valid JSON key for the `title` property in the `YtArtist` Dart object to improve compatibility with data parsed from the artist page `related` section.

## 2.1.3

- Made the `views` field of the `YtVideo` Dart object nullable to better handle cases where view counts may be unavailable or missing.

## 2.1.2

- Added support for `MUSIC_VIDEO_TYPE_PODCAST_EPISODE` as a possible `VideoType` in Dart objects.

## 2.1.1

- Added parsing support for `Top result` as a Dart object.
- Introduced the `isExplicit` field to songs and albums that appear as the `Top result`, enabling more accurate metadata handling.

## 2.1.0

- Replaced the search `filter` parameter from a String to an enum for improved type safety and clarity. Code that previously passed a raw string as the search `filter` will no longer compile. You must update your usage to the new `SearchFilter` enum.
- Added early-stage Dart classes for parsing and deserializing search-related JSON into strongly typed objects. These classes are still under active development and may change in future releases. They are not yet recommended for production use.

## 2.0.0

- This release is a full rewrite of the library. Many components have been ported from the original Python implementation, and the API and usage have been completely redesigned. Please note: Old APIs are no longer compatible. Refer to the updated README for details on the new structure, available features, and stable functionality.

## 1.1.0

- Fixed typo where instead of `thumbnails` it was `thumbnail` in the search results. If the field `thumbnail` was used in your code using **1.0.2** of this library, it will no longer work with **1.1.0** since this field does not exist anymore.

## 1.0.2

- Fix bug where in some cases the top search result cannot be parsed because of imprecise types.

## 1.0.1

- Longer description to get more pub points. No code changes.

## 1.0.0

- Initial version.
