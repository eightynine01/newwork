import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newwork/features/session/widgets/download_progress_dialog.dart';

void main() {
  group('DownloadProgressDialog', () {
    testWidgets('should display filename', (tester) async {
      Completer<String>? completer;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => DownloadProgressDialog(
                      fileName: 'test_file.txt',
                      downloadTask: (onProgress) {
                        completer = Completer<String>();
                        return completer!.future;
                      },
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pump();

      expect(find.text('test_file.txt'), findsOneWidget);
      expect(find.text('Downloading...'), findsOneWidget);

      // Complete the download to clean up
      completer?.complete('/path/to/test_file.txt');
      await tester.pumpAndSettle();
    });

    testWidgets('should show progress indicator', (tester) async {
      Completer<String>? completer;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => DownloadProgressDialog(
                      fileName: 'test.pdf',
                      downloadTask: (onProgress) {
                        completer = Completer<String>();
                        // Report 50% progress immediately
                        onProgress(0.5);
                        return completer!.future;
                      },
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pump();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // Complete the download to clean up
      completer?.complete('/path/to/test.pdf');
      await tester.pumpAndSettle();
    });

    testWidgets('should call onCancel when cancel pressed', (tester) async {
      bool cancelled = false;
      Completer<String>? completer;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => DownloadProgressDialog(
                      fileName: 'test.pdf',
                      downloadTask: (onProgress) {
                        completer = Completer<String>();
                        return completer!.future;
                      },
                      onCancel: () {
                        cancelled = true;
                      },
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pump();

      // Find and tap cancel button
      await tester.tap(find.text('Cancel'));
      await tester.pump();

      expect(cancelled, isTrue);

      // Complete the completer to clean up any pending timers
      completer?.complete('/path/to/test.pdf');
      await tester.pumpAndSettle();
    });
  });
}
