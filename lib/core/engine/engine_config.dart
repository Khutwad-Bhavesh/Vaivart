import 'dart:convert';
import 'dart:io';
import 'tool_resolver.dart';

enum EngineType { lightweight, powerful, manual }

class EngineConfig {
  static bool get isAndroid => Platform.isAndroid;
  static bool get isDesktop =>
      Platform.isLinux || Platform.isWindows || Platform.isMacOS;

  static EngineType? _cachedEngine;

  static Future<EngineType> getEngine() async {
    if (_cachedEngine != null) return _cachedEngine!;
    final configFile = _getConfigFile();
    if (configFile.existsSync()) {
      try {
        final content = jsonDecode(configFile.readAsStringSync());
        if (content is Map && content.containsKey('engine')) {
          final val = content['engine'] as int;
          if (val >= 0 && val < EngineType.values.length) {
            _cachedEngine = EngineType.values[val];
            return _cachedEngine!;
          }
        }
      } catch (_) {}
    }
    _cachedEngine = EngineType.powerful;
    return _cachedEngine!;
  }

  static Future<void> setEngine(EngineType engine) async {
    _cachedEngine = engine;
    try {
      final configFile = _getConfigFile();
      Map<String, dynamic> data = {};
      if (configFile.existsSync()) {
        try {
          data = Map<String, dynamic>.from(jsonDecode(configFile.readAsStringSync()));
        } catch (_) {}
      }
      data['engine'] = engine.index;
      configFile.parent.createSync(recursive: true);
      configFile.writeAsStringSync(jsonEncode(data));
    } catch (_) {}
  }

  static File _getConfigFile() {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '.';
    return File('$home/.config/vaivart/config.json');
  }

  // ── Feature support matrix ──────────────────────────────────────

  // Images, CSV/XLSX, TXT/MD/HTML → PDF: pure Dart, always works
  static bool supportsImages(EngineType e) => true;
  static bool supportsData(EngineType e) => true;
  static bool supportsPdf(EngineType e) => true;

  // Video: desktop needs ffmpeg; Android uses ffmpeg_kit (powerful only)
  static bool supportsVideo(EngineType e) {
    if (isAndroid) return e == EngineType.powerful;
    return e == EngineType.powerful || e == EngineType.manual;
  }

  // Audio: same as video
  static bool supportsAudio(EngineType e) => supportsVideo(e);

  // DOCX/PPTX/EPUB → PDF: desktop only
  static bool supportsDesktopDocs(EngineType e) {
    if (isAndroid) return false;
    return e == EngineType.powerful || e == EngineType.manual;
  }

  // ── Dynamic tool availability checks ───────────────────────────
  static Future<bool> hasFfmpeg() async {
    if (isAndroid) return true;
    final path = await ToolResolver.findExecutable('ffmpeg');
    return path != null;
  }

  static Future<bool> hasLibreOffice() async {
    if (isAndroid) return false;
    final path = await ToolResolver.findExecutable('soffice');
    return path != null;
  }

  static Future<bool> hasCalibre() async {
    if (isAndroid) return false;
    final path = await ToolResolver.findExecutable('ebook-convert');
    return path != null;
  }
}
