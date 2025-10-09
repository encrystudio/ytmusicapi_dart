/// @docImport 'package:ytmusicapi_dart/mixins/browsing.dart';
library;

import 'dart:core';
import 'package:ytmusicapi_dart/exceptions.dart';
import 'package:ytmusicapi_dart/models/content/enums.dart';

/// Literal `a_to_z`, `z_to_a`, or `recently_added`.
typedef LibraryOrderType = String;

/// Returns endpoint according to [rating].
String prepareLikeEndpoint(dynamic rating) {
  if (rating == LikeStatus.LIKE) {
    return 'like/like';
  } else if (rating == LikeStatus.DISLIKE) {
    return 'like/dislike';
  } else if (rating == LikeStatus.INDIFFERENT) {
    return 'like/removelike';
  } else {
    final values = LikeStatus.values.map((e) => e.name).toList();
    throw YTMusicUserError('Invalid rating provided. Use one of $values.');
  }
}

/// Validate the provided [order], if any.
///
/// Throws [YTMusicUserError] if invalid.
void validateOrderParameter(LibraryOrderType? order) {
  final orders = ['a_to_z', 'z_to_a', 'recently_added'];
  if (order != null && !orders.contains(order)) {
    throw YTMusicUserError(
      "Invalid order provided. Please use one of the following orders or leave out the parameter: ${orders.join(', ')}",
    );
  }
}

/// Returns request params belonging to a specific sorting [order].
String prepareOrderParams(LibraryOrderType order) {
  final orders = ['a_to_z', 'z_to_a', 'recently_added'];
  // determine orderParams via `.contents.singleColumnBrowseResultsRenderer.tabs[0].tabRenderer.content.sectionListRenderer.contents[1].itemSectionRenderer.header.itemSectionTabbedHeaderRenderer.endItems[1].dropdownRenderer.entries[].dropdownItemRenderer.onSelectCommand.browseEndpoint.params` of `/youtubei/v1/browse` response
  final orderParams = ['ggMGKgQIARAA', 'ggMGKgQIARAB', 'ggMGKgQIABAB'];
  return orderParams[orders.indexOf(order)];
}

/// Sanitize tags from HTML.
///
/// - [htmlText] String containing html tags.
///
/// Returns String without < > characters.
String htmlToTxt(String htmlText) {
  final regExp = RegExp('<[^>]+>');
  return htmlText.replaceAll(regExp, '');
}

/// Returns the number of days since January 1, 1970.
///
/// Currently only used for the signature timestamp in [BrowsingMixin.getSong].
int getDatestamp() {
  final epoch = DateTime.fromMillisecondsSinceEpoch(0);
  final now = DateTime.now();
  return now.difference(epoch).inDays;
}

// TODO this might be wrong or incomplete, report issues
/// Decodes Unicode escapes.
String decodeEscapes(String input, {bool replaceQuot = false}) {
  String output = input;
  output = output.replaceAllMapped(RegExp(r'\\u([0-9a-fA-F]{4})'), (match) {
    final hexCode = match.group(1)!;
    final charCode = int.parse(hexCode, radix: 16);
    return String.fromCharCode(charCode);
  });

  output = output.replaceAllMapped(RegExp(r'\\x([0-9a-fA-F]{2})'), (match) {
    final hexCode = match.group(1)!;
    final charCode = int.parse(hexCode, radix: 16);
    return String.fromCharCode(charCode);
  });

  output = output.replaceAll(r'\\', r'\');
  output = output.replaceAll(r'\/', '/');
  output = output.replaceAll(r'\&', '&');
  if (replaceQuot) {
    output = output.replaceAll(r'\"', '"');
  }

  return output;
}
