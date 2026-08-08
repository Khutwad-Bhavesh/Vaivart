import 'dart:io';
import 'dart:convert';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path/path.dart' as p;

class DataConverter {
  static Future<String> csvToXlsx({
    required String sourcePath,
    required String outputDir,
  }) async {
    final content = await File(sourcePath).readAsString();
    final lines = const LineSplitter().convert(content);
    final rows = lines.map((l) => l.split(',')).toList();

    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    for (final row in rows) {
      sheet.appendRow(row.map((e) => TextCellValue(e)).toList());
    }

    final baseName = p.basenameWithoutExtension(sourcePath);
    final outPath = p.join(outputDir, '$baseName.xlsx');
    final fileBytes = excel.save();
    if (fileBytes == null) throw Exception('Failed to encode xlsx');
    await File(outPath).writeAsBytes(fileBytes);
    return outPath;
  }

  static Future<String> xlsxToCsv({
    required String sourcePath,
    required String outputDir,
  }) async {
    final bytes = await File(sourcePath).readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables.values.first;

    final rows = sheet.rows
        .map((row) => row.map((cell) => cell?.value?.toString() ?? '').join(','))
        .join('\n');

    final baseName = p.basenameWithoutExtension(sourcePath);
    final outPath = p.join(outputDir, '$baseName.csv');
    await File(outPath).writeAsString(rows);
    return outPath;
  }

  static Future<String> jsonToCsv({
    required String sourcePath,
    required String outputDir,
  }) async {
    final content = await File(sourcePath).readAsString();
    final decoded = jsonDecode(content);
    if (decoded is! List || decoded.isEmpty) {
      throw Exception('JSON must be an array of objects');
    }

    final headers = (decoded.first as Map<String, dynamic>).keys.toList();
    final buffer = StringBuffer();
    buffer.writeln(headers.map(_csvEscape).join(','));

    for (final item in decoded) {
      if (item is Map<String, dynamic>) {
        buffer.writeln(headers.map((h) => _csvEscape(item[h]?.toString() ?? '')).join(','));
      }
    }

    final baseName = p.basenameWithoutExtension(sourcePath);
    final outPath = p.join(outputDir, '$baseName.csv');
    await File(outPath).writeAsString(buffer.toString());
    return outPath;
  }

  static Future<String> csvToJson({
    required String sourcePath,
    required String outputDir,
  }) async {
    final content = await File(sourcePath).readAsString();
    final lines = const LineSplitter().convert(content);
    if (lines.isEmpty) throw Exception('CSV file is empty');

    final headers = lines.first.split(',').map((h) => h.trim()).toList();
    final rows = <Map<String, String>>[];

    for (int i = 1; i < lines.length; i++) {
      if (lines[i].trim().isEmpty) continue;
      final values = lines[i].split(',');
      final row = <String, String>{};
      for (int j = 0; j < headers.length; j++) {
        row[headers[j]] = j < values.length ? values[j].trim() : '';
      }
      rows.add(row);
    }

    final baseName = p.basenameWithoutExtension(sourcePath);
    final outPath = p.join(outputDir, '$baseName.json');
    await File(outPath).writeAsString(const JsonEncoder.withIndent('  ').convert(rows));
    return outPath;
  }

  static Future<String> tsvToCsv({
    required String sourcePath,
    required String outputDir,
  }) async {
    final content = await File(sourcePath).readAsString();
    final lines = const LineSplitter().convert(content);
    final csvLines = lines.map((line) {
      final fields = line.split('\t');
      return fields.map(_csvEscape).join(',');
    }).join('\n');

    final baseName = p.basenameWithoutExtension(sourcePath);
    final outPath = p.join(outputDir, '$baseName.csv');
    await File(outPath).writeAsString(csvLines);
    return outPath;
  }

  static Future<String> csvToTsv({
    required String sourcePath,
    required String outputDir,
  }) async {
    final content = await File(sourcePath).readAsString();
    final lines = const LineSplitter().convert(content);
    final tsvLines = lines.map((line) => line.split(',').join('\t')).join('\n');

    final baseName = p.basenameWithoutExtension(sourcePath);
    final outPath = p.join(outputDir, '$baseName.tsv');
    await File(outPath).writeAsString(tsvLines);
    return outPath;
  }

  static Future<String> xlsxToJson({
    required String sourcePath,
    required String outputDir,
  }) async {
    final bytes = await File(sourcePath).readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables.values.first;
    if (sheet.rows.isEmpty) throw Exception('Excel file is empty');

    final headers = sheet.rows.first
        .map((cell) => cell?.value?.toString() ?? '')
        .toList();
    final rows = <Map<String, String>>[];

    for (int i = 1; i < sheet.rows.length; i++) {
      final row = <String, String>{};
      for (int j = 0; j < headers.length; j++) {
        row[headers[j]] = j < sheet.rows[i].length
            ? (sheet.rows[i][j]?.value?.toString() ?? '')
            : '';
      }
      rows.add(row);
    }

    final baseName = p.basenameWithoutExtension(sourcePath);
    final outPath = p.join(outputDir, '$baseName.json');
    await File(outPath).writeAsString(const JsonEncoder.withIndent('  ').convert(rows));
    return outPath;
  }

  static Future<String> csvToPdf({
    required String sourcePath,
    required String outputDir,
  }) async {
    final content = await File(sourcePath).readAsString();
    final lines = const LineSplitter().convert(content);
    final rows = lines.map((l) => l.split(',')).toList();

    final pdf = pw.Document();
    // Split into chunks of 30 rows per page
    for (var i = 0; i < rows.length; i += 30) {
      final chunk = rows.sublist(i, i + 30 > rows.length ? rows.length : i + 30);
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        orientation: pw.PageOrientation.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (_) => pw.TableHelper.fromTextArray(
          data: chunk,
          headerCount: i == 0 ? 1 : 0,
          cellStyle: const pw.TextStyle(fontSize: 8),
          headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
      ));
    }

    final baseName = p.basenameWithoutExtension(sourcePath);
    final outPath = p.join(outputDir, '$baseName.pdf');
    await File(outPath).writeAsBytes(await pdf.save());
    return outPath;
  }

  static String _csvEscape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}