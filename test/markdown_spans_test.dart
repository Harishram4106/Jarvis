import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarvis/features/chat/presentation/screens/chat_screen.dart';

/// Replies arrive as markdown. Before this, a plain Text widget rendered the
/// raw "**bold**" asterisks on screen, which is what users actually saw.
void main() {
  const base = TextStyle(fontSize: 14);

  String flatten(List<TextSpan> spans) => spans.map((s) => s.text).join();

  test('bold markers are consumed and the text is emboldened', () {
    final spans = markdownSpans('a **b** c', base);

    expect(flatten(spans), 'a b c');
    expect(flatten(spans), isNot(contains('*')));
    final bold = spans.firstWhere((s) => s.text == 'b');
    expect(bold.style!.fontWeight, FontWeight.w700);
  });

  test('italic and inline code are styled', () {
    final spans = markdownSpans('*i* and `c`', base);

    expect(flatten(spans), 'i and c');
    expect(spans.firstWhere((s) => s.text == 'i').style!.fontStyle,
        FontStyle.italic);
    expect(spans.firstWhere((s) => s.text == 'c').style!.fontFamily,
        'monospace');
  });

  test('bold wins over italic at the same position', () {
    final spans = markdownSpans('**both**', base);

    expect(flatten(spans), 'both');
    expect(spans.single.style!.fontWeight, FontWeight.w700);
  });

  test('headings, quotes and bullets are cleaned up', () {
    final spans = markdownSpans('## Title\n- one\n> quoted', base);

    expect(flatten(spans), 'Title\n• one\nquoted');
  });

  test('plain text passes through untouched', () {
    final spans = markdownSpans('nothing to format', base);

    expect(flatten(spans), 'nothing to format');
    expect(spans.single.style, base);
  });

  test('unmatched asterisk is left alone rather than eating the rest', () {
    final spans = markdownSpans('2 * 3 = 6', base);

    expect(flatten(spans), '2 * 3 = 6');
  });
}
