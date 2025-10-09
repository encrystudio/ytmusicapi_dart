import 'dart:convert';
import 'dart:io';
import 'dart:io' as io;

import 'package:ytmusicapi_dart/exceptions.dart';
import 'package:ytmusicapi_dart/helpers.dart';

/// Wether the [headers] are for browser.
bool isBrowser(Map<String, String> headers) {
  final browserStructure = {'authorization', 'cookie'};
  return browserStructure.every((key) => headers.containsKey(key));
}

/// Set up Browser authentication.
Future<String> setupBrowser({String? filepath, String? headersRaw}) async {
  List<String> contents = [];

  if (headersRaw == null) {
    final eof = io.Platform.isWindows ? "'Enter, Ctrl-Z, Enter'" : 'Ctrl-D';
    // ignore: avoid_print
    print(
      'Please paste the request headers from your browser and press $eof to continue:',
    );

    while (true) {
      try {
        final line = stdin.readLineSync();
        if (line == null) break;
        contents.add(line);
      } catch (_) {
        break;
      }
    }
  } else {
    contents = headersRaw.split('\n');
  }

  final Map<String, String> userHeaders = {};
  String chromeRememberedKey = '';

  try {
    for (final content in contents) {
      final header = content.split(': ');
      if (header[0].startsWith(':')) {
        // nothing was split or chromium headers
        continue;
      }
      if (header[0].endsWith(':')) {
        // weird new chrome "copy-paste in separate lines" format
        chromeRememberedKey = content.replaceAll(':', '');
      }
      if (header.length == 1) {
        if (chromeRememberedKey.isNotEmpty) {
          userHeaders[chromeRememberedKey] = header[0];
        }
        continue;
      }
      userHeaders[header[0].toLowerCase()] = header.sublist(1).join(': ');
    }
  } catch (e) {
    throw YTMusicError(
      'Error parsing your input, please try again. Full error: $e',
    );
  }

  final missingHeaders = {
    'cookie',
    'x-goog-authuser',
  }.difference(userHeaders.keys.map((k) => k.toLowerCase()).toSet());
  if (missingHeaders.isNotEmpty) {
    throw YTMusicUserError(
      'The following entries are missing in your headers: ${missingHeaders.join(', ')}. '
      'Please try a different request (such as /browse) and make sure you are logged in.',
    );
  }

  final ignoreHeaders = {'host', 'content-length', 'accept-encoding'};
  for (final key in List<String>.from(userHeaders.keys)) {
    if (key.startsWith('sec') || ignoreHeaders.contains(key)) {
      userHeaders.remove(key);
    }
  }

  final initHeaders = initializeHeaders();
  userHeaders.addAll(initHeaders);
  final headers = userHeaders;

  if (filepath != null) {
    final file = File(filepath);
    await file.writeAsString(
      const JsonEncoder.withIndent('    ').convert(headers),
    );
  }

  return jsonEncode(headers);
}
