/// App-wide constants for consents and links (ADR-0011 pkt 1, ADR-0012, ADR-0006 Aneks A pkt 1).
///
/// Changing the text of a consent in ANY language requires a new version here
/// (test/consent_text_version_test.dart pins a hash of the texts per version).
abstract final class AppConstants {
  /// Version of the privacy policy built into this app (`privacy-vN`, ADR-0012 pkt 1).
  /// The server must know it before the app is released (ADR-0012 pkt 6).
  static const privacyPolicyVersion = 'privacy-v1';

  /// Date of [privacyPolicyVersion]; only for the optional dated EK-03 text.
  static final privacyPolicyDate = DateTime.utc(2026, 11, 16);

  /// Working draft of the AI consent text (EK-06). The final legal text becomes
  /// `ai-consent-v2` (SEC-15, S15/S16); until then `ALLOW_REAL_DATA=false`.
  static const aiConsentVersion = 'ai-consent-v1';

  /// API contract version sent with every callable (posrednik-api.md pkt 1).
  static const apiVersion = 1;

  /// Privacy policy per UI language. The EN address is not decided yet
  /// (open question in docs/open-questions.md, P3-04).
  static final privacyPolicyUrls = <String, Uri>{
    'pl': Uri.parse('https://tadecode.pl/tamitu/prywatnosc'),
    'en': Uri.parse('https://tadecode.pl/tamitu/prywatnosc/en'),
  };

  /// "Update the app" target (EK-16): Google Play, no in-app update.
  static final playStoreUrl = Uri.parse(
    'https://play.google.com/store/apps/details?id=pl.tadecode.tamitu',
  );

  /// Number N of a `privacy-vN` / `ai-consent-vN` version, or null when malformed.
  static int? versionNumber(String version) {
    final m = RegExp(r'^(privacy|ai-consent)-v([1-9]\d{0,3})$')
        .firstMatch(version);
    return m == null ? null : int.parse(m.group(2)!);
  }
}
