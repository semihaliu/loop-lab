# Bölüm 6 taslağı: "Nöbetçi Geçit" (`scenes/bolumler/bolum_6.tscn`)
(Tasarımcı çıktısı; Aşama 2'de onaysız uygulama kullanıcı kararı.)

Öğretilen fikir: GEÇİT (VEYA) + LAZER, iki klonun farklı görevi, zincirleme bağımlılık. Klon A geçidi tutar; klon B (A sayesinde geçidin ötesine geçen oyuncunun kaydı) PlakaL'i tutar. PlakaL lazeri kapatır, asansörü kaldırır ve geçidi VEYA ile açık tutar. Nesneler: plaka, geçit, lazer, asansör, kapı.
Sabitler: 28x48, HIZ 300 (5 px/kare), zıplama tepesi 96,5/~100,9, geçit ve asansör 120 px/sn, zemin yüzeyi y=600, oyuncu (100,570). Asansör position.y merkezdir.

## Kat planı
Oda 1 x 0..570 (alçak tavan y 400); geçit x 570..590 (kapalı y 400..600, açılırken yukarı Tavan1 içine kayar); Oda 2 x 590..1152 (tavan y 300), PlakaL x 630..690, lazer x 760, asansör x 830..950, seki x 952..1152 yüzeyi y=450, kapı seki üstünde.

## Nesneler (merkez)
| Düğüm | Tür | Konum | Ayrıntı |
|---|---|---|---|
| Zemin | StaticBody2D | (576,620) | 1152x40 |
| Tavan1 | StaticBody2D | (295,250) | 590x300 (x 0..590, y 100..400) |
| Tavan2 | StaticBody2D | (871,200) | 562x200 (x 590..1152, y 100..300) |
| Seki | StaticBody2D | (1052,470) | 200x40 (x 952..1152, y 450..490) |
| PlakaA | basinc_plakasi | (40,592) | 60x16 |
| PlakaL | basinc_plakasi | (660,592) | 60x16 |
| Asansor | asansor.gd | (890,610) | 120x20, plaka=../PlakaL, yukseklik=80 (üst yüzey 520), x 830..950 |
| Gecit | scenes/gecit.tscn | (580,500) | 20x200 (y 400..600), kayma_yonu=(0,-1), kayma_mesafe=200, hiz=120, tetikleyici_yollari=[../PlakaA, ../PlakaL] |
| Lazer | scenes/lazer.tscn | (760,300) | yon=(0,1), uzunluk=300 (y 300..600), tetikleyici_yollari=[../PlakaL], tetik_aktifken_kapali=true |
| Kapi | kapi.gd Area2D | (1090,426) | 36x48 |
| Oyuncu | oyuncu.tscn | (100,570) | |
| Bilgi | Label | (16,12)-(600,40) | |

`max_klon = 2`. Ağaç sırası: Zemin, Tavan1, Tavan2, Seki, PlakaA, PlakaL, Asansor, Gecit, Lazer, Kapi, Oyuncu, Bilgi. Export kalıpları bolum_2/bolum_5.tscn'den. Başlangıç: geçit kapalı, lazer açık, asansör aşağıda. Asansör ile seki arası 2 px boşluk (asansör x 830..950, seki 952..).

## Çözüm (kare; testler koşula kadar bekler)
- Tur 1 → klon A: sol 12 kare (x→40), ~10 bekle, R (~0,4 sn). Geçit ~13'ten açılır.
- Tur 2 → klon B: oyuncu durmadan sağa yürür (x=556'ya ~91, geçit ~156 px açık), x=660'a ~112, ~12 bekle, R (~2,1 sn). Işına (x 757) gitmez.
- Tur 3 (R kapalı "Klon: 2/2"): B ~104'te PlakaL'e basar, lazer kapanır, asansör kalkar (~145 üst 520). Oyuncu sağa yürür, ışından ~129'da geçer, x≈800'de zıplar + sağ (asansör üstüne ~172), hemen ikinci zıplama + sağ (seki ~205), kapıya ~215 (3,6 sn). Zıplama koşula bağlı: x≥~900 ve y≈520 olunca ikinci zıplama.

## Atlanamazlık
Geçit 200 px, tavan alt kenarına bitişik; klonsuz sprint: plakadan x≥84'te ayrılınca geçit ~94 karede alt kenar ~588 (baş için ≤552 gerek) → 36 px eksik, geçilemez. Seki zeminden 150 px > 100,9; asansör yalnız PlakaL basılıyken kalkar; oyuncu PlakaL'i kendi basarsa ışına 67 px, geçemez. Tüm plakalar zeminde (baş-plaka çakışması yok).

## Kilitlenme / klon altı
A x=40, B x=660; ikisi de asansör kolonunda veya geçit bölgesinde değil. Yanlış kayıtta "Baştan başla".

## Başarısızlık senaryoları
1. Klonsuz: PlakaA'da 100 kare bekle, sağa koş: geçitte sıkışır, bitmez.
2. Yalnız A: geçidi geçer, PlakaL'e basmadan ışına girer, ölür.
3. A kaydı boş: B geçide takılır, bitmez.
4. A erken ayrılır: geçit kapanmaya başlar, B takılır.
5. B plaka dışında (x≈740): lazer açık, oyuncu ölür.
6. B yön hatası: PlakaL basılmaz, bitmez.
7. Asansör aşağıdayken zeminden zıplama: seki'ye ulaşılmaz (ayak y min 499).

## Riskler
İki ardışık zıplama zamanlaması; asansör yan yüzü takılma (seki x 954..1152'ye çekilebilir); geçit sprint payı 36 px.

## Harita
`yol = res://scenes/bolumler/bolum_6.tscn`, `konum = Vector2(620, 380)`, `onceki = res://scenes/bolumler/bolum_5.tscn`. Kesişim/çakışma olursa alternatif (1050,300).

## Düzeltme (test bulgusu)
Asansör yükselince altında 60 px boşluk, baş üstü 552 > alt yüzey 540: asansörün altına giren oyuncu zıplarken kafasını çarpar. Birinci zıplama asansörün yanından, x ≲ 800'de (test x=740 kullanır; x=810'da başarısız) başlamalıdır, "x≈800" sınırdır.
