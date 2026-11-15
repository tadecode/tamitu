import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';

/// Placeholder start screen (skeleton, P3-01).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeTitle)),
      body: Center(child: Text(l10n.homeSubtitle)),
    );
  }
}
