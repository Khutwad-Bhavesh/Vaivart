import 'dart:io';
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path/path.dart' as p;

import '../engine/tool_resolver.dart';

class DocumentConverter {
  static Future<String> _getSoffice() async {
    final path = await ToolResolver.findExecutable('soffice');
    if (path == null) {
      throw Exception(
        'LibreOffice (soffice) not found. Please install LibreOffice or check your PATH in Settings.',
      );
    }
    return path;
  }

  static Future<String> _getEbookConvert() async {
    final path = await ToolResolver.findExecutable('ebook-convert');
    if (path == null) {
      throw Exception(
        'Calibre (ebook-convert) not found. Please install Calibre or check your PATH in Settings.',
      );
    }
    return path;
  }

  static Future<String> txtToPdf({
    required String sourcePath,
    required String outputDir,
  }) async {
    final content = await File(sourcePath).readAsString();
    final pdf = pw.Document();
    final lines = content.split('\n');
    final chunks = <List<String>>[];

    for (var i = 0; i < lines.length; i += 40) {
      chunks.add(lines.sublist(i, i + 40 > lines.length ? lines.length : i + 40));
    }

    for (final chunk in chunks) {
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: chunk
              .map((line) => pw.Text(line, style: const pw.TextStyle(fontSize: 11)))
              .toList(),
        ),
      ));
    }

    final baseName = p.basenameWithoutExtension(sourcePath);
    final outPath = p.join(outputDir, '$baseName.pdf');
    await File(outPath).writeAsBytes(await pdf.save());
    return outPath;
  }

  static Future<String> docxToPdf({
    required String sourcePath,
    required String outputDir,
  }) async {
    final soffice = await _getSoffice();
    final result = await Process.run(soffice, [
      '--headless',
      '--convert-to', 'pdf',
      '--outdir', outputDir,
      sourcePath,
    ]);

    if (result.exitCode != 0) {
      throw Exception('LibreOffice error: ${result.stderr}');
    }

    final baseName = p.basenameWithoutExtension(sourcePath);
    return p.join(outputDir, '$baseName.pdf');
  }

  static Future<String> pdfToDocx({
    required String sourcePath,
    required String outputDir,
  }) async {
    final bytes = await File(sourcePath).readAsBytes();
    final text = _extractTextFromPdf(bytes);
    final baseName = p.basenameWithoutExtension(sourcePath);
    final outPath = p.join(outputDir, '$baseName.docx');
    await File(outPath).writeAsString(text);
    return outPath;
  }

  static String _extractTextFromPdf(List<int> bytes) {
    try {
      final raw = String.fromCharCodes(bytes);
      final matches = RegExp(r'BT(.*?)ET', dotAll: true)
          .allMatches(raw)
          .map((m) => m.group(1) ?? '')
          .join('\n');
      final cleaned = matches
          .replaceAll(RegExp(r'\(([^)]*)\)\s*Tj'), r'$1')
          .replaceAll(RegExp(r'[^\x20-\x7E\n]'), '')
          .trim();
      return cleaned.isEmpty ? 'Could not extract text from this PDF.' : cleaned;
    } catch (_) {
      return 'Could not extract text from this PDF.';
    }
  }

  static Future<String> epubToPdf({
    required String sourcePath,
    required String outputDir,
  }) async {
    final baseName = p.basenameWithoutExtension(sourcePath);
    final outPath = p.join(outputDir, '$baseName.pdf');
    final ebookConvert = await _getEbookConvert();

    final result = await Process.run(ebookConvert, [
      sourcePath,
      outPath,
    ]);

    if (result.exitCode != 0) {
      throw Exception('ebook-convert error: ${result.stderr}');
    }

    return outPath;
  }

  static Future<String> pptxToPdf({
    required String sourcePath,
    required String outputDir,
  }) async {
    final soffice = await _getSoffice();
    final result = await Process.run(soffice, [
      '--headless',
      '--convert-to', 'pdf',
      '--outdir', outputDir,
      sourcePath,
    ]);

    if (result.exitCode != 0) {
      throw Exception('LibreOffice error: ${result.stderr}');
    }

    final baseName = p.basenameWithoutExtension(sourcePath);
    return p.join(outputDir, '$baseName.pdf');
  }

  static Future<String> htmlToPdf({
    required String sourcePath,
    required String outputDir,
  }) async {
    final soffice = await _getSoffice();
    final result = await Process.run(soffice, [
      '--headless',
      '--convert-to', 'pdf',
      '--outdir', outputDir,
      sourcePath,
    ]);

    if (result.exitCode != 0) {
      throw Exception('LibreOffice error: ${result.stderr}');
    }

  final baseName = p.basenameWithoutExtension(sourcePath);
  return p.join(outputDir, '$baseName.pdf');
}

  /// ──────────── Markdown → PDF ────────────
  static Future<String> mdToPdf({
    required String sourcePath,
    required String outputDir,
  }) async {
    final content = await File(sourcePath).readAsString();
    final lines = content.split('\n');
    final pdf = pw.Document();

    // Collect all widgets, then paginate
    final widgets = <pw.Widget>[];
    bool inCodeBlock = false;
    final codeBuffer = StringBuffer();

    for (final rawLine in lines) {
      // ── fenced code blocks ───
      if (rawLine.trimLeft().startsWith('```')) {
        if (inCodeBlock) {
          // Close block
          widgets.add(
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              color: PdfColor.fromHex('#F5F5F5'),
              width: double.infinity,
              child: pw.Text(
                codeBuffer.toString().trimRight(),
                style: pw.TextStyle(
                  font: pw.Font.courier(),
                  fontSize: 9,
                ),
              ),
            ),
          );
          widgets.add(pw.SizedBox(height: 6));
          codeBuffer.clear();
          inCodeBlock = false;
        } else {
          inCodeBlock = true;
        }
        continue;
      }
      if (inCodeBlock) {
        codeBuffer.writeln(rawLine);
        continue;
      }

      final line = rawLine.trimRight();

      // ── blank line → spacer ───
      if (line.trim().isEmpty) {
        widgets.add(pw.SizedBox(height: 8));
        continue;
      }

      // ── horizontal rule ───
      if (RegExp(r'^(\*{3,}|-{3,}|_{3,})$').hasMatch(line.trim())) {
        widgets.add(pw.Divider(thickness: 1));
        widgets.add(pw.SizedBox(height: 4));
        continue;
      }

      // ── headings ───
      final headingMatch = RegExp(r'^(#{1,6})\s+(.*)').firstMatch(line);
      if (headingMatch != null) {
        final level = headingMatch.group(1)!.length;
        final text = headingMatch.group(2)!;
        final sizes = {1: 24.0, 2: 20.0, 3: 17.0, 4: 15.0, 5: 13.0, 6: 12.0};
        widgets.add(pw.SizedBox(height: level <= 2 ? 12.0 : 8.0));
        widgets.add(pw.RichText(
          text: pw.TextSpan(
            text: text,
            style: pw.TextStyle(
              fontSize: sizes[level] ?? 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ));
        if (level <= 2) widgets.add(pw.Divider(thickness: 0.5));
        widgets.add(pw.SizedBox(height: 4));
        continue;
      }

      // ── blockquote ───
      if (line.trimLeft().startsWith('> ')) {
        final quoteText = line.trimLeft().substring(2);
        widgets.add(
          pw.Container(
            padding: const pw.EdgeInsets.only(left: 12, top: 4, bottom: 4),
            decoration: pw.BoxDecoration(
              border: pw.Border(left: pw.BorderSide(width: 3, color: PdfColors.grey400)),
            ),
            child: pw.RichText(text: pw.TextSpan(
              children: _parseInlineSpans(quoteText, pw.TextStyle(
                fontSize: 11, color: PdfColors.grey700, fontStyle: pw.FontStyle.italic,
              )),
            )),
          ),
        );
        widgets.add(pw.SizedBox(height: 4));
        continue;
      }

      // ── unordered list ───
      final ulMatch = RegExp(r'^(\s*)[-*+]\s+(.*)').firstMatch(line);
      if (ulMatch != null) {
        final indent = (ulMatch.group(1)!.length / 2).clamp(0, 4).toDouble();
        final text = ulMatch.group(2)!;
        widgets.add(pw.Padding(
          padding: pw.EdgeInsets.only(left: 16 + indent * 12),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('•  ', style: const pw.TextStyle(fontSize: 11)),
              pw.Expanded(child: pw.RichText(text: pw.TextSpan(
                children: _parseInlineSpans(text, const pw.TextStyle(fontSize: 11)),
              ))),
            ],
          ),
        ));
        widgets.add(pw.SizedBox(height: 2));
        continue;
      }

      // ── ordered list ───
      final olMatch = RegExp(r'^(\s*)(\d+)\.\s+(.*)').firstMatch(line);
      if (olMatch != null) {
        final indent = (olMatch.group(1)!.length / 2).clamp(0, 4).toDouble();
        final number = olMatch.group(2)!;
        final text = olMatch.group(3)!;
        widgets.add(pw.Padding(
          padding: pw.EdgeInsets.only(left: 16 + indent * 12),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('$number. ', style: const pw.TextStyle(fontSize: 11)),
              pw.Expanded(child: pw.RichText(text: pw.TextSpan(
                children: _parseInlineSpans(text, const pw.TextStyle(fontSize: 11)),
              ))),
            ],
          ),
        ));
        widgets.add(pw.SizedBox(height: 2));
        continue;
      }

      // ── normal paragraph ───
      widgets.add(pw.RichText(text: pw.TextSpan(
        children: _parseInlineSpans(line, const pw.TextStyle(fontSize: 11)),
      )));
      widgets.add(pw.SizedBox(height: 4));
    }

    // Flush any unclosed code block
    if (inCodeBlock && codeBuffer.isNotEmpty) {
      widgets.add(
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          color: PdfColor.fromHex('#F5F5F5'),
          width: double.infinity,
          child: pw.Text(
            codeBuffer.toString().trimRight(),
            style: pw.TextStyle(font: pw.Font.courier(), fontSize: 9),
          ),
        ),
      );
    }

    // Use MultiPage so long docs auto-paginate
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (_) => widgets,
    ));

    final baseName = p.basenameWithoutExtension(sourcePath);
    final outPath = p.join(outputDir, '$baseName.pdf');
    await File(outPath).writeAsBytes(await pdf.save());
    return outPath;
  }

  /// Parse inline Markdown spans: **bold**, *italic*, ***both***, `code`
  static List<pw.InlineSpan> _parseInlineSpans(String text, pw.TextStyle base) {
    final spans = <pw.InlineSpan>[];
    final pattern = RegExp(
      r'(`[^`]+`)'           // inline code
      r'|(\*\*\*[^*]+\*\*\*)' // bold+italic
      r'|(\*\*[^*]+\*\*)'     // bold
      r'|(\*[^*]+\*)'         // italic
    );

    int cursor = 0;
    for (final match in pattern.allMatches(text)) {
      // Text before this match
      if (match.start > cursor) {
        spans.add(pw.TextSpan(text: text.substring(cursor, match.start), style: base));
      }

      final raw = match.group(0)!;
      if (raw.startsWith('`')) {
        // inline code
        spans.add(pw.TextSpan(
          text: raw.substring(1, raw.length - 1),
          style: base.copyWith(font: pw.Font.courier(), fontSize: (base.fontSize ?? 11) - 1),
        ));
      } else if (raw.startsWith('***')) {
        spans.add(pw.TextSpan(
          text: raw.substring(3, raw.length - 3),
          style: base.copyWith(fontWeight: pw.FontWeight.bold, fontStyle: pw.FontStyle.italic),
        ));
      } else if (raw.startsWith('**')) {
        spans.add(pw.TextSpan(
          text: raw.substring(2, raw.length - 2),
          style: base.copyWith(fontWeight: pw.FontWeight.bold),
        ));
      } else if (raw.startsWith('*')) {
        spans.add(pw.TextSpan(
          text: raw.substring(1, raw.length - 1),
          style: base.copyWith(fontStyle: pw.FontStyle.italic),
        ));
      }
      cursor = match.end;
    }

    // Remaining text
    if (cursor < text.length) {
      spans.add(pw.TextSpan(text: text.substring(cursor), style: base));
    }

    return spans.isEmpty ? [pw.TextSpan(text: text, style: base)] : spans;
  }

  /// Pure Dart HTML → PDF fallback (strips tags, renders as plain text PDF)
  /// Used on Android where LibreOffice is unavailable.
  static Future<String> htmlToPdfDart({
    required String sourcePath,
    required String outputDir,
  }) async {
    final html = await File(sourcePath).readAsString();
    // Strip HTML tags for basic text extraction
    final text = html
        .replaceAll(RegExp(r'<style[^>]*>.*?</style>', dotAll: true), '')
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', dotAll: true), '')
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<p[^>]*>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll(RegExp(r'&nbsp;'), ' ')
        .replaceAll(RegExp(r'&amp;'), '&')
        .replaceAll(RegExp(r'&lt;'), '<')
        .replaceAll(RegExp(r'&gt;'), '>')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();

    // Reuse txtToPdf logic by writing to a temp file
    final tempTxt = File('${sourcePath}_temp.txt');
    await tempTxt.writeAsString(text);
    final result = await txtToPdf(sourcePath: tempTxt.path, outputDir: outputDir);
    await tempTxt.delete();

    // Rename output to match original html filename
    final baseName = p.basenameWithoutExtension(sourcePath);
    final finalPath = p.join(outputDir, '$baseName.pdf');
    await File(result).rename(finalPath);
    return finalPath;
  }

  static Future<String> rtfToPdf({
    required String sourcePath,
    required String outputDir,
  }) async {
    final soffice = await _getSoffice();
    final result = await Process.run(soffice, [
      '--headless',
      '--convert-to', 'pdf',
      '--outdir', outputDir,
      sourcePath,
    ]);

    if (result.exitCode != 0) {
      throw Exception('LibreOffice error: ${result.stderr}');
    }

    final baseName = p.basenameWithoutExtension(sourcePath);
    return p.join(outputDir, '$baseName.pdf');
  }

  static Future<String> odtToPdf({
    required String sourcePath,
    required String outputDir,
  }) async {
    final soffice = await _getSoffice();
    final result = await Process.run(soffice, [
      '--headless',
      '--convert-to', 'pdf',
      '--outdir', outputDir,
      sourcePath,
    ]);

    if (result.exitCode != 0) {
      throw Exception('LibreOffice error: ${result.stderr}');
    }

    final baseName = p.basenameWithoutExtension(sourcePath);
    return p.join(outputDir, '$baseName.pdf');
  }

  static Future<String> odpToPdf({
    required String sourcePath,
    required String outputDir,
  }) async {
    final soffice = await _getSoffice();
    final result = await Process.run(soffice, [
      '--headless',
      '--convert-to', 'pdf',
      '--outdir', outputDir,
      sourcePath,
    ]);

    if (result.exitCode != 0) {
      throw Exception('LibreOffice error: ${result.stderr}');
    }

    final baseName = p.basenameWithoutExtension(sourcePath);
    return p.join(outputDir, '$baseName.pdf');
  }

  static Future<String> jsonToPdf({
    required String sourcePath,
    required String outputDir,
  }) async {
    final raw = await File(sourcePath).readAsString();
    String prettyJson;
    try {
      final decoded = jsonDecode(raw);
      prettyJson = const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      prettyJson = raw;
    }

    final tempTxt = File('${sourcePath}_temp.txt');
    await tempTxt.writeAsString(prettyJson);
    final result = await txtToPdf(sourcePath: tempTxt.path, outputDir: outputDir);
    await tempTxt.delete();

    final baseName = p.basenameWithoutExtension(sourcePath);
    final finalPath = p.join(outputDir, '$baseName.pdf');
    if (result != finalPath) await File(result).rename(finalPath);
    return finalPath;
  }

  static Future<String> xmlToPdf({
    required String sourcePath,
    required String outputDir,
  }) async {
    return txtToPdf(sourcePath: sourcePath, outputDir: outputDir);
  }

  static Future<String> yamlToPdf({
    required String sourcePath,
    required String outputDir,
  }) async {
    return txtToPdf(sourcePath: sourcePath, outputDir: outputDir);
  }

  static Future<String> logToPdf({
    required String sourcePath,
    required String outputDir,
  }) async {
    return txtToPdf(sourcePath: sourcePath, outputDir: outputDir);
  }
}
