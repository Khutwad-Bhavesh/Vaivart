import 'dart:io';

class PackageInstallCommand {
  final String osName;
  final String command;
  final String packageManager;

  const PackageInstallCommand({
    required this.osName,
    required this.command,
    required this.packageManager,
  });
}

class EngineDownloader {
  /// Detect distro/OS and return copyable package installation commands
  static Future<PackageInstallCommand> getRecommendedInstallCommand() async {
    if (Platform.isWindows) {
      return const PackageInstallCommand(
        osName: 'Windows',
        command: 'winget install Gyan.FFmpeg LibreOffice.LibreOffice calibre.calibre',
        packageManager: 'winget',
      );
    }

    if (Platform.isMacOS) {
      return const PackageInstallCommand(
        osName: 'macOS',
        command: 'brew install ffmpeg libreoffice calibre',
        packageManager: 'Homebrew',
      );
    }

    if (Platform.isLinux) {
      try {
        final osRelease = await File('/etc/os-release').readAsString();
        final lower = osRelease.toLowerCase();

        if (lower.contains('arch') || lower.contains('manjaro') || lower.contains('endeavouros')) {
          return const PackageInstallCommand(
            osName: 'Arch Linux',
            command: 'sudo pacman -S ffmpeg libreoffice-fresh calibre libheif',
            packageManager: 'pacman',
          );
        }

        if (lower.contains('fedora') || lower.contains('rhel') || lower.contains('centos')) {
          return const PackageInstallCommand(
            osName: 'Fedora / RHEL',
            command: 'sudo dnf install ffmpeg libreoffice calibre',
            packageManager: 'dnf',
          );
        }

        if (lower.contains('ubuntu') || lower.contains('debian') || lower.contains('mint') || lower.contains('pop')) {
          return const PackageInstallCommand(
            osName: 'Ubuntu / Debian',
            command: 'sudo apt update && sudo apt install -y ffmpeg libreoffice calibre libheif-examples',
            packageManager: 'apt',
          );
        }
      } catch (_) {}

      return const PackageInstallCommand(
        osName: 'Linux',
        command: 'sudo apt install -y ffmpeg libreoffice calibre',
        packageManager: 'apt',
      );
    }

    return const PackageInstallCommand(
      osName: 'Android',
      command: 'FFmpeg Kit integrated natively.',
      packageManager: 'native',
    );
  }
}
