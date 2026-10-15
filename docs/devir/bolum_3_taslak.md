# Bölüm 3 taslağı: "Lazer tanıtımı" (`scenes/bolumler/bolum_3.tscn`)
(Tasarımcı çıktısı; kullanıcı Aşama 2'de onaysız uygulamayı onayladı.)

Öğretilen fikir: plaka lazeri kapatır, klon plakada bekleyerek yolu açık tutar. Nesneler: plaka, lazer, hedef kapısı.
Sabitler: karakter 28x48, HIZ 300 (5 px/kare), zıplama -520, yerçekimi 1400. Zemin yüzeyi y=600 (Zemin konum (576,620), 1152x40, Bölüm 2 ile aynı). Oyuncu başlangıcı (100,570).

## Kat planı (tek kat, koridor yüksekliği 200: y 400..600)
Tavan y 100..400. Işınlar zeminden tavana (y 400..600) tam kapatır; aşılamaz.

## Nesneler
| Düğüm | Tür | Konum | Ayrıntı |
|---|---|---|---|
| Zemin | StaticBody2D | (576,620) | 1152x40 |
| Tavan | StaticBody2D | (576,250) | 1152x300 (y 100..400), katman 1 |
| Plaka1 | basinc_plakasi | (260,592) | 60x16 |
| Plaka2 | basinc_plakasi | (640,592) | 60x16 |
| Lazer1 | scenes/lazer.tscn | (480,400) | yon=(0,1), uzunluk=200, tetikleyici_yollari=[../Plaka1], tetik_aktifken_kapali=true |
| Lazer2 | scenes/lazer.tscn | (860,400) | yon=(0,1), uzunluk=200, tetikleyici_yollari=[../Plaka2], tetik_aktifken_kapali=true |
| Kapi | kapi.gd Area2D | (1060,576) | 36x48 |
| Oyuncu | oyuncu.tscn | (100,570) | |
| Bilgi | Label | (16,12)-(600,40) | |

`max_klon = 2`. Ağaç sırası: Zemin, Tavan, Plaka1, Plaka2, Lazer1, Lazer2, Kapi, Oyuncu, Bilgi (bolum_2 ile aynı kalıp; sınır duvarlarını bolum.gd kurar).

## Çözüm (kare = 1/60 sn, zıplama yok)
- Tur 1 (Klon A, P1'i tutar): sağ 32 kare (x 100→260), ~28 kare bekle, R.
- Tur 2 (Klon B, P2'yi tutar): A ~24. karede P1'e değer, L1 kapanır; sağ 108 kare (x→640), ~30 kare bekle, R. L1'e varış kare ~73, kapanma ~26 (pay ~47 kare).
- Tur 3: sağ tuş basılı tut; B ~100. karede P2'ye değer, L2 kapanır; oyuncu L2'ye kare ~149'da varır (pay ~48), kapıya ~186'da (3,1 sn) değer.
Süreler 1,0 / 2,3 / 3,1 sn.

## Atlanamazlık / klon gereği
0 klonla L1 açık, oyuncu ölür. 1 klonla: P2'yi tutacak klonun kaydı sırasında P1'i tutan başka karakter olmalı; yoksa klon L1'de ölür (kayıt atılır). 2 klon gerekir ve yeter.

## Kilitlenme
Oyuncu ışında ölürse tur yeniden başlar (klon sayısı değişmez). Yanlış kaydedilmiş klon varsa tek çıkış "Baştan başla" (tam sıfırlama). Fiziksel kilitlenme yok.

## Başarısızlık senaryoları
1. Klonsuz sağa yürüyüş: L1'de ölür (~73. kare), Kayitlar.turlar değişmez, bölüm bitmez.
2. Yalnız A: tur 2'de oyuncu L2'ye yürür, ~149'da ölür.
3. A plakada değil (20 kare sağ, x=200): tur 2'de L1'de ölür.
4. Ölü klon etkisizliği: zorlama testi (normal akışta klon ölmez).

## Harita
`yol = res://scenes/bolumler/bolum_3.tscn`, `konum = Vector2(1010, 440)`, `onceki = res://scenes/bolumler/bolum_2.tscn`.
