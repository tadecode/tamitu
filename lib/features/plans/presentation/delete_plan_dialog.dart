import 'package:material_ui/material_ui.dart';

import '../../../core/ui/app_icon.dart';
import '../../../l10n/app_localizations.dart';

/// EK-11 Delete confirmation (US-009, CMP-15 destructive). Runs [delete] on "Delete":
/// loading (Cancel disabled, no dismiss), error (message, plan unchanged, "Try again" /
/// "Close"). Resolves true only when [delete] succeeded.
Future<bool> showDeletePlanDialog(
  BuildContext context, {
  required String destination,
  required Future<void> Function() delete,
}) async {
  final deleted = await showDialog<bool>(
    context: context,
    builder: (_) => _DeletePlanDialog(destination: destination, delete: delete),
  );
  return deleted == true;
}

enum _Phase { confirm, deleting, failed }

class _DeletePlanDialog extends StatefulWidget {
  const _DeletePlanDialog({required this.destination, required this.delete});

  final String destination;
  final Future<void> Function() delete;

  @override
  State<_DeletePlanDialog> createState() => _DeletePlanDialogState();
}

class _DeletePlanDialogState extends State<_DeletePlanDialog> {
  _Phase _phase = _Phase.confirm;

  Future<void> _run() async {
    setState(() => _phase = _Phase.deleting);
    try {
      await widget.delete();
    } catch (_) {
      if (mounted) setState(() => _phase = _Phase.failed);
      return;
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final busy = _phase == _Phase.deleting;
    final failed = _phase == _Phase.failed;
    final errorStyle = TextButton.styleFrom(foregroundColor: scheme.error);
    return PopScope(
      // Back = Cancel, except while deleting (CMP-15 "Zachowanie").
      canPop: !busy,
      child: AlertDialog(
        key: const Key('planDeleteDialog'),
        icon: AppIcon(AppIcons.delete, color: scheme.error),
        title: Semantics(header: true, child: Text(l10n.planDeleteTitle)),
        content: SingleChildScrollView(
          child: Text(
            failed
                ? l10n.planDeleteError
                : l10n.planDeleteBody(widget.destination),
            key: Key(failed ? 'planDeleteError' : 'planDeleteBody'),
          ),
        ),
        actions: failed
            ? [
                TextButton(
                  key: const Key('planDeleteClose'),
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(l10n.commonClose),
                ),
                TextButton(
                  key: const Key('planDeleteRetry'),
                  onPressed: _run,
                  child: Text(l10n.commonRetry),
                ),
              ]
            : [
                TextButton(
                  key: const Key('planDeleteCancel'),
                  onPressed: busy
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: Text(l10n.commonCancel),
                ),
                Semantics(
                  label: busy ? l10n.commonLoading : null,
                  child: TextButton(
                    key: const Key('planDeleteConfirm'),
                    style: errorStyle,
                    onPressed: busy ? null : _run,
                    child: busy
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.planDeleteConfirm),
                  ),
                ),
              ],
      ),
    );
  }
}
