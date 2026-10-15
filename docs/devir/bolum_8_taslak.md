# Bölüm 8 taslağı (FİNAL): "Zaman Kulesi" (`scenes/bolumler/bolum_8.tscn`)
(Tasarımcı çıktısı; Aşama 2'de onaysız uygulama kullanıcı kararı.)

Fikir: üç katlı spiral (F1 kısa sağa, F2 uzun sağa, tek yönlü basamaklı kule ile F3, F3'te SOLA koşu). Nesneler: plaka x2, asansör, şalter, geçit, lazer x3, tek yönlü x3, kapı. Çözüm tam 3 klon: A, C, B.
Sabitler: 28x48, HIZ 300 (5 px/kare), zıplama -520, g 1400; tepe 96,5/~100,9. Asansör/geçit 120 px/sn, `position.y` merkez (üst yüzey 10 px yukarıda). Şalter alanları SolAlan x -40..0, SagAlan x 0..40, y -48..0; sol yarı yalnız yon>0 ile SAĞA, sağ yarı yalnız yon<0 ile SOLA çevirir. Tek yönlü 120x12 (üst yüzey = merkez-6). Zemin yüzeyi 600, Tavan (576,20) 1152x40. Tüm klonlar oyuncunun başlangıç konumunda doğar.

## Kat planı (yüzeyler: F1=600, F2=400, F3=200)
F1 koridor y 440..600 (oyuncu E1 üstünde doğar, E1 x 40..160); K2 x 162..1152 y 400..440 (F2 yüzeyi 400, E1 ile 2 px boşluk); F2 koridor y 240..400; K3 x 0..700 y 200..240 (F3 yüzeyi 200); F3 koridor y 40..200; kule x 700..900 (a, b basamakları F2'den K3'e).
Yol: E1 ile F2 → sağa koş (L1) → x≈680'de zıpla: a → b → K3 (b'den 60 px) → F3'te SOLA: sekmenin altından, G (şalter SAĞda açar), L_L (şalter SOLda kapanır), L3 (PlakaA kapatır), kapı.

## Nesneler (merkez)
| Düğüm | Tür | Konum | Ayrıntı |
|---|---|---|---|
| Zemin | StaticBody2D | (576,620) | 1152x40 |
| K2 | StaticBody2D | (657,420) | 990x40 (x 162..1152, y 400..440) |
| K3 | StaticBody2D | (350,220) | 700x40 (x 0..700, y 200..240) |
| Tavan | StaticBody2D | (576,20) | 1152x40 |
| Basamak1 (a) | scenes/tek_yonlu.tscn | (840,336) | üst 330, x 780..900 |
| Basamak2 (b) | scenes/tek_yonlu.tscn | (760,266) | üst 260, x 700..820 |
| Sekme | scenes/tek_yonlu.tscn | (450,126) | üst 120, x 390..510 |
| PlakaA | basinc_plakasi | (260,592) | 60x16, E1 + Lazer3 |
| PlakaC | basinc_plakasi | (900,592) | 60x16 (K2 altı), Lazer1 |
| Salter | scenes/salter.tscn | (450,120) | baslangic_sagda=false; alan y 72..120 |
| Asansor | asansor.gd | (100,610) | 120x20, plaka=../PlakaA, yukseklik=200 (üst yüzey 400), x 40..160 |
| Gecit | scenes/gecit.tscn | (320,140) | 20x200 (y 40..240), kayma_yonu=(0,-1), kayma_mesafe=100, hiz=120, tetikleyici_yollari=[../Salter], acik_taraf_sag=true |
| Lazer1 | scenes/lazer.tscn | (560,240) | yon=(0,1), uzunluk=160 (y 240..400), tetikleyici_yollari=[../PlakaC], tetik_aktifken_kapali=true |
| Lazer2 (L_L) | scenes/lazer.tscn | (250,40) | yon=(0,1), uzunluk=160 (y 40..200), tetikleyici_yollari=[../Salter], acik_taraf_sag=false, tetik_aktifken_kapali=true |
| Lazer3 | scenes/lazer.tscn | (190,40) | yon=(0,1), uzunluk=160, tetikleyici_yollari=[../PlakaA], tetik_aktifken_kapali=true |
| Kapi | kapi.gd Area2D | (80,176) | 36x48, K3 üstünde |
| Oyuncu | oyuncu.tscn | (100,570) | |
| Bilgi | Label | (16,12)-(600,40) | |

`max_klon = 3`. Ağaç sırası: Zemin, K2, K3, Tavan, Basamak1, Basamak2, Sekme, PlakaA, PlakaC, Salter, Asansor, Gecit, Lazer1, Lazer2, Lazer3, Kapi, Oyuncu, Bilgi. Export kalıpları bolum_4/5/6/7.tscn'den. Başlangıç: E1 aşağıda, G kapalı, şalter SOL (L_L KAPALI), L1 ve L3 açık.

## Roller
- A "taşıyıcı": PlakaA'yı tüm tur tutar (E1 yukarıda, L3 kapalı).
- C "uzak plaka": PlakaC'yi tutar (L1 kapalı).
- B "şalter operatörü": E1 + kule ile F3'e çıkar, sekmeye zıplar, şalteri SAĞA sonra SOLA çevirir.

## Çözüm (kare; testler koşula kadar bekler)
- Tur 1 → A: sağ 32 kare (x=260), R (~0,6 sn).
- Tur 2 → C: sağ basılı, x≈900'e ~152'de plakaya basar; ~10 bekle, R (~2,7 sn). (C E1'den ~15'te iner; E1 ~25'te kalkar.)
- Tur 3 → B: E1 üstünde dur (E1.position.y ≤ 410 olunca sağa). L1'e ~214 (C ~153'te kapatmıştı). x≈680'de (pencere 624..716) zıpla+sağ → a (x≈850). a'da zıpla+SOL → b (x≈714, K3 duvarına dayanır). Hemen zıpla+SOL → K3'e (~345, x≈580). Sola x≈480'e, dur, düz yukarı zıpla (sekmeden geçer, sekmede ~397). Sola 4 kare (SolAlan), sağa 1 kare → şalter SAĞA (~402; G açılır, L_L AÇIK). Bekle; ~470'te sola 1 kare → şalter SOLA (G kapanır, L_L kapanır ~471). R (~8,0 sn).
- Tur 4 (R kapalı "Klon: 3/3"): oyuncu aynı yolu yapar, K3'te sola basılı: sekmenin ALTINDAN yürür, G'ye ~392'de dayanır, G ~446'da açılır, ~456'da geçer; x≈276'da (L_L'den 9 px önce) durur, L_L ~471'de kapanınca geçer, kapıya ~505 (8,4 sn). Oyuncu şalter alanına (y 72..120) girmez.
Süreler ≈ 0,6 / 2,7 / 8,0 / 8,4 sn (≤600 kare).

## Atlanamazlık
F2'ye 200 px > 100,9 (E1 yalnız PlakaA basılıyken); F3'e F2'den 200, a→K3 130 > 100,9: yalnız a-b-K3 zinciri (her adım ≤70). Işınlar koridoru tam kapatır, plaka-ışın arası 100+ px. G koridoru tamamen doldurur (tavana bitişik). Baş payları: zeminden zıplayan baş ≥451 (K2 alt kenarı 440, 11 px); F2'den ≥251 (K3 alt 240); a üstünde 282 (b alt 272).

## 3 klon gereği
A olmadan E1 inik / A ayrılırsa E1 iner ve L3 açılır. L1 ~214'te kapalı olmalı, PlakaC F1'de, B o sırada F2'de, A bağlı → C zorunlu. Şalteri yalnız F3'e çıkan çevirebilir → B zorunlu. 2 klon yetmez.

## Klon altı / kilitlenme
A (260,570), C (900,570), B sekmede; hiçbiri E1 kolonunda (x 40..160) veya G bölgesinde değil. Yanlış kayıtta "Baştan başla".

## Başarısızlık senaryoları
1. Klonsuz: E1 inik, bitmez.
2. Yalnız A (C yok): ~214'te L1'de ölür.
3. A+C (B yok): G kapalı (şalter SOL); oyuncu şalteri çevirse G açılır ama L_L açık kalır, ölür veya bitmez.
4. B şalteri çok erken SOLA çevirir: G kapanır, bitmez.
5. C yanlış yerde (x≈840): L1 açık, ölür.
6. A plakadan ayrılır: E1 iner, L3 açılır, ölür.
7. Birinci zıplama erken/geç: a'ya inilmez, F2'ye düşer (ölüm yok).

## Riskler
3. zıplama köşede 0-2 kare takılabilir (b'yi 5 px yukarı al: üst 255, veya K3 sağ kenarı 698); sekme payı 16,5/20,9 (sorun olursa üst 124); b sol ucu K3'e bitişik (takılırsa b x 702..822); G tepesi ekran dışına kayar (grafikte örtülmeli).

## Harita
`yol = res://scenes/bolumler/bolum_8.tscn`, `konum = Vector2(740, 450)`, `onceki = res://scenes/bolumler/bolum_7.tscn`. Hover etiketi Bölüm 4 altıgeniyle çakışırsa alternatif (760,445).
