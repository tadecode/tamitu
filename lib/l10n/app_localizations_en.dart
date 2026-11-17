// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Tamitu';

  @override
  String get homeTitle => 'Travel planner';

  @override
  String get homeSubtitle => 'Plan your trip with AI.';

  @override
  String get commonLoading => 'In progress…';

  @override
  String get commonLoadingLabel => 'Loading';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonOfflineNotice =>
      'No internet connection. This feature needs a network.';

  @override
  String get commonOpensInBrowser => 'opens in browser';

  @override
  String get languageSwitchLabel => 'App language';

  @override
  String get welcomeTagline =>
      'Your day-by-day travel plan – here and there, in one place.';

  @override
  String get welcomePrivacyTitle => 'Your privacy';

  @override
  String get welcomePrivacyBody =>
      'We store your trips only on this phone. To create a plan we send trip details to an AI service – we\'ll ask for your consent before your first plan.';

  @override
  String get welcomeAdultsOnly => 'Tamitu is for adults only.';

  @override
  String consentPolicyCheckbox(String policyLink) {
    return 'I confirm I have read and accept the $policyLink';
  }

  @override
  String get consentPolicyLink => 'Privacy Policy';

  @override
  String get welcomeSignIn => 'Sign in with Google';

  @override
  String get welcomeSignInHint => 'Accept the Privacy Policy to sign in.';

  @override
  String get welcomeSigningIn => 'Signing in…';

  @override
  String get welcomeSignInCancelled => 'Sign-in cancelled.';

  @override
  String get welcomeSignInError => 'Couldn\'t sign in. Please try again.';

  @override
  String get startAccountDeleted =>
      'Your account and data on this device have been deleted.';

  @override
  String get reconsentTitle => 'Updated Privacy Policy';

  @override
  String get reconsentBody =>
      'We\'ve updated our Privacy Policy. To keep using Tamitu, please read and accept it. Your trips stay on this device.';

  @override
  String get reconsentLink => 'Read the Privacy Policy';

  @override
  String get reconsentBodyDataReset =>
      'The data on this device was cleared, so we need you to accept the Privacy Policy again. Please read and accept it to keep using Tamitu.';

  @override
  String reconsentBodyDated(String date) {
    return 'We updated our Privacy Policy ($date). To keep using Tamitu, please read and accept it. Your trips stay on this device.';
  }

  @override
  String get reconsentAccept => 'Accept and continue';

  @override
  String get reconsentSaveError =>
      'Couldn\'t save your acceptance. Please try again.';

  @override
  String get reconsentOffline =>
      'Connect to the internet to accept the policy.';

  @override
  String get reconsentSignOut => 'Sign out';

  @override
  String get reconsentDeleteAccount => 'Delete account';

  @override
  String get aiConsentTitle => 'Consent to use AI';

  @override
  String get aiConsentIntro =>
      'Plans are created by an artificial intelligence model. To do this, we need to send it your trip details.';

  @override
  String get aiConsentSendTitle => 'What we send';

  @override
  String get aiConsentSendList =>
      'Destination, accommodation name or area, number of days, arrival date, time and mode, airport; preferences (interests, budget, pace, number of travellers) and plan language.';

  @override
  String get aiConsentNotSendTitle => 'What we don\'t send';

  @override
  String get aiConsentNotSendList =>
      'Your email, name, account ID, location or flight number.';

  @override
  String get aiConsentRecipientTitle => 'Who receives the data';

  @override
  String get aiConsentRecipient =>
      'Google Cloud AI service (Vertex AI) in the EU region. Our intermediary server processes the data in memory only – we don\'t store or log it.';

  @override
  String get aiConsentErrors =>
      'The plan may contain mistakes – check opening hours and availability.';

  @override
  String get aiConsentSensitive =>
      'Don\'t enter a full private address, sensitive data or other people\'s data in the form.';

  @override
  String get aiConsentWithdraw =>
      'You can withdraw consent at any time in Settings → Privacy. We block creating new plans right away and record the withdrawal on our server as soon as there is a connection. Saved plans remain.';

  @override
  String get aiConsentController =>
      'The controller of your data is TadeCode (contact: tamitu@tadecode.pl).';

  @override
  String get aiConsentUpdatedIntro =>
      'We\'ve updated the AI consent. Please read it and decide again – until then we can\'t create new plans.';

  @override
  String aiConsentPolicy(String policyLink) {
    return 'Details in the $policyLink.';
  }

  @override
  String get aiConsentPolicyLink => 'Privacy Policy';

  @override
  String get aiConsentAgree => 'I agree';

  @override
  String get aiConsentDisagree => 'I don\'t agree';

  @override
  String get aiConsentSaveError =>
      'Couldn\'t save your consent. Nothing was sent. Please try again.';

  @override
  String get aiConsentOffline => 'Connect to the internet to give consent.';

  @override
  String get aiConsentGivenSnack => 'AI consent given';

  @override
  String get errorGenericTitle => 'Something went wrong';

  @override
  String get errorGenericBody =>
      'Please try again in a moment. Your trips on this device haven\'t changed.';

  @override
  String get errorOfflineTitle => 'You\'re offline';

  @override
  String get errorOfflineBody =>
      'Check your internet connection and try again.';

  @override
  String get errorGenerateTitle => 'Couldn\'t create the plan';

  @override
  String get errorAiUnavailableBody =>
      'The AI service is temporarily unavailable. This attempt doesn\'t count towards your limit. Please try again shortly.';

  @override
  String get errorAiInvalidBody =>
      'The AI returned an incomplete plan, so we didn\'t save it. This attempt doesn\'t count towards your limit. Please try again.';

  @override
  String get errorTimeoutBody =>
      'Creating the plan took too long. This attempt may have counted towards today\'s limit. Please try again.';

  @override
  String get errorLimitTitle => 'You\'ve reached today\'s plan limit';

  @override
  String errorLimitBody(int limit, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: '$limit plans',
      one: '1 plan',
    );
    return 'You can create $_temp0 a day. More from tomorrow at $time. Your saved trips are still available.';
  }

  @override
  String get errorUpdateTitle => 'Update the app';

  @override
  String get errorUpdateBody =>
      'This version of Tamitu is no longer supported. Update the app in Google Play to create plans. Your saved trips are available.';

  @override
  String get errorUpdateAction => 'Update app';

  @override
  String get errorUnavailableForAccountBody =>
      'Creating plans is temporarily unavailable. Please try later.';

  @override
  String get errorSessionExpired =>
      'Your session has expired. Sign in again – your trips are on this device.';

  @override
  String get errorInvalidFormBody =>
      'Check the details in the form and try again.';
}
