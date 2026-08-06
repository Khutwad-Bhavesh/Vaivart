import 'package:flutter_test/flutter_test.dart';
import 'package:vaivart/core/engine/tool_resolver.dart';
import 'package:vaivart/core/engine/engine_downloader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ToolResolver Tests', () {
    test('checkAllTools returns status for all 5 tools', () async {
      final tools = await ToolResolver.checkAllTools();
      expect(tools.length, equals(5));
      final names = tools.map((t) => t.name).toList();
      expect(names, containsAll(['ffmpeg', 'libreoffice', 'ebook-convert', 'heif-convert', 'rsvg-convert']));
    });

    test('getRecommendedInstallCommand returns non-empty command', () async {
      final cmd = await EngineDownloader.getRecommendedInstallCommand();
      expect(cmd.command, isNotEmpty);
      expect(cmd.osName, isNotEmpty);
    });
  });
}
