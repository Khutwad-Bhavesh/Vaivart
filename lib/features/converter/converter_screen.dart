import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/conversion_job.dart';
import '../../core/converters/converter_dispatcher.dart';
import '../../core/services/output_service.dart';
import 'widgets/drop_zone.dart';
import 'widgets/queue_item_tile.dart';

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  final List<ConversionJob> _queue = [];
  String _outputDir = '';
  int _doneCount = 0;
  bool _converting = false;

  @override
  void initState() {
    super.initState();
    _loadOutputDir();
  }

  Future<void> _loadOutputDir() async {
    final dir = await OutputService.getOutputDir();
    setState(() => _outputDir = dir);
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );
    if (result == null) return;
    setState(() {
      for (final f in result.files) {
        if (f.path != null) _queue.add(ConversionJob.fromFile(f.path!));
      }
    });
  }

  Future<void> _pickOutputDir() async {
    final result = await FilePicker.getDirectoryPath();
    if (result == null) return;
    await OutputService.setOutputDir(result);
    setState(() => _outputDir = result);
  }

  void _removeJob(int index) => setState(() => _queue.removeAt(index));

  void _updateFormat(int index, String format) {
    setState(() => _queue[index] = _queue[index].copyWith(targetFormat: format));
  }

  Future<void> _convertAll() async {
    setState(() { _converting = true; _doneCount = 0; });
    for (int i = 0; i < _queue.length; i++) {
      setState(() => _queue[i] = _queue[i].copyWith(status: JobStatus.converting));
      try {
        await ConverterDispatcher.run(_queue[i]);
        setState(() {
          _queue[i] = _queue[i].copyWith(status: JobStatus.done);
          _doneCount++;
        });
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        debugPrint('Conversion error: $e');
        setState(() => _queue[i] = _queue[i].copyWith(status: JobStatus.failed));
  if (e.toString().contains('engine')) {
    _showEngineError(e.toString().replaceAll('Exception: ', ''));
  }
}
    }
    setState(() => _converting = false);
  }
void _showEngineError(String message) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkBgSecondary
          : AppColors.lightBg,
      title: Text('Engine limitation',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkText
                : AppColors.lightText,
          )),
      content: Text(message,
          style: AppTypography.body.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          )),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('OK', style: TextStyle(color: AppColors.teal)),
        ),
      ],
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textTertiary = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropZone(onFilesDropped: _pickFiles),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pickOutputDir,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: border, width: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.folder_outlined, size: 14, color: textTertiary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _outputDir.isEmpty ? 'Loading...' : _outputDir,
                      style: AppTypography.caption.copyWith(color: textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text('change', style: AppTypography.caption.copyWith(color: AppColors.teal)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_queue.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _converting
                      ? '$_doneCount / ${_queue.length} converted'
                      : 'Queue — ${_queue.length} file${_queue.length == 1 ? '' : 's'}',
                  style: AppTypography.label.copyWith(color: textSecondary),
                ),
                TextButton(
                  onPressed: _converting ? null : _convertAll,
                  style: TextButton.styleFrom(
                    backgroundColor: _converting ? border : AppColors.teal,
                    foregroundColor: AppColors.tealLight,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    _converting ? 'Converting...' : 'Convert all',
                    style: AppTypography.label.copyWith(color: AppColors.tealLight),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _queue.isEmpty ? 0 : _doneCount / _queue.length,
                backgroundColor: border,
                color: AppColors.teal,
                minHeight: 3,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                itemCount: _queue.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, i) => QueueItemTile(
                  job: _queue[i],
                  onRemove: () => _removeJob(i),
                  onFormatChanged: (f) => _updateFormat(i, f),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Divider(color: border, thickness: 0.5),
            ),
            Text(
              '100% local — nothing leaves your machine',
              style: AppTypography.caption.copyWith(color: textTertiary),
            ),
          ],
          if (_queue.isEmpty)
            Expanded(
              child: Center(
                child: Text('Add files to get started',
                    style: AppTypography.body.copyWith(color: textTertiary)),
              ),
            ),
        ],
      ),
    );
  }
}
