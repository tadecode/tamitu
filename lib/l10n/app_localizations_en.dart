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
      'The AI service is temporarily unavailable. This attempt doesn\'t count towards today\'s limit. Please try again shortly.';

  @override
  String get errorAiUnavailableCountedBody =>
      'The AI service is temporarily unavailable. This attempt counted towards today\'s limit, because we give back failed attempts at most twice a day. Please try again later.';

  @override
  String get errorAiUnavailableMaybeBody =>
      'The AI service is temporarily unavailable. This attempt may have counted towards today\'s limit. Please try again shortly.';

  @override
  String get errorAiInvalidBody =>
      'The AI returned an incomplete plan, so we didn\'t save it. This attempt doesn\'t count towards today\'s limit. Please try again.';

  @override
  String get errorAiInvalidCountedBody =>
      'The AI returned an incomplete plan, so we didn\'t save it. This attempt counted towards today\'s limit, because we give back failed attempts at most twice a day.';

  @override
  String get errorAiInvalidMaybeBody =>
      'The AI returned an incomplete plan, so we didn\'t save it. This attempt may have counted towards today\'s limit. Please try again.';

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

  @override
  String get generationBusyTitle => 'Our AI assistant is busy right now';

  @override
  String get generationBusyStillTitle => 'Our AI assistant is still busy';

  @override
  String generationBusyBodyAuto(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: 'a minute',
    );
    return 'We\'ll try again in $_temp0. You don\'t need to do anything.';
  }

  @override
  String get generationBusyBodyManual =>
      'Please try again in a moment. Your trip details are kept in the form.';

  @override
  String get generationBusyBodyPaused =>
      'We didn\'t retry while the app was in the background. You can try now.';

  @override
  String get generationBusyQuotaReleased =>
      'This attempt doesn\'t count towards your limit.';

  @override
  String get generationBusyQuotaCounted =>
      'This attempt counted towards today\'s limit.';

  @override
  String get generationBusyQuotaUnknown =>
      'This attempt may have counted towards today\'s limit.';

  @override
  String generationBusyCountdown(String time) {
    return 'Retrying in $time';
  }

  @override
  String generationBusyCountdownA11y(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds seconds',
      one: '1 second',
    );
    return 'Retrying in $_temp0';
  }

  @override
  String get generationBusyTryNow => 'Try now';

  @override
  String get generationBusyBack => 'Back to the form';

  @override
  String get generationRetrying => 'Trying again…';

  @override
  String get tripFormTitle => 'New trip';

  @override
  String get tripFormSectionWhere => 'Where';

  @override
  String get tripFormSectionWhen => 'When and how';

  @override
  String get tripFormSectionPrefs => 'Preferences (optional)';

  @override
  String get tripFormDestination => 'Destination';

  @override
  String get tripFormDestinationHelper => 'City or region, e.g. Lisbon';

  @override
  String get tripFormLodging => 'Accommodation name or area';

  @override
  String get tripFormLodgingHelper => 'Don\'t enter a full private address.';

  @override
  String get tripFormDays => 'Number of days';

  @override
  String get tripFormDaysError => 'Choose the number of days (1–14)';

  @override
  String get tripFormArrivalMode => 'How you get there';

  @override
  String get tripFormArrivalFlight => 'Flight';

  @override
  String get tripFormArrivalCar => 'Car';

  @override
  String get tripFormArrivalModeError => 'Choose how you get there';

  @override
  String get tripFormDateFlight => 'Arrival date';

  @override
  String get tripFormDateCar => 'Arrival date';

  @override
  String get tripFormTimeFlight => 'Landing time';

  @override
  String get tripFormTimeCar => 'Arrival time';

  @override
  String get commonLocalTimeHelper => 'Local time at your destination';

  @override
  String get tripFormAirport => 'Airport';

  @override
  String get tripFormAirportHelper => 'Name or code, e.g. LIS';

  @override
  String get tripFormFlightNumber => 'Flight number (optional)';

  @override
  String get tripFormFlightNumberHelper =>
      'Stays on your phone – we don\'t send it to AI.';

  @override
  String get tripFormInterests => 'Interests';

  @override
  String tripFormInterestsCounter(int count) {
    return '$count of 5 selected';
  }

  @override
  String get tripFormInterestsEmptyHelper =>
      'Select none for general sightseeing';

  @override
  String get interestMonumentsHistory => 'Monuments and history';

  @override
  String get interestArchitecture => 'Architecture';

  @override
  String get interestArtMuseums => 'Art and museums';

  @override
  String get interestNatureParks => 'Nature and parks';

  @override
  String get interestBeachesWater => 'Beaches and water';

  @override
  String get interestLocalFood => 'Local food';

  @override
  String get interestActiveSport => 'Active and sport';

  @override
  String get interestFamilyAttractions => 'Family attractions';

  @override
  String get interestShopping => 'Shopping';

  @override
  String get interestNightlife => 'Nightlife';

  @override
  String get interestRelaxation => 'Relaxation';

  @override
  String get tripFormBudget => 'Budget';

  @override
  String get budgetLow => 'Low';

  @override
  String get budgetMedium => 'Medium';

  @override
  String get budgetHigh => 'High';

  @override
  String get tripFormPace => 'Pace';

  @override
  String get paceRelaxed => 'Relaxed';

  @override
  String get paceModerate => 'Moderate';

  @override
  String get paceIntense => 'Intense';

  @override
  String get paceRelaxedHelper => '2–3 places a day';

  @override
  String get paceModerateHelper => '4–5 places a day';

  @override
  String get paceIntenseHelper => '6–7 places a day';

  @override
  String get tripFormPartySize => 'Travellers';

  @override
  String get tripFormPlanLanguage => 'Plan language';

  @override
  String get languageNamePl => 'Polski';

  @override
  String get languageNameEn => 'English';

  @override
  String get tripFormGenerate => 'Create plan';

  @override
  String get tripFormOfflineNotice =>
      'No internet connection. Plans can only be created online – your details stay in the form.';

  @override
  String get tripFormConsentWithdrawn =>
      'Your consent to share data with AI is withdrawn, so we can\'t create a plan.';

  @override
  String get tripFormGiveConsent => 'Give consent';

  @override
  String tripFormErrorsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fields need fixing',
      one: '1 field needs fixing',
    );
    return '$_temp0';
  }

  @override
  String get tripFormDecrease => 'Fewer';

  @override
  String get tripFormIncrease => 'More';

  @override
  String get generationCancelledSnack =>
      'Plan creation stopped. Nothing was saved.';

  @override
  String get commonFieldRequiredError => 'This field is required';

  @override
  String commonFieldTooLongError(int max) {
    return 'Maximum $max characters';
  }

  @override
  String get commonFieldCharsError =>
      'Allowed: letters, digits, space and , . - \' ( ) / &';

  @override
  String commonDateRangeError(String from, String to) {
    return 'Date must be between $from and $to';
  }

  @override
  String commonDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get generationTitle => 'Building your plan…';

  @override
  String generationFor(String destination, String days) {
    return '$destination · $days';
  }

  @override
  String get generationMayTakeTime => 'This may take up to 2 minutes.';

  @override
  String get generationStep1 => 'Checking your preferences…';

  @override
  String get generationStep2 => 'Arranging the days…';

  @override
  String get generationStep3 => 'Almost there…';

  @override
  String get generationCancel => 'Cancel';

  @override
  String get generationCancelTitle => 'Stop creating the plan?';

  @override
  String get generationCancelBody =>
      'Nothing will be saved. If the plan is already being created, this attempt may count towards today\'s limit.';

  @override
  String get generationCancelConfirm => 'Stop';

  @override
  String get generationCancelContinue => 'Keep waiting';

  @override
  String get planAiNotice =>
      'This plan was created by AI and may contain mistakes. Check opening hours before you go.';

  @override
  String planLodging(String lodging) {
    return 'Stay: $lodging';
  }

  @override
  String planArrivalFlight(String date, String time, String airport) {
    return 'Arrival $date, $time · $airport';
  }

  @override
  String planArrivalCar(String date, String time) {
    return 'Arrival $date, $time';
  }

  @override
  String planFlightNumber(String number) {
    return 'Flight $number';
  }

  @override
  String planDayTab(int number) {
    return 'Day $number';
  }

  @override
  String planItemTime(String time) {
    return 'approx. $time';
  }

  @override
  String get planRoute => 'Directions';

  @override
  String get planDayOnlyArrival => 'Today: just getting to your accommodation.';

  @override
  String get planDelete => 'Delete trip';

  @override
  String planSavedSnack(int remaining, int limit) {
    return 'Plan saved. You can create $remaining more of $limit today.';
  }

  @override
  String get planLoadErrorTitle => 'Couldn\'t open this trip';

  @override
  String get planLoadErrorBody => 'Go back to the list and try again.';

  @override
  String get planBackToList => 'Back to list';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonClose => 'Close';

  @override
  String get planListTitle => 'Your trips';

  @override
  String get planListEmptyTitle => 'No trips yet';

  @override
  String get planListEmptyBody =>
      'Enter your destination, stay and dates – AI will plan it day by day.';

  @override
  String get planListNewTrip => 'New trip';

  @override
  String get planListDeviceOnlyNotice =>
      'Plans are stored only on this device. They won\'t be available after uninstalling the app or changing your phone.';

  @override
  String planListDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get planListArrivalFlight => 'flight';

  @override
  String get planListArrivalCar => 'car';

  @override
  String planListCreatedOn(String date) {
    return 'Created $date';
  }

  @override
  String get planListLoadErrorTitle => 'Couldn\'t load your trips';

  @override
  String get planListLoadErrorBody =>
      'Please try again. If the problem continues, restart the app.';

  @override
  String planDeletedSnack(String destination) {
    return 'Trip “$destination” deleted';
  }

  @override
  String get planDeleteTitle => 'Delete this trip?';

  @override
  String planDeleteBody(String destination) {
    return '“$destination” will be permanently deleted from this device. This can\'t be undone.';
  }

  @override
  String get planDeleteConfirm => 'Delete';

  @override
  String get planDeleteError =>
      'Couldn\'t delete the trip. Nothing was changed.';

  @override
  String planRouteTo(String place) {
    return 'Directions to $place';
  }

  @override
  String get commonCloseSheet => 'Close sheet';

  @override
  String routeTitle(String place) {
    return 'Directions to: $place';
  }

  @override
  String get routeFrom => 'From';

  @override
  String get routeFromMyLocation => 'My location';

  @override
  String get routeFromMyLocationHint =>
      'Google Maps will find where you are. It may ask for access to your location.';

  @override
  String get routeFromPrevious => 'Previous place';

  @override
  String get routeFromLodging => 'Your stay';

  @override
  String routeFromLodgingHint(String lodging) {
    return '$lodging · approximate point';
  }

  @override
  String get routeMode => 'How';

  @override
  String get routeModeDriving => 'Car';

  @override
  String get routeModeTransit => 'Transit';

  @override
  String get routeModeWalking => 'Walk';

  @override
  String get routeOpenMaps => 'Open in Google Maps';

  @override
  String get routeOpensOtherApp => 'opens another app';

  @override
  String get routeOpenError => 'Couldn\'t open maps. Please try again.';

  @override
  String get planNotSavedTitle => 'This trip isn\'t saved';

  @override
  String get planNotSavedBody =>
      'We couldn\'t save this trip on your phone. If you leave this screen or close the app, the trip will be lost.';

  @override
  String get planNotSavedStorageBody =>
      'Your phone is out of storage, so the trip wasn\'t saved. Free up some space and try again. If you leave this screen or close the app, the trip will be lost.';

  @override
  String get planSaveRetry => 'Try saving again';

  @override
  String get planSaving => 'Saving…';

  @override
  String get planSaveFailedAgainSnack => 'The trip still couldn\'t be saved.';

  @override
  String get planLeaveUnsavedTitle => 'Leave without saving?';

  @override
  String get planLeaveUnsavedBody =>
      'The trip will be lost and can\'t be recovered. This generation already counts towards today\'s limit.';

  @override
  String get planLeaveUnsavedConfirm => 'Leave without saving';
}
