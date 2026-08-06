import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'tool_resolver.dart';

enum EngineType { lightweight, powerful, manual }

class EngineConfig {
  static bool get isAndroid => Platform.isAndroid;
  static bool get isDesktop =>
      Platform.isLinux || Platform.isWindows || Platform.isMacOS;

  static Future<EngineType> getEngine() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getInt('engine') ?? 0;
    // On Android, manual falls back to lightweight (no shell tools)
    final engine = EngineType.values[val];
    if (isAndroid && engine == EngineType.manual) return EngineType.lightweight;
    return engine;
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
