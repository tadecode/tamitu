# Polityka narzędzi recenzji

Zasada: **narzędzia deterministyczne dają twarde fakty, recenzent-agent dodaje rozumienie
kontekstu.** Jedno nie zastępuje drugiego. Agent nie „uczy się sam" między uruchomieniami -
wiedza zdobyta w przeglądach trafia do plików (checklisty), po zatwierdzeniu przez właściciela.

## Poziom 0 - w CI od początku (darmowe)
| Narzędzie | Po co |
|---|---|
| `flutter analyze` (z `flutter_lints` lub ostrzejszym zestawem) | błędy i złe praktyki Dart |
| `dart format --output=none --set-exit-if-changed .` | spójny styl |
| `flutter test` w CI | regresje |
| `gitleaks` | sekrety w historii |
| Dependabot | aktualizacje zależności |

## Poziom 1 - zalecane dodać (darmowe, lokalne dla recenzenta)
| Narzędzie | Po co |
|---|---|
| `osv-scanner` | znane podatności w zależnościach (pub, gradle) |
| `dart pub outdated`, `dart pub deps` | przestarzałe i tranzytywne zależności |

Recenzent używa ich tylko jeśli są zainstalowane (lista dozwolonych poleceń w
`.farm/hooks/guard-bash-allow.ps1`); jeśli narzędzia brakuje - odnotowuje to w raporcie.

## Poziom 2 - opcjonalne, decyzja właściciela
| Narzędzie | Kiedy rozważyć |
|---|---|
| SonarQube / SonarQube Cloud | o ile wiem, brak oficjalnego wsparcia dla Dart/Flutter (tylko nieoficjalne wtyczki); sensowne, gdy pojawi się dużo kodu natywnego Kotlin/Java albo potrzeba bramki jakości i metryk długu technicznego. Wysyła kod do zewnętrznej usługi (RODO/poufność) lub wymaga własnego serwera (koszt). |
| DCM (Dart Code Metrics) | płatne; metryki złożoności i dodatkowe reguły dla Dart |
| Skanery SAST/mobile (np. MobSF) | przed pierwszym wydaniem publicznym |

Włączenie narzędzia poziomu 2 wymaga: decyzji właściciela, wpisu w ADR (koszt, dane
wysyłane na zewnątrz), dodania polecenia do listy dozwolonych (zmiana w trybie
`FARM_MAINTENANCE=1`) i kroku w CI.

## Uczenie się recenzenta (kontrolowane)
1. Recenzent zauważa powtarzający się problem (≥3 razy) i dopisuje propozycję
   do `docs/reviews/lessons-proposed.md` z przykładami.
2. Właściciel (w trybie maintenance) przenosi zatwierdzone wnioski do checklist w `.farm/review/`.
3. Zmianę sprawdza zadanie próbne recenzenta (`.farm/evals/trial-tasks.md`).
