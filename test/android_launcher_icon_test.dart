import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards MD-ICON (docs/ux/icon-and-illustration.md 2, 4.1): Tamitu adaptive icon,
/// variant A, no Flutter logo left in the APK (OBS-DEV-2).
void main() {
  const res = 'android/app/src/main/res';

  test('manifest uses @mipmap/ic_launcher', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    expect(manifest, contains('android:icon="@mipmap/ic_launcher"'));
  });

  test('adaptive icon has background, foreground and monochrome layers', () {
    final icon = File('$res/mipmap-anydpi-v26/ic_launcher.xml')
        .readAsStringSync();
    expect(icon, contains('<adaptive-icon'));
    expect(icon, contains('@color/ic_launcher_background'));
    expect(icon, contains('@drawable/ic_launcher_foreground'));
    expect(
      icon,
      contains(
        '<monochrome android:drawable="@drawable/ic_launcher_monochrome"',
      ),
    );
  });

  test('background is variant A (#006A6A)', () {
    final colors = File('$res/values/ic_launcher_background.xml')
        .readAsStringSync();
    expect(
      colors,
      contains('<color name="ic_launcher_background">#006A6A</color>'),
    );
  });

  for (final layer in ['foreground', 'monochrome']) {
    test('$layer layer is a 108 dp vector with a hole and round strokes', () {
      final xml = File('$res/drawable/ic_launcher_$layer.xml')
          .readAsStringSync();
      expect(xml, contains('android:viewportWidth="108"'));
      expect(xml, contains('android:width="108dp"'));
      expect(xml, contains('android:fillType="evenOdd"'));
      expect('android:strokeLineCap="round"'.allMatches(xml), hasLength(3));
      expect('android:strokeLineJoin="round"'.allMatches(xml), hasLength(3));
    });
  }

  test('no Flutter logo PNGs left in mipmap-*dpi', () {
    final pngs = Directory(res)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.replaceAll(r'\', '/').contains('/mipmap-'))
        .where((f) => f.path.endsWith('.png'));
    expect(pngs, isEmpty);
  });
}
