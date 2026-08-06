import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _selected = -1;
  final bool _isAndroid = Platform.isAndroid;

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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('engine', _selected);
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
                if (_isAndroid) ...[
                  const SizedBox(height: 6),
                  Text('Note: DOCX, PPTX, and EPUB conversion is desktop-only.', style: AppTypography.caption.copyWith(color: textTertiary)),
                ],
                const SizedBox(height: 32),
                ...List.generate(_engines.length, (i) {
                  final e = _engines[i];
                  final isSelected = _selected == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selected = i),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? (isDark ? AppColors.darkBgSecondary : AppColors.lightBgSecondary) : Colors.transparent,
                        border: Border.all(color: isSelected ? AppColors.teal : border, width: isSelected ? 1 : 0.5),
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
                                Text(e['title']!, style: AppTypography.label.copyWith(color: textPrimary, fontSize: 13)),
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
                    onPressed: _selected == -1 ? null : _confirm,
                    style: TextButton.styleFrom(
                      backgroundColor: _selected == -1 ? border : AppColors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('Continue', style: AppTypography.label.copyWith(color: _selected == -1 ? textTertiary : AppColors.tealLight)),
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
