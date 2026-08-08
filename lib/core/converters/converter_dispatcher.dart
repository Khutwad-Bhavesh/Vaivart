import 'dart:io';
import 'package:vaivart/core/services/output_service.dart';
import 'package:vaivart/core/services/history_service.dart';
import 'package:vaivart/core/engine/engine_config.dart';
import 'package:vaivart/core/engine/tool_resolver.dart';
import 'image_converter.dart';
import 'pdf_converter.dart';
import 'data_converter.dart';
import 'document_converter.dart';
import 'video_converter.dart';
import 'audio_converter.dart';
import '../models/conversion_job.dart';

class ConverterDispatcher {
  // ── Format sets ────────────────────────────────────────────────
  static const _videoFormats = {'mp4', 'avi', 'mkv', 'mov', 'webm', 'flv', 'wmv', '3gp'};
  static const _audioFormats = {'mp3', 'wav', 'ogg', 'flac', 'aac', 'm4a', 'wma', 'aiff'};
  static const _imageFormats = {'jpg', 'jpeg', 'png', 'webp', 'bmp', 'tiff', 'tif', 'gif', 'ico', 'heic'};
  static const _audioTargets = {'MP3', 'WAV', 'OGG', 'FLAC', 'AAC', 'M4A', 'WMA', 'AIFF'};

  static Future<String> run(ConversionJob job) async {
    final outputDir = await OutputService.getOutputDir();
    final ext = job.extension.toLowerCase();
    final target = (job.targetFormat ?? '').toUpperCase();
    final engine = await EngineConfig.getEngine();

    String outPath;

    // ── Video ──────────────────────────────────────────────────────
    if (_videoFormats.contains(ext)) {
      // Video → Audio extraction (e.g. MP4 → MP3)
      if (_audioTargets.contains(target)) {
        if (!EngineConfig.supportsVideo(engine)) {
          throw Exception(
            Platform.isAndroid
                ? 'Audio extraction requires the Powerful engine.\nChange engine in Settings.'
                : 'Audio extraction requires Powerful or Manual engine.\nChange engine in Settings.',
          );
        }
        outPath = await VideoConverter.extractAudio(
          sourcePath: job.sourcePath,
          targetFormat: target,
          outputDir: outputDir,
        );
      }
      // Video → Video / GIF
      else {
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
    }

    // ── Audio ──────────────────────────────────────────────────────
    else if (_audioFormats.contains(ext)) {
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

    // ── RTF → PDF ─────────────────────────────────────────────────
    else if (ext == 'rtf') {
      if (!EngineConfig.supportsDesktopDocs(engine)) {
        throw Exception(
          Platform.isAndroid
              ? 'RTF → PDF is not supported on Android.\nUse the desktop app for this conversion.'
              : 'RTF → PDF requires Powerful or Manual engine.\nChange engine in Settings.',
        );
      }
      outPath = await DocumentConverter.rtfToPdf(
        sourcePath: job.sourcePath,
        outputDir: outputDir,
      );
    }

    // ── ODT → PDF ─────────────────────────────────────────────────
    else if (ext == 'odt') {
      if (!EngineConfig.supportsDesktopDocs(engine)) {
        throw Exception(
          Platform.isAndroid
              ? 'ODT → PDF is not supported on Android.\nUse the desktop app for this conversion.'
              : 'ODT → PDF requires Powerful or Manual engine.\nChange engine in Settings.',
        );
      }
      outPath = await DocumentConverter.odtToPdf(
        sourcePath: job.sourcePath,
        outputDir: outputDir,
      );
    }

    // ── ODP → PDF ─────────────────────────────────────────────────
    else if (ext == 'odp') {
      if (!EngineConfig.supportsDesktopDocs(engine)) {
        throw Exception(
          Platform.isAndroid
              ? 'ODP → PDF is not supported on Android.\nUse the desktop app for this conversion.'
              : 'ODP → PDF requires Powerful or Manual engine.\nChange engine in Settings.',
        );
      }
      outPath = await DocumentConverter.odpToPdf(
        sourcePath: job.sourcePath,
        outputDir: outputDir,
      );
    }

    // ── Images ────────────────────────────────────────────────────
    else if (_imageFormats.contains(ext)) {
      if (ext == 'heic') {
        outPath = await ImageConverter.heicToImage(
          sourcePath: job.sourcePath,
          targetFormat: target,
          outputDir: outputDir,
        );
      } else if (ext == 'svg') {
        outPath = await ImageConverter.svgToImage(
          sourcePath: job.sourcePath,
          targetFormat: target,
          outputDir: outputDir,
        );
      } else if (target == 'PDF') {
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

    // ── Data: CSV ─────────────────────────────────────────────────
    else if (ext == 'csv') {
      switch (target) {
        case 'XLSX':
          outPath = await DataConverter.csvToXlsx(sourcePath: job.sourcePath, outputDir: outputDir);
        case 'JSON':
          outPath = await DataConverter.csvToJson(sourcePath: job.sourcePath, outputDir: outputDir);
        case 'TSV':
          outPath = await DataConverter.csvToTsv(sourcePath: job.sourcePath, outputDir: outputDir);
        case 'PDF':
          outPath = await DataConverter.csvToPdf(sourcePath: job.sourcePath, outputDir: outputDir);
        default:
          throw Exception('Unsupported CSV target: $target');
      }
    }

    // ── Data: XLSX ────────────────────────────────────────────────
    else if (ext == 'xlsx') {
      switch (target) {
        case 'CSV':
          outPath = await DataConverter.xlsxToCsv(sourcePath: job.sourcePath, outputDir: outputDir);
        case 'JSON':
          outPath = await DataConverter.xlsxToJson(sourcePath: job.sourcePath, outputDir: outputDir);
        default:
          throw Exception('Unsupported XLSX target: $target');
      }
    }

    // ── Data: TSV ─────────────────────────────────────────────────
    else if (ext == 'tsv') {
      outPath = await DataConverter.tsvToCsv(sourcePath: job.sourcePath, outputDir: outputDir);
    }

    // ── Data: JSON → CSV ──────────────────────────────────────────
    else if (ext == 'json') {
      switch (target) {
        case 'CSV':
          outPath = await DataConverter.jsonToCsv(sourcePath: job.sourcePath, outputDir: outputDir);
        case 'PDF':
          outPath = await DocumentConverter.jsonToPdf(sourcePath: job.sourcePath, outputDir: outputDir);
        default:
          throw Exception('Unsupported JSON target: $target');
      }
    }

    // ── Data: ODS ─────────────────────────────────────────────────
    else if (ext == 'ods') {
      if (!EngineConfig.supportsDesktopDocs(engine)) {
        throw Exception(
          Platform.isAndroid
              ? 'ODS conversion is not supported on Android.\nUse the desktop app for this conversion.'
              : 'ODS conversion requires Powerful or Manual engine.\nChange engine in Settings.',
        );
      }
      // Use LibreOffice to convert ODS → target
      final soffice = await _findSoffice();
      final targetExt = target.toLowerCase();
      final result = await Process.run(soffice, [
        '--headless',
        '--convert-to', targetExt,
        '--outdir', outputDir,
        job.sourcePath,
      ]);
      if (result.exitCode != 0) {
        throw Exception('LibreOffice error: ${result.stderr}');
      }
      final baseName = job.fileName.split('.').first;
      outPath = '$outputDir/$baseName.$targetExt';
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
    } else if (ext == 'xml') {
      outPath = await DocumentConverter.xmlToPdf(
        sourcePath: job.sourcePath,
        outputDir: outputDir,
      );
    } else if (ext == 'yaml' || ext == 'yml') {
      outPath = await DocumentConverter.yamlToPdf(
        sourcePath: job.sourcePath,
        outputDir: outputDir,
      );
    } else if (ext == 'log') {
      outPath = await DocumentConverter.logToPdf(
        sourcePath: job.sourcePath,
        outputDir: outputDir,
      );
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

  /// Helper to find LibreOffice for ODS conversions
  static Future<String> _findSoffice() async {
    final path = await ToolResolver.findExecutable('soffice');
    if (path == null) {
      throw Exception('LibreOffice (soffice) not found. Please install LibreOffice or check your PATH in Settings.');
    }
    return path;
  }
}

