/* Tamitu – wspólny skrypt makiet (P3-14b krok 2). Dokumentacja, nie kod aplikacji.
   - przełączniki: język interfejsu PL/EN, motyw jasny/ciemny, skala tekstu 100/150/200%;
   - <t-x pl="…" en="…"></t-x> – tekst w języku interfejsu; pary <span class="l" lang="pl|en"> – tekst z formatowaniem;
   - treść planu (język planu) NIE jest przełączana: oznaczona atrybutem lang bez klasy „l".
   Brak zapisu stanu (bez localStorage), brak zasobów zewnętrznych. Stan startowy można ustawić w adresie: #en, #dark, #s200. */
(function () {
  // Ikony: WŁASNE, uproszczone odpowiedniki w stylu Hugeicons Free „Stroke Rounded" (kreska 1,5, zaokrąglone końce),
  // narysowane na potrzeby makiet – NIE są plikami Hugeicons (licencja do potwierdzenia, UX15). Nazwy w komentarzu = słownik design-system.md pkt 8.
  // Format: "ścieżka kreski|ścieżka wypełnienia (opcjonalnie, np. kropki)".
  var ICONS = {
    add: 'M12 5v14M5 12h14',                                                        // add-01
    back: 'M19 12H5M11 6l-6 6 6 6',                                                 // arrow-left-01
    check: 'M5 12.5l4.5 4.5L19 7',                                                  // tick-02
    info: 'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM12 11v5|M12 9a1 1 0 1 0 0-2 1 1 0 0 0 0 2z',   // information-circle
    error: 'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM12 7.5v5|M12 17a1 1 0 1 0 0-2 1 1 0 0 0 0 2z', // alert-circle
    warning: 'M10.3 4.2a2 2 0 0 1 3.4 0l7.6 13.1A2 2 0 0 1 19.6 20H4.4a2 2 0 0 1-1.7-2.7zM12 9v4|M12 17.5a1 1 0 1 0 0-2 1 1 0 0 0 0 2z', // alert-02
    settings: 'M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6zM12 6.5a5.5 5.5 0 1 0 0 11 5.5 5.5 0 0 0 0-11zM12 2.8v3.7M12 17.5v3.7M2.8 12h3.7M17.5 12h3.7M5.5 5.5l2.6 2.6M15.9 15.9l2.6 2.6M5.5 18.5l2.6-2.6M15.9 8.1l2.6-2.6', // settings-02
    directions: 'M6 20a2 2 0 1 0 0-4 2 2 0 0 0 0 4zM18 8a2 2 0 1 0 0-4 2 2 0 0 0 0 4zM8 18h7a3 3 0 0 0 0-6H9a3 3 0 0 1 0-6h7', // route-02
    ai: 'M11 3.5l1.8 4.7 4.7 1.8-4.7 1.8L11 16.5l-1.8-4.7L4.5 10l4.7-1.8zM18 15l.8 2.2 2.2.8-2.2.8L18 21l-.8-2.2L15 18l2.2-.8z', // sparkles
    flight: 'M3 20.5h18M5.2 8.2l1.6 4.6 12.3 3.4a1.6 1.6 0 0 0 .9-3.1l-5.4-1.5-3.3-6.9-1.9-.5 1.2 6.4-3.6-1-1-2.2z', // airplane-landing-01
    car: 'M4 16v-3.5L6 8a2 2 0 0 1 1.8-1.2h8.4A2 2 0 0 1 18 8l2 4.5V16a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1zM4.5 12.5h15M7.5 20.5a1.5 1.5 0 1 0 0-3 1.5 1.5 0 0 0 0 3zM16.5 20.5a1.5 1.5 0 1 0 0-3 1.5 1.5 0 0 0 0 3z', // car-01
    transit: 'M6 3.5h12a2 2 0 0 1 2 2V16a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V5.5a2 2 0 0 1 2-2zM4 11h16M7 18v2.5M17 18v2.5|M8 15.5a1 1 0 1 0 0-2 1 1 0 0 0 0 2zM16 15.5a1 1 0 1 0 0-2 1 1 0 0 0 0 2z', // bus-01
    walk: 'M13 6a1.5 1.5 0 1 0 0-3 1.5 1.5 0 0 0 0 3zM9.5 21l2.2-6.5 2.8 2.8V21M8 12.5l2.5-4 3.5 1.2 2 3.3M11.7 14.5l-1.2-6', // walking
    more: '|M12 6.5a1.5 1.5 0 1 0 0-3 1.5 1.5 0 0 0 0 3zM12 13.5a1.5 1.5 0 1 0 0-3 1.5 1.5 0 0 0 0 3zM12 20.5a1.5 1.5 0 1 0 0-3 1.5 1.5 0 0 0 0 3z', // more-vertical
    phone: 'M8 2.5h8a2 2 0 0 1 2 2v15a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2v-15a2 2 0 0 1 2-2zM11 18.5h2', // smart-phone-01
    delete: 'M4 6.5h16M9.5 6.5v-2h5v2M6.5 6.5l.8 12.6a2 2 0 0 0 2 1.9h5.4a2 2 0 0 0 2-1.9l.8-12.6M10 11v5M14 11v5', // delete-02
    hotel: 'M3 19V6M3 15.5h18V19M21 15.5v-3a3 3 0 0 0-3-3h-7v6M7 13a1.75 1.75 0 1 0 0-3.5A1.75 1.75 0 0 0 7 13z', // bed-double
    location: 'M12 19a7 7 0 1 0 0-14 7 7 0 0 0 0 14zM12 2v3M12 19v3M2 12h3M19 12h3|M12 14a2 2 0 1 0 0-4 2 2 0 0 0 0 4z', // gps-01
    place: 'M12 21s-7-6.2-7-11.5a7 7 0 0 1 14 0C19 14.8 12 21 12 21zM12 12a2.5 2.5 0 1 0 0-5 2.5 2.5 0 0 0 0 5z', // location-01
    wifioff: 'M3 3l18 18M8.5 16a5 5 0 0 1 6.5-.3M5 12.3a10 10 0 0 1 4.3-2.4M19 12.3a10 10 0 0 0-3.4-2.1M2 8.7a15 15 0 0 1 5-3M22 8.7a15 15 0 0 0-11.3-4.1|M12 20.5a1.25 1.25 0 1 0 0-2.5 1.25 1.25 0 0 0 0 2.5z', // wifi-off-01
    shield: 'M12 21.5s7.5-3 7.5-9.5V5.5L12 2.5 4.5 5.5V12c0 6.5 7.5 9.5 7.5 9.5zM9 12l2 2 4-4', // shield-01
    language: 'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM3 12h18M12 3c2.5 2.5 3.5 5.5 3.5 9s-1 6.5-3.5 9c-2.5-2.5-3.5-5.5-3.5-9s1-6.5 3.5-9z', // globe-02
    logout: 'M14 4.5H7a2 2 0 0 0-2 2v11a2 2 0 0 0 2 2h7M11 12h10M17.5 8.5L21 12l-3.5 3.5', // logout-01
    personremove: 'M10 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM3 20.5c0-3.6 3.1-6 7-6s7 2.4 7 6M16 9h6', // user-remove-01
    openinnew: 'M11 4.5H6.5a2 2 0 0 0-2 2v11a2 2 0 0 0 2 2h11a2 2 0 0 0 2-2V13M14.5 4H20v5.5M20 4l-9 9', // link-square-02
    schedule: 'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM12 7.5V12l3 2', // clock-01
    calendar: 'M6 4.5h12a2 2 0 0 1 2 2V19a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6.5a2 2 0 0 1 2-2zM4 9.5h16M8 2.5v4M16 2.5v4', // calendar-03
    dropdown: 'M6 9.5l6 6 6-6', // arrow-down-01
    luggage: 'M6.5 7h11a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2h-11a2 2 0 0 1-2-2V9a2 2 0 0 1 2-2zM9 7V5a1.5 1.5 0 0 1 1.5-1.5h3A1.5 1.5 0 0 1 15 5v2M9 11v5M15 11v5M8 20v1.5M16 20v1.5', // luggage-01
    update: 'M20 12a8 8 0 1 1-2.4-5.7M20 4v4.5h-4.5' // reload
  };
  // <i-c n="name" s="18"></i-c> → inline SVG
  function renderIcons(root) {
    root.querySelectorAll('i-c').forEach(function (el) {
      var n = el.getAttribute('n'), s = el.getAttribute('s');
      var cls = 'ic' + (s ? ' s' + s : '') + (el.className ? ' ' + el.className : '');
      var parts = (ICONS[n] || '').split('|');
      el.outerHTML = '<svg class="' + cls + '" viewBox="0 0 24 24" aria-hidden="true">' +
        (parts[0] ? '<path d="' + parts[0] + '" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>' : '') +
        (parts[1] ? '<path d="' + parts[1] + '" fill="currentColor"/>' : '') + '</svg>';
    });
  }
  function applyLang(lang) {
    document.body.dataset.lang = lang;
    document.querySelectorAll('t-x').forEach(function (el) { el.textContent = el.getAttribute(lang) || el.getAttribute('pl'); });
    document.documentElement.lang = lang;
  }
  function btns(group, items, current, onClick) {
    var d = document.createElement('div'); d.className = 'pg-ctl'; d.setAttribute('role', 'group'); d.setAttribute('aria-label', group);
    d.innerHTML = '<span>' + group + ':</span>';
    items.forEach(function (it) {
      var b = document.createElement('button'); b.type = 'button'; b.textContent = it[1]; b.dataset.v = it[0];
      b.setAttribute('aria-pressed', String(it[0] === current));
      b.addEventListener('click', function () {
        d.querySelectorAll('button').forEach(function (x) { x.setAttribute('aria-pressed', String(x === b)); });
        onClick(it[0]);
      });
      d.appendChild(b);
    });
    return d;
  }
  document.addEventListener('DOMContentLoaded', function () {
    var h = location.hash.toLowerCase();
    var lang = h.indexOf('en') > -1 ? 'en' : 'pl';
    var theme = h.indexOf('dark') > -1 ? 'dark' : (h.indexOf('light') > -1 ? 'light' :
      (window.matchMedia && matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'));
    var scale = h.indexOf('s200') > -1 ? '200' : (h.indexOf('s150') > -1 ? '150' : '100');
    document.body.dataset.theme = theme; document.body.dataset.scale = scale;
    renderIcons(document);
    applyLang(lang);
    var note = document.querySelector('.pg-note');
    if (note) { var s = document.createElement('span'); s.className = 'pg-anno';
      s.textContent = 'Ikony: własne uproszczone odpowiedniki w stylu Hugeicons Free (Stroke Rounded), nie oryginalne pliki – do czasu potwierdzenia licencji (UX15).';
      note.appendChild(document.createTextNode(' ')); note.appendChild(s); }
    var nav = document.querySelector('.pg-nav');
    if (nav) {
      var here = location.pathname.split('/').pop();
      var names = ['01 Start', '02 Ekran startowy', '03 Ponowna akceptacja', '04 Lista planów', '05 Formularz', '06 Zgoda na AI', '07 Generowanie',
        '08 Widok planu', '09 Trasa', '10 Lokalizacja', '11 Usunięcie planu', '12 Ustawienia', '13 Prywatność', '14 Wylogowanie', '15 Usunięcie konta', '16 Komunikaty'];
      nav.innerHTML = names.map(function (n) {
        var f = 'ek-' + n.slice(0, 2) + '.html';
        return f === here ? '<b>EK-' + n + '</b>' : '<a href="' + f + '">EK-' + n + '</a>';
      }).join(' · ');
    }
    var head = document.querySelector('.pg-head');
    if (head) {
      head.appendChild(btns('Język UI', [['pl', 'PL'], ['en', 'EN']], lang, applyLang));
      head.appendChild(btns('Motyw', [['light', 'Jasny'], ['dark', 'Ciemny']], theme, function (v) { document.body.dataset.theme = v; }));
      head.appendChild(btns('Tekst', [['100', '100%'], ['150', '150%'], ['200', '200%']], scale, function (v) { document.body.dataset.scale = v; }));
    }
  });
})();
