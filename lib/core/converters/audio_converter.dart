import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

import '../engine/tool_resolver.dart';

class AudioConverter {
  static Future<String> convert({
    required String sourcePath,
    required String targetFormat,
    required String outputDir,
  }) async {
    final baseName = p.basenameWithoutExtension(sourcePath);
    final outPath = p.join(outputDir, '$baseName.${targetFormat.toLowerCase()}');
    final args = _buildArgs(sourcePath: sourcePath, outPath: outPath, targetFormat: targetFormat.toUpperCase());

    if (Platform.isAndroid) {
      final cmd = args.join(' ');
      final session = await FFmpegKit.execute(cmd);
      final rc = await session.getReturnCode();
      if (!ReturnCode.isSuccess(rc)) {
        final logs = await session.getLogsAsString();
        throw Exception('ffmpeg audio error: $logs');
      }
    } else {
      final ffmpegPath = await ToolResolver.findExecutable('ffmpeg');
      if (ffmpegPath == null) {
        throw Exception('ffmpeg not found. Please install ffmpeg or check Settings.');
      }
      final result = await Process.run(ffmpegPath, args);
      if (result.exitCode != 0) {
        throw Exception('ffmpeg audio error: ${result.stderr}');
      }
    }

    return outPath;
  }

  static List<String> _buildArgs({
    required String sourcePath,
    required String outPath,
    required String targetFormat,
  }) {
    final base = ['-i', sourcePath, '-y'];
    switch (targetFormat) {
      case 'MP3':
        return [...base, '-codec:a', 'libmp3lame', '-q:a', '2', outPath];
      case 'WAV':
        return [...base, '-codec:a', 'pcm_s16le', outPath];
      case 'OGG':
        return [...base, '-codec:a', 'libvorbis', '-q:a', '4', outPath];
      case 'FLAC':
        return [...base, '-codec:a', 'flac', outPath];
      case 'AAC':
        return [...base, '-codec:a', 'aac', '-b:a', '192k', outPath];
      case 'M4A':
        return [...base, '-codec:a', 'aac', '-b:a', '192k', outPath];
      case 'WMA':
        return [...base, '-codec:a', 'wmav2', '-b:a', '192k', outPath];
      case 'AIFF':
        return [...base, '-codec:a', 'pcm_s16be', outPath];
      case 'OPUS':
        return [...base, '-codec:a', 'libopus', '-b:a', '128k', outPath];
      case 'AMR':
        return [...base, '-codec:a', 'libopencore_amrnb', '-ar', '8000', '-ac', '1', outPath];
      case 'AC3':
        return [...base, '-codec:a', 'ac3', '-b:a', '192k', outPath];
      case 'AU':
        return [...base, '-codec:a', 'pcm_s16be', '-f', 'au', outPath];
      case 'DTS':
        return [...base, '-codec:a', 'dca', '-b:a', '768k', outPath];
      case 'RA':
        return [...base, '-codec:a', 'real_144', '-f', 'rm', outPath];
      default:
        return [...base, outPath];
    }
  }
}
