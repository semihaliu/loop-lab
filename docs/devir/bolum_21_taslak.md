# Bölüm 22 taslağı (v2, sıfırdan): Fitil ve Mühür (ad önerisi; eski ad "Çifte Mühür")

**DURUM: ONAYLANDI (2026-10-16, kullanıcı); yeni bölüm olarak uygulanır (eski B16/B17 oyunda aynen kalır)**

(Tasarımcı çıktısı, Parça 3. Eski `bolum_17_taslak.md` değiştirilmedi; yalnızca ne OLMAMASI gerektiğini görmek için okundu, bkz. §0.)

> **UYARI: Bütün kare/piksel zaman sayıları TAHMİNDİR.** Kare modeli: 60 kare/sn, yatay 5 px/kare, sürekli fizik formülü. Ölçüm yapılmadı; `test-yazari` ölçecek (§12). Önceki taslaklarda sayılar ölçümle saptı (eski B17'de fitil payı taslakta ~21, ölçümde 17 / çıkışa göre 7 kare çıktı). Bu yüzden bu taslakta **hiçbir zorunlu pencere 50 karenin altında değil** ve hepsi "gör, bekle, geç" türünde: kimse kare saymak ya da başka bir klonun zamanını tahmin etmek zorunda değil.

`scenes/bolumler/bolum_22.tscn`, **`max_klon = 2` (öneri, §15 soru 1)**, **çözüm tam 2 klon**, `ipucu_klon = 0`. Harita konumu (6x4 ızgara kararıyla güncellendi): (500,510). `BolumListesi` adı önerisi: "Fitil ve Mühür".

## 0. Eski B17'den alınan ders (yapılmayacaklar)
- `tutma_kare = 70` ile fitil koşusu 7–17 kare pay bırakıyordu: **haksız zamanlama.** Burada fitil varsayılan 180 kare; koşan kişi geçidin dibinde bekler, pay ~190 kare.
- Zıplatıcı uçuşunda görünmeyen köşe çarpması, cepte iki özel plaka + Z2 sensörü birbirine bitişik, kutu kilidi, ters bant, üç mıhlanmış lazer: **hepsi çıkarıldı.** Zıplatıcı, kutu, bant YOK.
- Eski tasarımda iki özel plaka "aynı cepte yan yana" idi; hangisinin neyi açtığı okunmuyordu. **Burada her özel plaka açtığı geçidin tam altında / yanında.**

## 1. Fikir ve özet
- **Öğrettiği tek fikir:** "Fitil kapıyı açar, mühür kalıcı kılar; fitili yakan ile kapıdan geçen farklı kişidir." Zamanlı plaka (fitil) bir kuyuda: ona basan yukarı geri çıkamaz. Fitilin açtığı geçidin ardında mandal (mühür) var. Bu yüzden biri aşağıda fitili yakar, diğeri yukarıda geçidin önünde bekleyip içeri girer, mührü basar.
- B15 (fitil) ve B21 (mandal) burada birleşir; yeni olan **iki klonun birbirine iş devretmesi** ve her iki klonun da iki iş yapmasıdır: A = fitil + PA tutucu, B = mühür + PB tutucu.
- Nesneler: zamanlı plaka x1 (180), mandal plaka x1, normal plaka x2, geçit x2, lazer x2, tek yönlü raf x1 (S ile kuyuya iniş), kapı. YOK: zıplatıcı, kutu, bant, şalter, asansör.
- 3 tur: A (~180 kare), B (~285), oyuncu (~295). Hepsi < 600. En uzun bekleme ~110 kare (~1,8 sn).
- **B21'dan zor çünkü:** iki klon da çift iş yapar; aralarında görünür bir iş devri (yakan → koşan) var; kuyu dönüşsüz (S kararı); `max_klon = 2` ile iki özel plakanın ikisi de anlaşılmadan çözülmez.

## 2. Kat planı (piksel; F2 koridoru y 180..380 = 200 px; F1 kuyusu y 420..600 = 180 px)
```
x:  0  50  110 160 180 226 254 320       440  517 523   640 660  760  820  900 906  1072 1108 1152
y=0   +----------------------------------- Tavan (y 0..180) ---------------------------------------+
y=180 |   ODA      |G|                         LA      |GM|                LB                       |
      |  (mühür    |#|   O                     |       |##|                |                       |
      |   odası)   |#|                         |       |##|                |           [Kapı]      |
      |  [ M ]     |#|                         |       |##|   [ PB ]       |          1072..1108   |
y=380 +------------|#|------------+==Raf==+----+-------|##|----------------+-----------------------+
      | DosemeSol (x 0..320)      |320..440|   DosemeSag (x 440..1152, y 380..420)                  |
y=420 +----+                      +  S ile +                +---------------------------------------+
      |Blok|        K U Y U   (x 100..600, dönüşsüz)        |  BlokF1Sag (x 600..1152, y 420..600)  |
      |F1  |   [ZP] (G'nin tam altında)    [PA] (LA'nın     |                                       |
      |Sol |   150..210                     490..550 altında)                                       |
y=600 +----+--------------------------------------------------+---------------------------------------+
```
- O = başlangıç (240,356). Oda (x 0..160) yalnız G'den girilir; içinde mühür M.
- Raf (x 320..440) üstünden yürünür; yalnız S ile kuyuya inilir. Kuyudan çıkış yok (220 px).
- Kuyuda ZP, G'nin tam altında (aynı x); PA, LA'nın tam altında (aynı x): "aşağıdaki plaka yukarıdaki şeyi kontrol eder" dikey hizayla okunur.

## 3. Nesneler (merkez, boyut) ve görünüm
| Düğüm | Tür | Konum (merkez) | Alan / parametre | Görünüm (çizim) |
|---|---|---|---|---|
| Zemin | StaticBody2D + Gorsel | (576,620) | 1152x40 (y 600..640) | DUVAR |
| Tavan | StaticBody2D + Gorsel | (576,90) | 1152x180 (y 0..180) | DUVAR |
| DosemeSol | StaticBody2D + Gorsel | (160,400) | 320x40 (x 0..320, y 380..420) | DUVAR |
| Raf | `tek_yonlu.tscn` | (380,386) | 120x12 (x 320..440, üst y=380) | TEK_YONLU: gri ızgara + yeşil üst çizgi |
| DosemeSag | StaticBody2D + Gorsel | (796,400) | 712x40 (x 440..1152, y 380..420) | DUVAR |
| BlokF1Sol | StaticBody2D + Gorsel | (50,510) | 100x180 (x 0..100, y 420..600) | DUVAR |
| BlokF1Sag | StaticBody2D + Gorsel | (876,510) | 552x180 (x 600..1152, y 420..600) | DUVAR |
| PlakaM (mühür) | `mandal_plaka.tscn` | (80,372) | 60x16 (x 50..110, y 364..380), `mandal = true` | PLAKA_MANDAL: plaka + üstte asma kilit (y≈350); basılınca yeşil, KALICI |
| PlakaZ (fitil) | `zamanli_plaka.tscn` | (180,592) | 60x16 (x 150..210, y 584..600), **`tutma_kare = 180` (varsayılan; sahnede DEĞİŞTİRME)** | PLAKA_ZAMANLI: plaka + üstte 40 px sayaç şeridi (y≈570), kalan süreyle azalır, son %34'te kırmızı |
| PlakaA | Area2D + `basinc_plakasi.gd` | (520,592) | 60x16 (x 490..550, y 584..600) | PLAKA |
| PlakaB | Area2D + `basinc_plakasi.gd` | (790,372) | 60x16 (x 760..820, y 364..380) | PLAKA |
| GecitG (oda kapısı) | `gecit.tscn` | (170,280) | 20x200 (x 160..180, y 180..380); `kayma_yonu=(0,-1)`, `kayma_mesafe=100`, `hiz=120`, **`tetikleyici_yollari=[../PlakaZ, ../PlakaM]`** (VEYA) | GECIT (z −1) |
| GecitM | `gecit.tscn` | (650,280) | 20x200 (x 640..660, y 180..380); aynı; `tetikleyici_yollari=[../PlakaM]` | GECIT |
| LazerA | `lazer.tscn` | (520,180) | `yon=(0,1)`, `uzunluk=200` → ışın x 517..523, y 180..380; tetik [../PlakaA], `tetik_aktifken_kapali=true` | LAZER |
| LazerB | `lazer.tscn` | (903,180) | `uzunluk=200` → ışın x 900..906, y 180..380; tetik [../PlakaB], kapalı=true | LAZER |
| Kapi | Area2D + `kapi.gd` | (1090,356) | 36x48 (x 1072..1108, y 332..380) | KAPI |
| Oyuncu | `oyuncu.tscn` | (240,356) | 28x48 (x 226..254, y 332..380) | OyuncuGorunum / klon |
| Bilgi | Label | (16,12) | | HUD |

**Ağaç sırası:** Zemin, Tavan, DosemeSol, Raf, DosemeSag, BlokF1Sol, BlokF1Sag, PlakaM, PlakaZ, PlakaA, PlakaB, GecitG, GecitM, LazerA, LazerB, Kapi, Oyuncu, Bilgi.
**Başlangıç:** iki geçit kapalı, iki lazer açık, mühür açık (kırmızı), fitil şeridi boş. Oyuncu hiçbir plakaya değmez; G'nin sağ yüzü (180) gövdenin 46 px solunda.

## 4. Roller
- **A (tur 1) "fitilci":** raftan S ile kuyuya iner, sola yürüyüp ZP'ye basar (G açılır, şerit dolar), sağa yürüyüp PlakaA'da kalır (LazerA kapalı).
- **B (tur 2) "mühürcü":** G'nin önünde bekler; A'nın fitiliyle G açılınca odaya girer, mühre basar (GM açılır, G de kalıcı açık), çıkar, rafın üstünden yürüyerek geçer, LazerA'yı (A tutuyor) ve GM'yi geçer, PlakaB'de kalır (LazerB kapalı).
- **Oyuncu (tur 3):** LazerA, GM, LazerB, kapı. Ne kuyuya ne odaya girmesi gerekir.

## 5. Çözüm (tur tur; c = gövde merkezi x; kareler TAHMİN)
**Tur 1 (A, ~180 kare):** `sag`: c=240 → raf ortası c≈380 (k~28). `sag` BIRAK, `asagi` bas: kuyuya düşer (~34 kare, k~64, c≈380). `sol`: ZP'ye c<224'te girer (k~96; G açılmaya başlar, şerit dolu). c≈200'de dön, `sag`: ZP'den c>224'te çıkar (k~106; şerit 180 kare boyunca azalır). PlakaA'ya c>476'da girer (k~157), c≈520'de dur (k~166). ~15 kare bekle, R.
**Tur 2 (B, ~285 kare):** A oynar. `sol`: c≈194'te G'ye dayan (k~10), **bekle** (G kapalı; A'nın kuyuya inişi ekranda görünür). A ZP'ye basınca G yükselir; ≥48 px açıklık k~120. `sol`: odaya gir, mühre c<124'te bas (k~134): kilit yeşil, GM açılmaya başlar (≥48 px k~158), G artık mühürle de açık. `sag`: odadan çık (k~148), raf üstünden yürü (S'ye BASMA), LazerA'ya c=503'te var (k~211; A k~157'den beri PlakaA'da), GM'yi geç (k~236), PlakaB'ye c>746'da gir (k~260), c≈790'da dur (k~269). ~15 kare bekle, R.
**Tur 3 (oyuncu, "Klon: 2/2", R çalışmaz, ~295 kare):** `sag`: LazerA önüne k~53'te varır, **bekle** (A k~157'de basar; ışın söner). Geç; GM (k~158'den beri açık) k~182; LazerB önüne k~234, **bekle** (B k~260'ta PlakaB'de; ışın söner). Geç, kapı (c>1058) k~295.

## 6. Zamanlama pencereleri (hepsi bekleyerek uzatılabilir)
| # | Pencere | Hesap (tahmin) | Pay |
|---|---|---|---|
| W1 | B'nin odaya girişi: G ≥48 px açık aralığı (fitil 180 + kapanma 26) | k~120 .. k~313 | **~190 kare**; B dipte beklediği için açılır açılmaz girer. (Mühürden sonra G hiç kapanmaz.) |
| W2 | A'nın ZP'ye basma anı | B G'nin önünde bekler; A ne kadar geç basarsa B o kadar bekler | alt/üst sınır yok (tur süresi sınırsız; önerilen: inince hemen bas) |
| W3 | S konumu (rafta tam gövde, dikişlerden 12 px içeride) | c 346..414 (tam raf 334..426) | **68 px** (~13 kare). Rafın dışında S etkisiz, zararsız |
| W4 | A PlakaA'da (k~157) → B'nin LazerA'ya varışı (k~211) | 211 − 157 | **~54 kare**; erken gelen ışını görür, bekler |
| W5 | Mühür (k~134) → GM ≥48 px (k~158) → B GM'de (k~236) | | **~78 kare** |
| W6 | B PlakaB'de (k~260) → oyuncunun LazerB'yi geçişi | oyuncu k~234'te gelir, bekler | alt sınır yok |
| W7 | Tutucu kaçışı (PB→sağ): ayrılınca gövde sağ kenarı 848, ışın 900 | 52 px / 5 | **~10 kare** ışın yeniden yanar → kaçan ölür (istenen) |
| W8 | PA tutucusu kaçamaz | kuyu kapalı | yapısal |
- Bant yok, hareketli platform yok: canlı/klon ayrışması beklenmez (0 px). Eş düzlemli dikişler (raf | DosemeSol x=320, raf | DosemeSag x=440) statik; yalnız S kararında geçerli ve W3 bunlardan 12 px uzak tutuldu.

## 7. Atlanamazlık (sürekli tepe 96,6; "erişilmez" hesabında ölçülmüş en çok ~100,9)
- **Geçitler ve ışınlar (F2):** G, GM, LazerA, LazerB y 180..380, tavandan F2 zeminine bitişik; boşluk 0. F2'de zıplayan başı y≈231, tavana bile ulaşmaz.
- **Kuyudan çıkış:** kuyu zemini 600, F2 yüzeyi 380: 220 px > 100,9 (pay 119). Raf tek yönlü (yukarıdan basılır, aşağıdan geçilir) ama kuyudan ayak en çok y≈499'a çıkar, rafa (380) ulaşmaz.
- **Fitil koşusu tek başına imkânsız (yapısal, zaman hesabına bağlı değil):** ZP kuyuda, G yukarıda; ZP'ye basan kuyudan G'ye hiç dönemez. Bu yüzden "yakan" ile "geçen" ayrı kişi olmak zorunda.
- **Odaya G'siz giriş:** yok (tek giriş G).
- **Kapı:** F2 sağ ucunda; LazerB'nin sağında.

## 8. Kısayol analizi (klon sayısını düşüren yol YOK)
| Deneme | Sonuç | Neden |
|---|---|---|
| Klonsuz | olmaz | LazerA'da ölür / G açılmaz (ZP kuyuda) |
| 1 klon = A (fitil + PA) | olmaz | oyuncu G'de bekleyip A'nın fitiliyle odaya girer, mühre basar, GM'yi geçer; ama LazerB açık (PlakaB boş) |
| 1 klon = B (mühür + PB) | kayıt alınamaz | tur 1'de ZP'ye basan yok, G açılmaz; LazerA da açık |
| 1 klon, oyuncu fitilci | olmaz | kuyuya inen oyuncu kapıya gidemez |
| Röle (bir tutucunun PA'dan PB'ye geçmesi) | olmaz | PA kuyuda, kuyudan çıkış yok; PB'den sağa ayrılan ~10 karede LazerB'ye girer (W7) |
| Rol değişimi (B kuyuya, A PB'ye) | olmaz | A tur 1'de LazerA ve kapalı GM yüzünden PB'ye ulaşamaz |
| Kör kayıt (A tur 1'de G önünde körlemesine "bekle, gir, mühür, çık, PB" kaydeder; B tur 2'de fitilci olur) | **BİTMEZ (ölçüldü)** | Tur 1'de klon yok: ZP'ye basan olmaz, G kapalı, PlakaA boş, LazerA açık; A' LazerA'da ölür ve oda/PB yolu kaydedilemez. Kısayol değil; test "bitirmez" bekler |
| Geçit altı park | işe yaramaz | G mühürle, GM mühürle kalıcı açılır; park edilecek kapanan geçit yok (G'nin kapanması mühürden önce, odaya girişte zaten anlamsız) |
| Lazeri zıplayarak aşma | olmaz | §7 |
| Kutu, zıplatıcı, bant, asansör | uygulanamaz | yok |
| S ile yeni iniş | yok | tek raf; diğer F2 zemini katı |
| Zamanlı plakayla tutucu tasarrufu (B15 dersi) | çözümün parçası | A fitili yakıp PA'ya gider (normal plaka olsaydı fitil başında kalması gerekirdi → 3 klon) |
| Mandalla tutucu tasarrufu (B21 dersi) | çözümün parçası | B mührü basıp PB'ye gider (normal plaka olsaydı odada kalması gerekirdi → 3 klon) |
**Min klon 2 kanıtı:** LazerA ve LazerB oyuncunun yolunda; tutucuları PA (kuyuda, çıkışsız) ve PB (LazerB'nin 80 px gerisinde): iki ayrı klon şart. **2'nin yetmesi iki özel plakaya bağlıdır:** ZP normal olsaydı fitil başında, M normal olsaydı odada bir klon kalırdı; `max_klon = 2` ile ikisi de imkânsız. Yani iki özelliğin ikisi de zorunludur.

## 9. Başarısızlık senaryoları (hepsi görünür)
1. Klonsuz: LazerA'da ölür / G kapalı kalır.
2. Tek başına fitil denemesi: oyuncu kuyuya iner, ZP'ye basar, G'nin açıldığını görür ama çıkamaz. R (hak varsa: bu kayıt A olarak kullanılabilir, PlakaA'da bitirdiyse doğrudan doğru A'dır) ya da T.
3. A ZP'ye basmadan PlakaA'da kalır: tur 2'de G hiç açılmaz; görünür ("şerit hiç dolmadı"). T.
4. B mührü basmadan odadan çıkar: GM kapalı görünür. Fitil bitmeden (~190 kare) geri dönüp basabilir; bittiyse G kapanmıştır ve bu tur boşa gider (R yanlış bir B kaydeder; doğru yol T). Mühür odanın tabanında, girene ~14 karede değer: kaçırmak zor.
5. Odada mühre basmadan oyalanmak: fitil biterse G kapanır; mühre basınca G yeniden açılır (VEYA). **Oda tuzak değil.**
6. B veya oyuncu rafın üstünde yanlışlıkla S: kuyuya düşer, dönüş yok. Kayıt turunda R/T; son turda T.
7. Oyuncu LazerA/LazerB'ye tutucu gelmeden yürür: ölür; tur yeniden başlar (klonlar korunur).
8. B PlakaB'den erken ayrılır (kayıt hatası): oyuncu LazerB'de bekler; T.

## 10. Kilitlenme kontrolü
- Kutu, asansör yok. GM yalnız mühürle açılır, açılınca kapanmaz. G kapanırken altında karakter varsa durur (`gecit.gd`); mühürden sonra hiç kapanmaz. Oda içinde kalan herkes mühre basarak G'yi açar (§9.5): odada kilitlenme yok.
- Klonlar plakada biter (A kuyuda PlakaA, B PlakaB); geçit altında bitmez.
- **Bilinçli dönüşsüz bölge:** kuyu (A'nın son yeri). Yanlışlıkla inen için çıkış: R (hak varsa) / T. Rafın yeşil üst çizgisi ve kuyunun kapalı duvarları dönüşsüzlüğü görünür kılar.

## 11. OKUNABİLİRLİK GEREKÇESİ (oyuncu ekrana bakınca)
1. **Görür:** solda kilitli bir oda (mor geçit G, içinde asma kilitli plaka), başlangıcın sağında bir raf ve altında kapalı bir kuyu; kuyuda iki plaka: biri sayaç şeritli (G'nin tam altında), biri düz (LA'nın tam altında). Yukarıda iki lazer, ikinci bir mor geçit (GM), bir düz plaka (PB), kapı. HUD "Klon: 0/2".
2. **Düşünür:** "Lazerler plakayla kapanır: LA'nınki kuyuda, LB'ninki yukarıda. Şeritli plaka G'nin altında: onu açıyor olmalı. Kilitli plaka odada: GM'yi açıyor olmalı (başka kapalı geçit yok)."
3. **Dener:** kuyuya iner, şeritli plakaya basar: G açılır, şerit azalır; ama kuyudan çıkamaz → **çıkarım:** "fitili yakan geçitten geçemez; geçecek kişi önceden kapıda beklemeli."
4. **Plan:** "A kuyuya iner, fitili yakar, LA'nın altındaki plakada kalır. B kapıda bekler, açılınca girer, mühre basar (B21'da öğrendi: basıp gidebilir), PB'ye gider. Ben yürürüm."
5. Bütün beklemeler görünür olaylara bağlı: "G açıldı mı?", "ışın söndü mü?". Hiçbir an kare saydırmaz; en kısa zorunlu pay ~54 kare ve o da beklemeyle uzar.
- Eşleşmeler: ZP↔G dikey hizada (x 150..210 / 160..180), PA↔LA dikey hizada (490..550 / 517..523), PB↔LB yan yana (80 px), M↔GM: tek kalan kapalı geçit; mühre basıldığı an GM ve G birlikte yükselir.

## 12. Ölçülmesi gerekenler (test-yazari)
1. S penceresi: raf üstünde c 334..426 iner, dışında etkisiz; dikiş ±12 px içinde (c 322..345, 415..438) davranış.
2. Kuyuya düşüş kare sayısı (~34) ve iniş x'i; kuyudan zıplamayla rafa/F2'ye ulaşılamadığı (ayak en küçük y).
3. ZP: ilk temas karesi, bırakış karesi, `tutma_kare` tam 180; G ≥48 px açıklık başlangıcı (~ZP+24) ve mühürsüz kapanma anı (~bırakış+180+26).
4. Mühür: kilit karesi; GM ≥48 px (~+24); **G'nin fitil bittikten sonra mühür sayesinde açık kaldığı** (k > 320'de G konumu).
5. Oda tuzağı: mühre basmadan c≈130'da bekle, fitil bitsin, G kapansın; sonra mühre bas → G yeniden açılmalı.
6. LazerA: A'nın PlakaA'ya giriş karesi (~157) ve B'nin varışı (~211) farkı (W4).
7. Tutucu kaçışı: PB'den sağa ayrılan klon LazerB'de ölmeli (W7, ~10 kare, ışın gecikmesi dahil).
8. Tur kareleri (beklenen A ~180, B ~285, oyuncu ~295) ve beklemeler (B G'de ~110, oyuncu LA'da ~100).
9. Min klon taraması: klonsuz; tek klon A / B; oyuncu fitilci; rol değişimi; röle; kör kayıt alternatifi (2 klonla bitmeli, 1 klonla bitmemeli); `max_klon = 2` ile naif yollar (fitil başında ya da odada bekleyen klon) bitmez.
10. Determinizm 100x; canlı kayıt ↔ klon tekrarı farkı (beklenen 0,00 px).
11. Görünürlük: zamanlı şerit (y≈568..574) kuyu tavanıyla (420) çakışmaz; kilit simgesi (y≈341..360) F2 koridorunda.

## 13. Görünürlük denetim listesi (gözden-gecirici için)
| Nesne | Çarpışma/tetik | Çizim (`Gorunum.Tur`) | Not |
|---|---|---|---|
| Zemin, Tavan, DosemeSol, DosemeSag, BlokF1Sol, BlokF1Sag | katı | DUVAR | Gorsel boyutu = şekil |
| Raf | tek yönlü | TEK_YONLU | yeşil üst çizgi |
| PlakaM | Area2D, mandal | PLAKA_MANDAL | asma kilit 14 px üstte |
| PlakaZ | Area2D, zamanlı | PLAKA_ZAMANLI (`_plaka` + `_plaka_sayac`) | şerit 14 px üstte, kalan süreyle azalır |
| PlakaA, PlakaB | Area2D | PLAKA | |
| GecitG, GecitM | katı, kayar | GECIT (z −1) | açılınca tavana gömülür; alt ucu, yeşil lamba görünür |
| LazerA, LazerB | Area2D (öldürür) | LAZER | kapalıyken noktalı kılavuz |
| Kapi | Area2D | KAPI | |
| Oyuncu/klon | katman 2/3 | OyuncuGorunum | |
| SinirDuvarlari | ekran dışı | yok (kararla) | |
Çizimsiz çarpışma/tetikleyici: **yok**. Kutu, zıplatıcı, bant yok (eski B17'deki çizimsiz Z1/Z2/kutu ve bant çift çizimi sorunları bu tasarımda doğmaz).

## 14. Fizik varsayımları ve kaynakları
- `scripts/player.gd`: HIZ 300 (5 px/kare), ZIPLAMA_HIZI −520, YER_CEKIMI 1400 → tepe **96,6 px** (ölçülmüş en çok ~100,9); 220 px düşüş ~34 kare; `ASAGI_DUSME_KARE = 12` (raf S); S yalnız `one_way_collision` şeklinde çalışır.
- `scenes/oyuncu.tscn` 28x48; 60 fizik karesi/sn (`docs/kararlar.md`); ekran 1152x648.
- `scripts/basinc_plakasi.gd`: `tutma_kare` (ZP için `zamanli_plaka.tscn` = 180; bırakıldıktan sonra tam 180 kare etkin, yeniden basış yeniler), `mandal` (ilk temasta tur sonuna kadar etkin). Sayaç yalnız fizik karesiyle.
- `scripts/gecit.gd` / `scenes/gecit.tscn`: 20x200, 2 px/kare, VEYA mantığı, kapanırken altında karakter varsa durur.
- `scripts/lazer.gd`: kalınlık 6, `uzunluk`, `tetik_aktifken_kapali`, `monitoring` ertelemesi (≤ birkaç kare).
- `scenes/tek_yonlu.tscn`: 120x12, margin 4.
- `scripts/bolum.gd`: `max_klon`, kayıt bitince klon boş girdiyle bekler.
- `scripts/gorunum.gd`: `PLAKA_ZAMANLI` ve `PLAKA_MANDAL` kolları `_draw`'da mevcut (görünürlük raporundaki kök neden giderilmiş durumda).

## 15. Kullanıcıya sorular
1. **`max_klon`:** (a) **2 (öneri):** iki özel plakanın ikisi de zorunlu; B21'dan belirgin zor. (b) 3: bir özel plakayı "normal" sanan oyuncu da bitirebilir (fitil başında ya da odada bekleyen 3. klon); daha yumuşak eğri.
2. **Ad:** (a) **"Fitil ve Mühür" (öneri):** yeni tasarımı ve iki plakayı adlandırır. (b) "Çifte Mühür" kalsın.
3. **G'nin tetikleyicisi:** (a) **[ZP, M] VEYA (öneri):** mühür odayı kalıcı açar, oda asla tuzak olmaz. (b) Yalnız [ZP]: daha sade ama odada oyalanan kilitlenir (T gerekir).
4. **(İsteğe bağlı, yalnız görünüm):** plaka–geçit/lazer eşleşmesini gösteren renk işareti / ince kablo (grafik işi, mekanik değil).
5. Not (ana oturum): eski `_b17_*` testleri, `tutma_kare = 70` sahne ayarı ve CLAUDE.md/kararlar.md'deki B17 tanımı ("ikisi + ters bant", 3 klon) onaydan sonra güncellenmeli.
