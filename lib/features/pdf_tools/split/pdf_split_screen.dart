import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/output_service.dart';
import '../../../core/converters/pdf_tools_converter.dart';

enum SplitMode { range, everyN, oddEven }

class PdfSplitScreen extends StatefulWidget {
  const PdfSplitScreen({super.key});

  @override
  State<PdfSplitScreen> createState() => _PdfSplitScreenState();
}

class _PdfSplitScreenState extends State<PdfSplitScreen> {
  String? _filePath;
  SplitMode _mode = SplitMode.range;
  final _rangeController = TextEditingController(text: '1-3,5,7-9');
  final _nController = TextEditingController(text: '2');
  bool _splitting = false;
  String? _result;

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null) return;
    setState(() => _filePath = result.files.first.path);
  }

  Future<void> _split() async {
    if (_filePath == null) return;
    setState(() { _splitting = true; _result = null; });
    try {
      final outputDir = await OutputService.getOutputDir();
      final List<String> outputs;
      switch (_mode) {
        case SplitMode.range:
          outputs = await PdfToolsConverter.splitByRange(
            sourcePath: _filePath!,
            outputDir: outputDir,
            rangeStr: _rangeController.text,
          );
        case SplitMode.everyN:
          outputs = await PdfToolsConverter.splitEveryN(
            sourcePath: _filePath!,
            outputDir: outputDir,
            n: int.tryParse(_nController.text) ?? 1,
          );
        case SplitMode.oddEven:
          outputs = await PdfToolsConverter.splitOddEven(
            sourcePath: _filePath!,
            outputDir: outputDir,
          );
      }
      setState(() => _result = '✓ ${outputs.length} file(s) saved');
    } catch (e) {
      setState(() => _result = 'Error: $e');
    } finally {
      setState(() => _splitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final bg = isDark ? AppColors.darkBgSecondary : AppColors.lightBgSecondary;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textTertiary = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Split PDF', style: AppTypography.label.copyWith(color: textSecondary)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _pickFile,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: _filePath != null ? AppColors.teal : border, width: 0.5),
                borderRadius: BorderRadius.circular(8),
                color: bg,
              ),
              child: Row(
                children: [
                  Icon(Icons.picture_as_pdf_outlined, size: 14, color: textTertiary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _filePath?.split('/').last ?? 'Select a PDF',
                      style: AppTypography.caption.copyWith(color: _filePath != null ? textPrimary : textTertiary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Split by', style: AppTypography.caption.copyWith(color: textTertiary)),
          const SizedBox(height: 8),
          Row(
            children: [
              _ModeChip(label: 'Page range', active: _mode == SplitMode.range, onTap: () => setState(() => _mode = SplitMode.range)),
              const SizedBox(width: 8),
              _ModeChip(label: 'Every N pages', active: _mode == SplitMode.everyN, onTap: () => setState(() => _mode = SplitMode.everyN)),
              const SizedBox(width: 8),
              _ModeChip(label: 'Odd / Even', active: _mode == SplitMode.oddEven, onTap: () => setState(() => _mode = SplitMode.oddEven)),
            ],
          ),
          const SizedBox(height: 16),
          if (_mode == SplitMode.range) ...[
            Text('Ranges (e.g. 1-3,5,7-9)', style: AppTypography.caption.copyWith(color: textTertiary)),
            const SizedBox(height: 6),
            TextField(
              controller: _rangeController,
              style: AppTypography.body.copyWith(color: textPrimary),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: border, width: 0.5), borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppColors.teal, width: 1), borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
          if (_mode == SplitMode.everyN) ...[
            Text('Split every N pages', style: AppTypography.caption.copyWith(color: textTertiary)),
            const SizedBox(height: 6),
            SizedBox(
              width: 80,
              child: TextField(
                controller: _nController,
                keyboardType: TextInputType.number,
                style: AppTypography.body.copyWith(color: textPrimary),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: border, width: 0.5), borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppColors.teal, width: 1), borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
          if (_mode == SplitMode.oddEven)
            Text('Splits into odd pages PDF and even pages PDF', style: AppTypography.caption.copyWith(color: textTertiary)),
          const Spacer(),
          if (_result != null) ...[
            Text(
              _result!,
              style: AppTypography.caption.copyWith(
                color: _result!.startsWith('Error') ? const Color(0xFFE24B4A) : AppColors.teal,
              ),
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _filePath == null || _splitting ? null : _split,
              style: TextButton.styleFrom(
                backgroundColor: _filePath == null ? border : AppColors.teal,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                _splitting ? 'Splitting...' : 'Split PDF',
                style: AppTypography.label.copyWith(color: AppColors.tealLight),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ModeChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppColors.teal : Colors.transparent,
          border: Border.all(color: active ? AppColors.teal : AppColors.darkBorder, width: 0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: AppTypography.caption.copyWith(color: active ? AppColors.tealLight : AppColors.darkTextSecondary)),
      ),
    );
  }
}