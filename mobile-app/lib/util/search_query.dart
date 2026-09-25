import 'package:diacritic/diacritic.dart';

/// The search box's rule, shared by the kennel list, the run list and the
/// map's kennel search. It was three hand copies until 2026-09-25, and they
/// had drifted: the run list's commas widened the results (each term added
/// its matches again, so a run could appear twice) where the others narrowed.
///
/// The text searched is a precomputed lowercase string of the row's words
/// (see `QueryKennels.searchKennelsField` / `QueryRuns.searchRunsField`).
///
/// - A comma separates terms that must ALL match: `city hash, london`.
/// - Within a term, every space-separated word must match, so
///   `city hash london` finds City Hash in London. Before this a term was one
///   phrase, and the obvious search for a kennel found nothing.
/// - `+` separates alternatives, any of which may match: `lh3 + city hash`.
/// - A term starting `not ` excludes what it matches: `london, not city`.
/// - A word matches the START of a word in the text, so `lon` finds London
///   but `ondon` does not. Accents are optional on both sides.
class SearchQuery {
  SearchQuery(String text) : _terms = _parse(text);

  final List<_Term> _terms;

  /// No terms at all: every row matches.
  bool get isEmpty => _terms.isEmpty;

  bool matches(String? searchText) {
    if (_terms.isEmpty) return true;
    final String raw = ' ${(searchText ?? '').toLowerCase()}';
    final String plain = removeDiacritics(raw);
    for (final _Term term in _terms) {
      final bool hit = term.alternatives.any(
        (List<String> words) => words.every(
          (String w) =>
              raw.contains(' $w') || plain.contains(' ${removeDiacritics(w)}'),
        ),
      );
      if (hit == term.negate) return false;
    }
    return true;
  }

  static List<_Term> _parse(String text) {
    final List<_Term> terms = <_Term>[];
    for (String part in text.toLowerCase().split(',')) {
      part = part.trim();
      bool negate = false;
      if (part.startsWith('not ')) {
        negate = true;
        part = part.substring(4);
      }
      final List<List<String>> alternatives = <List<String>>[
        for (final String alt in part.split('+'))
          if (alt.trim().isNotEmpty) alt.trim().split(RegExp(r'\s+')).toList(),
      ];
      if (alternatives.isNotEmpty) {
        terms.add(_Term(negate: negate, alternatives: alternatives));
      }
    }
    return terms;
  }
}

class _Term {
  const _Term({required this.negate, required this.alternatives});

  final bool negate;

  /// Any one alternative matching is enough; within it, every word must.
  final List<List<String>> alternatives;
}
