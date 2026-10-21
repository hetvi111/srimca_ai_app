import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:srimca_ai/markdown_message_view.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

void main() {
  group('MarkdownMessageView Tests', () {
    test('sanitizeMarkdown normalizes malformed triple asterisks and bullets', () {
      const raw =
          "**SRIMCA** stands for **Shrimad Rajchandra Institute of Management and Computer Application**\n"
          "**Affiliation Constituent institute of **Uka Tarsadia University (UTU)**\n"
          "***Programmes Offered:** MCA, BCA, Integrated MCA, MBA, Integrated MBA.";

      final cleaned = MarkdownMessageView.sanitizeMarkdown(raw);
      expect(cleaned.contains('***'), isFalse);
      expect(cleaned.contains('- **Affiliation:** Constituent institute of **Uka Tarsadia University (UTU)**'), isTrue);
      expect(cleaned.contains('- **Programmes Offered:** MCA, BCA, Integrated MCA, MBA, Integrated MBA.'), isTrue);
      expect(cleaned.contains('**SRIMCA** stands for **Shrimad Rajchandra Institute of Management and Computer Application**'), isTrue);
    });

    test('sanitizeMarkdown preserves valid markdown formatting', () {
      const validMarkdown =
          "**SRIMCA** stands for Shrimad Rajchandra Institute of Management and Computer Application.\n\n"
          "- **Affiliation:** Constituent institute of Uka Tarsadia University (UTU), Maliba Campus, Bardoli, Surat.\n"
          "- **Approvals:** Approved by AICTE, New Delhi, and the Government of Gujarat.\n"
          "- **Established:** MCA in 2002 and MBA in 2004.\n"
          "- **Programmes Offered:** MCA, BCA, Integrated MCA, MBA, and Integrated MBA.";

      final cleaned = MarkdownMessageView.sanitizeMarkdown(validMarkdown);
      expect(cleaned, equals(validMarkdown));
    });

    test('sanitizeMarkdown converts unicode bullets to standard markdown list items', () {
      const unicodeBullets =
          "**SRIMCA Programmes & Admissions:**\n\n"
          "• **MCA:** 2-Year PG Degree.\n"
          "• **BCA:** 3-Year UG Degree.";

      final cleaned = MarkdownMessageView.sanitizeMarkdown(unicodeBullets);
      expect(cleaned.contains('•'), isFalse);
      expect(cleaned.contains('- **MCA:**'), isTrue);
      expect(cleaned.contains('- **BCA:**'), isTrue);
    });

    testWidgets('MarkdownMessageView renders MarkdownBody widget correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MarkdownMessageView(
              text: "**Bold Title**\n\n- Item 1\n- Item 2",
            ),
          ),
        ),
      );

      expect(find.byType(MarkdownBody), findsOneWidget);
    });
  });
}
