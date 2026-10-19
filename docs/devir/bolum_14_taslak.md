# Bölüm 14 taslağı: Çekirdek
(Tasarımcı çıktısı; Aşama C'de onaysız uygulama kullanıcı kararı.)

> **UYARI (2026-10-15, ölçümden sonra):** Bu taslağın sayıları tahmindi; ölçüm ve denetim sonuçları `docs/sorunlar.md` "Bölüm 14". Geçerli değerler: tur kareleri 153 / 393 / 483 + oyuncu 556 (600 sınırına 44 kare pay); Lazer2 kalıcı kapanış kare 142; PlakaR en az 51 kare basılı; bant yarışı payı 2 kare; W6 "konvoy +1..+3" ÇALIŞMAZ, çalışan aralık C2'den +26..+140 kare; Z1 iniş x 541; S penceresi (klon tekrarında) 848..872, canlıda 836..864, ikisi birden 848..864 (taslaktaki 840..866 yanlış: bant dikişi farkı, aşağıya bkz.). Min klon 3 doğrulandı, kısayol bulunamadı (klonsuz/1/2 klon 36 küme, park/röle 0/49, kutu varyantları).
> **BİLİNEN KISIT (kullanıcı kararı bekliyor):** canlı oyuncu ile klon tekrarı eş düzlemli UL1|Bant dikişinde (x≈490) motorun zemin seçimi yüzünden ayrışır (C2 klonu en çok 11,67 px, C3 1,67 px geride). Bölüm 10 ve 13'te de aynı sınıf var (≤10 px). Ayrıntı ve seçenekler: `docs/sorunlar.md`.


(`scenes/bolumler/bolum_14.tscn`) FİNAL. Sabitler `player.gd`, `gecit.gd`, `lazer.gd`, `kutu.gd`, `yayli_ziplatici.gd`, `tasima_bandi.gd`, `basinc_plakasi.gd`, `scenes/tek_yonlu.tscn` ve Bölüm 10-13 taslak/ölçüm notlarından (docs/sorunlar.md) okundu. Koşturulmadı; "ölçülecek" işaretli sayılar tahmindir (kare modeli 60 kare/sn).

## 1. Özet
- Yeni fikir: **üç klonun her biri farklı bir tekniğin sonunda kendi lazerinin ARKASINDA kalıcı olarak "mıhlanır"** (raf tepesi, çukur dibi, çıkıntı üstü). Kutu, zıplatıcı ve bant hepsi ortak yoldadır; iki yarış geçidi (biri bantla hızlanır, biri kutuyla itilir) her aktöre uygulanır.
- B12'den farkı: kutu zıplatıcıyla fırlatılıp basamak olmaz; kutu güvertede basamak olur, lazerleri ve çukuru geçerek itilir; geçit yarışı bant yardımıyla, kutuyla birlikte ve iki kez yapılır. B13'ten farkı: bant darbesi/şalter yok; S düşmesi geri dönüşsüz kuyu değil, klonun çukura inip plakayı tutmasıdır (çukurdan klonun dönüşü lazer yüzünden kapalıdır).
- Nesneler: kutu x1, yaylı zıplatıcı x2, taşıma bandı x1, geçit x2, lazer x3, plaka x4, tek yönlü x3 (raf + 2 kapak), kapı. **YOK:** şalter, asansör (geçit altı park/röle kısayolu lazerlerde işlemez, §9).
- `max_klon = 3`, **tam 3 klon gerekir** (§9 kanıt). Tur başına ≤ ~520 kare.
- Zorluk (B13'ten bir kademe): 3 farklı mıhlanmış tutucu (S, zıplatıcı, kutu basamağı), iki yarış penceresi 2,4 ve 4 kare (≤10), kutuyla yarış, klonlar arası sıra bağımlılığı (kutuyu önce C2 sonra C3 iter).

## 2. Sabitler (koddan)
Karakter 28x48, HIZ 300 (5 px/kare), zıplama tepesi 96,5 (kare ~100,9), g 1400, `ASAGI_DUSME_KARE`=12. Zıplatıcı: sensör 60x12, 820 px/sn, tepe ~247 px (K=36), havada ~71 kare, tetik karakter merkezi x0±44 (kutu x0±50), yalnız `velocity.y>=0`. R(K)=(820K-11,667K(K-1))/60 px: K=20 -> 199,5; K=29 -> 238; K=36 -> 247. Bant 100 px/sn: girdisiz 1,667 px/kare, girdili sağa 6,667, ters 3,333 (B10 ölçümü). Geçit 20x200, 120 px/sn (2 px/kare), açıklık 100 -> 48 px'e 26 kare. Plaka 60x16 (kutu da basar). Lazer 6 px kalınlık; ışın geçişi (28+6)/5 = 6,8 kare. Kutu 40x40 (karakterler için katı, kendisi yalnız `it()` ile itilir).

## 3. Kat planı (yüzey zemin 600, güverte 400, çıkıntı 270)
```
x:   0        280  400    500      650 700  760      880  920 1000      1152
y=0  ┌─────────────────────────── Tavan (y 0..140) ──────────────────────────┐
140  │ MIL (x<400, tavan 140)  ┌──── TavanD (x 400..1152, y 140..200) ────────┤
200  │                         │ L2|          GR2|      |L1      |   LD  Kapı │
270  │                         │ |             |  |      |       ÇIKINTI(270)  │
     │                         │ |             |  |      |       [PU]   ┌─────┤
400  │ [PM]RS(tek yönlü)──UL1──┤ [PR2]=BANT====UL2 Kutu|Kapak1|Kapak2 UR  │     │
     │        ZıpL1            │                      | ÇUKUR (160 px)    │     │
600  │ [PA] GA  Z1             Zemin ...        Z2 [PP] ...              │     │
     └─────────────────────────────────────────────────────────────────────────┘
```
- Mil (x 0..400): zemin 600, tavan Tavan alt kenarı 140. Güverte (x 400..1152): zemin yüzeyi 400, tavan TavanD alt kenarı 200 (salon 200 px).
- Çukur x 760..920 (160 px), derinlik 200, tabanı Zemin (y=600); üstü iki tek yönlü kapak kapatır (ancak S ile girilir).
- Çıkıntı (x 1000..1152) yüzeyi y=270; kapı çıkıntıdadır.

## 4. Nesneler (merkez)
| Düğüm | Tür | Konum | Ayrıntı |
|---|---|---|---|
| Zemin | StaticBody2D | (576,620) | 1152x40 (y 600..640) |
| Tavan | StaticBody2D | (576,70) | 1152x140 (y 0..140) |
| TavanD | StaticBody2D | (776,170) | 752x60 (x 400..1152, y 140..200) |
| UL1 | StaticBody2D | (445,500) | 90x200 (x 400..490, üst 400) |
| BantAlti | StaticBody2D | (570,508) | 160x184 (x 490..650, y 416..600) |
| UL2 | StaticBody2D | (705,500) | 110x200 (x 650..760, üst 400) |
| UR | StaticBody2D | (960,500) | 80x200 (x 920..1000, üst 400) |
| Cikinti | StaticBody2D | (1076,435) | 152x330 (x 1000..1152, y 270..600) |
| Raf (RS) | scenes/tek_yonlu.tscn | (340,406) | 120x12, üst y=400, x 280..400 |
| Kapak1 | scenes/tek_yonlu.tscn | (820,406) | üst y=400, x 760..880 |
| Kapak2 | scenes/tek_yonlu.tscn | (940,406) | üst y=400, x 880..1000 |
| Bant | scenes/tasima_bandi.tscn | (570,408) | 160x16, üst y=400, x 490..650; `yon=1`, `hiz=100` |
| PlakaA (PA) | basinc_plakasi | (87,592) | x 57..117; GecitA'yı açar |
| PlakaM (PM) | basinc_plakasi | (330,392) | x 300..360, Raf üstünde; Lazer2'yi KAPATIR |
| PlakaR (PR2) | basinc_plakasi | (500,392) | x 470..530 (yarısı UL1, yarısı bant üstünde); GecitR'yi açar |
| PlakaP (PP) | basinc_plakasi | (880,592) | x 850..910, çukur tabanında; Lazer1'i KAPATIR |
| PlakaU (PU) | basinc_plakasi | (1030,262) | x 1000..1060, çıkıntı üstünde; Lazer3'ü KAPATIR |
| Z1 | scenes/yayli_ziplatici.tscn | (370,594) | `firlatma_hizi=820`, bölge x 340..400 (Raf'ın altında, UL1 duvarına bitişik) |
| Z2 | scenes/yayli_ziplatici.tscn | (790,594) | `firlatma_hizi=820`, bölge x 760..820 (çukur sol ucu) |
| GecitA | scenes/gecit.tscn | (265,500) | `kayma_yonu=(0,-1)`, `kayma_mesafe=100`, `hiz=120`; tetik [../PlakaA]; kapalıyken x 255..275, y 400..600 |
| GecitR | scenes/gecit.tscn | (710,300) | aynı parametreler; tetik [../PlakaR]; kapalıyken x 700..720, y 200..400 (tavana bitişik) |
| Lazer2 (L2) | scenes/lazer.tscn | (450,200) | `yon=(0,1)`, `uzunluk=200` (x 447..453, y 200..400), tetik [../PlakaM], `tetik_aktifken_kapali=true` |
| Lazer1 (L1) | scenes/lazer.tscn | (915,200) | `yon=(0,1)`, `uzunluk=200` (x 912..918, y 200..400), tetik [../PlakaP], kapalı=true |
| Lazer3 (LD) | scenes/lazer.tscn | (1090,200) | `yon=(0,1)`, `uzunluk=70` (x 1087..1093, y 200..270), tetik [../PlakaU], kapalı=true |
| Kapi | kapi.gd Area2D | (1128,246) | 36x48 (x 1110..1146, y 222..270) |
| Kutu | scenes/kutu.tscn | (675,380) | 40x40, x 655..695 (bant ucu 650, geçit sol yüzü 700) |
| Oyuncu | oyuncu.tscn | (60,576) | |
| Bilgi | Label | (16,12)-(600,40) | |

Ağaç sırası: Zemin, Tavan, TavanD, UL1, BantAlti, UL2, UR, Cikinti, Raf, Kapak1, Kapak2, Bant, PlakaA, PlakaM, PlakaR, PlakaP, PlakaU, Z1, Z2, GecitA, GecitR, Lazer2, Lazer1, Lazer3, Kapi, Kutu, Oyuncu, Bilgi (plaka/geçit/lazer karakterlerden ve kutudan önce). Her StaticBody2D'de `Gorsel` ColorRect. Başlangıç: lazerler AÇIK (PlakaM/PlakaP/PlakaU boş), geçitler kapalı; oyuncu PlakaA üstünde başlamaz (sağ kenarı 74, plaka 57..117: GÖRÜNÜR çakışma var: 57..74, yani PlakaA başlangıçta BASILI).

Güvenlik payları: kutu oyuncudan 595 px (>=40); asansör yok; geçit kapalı üstü tavana bitişik (GecitR) ya da açık mil (GecitA, üstü açık ama 200 px'lik duvar, aşılamaz §8); lazer ışınları tavandan zemine tam yükseklik; çıkıntı üstü ile TavanD arası 70 px (48 sığar, baş payı 22).

## 5. Roller
- **C1 (raf tutucusu):** GecitA yarışını tek başına yapar, Z1 ile dikey fırlayıp Raf üstündeki PlakaM'ye iner ve kalır. Lazer2 kapalı. (Raf'ta kalan klon çıkamaz: ileri her yol Lazer2'den geçer, plakadan ayrılınca ışık açılır.)
- **C2 (çukur tutucusu):** Lazer2 kapalıyken Z1'le (sağa basılı) güverteye uçar, PlakaR + bant yarışını kutuyla birlikte yapar (GecitR'den kutuyu iterek geçer), kapağa kadar iter, Kapak1 üstünde S ile çukura iner, PlakaP'de kalır. Lazer1 kapalı. Çukurdan klon çıkamaz: Z2'den yalnız sola, Lazer1'in solunda çıkar (§9).
- **C3 (çıkıntı tutucusu):** Lazer2 ve (çukurdan sonra) Lazer1 kapalıyken kutuyu iter, kutuyu çıkıntı yüzüne dayar, kutu üstünden çıkıntıya zıplar, PlakaU'da kalır. Lazer3 kapalı.
- **Oyuncu (son tur):** üç lazer kapalıyken yolu alır: PlakaR yarışı tek başına, kutu basamağı, kapı.

## 6. Çözüm (tuş kareleri tahmin; testler "koşula kadar bekle")
**Tur 1 -> C1 (~190 kare, R ~kare 260):**
1. Başta `bekle` >= 32 kare (PlakaA basılı, GecitA açılır). `sag` kesintisiz ~14 kare: x 60 -> 131 (plakadan ayrılma, kare >= 46).
2. `sag` kesintisiz (GecitA'ya 22 kare sonra girer, açıklık ~56 px >= 48; PAY ~4 kare, kesintisiz basılı olmalı).
3. x ~320'de dur; `sag` 2 kare (merkez 326 sınırı, Z1 tetik, x ~330), sonra bırak: dikey fırlar, Raf üstüne ve PlakaM üstüne iner (kare ~137). Orada boş girdiyle kal; R kare ~260.
**Tur 2 -> C2 (~330 kare, R ~kare 480):** C1 oynar.
1. GecitA: C1 PlakaA'da (kare <46) basılıyken geçer: başta bekleme yok, `sag` hemen (kare 36'da GecitA'dan geçer, açıklık 72).
2. x ~320'de bekle: PlakaM basılı (C1 inmesi ~kare 136) olana kadar; Lazer2'den geçme kare >= ~137. Z1'e `sag` basılı gir (kare >= ~110 fırlatma); basılı tutarak Lazer2'yi havada geçer, bant üstüne x ~546 civarı iner (kare ~165).
3. PlakaR'a dön: `sol` ~(546-475)/3,33 = 21 kare (bant ters 3,33 px/kare), x <= 475'te dur (bant dışı, plaka basılı). PlakaR >= 47 kare basılı kalmalı (GecitR açıklığı >= 92).
4. `sag` kesintisiz: bant (6,667) ile 15,9 kare, kutuya x=641'de değer, kutuyu iter (5 px/kare), 9 kare sonra GecitR'ye girer (toplam ~23,6 kare, açıklık ~52,8; PAY ~2,4 kare). Kutu GecitR altından önce geçer (açıklık ~69 >= 40).
5. Kutuyu `sag` ile ~37 kareyle Kapak1/Kapak2 üstüne (x ~880..900) sürer; C2 merkezi 840..866 iken `sag` bırak, S (`asagi`) bas; Kapak1'den iner (Z2 sensörü x 760..820'den 20 px uzak), PlakaP üstüne ~31 kare sonra iner. Kal; R ~kare 480.
**Tur 3 -> C3 (~380 kare, R ~kare 540):** C1, C2 oynar.
1. GecitA'dan hemen geç (C1 basılı); Z1'e `sag` basılı (>= kare ~110), Lazer2 kapalı; bant üstüne in; PlakaR'a dön, x <= 475'te bekle; C2 yarışı bitirene kadar kal (C2 kare ~217'de ayrılır): GecitR C2 ayrılana kadar açık, C3 PlakaR'dan ayrılıp C2'nin ARKASINDAN en az 1, en çok 3 kare sonra geçebilir (kutuyu C2 iter, C3 itmemeli) ya da C2 geçtikten sonra PlakaR'da >= 47 kare basılı kalıp kendi başına yarışır (PAY ~2,9 kare, kutu artık geçitten sonrada).
2. Kutu Kapak1/Kapak2 üstünde (~x 900); `sag` ile Lazer1'den geç (PlakaP basılı olmalı, C2 inişi ~kare 313); kutuyu çıkıntı yüzüne iter (kutu x 980), kutunun solundan (merkez ~946) `zipla`+`sag` ile kutu üstüne, sonra çıkıntıya zıplar; `sag` ile PlakaU üstünde (x ~1030) dur, kal. R ~kare 540.
**Tur 4 (R kapalı "Klon: 3/3") -> oyuncu (~430 kare):** başlangıçta plaka basılı kalma süresi serbest (C1 yeterli): `sag` hemen (GecitA açıkken geçer). Z1'e yaklaş; Lazer2 kapalı olana kadar (kare ~137) bekle, `sag` basılı fırlat, bant üstüne in, PlakaR'a dön, >= 47 kare bekle (diğer klonlar PlakaR'dan çoktan ayrıldı: GecitR kapalı), `sag` kesintisiz GecitR'yi geçer (PAY ~2,9 kare), Kapak1/Kapak2 üstünden yürür (Lazer1 kapalı), kutu çıkıntı yüzünde (C3 itti); kutu üstü + çıkıntı, PlakaU'yu geç, Lazer3 (kapalı) altından kapıya.

Süreler ≈ 4,3 / 5,5 / 6,3 / 7,2 sn (hepsi ≤600 kare).

## 7. Zamanlama pencereleri (ölçülecek)
| # | Pencere | Genişlik |
|---|---|---|
| W1 | GecitA yarışı (her aktör, PlakaA'yı en son bırakan): ayrılma merkezi 131 -> GecitA sol yüzü 255, giriş merkezi 241: 22 kare, açıklık 56 >= 48; pay | **4 kare** (ve PlakaA >= 46 kare basılı) |
| W2 | GecitR yarışı kutuyla (bant yardımlı): ayrılma 544 -> bant ucu 650: 15,9 kare; kutuya değme (merkez 641): 14,6 kare, +9 kare itme: 23,6 kare; açıklık 52,8 | **~2,4 kare** (kutusuz 22,6 kare, pay ~3,3; bantsız 28,4 kare > 26 BAŞARISIZ) |
| W3 | Lazer2 geçişi: PlakaM basılı (C1 iniş ~kare 135) sonrası; fırlatma sonrası ışın girişi K~29..33 | alt sınır tek yanlı; ışın penceresi sınırsız (klonlar dokunmaz) |
| W4 | Z1 dikey fırlatma (C1): sensör merkezi 326'dan 2 kare sonra bırakma | x 286..374 PlakaM üstü (88 px, 17 kare) |
| W5 | C2 S konumu: Kapak1 üstünde yalnız (Kapak2 yok), Z2 sensöründen uzak, PlakaP üstüne iniş | merkez 840..866 = 26 px = **5,2 kare** (yürürken) |
| W6 | C3 yarışı C2'nin arkasında (kutu sırası) ya da kendi başına | konvoy: C2'den +1..+3 kare (**3 kare**); kendi yarışı pay ~2,9 |
| W7 | Çıkıntı çıkışı: kutu üstü -> çıkıntı yüzeyi, pay 10,9 px (kutu üstü 360, 90 px, zıplama 100,9) | ~11 px |
- Zorunlu pencerelerden <=10 kare olanlar: W1 (4), W2 (2,4), W5 (5,2), W6 (3). B13'ün en dar penceresi pay ~2 kare, kalan 8-22 kare; B14'te hepsi bir aktörde art arda gelir ve her aktör uygular.

## 8. Atlanamazlık hesapları
- GecitA: 200 px (zemin 600, üst 400) > 100,9; aşma bölgesi Z1'in solunda zıplatıcı yok. Açıkken üst yüzey y=300 > ulaşılabilir ayak 499.
- Zemin -> Raf: 200 > 100,9; yalnız Z1 (ayak tepe 353 < 400).
- Raf -> güverte: aynı seviye (Raf üstü 400 = güverte). UL1 yüzü x=400, 200 px.
- Lazer2: ışın y 200..400, güverte yüzeyi 400, tavan TavanD 200 (bitişik): üstten/alttan aşma yok; zıplama başı 251 > 200 ışın içinde; Z1 uçuş başı >= 305 ışın içinde.
- GecitR: kapalı y 200..400, tavana bitişik; zıplama tepe ayak 299 > 200.
- Çukur: 160 px genişlik, kapak(lar) yalnız S'le geçilir; kapak üstünden yürünür (çukur atlanmaz sorunu yok, üstü kapalı). Çukur duvarı UR sol yüzü x=920, y 400..600.
- Çıkıntı: 130 px yüksek > 100,9 (kıtlık 29,1 px); yalnız kutu (140,9, pay 10,9) ya da yok. Z2 uçuşu tepe ayak 353 > 270 (83 px kısa), Z1 aynı. Güverte tavan 200: bir zıplatıcı güvertede olsaydı çıkıntıya yetebilirdi; **güvertede zıplatıcı yoktur** (tasarım kararı).
- Lazer3: ışın y 200..270, çıkıntı yüzeyi 270, tavan 200: baş 222 >= ışın içinde; geçmeden kapıya varılamaz.
- Mil tavanı 140, güverte tavanı 200: Z1 uçuşu başı 305; çıkıntıda ayak 259,1 zıplamada baş 211,1 >= 200 (11 px pay).

## 9. KISAYOL TARAMASI (zorunlu; gozden-gecirici bağımsız kontrol eder) ve min klon 3
**Kanıt (mıhlanmış tutucu argümanı):** Lazer2, Lazer1, Lazer3 sırayla geçilir; tutucuları (PlakaM, PlakaP, PlakaU) üç ayrı yerde. Her tutucu kendi lazerinin ARKASINDA kalır: PlakaM'den ayrılan Lazer2'yi (başkası tutmuyorsa) geçemez (ışın tavandan zemine tam yükseklik); PlakaP'den ayrılan klon yalnız Z2'den sola, Lazer1'in soluna çıkar (çukur sağ duvarı x=920 > ışın x=918: uçuşta ışına girer); PlakaU'daki zaten sondadır. Her biri bir klon, hiçbiri başka bir klonun işini yapamaz, oyuncu son turda hiçbirini tutamaz (ışınları kendisi geçmeli). 3 eşzamanlı tutma >= 3 klon.

| Deneme | Sonuç | Neden |
|---|---|---|
| Klonsuz | olmaz | Lazer2'de (x=450) ölür |
| 1 klon (yalnız C1) | olmaz | Lazer1 açık: x=912'de ölür; PlakaP'ye kimse inmedi |
| 1 klon (C2 tek başına) | olmaz | C2 kayıt dünyasında Lazer2 açık: ölür/çukura varamaz |
| 2 klon (C1+C2) | olmaz | LD açık: oyuncu çıkıntıda ölür (ışın tavandan çıkıntıya tam). Oyuncu PlakaU'yu tutarken LD'yi geçemez |
| 2 klon (C1+C3 / C2+C3 / ters sıra) | olmaz | C3 Lazer1'den (PlakaP boş) ya da Lazer2'den (PlakaM boş) geçemez |
| Kutu basamağı (tam hedef) | tasarım yolu | çıkıntı 130 > 100,9; kutu 140,9: tek yol. Kutu başka basamak olamaz (güvertede başka yükseklik yok) |
| Kutuyla plaka tutma | kısayol yok | kutu yalnız PlakaM'ye sola itilirse (arkadan değil: itici sağda olmalı, ışından sonra) basılı tutar ama basamak kaybolur; kutuyu PlakaP'ye (çukur) kapaklar yüzünden sokamaz; PlakaU çıkıntıda (kutu çıkamaz); PlakaR bantta 1,667 px/kare ile sürüklenir, <=60 kare tutar |
| Zıplatıcı + kutu | kısayol yok | Z1 altına kutu itilirse kutu Raf'a PlakaM'nin üstüne iner (tutucu), ama sola gerisinde itici kalamaz: kutu Raf'ta kilitlenir; Z2 çukurda: kutu kapak üstünde, Z2 sensörü (çukur tabanı) tetiklenmez |
| Bant darbesi dalgalanması | klon düşürmez | PlakaR kısmen bant dışı: klon x<=475'te hareketsiz basılı kalır (dalgalanma gerekmez); bu "PlakaR tutucusu" 4. klon olurdu, kimse yok. Darbe yalnız GecitR'yi etkiler, lazer yok |
| Geçit altı park / röle | işlemez | GecitA/GecitR'nin tutucuları ayrıdır: her aktör kendi plakasını tutup yarışır, park yalnız yarışı kolaylaştırır (klon düşürmez; ölçülecek). Lazerlerde park yok (ölür) |
| Şalter | yok | bu bölümde şalter yok |
| S ile yeni iniş yolu | kısayol yok | S yalnız Raf (mile iner, başa dönüş) ve iki kapakta işler (çukur). Kapak2 üstünde x >= 934'te S: altı UR (katı), etkisiz; x 888..906'da S: PlakaP üstüne iner (Lazer1'in solu, geçerli tutucu) |
| Lazeri zıplayarak aşma | olmaz | Lazer2, Lazer1: y 200..400 (zemin-tavan); Lazer3: y 200..270 (çıkıntı-tavan); tüm zıplama/uçuş başı ışın bandının içinde |
| Z2 uçuşuyla Lazer1'i atlama | olmaz | çukurdan sağa uçuşta duvar x=920'ye sürtünür, K=20'de güverte seviyesine çıkınca gövde x 892..920 ışın x 912..918 içinde |
| Z1 uçuşuyla GecitR'yi atlama | olmaz | Z1 en çok x ~546'ya indirir (kalıcı), GecitR x=700 |

## 10. Kilitlenme analizi ("Baştan başla" ile giderilir; asansör yok)
1. Kutu sola itilirse (bir aktör kutunun sağında): GecitR açıkken altından geçer (kutu üstü 360 > gecit açık alt kenar 300), Raf'ın kenarından Mil'e düşer; Z1 sütununa inerse Raf'a PlakaM üstünde iner, itici solunda duramaz: çıkıntı basamağı kaybolur. Kilitlenme.
2. Kutu GecitR altında kalırsa (geçit kutu üstünde 40 px'te durur): karakter geçemez, kutuyu sağdan iterek çıkarmak için geçidin solunda durmak yeter (kutu geçit altından itilir). Kilit değil.
3. Kutu çukura düşmez (kapaklar), Z2'ye de değmez.
4. Aktör yanlışlıkla çukura inerse (Kapak1/Kapak2 üstünde S): Z2'den çıkar (x ~834'te sola); PlakaP ile Lazer1 arasında kalma yok, kilit değil.
5. GecitA/GecitR yarışı kaçırılırsa aktör kapının solunda kalır, PlakaA'ya/PlakaR'ya dönüp yeniden dener (geçit kilitleme yok).
6. Klon GecitA/GecitR altında biterse geçit 48 px'te durur (zararsız).
7. C1/C2/C3 kaydı yanlış: "Baştan başla".

## 11. Başarısızlık senaryoları (test-yazarı için)
1. Klonsuz: Lazer2'de ölür (tur yeniden).
2. Yalnız C1: Lazer1'de ölür.
3. C1+C2: Lazer3'te ölür.
4. C1 başta < ~32 kare bekler: GecitA'ya girerken açıklık < 48, kapıya takılır (Z1'e varamaz).
5. C2 PlakaR'da < 47 kare basılı kalır: GecitR açıklığı yetmez, kutu ve C2 geçemez.
6. C2 Kapak1'de x 816..834'te S: Z2 üstüne iner, geri fırlar; PlakaP basılmaz.
7. C3 kutuyu C2'den önce iter (konvoy +0 kare): kutu çarpışması C2'nin yolunu kaydırır, kutu kapağa varmaz.
8. Oyuncu Lazer2'ye kare < ~137'de girer: ölür.
9. C3 çıkıntıya çıkmaz (PlakaU boş): oyuncu Lazer3'te ölür.
10. Bant olmadan yarış (örn. kutusuz sola yürüme ve sonra uzun yol): 28,4 kare > 26.

## 12. Riskler (ölçülecek)
- GecitR yarışı payı ~2,4 kare (bant sürüklemesi ve kutu teması); bant ile plaka dikişi x=490 ve 650'de gövde zemin değiştirmesi (B13 dikiş bulgusu: x>=~927 gövde yeni zemine geçer). Bant çıkışı (x=650) ile kutu (655) arası 5 px.
- Kutu GecitR sol yüzüne 5 px: başlangıçta temas yok; kapı açılırken kutu üstü 360 > gecit alt kenar 300 (kutu geçit içine girmez ama gecit açıkken altından geçer).
- Z1 uçuşunda UL1 yüzü sürtünmesi (K=12..20 gövde x=386'da sabit); iniş x ~546 ± 6.
- Kapak1/Kapak2 yan yana (880'de dikiş): S yalnız tek kapakta, 840..866.
- Z2 çukurda yalnız kurtarıcı; kimse bilerek kullanmaz.
- PlakaM'de Raf sağ ucu UL1'e bitişik (x=400).
- Çıkıntı üstü 70 px: zıplama başı 211,1 >= tavan 200.

## 13. Geri dönmesi zor kararlar (kullanıcı karar versin)
1. **Çukur genişliği 160 px, iki kapak, Z2 sola konumlu:** çukurdan klonun Lazer1'i atlamasını kapatan tasarım. Kapaklar yan yana (S bilinçli konuma gerekir). Eksi: çukurdan çıkış yalnız Z2.
2. **Kutu ışından SAĞDA başlar (Raf/PlakaM'ye ulaşamaz):** kutuyla tutucu klon tasarrufunu kapatır; kutu yalnız sağa sürülür. Eksi: kutu sola itilirse bölüm kilitlenir (Baştan başla).
3. **Güvertede zıplatıcı yok, güverte tavanı 200:** çıkıntıya zıplatıcıyla çıkışı kapatır; eksi: güvertede zıplatıcı kullanılamaz.
4. **Bant GecitR yarışını gerektirir (bantsız 28,4 kare > 26):** bant "çözümün parçası" olur ama pay dar (~2,4 kare); ölçümde kırılgan çıkarsa plaka/geçit mesafesi 10 px kaydırılır.
5. **Şalter ve asansör yok:** final için "nesne yığmak" yerine üç tutucu + iki yarış.
6. **Harita konumu:** `Vector2(1070,545)`, önceki Bölüm 13 (docs/kararlar.md'de zaten öngörülmüştü). Mesafeler: 13'e 195 px, 3'e 121 px, 12'ye 315 px (hepsi >=100). Çizgi 13-14 dikey x=1070 (y 350..545); 3-4 çizgisi (1010,440)->(700,530) soldan başlar, 2-3 çizgisi (820,270)->(1010,440) x<=1010; hiçbiri kesişmez (segment kesişim hesabı: 13-14 ile her çizgi için x aralıkları ayrık ya da y aralıkları ayrık). Etiket y 545+34+14+30=623 < 648.

## 14. Harita kaydı
`yol = res://scenes/bolumler/bolum_14.tscn`, `konum = Vector2(1070, 545)`, `onceki = res://scenes/bolumler/bolum_13.tscn`.
