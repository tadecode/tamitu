// Generates icon-preview.html from docs/ux/assets/*.svg (documentation only). Run from repo root: node docs/ux/mockups/_gen-icon-preview.js
const fs=require("fs"),A="docs/ux/assets/";
const raw=n=>fs.readFileSync(A+n,"utf8").replace(/<!--[\s\S]*?-->/g,"").replace(/<title[\s\S]*?<\/desc>/,"").replace(/\s*role="img" aria-labelledby="title desc"/,' aria-hidden="true"').trim();
const uri=n=>"data:image/svg+xml;base64,"+fs.readFileSync(A+n).toString("base64");
const fg=raw("tamitu-icon-foreground.svg"),bg=raw("tamitu-icon-background.svg"),mono=raw("tamitu-icon-monochrome.svg");
const full=uri("tamitu-icon-full.svg"),alt=uri("tamitu-icon-alt-light-full.svg");
const masks={"Koło":"50%","Zaokrąglony kwadrat":"22%","Squircle (przybliżenie)":"34%","Kropla":"50% 50% 50% 18%"};
// adaptive: 108 layer, visible 72 → show element w=size, layer scaled 1.5x, centered
const icon=(size,radius,src)=>`<div class="ic" style="width:${size}px;height:${size}px;border-radius:${radius}"><img src="${src}" alt="" style="width:${size*1.5}px;height:${size*1.5}px;margin:${-size*.25}px"></div>`;
const themed=(size,radius,b,f)=>`<div class="ic" style="width:${size}px;height:${size}px;border-radius:${radius};background:${b}"><div style="width:${size*1.5}px;height:${size*1.5}px;margin:${-size*.25}px;background:${f};-webkit-mask:url(${uri("tamitu-icon-monochrome.svg")}) center/contain no-repeat;mask:url(${uri("tamitu-icon-monochrome.svg")}) center/contain no-repeat"></div></div>`;
const row=(src,wall,c="#1B1B1B")=>`<div class="wall" style="background:${wall};color:${c}">`+Object.entries(masks).map(([k,r])=>`<figure>${icon(72,r,src)}<figcaption>${k}</figcaption></figure>`).join("")+`<figure>${icon(48,"50%",src)}<figcaption>48 dp</figcaption></figure><figure>${icon(36,"50%",src)}<figcaption>36 dp</figcaption></figure></div>`;
const crop=(w,h,t)=>`<figure><div class="hero" style="width:${w}px;height:${h}px;background-image:url(${uri("ek-02-illustration-"+t+".svg")})"></div><figcaption>${w}×${h} dp, ${t==="light"?"jasny":"ciemny"}</figcaption></figure>`;
const html=`<!doctype html>
<html lang="pl"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Tamitu – ikona i ilustracja EK-02 (podgląd)</title>
<style>
:root{--bg:#ECECEC;--fg:#1B1B1B;--muted:#555;--card:#FFF;--line:#CFCFCF}
@media (prefers-color-scheme:dark){:root{--bg:#111;--fg:#EDEDED;--muted:#AAA;--card:#1C1C1C;--line:#383838}}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--fg);font:15px/1.5 system-ui,"Segoe UI",Roboto,sans-serif}
main{max-width:1000px;margin:0 auto;padding:16px}h1{font-size:20px}h2{font-size:17px;margin-top:32px}p,li{color:var(--muted)}
section{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:16px;margin:12px 0}
.wall{display:flex;flex-wrap:wrap;gap:20px;align-items:flex-end;padding:20px;border-radius:12px;margin:8px 0}
figure{margin:0;display:flex;flex-direction:column;align-items:center;gap:6px}figcaption{font-size:12px;color:var(--muted)}
.wall figcaption{color:inherit;opacity:.85}
.ic{overflow:hidden;flex:none}.ic img{display:block}
.layers{display:flex;flex-wrap:wrap;gap:20px}.layer{width:216px;height:216px;position:relative;border:1px solid var(--line);background:repeating-conic-gradient(#ddd 0 25%,#fff 0 50%) 0 0/16px 16px}
.layer svg{width:100%;height:100%;display:block}.layer .safe{position:absolute;inset:0;pointer-events:none}
.hero{border-radius:16px;background:center/cover no-repeat}.heros{display:flex;flex-wrap:wrap;gap:16px}
.chooser{width:328px;background:#fff;color:#1f1f1f;border-radius:28px;padding:24px;font-family:Roboto,system-ui,sans-serif}
.chooser.dark{background:#2B2B2B;color:#E3E3E3}.chooser .top{display:flex;gap:12px;align-items:center;margin-bottom:12px}
.chooser .acc{display:flex;gap:12px;align-items:center;padding:10px 0;border-top:1px solid #0002}.av{width:32px;height:32px;border-radius:50%;background:#7B8C8B}
.cmp{display:flex;gap:24px;flex-wrap:wrap}
</style></head><body><main>
<h1>Tamitu – ikona aplikacji i ilustracja EK-02 (UX-ICON)</h1>
<p>Dokument do akceptacji, nie zasób aplikacji. Specyfikacja: <code>docs/ux/icon-and-illustration.md</code>. Źródła SVG: <code>docs/ux/assets/</code>. Maski i tła tapet są przybliżeniem launcherów Androida.</p>

<h2>1. Ikona – wariant A (rekomendowany): tło morskie <code>#006A6A</code></h2>
<section>${row(full,"#F3EEE6")}${row(full,"#1B2430","#EEE")}${row(full,"linear-gradient(135deg,#F2A65A,#6C4AA0)","#FFF")}</section>

<h2>2. Ikona tematyczna (Android 13+, warstwa monochromatyczna, kolory nadaje system)</h2>
<section><div class="wall" style="background:#F3EEE6;color:#1B1B1B">${["50%","22%","34%"].map(r=>`<figure>${themed(72,r,"#C4E2E1","#004F4F")}<figcaption>jasny (przykład)</figcaption></figure>`).join("")}</div>
<div class="wall" style="background:#1B2430;color:#eee">${["50%","22%","34%"].map(r=>`<figure>${themed(72,r,"#324B4B","#CCE8E7")}<figcaption>ciemny (przykład)</figcaption></figure>`).join("")}</div></section>

<h2>3. Warstwy adaptacyjne 108×108 dp i strefa bezpieczna</h2>
<section><p>Przerywany okrąg: strefa bezpieczna Ø 66 dp (widoczna w każdej masce). Kwadrat: obszar widoczny 72×72 dp. Treść mieści się w Ø ok. 60 dp.</p>
<div class="layers">${[["pierwszy plan",fg],["tło",bg],["monochromatyczna",mono]].map(([n,s])=>`<figure><div class="layer">${s}<svg class="safe" viewBox="0 0 108 108"><circle cx="54" cy="54" r="33" fill="none" stroke="#E0457B" stroke-width=".8" stroke-dasharray="2 2"/><rect x="18" y="18" width="72" height="72" fill="none" stroke="#3B6FD8" stroke-width=".6"/></svg></div><figcaption>${n}</figcaption></figure>`).join("")}</div></section>

<h2>4. Okno wyboru konta Google (OBS-DEV-2) – szkic</h2>
<section class="cmp">${["","dark"].map(d=>`<div class="chooser ${d}"><div class="top">${icon(40,"50%",full)}<div><b>Wybierz konto</b><br><small>aby nadal używać aplikacji Tamitu</small></div></div><div class="acc"><div class="av"></div><div>Konto testowe<br><small>konto@example.com</small></div></div></div>`).join("")}</section>

<h2>5. Wariant B (alternatywa do decyzji): jasne tło <code>#F4FBFA</code>, kolory znaku z logo</h2>
<section>${row(alt,"#F3EEE6")}${row(alt,"#1B2430","#EEE")}<p>B jest bliższy logo na jasnym tle, ale na jasnych tapetach i w białym oknie Google gubi kształt maski; A jest wyraźniejszy na każdym tle.</p></section>

<h2>6. Ilustracja EK-02 – kadry „cover" (144 dp, 96 dp przy tekście ≥ 150%)</h2>
<section><div class="heros">${crop(328,144,"light")}${crop(560,144,"light")}${crop(328,96,"light")}</div></section>
<section style="background:#0E1514;color:#DDE4E3"><div class="heros">${crop(328,144,"dark")}${crop(560,144,"dark")}${crop(328,96,"dark")}</div></section>
</main></body></html>`;
fs.writeFileSync("docs/ux/mockups/icon-preview.html",html);console.log(html.length);
