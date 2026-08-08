import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:vaivart/core/converters/converter_dispatcher.dart';
import 'package:vaivart/core/engine/engine_config.dart';
import 'package:vaivart/core/engine/tool_resolver.dart';
import 'package:vaivart/core/models/conversion_job.dart';
import 'package:vaivart/core/services/history_service.dart';
import 'package:vaivart/core/services/output_service.dart';
import 'tui_ansi.dart';

class TuiApp {
  bool _running = true;

  // Supported extensions map
  static const Map<String, List<String>> _targetFormatMap = {
    // Images
    'png': ['JPG', 'WEBP', 'PDF', 'BMP', 'GIF', 'ICO', 'TIFF'],
    'jpg': ['PNG', 'WEBP', 'PDF', 'BMP', 'GIF', 'ICO', 'TIFF'],
    'jpeg': ['PNG', 'WEBP', 'PDF', 'BMP', 'GIF', 'ICO', 'TIFF'],
    'webp': ['PNG', 'JPG', 'PDF', 'BMP', 'GIF', 'ICO'],
    'bmp': ['PNG', 'JPG', 'WEBP', 'PDF'],
    'gif': ['PNG', 'JPG', 'MP4', 'WEBP'],
    'svg': ['PNG', 'JPG', 'PDF'],
    'ico': ['PNG', 'JPG'],

    // Documents
    'pdf': ['PNG', 'JPG', 'TXT'],
    'docx': ['PDF', 'TXT', 'HTML'],
    'pptx': ['PDF'],
    'ppt': ['PDF'],
    'md': ['PDF', 'HTML'],
    'txt': ['PDF', 'HTML'],
    'html': ['PDF', 'TXT'],
    'epub': ['PDF', 'TXT'],

    // Audio
    'mp3': ['WAV', 'FLAC', 'AAC', 'OGG', 'M4A', 'OPUS', 'WMA'],
    'wav': ['MP3', 'FLAC', 'AAC', 'OGG', 'M4A', 'OPUS'],
    'flac': ['MP3', 'WAV', 'AAC', 'OGG', 'M4A'],
    'm4a': ['MP3', 'WAV', 'FLAC', 'AAC', 'OGG'],
    'ogg': ['MP3', 'WAV', 'FLAC', 'AAC', 'M4A'],
    'aac': ['MP3', 'WAV', 'FLAC', 'OGG'],

    // Video
    'mp4': ['MKV', 'AVI', 'MOV', 'WEBM', 'GIF', 'MP3', 'WAV', 'FLAC', 'AAC'],
    'mkv': ['MP4', 'AVI', 'MOV', 'WEBM', 'MP3', 'WAV', 'FLAC'],
    'avi': ['MP4', 'MKV', 'MOV', 'WEBM', 'MP3', 'WAV'],
    'mov': ['MP4', 'MKV', 'AVI', 'WEBM', 'MP3', 'WAV'],
    'webm': ['MP4', 'MKV', 'AVI', 'MP3', 'WAV'],
    'flv': ['MP4', 'MP3', 'WAV'],

    // Data
    'csv': ['JSON', 'XLSX'],
    'json': ['CSV'],
    'xlsx': ['CSV', 'JSON', 'PDF'],
  };

  /// Launch main interactive TUI loop
  Future<void> run() async {
    while (_running) {
      TuiAnsi.clearScreen();
      stdout.write(TuiAnsi.getBanner());

      final outputDir = await OutputService.getOutputDir();
      final engine = await EngineConfig.getEngine();

      stdout.writeln(
        '  ${TuiAnsi.bold}${TuiAnsi.white}Engine Mode:${TuiAnsi.reset} ${TuiAnsi.emerald}${engine.name.toUpperCase()}${TuiAnsi.reset}  │  '
        '${TuiAnsi.bold}${TuiAnsi.white}Output Dir:${TuiAnsi.reset} ${TuiAnsi.skyBlue}$outputDir${TuiAnsi.reset}\n',
      );

      stdout.writeln('${TuiAnsi.bold}${TuiAnsi.cyan}  MAIN MENU${TuiAnsi.reset}');
      stdout.writeln('  ${TuiAnsi.gold}[1]${TuiAnsi.reset} 📁  Convert a File');
      stdout.writeln('  ${TuiAnsi.gold}[2]${TuiAnsi.reset} ⚡  Batch File Conversion Queue');
      stdout.writeln('  ${TuiAnsi.gold}[3]${TuiAnsi.reset} 📊  System & Tool Inspector');
      stdout.writeln('  ${TuiAnsi.gold}[4]${TuiAnsi.reset} 📜  Conversion History Log');
      stdout.writeln('  ${TuiAnsi.gold}[5]${TuiAnsi.reset} ⚙️   Settings & Configuration');
      stdout.writeln('  ${TuiAnsi.gold}[6]${TuiAnsi.reset} ❓  Supported Formats Matrix');
      stdout.writeln('  ${TuiAnsi.gold}[q]${TuiAnsi.reset} 🚪  Exit TUI\n');

      stdout.write('${TuiAnsi.cyan}${TuiAnsi.bold}Select option [1-6, q]: ${TuiAnsi.reset}');
      final choice = _readLine().trim().toLowerCase();

      switch (choice) {
        case '1':
          await _convertSingleFile();
          break;
        case '2':
          await _convertBatchQueue();
          break;
        case '3':
          await _showSystemTools();
          break;
        case '4':
          await _showHistory();
          break;
        case '5':
          await _showSettings();
          break;
        case '6':
          await _showFormatMatrix();
          break;
        case 'q':
        case 'exit':
          _running = false;
          TuiAnsi.clearScreen();
          stdout.writeln('${TuiAnsi.emerald}Thank you for using Vaivart TUI. Goodbye!${TuiAnsi.reset}\n');
          return;
        default:
          stdout.writeln('${TuiAnsi.coralRed}Invalid choice. Press Enter to try again.${TuiAnsi.reset}');
          _readLine();
      }
    }
  }

  /// Interactive Single File Conversion Flow
  Future<void> _convertSingleFile() async {
    TuiAnsi.clearScreen();
    stdout.write(TuiAnsi.getBanner());
    stdout.writeln('${TuiAnsi.bold}${TuiAnsi.cyan}📁 SINGLE FILE CONVERTER${TuiAnsi.reset}\n');

    stdout.write('${TuiAnsi.bold}${TuiAnsi.white}Enter source file path (or drag & drop file here): ${TuiAnsi.reset}');
    var inputPath = _readLine().trim();

    // Clean drag & drop quotes if any
    if ((inputPath.startsWith("'") && inputPath.endsWith("'")) ||
        (inputPath.startsWith('"') && inputPath.endsWith('"'))) {
      inputPath = inputPath.substring(1, inputPath.length - 1);
    }

    if (inputPath.isEmpty) return;

    final file = File(inputPath);
    if (!file.existsSync()) {
      stdout.writeln('\n${TuiAnsi.coralRed}Error: File does not exist at path: "$inputPath"${TuiAnsi.reset}');
      _promptPressEnter();
      return;
    }

    final ext = p.extension(inputPath).toLowerCase().replaceAll('.', '');
    final targets = _targetFormatMap[ext];

    stdout.writeln('\n${TuiAnsi.emerald}✔ File verified:${TuiAnsi.reset} ${p.basename(inputPath)} (${(file.lengthSync() / 1024).toStringAsFixed(1)} KB)');
    stdout.writeln('${TuiAnsi.dim}Detected extension: .$ext${TuiAnsi.reset}\n');

    String targetFormat;
    if (targets == null || targets.isEmpty) {
      stdout.write('${TuiAnsi.bold}${TuiAnsi.gold}Unknown format extension .$ext. Type desired output format manually (e.g. PDF, PNG, MP3): ${TuiAnsi.reset}');
      targetFormat = _readLine().trim().toUpperCase();
    } else {
      stdout.writeln('${TuiAnsi.bold}${TuiAnsi.cyan}Select target format:${TuiAnsi.reset}');
      for (var i = 0; i < targets.length; i++) {
        stdout.writeln('  ${TuiAnsi.gold}[${i + 1}]${TuiAnsi.reset} ${targets[i]}');
      }
      stdout.write('\n${TuiAnsi.cyan}Select target [1-${targets.length}] or type extension: ${TuiAnsi.reset}');
      final inputFmt = _readLine().trim();
      final selIdx = int.tryParse(inputFmt);
      if (selIdx != null && selIdx >= 1 && selIdx <= targets.length) {
        targetFormat = targets[selIdx - 1];
      } else {
        targetFormat = inputFmt.toUpperCase();
      }
    }

    if (targetFormat.isEmpty) {
      stdout.writeln('${TuiAnsi.coralRed}No target format specified. Aborting.${TuiAnsi.reset}');
      _promptPressEnter();
      return;
    }

    await _executeJob(inputPath, targetFormat);
    _promptPressEnter();
  }

  /// Interactive Batch File Queue Converter
  Future<void> _convertBatchQueue() async {
    TuiAnsi.clearScreen();
    stdout.write(TuiAnsi.getBanner());
    stdout.writeln('${TuiAnsi.bold}${TuiAnsi.cyan}⚡ BATCH FILE CONVERSION QUEUE${TuiAnsi.reset}\n');

    stdout.writeln('${TuiAnsi.dim}Enter multiple file paths separated by commas or newlines (empty line to finish):${TuiAnsi.reset}');

    final paths = <String>[];
    while (true) {
      stdout.write('${TuiAnsi.gold}File ${paths.length + 1} path > ${TuiAnsi.reset}');
      var line = _readLine().trim();
      if (line.isEmpty) break;

      // Handle quotes
      if ((line.startsWith("'") && line.endsWith("'")) ||
          (line.startsWith('"') && line.endsWith('"'))) {
        line = line.substring(1, line.length - 1);
      }

      final splits = line.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
      for (final s in splits) {
        if (File(s).existsSync()) {
          paths.add(s);
          stdout.writeln('  ${TuiAnsi.emerald}+ Added:${TuiAnsi.reset} ${p.basename(s)}');
        } else {
          stdout.writeln('  ${TuiAnsi.coralRed}x File not found:${TuiAnsi.reset} $s');
        }
      }
    }

    if (paths.isEmpty) {
      stdout.writeln('\n${TuiAnsi.gold}No valid files in batch queue.${TuiAnsi.reset}');
      _promptPressEnter();
      return;
    }

    stdout.write('\n${TuiAnsi.bold}${TuiAnsi.cyan}Enter target format for all queued files (e.g. PDF, PNG, MP3): ${TuiAnsi.reset}');
    final targetFmt = _readLine().trim().toUpperCase();

    if (targetFmt.isEmpty) {
      stdout.writeln('${TuiAnsi.coralRed}Target format required.${TuiAnsi.reset}');
      _promptPressEnter();
      return;
    }

    stdout.writeln('\n${TuiAnsi.bold}${TuiAnsi.cyan}Starting batch process of ${paths.length} file(s)...${TuiAnsi.reset}\n');

    int successCount = 0;
    final stopwatch = Stopwatch()..start();

    for (int i = 0; i < paths.length; i++) {
      final currentPath = paths[i];
      stdout.writeln('--------------------------------------------------');
      stdout.writeln('${TuiAnsi.bold}[${i + 1}/${paths.length}]${TuiAnsi.reset} Processing: ${p.basename(currentPath)}');

      final ok = await _executeJob(currentPath, targetFmt);
      if (ok) successCount++;
    }

    stopwatch.stop();
    stdout.writeln('\n==================================================');
    stdout.writeln(
      '${TuiAnsi.emerald}${TuiAnsi.bold}Batch complete!${TuiAnsi.reset} '
      'Processed $successCount / ${paths.length} successfully in ${stopwatch.elapsedMilliseconds} ms.',
    );
    _promptPressEnter();
  }

  /// Execute single conversion job
  Future<bool> _executeJob(String sourcePath, String targetFormat) async {
    final startTime = DateTime.now();
    final fileName = p.basename(sourcePath);
    final ext = p.extension(sourcePath).replaceAll('.', '');

    stdout.writeln('\n${TuiAnsi.statusBadge("CONVERTING...", warning: true)} $fileName → $targetFormat');
    stdout.write('${TuiAnsi.progressBar(0.3)} Initializing engine dispatcher...\r');

    try {
      final job = ConversionJob.fromFile(sourcePath).copyWith(targetFormat: targetFormat);

      stdout.write('${TuiAnsi.progressBar(0.6)} Processing conversion...\r');
      final outPath = await ConverterDispatcher.run(job);

      stdout.writeln('\n${TuiAnsi.statusBadge("SUCCESS")} Output saved to:');
      stdout.writeln('  ${TuiAnsi.bold}${TuiAnsi.skyBlue}$outPath${TuiAnsi.reset}');

      await HistoryService.addEntry(
        HistoryEntry(
          fileName: fileName,
          fromFormat: ext.toUpperCase(),
          toFormat: targetFormat,
          outputPath: outPath,
          convertedAt: startTime,
          success: true,
        ),
      );
      return true;
    } catch (e) {
      stdout.writeln('\n${TuiAnsi.statusBadge("FAILED", success: false)} Error: $e');

      await HistoryService.addEntry(
        HistoryEntry(
          fileName: fileName,
          fromFormat: ext.toUpperCase(),
          toFormat: targetFormat,
          outputPath: '',
          convertedAt: startTime,
          success: false,
        ),
      );
      return false;
    }
  }

  /// System Tools & Converter Engine Inspector
  Future<void> _showSystemTools() async {
    TuiAnsi.clearScreen();
    stdout.write(TuiAnsi.getBanner());
    stdout.writeln('${TuiAnsi.bold}${TuiAnsi.cyan}📊 SYSTEM & ENGINE INSPECTOR${TuiAnsi.reset}\n');

    final engine = await EngineConfig.getEngine();
    stdout.writeln('  ${TuiAnsi.bold}Current Engine Setting:${TuiAnsi.reset} ${TuiAnsi.emerald}${engine.name.toUpperCase()}${TuiAnsi.reset}');
    stdout.writeln('  ${TuiAnsi.dim}Platform: ${Platform.operatingSystem} (${Platform.operatingSystemVersion})${TuiAnsi.reset}\n');

    stdout.writeln('${TuiAnsi.bold}${TuiAnsi.white}Installed Binary Tools Matrix:${TuiAnsi.reset}');

    final tools = [
      {'name': 'FFmpeg (Video/Audio)', 'exe': 'ffmpeg'},
      {'name': 'LibreOffice (Office Docs -> PDF)', 'exe': 'soffice'},
      {'name': 'Calibre (eBooks / EPUB)', 'exe': 'ebook-convert'},
      {'name': 'Pandoc (Markdown/HTML/Doc)', 'exe': 'pandoc'},
      {'name': 'Ghostscript (PDF Compression)', 'exe': 'gs'},
      {'name': 'Inkscape (SVG Rasterization)', 'exe': 'inkscape'},
    ];

    for (final tool in tools) {
      final exe = tool['exe']!;
      final path = await ToolResolver.findExecutable(exe);
      if (path != null) {
        stdout.writeln('  ${TuiAnsi.emerald}✔ ${tool['name']}${TuiAnsi.reset}');
        stdout.writeln('    ${TuiAnsi.dim}Path: $path${TuiAnsi.reset}');
      } else {
        stdout.writeln('  ${TuiAnsi.coralRed}✖ ${tool['name']}${TuiAnsi.reset} ${TuiAnsi.dim}(Not found in PATH)${TuiAnsi.reset}');
      }
    }

    _promptPressEnter();
  }

  /// View Conversion History Log
  Future<void> _showHistory() async {
    TuiAnsi.clearScreen();
    stdout.write(TuiAnsi.getBanner());
    stdout.writeln('${TuiAnsi.bold}${TuiAnsi.cyan}📜 CONVERSION HISTORY LOG${TuiAnsi.reset}\n');

    final history = await HistoryService.getHistory();

    if (history.isEmpty) {
      stdout.writeln('  ${TuiAnsi.dim}No conversion history recorded yet.${TuiAnsi.reset}');
    } else {
      stdout.writeln('  ${TuiAnsi.bold}${TuiAnsi.white}Recent Jobs (Total: ${history.length}):${TuiAnsi.reset}\n');
      for (var i = 0; i < history.length && i < 20; i++) {
        final item = history[i];
        final badge = item.success
            ? '${TuiAnsi.emerald}[ OK ]${TuiAnsi.reset}'
            : '${TuiAnsi.coralRed}[FAIL]${TuiAnsi.reset}';
        final timeStr = '${item.convertedAt.hour.toString().padLeft(2, '0')}:${item.convertedAt.minute.toString().padLeft(2, '0')}';
        stdout.writeln('  $badge ${TuiAnsi.dim}$timeStr${TuiAnsi.reset} ${TuiAnsi.bold}${item.fileName}${TuiAnsi.reset} (${item.fromFormat} → ${item.toFormat})');
        if (item.success) {
          stdout.writeln('         ${TuiAnsi.dim}└─ ${item.outputPath}${TuiAnsi.reset}');
        }
      }
    }

    stdout.writeln('\n  ${TuiAnsi.gold}[c]${TuiAnsi.reset} Clear history  │  ${TuiAnsi.gold}[Enter]${TuiAnsi.reset} Back');
    stdout.write('\nSelect option: ');
    final ans = _readLine().trim().toLowerCase();
    if (ans == 'c') {
      await HistoryService.clearHistory();
      stdout.writeln('\n${TuiAnsi.emerald}History cleared.${TuiAnsi.reset}');
      _promptPressEnter();
    }
  }

  /// Change Settings
  Future<void> _showSettings() async {
    TuiAnsi.clearScreen();
    stdout.write(TuiAnsi.getBanner());
    stdout.writeln('${TuiAnsi.bold}${TuiAnsi.cyan}⚙️ SETTINGS & CONFIGURATION${TuiAnsi.reset}\n');

    final currentOutput = await OutputService.getOutputDir();
    final currentEngine = await EngineConfig.getEngine();

    stdout.writeln('  ${TuiAnsi.bold}[1]${TuiAnsi.reset} Output Directory: ${TuiAnsi.skyBlue}$currentOutput${TuiAnsi.reset}');
    stdout.writeln('  ${TuiAnsi.bold}[2]${TuiAnsi.reset} Conversion Engine: ${TuiAnsi.emerald}${currentEngine.name.toUpperCase()}${TuiAnsi.reset}');
    stdout.writeln('  ${TuiAnsi.bold}[q]${TuiAnsi.reset} Back to Main Menu\n');

    stdout.write('${TuiAnsi.cyan}Select option to change [1-2, q]: ${TuiAnsi.reset}');
    final choice = _readLine().trim().toLowerCase();

    if (choice == '1') {
      stdout.write('\n${TuiAnsi.bold}Enter new absolute output directory path: ${TuiAnsi.reset}');
      final newPath = _readLine().trim();
      if (newPath.isNotEmpty) {
        final dir = Directory(newPath);
        if (!dir.existsSync()) {
          try {
            dir.createSync(recursive: true);
          } catch (e) {
            stdout.writeln('${TuiAnsi.coralRed}Failed to create directory: $e${TuiAnsi.reset}');
            _promptPressEnter();
            return;
          }
        }
        await OutputService.setOutputDir(newPath);
        stdout.writeln('${TuiAnsi.emerald}Output directory updated to: $newPath${TuiAnsi.reset}');
        _promptPressEnter();
      }
    } else if (choice == '2') {
      stdout.writeln('\n${TuiAnsi.bold}Select Engine Mode:${TuiAnsi.reset}');
      stdout.writeln('  [0] Lightweight (Pure Dart, zero system tool requirements)');
      stdout.writeln('  [1] Powerful (Uses system binaries FFmpeg/LibreOffice when available)');
      stdout.writeln('  [2] Manual');
      stdout.write('Select [0-2]: ');
      final sel = int.tryParse(_readLine().trim());
      if (sel != null && sel >= 0 && sel <= 2) {
        await EngineConfig.setEngine(EngineType.values[sel]);
        stdout.writeln('${TuiAnsi.emerald}Engine set to ${EngineType.values[sel].name.toUpperCase()}${TuiAnsi.reset}');
        _promptPressEnter();
      }
    }
  }

  /// Show Format Matrix
  Future<void> _showFormatMatrix() async {
    TuiAnsi.clearScreen();
    stdout.write(TuiAnsi.getBanner());
    stdout.writeln('${TuiAnsi.bold}${TuiAnsi.cyan}❓ SUPPORTED FORMATS MATRIX${TuiAnsi.reset}\n');

    stdout.writeln('  ${TuiAnsi.bold}${TuiAnsi.emerald}Category        Supported Input -> Target Formats${TuiAnsi.reset}');
    stdout.writeln('  ─────────────── ───────────────────────────────────────────────────');
    stdout.writeln('  📷 Images        PNG, JPG, WEBP, BMP, GIF, SVG, ICO -> PNG/JPG/WEBP/PDF');
    stdout.writeln('  📄 Documents     DOCX, PPTX, PPT, EPUB, TXT, MD, HTML -> PDF/HTML/TXT');
    stdout.writeln('  🎵 Audio         MP3, WAV, FLAC, M4A, OGG, AAC, OPUS -> MP3/WAV/FLAC');
    stdout.writeln('  🎬 Video         MP4, MKV, AVI, MOV, WEBM, FLV -> MP4/MKV/GIF/MP3');
    stdout.writeln('  📊 Data          CSV, JSON, XLSX -> CSV/JSON/XLSX');
    stdout.writeln('  📕 PDF Tools     Extract text/images, convert to images, merge/split');

    _promptPressEnter();
  }

  void _promptPressEnter() {
    stdout.write('\n${TuiAnsi.dim}Press Enter to return...${TuiAnsi.reset}');
    _readLine();
  }

  String _readLine() {
    return stdin.readLineSync() ?? '';
  }
}
