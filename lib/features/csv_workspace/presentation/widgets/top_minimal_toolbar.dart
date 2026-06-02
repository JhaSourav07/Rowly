import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/colors.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../controllers/csv_loader_provider.dart';
import '../controllers/table_editing_provider.dart';
import '../controllers/table_filter_provider.dart';

class TopMinimalToolbar extends ConsumerWidget {
  const TopMinimalToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final csvState = ref.watch(csvLoaderProvider);
    final mutations = ref.watch(tableEditingProvider);
    final hasMutations = mutations.isNotEmpty;
    final editMode = ref.watch(editModeProvider);

    final metadata = csvState.value;
    final activeFile = metadata?.filePath.split(Platform.pathSeparator).last ?? 'sales_data_2024.csv';

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 680.0;

        return Container(
          height: 84.0,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(color: AppColors.borderSubtle, width: 1.0),
            ),
          ),
          child: Column(
            children: [
              // ================= ROW 1: TABS & GLOBAL SEARCH =================
              Container(
                height: 40.0,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.borderMuted, width: 1.0),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  children: [
                    // Active Tab
                    Container(
                      height: 32.0,
                      width: isCompact ? 120.0 : 220.0,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6.0)),
                        border: Border.all(color: AppColors.borderSubtle.withAlpha(120)),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 2.0,
                              decoration: const BoxDecoration(
                                color: AppColors.successGreen,
                                borderRadius: BorderRadius.vertical(top: Radius.circular(6.0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12.0, 2.0, 12.0, 0),
                            child: Row(
                              children: [
                                const Icon(Icons.insert_drive_file_outlined, size: 14, color: AppColors.successGreen),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    activeFile,
                                    style: context.textTheme.bodyMedium?.copyWith(
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    ref.read(csvLoaderProvider.notifier).closeFile();
                                  },
                                  child: const Icon(Icons.close, size: 12, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8.0),
                    // Plus tab button
                    IconButton(
                      icon: const Icon(Icons.add, size: 16, color: AppColors.textMuted),
                      onPressed: () {},
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),

                    const Spacer(),

                    // Center Global Search Box (sleek Linear/Raycast style)
                    _SearchField(isCompact: isCompact),

                    const Spacer(),

                    // Utility Icons
                    IconButton(
                      icon: const Icon(Icons.light_mode_outlined, size: 16, color: AppColors.textMuted),
                      onPressed: () {},
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12.0),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined, size: 16, color: AppColors.textMuted),
                      onPressed: () {},
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12.0),
                    IconButton(
                      icon: const Icon(Icons.help_outline, size: 16, color: AppColors.textMuted),
                      onPressed: () {},
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    if (!isCompact) ...[
                      const SizedBox(width: 12.0),
                      IconButton(
                        icon: const Icon(Icons.fullscreen_outlined, size: 16, color: AppColors.textMuted),
                        onPressed: () {},
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ],
                ),
              ),

              // ================= ROW 2: ACTIONS TOOLBAR =================
              Container(
                height: 43.0,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  children: [
                    // Filter Button
                    _buildActionButton(context, Icons.filter_list_outlined, 'Filter', isCompact),
                    const SizedBox(width: 8),

                    // Sort Button
                    _buildActionButton(context, Icons.sort_outlined, 'Sort', isCompact),
                    const SizedBox(width: 8),

                    // Columns Button
                    _buildActionButton(context, Icons.view_column_outlined, 'Columns', isCompact),
                    const SizedBox(width: 8),

                    // Freeze Button
                    _buildActionButton(context, Icons.ac_unit_outlined, 'Freeze', isCompact),
                    const SizedBox(width: 12),

                    const VerticalDivider(color: AppColors.borderSubtle, width: 1, indent: 8, endIndent: 8),
                    const SizedBox(width: 12),

                    // Search in file search field
                    Container(
                      width: isCompact ? 100.0 : 180.0,
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
                              style: const TextStyle(fontSize: 11.0, color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                hintText: isCompact ? 'Find...' : 'Search in file...',
                                hintStyle: TextStyle(fontSize: 11.0, color: AppColors.textMuted.withAlpha(180)),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Metadata readout: 1,048,576 rows • 28 columns
                    if (metadata != null)
                      Text(
                        isCompact
                            ? '${metadata.totalRows.toString()} R'
                            : '${metadata.totalRows.toString()} rows • ${metadata.headers.length.toString()} columns',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11.0, fontWeight: FontWeight.w400),
                      ),
                    const SizedBox(width: 12),

                    // Edit Mode / Read Only Toggle Pill Button
                    Material(
                      color: editMode ? AppColors.successGreen.withAlpha(20) : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(20.0),
                      child: InkWell(
                        onTap: () {
                          ref.read(editModeProvider.notifier).toggle();
                        },
                        borderRadius: BorderRadius.circular(20.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: editMode ? AppColors.successGreen.withAlpha(180) : AppColors.borderSubtle,
                              width: 0.5,
                            ),
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                editMode ? Icons.edit_outlined : Icons.lock_outline,
                                size: 11,
                                color: editMode ? AppColors.successGreen : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                editMode ? 'Edit' : 'Lock',
                                style: TextStyle(
                                  color: editMode ? AppColors.textPrimary : AppColors.textSecondary,
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Save Changes button
                    if (hasMutations)
                      ElevatedButton.icon(
                        onPressed: () => ref.read(csvLoaderProvider.notifier).saveActiveEdits(mutations),
                        icon: const Icon(Icons.save_outlined, size: 12, color: AppColors.textPrimary),
                        label: Text(isCompact ? 'Save' : 'Save Changes', style: const TextStyle(fontSize: 11.0, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.textPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                      ),

                    // Vertical dots menu
                    IconButton(
                      icon: const Icon(Icons.more_vert, size: 16, color: AppColors.textMuted),
                      onPressed: () {},
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String text, bool isCompact) {
    return Container(
      height: 28.0,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: AppColors.borderSubtle, width: 0.5),
      ),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$text options clicked')),
          );
        },
        borderRadius: BorderRadius.circular(6.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Icon(icon, size: 12, color: AppColors.textSecondary),
              if (!isCompact) ...[
                const SizedBox(width: 6),
                Text(
                  text,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.0,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down, size: 10, color: AppColors.textMuted),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends ConsumerStatefulWidget {
  final bool isCompact;
  const _SearchField({required this.isCompact});

  @override
  ConsumerState<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<_SearchField> {
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