import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/breadcrumb_state_service.dart';

void main() {
  group('Kiểm thử nghiêm ngặt Module 1-4', () {
    test('BreadcrumbStateService lưu và truy xuất chuẩn xác', () {
      BreadcrumbStateService.updateCurrentTopic(
        topicId: '161',
        categorySlug: 'thong-bao-su-kien',
        categoryTitle: 'Thông báo - Sự kiện',
        topicTitle: 'Re: Talkshow hướng nghiệp tháng 7/2026',
      );

      final cached = BreadcrumbStateService.getCachedTopic('161');
      expect(cached, isNotNull);
      expect(cached!.topicId, '161');
      expect(cached.categorySlug, 'thong-bao-su-kien');
      expect(cached.categoryTitle, 'Thông báo - Sự kiện');
      expect(cached.topicTitle, 'Re: Talkshow hướng nghiệp tháng 7/2026');
    });

    test('BreadcrumbStateService fallback mặc định khi thiếu category', () {
      BreadcrumbStateService.updateCurrentTopic(
        topicId: '999',
        categorySlug: '',
        categoryTitle: '',
        topicTitle: 'Tiêu đề kiểm thử',
      );

      final cached = BreadcrumbStateService.getCachedTopic('999');
      expect(cached, isNotNull);
      expect(cached!.categorySlug, 'thong-bao-su-kien');
      expect(cached.categoryTitle, 'Thông báo - Sự kiện');
    });
  });
}
