import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../core/config/app_constants.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/ui/app_icon.dart';
import '../../../core/ui/components.dart';
import '../../../core/ui/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../session/session_controller.dart';

/// EK-06 Consent to use AI (US-003; working text `ai-consent-v1`).
///
/// Two outlined buttons of equal weight in a fixed order, no checkbox. "I don't agree",
/// the back arrow and system back return `false` without creating a record (U-5).
/// "I agree" saves the decision (network) and pops `true`; on error nothing is sent.
class AiConsentScreen extends ConsumerStatefulWidget {
  const AiConsentScreen({super.key, required this.uid, this.updated = false});

  final String uid;

  /// Entered from `consent_required` (new consent version): shows the updated intro.
  final bool updated;

  @override
  ConsumerState<AiConsentScreen> createState() => _AiConsentScreenState();
}

class _AiConsentScreenState extends ConsumerState<AiConsentScreen> {
  bool _saving = false;
  AppFailure? _failure;
  late final String _consentId = ref
      .read(consentServiceProvider)
      .newConsentId();
  late final _policyTap = TapGestureRecognizer()..onTap = _openPolicy;

  @override
  void dispose() {
    _policyTap.dispose();
    super.dispose();
  }

  Future<void> _openPolicy() async {
    final lang = languageOf(context);
    await ref.read(urlOpenerProvider)(AppConstants.privacyPolicyUrls[lang]!);
  }

  /// Pops this route with the decision (null from system back = no).
  void _finish(bool granted) => Navigator.of(context).pop(granted);

  void _disagree() {
    if (_saving) return;
    _finish(false);
  }

  Future<void> _agree() async {
    if (_saving) return;
    final lang = languageOf(context);
    setState(() {
      _saving = true;
      _failure = null;
    });
    try {
      await ref
          .read(consentServiceProvider)
          .recordAiDecision(
            uid: widget.uid,
            consentId: _consentId,
            granted: true,
            lang: lang,
          );
      if (mounted) _finish(true);
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
    final (before, after) = splitAround(l10n.aiConsentPolicy(_marker), _marker);
    final failure = _failure;

    Widget section(String title, String body) => Padding(
      padding: const EdgeInsets.only(bottom: Space.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: theme.textTheme.titleMedium),
          ),
          const SizedBox(height: Space.s1),
          Text(body, style: theme.textTheme.bodyLarge),
        ],
      ),
    );

    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: _saving ? null : _disagree),
          title: Semantics(header: true, child: Text(l10n.aiConsentTitle)),
        ),
        body: SafeArea(
          child: ContentColumn(
            child: StickyBottomLayout(
              content: [
                if (widget.updated) ...[
                  Notice(
                    key: const Key('aiConsentUpdated'),
                    variant: NoticeVariant.info,
                    icon: AppIcons.info,
                    text: l10n.aiConsentUpdatedIntro,
                  ),
                  const SizedBox(height: Space.s4),
                ],
                Text(l10n.aiConsentIntro, style: theme.textTheme.bodyLarge),
                const SizedBox(height: Space.s4),
                section(l10n.aiConsentSendTitle, l10n.aiConsentSendList),
                section(l10n.aiConsentNotSendTitle, l10n.aiConsentNotSendList),
                section(l10n.aiConsentRecipientTitle, l10n.aiConsentRecipient),
                Text(l10n.aiConsentErrors, style: theme.textTheme.bodyLarge),
                const SizedBox(height: Space.s4),
                Notice(
                  variant: NoticeVariant.warning,
                  icon: AppIcons.warning,
                  text: l10n.aiConsentSensitive,
                ),
                const SizedBox(height: Space.s4),
                Text(l10n.aiConsentWithdraw, style: theme.textTheme.bodyMedium),
                const SizedBox(height: Space.s4),
                Text(
                  l10n.aiConsentController,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: Space.s2),
                Semantics(
                  link: true,
                  label:
                      '$before${l10n.aiConsentPolicyLink}$after, ${l10n.commonOpensInBrowser}',
                  excludeSemantics: true,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: LayoutLimits.minTouchTarget,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text.rich(
                        TextSpan(
                          style: theme.textTheme.bodyMedium,
                          children: [
                            TextSpan(text: before),
                            TextSpan(
                              text: l10n.aiConsentPolicyLink,
                              recognizer: _policyTap,
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            TextSpan(text: after),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              bottom: [
                if (failure != null) ...[
                  failure.kind == FailureKind.offline
                      ? Notice(
                          key: const Key('aiConsentOffline'),
                          variant: NoticeVariant.warning,
                          icon: AppIcons.offline,
                          text: l10n.aiConsentOffline,
                          liveRegion: true,
                        )
                      : Notice(
                          key: const Key('aiConsentError'),
                          variant: NoticeVariant.error,
                          icon: AppIcons.error,
                          text: l10n.aiConsentSaveError,
                          liveRegion: true,
                        ),
                  const SizedBox(height: Space.s4),
                ],
                // Same style and weight; fixed order (security U-5).
                AppButton.outlined(
                  key: const Key('aiConsentAgree'),
                  label: l10n.aiConsentAgree,
                  loading: _saving,
                  loadingLabel: l10n.commonLoading,
                  onPressed: _agree,
                ),
                const SizedBox(height: Space.s2),
                AppButton.outlined(
                  key: const Key('aiConsentDisagree'),
                  label: l10n.aiConsentDisagree,
                  onPressed: _saving ? null : _disagree,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const _marker = '\u0000';
