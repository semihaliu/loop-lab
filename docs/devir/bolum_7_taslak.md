# Bölüm 7 taslağı: "Üç Anahtar" (`scenes/bolumler/bolum_7.tscn`)
(Tasarımcı çıktısı; Aşama 2'de onaysız uygulama kullanıcı kararı.)

Fikir: U dönüşlü iki katlı mekan. F1'de sağa yürü, asansörle F2'ye çık, F2'de SOLA yürü. Çözüm zıplama gerektirmez; zorluk eşzamanlı tutma ve zamanlama. Nesneler: plaka x3, asansör, şalter, geçit, lazer x2, kapı.
Sabitler: 28x48, HIZ 300 (5 px/kare), zıplama tepesi 96,5/~100,9, asansör ve geçit 120 px/sn (2 px/kare), zemin yüzeyi y=600, oyuncu (100,570). Asansör position.y merkezdir. Şalter alanları SolAlan x -40..0, SagAlan x 0..40, y -48..0 (düğüme göre).

## Kat planı
F1 koridoru y 400..600 (200 px); F2 koridoru y 180..340 (160 px). Kat2 döşemesi y 340..400, x 0..838; Asansör x 840..960 (üst yüzey 340); Duvar x 962..1152. Tavan y 100..180.

## Nesneler (merkez)
| Düğüm | Tür | Konum | Ayrıntı |
|---|---|---|---|
| Zemin | StaticBody2D | (576,620) | 1152x40 |
| Kat2 | StaticBody2D | (419,370) | 838x60 (x 0..838, y 340..400) |
| Tavan | StaticBody2D | (576,140) | 1152x80 (y 100..180) |
| Duvar | StaticBody2D | (1057,390) | 190x420 (x 962..1152, y 180..600) |
| PlakaA | basinc_plakasi | (40,592) | 60x16 zeminde |
| PlakaB | basinc_plakasi | (700,332) | 60x16 Kat2 üstünde |
| PlakaC | basinc_plakasi | (500,332) | 60x16 Kat2 üstünde |
| Salter | scenes/salter.tscn | (260,600) | baslangic_sagda=false |
| Asansor | asansor.gd | (900,610) | 120x20, plaka=../PlakaA, yukseklik=260 (üst yüzey 340), x 840..960 |
| Gecit | scenes/gecit.tscn | (440,500) | 20x200 (y 400..600), kayma_yonu=(0,-1), kayma_mesafe=60, hiz=120, tetikleyici_yollari=[../Salter], acik_taraf_sag=true |
| Lazer1 | scenes/lazer.tscn | (600,180) | yon=(0,1), uzunluk=160 (y 180..340), tetikleyici_yollari=[../PlakaB], tetik_aktifken_kapali=true |
| Lazer2 | scenes/lazer.tscn | (380,180) | yon=(0,1), uzunluk=160, tetikleyici_yollari=[../PlakaC], tetik_aktifken_kapali=true |
| Kapi | kapi.gd Area2D | (120,316) | 36x48 |
| Oyuncu | oyuncu.tscn | (100,570) | |
| Bilgi | Label | (16,12)-(600,40) | |

`max_klon = 3`. Ağaç sırası: Zemin, Kat2, Tavan, Duvar, PlakaA, PlakaB, PlakaC, Salter, Asansor, Gecit, Lazer1, Lazer2, Kapi, Oyuncu, Bilgi. Export kalıpları bolum_5/bolum_6.tscn'den. Başlangıç: asansör aşağıda, geçit kapalı, şalter sol, lazerler açık.

## Çözüm (kare; testler koşula kadar bekler)
- Tur 1 → klon A (PlakaA'yı tutar): ~170 kare bekle, sol 6 kare (x=70, plakaya ~171'de basar), ~10 bekle, R. E1 ~172'de kalkar, ~302'de y=340.
- Tur 2 → klon Z: sağ basılı (şalter ~22'de sağa, geçit ~52'de açık, geçit ~63-67'de geçilir), x=900'e ~160'ta varıp bırak, asansör üst (position.y ≤ 390) olunca sol 40 kare (x=700 PlakaB ~333'te basar), ~10 bekle, R.
- Tur 3 → klon Y: Z gibi ama PlakaB'yi geçip sol 80 kare (x=500 PlakaC ~373'te basar). L1'e ~359'da varır (Z kapatmasından 26 kare sonra). ~10 bekle, R.
- Tur 4 (R kapalı "Klon: 3/3"): oyuncu x=900'e gider, asansör üstte olunca sola yürür; L1 ~359'da, L2 ~403'te geçer; kapıya ~458'de (7,6 sn).
Süreler 3,1 / 5,9 / 6,5 / 7,6 sn.

## Atlanamazlık
F2'ye 260 px > 100,9; asansör yalnız PlakaA basılıyken kalkar. Geçit 200 px tavan altına bitişik. Işınlar y 180..340 tam kesintisiz; plaka-ışın arası 100+ px. F1'den zıplayanın başı en çok y=451 (Kat2 alt kenarı 400 altı). F2 koridor payı: zıplayan baş tavana 11 px kala.

## 3 klon gereği
A F2'ye çıkamaz (plakayı bırakırsa E1 iner); Z ≠ Y (Y, PlakaC'ye ancak L1 kapalıyken varır; Z bırakırsa L1 açılır); oyuncu L2'yi geçerken Y tutmak zorunda. Roller paylaştırılamaz → `max_klon=3`, pay yok.

## Klon altı / kilitlenme
A x≈70, Z x=700, Y x=500; hiçbiri asansör kolonunda (x 840..960) değil. Yanlış kayıtta "Baştan başla".

## Başarısızlık senaryoları
1. Klonsuz: E1 inik, F2'ye çıkılamaz.
2. Yalnız A: PlakaB'yi kendisi tutar, L1'e girince ölür.
3. A+Z (Y yok): L2'de ölür.
4. A erken basar (~40): E1 yukarıda, binilemez, bitmez.
5. Z yanlış (x=640'ta durur): L1 açık, ölür.
6. Şalter çevrilmez (zıplayarak geçilir): geçit kapalı, bitmez.
7. Y L1'i Z basmadan geçer: ölür.

## Riskler
A'nın basma anı (erken olursa E1 yukarıda kalır); E1-Kat2 2 px boşluk (takılırsa Kat2 sağ kenarı 836); geçit üstü Kat2 içinde saklanır (grafikte örtülmeli); F1'deki herkes şalteri çevirebilir (bilinçli).

## Harita
`yol = res://scenes/bolumler/bolum_7.tscn`, `konum = Vector2(850, 410)`, `onceki = res://scenes/bolumler/bolum_6.tscn`.
