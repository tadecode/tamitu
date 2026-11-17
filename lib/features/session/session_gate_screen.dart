import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';

/// EK-01 while the session is being decided: plain `surface` (continuing the system
/// splash); after 500 ms a 48 dp circular indicator labelled "Loading" (CMP-17).
class SessionGateScreen extends StatefulWidget {
  const SessionGateScreen({super.key});

  static const indicatorDelay = Duration(milliseconds: 500);

  @override
  State<SessionGateScreen> createState() => _SessionGateScreenState();
}

class _SessionGateScreenState extends State<SessionGateScreen> {
  Timer? _timer;
  bool _showIndicator = false;

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
