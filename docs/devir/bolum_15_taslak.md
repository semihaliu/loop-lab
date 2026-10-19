# Bölüm 15 taslağı: Fitil
(Tasarımcı çıktısı; gece otonom üretim, kullanıcı onaylı.)

> **ÖLÇÜM NOTU (2026-10-16):** Bu taslağın kare/piksel sayıları tahmindi; ölçümler `docs/sorunlar.md` "Bölüm 15-17" ve `tests/test_runner.gd` `_b15_*` testlerindedir. Güncel: tur kareleri 148/189/249; ZP'den sonra duraksama payı 60 kare (taslak ~51); C_A geç basış payı 14 kare (taslak ~25); C_B bekleme ≥64 kare; S eşiği 1012..1078 (66 px); Z1'de `sag` bırakma yalnızca 0..9 kare (uzun bırakmada baş döşeme köşesine çarpar, yeniden fırlatma); `tutma_kare` tam 180; canlı/klon farkı 0,00 px. §9.3 tek başına doğru değil (C_B plakayı geçerken kendisi basıyor, gerçek pay ~14 kare); §9.6 "rafta `sag` ile S ışına iner, ölür" son turda LazerB kapalı olduğundan geçerli değil. Min klon 2 doğrulandı, kısayol yok.


> **UYARI:** Bu taslağın bütün kare/piksel sayıları TAHMİNDİR (kare modeli: 60 kare/sn, HIZ 5 px/kare, ölçüm yapılmadı). Uygulama sonrası ölçümle düzeltilecek (Bölüm 12-14 deneyimi: taslak sayıları hep ölçümle değişti). Harita konumu: harita agent atayacak.

(`scenes/bolumler/bolum_15.tscn`, `max_klon = 3`, **çözüm en az 2 klon**.) Sabitler `player.gd`, `gecit.gd`, `lazer.gd`, `basinc_plakasi.gd`, `yayli_ziplatici.gd`, `tek_yonlu.tscn` ve Bölüm 14 taslağından okundu: karakter 28x48, HIZ 300 (5 px/kare), zıplama tepesi 96,5 (kare ~100,9), g 1400, `ASAGI_DUSME_KARE`=12, zıplatıcı 820 px/sn (tepe ~247, havada ~71 kare), geçit 20x200 ve 120 px/sn (2 px/kare), lazer ışını 6 px, plaka 60x16. `ZamanliPlaka` (`tutma_kare`, varsayılan 180) varsayım: basış bitince `basili_mi()` 180 kare daha true döner, yeniden basış sayacı yeniler; bağlı geçit/lazer koduna dokunulmaz.

## 1. Fikir ve özet
- **Öğrettiği fikir:** zamanlı plaka (fitil). Basıp bırakınca geçit 3 sn açık kalır; bu süre içinde koşmak gerekir, plakada durup tutucu klon harcamak gerekmez. A ve B zaten iki mıhlanmış tutucudur; ZP normal plaka olsaydı ZP başında kalan 3. bir klon şart olurdu (§8 kanıt). Zamanlı plaka tam bir tutucuyu tasarruf ettirir; `max_klon = 3` pay bırakır (ZP başında klon bırakan 3 klonlu yol da geçerli, daha kolaydır).
- Uygulama notu: `ZamanliPlaka` = `BasincPlakasi` + `tutma_kare` (CLAUDE.md); sahne `scenes/zamanli_plaka.tscn`, `tutma_kare` varsayılan 180.
- Nesneler: zamanlı plaka x1, plaka x2, geçit x1, lazer x2, yaylı zıplatıcı x1, tek yönlü raf x1 (S ile iniş), kapı. YOK: kutu, bant, şalter, asansör (öğretici bölüm; zorluk 16-17'de artar).
- **Min klon 2** (§9). Turlar: C_A (~130 kare), C_B (~190), oyuncu (~255); hepsi ≤ 600.
- İç içe: zıplatıcıyla kata çıkış, iki mıhlanmış lazer tutucusu, zamanlı geçit koşusu, S ile kuyuya iniş.

## 2. Kat planı (yüzeyler: F1 y=600, F2 y=380; F2 koridoru 200 px: y 180..380; F1 koridoru 180 px: y 420..600)
```
y=0   ┌────────────────────────── Tavan (y 0..180) ───────────────────────────┐
y=180 │ F2 koridoru (200 px)  LazerA     GecitG   LazerB(ışın x=1060, y180..600)│
      │                         |          |       |   [raf S]                 │
y=380 ├──────────┐ boşluk ┌──[PlakaA]───────|──[PlakaB]──── Raf ─┤ SağDuvar    │
y=420 │ DöşemeSol│ 470..570│ DöşemeOrta (x570..1000)           │ kuyu   │      │
      │ (F1 koridoru 180 px)  Z1 gap        DuvarF1 (980..1000)│ [Kapı] │      │
y=600 └─[O]─[ZP]──────[Z1]─────────────────────────────────────┴────────┴──────┘
       60   120       520                                      1000..1120 (kuyu)
```
- Z1 (x=520) boşluktan (x 470..570) F2'ye fırlatır. F1 koridoru x=980'de DuvarF1 ile kapalıdır: kuyuya yalnız F2'deki raftan S ile inilir.
- Raf (x 1000..1120) kuyuyu kapatır: yürüyerek geçilir, S ile düşülür. Kapı kuyu tabanındadır, LazerB ışını raf ve kuyuyu tavandan zemine keser.

## 3. Nesneler (merkez, boyut)
| Düğüm | Tür | Konum | Boyut / parametre |
|---|---|---|---|
| Zemin | StaticBody2D | (576,620) | 1152x40 |
| Tavan | StaticBody2D | (576,90) | 1152x180 (y 0..180) |
| DosemeSol | StaticBody2D | (235,400) | 470x40 (x 0..470, üst y=380) |
| DosemeOrta | StaticBody2D | (785,400) | 430x40 (x 570..1000) |
| DuvarF1 | StaticBody2D | (990,510) | 20x180 (x 980..1000, y 420..600) |
| SagDuvar | StaticBody2D | (1136,390) | 32x420 (x 1120..1152, y 180..600) |
| Raf | tek_yonlu.tscn | (1060,386) | 120x12, üst y=380 |
| PlakaZ (ZP) | zamanli_plaka.tscn | (120,592) | 60x16; `tutma_kare = 180` (varsayılan) |
| PlakaA | basinc_plakasi | (640,372) | 60x16 (x 610..670) |
| PlakaB | basinc_plakasi | (940,372) | 60x16 (x 910..970) |
| Z1 | yayli_ziplatici.tscn | (520,594) | 60x12, `firlatma_hizi=820`, sensör x 490..550 |
| GecitG | gecit.tscn | (860,280) | 20x200 (y 180..380), `kayma_yonu=(0,-1)`, `kayma_mesafe=100`, `hiz=120`, tetik [../PlakaZ] |
| LazerA | lazer.tscn | (740,180) | `yon=(0,1)`, `uzunluk=200` (x 737..743, y 180..380), tetik [../PlakaA], `tetik_aktifken_kapali=true` |
| LazerB | lazer.tscn | (1060,180) | `yon=(0,1)`, `uzunluk=420` (x 1057..1063, y 180..600), tetik [../PlakaB], kapalı=true |
| Kapi | kapi.gd Area2D | (1100,576) | 36x48 |
| Oyuncu | oyuncu.tscn | (60,576) | |
| Bilgi | Label | (16,12) | |

**Ağaç sırası:** Zemin, Tavan, DosemeSol, DosemeOrta, DuvarF1, SagDuvar, Raf, PlakaZ, PlakaA, PlakaB, Z1, GecitG, LazerA, LazerB, Kapi, Oyuncu, Bilgi (plaka/geçit/lazer karakterlerden önce). Başlangıç: lazerler açık, geçit kapalı; oyuncu ZP'ye değmez (gövde x 46..74, plaka 90..150).

## 4. Roller
- **C_A:** ZP üstünden geçer, Z1 ile F2'ye uçar, PlakaA'da kalır (LazerA kapalı).
- **C_B:** aynı koşu, G'yi fitil süresinde geçer, PlakaB'de kalır (LazerB kapalı).
- **Oyuncu (son tur):** aynı koşu, rafta S, kuyudan kapıya.

## 5. Çözüm (tuş kareleri tahmin)
**Tur 1 (C_A, ~130 kare):** `sag` kesintisiz: ZP üstünden geçilir (kare ~3..21 basılı), Z1 sensörüne kare ~83'te girilir, `sag` basılı tutularak fırlama (gövde boşluk duvarına x=556'da yaslanır, kare ~110'da F2'ye çıkar), PlakaA'ya kare ~118'de değer; x~640'ta dur, ~15 kare bekle, R.
**Tur 2 (C_B, ~190 kare):** C_A oynar. Aynı koşu; LazerA ışınına kare ~143'te varılır (C_A plakada kare ~118'den beri): geçilir; G'ye kare ~166'da girilir, kare ~176'da çıkılır; PlakaB'de x~940'ta dur (kare ~187), ~10 kare bekle, R.
**Tur 3 (oyuncu, R kapalı "Klon: 2/2", ~255 kare):** aynı koşu; PlakaB'yi geçtikten sonra raf üstünde x 1014..1043 arası dur, `sag` BIRAK, `asagi` bas (kare ~210); kuyuya düşer (~34 kare), `sag` ile x~1080'e, kapı (kare ~255).

## 6. Zamanlama pencereleri (pay)
| # | Pencere | Hesap | Pay |
|---|---|---|---|
| W1 | ZP son basış (kare ~21) -> G'den çıkış (kare ~176); geçit geçilebilir: 180 + 26 kare (açıklık >= 48) | 227 - 176 | **~51 kare** (~255 px) |
| W2 | Z1 uçuşunda `sag` basma başlangıcı: sensör girişinden en geç ~28 kare sonra | gövdenin boşluk kenarına 16 kare yürümesi + 20 kare havada | **~28 kare**; daha geç/bırakılırsa gövde boşluğa geri düşer, Z1 yeniden fırlatır (kayıp ~71 kare, W1 payı 51 < 71: G kaçar) |
| W3 | C_A'nın PlakaA'ya basması (kare ~118) -> C_B'nin LazerA ışınına varışı (kare ~143) | 143 - 118 | **~25 kare** |
| W4 | C_B'nin PlakaB'ye basması (kare ~172) -> oyuncunun LazerB ışınına varışı (~kare 245) | | **~70 kare** |
| W5 | S konumu: raf üstü, gövde tam raf üstünde (merkez >= 1014) ve ışının solunda (merkez <= 1043) | 29 px | **29 px** (>= 12; sağ tuşu bırakılmalı, aksi 12 karede +60 px ışına sürer) |
| W6 | Kapıya yürüyüş (ışın kapalı iken) | | tek yönlü, pencere yok |
- Zorunlu pencerelerin hepsi >= 25 kare / 29 px; bant, dikiş, plaka-bant ayrışması bu bölümde yok.

## 7. Atlanamazlık (sayılar sahneden)
- **Zemin -> F2:** döşeme üstü y=380, zeminden 220 px > 100,9 (pay 119). Tek yol Z1 (tepe 247 > 220; ayak y 353, F2 yüzeyinin 27 px üstü).
- **GecitG:** kapalı y 180..380, tavan y=180 bitişik, boşluk 0; üstüne çıkış 200 px > 100,9. Açıkken kapalı alt kenar y=280 (açıklık 100).
- **LazerA:** ışın y 180..380 (tavan-zemin bitişik); zıplama baş y 251 ışının içinde. Z1 uçuşu x=520'de, ışın x=740'ta: uçuşla aşılmaz (ayak min y 353, baş 305, ışın bandı içinde).
- **LazerB:** y 180..600 (tavandan kuyu tabanına); raf üstü yürüyüş ve kuyu yürüyüşü ışından geçer.
- **F1 -> kuyu:** DuvarF1 x 980..1000 (180 px) F1 koridorunu kapatır; kuyu tabanı F2'den 220 px, oradan F2'ye yalnız S düşme ile (çıkış yok).
- **Kapı:** yalnız kuyu tabanında; kuyuya raf S ile girilir.

## 8. Kısayol taraması (min klon 2'yi düşüren yol YOK)
| Deneme | Sonuç | Neden |
|---|---|---|
| Klonsuz | olmaz | LazerA'da (kare ~143) ölür |
| 1 klon (yalnız C_A / yalnız C_B) | olmaz | C_A tek: LazerB açık, kuyuda/rafta ölür. C_B tek: kayıt turunda LazerA'da ölür, kayıt alınamaz |
| min-1 = 1 klon (tutucu PlakaB, oyuncu PlakaA'yı kendisi tutmaya çalışır) | olmaz | oyuncu hem plakada hem kapıda olamaz; plakadan ayrılınca ışın 1 karede açılır, plakadan ışına 8 kare |
| Kutu basamağı / kutuyla plaka | uygulanamaz | bölümde kutu yok |
| Zıplatıcı + kutu | uygulanamaz | kutu yok |
| Bant dalgalanması | uygulanamaz | bant yok |
| Geçit altı park / röle | işlemez | tek geçit (G) yalnız fitil süresi sorunu; lazerler park edilemez (ölüm). G altında park edip kör klonu geçirmek A/B tutucu sayısını azaltmaz (LazerA/B mıhlanma) |
| S ile yeni iniş yolu | yok | tek raf, kuyuya iniş zorunlu yoldur; F2'de başka tek yönlü yok |
| Lazeri zıplayarak aşma | olmaz | ışınlar tavandan zemine bitişik (§7) |
| **Zamanlı plakayla röle / zaman paylaşımı** | min'i düşürmez | tek klon A'da kalıp oyuncu geçince B'ye gitmek: plakadan ayrılınca LazerA ışını açılır, plaka sağ kenarı 670, ışın 737: klon ~8 karede ölür. G'yi ZP ile kimin açtığı fark etmez (her geçen kendi basar). ZP yalnız G içindir; tutucu sayısı A, B = 2 |
| Mandal plaka ile klon tasarrufu | uygulanamaz | bu bölümde yok |
| ZP'yi oyuncunun kendisi basması | tasarım yolu | G'yi her geçen kendi koşusuyla açar; klon azaltmaz (LazerA/LazerB tutucuları ayrıdır) |
**Min klon 2 kanıtı:** LazerA'nın tutucusu (PlakaA) ışının 67 px gerisinde, ışından önce: tutucu kendi lazerinin gerisinde mıhlanır (ayrılan ölür); LazerB'nin tutucusu da öyle (PlakaB, ışın 90 px ileride kuyuda). Oyuncu son turda ikisinin geçildiği anda ikisini de gerektirir; ikisi aynı klon olamaz (PlakaA'dan PlakaB'ye giden yol LazerA'dan geçer, klon plakadan ayrılınca ışın açılır). Oyuncu kendisi plakada kalırsa kapıya gidemez. Klon kaydı, kör kayıtla başka bir turda geçilemez (kayıt turunda LazerA'ya giren oyuncu ölür, tur atılır). Normal plakalı ZP olsaydı (G'de mıhlanmayan ama ZP başında kalması gereken 3. tutucu) min 3 olurdu: zamanlı plaka tam 1 tutucu tasarrufu sağlar.

## 9. Başarısızlık senaryoları
1. Klonsuz: LazerA'da ölür, tur yeniden başlar.
2. Yalnız C_A: oyuncu LazerB'de ölür (kuyuya iner, ışın x=1060 açık).
3. C_A kaydında PlakaA'dan erken ayrılma: LazerA açık, C_B ve oyuncu ölür (kayıt tekrarı).
4. Z1'de `sag` bırakılırsa: uçuş boşluğa geri düşer, ~71 kare kaybı, G kapanır; oyuncu G'nin solunda kalır, ZP'ye dönmek için ... F2'den F1'e boşluktan düşüp (yürüyerek) tekrar dener, kilit yok.
5. G'de geç kalma (fitil bitti): G kapalı, çarpıp durur; ZP'ye dönüp yeniden basması gerekir (~190 kare).
6. Rafta `sag` basılıyken S: 12 karede +60 px sürükler, ışına inip ölür.
7. C_B PlakaB'ye ulaşmadan R: LazerB açık, oyuncu kuyuda ölür.
8. S çok erken (merkez < 1014): döşeme desteği sürer, S etkisiz; hata değil, tekrar dener.

## 10. Kilitlenme analizi ("Baştan başla" dışı çıkmaz arar)
- Kutu yok, asansör yok; klon asansör altında kalmaz. Klonlar plakada durur, kimseyi engellemez.
- Oyuncu LazerB açıkken kuyuya inerse (C_B yok) ışına girmeden solda kalabilir; F2'ye dönüş yok (220 px). Çıkış: R (klon hakkı varsa tur biter) ya da "Baştan başla". Tur 3'te klon hakkı yok: "Baştan başla" gerekir. Bu geri dönmesi zor karardır (§12).
- Klon G altında bitmez (C_A ve C_B plakada biter).
- ZP başında bekleyen klon yok (bilinçli; fitil).

## 11. S düşme kullanımı ve riskleri
Tek S kullanımı rafta (x 1000..1120). Risk: sağ tuşu basılı iken S (W5), S'nin erken basılması (etkisiz), kuyuya geri dönüş yok. S düşme 12 karede raftan çıkar, ~34 kare düşer.

## 12. Geri dönmesi zor kararlar (kullanıcı karar versin)
1. **Kuyuya dönüşsüz iniş:** kuyudan F2'ye çıkış yok; yanlış zamanda S "Baştan başla" gerektirir (alternatif: kuyuda bir zıplatıcı ile dönüş, ama LazerB'yi atlama olasılığı doğar).
2. **`tutma_kare = 180` (varsayılan):** G payı ~51 kare; öğretici olduğu için bilerek geniş. Daha sert istenirse sahnede 120 yapılır (pay ~ -9: bu durumda G'yi 15 px sola çekmek ya da ZP'yi 100 px sola taşımak gerekir).
3. **ZP başlangıca yakın (x=120):** bekleme/koşu zorunlu; klon ZP'de kalamaz (kalırsa C_A/C_B yerine geçmez).
4. **Kutu/bant yok:** zorluk 16-17'ye bırakıldı.
5. **Harita konumu:** harita agent atayacak.
