import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaivart/core/engine/binary_downloader_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getApplicationSupportDirectory') {
          return '.';
        }
        return null;
      },
    );
  });

  group('BinaryDownloaderService Tests', () {
    test('getDownloadInfo returns valid download config for ffmpeg', () {
      final info = BinaryDownloaderService.getDownloadInfo('ffmpeg');
      expect(info, isNotNull);
      expect(info!.toolName, equals('ffmpeg'));
      expect(info.url, startsWith('http'));
      expect(info.binaryFileName, contains('ffmpeg'));
    });

    test('getDownloadInfo returns null for unknown tool', () {
      final info = BinaryDownloaderService.getDownloadInfo('unknown_tool_xyz');
      expect(info, isNull);
    });

    test('isToolDownloaded returns boolean without throwing', () async {
      final isDownloaded = await BinaryDownloaderService.isToolDownloaded('ffmpeg');
      expect(isDownloaded, isA<bool>());
    });
  });
}
