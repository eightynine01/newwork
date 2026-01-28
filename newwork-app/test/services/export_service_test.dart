import 'package:flutter_test/flutter_test.dart';
import 'package:newwork/services/export_service.dart';

void main() {
  group('ExportFormat', () {
    test('should have correct extensions', () {
      expect(ExportFormat.json.extension, 'json');
      expect(ExportFormat.markdown.extension, 'md');
    });

    test('should have display names', () {
      expect(ExportFormat.json.displayName, 'JSON');
      expect(ExportFormat.markdown.displayName, 'Markdown');
    });
  });

  group('ExportService', () {
    late ExportService service;

    setUp(() {
      service = ExportService();
    });

    tearDown(() {
      service.dispose();
    });

    test('should create instance without error', () {
      expect(service, isNotNull);
    });
  });
}
