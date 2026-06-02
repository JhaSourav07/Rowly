import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/colors.dart';
import '../controllers/table_filter_provider.dart';

class ToolbarSearchField extends ConsumerStatefulWidget {
  final bool isCompact;
  const ToolbarSearchField({super.key, required this.isCompact});

  @override
  ConsumerState<ToolbarSearchField> createState() => _ToolbarSearchFieldState();
}

class _ToolbarSearchFieldState extends ConsumerState<ToolbarSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final initialQuery = ref.read(tableFilterProvider).searchQuery;
    _controller = TextEditingController(text: initialQuery);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<TableFilterState>(
      tableFilterProvider,
      (previous, next) {
        if (next.searchQuery != _controller.text) {
          _controller.text = next.searchQuery;
        }
      },
    );

    return Container(
      width: widget.isCompact ? 120.0 : 280.0,
      height: 28.0,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: AppColors.borderSubtle, width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          const Icon(Icons.search, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(fontSize: 11.0, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: widget.isCompact ? 'Search...' : 'Search (Ctrl + F)',
                hintStyle: TextStyle(fontSize: 11.0, color: AppColors.textMuted.withAlpha(180)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (val) {
                ref.read(tableFilterProvider.notifier).setSearchQuery(val);
              },
            ),
          ),
          if (_controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _controller.clear();
                ref.read(tableFilterProvider.notifier).setSearchQuery('');
              },
              child: const Icon(Icons.clear, size: 12, color: AppColors.textMuted),
            ),
        ],
      ),
    );
  }
}
