import 'dart:io';
import 'package:vaivart/core/services/output_service.dart';
import 'package:vaivart/core/services/history_service.dart';
import 'package:vaivart/core/engine/engine_config.dart';
import 'image_converter.dart';
import 'pdf_converter.dart';
import 'data_converter.dart';
import 'document_converter.dart';
import 'video_converter.dart';
import 'audio_converter.dart';
import '../models/conversion_job.dart';

class ConverterDispatcher {
  static Future<String> run(ConversionJob job) async {
    final outputDir = await OutputService.getOutputDir();
    final ext = job.extension.toLowerCase();
    final target = (job.targetFormat ?? '').toUpperCase();
    final engine = await EngineConfig.getEngine();

    String outPath;

    // ── Video ──────────────────────────────────────────────────────
    if (['mp4', 'avi', 'mkv', 'mov', 'webm'].contains(ext)) {
      if (!EngineConfig.supportsVideo(engine)) {
        throw Exception(
          Platform.isAndroid
              ? 'Video conversion requires the Powerful engine.\nChange engine in Settings.'
              : 'Video conversion requires Powerful or Manual engine.\nChange engine in Settings.',
        );
      }
      outPath = await VideoConverter.convert(
        sourcePath: job.sourcePath,
        targetFormat: target,
        outputDir: outputDir,
      );
    }

    // ── Audio ──────────────────────────────────────────────────────
    else if (['mp3', 'wav', 'ogg'].contains(ext)) {
      if (!EngineConfig.supportsAudio(engine)) {
        throw Exception(
          Platform.isAndroid
              ? 'Audio conversion requires the Powerful engine.\nChange engine in Settings.'
              : 'Audio conversion requires Powerful or Manual engine.\nChange engine in Settings.',
        );
      }
      outPath = await AudioConverter.convert(
        sourcePath: job.sourcePath,
        targetFormat: target,
        outputDir: outputDir,
      );
    }

    // ── DOCX → PDF ────────────────────────────────────────────────
    else if (ext == 'docx' && target == 'PDF') {
      if (!EngineConfig.supportsDesktopDocs(engine)) {
        throw Exception(
          Platform.isAndroid
              ? 'DOCX → PDF is not supported on Android.\nUse the desktop app for this conversion.'
              : 'DOCX → PDF requires Powerful or Manual engine.\nChange engine in Settings.',
        );
      }
      outPath = await DocumentConverter.docxToPdf(
        sourcePath: job.sourcePath,
        outputDir: outputDir,
      );
    }

    // ── PPTX → PDF ────────────────────────────────────────────────
    else if (ext == 'pptx' || ext == 'ppt') {
      if (!EngineConfig.supportsDesktopDocs(engine)) {
        throw Exception(
          Platform.isAndroid
              ? 'PPTX → PDF is not supported on Android.\nUse the desktop app for this conversion.'
              : 'PPTX → PDF requires Powerful or Manual engine.\nChange engine in Settings.',
        );
      }
      outPath = await DocumentConverter.pptxToPdf(
        sourcePath: job.sourcePath,
        outputDir: outputDir,
      );
    }

    // ── EPUB → PDF ────────────────────────────────────────────────
    else if (ext == 'epub') {
      if (!EngineConfig.supportsDesktopDocs(engine)) {
        throw Exception(
          Platform.isAndroid
              ? 'EPUB → PDF is not supported on Android.\nUse the desktop app for this conversion.'
              : 'EPUB → PDF requires Powerful or Manual engine.\nChange engine in Settings.',
        );
      }
      outPath = await DocumentConverter.epubToPdf(
        sourcePath: job.sourcePath,
        outputDir: outputDir,
      );
    }

    // ── Images ────────────────────────────────────────────────────
    else if (['jpg', 'jpeg', 'png', 'webp', 'bmp', 'heic'].contains(ext)) {
      if (target == 'PDF') {
        outPath = await PdfConverter.imageToPdf(
          imagePaths: [job.sourcePath],
          outputDir: outputDir,
          baseName: job.fileName.split('.').first,
        );
      } else {
        outPath = await ImageConverter.convert(
          sourcePath: job.sourcePath,
          targetFormat: target,
          outputDir: outputDir,
        );
      }
    }

    // ── SVG ───────────────────────────────────────────────────────
    else if (ext == 'svg') {
      outPath = await ImageConverter.svgToImage(
        sourcePath: job.sourcePath,
        targetFormat: target,
        outputDir: outputDir,
      );
    }

    // ── Data ──────────────────────────────────────────────────────
    else if (ext == 'csv') {
      outPath = await DataConverter.csvToXlsx(
        sourcePath: job.sourcePath,
        outputDir: outputDir,
      );
    } else if (ext == 'xlsx') {
      outPath = await DataConverter.xlsxToCsv(
        sourcePath: job.sourcePath,
        outputDir: outputDir,
      );
    }

    // ── Documents (pure Dart) ─────────────────────────────────────
    else if (ext == 'txt') {
      outPath = await DocumentConverter.txtToPdf(
        sourcePath: job.sourcePath,
        outputDir: outputDir,
      );
    } else if (ext == 'md' || ext == 'markdown') {
      outPath = await DocumentConverter.mdToPdf(
        sourcePath: job.sourcePath,
        outputDir: outputDir,
      );
    } else if (ext == 'html' || ext == 'htm') {
      // HTML → PDF: try LibreOffice on desktop, pure Dart fallback on Android
      if (Platform.isAndroid) {
        outPath = await DocumentConverter.htmlToPdfDart(
          sourcePath: job.sourcePath,
          outputDir: outputDir,
        );
      } else {
        if (!EngineConfig.supportsDesktopDocs(engine)) {
          outPath = await DocumentConverter.htmlToPdfDart(
            sourcePath: job.sourcePath,
            outputDir: outputDir,
          );
        } else {
          outPath = await DocumentConverter.htmlToPdf(
            sourcePath: job.sourcePath,
            outputDir: outputDir,
          );
        }
      }
    } else if (ext == 'pdf' && target == 'DOCX') {
      if (Platform.isAndroid) {
        throw Exception('PDF → DOCX is not supported on Android.\nUse the desktop app for this conversion.');
      }
      outPath = await DocumentConverter.pdfToDocx(
        sourcePath: job.sourcePath,
        outputDir: outputDir,
      );
    }

    else {
      throw Exception('Unsupported conversion: $ext → $target');
    }

    await HistoryService.addEntry(HistoryEntry(
      fileName: job.fileName,
      fromFormat: ext.toUpperCase(),
      toFormat: target,
      outputPath: outPath,
      convertedAt: DateTime.now(),
      success: true,
    ));

    return outPath;
  }
}
