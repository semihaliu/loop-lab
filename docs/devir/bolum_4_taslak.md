# Bölüm 4 taslağı: "Kule" (`scenes/bolumler/bolum_4.tscn`)
(Tasarımcı çıktısı; Aşama 2'de onaysız uygulama kullanıcı kararıdır.)

Öğretilen fikir: tek yönlü platform (aşağıdan zıplayıp geçilir, üstüne çıkılır; üstten düşen üstünde kalır). 3 katlı dikey yapı, 3 klon zinciri, lazer yok. Nesneler: plaka, asansör, tek yönlü platform, kapı.
Sabitler: 28x48, HIZ 300 (5 px/kare), zıplama -520, yerçekimi 1400. Zıplama tepesi: sürekli 96,5 px; kare modeli ~100,9 px. Erişilebilir yükseklik ≤70, erişilemez ≥120 (tasarım iki modelde de güvenli). Düşme(n)=0,1944·n(n+1): n=24 → 116,7 px. Asansör hızı varsayılan 120 px/sn (2 px/kare). Zemin yüzeyi y=600, oyuncu (100,570).

## Kat planı (yüzeyler: F1=600, F2=360, F3=200)
- F1 koridoru y 400..600; F2 koridoru y 240..360; F3 balkon koridoru y 40..200.
- F2 döşemesi y 360..400, yalnız x 400..960 (x 960..1152 açık: K'nın üstü). E1 (x 280..400) üstünde yalnız F3 döşemesi (y 200..240) vardır.
- F3 döşemesi: F3Sol x 0..700, F3Sag x 820..1152 (E2 boşluğu 700..820).

## Nesneler (merkez konumları)
| Düğüm | Tür | Konum | Ayrıntı |
|---|---|---|---|
| Zemin | StaticBody2D | (576,620) | 1152x40 |
| F2 | StaticBody2D | (680,380) | 560x40 (x 400..960, y 360..400) |
| F3Sol | StaticBody2D | (350,220) | 700x40 |
| F3Sag | StaticBody2D | (986,220) | 332x40 (x 820..1152) |
| Tavan | StaticBody2D | (576,20) | 1152x40 |
| PA | scenes/tek_yonlu.tscn | (660,476) | 120x12, üst y=470, x 600..720 |
| K | scenes/tek_yonlu.tscn | (1070,476) | 120x12, üst y=470, x 1010..1130 |
| Plaka0 | basinc_plakasi | (200,592) | 60x16 zeminde |
| PlakaA | basinc_plakasi | (680,462) | 60x16 PA üstünde |
| PlakaC | basinc_plakasi | (1070,462) | 60x16 K üstünde |
| Asansor0 | asansor.gd | (580,610) | 120x20, plaka=../Plaka0, yukseklik=60 (üst yüzey y=540), x 520..640 |
| Asansor1 | asansor.gd | (340,610) | plaka=../PlakaA, yukseklik=240 (üst yüzey y=360), x 280..400 |
| Asansor2 | asansor.gd | (760,370) | plaka=../PlakaC, yukseklik=160 (üst yüzey y=200), x 700..820 |
| Kapi | kapi.gd Area2D | (960,176) | 36x48, F3Sag üstünde |
| Oyuncu | oyuncu.tscn | (100,570) | |
| Bilgi | Label | (16,12)-(600,40) | |

`max_klon = 3`. Ağaç sırası: Zemin, F2, F3Sol, F3Sag, Tavan, PA, K, Plaka0, PlakaA, PlakaC, Asansor0, Asansor1, Asansor2, Kapi, Oyuncu, Bilgi. Asansörlerin export alanları ve plaka yolları mevcut bolum_2.tscn'deki asansör kalıbına göre ayarlanır. Eşleme: P_0→E0, P_a→E1, P_c→E2. Şalter/geçit/lazer yok.

## Çözüm (kare = 1/60 sn; hedef kareler, testler "koşula kadar bekle" kullanmalı)
- Tur 1 → klon A0 (Plaka0'ı tutar): sağ 20 kare (x=200), 10 kare bekle, R (~0,5 sn). E0 yukarıda kalır.
- Tur 2 → klon A (PlakaA'yı tutar): sağ 68 kare (x=440), zıpla, sağı 20 kare daha (E0 üstüne iner, ~kare 105); sağ 16 kare (x=620, ~121), zıpla: PA'nın altından yükselip içinden geçer ve ~147'de PA üstüne iner; sağ 12 kare (x=680), 10 kare bekle, R (~2,8 sn). E1 ~151'de yükselir, ~271'de y=360.
- Tur 3 → klon B (PlakaC'yi tutar): sağ 48 kare (E1'e biner, taşınır), tepede sağ basılı ~127 kare (x 340→974, F2'nin sağ ucundan düşer), düşerken sağ basılı, K üstüne iner (~422), PlakaC'ye değer, R (~7,3 sn). E2 ~423'te yükselir, ~503'te y=200.
- Tur 4 (R kapalı "Klon: 3/3"): sağ 48 kare (E1), tepede (~271) F2'de sağa 84 kare yürü (E2 üstü x=760), E2 oyuncuyu ~503'te y=200'e taşır, sağa 34 kare, ~kare 540'ta (9,0 sn) kapıya değer.
Süreler 0,5 / 2,8 / 7,3 / 9,0 sn (≤10 sn). Beklemeler E1'de ~100, E2'de ~65 kare.

## Atlanamazlık
PA'ya zeminden 130 px > 100,9; K'ya zeminden 130 px (+ yatay erim yetmez); F2'ye zeminden/E0 üstünden E1 gerekir; F3'e F2'den 160 px > 100,9, E2 gerekir. E0 yukarıdayken altından geçilmez (40 px < 48), üstünden geçilir.

## 3 klon gereği
A, PA'ya yalnız E0 yukarıdayken çıkar: E0'ı tutan A0 şart. Son turda E1 ve E2 aynı anda yukarıda olmalı: A ve B. P_c yalnız F2'den düşerek erişilir (F2'ye E1 gerekir, A tutuyor). Birleştirilemez. `max_klon = 3` pay bırakmaz.

## Klon asansör altında kilitlenme
A0 (200,570), A PA üstü (680,~446), B K üstü: hiçbiri bir asansörün altında değil.

## Başarısızlık senaryoları
1. Klonsuz, zeminden PA'ya zıplama: ayak y<470 olmaz; P_a basılmaz; bölüm bitmez. K altında ayak y min ≥ 499.
2. Yalnız A0: oyuncu E0 ile PA'ya çıkar, P_a basar, E1 yükselir ama oyuncu üstünde değil; bölüm bitmez.
3. Yalnız A (A0 yok): PA'ya ulaşılmaz, P_a basılmaz.
4. A0+A (2 klon) ve oyuncu F2'den K'ya düşer: K'dan F2'ye zıplayıp çıkamaz (110 px), E2'ye binemez, bölüm bitmez.
5. B yön hatası: sola yürür, P_c basılmaz, bölüm bitmez.
6. Tek yönlü platform: yan yüzden yürünebilir; 70 px aşağıdan çıkış ~15 karede üstüne oturur.

## Riskler
Kare tepesi 100,9 > 96,5: gerçek fizikte ölçülmeli; olmazsa PA/K 20 px alçaltılır (üst y=480). Zor: 3 klon, sıfır pay.

## Harita
`yol = res://scenes/bolumler/bolum_4.tscn`, `konum = Vector2(700, 530)`, `onceki = res://scenes/bolumler/bolum_3.tscn`.

---
# REVİZYON 1 (ana oturum, test bulgusuna göre) — yukarıdaki tablo ve sayıların YERİNE geçer
Bulgu: zeminden zıplayan karakterin başı (ayak min y=499 → baş y=451) plakanın (y 454..470) alanına girdi ve plakayı basılı saydı. Düzeltme: platform üst yüzleri y=445'e yükseltildi (baş 451 > 445; plaka platformun üstünde, altına sarkmaz), bunun getirdiği boşluk farkı F2'yi yükselterek ve E0'ı yükselterek dengelendi.
- **PA**: konum (660,451) → üst yüzey y=445 (x 600..720). **K**: konum (1070,451) → üst y=445 (x 1010..1130).
- **PlakaA** (680,437), **PlakaC** (1070,437) (60x16, platform üstünde; alt kenar 445).
- **Asansor0**: yukseklik=80 (üst yüzey y=520). (Konum/plaka aynı.) Not: E0 yukarıdayken altında 60 px boşluk var; altından yürünebilir (çözümü etkilemez).
- **F2** yükseltildi: konum (680,350), 560x40 → yüzey y=330 (x 400..960). F2 döşemesi y 330..370.
- **Asansor1**: yukseklik=270 (üst yüzey y=330).
- **Asansor2**: konum (760,340) (F2 yüzeyi 330 → üst yüzey 330), yukseklik=130 (üst yüzey y=200).
- F3Sol/F3Sag/Tavan/Kapi/Oyuncu/Zemin/Plaka0 aynı.
- Yeni yükseklik farkları: E0 üstü (520) → PA üstü (445) = 75 px (erişilir, ≤100). Zeminden PA/K = 155 (>100,9, erişilmez) ve zıplayan başı plakaya giremez. K → F2 = 115 px (>100,9: çıkılamaz, pay ~14). F2 → K düşüşü 115 px (~23 kare). F2 → F3 = 130 (E2 gerekir). F2 koridoru y 240..330 (90 px).
- Testler: eşikler buna göre ("ayak y < 445 olmaz", "E1 üst 330", "E2 üst 200", "K'dan zıplayan ayak y min ≥ 330+margin" vb.); atlanamazlık: zeminden zıplayan plakaya HİÇ basmamalı (P_a/P_c asla basılı olmamalı).
- Çözüm kareleri değişebilir; koşullu bekleme betikleri kullanılır. Süre ≤10 sn kuralı korunur.
