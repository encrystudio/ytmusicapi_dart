class CaseInsensitiveMap<V> {
  final Map<String, V> _store = {};
  final Map<String, String> _originalKeys = {};

  CaseInsensitiveMap([Map<String, V>? initial]) {
    if (initial != null) {
      for (var entry in initial.entries) {
        this[entry.key] = entry.value;
      }
    }
  }

  String _normalizeKey(String key) => key.toLowerCase();

  V? operator [](String key) {
    return _store[_normalizeKey(key)];
  }

  void operator []=(String key, V value) {
    String normalized = _normalizeKey(key);
    if (!_originalKeys.containsKey(normalized)) {
      _originalKeys[normalized] = key;
    }
    _store[normalized] = value;
  }

  bool containsKey(String key) {
    return _store.containsKey(_normalizeKey(key));
  }

  V? remove(String key) {
    String normalized = _normalizeKey(key);
    _originalKeys.remove(normalized);
    return _store.remove(normalized);
  }

  Iterable<String> get keys => _originalKeys.values;

  Iterable<V> get values => _store.values;

  int get length => _store.length;

  bool get isEmpty => _store.isEmpty;

  bool get isNotEmpty => _store.isNotEmpty;

  void clear() {
    _store.clear();
    _originalKeys.clear();
  }

  Map<String, V> toMap() {
    final result = <String, V>{};
    for (final key in _originalKeys.entries) {
      result[key.value] = _store[key.key] as V;
    }
    return result;
  }

  @override
  String toString() => toMap().toString();
}
