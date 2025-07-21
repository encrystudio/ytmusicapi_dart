import 'package:ytmusicapi_dart/src/enums.dart';

class Parser {
  List<String> getSearchResultTypes() {
    var types = <String>[];

    for (var type in SearchResultTypes.values) {
      types.add(type.name);
    }

    return types;
  }

  List<String> getApiResultTypes() {
    var types = <String>[];

    for (var type in ApiResultTypes.values) {
      types.add(type.name);
    }

    return types;
  }
}
