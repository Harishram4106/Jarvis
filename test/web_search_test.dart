import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jarvis/repositories/web_search.dart';

/// The two parsers are the fragile part of search: DuckDuckGo is scraped HTML
/// and Wikipedia is JSON with markup inside the snippets. Fixtures are real
/// captured responses, so a layout change fails here instead of at runtime.
void main() {
  test('parseResults pulls title, unwrapped url and snippet from DDG html', () {
    final results =
        WebSearch.parseResults(File('test/ddg_sample.html').readAsStringSync());

    expect(results, isNotEmpty);
    expect(results.length, lessThanOrEqualTo(WebSearch.maxResults));
    for (final r in results) {
      expect(r.title, isNotEmpty);
      // The redirect wrapper must be unwrapped to the real destination.
      expect(r.url, startsWith('http'));
      expect(r.url, isNot(contains('duckduckgo.com/l/')));
      // Markup and entities must be stripped, not passed through.
      expect(r.title, isNot(contains('<')));
      expect(r.snippet, isNot(contains('<')));
    }
  });

  test('parseWikipedia maps hits to titles, urls and clean snippets', () {
    final results = WebSearch.parseWikipedia(
        File('test/wiki_sample.json').readAsStringSync());

    expect(results, isNotEmpty);
    expect(results.first.title, 'Flutter (software)');
    expect(results.first.url,
        'https://en.wikipedia.org/wiki/Flutter_(software)');
    // Wikipedia wraps matches in <span class="searchmatch">.
    expect(results.first.snippet, isNot(contains('<span')));
  });

  test('both parsers return empty on junk instead of throwing', () {
    expect(WebSearch.parseResults('<html>nothing here</html>'), isEmpty);
    expect(WebSearch.parseWikipedia('not json'), isEmpty);
  });
}
