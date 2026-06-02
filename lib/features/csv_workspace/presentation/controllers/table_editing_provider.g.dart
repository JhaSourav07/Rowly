// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'table_editing_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$tableEditingHash() => r'87c4a185f1640470b05566f03a06220f1128d399';

/// See also [TableEditing].
@ProviderFor(TableEditing)
final tableEditingProvider = AutoDisposeNotifierProvider<TableEditing,
    Map<CsvCellPosition, String>>.internal(
  TableEditing.new,
  name: r'tableEditingProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$tableEditingHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TableEditing = AutoDisposeNotifier<Map<CsvCellPosition, String>>;
String _$selectedCellHash() => r'b21e382b69c7ec2fe2cc1611c5f19fd03a88adb5';

/// See also [SelectedCell].
@ProviderFor(SelectedCell)
final selectedCellProvider =
    AutoDisposeNotifierProvider<SelectedCell, CsvCellPosition?>.internal(
  SelectedCell.new,
  name: r'selectedCellProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$selectedCellHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedCell = AutoDisposeNotifier<CsvCellPosition?>;
String _$editModeHash() => r'17fdd5eb67ce8d5eca4f73b31ded1a03ecd2db2b';

/// See also [EditMode].
@ProviderFor(EditMode)
final editModeProvider = AutoDisposeNotifierProvider<EditMode, bool>.internal(
  EditMode.new,
  name: r'editModeProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$editModeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$EditMode = AutoDisposeNotifier<bool>;
String _$inlineEditingCellHash() => r'c6d49acc9dc84bae202ac975fd876b521c6c5c7f';

/// See also [InlineEditingCell].
@ProviderFor(InlineEditingCell)
final inlineEditingCellProvider =
    AutoDisposeNotifierProvider<InlineEditingCell, CsvCellPosition?>.internal(
  InlineEditingCell.new,
  name: r'inlineEditingCellProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$inlineEditingCellHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$InlineEditingCell = AutoDisposeNotifier<CsvCellPosition?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
