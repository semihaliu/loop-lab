# Bölüm 13 taslağı: Kuyu
(Tasarımcı çıktısı; Aşama C'de onaysız uygulama kullanıcı kararı.)

> **UYARI (2026-10-15, ölçümden sonra):** Bu taslağın sayıları tahmindi; test yazarı ve gözden geçirici ölçtü (ayrıntı `docs/sorunlar.md`, "Bölüm 13"). Geçerli değerler: K1 ilk yürüyüşü `sag` **11..18 kare** (testler 12; taslaktaki "8 kare" ÇALIŞMAZ: gövde bant başında ~20 kare takılır, darbe kayar, B LazerA'da ölür); Td (S basma) penceresi P0-21..P0 (22 kare, P0=206); LazerC ışını Td+20..+25, LazerD Td+28..+31, zemin Td+33; B bırakma x 640..720 (730/740 iniş yok, 750+ LazerB'de ölüm); kapak merkez x 975..1065; K2'nin LazerA geçiş gecikmesi 2..26; Z1 köşe payı 38,5 px; PlakaB-LazerB payı ~2 kare; darbe süreleri 13/26/53. Şalter tuzağı: oyuncu SolAlan'dan (x 875..915) sağa yürürse şalteri geri çevirir (LazerD açılır); kapaktan sola yürüyüp tekrar çevirerek düzeltilir, kilitlenme değil. Min klon 3 doğrulandı, kısayol bulunamadı.


(`scenes/bolumler/bolum_13.tscn`) Fizik hesapları `player.gd`, `tasima_bandi.gd`, `yayli_ziplatici.gd`, `lazer.gd`, `salter.gd`, `basinc_plakasi.gd`, `scenes/tek_yonlu.tscn` ve Bölüm 10/11/12 taslaklarından okundu. Koşturulmadı; "ölçülecek" işaretli sayılar tahmindir. Kare modeli 60 kare/sn.

## 1. Özet
- Yeni fikir: **bant, plakayı "darbe"ye çevirir.** Plaka bantın üstündeyse bandın üstünde duran biri plakayı yalnızca geçerken basar (13 / 26 / 53 kare; bkz. §2). İki lazer kapısı böyle darbelerle geçilir; iki geçişten biri **kuyu**dur: zıplatıcıyla çıkılan katın ucundaki tek yönlü kapaktan **S ile düşerek** inilen, geri dönüşü olmayan bir kuyu. Kapı kuyunun dibindedir.
- Nesneler: bant x2, yaylı zıplatıcı x1, şalter x1, lazer x4, plaka x3, tek yönlü x1 (kapak), kapı. **YOK:** kutu, geçit, asansör (geçit altı park/röle kısayolu bu yüzden uygulanamaz, bkz. §9.8).
- `max_klon = 3` (**tam 3 klon gerekir**; kısayol taraması §9).
- Zorluk (B12'ye göre bir kademe): B12 2 klon + 3 teknik; B13 3 klon + 5 teknik (bant darbesi, zıplatıcı katı, plaka tutma, şalter mandalı, S ile düşme) ve klonların birbirinin üstüne zincirlenmesi: ilk klon yalnız "darbe veren" (kendi başına hiçbir yere varamaz), ikinci klon tutucu, üçüncü klon ikinci bir darbe + şalter. Bölüm 11'deki "havada plaka" ve B12'deki "kutu fırlatma / ortak plaka / geçit yarışı" kullanılmaz.

## 2. Sabitler (koddan)
Karakter 28x48 (yarı 14 x 24), HIZ 300 (5 px/kare), zıplama tepesi 96,5 (kare ~100,9), g 1400 (n kare serbest düşüşte yer değiştirme 0,1944·n(n+1) px). Bant `hiz` 100 px/sn = 1,667 px/kare: bant yönünde girdi 6,667 px/kare, girdisiz 1,667, ters girdi 3,333 (net), havada yalnızca yon*300 (`velocity.x = yon*HIZ`). Plaka 60x16, karakter merkezi x0±44 içindeyken basılı (88 px): girdisiz bantta 52,8 kare, bantla yürüyerek 13,2 kare, banda karşı yürüyerek 26,4 kare. Zıplatıcı: sensör 60x12, 820 px/sn, ölçülen tepe 247 px (testte 240±15), yalnız velocity.y ≥ 0; tetik: karakter merkezi x_z±44 içinde. Kare modeli (B11/B12'den): R(K)=(820K-11,667K(K-1))/60: K=20 → 199,5; K=30 → 240,8; K=36 → 247; K=51 → ~200 (zemin seviyesinden 200 px yukarıdaki kata iniş). Lazer KALINLIK 6; plaka bırakıldıktan sonra lazer ~1-2 kare gecikmeyle açılır (plaka Area çakışması + `set_deferred("monitoring")`), öldürme +1-2 kare daha gecikir. Tek yönlü: kalınlık 12, margin 4; S ile `ASAGI_DUSME_KARE`=12 kare yok sayılır.

## 3. Kat planı (yüzeyler: zemin 600, kat 400; tavan alt kenarı 150)
Şema (x ekseni; kat yüzeyi y=400, zemin y=600, tavan alt kenarı y=150):
```
x:  0     100   260   320   490 550   640        760   780       940 960     1080 1152
    spawn BantA(→)      LA    [Z1]    ┌── KatA ──┐ LB   BantC(→)    KatB ╔Kapak╗ KatC
    ●     ▒▒▒▒▒▒▒ [PA]   │            │ [PB]     │ │    ▒▒▒▒▒▒▒▒ [PC](S) │  ╚kuyu╝
                         │      kat y=400 yüzeyi                       LC y=470 ═══
                                                                      LD y=540 ═══
                                                                      Kapı (1020,576)
```
- Sol salon x 0..640 (zemin 600). x=640'ta KatA'nın sol yüzü (200 px, zıplamayla aşılmaz).
- Kat yüzeyi y=400, x 640..960 (KatA, BantC, KatB). Kapak (tek yönlü) x 960..1080, üstü y=400. Sağda KatC sütunu x 1080..1152. Kuyu: x 960..1080, y 412..600 (üstü kapak, altı zemin, yanları dolu). Kuyuya **başka giriş yok**.
- Zıplatıcı Z1 sol salonda (x=520), kat sol yüzünün 120 px solunda.

## 4. Nesneler (merkez)
| Düğüm | Tür | Konum | Ayrıntı |
|---|---|---|---|
| ZeminSol | StaticBody2D | (50,620) | 100x40 (x 0..100) |
| BantAlti | StaticBody2D | (180,628) | 160x24 (x 100..260, y 616..640) |
| ZeminSag | StaticBody2D | (706,620) | 892x40 (x 260..1152) |
| Tavan | StaticBody2D | (576,75) | 1152x150 (y 0..150) |
| KatA | StaticBody2D | (710,500) | 140x200 (x 640..780, y 400..600) |
| BantDolgu | StaticBody2D | (860,508) | 160x184 (x 780..940, y 416..600; BantC altı) |
| KatB | StaticBody2D | (950,500) | 20x200 (x 940..960, y 400..600) |
| KatC | StaticBody2D | (1116,500) | 72x200 (x 1080..1152, y 400..600) |
| Kapak | scenes/tek_yonlu.tscn | (1020,406) | 120x12, üst y=400, x 960..1080 |
| BantA | scenes/tasima_bandi.tscn | (180,608) | yon=1, hiz=100, üst y=600, x 100..260 |
| BantC | scenes/tasima_bandi.tscn | (860,408) | yon=1, hiz=100, üst y=400, x 780..940 |
| PlakaA | basinc_plakasi | (180,592) | 60x16, BantA üstü, x 150..210 (basma penceresi merkez 136..224); LazerA'yı kapatır |
| PlakaB | basinc_plakasi | (680,392) | 60x16, KatA üstü, x 650..710 (merkez 636..724); LazerB'yi kapatır |
| PlakaC | basinc_plakasi | (840,392) | 60x16, BantC üstü, x 810..870 (merkez 796..884); LazerC'yi kapatır |
| Salter | salter.tscn | (915,400) | `baslangic_sagda = true`; SolAlan x 875..915, SagAlan x 915..955 (y 352..400); LazerD'yi sola gelince kapatır |
| Ziplatici | scenes/yayli_ziplatici.tscn | (520,594) | firlatma_hizi=820; yüzey y=600, sensör x 490..550 |
| LazerA | scenes/lazer.tscn | (320,150) | yon=(0,1), uzunluk=450 (x 317..323, y 150..600), tetikleyici=[../PlakaA], tetik_aktifken_kapali=true |
| LazerB | scenes/lazer.tscn | (760,150) | yon=(0,1), uzunluk=250 (x 757..763, y 150..400), tetikleyici=[../PlakaB], tetik_aktifken_kapali=true |
| LazerC | scenes/lazer.tscn | (960,470) | yon=(1,0), uzunluk=120 (x 960..1080, y 467..473), tetikleyici=[../PlakaC], tetik_aktifken_kapali=true |
| LazerD | scenes/lazer.tscn | (960,540) | yon=(1,0), uzunluk=120 (x 960..1080, y 537..543), tetikleyici=[../Salter], acik_taraf_sag=false, tetik_aktifken_kapali=true |
| Kapi | kapi.gd Area2D | (1020,576) | 36x48 (x 1002..1038, y 552..600) |
| Oyuncu | oyuncu.tscn | (60,576) | |
| Bilgi | Label | (16,12)-(600,40) | |

Ağaç sırası: ZeminSol, BantAlti, ZeminSag, Tavan, KatA, BantDolgu, KatB, KatC, Kapak, BantA, BantC, PlakaA, PlakaB, PlakaC, Salter, LazerA, LazerB, LazerC, LazerD, Ziplatici, Kapi, Oyuncu, Bilgi (plaka/şalter/lazer karakterlerden önce). Her StaticBody2D parçasında `Gorsel` ColorRect. `max_klon = 3`. Başlangıç: LazerA/B/C açık (öldürücü), Şalter sağda: LazerD açık.

Lazer D mantığı: `aktif_mi()` şalter `sagda == acik_taraf_sag(false)` yani şalter SOLDA iken aktif, `tetik_aktifken_kapali=true` ile lazer kapanır. Şalter sağdayken LazerD açık.

## 5. Roller
- **K1 (A):** yalnız darbe verir. BantA'da girdisiz sürüklenerek PlakaA'yı ~53 kare basılı tutar (LazerA kapanır), sonra bant sonunda (x≈274) durur. LazerA'yı kendisi geçemez (plakadan ayrılınca ışın açılır, ışına 79 px/12 kare uzak). **İlk klon her zaman K1'dir** (yalnız oyuncu varken kimse LazerA'yı geçemez).
- **K2 (B):** A'nın darbesiyle LazerA'yı geçer, Z1 ile kata çıkar, **PlakaB'ye iner ve sonsuza dek durur** (LazerB kapalı kalır).
- **K3 (C):** aynı yolla kata çıkar, B'nin tuttuğu LazerB'yi geçer, bandın üstünden kapak kenarına varır, **geri döner**: dönerken şalteri sola çevirir (LazerD kapanır, mandal), sonra PlakaC'ye bantın aksi yönünde yürüyerek ~26 karelik darbe verir (LazerC kapanır). Sonra LazerB'den geri geçip bırakır.
- **Oyuncu (4. tur):** aynı yoldan kata çıkar, LazerB'yi geçer, kapak üstünde C'nin dönüşünü bekler, **S'ye basarak** kuyuya düşer: düşerken LazerC (C'nin darbesi) ve LazerD (şalter mandalı) geçilir, kapıya yürür.

## 6. Çözüm (tuş kareleri tahminidir; testler "koşula kadar bekle" ile yazılır)
Ortak ön yol (**K2, K3, oyuncu** için aynı): `sag` basılı. Kareler (spawn x=60): kare ~5'te bant (x=86), kare ~13 PlakaA penceresi (x=136), ~26'da pencereden çıkış (x=224), ~33'te bant sonu (x=274), **39,2-46'da LazerA ışınında** (x 303..337), ~74'te Z1 sensörü (x≈476) → fırlatma. `sag` uçuşta basılı tutulur; kare 30'da x=626 (sağ kenar 640, ayak 359 < 400), kare ~51'de x=731 ve ayak y=400: kata iner.
- **Tur 1 → A (~115 kare):** `sag` 8 kare (x≈103, bantta), sonra girdi YOK (sürüklenir). PlakaA'ya merkez 136'da girer (kare ~28), 224'te çıkar (kare ~81), bant sonunda x=274'te (kare ~110) durur. R. (LazerA'ya mesafe: sağ kenar 288, ışın sol kenarı 317: **29 px pay**.)
- **Tur 2 → B (~145 kare):** ortak ön yol, A'nın darbesi kare ~29..81 (ışın geçişi kare 39..46 = darbe içi). Fırlatmadan sonra `sag`'ı K≈45'te bırak (x≈701, doğrudan PlakaB üstüne in; kare ~125), bekle, R. PlakaB kare ~126'dan basılı. (LazerB bu turda açıktır: iniş x ≤ 735 olmalı, sağ kenar ≤ 749 < 757: **12 px pay**; `sag`'ı hiç bırakmazsan x=731 → 14 px pay yine güvenli.)
- **Tur 3 → C (~245 kare):** ortak ön yol; K≈45'te `sag` bırak, ~6 kare bekle (B kare ~126'dan PlakaB'de, LazerB kapalı kare ~128); `sag` ile LazerB'yi (kare ~132-139) geç, bant ve KatB'den kapak kenarına, x≈985'e (kare ~173) var, `sol`'a geç: x=969'da şalter SagAlan'a girer (kare ~176) **şalter sola döner, LazerD kapanır**; `sol` sürekli: PlakaC penceresine merkez 884'te girer (kare ~200), 796'da çıkar (kare ~226) (**darbe ≈ 26,4 kare**, kare ~200..226); `sol` ile LazerB'den (B tutuyor) x≈735'e kadar yürü, bırak, R.
- **Tur 4 (R kapalı, "Klon: 3/3") → oyuncu (~235 kare):** ortak ön yol, B'nin PlakaB'de durmasından sonra LazerB'yi geç (kare ~133-140), kapak üstüne x≈985'e var (kare ~172), **dur**; C'nin x≈985'ten `sol`'a dönüp şalteri çevirmesinden sonra (kare ~176 işaret: şalter kolu sola döner) **~10-14 kare bekle**, `asagi` (S) bas: kuyuya düşer. Düşme: S basma karesi Td; gövde LazerC ışınında Td+19..Td+24, LazerD ışınında Td+27..Td+30, zemine Td+32. LazerC'nin kapalı olduğu kare aralığı [P0+1, P0+26] (P0≈200). `Td ∈ [P0-18, P0+2] ≈ [182, 202]` (**20 kare**). İndikten sonra kapıya (x 1002..1038) ~3-10 kare yürü.

## 7. Zamanlama pencereleri (kare; ölçülecek)
| Pencere | Genişlik | Neden |
|---|---|---|
| LazerA geçişi (K2/K3/oyuncu) A'nın darbesine göre | başlangıç gecikmesi s ∈ [-10, +34] | darbe [28..81], ışın geçişi s+39..s+46; A girdisiz (52,8 kare) |
| B'nin iniş x'i (LazerB açıkken) | x ∈ [626, 735] | sol sınır kat yüzü (ayak desteği), sağ sınır ışın sol kenarı 757-14 |
| Z1 fırlatma → kat | `sag` ≥ 30 kare, ayak tepede 359 | kat sol köşesi (x 640, y 400): K=30'da x=626 |
| PlakaB → LazerB boşluğu | 19 px = 3,8 kare | plaka bırakınca ışın ~2 karede açılır; ışın 6,8 kare süren geçiş: ölür (**tutucu zorunlu**) |
| Oyuncunun LazerB'yi geçişi | B'nin PlakaB'ye basmasından ~2-6 kare sonra (kare ≥128) | LazerB kapanma gecikmesi |
| Şalter mandalı (C) → LazerD ışını | şalter kare ~176, LazerD ışını Td+27 ≈ 209+ | pay ≥ 30 kare |
| S basma Td → LazerC ışını | Td+19..Td+24 darbenin [P0+1, P0+26] içinde olmalı | C'nin 26,4 kareli darbesi (6 kare ışın) → **Td penceresi ~20 kare**; C girdisiz bırakırsa 53 kare, bantla yürürse 13 kare (Td penceresi ~7 kare) |
| S düşmesi için kapak x'i | merkez ∈ [974, 1066] | gövde sol kenarı ≥ 960 (KatB duvarı), sağ kenar ≤ 1080 |

**Önemli (dürüst not):** bantlı plaka "elle tutulabilir": kaydeden oyuncu bantta girdiyle dalgalanıp plakayı istediği kadar basılı tutabilir. Bu yüzden darbe süreleri tasarım tarafından **zorlanmaz**, kayıt edenin seçimidir (13 / 26 / 53 kare ya da dalgalanarak sonsuz). Zorluk "klonların zincir bağımlılığı + 5 teknik + kuyunun geri dönüşsüzlüğünde"dir; en sıkı fiziksel pencereler lazer geçiş süreleridir (LazerA 6,8, LazerB 6,8, LazerC 6, LazerD 4 kare). İstenirse zamanlama sıkılığı geçit eklenerek (B12'deki yarış) artırılabilir; bkz. §13 karar 2.

## 8. Atlanamazlık hesapları
- Zeminden kat: 200 > 100,9 (zıplama); kutu yok; tek çıkış Z1: tepe ayak y=353 (en kötü ~375) < 400 (47 px / en kötü 25 px pay).
- Kat sol köşesi: Z1 sensörü merkezi x0 ≤ 564 (zıplatıcıya zıplayarak girmek dahil); `sag` basılı fırlatmada kare 30'a kadar x ≤ 626 (sağ kenar ≤ 640, ayak y ≥ 359) yani köşeye çarpmaz.
- **LazerB Z1 uçuşuyla aşılamaz:** ışın y 150..400, uçuş gövdesi y 305..400 aralığında; ışın sol kenarına (x=757) varmak için gerekli K ≥ (743-476)/5 = 53 > 51 (kata iniş); sensörde x0=564'ten (zıplayarak giriş) 564+5·36=744 → K=36'da (ayak 353, gövde 305..353) ışının içinde: ölür. Tavan alt kenarı 150, ışın tavandan başlar: üstten geçiş yok.
- LazerA: tavandan (150) zemine (600) tam: zıplayarak aşılamaz (tepe 96,5 px).
- LazerC/LazerD: kuyuyu duvardan duvara kapatır (x 960..1080); düşüşte yana kaçış yok.
- Kuyuya giriş: yalnız kapak (üstten). Kapak KatB/KatC arasında. Zıplatıcı ile yukarıdan kuyuya: kuyu tabanı ayak y 600, uçuşun inişi katı bulur (x 640..960 ya da kapak üstü); sensör x0 ≤ 564 + 5·71 = 919 < 974 (kuyu düşme sütunu): kuyuya uçarak giremez.
- Kapak üstünde durmak: tek yönlü, yukarıdan katı; S olmadan kuyu açılmaz.
- Kapı yalnız kuyudadır (x 1002..1038, kuyu dibi).

## 9. KISAYOL TARAMASI (zorunlu; gozden-gecirici bağımsız kontrol eder)
| Deneme | Sonuç | Neden |
|---|---|---|
| 1. Klonsuz | olmaz | LazerA'yı geçecek darbeyi verecek ikinci beden yok; kendi darbesi 12 kare uzakta biter |
| 2. Yalnız K1 (A) | olmaz | LazerB'de ölür: PlakaB'yi kendisi basıp ışına gidemez (19 px / 3,8 kare sonra ışına girer, lazer ~2 karede açılır) |
| 3. K1 + tutucu (2 klon, B) | olmaz | oyuncu LazerB'yi geçer, kapakta LazerC'yi kapatacak kimse yok. Oyuncunun PlakaC'de kendi darbesi: plakadan çıkıp kapağa varış ≥ 15 kare + S + 19 kare düşüş ≫ 1-2 kare. B kendisi PlakaC'ye gidemez: LazerB'den geçmek için PlakaB'yi tutan başka beden gerekir |
| 4. 2 klon, K2 darbeci kat tarafında | olmaz | LazerB'yi geçen ilk klonun hâlâ bir tutucusu gerekir; tutucu (sol tarafta kalan) klon sonra kapağa varamaz; kat tarafındaki bedenler (B değil C) **iki ayrı klon** + A = 3 |
| 5. Tutucu kapak tarafına geçip PlakaC'ye geçer (röle) | olmaz | tutucu LazerB'yi geçmek için başka tutucu ister; tek tutucu yok. PlakaB → PlakaC arası ışının öbür yanında |
| 6. Oyuncu PlakaC'yi bantta dalgalanıp tutar, kapağa gider | olmaz | PlakaC penceresi (x ≤ 884) ile kapak düşme sütunu (x ≥ 974) arası ≥ 90 px; aynı beden aynı anda iki yerde değil |
| 7. Plaka kapak üstüne (uçuş/kapak darbesi) | uygulanamaz | PlakaC yalnız bantta; kapak üstünde plaka yok; kuyu içinde plaka yok |
| 8. **Geçit altı park / röle** | uygulanamaz | bölümde geçit ve asansör yok (Bölüm 6 bulgusu bu bölümü etkilemez). Plaka rölesi: PlakaA'yı tutan K1 sol salonda kalır (hiçbir yere varamaz), PlakaB tutucusu LazerB'nin sol yanında kalır, PlakaC darbesi LazerB'nin sağ yanındadır |
| 9. Lazeri zıplayarak aşma | olmaz | LazerA, LazerB tavandan zemine/kata tam; LazerC/D kuyuyu duvardan duvara kapatır |
| 10. Zıplatıcı + bant kombinasyonu | olmaz | Z1 BantA'dan 230 px uzakta; havada bant etkisi yok (yalnız yon*300); Z1 uçuşu LazerB'yi aşamaz (§8) |
| 11. Z1'den doğrudan kuyuya | olmaz | menzil 919 < 974; ayrıca LazerB |
| 12. Şalter itmeyle yolu kısaltma | etkisiz | şalter yalnız LazerD'yi kapatır; oyuncu kendisi sola çevirebilir, bu klon saymaz çünkü LazerC için C zaten gerekli |
| 13. S ile düşmenin açtığı yeni iniş yolları | kısaltma yok | tek yönlü yalnız kapak; kapaktan kuyuya tek yönlü; katın sol kenarından zemine yürüyerek inmek (S'siz) geri dönüş; kuyudan çıkış yok |
| 14. Kutu basamağı, kutuyla plaka tutma | uygulanamaz | kutu yok |
| 15. A'nın darbesi bir kez, hepsi birlikte (B+C+oyuncu aynı karede) | tasarım gereği | LazerA ışın geçişi 6,8 kare; üç beden aynı girdi kaydıyla aynı karede geçer, A tek darbe yeter |

Min klon = 3. Gerekçe (kısa): kat tarafındaki **ilk** beden (B) LazerB'yi geçmek için sol tarafta kalan bir tutucu ister; tutucu klon olmak zorunda (oyuncu en sona kalır) → B tutucu olarak sol tarafta kalır → LazerB'yi geçen **ikinci** klon (C) hem tutucuya hem A'nın darbesine bağlıdır; oyuncu son tur; LazerC darbesi kat tarafındaki bir klon (C) olmak zorunda; ilk klon (A) yalnız darbe verir. 3 bağımsız bedene indirgenemez.

## 10. Kilitlenme analizi ("Baştan başla" ile giderilir)
1. K1 yanlış kaydedilirse (darbe yok / kısa): sonraki klonlar LazerA'da ölür (donar); klon hakkı harcanır: "Baştan başla".
2. K2 PlakaB'ye basmadan biterse ya da inişi x > 743: LazerB'de ölür/ışın açık; "Baştan başla".
3. K3 LazerB açıkken geçerse ölür, donar, etkisiz: "Baştan başla".
4. Oyuncu kuyuya düşüp LazerC/LazerD'de ölür: tur yeniden başlar, klonlar korunur (kilitlenme DEĞİL).
5. Oyuncu kuyuya düşüp kapıya ulaşamaz durumda kalmaz (kuyu dibi 120 px, kapı içinde). Kuyudan çıkış yok ama bu bölüm sonudur.
6. Klon bantta kalırsa (kayıt hatası): sürüklenir, zararsız. Klon kuyuda biterse (kayıt hatası) donabilir ama plaka/şalteri etkilemez, oyuncuya engel olmaz (karakter karakterle çarpışmaz).
7. Şalter yanlış konumda biterse: oyuncu kendisi çevirir (SagAlan'da `sol`, SolAlan'da `sag`).
Asansör/geçit/kutu olmadığından "asansör altında klon", "kutu geri alınamaz" kilitlenmeleri yoktur.

## 11. Başarısızlık senaryoları (test-yazarı için)
1. Klonsuz: LazerA'da ölür.
2. Yalnız A: LazerB'de ölür.
3. A + B (C yok): LazerC'de ölür (kuyuda).
4. A + C (B yok; C LazerB'de ölür).
5. A, B, C ama oyuncu S'yi erken basar (Td < P0-18): LazerC'de ölür.
6. Oyuncu S'yi geç basar (Td > P0+2): LazerC'de ölür (darbe bitti).
7. C şalteri sola çevirmeden döner ve oyuncu da çevirmezse: LazerD'de ölür.
8. B iniş x ≥ 743: LazerB'de ölür.
9. Oyuncu kapakta x < 974'te S'ye basar: KatB sol duvarına dayanır, düşmez.
10. R3'ten sonra 4. R: klon kaydetmez (max_klon=3).

## 12. Riskler / ölçülecekler
- Z1 uçuşunda K=30'daki köşe payı: x=626 sağ kenar 640 → ayak 359 (pay 41 px). Ölçülecek.
- Bant/zemin ve bant/KatB dikişleri (x=100, 260, 780, 940): `platform_on_leave`, takılma (B10 aynı risk). BantC–KatB bitişikliği için bant sonu x=940 ile KatB x=940 arasında 0 px; gövde x∈[926,954] aralığında hem bant hem KatB üstünde olur (platform hızı belirsiz).
- C'nin dönüşte bantın üstündeki yürüyüşü 3,33 px/kare olmalı; kapak kenarı → bant geçişinde hız 5 → 3,33.
- PlakaB → LazerB 19 px (3,8 kare) payı: lazer açılma gecikmesinin 1-2 kare olduğu varsayıldı.
- LazerA/B yayıcı (`Govde` 12x16) tavan içinde; ışın zemin/kata değer: yayıcı y=150, ışın uzunluğu 450/250, görünümde zemine/kata değmesi gerekir.
- Kuyuda düşüş zamanlaması: 0,1944·n(n+1) modeli; ölçülen S basma karesi ve `_yok_sayma_kare` (12) etkileşimi ölçülmeli.
- Şalter: SagAlan x 915..955 kapak/KatB sınırına (940, 960) denk gelir; gövde `girdi_al()["yon"]` ile çalışır (klonda kayıt).
- LazerD yayıcısı (960,540) kuyu duvarında; kapı üstünden geçmez (y 537..543, kapı üstü 552).

## 13. Karar gerektiren / geri dönmesi zor noktalar
1. **max_klon = 3 ve min 3.** B14 final de 3 klon olduğundan B14'ün başka bir yönden (ör. kutu + geçit eklenmesi, 3 klon + daha sıkı yarış) ayrışması gerekir.
2. **Zamanlama sıkılığı "zorlanmaz".** Bantlı plaka kayıt edenin elinde 13–53 kare ya da sonsuz (dalgalanma). Fiziksel sıkı pencereleri yalnız lazer geçiş süreleri (4–7 kare) belirler. Daha sıkı istenirse geçit eklenmeli (B12'nin yarışı) ama o zaman Bölüm 6'daki park/röle kısayolu taranmalı; ya da bant yerine plakaya "kalıcı" ihtiyaç kalmaması için bölüm yeniden tasarlanır.
3. **Kuyu geri dönüşsüz** (tek yönlü + S ile giriş, çıkışsız). Kapı kuyuda olduğu için bölüm sonudur; kullanıcı beğenmezse kapıyı kuyu dışına alıp çıkış (zıplatıcı) eklemek ek mekanik gerektirmez ama bölümü uzatır.
4. **Şalter rolü zayıf:** tek başına klon zorlamaz (oyuncu kendisi çevirebilir). Gerçek zorlayıcı yapmak için bölümde şalter başka bir yerde olmalı (ör. yalnız klonun gidebildiği kat) ama bu ek bir ışın/yol ister; kullanıcı kararı.
5. Kutu bilerek kullanılmadı (B12 ile çakışma + kısayol yüzeyi). İstenirse kutu "PlakaB tutucusu yerine" eklenebilir ama basamak (40 px) kısayolunu yeniden taramak gerekir.
6. Plaka-bant dikişi ve görsel okunabilirlik: iki bant yan yana değil ama PlakaB/PlakaC/PlakaA görünümü lazerle bağı belli etmeli (renk).

## 14. B12 ile çakışma
- B13 kullanır: bant x2 (B10'da da), zıplatıcı x1 (B11/B12'de de), şalter x1 (B5-8'de de), lazer x4, plaka x3, tek yönlü x1 (B12'de de), kapı.
- B12'den farklı: kutu yok, geçit yok, "ortak plaka" yok, "yarış" yok; zıplatıcı karakteri kata taşır (kutuyu değil).
- B11'den farklı: plaka havada değil; lazerler tek yönlü kapakla kuyuda, bant darbesi.
- B10'dan farklı: bant kutuyu değil karakterin plaka darbesini üretir; kutu yok.

## 15. Harita
`{"yol": "res://scenes/bolumler/bolum_13.tscn", "konum": Vector2(1070, 350), "onceki": "res://scenes/bolumler/bolum_12.tscn"}`.
- Mevcut 12 düğümle mesafeler (px): B1 741,7; B2 262,5; **B3 108,2**; B4 411,5; B5 642,9; B6 850,0; B7 920,2; B8 855,1; B9 641,3; B10 458,8; B11 281,1; B12 126,5. Hepsi ≥ 100 (en yakın B3, 108,2).
- Çizgi: B12 (1030,230) → B13 (1070,350); `HEX_YARICAP`=34 ile kısaltılmış uçlar. Başka düğüme en yakın mesafesi B3'e ≥ 108 (uç noktası), B13 düğümü ile B2-B3 çizgisi arası 107,4 (> 34). Python ile yaklaşım (test mantığı): mevcut 11 çizgi + yeni çizgi için hiçbir çift kesişmiyor, hiçbir çizgi başka düğüme 74 px'ten yakın değil; ortak düğüm (B12) çıkışları (B11 yönü ve B13 yönü) arasındaki açı: B12→B11 (−180,−55), B12→B13 (40,120): nokta çarpımı −0,28 (> 0,985 değil), üst üste binme yok.
