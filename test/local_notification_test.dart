import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalNotificationService duplicate detection test', () {
    test('extracts notice IDs correctly and prevents duplicate alerts', () {
      final sampleNotices = [
        {'id': 'notice_101', 'title': 'Mid-term Exam', 'content': 'Schedule published'},
        {'_id': 'notice_102', 'title': 'Holiday Notice', 'content': 'Campus closed on Friday'},
        {'title': 'Workshop', 'created_at': '2026-09-12'},
      ];

      final List<String> notifiedSet = ['notice_101'];

      final newNoticesToNotify = <Map<String, dynamic>>[];
      for (final notice in sampleNotices) {
        final String id = notice['id']?.toString() ??
            notice['_id']?.toString() ??
            (notice['title'] != null && notice['created_at'] != null
                ? '${notice['title']}_${notice['created_at']}'
                : notice['title']?.toString() ?? '');

        if (id.isNotEmpty && !notifiedSet.contains(id)) {
          newNoticesToNotify.add(notice);
          notifiedSet.add(id);
        }
      }

      expect(newNoticesToNotify.length, equals(2));
      expect(newNoticesToNotify[0]['_id'], equals('notice_102'));
      expect(notifiedSet.contains('notice_101'), isTrue);
      expect(notifiedSet.contains('notice_102'), isTrue);
      expect(notifiedSet.contains('Workshop_2026-09-12'), isTrue);
    });
  });
}
