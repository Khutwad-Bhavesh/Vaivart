import 'dart:io';
import 'pdf_tools_helper.dart';
import 'package:path/path.dart' as p;

class PdfToolsConverter {
  static Future<String> merge({
    required List<String> sourcePaths,
    required String outputDir,
  }) async {
    final mergedDoc = PdfDocument();

    for (final path in sourcePaths) {
      final bytes = await File(path).readAsBytes();
      final srcDoc = PdfDocument(inputBytes: bytes);
      final count = srcDoc.pages.count;

      for (int i = 0; i < count; i++) {
        final template = srcDoc.pages[i].createTemplate();
        final page = mergedDoc.pages.add();
        page.graphics.drawPdfTemplate(
          template,
          Offset.zero,
          Size(page.getClientSize().width, page.getClientSize().height),
        );
      }
      srcDoc.dispose();
    }

    final outPath = p.join(outputDir, 'merged_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await File(outPath).writeAsBytes(await mergedDoc.save());
    mergedDoc.dispose();
    return outPath;
  }

  static Future<List<String>> splitByRange({
    required String sourcePath,
    required String outputDir,
    required String rangeStr,
  }) async {
    final bytes = await File(sourcePath).readAsBytes();
    final srcDoc = PdfDocument(inputBytes: bytes);
    final pages = _parseRanges(rangeStr);
    final baseName = p.basenameWithoutExtension(sourcePath);
    final outputs = <String>[];

    for (final pageNum in pages) {
      if (pageNum < 1 || pageNum > srcDoc.pages.count) continue;
      final pdf = PdfDocument();
      final template = srcDoc.pages[pageNum - 1].createTemplate();
      final page = pdf.pages.add();
      page.graphics.drawPdfTemplate(
        template,
        Offset.zero,
        Size(page.getClientSize().width, page.getClientSize().height),
      );
      final outPath = p.join(outputDir, '${baseName}_page$pageNum.pdf');
      await File(outPath).writeAsBytes(await pdf.save());
      pdf.dispose();
      outputs.add(outPath);
    }

    srcDoc.dispose();
    return outputs;
  }

  static Future<List<String>> splitEveryN({
    required String sourcePath,
    required String outputDir,
    required int n,
  }) async {
    final bytes = await File(sourcePath).readAsBytes();
    final srcDoc = PdfDocument(inputBytes: bytes);
    final total = srcDoc.pages.count;
    final baseName = p.basenameWithoutExtension(sourcePath);
    final outputs = <String>[];
    int chunk = 1;

    for (int start = 0; start < total; start += n) {
      final pdf = PdfDocument();
      final end = (start + n).clamp(0, total);
      for (int i = start; i < end; i++) {
        final template = srcDoc.pages[i].createTemplate();
        final page = pdf.pages.add();
        page.graphics.drawPdfTemplate(
          template,
          Offset.zero,
          Size(page.getClientSize().width, page.getClientSize().height),
        );
      }
      final outPath = p.join(outputDir, '${baseName}_part$chunk.pdf');
      await File(outPath).writeAsBytes(await pdf.save());
      pdf.dispose();
      outputs.add(outPath);
      chunk++;
    }

    srcDoc.dispose();
    return outputs;
  }

  static Future<List<String>> splitOddEven({
    required String sourcePath,
    required String outputDir,
  }) async {
    final bytes = await File(sourcePath).readAsBytes();
    final srcDoc = PdfDocument(inputBytes: bytes);
    final baseName = p.basenameWithoutExtension(sourcePath);
    final outputs = <String>[];

    for (final isOdd in [true, false]) {
      final pdf = PdfDocument();
      for (int i = 0; i < srcDoc.pages.count; i++) {
        final pageNum = i + 1;
        if (isOdd ? pageNum.isOdd : pageNum.isEven) {
          final template = srcDoc.pages[i].createTemplate();
          final page = pdf.pages.add();
          page.graphics.drawPdfTemplate(
            template,
            Offset.zero,
            Size(page.getClientSize().width, page.getClientSize().height),
          );
        }
      }
      final label = isOdd ? 'odd' : 'even';
      final outPath = p.join(outputDir, '${baseName}_$label.pdf');
      await File(outPath).writeAsBytes(await pdf.save());
      pdf.dispose();
      outputs.add(outPath);
    }

    srcDoc.dispose();
    return outputs;
  }

  static List<int> _parseRanges(String rangeStr) {
    final pages = <int>{};
    final parts = rangeStr.split(',');
    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.contains('-')) {
        final bounds = trimmed.split('-');
        final start = int.tryParse(bounds[0].trim()) ?? 1;
        final end = int.tryParse(bounds[1].trim()) ?? start;
        for (int i = start; i <= end; i++) {
          pages.add(i);
        }
      } else {
        final page = int.tryParse(trimmed);
        if (page != null) pages.add(page);
      }
    }
    return pages.toList()..sort();
  }
}