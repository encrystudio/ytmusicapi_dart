# Changelog

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
