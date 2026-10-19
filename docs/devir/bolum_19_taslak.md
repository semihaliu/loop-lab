# Bölüm 20 taslağı: Büyük Saat
(Tasarımcı çıktısı; gece otonom üretim, kullanıcı onaylı; sayılar tahmindir, ölçümle düzeltilecek.)

> **ÖLÇÜM NOTU (2026-10-16):** Bu taslağın sayıları tahmindi; ölçümler `docs/sorunlar.md` ve `_b20_*` testlerindedir. Güncel: 4 tur, 3 klon, kareler 78/294/377 + oyuncu 407; asansör biniş x 404..532 (~132 px); oyuncu başlangıç gecikmesi en çok 32 kare; C_A geç basış payı YALNIZ 8 kare (40 px; taslak ~19); C_B payı 18 kare (90 px); şalter geri bas: 1 karelik `sol` basışında 1016..1054 (38 px), 4 kareliğinde 1032..1054 (22 px), 6 kareliğinde 12 px (taslak 35; insan basışı 3–6 kare); raf S 821..916; H'nin PlakaL'de kalma penceresi 104..156 kare (çözüm değeri 150, üst sınıra 6 kare yakın); Z1 uçuşunda `sag` bırakma en çok 32 kare; canlı/klon farkı 0,00 px. Min klon 3 doğrulandı (100 çift x 2 strateji, röle/park), kısayol yok.


> **UYARI:** Bütün kare/piksel sayıları TAHMİNDİR (60 kare/sn, HIZ 5 px/kare; ölçüm yapılmadı). Bölüm 12-14 deneyimi: taslak sayıları hep ölçümle değişti; Bölüm 10/13/14'te canlı/klon dikiş ayrışması ~11,67 px görüldü (docs/sorunlar.md); payların hepsi >= 12 px dikiş payıyla ve bu ayrışma düşülerek verildi. FİNAL. Harita konumu: `harita agent atayacak` (docs/devir/harita_yerlesim.md'de 20 için (140,510) ayrılmış).

(`scenes/bolumler/bolum_20.tscn`, `max_klon = 3`, **çözüm tam 3 klon**.) Sabitler `player.gd` (HIZ 5 px/kare, zıplama tepesi 96,5 / kare ~100,9, g 1400, `ASAGI_DUSME_KARE` 12; gövde 28x48), `asansor.gd`, `gecit.gd` (20x200, 2 px/kare), `lazer.gd`, `salter.gd` (Sol/SagAlan 40x48; "karakterin uygulanan `yon` girdisi, çakışma önceki adımdan"), `tasima_bandi.gd` (100 px/sn: girdisiz 1,667, girdili ters 3,33 px/kare), `yayli_ziplatici.gd` (820 px/sn, tepe ~247, ayak y 353), `basinc_plakasi.gd`, `tek_yonlu.tscn` ve Bölüm 15-19 taslaklarından okundu. Klon kaydı bitince boş girdiyle yerinde bekler.

## 1. Fikir ve özet
- **Öğrettiği fikir:** "devir teslim" (röle) zorunluluğu. Tutucu bir plakada sonsuza kadar durmak zorunda değil: asansörü yukarıda tutan klon, binenler indikten sonra yanındaki ikinci plakaya geçip geçidi açık tutar. Naif sayım 4 tutucu (lazer A, asansör, geçit, lazer B) ister; max 3 olduğundan asansör tutucusu geçit tutucusuna dönüşür. Son metre ayrıca şalterin "geri bas" hilesidir.
- Kat yapısı 3 katlı: F1 (y=600), F2 (y=380), F3 (y=160) + kapalı oda (F2 sağ, yalnız F3 rafından S ile).
- Nesneler: yaylı zıplatıcı x1 (Z1), asansör x1, plaka x4 (A, L, X, B), taşıma bandı x1 (ters, F3), geçit x1, lazer x3 (A, B, S), şalter x1, tek yönlü raf x1, kapı. YOK: kutu, zamanlı/mandal plaka (Bölüm 15-19'da işlendi; final saf röle ve zamanlama).
- **Min klon 3** (§8). 4 tur: C_A (~75 kare), C_H (~290), C_B (~375), oyuncu (~400); hepsi <= 600 (pay >= 200).
- İç içe: zıplatıcıyla ilk çıkış, normal plakalı asansör (binme koreografisi), tutucu devri (L -> X), ters bantta yürüyüş, geçit bekleme, rafta S ile dönüşsüz iniş, odadaki mıhlanmış lazer tutucusu, şalter hilesi. Bölüm 19'dan farkı: ZP yerine zıplatıcı, geçit AYRI plakaya (X) bağlı => röle zorunlu; şalter ve bant eklendi; kat yüksekliği/dar F3.

## 2. Kat planı (F1 y 420..600; F2 koridoru y 200..380; F3 koridoru y 0..160)
```
y=0   ┌──BlokF3L (0..400)──┬ L2 ┬─F3a┬─Bant◄(ters)─┬Yer┬[G]┬── raf(S) ──┬─BlokF3R─┐
y=160 │                    │tepe│ 540│ 560..720    │720│780│ 810..930   │930..1152│
y=200 ├────────────────────┴────┴────┴─────────────┴───┴───┴────────────┴─────────┤
      │ F2: [PlakaA] LazerA   L2 kuyusu    [PlakaL][PlakaX] │W2│ ODA: [PlakaB] LazerB Ş LazerS [Kapı] │
y=380 ├DS┐ Z1  ┌DosemeA(200..400)┴───(400..540)───┴DosemeB(540..720)┤  ├──DosemeR (740..1152)─────────┤
y=420 │ │boşluk│                                                    │  │                              │
      │ [O] Z1     F1 sol alan (0..400)    │ BlokF1 (400..1152, y 420..600)                          │
y=600 └─────────────────────────────────────────────────────────────────────────────────────────────┘
       40  150
```
- F1 sol alan (x 0..400): oyuncu, Z1 (x 150). BlokF1 (x 400..1152) F1'in kalanını doldurur.
- F2: DosemeSol (0..100), Z1 boşluğu (100..200), DosemeA (200..400: PlakaA, LazerA), L2 kuyusu (400..540), DosemeB (540..720: PlakaL x 560..620, PlakaX x 640..700), DuvarW2 (720..740), oda (740..1152).
- F3: L2 tepesi (kuyu 400..540), DosemeF3a (540..560), ters bant (560..720), DosemeF3b (720..810: bekleme yeri 720..780, G x 790), raf (810..930), BlokF3R (930..1152). Oda yalnız raftan; dönüş yok.

## 3. Nesneler (merkez, boyut)
| Düğüm | Tür | Konum | Boyut / parametre |
|---|---|---|---|
| Zemin | StaticBody2D | (576,620) | 1152x40 |
| BlokF1 | StaticBody2D | (776,510) | 752x180 (x 400..1152, y 420..600) |
| DosemeSol | StaticBody2D | (50,400) | 100x40 (x 0..100, üst y=380) |
| DosemeA | StaticBody2D | (300,400) | 200x40 (x 200..400) |
| DosemeB | StaticBody2D | (630,400) | 180x40 (x 540..720) |
| DuvarW2 | StaticBody2D | (730,310) | 20x220 (x 720..740, y 200..420) |
| DosemeR | StaticBody2D | (946,400) | 412x40 (x 740..1152, oda zemini) |
| BlokF3L | StaticBody2D | (200,100) | 400x200 (x 0..400, y 0..200) |
| DosemeF3a | StaticBody2D | (550,180) | 20x40 (x 540..560, üst y=160) |
| BantTaban | StaticBody2D | (640,188) | 160x24 (x 560..720, y 176..200) |
| DosemeF3b | StaticBody2D | (765,180) | 90x40 (x 720..810, üst y=160) |
| BlokF3R | StaticBody2D | (1041,100) | 222x200 (x 930..1152, y 0..200) |
| Raf | tek_yonlu.tscn | (870,166) | 120x12 (x 810..930, üst y=160) |
| Bant | tasima_bandi.tscn | (640,168) | 160x16 (üst y=160), `yon=-1`, `hiz=100` |
| Z1 | yayli_ziplatici | (150,594) | `firlatma_hizi=820`, sensör x 120..180 |
| PlakaA | basinc_plakasi | (265,372) | 60x16 (x 235..295) |
| PlakaL | basinc_plakasi | (590,372) | 60x16 (x 560..620) |
| PlakaX | basinc_plakasi | (670,372) | 60x16 (x 640..700) |
| PlakaB | basinc_plakasi | (870,372) | 60x16 (x 840..900, odada raf altı) |
| Asansor | asansor.gd | (470,390) | 120x20 (x 410..530, üst y=380), `yukseklik=220` (tepe y=160), `hiz=120`, `plaka=../PlakaL` |
| GecitG | gecit.tscn | (790,60) | 20x200 (x 780..800, y -40..160), `kayma_yonu=(0,-1)`, `kayma_mesafe=100`, `hiz=120`, tetik [../PlakaX] |
| LazerA | lazer.tscn | (340,200) | `yon=(0,1)`, `uzunluk=180` (x 337..343, y 200..380), tetik [../PlakaA], `tetik_aktifken_kapali=true` |
| LazerB | lazer.tscn | (945,200) | `yon=(0,1)`, `uzunluk=180` (x 942..948), tetik [../PlakaB], kapalı=true |
| Salter | salter.tscn | (1000,380) | `baslangic_sagda=true`; SolAlan x 960..1000, SagAlan x 1000..1040 (y 332..380) |
| LazerS | lazer.tscn | (1075,200) | `yon=(0,1)`, `uzunluk=180` (x 1072..1078), tetik [../Salter], `acik_taraf_sag=true`, `tetik_aktifken_kapali=false` (şalter SAĞDAYKEN öldürücü) |
| Kapi | kapi.gd Area2D | (1115,356) | 36x48 (x 1097..1133, y 332..380) |
| Oyuncu | oyuncu.tscn | (40,576) | |
| Bilgi | Label | (16,12) | |

**Ağaç sırası:** Zemin, BlokF1, DosemeSol, DosemeA, DosemeB, DuvarW2, DosemeR, BlokF3L, DosemeF3a, BantTaban, DosemeF3b, BlokF3R, Raf, Bant, PlakaA, PlakaL, PlakaX, PlakaB, Salter, Z1, Asansor, GecitG, LazerA, LazerB, LazerS, Kapi, Oyuncu, Bilgi (plaka/şalter/asansör/geçit/lazer karakterlerden önce). Başlangıç: asansör aşağıda, G kapalı, LazerA/B açık, şalter sağda (LazerS öldürücü).

## 4. Roller
- **C_A:** Z1 ile F2, PlakaA'da kalır (LazerA kapalı).
- **C_H (tutucu, DEVİR):** Z1, LazerA, PlakaL'de ~150 kare durur (L2 yukarıda), ~k260'ta PlakaX'e geçer ve orada kalır (G açık).
- **C_B:** Z1, LazerA, L2'ye biner (C_H basmadan ÖNCE), F3, bant, G (açık), rafta S, odada PlakaB'de kalır.
- **Oyuncu:** aynı yol; LazerB geçilir, şalter "geri bas", LazerS, kapı.

## 5. Çözüm (tuş kareleri tahmin; c = gövde merkezi x)
**Tur 1 (C_A, ~75 kare):** `sag` kesintisiz: Z1'e k~13, `sag` tutarak fırlama (F2'ye k~40, c~186 boşluk duvarında yaslı); PlakaA'ya c>=221'de (k~47), c~265'te dur, ~15 kare bekle, R.
**Tur 2 (C_H, ~290 kare):** C_A oynar. Aynı yol (LazerA'ya c=323'te k~67'de varılır, C_A plakada k~47'den beri). L2 kuyusunu c 410..530 yürüyerek geçer; PlakaL'e c>=546'da (k~112) girer, c~590'da dur (asansör k~113'te kalkar, tepe k~223). **k~260'ta** `sag`: c>=626'da PlakaX'e girer (k~268), c~670'te dur; R.
**Tur 3 (C_B, ~375 kare):** C_A, C_H oynar. Aynı yol; L2 kuyusunda c~470'te (k~97) `sag` BIRAK, asansörde bekle (C_H k~112'de plakaya basar, L2 kalkar, tepe k~223). `sag`: c=544'ü geçince asansörden iner (k~239); bant (c 560..720, net 3,33 px/kare) k~242..290; bekleme yeri c 746..764 (k~296); G açıksa (X basılı k~268, G >= 56 px k~296) `sag`: G'yi geçer (k~304); rafta c 824..916 arası (c~870, k~320) `sag` BIRAK, `asagi` bas: odaya iner (k~354), PlakaB'de dur, ~15 kare bekle, R.
**Tur 4 (oyuncu, "Klon: 3/3", R kapalı, ~400 kare):** aynı yol ve kareler; odada LazerB'ye (c=928) k~366'da varılır (C_B plakada k~354'ten beri); Ş: `sag` ile c>=1019'a kadar (k~384), c~1030'da (k~386) `sol` bir kare, hemen `sag`: şalter SOLA geçer (LazerS kapalı); LazerS c=1058'de (k~394), kapı k~399.

## 6. Zamanlama pencereleri (pay; bant/asansör dikişi >= 12 px, ayrışma 11,67 px düşülmüş)
| # | Pencere | Pay |
|---|---|---|
| W1 | C_A plakada (k~47) -> LazerA ışınına varış (k~67) | **~19 kare** |
| W2 | L2 biniş: `sag` bırakma c 436..504 (gövde asansör üstünde, uçlardan >= 12 px), C_H'nin PlakaL'e basışından (k~112) önce: doğal bırakış c~470 (k~97); c=516'ya (k~106) kadar | **68 px** (+-34 px = +-6,8 kare) |
| W3 | C_H'nin PlakaL tutuşu: tepe (k~223) + binenlerin asansörden çıkışı (c>544, k~239) -> C_H'nin ayrılışı (k~260) | **~21 kare** (erken ayrılırsa asansör iner, binenler ~46 px geride; ayrılış k~239'dan önce olmamalı) |
| W4 | Devir: C_H PlakaL'den ayrılır (c>=634, k~269) / PlakaX'e girer (c>=626, k~268): ikisi arası 8 px örtüşme, boşluk yok; yine de G 2 px/kare kapandığından 26 kare dayanır | **>= 26 kare** (kopuş payı) |
| W5 | G açıklığı >= 48 px (k~292), bekleyen geçici (k~296): oyuncu G açılana kadar bekleyebilir; üst sınır yok (X kalıcı basılı) | **bekleme serbest** |
| W6 | Bant yürüyüşü c 560..720: 160/3,33 = 48 kare; bekleme yeri c 746..764 (dikiş x=720'den >= 12 px; G'ye 780-14=766) | **18 px** |
| W7 | Raf S: gövde tam raf üstünde ve G'nin sağında: c 824..916 (sağ tuş bırakılmalı: +60 px sürüklenme BlokF3R'ye yaslar) | **92 px** |
| W8 | C_B'nin PlakaB'ye basışı (k~354) -> oyuncunun LazerB ışınına varışı (k~366) | **~11 kare** (oyuncu ~10 kareden fazla önde inmemeli) |
| W9 | Şalter "geri bas": `sol` basışı c 1019..1053 (c-14 >= 1000: SolAlan'ın dışı; c-14 < 1040: SagAlan içi) | **35 px** (7 kare); c<1019: şalter tekrar sağa döner (LazerS öldürücü, ışına varmadan tekrar denenir) |
| W10 | Tur süresi: oyuncu ~400 | **~200 kare** (<= 600) |
- Bant payı: bant yalnız F3'te; plaka/geçit/raf bant üstünde değil; dikişler (x 560, 720) üstünde zorunlu karar yok. Zıplatıcı uçuş payı 27 px (ayak 353 / yüzey 380).

**Şalter durumu (her geçişte):**
| Anı | Şalter | LazerS | Not |
|---|---|---|---|
| Tur başı | sağda | öldürücü | |
| C_A, C_H, C_B | sağda | öldürücü | kimse şalterin yanına varmaz (odada C_B PlakaB'de kalır, ışının solu) |
| Oyuncu c<987 (SolAlan'a girmeden) / SolAlan'dan sağa yürürken | sağda (sağdayken SolAlan yön>0 tetiklemez) | öldürücü | |
| Oyuncu SagAlan içinde, c 1019..1053, `sol` 1 kare | **SOLA geçer** | kapalı | `sagda=false` |
| Oyuncu `sag` ile ilerler (c>1054) | solda (SagAlan yön>0 tetiklemez) | kapalı | |
| Oyuncu LazerS'yi (c=1058) geçer, kapı | solda | kapalı | |

## 7. Atlanamazlık (sahne sayıları)
- **F1 -> F2:** 220 px > 100,9 (pay 119); tek yol Z1 (tepe 247 > 220; ayak y 353, F2 yüzeyinin 27 px üstü; baş y 305 > F2 tavanı 200: 105 px pay).
- **F2 -> F3:** F3 yüzeyi y=160, F2 yüzeyi 380: 220 px > 100,9; tek yol L2. F3 koridoru 160 px: baş payı 160-48-96,5 = 15,5 px.
- **GecitG:** kapalı y -40..160 (F3 yüzeyi 160 bitişik, sınır duvarına gömülü), açıkken boşluk 100 px; zıplama aşamaz.
- **LazerA/B/S:** y 200..380 (tavan 200 bitişik); zıplama baş y>=251 ışın bandı içinde; Z1 uçuşu x=150'de ışın x=340'ta (aşılmaz).
- **F1 -> L2 kuyusu:** BlokF1 F1'i x=400'de keser; F2 kuyusu açık ama zemin 40 px altta (BlokF1 üstü y=420).
- **Oda:** DuvarW2 220 px, tavan bitişik; yalnız raf (F3). Odadan F3'e 220 px > 100,9.
- **F3 sağ ucu:** BlokF3R tavandan F3'e kadar kapalı (x 930..); raf ötesi yok.

## 8. Kısayol taraması (min 3 düşmez)
| Deneme | Sonuç | Neden |
|---|---|---|
| Klonsuz | olmaz | LazerA'da (k~67) ölür |
| 1 klon / 2 klon (tüm sıralar) | olmaz | Üç tutucu: A (LazerA), L->X (asansör ve geçit), B (LazerB). C_A yoksa C_H/C_B LazerA'da ölür (kayıt alınamaz); C_H yoksa L2 yükselmez ya da G açılmaz; C_B yoksa odada LazerB öldürür |
| min-1 = 2 klon + oyuncu PlakaX/PlakaB'yi tutar | olmaz | oyuncu kapıya gidemez; X F2'de, B odada |
| Röle: C_A (A -> L/X) | olmaz | C_A plakadan ayrılırsa LazerA açılır; ışın plaka sağ kenarından (295) 42 px ilerde (~9 kare); ışından geçip PlakaL'e gidemez |
| Röle: C_H (L -> X -> B) | **L -> X zorunlu, X -> B olmaz** | X F2'dedir, G'den F3'e çıkış ve oda yolu asansör (tutucusuz inmiş) ve G (kapanıyor, 2 px/kare, X'ten 120+ px) arkasında kalır |
| Röle: C_B (B -> X) | olmaz | C_B odada dönüşsüz (220 px) |
| Kutu basamağı / kutuyla plaka tutma / zıplatıcı + kutu | uygulanamaz | kutu yok |
| Bant dalgalanması | min'i düşürmez | bant F3'te; plaka/geçit bant üstünde değil; girdisiz karakter bant ucunda x~720'ye (DosemeF3b) kayar; yalnız yürüyüşü ~16 kare uzatır |
| **Geçit altı park / röle** | min'i düşürmez | G kapanırken altında karakter varsa durur: G'nin altında park eden klon G'yi ~50 px açık tutar; ama bu klon odaya gidemez (B tutucusu yok) ve C_H'nin devrini ikame etmez (park eden başka bir klondur: 4. rol). Oyuncu parkta kalırsa kapıya varamaz |
| Asansör altı park | min'i düşürmez | tepedeki L2'nin altında park eden karakter asansörü baş üstünde (y~308) tutar: F3'e 148 px (> 100,9) |
| S ile yeni iniş yolu | yok | tek raf; DosemeF3a/b ve bant katı |
| Lazeri zıplayarak aşma | olmaz | §7 |
| Zamanlı plakayla röle / mandalla tasarruf | uygulanamaz | zamanlı/mandal plaka yok |
**Min klon 3 kanıtı:** tutucu zaman aralıkları (oyuncu k~400): PlakaA [k 67..~390 (LazerA)], PlakaL [k 112..239 (asansör)], PlakaX [k 296..304 (G)], PlakaB [k 366..~399 (LazerB)]. L ve X aralıkları ayrık: tek klon devirle (C_H) ikisini taşır (X'e F2'de yan plakadan geçilir). A tutucusu ışının solunda mıhlanır (ayrılan ~9 karede ölür); B tutucusu odadadır (L2 ve G arkasından rafla gelen, dönüşsüz). C_H odaya ulaşamaz (L2'yi tutarken binemez, bırakınca iner; G'ye ulaşamaz). Dolayısıyla A, C_H ve B tutucuları üç farklı klon; oyuncu dördüncü. X'in L'den ayrı plaka olması röleyi ZORUNLU yapar (naif 4 tutucu max 3 ile imkânsız).

## 9. Başarısızlık senaryoları
1. Klonsuz: LazerA'da ölür, tur yeniden başlar.
2. Yalnız C_A: oyuncu L2'de takılır (PlakaL tutulmaz), çıkış yok.
3. C_A + C_H, C_B yok: oyuncu odada LazerB'de ölür.
4. C_H devri olmadan (X'e geçmeden PlakaL'de kalırsa): L2 tepede ama G kapalı; binenler G altında takılır; X'i tutan yok, kilit değil ama bölüm biter (R/"Baştan başla").
5. C_H PlakaL'den erken ayrılırsa (k<239): asansör iner, binenler ~(260-239)*2 px aşağıda; sonra G açıksa da F3'e inemez: tekrar.
6. L2 geç biniş (C_H basışından sonra >~50 kare, ya da C_H ayrıldıktan sonra): asansör gitmiş/inişte; "Baştan başla" (tur 4) ya da R.
7. Rafta sağ tuş basılı S: +60 px BlokF3R'ye yaslanır, cebe iner (zarar yok); rafta çok erken S (c<824): DosemeF3b destekler, etkisiz.
8. Odada oyuncu C_B'den ~11 kareden önce inerse: LazerB açık, ışında ölür.
9. Şalter geri bas c<1019: şalter tekrar sağa geçer (SolAlan yön>0), LazerS öldürücü; ışına varmadan tekrar denenir; c>1053: SagAlan'ın dışı, şalter sağda kalır, LazerS'de ölür.
10. Geçide G açılmadan yürümek: G'ye çarpar, bekler; kilit yok.

## 10. Kilitlenme analizi
- **L2 geç biniş / C_H'nin devir sonrası:** asansör iner (tutucu yok); binemeyen R (tur 4'te hak yok: "Baştan başla"). Geri dönmesi zor karar (§12).
- Klon asansör altında kalmaz: C_A F2'de, C_H F2'de (plakalar), C_B F3/odada; asansörün kuyusunda (x 410..530) F2'den düşen biri 40 px çukura iner (BlokF1 üstü), asansör ineceğinde altında kalırsa asansör durur (zarar yok; zıplayarak çıkar, 40 px < 100,9).
- Oda dönüşsüz: odadan F3'e çıkış yok.
- G altında klon bitmez: C_H X'te, C_B odada; G altında park eden kimse yok.
- C_H'nin devrindeki PlakaL-PlakaX arası 20 px boşluk: gövde 28 px, 8 px örtüşme; boşluğa düşme yok (plakalar Area2D, zemin DosemeB sürekli).
- Şalter: sağda başlar, yalnızca oyuncu çevirir; kilit yok (geri bas tekrar denenir).

## 11. S düşme kullanımı ve riskleri
Tek S: raf (c 824..916), 220 px ~34 kare, dönüşsüz. Risk: sağ tuş +60 px sürüklenme (zararsız, BlokF3R'ye yaslar), c<824'te S etkisiz, bant üstünde S yok.

## 12. Geri dönmesi zor kararlar (kullanıcı karar versin)
1. **Devir (röle) kasıtlı zorunlu:** X, L'den ayrı plaka. L ile aynı plaka yapılırsa röle gerekmez (C_H bırakmaz, min yine 3 ama bölüm kolaylaşır). Çözüm yolu tek ve gizli: "tutucu yan plakaya geçer".
2. **Asansör iner:** C_H plakadan ayrılınca L2 tepeden iner; gecikmeli binen "Baştan başla". Alternatif: asansörü ZP yapmak (ama C_H'nin devri anlamsızlaşır).
3. **F3 koridoru 160 px (baş payı 15,5 px)** ve tavan sınır duvarı y=0: geçit sınır duvarına gömülü; ölçümde sorun çıkarsa F3 yüzeyi y=140 yapılır.
4. **Şalter "geri bas":** 35 px (7 kare) penceresi dar; canlı/klon fark etmez (yalnız oyuncu), ama c 1019 sınırı Godot ölçümüyle (SolAlan çakışması önceki adım) doğrulanmalı.
5. **Ters bant:** 160 px'de ~16 kare; ayrışma 11,67 px >= payları (W6) ölçümle >= 12 px çıkmazsa bekleme yeri genişletilir.
6. **Harita konumu:** `harita agent atayacak`.
