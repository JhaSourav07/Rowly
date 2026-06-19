import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/colors.dart';
import '../controllers/row_operations_provider.dart';
import '../controllers/table_filter_provider.dart';

/// Shows the Row Operations context menu dialog.
/// All 7 operations (Insert Above, Insert Below, Duplicate, Hide, Delete,
/// Move Up, Move Down) are wired to the [RowOperations] Riverpod notifier.
Future<void> showRowContextMenu({
  required BuildContext context,
  required WidgetRef ref,
  required int visiblePos,      // position in rowLayoutState.visibleOrder
  required int displayRowNumber, // the 1-based label shown to the user
}) async {
  final rowLayout = ref.read(rowOperationsProvider);
  final totalVisible = rowLayout.visibleOrder.length;

  await showDialog<void>(
    context: context,
    barrierColor: Colors.black.withAlpha(120),
    builder: (ctx) => _RowContextMenuDialog(
      outerRef: ref,
      visiblePos: visiblePos,
      displayRowNumber: displayRowNumber,
      totalVisible: totalVisible,
    ),
  );
}

class _RowContextMenuDialog extends ConsumerWidget {
  final WidgetRef outerRef;
  final int visiblePos;
  final int displayRowNumber;
  final int totalVisible;

  const _RowContextMenuDialog({
    required this.outerRef,
    required this.visiblePos,
    required this.displayRowNumber,
    required this.totalVisible,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              // ── Header ───────────────────────────────────────────────
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
                      'Row Operations',
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
                        Icon(Icons.table_rows_outlined,
                            size: 11, color: AppColors.textMuted),
                        const SizedBox(width: 5),
                        Text(
                          'Row $displayRowNumber',
                          style: TextStyle(
                            color: AppColors.successGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
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
                      icon: Icons.add_circle_outline,
                      label: 'Insert Row Above',
                      onTap: () {
                        ref
                            .read(rowOperationsProvider.notifier)
                            .insertRowAbove(visiblePos);
                        Navigator.of(context).pop();
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.add_circle_outline,
                      label: 'Insert Row Below',
                      onTap: () {
                        ref
                            .read(rowOperationsProvider.notifier)
                            .insertRowBelow(visiblePos);
                        Navigator.of(context).pop();
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.copy_outlined,
                      label: 'Duplicate',
                      onTap: () {
                        ref
                            .read(rowOperationsProvider.notifier)
                            .duplicateRow(visiblePos);
                        Navigator.of(context).pop();
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.visibility_off_outlined,
                      label: 'Hide',
                      onTap: () {
                        ref
                            .read(rowOperationsProvider.notifier)
                            .hideRow(visiblePos);
                        Navigator.of(context).pop();
                      },
                    ),
                    Divider(
                        color: AppColors.borderSubtle,
                        height: 1,
                        indent: 16,
                        endIndent: 16),
                    const SizedBox(height: 4),
                    _buildMenuItem(
                      icon: Icons.keyboard_arrow_up_outlined,
                      label: 'Move Up',
                      enabled: visiblePos > 0,
                      onTap: () {
                        ref
                            .read(rowOperationsProvider.notifier)
                            .moveRowUp(visiblePos);
                        Navigator.of(context).pop();
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.keyboard_arrow_down_outlined,
                      label: 'Move Down',
                      enabled: visiblePos < totalVisible - 1,
                      onTap: () {
                        ref
                            .read(rowOperationsProvider.notifier)
                            .moveRowDown(visiblePos);
                        Navigator.of(context).pop();
                      },
                    ),
                    Divider(
                        color: AppColors.borderSubtle,
                        height: 1,
                        indent: 16,
                        endIndent: 16),
                    const SizedBox(height: 4),
                    _buildMenuItem(
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      accentColor: AppColors.error,
                      onTap: () => _handleDelete(context, ref),
                    ),
                  ],
                ),
              ),

              // ── Footer ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
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

  Future<void> _handleDelete(BuildContext ctx, WidgetRef ref) async {
    Navigator.of(ctx).pop();
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (innerCtx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 18),
            const SizedBox(width: 8),
            Text('Delete Row',
                style:
                    TextStyle(color: AppColors.textPrimary, fontSize: 14)),
          ],
        ),
        content: Text(
          'Remove Row $displayRowNumber from the view? This cannot be undone.',
          style: TextStyle(
              color: AppColors.textSecondary, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(innerCtx).pop(false),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
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
                style:
                    TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(rowOperationsProvider.notifier).deleteRow(visiblePos);
      // Re-trigger filter so row counts stay in sync
      ref.read(tableFilterProvider.notifier).setSearchQuery(
            ref.read(tableFilterProvider).searchQuery,
          );
    }
  }
}
