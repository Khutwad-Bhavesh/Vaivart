import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:vaivart/core/converters/converter_dispatcher.dart';
import 'package:vaivart/core/engine/engine_config.dart';
import 'package:vaivart/core/engine/tool_resolver.dart';
import 'package:vaivart/core/models/conversion_job.dart';
import 'package:vaivart/core/services/history_service.dart';
import 'package:vaivart/core/services/output_service.dart';
import 'package:vaivart/tui/tui_ansi.dart';
import 'package:vaivart/tui/tui_app.dart';

void main(List<String> args) async {
  if (args.isEmpty || args.contains('-i') || args.contains('--interactive') || args.contains('tui')) {
    await TuiApp().run();
    return;
  }

  final command = args[0].toLowerCase();

  switch (command) {
    case 'convert':
    case '-c':
      await _handleConvertCli(args.sublist(1));
      break;

    case 'tools':
    case 'inspector':
      await _handleToolsCli();
      break;

    case 'history':
    case 'log':
      await _handleHistoryCli();
      break;

    case 'help':
    case '-h':
    case '--help':
      _printHelp();
      break;

    default:
      // Direct file conversion shorthand: vaivart input.png -t pdf
      if (File(command).existsSync()) {
        await _handleConvertCli(args);
      } else {
        stdout.writeln('${TuiAnsi.coralRed}Unknown command or file not found: $command${TuiAnsi.reset}\n');
        _printHelp();
        exit(1);
      }
  }
}

Future<void> _handleConvertCli(List<String> args) async {
  if (args.isEmpty) {
    stdout.writeln('${TuiAnsi.coralRed}Error: Source file path required for conversion.${TuiAnsi.reset}');
    stdout.writeln('Usage: vaivart convert <source_file> -t <target_format> [-o <output_dir>]\n');
    exit(1);
  }

  String? sourcePath;
  String? targetFormat;
  String? outputDir;

  for (int i = 0; i < args.length; i++) {
    final arg = args[i];
    if ((arg == '-t' || arg == '--target') && i + 1 < args.length) {
      targetFormat = args[i + 1].toUpperCase();
      i++;
    } else if ((arg == '-o' || arg == '--output') && i + 1 < args.length) {
      outputDir = args[i + 1];
      i++;
    } else if (sourcePath == null && !arg.startsWith('-')) {
      sourcePath = arg;
    }
  }

  if (sourcePath == null || !File(sourcePath).existsSync()) {
    stdout.writeln('${TuiAnsi.coralRed}Error: Valid source file path required.${TuiAnsi.reset}');
    exit(1);
  }

  if (targetFormat == null || targetFormat.isEmpty) {
    stdout.writeln('${TuiAnsi.coralRed}Error: Target format required (-t <format>).${TuiAnsi.reset}');
    stdout.writeln('Example: vaivart convert sample.docx -t pdf');
    exit(1);
  }

  if (outputDir != null) {
    await OutputService.setOutputDir(outputDir);
  }

  final fileName = p.basename(sourcePath);
  final ext = p.extension(sourcePath).replaceAll('.', '');

  stdout.writeln('${TuiAnsi.cyan}${TuiAnsi.bold}Vaivart CLI Conversion${TuiAnsi.reset}');
  stdout.writeln('  Source: $fileName');
  stdout.writeln('  Target: $targetFormat');

  final startTime = DateTime.now();

  try {
    final job = ConversionJob.fromFile(sourcePath).copyWith(targetFormat: targetFormat);

    final outPath = await ConverterDispatcher.run(job);

    stdout.writeln('\n${TuiAnsi.emerald}${TuiAnsi.bold}✔ Conversion successful!${TuiAnsi.reset}');
    stdout.writeln('  Output file: ${TuiAnsi.skyBlue}$outPath${TuiAnsi.reset}');

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
  } catch (e) {
    stdout.writeln('\n${TuiAnsi.coralRed}${TuiAnsi.bold}✖ Conversion failed!${TuiAnsi.reset}');
    stdout.writeln('  Reason: $e');

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
    exit(1);
  }
}

Future<void> _handleToolsCli() async {
  final engine = await EngineConfig.getEngine();
  stdout.writeln('${TuiAnsi.cyan}${TuiAnsi.bold}Vaivart System Tools & Engine Matrix${TuiAnsi.reset}');
  stdout.writeln('Engine Mode: ${engine.name.toUpperCase()}\n');

  final tools = ['ffmpeg', 'soffice', 'ebook-convert', 'pandoc', 'gs', 'inkscape'];
  for (final exe in tools) {
    final path = await ToolResolver.findExecutable(exe);
    if (path != null) {
      stdout.writeln('  ${TuiAnsi.emerald}✔ $exe${TuiAnsi.reset}: $path');
    } else {
      stdout.writeln('  ${TuiAnsi.coralRed}✖ $exe${TuiAnsi.reset}: Not found');
    }
  }
}

Future<void> _handleHistoryCli() async {
  final history = await HistoryService.getHistory();
  stdout.writeln('${TuiAnsi.cyan}${TuiAnsi.bold}Vaivart Conversion History${TuiAnsi.reset} (Total: ${history.length})\n');

  for (final item in history.take(15)) {
    final status = item.success ? '${TuiAnsi.emerald}[OK]${TuiAnsi.reset}' : '${TuiAnsi.coralRed}[FAIL]${TuiAnsi.reset}';
    stdout.writeln('$status ${item.fileName} (${item.fromFormat} -> ${item.toFormat}) => ${item.outputPath}');
  }
}

void _printHelp() {
  stdout.write(TuiAnsi.getBanner());
  stdout.writeln('''
${TuiAnsi.bold}${TuiAnsi.cyan}USAGE:${TuiAnsi.reset}
  dart run bin/vaivart_tui.dart [COMMAND] [OPTIONS]

${TuiAnsi.bold}${TuiAnsi.cyan}COMMANDS:${TuiAnsi.reset}
  (no args)                        Launch interactive Terminal UI (TUI)
  convert <file> -t <target>       Convert file to specified target format
  tools                            Check system conversion tools (FFmpeg, LibreOffice, etc.)
  history                          Show past conversion logs
  help                             Show this help message

${TuiAnsi.bold}${TuiAnsi.cyan}OPTIONS:${TuiAnsi.reset}
  -t, --target <FORMAT>            Target format (e.g. PDF, PNG, MP3, WEBP)
  -o, --output <DIR>               Custom output directory path
  -i, --interactive                Force interactive TUI dashboard mode

${TuiAnsi.bold}${TuiAnsi.cyan}EXAMPLES:${TuiAnsi.reset}
  dart run bin/vaivart_tui.dart
  dart run bin/vaivart_tui.dart convert document.docx -t pdf
  dart run bin/vaivart_tui.dart convert video.mp4 -t mp3 -o ~/Music
''');
}
