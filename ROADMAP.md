# Mancs Mentőakció – ROADMAP

Fejlesztőjáték 3 éves gyermeknek, 13" iPad Air (landscape, 1366×1024 CSS px). Vanilla JS + natív ES modulok, build nélkül.

**Futtatás:**
- **Közvetlenül fájlként (`file://`):** az `index.html` dupla kattintással is azonnal elindul, mert `file://` protokollon automatikusan a `dist/bundle.js` csomagot tölti be. Ha a `src/` alatt módosítasz valamit, futtasd a `powershell -ExecutionPolicy Bypass -File .\build-bundle.ps1` parancsot!
- **Helyi webszerverről (`http://` / `https://`):** natív ES modulokkal (`src/main.js`) és PWA Service Workerrel fut.

## Fázisok és készültség

| Fázis | Tartalom | Állapot |
|---|---|---|
| 1 | Keretrendszer, állapotgép, audio/TTS, SVG váz, placeholder akció | **Kész** |
| 2 | 6 érintési minijáték (`scrub`, `multitap`, `drag`, `shapes`, `peekaboo`, `lasso`) | **Kész** |
| 3 | Részecske-effektek, adaptív segítség (animált mutatóujj), saját hangfájl fallback | **Kész** |
| 4 | Interaktív matricaalbum, LocalStorage, PWA / Service Worker | **Kész** |
| 5 (Bővítés) | 8 kutyus (Everest + Tracker), 16 mentőakció, szigorú Matricaalbum-ellenőrzés, 2 új játékmód (`CARE`, `SORTER`), modernizált UI + Házikó gomb | **Kész** |

## Modulok és interfészek

- `core/scope.js` – `Scope`: `setTimeout/setInterval/requestAnimationFrame/on/addCleanup/child/dispose`. Minden időzítő és listener ezen át fut.
- `core/stateMachine.js` – `registerState(name, {enter(ctx), exit?(ctx)})`, `setState(name, params)`. Váltáskor: exit → scope.dispose() (minden timer + listener törlődik) → `stopSpeech()` → bemenet-zár feloldás → új gyökér. A `ctx.setState` elavult állapotból no-op (race condition védelem).
- `core/input.js` – `installInputGuards()` (egyetlen aktív pointer, tenyérvédelem), `onTap(el, fn, scope, opts)`, `setInputLocked()`. Csak Pointer Events.
- `core/stage.js` – 1366×1024 színpad skálázása.
- `audio/sfx.js` – `unlockAudio, playChime, playBoop, playSuccess, playPop, playMagic`. **3. fázis:** itt kap fájl-fallbacket, a függvénynevek változatlanok.
- `audio/speech.js` – `speakHu(text|{say,show}, onEnd, {remember})`, `stopSpeech`, `replayLast`. Biztonsági időzítő + felirat.
- `data/gameData.js` – `GAME_DATA`; `imageUrl`, `symbolImageUrl`, `mission.sceneImageUrl/solvedImageUrl` mezőkkel azonnal cserélhető grafika.
- `state/progressStore.js` – `getSnapshot, addBone, awardSticker, resetBones, subscribe, setAdapter({load,save})`. **4. fázis:** `setAdapter` LocalStorage-zsal.
- `minigames/index.js` – **becsatolási pont:**

```js
mountActionMinigame(pupConfig, containerElement, onCompleteCallback, parentScope?)
  // → { unmount(), scope }
registerMinigame(mechanic, (pupConfig, container, onComplete, scope) => cleanupFn | { unmount })
```
  A **2. fázisban** csak a `src/minigames/<mechanic>.js` modulokat kell megírni és `registerMinigame`-mel regisztrálni (pl. `main.js`-ben importálva); az `action.js` és az állapotgép nem változik. Az `onComplete` egyszer hívható; a `scope`-on keresztül futtatott minden időzítő/listener automatikusan takarítódik.

## Állapotgép

`SPLASH → HUB → SELECTION (briefing + választás) → ACTION → REWARD → HUB`

## Kézi tesztlista (1. fázis)

1. Splash érintés után hang + üdvözlés a HUB-on.
2. Mancs-jelvény → csipogás, probléma + kérdés elhangzik; kártyák a végén "ugranak be".
3. Téves kártya: rázkódás, boop, elhalványul. 6 mp tétlenség: arany ugráló helyes kártya.
4. Helyes kártya: siker + dicséret → ACTION → gomb → megoldott jelenet → REWARD.
5. Gyors, ismételt koppintgatás minden képernyőn: nincs dupla állapotváltás.
6. 3 csont után "Új Matrica!", koppintásra csontok nullázódnak, HUB; Album mutatja a matricát.
7. Hangismétlés gomb (jobb felső) bármikor megismétli a legutóbbi mondatot.

## 2. fázis – minijátékok

Minden mechanika a src/minigames/ alatt, egisterMinigame-mel regisztrálva (minigames/index.js); a placeholder.js tartalék marad ismeretlen mechanikára. Közös alap: common.js (uildPlayfield: haladással megoldottá úszó jelenet, súgó, inish(); 	rackPointer: egy-pointeres húzás).

| Mechanika | Kutyus | Játék |
|---|---|---|
| scrub | Marshall | tűz dörzsölése az ujjal, vízcseppek (Canvas) |
| multitap | Rubble | 3 nagy szikla, mindegyikre 1 koppintás |
| drag | Skye | a repülő áthúzása a kiscicához, rossz elengedésnél visszasiklik |
| shapes | Rocky | 3 alakzat az ugyanolyan lyukba, rossznál boop + vissza |
| peekaboo | Chase | bokrok felemelése, véletlen helyen a kiskacsa |
| lasso | Zuma | kör rajzolása a labda köré (zárt hurok vagy elég közeli rajz) |

Minden interaktív elem az alsó zónában (y ≥ 560) van, nincs kudarc: 8 mp tétlenség után arany kiemelés + hangos tipp.

## 3. fázis – Audiovizuális effektek, Adaptív Segítő Rendszer és Hangfájl Fallback

- **Részecskerendszer (`src/ui/particles.js` – `createParticleLayer(container, scope)`):**
  - `emitWaterJet(fromX, fromY, toX, toY, count)`: irányított vízsugár és gőzpára Marshall tűzoltó-játékában (`scrub`).
  - `emitWaterSplash(x, y, count)`: vízcsobbanás és hullámgyűrűk Zuma mentőöv-játékában (`lasso`).
  - `emitDustCloud(x, y, opts)`: gomolygó porfelhő és kavics/faforgács/levél törmelék (`multitap`, `shapes`, `peekaboo`).
  - `emitSparkles(x, y, opts)` és `emitStarTrail(x, y, color)`: csillogó csillag-kitörés és húzási nyomvonal (`HUB`, `SELECTION`, `drag`, `shapes`, `peekaboo`, `lasso`).
- **Dinamikus vizuális rávezetés (`src/ui/guideHand.js` – `createGuideHand(container, scope)`):**
  - Kontrasztos, kesztyűs animált mutatóujj + érintési hullámgyűrű + szaggatott útvonal-vezető:
    - `showTap(x, y)`, `showScrub(cx, cy, rx, ry)`, `showDrag(fromX, fromY, toX, toY)`, `showCircle(cx, cy, r)`, `hide()`.
- **Adaptív Segítő Rendszer (`src/ui/scaffolding.js` – `createScaffolding(container, scope, opts)`):**
  - **1. szint (~4,5–6 mp tétlenség vagy 1 téves próbálkozás):** célpont arany pulzálása (`is-hint`).
  - **2. szint (~8–9,5 mp tétlenség vagy 2 téves próbálkozás):** megjelenik az animált mutatóujj a pontos mozdulattal + elhangzik a segítő hangnarráció.
  - **3. szint (~13,5 mp tétlenség vagy 3 téves próbálkozás):** aktív könnyítés (nagyobb mágneses befogási sugár, kevesebb hátralévő dörzsölés/ívhossz, téves választási lehetőségek elhalványítása).
  - Érintéskor (`touch()`) a mutatóujj azonnal eltűnik, hogy ne zavarja a gyermeket.
- **Saját hangfájlok (`.m4a` / `.mp3`) fallback támogatása (`src/data/audioManifest.js`, `src/audio/engine.js`):**
  - Az `AUDIO_MANIFEST.sfx` és `AUDIO_MANIFEST.voice` objektumokban megadott hangfájlokat az első érintéskor (`unlockAudio`) előtölti a böngésző által támogatott formátumban (`.m4a` / `.mp3`).
  - Ha egy hangeffekt vagy narrációs mondat nem rendelkezik saját fájllal (vagy a fájl nem tölthető be), a rendszer automatikusan és zökkenőmentesen visszaesik a Web Audio API szintetizátorra (`src/audio/sfx.js`) illetve a magyar Web Speech API-ra (`src/audio/speech.js`).
  - Konzolos segédfüggvény az összes felvehető magyar mondat listázásához: `window.mancs.voiceLines()`.

## 4. fázis – Interaktív Drag-and-Drop Matricaalbum, LocalStorage Mentés és PWA

- **Interaktív Drag-and-Drop Matricaalbum (`src/ui/modal.js` – `openStickerAlbumModal`):**
  - Felső **Kaland-öböl Panoráma-tábla** (Kilátótoronnyal, égbolttal, erdővel, domboldallal, folyóhíddal, havas csúccsal és tóval), ahol mind a **8 kutyusnak** van egy szimbólummal és névvel jelölt saját helye (`HOME_SPOTS`).
  - **Szigorú hely-ellenőrzés (Form-illesztő logika):** Minden matrica kizárólag a saját kutyusának jelölt helyére (`SNAP_RADIUS = 135px`) tapad fel! Ha a gyermek másik kutyus helyére vagy üres területre húzza, a játék `playBoop()` hangot ad, kedvesen visszajelez (*„Hoppá! Ez nem {name} helye! Keresd {name} saját jelét a képen!”*), arany fénnyel felvillantja a helyes célhelyet (`.is-target-hint`), és a matrica visszacsúszik a tálcára. 2 téves próbálkozás után az animált mutatóujj (`guideHand.showDrag`) megmutatja a pontos útvonalat.
  - Alsó **Reach Zone Matrica-tálca** (`y = 835`) 8 rekesszel és piros Bezáró (`✕`) gombbal.

## 5. fázis (Bővítés) – 8 Kutyus, 16 Küldetés és 2 Új Játékmód

- **8 Kutyus és 16 Mentőakció (`src/data/gameData.js`, `src/art/scenes.js`, `src/art/pupSvg.js`, `src/art/symbols.js`):**
  - Csatlakozott **Everest** (havas-jeges mentő, `#00ACC1` türkiz, hópehely szimbólum) és **Tracker** (dzsungel-mentő, `#689F38` dzsungelzöld, iránytű szimbólum).
  - Mind a 8 kutyus **2-2 különböző mentő-küldetést** kapott (összesen **16 egyedi helyszín és feladat**):
    1. **Marshall (`scrub`):** Tábortűz eloltása + Sáros tűzoltóautó lemosása
    2. **Rubble (`multitap`):** Sziklák eltakarítása a sínekről + Homokkupacok elásása a játszótérről
    3. **Skye (`drag`):** Kiscica mentése a fáról + Elszállt piros lufi visszahozása a felhők közül
    4. **Rocky (`shapes`):** Eltört fahíd megjavítása + Kutyaház tetőfoltjainak beillesztése
    5. **Chase (`peekaboo`):** Elveszett kiskacsa a bokrok mögött + Elbújt kisnyuszi a virágos réten
    6. **Zuma (`lasso`):** Besodródott strandlabda + Kis vitorlás hajó kimentése mentőövvel
    7. **Everest (`scrub`):** Behavazott faházikó megtisztítása + Befagyott kispingvin kiszabadítása a jégből
    8. **Tracker (`peekaboo` / `multitap`):** Kismajom megkeresése a dzsungel-indák mögött + Kidőlt bambuszok eltakarítása az ősi ösvényről
- **Új Játékmód 1: „Kutyus-gondozó és Etető” (`CARE` – `src/screens/care.js`):**
  - 3 sáros kutyus közül választhat a gyermek, majd a fürdőkádban:
    1. **Szappanozás:** a sárga szivaccsal átdörzsölve habbuborékok nőnek a kutyuson és eltűnik a sár.
    2. **Öblítés:** a zuhanyrózsával vízsugarat (`emitWaterJet`) fújva leöblíti a habot.
    3. **Etetés:** 2 finom jutalomfalatot húz (vagy koppint) a tiszta kutyus szájához → `REWARD` (+1 aranycsont!).
- **Új Játékmód 2: „Szín- és Formaválogató Kutyus-tálak” (`SORTER` – `src/screens/sorter.js`):**
  - 3 különböző színű kutyus ül a saját színes tálkája mögött.
  - 5 színes, szimbólumos jutalomfalatot kell a megfelelő színű tálkába húzni; téves tálkánál kedves hangos visszajelzés, visszapattanás és vizuális segítség; 5 sikeres falatka után `REWARD` (+1 aranycsont!).
- **Modernizált Felület és Állandó Házikó (`🏠`) Gomb (`src/ui/hud.js`, `src/screens/hub.js`, `styles/main.css`):**
  - A `HUB` alsó Reach Zone sávjában 4 nagy tevékenység-gomb érhető el: **Fürdető**, **Tálkák**, középen a **Mentőakció (Mancs-jelvény)** és jobb oldalt a **Matricák (8/8)**.
  - A bal felső HUD-ban minden játékképernyőn (`SELECTION`, `ACTION`, `CARE`, `SORTER`) megjelenik a **Házikó (`🏠`)** gomb, amellyel bármikor azonnal vissza lehet térni a Kilátótoronyba.
- **LocalStorage Haladásmentés (`src/state/localStorageAdapter.js`, `src/state/progressStore.js`):**
  - A `createLocalStorageAdapter()` (`mancs_mentoakcio_progress_v1` kulccsal) a `progressStore.setAdapter()` interfészen keresztül csatlakozik (`src/main.js`).
  - Automatikusan menti és visszaállítja a jutalomcsontokat (`bones`), a megszerzett matricákat (`stickers`) és a panoráma-táblán elhelyezett matricák pontos koordinátáit (`placedStickers: { [pupId]: { x, y } }`).
  - Safari privát böngészés vagy tárhely-hiba esetén memóriában tartja az adatokat, így sosem dob kivételt.
  - Konzolos visszaállítás: `window.mancs.resetProgress()`.
- **PWA Csomagolás és Offline Service Worker (`manifest.webmanifest`, `sw.js`, `src/pwa/registerSw.js`, `assets/icons/icon.svg`):**
  - Teljes képernyős, fektetett (`landscape`, `standalone`) Web App Manifest iPadOS főképernyőhöz.
  - Az offline Service Worker (`sw.js`) telepítéskor (`install`) előre gyorsítótárazza a teljes alkalmazás-héjat (HTML, CSS, manifest, ikon és mind a 25 ES modul), így az első megnyitás után internetkapcsolat nélkül is 100%-ban működik.
