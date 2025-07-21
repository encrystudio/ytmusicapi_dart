import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import 'constants.dart';
import 'utils/case_insensitive_map.dart';

CaseInsensitiveMap<String> initializeHeaders() {
  return CaseInsensitiveMap<String>({
    'user-agent': userAgent,
    'accept': '*/*',
    'accept-encoding': 'gzip, deflate',
    'content-type': 'application/json',
    'content-encoding': 'gzip',
    'origin': ytmDomain,
  });
}

Map<String, dynamic> initializeContext() {
  final String date = DateFormat('yyyyMMdd').format(DateTime.now().toUtc());
  return {
    'context': {
      'client': {'clientName': 'WEB_REMIX', 'clientVersion': '1.$date.01.00'},
      'user': {},
    },
  };
}

Future<String> getVisitorId(
  Future<Response> Function(
    String url,
    Map<String, dynamic>? params, {
    bool useBaseHeaders,
  })
  requestFunc,
) async {
  final response = await requestFunc(ytmDomain, null, useBaseHeaders: true);

  final regex = RegExp(r'ytcfg\.set\s*\(\s*({.+?})\s*\)\s*;');
  final matches = regex.allMatches(response.data);

  String visitorId = '';

  if (matches.isNotEmpty) {
    final jsonString = matches.first.group(1);
    if (jsonString != null) {
      final ytcfg = json.decode(jsonString);
      visitorId = ytcfg['VISITOR_DATA'] ?? '';
    }
  }

  return visitorId;
}

int toInt(String str) {
  String numberString = str.replaceAll(RegExp(r'\D'), '');
  numberString = numberString.replaceAll(',', '');
  return int.parse(numberString);
}
