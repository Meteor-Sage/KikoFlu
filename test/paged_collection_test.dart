import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/utils/paged_collection.dart';

void main() {
  test('append merges by stable identity without duplicating refreshed items',
      () {
    final merged = mergePagedItems<_Item, int>(
      existing: const [_Item(1, 'old'), _Item(2, 'two')],
      incoming: const [_Item(1, 'new'), _Item(3, 'three'), _Item(3, 'latest')],
      idOf: (item) => item.id,
    );

    expect(merged.map((item) => item.id), [1, 2, 3]);
    expect(merged.first.label, 'new');
    expect(merged.last.label, 'latest');
  });

  test('refresh replaces old pages and removes duplicates in the response', () {
    final merged = mergePagedItems<_Item, int>(
      existing: const [_Item(1, 'old'), _Item(2, 'stale')],
      incoming: const [_Item(1, 'new'), _Item(1, 'latest'), _Item(3, 'three')],
      idOf: (item) => item.id,
      replace: true,
    );

    expect(merged.map((item) => item.id), [1, 3]);
    expect(merged.first.label, 'latest');
  });

  test('request gate rejects reentry and invalidates stale responses', () {
    final gate = PagedRequestGate();
    final first = gate.begin();

    expect(first, isNotNull);
    expect(gate.begin(), isNull);

    final replacement = gate.begin(supersede: true)!;
    expect(gate.isCurrent(first!), isFalse);
    expect(gate.isCurrent(replacement), isTrue);

    gate.complete(first);
    expect(gate.isInFlight, isTrue);
    gate.complete(replacement);
    expect(gate.isInFlight, isFalse);
  });
}

class _Item {
  const _Item(this.id, this.label);

  final int id;
  final String label;
}
