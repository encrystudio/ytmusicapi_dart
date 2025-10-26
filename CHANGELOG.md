# Changelog

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
