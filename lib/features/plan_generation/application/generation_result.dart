import '../../../core/errors/app_failure.dart';

/// How EK-07 ended when it returns to EK-05 (success navigates to EK-08 directly).
sealed class GenerationResult {
  const GenerationResult();
}

/// "Stop" confirmed in the cancel dialog: EK-05 shows `generationCancelledSnack`.
class GenerationCancelled extends GenerationResult {
  const GenerationCancelled();
}

/// "Back to the form" / system back in the "AI busy" state: no message (ek-07-ai-busy.md).
class GenerationBack extends GenerationResult {
  const GenerationBack();
}

/// `consent_required` for `ai_processing` without a synced record in the app's version:
/// EK-05 opens EK-06 with the "updated" intro (EK-16).
class GenerationNeedsAiConsent extends GenerationResult {
  const GenerationNeedsAiConsent();
}

/// Any other failure: EK-05 maps it with the EK-16 catalogue.
class GenerationFailed extends GenerationResult {
  const GenerationFailed(this.failure);

  final AppFailure failure;
}
