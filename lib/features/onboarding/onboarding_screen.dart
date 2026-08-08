import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/engine/tool_resolver.dart';
import '../../core/engine/binary_downloader_service.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _selected = -1;
  bool _isScanning = true;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _downloadStatus = '';
  String? _downloadError;
  List<ToolStatus> _detectedTools = [];
  final bool _isAndroid = Platform.isAndroid;

  @override
  void initState() {
    super.initState();
    _scanSystemTools();
  }

  Future<void> _scanSystemTools() async {
    final tools = await ToolResolver.checkAllTools();
    if (!mounted) return;
    setState(() {
      _detectedTools = tools;
      _isScanning = false;
      if (tools.hasAnyConverter) {
        _selected = 1; // Powerful / Recommended
      } else {
        _selected = 0; // Default to Lightweight if no system tools found
      }
    });
  }

  List<Map<String, String>> get _engines {
    if (_isAndroid) {
      return [
        {
          'title': 'Lightweight',
          'sub': 'Images, PDF, CSV, Markdown. No setup needed.',
          'size': '~50MB',
          'icon': '⚡',
        },
        {
          'title': 'Powerful',
          'sub': 'Adds video & audio conversion via bundled ffmpeg.',
          'size': '~200MB',
          'icon': '🔧',
        },
      ];
    }
    return [
      {
        'title': 'Lightweight',
        'sub': 'Dart-only libs. Images, PDF, CSV, Markdown.',
        'size': '~50MB install',
        'icon': '⚡',
      },
      {
        'title': 'Powerful',
        'sub': 'Bundles ffmpeg + LibreOffice. Full format support.',
        'size': '~200MB install',
        'icon': '🔧',
      },
      {
        'title': 'Manual',
        'sub': "I'll install ffmpeg and LibreOffice myself.",
        'size': 'Smallest install',
        'icon': '🎛️',
      },
    ];
  }

  Future<void> _confirm() async {
    if (_selected == -1) return;

    // Check if Powerful engine is selected and binary needs downloading on desktop
    if (!_isAndroid && _selected == 1 && !_detectedTools.hasFfmpeg) {
      final isAlreadyDownloaded = await BinaryDownloaderService.isToolDownloaded('ffmpeg');
      if (!isAlreadyDownloaded) {
        await _startToolDownload('ffmpeg');
        return;
      }
    }

    await _finishOnboarding(_selected);
  }

  Future<void> _startToolDownload(String toolName) async {
    setState(() {
      _isDownloading = true;
      _downloadError = null;
      _downloadProgress = 0.05;
      _downloadStatus = 'Initializing download...';
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

      if (!mounted) return;
      await _finishOnboarding(_selected);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _downloadError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _finishOnboarding(int engineIndex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('engine', engineIndex);
    await prefs.setBool('onboarded', true);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textTertiary = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final installedTools = _detectedTools.installedTools;

    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: 480,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vaivart', style: AppTypography.label.copyWith(color: AppColors.teal, letterSpacing: 0.1)),
                const SizedBox(height: 12),
                Text('How should it work?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: textPrimary)),
                const SizedBox(height: 6),
                Text('You can change this anytime in settings.', style: AppTypography.body.copyWith(color: textTertiary)),
                
                // System Tool Detection Status Banner
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBgSecondary : AppColors.lightBgSecondary,
                    border: Border.all(color: border, width: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      if (_isScanning) ...[
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('Scanning system for conversion tools...', style: AppTypography.caption.copyWith(color: textSecondary)),
                        ),
                      ] else if (installedTools.isNotEmpty) ...[
                        const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.teal),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Detected ${installedTools.length} tool${installedTools.length > 1 ? 's' : ''} on your system:',
                                style: AppTypography.caption.copyWith(color: textPrimary, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: installedTools.map((t) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.teal.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      t.name,
                                      style: AppTypography.caption.copyWith(color: AppColors.teal, fontSize: 10, fontWeight: FontWeight.w600),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Icon(Icons.info_outline_rounded, size: 18, color: textTertiary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'No pre-installed system tools detected. Select Lightweight or download tools below.',
                            style: AppTypography.caption.copyWith(color: textSecondary),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Download Progress or Error Card
                if (_isDownloading || _downloadError != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBgSecondary : AppColors.lightBgSecondary,
                      border: Border.all(
                        color: _downloadError != null ? const Color(0xFFE24B4A) : AppColors.teal,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _downloadError != null ? Icons.error_outline_rounded : Icons.cloud_download_rounded,
                              size: 20,
                              color: _downloadError != null ? const Color(0xFFE24B4A) : AppColors.teal,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _downloadError != null ? 'Download Failed' : _downloadStatus,
                                style: AppTypography.label.copyWith(color: textPrimary, fontSize: 13),
                              ),
                            ),
                            if (_isDownloading)
                              Text(
                                '${(_downloadProgress * 100).toStringAsFixed(0)}%',
                                style: AppTypography.caption.copyWith(color: AppColors.teal, fontWeight: FontWeight.w600),
                              ),
                          ],
                        ),
                        if (_isDownloading) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _downloadProgress,
                              minHeight: 6,
                              backgroundColor: border,
                              color: AppColors.teal,
                            ),
                          ),
                        ],
                        if (_downloadError != null) ...[
                          const SizedBox(height: 8),
                          Text(_downloadError!, style: AppTypography.caption.copyWith(color: const Color(0xFFE24B4A))),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: () => _startToolDownload('ffmpeg'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.teal,
                                  foregroundColor: AppColors.tealLight,
                                  elevation: 0,
                                ),
                                child: const Text('Retry Download'),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: () => _finishOnboarding(0), // Fallback to Lightweight
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: border),
                                ),
                                child: Text('Continue with Lightweight', style: TextStyle(color: textSecondary)),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                if (_isAndroid) ...[
                  const SizedBox(height: 6),
                  Text('Note: DOCX, PPTX, and EPUB conversion is desktop-only.', style: AppTypography.caption.copyWith(color: textTertiary)),
                ],
                const SizedBox(height: 24),
                ...List.generate(_engines.length, (i) {
                  final e = _engines[i];
                  final isSelected = _selected == i;
                  final isRecommended = installedTools.isNotEmpty && (i == 1 || i == 2);

                  return GestureDetector(
                    onTap: _isDownloading ? null : () => setState(() => _selected = i),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? (isDark ? AppColors.darkBgSecondary : AppColors.lightBgSecondary) : Colors.transparent,
                        border: Border.all(color: isSelected ? AppColors.teal : border, width: isSelected ? 1.5 : 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Text(e['icon']!, style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(e['title']!, style: AppTypography.label.copyWith(color: textPrimary, fontSize: 13)),
                                    if (isRecommended) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: AppColors.teal.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Recommended',
                                          style: AppTypography.caption.copyWith(color: AppColors.teal, fontSize: 9, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(e['sub']!, style: AppTypography.caption.copyWith(color: textSecondary)),
                              ],
                            ),
                          ),
                          Text(e['size']!, style: AppTypography.caption.copyWith(color: textTertiary)),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: (_selected == -1 || _isDownloading) ? null : _confirm,
                    style: TextButton.styleFrom(
                      backgroundColor: (_selected == -1 || _isDownloading) ? border : AppColors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isDownloading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.tealLight),
                          )
                        : Text('Continue', style: AppTypography.label.copyWith(color: _selected == -1 ? textTertiary : AppColors.tealLight)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
