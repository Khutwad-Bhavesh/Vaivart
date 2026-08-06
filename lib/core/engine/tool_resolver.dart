import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ToolStatus {
  final String name;
  final bool isInstalled;
  final String? path;
  final String category;

  const ToolStatus({
    required this.name,
    required this.isInstalled,
    this.path,
    required this.category,
  });
}

class ToolResolver {
  static final Map<String, String?> _cache = {};

  /// Get the app's dedicated local binary storage directory (~/.local/share/vaivart/bin or LocalAppData/vaivart/bin)
  static Future<Directory> getAppBinDir() async {
    final appSupport = await getApplicationSupportDirectory();
    final binDir = Directory(p.join(appSupport.path, 'bin'));
    if (!await binDir.exists()) {
      await binDir.create(recursive: true);
    }
    return binDir;
  }

  /// Locate an executable by checking local app bin dir, standard system locations, and system PATH
  static Future<String?> findExecutable(
    String name, {
    List<String>? candidates,
  }) async {
    if (_cache.containsKey(name)) {
      return _cache[name];
    }

    final isWin = Platform.isWindows;
    final exeName = isWin && !name.endsWith('.exe') ? '$name.exe' : name;

    // 1. Check local app bin directory
    try {
      final binDir = await getAppBinDir();
      final localFile = File(p.join(binDir.path, exeName));
      if (await localFile.exists()) {
        _cache[name] = localFile.path;
        return localFile.path;
      }
    } catch (_) {}

    // 2. Check explicitly provided candidate paths
    final explicitCandidates = candidates ?? _getDefaultCandidates(name);
    for (final candidatePath in explicitCandidates) {
      final file = File(candidatePath);
      if (await file.exists()) {
        _cache[name] = file.path;
        return file.path;
      }
    }

    // 3. Check system PATH via 'which' or 'where'
    try {
      final checkCmd = isWin ? 'where' : 'which';
      final result = await Process.run(checkCmd, [name]);
      if (result.exitCode == 0) {
        final resolved = result.stdout.toString().split('\n').first.trim();
        if (resolved.isNotEmpty && await File(resolved).exists()) {
          _cache[name] = resolved;
          return resolved;
        }
      }
    } catch (_) {}

    _cache[name] = null;
    return null;
  }

  /// Default search candidates per platform
  static List<String> _getDefaultCandidates(String name) {
    final isWin = Platform.isWindows;
    final isMac = Platform.isMacOS;

    switch (name) {
      case 'soffice':
      case 'libreoffice':
        if (isWin) {
          return [
            r'C:\Program Files\LibreOffice\program\soffice.exe',
            r'C:\Program Files (x86)\LibreOffice\program\soffice.exe',
          ];
        } else if (isMac) {
          return [
            '/Applications/LibreOffice.app/Contents/MacOS/soffice',
            '/opt/homebrew/bin/soffice',
          ];
        } else {
          return [
            '/usr/bin/libreoffice',
            '/usr/bin/soffice',
            '/usr/lib/libreoffice/program/soffice',
            '/usr/local/bin/soffice',
          ];
        }
      case 'ffmpeg':
        if (isWin) {
          return [
            r'C:\Program Files\ffmpeg\bin\ffmpeg.exe',
            r'C:\ffmpeg\bin\ffmpeg.exe',
          ];
        } else if (isMac) {
          return [
            '/opt/homebrew/bin/ffmpeg',
            '/usr/local/bin/ffmpeg',
          ];
        } else {
          return [
            '/usr/bin/ffmpeg',
            '/usr/local/bin/ffmpeg',
          ];
        }
      case 'ebook-convert':
        if (isWin) {
          return [
            r'C:\Program Files\Calibre2\ebook-convert.exe',
          ];
        } else if (isMac) {
          return [
            '/Applications/calibre.app/Contents/MacOS/ebook-convert',
            '/opt/homebrew/bin/ebook-convert',
          ];
        } else {
          return [
            '/usr/bin/ebook-convert',
            '/usr/local/bin/ebook-convert',
          ];
        }
      default:
        return [];
    }
  }

  /// Check health status of all conversion tools
  static Future<List<ToolStatus>> checkAllTools() async {
    final tools = [
      {'name': 'ffmpeg', 'category': 'Video & Audio'},
      {'name': 'soffice', 'category': 'Documents & PDFs'},
      {'name': 'ebook-convert', 'category': 'EPUB / E-books'},
      {'name': 'heif-convert', 'category': 'HEIC Images'},
      {'name': 'rsvg-convert', 'category': 'SVG Vector Images'},
    ];

    final results = <ToolStatus>[];
    for (final t in tools) {
      final name = t['name']!;
      final category = t['category']!;
      final path = await findExecutable(name);
      results.add(ToolStatus(
        name: name == 'soffice' ? 'libreoffice' : name,
        isInstalled: path != null,
        path: path,
        category: category,
      ));
    }
    return results;
  }

  /// Cross-platform folder/file launcher
  static Future<bool> openFolder(String path) async {
    try {
      if (Platform.isWindows) {
        final res = await Process.run('explorer.exe', [path]);
        return res.exitCode == 0;
      } else if (Platform.isMacOS) {
        final res = await Process.run('open', [path]);
        return res.exitCode == 0;
      } else {
        final res = await Process.run('xdg-open', [path]);
        return res.exitCode == 0;
      }
    } catch (_) {
      return false;
    }
  }

  /// Clear path resolution cache
  static void clearCache() {
    _cache.clear();
  }
}
