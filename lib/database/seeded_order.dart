import 'package:drift/drift.dart';

/// A per-session shuffle for local pages, like the API's seeded order.
///
/// Rows sort by `(rowid * m) mod p` with `m` taken from the session seed:
/// `p` is a prime larger than any table here, so every seed is a different
/// permutation, and paging with the same seed walks the same order.
OrderingTerm seededOrder(int seed) {
  const p = 1000003;
  final m = (seed.abs() % (p - 2)) + 2;
  return OrderingTerm.asc(CustomExpression<int>('((rowid * $m) % $p)'));
}
