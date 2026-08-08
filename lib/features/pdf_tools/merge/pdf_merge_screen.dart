import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/output_service.dart';
import '../../../core/converters/pdf_tools_converter.dart';

class PdfMergeScreen extends StatefulWidget {
  const PdfMergeScreen({super.key});

  @override
  State<PdfMergeScreen> createState() => _PdfMergeScreenState();
}

class _PdfMergeScreenState extends State<PdfMergeScreen> {
  final List<String> _files = [];
  bool _merging = false;
  String? _result;

  Future<void> _pickFiles() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null) return;
    setState(() {
      _files.addAll(result.files.map((f) => f.path!).where((p) => !_files.contains(p)));
    });
  }

  void _removeFile(int i) => setState(() => _files.removeAt(i));

  void _moveUp(int i) {
    if (i == 0) return;
    setState(() {
      final f = _files.removeAt(i);
      _files.insert(i - 1, f);
    });
  }

  void _moveDown(int i) {
    if (i == _files.length - 1) return;
    setState(() {
      final f = _files.removeAt(i);
      _files.insert(i + 1, f);
    });
  }

  Future<void> _merge() async {
    if (_files.length < 2) return;
    setState(() { _merging = true; _result = null; });
    try {
      final outputDir = await OutputService.getOutputDir();
      final out = await PdfToolsConverter.merge(
        sourcePaths: _files,
        outputDir: outputDir,
      );
      setState(() => _result = out);
    } catch (e) {
      setState(() => _result = 'Error: $e');
    } finally {
      setState(() => _merging = false);
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
          Text('Merge PDFs', style: AppTypography.label.copyWith(color: textSecondary)),
          const SizedBox(height: 4),
          Text('Add PDFs in order. Drag to reorder.', style: AppTypography.caption.copyWith(color: textTertiary)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _pickFiles,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: border, width: 0.5),
                borderRadius: BorderRadius.circular(6),
                color: bg,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 14, color: AppColors.teal),
                  const SizedBox(width: 6),
                  Text('Add PDFs', style: AppTypography.caption.copyWith(color: AppColors.teal)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _files.isEmpty
                ? Center(child: Text('No PDFs added yet', style: AppTypography.body.copyWith(color: textTertiary)))
                : ListView.separated(
                    itemCount: _files.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, i) {
                      final name = _files[i].split('/').last;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: bg,
                          border: Border.all(color: border, width: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28, height: 24,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: AppColors.pdfBg, borderRadius: BorderRadius.circular(4)),
                              child: Text('PDF', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: AppColors.pdfFg)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(name, style: AppTypography.body.copyWith(color: textPrimary), overflow: TextOverflow.ellipsis)),
                            IconButton(onPressed: () => _moveUp(i), icon: Icon(Icons.arrow_upward, size: 14, color: textTertiary), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                            const SizedBox(width: 8),
                            IconButton(onPressed: () => _moveDown(i), icon: Icon(Icons.arrow_downward, size: 14, color: textTertiary), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                            const SizedBox(width: 8),
                            GestureDetector(onTap: () => _removeFile(i), child: Icon(Icons.close, size: 14, color: textTertiary)),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 8),
            Text(
              _result!.startsWith('Error') ? _result! : '✓ Saved to $_result',
              style: AppTypography.caption.copyWith(
                color: _result!.startsWith('Error') ? const Color(0xFFE24B4A) : AppColors.teal,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _files.length < 2 || _merging ? null : _merge,
              style: TextButton.styleFrom(
                backgroundColor: _files.length < 2 ? border : AppColors.teal,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                _merging ? 'Merging...' : 'Merge PDFs',
                style: AppTypography.label.copyWith(color: AppColors.tealLight),
              ),
            ),
          ),
        ],
      ),
    );
  }
}