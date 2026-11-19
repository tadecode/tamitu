import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../core/config/app_constants.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/ui/app_icon.dart';
import '../../../core/ui/components.dart';
import '../../../core/ui/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../session/session_controller.dart';

/// EK-02 Start screen: privacy and Google sign-in (US-001, US-003; spec v0.5).
///
/// The illustration is the approved "here and there" v0.5 (UX-ICON, 2026-11-19);
/// the wordmark stays text until the final logo (UX2).
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  /// Lives only in this screen's memory (CMP-09): never persisted, never pre-checked.
  bool _accepted = false;
  bool _loading = false;
  AppFailure? _failure;

  /// consentId of the current acceptance (ADR-0011 pkt 10); new one per check.
  String? _consentId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showFlash());
  }

  void _showFlash() {
    if (!mounted) return;
    final flash = ref.read(welcomeFlashProvider.notifier).take();
    if (flash == null) return;
    final l10n = AppLocalizations.of(context)!;
    final text = switch (flash) {
      WelcomeFlash.sessionExpired => l10n.errorSessionExpired,
      WelcomeFlash.accountDeleted => l10n.startAccountDeleted,
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _setAccepted(bool v) => setState(() {
    _accepted = v;
    _consentId = v ? ref.read(consentServiceProvider).newConsentId() : null;
  });

  void _changeLanguage(String code) {
    // P-3: the acceptance refers to the text that was shown – switching clears it.
    setState(() {
      _accepted = false;
      _consentId = null;
      _failure = null;
    });
    ref.read(uiLanguageProvider.notifier).set(code);
  }

  Future<void> _openPolicy() async {
    final lang = languageOf(context);
    await ref.read(urlOpenerProvider)(AppConstants.privacyPolicyUrls[lang]!);
  }

  Future<void> _signIn() async {
    final consentId = _consentId;
    if (!_accepted || _loading || consentId == null) return;
    final lang = languageOf(context);
    final messenger = ScaffoldMessenger.of(context);
    final cancelled = AppLocalizations.of(context)!.welcomeSignInCancelled;
    setState(() {
      _loading = true;
      _failure = null;
    });
    try {
      await ref
          .read(sessionProvider.notifier)
          .signInWithGoogle(consentId: consentId, lang: lang);
      // Success: the router leaves this screen.
    } on AppFailure catch (f) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failure = f.kind == FailureKind.cancelled ? null : f;
      });
      if (f.kind == FailureKind.cancelled) {
        messenger.showSnackBar(SnackBar(content: Text(cancelled)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final (before, after) = splitAround(
      l10n.consentPolicyCheckbox(_marker),
      _marker,
    );
    final failure = _failure;

    final content = <Widget>[
      Align(
        alignment: Alignment.centerRight,
        child: LanguageSwitch(
          languageCode: languageOf(context),
          label: l10n.languageSwitchLabel,
          onChanged: _loading ? null : _changeLanguage,
        ),
      ),
      const SizedBox(height: Space.s6),
      if (textScale < 2) ...[
        _WelcomeHero(height: textScale >= 1.5 ? 96 : 144),
        const SizedBox(height: Space.s4),
      ],
      Semantics(
        header: true,
        child: Text(
          l10n.appTitle,
          style: theme.textTheme.displaySmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
      const SizedBox(height: Space.s2),
      Text(l10n.welcomeTagline, style: theme.textTheme.bodyLarge),
      const SizedBox(height: Space.s6),
      Notice(
        variant: NoticeVariant.info,
        icon: AppIcons.privacy,
        title: l10n.welcomePrivacyTitle,
        text: l10n.welcomePrivacyBody,
      ),
      const SizedBox(height: Space.s4),
      Text(
        l10n.welcomeAdultsOnly,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: Space.s4),
      ConsentCheckbox(
        value: _accepted,
        onChanged: _loading ? null : _setAccepted,
        before: before,
        linkText: l10n.consentPolicyLink,
        after: after,
        onOpenLink: _openPolicy,
        linkHint: l10n.commonOpensInBrowser,
        linkButtonText: l10n.reconsentLink,
      ),
    ];

    final bottom = <Widget>[
      if (failure != null) ...[
        failure.kind == FailureKind.offline
            ? Notice(
                key: const Key('welcomeOffline'),
                variant: NoticeVariant.warning,
                icon: AppIcons.offline,
                text: l10n.commonOfflineNotice,
                liveRegion: true,
              )
            : Notice(
                key: const Key('welcomeError'),
                variant: NoticeVariant.error,
                icon: AppIcons.error,
                text: l10n.welcomeSignInError,
                liveRegion: true,
              ),
        const SizedBox(height: Space.s4),
      ],
      AppButton.filled(
        key: const Key('welcomeSignIn'),
        label: l10n.welcomeSignIn,
        loading: _loading,
        loadingLabel: l10n.welcomeSigningIn,
        disabledHint: _accepted ? null : l10n.welcomeSignInHint,
        onPressed: _accepted ? _signIn : null,
      ),
      if (!_accepted) ...[
        const SizedBox(height: Space.s1),
        ExcludeSemantics(
          child: Text(
            l10n.welcomeSignInHint,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    ];

    return Scaffold(
      body: SafeArea(
        child: ContentColumn(
          child: StickyBottomLayout(content: content, bottom: bottom),
        ),
      ),
    );
  }
}

/// Placeholder marker used to split the policy sentence around the link.
const _marker = '\u0000';

/// EK-02 illustration "here and there" v0.5 (UX-ICON), one file per theme brightness.
@visibleForTesting
const welcomeHeroAssetLight = 'assets/images/ek-02-illustration-light.svg';
@visibleForTesting
const welcomeHeroAssetDark = 'assets/images/ek-02-illustration-dark.svg';

/// Decorative EK-02 illustration (144 dp, 96 dp at >= 150 % text, hidden at 200 %;
/// cover-cropped to the centre, radius shape-l; excluded from semantics). The dark
/// theme uses the night variant instead of dimming (spec v0.5). The surfaceContainerHigh
/// background avoids a flash while the SVG loads.
class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final asset = theme.brightness == Brightness.dark
        ? welcomeHeroAssetDark
        : welcomeHeroAssetLight;
    return ExcludeSemantics(
      child: ClipRRect(
        key: const Key('welcomeHero'),
        borderRadius: BorderRadius.circular(Radii.l),
        child: ColoredBox(
          color: theme.colorScheme.surfaceContainerHigh,
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: SvgPicture.asset(
              asset,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              excludeFromSemantics: true,
            ),
          ),
        ),
      ),
    );
  }
}
