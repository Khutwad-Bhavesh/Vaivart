import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/services/output_service.dart';
import '../../core/engine/tool_resolver.dart';
import '../../core/engine/engine_downloader.dart';

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

    _refreshTools();
  }

  Future<void> _refreshTools() async {
    setState(() => _loadingTools = true);
    ToolResolver.clearCache();
    final statuses = await ToolResolver.checkAllTools();
    if (!mounted) return;
    setState(() {
      _toolStatuses = statuses;
      _loadingTools = false;
    });
  }

  Future<void> _setEngine(int val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('engine', val);
    setState(() => _engine = val);
  }

  Future<void> _pickOutputDir() async {
    final result = await FilePicker.platform.getDirectoryPath();
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
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final bg = isDark ? AppColors.darkBgSecondary : AppColors.lightBgSecondary;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textTertiary = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;

    return SingleChildScrollView(
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
                      ..._toolStatuses.map((t) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: t.isInstalled ? AppColors.teal : Colors.orangeAccent,
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
                                const Spacer(),
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
                          )),
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
                            color: isDark ? Colors.black26 : Colors.black.withOpacity(0.05),
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
                                tooltip: 'Copy install command',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
          ),

          const SizedBox(height: 24),
          _SectionHeader(label: 'OUTPUT FOLDER', textTertiary: textTertiary),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pickOutputDir,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: bg,
                border: Border.all(color: border, width: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.folder_outlined, size: 14, color: textTertiary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_outputDir, style: AppTypography.caption.copyWith(color: textSecondary), overflow: TextOverflow.ellipsis),
                  ),
                  Text('change', style: AppTypography.caption.copyWith(color: AppColors.teal)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(label: 'ABOUT', textTertiary: textTertiary),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bg,
              border: Border.all(color: border, width: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vaivart', style: AppTypography.label.copyWith(color: textPrimary)),
                const SizedBox(height: 4),
                Text('Free, offline, open source file converter. Optimized for low-end hardware.', style: AppTypography.caption.copyWith(color: textTertiary)),
                const SizedBox(height: 8),
                Text('v1.0.0', style: AppTypography.caption.copyWith(color: textTertiary)),
              ],
            ),
          ),
        ],
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
    return Text(label, style: AppTypography.sectionHeader.copyWith(color: textTertiary));
  }
}