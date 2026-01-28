import 'package:flutter_test/flutter_test.dart';
import 'package:newwork/services/file_download_service.dart';

void main() {
  group('FileDownloadService', () {
    late FileDownloadService service;

    setUp(() {
      service = FileDownloadService();
    });

    tearDown(() {
      service.dispose();
    });

    test('should create instance without error', () {
      expect(service, isNotNull);
    });

    test('should accept custom base URL', () {
      final customService = FileDownloadService(
        baseUrl: 'http://localhost:8000',
      );
      expect(customService, isNotNull);
      customService.dispose();
    });
  });
}
