import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../core/ui/components.dart';
import '../core/ui/tokens.dart';
import '../l10n/app_localizations.dart';
import 'router.dart';

/// Placeholder start screen (skeleton, P3-01). The trip list (EK-04) comes later; until
/// then "New trip" opens EK-05 from here (TAM-101).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeTitle)),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(Space.s4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.homeSubtitle, textAlign: TextAlign.center),
                const SizedBox(height: Space.s6),
                AppButton.filled(
                  key: const Key('homeNewTrip'),
                  label: l10n.tripFormTitle,
                  onPressed: () => context.push(Routes.tripForm),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
