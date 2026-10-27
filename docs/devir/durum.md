# Durum (üretim dalı: `uretim`) — 2026-10-19

## 2026-10-27 — A12 görsel düzeltmeleri bitti (güncel, en üstte)
- **Biten:** pencereli ekran görüntüsü incelemesinin 5 bulgusu giderildi (`uretim`, push yok): Bölümlerim satırı iki satır (ad ellipsis+ipucu, altta durum/"Canlı: Bölüm N"/uyarı sarar, panel 900 px); sıra diyaloğunda açıklama görünür; tüm diyaloglar Türkçe başlıklı ("Onayla", "Uyarı"); haritada canlı düğüm halkası ve hover "· Canlı"; doğrulama şeridi uyarısı amber (kontrast >= 4,5:1). Resmî bölümlerin fiziği/çözümü/çizimi değişmedi (resmî ekran görüntüleri birebir aynı). Ayrıntı: `kararlar.md`, `testler.md` (2026-10-27).
- **Testler:** tam koşu 1180 GEÇTİ / 0 KALDI, determinizm 0,0000 px, `--dene-fizik` 21 GEÇTİ; 16 yeni "Editör A12 görsel" kontrolü.
- **Gözden geçirici (opus): koşullu kabul, işlendi:** harita etiketi ağaca eklenmeden ölçülüyordu (uzun canlı etiket ortalanmıyor, sağda taşabilirdi); ölçüm yazı tipiyle yapıldı, genişleme yalnız canlı etikette, test ortalama/kenetleme/ekran içi kontrolü eklendi.
- **Kalan risk:** çok uzun canlı etiket komşu bağlantı çizgisinin üstünden geçebilir (konturlu, okunur); başarılı "Doğrulandı" yolu ekranda yeniden görülmedi (testler kapsıyor). Diğer kalan riskler aşağıdaki A12 girişinde.

## 2026-10-27 — Parça 12 / A12 (Canlıya al) bitti
- **Biten parça:** A12 (`uretim`, push yok). `BolumListesi.liste()` (resmî 21 + `canli/sira.json`, saf okuyucu, `yenile()`), `HaritaYerlesimi.konum(i, n)` (≤40 bölüm), `CanliBolumler` (canliya_al / guncelle / kaldir), Bölümlerim'de Canlıya al (çözümsüzse "Çözüm doğrulanmadı, yine de ekleyeyim mi?" uyarısı, sıra seçici) / Canlıdan kaldır / Canlıyı güncelle; harita, HUD, sonuç ekranı `liste()` okur. `.tscn` dosyaları yeniden adlandırılmadı. Editördeki bayat "kablo henüz çizilmez" notu ve onu şart koşan A7 testi kullanıcı onayıyla düzeltildi. T1–T22 sahne yoluna / `liste()`'ye bağlandı (silinerek geçilen yok). Kararlar: `kararlar.md` 2026-10-27.
- **Testler:** bkz. `testler.md` 2026-10-27; tam koşu 0 KALDI, determinizm 0,0000 px, `--dene-fizik` 21 GEÇTİ.
- **Gözden geçirici (A12, opus): koşullu kabul, işlendi:** aynı yere ikinci ekleme artık "hemen sonra" (öncekiler arkaya geçer); bozuk/geçersiz `sira.json` üstüne yazılmaz (C6) ve yazma geçici dosyadan yerine geçer; kaldırmada devredilen kayıtlar kaldırılanın yerine taşınıp kardeş sırası korunur; sahne dosyası silinmiş canlı kayıt Bölümlerim'de yine canlı sayılır (kaldırılabilir); güncellemede dondurulmuş JSON en son yazılır; `canli/` yokken hata günlüğü yok; sira.json kimlikleri biçim denetiminden geçer.
- **Kalan risk / kullanıcı kararı:** (a) 40 bölüm sınırı (Y2) varsayılan karar; fazlası sayfalama/kaydırma ister. (b) Canlı bölüm oyundaki konumu yalnız "şundan sonra" ile seçilir; sonradan yer değiştirme için kaldır + yeniden al gerekir. (c) Başarısız `sira.json` yazımında geri alma yalnız sahne/JSON temizler (disk dolu gibi uç durumlar elle sınanmadı). (d) Canlı sahne dosyası sonradan silinirse kayıt `sira.json`'da kalır, listede görünmez (uyarı `son_uyarilar`'da; Bölümlerim'den kaldırılabilir). (e) Elle kontrol: oyunda 3 adım (aşağıda).
- **Elle deneme (3 adım):** 1) Ana menü → Editör → Bölümlerim → bir bölümde (ör. kayıtlı bir bölüm) "Canlıya al" → sıra listesinden "Şundan sonra: Bölüm 10 · Hat" → "Canlıya al" (satır "Canlı: Bölüm 11" olur). 2) Ana menü → Oyna: haritada 22 düğüm, 11. düğüm yeni bölümün; üstüne gelince "Bölüm 11: Ad". 3) 11. düğüme tıkla: HUD "Bölüm 11 · Ad"; bölüm 10 bitince "Sonraki bölüm" ona gider, eski 11 artık "Bölüm 12 · Yay". Geri almak: Bölümlerim → "Canlıdan kaldır".
- **Sıradaki parça:** editör v1 tamam (A1–A12). Kalan: kullanıcı elle kontrolü ve `uretim` dalının `main`'e alınması / push kararı (şimdilik push yok). Kullanıcı onayı bekle.

## 2026-10-21 — Parça 11 / A11 (kablo görünüm eki) + kirli_mi bitti
- **Biten parça:** A11 (`uretim`, push yok). (1) `gorunum.gd`: her `kablo_<N>` çizilir, şalter kablosu hedefin `acik_taraf_sag`ına göre yanar, asansör kablosu çizilir, ara noktalara perçin halkası; `kablo` birden çok tetikleyicili hedefte hep 1. tetikleyicidir. 21 resmî bölümün çizimi B1–B19'da piksel piksel aynı, B20/B21'de yalnız ara nokta perçinleri farklı. (2) `kirli_mi`: çözüm kaydı ve doğrulama sonucu da kaydedilmemiş iş (`BolumVerisi.kirlilik_metni`); Yeni/Aç/Menü/Bölümlerim onay sorar. (3) Pencere 1920x1080 + F11 (ayrı commit).
- **Testler:** tam koşu 1010 GEÇTİ / 0 KALDI, determinizm 0,0000 px, `--dene-fizik` 21 GEÇTİ; yeni 20 test (`-- --ed-a11`).
- **Gözden geçirici (A11): koşullu kabul, işlendi:** gizli 2. kablolu geçitte görünür kablo yanlış plakayla yanıyordu (düzeltildi, test eklendi); `range` bir fazla taranıyordu; zayıf içerik-özeti testi güçlendirildi; B20 kablo planı testi eklendi.
- **Kalan risk / kullanıcı kararı:** (a) Editör durum notu (`editor.gd` `_kablo_notu`) hâlâ "asansör kablosu ve 3. kablo oyunda henüz çizilmez" diyor, artık yanlış; A7 testi (`editor_testleri.gd` ~2600) bu metni şart koşuyor. Taslak A1–A11'de mevcut test değişikliğini yasakladığı için dokunulmadı: A12'de metin ve test birlikte düzeltilsin mi? (b) Perçin halkası B20/B21 köşelerini değiştirir (önceden bildirilmişti). (c) Headless'ta çizim atlandığı için kablo çizimi testte yalnız mantık düzeyinde sınanır; görünüm ekran görüntüsüyle elle doğrulandı. (d) `notlar`/`canli` alanları kirlilik metnine girmez (editör yazmıyor).
- **Bölüm 16/17 v2 durumu (belge düzeltildi):** v2 taslakları 2026-10-16'da onaylandı ve uygulandı; bugün **Bölüm 20 "Mandal"** ve **Bölüm 21 "Fitil ve Mühür"** (ilk numaraları 21/22; Bölüm 19 kaldırılınca 20/21; taslak dosyaları `bolum_20_taslak.md`/`bolum_21_taslak.md`). Sahnedeki 16 "Mandal" ve 17 "Çifte Mühür" eski (v1) sürümdür, bilinçli kalır. Onay bekleyen taslak yok.
- **Sıradaki parça:** A12 (Canlıya al + numara kaydırma + T1–T22). Kullanıcı onayı bekle.

## 2026-10-21 — Parça 10 / A10 (Bölümlerim ekranı) bitti 
- **Biten parça:** A10 (`uretim`, push yok): `scenes/bolumlerim.tscn` + `scripts/editor/bolumlerim.gd` (`Bolumlerim`): liste (ad, durum, hata/uyarı, dosya adına göre sıralı), Aç, Oyna (`<kok>oyna/oyna_NNN.tscn`), onaylı Sil, Yeni bölüm, Ana menü; editör çubuğunda "Bölümlerim" düğmesi; özel kip (`BolumYollari.ev_sahnesi`, HUD "Özel · Ad", sonuç ekranı "Bölümlerim'e dön"); `BolumVerisi.dogrulama_durumu` ortak; `EditorOturumu.ac_yolu/kok`.
- **Testler:** A10 için 33 kontrol (`--editor` 386 GEÇTİ satırı). Tam koşu: exit 0, KALDI yok, 990 GEÇTİ satırı, determinizm 0,0000 px; `--dene-fizik` 21 GEÇTİ.
- **Gözden geçirici (A10): koşullu kabul, işlendi:** şema HATA'lı ama geçerli JSON'da betik hatası (şema kontrolü öne alındı, `dogrulama_durumu` tür kontrolü), şema HATA'lı fikstür testi, Bölümlerim testlerinde kök `KOK`, zayıf testler güçlendirildi, kararlar.md kaydı.
- **Kalan risk:** Oyna tıklama anında statik denetimi yeniden çalıştırmaz (çok düşük); lazer önbellek izi Bölümlerim → Oyna yolunda ayrıca test edilmedi (kodda önbellek yok); A9'dan kalan açık sorular (kirli_mi çözüm/doğrulamayı saymıyor, tuş kısıtı, D12/D13 testi) duruyor.
- **Sıradaki parça:** A11 (taslak §9.2, görünüm eki). Kullanıcı onayı bekle.

## 2026-10-21 — Parça 9 / A9 (Doğrula) bitti 
- **Biten parça:** A9 (`uretim`, push yok): "Doğrula" düğmesi/F6, `EditorDogrulama` (ilerleme şeridi, Esc/İptal), `dogrulama` kaydı (`dogrulandi`/`taslak`, içerik özetiyle), durum çubuğunda doğrulama durumu, çift başlatma koruması, girdi sızıntısı önlemi. **Sıradaki parça:** A10 (Bölümlerim ekranı, Oyna). Kullanıcı onayı bekle.
- **Testler:** A9 için 25 kontrol. Son tam koşu: exit 0, KALDI yok, 1915 GEÇTİ satırı, determinizm 0,0000 px; `--dene-fizik` 21 GEÇTİ (B13/14/19 aynı).
- **Gözden geçirici (A9): koşullu kabul, işlendi:** iptal bekleme karelerinde kayboluyordu (düzeltildi), klavye/sonuç ekranı sızıntısı (olaylar tüketilir, `bastan`/`tur_bitir` bırakılır), çift başlatma; D10 uyuşmazlığı, kayıtlıyken iptal, erken iptal testleri eklendi.
- **Kalan risk / kullanıcı kararı:** `kirli_mi` çözüm ve doğrulamayı saymıyor (Kaydet'siz çıkışta sessizce kaybolur); fiziksel yön/zıplama tuşları doğrulama sırasında engellenemez (şerit uyarır); D12 kısayol ve çok klonlu uçtan uca test yok; D10 kaydı ikinci doğrulamada yeniden temel alınır.

## 2026-10-21 — Parça 8 / A8 (kalan türler, özellik paneli, lazer ucu) bitti
- **Biten parça:** A8 (`uretim`, push yok): palete zamanlı/mandal plaka, şalter, lazer, kutu, zıplatıcı, bant, tek yönlü (16 araç, iki sütun); sağ üstte özellik paneli (bant yönü, tutma kare, şalter tarafı, lazer yön/uzunluk/bayraklar, geçit tarafı/kayma, asansör yüksekliği; tek doğrulama `ozellik_ata`); lazer ucu tutamağı (yön + uzunluk); lazer yayıcı gövdesi tıklanabilir. **Sıradaki parça:** A9. Kullanıcı onayı bekle.
- **Testler:** `--editor` 100'ün üstünde yeni A8 kontrolü (657 GEÇTİ satırı editör koşusunda). Tam koşu: exit 0, KALDI yok, determinizm 0,0000 px; `--dene-fizik` 21 GEÇTİ (B13/14/19 aynı).
- **Gözden geçirici (A8): koşullu kabul, koşullar işlendi:** lazer `acik_taraf_sag` etiketi ayrıldı ("Şalter sağdayken tetik aktif"), `kablo_sec` paneli eşitliyor, Kaydet/Dene sayı kutusunu işliyor (`gui_release_focus`), yayıcı testi gerçekten yayıcı dalını sınıyor, panel/geri al/sürükleme testleri eklendi.
- **Kalan risk (kullanıcı kararı bekler):** lazer uzunluk aralığı arayüzde 10..1100 (şema yalnız >0 ister; dışarıdan gelen 1150 px ilk dokunuşta kıstırılır); `acik_taraf_sag`/`tetik_aktifken_kapali` tetikleyici yokken de görünür (taslak "gerekirse görünür" der); panel sağ üstte tuvali örter (`H`/Tab gizlemez, paletin fareden kaçması yok); uç tutamağı yayıcıya çekilince (v=0) yön "aşağı" olur ve uzunluk 10'da tutamak yayıcı kutusuyla çakışır; kutu/zıplatıcı/mandal için ayar yok; 40 px zemin mıknatısı ve çoklu seçim hâlâ ertelendi.

## 2026-10-21 — Parça 7 / A7 (bağlantı ve kablo arayüzü) bitti
- **Biten parça:** A7 (`uretim`, push yok): Plaka/Geçit/Asansör araçları, Bağla (K8 kuralları, asansörde ikinci plaka onayı), silmede bağlantı temizliği, kablo sürükleme (ara nokta ekle/taşı/çift tık sil, L köşesi dahil), Kabloyu sıfırla / gizle-göster, asansör yüksekliği ve geçit kayma tutamağı. Yeni: `scripts/editor/baglanti_islemleri.gd`. **Sıradaki parça:** A8 (kutu, zıplatıcı, bant, tek yönlü, lazer, şalter, zamanlı/mandal plaka arayüzü). Kullanıcı onayı bekle.
- **Testler:** `--editor` 281 (A7: 60 kontrol). Son tam koşu: exit 0, KALDI yok, determinizm 0,0000 px, 1771 GEÇTİ satırı; `--dene-fizik` 21 (B13/14/19 izi aynı).
- **Gözden geçirici (A7): koşullu kabul, işlendi:** L köşesi tutulamıyordu (ara_ac), bozuk L'de `insert` taşması (sıra kıstırıldı), tek tık ara nokta ekliyordu (artık 3 px sürükleme eşiği), `uclari_sil` artık boş kayıt bırakmaz; eksik testler eklendi.
- **Kalan risk:** kablo, blok/başlangıç/çıkış üstünde nesne seçiminden öncelikli (6 px içinde; tasarım kararı); asansör ve 3. kablo oyunda A11'e kadar çizilmez (durum satırında Bilgi); `acik_taraf_sag`/`tetik_aktifken_kapali` arayüzü A8; D26 editör akışında ayrıca sınanmadı (A4'te denetçi düzeyinde var); A7 testleri tek editör örneğinde zincirleme koşar.
- Tuval arka planı `Zemin` düğümüne (z −100) alındı: geçit/asansör görünümü önizlemede artık görünür.

## 2026-10-20 — Editör hazırlık parçaları
- **Biten parçalar (hepsi `uretim` dalında, push yok):** Parça 0 (taslak rev. 4, `126a872`), Parça 1/A1 (`0db96b9`), Parça 2/A2 (`384c622`), Parça 3/A3 `CozumDogrulayici` (`c032933`), Parça 4/A4 `BolumDenetci` (D1–D26; bu commit).
- **Parça 5 / A5 (editör iskeleti) ve Parça 6 / A6 (Dene akışı) bitti:** Dene (F5/`DeneDugmesi`, statik HATA engeller, çözümsüz bölüm oynanır), `EditorOturumu`, "Deneme · Ad" HUD, Dene sonuç ekranında "Çözümü kaydet ve editöre dön"/"Editöre dön", Ev butonu editöre döner, her çıkışta `Kayitlar.sifirla()`; A5 düzeltmeleri: şeffaf alt çubuk, Yeni/Aç/Menü için onay diyaloğu. **Sıradaki parça:** A7 (bağlantı/kablo arayüzü). Kullanıcı onayı bekle.
- **Son tam koşu (A6 sonrası):** exit 0, KALDI yok, determinizm 0,0000 px, 1651 GEÇTİ satırı; `--editor` 222 test, `--dene-fizik` 21 test.
- **A6 önemli bulgu (çözüldü):** `bolum_kurucu.gd` `preload(lazer.tscn)` yüzünden editör yüklenince B13/B14 bitiş karesi 1 kare kayıyordu (231→230, 556→557). Sahne sabitleri yol metni + `load` yapıldı; `tests/dene_fizik_testleri.gd` (temiz süreçte) koruyor. Kural: `lazer.tscn`'yi kalıcı önbelleğe sokan preload yok. Aynı ±1 kare kayma `change_scene_to_file` ile lazerli bölümden geçişte de var (A6 dışı; sorunlar.md geniş-faz A/C kararıyla aynı aile).
- **Gözden geçirici (A3+A4): koşullu kabul, koşullar işlendi:** D5 geçit istisnası, iptal bayrağı (`toplu_basla/bitir`), öncelik sapması taslak §6.2 ve `kararlar.md`'de.
- **Kalan risk / açık notlar:** D7 ve statik D4 veriden tetiklenemiyor (kurucu hep doğru kuruyor), yalnız olumlu test; `_sapma` iki dosyada kopya; iptalden sonra sahne açık kalır (A9'da çağıran editöre dönmeli); D6=640, D15 gevşetmesi, D24 merkez mesafesi, D5 geçit istisnası varsayılan kararlar (itiraz edilebilir); A4 yalnız 5 resmî fikstürle (B1/5/10/14/21) sınandı, 16 bölüm için fikstür yok (A12 öncesi genişletilebilir).
- **A5 gözden geçirici: koşullu kabul, 1–4 düzeltildi** (`ac()` şema HATA'sını reddeder; Tab `_input`'ta yakalanır, ad alanı FOCUS_CLICK; durum çubuğu fareyi geçirir, H iki çubuğu gizler; `kaydet()` önce adı işler).
- **A5 kalan risk (A7 öncesi):** (5) Aç ile gelen blok dışı nesneler silinirse D3 hatası kalabilir, kaydet şemayı denetlemeden yazar (bağlantı temizliği A7); (6) Yeni/Aç/Menü kaydedilmemiş işi onaysız atar; alt çubuk tuvalin alt 32 px'ini örter (H gizler); taslak §3.2 farkları ertelendi: 40 px zemin mıknatısı, Shift+tık çoklu seçim, paletin fareden kaçması; ok tuşu echo her kare geçmiş kaydı atar; sürükleme sırasında Ctrl+Z; "editöre gir, menüye dön, B13/B14/B19 oyna" fizik kayması testi yok (düşük risk, önizleme DISABLED).
- **A6 gözden geçirici: koşullu kabul, işlendi** (çözüm geri al/yinele ile korunur, Enter'sız ad kirlilik sayılır, ek testler). **A6 kalan risk:** `user://editor/` altında son `dene_NNN.tscn` kalır (bir dosya, sonraki Dene siler); EditorHud uyarısı çözüm kaydedildikten sonra da görünür (A9'a kadar); çözüm, kaydedildiği anlık görüntüden önceki görüntüye geri alınınca yoktur (tasarım gereği).
- Numaraya bağlı bulunan testler: taslak §8.4 (T1–T22), A12'de düzeltilecek; A1–A4'te mevcut teste dokunulmadı.

---

## 2026-10-19 özeti (güncel)
- **Oyunda 21 bölüm var.** Bölüm 19 "Karşı Ağırlık" kaldırıldı (arşiv: `scenes/bolumler/arsiv/bolum_19_arsiv.tscn`), eski 20/21/22 -> 19/20/21 (sahne dosyaları da yeniden adlandırıldı; tablo `docs/devir/numara_esleme.md`). Harita zinciri 18 -> 19 -> 20 -> 21.
- **Bölüm 18:** `max_klon = 2`, "?" ikonu yok (2 klonla çözüm doğrulandı). İkon yalnızca Bölüm 4 ve 6'da.
- **HUD:** her bölümde "Bölüm N · Ad" (`BolumEtiketi`, `BolumListesi.baslik`), Bilgi satırının üstünde.
- Son tam koşu: 583 GEÇTİ / 0 KALDI; denetim KABUL (`docs/devir/sabah_raporu.md`). GitHub'a push YAPILMADI.
- **Hâlâ açık:** canlı/klon dikiş sapması kararı (A/C, aşağıda), B14 `PlakaR` / B10 `PlakaPG` plaka seçenekleri (`docs/sorunlar.md`).
- Aşağıdaki eski bölümlerdeki bölüm numaraları (15–22, "22 bölüm") yazıldıkları günkü numaralardır; `numara_esleme.md` ile oku.

---
(Aşağısı 2026-10-16 tarihli önceki durumdur; numaralar eskidir.)


## 2026-10-16 (ikinci gece) özeti
Görünürlük/okunabilirlik kuralları kalıcı; T tuşu; görünürlük düzeltmeleri (kutu/zıplatıcı/zamanlı-mandal plaka çizimi, bant); B9 ayarı. 554 GEÇTİ / 0 KALDI. **Bekleyen (o gün):** B16/B17 v2 taslak onayı [GÜNCEL DEĞİL: 2026-10-16'da onaylandı ve uygulandı; dosyanın en üstündeki A11 girişine bak], B9 seçeneği (a/b/c), B14 PlakaR konumu. Ayrıntı: `docs/devir/sabah_raporu.md`.

## Nerede kaldık
- Gece planı tamamlandı: Bölüm 15–20, zamanlı/mandal plaka, arayüz iyileştirmeleri, son denetim. Son tam koşu: 526 GEÇTİ / 0 KALDI. Ayrıntı: `docs/devir/sabah_raporu.md`, kararlar `docs/devir/gece_notlari.md`.
- GitHub'a push YAPILMADI (`origin/main` = `87614a2`); push için geçmişsiz ekleme yöntemi kullanılacak.
- Sıradaki: elle kontrol (sabah_raporu.md listesi), açık kararlar (canlı/klon dikiş sapması: şimdilik A), isteğe bağlı sertleştirmeler (B20 şalter/C_A payları).

## Aşama özeti
- **Gece (2026-10-16):** Bölüm 15 Fitil, 16 Mandal, 17 Çifte Mühür, 18 Vardiya, 19 Karşı Ağırlık, 20 Büyük Saat; zamanlı + mandal plaka; ana menü/Kontroller/harita/sonuç/HUD/geçiş arayüzü.
- **Aşama 1–4, A, B:** tamam.
- **Aşama C (Bölüm 9–14):** tamam. Her biri: tasarımcı taslağı → uygulayıcı → bağımsız test → gözden geçirici → commit.
  - 9, 10 (kutu, bant), 11 (zıplatıcı + havada plaka, zorlaştırıldı), 12 "Kargo" (kutu fırlatma, min 2 klon), 13 "Kuyu" (bant darbesi + S düşme, min 3 klon), 14 "Çekirdek" (final, min 3 klon).
- **Yeni mekanik (kullanıcı onaylı):** S/Aşağı ile tek yönlü platformdan düşme (12 kare, kayıt `{yon, zipla, asagi}`); Bölüm 4 ve 6'da "?" ipucu ikonu (`ipucu_klon`).
- **Aşama 3 görsel:** taşıma bandı animasyonu, Bölüm 11 plaka askısı, oyun adı "Loop Lab". **Aşama D:** kutu ve zıplatıcı görünümü.
- **Hazırlık:** gerçek Godot yolu `CLAUDE.local.md`'de (git'e girmez); GitHub `main` geçmişsiz, kişisel iz yok.

## KULLANICI KARARI BEKLİYOR
**Canlı/klon ayrışması (eş düzlemli zemin seçimi).** Canlı kayıt turu ile klon tekrarı, eş düzlemli bant/zemin (ve asansör-zemin) dikişlerinde motorun platform seçimi yüzünden en çok 11,67 px ayrışıyor (B14 UL1|Bant x≈490; B13 BantA|ZeminSag x=260; B10 ZeminSol|Bant1 x=270). Kök neden `player.gd` değil, fizik geniş-faz sırası (dünyada boşta klon sayısına bağlı). Etki: B14'te S penceresinin ~8 px'i "canlıda çalışır, klonda çukura inmez" tuzağı; çözümler yine de geçiyor. Seçenekler: **A)** kabul (şu anki durum; üst sınır testle izleniyor, fark büyürse KALDI), **C)** bant etkisini motor platform hızından ayırıp deterministik uygulamak (player/kutu/bant fiziği değişir, bant pencereleri yeniden ölçülür). Ayrıntı: `docs/sorunlar.md`, `docs/kararlar.md`.

## Bekleyen sorun listesi (düşük)
- **Bölüm 6 geçit altı park/röle:** oyuncu geçit altında parkederek tek klonu geçirebiliyor, Bölüm 6 1 klonla bitiyor (`ipucu_klon=1` bu yüzden doğru). Bölüm 7, 9, 10, 12, 13, 14'te çalışmıyor (ölçüldü). Karar: kabul / geçit kuralı değişsin / bölüm yeniden ayarlansın (şu an kabul).
- **Bölüm 8 Basamak2 x≈714:** S sonrası ~27 kare yavaş iniş (+1 px/kare), kozmetik.
- **Bölüm 9:** asansör kutuda takılıp basamak olunca F2'ye çıkış payı ~0,5 px; bölüm yine bitmiyor.
- **Bölüm 5:** asansör-plaka-zıplama hilesi Godot `platform_on_leave` varsayılanına bağlı; `_test_bolum5_erken_ayrilma` yakalar.
- **Bölüm 14:** `max_klon = 3` = asgari 3, hata payı yok; son tur 556/600 kare. Kutu sola itilirse kilit (Baştan başla).
- **Test hijyeni:** `--rapor` her koşuda `docs/testler.md`'ye ek bölüm yazar; gözden geçirici ajanlar kullanmamalı. Test sabit koordinatlara bağlı (sahne değişirse güncelle).
- **Çıktı yolları:** tam koşu ~2,5 dk.

## Elle kontrol (görsel, headless'ta çizim atlanıyor)
1. Ana menü başlığı ve pencere başlığı "Loop Lab".
2. Bölüm 10, 13, 14: taşıma bandı (makaralar, kayan oklar, yön ve hız).
3. Bölüm 11: PlakaPB tavan halatları ve duvar kolu, plaka kalın blok; zıplatıcı yörüngesini kapatmıyor mu.
4. Kutu (ahşap/metal) ve zıplatıcı (yay, sıkışma animasyonu, oklar) Bölüm 9–14'te.
5. Bölüm 4 ve 6: "?" ikonu, hover'da "2 klonla çözülebilir" / "1 klonla çözülebilir"; diğer bölümlerde yok.
6. S tuşu: Bölüm 4, 8, 9, 11, 12, 13'te tek yönlü platformdan düşüş; duvara yaslıyken de çalışmalı (Bölüm 12 kovuk).
7. Bölüm 12–14 oynanış hissi (zamanlama pencereleri dar; test geçse de insan için zor olabilir).

## Sıradaki adım
1. Kullanıcı: yukarıdaki kararı (A/C) ver, elle kontrolleri yap.
2. İstenirse GitHub'a yeni geçmişsiz/ekli commit (parent `87614a2`) gönder.
