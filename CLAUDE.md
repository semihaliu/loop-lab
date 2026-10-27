# Loop Lab (Godot 4 / GDScript)

Bitirme projesi: 2D bulmaca platform oyunu.

## OYUN
Tek karakter, hedef kapıya ulaşmak. Her turda oyuncunun tuş basışları kaydedilir, tur bitince zaman başa sarar ve kaydedilen tur "klon" olarak tekrar oynar. Oyuncu klonlarla birlikte bir sonraki adımı yapar.

Örnek: tur 1'de butona basılır, asansör çıkar; tur 2'de klon butona basar, oyuncu asansörle çıkar. Klonlar gerçek karakter gibi davranır (hayalet değil): asansör yukarıdaysa klon binemez, aşağıda bekler.

## KURALLAR
- Klonlara tuş girdisi kaydı uygulanır, dünya her turda baştan ve deterministik simüle edilir.
- Sabit fizik karesi (`_physics_process`) kullan, rastgelelik kullanma.
- Butonlar basınç plakasıdır (üstünde biri var mı diye bakılır).
- Kapsam: oyuncu, basınç plakası, asansör, kapı, şalter, geçit, lazer, tek yönlü platform. Başka mekanik ekleme (şalter, geçit, lazer ve tek yönlü platform kullanıcının açık kararıyla eklendi).
  - İstisna (kullanıcı kararıyla, Aşama B): kutu (itilir, plakayı tutar), yaylı zıplatıcı, taşıma bandı. Kutu katman 4'tedir (`1 << 3`; dünya katmanı 1 ile birlikte): karakterler katman 1'le çarpışır, asansör/geçit/plaka katman 4'ü ayrı sorgular. Başka yeni mekanik eklenmez.
  - Lazer: sabit yayıcı + `Area2D` ışın; tetikleyiciler (plaka/şalter, VEYA) kapatır ya da açar, tetikleyicisiz hep açıktır. Canlı oyuncu ölürse tur yeniden başlar (`Kayitlar.turlar` değişmez, tur sayısı artmaz, o turun girdisi atılır); klon ölürse yerinde donar ve etkisiz kalır (plakayı basılı tutmaz, asansörü durdurmaz, kapıya/geçide etkisiz). Ağaç sırası: plaka/şalter/asansör/geçit/lazer karakterlerden ÖNCE.
  - Zamanlı ve mandal plaka (2026-10-15, kullanıcı kararı, en çok 2 yeni basit nesne): `BasincPlakasi`'nin `tutma_kare` (>0: basış bitince o kadar fizik karesi daha basılı) ve `mandal` (bir kez basılınca tur sonuna kadar basılı) alanları; sahneler `scenes/zamanli_plaka.tscn` (180 kare), `scenes/mandal_plaka.tscn`. Varsayılan 0/false eski davranıştır. Sayaç yalnızca fizik karesi; başka yeni mekanik eklenmez.
  - Tek yönlü platform: `scenes/tek_yonlu.tscn`, Godot'un `one_way_collision` özelliği, betiksiz.
  - Aşağı düşme (2026-10-15, kullanıcı kararı): tek yönlü platformun üstünde `asagi` (S / Aşağı ok) basılıysa platform o karakter için 12 kare (`ASAGI_DUSME_KARE`) yok sayılır. Kayıt formatı `{yon, zipla, asagi}`; eski kayıtlarda alan yoksa `asagi` basılmamış sayılır (geriye uyumlu).
  - Tema (değişmez): "terk edilmiş zaman laboratuvarı". Görünüm yalnızca görsel katmandadır (`scripts/gorunum.gd`, `oyuncu_gorunum.gd`, `lab_*.gd`); oyun durumunu okur, yazmaz. Headless'ta çizim atlanır (`LabPaleti.ekransiz()`).
  - Not: sınır duvarları, ekran butonları (ana menü / baştan başla = tam sıfırlama: tüm klonlar silinir, tur 1'e döner; "turu kaydetmeden yeniden başlat" yolu yoktur) ve bölüm başına klon sınırı (`max_klon`) kullanıcının açık kararıyla eklendi (bkz. `docs/kararlar.md`); yeni mekanik sayılmaz.
  - Asansör inerken altında karakter varsa durur; tur süresi bilinçli olarak sınırsızdır.
  - Şalter itilerek çalışır (etkileşim tuşu yok, kayıt formatı `{yon, zipla, asagi}` değişmez); karakterin uygulanan `yon` girdisine bakar. Geçit: plaka/şalter VEYA mantığı, kapanırken altında karakter varsa durur. Ağaç sırası: plaka/şalter/asansör/geçit karakterlerden ÖNCE.
  - Bilinen kısıt: klon asansörün altında kalırsa asansör inemez.
- **Görünürlük kuralı (2026-10-16, kalıcı):** Çarpışması, tetikleyicisi veya etkisi olan her nesnenin ekranda net bir görünümü olur. Çizimsiz çarpışma, görünmez plaka/blok, gizli işlev YASAK.
- **Okunabilirlik kuralı (2026-10-16, kalıcı):** Her bölüm, oyuncu yalnızca ekrana bakarak "şunu şuradan şöyle yapmalıyım" diyebilecek şekilde çözülebilir olmalı. Çözüm görünmeyen şeye veya tahmin edilemeyen zamanlamaya dayanmaz. Karmaşık/zor olabilir, haksız olamaz.
- **Gözden geçirici kapısı:** `gozden-gecirici` her bölümde çizimsiz çarpışma/tetikleyici var mı kontrol eder; varsa bölüm kabul edilmez.
- **Yeni bölüm taslağı kullanıcı onayı olmadan uygulanmaz.**
- Küçük adımlarla ilerle, her adımdan sonra çalıştırıp test ettir.
- Önemli tasarım kararlarını kullanıcıya sormadan verme, seçenekleri artı eksileriyle kısaca anlat.
- Kod yorumları ve açıklamalar Türkçe olsun.
- Tasarım kararlarını `docs/kararlar.md` dosyasına tarihli not et (rapor için).

## Godot ve Doğrulama
- Godot (console sürümü), yolda boşluk var, tırnak içinde kullan:
  `<GODOT_YOLU>` (gerçek yol `CLAUDE.local.md` dosyasında; o dosya commit edilmez)
- Kod yazdıktan sonra headless çalıştır: `--headless --path . --quit`. Hata varsa kendin düzelt.
- **Testler (her kod değişikliğinden sonra çalıştır):**
  `<Godot yolu> --headless --path . --fixed-fps 60 --script res://tests/test_runner.gd`
  Determinizm (100x), Bölüm 1–21 çözümleri, başarısızlık/atlanamazlık/kısayol, lazer, S düşme, ipucu ikonu, plaka ve arayüz testlerini koşar (~583 test, ~7-10 dk; tek bölüm için `-- --b9` ... `--b21`, `--sdusme`, `--ipucu`, `--plaka`, `--arayuz`, `--tustu`, `--gorunurluk`, `--editor` (editör testleri), `--ed-a11` (yalnız A11: kablo görünümü ve `kirli_mi`, hızlı), `--dene-fizik` (editör açıldıktan sonra B13/B14/B19 izi aynı mı; temiz süreç ister); bayraklar birleşmez, her biri ayrı koşulur), GEÇTİ/KALDI yazar; kaldıysa çıkış kodu 1.
  Sonucu `docs/testler.md`'ye tarihli eklemek için sonuna `-- --rapor` ekle. Testler oyun kodunu değiştirmez, girdiyi `Input.action_press` ile enjekte eder; girdi/fizik/bölüm yerleşimi değişirse `tests/test_runner.gd` içindeki betikleri güncelle.

## Yapı
- `project.godot` — proje ayarları ve girdi eşlemeleri (`sol`, `sag`, `zipla`, `asagi`)
- `scenes/` — sahneler (`scenes/bolumler/` bölümler, `scenes/ekran_butonlari.tscn` sağ üst butonlar), `scripts/` — GDScript dosyaları
- `scripts/bolum.gd` — tur yönetimi, sınır duvarları, klon sınırı (`@export max_klon`), isteğe bağlı HUD ipucu ikonu (`@export ipucu_klon`, 0 = yok; `IpucuIkonu`/`IpucuMetni`, hover'da "N klonla çözülebilir"; yalnızca Bölüm 4 = 2 ve Bölüm 6 = 1; Bölüm 18 ikonu 2026-10-19'da kaldırıldı), ekran butonlarını ekler; HUD bölüm etiketi `BolumEtiketi` ("Bölüm N · Ad", numara/ad `BolumListesi.baslik`ten, Bilgi satırının üstünde, listede olmayan test sahnesinde yok)
- `scenes/bolumler/bolum_1.tscn` .. `bolum_21.tscn` — 21 bölüm (15 "Fitil": zamanlı plaka; 16 "Mandal": mandal plaka; 17 "Çifte Mühür": ikisi + ters bant; 18 "Vardiya": zamanlı plakalı asansör, `max_klon = 2`, ikon yok; 19 "Büyük Saat": final, tutucu devri + şalter; 20 "Mandal": mandal plaka, 2 klon; 21 "Fitil ve Mühür": zamanlı + mandal plaka, 2 klon (eski "Karşı Ağırlık" kaldırıldı, `scenes/bolumler/arsiv/`; eski/yeni numara tablosu `docs/devir/numara_esleme.md`); adlar `BolumListesi.ad`; ayrıca 9: kutu tanıtımı; 10: bant + kutu; 11: yaylı zıplatıcı + havada plaka; 12: kutu fırlatma + ortak plaka + geçit yarışı; 13: bant darbesi + kuyu + S düşme, min 3 klon; 14: final, 3 klon). Bölüm 1–8: (Bölüm 2: 3 katlı, `max_klon = 2`; 3: lazer tanıtımı; 4: tek yönlü platformlu kule, 3 klon; 5: şalter + lazer; 6: geçit + lazer; 7: üç klonlu karışık; 8: final spiral kule, `max_klon = 2`). Taslaklar ve çözümler `docs/devir/bolum_N_taslak.md` ve `docs/kararlar.md`'de. Menüde "Oyna" ilerleme haritasını (`scenes/harita.tscn`, `scripts/harita.gd`) açar (kilit yok); sonuç ekranında "Sonraki bölüm" vardır.
- `scripts/harita.gd`, `scripts/harita_dugumu.gd`, `scripts/harita_arkaplan.gd` — ilerleme haritası (çizgiler `Line2D`, düğümler altıgen; çizim sırası: Arkaplan < Baglantilar < Dugumler)
- `scripts/bolumler_listesi.gd` — bölüm kayıtları tek yerde (`BolumListesi.BOLUMLER`: `yol`, `ad`, `konum`, `onceki`; `baslik()` HUD başlığını üretir); yeni bölüm = listeye bir kayıt, harita kodu değişmez. `scripts/ana_menu.gd` — ana menü (+ `scripts/menu_animasyon.gd` görsel arka plan, `scenes/kontroller.tscn`/`scripts/kontroller.gd` tuşları InputMap'ten gösteren Kontroller ekranı), `scripts/sonuc_ekrani.gd` — sonuç ekranı
- `scripts/salter.gd`, `scenes/salter.tscn` — şalter; `scripts/gecit.gd`, `scenes/gecit.tscn` — geçit; `scripts/lazer.gd`, `scenes/lazer.tscn` — lazer; `scenes/tek_yonlu.tscn` — tek yönlü platform
- `scripts/kutu.gd`, `scenes/kutu.tscn` — itilen kutu; `scripts/yayli_ziplatici.gd`, `scenes/yayli_ziplatici.tscn` — yaylı zıplatıcı; `scenes/tasima_bandi.tscn` — taşıma bandı
- `tests/sahneler/kutu_test.tscn`, `kutu_plaka_test.tscn`, `ziplatici_bant_test.tscn` — kutu/zıplatıcı/bant test sahneleri (oyun bölümü değil)
- `scripts/gorunum.gd` (nesne çizimi), `scripts/oyuncu_gorunum.gd` (insan, klon, ölü klon), `scripts/lab_paleti.gd`, `scripts/lab_arkaplani.gd`, `scripts/lab_tema.gd` — görsel katman; `docs/stil.md` — stil rehberi
- `tests/sahneler/gecit_test.tscn`, `tests/sahneler/lazer_test.tscn` — şalter/geçit ve lazer test sahneleri (oyun bölümü değil)
- `assets/ikonlar/` — ekran butonu SVG ikonları (ev.svg, yeniden.svg = "Baştan başla")
- `tests/test_runner.gd` — otomatik testler, `docs/testler.md` — test sonuç günlüğü
- `docs/kararlar.md` — tasarım karar günlüğü

## Ajanlar
Ajanların kullanılması kullanıcının açık kararıdır (bkz. `docs/kararlar.md`). Tanımlar `.claude/agents/` altındadır.

- `tasarimci` (opus, salt okunur) — yeni bölüm taslağı üretir.
- `uygulayici` (sonnet, yazma) — onaylı taslağı sahneye/koda döker, teste dokunmaz.
- `test-yazari` (sonnet, yazma, bağımsız) — testleri taslağa göre yazar ve koşar, kodu düzeltmez.
- `gozden-gecirici` (opus, salt okunur) — işi denetler, düzeltmez.
- `grafik` (sonnet, yazma, sınırlı) — yalnızca görünüm değiştirir, `docs/stil.md` yazar.

Devir klasörü: `docs/devir/` (akış ve dosya adları için `docs/devir/README.md`; güncel durum `docs/devir/durum.md`).
Bölüm 8: `max_klon = 2` (kullanıcı kararı, `docs/kararlar.md`).
Bölüm 16/17 (v2) taslakları onaylandı ve uygulandı (2026-10-16): Bölüm 20 "Mandal" ve Bölüm 21 "Fitil ve Mühür" (`docs/devir/bolum_20_taslak.md` / `bolum_21_taslak.md`; v2 dosya adları ve ilk numaraları 21/22 idi, Bölüm 19 kaldırılınca 20/21 oldu). Sahnedeki 16 "Mandal" ve 17 "Çifte Mühür" eski (v1) sürümdür ve bilinçli olarak oyunda kalır. Onay bekleyen taslak yok.
Not: ajanlar yalnızca yeni bölüm üretirken kullanılır, küçük düzeltmeler tek oturumda yapılır.
