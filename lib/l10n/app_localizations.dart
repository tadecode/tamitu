import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pl'),
  ];

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'Tamitu'**
  String get appTitle;

  /// Placeholder home (EK-04 comes later)
  ///
  /// In en, this message translates to:
  /// **'Travel planner'**
  String get homeTitle;

  /// Placeholder home subtitle
  ///
  /// In en, this message translates to:
  /// **'Plan your trip with AI.'**
  String get homeSubtitle;

  /// CMP-02 loading state
  ///
  /// In en, this message translates to:
  /// **'In progress…'**
  String get commonLoading;

  /// EK-01 TalkBack label of the progress indicator
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get commonLoadingLabel;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonRetry;

  /// No description provided for @commonOfflineNotice.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. This feature needs a network.'**
  String get commonOfflineNotice;

  /// TalkBack hint for links that open the browser (CMP-09)
  ///
  /// In en, this message translates to:
  /// **'opens in browser'**
  String get commonOpensInBrowser;

  /// TalkBack label of the PL/EN switch on EK-02 (CMP-07)
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get languageSwitchLabel;

  /// No description provided for @welcomeTagline.
  ///
  /// In en, this message translates to:
  /// **'Your day-by-day travel plan – here and there, in one place.'**
  String get welcomeTagline;

  /// No description provided for @welcomePrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your privacy'**
  String get welcomePrivacyTitle;

  /// No description provided for @welcomePrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'We store your trips only on this phone. To create a plan we send trip details to an AI service – we\'ll ask for your consent before your first plan.'**
  String get welcomePrivacyBody;

  /// No description provided for @welcomeAdultsOnly.
  ///
  /// In en, this message translates to:
  /// **'Tamitu is for adults only.'**
  String get welcomeAdultsOnly;

  /// CMP-09, one text for EK-02 and EK-03. Changing it requires a new privacy policy version.
  ///
  /// In en, this message translates to:
  /// **'I confirm I have read and accept the {policyLink}'**
  String consentPolicyCheckbox(String policyLink);

  /// No description provided for @consentPolicyLink.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get consentPolicyLink;

  /// No description provided for @welcomeSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get welcomeSignIn;

  /// No description provided for @welcomeSignInHint.
  ///
  /// In en, this message translates to:
  /// **'Accept the Privacy Policy to sign in.'**
  String get welcomeSignInHint;

  /// No description provided for @welcomeSigningIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in…'**
  String get welcomeSigningIn;

  /// No description provided for @welcomeSignInCancelled.
  ///
  /// In en, this message translates to:
  /// **'Sign-in cancelled.'**
  String get welcomeSignInCancelled;

  /// No description provided for @welcomeSignInError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sign in. Please try again.'**
  String get welcomeSignInError;

  /// No description provided for @startAccountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Your account and data on this device have been deleted.'**
  String get startAccountDeleted;

  /// No description provided for @reconsentTitle.
  ///
  /// In en, this message translates to:
  /// **'Updated Privacy Policy'**
  String get reconsentTitle;

  /// No description provided for @reconsentBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ve updated our Privacy Policy. To keep using Tamitu, please read and accept it. Your trips stay on this device.'**
  String get reconsentBody;

  /// No description provided for @reconsentLink.
  ///
  /// In en, this message translates to:
  /// **'Read the Privacy Policy'**
  String get reconsentLink;

  /// No description provided for @reconsentBodyDataReset.
  ///
  /// In en, this message translates to:
  /// **'The data on this device was cleared, so we need you to accept the Privacy Policy again. Please read and accept it to keep using Tamitu.'**
  String get reconsentBodyDataReset;

  /// Optional dated EK-03 text
  ///
  /// In en, this message translates to:
  /// **'We updated our Privacy Policy ({date}). To keep using Tamitu, please read and accept it. Your trips stay on this device.'**
  String reconsentBodyDated(String date);

  /// No description provided for @reconsentAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept and continue'**
  String get reconsentAccept;

  /// No description provided for @reconsentSaveError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your acceptance. Please try again.'**
  String get reconsentSaveError;

  /// No description provided for @reconsentOffline.
  ///
  /// In en, this message translates to:
  /// **'Connect to the internet to accept the policy.'**
  String get reconsentOffline;

  /// No description provided for @reconsentSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get reconsentSignOut;

  /// No description provided for @reconsentDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get reconsentDeleteAccount;

  /// No description provided for @aiConsentTitle.
  ///
  /// In en, this message translates to:
  /// **'Consent to use AI'**
  String get aiConsentTitle;

  /// No description provided for @aiConsentIntro.
  ///
  /// In en, this message translates to:
  /// **'Plans are created by an artificial intelligence model. To do this, we need to send it your trip details.'**
  String get aiConsentIntro;

  /// No description provided for @aiConsentSendTitle.
  ///
  /// In en, this message translates to:
  /// **'What we send'**
  String get aiConsentSendTitle;

  /// No description provided for @aiConsentSendList.
  ///
  /// In en, this message translates to:
  /// **'Destination, accommodation name or area, number of days, arrival date, time and mode, airport; preferences (interests, budget, pace, number of travellers) and plan language.'**
  String get aiConsentSendList;

  /// No description provided for @aiConsentNotSendTitle.
  ///
  /// In en, this message translates to:
  /// **'What we don\'t send'**
  String get aiConsentNotSendTitle;

  /// No description provided for @aiConsentNotSendList.
  ///
  /// In en, this message translates to:
  /// **'Your email, name, account ID, location or flight number.'**
  String get aiConsentNotSendList;

  /// No description provided for @aiConsentRecipientTitle.
  ///
  /// In en, this message translates to:
  /// **'Who receives the data'**
  String get aiConsentRecipientTitle;

  /// No description provided for @aiConsentRecipient.
  ///
  /// In en, this message translates to:
  /// **'Google Cloud AI service (Vertex AI) in the EU region. Our intermediary server processes the data in memory only – we don\'t store or log it.'**
  String get aiConsentRecipient;

  /// No description provided for @aiConsentErrors.
  ///
  /// In en, this message translates to:
  /// **'The plan may contain mistakes – check opening hours and availability.'**
  String get aiConsentErrors;

  /// No description provided for @aiConsentSensitive.
  ///
  /// In en, this message translates to:
  /// **'Don\'t enter a full private address, sensitive data or other people\'s data in the form.'**
  String get aiConsentSensitive;

  /// No description provided for @aiConsentWithdraw.
  ///
  /// In en, this message translates to:
  /// **'You can withdraw consent at any time in Settings → Privacy. We block creating new plans right away and record the withdrawal on our server as soon as there is a connection. Saved plans remain.'**
  String get aiConsentWithdraw;

  /// No description provided for @aiConsentController.
  ///
  /// In en, this message translates to:
  /// **'The controller of your data is TadeCode (contact: tamitu@tadecode.pl).'**
  String get aiConsentController;

  /// No description provided for @aiConsentUpdatedIntro.
  ///
  /// In en, this message translates to:
  /// **'We\'ve updated the AI consent. Please read it and decide again – until then we can\'t create new plans.'**
  String get aiConsentUpdatedIntro;

  /// EK-06; part of the AI consent text (ai-consent-v1)
  ///
  /// In en, this message translates to:
  /// **'Details in the {policyLink}.'**
  String aiConsentPolicy(String policyLink);

  /// Link text inside aiConsentPolicy (PL needs the locative case)
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get aiConsentPolicyLink;

  /// No description provided for @aiConsentAgree.
  ///
  /// In en, this message translates to:
  /// **'I agree'**
  String get aiConsentAgree;

  /// No description provided for @aiConsentDisagree.
  ///
  /// In en, this message translates to:
  /// **'I don\'t agree'**
  String get aiConsentDisagree;

  /// No description provided for @aiConsentSaveError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your consent. Nothing was sent. Please try again.'**
  String get aiConsentSaveError;

  /// No description provided for @aiConsentOffline.
  ///
  /// In en, this message translates to:
  /// **'Connect to the internet to give consent.'**
  String get aiConsentOffline;

  /// No description provided for @aiConsentGivenSnack.
  ///
  /// In en, this message translates to:
  /// **'AI consent given'**
  String get aiConsentGivenSnack;

  /// No description provided for @errorGenericTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorGenericTitle;

  /// No description provided for @errorGenericBody.
  ///
  /// In en, this message translates to:
  /// **'Please try again in a moment. Your trips on this device haven\'t changed.'**
  String get errorGenericBody;

  /// No description provided for @errorOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline'**
  String get errorOfflineTitle;

  /// No description provided for @errorOfflineBody.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection and try again.'**
  String get errorOfflineBody;

  /// No description provided for @errorGenerateTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create the plan'**
  String get errorGenerateTitle;

  /// EK-16 ai_unavailable with details.slotReleased = true: the attempt did not use the daily limit (TAM-94)
  ///
  /// In en, this message translates to:
  /// **'The AI service is temporarily unavailable. This attempt doesn\'t count towards today\'s limit. Please try again shortly.'**
  String get errorAiUnavailableBody;

  /// EK-16 ai_unavailable with details.slotReleased = false: the attempt counted (max 2 give-backs per day) (TAM-94)
  ///
  /// In en, this message translates to:
  /// **'The AI service is temporarily unavailable. This attempt counted towards today\'s limit, because we give back failed attempts at most twice a day. Please try again later.'**
  String get errorAiUnavailableCountedBody;

  /// EK-16 ai_unavailable without details.slotReleased (older server): unknown whether the attempt counted (TAM-94)
  ///
  /// In en, this message translates to:
  /// **'The AI service is temporarily unavailable. This attempt may have counted towards today\'s limit. Please try again shortly.'**
  String get errorAiUnavailableMaybeBody;

  /// EK-16 ai_invalid_response with details.slotReleased = true: the attempt did not use the daily limit (TAM-94)
  ///
  /// In en, this message translates to:
  /// **'The AI returned an incomplete plan, so we didn\'t save it. This attempt doesn\'t count towards today\'s limit. Please try again.'**
  String get errorAiInvalidBody;

  /// EK-16 ai_invalid_response with details.slotReleased = false: the attempt counted (max 2 give-backs per day) (TAM-94)
  ///
  /// In en, this message translates to:
  /// **'The AI returned an incomplete plan, so we didn\'t save it. This attempt counted towards today\'s limit, because we give back failed attempts at most twice a day.'**
  String get errorAiInvalidCountedBody;

  /// EK-16 ai_invalid_response without details.slotReleased (older server): unknown whether the attempt counted (TAM-94)
  ///
  /// In en, this message translates to:
  /// **'The AI returned an incomplete plan, so we didn\'t save it. This attempt may have counted towards today\'s limit. Please try again.'**
  String get errorAiInvalidMaybeBody;

  /// No description provided for @errorTimeoutBody.
  ///
  /// In en, this message translates to:
  /// **'Creating the plan took too long. This attempt may have counted towards today\'s limit. Please try again.'**
  String get errorTimeoutBody;

  /// No description provided for @errorLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached today\'s plan limit'**
  String get errorLimitTitle;

  /// EK-16 limit_exceeded; time = reset time in the device's local time
  ///
  /// In en, this message translates to:
  /// **'You can create {limit, plural, one{1 plan} other{{limit} plans}} a day. More from tomorrow at {time}. Your saved trips are still available.'**
  String errorLimitBody(int limit, String time);

  /// No description provided for @errorUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Update the app'**
  String get errorUpdateTitle;

  /// No description provided for @errorUpdateBody.
  ///
  /// In en, this message translates to:
  /// **'This version of Tamitu is no longer supported. Update the app in Google Play to create plans. Your saved trips are available.'**
  String get errorUpdateBody;

  /// No description provided for @errorUpdateAction.
  ///
  /// In en, this message translates to:
  /// **'Update app'**
  String get errorUpdateAction;

  /// No description provided for @errorUnavailableForAccountBody.
  ///
  /// In en, this message translates to:
  /// **'Creating plans is temporarily unavailable. Please try later.'**
  String get errorUnavailableForAccountBody;

  /// No description provided for @errorSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Sign in again – your trips are on this device.'**
  String get errorSessionExpired;

  /// No description provided for @errorInvalidFormBody.
  ///
  /// In en, this message translates to:
  /// **'Check the details in the form and try again.'**
  String get errorInvalidFormBody;

  /// No description provided for @generationBusyTitle.
  ///
  /// In en, this message translates to:
  /// **'Our AI assistant is busy right now'**
  String get generationBusyTitle;

  /// No description provided for @generationBusyStillTitle.
  ///
  /// In en, this message translates to:
  /// **'Our AI assistant is still busy'**
  String get generationBusyStillTitle;

  /// No description provided for @generationBusyBodyAuto.
  ///
  /// In en, this message translates to:
  /// **'We\'ll try again in {minutes, plural, one{a minute} other{{minutes} minutes}}. You don\'t need to do anything.'**
  String generationBusyBodyAuto(int minutes);

  /// No description provided for @generationBusyBodyManual.
  ///
  /// In en, this message translates to:
  /// **'Please try again in a moment. Your trip details are kept in the form.'**
  String get generationBusyBodyManual;

  /// No description provided for @generationBusyBodyPaused.
  ///
  /// In en, this message translates to:
  /// **'We didn\'t retry while the app was in the background. You can try now.'**
  String get generationBusyBodyPaused;

  /// No description provided for @generationBusyQuotaReleased.
  ///
  /// In en, this message translates to:
  /// **'This attempt doesn\'t count towards your limit.'**
  String get generationBusyQuotaReleased;

  /// No description provided for @generationBusyQuotaCounted.
  ///
  /// In en, this message translates to:
  /// **'This attempt counted towards today\'s limit.'**
  String get generationBusyQuotaCounted;

  /// No description provided for @generationBusyQuotaUnknown.
  ///
  /// In en, this message translates to:
  /// **'This attempt may have counted towards today\'s limit.'**
  String get generationBusyQuotaUnknown;

  /// No description provided for @generationBusyCountdown.
  ///
  /// In en, this message translates to:
  /// **'Retrying in {time}'**
  String generationBusyCountdown(String time);

  /// No description provided for @generationBusyCountdownA11y.
  ///
  /// In en, this message translates to:
  /// **'Retrying in {seconds, plural, one{1 second} other{{seconds} seconds}}'**
  String generationBusyCountdownA11y(int seconds);

  /// No description provided for @generationBusyTryNow.
  ///
  /// In en, this message translates to:
  /// **'Try now'**
  String get generationBusyTryNow;

  /// No description provided for @generationBusyBack.
  ///
  /// In en, this message translates to:
  /// **'Back to the form'**
  String get generationBusyBack;

  /// No description provided for @generationRetrying.
  ///
  /// In en, this message translates to:
  /// **'Trying again…'**
  String get generationRetrying;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pl':
      return AppLocalizationsPl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
