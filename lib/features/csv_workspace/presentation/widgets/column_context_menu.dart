import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/colors.dart';
import '../../domain/models/csv_table.dart';
import '../controllers/column_operations_provider.dart';
import '../controllers/column_widths_provider.dart';
import '../controllers/table_filter_provider.dart';

/// Shows the Column Operations context menu anchored to the right-click position.
/// All 7 operations (Rename, Duplicate, Hide, Freeze, Delete, Move Left, Move Right)
/// are wired to the [ColumnOperations] Riverpod notifier.
Future<void> showColumnContextMenu({
  required BuildContext context,
  required WidgetRef ref,
  required CsvTableMetadata metadata,
  required int visibleOrderIndex,
  required Offset globalPosition,
}) async {
  final layoutState = ref.read(columnOperationsProvider);
  final physicalIndex = visibleOrderIndex < layoutState.visibleOrder.length
      ? layoutState.visibleOrder[visibleOrderIndex]
      : visibleOrderIndex;

  String getColumnLetter(int index) {
    String letter = '';
    int temp = index;
    while (temp >= 0) {
      letter = String.fromCharCode((temp % 26) + 65) + letter;
      temp = (temp ~/ 26) - 1;
    }
    return letter;
  }

  final originalHeader = physicalIndex < metadata.headers.length
      ? metadata.headers[physicalIndex]
      : 'Column ${getColumnLetter(visibleOrderIndex)}';
  final displayName = layoutState.displayName(originalHeader, physicalIndex);
  final isFrozen = layoutState.frozenColumnCount > visibleOrderIndex;

  await showDialog<void>(
    context: context,
    barrierColor: Colors.black.withAlpha(120),
    builder: (ctx) => _ColumnContextMenuDialog(
      ref: ref,
      metadata: metadata,
      visibleOrderIndex: visibleOrderIndex,
      physicalIndex: physicalIndex,
      displayName: displayName,
      isFrozen: isFrozen,
      totalVisibleColumns: layoutState.visibleOrder.length,
    ),
  );
}

class _ColumnContextMenuDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;
  final CsvTableMetadata metadata;
  final int visibleOrderIndex;
  final int physicalIndex;
  final String displayName;
  final bool isFrozen;
  final int totalVisibleColumns;

  const _ColumnContextMenuDialog({
    required this.ref,
    required this.metadata,
    required this.visibleOrderIndex,
    required this.physicalIndex,
    required this.displayName,
    required this.isFrozen,
    required this.totalVisibleColumns,
  });

  @override
  ConsumerState<_ColumnContextMenuDialog> createState() =>
      _ColumnContextMenuDialogState();
}

class _ColumnContextMenuDialogState
    extends ConsumerState<_ColumnContextMenuDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Center(
        child: Container(
          width: 300,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSubtle, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(160),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ──────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.borderSubtle, width: 1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Column Operations',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.table_chart_outlined,
                            size: 11, color: AppColors.textMuted),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            widget.displayName,
                            style: TextStyle(
                              color: AppColors.successGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Actions ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMenuItem(
                      icon: Icons.edit_outlined,
                      label: 'Rename',
                      onTap: () => _handleRename(context),
                    ),
                    _buildMenuItem(
                      icon: Icons.copy_outlined,
                      label: 'Duplicate',
                      onTap: () {
                        ref
                            .read(columnOperationsProvider.notifier)
                            .duplicateColumn(widget.visibleOrderIndex);
                        Navigator.of(context).pop();
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.visibility_off_outlined,
                      label: 'Hide',
                      onTap: () {
                        ref
                            .read(columnOperationsProvider.notifier)
                            .hideColumn(widget.visibleOrderIndex);
                        Navigator.of(context).pop();
                      },
                    ),
                    _buildMenuItem(
                      icon: widget.isFrozen
                          ? Icons.lock_open_outlined
                          : Icons.ac_unit_outlined,
                      label: widget.isFrozen ? 'Unfreeze' : 'Freeze',
                      accentColor: AppColors.accent,
                      onTap: () {
                        ref
                            .read(columnOperationsProvider.notifier)
                            .toggleFreezeColumn(widget.visibleOrderIndex);
                        Navigator.of(context).pop();
                      },
                    ),
                    Divider(
                        color: AppColors.borderSubtle, height: 1, indent: 16, endIndent: 16),
                    const SizedBox(height: 4),
                    _buildMenuItem(
                      icon: Icons.arrow_back_outlined,
                      label: 'Move Left',
                      enabled: widget.visibleOrderIndex > 0,
                      onTap: () {
                        ref
                            .read(columnOperationsProvider.notifier)
                            .moveColumnLeft(widget.visibleOrderIndex);
                        Navigator.of(context).pop();
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.arrow_forward_outlined,
                      label: 'Move Right',
                      enabled: widget.visibleOrderIndex <
                          widget.totalVisibleColumns - 1,
                      onTap: () {
                        ref
                            .read(columnOperationsProvider.notifier)
                            .moveColumnRight(widget.visibleOrderIndex);
                        Navigator.of(context).pop();
                      },
                    ),
                    Divider(
                        color: AppColors.borderSubtle, height: 1, indent: 16, endIndent: 16),
                    const SizedBox(height: 4),
                    _buildMenuItem(
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      accentColor: AppColors.error,
                      onTap: () => _handleDelete(context),
                    ),
                  ],
                ),
              ),

              // ── Footer ───────────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: BorderSide(
                          color: AppColors.borderSubtle, width: 0.8),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                    ),
                    child:
                        const Text('Cancel', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? accentColor,
    bool enabled = true,
  }) {
    final color = !enabled
        ? AppColors.textMuted
        : accentColor ?? AppColors.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Rename Dialog ────────────────────────────────────────────────────────────

  Future<void> _handleRename(BuildContext ctx) async {
    Navigator.of(ctx).pop();
    final controller =
        TextEditingController(text: widget.displayName);

    final result = await showDialog<String>(
      context: ctx,
      builder: (innerCtx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Text('Rename Column',
            style:
                TextStyle(color: AppColors.textPrimary, fontSize: 14)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style:
              TextStyle(color: AppColors.textPrimary, fontSize: 13),
          cursorColor: AppColors.successGreen,
          decoration: InputDecoration(
            hintText: 'Enter new column name…',
            hintStyle:
                TextStyle(color: AppColors.textMuted, fontSize: 12),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide:
                  BorderSide(color: AppColors.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                  color: AppColors.successGreen, width: 1.5),
            ),
          ),
          onSubmitted: (v) => Navigator.of(innerCtx).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(innerCtx).pop(),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.successGreen,
              foregroundColor: AppColors.textPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () =>
                Navigator.of(innerCtx).pop(controller.text),
            child: const Text('Rename',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      ref
          .read(columnOperationsProvider.notifier)
          .renameColumn(widget.physicalIndex, result.trim());
    }
  }

  // ── Delete Confirmation ──────────────────────────────────────────────────────

  Future<void> _handleDelete(BuildContext ctx) async {
    Navigator.of(ctx).pop();
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (innerCtx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: AppColors.error, size: 18),
            const SizedBox(width: 8),
            Text('Delete Column',
                style: TextStyle(
                    color: AppColors.textPrimary, fontSize: 14)),
          ],
        ),
        content: Text(
          'Remove "${widget.displayName}" from the view? This cannot be undone.',
          style: TextStyle(
              color: AppColors.textSecondary, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(innerCtx).pop(false),
            child: Text('Cancel',
                style:
                    TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () => Navigator.of(innerCtx).pop(true),
            child: const Text('Delete',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref
          .read(columnOperationsProvider.notifier)
          .deleteColumn(widget.visibleOrderIndex);
      // Also clear the auto-fit width so the layout stays consistent
      ref
          .read(columnWidthsProvider.notifier)
          .resizeColumn(widget.visibleOrderIndex, 0);
      // Reapply filter to let visibleRowIndices stay consistent
      ref.read(tableFilterProvider.notifier).setSearchQuery(
            ref.read(tableFilterProvider).searchQuery,
          );
    }
  }
}
