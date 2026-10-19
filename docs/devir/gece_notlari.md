# Gece notları (otonom çalışma, 2026-10-15 → 16)

Biçim: karar, gerekçe, alternatif. Kullanıcı yok; orkestra şefi (ana oturum) yazar.

## Başlangıç
- **Sorunlar dosyası:** kullanıcı `docs/devir/sorunlar.md` dedi; mevcut `docs/sorunlar.md` korunur, `docs/devir/sorunlar.md` gece bulgularının listesidir ve ana dosyaya işaret eder. Gerekçe: iki yerde dağınık yazmamak; alternatif: dosyayı taşımak (geçmiş referansları bozar).
- **İki yeni basit nesne (kullanıcı limiti: en çok 2):** (1) *Zamanlı plaka*: basılı bırakıldıktan sonra `tutma_kare` fizik karesi (180 = 3 sn) daha aktif kalır; (2) *Mandal plaka*: bir kez basılınca tur sonuna kadar aktif kalır ("tek kullanımlık" yorumu). İkisi de mevcut `basinc_plakasi.gd`'ye varsayılanı eski davranış olan export alanlarıyla eklenir (`tutma_kare = 0`, `mandal = false`), böylece mevcut 371 test etkilenmez. Gerekçe: plaka/şalter kadar basit, determinist (yalnız fizik karesi sayacı), kayıt formatına dokunmaz. Alternatif: zamanlı kapı (kapı/geçit koduna dokunur, daha riskli), yeni şalter türü.
- **Paralel çalışma düzeni:** nesne uygulaması, Bölüm 15–17 tasarımı ve arayüz (Parça 2) paralel; `tests/test_runner.gd` yalnızca test-yazari tarafından düzenlenir (çakışma önlemi); commit'leri yalnızca ana oturum atar.

## Arayüz (grafik)
- **Geçiş yalnız fade-in:** karar: yeni sahne açılırken perde solar, çıkışta solma yok. Gerekçe: R/ölümde reload'u geciktirmemek, girdiyi yutmamak. Alternatif: çıkış solması (reload gecikir, determinizm riski).
- **Süre = önceki kayıtların uzunluğu toplamı + canlı kare**, gösterim `mm:ss.s`. Alternatif: yalnızca son tur (kullanıcı toplam istedi).
- **Mevcut `Bilgi` etiketi ve düğüm adları korundu**; yeni düğümler kodla eklendi (KlonEtiketi, AzKlonRozeti, KlonGostergesi, GecisKatmani). HUD/geçiş headless'ta kurulmaz.

## Zamanlı / mandal plaka (uygulayici)
- **Kip, `basili_mi()` içinde, `Engine.get_physics_frames()` ile karede bir kez ilerler.** Karar: sayaç lazy + `_physics_process` ikisinden de tetiklenir. Gerekçe: asansör/geçit/lazer aynı kareyi birden çok kez sorgular, sayaç çift düşmemeli; ağaç sırası bağımsız. Alternatif: yalnızca `_physics_process`'te sayaç (sorgu sırasına bağımlı, bir kare gecikme riski).
- **Varsayılan (0/false) yolu eski tek satırdır** (`has_overlapping_bodies()`), davranış birebir.
- **Tutma süresi tam `tutma_kare` kare** (bırakıldıktan sonra); `tutma_kare+1` ile yüklenir. Alternatif: bir eksik kare, anlamı belirsiz.
- **Mandal/sayaç sıfırlama:** sahne her tur `reload_current_scene` ile kurulduğu için ekstra kod yok.
- **Görünüm:** ayrı `Tur` değerleri (PLAKA_ZAMANLI, PLAKA_MANDAL), taban `_plaka()` yeniden kullanılır. Hiçbir bölümde kullanılmıyor.

## Arayüz: ana menü, kontroller, harita (grafik)
- **Harita yerleşimi:** 5x4 yılan ızgara (x 140..1020 aralık 220, y 165..510 aralık 115), tüm bağlantılar yatay/dikey. Gerekçe: kesişim ve düğüm örtüşmesi yapısal olarak yok, düğümler >=115 px mesafede, ana yol okunaklı. Alternatif: serbest eğri yol (15–20 eklenince kesişim riski). Konumlar `docs/devir/harita_yerlesim.md`'de.
- **Bölüm adları:** 1 "Giriş", 2 "İkiz" (taslak dosyası yok, tahmin; değiştirilebilir), 3–14 taslak başlıklarından.
- **Kontroller tuş adı:** `OS.get_keycode_string(physical_keycode)` (İngilizce adlar: Left, Space...). Gerekçe: InputMap'ten okunur, sabit metin yok. Alternatif: sözlükle Türkçeleştirme.
- **Ekran butonları satırı** sabit açıklama (InputMap eylemi değiller).

## Bölüm 15-17 taslakları (tasarımcı)
- **Karar:** Üç bölüm aynı kabuğu (F1 y=600 / F2 y=380, 180-200 px koridorlar, Z1 ile kata çıkış, raf + S ile iniş) kullanır; fikir sırası 15 zamanlı plaka (min 2), 16 mandal plaka (min 3), 17 ikisi birden + ters bant (min 3). Gerekçe: aynı kabukta sayılar (zıplatıcı tepe 247, S 12 kare) bir kez hesaplanıp güvenle yeniden kullanılır; zorluk yeni nesne ve sıkılaşan paylarla artar. Alternatif: her bölümde yeni kat planı (hesap riski, ölçüm yükü).
- **Karar:** Min klon kanıtı "mıhlanmış tutucu" argümanıyla (plaka lazerin 25-145 px gerisinde, ayrılan ışına varıp ölür) yapıldı; zamanlı/mandal plaka yalnız cepte/koşuda 4. tutucuyu engeller, tutucu sayısını düşürmez. Alternatif: geçit-tutucu zinciri (geçit altı park/röle Bölüm 6'da min'i düşürdüğü için kaçınıldı).
- **Karar:** Bölüm 17'de `tutma_kare = 70` (sahne ayarı); `tutma_kare` export değilse ya da 180'e sabitse G_Z 60 px sağa çekilir (taslakta not). Gerekçe: fitil payı ~21 kare (varsayılan 180'de ~130 kare, anlamsız kolay). Alternatif: 180 bırakıp koşuyu uzatmak (kat planı büyür).
- **Karar:** Kutu bu üç bölümde yalnız basamak (16: Sehpa 120 px; 17: ledge 114 px) ve plaka tutamayacak yerde (kuyu / LazerC sağı) konuldu; kutuyla plaka tutma ve zıplatıcıyla kutu taşıma yolları kapatıldı. Alternatif: kutuyu tutucu yapıp 4 plakayla 3 klon (daha fazla kısayol yüzeyi).
- **Açık/ölçülecek:** Z1/Z2 yan duvara yaslı fırlama (x=186/526/666'da yaslanma) ve cepte raf-S düşüşü Godot ölçümüyle doğrulanmalı; B17 W2/W7 payları 11,67 px bant dikişi ayrışması düşülerek verildi; Z2 sensörünün raf1 S penceresine (606+) bitişikliği ölçümle teyit edilmeli.

## Bölüm 15-17 uygulaması (uygulayici)
- **Karar:** `bolum_15/16/17.tscn` taslak tablolarına birebir kuruldu (ağaç sırası, parametreler, `tutma_kare`: B15 180, B17 70). Gerekçe: taslak onaylı. Zamanlı/mandal plaka örneklerine (alt sahne) Gorsel ColorRect (plaka rengi 0.6,0.55,0.25) çocuk olarak eklendi; diğer plakalarla görsel uyum.
- **Karar:** Lazer "kapalı=true" ifadesi `tetik_aktifken_kapali = true` olarak okundu (B15 LazerA/B, B17 LazerC dahil tüm lazerler). `ipucu_klon` verilmedi.
- **Çelişki yok / sapma yok.** Taslak sayıları (kare, px) ölçülmedi; ölçüm ve çözüm testleri sonraki iş. B16 Kutu (920,360) oyuncudan 880 px, B17 kutu (1060,580) oyuncudan >1000 px.
- Kayıtlar: 15 "Fitil" (1020,395), 16 "Mandal" (1020,510), 17 "Çifte Mühür" (800,510). Tüm testler (harita 17 kayıt, çizgi kesişimi dahil) GEÇTİ.

## Bölüm 18-20 taslakları (tasarımcı)
- **Karar:** 18 "Vardiya" (min 2), 19 "Karşı Ağırlık" (min 3), 20 "Büyük Saat" (min 3, final). Fikir sırası: 18 zamanlı plakalı asansör (tek başına binilen) + F1 arka odaya dönen döngü ve tek plakanın iki katta iki lazeri; 19 normal plakalı ikinci asansör (karşı ağırlık/biniş koreografisi) + 3 kat + kapalı oda; 20 tutucu devri (asansör plakasından geçit plakasına röle zorunlu) + ters bant + şalter "geri bas". Gerekçe: B15-17 asansör/şalter/geçit içermiyordu; yeni nesne eklemeden eski mekanikler birleştirildi, her bölümde min klon kanıtı "mıhlanmış tutucu" + zaman aralığı çakışmasıyla yapıldı. Alternatif: B15-17 kabuğunu tekrar etmek (hesap güvenli, ama sentez eksik).
- **Karar:** 3 katlı kabuk (F1 600 / F2 380 / F3 160, F3 koridoru 160 px, baş payı 15,5 px) B19-20'de kullanıldı; F3 yüzeyi/sınır duvarı ölçümle doğrulanmalı (geçit sınır duvarına gömülü). Alternatif: 2 katlı kabuk + cep (B17 gibi; daha az "çok katlı").
- **Karar:** Zamanlı plaka asansör plakası olarak kullanıldı ("kendi asansörünü tut"): plaka asansörün üstünde (Area2D, asansör katman 1 algılanmaz) bırakıldı ki biniş dikişi/taşma çakışması olmasın (plaka asansör sağ kenarında olsaydı gövde yukarı çıkarken kat alt kenarına çarpardı). Varsayılan `tutma_kare = 180` bırakıldı (pay ~78 kare).
- **Karar:** B20'de zamanlı/mandal plaka ve kutu YOK (B15-19'da işlendi); final saf röle + şalter + bant. B18/B19'da bant ve kutu YOK. Alternatif: B20'ye hepsini koymak (tur >600 kare ve ölçüm yükü).
- **Açık/ölçülecek:** (1) asansörün üstündeki plaka ve fitil süresi; (2) L2 biniş penceresi +-6,8 kare (68 px; asansör-zemin dikişi ayrışması >= 12 px düşüldü); (3) C_H devrinde PlakaL->PlakaX 8 px örtüşme ve G kapanma payı; (4) şalter "geri bas" penceresi 35 px (SolAlan çakışması önceki adım, ölçümle); (5) F2 kuyusunda (asansör tepedeyken) 40 px çukur; (6) kayıt sonu boş girdiyle bekleyen klon plakayı tutmaya devam eder (bolum.gd).
- **Kayıtlar (harita agent):** 18 "Vardiya" (580,510), 19 "Karşı Ağırlık" (360,510), 20 "Büyük Saat" (140,510); `onceki` sırayla.

## Bölüm 18-20 uygulaması (uygulayici)
- **Karar:** `bolum_18/19/20.tscn` taslak tablolarına birebir kuruldu (ağaç sırası, asansör `yukseklik=220`/`hiz=120`/`plaka`, zamanlı plaka varsayılan `tutma_kare=180`, bant `yon=-1 hiz=100`, G `kayma_mesafe=100`, Z1 `firlatma_hizi=820`). `ipucu_klon` verilmedi. Zamanlı plakaya Gorsel ColorRect eklendi (B15-17 kalıbı).
- **Okuma:** "kapalı=true" lazerler `tetik_aktifken_kapali = true`; LazerS `acik_taraf_sag=true`, `tetik_aktifken_kapali=false` (şalter sağdayken açık/öldürücü, lazer.gd ile tutarlı).
- **Not:** B20 Salter (1000,380) sahnenin taban noktası (alanlar y 332..380). B18 DosemeSol (x 0..160) taslakta ölü parça. Sapma/çelişki yok.
- Kayıtlar: 18 "Vardiya" (580,510), 19 "Karşı Ağırlık" (360,510), 20 "Büyük Saat" (140,510).

## 2026-10-16 (ikinci gece) — Parça 2: T tuşu, Türkçe kontroller
- **Kontroller ekranı iki sütunlu** (açıklama solda, tuşlar sağda); "(zıpla)", "(turu bitir)" parantezleri tuş sütununa yazılmadı, açıklama sütunu bunu söylüyor. `asagi` eylemi S + Aşağı ok olduğundan "S / Aşağı ok" görünür. Gerekçe: InputMap'ten okuma korunur.
- **Mevcut kontroller testi güncellendi (1 satır):** beklenen tuş adı artık `kontroller.gd` `TUS_ADLARI` sözlüğünden (kullanıcının istediği Türkçe adlar bu testle çakışıyordu). Başka test değiştirilmedi.
- **T tuşu geçiş perdesi sırasında:** perde yalnızca görsel; sonuç ekranı ve ölüm yeniden yüklemesinde `bitti=true` olduğu için T çalışmaz. Perde solarken çalışması kabul edildi (zararsız: aynı sıfırlama).

## Bölüm 9 ince ayar (2026-10-16, Parça 2 madde 3)
- **Karar:** F2 440 -> 430 (asansör 170, Kat2 170 boy, Plaka3/PlakaKutu/Kapı/Geçit/L1 F2'ye göre kaydırıldı), PlakaKutu x 930 -> 910, çözüm betiğinde k2 beklemesi 120 -> 60. Gerekçe: ölçülen oyuncu pencereleri zaten >= 15 kare; sorun boş bekleme (tur başına 2-3 sn) ve dar güvenlik payları (takılı-asansör basamağı -4,9 px, G sprint 2-4 kare). Sonuç: tur 25/164/274/348 kare, k3/oyuncu geç kalma 50 kare, basamak +5 px, G sprint 6-8 kare. Alternatif: F2'yi 434'e almak (basamak payı yalnız ~1 px, reddedildi); platformu sağa almak (k2 basışını geciktirir ama F2 kısayolu riski).
- **Karar:** Tur 4 test betiği L1 kapanmadan geçmez (x=800'de bekler). Gerekçe: k3 asansörde duvara dayalı durunca oyuncu k3'ü geçip açık L1'e giriyordu; insan oyuncu ışını görür, bu betik hatasıydı. Alternatif: betiği değiştirmeden durma aralığını 640'ta kesmek (yanlış dar pencere raporlardı).
- **Açık:** k2'nin "k3 ve kutu bindikten sonra bas" koşulu tek taraflı ve 2. turda görünmez (en erken ~kare 95). Ayar beklemeyi kısalttı, koşulu kaldırmadı; kullanıcıya not (`docs/sorunlar.md`).

## 2026-10-16 — Plakaları bandın üstüne oturtma (B14 PlakaR, B10 PlakaPG/PlakaP1)
Ölçüm `--b14` / `--b10` ile (sahne kopyaları scratchpad'de, her deneme ayrı koşu). Temel bulgu: plaka TAM bandın üstündeyse, plakayı **hareketsiz tutması gereken** karakter bantla sürüklenir; tutucu yalnızca (i) bandın dışında (ii) eş düzlem dikişinde (motorun zemin seçimine bağlı, canlı/klon ayrışır) ya da (iii) bant yönünde bir engele dayanarak durabilir. Kutu P1'de (iii) ile durur; PlakaR ve PlakaPG'nin tutucuları (i) ile duruyordu.

### Bölüm 14 PlakaR — DEĞİŞİKLİK YOK (2 seçenek ölçüldü, ikisi de KALDI, geri alındı)
- **(b) bandı 20 px sola uzatma** (Bant x470..650, BantAlti x470..650, UL1 x400..470; PlakaR x470..530 yerinde): `--b14` 10 KALDI (çözüm, başarısızlık 2/3/7/9, kısayol, W ölçümü, dikiş, determinizm). Çözümün "x<=475'te dur" noktası artık UL1|Bant dikişinin (x=470) üstünde: gövde 461..489 iki zemine değiyor. Dikiş ölçümü: C2 farkı 11,67 -> 5,00 px, ama **C3 1,67 -> 13,33 px (sınır 2,5)**: dikiş riski çözümün tutma evresine taşındı (kötüleşme). W2a PlakaR basılı 94 -> 67 kare, **W2b bant yarışı payı 2 -> 0 kare**. Girdisiz duruş: x0=486/496/506/520 plakadan 29..35 karede sürüklenip x=640,9'da (kutuya dayalı) duruyor; yalnız x0<=476 (dikişte) duruyor.
- **(a) plakayı sağa alma (520, x490..550)**: `--b14` 10 KALDI (önceki denemeyle aynı). Girdisiz duruş x0=469/476'da plaka basılmıyor (0-1/120), x0=486/496'da dikişte (UL1 sağ ucu 490) duruyor; C3 farkı 3,33 px (sınır 2,5). 510 (önceki deneme): çözüm geçer ama başarısızlık 5/10 bozulur, yarış payı 2,4 -> 8 kare (bölüm kolaylaşır) ve plaka yine 10 px UL1 üstünde (istenen "tam bant üstü" değil).
- **Seçim:** ikisi de reddedildi, PlakaR 500'de (x470..530) kaldı. Gerekçe: tam-bant-üstü her konumda C2/C3'ün PlakaR'da hareketsiz beklemesi (C2 >=51 kare, C3 C2 kutuyu geçitten geçirene kadar) ancak dikişte mümkün; bu da "dikiş riski kötüleşmemeli" koşulunu bozuyor (C3 13,33 px) ve bant payını 0'a indiriyor. 3. deneme yapılmadı: her "tam bant üstü" varyantı aynı ilkeye takılıyor (ölçümle doğrulandı).
- **Alternatif (kullanıcı/tasarımcı kararı):** (c) plakayı bandın SAĞ ucuna, kutunun önüne almak (sürüklenen tutucu kutuya dayanıp durur; ama yarış ve kutu sırası yeniden tasarlanmalı); (d) tutucunun dayanacağı görünür bir durdurucu/duvar eklemek (yeni geometri, taslak gerekir); (e) bant etkisini motordan ayırmak (sorunlar.md "dikiş" seçenek C; fizik değişir); (f) bırak (plaka 20 px UL1 üstünde; bandın başlangıcını gösteren kusur yalnız görsel).

### Bölüm 10 PlakaP1 — UYGULANDI (x380..440 -> x370..430)
- `PlakaP1` merkezi 410 -> 400: plaka artık tam Bant1'in (x270..430) üstünde ve Duvar (x430..450) ile örtüşmüyor. Tutucu kutudur ve bant onu Duvar'a dayayıp durdurur (kutu x 389,93..429,93, plakanın içinde), sürükleme sorunu yok.
- Ölçüm (önce -> sonra): L1 ilk kapanış (A turu) kare 79 -> 73 (kutu plakaya 10 px önce değer); tur kareleri 251/187/336 + 394 -> 251/181/335 + 393; A'nın PE basma penceresi (10'ar kare) 180..330 -> 180..330 (çözüm 230, pay -50/+100 kare, değişmedi); A canlı/klon farkı 3,33 -> 1,67 px (iyileşti), C 2,04 -> 2,04. Klon sayısı 3, kısayol/başarısızlık/atlanamazlık testleri aynen geçti. Lazer1 ışını (x347..353) ile plaka sol ucu (370) arası 17 px: ışından geçmeden plakaya değilemez (ışın tavandan zemine).

### Bölüm 10 PlakaPG — DEĞİŞİKLİK YOK (bant 70 px sola uzatma ölçüldü, geri alındı)
- **Deneme:** Bant2 x820..1050 (Kat2Sol x812..820, Kat2Dolgu x820..1050), PG x820..880 yerinde. Mevcut 24 test GEÇTİ ama yeni `_test_bolum10_pg_tutma` KALDI: son turda C klonu PG'de 813,33'te durmuyor, bant sola sürükleyip 805'e (plakanın dışına) alıyor; PG ilk basılıştan sonra 117 kare BOŞ. Girdisiz duruş: x0=830..890 hepsi ~805'e sürüklenir, plaka 70-95/120 kare basılı. Eski testler bunu görmüyordu (büyük olasılıkla oyuncu, geçit kapanmasını tamamlamadan geçiyor; ölçülmedi).
- Plakayı sağa (Bant2 üstüne, x890..950) almak aynı ilkeye takılır (C sola sürüklenir). **Seçim:** PG yerinde (Kat2Sol üstünde, bandın sol çıkışının 10 px solunda); yeni test tutmanın sağlam olduğunu bekçiler (önce/sonra: C 813,33'te sabit, 0 boş kare).
- **Alternatif:** PG'nin solunda görünür bir durdurucu (tutucu dayanır) + bant uzatma (geometri/taslak değişikliği, onay gerekir).

## 2026-10-16 — Bölüm 21 "Mandal" uygulandı (uygulayıcı) + harita 22 düğüm
- **Sahne:** `scenes/bolumler/bolum_21.tscn` taslağa (`bolum_21_taslak.md`) birebir: Zemin, Tavan, DosemeF2, BlokF1Sol, Raf (tek yönlü), PlakaM (mandal), PlakaA, PlakaB, GecitG, LazerA, LazerB, Kapi, Oyuncu, Bilgi; `max_klon = 2`, `ipucu_klon = 0`. Taslaktan sapma yok. Eski B16/B17 dokunulmadı.
- **Karar (geçit yeri):** G, LazerA'dan sonra (taslak önerisi a). Gerekçe: mandal işini B yapar, A sade tutucu kalır. Alternatif (b, PlakaA'dan önce): ders ilk turda kendiliğinden çıkar, daha yumuşak ama taslak ölçümleri değişirdi.
- **Karar (kablo):** plaka-geçit/lazer eşleşmesi için ince kablo çizimi, YALNIZ görünüm: `gorunum.gd` `_kablo()` (GECIT ve LAZER çiziminden çağrılır; yeni Tur/yeni düğüm yok, çarpışma yok). Üst düğümde `metadata/kablo` (dünya koordinatlı çoklu çizgi) varsa çizilir; yoksa hiçbir şey çizmez, bu yüzden eski bölümler değişmez. Tetikleyici plaka etkinken kablo camgöbeği + yeşil uç, değilken soluk metal. B21 rotaları: M -> G: (230,297)-(245,297)-(245,184)-(650,184) (tavan altından); PA -> LA: (440,375)-(523,375) (zemin üstünden alıcıya); PB -> LB: (886,594)-(800,594). Alternatif: aynı renkli küçük işaret (daha az bilgi) ya da tüm bölümlere kablo (eski bölümlerin görünümünü değiştirirdi, seçilmedi). Not: kablo ekran görüntüsüyle henüz gözle doğrulanmadı (headless çizim yok); gözden-geçirici/kullanıcı bakmalı.
- **Harita (22 düğüm):** 6x4 yılan ızgara: x = 140, 320, 500, 680, 860, 1040; y = 165, 280, 395, 510. Satır 1 (1-6) soldan sağa, 2 (7-12) sağdan sola, 3 (13-18) soldan sağa, 4 (19-22) sağdan sola (19@1040 ... 22@500). 1..21 `konum` değerleri güncellendi, 22 ayrıldı (`docs/devir/harita_yerlesim.md`). Neden: 5x4 ızgara 22 düğüme yetmez. `harita.gd`/`harita_arkaplan.gd`'de sabit koordinat yoktu, değişmedi.
- **Test durumu (KALDI beklenen):** `--gorunurluk`: "Bölüm listesi: 20 kayıt ve 20 farklı sahne dosyası" (n == 20 sabit; kayıt 21). `--arayuz`: "Harita: BolumListesi konumları harita_yerlesim.md tablosuyla eşleşir" (`tablo.size() == 20 and n <= 20` sabit; tablo artık 22 satır) ve "Harita 20 düğümlük yerleşim" testleri 20 düğümü tarar (22'ye genişletilmeli). Bölüm 21 görünürlük taraması GEÇTİ (12 nesne, çizimsiz yok).

## 2026-10-16 — Bölüm 22 "Fitil ve Mühür" uygulandı (uygulayıcı)
- **Sahne:** `scenes/bolumler/bolum_22.tscn` taslağa birebir: Zemin, Tavan, DosemeSol, Raf (tek yönlü), DosemeSag, BlokF1Sol, BlokF1Sag, PlakaM (mandal), PlakaZ (zamanlı 180), PlakaA, PlakaB, GecitG, GecitM, LazerA, LazerB, Kapi, Oyuncu, Bilgi (18 düğüm); `max_klon = 2`, `ipucu_klon = 0`. Taslaktan sapma yok.
- **Kararlar:** G tetikleyicileri [ZP, M] VEYA (taslak önerisi); ad "Fitil ve Mühür"; kablo yalnız görünüm (`kablo` + yeni isteğe bağlı `kablo_2`, bkz. kararlar.md). Harita kaydı 22: (500, 510); `harita_yerlesim.md` 22. satır "kayıtlı".
- **Test notu:** test-yazari `--gorunurluk` (kayıt sayısı) ve `--arayuz` harita testlerini 22'ye uyarlıyor; eski `_b17_*` testleri / CLAUDE.md B17 tanımı güncellenmeli (taslak §15.5).

## 2026-10-16 — Bölüm 22 "Fitil ve Mühür" testleri ve ölçümler (test-yazari)
- **Testler:** `tests/test_runner.gd` `-- --b22` (ve tam koşu): 23 test. Çözüm (gerçek R yolu, 3 tur, tam 2 klon), sahne yapısı + 5 kablo meta'sı (`GecitG.kablo`=ZP, `kablo_2`=M, `GecitM`, `LazerA`, `LazerB`; başlangıç ilgili plakada, bitiş hedefte, ekran içinde), 10 başarısızlık, atlanamazlık, kısayol taraması (klonsuz, 1 klon x 6 rol x 8 strateji, 9 iki-klon kümesi, min klon 2, S inişleri), zamanlama payları, canlı/klon farkı, zamanlı/mandal plaka, oda tuzağı, klon sınırı, kilitlenme/çıkış, görünürlük (çizimsiz yok + Gorunum türleri), determinizm (20x). Sahne DEĞİŞTİRİLMEDİ.
- **Bölüm sayısı sabitleri:** kayıt sayısı = `bolum_*.tscn` sayısı testi eşiği `>= 21` -> `>= 22`. Harita testleri a0df0fa'da zaten genelleştirilmişti (22 düğüm kapsanıyor; `--arayuz` 18/18 GEÇTİ). Yukarıdaki "KALDI beklenen" notu (Bölüm 21 uygulaması) eskidir. Eski `_b17_*` testleri ve CLAUDE.md B17 tanımı DEĞİŞTİRİLMEDİ.
- **Ölçülen paylar (taslak tahmini -> ölçüm):**
  - Tur kareleri: A 165 (~180), B 280 (~285), oyuncu 309 (~295); hepsi <= 600.
  - Kuyuya iniş: raf ortası (c=380) k28, zemine 35 kare sonra (~34), iniş x=380. ZP basışı k96 (~96). PlakaA basışı k150 (~157).
  - W1 G: ZP basıştan +24 kare sonra >=48 px açık (k120), tam açık k146. B G önüne k9'da varır, **111 kare** bekler (~110). Fitil bırakıştan sonra tam **180** kare basılı; G (mühürsüz) bırakıştan +208 kare sonra <48 px (taslak ~206), tam kapalı açıklıktan +209.
  - B gecikme taraması (G önüne varış gecikmesi, çözüm bitiyor): **0..270 kare** (300+ kare geç gelen B odaya giremez; 340 kare geç: G kapalı, mühür basılamaz). A başta bekleme: 0..240 kare tarandı, hepsi bitti (üst sınır tur kare sınırı).
  - W5 mühür: kilit k137 (B G'den girdi, M k137), GM >=48 px k161 (+24), B GM'yi k237'de geçer -> **76 kare** pay (~78). Mühürden sonra G ve GM hiç kapanmaz (ölçülen son y=180).
  - W4 LazerA: A PlakaA k150, B LazerA'ya (x>=500) k215 -> **65 kare** pay (~54). Oyuncu LazerA önüne k48, ışın k151'de söner -> bekleme **103 kare** (~100).
  - LazerB: B PlakaB k265 (B G'den sonra PlakaB'ye ilk temasta durur, c~754; taslak c~790), oyuncu LazerB önüne (x>=850) k225, ışın k266'da söner -> bekleme **41 kare**. A+B birlikte basılı ilk kare k206; oyuncu LazerB ışınına (x>=886) k274'te varır.
  - GM: oyuncu GM önüne k178 (GM açılalı yalnız **17 kare**); LazerA bekleyişi nedeniyle doğal olarak sonradan gelir, ışını izleyen oyuncuyu etkilemez, ama sabırsız/hızlı bir oyuncu için GM'nin "kapalı" kalabileceği tek an budur (görünür).
  - W3 S penceresi (rafta kuyuya iniş, c): **336..424 (92 px)**; taslak güvenli 346..414, tam raf 334..426. Raf dışında (60, 200, 300, 460, 560, 800, 1000) S etkisiz; F2'de S yalnız x=360 ve 400'de kuyuya indirir.
  - Kuyudan çıkış: tüm x'lerde dikey/yatay zıplamada en yüksek ayak y=499 (F2 yüzeyi 380, kuyu tavanı 420, pay >= 119). G kapalıyken en küçük x=194, GM kapalıyken en büyük x=626 (tavana ulaşılmaz, baş y=231).
  - W7 tutucu kaçışı: PlakaB'den sağa ayrılan 13 kare sonra LazerB'de ölür (taslak ~10). PlakaA tutucusu kuyuda; ayrılsa bile kuyuda kalır (kaçış yok).
  - Canlı/klon farkı: A, B, oyuncu 0,00 px. Determinizm 20x: sapma 0.
- **Taslakla çelişki (sahne değil, taslak §8 "Kör kayıt" satırı):** "A tur 1'de G önünde körlemesine bekle-gir-mühürle-çık-PB kaydeder; 2 klonla da biter" iddiası ölçümde tutmadı. Kayıt turunda G kapalı ve PlakaA boş olduğu için A' sağa çıkınca LazerA'da ölür; kayıt ölüm anında kesilir, PB'ye giden yol kaydedilemez (`A'(kör)+B_fitilci` bitirmiyor, test bunu "bitirmez" diye bekliyor). Sonuç tasarımı kolaylaştırmaz, yalnız belgedeki alternatif yol satırı yanlış: kısayol değil, ama "2 klonla da biter" ifadesi düzeltilmeli (karar sende).
- **Not (taslak §6 W2):** "A ne kadar geç basarsa B o kadar bekler" alt/üst sınır yok iddiası doğru: 0..240 kare A gecikmesinde çözüm bitiyor.

## 2026-10-19 — Parça 1: Bölüm 19 kaldırıldı (kararı yazan: ana oturum)
- **Dosya adı kararı:** yeniden adlandırma seçildi (sıra numarası + eski dosya adı yerine). Neden: test dosyasındaki tüm sabitler/işlevler dosya adına bağlı; adlar kaymazsa "Bölüm 19 = bolum_20.tscn" kalıcı karışıklık olurdu. Risk: toplu yeniden adlandırma; tam test koşusuyla kapatıldı.
- **Yöntem:** eski B19 test bölümü (`_n19_*`, `_test_b19_*`) silindi; sonra `bN`/`nN`/`BOLUM_N`/`bolum_N`/"Bölüm N" kalıpları 20->19, 21->20, 22->21 tek geçişle kaydırıldı. `--b19` bayrağı artık eski B20'yi (Büyük Saat) koşar.
- **Test eşikleri:** `>= 22` -> `>= 21` (harita tablosu, bolum_*.tscn sayısı).
- Eşleme tablosu: `docs/devir/numara_esleme.md`.
