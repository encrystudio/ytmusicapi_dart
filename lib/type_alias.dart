import 'dart:async';

/// Dart representation of a Json object.
typedef JsonMap = Map<String, dynamic>;

/// A function to receive a [JsonMap] eventually.
typedef RequestFuncType = Future<JsonMap> Function(String);

/// A function to receive a request body eventually.
typedef RequestFuncBodyType = FutureOr<JsonMap> Function(JsonMap);

/// A function to parse a List from another List.
typedef ParseFuncType = FutureOr<List> Function(List<JsonMap>);

/// A function to parse a [JsonMap] from another [JsonMap].
typedef ParseFuncMapType = FutureOr<JsonMap> Function(JsonMap);
