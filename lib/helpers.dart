import 'dart:convert';
import 'dart:core';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:unorm_dart/unorm_dart.dart' as unorm;
import 'package:ytmusicapi_dart/constants.dart';
import 'package:ytmusicapi_dart/mixins/utils.dart';
import 'package:ytmusicapi_dart/models/content/text_run.dart';
import 'package:ytmusicapi_dart/models/objects/album.dart';
import 'package:ytmusicapi_dart/models/objects/playlist.dart';
import 'package:ytmusicapi_dart/navigation.dart';
import 'package:ytmusicapi_dart/type_alias.dart';

/// Returns initial request headers.
Map<String, String> initializeHeaders() {
  return {
    'user-agent': USER_AGENT,
    'accept': '*/*',
    'accept-encoding': 'gzip, deflate',
    'content-type': 'application/json',
    'content-encoding': 'gzip',
    'origin': YTM_DOMAIN,
  };
}

/// Returns initial context request headers.
JsonMap initializeContext() {
  final clientVersion =
      "1.${DateFormat('yyyyMMdd').format(DateTime.now().toUtc())}.01.00";
  return {
    'context': {
      'client': {'clientName': 'WEB_REMIX', 'clientVersion': clientVersion},
      'user': {},
    },
  };
}

/// Returns a `X-Goog-Visitor-Id`.
Future<Map<String, String>> getVisitorId(
  Future<Response> Function(String url) requestFunc,
) async {
  final response = await requestFunc(YTM_DOMAIN);
  final regex = RegExp(r'ytcfg\.set\s*\(\s*({.+?})\s*\)\s*;');
  final matches = regex.allMatches(decodeEscapes(response.data.toString()));
  String visitorId = '';
  if (matches.isNotEmpty) {
    final jsonStr = matches.first.group(1)!;
    final ytcfg = jsonDecode(jsonStr) as JsonMap;
    visitorId =
        (ytcfg['VISITOR_DATA'] ?? ytcfg['EOM_VISITOR_DATA'] ?? '') as String;
  }
  return {'X-Goog-Visitor-Id': visitorId};
}

/// Returns `SAPISID` from a given [rawCookie].
String sapisidFromCookie(String rawCookie) {
  final cookies = <String, String>{};
  for (final pair in rawCookie.replaceAll('"', '').split(';')) {
    final kv = pair.split('=');
    if (kv.length == 2) cookies[kv.first.trim()] = kv[1].trim();
  }
  return cookies['__Secure-3PAPISID'] ?? '';
}

// SAPISID Hash reverse engineered by
// https://stackoverflow.com/a/32065323/5726546
/// Returns `SAPISIDHASH` value based on headers and current time.
///
/// - [auth] `SAPISID` and origin value from headers concatenated with space.
String getAuthorization(String auth) {
  final unixTimestamp =
      (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
  final bytes = utf8.encode('$unixTimestamp $auth');
  final hash = sha1.convert(bytes).toString();
  return 'SAPISIDHASH ${unixTimestamp}_$hash';
}

/// Attempts to cast a String to an integer using locale or Dart int cast.
///
/// - [input] String that can be cast to an integer.
///
/// Returns int if string is a valid integer.
///
/// Throws [FormatException] if String is not a valid integer.
int toInt(String input, {String locale = 'en_US'}) {
  final String normalized = unorm.nfkd(input);

  String numberString = normalized.replaceAll(RegExp(r'\D'), '');

  if (numberString.isEmpty) {
    throw FormatException('Invalid integer string: $input');
  }

  try {
    final format = NumberFormat.decimalPattern(locale);
    return format.parse(numberString).toInt();
  } on FormatException {
    numberString = numberString.replaceAll(',', '');
    return int.parse(numberString);
  }
}

/// Returns sum of the [item] duration.
int sumTotalDurationPlaylist(YtPlaylist item) {
  final tracks = item.items;
  return tracks.fold<int>(0, (sum, track) {
    if (track is JsonMap) {
      return sum + (track.duration?.inSeconds ?? 0);
    }
    return sum;
  });
}

/// Returns sum of the [item] duration.
int sumTotalDurationAlbum(YtAlbum item) {
  final tracks = item.tracks;
  return tracks.fold<int>(0, (sum, track) {
    if (track is JsonMap) {
      return sum + (track.duration?.inSeconds ?? 0);
    }
    return sum;
  });
}

/// Parses a descriptionRuns section
(String, List<TextRun>) parseDescriptionRuns(dynamic descriptionRunsList) {
  if (descriptionRunsList is! List) {
    return ('', []);
  }

  final descriptionRuns = List<TextRun>.empty(growable: true);
  final description = StringBuffer();

  for (final run in List<Map<String, dynamic>>.from(descriptionRunsList)) {
    {
      description.write(run['text']);
      // hashtag runs carry a searchEndpoint instead of an urlEndpoint - treat them as plain text
      final link = nav(run, [
        'navigationEndpoint',
        'urlEndpoint',
        'url',
      ], nullIfAbsent: true);
      if (link != null) {
        descriptionRuns.add(
          HyperLink(text: run['text'] as String, url: link as String),
        );
      } else {
        descriptionRuns.add(PlainText(text: run['text'] as String));
      }
    }
  }
  return (description.toString(), descriptionRuns);
}
