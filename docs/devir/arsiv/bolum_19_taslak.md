# Bölüm 19 taslağı: Karşı Ağırlık
(Tasarımcı çıktısı; gece otonom üretim, kullanıcı onaylı; sayılar tahmindir, ölçümle düzeltilecek.)

> **ÖLÇÜM NOTU (2026-10-16):** Bu taslağın sayıları tahmindi; ölçümler `docs/sorunlar.md` ve `_b19_*` testlerindedir. Güncel: 4 tur, 3 klon, kareler 179/249/458 + oyuncu 471 (600'e 129 kare pay); L1 biniş x 186..294 (~112 px), L2 biniş x 544..672 (~132 px, taslak 68 px); L2'ye geç biniş: tepede en çok 32 kare bekleme (taslak ±7); C_B odada PlakaB'ye geç basış payı 16 kare (80 px); raf S 871..966; fitil payı 64 kare; canlı/klon farkı 0,00 px. Min klon 3 doğrulandı (49 çift x 2 strateji, röle/park denemeleri), kısayol yok.


> **UYARI:** Bütün kare/piksel sayıları TAHMİNDİR (60 kare/sn, HIZ 5 px/kare; ölçüm yapılmadı). Bölüm 12-14 deneyimi: taslak sayıları hep ölçümle değişti; Bölüm 10/13/14'te canlı/klon dikiş ayrışması ~11,67 px görüldü (docs/sorunlar.md). Payların hepsi >= 12 px dikiş payıyla ve ayrışma düşülerek verildi. Harita konumu: `harita agent atayacak` (docs/devir/harita_yerlesim.md'de 19 için (360,510) ayrılmış).

(`scenes/bolumler/bolum_19.tscn`, `max_klon = 3`, **çözüm tam 3 klon**.) Sabitler `player.gd` (HIZ 5 px/kare, zıplama tepesi 96,5 / kare ~100,9, g 1400, `ASAGI_DUSME_KARE` 12; gövde 28x48), `asansor.gd` (yukseklik/hiz export, plakayla çıkar, inerken altında karakter varsa durur), `gecit.gd` (20x200, 2 px/kare), `lazer.gd` (6 px), `basinc_plakasi.gd`, `tek_yonlu.tscn` ve Bölüm 15-18 taslaklarından okundu. Klon kaydı bitince boş girdiyle yerinde bekler (`player.gd` `girdi_al`).

## 1. Fikir ve özet
- **Öğrettiği fikir:** "karşı ağırlık": normal plakaya bağlı asansörü tutan yükselemez; tutucu aşağıda kalır, yükselen yukarı gider. Klon sayısı yükselenlerden değil tutucu sayısından çıkar: üç ayrı tutucu (LazerA/G plakası, asansör plakası, odadaki LazerB plakası). İlk çıkış için zamanlı plaka asansörü (Bölüm 18) tek başına kullanılır.
- Kat yapısı 3 katlı: F1 (y=600), F2 (y=380), F3 (y=160); F1 -> F2 zamanlı plakalı asansör L1, F2 -> F3 normal plakalı asansör L2, F3 -> oda (F2 sağ, kapalı oda) rafta S ile dönüşsüz iniş.
- Nesneler: asansör x2, zamanlı plaka x1, plaka x3 (A, L, B), geçit x1, lazer x2, tek yönlü raf x1, kapı. YOK: kutu, bant, zıplatıcı, şalter, mandal plaka.
- **Min klon 3** (§8). 4 tur: C_A (~185 kare), C_H (~250), C_B (~460), oyuncu (~470); hepsi <= 600 (pay >= 130).
- İç içe: iki ayrı asansör türü, 3 katlı kule, ortak plaka (A hem F2 lazerini hem F3 geçidini kontrol eder), biniş koreografisi (binenler tutucudan ÖNCE asansörde olmalı), kapalı oda.

## 2. Kat planı (F1 koridoru y 420..600 = 180 px; F2 koridoru y 200..380 = 180 px; F3 koridoru y 0..160 = 160 px)
```
y=0   ┌──────────────── BlokF3L (0..540) ─┬ L2 ┬───── F3 (koridor 160) ───────┬── BlokF3R ──┐
y=160 │                                   │tepe│ ▒▒▒ DosemeF3 ▒[G]▒ ·raf(S)· │ 980..1152   │
y=200 ├────────────────────────────────── ┴────┴─────────────────────────────┴─────────────┤
      │ F2   LazerA      L2 kuyusu (540..680)  PlakaL │W2│  ODA: PlakaB LazerB [Kapı]     │
y=380 ├──┐ boşluk ┌──[A]──┴─────┴──────────┐ ╔DosemeB╗ │  ├─────────────────────────────┤
y=420 │DS │160..300│ DosemeA 300..540       │ 680..800 │  │ DosemeR (820..1152)          │
      │ [O]  [L1+ZP]  F1 sol alan 0..350  │ BlokF1 (350..1152, y 420..600)              │
y=600 └─────────────────────────────────────────────────────────────────────────────────┘
       40   170..290 (L1)
```
- F1 sol alan (x 0..350): oyuncu, L1 (x 170..290) ve ZP (asansörün üstünde). BlokF1 (x 350..1152) F1'in kalanını doldurur: F1 başka yere varmaz.
- F2: DosemeSol (x 0..160), L1 kuyusu (160..300), DosemeA (300..540; PlakaA, LazerA), L2 kuyusu (540..680), DosemeB (680..800; PlakaL), duvar W2 (x 800..820, y 200..420), oda (x 820..1152; yalnız raftan).
- F3: L2 tepesinden DosemeF3 (x 680..860) üstünde yürünür, G (x 760), raf (x 860..980), BlokF3R sağda kapatır. Odaya raftan S ile inilir.

## 3. Nesneler (merkez, boyut)
| Düğüm | Tür | Konum | Boyut / parametre |
|---|---|---|---|
| Zemin | StaticBody2D | (576,620) | 1152x40 |
| BlokF1 | StaticBody2D | (751,510) | 802x180 (x 350..1152, y 420..600) |
| DosemeSol | StaticBody2D | (80,400) | 160x40 (x 0..160, üst y=380) |
| DosemeA | StaticBody2D | (420,400) | 240x40 (x 300..540) |
| DosemeB | StaticBody2D | (740,400) | 120x40 (x 680..800) |
| DuvarW2 | StaticBody2D | (810,310) | 20x220 (x 800..820, y 200..420) |
| DosemeR | StaticBody2D | (986,400) | 332x40 (x 820..1152, oda zemini) |
| BlokF3L | StaticBody2D | (270,100) | 540x200 (x 0..540, y 0..200) |
| DosemeF3 | StaticBody2D | (770,180) | 180x40 (x 680..860, üst y=160, alt y=200) |
| BlokF3R | StaticBody2D | (1066,100) | 172x200 (x 980..1152, y 0..200) |
| Raf | tek_yonlu.tscn | (920,166) | 120x12 (x 860..980, üst y=160) |
| Asansor1 (L1) | asansor.gd | (230,610) | 120x20 (x 170..290, üst y=600), `yukseklik=220`, `hiz=120`, `plaka=../PlakaZ` |
| PlakaZ | zamanli_plaka.tscn | (230,592) | 60x16 (x 200..260), `tutma_kare=180` (varsayılan) |
| PlakaA | basinc_plakasi | (380,372) | 60x16 (x 350..410) |
| Asansor2 (L2) | asansor.gd | (610,390) | 120x20 (x 550..670, üst y=380), `yukseklik=220` (tepe y=160), `hiz=120`, `plaka=../PlakaL` |
| PlakaL | basinc_plakasi | (730,372) | 60x16 (x 700..760, DosemeB üstü) |
| PlakaB | basinc_plakasi | (920,372) | 60x16 (x 890..950, odada raf altı) |
| LazerA | lazer.tscn | (470,200) | `yon=(0,1)`, `uzunluk=180` (x 467..473, y 200..380), tetik [../PlakaA], `tetik_aktifken_kapali=true` |
| LazerB | lazer.tscn | (1010,200) | `yon=(0,1)`, `uzunluk=180` (x 1007..1013), tetik [../PlakaB], kapalı=true |
| GecitG | gecit.tscn | (760,60) | 20x200 (x 750..770, y -40..160), `kayma_yonu=(0,-1)`, `kayma_mesafe=100`, `hiz=120`, tetik [../PlakaA] |
| Kapi | kapi.gd Area2D | (1090,356) | 36x48 (x 1072..1108, y 332..380) |
| Oyuncu | oyuncu.tscn | (40,576) | |
| Bilgi | Label | (16,12) | |

**Ağaç sırası:** Zemin, BlokF1, DosemeSol, DosemeA, DosemeB, DuvarW2, DosemeR, BlokF3L, DosemeF3, BlokF3R, Raf, PlakaZ, PlakaA, PlakaL, PlakaB, Asansor1, Asansor2, GecitG, LazerA, LazerB, Kapi, Oyuncu, Bilgi. Başlangıç: asansörler aşağıda, G kapalı, lazerler açık. Güvenlik: kutu yok. Geçit üstü sınır duvarının içinde (y<0 yasak bölge, geçit AnimatableBody kutudan etkilenmez).

## 4. Roller
- **C_A:** L1 ile F2'ye çıkar, PlakaA'da kalır (LazerA kapalı, G açık).
- **C_H ("tutucu"):** L1, LazerA'dan geçer, PlakaL'de kalır (L2 yukarıda tutulur).
- **C_B:** L1, LazerA, L2'ye biner (C_H plakaya basmadan ÖNCE asansörde), F3, G, rafta S, odada PlakaB'de kalır (LazerB kapalı).
- **Oyuncu:** aynı yol (C_B ile birlikte), LazerB'yi geçip kapıya.

## 5. Çözüm (tuş kareleri tahmin; c = gövde merkezi x, c(k)=40+5k)
**Tur 1 (C_A, ~185 kare):** `sag`: c=186'da (k~30) gövde L1'e binmiş ve ZP'ye değiyor; c~230'da (k~38) `sag` BIRAK: L1 ile yükselir (tepe k~140, fitil 180 kare). `sag`: PlakaA'ya c>=336'da (k~162), c~380'de dur, ~15 kare bekle, R.
**Tur 2 (C_H, ~250 kare):** C_A oynar. L1 aynı; LazerA'ya (c=453) k~185'te varılır (C_A plakada k~163'ten beri). L2 kuyusunu c 550..670 üzerinden yürüyüp PlakaL'e c>=686'da (k~232) girer, c~730'da dur; R (asansör boş çıkar).
**Tur 3 (C_B, ~460 kare):** C_A, C_H oynar. L1, LazerA; L2 kuyusunda c~610'da (k~216) `sag` BIRAK: asansörde bekler (C_H plakaya k~232'de basar, L2 kalkar; tepe k~342). `sag`: c=685'ten çıkar, G (c~736..790, açık: C_A plakada) k~367..378; rafta c 874..966 arası (k~404, c=920) `sag` BIRAK, `asagi` bas: odaya iner (k~438), PlakaB'de dur, ~15 kare bekle, R.
**Tur 4 (oyuncu, "Klon: 3/3", R kapalı, ~470 kare):** aynı yol ve kareler; odada LazerB'ye (c=993) k~453'te varılır (C_B plakada k~438'den beri); kapı k~466.

## 6. Zamanlama pencereleri (pay; asansör-zemin dikişi >= 12 px)
| # | Pencere | Pay |
|---|---|---|
| W1 | L1 biniş: `sag` bırakma c aralığı 196..264 (gövde asansör üstünde, uçlardan >= 12 px) | **68 px** (+-34 px = +-6,8 kare) |
| W2 | ZP fitili: plakadan ayrılış ~k38 + 180; L1 tepesi k~140 ve çıkış | **~78 kare** |
| W3 | C_A plakada (k~163) -> LazerA ışınına varış (k~185) | **~22 kare** |
| W4 | L2 biniş: `sag` bırakma c 576..644 (gövde asansör üstünde, uçlardan >= 12 px), C_H'nin plakaya basışından (k~232) önce: doğal bırakış c=610 (k~216); c=656'ya (k~225) kadar | **68 px**, kare payı **~+-7 kare** (geç kalan: asansör ~50 kare daha zıplayarak binilebilir, sonra yetişilmez) |
| W5 | C_H tutuşu: L2 tepesi (k~342) + binenlerin asansörden çıkışı (c>684, k~357) | C_H kayıt sonu yerinde bekler: pay sınırsız |
| W6 | G açık: C_A plakada (k~163) -> G >= 48 px (k~187) -> geçen en erken G'de (k~367) | **~180 kare** |
| W7 | Raf S: gövde tam raf üstünde ve G'nin sağında: c 874..966 | **92 px** (sağ tuş bırakılmalı: +60 px sürüklenme, BlokF3R'ye yaslar) |
| W8 | C_B'nin PlakaB'ye basışı (k~438) -> oyuncunun LazerB ışınına varışı (k~453) | **~15 kare** |
| W9 | Tur süresi: oyuncu ~470 | **~130 kare** (<= 600) |
- Bant ve geçit altı yarış yok; asansör tepede gövde-tepe dikişi (10 px çatlak, gövde 28 px) zorunlu karar değil.

## 7. Atlanamazlık (sahne sayıları)
- **F1 -> F2:** F2 yüzeyi y=380, F1 yüzeyi 600: 220 px > 100,9 (pay 119); tek yol L1.
- **F2 -> F3:** F3 yüzeyi y=160, F2 yüzeyi 380: 220 px > 100,9 (pay 119); tek yol L2. F3 koridoru 160 px: zıplama baş payı 160-48-96,5 = 15,5 px (tavan sınır duvarı y=0).
- **GecitG:** kapalı y -40..160, F3 yüzeyi 160'a bitişik, sınır duvarına gömülü; açıkken y -140..60, boşluk 100 px (gövde 48). Kapalıyken zıplama aşamaz.
- **LazerA:** y 200..380 (DosemeF3/BlokF3L alt kenarı 200, F2 yüzeyi 380). **LazerB:** y 200..380 (oda tavanı BlokF3R 200). Zıplamada baş y>=251 ışın bandı içinde.
- **Oda:** DuvarW2 220 px, tavan BlokF3R/DosemeF3 bitişik; odaya yalnız raf (F3). Odadan F3'e 220 px > 100,9.
- **Kapı:** odada, LazerB'nin sağında.
- **L2 kuyusundan atlama:** F2'den F3'e L2 dışında yol yok (kuyu boşluğu 140 px, tavan açık ama F3 yüzeyi 220 px yukarıda).

## 8. Kısayol taraması (min 3 düşmez)
| Deneme | Sonuç | Neden |
|---|---|---|
| Klonsuz | olmaz | LazerA'da (k~185) ölür |
| 1 klon (C_A) | olmaz | L2 plakası tutulmaz: oyuncu F3'e çıkamaz |
| 2 klon (C_A + C_H) | olmaz | odada PlakaB tutucusu yok: LazerB (k~453) öldürür; oyuncu PlakaB'de kendisi dursa ışına gidemez |
| 2 klon (C_A + C_B) | olmaz | C_B L2 yükselmeden F3'e çıkamaz (kayıt alınamaz: tutucu yok) |
| 2 klon (C_H + C_B) | kayıt alınamaz | LazerA'yı tutan yok: C_H LazerA'da ölür |
| min-1 = 2 klon + oyuncu PlakaL'i tutar | olmaz | oyuncu asansörle çıkamaz |
| Röle: C_A (A -> L) | olmaz | C_A PlakaA'dan ayrılırsa LazerA açılır, ışın plaka sağ kenarından (410) 57 px ileride: ~11 karede ölür; G ayrıca k~378'e kadar PlakaA'yı ister |
| Röle: C_H (L -> B) | olmaz | L2 tepeye çıkınca C_H plakadan ayrılabilir ama F3'e/odaya çıkış yolu yok (asansörü tutan kalmaz, kendisi binemez) |
| Kutu basamağı / kutuyla plaka tutma / zıplatıcı + kutu | uygulanamaz | kutu ve zıplatıcı yok |
| Bant dalgalanması | uygulanamaz | bant yok |
| **Geçit altı park / röle** | min'i düşürmez | G zaten PlakaA'ya bağlı (C_A mıhlanmış); G altında park edip G'yi açık tutmak C_A'nın LazerA görevini (k~185) kaldırmaz; ayrıca oyuncu geçmeden parktan çıkamaz |
| Asansör altı park | min'i düşürmez | tepedeki L2'nin altında park eden karakter asansörü yüksekte tutar ama asansör ancak baş üstünde (y~308) kalır: F3'e 148 px (> 100,9) |
| S ile yeni iniş yolu | yok | tek raf; DosemeF3 üstünde S etkisiz (katı); F2'de tek yönlü yok |
| Lazeri zıplayarak aşma | olmaz | §7 |
| **Zamanlı plakayla röle** | min'i düşürmez | ZP yalnız L1 (ilk çıkış); her geçen kendi asansörünü tutar. ZP'ye klon bırakmak 4. klon ister |
| Mandalla tasarruf | uygulanamaz | mandal plaka yok |
**Min klon 3 kanıtı:** üç plaka üç ayrı yerde, zaman aralıkları: PlakaA [k 185..378] (LazerA ve G), PlakaL [k 232..342] (asansör), PlakaB [k 438..453] (LazerB). A ve L aralıkları kesişir, farklı tutucu. PlakaB'nin tutucusu odadadır; odaya yalnız F3 rafı, F3'e yalnız L2 ile gidilir; L2'nin tutucusu F3'e çıkamaz (asansörü tutarken binemez, bırakınca asansör iner), PlakaA tutucusu ışının solunda mıhlanır (ayrılan ışına varıp ölür). Dolayısıyla B tutucusu, A tutucusu ve L tutucusu birbirinden farklı üç klondur; oyuncu dördüncü. 3 klon şart ve yeter.

## 9. Başarısızlık senaryoları
1. Klonsuz: LazerA'da ölür.
2. Yalnız C_A: oyuncu L2 tabanında bekler, çıkamaz; "Baştan başla" / R.
3. C_A, C_H var, C_B yok: oyuncu odada LazerB'de ölür.
4. L2'de geç biniş (C_H plakaya bastıktan > ~50 kare sonra gelinirse): asansör yukarıda kalır, çıkış yok; tur sonu R ya da "Baştan başla" (kilit, §10).
5. C_A kaydında PlakaA'dan erken ayrılma: LazerA ve G tarafı bozulur; C_H ve C_B ışında ölür veya G'de takılır (kayıt tekrarı).
6. L1'de gövde plakaya basıp asansörde durmadan c>304'e yürürse asansör boş çıkar; ~290 kare kayıp (fitil + iniş), kilit yok.
7. Rafta çok erken S (c<874): DosemeF3 destekler, S etkisiz; tekrar dener.
8. Rafta sağ tuş basılı S: +60 px sürüklenme BlokF3R'ye yaslar (zarar yok); sol tuş basılı: DosemeF3'e kayar, düşmez.
9. Oyuncu C_B'den ~15 kare önce odaya inerse: LazerB açık, ışına girer ölür.

## 10. Kilitlenme analizi
- **L2 geç biniş:** C_H plakada kalıcı; asansör yukarıda sabit. Tur 4'te klon hakkı yok: "Baştan başla" (§12). Tur 3'te R ile atlanabilir.
- Klon asansör altında kalmaz: C_A ve C_H F2'de, C_B F3/odada; L1 (x 170..290) ve L2 (x 550..670) kuyularında kimse beklemez. L1'in altı Zemin (karakter giremez). L2 alt kenarı (y 400) altı boşluk 20 px (karakter giremez).
- Oda dönüşsüz: odadan F3'e yol yok (220 px); oyuncu R ya da "Baştan başla" ile tekrar dener.
- G altında klon bitmez (C_B ve oyuncu geçip raftan iner; C_A ışının solunda).
- Şalter yok.

## 11. S düşme kullanımı ve riskleri
Tek S: raf (c 874..966), düşüş 220 px ~34 kare. Risk: erken S etkisiz; sağ tuş sürükler (zararsız). Odaya iniş dönüşsüz. L2'ye binerken düşmeyen asansör: zıplama gerekmez.

## 12. Geri dönmesi zor kararlar (kullanıcı karar versin)
1. **L2 biniş koreografisi:** asansör tutulduğu sürece yukarıda kalır; geç kalan binemez (tur 4'te "Baştan başla"). Alternatif: tutucu plakayı asansörden uzak koyup biniş payını büyütmek (yürüyüş uzar).
2. **Oda dönüşsüz:** F3 -> oda 220 px, geri yok.
3. **F3 koridoru 160 px (baş payı 15,5 px):** F2/F1 koridorlarından 20 px dar; ölçümde 160 px'e sığmazsa üst sınır duvarı 20 px yukarı (tavan çıkıntısı) ya da F3 yüzeyi y=140 yapılır.
4. **`tutma_kare` 180:** L1 payı ~78 kare (öğretici). 120 yapılırsa ~18 kare.
5. **Harita konumu:** `harita agent atayacak`.
