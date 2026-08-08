import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'tool_resolver.dart';

class DownloadToolInfo {
  final String toolName;
  final String url;
  final String archiveType; // 'zip', 'tar.xz', 'binary'
  final String binaryFileName;
  final String fileSizeMB;
  final String? expectedSha256;

  const DownloadToolInfo({
    required this.toolName,
    required this.url,
    required this.archiveType,
    required this.binaryFileName,
    required this.fileSizeMB,
    this.expectedSha256,
  });
}

class BinaryDownloaderService {
  /// Get static download URL and info per tool and platform
  static DownloadToolInfo? getDownloadInfo(String toolName) {
    final name = toolName.toLowerCase();
    if (name == 'ffmpeg') {
      if (Platform.isLinux) {
        return const DownloadToolInfo(
          toolName: 'ffmpeg',
          url: 'https://github.com/BtbN/FFmpeg-Builds/releases/download/autobuild-2025-08-31-13-00/ffmpeg-n6.1.3-linux64-gpl-6.1.tar.xz',
          archiveType: 'tar.xz',
          binaryFileName: 'ffmpeg',
          fileSizeMB: '~100MB',
          expectedSha256: '400f9ca9d8ea3f812660cf7a00b9bfed944175cd9d6bd0c9b6257cf99376a75c',
        );
      } else if (Platform.isWindows) {
        return const DownloadToolInfo(
          toolName: 'ffmpeg',
          url: 'https://github.com/BtbN/FFmpeg-Builds/releases/download/autobuild-2025-08-31-13-00/ffmpeg-n6.1.3-win64-gpl-6.1.zip',
          archiveType: 'zip',
          binaryFileName: 'ffmpeg.exe',
          fileSizeMB: '~130MB',
          expectedSha256: '7142408984a0b63de725e885632af4d80e7824c0d86161577fd227641a6749dc',
        );
      } else if (Platform.isMacOS) {
        return const DownloadToolInfo(
          toolName: 'ffmpeg',
          url: 'https://evermeet.cx/ffmpeg/ffmpeg-6.1.1.zip',
          archiveType: 'zip',
          binaryFileName: 'ffmpeg',
          fileSizeMB: '~25MB',
          expectedSha256: '7de74c26a20dd172ed49c7de6035ee0790c83e69e461c3a6895b33ae0787e513',
        );
      }
    }
    return null;
  }

  /// Check if binary is already installed locally in app bin folder
  static Future<bool> isToolDownloaded(String toolName) async {
    final info = getDownloadInfo(toolName);
    final targetName = info?.binaryFileName ?? toolName;
    final binDir = await ToolResolver.getAppBinDir();
    final file = File(p.join(binDir.path, targetName));
    return file.exists();
  }

  /// Streamed HTTP download and install of static standalone binary
  static Future<String> downloadTool({
    required String toolName,
    required Function(double progress, String status) onProgress,
  }) async {
    final info = getDownloadInfo(toolName);
    if (info == null) {
      throw Exception('No static download configuration found for $toolName on this platform.');
    }

    onProgress(0.05, 'Preparing download for ${info.toolName} (${info.fileSizeMB})...');

    final binDir = await ToolResolver.getAppBinDir();
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 15);

    try {
      final request = await client.getUrl(Uri.parse(info.url));
      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('Download failed with HTTP status code ${response.statusCode}');
      }

      final contentLength = response.contentLength;
      final tempFile = File(p.join(binDir.path, '${info.toolName}_temp.${info.archiveType}'));
      final sink = tempFile.openWrite();

      int downloaded = 0;
      await for (final chunk in response) {
        downloaded += chunk.length;
        sink.add(chunk);

        if (contentLength > 0) {
          final progress = 0.05 + (downloaded / contentLength) * 0.75;
          final percentStr = (progress * 100).toStringAsFixed(0);
          onProgress(progress, 'Downloading ${info.toolName}... $percentStr%');
        } else {
          onProgress(0.5, 'Downloading ${info.toolName}... (${(downloaded / (1024 * 1024)).toStringAsFixed(1)} MB)');
        }
      }

      await sink.flush();
      await sink.close();

      onProgress(0.85, 'Validating download...');

      if (info.expectedSha256 != null) {
        final hashStream = tempFile.openRead();
        final digest = await sha256.bind(hashStream).first;
        final actualSha256 = digest.toString();
        if (actualSha256 != info.expectedSha256) {
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
          throw Exception('Security Error: Checksum mismatch. The downloaded file may be corrupted.\nExpected: ${info.expectedSha256}\nGot: $actualSha256');
        }
      }

      onProgress(0.90, 'Extracting and installing ${info.toolName}...');

      final installedFile = await _extractAndInstall(
        archiveFile: tempFile,
        info: info,
        binDir: binDir,
      );

      // Clean up temp archive file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      // Clear ToolResolver cache so new binary is detected immediately
      ToolResolver.clearCache();

      onProgress(1.0, '${info.toolName} installed successfully!');
      return installedFile.path;
    } finally {
      client.close();
    }
  }

  /// Unpack archive and place target executable into app bin directory
  static Future<File> _extractAndInstall({
    required File archiveFile,
    required DownloadToolInfo info,
    required Directory binDir,
  }) async {
    final targetFile = File(p.join(binDir.path, info.binaryFileName));

    if (info.archiveType == 'zip') {
      try {
        final bytes = await archiveFile.readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);
        for (final file in archive) {
          if (file.isFile && (file.name.endsWith(info.binaryFileName) || p.basename(file.name) == info.binaryFileName)) {
            final data = file.content as List<int>;
            await targetFile.writeAsBytes(data);
            break;
          }
        }
      } catch (_) {
        // Fallback: try native unzip if system has it
        if (Platform.isLinux || Platform.isMacOS) {
          await Process.run('unzip', ['-o', archiveFile.path, info.binaryFileName, '-d', binDir.path]);
        }
      }
    } else if (info.archiveType == 'tar.xz') {
      // Use native tar for fast .tar.xz extraction on Linux/macOS
      try {
        final result = await Process.run('tar', [
          '-xvf', archiveFile.path,
          '--strip-components=1',
          '--wildcards', '*/${info.binaryFileName}',
          '-C', binDir.path,
        ]);
        if (result.exitCode != 0) {
          // Alternative tar syntax without wildcards
          await Process.run('tar', ['-xf', archiveFile.path, '-C', binDir.path]);
        }
      } catch (_) {}
    } else {
      // Direct binary file copy
      await archiveFile.copy(targetFile.path);
    }

    // Set executable permissions on Unix/Linux/macOS
    if (Platform.isLinux || Platform.isMacOS) {
      try {
        await Process.run('chmod', ['+x', targetFile.path]);
      } catch (_) {}
    }

    return targetFile;
  }
}
