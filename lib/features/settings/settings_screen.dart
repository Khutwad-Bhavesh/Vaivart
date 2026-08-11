import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/services/output_service.dart';
import '../../core/engine/tool_resolver.dart';
import '../../core/engine/engine_downloader.dart';
import '../../core/engine/binary_downloader_service.dart';
import '../../core/engine/update_checker_service.dart';
import '../../core/engine/engine_config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _engine = 0;
  String _outputDir = '';
  List<ToolStatus> _toolStatuses = [];
  PackageInstallCommand? _installCommand;
  bool _loadingTools = true;
  bool _copied = false;

  bool _isDownloadingTool = false;
  double _downloadProgress = 0.0;
  String _downloadStatus = '';
  List<ToolUpdateStatus> _updateStatuses = [];
  int _ffmpegBuildType = 0; // 0 = GPL, 1 = LGPL

  final _engines = ['Lightweight', 'Powerful', 'Manual'];
  final _engineSubs = [
    'Pure Dart conversion engines, zero external dependencies (~50MB)',
    'Uses system / bundled ffmpeg & LibreOffice for heavy media & docs (~200MB)',
    'Uses custom executables from system PATH or local app bin folder',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final dir = await OutputService.getOutputDir();
    final command = await EngineDownloader.getRecommendedInstallCommand();

    setState(() {
      _engine = prefs.getInt('engine') ?? 0;
      _outputDir = dir;
      _installCommand = command;
    });

    _loadFfmpegBuildType();
    _refreshTools();
  }

  Future<void> _loadFfmpegBuildType() async {
    final buildType = await EngineConfig.getFfmpegBuildType();
    if (!mounted) return;
    setState(() => _ffmpegBuildType = buildType.index);
  }

  Future<void> _refreshTools() async {
    setState(() => _loadingTools = true);
    final tools = await ToolResolver.checkAllTools();
    final updates = await UpdateCheckerService.checkForUpdates();
    if (!mounted) return;
    setState(() {
      _toolStatuses = tools;
      _updateStatuses = updates;
      _loadingTools = false;
    });
  }

  Future<void> _downloadTool(String toolName) async {
    setState(() {
      _isDownloadingTool = true;
      _downloadProgress = 0.05;
      _downloadStatus = 'Starting download...';
    });

    try {
      await BinaryDownloaderService.downloadTool(
        toolName: toolName,
        onProgress: (progress, status) {
          if (!mounted) return;
          setState(() {
            _downloadProgress = progress;
            _downloadStatus = status;
          });
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: ${e.toString().replaceAll("Exception: ", "")}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloadingTool = false);
        _refreshTools();
      }
    }
  }

  Future<void> _setEngine(int val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('engine', val);
    setState(() => _engine = val);
  }

  Future<void> _setFfmpegBuildType(int val) async {
    if (val == _ffmpegBuildType) return;
    final newBuild = FfmpegBuildType.values[val];
    final isDownloaded = await BinaryDownloaderService.isToolDownloaded('ffmpeg');

    if (isDownloaded && mounted) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
          final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
          return AlertDialog(
            backgroundColor: isDark ? AppColors.darkBgSecondary : AppColors.lightBgSecondary,
            title: Text('Switch FFmpeg Build?', style: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
            content: Text(
              'Switching build type requires re-downloading FFmpeg. The existing binary will be replaced.\n\nContinue?',
              style: TextStyle(color: textSecondary, fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text('Cancel', style: TextStyle(color: textSecondary)),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Re-download', style: TextStyle(color: AppColors.teal)),
              ),
            ],
          );
        },
      );
      if (confirmed != true) return;
    }

    await EngineConfig.setFfmpegBuildType(newBuild);
    setState(() => _ffmpegBuildType = val);

    if (isDownloaded) {
      // Delete old binary and version file, then re-download
      try {
        final binDir = await ToolResolver.getAppBinDir();
        final info = BinaryDownloaderService.getDownloadInfo('ffmpeg', buildType: FfmpegBuildType.values[_ffmpegBuildType == 0 ? 1 : 0]);
        if (info != null) {
          final oldBinary = File('${binDir.path}/${info.binaryFileName}');
          final oldVersion = File('${binDir.path}/ffmpeg.version.json');
          if (await oldBinary.exists()) await oldBinary.delete();
          if (await oldVersion.exists()) await oldVersion.delete();
          ToolResolver.clearCache();
        }
      } catch (_) {}
      _downloadTool('ffmpeg');
    }
  }

  Future<void> _pickOutputDir() async {
    final result = await FilePicker.getDirectoryPath();
    if (result == null) return;
    await OutputService.setOutputDir(result);
    setState(() => _outputDir = result);
  }

  void _copyCommand() {
    if (_installCommand == null) return;
    Clipboard.setData(ClipboardData(text: _installCommand!.command));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBgSecondary : AppColors.lightBgSecondary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textTertiary = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary)),
            const SizedBox(height: 24),
            _SectionHeader(label: 'CONVERSION ENGINE', textTertiary: textTertiary),
            const SizedBox(height: 10),
            ...List.generate(_engines.length, (i) {
              final isSelected = _engine == i;
              return GestureDetector(
                onTap: () => _setEngine(i),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected ? (isDark ? AppColors.darkBgTertiary : AppColors.lightBgTertiary) : bg,
                    border: Border.all(color: isSelected ? AppColors.teal : border, width: isSelected ? 1 : 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_engines[i], style: AppTypography.label.copyWith(color: textPrimary)),
                            const SizedBox(height: 2),
                            Text(_engineSubs[i], style: AppTypography.caption.copyWith(color: textTertiary)),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.teal),
                        ),
                    ],
                  ),
                ),
              );
            }),

            // FFmpeg Build Type section — only visible for Powerful / Manual engines
            if (_engine != 0) ...[
              const SizedBox(height: 24),
              _SectionHeader(label: 'FFMPEG BUILD TYPE', textTertiary: textTertiary),
              const SizedBox(height: 4),
              Text(
                Platform.isMacOS
                    ? 'macOS only has GPL builds available.'
                    : 'Choose which FFmpeg variant to use for media conversions.',
                style: AppTypography.caption.copyWith(color: textTertiary),
              ),
              if (!Platform.isMacOS) ...[
                const SizedBox(height: 10),
                ...[
                  {
                    'title': 'GPL',
                    'sub': 'Full codec support — x264, x265, libfdk-aac, libass. Larger download.',
                    'index': 0,
                  },
                  {
                    'title': 'LGPL',
                    'sub': 'Lighter build, fewer codecs. More permissive license.',
                    'index': 1,
                  },
                ].map((opt) {
                  final i = opt['index'] as int;
                  final isSelected = _ffmpegBuildType == i;
                  return GestureDetector(
                    onTap: _isDownloadingTool ? null : () => _setFfmpegBuildType(i),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected ? (isDark ? AppColors.darkBgTertiary : AppColors.lightBgTertiary) : bg,
                        border: Border.all(color: isSelected ? AppColors.teal : border, width: isSelected ? 1 : 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(opt['title'] as String, style: AppTypography.label.copyWith(color: textPrimary)),
                                const SizedBox(height: 2),
                                Text(opt['sub'] as String, style: AppTypography.caption.copyWith(color: textTertiary)),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Container(
                              width: 8, height: 8,
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.teal),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ],

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SectionHeader(label: 'ENGINE DIAGNOSTICS & SYSTEM TOOLS', textTertiary: textTertiary),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 16),
                  color: AppColors.teal,
                  tooltip: 'Re-scan system dependencies',
                  onPressed: _refreshTools,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: bg,
                border: Border.all(color: border, width: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _loadingTools
                  ? const Center(child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isDownloadingTool) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkBgTertiary : AppColors.lightBgTertiary,
                              border: Border.all(color: AppColors.teal, width: 0.5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.cloud_download_rounded, size: 16, color: AppColors.teal),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(_downloadStatus, style: AppTypography.caption.copyWith(color: textPrimary, fontWeight: FontWeight.w600)),
                                    ),
                                    Text(
                                      '${(_downloadProgress * 100).toStringAsFixed(0)}%',
                                      style: AppTypography.caption.copyWith(color: AppColors.teal, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    value: _downloadProgress,
                                    minHeight: 4,
                                    backgroundColor: border,
                                    color: AppColors.teal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        ..._toolStatuses.map((t) {
                          final canDownload = !t.isInstalled && BinaryDownloaderService.getDownloadInfo(t.name) != null;
                          final updateStatus = _updateStatuses.cast<ToolUpdateStatus?>().firstWhere(
                            (u) => u?.toolName == t.name,
                            orElse: () => null,
                          );
                          final hasUpdate = updateStatus != null && updateStatus.updateAvailable && t.isInstalled;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: t.isInstalled
                                        ? (hasUpdate ? Colors.amber : AppColors.teal)
                                        : Colors.orangeAccent,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  t.name,
                                  style: AppTypography.label.copyWith(color: textPrimary),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '(${t.category})',
                                  style: AppTypography.caption.copyWith(color: textTertiary),
                                ),
                                if (hasUpdate) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'v${updateStatus.installedVersion ?? "?"} → v${updateStatus.latestVersion}',
                                      style: AppTypography.caption.copyWith(color: Colors.amber.shade700, fontSize: 9, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                                const Spacer(),
                                if (hasUpdate && !_isDownloadingTool) ...[
                                  GestureDetector(
                                    onTap: () => _downloadTool(t.name),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.system_update_alt_rounded, size: 12, color: Colors.amber.shade700),
                                          const SizedBox(width: 4),
                                          Text('Update', style: AppTypography.caption.copyWith(color: Colors.amber.shade700, fontSize: 10, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ] else if (canDownload && !_isDownloadingTool) ...[
                                  GestureDetector(
                                    onTap: () => _downloadTool(t.name),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.teal.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.download_rounded, size: 12, color: AppColors.teal),
                                          const SizedBox(width: 4),
                                          Text('Download', style: AppTypography.caption.copyWith(color: AppColors.teal, fontSize: 10, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Text(
                                  t.isInstalled ? (t.path ?? 'Installed') : 'Not Found',
                                  style: AppTypography.caption.copyWith(
                                    color: t.isInstalled ? AppColors.teal : textTertiary,
                                    fontSize: 11,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          );
                        }),
                        if (_installCommand != null) ...[
                          const Divider(height: 20),
                          Text(
                            'Install missing tools for ${_installCommand!.osName}:',
                            style: AppTypography.caption.copyWith(color: textSecondary, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: SelectableText(
                                    _installCommand!.command,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 11,
                                      color: textPrimary,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(_copied ? Icons.check : Icons.copy, size: 14),
                                  color: AppColors.teal,
                                  onPressed: _copyCommand,
                                  tooltip: 'Copy command',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
            ),

            const SizedBox(height: 24),
            _SectionHeader(label: 'OUTPUT DIRECTORY', textTertiary: textTertiary),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: bg,
                border: Border.all(color: border, width: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _outputDir.isEmpty ? 'Loading...' : _outputDir,
                      style: AppTypography.body.copyWith(color: textPrimary, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _pickOutputDir,
                    icon: const Icon(Icons.folder_open_outlined, size: 14),
                    label: const Text('Change'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textPrimary,
                      side: BorderSide(color: border, width: 0.5),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: AppTypography.caption,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color textTertiary;
  const _SectionHeader({required this.label, required this.textTertiary});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.caption.copyWith(color: textTertiary, fontWeight: FontWeight.w600, letterSpacing: 0.08),
    );
  }
}