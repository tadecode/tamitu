import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamitu/core/ui/icon_licenses.dart';

void main() {
  test('Hugeicons 2025 MIT notice is registered (ADR-0010 pkt 6)', () async {
    registerIconLicenses();
    final entries = await LicenseRegistry.licenses.toList();
    final hugeicons = entries.where(
      (e) => e.packages.contains('hugeicons (icon set)'),
    );
    expect(hugeicons, isNotEmpty);
    final text = hugeicons.first.paragraphs.map((p) => p.text).join('\n');
    expect(text, contains('Copyright (c) 2025 Hugeicons'));
  });
}
