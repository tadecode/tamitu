import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../core/config/app_constants.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/ui/app_icon.dart';
import '../../../core/ui/components.dart';
import '../../../core/ui/tokens.dart';
import '../../../core/ui/update_app_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../session/session_controller.dart';

/// EK-03 Re-acceptance of the privacy policy (US-003, U2): blocking screen without a
/// back arrow; system back closes the app (root route). Saving needs the network.
class ReconsentScreen extends ConsumerStatefulWidget {
  const ReconsentScreen({
    super.key,
    required this.uid,
    this.dataReset = false,
    this.onSignOut,
    this.onDeleteAccount,
  });

  final String uid;

  /// Variant after the unreadable database was cleared (`reconsentBodyDataReset`).
  final bool dataReset;

  /// "Sign out" (-> EK-14). Hidden when null.
  final VoidCallback? onSignOut;

  /// "Delete account" (-> EK-15, P3-08). Hidden when null.
  final VoidCallback? onDeleteAccount;

  @override
  ConsumerState<ReconsentScreen> createState() => _ReconsentScreenState();
}

class _ReconsentScreenState extends ConsumerState<ReconsentScreen> {
  bool _accepted = false;
  bool _saving = false;
  AppFailure? _failure;

  /// One id for this decision so that retries are idempotent on the server.
  late final String _consentId = ref
      .read(consentServiceProvider)
      .newConsentId();

  Future<void> _openPolicy() async {
    final lang = languageOf(context);
    await ref.read(urlOpenerProvider)(AppConstants.privacyPolicyUrls[lang]!);
  }

  Future<void> _accept() async {
    if (!_accepted || _saving) return;
    final lang = languageOf(context);
    setState(() {
      _saving = true;
      _failure = null;
    });
    try {
      await ref
          .read(consentServiceProvider)
          .acceptPolicy(uid: widget.uid, consentId: _consentId, lang: lang);
      await ref.read(sessionProvider.notifier).refresh();
    } on AppFailure catch (f) {
      if (!mounted) return;
      if (f.kind == FailureKind.unauthenticated) {
        await ref.read(sessionProvider.notifier).expireSession();
        return;
      }
      setState(() {
        _saving = false;
        _failure = f;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final (before, after) = splitAround(
      l10n.consentPolicyCheckbox(_marker),
      _marker,
    );
    final failure = _failure;

    if (failure?.kind == FailureKind.unsupportedVersion) {
      // BUG-4: retrying cannot help – EK-16 "Update the app"; sign-out stays (QA9).
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Semantics(header: true, child: Text(l10n.reconsentTitle)),
        ),
        body: SafeArea(
          child: UpdateAppView(
            secondary: widget.onSignOut == null
                ? null
                : TextButton(
                    onPressed: widget.onSignOut,
                    child: Text(l10n.reconsentSignOut),
                  ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Semantics(header: true, child: Text(l10n.reconsentTitle)),
      ),
      body: SafeArea(
        child: ContentColumn(
          child: StickyBottomLayout(
            content: [
              Text(
                widget.dataReset
                    ? l10n.reconsentBodyDataReset
                    : l10n.reconsentBody,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: Space.s2),
              Align(
                alignment: Alignment.centerLeft,
                child: Semantics(
                  link: true,
                  label: '${l10n.reconsentLink}, ${l10n.commonOpensInBrowser}',
                  excludeSemantics: true,
                  child: TextButton.icon(
                    onPressed: _openPolicy,
                    icon: const AppIcon(AppIcons.openExternal, size: 18),
                    label: Text(l10n.reconsentLink),
                  ),
                ),
              ),
              const SizedBox(height: Space.s4),
              ConsentCheckbox(
                value: _accepted,
                onChanged: _saving
                    ? null
                    : (v) => setState(() => _accepted = v),
                before: before,
                linkText: l10n.consentPolicyLink,
                after: after,
                onOpenLink: _openPolicy,
                linkHint: l10n.commonOpensInBrowser,
              ),
            ],
            bottom: [
              if (failure != null) ...[
                failure.kind == FailureKind.offline
                    ? Notice(
                        key: const Key('reconsentOffline'),
                        variant: NoticeVariant.warning,
                        icon: AppIcons.offline,
                        text: l10n.reconsentOffline,
                        liveRegion: true,
                      )
                    : Notice(
                        key: const Key('reconsentError'),
                        variant: NoticeVariant.error,
                        icon: AppIcons.error,
                        text: l10n.reconsentSaveError,
                        liveRegion: true,
                      ),
                const SizedBox(height: Space.s4),
              ],
              AppButton.filled(
                key: const Key('reconsentAccept'),
                label: l10n.reconsentAccept,
                loading: _saving,
                loadingLabel: l10n.commonLoading,
                onPressed: _accepted ? _accept : null,
              ),
              if (widget.onSignOut != null || widget.onDeleteAccount != null)
                const SizedBox(height: Space.s4),
              if (widget.onSignOut != null)
                TextButton(
                  onPressed: _saving ? null : widget.onSignOut,
                  child: Text(l10n.reconsentSignOut),
                ),
              if (widget.onDeleteAccount != null)
                TextButton(
                  onPressed: _saving ? null : widget.onDeleteAccount,
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  child: Text(l10n.reconsentDeleteAccount),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

const _marker = '\u0000';
