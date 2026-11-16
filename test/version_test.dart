import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:geokuna/app/version.dart';

void main() {
  test('version shown in the app matches pubspec.yaml', () {
    final line = File('pubspec.yaml')
        .readAsLinesSync()
        .firstWhere((l) => l.startsWith('version:'));
    expect(line, 'version: $appVersion+$appBuild');
  });
}
