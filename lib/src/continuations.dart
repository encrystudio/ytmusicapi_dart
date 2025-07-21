import 'package:ytmusicapi_dart/src/navigation.dart';

Future<List<dynamic>> getContinuations(
  Map<String, dynamic> results,
  String continuationType,
  int? limit,
  Future<Map<String, dynamic>> Function(String) requestFunc,
  List<dynamic> Function(List<Map<String, dynamic>>) parseFunc, {
  String cTokenPath = '',
  String? additionalParams,
}) async {
  List<dynamic> items = [];

  while (results.containsKey('continuations') &&
      (limit == null || items.length < limit)) {
    additionalParams =
        additionalParams ??
        getContinuationParams(results, cTokenPath: cTokenPath);
    var response = await requestFunc(additionalParams);
    if (results.containsKey('continuationContents')) {
      results = response['continuationContents'][continuationType];
    } else {
      break;
    }
    var contents = getContinuationContents(results, parseFunc);

    if (contents.isEmpty) {
      break;
    }
    items.addAll(contents);
  }
  return items;
}

List<dynamic> getContinuationContents(
  Map<String, dynamic> continuation,
  List<dynamic> Function(List<Map<String, dynamic>> p1) parseFunc,
) {
  for (var term in ['contents', 'items']) {
    if (continuation.containsKey(term)) {
      return parseFunc(continuation[term]);
    }
  }
  return [];
}

String getContinuationParams(
  Map<String, dynamic> results, {
  String cTokenPath = '',
}) {
  var cToken = nav(results, [
    'continuations',
    0,
    'next${cTokenPath}ContinuationData',
    'continuation',
  ]);
  return getContinuationString(cToken);
}

String getContinuationString(String cToken) {
  return '&ctoken=$cToken&continuation=$cToken';
}
