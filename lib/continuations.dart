import 'package:ytmusicapi_dart/navigation.dart';
import 'package:ytmusicapi_dart/type_alias.dart';

// ignore: public_member_api_docs
const List<String> CONTINUATION_TOKEN = [
  'continuationItemRenderer',
  'continuationEndpoint',
  'continuationCommand',
  'token',
];

// ignore: public_member_api_docs
const List CONTINUATION_ITEMS = [
  'onResponseReceivedActions',
  0,
  'appendContinuationItemsAction',
  'continuationItems',
];

/// Get the token used for continuations.
String? getContinuationToken(List results) {
  return nav(results.last, CONTINUATION_TOKEN, nullIfAbsent: true) as String?;
}

/// Get the continuations in the format of 2025.
Future<List> getContinuations2025(
  JsonMap results,
  int? limit,
  RequestFuncBodyType requestFunc,
  ParseFuncType parseFunc,
) async {
  final List items = [];
  String? continuationToken = getContinuationToken(results['contents'] as List);

  while (continuationToken != null && (limit == null || items.length < limit)) {
    final JsonMap response = await requestFunc({
      'continuation': continuationToken,
    });
    final continuationItems = nav(
      response,
      CONTINUATION_ITEMS,
      nullIfAbsent: true,
    );
    if (continuationItems == null) break;

    final contents = await parseFunc(
      List<JsonMap>.from(continuationItems as List),
    );
    if (contents.isEmpty) break;

    items.addAll(contents);
    continuationToken = getContinuationToken(continuationItems);
  }

  return items;
}

/// Reloadable continuations are a special case that only exists on the playlists page (suggestions).
Future<List> getReloadableContinuations(
  JsonMap results,
  String continuationType,
  int? limit,
  RequestFuncType requestFunc,
  ParseFuncType parseFunc,
) async {
  final additionalParams = getReloadableContinuationParams(results);
  return await getContinuations(
    results,
    continuationType,
    limit,
    requestFunc,
    parseFunc,
    additionalParams: additionalParams,
  );
}

/// Returns list of parsed continuation results.
///
/// - [results] Result List from request data.
/// - [continuationType] Type of continuation, determines which subkey will be
///                      used to navigate the continuation return data.
/// - [limit] Determines minimum of how many items to retrieve in total.
///           `null` to retrieve all items until no more continuations are returned.
/// - [requestFunc] The request function to use to get the continuations.
/// - [parseFunc] The parse function to apply on the returned continuations.
/// - [ctokenPath] Rarely used specifier applied to retrieve the
///                ctoken ("next&lt;ctoken_path&gt;ContinuationData"). (Default: empty String).
/// - [additionalParams] Optional additional params to pass to the [requestFunc].
///                      (Default: use [getContinuationParams]).
Future<List> getContinuations(
  JsonMap results,
  String continuationType,
  int? limit,
  RequestFuncType requestFunc,
  ParseFuncType parseFunc, {
  String ctokenPath = '',
  String? additionalParams,
}) async {
  final List items = [];
  JsonMap realResults = results;

  while (realResults.containsKey('continuations') &&
      (limit == null || items.length < limit)) {
    final params =
        additionalParams ?? getContinuationParams(realResults, ctokenPath);
    final JsonMap response = await requestFunc(params);
    if (response.containsKey('continuationContents') &&
        (response['continuationContents'] as JsonMap).containsKey(
          continuationType,
        )) {
      realResults =
          (response['continuationContents'] as JsonMap)[continuationType]
              as JsonMap;
    } else {
      break;
    }

    final contents = await getContinuationContents(realResults, parseFunc);
    if (contents.isEmpty) break;

    items.addAll(contents);
  }

  return items;
}

/// Returns validated continuations.
Future<List> getValidatedContinuations(
  JsonMap results,
  String continuationType,
  int limit,
  int perPage,
  RequestFuncType requestFunc,
  ParseFuncType parseFunc, {
  String ctokenPath = '',
}) async {
  final List items = [];
  JsonMap realResults = results;

  while (realResults.containsKey('continuations') && items.length < limit) {
    final additionalParams = getContinuationParams(realResults, ctokenPath);

    JsonMap wrappedParseFunc(JsonMap rawResponse) =>
        getParsedContinuationItems(rawResponse, parseFunc, continuationType);
    bool validateFunc(JsonMap parsed) =>
        validateResponse(parsed, perPage, limit, items.length);

    final response = await resendRequestUntilParsedResponseIsValid(
      requestFunc,
      additionalParams,
      wrappedParseFunc,
      validateFunc,
      3,
    );
    realResults = response['results'] as JsonMap;
    items.addAll(response['parsed'] as List);
  }

  return items;
}

/// Returns parsed continuation items.
JsonMap getParsedContinuationItems(
  JsonMap response,
  ParseFuncType parseFunc,
  String continuationType,
) {
  final results =
      (response['continuationContents'] as JsonMap)[continuationType]
          as JsonMap;
  return {
    'results': results,
    'parsed': getContinuationContents(results, parseFunc),
  };
}

/// Returns continuation params.
String getContinuationParams(JsonMap results, [String ctokenPath = '']) {
  final ctoken =
      nav(results, [
            'continuations',
            0,
            'next${ctokenPath}ContinuationData',
            'continuation',
          ])
          as String;
  return getContinuationString(ctoken);
}

/// Returns reloadable continuation params.
String getReloadableContinuationParams(JsonMap results) {
  final ctoken =
      nav(results, [
            'continuations',
            0,
            'reloadContinuationData',
            'continuation',
          ])
          as String;
  return getContinuationString(ctoken);
}

/// Returns the continuation string used in the continuation request.
///
/// - [ctoken] the unique continuation token.
String getContinuationString(String ctoken) =>
    '&ctoken=$ctoken&continuation=$ctoken';

/// Returns continuation contents.
Future<List> getContinuationContents(
  JsonMap continuation,
  ParseFuncType parseFunc,
) async {
  for (final term in ['contents', 'items']) {
    if (continuation.containsKey(term)) {
      return await parseFunc(List<JsonMap>.from(continuation[term] as List));
    }
  }
  return [];
}

/// Resends the [requestFunc] until the [validateFunc] returns `true`.
///
/// - [maxRetries] How often to resend.
Future<JsonMap> resendRequestUntilParsedResponseIsValid(
  RequestFuncType requestFunc,
  String requestAdditionalParams,
  ParseFuncMapType parseFunc,
  bool Function(JsonMap) validateFunc,
  int maxRetries,
) async {
  JsonMap response = await requestFunc(requestAdditionalParams);
  JsonMap parsedObject = await parseFunc(response);
  int retryCounter = 0;

  while (!validateFunc(parsedObject) && retryCounter < maxRetries) {
    response = await requestFunc(requestAdditionalParams);
    final attempt = await parseFunc(response);
    if ((attempt['parsed'] as List).length >
        (parsedObject['parsed'] as List).length) {
      parsedObject = attempt;
    }
    retryCounter += 1;
  }

  return parsedObject;
}

/// Validate [response].
bool validateResponse(
  JsonMap response,
  int perPage,
  int limit,
  int currentCount,
) {
  final remainingItemsCount = limit - currentCount;
  final expectedItemsCount =
      remainingItemsCount < perPage ? remainingItemsCount : perPage;

  // response is invalid, if it has less items then minimal expected count
  return (response['parsed'] as List).length >= expectedItemsCount;
}
