# Bölüm 18 taslağı: Vardiya
(Tasarımcı çıktısı; gece otonom üretim, kullanıcı onaylı; sayılar tahmindir, ölçümle düzeltilecek.)

> **ÖLÇÜM NOTU (2026-10-16):** Bu taslağın sayıları tahmindi; ölçümler `docs/sorunlar.md` ve `tests/test_runner.gd` `_b18_*` testlerindedir. Güncel: 3 tur, 2 klon, kareler 179/223/354; asansöre biniş `sag` bırakma x 186..294 (~112 px, taslak 68 px); raf S 733..826; fitil payı 64 kare (taslak ~78); C_A geç basış payı 22 kare; C_B payı fitille 64 kareye sınırlı (taslak ~99); `tutma_kare` tam 180; canlı/klon farkı 0,00 px. "Başta bekleme" payı paylaşılan zamanlı asansörü kaçırtabilir. Min klon 2 doğrulandı, kısayol yok.


> **UYARI:** Bütün kare/piksel sayıları TAHMİNDİR (60 kare/sn, HIZ 5 px/kare; ölçüm yapılmadı). Bölüm 12-14 deneyimi: taslak sayıları hep ölçümle değişti; Bölüm 10/13/14'te canlı/klon dikiş ayrışması ~11,67 px görüldü (docs/sorunlar.md). Payların hepsi bu ayrışma ve asansör-zemin hizası düşülerek verildi: zorunlu karar dikişlerin >= 12 px içindedir. Harita konumu: `harita agent atayacak` (docs/devir/harita_yerlesim.md'de 18 için (580,510) ayrılmış).

(`scenes/bolumler/bolum_18.tscn`, `max_klon = 3`, **çözüm en az 2 klon**.) Sabitler `player.gd` (HIZ 300 = 5 px/kare, zıplama tepesi 96,5 / kare ~100,9, g 1400, `ASAGI_DUSME_KARE` 12), `asansor.gd` (plaka basılıyken çıkar, inerken altında karakter varsa durur), `basinc_plakasi.gd` (`tutma_kare` varsayılan sahne 180), `lazer.gd`, `gecit.gd`, `tek_yonlu.tscn`, `bolum.gd` (klon kaydı bitince boş girdiyle yerinde bekler) ve Bölüm 10/15-17 taslaklarından okundu. Asansör boyutu Bölüm 10 sahnesinden (120x20, `yukseklik`/`hiz` export).

## 1. Fikir ve özet
- **Öğrettiği fikir (tek cümle):** zamanlı plakaya bağlı asansör, plakayı tutan kimse olmadan tek başına binilen bir asansördür ("kendi asansörünü kendin tut"); ayrıca bir plaka birden çok lazeri (katlar arası) kontrol edebilir ve çıkıştan sonra yol bir DÖNGÜYLE aşağıdaki kapıya geri döner.
- Kat yapısı: F1 (y=600) ve F2 (y=380) + F2'nin ucundaki raftan S ile inilen cep (F1 sağ bölge) + cepten SOLA yürünen F1 "arka oda" (kapı orada). Yani rota F1 -> F2 -> F1: oyuncu başladığı katın dibine, duvarın ardına döner.
- Nesneler: zamanlı plaka x1 (asansör plakası), asansör x1, plaka x2 (A, B), lazer x3 (A: F2, A2: F1 arka oda, B: F1 arka oda), tek yönlü raf x1, kapı. YOK: kutu, bant, zıplatıcı, şalter, geçit, mandal plaka (kısayol yüzeyi bilerek dar).
- **Min klon 2** (§8). 3 tur: C_A (~185 kare), C_B (~240), oyuncu (~350); hepsi <= 600.
- İç içe: (1) asansörü tek başına kullanma (zamanlı plaka), (2) tek plakanın iki lazeri (F2 + F1) ayrı katlarda kontrolü: tutucu kimsesi göremeden uzun süre bekler, (3) S ile iniş ve dönüşsüz cep, (4) döngü: cepten çıkan yol iki lazer kapısından geçerek kapıya gider; tutucular kapıdan önce bırakılamaz.

## 2. Kat planı (F1 koridoru y 420..600 = 180 px, F2 koridoru y 180..380 = 200 px)
```
y=180 ┌────────────────────────── Tavan (0..180) ──────────────────────────────┐
      │ F2        (asansör tepe)  PlakaA   LazerA   PlakaB      raf(S)   BlokR │
y=380 ├───────┐ boşluk ┌───────────[A]──┴──┴──────[B]─────────┬─Raf────┤       │
y=420 │DöşSol │160..300│ DöşemeA (300..720)                   │720..840│       │
      │ (arka alan)    │  F1 ARKA ODA (x 370..720)  Kapı (420) A2 │  B  │ cep   │
      │ [O]  [Asansör]──ZP──│ DuvarWK │ ◄── yürüyüş ◄── ◄── ◄── ◄──── │ 720..840│
y=600 └──────────────────────────────────────────────────────────────────────────┘
       40   170..290                350..370  420            540  640
```
- F1 sol alan (x 0..350): oyuncu, asansör (x 170..290), zamanlı plaka (asansörün üstüne denk gelen x 200..260). DuvarWK (x 350..370) bu alanı arka odadan ayırır.
- F2: DosemeSol (x 0..160) ve DosemeA (x 300..720) arasında 140 px'lik boşluk = asansör kuyusu; raf (x 720..840) cebin üstünü kapatır; BlokR (x 840..1152, y 180..600) sağ ucu kapatır.
- Cep (x 720..840, y 386..600): yalnız raftan S ile girilir. Cepten sola F1 arka oda (x 370..720); iki lazer kapısı (x 640 ve 540) ve kapı (x 420) orada. Kuyu ve odadan F2'ye dönüş yok.

## 3. Nesneler (merkez, boyut)
| Düğüm | Tür | Konum | Boyut / parametre |
|---|---|---|---|
| Zemin | StaticBody2D | (576,620) | 1152x40 (y 600..640) |
| Tavan | StaticBody2D | (576,90) | 1152x180 (y 0..180) |
| DosemeSol | StaticBody2D | (80,400) | 160x40 (x 0..160, üst y=380) |
| DosemeA | StaticBody2D | (510,400) | 420x40 (x 300..720, üst y=380) |
| Raf | tek_yonlu.tscn | (780,386) | 120x12 (x 720..840, üst y=380) |
| BlokR | StaticBody2D | (996,390) | 312x420 (x 840..1152, y 180..600) |
| DuvarWK | StaticBody2D | (360,510) | 20x180 (x 350..370, y 420..600) |
| Asansor | asansor.gd AnimatableBody2D | (230,610) | 120x20 (x 170..290, üst y=600 = F1 yüzeyi), `yukseklik=220` (üst y=380 = F2 yüzeyi), `hiz=120`, `plaka=../PlakaZ` |
| PlakaZ | zamanli_plaka.tscn | (230,592) | 60x16 (x 200..260, asansörün üstünde), `tutma_kare=180` (varsayılan) |
| PlakaA | basinc_plakasi | (380,372) | 60x16 (x 350..410, DosemeA üstü) |
| PlakaB | basinc_plakasi | (600,372) | 60x16 (x 570..630, DosemeA üstü) |
| LazerA | lazer.tscn | (470,180) | `yon=(0,1)`, `uzunluk=200` (x 467..473, y 180..380), tetik [../PlakaA], `tetik_aktifken_kapali=true` |
| LazerA2 | lazer.tscn | (540,420) | `yon=(0,1)`, `uzunluk=180` (x 537..543, y 420..600), tetik [../PlakaA], kapalı=true (ortak plaka) |
| LazerB | lazer.tscn | (640,420) | `yon=(0,1)`, `uzunluk=180` (x 637..643, y 420..600), tetik [../PlakaB], kapalı=true |
| Kapi | kapi.gd Area2D | (420,576) | 36x48 (x 402..438, y 552..600) |
| Oyuncu | oyuncu.tscn | (40,576) | gövde 28x48 |
| Bilgi | Label | (16,12) | |

**Ağaç sırası:** Zemin, Tavan, DosemeSol, DosemeA, Raf, BlokR, DuvarWK, PlakaZ, PlakaA, PlakaB, Asansor, LazerA, LazerA2, LazerB, Kapi, Oyuncu, Bilgi (plaka/asansör/lazer karakterlerden önce; asansörün `plaka` yolu PlakaZ'ye). Başlangıç: asansör aşağıda, tüm lazerler açık. Güvenlik: kutu yok; oyuncu ZP'ye değmez (gövde x 26..54, plaka 200..260).

## 4. Roller
- **C_A:** asansörle F2'ye çıkar, PlakaA'da KALIR: LazerA (F2) ve LazerA2 (F1 arka oda) birlikte kapalı.
- **C_B:** asansör, LazerA'dan geçer, PlakaB'de KALIR: LazerB (F1 arka oda) kapalı.
- **Oyuncu:** asansör, LazerA, raf S, cep, LazerB, LazerA2, kapı. Kimseyi taşımaz, 3 tur sonra başlar.

## 5. Çözüm (tuş kareleri tahmin; c = gövde merkezi x)
Tüm turlarda aynı başlangıç: `sag` basılı, c(k)=40+5k.
**Tur 1 (C_A, ~185 kare):** c=186'da (k~30) gövde asansöre (x 170..290) binmiş ve plakaya (x 200..260) değiyor; asansör kalkmaya başlar. c~230'da (k~38) `sag` BIRAK: asansörle yükselir (gövde ~8 karede plakadan ayrılır; fitil 180 kare). Tepe k~140. `sag`: c=300'e geçer, PlakaA'ya c>=336'da (k~161) girer; c~380'de dur, ~15 kare bekle, R.
**Tur 2 (C_B, ~240 kare):** C_A oynar. Aynı yol; LazerA ışınına (c=453) k~185'te varılır (C_A plakada k~162'den beri: ~23 kare pay). PlakaB'ye c>=556'da (k~210) girer, c~600'de dur, ~15 kare bekle, R.
**Tur 3 (oyuncu, "Klon: 2/3", R basılmaz, ~350 kare):** aynı yol ve aynı kareler; LazerA geçilir; raf üstünde c=734..826 arası (örn. c=780, k~250) `sag` BIRAK, `asagi` bas: cebe iner (düşüş ~34 kare, k~284). `sol` basılı: LazerB (x 640) k~309, LazerA2 (x 540) k~329, kapı (c<~452) k~350.

## 6. Zamanlama pencereleri (pay; asansör-zemin dikişi >= 12 px)
| # | Pencere | Pay |
|---|---|---|
| W1 | Asansöre biniş: `sag` bırakma c aralığı: gövde asansör üstünde ve dikişlerden >= 12 px (c 196..264); c>276'da gövde sağ kenardan taşar | **68 px** (+-34 px = +-6,8 kare) |
| W2 | Fitil: plakadan ayrılıştan sonra 180 kare; asansör tepeye 110 - 8 = ~102 kare sonra çıkar; tepede yürüyüşle çıkış | **~78 kare** |
| W3 | C_A plakada (k~162) -> bir sonraki klonun / oyuncunun LazerA ışınına varışı (k~185) | **~23 kare** |
| W4 | Raf S: gövde tam raf üstünde ve duvar yok: c 734..826 | **92 px** (tek yönlü bir yönde sağ tuş bırakılmalı: 12 kare x 5 = 60 px sürüklenme; sağ duvara BlokR yaslar, zarar yok) |
| W5 | C_B plakada (k~210) -> oyuncunun LazerB ışınına varışı (k~309) | **~99 kare** |
| W6 | C_A plakada -> oyuncunun LazerA2 ışınına varışı (k~329): C_A kayıt sonu yerinde bekler (yanlışlıkla ayrılmaz) | >= 160 kare |
| W7 | Cepten kapıya yürüyüş: 3 hat, 25 + 20 + ~20 kare | tek yönlü |
- Bant, dikiş, S dönüşü yok; asansörün dikişleri (x 170, 290) yalnız biniş W1'de.

## 7. Atlanamazlık (sahne sayıları)
- **F1 -> F2:** F2 yüzeyi y=380, F1 yüzeyi y=600: 220 px > 100,9 (pay 119); tek yol asansör (asansör üstü 380 = F2'ye bitişik).
- **F1 sol alan -> arka oda:** DuvarWK (x 350..370, y 420..600) tavana (DosemeA alt kenarı y=420) bitişik; üstü yok; zıplama tepesi 100,9 < 180.
- **LazerA:** ışın y 180..380 (tavan alt kenarı 180, F2 yüzeyi 380 bitişik); zıplamada baş y>=251 ışın bandı içinde.
- **LazerA2, LazerB:** ışın y 420..600 (DosemeA alt kenarı 420, zemin 600); zıplama tepesi (ayak y 499) baş y 451 ışının içinde.
- **Raf -> F2 dönüş:** cepten F2'ye 220 px (zıplama 100,9); asansör kuyusuna giden yol arka odadan kapalı (DuvarWK).
- **Kapı:** arka odada, yalnız cepten sola yürüyerek varılır.

## 8. Kısayol taraması (min 2 düşmez)
| Deneme | Sonuç | Neden |
|---|---|---|
| Klonsuz | olmaz | LazerA'da (k~185) ölür |
| 1 klon (yalnız C_A) | olmaz | oyuncu cepte LazerB'de (k~309) ölür; PlakaB'ye kendisi basarsa LazerB başka katta (arka oda), oraya gidemez |
| 1 klon (yalnız C_B) | kayıt alınamaz | C_B kayıt turunda LazerA'da ölür (tutucu yok) |
| min-1 = 1 klon + oyuncu PlakaB'yi tutar | olmaz | oyuncu plakada kalamaz (kapı arka odada) |
| 1 klon, A -> B röle (C_A plakadan ayrılıp PlakaB'ye gider) | olmaz | LazerA yeniden açılır; ayrılan C_A ışına (plaka sağ kenarı 410, ışın 467: 57 px) ~11 karede varır ve ölür; ayrıca LazerA2 (k~329) PlakaA'yı ister |
| Kutu basamağı / kutuyla plaka tutma | uygulanamaz | bölümde kutu yok |
| Zıplatıcı + kutu | uygulanamaz | zıplatıcı ve kutu yok |
| Bant dalgalanması | uygulanamaz | bant yok |
| **Geçit altı park / röle** | uygulanamaz | bölümde geçit yok; asansör altı park: asansör tepedeyken altında park eden karakter asansörü yukarıda tutar (indiremez), ama plaka/lazer sayısını düşürmez (tutucu A ve B ayrı) |
| S ile yeni iniş yolu | yok | tek raf; F2'de başka tek yönlü yok; DosemeA üstünde S etkisiz (katı) |
| Lazeri zıplayarak aşma | olmaz | §7 |
| **Zamanlı plakayla röle** | min'i düşürmez | ZP yalnız asansör içindir; her geçen kendi asansörünü tutar; ZP lazer tutmaz. ZP'ye klon bırakmak 3. klon, fayda yok |
| Mandalla tasarruf | uygulanamaz | mandal plaka yok |
**Min klon 2 kanıtı:** LazerA, PlakaA'nın 57 px ilerisinde; LazerB ve LazerA2 oyuncunun son turda karşılaşacağı arka odada. PlakaA, oyuncunun LazerA'yı (k~185) ve LazerA2'yi (k~329) geçtiği ana kadar basılı olmalı; PlakaB, oyuncunun LazerB'yi (k~309) geçtiği ana kadar. İkisi aynı anda (k 309..329 arasında) basılı olmak zorunda, birbirinden uzak ve farklı katlarda: tek klon iki plakada olamaz, tek klon PlakaA'dan PlakaB'ye giderse LazerA ve LazerA2 açılır. Oyuncu kendisi tutucu olamaz (kapı arka odada, plakalar F2'de). 2 klon yeter; 3. klon gereksiz.

## 9. Başarısızlık senaryoları
1. Klonsuz: LazerA'da ölür, tur yeniden başlar.
2. Yalnız C_A: oyuncu cepte LazerB'de ölür (k~309).
3. C_A kaydında PlakaA'dan erken ayrılma: LazerA ve LazerA2 açık; C_B ve oyuncu ölür (kayıt tekrarı).
4. Asansör plakası: gövde plakaya basıp asansöre binmeden (c>304'e yürüyerek) geçerse asansör boş çıkar; fitil bitene (180) ve inene (~110) kadar ~290 kare kaybı, kilit yok.
5. Asansörde `sag` bırakılmadan tepeye yürünürse: gövde yolda sağ kenardan F1'e düşer (asansör 46 px yukarıda), tekrar dener.
6. Rafta çok erken S (c<734): DosemeA destekler, S etkisiz; tekrar dener.
7. Rafta sağ tuş basılı S: 12 karede +60 px sürüklenme BlokR'ye yaslar, cebe yine iner (zarar yok).
8. C_B PlakaB'den ayrılırsa: LazerB açılır, oyuncu ölür.
9. Cepte LazerB/LazerA2 açıkken sola yürüme: ölüm; cep dönüşsüz, tur R veya "Baştan başla" ile biter.

## 10. Kilitlenme analizi
- Cep ve arka oda tek yön: cepten F2'ye çıkış yok; oyuncu klonsuz inerse yalnız R (klon hakkı varsa tur kaydedilir) ya da "Baştan başla" çözer (§12).
- Klon asansör altında kalmaz: tüm klonlar asansörle çıkıp F2'de biter; F1 sol alanda kimse beklemez. Asansör ineceği kuyuda (x 170..290) kimse yok (aşağı düşen karakter asansörün üstüne iner).
- DosemeSol (x 0..160) ölü bir parça: oraya yürüyen karakter kuyuya düşerek F1'e döner.
- Klonlar plakada biter, kimseyi engellemez.
- Şalter yok (durum tablosu gerekmez).

## 11. S düşme kullanımı ve riskleri
Tek S: raf (c 734..826), cebe iniş ~34 kare. Risk: erken S etkisiz; sağ tuş basılı S 60 px sürükler (duvara yaslanır). Cepten dönüş yok.

## 12. Geri dönmesi zor kararlar (kullanıcı karar versin)
1. **Cep dönüşsüz:** kapı F1 arka odada; cebe klonsuz inen oyuncu tur içinde F2'ye dönemez. Alternatif: cepte zıplatıcı (LazerB'yi atlama riski doğar).
2. **Plaka ortak (A iki lazeri kontrol eder):** C_A kaydı uzun bekler (~350 kare boyunca yerinde); kayıt sonu boş girdiyle bekleme kullanılır (bolum.gd davranışı).
3. **`tutma_kare` varsayılan 180:** asansör payı ~78 kare (öğretici); sahnede 120 yapılırsa pay ~18 kare (kolayca sertleştirilebilir).
4. **Harita konumu:** `harita agent atayacak`.
