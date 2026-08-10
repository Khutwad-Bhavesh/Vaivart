import 'dart:convert';
import 'dart:io';

class HistoryEntry {
  final String fileName;
  final String fromFormat;
  final String toFormat;
  final String outputPath;
  final DateTime convertedAt;
  final bool success;

  HistoryEntry({
    required this.fileName,
    required this.fromFormat,
    required this.toFormat,
    required this.outputPath,
    required this.convertedAt,
    required this.success,
  });

  Map<String, dynamic> toJson() => {
        'fileName': fileName,
        'fromFormat': fromFormat,
        'toFormat': toFormat,
        'outputPath': outputPath,
        'convertedAt': convertedAt.toIso8601String(),
        'success': success,
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        fileName: json['fileName'],
        fromFormat: json['fromFormat'],
        toFormat: json['toFormat'],
        outputPath: json['outputPath'],
        convertedAt: DateTime.parse(json['convertedAt']),
        success: json['success'],
      );
}

class HistoryService {
  static Future<List<HistoryEntry>> getHistory() async {
    final file = _getHistoryFile();
    if (!file.existsSync()) return [];
    try {
      final raw = List<String>.from(jsonDecode(file.readAsStringSync()));
      return raw
          .map((e) => HistoryEntry.fromJson(jsonDecode(e)))
          .toList()
          .reversed
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> addEntry(HistoryEntry entry) async {
    try {
      final file = _getHistoryFile();
      List<String> raw = [];
      if (file.existsSync()) {
        raw = List<String>.from(jsonDecode(file.readAsStringSync()));
      }
      raw.add(jsonEncode(entry.toJson()));
      if (raw.length > 100) raw.removeAt(0);
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(jsonEncode(raw));
    } catch (_) {}
  }

  static Future<void> clearHistory() async {
    try {
      final file = _getHistoryFile();
      if (file.existsSync()) file.deleteSync();
    } catch (_) {}
  }

  static File _getHistoryFile() {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '.';
    return File('$home/.config/vaivart/history.json');
  }
}