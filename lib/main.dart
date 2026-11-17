import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'core/ui/icon_licenses.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerIconLicenses();
  final overrides = await bootstrapOverrides();
  runApp(ProviderScope(overrides: overrides, child: const TamituApp()));
}
