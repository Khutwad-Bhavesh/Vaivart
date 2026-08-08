import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/services/history_service.dart';
import '../../core/engine/tool_resolver.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<HistoryEntry> _entries = [];
  List<HistoryEntry> _filtered = [];
  final _searchController = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(_filter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final entries = await HistoryService.getHistory();
    setState(() {
      _entries = entries;
      _filtered = entries;
      _loading = false;
    });
  }

  void _filter() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _entries
          : _entries.where((e) =>
              e.fileName.toLowerCase().contains(q) ||
              e.fromFormat.toLowerCase().contains(q) ||
              e.toFormat.toLowerCase().contains(q)).toList();
    });
  }

  Future<void> _clearAll() async {
    await HistoryService.clearHistory();
    setState(() { _entries = []; _filtered = []; });
  }

  void _openFolder(String path) {
    final dir = File(path).parent.path;
    ToolResolver.openFolder(dir);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final bg = isDark ? AppColors.darkBgSecondary : AppColors.lightBgSecondary;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textTertiary = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary)),
              const Spacer(),
              if (_entries.isNotEmpty)
                GestureDetector(
                  onTap: _clearAll,
                  child: Text('Clear all', style: AppTypography.caption.copyWith(color: const Color(0xFFE24B4A))),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            style: AppTypography.body.copyWith(color: textPrimary),
            decoration: InputDecoration(
              hintText: 'Search conversions...',
              hintStyle: AppTypography.body.copyWith(color: textTertiary),
              prefixIcon: Icon(Icons.search, size: 16, color: textTertiary),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: border, width: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: AppColors.teal, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
                : _filtered.isEmpty
                    ? Center(child: Text('No conversions yet', style: AppTypography.body.copyWith(color: textTertiary)))
                    : ListView.separated(
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, i) {
                          final e = _filtered[i];
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
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.teal.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${e.fromFormat} → ${e.toFormat}',
                                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.teal),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(e.fileName, style: AppTypography.body.copyWith(color: textPrimary), overflow: TextOverflow.ellipsis),
                                      Text(_formatDate(e.convertedAt), style: AppTypography.caption.copyWith(color: textTertiary)),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _openFolder(e.outputPath),
                                  child: Row(
                                    children: [
                                      Icon(Icons.folder_outlined, size: 13, color: textTertiary),
                                      const SizedBox(width: 4),
                                      Text('open', style: AppTypography.caption.copyWith(color: textTertiary)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}