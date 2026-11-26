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

  /// No description provided for @tripFormTitle.
  ///
  /// In en, this message translates to:
  /// **'New trip'**
  String get tripFormTitle;

  /// No description provided for @tripFormSectionWhere.
  ///
  /// In en, this message translates to:
  /// **'Where'**
  String get tripFormSectionWhere;

  /// No description provided for @tripFormSectionWhen.
  ///
  /// In en, this message translates to:
  /// **'When and how'**
  String get tripFormSectionWhen;

  /// No description provided for @tripFormSectionPrefs.
  ///
  /// In en, this message translates to:
  /// **'Preferences (optional)'**
  String get tripFormSectionPrefs;

  /// No description provided for @tripFormDestination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get tripFormDestination;

  /// No description provided for @tripFormDestinationHelper.
  ///
  /// In en, this message translates to:
  /// **'City or region, e.g. Lisbon'**
  String get tripFormDestinationHelper;

  /// No description provided for @tripFormLodging.
  ///
  /// In en, this message translates to:
  /// **'Accommodation name or area'**
  String get tripFormLodging;

  /// No description provided for @tripFormLodgingHelper.
  ///
  /// In en, this message translates to:
  /// **'Don\'t enter a full private address.'**
  String get tripFormLodgingHelper;

  /// No description provided for @tripFormDays.
  ///
  /// In en, this message translates to:
  /// **'Number of days'**
  String get tripFormDays;

  /// No description provided for @tripFormDaysError.
  ///
  /// In en, this message translates to:
  /// **'Choose the number of days (1–14)'**
  String get tripFormDaysError;

  /// No description provided for @tripFormArrivalMode.
  ///
  /// In en, this message translates to:
  /// **'How you get there'**
  String get tripFormArrivalMode;

  /// No description provided for @tripFormArrivalFlight.
  ///
  /// In en, this message translates to:
  /// **'Flight'**
  String get tripFormArrivalFlight;

  /// No description provided for @tripFormArrivalCar.
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get tripFormArrivalCar;

  /// No description provided for @tripFormArrivalModeError.
  ///
  /// In en, this message translates to:
  /// **'Choose how you get there'**
  String get tripFormArrivalModeError;

  /// No description provided for @tripFormDateFlight.
  ///
  /// In en, this message translates to:
  /// **'Arrival date'**
  String get tripFormDateFlight;

  /// No description provided for @tripFormDateCar.
  ///
  /// In en, this message translates to:
  /// **'Arrival date'**
  String get tripFormDateCar;

  /// No description provided for @tripFormTimeFlight.
  ///
  /// In en, this message translates to:
  /// **'Landing time'**
  String get tripFormTimeFlight;

  /// No description provided for @tripFormTimeCar.
  ///
  /// In en, this message translates to:
  /// **'Arrival time'**
  String get tripFormTimeCar;

  /// No description provided for @commonLocalTimeHelper.
  ///
  /// In en, this message translates to:
  /// **'Local time at your destination'**
  String get commonLocalTimeHelper;

  /// No description provided for @tripFormAirport.
  ///
  /// In en, this message translates to:
  /// **'Airport'**
  String get tripFormAirport;

  /// No description provided for @tripFormAirportHelper.
  ///
  /// In en, this message translates to:
  /// **'Name or code, e.g. LIS'**
  String get tripFormAirportHelper;

  /// No description provided for @tripFormFlightNumber.
  ///
  /// In en, this message translates to:
  /// **'Flight number (optional)'**
  String get tripFormFlightNumber;

  /// No description provided for @tripFormFlightNumberHelper.
  ///
  /// In en, this message translates to:
  /// **'Stays on your phone – we don\'t send it to AI.'**
  String get tripFormFlightNumberHelper;

  /// No description provided for @tripFormInterests.
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get tripFormInterests;

  /// No description provided for @tripFormInterestsCounter.
  ///
  /// In en, this message translates to:
  /// **'{count} of 5 selected'**
  String tripFormInterestsCounter(int count);

  /// No description provided for @tripFormInterestsEmptyHelper.
  ///
  /// In en, this message translates to:
  /// **'Select none for general sightseeing'**
  String get tripFormInterestsEmptyHelper;

  /// No description provided for @interestMonumentsHistory.
  ///
  /// In en, this message translates to:
  /// **'Monuments and history'**
  String get interestMonumentsHistory;

  /// No description provided for @interestArchitecture.
  ///
  /// In en, this message translates to:
  /// **'Architecture'**
  String get interestArchitecture;

  /// No description provided for @interestArtMuseums.
  ///
  /// In en, this message translates to:
  /// **'Art and museums'**
  String get interestArtMuseums;

  /// No description provided for @interestNatureParks.
  ///
  /// In en, this message translates to:
  /// **'Nature and parks'**
  String get interestNatureParks;

  /// No description provided for @interestBeachesWater.
  ///
  /// In en, this message translates to:
  /// **'Beaches and water'**
  String get interestBeachesWater;

  /// No description provided for @interestLocalFood.
  ///
  /// In en, this message translates to:
  /// **'Local food'**
  String get interestLocalFood;

  /// No description provided for @interestActiveSport.
  ///
  /// In en, this message translates to:
  /// **'Active and sport'**
  String get interestActiveSport;

  /// No description provided for @interestFamilyAttractions.
  ///
  /// In en, this message translates to:
  /// **'Family attractions'**
  String get interestFamilyAttractions;

  /// No description provided for @interestShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get interestShopping;

  /// No description provided for @interestNightlife.
  ///
  /// In en, this message translates to:
  /// **'Nightlife'**
  String get interestNightlife;

  /// No description provided for @interestRelaxation.
  ///
  /// In en, this message translates to:
  /// **'Relaxation'**
  String get interestRelaxation;

  /// No description provided for @tripFormBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get tripFormBudget;

  /// No description provided for @budgetLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get budgetLow;

  /// No description provided for @budgetMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get budgetMedium;

  /// No description provided for @budgetHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get budgetHigh;

  /// No description provided for @tripFormPace.
  ///
  /// In en, this message translates to:
  /// **'Pace'**
  String get tripFormPace;

  /// No description provided for @paceRelaxed.
  ///
  /// In en, this message translates to:
  /// **'Relaxed'**
  String get paceRelaxed;

  /// No description provided for @paceModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get paceModerate;

  /// No description provided for @paceIntense.
  ///
  /// In en, this message translates to:
  /// **'Intense'**
  String get paceIntense;

  /// No description provided for @paceRelaxedHelper.
  ///
  /// In en, this message translates to:
  /// **'2–3 places a day'**
  String get paceRelaxedHelper;

  /// No description provided for @paceModerateHelper.
  ///
  /// In en, this message translates to:
  /// **'4–5 places a day'**
  String get paceModerateHelper;

  /// No description provided for @paceIntenseHelper.
  ///
  /// In en, this message translates to:
  /// **'6–7 places a day'**
  String get paceIntenseHelper;

  /// No description provided for @tripFormPartySize.
  ///
  /// In en, this message translates to:
  /// **'Travellers'**
  String get tripFormPartySize;

  /// No description provided for @tripFormPlanLanguage.
  ///
  /// In en, this message translates to:
  /// **'Plan language'**
  String get tripFormPlanLanguage;

  /// No description provided for @languageNamePl.
  ///
  /// In en, this message translates to:
  /// **'Polski'**
  String get languageNamePl;

  /// No description provided for @languageNameEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageNameEn;

  /// No description provided for @tripFormGenerate.
  ///
  /// In en, this message translates to:
  /// **'Create plan'**
  String get tripFormGenerate;

  /// No description provided for @tripFormOfflineNotice.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Plans can only be created online – your details stay in the form.'**
  String get tripFormOfflineNotice;

  /// No description provided for @tripFormConsentWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Your consent to share data with AI is withdrawn, so we can\'t create a plan.'**
  String get tripFormConsentWithdrawn;

  /// No description provided for @tripFormGiveConsent.
  ///
  /// In en, this message translates to:
  /// **'Give consent'**
  String get tripFormGiveConsent;

  /// No description provided for @tripFormErrorsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 field needs fixing} other{{count} fields need fixing}}'**
  String tripFormErrorsCount(int count);

  /// No description provided for @tripFormDecrease.
  ///
  /// In en, this message translates to:
  /// **'Fewer'**
  String get tripFormDecrease;

  /// No description provided for @tripFormIncrease.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get tripFormIncrease;

  /// No description provided for @generationCancelledSnack.
  ///
  /// In en, this message translates to:
  /// **'Plan creation stopped. Nothing was saved.'**
  String get generationCancelledSnack;

  /// No description provided for @commonFieldRequiredError.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get commonFieldRequiredError;

  /// No description provided for @commonFieldTooLongError.
  ///
  /// In en, this message translates to:
  /// **'Maximum {max} characters'**
  String commonFieldTooLongError(int max);

  /// No description provided for @commonFieldCharsError.
  ///
  /// In en, this message translates to:
  /// **'Allowed: letters, digits, space and , . - \' ( ) / &'**
  String get commonFieldCharsError;

  /// No description provided for @commonDateRangeError.
  ///
  /// In en, this message translates to:
  /// **'Date must be between {from} and {to}'**
  String commonDateRangeError(String from, String to);

  /// No description provided for @commonDaysCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 day} other{{count} days}}'**
  String commonDaysCount(int count);

  /// No description provided for @generationTitle.
  ///
  /// In en, this message translates to:
  /// **'Building your plan…'**
  String get generationTitle;

  /// No description provided for @generationFor.
  ///
  /// In en, this message translates to:
  /// **'{destination} · {days}'**
  String generationFor(String destination, String days);

  /// No description provided for @generationMayTakeTime.
  ///
  /// In en, this message translates to:
  /// **'This may take up to 2 minutes.'**
  String get generationMayTakeTime;

  /// No description provided for @generationStep1.
  ///
  /// In en, this message translates to:
  /// **'Checking your preferences…'**
  String get generationStep1;

  /// No description provided for @generationStep2.
  ///
  /// In en, this message translates to:
  /// **'Arranging the days…'**
  String get generationStep2;

  /// No description provided for @generationStep3.
  ///
  /// In en, this message translates to:
  /// **'Almost there…'**
  String get generationStep3;

  /// No description provided for @generationCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get generationCancel;

  /// No description provided for @generationCancelTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop creating the plan?'**
  String get generationCancelTitle;

  /// No description provided for @generationCancelBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing will be saved. If the plan is already being created, this attempt may count towards today\'s limit.'**
  String get generationCancelBody;

  /// No description provided for @generationCancelConfirm.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get generationCancelConfirm;

  /// No description provided for @generationCancelContinue.
  ///
  /// In en, this message translates to:
  /// **'Keep waiting'**
  String get generationCancelContinue;

  /// No description provided for @planAiNotice.
  ///
  /// In en, this message translates to:
  /// **'This plan was created by AI and may contain mistakes. Check opening hours before you go.'**
  String get planAiNotice;

  /// No description provided for @planLodging.
  ///
  /// In en, this message translates to:
  /// **'Stay: {lodging}'**
  String planLodging(String lodging);

  /// No description provided for @planArrivalFlight.
  ///
  /// In en, this message translates to:
  /// **'Arrival {date}, {time} · {airport}'**
  String planArrivalFlight(String date, String time, String airport);

  /// No description provided for @planArrivalCar.
  ///
  /// In en, this message translates to:
  /// **'Arrival {date}, {time}'**
  String planArrivalCar(String date, String time);

  /// No description provided for @planFlightNumber.
  ///
  /// In en, this message translates to:
  /// **'Flight {number}'**
  String planFlightNumber(String number);

  /// No description provided for @planDayTab.
  ///
  /// In en, this message translates to:
  /// **'Day {number}'**
  String planDayTab(int number);

  /// No description provided for @planItemTime.
  ///
  /// In en, this message translates to:
  /// **'approx. {time}'**
  String planItemTime(String time);

  /// No description provided for @planRoute.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get planRoute;

  /// No description provided for @planDayOnlyArrival.
  ///
  /// In en, this message translates to:
  /// **'Today: just getting to your accommodation.'**
  String get planDayOnlyArrival;

  /// No description provided for @planDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete trip'**
  String get planDelete;

  /// No description provided for @planSavedSnack.
  ///
  /// In en, this message translates to:
  /// **'Plan saved. You can create {remaining} more of {limit} today.'**
  String planSavedSnack(int remaining, int limit);

  /// No description provided for @planLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open this trip'**
  String get planLoadErrorTitle;

  /// No description provided for @planLoadErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Go back to the list and try again.'**
  String get planLoadErrorBody;

  /// No description provided for @planBackToList.
  ///
  /// In en, this message translates to:
  /// **'Back to list'**
  String get planBackToList;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @planListTitle.
  ///
  /// In en, this message translates to:
  /// **'Your trips'**
  String get planListTitle;

  /// No description provided for @planListEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No trips yet'**
  String get planListEmptyTitle;

  /// No description provided for @planListEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Enter your destination, stay and dates – AI will plan it day by day.'**
  String get planListEmptyBody;

  /// No description provided for @planListNewTrip.
  ///
  /// In en, this message translates to:
  /// **'New trip'**
  String get planListNewTrip;

  /// No description provided for @planListDeviceOnlyNotice.
  ///
  /// In en, this message translates to:
  /// **'Plans are stored only on this device. They won\'t be available after uninstalling the app or changing your phone.'**
  String get planListDeviceOnlyNotice;

  /// No description provided for @planListDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String planListDays(int count);

  /// No description provided for @planListArrivalFlight.
  ///
  /// In en, this message translates to:
  /// **'flight'**
  String get planListArrivalFlight;

  /// No description provided for @planListArrivalCar.
  ///
  /// In en, this message translates to:
  /// **'car'**
  String get planListArrivalCar;

  /// No description provided for @planListCreatedOn.
  ///
  /// In en, this message translates to:
  /// **'Created {date}'**
  String planListCreatedOn(String date);

  /// No description provided for @planListLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your trips'**
  String get planListLoadErrorTitle;

  /// No description provided for @planListLoadErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Please try again. If the problem continues, restart the app.'**
  String get planListLoadErrorBody;

  /// No description provided for @planDeletedSnack.
  ///
  /// In en, this message translates to:
  /// **'Trip “{destination}” deleted'**
  String planDeletedSnack(String destination);

  /// No description provided for @planDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this trip?'**
  String get planDeleteTitle;

  /// No description provided for @planDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'“{destination}” will be permanently deleted from this device. This can\'t be undone.'**
  String planDeleteBody(String destination);

  /// No description provided for @planDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get planDeleteConfirm;

  /// No description provided for @planDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete the trip. Nothing was changed.'**
  String get planDeleteError;

  /// No description provided for @planRouteTo.
  ///
  /// In en, this message translates to:
  /// **'Directions to {place}'**
  String planRouteTo(String place);

  /// No description provided for @commonCloseSheet.
  ///
  /// In en, this message translates to:
  /// **'Close sheet'**
  String get commonCloseSheet;

  /// No description provided for @routeTitle.
  ///
  /// In en, this message translates to:
  /// **'Directions to: {place}'**
  String routeTitle(String place);

  /// No description provided for @routeFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get routeFrom;

  /// No description provided for @routeFromMyLocation.
  ///
  /// In en, this message translates to:
  /// **'My location'**
  String get routeFromMyLocation;

  /// No description provided for @routeFromMyLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Google Maps will find where you are. It may ask for access to your location.'**
  String get routeFromMyLocationHint;

  /// No description provided for @routeFromPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous place'**
  String get routeFromPrevious;

  /// No description provided for @routeFromLodging.
  ///
  /// In en, this message translates to:
  /// **'Your stay'**
  String get routeFromLodging;

  /// No description provided for @routeFromLodgingHint.
  ///
  /// In en, this message translates to:
  /// **'{lodging} · approximate point'**
  String routeFromLodgingHint(String lodging);

  /// No description provided for @routeMode.
  ///
  /// In en, this message translates to:
  /// **'How'**
  String get routeMode;

  /// No description provided for @routeModeDriving.
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get routeModeDriving;

  /// No description provided for @routeModeTransit.
  ///
  /// In en, this message translates to:
  /// **'Transit'**
  String get routeModeTransit;

  /// No description provided for @routeModeWalking.
  ///
  /// In en, this message translates to:
  /// **'Walk'**
  String get routeModeWalking;

  /// No description provided for @routeOpenMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Google Maps'**
  String get routeOpenMaps;

  /// No description provided for @routeOpensOtherApp.
  ///
  /// In en, this message translates to:
  /// **'opens another app'**
  String get routeOpensOtherApp;

  /// No description provided for @routeOpenError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open maps. Please try again.'**
  String get routeOpenError;

  /// No description provided for @planNotSavedTitle.
  ///
  /// In en, this message translates to:
  /// **'This trip isn\'t saved'**
  String get planNotSavedTitle;

  /// No description provided for @planNotSavedBody.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t save this trip on your phone. If you leave this screen or close the app, the trip will be lost.'**
  String get planNotSavedBody;

  /// No description provided for @planNotSavedStorageBody.
  ///
  /// In en, this message translates to:
  /// **'Your phone is out of storage, so the trip wasn\'t saved. Free up some space and try again. If you leave this screen or close the app, the trip will be lost.'**
  String get planNotSavedStorageBody;

  /// No description provided for @planSaveRetry.
  ///
  /// In en, this message translates to:
  /// **'Try saving again'**
  String get planSaveRetry;

  /// No description provided for @planSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get planSaving;

  /// No description provided for @planSaveFailedAgainSnack.
  ///
  /// In en, this message translates to:
  /// **'The trip still couldn\'t be saved.'**
  String get planSaveFailedAgainSnack;

  /// No description provided for @planLeaveUnsavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave without saving?'**
  String get planLeaveUnsavedTitle;

  /// No description provided for @planLeaveUnsavedBody.
  ///
  /// In en, this message translates to:
  /// **'The trip will be lost and can\'t be recovered. This generation already counts towards today\'s limit.'**
  String get planLeaveUnsavedBody;

  /// No description provided for @planLeaveUnsavedConfirm.
  ///
  /// In en, this message translates to:
  /// **'Leave without saving'**
  String get planLeaveUnsavedConfirm;
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
