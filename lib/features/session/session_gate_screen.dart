import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/ui/app_icon.dart';
import '../../core/ui/components.dart';
import '../../l10n/app_localizations.dart';
import 'session_controller.dart';

/// EK-01 while the session is being decided: plain `surface` (continuing the system
/// splash); after 500 ms a 48 dp circular indicator labelled "Loading" (CMP-17).
/// When the account database cannot be opened (not a lost key): CMP-18 error with
/// retry, data untouched (EK-01 "inny błąd otwarcia bazy").
class SessionGateScreen extends ConsumerStatefulWidget {
  const SessionGateScreen({super.key});

  static const indicatorDelay = Duration(milliseconds: 500);

  @override
  ConsumerState<SessionGateScreen> createState() => _SessionGateScreenState();
}

class _SessionGateScreenState extends ConsumerState<SessionGateScreen> {
  Timer? _timer;
  bool _showIndicator = false;
  bool _retrying = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(SessionGateScreen.indicatorDelay, () {
      if (mounted) setState(() => _showIndicator = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _retry() async {
    setState(() => _retrying = true);
    await ref.read(sessionProvider.notifier).refresh();
    if (mounted) setState(() => _retrying = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final status = ref.watch(sessionProvider);
    if (status is SessionStorageError) {
      return Scaffold(
        body: SafeArea(
          child: StateView(
            icon: AppIcons.error,
            title: l10n.errorGenericTitle,
            body: l10n.errorGenericBody,
            primary: AppButton.filled(
              key: const Key('gateRetry'),
              label: l10n.commonRetry,
              loading: _retrying,
              loadingLabel: l10n.commonLoading,
              onPressed: _retry,
            ),
          ),
        ),
      );
    }
    return Scaffold(
      body: Center(
        child: _showIndicator
            ? Semantics(
                label: l10n.commonLoadingLabel,
                child: const SizedBox.square(
                  dimension: 48,
                  child: CircularProgressIndicator(),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
