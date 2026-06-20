import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/colors.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../controllers/column_operations_provider.dart';
import '../controllers/csv_loader_provider.dart';
import '../controllers/row_operations_provider.dart';
import '../controllers/table_editing_provider.dart';
import '../controllers/table_filter_provider.dart';
import '../controllers/theme_provider.dart';
import 'formula_bar.dart';
import 'toolbar_search_field.dart';

class TopMinimalToolbar extends ConsumerStatefulWidget {
  const TopMinimalToolbar({super.key});

  @override
  ConsumerState<TopMinimalToolbar> createState() => _TopMinimalToolbarState();
}

class _TopMinimalToolbarState extends ConsumerState<TopMinimalToolbar> {
  bool _isFormulaBarExpanded = false;

  @override
  Widget build(BuildContext context) {
    final csvState = ref.watch(csvLoaderProvider);
    final mutations = ref.watch(tableEditingProvider);
    final hasMutations = mutations.isNotEmpty;
    final editMode = ref.watch(editModeProvider);
    final colLayout = ref.watch(columnOperationsProvider);
    final rowLayout = ref.watch(rowOperationsProvider);
    final filterState = ref.watch(tableFilterProvider);
    final excelPath = ref.watch(excelFilePathProvider);
    final themeMode = ref.watch(appThemeModeProvider);

    // Show Save Changes whenever there are cell edits OR structural ops
    final hasAnyChanges = hasMutations || colLayout.hasChanges || rowLayout.hasChanges;

    final metadata = csvState.value;
    final displayPath = excelPath ?? metadata?.filePath;
    final activeFile = displayPath != null ? displayPath.split(RegExp(r'[/\\]')).last : 'sales_data_2024.csv';

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 680.0;
        final double formulaBarHeight = _isFormulaBarExpanded ? 80.0 : 36.0;
        final double totalHeight = 84.0 + formulaBarHeight;

        return Container(
          height: totalHeight,
          decoration: BoxDecoration(
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
                decoration: BoxDecoration(
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
                              decoration: BoxDecoration(
                                color: AppColors.successGreen,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(6.0)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12.0, 2.0, 12.0, 0),
                            child: Row(
                              children: [
                                Icon(Icons.insert_drive_file_outlined, size: 14, color: AppColors.successGreen),
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
                                  child: Icon(Icons.close, size: 12, color: AppColors.textMuted),
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
                      icon: Icon(Icons.add, size: 16, color: AppColors.textMuted),
                      onPressed: () {},
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),

                    const Spacer(),

                    // Utility Icons
                    IconButton(
                      icon: Icon(
                        themeMode == ThemeMode.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () {
                        ref.read(appThemeModeProvider.notifier).toggle();
                      },
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12.0),
                    if (!kIsWeb && displayPath != null) ...[
                      IconButton(
                        icon: Icon(Icons.open_in_new_outlined, size: 16, color: AppColors.textMuted),
                        onPressed: () async {
                          try {
                            if (Platform.isWindows) {
                              await Process.run('cmd', ['/c', 'start', '', displayPath]);
                            } else if (Platform.isMacOS) {
                              await Process.run('open', [displayPath]);
                            } else if (Platform.isLinux) {
                              await Process.run('xdg-open', [displayPath]);
                            }
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to launch external app: $e')),
                            );
                          }
                        },
                        tooltip: 'Open in Excel / External App',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12.0),
                    ],
                    IconButton(
                      icon: Icon(Icons.settings_outlined, size: 16, color: AppColors.textMuted),
                      onPressed: () {},
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12.0),
                    IconButton(
                      icon: Icon(Icons.help_outline, size: 16, color: AppColors.textMuted),
                      onPressed: () {},
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    if (!isCompact) ...[
                      const SizedBox(width: 12.0),
                      IconButton(
                        icon: Icon(Icons.fullscreen_outlined, size: 16, color: AppColors.textMuted),
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

                    VerticalDivider(color: AppColors.borderSubtle, width: 1, indent: 8, endIndent: 8),
                    const SizedBox(width: 12),

                    // Search in file search field
                    ToolbarSearchField(isCompact: isCompact),

                    const Spacer(),

                    // Metadata readout: 1,048,576 rows • 28 columns
                    if (metadata != null)
                      Text(
                        isCompact
                            ? '${metadata.totalRows.toString()} R'
                            : '${metadata.totalRows.toString()} rows • ${metadata.headers.length.toString()} columns',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 11.0, fontWeight: FontWeight.w400),
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

                    // Save Changes button — appears for ANY pending change
                    if (hasAnyChanges)
                      ElevatedButton.icon(
                        onPressed: () {
                          // Always use saveAllChanges so structural ops are included
                          ref.read(csvLoaderProvider.notifier).saveAllChanges(
                            mutations: mutations,
                            columnVisibleOrder: colLayout.visibleOrder.isEmpty
                                ? List.generate(
                                    metadata?.headers.length ?? 0, (i) => i)
                                : colLayout.visibleOrder,
                            renamedHeaders: colLayout.renamedHeaders,
                            rowFilterIndices: rowLayout.visibleOrder.isEmpty
                                ? List.generate(
                                    filterState.visibleRowIndices.length,
                                    (i) => i)
                                : rowLayout.visibleOrder,
                            filterToFileRow: filterState.visibleRowIndices,
                          );
                        },
                        icon: Icon(Icons.save_outlined,
                            size: 12, color: AppColors.textPrimary),
                        label: Text(
                          isCompact ? 'Save' : 'Save Changes',
                          style: const TextStyle(
                              fontSize: 11.0, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.textPrimary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                        ),
                      ),

                    // Vertical dots menu
                    IconButton(
                      icon: Icon(Icons.more_vert, size: 16, color: AppColors.textMuted),
                      onPressed: () {},
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),

              // ================= ROW 3: EXCEL-STYLE FORMULA BAR =================
              FormulaBar(
                metadata: metadata,
                isCompact: isCompact,
                isExpanded: _isFormulaBarExpanded,
                onToggleExpand: () {
                  setState(() {
                    _isFormulaBarExpanded = !_isFormulaBarExpanded;
                  });
                },
                height: formulaBarHeight,
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
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.0,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down, size: 10, color: AppColors.textMuted),
              ],
            ],
          ),
        ),
      ),
    );
  }
}