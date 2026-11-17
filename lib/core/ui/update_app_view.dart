import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../l10n/app_localizations.dart';
import '../config/app_constants.dart';
import 'app_icon.dart';
import 'components.dart';

/// EK-16 `unsupported_version` (and the consent loop of ADR-0011 pkt 7): CMP-18
/// blocking state with "Update app" -> Google Play (no in-app update). [secondary] keeps
/// the screen's way out (e.g. "Sign out" on EK-03, QA9).
class UpdateAppView extends ConsumerWidget {
  const UpdateAppView({super.key, this.secondary});

  final Widget? secondary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return StateView(
      key: const Key('updateApp'),
      icon: AppIcons.appUpdate,
      title: l10n.errorUpdateTitle,
      body: l10n.errorUpdateBody,
      primary: AppButton.filled(
        label: l10n.errorUpdateAction,
        onPressed: () => ref.read(urlOpenerProvider)(AppConstants.playStoreUrl),
      ),
      secondary: secondary,
    );
  }
}
