# Bölüm 10 taslağı: "Hat" (`scenes/bolumler/bolum_10.tscn`)
(Tasarımcı çıktısı; Aşama C'de onaysız uygulama kullanıcı kararı.)

Yeni fikir: TAŞIMA BANDI (+ kutu). B1 sağa (kutuyu ışının ötesindeki plakaya taşır), B2 sola (F2'de karşı koşu). Nesneler: bant x2, plaka x4, asansör, geçit, lazer x2, kutu, kapı, duvar parçaları. `max_klon = 3`.
Sabitler: 28x48, HIZ 300 (5 px/kare), zıplama tepesi 96,5 (kare ~100,9), g 1400. Bant `hiz` 100 px/sn = 1,667 px/kare; bant yönüne girdi 6,667 px/kare, ters 3,333; havada yalnızca yon*300. Kutu 40x40 (bantta 1,667 px/kare). Asansör/geçit 120 px/sn, asansör position.y merkez. Zemin yüzeyi 600, F2 yüzeyi 440, tavan alt kenarı 300.

## Kat planı
B1 x 270..430 (üst y=600, zemine gömülü), L1 bandın ortasında x=350, duvar x 430..450 (kutuyu durdurur), P1 ışının ötesinde (bandın sonunda), PE ve P2 duvardan sonra, E x 690..810, Kat2 yüzü x=812 (2 px boşluk), F2'de PG, B2 (sola), G, kapı.

## Nesneler (merkez)
| Düğüm | Tür | Konum | Ayrıntı |
|---|---|---|---|
| ZeminSol | StaticBody2D | (135,620) | 270x40 |
| ZeminDolgu | StaticBody2D | (350,628) | 160x24 (bandın altı) |
| ZeminSag | StaticBody2D | (791,620) | 722x40 (x 430..1152) |
| Tavan | StaticBody2D | (576,150) | 1152x300 |
| Kat2Sol | StaticBody2D | (851,520) | 78x160 (x 812..890, y 440..600) |
| Kat2Dolgu | StaticBody2D | (970,528) | 160x144 (x 890..1050, y 456..600) |
| Kat2Sag | StaticBody2D | (1101,520) | 102x160 (x 1050..1152, y 440..600) |
| Duvar | StaticBody2D | (440,580) | 20x40 (x 430..450, y 560..600) |
| Bant1 | scenes/tasima_bandi.tscn | (350,608) | yon=1, hiz=100, üst yüz y=600 |
| Bant2 | scenes/tasima_bandi.tscn | (970,448) | yon=-1, hiz=100, üst yüz y=440 |
| PlakaP1 | basinc_plakasi | (400,592) | 60x16 (x370..430, tam Bant1 üstünde; 2026-10-16: 410 -> 400, Duvar örtüşmesi giderildi), Lazer1'i kapatır |
| PlakaP2 | basinc_plakasi | (510,592) | 60x16, Lazer2'yi kapatır |
| PlakaPE | basinc_plakasi | (610,592) | 60x16, asansörü kaldırır |
| PlakaPG | basinc_plakasi | (850,432) | 60x16 (F2), Gecit'i açar |
| Asansor | asansor.gd | (750,610) | 120x20, plaka=../PlakaPE, yukseklik=160, hiz=120 (üst yüz 440) |
| Gecit | scenes/gecit.tscn | (1065,340) | 20x200 (y 240..440), kayma_yonu=(0,-1), kayma_mesafe=100, hiz=120, tetikleyici_yollari=[../PlakaPG] |
| Lazer1 | scenes/lazer.tscn | (350,300) | yon=(0,1), uzunluk=300, tetikleyici_yollari=[../PlakaP1], tetik_aktifken_kapali=true |
| Lazer2 | scenes/lazer.tscn | (690,510) | yon=(1,0), uzunluk=120, tetikleyici_yollari=[../PlakaP2], tetik_aktifken_kapali=true |
| Kapi | kapi.gd Area2D | (1110,416) | 36x48 |
| Kutu | scenes/kutu.tscn | (180,580) | |
| Oyuncu | oyuncu.tscn | (50,570) | |
| Bilgi | Label | (16,12)-(600,40) | |

Ağaç sırası: ZeminSol, ZeminDolgu, ZeminSag, Tavan, Kat2Sol, Kat2Dolgu, Kat2Sag, Duvar, Bant1, Bant2, PlakaP1, PlakaP2, PlakaPE, PlakaPG, Asansor, Gecit, Lazer1, Lazer2, Kapi, Kutu, Oyuncu, Bilgi. Her StaticBody2D parçasında `Gorsel` ColorRect (bolum.gd görünümü kurar). Başlangıç: asansör aşağıda, geçit kapalı, L1 ve L2 açık.

## Roller
A: kutuyu bantla P1'e gönderir, L1'i kutu+duvarın üstünden zıplayarak geçer, PE'nin solunda bekler, T_A'da PE'ye basar ve kalır. B: A'dan sonra aynı geçişi yapar, P2'de durur ve kalır. C: E'ye biner, A'nın PE'ye basmasıyla çıkar, PG'de durur ve kalır. Oyuncu: E'ye biner, F2'de B2 üstünden G'ye koşar, kapı.

## Çözüm (testler "koşula kadar bekle"; kareler yaklaşık)
Ortak giriş: `sag` basılı ~44 kare (kutu merkezi ≥300 olunca bırak, kutu bantta kendi gider), ~4 kare `sol`, Lazer1 kapanana kadar bekle (kutu P1'e basar ≈kare 80), `sag` ile x≈285'e koş, TEK karelik `zipla`, `sag` basılı ~45 kare (x≈508'e iner; kalkış penceresi x0 ∈ [267,350], kalkış kare ≥ ~74).
- Tur 1 → A (≈255 kare): ortak giriş; x≈560'a yürü; kare ~230'a kadar bekle; `sag` 10 kare (PE'ye basar), kalır; R.
- Tur 2 → B (≈155 kare): ~50 kare bekle (A iter), ortak giriş, x≈510'a in (P2), dur, R.
- Tur 3 → C (≈345 kare): ~50 bekle, ortak giriş, PE'nin ÜSTÜNDEN zıpla (x≈555'ten), E'ye in (x≈750), A'nın basmasına (~240) kadar bekle, asansör ~320'de üstte; `sag` ile PG'ye (x≈850) yürü, dur, R.
- Tur 4 (R kapalı "Klon: 3/3"): oyuncu E'ye biner, asansör çıkar, F2'de `sag`: B2 üstünde G'ye (≈393), G altından kapıya (≈410, ~6,8 sn).
Süreler ≈4,3 / 2,6 / 5,8 / 6,8 sn (≤600 kare).

## Atlanamazlık
L1 300 px tavandan zemine tam. Kutu P1'den çıkarılamaz (duvar sağda). F2'ye zeminden 160 > 100,9; kutu basamağı 140,9 < 160. G: PG'den ayrılma→G önü 147 px, G 100→50 px için 25 kare; bantla 43 kare > 25 → sprint kapatılmış. L2: asansörle çıkan karakter L2 bölgesinden geçer, L2 kapalı olmalı → B zorunlu.

## KISAYOL TARAMASI (tasarımcı sonucu; gozden-gecirici bağımsız kontrol edecek)
Klonsuz, yalnız A, A+B (C yok: G'ye sprintte 43 kare, G kapanır), röle (PE→P2: aralarında 40 px, ikisi aynı anda tutulamaz), kutuyu başka plakaya taşıma (duvar, farklı kat), kutu basamak (140,9<160), ışın zıplama → hiçbiri çözmez. Minimum 3 klon.

## Kilitlenmeler (Baştan başla ile giderilir)
Kutu bandın dışına sola itilir (sol duvara sıkışır); kutu yanlış kaydedilmiş; oyuncu bantta bekleyip ışına sürüklenir (tur yeniden başlar); A, C binmeden PE'ye basarsa C binemez.

## Başarısızlık senaryoları
1. Klonsuz: PE'ye basılamaz, bitmez. 2. Yalnız A: asansörle L2'de ölür. 3. A+B (C yok): G'ye sprintte G kapanır, bitmez. 4. Oyuncu itişten sonra bantta bekler: ışına sürüklenir, ölür. 5. Kalkış penceresi dışı (x0<267 ya da >350): geçemez. 6. A, C bindikten önce PE'ye basar: C binemez.

## Riskler
Bant-zemin dikişleri (x=270, 430; B2 x=890/1050) takılma; kutu bandın başında kısmen bantta; kutu duvara dayalı + bant titreme (plaka basılı kalmalı, x oynaması <0,1 px); bantta zıplama `platform_on_leave`; Kat2Dolgu/ZeminDolgu eksikse görünüm bozulur (fizik etkisi yok).

## Harita
`yol = res://scenes/bolumler/bolum_10.tscn`, `konum = Vector2(640, 190)`, `onceki = res://scenes/bolumler/bolum_9.tscn`.
