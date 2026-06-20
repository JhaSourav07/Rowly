import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rowly/main.dart';

void main() {
  test('initialFilePathProvider defaults to null', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(initialFilePathProvider), isNull);
  });

  test('initialFilePathProvider can be overridden with a command-line argument path', () {
    final container = ProviderContainer(
      overrides: [
        initialFilePathProvider.overrideWithValue('/path/to/test.csv'),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(initialFilePathProvider), '/path/to/test.csv');
  });
}
