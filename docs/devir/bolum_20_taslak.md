# Bölüm 21 taslağı (v2, sıfırdan): Mandal

**DURUM: ONAYLANDI (2026-10-16, kullanıcı); yeni bölüm olarak uygulanır (eski B16/B17 oyunda aynen kalır)**

> **ÖLÇÜM NOTU (2026-10-16, test-yazari; `-- --b21`, aşağıdaki tahmin sayıları bununla ÖNCELİKLİ okunmalıdır):** 60 kare/sn, sabit fizik karesi, ölçüm bölüm 21 sahnesinde gerçek girdi enjeksiyonu ile yapıldı.
> - **Tur kareleri:** A 78 (tahmin ~85), B 313 (~340), oyuncu 352 (~370). Hepsi < 600 (en geniş pay 248 kare). Bölüm 2 klonla çözülür (3 tur, R gerçek yolu ile), klon farkı canlı/klon 0,00 px (bant yok).
> - **W1 (A'nın PlakaA'ya basması -> B'nin LazerA'ya varışı):** A kare 63'te basar, B kare 124'te ışına varır: **pay 61 kare** (tahmin ~78). A'nın başta bekleme taraması: 0..64 kare başarılı (en çok 64 kare); 68+ kare geç A ise B LazerA'da ölür. B erken/geç gelmesi sorun değil (ışın açıksa görünür, A'nın erken basması zararsız).
> - **W1b (B gecikmesi):** B başta 0..200 kare bekleyebilir, oyuncu LazerB önünde bekler ve bitirir (üst sınır yalnız tur kare sınırı 600).
> - **W2 (mandala zıplama konumu, dur-zıpla, gövde merkezi c):** kilit + rafa iniş **c = 156..240** (4 px adımlı tarama; ~88 px, tahmin 156..244). Dışında (c=110, c=300) mandal basılmaz, G kapalı kalır, ölüm yok.
> - **W3 (rafa çıkış):** dikey zıplamada en yüksek ayak y = 277,9 (raf üstü 305): **pay 27,1 px** (tahmin 21,5; ölçülen zıplama tepesi ~102 px).
> - **W4 (mandal -> G):** mandal ilk basılı kare 34 (zıplamadan ~3 kare sonra), G >= 48 px açık kare 58 (+24, tahmin 24), tam açık kare 84; B G önüne (x>=612) kare 147: **pay 89 kare** (tahmin ~145 -> 89; yine de bekleme gerekmez). Mandal bir kez basılınca tur sonuna kadar basılı kalır, G hiç kapanmaz (350 kare ölçüldü).
> - **W5 (oyuncu F1'de):** oyuncu düşerken PlakaB'nin üstünden geçip ışını kısa süre kendisi kapatır (kare ~262, zararsız, görsel). LazerB önüne (x<=830) kare 287'de varır; B kare 298'de PlakaB'ye basar (LazerB kare 299'da kapanır): **oyuncu yalnız ~12 kare bekler** (tahmin ~55: B tahminden erken ve oyuncu geç varıyor). Beklemeden yürürse (x=817'de) ışın açıkken girer ve ölür; bekleme konumu x = 820..860 ve >= 970 güvenli (870..960 aralığında oyuncu PlakaB'nin üstünde durup kendisi tutucu olur, sonra ayrılınca ölür; 790..810 ışının gövde girişi).
> - **W6/W7 (tutucu kaçışı):** plakadan ayrılan karakter plakadan ayrıldıktan **13 kare** sonra ışında ölür (tahmin ~10-11; ışın gecikmesi dahil). 0-3 karelik duraksamalar ve "4 kare yürü, 2 dur, devam" varyantı dahil hepsi ölür: röle (tek klonla iki plaka) imkânsız.
> - **Atlanamazlık:** F1'den dikey zıplama en yüksek ayak y = 499 (DosemeF2 alt kenarı 420, 79 px pay); raftan zıplama tavana çarpar (baş y = 180); G kapalıyken sağ+zıpla spam x <= 626; LazerA/LazerB zıplanarak aşılmaz (ölüm); F2'de zıplayan baş y = 231 (tavan 180'e ulaşmaz); raf altından yürümek mandala dokunmaz.
> - **Kısayol taraması:** klonsuz (8 strateji), 1 klon (6 rol x 8 strateji), röle (T=0/20/60), iki klon kümeleri (9) ve S inişleri: yalnızca beklenen 2 klonlu çözümler bitirir (A+B ve eşdeğer A_mandal+B_sade, oyuncu LazerA'yı beklerse); naif yol (A mandalın üstünde kalır) bitmez ("Klon hakkı bitti", çıkış T / Baştan başla).

(Tasarımcı çıktısı, Parça 3. Eski `bolum_16_taslak.md` değiştirilmedi; yalnızca ne OLMAMASI gerektiğini görmek için okundu, bkz. §0.)

> **UYARI: Bütün kare/piksel zaman sayıları TAHMİNDİR.** Kare modeli: 60 kare/sn, yatay 5 px/kare, sürekli fizik formülü. Ölçüm yapılmadı; `test-yazari` ölçecek (§12). Önceki taslaklarda (B13–B17) sayılar ölçümle hep saptı; bu yüzden her zamanlama payı cömert tutuldu ve hiçbir pencere oyuncunun "tahmin etmesine" dayanmıyor (hepsi "gör, bekle, geç" türünde).

`scenes/bolumler/bolum_21.tscn`, **`max_klon = 2` (öneri, §15 soru 1)**, **çözüm tam 2 klon**, `ipucu_klon = 0`. Harita konumu değişmez: (1020,510). `BolumListesi` adı: "Mandal" (değişmez).

## 0. Eski B16'dan alınan ders (yapılmayacaklar)
- Mandal plaka cebin dibindeydi, Z2 sensörü ve MP çizimsizdi: oyuncu ne olduğunu göremiyordu. **Burada mandal göz hizasında, açık bir rafta; kilit simgesi kendi çizimiyle görünür.**
- Z1/Z2 uçuşunda "`sag` bırak, ayak y≤345'te yeniden bas" gerekiyordu (görünmeyen köşe çarpması). **Bu bölümde zıplatıcı YOK.**
- C_A geç basış payı 6 kare çıktı. **Burada hiçbir pencere "önceden bil" türünde değil; en dar pay ~29 kare ve hepsi beklenerek uzatılabilir.**
- Üç mıhlanmış lazer + kutu basamağı + cep + iki zıplatıcı: tek bölümde beş fikir. **Burada tek fikir: mandal.**

## 1. Fikir ve özet
- **Öğrettiği tek fikir:** mandal plaka "bir kez dokun, tur boyunca açık". Ona dokunan klon orada durmak zorunda değildir; dokunup başka bir işe (plaka tutmaya) gidebilir.
- **Neden zorunlu:** iki lazer tutucusu (PA, PB) şart; `max_klon = 2`. Mandalın başında bir klon bırakmak üçüncü klon ister, hak yoktur. Oyuncu mandalı "bas ve git" diye kullanmayı görmek zorunda kalır.
- Nesneler: mandal plaka x1 (rafta), normal plaka x2, geçit x1, lazer x2, tek yönlü raf x1, kapı. YOK: zıplatıcı, kutu, bant, şalter, asansör, zamanlı plaka.
- Kat yapısı: başlangıç üst katta (F2). F2 boyunca sağa, uçtaki açık boşluktan F1'e düşülür, F1'de sola, kapıya. Rota "U" biçiminde.
- 3 tur: A (~85 kare), B (~340 kare), oyuncu (~370 kare). Hepsi < 600. En uzun bekleme ~60 kare (1 sn).

## 2. Kat planı (piksel; F2 koridoru y 180..380 = 200 px, F1 koridoru y 420..600 = 180 px)
```
x:  0   46 74 140 170 230 260   380  440   520 526  640 660                  1000            1152
y=0   +-------------------------------- Tavan (y 0..180) -------------------------------------+
y=180 |                                         LA      G                       :              |
      |               (kilit simgesi y~275)     |      |#|                      :   açık       |
      |             [M]  (y 289..305)           |      |#|                      :   boşluk     |
      |          =====Raf===== (y 305..317)     |      |#|                      :   (F2 yok)   |
      |  O                                      |      |#|                      :              |
y=380 +------------------------[ PA ]-----------+------|#|----------------------+   düşüş      |
      |  DosemeF2 (x 0..1000, y 380..420)                                       |   ~34 kare   |
y=420 +-------------------------+                 LB                            +              |
      |  BlokF1Sol              |   [Kapı]        |           [ PB ]                   iniş     |
      |  (x 0..500, y 420..600) |   522..558      |          886..946                  bölgesi  |
y=600 +-------------------------+-----------------+--------------------------------------------+
                                                797..803
```
- O = oyuncu başlangıcı (60,356). Raf rotanın ÜSTÜNDE: altından yürüyen başı (y 332) rafın altına (y 317) 15 px kalır, mandala değmez. Mandala ancak bilerek zıplayarak dokunulur.
- F2 x=1000'de biter; sağındaki açık boşluktan F1'e düşülür (geri dönüş yok, 220 px).
- F1'in sol yarısı dolu blok (BlokF1Sol); F1 yalnız düşüş bölgesinden girilir, kapıya LB'den geçilerek varılır.

## 3. Nesneler (merkez, boyut) ve görünüm
| Düğüm | Tür | Konum (merkez) | Alan / parametre | Görünüm (çizim) |
|---|---|---|---|---|
| Zemin | StaticBody2D + Gorsel | (576,620) | 1152x40 (y 600..640) | DUVAR paneli (bolum.gd ortak çizim) |
| Tavan | StaticBody2D + Gorsel | (576,90) | 1152x180 (y 0..180) | DUVAR |
| DosemeF2 | StaticBody2D + Gorsel | (500,400) | 1000x40 (x 0..1000, y 380..420) | DUVAR, üst kenarda soluk ışık şeridi |
| BlokF1Sol | StaticBody2D + Gorsel | (250,510) | 500x180 (x 0..500, y 420..600) | DUVAR |
| Raf | `tek_yonlu.tscn` | (200,311) | 120x12 (x 140..260, üst y=305) | TEK_YONLU: gri ızgara + yeşil üst çizgi |
| PlakaM | `mandal_plaka.tscn` | (200,297) | 60x16 (x 170..230, y 289..305), `mandal = true` | PLAKA_MANDAL: amber plaka + üstünde asma kilit (merkez y≈275). Boşta kanca kalkık, gövde paslı, lamba kırmızı; basılınca kanca oturur, lamba yeşil + hale, KALICI |
| PlakaA | Area2D + `basinc_plakasi.gd` | (410,372) | 60x16 (x 380..440, y 364..380) | PLAKA: amber, uyarı şeritli; basılıyken çöker, camgöbeği, lamba yeşil |
| PlakaB | Area2D + `basinc_plakasi.gd` | (916,592) | 60x16 (x 886..946, y 584..600) | PLAKA |
| GecitG | `gecit.tscn` | (650,280) | 20x200 (x 640..660, y 180..380); `kayma_yonu=(0,-1)`, `kayma_mesafe=100`, `hiz=120`, `tetikleyici_yollari=[../PlakaM]` | GECIT: mor lamelli levha, kapalıyken kırmızı lamba; açılınca tavana gömülür (z −1), görünen alt kısım koyu mor + yeşil lamba |
| LazerA | `lazer.tscn` | (523,180) | `yon=(0,1)`, `uzunluk=200` → ışın x 520..526, y 180..380; `tetikleyici_yollari=[../PlakaA]`, `tetik_aktifken_kapali=true` | LAZER: tavanda yayıcı, F2 zemininde alıcı; açıkken kırmızı ışın, kapalıyken noktalı kılavuz |
| LazerB | `lazer.tscn` | (800,420) | `yon=(0,1)`, `uzunluk=180` → ışın x 797..803, y 420..600; tetik [../PlakaB], kapalı=true | LAZER (yayıcı DosemeF2 altında) |
| Kapi | Area2D + `kapi.gd` | (540,576) | 36x48 (x 522..558, y 552..600) | KAPI |
| Oyuncu | `oyuncu.tscn` | (60,356) | 28x48 (x 46..74, y 332..380) | OyuncuGorunum / klon hologramı |
| Bilgi | Label | (16,12) | | HUD |

**Ağaç sırası:** Zemin, Tavan, DosemeF2, BlokF1Sol, Raf, PlakaM, PlakaA, PlakaB, GecitG, LazerA, LazerB, Kapi, Oyuncu, Bilgi (plaka/geçit/lazer karakterlerden önce; CLAUDE.md kuralı).
**Başlangıç durumu:** G kapalı, iki lazer açık, mandal açık (kırmızı). Oyuncu hiçbir plakaya değmez (gövde x 46..74; en yakın plaka 170..230 ve rafın üstünde).

## 4. Roller
- **A (tur 1):** PlakaA'da kalır → LazerA kapalı.
- **B (tur 2):** rafın altında zıplayıp mandala dokunur (G kalıcı açılır), LazerA'yı (A tutuyor) ve G'yi geçer, boşluktan F1'e düşer, PlakaB'de kalır → LazerB kapalı.
- **Oyuncu (tur 3):** LazerA, G, düşüş, LazerB, kapı.
- Eşdeğer yol: mandala A da dokunabilir (tur 1'de zıplarsa); o zaman B yalnız PlakaB'ye gider. İkisi de 2 klon.

## 5. Çözüm (tur tur; c = gövde merkezi x; kareler TAHMİN)
**Tur 1 (A, ~85 kare):** `sag` basılı: c=60 → PlakaA'ya c>366'da girer (k~62); c≈410'da dur (k~70). ~15 kare bekle, R.
**Tur 2 (B, ~340 kare):** A oynar (k~62'den itibaren PlakaA'da, LazerA kapalı).
- `sag`: c≈200'e (rafın tam altı) k~28'de var; `zipla` (`sag` basılı kalabilir). Gövde yükselirken mandal alanından geçer → k~31 civarı kilit yeşil, G açılmaya başlar (≥48 px açıklık k~55, tam açık k~81).
- Raf üstüne iner (ayak y=305), `sag` ile rafın sağ ucundan F2'ye düşer (75 px, ~20 kare), c≈280 (k~95).
- LazerA'ya (sağ kenar 520, c=506) k~140'ta varır; A k~62'den beri plakada (pay ~78 kare; erken gelirse bekler, ışın görünür).
- G'den (açık) geçer, x=1000 kenarından düşer (k~242 kenar, ~34 kare düşüş; `sag` basılıysa sağ duvara, c≈1138, yaslanarak iner, k~276).
- `sol`: PlakaB'ye c<960'ta girer (k~312), c≈916'da dur (k~321). ~15 kare bekle, R.
**Tur 3 (oyuncu, "Klon: 2/2", R çalışmaz, ~370 kare):** `sag` (mandala dokunmak gerekmez: B'nin kaydı k~31'de kilitler). LazerA (A tutuyor), G (k~55'ten beri açık), kenardan düş (k~225), `sol`: PlakaB'ye k~261'de varır. B k~312'de iner/PlakaB'ye gelir: oyuncu PlakaB üstünde ya da LazerB önünde bekler (~55 kare, ışın görünür). B PlakaB'deyken `sol`: LazerB'yi geçer, kapı (c<572) k~370.

## 6. Zamanlama pencereleri (hepsi "bekleyerek uzatılabilir")
| # | Pencere | Hesap (tahmin) | Pay |
|---|---|---|---|
| W1 | A'nın PlakaA'ya basması (k~62) → B'nin LazerA'ya varışı (k~140) | 140 − 62 | **~78 kare**; B erken gelirse ışın açık görünür, bekler (alt sınır yok) |
| W2 | Mandala zıplayarak dokunma: ayakta zıplamada gövde merkezi plaka x'iyle örtüşmeli | c ∈ (156, 244) | **88 px**; koşarak zıplamada gövde ~14 kare boyunca plaka yüksekliğinde (~70 px yol) |
| W3 | Rafa çıkış yüksekliği | raf üstü 75 px; tepe 96,5 | **21,5 px** (≥ 12) |
| W4 | Mandal → G ≥48 px | 24 kare (2 px/kare) | B G'ye k~200'de varır: **~145 kare** |
| W5 | B PlakaB'de (k~312) → oyuncunun LazerB'yi geçmesi | oyuncu k~261'de gelir, bekler | alt sınır yok (görünür ışın); üst sınır yok |
| W6 | Tutucu kaçışı (PA→sağ): plakadan ayrıldığı an gövde sağ kenarı 468, ışın 520 | 52 px / 5 | **~10 kare** ışın yeniden yanar (gecikme ≤3 kare) → kaçan ölür (istenen) |
| W7 | Tutucu kaçışı (PB→sol): ayrılınca gövde sol kenarı 858, ışın sağ kenarı 803 | 55 px / 5 | **~11 kare** (istenen) |
- Bant yok, eş düzlemli bant/zemin dikişi yok: canlı/klon ayrışması beklenmez (0 px). Zorunlu kararların hiçbiri bir dikişin 12 px yakınında değil (raf ve F2 eş düzlemli değil; DosemeF2 tek gövde).

## 7. Atlanamazlık (sayılar sahneden; zıplama tepesi sürekli 96,6 / ölçülmüş en çok ~100,9)
- **Işınlar ve geçit:** LazerA ve G y 180..380 (tavandan F2 zeminine bitişik), LazerB y 420..600 (DosemeF2 altından zemine). Arada boşluk 0: üstünden/altından geçilmez. F2'de zıplayan başı y 332−100,9 = 231, tavana bile ulaşmaz.
- **F1 → F2 dönüş:** 220 px > 100,9 (pay 119). Boşluktan geri çıkılmaz.
- **Rafın işe yaraması:** yalnız mandala erişim. Raftan zıplayan baş y≈160'ta tavana çarpar (zararsız). Raf LazerA'ya 260 px uzak: üstünden ışın aşılmaz.
- **Mandala kazara basılmaz:** altından yürüyen başı y 332, plaka alt kenarı y 305 (27 px), raf alt kenarı y 317 (15 px).
- **Kapı:** yalnız F1'de, LazerB'nin solunda; F1 yalnız boşluktan girilir.

## 8. Kısayol analizi (klon sayısını düşüren yol YOK)
| Deneme | Sonuç | Neden |
|---|---|---|
| Klonsuz | olmaz | LazerA'da ölür (PlakaA boş) |
| 1 klon = PlakaA tutucu | olmaz | oyuncu mandal + G + düşüş yapar, LazerB açık, PlakaB boş |
| 1 klon = PlakaB tutucu | kayıt alınamaz | kayıt turunda LazerA açık; kayıt sırasında ölür (tur atılır) |
| 1 klon, PA'yı tutup PB'ye taşınma (röle) | olmaz | PA'dan sağa ayrılan klon ~10 karede yeniden yanan LazerA'ya girer (W6). Sola ayrılıp başka yol yok (tek koridor) |
| Oyuncunun kendisinin tutucu olması | olmaz | iki plaka da kapının uzağında, kapı LazerB'nin ardında |
| Kör kayıt (klon kapalı geçide yürür, sonra açılınca devam eder) | klon azaltmaz | iki tutucu yine şart; yalnız rol sırası değişir |
| Geçit altı park / röle | uygulanamaz | G mandallı: bir kez açılınca kapanmaz; park anlamsız |
| Lazeri zıplayarak aşma | olmaz | §7 |
| Kutu basamağı / kutuyla plaka | uygulanamaz | kutu yok |
| Zıplatıcı, bant, asansör | uygulanamaz | yok |
| S ile yeni iniş | yok | S yalnız raftan F2'ye indirir (zararsız); başka tek yönlü yok |
**Min klon 2 kanıtı:** LazerA ve LazerB oyuncunun yolunda, tutucuları PA ve PB ışınlarının 80/83 px gerisinde (mıhlanmış, W6/W7). Oyuncu ikisini de geçerken ikisi basılı olmalı; tek klon iki plakada olamaz ve PA'dan PB'ye yürüyemez. **2 klonun yetmesi mandala bağlıdır:** mandal normal plaka olsaydı G'yi açık tutan üçüncü bir klon gerekirdi (`max_klon = 2` ile imkânsız).

## 9. Başarısızlık senaryoları (hepsi görünür)
1. Klonsuz: LazerA'da ölür, tur yeniden başlar (klonlar korunur).
2. "Mandalda bekleyen klon" (naif yol): A mandalda kalır, B PlakaA'da; tur 3'te LazerB açık, hak yok ("Klon hakkı bitti"). Çıkış: T / "Baştan başla". Oyuncu kilidin yeşil kaldığını ve G'nin açık durduğunu görmüştür; ders budur.
3. Mandala dokunmadan G'ye gitmek: G kapalı, durur; geri dönüp zıplar (kayıp ~40 kare, ölüm yok).
4. B, A plakaya basmadan LazerA'ya yürür: ölür; tur yeniden.
5. Oyuncu F1'de B gelmeden PlakaB'yi geçip devam eder: LazerB yeniden yanar (W7), ölür; tur yeniden (klonlar korunur). Işın plakadan inince görünür biçimde geri yanar.
6. B PlakaB'den erken ayrılırsa (kayıt hatası): oyuncu LazerB'de bekler, B gelmez; tur 3'te T gerekir.

## 10. Kilitlenme kontrolü
- Kutu, asansör yok. G mandallı: açıldıktan sonra kapanmaz, kimseyi sıkıştırmaz; açılmadan önce kapalıdır, altında kimse olamaz.
- Klonlar plakada biter (A PlakaA, B PlakaB); geçit/asansör altında bitmez.
- **Tek yönlü yol:** F2→F1 düşüşü geri dönüşsüz. B'den önce düşen oyuncu yalnız bekler (kilit değil). Kayıt turunda yanlış düşen oyuncu R ile turu bitirebilir (hak varsa) ya da T. Son turda (hak yok) yanlışlık = T / "Baştan başla" (B8/B13–B20 kalıbı).
- Raf: üstüne çıkan iner (sağ/sol uçtan yürüyerek ya da S ile). Kilit yok.

## 11. OKUNABİLİRLİK GEREKÇESİ (oyuncu ekrana bakınca)
1. **Görür:** solda rafta üstünde asma kilit olan bir plaka (kırmızı), ortada mor bir geçit, iki amber plaka ve her birinin hemen önünde (yürüyüş yönünde) bir kırmızı ışın, sağda açık bir boşluk, aşağıda kapı. HUD: "Klon: 0/2".
2. **Düşünür:** "Işınlar plakayla kapanıyor (B3'ten beri bilinen); her plakaya bir klon lazım: 2 klon. Geçidi ne açıyor? Kilitli plaka."
3. **Dener (tur 1):** zıplayıp kilide dokunur: kilit yeşil, G açılır; raftan iner: kilit yeşil KALIR, G açık KALIR. Çıkarım: "kilide bir kez dokunmak yetiyor, kimse orada durmak zorunda değil."
4. **Plan:** "A ilk plakada, B kilide dokunup ikinci plakaya; ben kapıya." Bütün beklemeler görünür (ışın sönene kadar bekle); hiçbir şey kare saydırmaz.
5. Hata yaparsa (naif yol), HUD'da "Klon hakkı bitti" ve hâlâ yanan LazerB tam olarak neyin eksik olduğunu gösterir.
- Plaka–hedef eşleşmesi yakınlıktan okunur: PA, LA'nın 80 px solunda; PB, LB'nin 83 px sağında (yürüme yönünde önünde); mandal ile G aynı koridorda, aralarında başka tetikleyici yok.

## 12. Ölçülmesi gerekenler (test-yazari)
1. Rafın altında ayakta zıplama: ayak en küçük y (beklenen ≤ 284; raf üstüne iniş), mandalın kilitlendiği kare (beklenen zıplamadan ~3 kare sonra), W2 c aralığı (beklenen ~156..244).
2. Raf altından zıplamadan yürüme: mandal KİLİTLENMEZ (baş 332, raf alt 317).
3. G: kilitten ≥48 px açıklığa kare (beklenen 24), tam açık (50); sonra hiç kapanmadığı (tur sonuna kadar).
4. Tutucu kaçışı: PA'dan sağa `sag` ile ayrılan klon LazerA'da ölmeli (W6, beklenen ~10 kare, ışın gecikmesi dahil); PB'den sola (W7). Sürekli `sag`/`sol` ve 1–3 karelik duraksamalı varyantlar.
5. Tur kareleri (beklenen A ~85, B ~340, oyuncu ~370) ve oyuncunun F1'de bekleme süresi (~55).
6. Düşüş: x=1000 kenarından `sag` basılı/bırakılmış iniş konumu ve kare sayısı (~34); iniş bölgesinin PlakaB'ye değmediği.
7. Min klon taraması: klonsuz; tek klon (PA / PB / PA+mandal); naif 2 klon (A mandalda kalır + B PA) bitmez; kör kayıt rol değişimi; röle; F1→F2 dönüş zıplaması; LazerA/LazerB üstünden zıplama.
8. Determinizm 100x; canlı kayıt ↔ klon tekrarı farkı (beklenen 0,00 px: bant yok).
9. Görünürlük: tüm nesnelerin Gorunum çocuğu var (bkz. §13); mandal simgesi tavanla çakışmıyor (simge y≈266..285, tavan 180).

## 13. Görünürlük denetim listesi (gözden-gecirici için)
| Nesne | Çarpışma/tetik | Çizim (`Gorunum.Tur`) | Not |
|---|---|---|---|
| Zemin, Tavan, DosemeF2, BlokF1Sol | katı | DUVAR | `bolum.gd` ortak çizim, Gorsel boyutu = şekil |
| Raf | tek yönlü | TEK_YONLU | yeşil üst çizgi "üstten basılır" |
| PlakaM | Area2D, mandal | PLAKA_MANDAL (`_plaka` + `_plaka_mandal`) | asma kilit plakanın 14 px üstünde |
| PlakaA, PlakaB | Area2D | PLAKA | |
| GecitG | katı, kayar | GECIT (z −1) | açılınca tavana gömülür; alt ucu ve lambası görünür |
| LazerA, LazerB | Area2D (öldürür) | LAZER | kapalıyken noktalı kılavuz |
| Kapi | Area2D (hedef) | KAPI | |
| Oyuncu/klon | katman 2/3 | OyuncuGorunum | |
| SinirDuvarlari | ekran dışı | yok (kararla görünmez, ekran kenarı) | kural istisnası değil, ekran dışında |
Çizimsiz çarpışma/tetikleyici: **yok**. Kutu, zıplatıcı, bant, zamanlı plaka yok.

## 14. Fizik varsayımları ve kaynakları
- `scripts/player.gd`: HIZ 300 px/sn (5 px/kare), ZIPLAMA_HIZI −520, YER_CEKIMI 1400 → tepe 520²/2800 = **96,6 px** (B4 ölçümü ~100,9; "erişilir" hesapta 96,6, "erişilmez" hesapta 100,9 kullanıldı), tepeye ~22 kare, havada ~45 kare; 220 px düşüş ~34 kare, 75 px ~20 kare. `ASAGI_DUSME_KARE` 12 (bu bölümde zorunlu değil).
- `scenes/oyuncu.tscn`: gövde 28x48. `docs/kararlar.md`: 60 fizik karesi/sn; ekran 1152x648; koridor kuralı (100 px F tasarımı; burada F2 200 px, F1 180 px).
- `scripts/gecit.gd` + `scenes/gecit.tscn`: 20x200, `hiz` 120 px/sn (2 px/kare), `kayma_mesafe` export (100), VEYA mantığı, kapanırken altında karakter varsa durur.
- `scripts/lazer.gd`: ışın kalınlığı 6 px, `uzunluk` export, `tetik_aktifken_kapali`, `monitoring` set_deferred (≤ birkaç kare gecikme; B13'te "+1 kare açılır, ışına +3 kare" ölçüldü).
- `scripts/basinc_plakasi.gd` + `scenes/mandal_plaka.tscn`: 60x16, `mandal = true`: ilk çakışmada `kilitli = true`, tur sonuna kadar etkin; her tur sahne yeniden kurulunca sıfırlanır.
- `scenes/tek_yonlu.tscn`: 120x12, `one_way_collision`, margin 4.
- `scripts/bolum.gd`: `max_klon` export, kayıt bitince klon boş girdiyle bekler, sınır duvarları ekran dışında.
- `scripts/gorunum.gd`: PLAKA_MANDAL kilidi plakanın 14 px üstüne çizer (`_plaka_mandal`), `_draw` match'inde kol mevcut.

## 15. Kullanıcıya sorular
1. **`max_klon`:** (a) **2 (öneri):** mandal dersi zorunlu; naif yol T gerektirir. (b) 3 + `ipucu_klon = 2`: naif 3 klonlu yol da biter, "Az klonla çözüldü" rozeti ödül olur; ders zorunlu değil.
2. **G'nin yeri:** (a) **LazerA'dan sonra (öneri):** mandal işini B yapar, A sade tutucu. (b) PlakaA'dan önce: A mandala dokunup PA'ya gider; ders ilk turda kendiliğinden çıkar (daha yumuşak).
3. **(İsteğe bağlı, yalnız görünüm, grafik işi):** plaka ile bağlı geçit/lazer arasında aynı renkte küçük işaret ya da ince "kablo" çizimi. Mekanik değil; okunabilirliği artırır. Şimdilik eşleşme yakınlıkla okunuyor.
4. Not (ana oturum): eski `_b16_*` testleri ve CLAUDE.md/kararlar.md'deki B16 tanımı ("mandal plaka, 3 klon") onaydan sonra güncellenmeli.
