import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'tool_resolver.dart';
import 'binary_downloader_service.dart';

/// Metadata about the currently installed version of a tool binary.
class ToolVersionInfo {
  final String version;
  final String installedDate;
  final String sha256;
  final String downloadUrl;

  const ToolVersionInfo({
    required this.version,
    required this.installedDate,
    required this.sha256,
    required this.downloadUrl,
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'installedDate': installedDate,
        'sha256': sha256,
        'downloadUrl': downloadUrl,
      };

  factory ToolVersionInfo.fromJson(Map<String, dynamic> json) {
    return ToolVersionInfo(
      version: json['version'] as String? ?? '',
      installedDate: json['installedDate'] as String? ?? '',
      sha256: json['sha256'] as String? ?? '',
      downloadUrl: json['downloadUrl'] as String? ?? '',
    );
  }
}

/// Result of comparing an installed tool against the latest known version.
class ToolUpdateStatus {
  final String toolName;
  final String? installedVersion;
  final String latestVersion;
  final bool updateAvailable;
  final bool isInstalled;

  const ToolUpdateStatus({
    required this.toolName,
    required this.installedVersion,
    required this.latestVersion,
    required this.updateAvailable,
    required this.isInstalled,
  });
}

class UpdateCheckerService {
  /// Save version metadata after a successful tool download.
  static Future<void> saveVersionInfo(String toolName, DownloadToolInfo info) async {
    final binDir = await ToolResolver.getAppBinDir();
    final versionFile = File(p.join(binDir.path, '$toolName.version.json'));

    final versionInfo = ToolVersionInfo(
      version: info.version ?? 'unknown',
      installedDate: DateTime.now().toIso8601String(),
      sha256: info.expectedSha256 ?? '',
      downloadUrl: info.url,
    );

    await versionFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(versionInfo.toJson()),
    );
  }

  /// Read version metadata for a locally installed tool.
  static Future<ToolVersionInfo?> getInstalledVersion(String toolName) async {
    try {
      final binDir = await ToolResolver.getAppBinDir();
      final versionFile = File(p.join(binDir.path, '$toolName.version.json'));
      if (!await versionFile.exists()) return null;

      final content = await versionFile.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return ToolVersionInfo.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// Compare installed versions against the latest known versions from
  /// [BinaryDownloaderService.getDownloadInfo]. Returns a list of update
  /// statuses for all tools that have download configurations.
  static Future<List<ToolUpdateStatus>> checkForUpdates() async {
    final toolNames = ['ffmpeg']; // Extend as more tools are added
    final results = <ToolUpdateStatus>[];

    for (final toolName in toolNames) {
      final downloadInfo = await BinaryDownloaderService.getDownloadInfoAsync(toolName);
      if (downloadInfo == null) continue;

      final latestVersion = downloadInfo.version ?? 'unknown';
      final isDownloaded = await BinaryDownloaderService.isToolDownloaded(toolName);

      if (!isDownloaded) {
        results.add(ToolUpdateStatus(
          toolName: toolName,
          installedVersion: null,
          latestVersion: latestVersion,
          updateAvailable: false,
          isInstalled: false,
        ));
        continue;
      }

      final installed = await getInstalledVersion(toolName);

      // If there's no version file (legacy install), we can't compare
      // but we know the tool exists — treat as potentially outdated
      if (installed == null) {
        results.add(ToolUpdateStatus(
          toolName: toolName,
          installedVersion: null,
          latestVersion: latestVersion,
          updateAvailable: true, // No version file means we can't confirm it's current
          isInstalled: true,
        ));
        continue;
      }

      final updateAvailable = installed.version != latestVersion;

      results.add(ToolUpdateStatus(
        toolName: toolName,
        installedVersion: installed.version,
        latestVersion: latestVersion,
        updateAvailable: updateAvailable,
        isInstalled: true,
      ));
    }

    return results;
  }
}
