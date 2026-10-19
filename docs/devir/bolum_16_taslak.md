# Bölüm 16 taslağı: Mandal
(Tasarımcı çıktısı; gece otonom üretim, kullanıcı onaylı.)

> **ÖLÇÜM NOTU (2026-10-16):** Bu taslağın kare/piksel sayıları tahmindi; ölçümler `docs/sorunlar.md` "Bölüm 15-17" ve `_b16_*` testlerindedir. Güncel: tur kareleri 78/209/235/323; Z1/Z2 uçuşunda "`sag` basılı tut" YANLIŞ (köşe x=540'a çarpar): uçuşta `sag` bırakılır (Z2'de ≥2 kare, üst sınır yok), ayak y≤345'te yeniden basılır; "geri düşen cepte ~71 kare kalır" yanlış (raf üstüne iner, kayıp yok); §9.5 "`sag` basılıyken S: MP basılmaz" yanlış (MP basılıyor, G açılıyor); G payı 34 kare (taslak ~16); C_A geç basış payı 6 kare (30 px); S eşiği 431..479; kutu basamağı payı 21,0 px; kutu sola itilebilir (x=660) ve orada kilitlenme gerçek ("Baştan başla"). Min klon 3 doğrulandı, kısayol yok.


> **UYARI:** Bu taslağın bütün kare/piksel sayıları TAHMİNDİR (60 kare/sn, HIZ 5 px/kare; ölçüm yapılmadı). Uygulama sonrası ölçümle düzeltilecek (Bölüm 12-14'te taslak sayıları hep ölçümle değişti). Harita konumu: harita agent atayacak.

(`scenes/bolumler/bolum_16.tscn`, `max_klon = 3`, **çözüm tam 3 klon**.) Sabitler `player.gd`, `gecit.gd`, `lazer.gd`, `kutu.gd`, `yayli_ziplatici.gd`, `basinc_plakasi.gd`, `tek_yonlu.tscn` ve Bölüm 14-15 taslaklarından okundu: karakter 28x48, HIZ 5 px/kare, zıplama tepesi 96,5 (kare ~100,9), `ASAGI_DUSME_KARE`=12, zıplatıcı 820 px/sn (tepe ~247, ayak y 353), geçit 20x200 / 2 px/kare, lazer 6 px, kutu 40x40 (karakterler için katı, yalnız `it()` ile itilir), plaka 60x16. `MandalPlaka` varsayım: bir kez basılınca (kutu dahil, `has_overlapping_bodies`) tur sonuna kadar `basili_mi()` true; sahne `scenes/mandal_plaka.tscn`.

## 1. Fikir ve özet
- **Öğrettiği fikir:** mandal plaka = "bir kez dokun, kalıcı". Normal plaka bir tutucu klon ister; mandal kimseyi plakada bırakmaz. Mandalın bulunduğu yer bir cep (kuyu), oradan yalnız zıplatıcıyla çıkılır: normal plaka olsaydı cepte mıhlanan 4. klon gerekirdi (max 3: çözülemezdi).
- Nesneler: mandal plaka x1, plaka x3 (normal), geçit x1, lazer x3, yaylı zıplatıcı x2, tek yönlü raf x1, kutu x1, kapı. YOK: bant, şalter, asansör, zamanlı plaka.
- **Min klon 3** (§8). 4 tur: C_A (~100 kare), C_B (~190), C_C (~260), oyuncu (~330); hepsi ≤ 600.
- İç içe: iki zıplatıcı (F1->F2 ve cepten dönüş), S ile cebe iniş, kalıcı mandal, üç mıhlanmış lazer tutucusu, kutu basamağı (çıkıntıya).

## 2. Kat planı (F1 y=600 koridoru 180 px; F2 y=380 koridoru 200 px, y 180..380)
```
y=0   ┌─────────────────────── Tavan (y 0..180) ─────────────────────────────┐
y=180 │ F2 koridoru  LazerA   G(mandal)  LazerB  LazerC   [K]  ┌─Sehpa(260)─┐│
      │               |         |         |       |             │   [Kapı]   ││
y=380 ├─┐ ┌──[PlakaA]──┴─┐ raf ┌──────[PlakaB]──[PlakaC]───────┤  Sehpa blok││
y=420 │ │ │DöşemeOrtaSol │▒▒▒▒▒│DöşemeOrtaSağ (x540..980)      │  (x980..)  ││
      │ │ Z1 boşluk    W   MP Z2 cep                  DuvarCep (600..1000)   │
y=600 └─[O]──[Z1]──────────────────────────────────────────────────────────────┘
       40   150          400..540 cep (F1 sağ bölge kapalı)
```
- F1: x 0..400 oyuncu bölgesi (Z1 boşlukla F2'ye açılır); W duvarı (x 380..400) F1'i cebe kapatır. Cep (x 400..600) yalnız raftan S ile girilir, Z2 ile çıkılır.
- F2: sol parça (x 0..100), Z1 boşluğu (100..200), DöşemeOrtaSol (200..420), raf boşluğu (420..540), DöşemeOrtaSağ (540..980), Sehpa bloğu (980..1152, üst y=260).

## 3. Nesneler (merkez, boyut)
| Düğüm | Tür | Konum | Boyut / parametre |
|---|---|---|---|
| Zemin | StaticBody2D | (576,620) | 1152x40 |
| Tavan | StaticBody2D | (576,90) | 1152x180 |
| DosemeSol | StaticBody2D | (50,400) | 100x40 (x 0..100) |
| DosemeOrtaSol | StaticBody2D | (310,400) | 220x40 (x 200..420) |
| DosemeOrtaSag | StaticBody2D | (760,400) | 440x40 (x 540..980) |
| DuvarW | StaticBody2D | (390,510) | 20x180 (x 380..400, y 420..600) |
| DuvarCep | StaticBody2D | (800,510) | 400x180 (x 600..1000, y 420..600) |
| Sehpa | StaticBody2D | (1066,320) | 172x120 (x 980..1152, y 260..380) |
| Raf | tek_yonlu.tscn | (480,386) | 120x12 (x 420..540, üst y=380) |
| PlakaA | basinc_plakasi | (260,372) | 60x16 (x 230..290) |
| PlakaB | basinc_plakasi | (670,372) | 60x16 (x 640..700) |
| PlakaC | basinc_plakasi | (800,372) | 60x16 (x 770..830) |
| MP | mandal_plaka.tscn | (450,592) | 60x16 (x 420..480), cepte |
| Z1 | yayli_ziplatici | (150,594) | `firlatma_hizi=820`, sensör x 120..180 |
| Z2 | yayli_ziplatici | (510,594) | `firlatma_hizi=820`, sensör x 480..540, cepte |
| G | gecit.tscn | (600,280) | 20x200 (y 180..380), `kayma_yonu=(0,-1)`, `kayma_mesafe=100`, `hiz=120`, tetik [../MP] |
| LazerA | lazer.tscn | (330,180) | `yon=(0,1)`, `uzunluk=200` (x 327..333, y 180..380), tetik [../PlakaA], `tetik_aktifken_kapali=true` |
| LazerB | lazer.tscn | (740,180) | aynı, tetik [../PlakaB] |
| LazerC | lazer.tscn | (860,180) | aynı, tetik [../PlakaC] |
| Kapi | kapi.gd Area2D | (1070,236) | 36x48 (y 212..260, Sehpa üstü) |
| Kutu | kutu.tscn | (920,360) | 40x40 (x 900..940) |
| Oyuncu | oyuncu.tscn | (40,576) | |
| Bilgi | Label | (16,12) | |

**Ağaç sırası:** Zemin, Tavan, DosemeSol, DosemeOrtaSol, DosemeOrtaSag, DuvarW, DuvarCep, Sehpa, Raf, PlakaA, PlakaB, PlakaC, MP, Z1, Z2, G, LazerA, LazerB, LazerC, Kapi, Kutu, Oyuncu, Bilgi. Güvenlik payları: kutu oyuncudan 880 px (>= 40); asansör yok; G kapalı alt kenar y=380 zemine bitişik, üst kenar tavana bitişik.

## 4. Roller
- **C_A:** Z1 ile F2'ye çıkar, PlakaA'da kalır (LazerA kapalı).
- **C_B:** LazerA'yı geçer, rafta S ile cebe iner, MP'ye basar (G kalıcı açık), Z2 ile döner, G'yi geçer, PlakaB'de kalır.
- **C_C:** LazerA/B'yi geçer, (G açık değilse kendi cep gezisini yapar), PlakaC'de kalır.
- **Oyuncu:** üç lazer kapalı; G açık; kutuyu Sehpa yüzüne iter, kutu üstünden Sehpa'ya, kapı.

## 5. Çözüm (tuş kareleri tahmin)
**Tur 1 (C_A, ~100 kare):** `sag` (Z1'e kare ~13), `sag` basılı tut: kare ~40'ta F2'ye çıkar (gövde x=186'da boşluk duvarına yaslanır), PlakaA'ya kare ~46'da girer; x~260'ta dur, ~15 kare bekle, R.
**Tur 2 (C_B, ~190 kare):** C_A oynar. Aynı yol; LazerA ışınına kare ~65'te varılır (C_A plakada ~46'dan beri). Raf üstünde x 434..465 arası dur (kare ~92), `sag` BIRAK, `asagi` bas: cebe iner (kare ~127, MP'ye değer, mandal). `sag` ile Z2 sensörüne (kare ~130), `sag` basılı tut: cepten çıkış (boşluk duvarında x=526'da yaslanır, kare ~155 F2'de). G'ye kare ~167'de varılır (G ~80 px açık), PlakaB'ye kare ~170'te girilir; x~670'te dur, ~15 kare bekle, R.
**Tur 3 (C_C, ~260 kare):** C_A, C_B oynar. Aynı cep gezisini yapar (ya da G'ye C_B'nin MP basmasından >= ~24 kare sonra varacak şekilde bekleyip cep gezisini atlar). LazerB ışınına kare ~195'te varılır (C_B plakada ~170'ten beri). PlakaC'ye x~800: dur, ~15 kare bekle, R.
**Tur 4 (oyuncu, R kapalı "Klon: 3/3", ~330 kare):** aynı yol; LazerC'yi geç (kare ~235); kutuya kare ~245'te değer, `sag` ~8 kare iter (kutu x=960, Sehpa yüzüne dayanır); kutu üstüne `zipla`+`sag`, ardından Sehpa üstüne `zipla`+`sag`; kapı (kare ~330).

## 6. Zamanlama pencereleri (pay)
| # | Pencere | Pay |
|---|---|---|
| W1 | C_A plakada (kare ~46) -> C_B'nin LazerA ışınına varışı (kare ~65) | **~19 kare** |
| W2 | S konumu rafta: gövde tam raf üstünde (merkez >= 434) ve Z2 sensörüne girmeden (merkez <= 465): MP'ye iner. Sağ tuş bırakılmalı | **31 px** (~6 kare) >= 12 |
| W3 | MP basışı (kare ~127) -> G'nin >= 48 px açılması (kare ~151) -> C_B'nin G'ye varışı (kare ~167) | **~16 kare** |
| W4 | Z2 sensörü: `sag` basılı tutma başlangıcı, sensör girişinden en geç ~28 kare | **~28 kare** (bırakılırsa cebe geri düşer, ~71 kare kayıp, kilit yok) |
| W5 | C_B plakada (kare ~170) -> C_C'nin LazerB ışınına varışı (kare ~195) | **~25 kare** |
| W6 | C_C plakada (kare ~230) -> oyuncunun LazerC ışınına varışı (kare ~235...); oyuncu beklemekle pay üretebilir | alt sınır tek yönlü; **>= 8 kare** (bekleme serbest) |
| W7 | Kutu itme: kutu x 900..940 -> Sehpa yüzü 980; itme mesafesi 40 px | pencere yok (8 kare) |
| W8 | Kutu basamağı: kutu üstü y=340 -> Sehpa üstü y=260: 80 px; zıplama 100,9; pay | **20,9 px** (>= 12) |
- Bant, dikiş ve plaka-bant ayrışması bu bölümde yok. Zıplatıcı uçuş payı: apex ayak y 353, F2 yüzeyi 380: **27 px** (>= 12), tavana baş payı 125 px.

## 7. Atlanamazlık (sahne sayıları)
- **Zemin -> F2:** 220 px > 100,9 (pay 119). Tek yol Z1.
- **F1 -> cep:** DuvarW (180 px, y 420..600) F1'i kapatır; cepe yalnız raftan S.
- **Cep -> kapı:** cep x 400..600 kapalı (DuvarCep); çıkış yalnız Z2 -> F2 sol/sağ parça (G'nin soluna iner).
- **G:** kapalı y 180..380, tavan ve zemin bitişik, boşluk 0; zıplama aşamaz.
- **LazerA/B/C:** ışın y 180..380 (tavan-F2 yüzeyi bitişik); zıplama baş y 251 ve Z1/Z2 uçuş başı 305 ışın bandı içinde; ölür.
- **Sehpa:** üst y=260, F2 yüzeyinden 120 px > 100,9 (pay 19,1; kutusuz çıkılmaz). Kutu üstü 340'tan 80 px: çıkılır (pay 20,9). Tavan alt kenarı y=180: kutu üstünden zıplama baş y min 191 (pay 11 px; ışın ve geçit etkisi yok).

## 8. Kısayol taraması (min 3 düşmez)
| Deneme | Sonuç | Neden |
|---|---|---|
| Klonsuz | olmaz | LazerA'da (kare ~65) ölür |
| 1 klon / 2 klon (tüm sıralar, C_A+C_B, C_A+C_C, C_B+C_C) | olmaz | C_C'siz oyuncu LazerC'de ölür; C_B'siz LazerB; C_A'sız LazerA. Her tutucu kendi lazerinin gerisinde mıhlanır |
| min-1 = 2 klon + oyuncunun kendisi PlakaC'yi tutması | olmaz | oyuncu kapıya gidemez |
| Kutu basamağı | tasarım yolu | Sehpa 120 > 100,9; kutu 80 px kalıyor. Başka basamak yok |
| Kutuyla plaka tutma | kısayol yok | kutu LazerC'nin sağında (x=920): ancak sola itilebilir ama oraya yalnız LazerC'yi geçen biri varır; kutu PlakaC'ye itilirse (oyuncu zaten LazerC'yi geçmiş) basamak kaybolur, tutucu gereksiz (oyuncu geçti): kilitlenme |
| Zıplatıcı + kutu | kısayol yok | kutu Z1'e ulaşamaz (sağda, DuvarW ve F1 ayrı); Z2 cepte, kutu giremez |
| Bant dalgalanması | uygulanamaz | bant yok |
| **Geçit altı park / röle** | işlemez | G'yi mandal açar (kalıcı); park gereksiz. Röle (lazer tutucusu hop): LazerA/B/C plakaları ışınların gerisinde, ayrılan ölür; geçit altı park yalnız G'yi kolaylaştırır, tutucu sayısı değişmez (3 mıhlanmış) |
| S ile yeni iniş yolu | yok | tek raf (cebe iniş zorunlu yol). Sehpa üstü ve F2 sağ parça tek yönlü değil |
| Lazeri zıplayarak aşma | olmaz | §7 |
| Mandal plakayla klon tasarrufu | min'i düşürmez | MP yalnız cep gezisini serbest kılar (4. tutucuyu engeller); A, B, C tutucuları ayrıdır. MP'yi oyuncu kendi son turunda da basabilir; yine A, B, C gerekir |
| Zamanlı plaka | uygulanamaz | bu bölümde yok |
**Min klon 3 kanıtı:** LazerA, LazerB, LazerC sırayla (x=330, 740, 860); tutucuları PlakaA (230..290), PlakaB (640..700), PlakaC (770..830) her ışının 40-90 px gerisinde. Tutucu plakadan ayrılırsa yürüyerek ışına varıp ölür (A: ~2 kare; B: ~5; C: ~7). Sağdaki plakaya ulaşmak soldaki lazerlerin kapalı olmasını gerektirir: C_C geçerken A ve B tutuluyor olmalı; C_B geçerken A. Oyuncu son turda üçünü de geçer. 3 farklı klon şart.

## 9. Başarısızlık senaryoları
1. Klonsuz: LazerA'da ölür.
2. Yalnız C_A: oyuncu G'de takılır (MP basılmadı, G kapalı); cebe inip döner de LazerB'de ölür.
3. C_A + C_B, C_C yok: oyuncu LazerC'de ölür.
4. C_B cep gezisi olmadan: G kapalı, C_B G'ye çarpıp bekler, PlakaB'ye gidemez; oyuncu LazerB'de ölür.
5. Rafta `sag` basılıyken S: cebe sürüklenip Z2 sensörüne iner (merkez > 465), cepten hemen fırlar, MP basılmaz (G kapalı); tekrar iner (kilit yok).
6. Z2'de `sag` bırakılırsa: cebe geri düşer, ~71 kare kayıp.
7. C_B plakadan erken ayrılır: LazerB açılır, C_C ve oyuncu ölür (kayıt tekrarı).
8. Kutu sola itilirse (oyuncu LazerC'yi geçtikten sonra kutunun sağından): basamak kaybolur (§10).

## 10. Kilitlenme analizi
- Kutu geri alınamaz: oyuncu LazerC'den sonra kutunun sağına geçip sola iterse kutu PlakaC/B yönünde gider; Sehpa basamağı kalmaz. Çıkış: "Baştan başla". Kutu LazerC'nin sağında başladığından klon bunu yapamaz (kayıt yok).
- Cebe inen klon çıkışı: Z2 döngüsü; kilit yok.
- G altında klon kalmaz (klonlar G'yi geçip plakada biter).
- Klon asansör yok.
- Kutu cebe giremez (cep yalnız raftan; kutu rafı yürür, S kutuya etki etmez).

## 11. S düşme kullanımı ve riskleri
Tek S: rafta (x 420..540) cebe iniş; merkez 434..465 (MP), 466..526 (Z2 sensörü: anında geri fırlar, mandal basılmaz). S sırasında `sag` basılı tutulmamalı; düşüş ~34 kare. Raf üstünde zıplayarak S'siz geçmek serbest (raf yürünür).

## 12. Geri dönmesi zor kararlar (kullanıcı karar versin)
1. **Cep dönüşü yalnız Z2:** cebe iniş geri dönüşsüz değildir (Z2), ama MP'ye basmadan Z2 sensörüne düşmek ölümsüz zaman kaybıdır.
2. **Kutu LazerC'nin sağında:** kutuyla plaka tutma kısayolunu kapatır; eksi: kutu sola itilirse bölüm kilitlenir ("Baştan başla").
3. **MP cepte:** normal plaka olsaydı 4. klon gerekirdi; mandal bölümü çözülebilir kılar (zorunlu).
4. **Sehpa 120 px, kutu 40 px:** 19,1 px kutusuz pay; kutu ölçümle (zıplama kare tepesi 100,9) yeniden doğrulanmalı.
5. **Harita konumu:** harita agent atayacak.
