import 'dart:convert';
import 'dart:io';

class OutputService {
  static const _key = 'output_dir';
  static String? _cliOutputDir;

  static Future<String> getOutputDir() async {
    if (_cliOutputDir != null) return _cliOutputDir!;
    final configFile = _getConfigFile();
    if (configFile.existsSync()) {
      try {
        final content = jsonDecode(configFile.readAsStringSync());
        if (content is Map && content.containsKey(_key)) {
          return content[_key] as String;
        }
      } catch (_) {}
    }
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '.';
    final downloadsDir = Directory('$home/Downloads');
    if (downloadsDir.existsSync()) return downloadsDir.path;
    return Directory.current.path;
  }

  static Future<void> setOutputDir(String path) async {
    _cliOutputDir = path;
    try {
      final configFile = _getConfigFile();
      Map<String, dynamic> data = {};
      if (configFile.existsSync()) {
        try {
          data = Map<String, dynamic>.from(jsonDecode(configFile.readAsStringSync()));
        } catch (_) {}
      }
      data[_key] = path;
      configFile.parent.createSync(recursive: true);
      configFile.writeAsStringSync(jsonEncode(data));
    } catch (_) {}
  }

  static File _getConfigFile() {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '.';
    return File('$home/.config/vaivart/config.json');
  }
}