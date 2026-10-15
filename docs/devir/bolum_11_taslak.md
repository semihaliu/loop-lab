> **UYARI (2026-10-15):** Bu taslağın gövdesi ilk tasarımı anlatır. PlakaPB sonradan (698,160) 60x32'ye taşındı (havada, Z2 uçuşunda 14 karelik darbe); güncel nesne konumu, çözüm ve kısayol sonuçları için en alttaki **Güncelleme** bölümü geçerlidir.

# Bölüm 11 taslağı: "Yay" (`scenes/bolumler/bolum_11.tscn`)
(Tasarımcı çıktısı; Aşama C'de onaysız uygulama kullanıcı kararı. NOT: tanıtım düzeyinde; kullanıcıya özet notunda "belirgin zor" ölçütüne tam uymadığı belirtilecek.)

Yeni fikir: YAYLI ZIPLATICI (asansörsüz kat atlama). Nesneler: zıplatıcı x2, plaka x2, lazer x2 (yan yana), tek yönlü platform, kapı. Asansör/geçit/şalter/kutu/bant YOK. `max_klon = 2` (tam 2 klon).
Sabitler: 28x48, HIZ 300 (5 px/kare), zıplama tepe 96,5 (kare ~100,9), g 1400; zıplatıcı `firlatma_hizi` 820 (varsayılan), ölçülen tepe 247 px; tetik bölgesi karakter merkezi x_p ± 44; yalnız velocity.y ≥ 0 iken. Fırlatma kare modeli R(K)=(820K-11,667K(K-1))/60 px: K=24 → 220,7; K=36 tepe 247; K=47 → 221,9; havada ~71 kare. Zemin yüzeyi y=600; oyuncu (60,576).

## Kat planı
F1 odası x 0..420 (sağ duvar Kat2 sol yüzü x=420); F2 yüzeyi y=380 (x 420..1152); F2 açık hava x 420..760; Kat3 x 760..1152, y 160..280 (F3 yüzü y=160); cep: x 760..1152, y 280..380 (100 px koridor). Raf: tek yönlü, üst y=420, x 120..240.

## Nesneler (merkez)
| Düğüm | Tür | Konum | Ayrıntı |
|---|---|---|---|
| Zemin | StaticBody2D | (576,620) | 1152x40 |
| Tavan | StaticBody2D | (576,30) | 1152x60 (y 0..60) |
| Kat2 | StaticBody2D | (786,490) | 732x220 (x 420..1152, y 380..600) |
| Kat3 | StaticBody2D | (956,220) | 392x120 (x 760..1152, y 160..280) |
| Raf | scenes/tek_yonlu.tscn | (180,426) | 120x12, üst y=420, x 120..240 |
| PlakaPA | basinc_plakasi | (180,412) | 60x16 (Raf üstünde), Lazer1'i kapatır |
| PlakaPB | basinc_plakasi | (950,152) | 60x16 (F3 üstünde, x 920..980), Lazer2'yi kapatır |
| Ziplatici1 (Z1) | scenes/yayli_ziplatici.tscn | (340,594) | firlatma_hizi=820, yüzey y=600, bölge x 310..370 |
| Ziplatici2 (Z2) | scenes/yayli_ziplatici.tscn | (640,374) | firlatma_hizi=820, yüzey y=380, bölge x 610..670 |
| Lazer1 | scenes/lazer.tscn | (880,280) | yon=(0,1), uzunluk=100 (x 877..883), tetikleyici_yollari=[../PlakaPA], tetik_aktifken_kapali=true |
| Lazer2 | scenes/lazer.tscn | (886,280) | yon=(0,1), uzunluk=100 (x 883..889), tetikleyici_yollari=[../PlakaPB], tetik_aktifken_kapali=true |
| Kapi | kapi.gd Area2D | (1100,356) | 36x48 |
| Oyuncu | oyuncu.tscn | (60,576) | |
| Bilgi | Label | (16,12)-(600,40) | |

Ağaç sırası: Zemin, Tavan, Kat2, Kat3, Raf, PlakaPA, PlakaPB, Ziplatici1, Ziplatici2, Lazer1, Lazer2, Kapi, Oyuncu, Bilgi. Her StaticBody2D'de `Gorsel` ColorRect. Başlangıç: iki lazer açık. Zıplatıcı sahnesi ve export adları scripts/yayli_ziplatici.gd'den.

## Roller
A: Z1'den SOLA fırlayıp Raf üstündeki PlakaPA'ya iner ve kalır (L1 kapalı). B: Z1 ve Z2'yi art arda kullanıp F3'e çıkar, PlakaPB'de kalır (L2 kapalı). Oyuncu: Z1 ile F2'ye çıkar, Z2'yi zıplayarak atlar, cebe girer, iki ışın kapanınca geçip kapıya varır.

## Çözüm (testler "koşula kadar bekle")
Z1 tetiği: gövde merkezi x>296 (kare 47'de x=300, pad kare 48).
- Tur 1 → A: `sag` 48 kare (x=300), `sol` 24 kare (x=180), boş girdi; K=55'te Raf/PlakaPA üstüne iner (kabul penceresi n ∈ [15,32]); ~10 bekle, R.
- Tur 2 → B: `sag` basılı sürekli; kare 48 Z1 fırlatır; K=24'te Kat2 köşesine ayak 0,7 px pay; kare ~95 F2'ye iner (x≈526); x>596'da (kare ~111) Z2 fırlatır; kare ~158 F3'e iner (x≈846); x>906'da PlakaPB basılı; x≈920'de dur, ~10 bekle, R.
- Tur 3 (R kapalı "Klon: 2/2"): `sag` basılı; F2'ye iner (x≈526); `sag`+`zipla` ile Z2'yi atla (kalkış x0≈540, x0 ∈ [~470,596]); cebe düş (x≈760); cebi x≈855'e kadar yürü ve DUR; L1 ve L2 kapalı olana kadar bekle (L2 ~kare 172); sonra `sag` ile geç, kapıya (x 1100).
Süreler ≈ 1,9 / 3,1 / 3,8 sn (≤600 kare).

## Atlanamazlık
Cep koridoru 100 px, ışınlar y 280..380 tam yükseklik, tavan Kat3 alt kenarı 280'e bitişik. F1→F2 duvar 220 > 100,9. Raf zeminden 180 > 100,9. F3'e F2'den 220 > 100,9, yalnız Z2. Z1 fırlatması F3'e erişemez (ayak y=353 > 160). Kat3 dolu, cebe yalnız F2 yüzeyinden x=760'ta girilir.

## KISAYOL TARAMASI (gozden-gecirici bağımsız kontrol edecek)
Klonsuz: ışına varınca ölür. Tek klon (A veya B): bir lazer açık kalır; röle (PA→PB) çalışmaz (ışınlar bitişik, ~6 kare ikisi birden kapalı olmalı, PA→PB >100 kare). Oyuncunun kendi plakayı tutması: ışının önünde olamaz. Zıplatıcıyla ışın/duvar aşma yok. Kutu yok. Minimum 2 klon.

## Kilitlenme / klon altı
Asansör yok; klonlar sabit yerde (A Raf üstünde, B F3 yüzünde). Klon Z1/Z2 bölgesinde biterse sekmeye devam eder, plaka tutmaz (kayıt hatası). Yanlış klonda "Baştan başla".

## Başarısızlık senaryoları
1. Klonsuz: cebe girip L1'e varınca ölür. 2. Yalnız A: L2'de ölür. 3. Yalnız B: L1'de ölür. 4. A çok uzun `sol` (n≥36): Raf'ı kaçırır, L1 açık. 5. Oyuncu x0<470'te zıplar: Z2 üstüne iner, F3'e fırlar (ölüm yok). 6. Oyuncu B'yi beklemeden ışına koşar: L2 açıkken ölür.

## Riskler
K=24'te Kat2 köşesine 0,7 px pay; PlakaPA'ya yükselirken 2 karelik titreşim (zararsız); cep girişi sürtünmesi (x0>556'da baş payı 10 px); iniş sapması Z1 x 526±6, Z2 x 846±6 (kayıt deterministik); yan yana ışınların görünümü (Gorunum 12 px).

## Harita
`yol = res://scenes/bolumler/bolum_11.tscn`, `konum = Vector2(850, 175)`, `onceki = res://scenes/bolumler/bolum_10.tscn`.

## Güncelleme 2026-10-15 (tasarımcı önerisi, test yazarı ölçümü): PlakaPB havaya taşındı
- Değişen tek nesne: PlakaPB (950,152) 60x16 -> (698,160) 60x32 (x 668..728, y 144..176; Z2 fırlatma yörüngesinde havada, F3 üstünde durarak basılamaz).
- Yeni çözüm: A aynı (sag 48, sol n, PlakaPA'da kal, R). B: kısa bekle (>=32 kare), `sag` basılı sürekli (Z1 -> F2 -> Z2), uçuşta PlakaPB'den 14 kare geçer (L2 14 kare kapanır), F3'e iner, birkaç kare yürür, R. Oyuncu: Z1 -> F2, Z2 üstünden zıpla+sag, cebe in, x~855'te DUR (L1 A ile kapalı, L2 açık), B'nin uçuşu L2'yi kapatınca hemen `sag` ile ışını geç, kapıya. Eski çözüm (B'yi plakada durdurup L2'yi kalıcı kapatma) artık yok.
- Ölçülen pencereler: A sol n in [16..32] (değişmedi); B başlangıç gecikmesi >= 32 kare (0,20,30,31 başarısız; 32,33,38,40,60,100 başarılı; üst sınır yok, oyuncu bekler); oyuncu geçiş gecikmesi (L2 kapandıktan sonra) yalnız 0..3 kare (>=4 ölür; ışın penceresi tasarımcı tahmini 0-6 idi); oyuncu zıplama x0 in [510..585] (B gecikmesi 40 iken; x0 <= 505 oyuncu cepe geç varır, x0 >= 590 Z2 üstüne iner). Uçuş darbesi: doğal ardışık 14 kare, F3 kenarından düşüş 17, F3'te zıplama/zıpla+sol en çok 10, idle 0; en uzunu 17 < 20.
