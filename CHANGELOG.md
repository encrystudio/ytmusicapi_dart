# Changelog

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
