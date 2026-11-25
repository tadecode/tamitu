// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'Tamitu';

  @override
  String get homeTitle => 'Planer podróży';

  @override
  String get homeSubtitle => 'Zaplanuj podróż z pomocą AI.';

  @override
  String get commonLoading => 'Trwa…';

  @override
  String get commonLoadingLabel => 'Wczytywanie';

  @override
  String get commonRetry => 'Spróbuj ponownie';

  @override
  String get commonOfflineNotice =>
      'Brak połączenia z internetem. Ta funkcja wymaga sieci.';

  @override
  String get commonOpensInBrowser => 'otwiera przeglądarkę';

  @override
  String get languageSwitchLabel => 'Język aplikacji';

  @override
  String get welcomeTagline =>
      'Plan podróży dzień po dniu – tam i tu, w jednym miejscu.';

  @override
  String get welcomePrivacyTitle => 'Twoja prywatność';

  @override
  String get welcomePrivacyBody =>
      'Plany zapisujemy tylko na tym telefonie. Aby ułożyć plan, wyślemy dane podróży do usługi AI – zapytamy Cię o zgodę przed pierwszym planem.';

  @override
  String get welcomeAdultsOnly => 'Tamitu jest dla osób pełnoletnich.';

  @override
  String consentPolicyCheckbox(String policyLink) {
    return 'Potwierdzam zapoznanie się z $policyLink i akceptuję ją';
  }

  @override
  String get consentPolicyLink => 'polityką prywatności';

  @override
  String get welcomeSignIn => 'Zaloguj przez Google';

  @override
  String get welcomeSignInHint =>
      'Zaznacz akceptację polityki, aby się zalogować.';

  @override
  String get welcomeSigningIn => 'Logowanie…';

  @override
  String get welcomeSignInCancelled => 'Logowanie anulowane.';

  @override
  String get welcomeSignInError => 'Nie udało się zalogować. Spróbuj ponownie.';

  @override
  String get startAccountDeleted =>
      'Konto i dane na tym urządzeniu zostały usunięte.';

  @override
  String get reconsentTitle => 'Nowa polityka prywatności';

  @override
  String get reconsentBody =>
      'Zaktualizowaliśmy politykę prywatności. Aby dalej korzystać z Tamitu, zapoznaj się z nią i zaakceptuj. Twoje plany pozostają na tym urządzeniu.';

  @override
  String get reconsentLink => 'Przeczytaj politykę prywatności';

  @override
  String get reconsentBodyDataReset =>
      'Dane na tym urządzeniu zostały wyczyszczone, więc potrzebujemy ponownie Twojej akceptacji polityki prywatności. Zapoznaj się z nią i zaakceptuj, aby korzystać z Tamitu.';

  @override
  String reconsentBodyDated(String date) {
    return 'Zaktualizowaliśmy politykę prywatności ($date). Aby dalej korzystać z Tamitu, zapoznaj się z nią i zaakceptuj. Twoje plany pozostają na tym urządzeniu.';
  }

  @override
  String get reconsentAccept => 'Akceptuję i przechodzę dalej';

  @override
  String get reconsentSaveError =>
      'Nie udało się zapisać akceptacji. Spróbuj ponownie.';

  @override
  String get reconsentOffline =>
      'Aby zaakceptować politykę, połącz się z internetem.';

  @override
  String get reconsentSignOut => 'Wyloguj';

  @override
  String get reconsentDeleteAccount => 'Usuń konto';

  @override
  String get aiConsentTitle => 'Zgoda na użycie AI';

  @override
  String get aiConsentIntro =>
      'Plan układa model sztucznej inteligencji. Aby to zrobić, musimy wysłać do niego dane Twojej podróży.';

  @override
  String get aiConsentSendTitle => 'Co wysyłamy';

  @override
  String get aiConsentSendList =>
      'Cel podróży, nazwę obiektu lub dzielnicę noclegu, liczbę dni, datę, godzinę i sposób dojazdu, lotnisko; preferencje (zainteresowania, budżet, tempo, liczbę osób) i język planu.';

  @override
  String get aiConsentNotSendTitle => 'Czego nie wysyłamy';

  @override
  String get aiConsentNotSendList =>
      'Twojego e-maila, imienia i nazwiska, identyfikatora konta, lokalizacji ani numeru lotu.';

  @override
  String get aiConsentRecipientTitle => 'Kto otrzymuje dane';

  @override
  String get aiConsentRecipient =>
      'Usługa AI Google Cloud (Vertex AI) w regionie UE. Nasz serwer pośredniczący przetwarza dane tylko w pamięci – nie zapisujemy ich ani nie logujemy.';

  @override
  String get aiConsentErrors =>
      'Plan może zawierać błędy – sprawdzaj godziny otwarcia i dostępność miejsc.';

  @override
  String get aiConsentSensitive =>
      'Nie wpisuj w formularzu pełnego adresu prywatnego, danych wrażliwych ani danych innych osób.';

  @override
  String get aiConsentWithdraw =>
      'Zgodę możesz w każdej chwili wycofać w Ustawieniach → Prywatność. Tworzenie nowych planów zablokujemy od razu, a wycofanie zapiszemy na naszym serwerze, gdy tylko będzie połączenie. Zapisane plany pozostaną.';

  @override
  String get aiConsentController =>
      'Administratorem Twoich danych jest TadeCode (kontakt: tamitu@tadecode.pl).';

  @override
  String get aiConsentUpdatedIntro =>
      'Zmieniliśmy treść zgody na użycie AI. Przeczytaj ją i zdecyduj ponownie – do tego czasu nie ułożymy nowych planów.';

  @override
  String aiConsentPolicy(String policyLink) {
    return 'Szczegóły w $policyLink.';
  }

  @override
  String get aiConsentPolicyLink => 'polityce prywatności';

  @override
  String get aiConsentAgree => 'Zgadzam się';

  @override
  String get aiConsentDisagree => 'Nie zgadzam się';

  @override
  String get aiConsentSaveError =>
      'Nie udało się zapisać zgody. Nic nie wysłaliśmy. Spróbuj ponownie.';

  @override
  String get aiConsentOffline => 'Aby wyrazić zgodę, połącz się z internetem.';

  @override
  String get aiConsentGivenSnack => 'Zgoda na AI wyrażona';

  @override
  String get errorGenericTitle => 'Coś poszło nie tak';

  @override
  String get errorGenericBody =>
      'Spróbuj ponownie za chwilę. Twoje plany na tym urządzeniu nie zostały zmienione.';

  @override
  String get errorOfflineTitle => 'Brak połączenia';

  @override
  String get errorOfflineBody =>
      'Sprawdź połączenie z internetem i spróbuj ponownie.';

  @override
  String get errorGenerateTitle => 'Nie udało się ułożyć planu';

  @override
  String get errorAiUnavailableBody =>
      'Usługa AI jest chwilowo niedostępna. Ta próba nie wlicza się do dzisiejszego limitu. Spróbuj ponownie za chwilę.';

  @override
  String get errorAiUnavailableCountedBody =>
      'Usługa AI jest chwilowo niedostępna. Ta próba została wliczona do dzisiejszego limitu, bo nieudane próby zwracamy najwyżej 2 razy dziennie. Spróbuj ponownie później.';

  @override
  String get errorAiUnavailableMaybeBody =>
      'Usługa AI jest chwilowo niedostępna. Ta próba mogła zostać wliczona do dzisiejszego limitu. Spróbuj ponownie za chwilę.';

  @override
  String get errorAiInvalidBody =>
      'AI zwróciło niepełny plan, więc go nie zapisaliśmy. Ta próba nie wlicza się do dzisiejszego limitu. Spróbuj ponownie.';

  @override
  String get errorAiInvalidCountedBody =>
      'AI zwróciło niepełny plan, więc go nie zapisaliśmy. Ta próba została wliczona do dzisiejszego limitu, bo nieudane próby zwracamy najwyżej 2 razy dziennie.';

  @override
  String get errorAiInvalidMaybeBody =>
      'AI zwróciło niepełny plan, więc go nie zapisaliśmy. Ta próba mogła zostać wliczona do dzisiejszego limitu. Spróbuj ponownie.';

  @override
  String get errorTimeoutBody =>
      'Tworzenie planu trwało zbyt długo. Ta próba mogła zostać wliczona do dzisiejszego limitu. Spróbuj ponownie.';

  @override
  String get errorLimitTitle => 'Dzisiejszy limit planów wykorzystany';

  @override
  String errorLimitBody(int limit, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: '$limit planu',
      many: '$limit planów',
      few: '$limit plany',
      one: '1 plan',
    );
    return 'Możesz utworzyć $_temp0 dziennie. Kolejne od jutra, od $time. Zapisane plany są nadal dostępne.';
  }

  @override
  String get errorUpdateTitle => 'Zaktualizuj aplikację';

  @override
  String get errorUpdateBody =>
      'Ta wersja Tamitu nie jest już obsługiwana. Zaktualizuj aplikację w Google Play, aby tworzyć plany. Zapisane plany są dostępne.';

  @override
  String get errorUpdateAction => 'Zaktualizuj aplikację';

  @override
  String get errorUnavailableForAccountBody =>
      'Tworzenie planów jest chwilowo niedostępne. Spróbuj później.';

  @override
  String get errorSessionExpired =>
      'Sesja wygasła. Zaloguj się ponownie – plany są na urządzeniu.';

  @override
  String get errorInvalidFormBody =>
      'Sprawdź dane w formularzu i spróbuj ponownie.';

  @override
  String get generationBusyTitle =>
      'Nasz asystent AI jest chwilowo przeciążony';

  @override
  String get generationBusyStillTitle =>
      'Nasz asystent AI nadal jest przeciążony';

  @override
  String generationBusyBodyAuto(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minuty',
      many: '$minutes minut',
      few: '$minutes minuty',
      one: 'minutę',
    );
    return 'Spróbujemy ponownie za $_temp0. Nie musisz nic robić.';
  }

  @override
  String get generationBusyBodyManual =>
      'Spróbuj ponownie za chwilę. Twoje dane w formularzu zostały zachowane.';

  @override
  String get generationBusyBodyPaused =>
      'Gdy aplikacja była w tle, nie ponawialiśmy próby. Możesz spróbować teraz.';

  @override
  String get generationBusyQuotaReleased =>
      'Ta próba nie wlicza się do limitu.';

  @override
  String get generationBusyQuotaCounted =>
      'Ta próba została wliczona do dzisiejszego limitu.';

  @override
  String get generationBusyQuotaUnknown =>
      'Ta próba mogła zostać wliczona do dzisiejszego limitu.';

  @override
  String generationBusyCountdown(String time) {
    return 'Ponowna próba za $time';
  }

  @override
  String generationBusyCountdownA11y(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds sekundy',
      many: '$seconds sekund',
      few: '$seconds sekundy',
      one: '1 sekundę',
    );
    return 'Ponowna próba za $_temp0';
  }

  @override
  String get generationBusyTryNow => 'Spróbuj teraz';

  @override
  String get generationBusyBack => 'Wróć do formularza';

  @override
  String get generationRetrying => 'Próbujemy ponownie…';

  @override
  String get tripFormTitle => 'Nowa podróż';

  @override
  String get tripFormSectionWhere => 'Dokąd';

  @override
  String get tripFormSectionWhen => 'Kiedy i jak';

  @override
  String get tripFormSectionPrefs => 'Preferencje (opcjonalnie)';

  @override
  String get tripFormDestination => 'Cel podróży';

  @override
  String get tripFormDestinationHelper => 'Miasto lub region, np. Lizbona';

  @override
  String get tripFormLodging => 'Nazwa obiektu lub dzielnica';

  @override
  String get tripFormLodgingHelper => 'Nie wpisuj pełnego adresu prywatnego.';

  @override
  String get tripFormDays => 'Liczba dni';

  @override
  String get tripFormDaysError => 'Wybierz liczbę dni (1–14)';

  @override
  String get tripFormArrivalMode => 'Sposób dojazdu';

  @override
  String get tripFormArrivalFlight => 'Lot';

  @override
  String get tripFormArrivalCar => 'Auto';

  @override
  String get tripFormArrivalModeError => 'Wybierz sposób dojazdu';

  @override
  String get tripFormDateFlight => 'Data przylotu';

  @override
  String get tripFormDateCar => 'Data przyjazdu';

  @override
  String get tripFormTimeFlight => 'Godzina przylotu';

  @override
  String get tripFormTimeCar => 'Godzina przyjazdu';

  @override
  String get commonLocalTimeHelper => 'Czas lokalny w miejscu docelowym';

  @override
  String get tripFormAirport => 'Lotnisko';

  @override
  String get tripFormAirportHelper => 'Nazwa lub kod, np. LIS';

  @override
  String get tripFormFlightNumber => 'Numer lotu (opcjonalnie)';

  @override
  String get tripFormFlightNumberHelper =>
      'Zostaje tylko na telefonie – nie wysyłamy go do AI.';

  @override
  String get tripFormInterests => 'Zainteresowania';

  @override
  String tripFormInterestsCounter(int count) {
    return 'Wybrano $count z 5';
  }

  @override
  String get tripFormInterestsEmptyHelper =>
      'Nie wybierzesz nic – zaplanujemy ogólne zwiedzanie';

  @override
  String get interestMonumentsHistory => 'Zabytki i historia';

  @override
  String get interestArchitecture => 'Architektura';

  @override
  String get interestArtMuseums => 'Sztuka i muzea';

  @override
  String get interestNatureParks => 'Przyroda i parki';

  @override
  String get interestBeachesWater => 'Plaże i woda';

  @override
  String get interestLocalFood => 'Lokalne jedzenie';

  @override
  String get interestActiveSport => 'Aktywny wypoczynek';

  @override
  String get interestFamilyAttractions => 'Atrakcje dla rodzin';

  @override
  String get interestShopping => 'Zakupy';

  @override
  String get interestNightlife => 'Życie nocne';

  @override
  String get interestRelaxation => 'Relaks';

  @override
  String get tripFormBudget => 'Budżet';

  @override
  String get budgetLow => 'Niski';

  @override
  String get budgetMedium => 'Średni';

  @override
  String get budgetHigh => 'Wysoki';

  @override
  String get tripFormPace => 'Tempo';

  @override
  String get paceRelaxed => 'Spokojne';

  @override
  String get paceModerate => 'Umiarkowane';

  @override
  String get paceIntense => 'Intensywne';

  @override
  String get paceRelaxedHelper => '2–3 miejsca dziennie';

  @override
  String get paceModerateHelper => '4–5 miejsc dziennie';

  @override
  String get paceIntenseHelper => '6–7 miejsc dziennie';

  @override
  String get tripFormPartySize => 'Liczba osób';

  @override
  String get tripFormPlanLanguage => 'Język planu';

  @override
  String get languageNamePl => 'Polski';

  @override
  String get languageNameEn => 'English';

  @override
  String get tripFormGenerate => 'Generuj plan';

  @override
  String get tripFormOfflineNotice =>
      'Brak połączenia z internetem. Plan można ułożyć tylko online – Twoje dane zostają w formularzu.';

  @override
  String get tripFormConsentWithdrawn =>
      'Zgoda na przekazanie danych do AI jest wycofana, więc nie możemy ułożyć planu.';

  @override
  String get tripFormGiveConsent => 'Wyraź zgodę';

  @override
  String tripFormErrorsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pola wymaga poprawy',
      many: '$count pól wymaga poprawy',
      few: '$count pola wymagają poprawy',
      one: '1 pole wymaga poprawy',
    );
    return '$_temp0';
  }

  @override
  String get tripFormDecrease => 'Mniej';

  @override
  String get tripFormIncrease => 'Więcej';

  @override
  String get generationCancelledSnack =>
      'Generowanie przerwane. Nic nie zapisano.';

  @override
  String get commonFieldRequiredError => 'To pole jest wymagane';

  @override
  String commonFieldTooLongError(int max) {
    return 'Maksymalnie $max znaków';
  }

  @override
  String get commonFieldCharsError =>
      'Dozwolone są litery, cyfry, spacja i znaki , . - \' ( ) / &';

  @override
  String commonDateRangeError(String from, String to) {
    return 'Data musi być między $from a $to';
  }

  @override
  String commonDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dnia',
      many: '$count dni',
      few: '$count dni',
      one: '1 dzień',
    );
    return '$_temp0';
  }

  @override
  String get generationTitle => 'Układamy plan…';

  @override
  String generationFor(String destination, String days) {
    return '$destination · $days';
  }

  @override
  String get generationMayTakeTime => 'To może potrwać do 2 minut.';

  @override
  String get generationStep1 => 'Sprawdzamy Twoje preferencje…';

  @override
  String get generationStep2 => 'Układamy kolejne dni…';

  @override
  String get generationStep3 => 'Jeszcze chwila…';

  @override
  String get generationCancel => 'Anuluj';

  @override
  String get generationCancelTitle => 'Przerwać tworzenie planu?';

  @override
  String get generationCancelBody =>
      'Nic nie zostanie zapisane. Jeśli plan już się tworzy, ta próba może zostać wliczona do dzisiejszego limitu.';

  @override
  String get generationCancelConfirm => 'Przerwij';

  @override
  String get generationCancelContinue => 'Czekaj dalej';

  @override
  String get planAiNotice =>
      'Plan stworzyła AI i może zawierać błędy. Sprawdź godziny otwarcia przed wyjściem.';

  @override
  String planLodging(String lodging) {
    return 'Nocleg: $lodging';
  }

  @override
  String planArrivalFlight(String date, String time, String airport) {
    return 'Przylot $date, $time · $airport';
  }

  @override
  String planArrivalCar(String date, String time) {
    return 'Przyjazd $date, $time';
  }

  @override
  String planFlightNumber(String number) {
    return 'Lot $number';
  }

  @override
  String planDayTab(int number) {
    return 'Dzień $number';
  }

  @override
  String planItemTime(String time) {
    return 'ok. $time';
  }

  @override
  String get planRoute => 'Trasa';

  @override
  String get planDayOnlyArrival => 'Dziś tylko dojazd do noclegu.';

  @override
  String get planDelete => 'Usuń plan';

  @override
  String planSavedSnack(int remaining, int limit) {
    return 'Plan zapisany. Dziś możesz utworzyć jeszcze $remaining z $limit.';
  }

  @override
  String get planLoadErrorTitle => 'Nie udało się otworzyć planu';

  @override
  String get planLoadErrorBody => 'Wróć do listy i spróbuj ponownie.';

  @override
  String get planBackToList => 'Wróć do listy';

  @override
  String get commonCancel => 'Anuluj';

  @override
  String get commonClose => 'Zamknij';

  @override
  String get planListTitle => 'Twoje podróże';

  @override
  String get planListEmptyTitle => 'Nie masz jeszcze planów';

  @override
  String get planListEmptyBody =>
      'Podaj cel, nocleg i termin – AI ułoży plan dzień po dniu.';

  @override
  String get planListNewTrip => 'Nowa podróż';

  @override
  String get planListDeviceOnlyNotice =>
      'Plany są zapisane tylko na tym urządzeniu. Po odinstalowaniu aplikacji lub zmianie telefonu nie będą dostępne.';

  @override
  String planListDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dni',
      one: '1 dzień',
    );
    return '$_temp0';
  }

  @override
  String get planListArrivalFlight => 'lot';

  @override
  String get planListArrivalCar => 'auto';

  @override
  String planListCreatedOn(String date) {
    return 'Utworzono $date';
  }

  @override
  String get planListLoadErrorTitle => 'Nie udało się wczytać planów';

  @override
  String get planListLoadErrorBody =>
      'Spróbuj ponownie. Jeśli problem się powtarza, uruchom aplikację jeszcze raz.';

  @override
  String planDeletedSnack(String destination) {
    return 'Plan „$destination” usunięty';
  }

  @override
  String get planDeleteTitle => 'Usunąć plan?';

  @override
  String planDeleteBody(String destination) {
    return 'Plan „$destination” zostanie trwale usunięty z tego urządzenia. Tego nie da się cofnąć.';
  }

  @override
  String get planDeleteConfirm => 'Usuń';

  @override
  String get planDeleteError =>
      'Nie udało się usunąć planu. Plan nie został zmieniony.';
}
