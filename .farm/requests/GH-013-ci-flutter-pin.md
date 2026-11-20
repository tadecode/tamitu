# GH-013: przypięcie wersji Fluttera w CI do wersji z pubspec.yaml

- Zgłasza (rola): właściciel (w czacie ze Stewardem) · Data: 2026-11-20 · Powiązane zadanie/PR: PR #122
- Typ: ci-change
- Status: approved  (ustawia Steward po merge PR)

## Potrzeba
Kontrola `flutter` jest czerwona na `main` od 2026-11-20: `flutter-action` z `channel: stable` pobrał 3.50.1,
a `pubspec.yaml` wymaga `flutter: 3.50.0` (`version solving failed`). Blokuje to każdy PR uruchamiający job.

## Szczegóły
`.github/workflows/ci.yml`, krok `subosito/flutter-action@v2`: dodano `flutter-version-file: pubspec.yaml`.
Wersja jest brana z `environment.flutter`, więc podniesienie Fluttera to jedna zmiana w `pubspec.yaml`.

## Wpływ
Koszty: brak. · Bezpieczeństwo: bez zmian; powtarzalny build (brak niespodziewanych aktualizacji SDK). · Ryzyko: niskie;
jeśli `flutter-version-file` nie zadziała, job zostanie czerwony (widoczne od razu w PR).

## Odpowiedź Stewarda
2026-11-20 Steward: zmiana na gałęzi `chore/ci-flutter-pin`, PR otworzy bot. Po merge'u sprawdzę zielony `flutter` na `main`.
