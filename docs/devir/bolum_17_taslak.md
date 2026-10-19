# Bölüm 17 taslağı: Çifte Mühür
(Tasarımcı çıktısı; gece otonom üretim, kullanıcı onaylı.)

> **ÖLÇÜM NOTU (2026-10-16):** Bu taslağın kare/piksel sayıları tahmindi; ölçümler `docs/sorunlar.md` "Bölüm 15-17" ve `_b17_*` testlerindedir. Güncel: tur kareleri 117/256/289/398; fitil payı 17 kare (taslak ~21; çıkışa göre 7 kare); C_A geç 22, C_B geç 18, C_C geç 33 kare (taslak ~59); MP→GecitM 80 kare; S raf1 572..608 (36 px), raf2 972..1062 (90 px); Z2'de `sag` bırakma ≥20 kare; `tutma_kare` tam 70; canlı/klon farkı çözüm turlarında 0,00 px (taslağın 11,67 px öngörüsü gerçekleşmedi; durma noktası taramasında en çok 3,33 px). §9.8 "rafta `sag` ile S ışına iner, ölür" son turda LazerC kapalı olduğundan yanlış; §9.9/§10 "kutu sola itilebilir, kilitlenir" yanlış (kutu–ledge aralığı 20 px < gövde 28 px: kutu yalnız sağa itilir ve itme zorunlu değil). Min klon 3 doğrulandı, kısayol yok.


> **UYARI:** Bu taslağın bütün kare/piksel sayıları TAHMİNDİR (60 kare/sn, HIZ 5 px/kare; ölçüm yapılmadı). Uygulama sonrası ölçümle düzeltilecek (Bölüm 12-14'te taslak sayıları hep ölçümle değişti; Bölüm 10/13/14'te bant dikişi ayrışması ~11,67 px görüldü, aşağıdaki paylar bunu düşerek hesaplandı). Harita konumu: harita agent atayacak.

(`scenes/bolumler/bolum_17.tscn`, `max_klon = 3`, **çözüm tam 3 klon**.) FİNAL. Sabitler `player.gd`, `gecit.gd`, `lazer.gd`, `kutu.gd`, `yayli_ziplatici.gd`, `tasima_bandi.gd`, `basinc_plakasi.gd`, `tek_yonlu.tscn` ve Bölüm 14-16 taslaklarından okundu: karakter 28x48, HIZ 5 px/kare, zıplama tepesi 96,5 (kare ~100,9), `ASAGI_DUSME_KARE`=12, zıplatıcı 820 px/sn (tepe ~247, ayak y 353), bant 100 px/sn (girdisiz 1,667; girdili ters 3,33 px/kare), geçit 20x200 / 2 px/kare, lazer 6 px, kutu 40x40. `ZamanliPlaka` (`tutma_kare`) ve `MandalPlaka` (bir kez basılınca tur sonuna) varsayımı Bölüm 15-16 ile aynı.

## 1. Fikir ve özet
- **Öğrettiği fikir:** iki kalıcı/yarı kalıcı plakanın birlikte kullanımı: cepte hem zamanlı (fitil) hem mandal plaka var. İkisi de normal olsaydı cepte mıhlanan 4. klon gerekirdi (max 3: çözülemezdi). Zamanlı plaka uzaktaki geçidi koşuyla açar, mandal plaka geçidi kalıcı açar; üç mıhlanmış lazer tutucusu hâlâ 3 klon ister.
- Nesneler: taşıma bandı x1 (ters yönlü), plaka x3, zamanlı plaka x1, mandal plaka x1, geçit x2, lazer x3, yaylı zıplatıcı x2, tek yönlü raf x2, kutu x1, kapı.
- **Min klon 3** (§8). 4 tur: C_A (~125 kare), C_B (~265), C_C (~305), oyuncu (~385); hepsi ≤ 600 (pay >= 215).
- B16'dan farkı: ters bant (yürüyüşü ~16 kare uzatır), ikinci geçit ve fitil koşusu (pay ~21 kare, B16'da yarış yok), iki ayrı S inişi (cep, kuyu), kuyuda kutu basamağı, dikiş/bant ayrışması payı (>= 12 px).

## 2. Kat planı (F1 y=600 koridoru 180 px; F2 y=380 koridoru 200 px)
```
y=180 ┌────────────────────────── Tavan (y 0..180) ─────────────────────────────┐
      │ F2    LazerA   (raf1)   LazerB  G_Z  GecitM        LazerC (x=1040)      │
y=380 ├─┐ ┌─D1┬Bant◄──┬D2[PlakaA]|──────|──[PlakaB]…|…[PlakaC]──(raf2)──┤piece3│
y=420 │ │ │   BantTaban 240..400  │ cep  ▒  │ DöşemeB (680..960)      │ ledge│
      │ │ Z1 gap     W1 (440..460) │ZP MP Z2│ W2 blok (760..960)      │[Kapı]│
y=600 └[O]─Z1──────────────────────┴────────┴─────────────────[K]─────┴──────┘
      40  150                      460..760 cep            960..1152 kuyu tabanı
```
- F1 sol bölge (x 0..440): oyuncu, Z1. W1 (x 440..460) cebi ayırır. Cep (x 460..760): ZP, MP, Z2; yalnız raf1'den S ile girilir, Z2 ile çıkılır. W2 bloğu (x 760..960) F1'i kuyudan ayırır. Kuyu tabanı (x 960..1152): K, çıkıntı (ledge), kapı; yalnız raf2'den S ile girilir (kuyudan F2'ye dönüş yok).

## 3. Nesneler (merkez, boyut)
| Düğüm | Tür | Konum | Boyut / parametre |
|---|---|---|---|
| Zemin | StaticBody2D | (576,620) | 1152x40 |
| Tavan | StaticBody2D | (576,90) | 1152x180 |
| DosemeSol | StaticBody2D | (50,400) | 100x40 (x 0..100) |
| DosemeA1 | StaticBody2D | (220,400) | 40x40 (x 200..240) |
| BantTaban | StaticBody2D | (320,408) | 160x24 (x 240..400, y 396..420) |
| Bant | tasima_bandi.tscn | (320,388) | 160x16, üst y=380, `yon=-1`, `hiz=100` |
| DosemeA2 | StaticBody2D | (480,400) | 160x40 (x 400..560) |
| Raf1 | tek_yonlu.tscn | (620,386) | 120x12 (x 560..680, üst y=380) |
| DosemeB | StaticBody2D | (820,400) | 280x40 (x 680..960) |
| Raf2 | tek_yonlu.tscn | (1020,386) | 120x12 (x 960..1080) |
| DosemeP3 | StaticBody2D | (1116,400) | 72x40 (x 1080..1152) |
| DuvarW1 | StaticBody2D | (450,510) | 20x180 (x 440..460, y 420..600) |
| BlokW2 | StaticBody2D | (860,510) | 200x180 (x 760..960, y 420..600) |
| Ledge | StaticBody2D | (1126,543) | 52x114 (x 1100..1152, üst y=486) |
| PlakaA | basinc_plakasi | (440,372) | 60x16 (x 410..470) |
| PlakaB | basinc_plakasi | (735,372) | 60x16 (x 705..765) |
| PlakaC | basinc_plakasi | (925,372) | 60x16 (x 895..955) |
| PlakaZ (ZP) | zamanli_plaka.tscn | (500,592) | 60x16 (x 470..530), **`tutma_kare = 70`** (sahnede ayar; export yoksa 180 + G_Z'yi 60 px sağa) |
| PlakaM (MP) | mandal_plaka.tscn | (570,592) | 60x16 (x 540..600) |
| Z1 | yayli_ziplatici | (150,594) | `firlatma_hizi=820`, sensör x 120..180 (F1) |
| Z2 | yayli_ziplatici | (650,594) | `firlatma_hizi=820`, sensör x 620..680 (cep) |
| GecitZ (G_Z) | gecit.tscn | (830,280) | 20x200 (y 180..380), `kayma_yonu=(0,-1)`, `kayma_mesafe=100`, `hiz=120`, tetik [../PlakaZ] |
| GecitM | gecit.tscn | (880,280) | aynı, tetik [../PlakaM] |
| LazerA | lazer.tscn | (515,180) | `yon=(0,1)`, `uzunluk=200` (x 512..518), tetik [../PlakaA], `tetik_aktifken_kapali=true` |
| LazerB | lazer.tscn | (790,180) | aynı (x 787..793), tetik [../PlakaB] |
| LazerC | lazer.tscn | (1040,180) | `uzunluk=420` (x 1037..1043, y 180..600), tetik [../PlakaC], kapalı=true |
| Kapi | kapi.gd Area2D | (1126,462) | 36x48 (ledge üstü, y 438..486) |
| Kutu | kutu.tscn | (1060,580) | 40x40 (x 1040..1080, kuyu tabanı) |
| Oyuncu | oyuncu.tscn | (40,576) | |
| Bilgi | Label | (16,12) | |

**Ağaç sırası:** Zemin, Tavan, DosemeSol, DosemeA1, BantTaban, Bant, DosemeA2, Raf1, DosemeB, Raf2, DosemeP3, DuvarW1, BlokW2, Ledge, PlakaA, PlakaB, PlakaC, PlakaZ, PlakaM, Z1, Z2, GecitZ, GecitM, LazerA, LazerB, LazerC, Kapi, Kutu, Oyuncu, Bilgi (plaka/geçit/lazer karakterlerden ve kutudan önce). Güvenlik: kutu oyuncudan > 1000 px; asansör yok.

## 4. Roller
- **C_A:** Z1, ters bant, PlakaA'da kalır (LazerA kapalı).
- **C_B:** LazerA'yı geçer, raf1'de S, cepte MP'ye basar (GecitM kalıcı), ZP'ye basar, Z2 ile döner, LazerB'yi geçemeden PlakaB'ye (ışının 25 px gerisi) kalır.
- **C_C:** LazerA/B'yi geçer, cep gezisini yapar (ZP fitili), G_Z'yi koşar, GecitM'den geçer, PlakaC'de kalır.
- **Oyuncu:** cep gezisi, G_Z koşusu, raf2'de S, kuyuda LazerC'den geçer, K basamağı, kapı.

## 5. Çözüm (tuş kareleri tahmin)
**Tur 1 (C_A, ~125 kare):** `sag` kesintisiz: Z1'e kare ~13, `sag` basılı tutarak fırlama (kare ~40 F2'de x~186'da), bant ters yönlü (net 3,33 px/kare, ~48 kare), PlakaA'ya kare ~98'de girer; x~445'te dur (hedef 425..456), ~15 kare bekle, R.
**Tur 2 (C_B, ~265 kare):** C_A oynar. Aynı yol; LazerA ışınına kare ~118'de varılır. Raf1 üstünde x 574..605 arası dur (kare ~136), `sag` BIRAK, `asagi` bas: cebe iner (kare ~170), MP'ye değer (mandal, GecitM açılır). `sol` ile ZP'ye yürü (x~500, kare ~188), `sag` ile geri: Z2 sensörüne kare ~209'da girer, `sag` basılı tutarak fırlar (cep boşluk duvarında x=666'da yaslanır, kare ~234'te F2'de). PlakaB'ye kare ~239'da girer; x~735'te dur, ~15 kare bekle, R.
**Tur 3 (C_C, ~305 kare):** C_A, C_B oynar. Aynı cep gezisi (ZP'nin son basışı kare ~197); LazerB ışınına kare ~255'te varılır (C_B plakada kare ~239'dan beri); G_Z'yi kare ~262..272'de geçer (fitil sona kare ~293); GecitM'den (açık) geçer; PlakaC'ye kare ~281'de girer, x~925'te dur (~15 kare bekle), R.
**Tur 4 (oyuncu, R kapalı "Klon: 3/3", ~385 kare):** aynı gezi ve koşu; PlakaC'yi geçince raf2 üstünde x 974..1023 arasında dur, `sag` BIRAK, `asagi` bas (kare ~300); kuyuya iner, LazerC'den (kapalı) geçer, kutuyu ~4 kare iter, kutu üstüne `zipla`+`sag`, ledge üstüne `zipla`+`sag`, kapı (kare ~385).

## 6. Zamanlama pencereleri (pay; bant dikişi ayrışması 11,67 px ≈ 2,3 kare düşüldü)
| # | Pencere | Pay |
|---|---|---|
| W1 | C_A plakada (kare ~98) -> C_B'nin LazerA ışınına varışı (kare ~118) | **~20 kare** (17,7 düşülünce) |
| W2 | S konumu raf1: gövde tam raf üstünde (merkez >= 574) ve Z2 sensörüne girmeden (merkez <= 605): 32 px; sağ tuş bırakılmalı | **32 px**, ayrışma düşülünce **20 px** (>= 12) |
| W3 | Z2 uçuşunda `sag` tutma başlangıcı: sensör girişinden en geç ~28 kare | **~28 kare** (bırakılırsa cebe düşer, ~71 kare kayıp: W4 payı 21 < 71, geçit kaçar) |
| W4 | ZP son basış (kare ~197) -> G_Z'den çıkış (kare ~272); fitil 70 + kapanış 26 = kare ~293 | **~21 kare** (~19 ayrışma düşülünce; ZP basılı kalınan an her geçen için aynı) |
| W5 | C_B'nin PlakaB'ye basışı (kare ~239) -> oyuncunun LazerB ışınına varışı (kare ~255) | **~16 kare** (~14 düşülünce) |
| W6 | MP basışı (kare ~170) -> GecitM >= 48 px açık (kare ~194) -> geçenin varışı (kare ~272) | **~78 kare** |
| W7 | S konumu raf2: gövde tam raf üstünde (merkez >= 974) ve LazerC ışınının solunda (merkez <= 1023): 49 px | **49 px**, ayrışma düşülünce **37 px** |
| W8 | C_C'nin PlakaC'ye basışı (kare ~281) -> oyuncunun LazerC ışınına varışı (kare ~340) | **~59 kare** |
| W9 | Kutu basamağı: kutu üstü 560 -> ledge üstü 486: 74 px; tavan (DosemeP3 alt 420) başı kırpar, ayak y >= 468 | **18 px** (ledge'e; kutusuz 114 > 100,9: 13,1 px) |
- Bant payı: bant yalnız F2 başında, hiçbir plaka/lazer bant üstünde değil, dikiş (x=240, 400) üstünde zorunlu karar yok. Zıplatıcı uçuş payı 27 px (ayak 353 / yüzey 380).

## 7. Atlanamazlık (sahne sayıları)
- **Zemin -> F2:** 220 px > 100,9 (pay 119); yalnız Z1.
- **F1 -> cep / kuyu:** DuvarW1, BlokW2 (180 px) F1'i böler; cebe yalnız raf1, kuyuya yalnız raf2.
- **Geçitler (GecitZ, GecitM):** kapalı y 180..380, tavan ve F2 yüzeyi bitişik, boşluk 0.
- **Lazerler:** A/B y 180..380; C y 180..600 (raf2 ve kuyuyu tavandan zemine keser); zıplama ve Z1/Z2 uçuşu (ayak y min 353, baş 305) ışın bandı içinde.
- **Ledge:** üst y=486, kuyu tabanından 114 px > 100,9 (pay 13,1); kutu üstü 74 px (pay 26,9; tavan kırpmasıyla 18 px). Ledge üstü ile DosemeP3 arası 66 px: kapı baş payı 18 px (438 > 420).
- **Piece3 (F2 sağ parça):** LazerC ışını (x=1040) raf2 yürüyüşünü keser; ışının sağına geçilemez.

## 8. Kısayol taraması (min 3 düşmez)
| Deneme | Sonuç | Neden |
|---|---|---|
| Klonsuz | olmaz | LazerA'da (kare ~118) ölür |
| 1 klon / 2 klon (tüm sıralar, C_A+C_B, C_A+C_C, C_B+C_C) | olmaz | C_C yoksa LazerC'de ölür; C_B yoksa LazerB; C_A yoksa LazerA. Her tutucu kendi lazerinin gerisinde mıhlanır (A 45 px, B 25 px, C 145 px; ayrılan ışına 2-20 karede varıp ölür) |
| min-1 = 2 klon + oyuncu PlakaC'yi tutar | olmaz | kapıya gidemez |
| Kutu basamağı | tasarım yolu | ledge 114 > 100,9; kutu 40: tek yol. Kutu kuyudan çıkamaz (BlokW2, raf2 tek yönlü yukarıdan), plaka tutamaz |
| Kutuyla plaka tutma | kısayol yok | kutu kuyuda (PlakaA/B/C F2'de, kutu F2'ye çıkamaz: kuyudan dönüş yok, Z yok); mandal/ZP kutu ağırlığıyla da basılır ama kutu cepte değil |
| Zıplatıcı + kutu | kısayol yok | Z1 F1'de, kutu kuyuda ayrı; Z2 cepte, kutu giremez |
| Bant dalgalanması | min'i düşürmez | PlakaA bant dışında (x 410..470, bant ucu x=400): bant sürüklemesi plakaya taşımaz; girdisiz karakter bant ucunda x~240'a (DosemeA1) kayar. Bant yalnız yürüyüşü uzatır |
| **Geçit altı park / röle** | min'i düşürmez | oyuncu G_Z altında park edip kör klonu fitilsiz geçirebilir (Bölüm 6 hilesi): C_C kaydı kapalı G_Z'de takılır, sonraki turda oyuncu park eder, klon geçer. Ama C_C yine PlakaC'de mıhlanır (LazerC) ve A, B tutucuları gerekir: 3 klon; röle yalnız cep gezisini/fitili atlatır. GecitM kalıcı (MP) olduğundan park anlamsız |
| S ile yeni iniş yolu | yok | raf1 (cep) ve raf2 (kuyu); F2'de başka tek yönlü yok. DosemeB üstünde S etkisiz (katı) |
| Lazeri zıplayarak aşma | olmaz | §7 |
| **Zamanlı plakayla röle / zaman paylaşımı** | min'i düşürmez | ZP'ye basıp ayrılan klon C_B/C_C zaten olacağı yere gider; fitil yalnız G_Z içindir. ZP'ye bir klonu bırakmak 4. klon ister (imkânsız). Tutucular A, B, C ayrı (mıhlanmış) |
| **Mandal plakayla klon tasarrufu** | min'i düşürmez | MP yalnız GecitM'yi kalıcı açar (cepte 4. tutucuyu engeller); lazer tutucularını azaltmaz. MP'yi oyuncunun kendi basması yine A, B, C'yi ister |
**Min klon 3 kanıtı:** LazerA (x=515), LazerB (x=790), LazerC (x=1040) sırasıyla; tutucuları PlakaA, PlakaB, PlakaC her ışının gerisinde (B16 ile aynı mıhlanma argümanı). C_C'nin PlakaC'ye varması A ve B'nin tutulmasını gerektirir; oyuncu son turda üçünü de geçer. ZP veya MP normal olsaydı cepte mıhlanan bir 4. klon gerekirdi (cep çıkışı: plakadan ayrılınca GecitM/G_Z kapanır): max 3 ile imkânsız; bu yüzden ikisinin de özel plaka olması zorunludur ve **hiçbiri A/B/C tutucusunun yerini almaz**.

## 9. Başarısızlık senaryoları
1. Klonsuz: LazerA'da ölür.
2. Yalnız C_A: oyuncu GecitM/G_Z'de takılır ya da LazerB'de ölür.
3. C_A + C_B, C_C yok: oyuncu LazerC'de (raf2 / kuyu) ölür.
4. G_Z'de geç kalma (fitil bitti, kare > ~293): G_Z kapalı, çarpıp durur; raf1'e dönüp cebe tekrar iner, ZP'yi yeniden basar (~120 kare), kilit yok.
5. Raf1'de `sag` basılıyken S: gövde Z2 sensörüne iner, cepten hemen fırlar, MP/ZP basılmaz; tekrar iner.
6. Z2'de `sag` bırakılırsa: cebe geri düşer (~71 kare kayıp), fitil kaçar.
7. C_B kaydında plakadan erken ayrılma: LazerB açılır, C_C ve oyuncu ölür (kayıt tekrarı).
8. Raf2'de `sag` basılıyken S: 12 karede +60 px ışına sürüklenir (merkez > 1023), ölür.
9. Kutu kuyuda ledge'den uzağa itilirse (sola, kuyu sol bölgesinde): basamak 40 px'ten uzak kalır; ledge'e çıkılamaz (§10).

## 10. Kilitlenme analizi
- Kutu geri alınamaz: oyuncu LazerC'nin sağına geçip kutuyu sola iterse (kutu x 1040'tan küçük): ışına girmeden itilemez; kutu ışın bölgesinde kalır, basamak ledge yüzünden >= 60 px uzaklaşır. Çıkış "Baştan başla". Kutu ışın solundayken itilemez (itmek için sağında durmak gerekir).
- Kuyuya inen oyuncu LazerC açıkken (PlakaC boş) ışının solunda kalır: F2'ye dönüş yok (220 px); R ile (klon hakkı varsa) bitirebilir, tur 4'te hak yok: "Baştan başla". Geri dönmesi zor karar (§12).
- Cep: Z2 döngüsü, kilit yok; G_Z solunda takılan oyuncu raf1'e dönüp tekrar deneyebilir (MP kalıcı).
- Klon asansör yok; klonlar plakada biter, geçit altında bitmez.

## 11. S düşme kullanımı ve riskleri
İki S kullanımı: raf1 (merkez 574..605: MP/ZP; 606+ Z2 sensörü anında geri fırlatır) ve raf2 (merkez 974..1023). Her ikisinde sağ tuşu bırakılmalı (12 kare x 5 px = 60 px sürüklenme). Düşüş ~34 kare. Raf1 ile bant dikişi arası ayrışma 11,67 px payları düşülerek verildi (W2, W7).

## 12. Geri dönmesi zor kararlar (kullanıcı karar versin)
1. **Kuyuya iniş dönüşsüz (raf2):** C hold edilmeden inen oyuncu tur içinde çıkamaz.
2. **`tutma_kare = 70` (varsayılan 180 değil):** fitil pay ~21 kare. Varsayılan 180 ile pay ~130 kare: bölüm kolaylaşır ama kırılmaz. Export yoksa G_Z 60 px sağa çekilir.
3. **MP ve ZP aynı cepte:** ikisi de özel; birini normal yapmak bölümü çözülemez kılar (4. klon).
4. **Ters bant:** yalnız F2 başında (dikiş x=240, 400); ayrışma 11,67 px W2/W7'de düşüldü; ölçümle >12 px çıkarsa raf pencereleri 10 px genişletilir.
5. **Kutu ledge'e 20 px, ışının sağında:** kutu geri alınamaz; ledge basamağı pay 18 px (tavan kırpması dahil).
6. **Harita konumu:** harita agent atayacak.
