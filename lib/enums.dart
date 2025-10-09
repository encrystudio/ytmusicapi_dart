/// Response status.
enum ResponseStatus {
  /// Succeeded.
  SUCCEEDED,
}

/// Extension to turn this enum into String representation.
extension ResponseStatusExtension on ResponseStatus {
  /// Get String value.
  String get value {
    switch (this) {
      case ResponseStatus.SUCCEEDED:
        return 'STATUS_SUCCEEDED';
    }
  }
}

/// Artist order type.
enum ArtistOrderType {
  /// Sort by recency.
  recency('Recency'),

  /// Sort by popularity.
  popularity('Popularity'),

  /// Sort by alphabetical order.
  alphabetical('Alphabetical order');

  /// Raw value.
  final String value;

  const ArtistOrderType(this.value);
}
