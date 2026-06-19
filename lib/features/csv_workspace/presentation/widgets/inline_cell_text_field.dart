import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/colors.dart';
import '../../domain/models/csv_cell.dart';
import '../controllers/table_editing_provider.dart';

class InlineCellTextField extends ConsumerStatefulWidget {
  final CsvCellPosition position;
  final String initialValue;

  const InlineCellTextField({
    super.key,
    required this.position,
    required this.initialValue,
  });

  @override
  ConsumerState<InlineCellTextField> createState() => _InlineCellTextFieldState();
}

class _InlineCellTextFieldState extends ConsumerState<InlineCellTextField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        ref.read(inlineEditingCellProvider.notifier).stopEditing();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          ref.read(inlineEditingCellProvider.notifier).stopEditing();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        autofocus: true,
        style: TextStyle(
          fontSize: 13.0,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.normal,
        ),
        cursorColor: AppColors.accent,
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (val) {
          ref.read(tableEditingProvider.notifier).updateCell(widget.position, val);
        },
        onSubmitted: (val) {
          ref.read(inlineEditingCellProvider.notifier).stopEditing();
        },
      ),
    );
  }
}
