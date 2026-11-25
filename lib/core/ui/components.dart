import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';

import 'app_icon.dart';
import 'tokens.dart';

/// CMP-13 variants (docs/ux/components/notice.md).
enum NoticeVariant { info, warning, error }

/// CMP-13 Notice in content: icon + optional title + text. Announced politely by
/// TalkBack (live region); the icon is decorative.
class Notice extends StatelessWidget {
  const Notice({
    super.key,
    required this.variant,
    required this.icon,
    required this.text,
    this.title,
    this.liveRegion = false,
  });

  final NoticeVariant variant;
  final AppIcons icon;
  final String? title;
  final String text;

  /// True for notices that appear after an action (offline, errors).
  final bool liveRegion;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final (bg, fg) = switch (variant) {
      NoticeVariant.error => (scheme.errorContainer, scheme.onErrorContainer),
      _ => (scheme.secondaryContainer, scheme.onSecondaryContainer),
    };
    return Semantics(
      liveRegion: liveRegion,
      container: true,
      child: Card.filled(
        color: bg,
        child: Padding(
          padding: const EdgeInsets.all(Space.s4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIcon(icon, color: fg),
              const SizedBox(width: Space.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null) ...[
                      Text(title!, style: text.titleSmall?.copyWith(color: fg)),
                      const SizedBox(height: Space.s1),
                    ],
                    Text(
                      this.text,
                      style: text.bodyMedium?.copyWith(color: fg),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ButtonVariant { filled, tonal, outlined }

/// CMP-02 filled/tonal/outlined button with a loading state: the label is replaced by a 20 dp
/// spinner, width unchanged, taps blocked; TalkBack reads "[loadingLabel]".
class AppButton extends StatelessWidget {
  const AppButton.filled({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.loadingLabel,
    this.disabledHint,
    this.focusNode,
  }) : _variant = _ButtonVariant.filled;

  /// Tonal (secondary container) button, e.g. "Try now" in the CMP-18 "AI busy" variant.
  const AppButton.tonal({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.loadingLabel,
    this.disabledHint,
    this.focusNode,
  }) : _variant = _ButtonVariant.tonal;

  const AppButton.outlined({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.loadingLabel,
    this.disabledHint,
    this.focusNode,
  }) : _variant = _ButtonVariant.outlined;

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  /// Spoken while loading (e.g. "Signing in…").
  final String? loadingLabel;

  /// Reason read together with a disabled button (EK-02: why it is disabled).
  final String? disabledHint;

  /// Lets a screen put input focus back on the button (EK-05 after EK-07, TAM-102).
  final FocusNode? focusNode;
  final _ButtonVariant _variant;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final child = loading
        ? const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(label, textAlign: TextAlign.center);
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(40)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: Space.s6, vertical: Space.s2),
      ),
    );
    final button = switch (_variant) {
      _ButtonVariant.outlined => OutlinedButton(
        onPressed: enabled ? onPressed : null,
        focusNode: focusNode,
        style: style,
        child: child,
      ),
      _ButtonVariant.tonal => FilledButton.tonal(
        onPressed: enabled ? onPressed : null,
        focusNode: focusNode,
        style: style,
        child: child,
      ),
      _ButtonVariant.filled => FilledButton(
        onPressed: enabled ? onPressed : null,
        focusNode: focusNode,
        style: style,
        child: child,
      ),
    };
    final spoken = loading
        ? (loadingLabel ?? label)
        : (!enabled && disabledHint != null ? '$label. $disabledHint' : label);
    return Semantics(
      button: true,
      enabled: enabled,
      label: spoken,
      excludeSemantics: true,
      child: button,
    );
  }
}

/// CMP-09 consent row: checkbox + text with an inline link. The whole row toggles; the
/// link only opens the document. TalkBack label = visible text (P-2).
class ConsentCheckbox extends StatefulWidget {
  const ConsentCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.before,
    required this.linkText,
    required this.after,
    required this.onOpenLink,
    required this.linkHint,
    this.linkButtonText,
  });

  final bool value;

  /// Null = disabled (e.g. while signing in).
  final ValueChanged<bool>? onChanged;
  final String before;
  final String linkText;
  final String after;
  final VoidCallback onOpenLink;

  /// "opens in browser"
  final String linkHint;

  /// Text of the separate 48 dp link button under the row (nominative, e.g. "Read the
  /// Privacy Policy"); null when the screen already shows such a link (EK-03).
  final String? linkButtonText;

  @override
  State<ConsentCheckbox> createState() => _ConsentCheckboxState();
}

class _ConsentCheckboxState extends State<ConsentCheckbox> {
  late final _linkTap = TapGestureRecognizer()
    ..onTap = () => widget.onOpenLink();

  @override
  void dispose() {
    _linkTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final value = w.value;
    final onChanged = w.onChanged;
    final before = w.before;
    final linkText = w.linkText;
    final after = w.after;
    final onOpenLink = w.onOpenLink;
    final linkHint = w.linkHint;
    final theme = Theme.of(context);
    final enabled = onChanged != null;
    final style = theme.textTheme.bodyLarge?.copyWith(
      color: theme.colorScheme.onSurface,
    );
    final linkStyle = style?.copyWith(
      color: theme.colorScheme.primary,
      decoration: TextDecoration.underline,
    );
    final full = '$before$linkText$after';
    return Opacity(
      opacity: enabled ? 1 : 0.38,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MergeSemantics(
            child: InkWell(
              onTap: enabled ? () => onChanged(!value) : null,
              borderRadius: BorderRadius.circular(Radii.s),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: LayoutLimits.minTouchTarget,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: value,
                      onChanged: enabled ? (v) => onChanged(v ?? false) : null,
                    ),
                    const SizedBox(width: Space.s2),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: Space.s3),
                        child: Semantics(
                          label: full,
                          excludeSemantics: true,
                          child: Text.rich(
                            TextSpan(
                              style: style,
                              children: [
                                TextSpan(text: before),
                                TextSpan(
                                  text: linkText,
                                  style: linkStyle,
                                  recognizer: _linkTap,
                                ),
                                TextSpan(text: after),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Separate 48 dp link target, also the link node for TalkBack (CMP-09).
          if (w.linkButtonText != null)
            Padding(
              padding: const EdgeInsets.only(left: Space.s12),
              child: Semantics(
                link: true,
                label: '${w.linkButtonText}, $linkHint',
                excludeSemantics: true,
                child: TextButton.icon(
                  onPressed: onOpenLink,
                  icon: const AppIcon(AppIcons.openExternal, size: 18),
                  label: Text(w.linkButtonText!),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Splits a message with one placeholder into (before, after) around [marker].
(String, String) splitAround(String message, String marker) {
  final i = message.indexOf(marker);
  if (i < 0) return (message, '');
  return (message.substring(0, i), message.substring(i + marker.length));
}

/// CMP-07 PL/EN segmented switch (EK-02, U1). Selected segment shows `tick-02`.
class LanguageSwitch extends StatelessWidget {
  const LanguageSwitch({
    super.key,
    required this.languageCode,
    required this.onChanged,
    required this.label,
  });

  final String languageCode;

  /// Null = disabled.
  final ValueChanged<String>? onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      container: true,
      child: SegmentedButton<String>(
        segments: const [
          ButtonSegment(
            value: 'pl',
            label: Text('PL', semanticsLabel: 'Polski'),
          ),
          ButtonSegment(
            value: 'en',
            label: Text('EN', semanticsLabel: 'English'),
          ),
        ],
        selected: {languageCode},
        showSelectedIcon: true,
        selectedIcon: const AppIcon(AppIcons.selected, size: 18),
        onSelectionChanged: onChanged == null
            ? null
            : (s) => onChanged!(s.first),
      ),
    );
  }
}

/// CMP-18 state view (blocking / offline / error): icon 48, headline, body, actions.
/// Focus moves to the title (header) when shown.
class StateView extends StatelessWidget {
  const StateView({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.detail,
    this.primary,
    this.secondary,
  });

  final AppIcons icon;
  final String title;
  final String body;

  /// Optional content between the body and the actions (24 dp above), e.g. the
  /// countdown of the "AI busy" variant (EK-07, ek-07-ai-busy.md).
  final Widget? detail;
  final Widget? primary;
  final Widget? secondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Space.s4),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: LayoutLimits.stateTextMaxWidth,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(
                icon,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: Space.s4),
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: Space.s2),
              Text(
                body,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (detail != null) ...[
                const SizedBox(height: Space.s6),
                detail!,
              ],
              if (primary != null) ...[
                const SizedBox(height: Space.s6),
                primary!,
              ],
              if (secondary != null) ...[
                const SizedBox(height: Space.s2),
                secondary!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Centred content column (max 560 dp on medium/expanded windows, layout.md).
class ContentColumn extends StatelessWidget {
  const ContentColumn({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: LayoutLimits.contentMaxWidth),
      child: child,
    ),
  );
}

/// Scrollable content with the action area stuck to the bottom when the content is
/// shorter than the screen; with large text (200 %) the actions scroll with the content
/// (EK-02, EK-03, EK-06).
class StickyBottomLayout extends StatelessWidget {
  const StickyBottomLayout({
    super.key,
    required this.content,
    required this.bottom,
  });

  final List<Widget> content;
  final List<Widget> bottom;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: Space.s4),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: Space.s2),
                ...content,
                const Spacer(),
                const SizedBox(height: Space.s4),
                ...bottom,
                const SizedBox(height: Space.s4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
