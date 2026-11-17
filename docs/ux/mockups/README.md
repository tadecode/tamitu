# Makiety ekranów Tamitu

Dokumentacja do akceptacji – **nie kod aplikacji**. Wariant marki A „Lazur".

- `ek-01.html` … `ek-16.html` – makieta każdego ekranu (specyfikacje w `../screens/`). Style i skrypt są wklejone do plików;
  EK-02 używa lokalnej ilustracji `../assets/ek-02-travel-hero.svg`. Makiety otwierają się bezpośrednio w przeglądarce,
  bez sieci i zewnętrznych zasobów.
- Przełączniki na górze strony: **Język UI** PL/EN, **Motyw** jasny/ciemny, **Tekst** 100/150/200% (symulacja skali czcionki systemu).
  Stan startowy można ustawić w adresie: `#en`, `#dark`, `#s200` (np. `ek-06.html#en-dark`).
- Każdy telefon to jeden stan ekranu (podpis pod nim). Żółte etykiety to adnotacje makiety, nie część interfejsu.
- `brand-preview.html` – porównanie wariantów marki z kroku 1 (archiwum decyzji UX1; ikony Material Icons z tamtego etapu, Apache 2.0).

## Źródła wspólne
`_kit.css` (tokeny z `design-system.md` i style komponentów CMP-01..20) oraz `_kit.js` (przełączniki, ikony, teksty PL/EN)
to **źródło**. Po ich zmianie trzeba wkleić je ponownie do makiet (między znaczniki `<style data-kit>` i `<script data-kit>`):

```bash
cd docs/ux/mockups && node -e '
const fs=require("fs");const css=fs.readFileSync("_kit.css","utf8"),js=fs.readFileSync("_kit.js","utf8");
for(const f of fs.readdirSync(".").filter(f=>/^ek-\d\d\.html$/.test(f))){let s=fs.readFileSync(f,"utf8");
s=s.replace(/<style data-kit>[\s\S]*?<\/style>/,()=>"<style data-kit>\n"+css+"</style>")
 .replace(/<script data-kit>[\s\S]*?<\/script>/,()=>"<script data-kit>\n"+js+"</script>");fs.writeFileSync(f,s);}'
```

## Konwencje w plikach
- `<t-x pl="…" en="…"></t-x>` – tekst interfejsu (przełączany); `<span class="l" lang="pl|en">` – tekst z formatowaniem.
- Treść planu (język planu) ma atrybut `lang` bez klasy `l` – **nie** zmienia się z językiem UI (pokazuje rozdzielenie języków).
- `<i-c n="nazwa">` – ikona: **własne, uproszczone odpowiedniki** w stylu Hugeicons Free Stroke Rounded (decyzja UX14), narysowane do makiet – nie są plikami Hugeicons (licencja do potwierdzenia, UX15). Nazwy Hugeicons przy każdej ikonie w `_kit.js` i w `design-system.md` pkt 8.
- Dane w makietach są wymyślone.
