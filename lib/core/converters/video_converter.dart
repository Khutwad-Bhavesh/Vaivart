import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:ffmpeg_kit_flutter_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_audio/return_code.dart';

import '../engine/tool_resolver.dart';

class VideoConverter {
  static Future<String> convert({
    required String sourcePath,
    required String targetFormat,
    required String outputDir,
  }) async {
    final baseName = p.basenameWithoutExtension(sourcePath);
    final outPath = p.join(outputDir, '$baseName.${targetFormat.toLowerCase()}');
    final args = _buildArgs(sourcePath: sourcePath, outPath: outPath, targetFormat: targetFormat.toUpperCase());

    if (Platform.isAndroid) {
      // Use ffmpeg_kit on Android
      final cmd = args.join(' ');
      final session = await FFmpegKit.execute(cmd);
      final rc = await session.getReturnCode();
      if (!ReturnCode.isSuccess(rc)) {
        final logs = await session.getLogsAsString();
        throw Exception('ffmpeg error: $logs');
      }
    } else {
      // Desktop: ffmpeg resolved dynamically
      final ffmpegPath = await ToolResolver.findExecutable('ffmpeg');
      if (ffmpegPath == null) {
        throw Exception('ffmpeg not found. Please install ffmpeg or check Settings.');
      }
      final result = await Process.run(ffmpegPath, args);
      if (result.exitCode != 0) {
        throw Exception('ffmpeg error: ${result.stderr}');
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
      case 'MP4':
        return [...base, '-c:v', 'libx264', '-c:a', 'aac', outPath];
      case 'AVI':
        return [...base, '-c:v', 'libxvid', '-c:a', 'mp3', outPath];
      case 'MKV':
        return [...base, '-c:v', 'libx264', '-c:a', 'aac', outPath];
      case 'GIF':
        return [
          '-i', sourcePath, '-y',
          '-vf', 'fps=10,scale=480:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse',
          '-loop', '0',
          outPath,
        ];
      case 'WEBM':
        return [...base, '-c:v', 'libvpx-vp9', '-c:a', 'libopus', '-b:v', '2M', outPath];
      case 'MOV':
        return [...base, '-c:v', 'libx264', '-c:a', 'aac', outPath];
      case 'FLV':
        return [...base, '-c:v', 'libx264', '-c:a', 'aac', '-f', 'flv', outPath];
      case 'WMV':
        return [...base, '-c:v', 'wmv2', '-c:a', 'wmav2', outPath];
      case '3GP':
        return [...base, '-c:v', 'h263', '-c:a', 'aac', '-s', '352x288', outPath];
      default:
        return [...base, outPath];
    }
  }
  static Future<String> extractAudio({
    required String sourcePath,
    required String targetFormat,
    required String outputDir,
  }) async {
    final baseName = p.basenameWithoutExtension(sourcePath);
    final outPath = p.join(outputDir, '$baseName.${targetFormat.toLowerCase()}');
    final args = ['-i', sourcePath, '-y', '-vn', '-codec:a', 'copy', outPath];

    if (Platform.isAndroid) {
      final cmd = args.join(' ');
      final session = await FFmpegKit.execute(cmd);
      final rc = await session.getReturnCode();
      if (!ReturnCode.isSuccess(rc)) {
        final logs = await session.getLogsAsString();
        throw Exception('ffmpeg extract audio error: $logs');
      }
    } else {
      final ffmpegPath = await ToolResolver.findExecutable('ffmpeg');
      if (ffmpegPath == null) {
        throw Exception('ffmpeg not found. Please install ffmpeg or check Settings.');
      }
      final result = await Process.run(ffmpegPath, args);
      if (result.exitCode != 0) {
        throw Exception('ffmpeg extract audio error: ${result.stderr}');
      }
    }

    return outPath;
  }
}
