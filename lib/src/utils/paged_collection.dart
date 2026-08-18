/// Tracks the newest request so stale responses cannot overwrite a newer query.
class PagedRequestGate {
  int _serial = 0;
  int? _activeToken;

  bool get isInFlight => _activeToken != null;

  int? begin({bool supersede = false}) {
    if (_activeToken != null && !supersede) return null;
    final token = ++_serial;
    _activeToken = token;
    return token;
  }

  bool isCurrent(int token) => _activeToken == token;

  void complete(int token) {
    if (_activeToken == token) _activeToken = null;
  }

  void invalidate() {
    _serial++;
    _activeToken = null;
  }
}

/// Creates an immutable, identity-based snapshot for refreshes and appends.
///
/// Existing positions are retained while newer values replace matching IDs.
/// New IDs are appended in response order. A refresh starts from an empty map.
List<T> mergePagedItems<T, I>({
  required List<T> existing,
  required Iterable<T> incoming,
  required I Function(T item) idOf,
  bool replace = false,
}) {
  final byId = <I, T>{};
  if (!replace) {
    for (final item in existing) {
      byId[idOf(item)] = item;
    }
  }
  for (final item in incoming) {
    byId[idOf(item)] = item;
  }
  return List<T>.unmodifiable(byId.values);
}
