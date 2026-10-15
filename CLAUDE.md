# Zaman Oyunu (Godot 4 / GDScript)

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
  - Tek yönlü platform: `scenes/tek_yonlu.tscn`, Godot'un `one_way_collision` özelliği, betiksiz.
  - Tema (değişmez): "terk edilmiş zaman laboratuvarı". Görünüm yalnızca görsel katmandadır (`scripts/gorunum.gd`, `oyuncu_gorunum.gd`, `lab_*.gd`); oyun durumunu okur, yazmaz. Headless'ta çizim atlanır (`LabPaleti.ekransiz()`).
  - Not: sınır duvarları, ekran butonları (ana menü / baştan başla = tam sıfırlama: tüm klonlar silinir, tur 1'e döner; "turu kaydetmeden yeniden başlat" yolu yoktur) ve bölüm başına klon sınırı (`max_klon`) kullanıcının açık kararıyla eklendi (bkz. `docs/kararlar.md`); yeni mekanik sayılmaz.
  - Asansör inerken altında karakter varsa durur; tur süresi bilinçli olarak sınırsızdır.
  - Şalter itilerek çalışır (etkileşim tuşu yok, kayıt formatı `{yon, zipla}` değişmez); karakterin uygulanan `yon` girdisine bakar. Geçit: plaka/şalter VEYA mantığı, kapanırken altında karakter varsa durur. Ağaç sırası: plaka/şalter/asansör/geçit karakterlerden ÖNCE.
  - Bilinen kısıt: klon asansörün altında kalırsa asansör inemez.
- Küçük adımlarla ilerle, her adımdan sonra çalıştırıp test ettir.
- Önemli tasarım kararlarını kullanıcıya sormadan verme, seçenekleri artı eksileriyle kısaca anlat.
- Kod yorumları ve açıklamalar Türkçe olsun.
- Tasarım kararlarını `docs/kararlar.md` dosyasına tarihli not et (rapor için).

## Godot ve Doğrulama
- Godot (console sürümü), yolda boşluk var, tırnak içinde kullan:
  `<GODOT_YOLU>`
- Kod yazdıktan sonra headless çalıştır: `--headless --path . --quit`. Hata varsa kendin düzelt.
- **Testler (her kod değişikliğinden sonra çalıştır):**
  `<Godot yolu> --headless --path . --fixed-fps 60 --script res://tests/test_runner.gd`
  Determinizm (100x), Bölüm 1–8 çözümleri, başarısızlık/atlanamazlık ve lazer testlerini koşar (~160 test, ~45 sn), GEÇTİ/KALDI yazar; kaldıysa çıkış kodu 1.
  Sonucu `docs/testler.md`'ye tarihli eklemek için sonuna `-- --rapor` ekle. Testler oyun kodunu değiştirmez, girdiyi `Input.action_press` ile enjekte eder; girdi/fizik/bölüm yerleşimi değişirse `tests/test_runner.gd` içindeki betikleri güncelle.

## Yapı
- `project.godot` — proje ayarları ve girdi eşlemeleri (`sol`, `sag`, `zipla`)
- `scenes/` — sahneler (`scenes/bolumler/` bölümler, `scenes/ekran_butonlari.tscn` sağ üst butonlar), `scripts/` — GDScript dosyaları
- `scripts/bolum.gd` — tur yönetimi, sınır duvarları, klon sınırı (`@export max_klon`), ekran butonlarını ekler
- `scenes/bolumler/bolum_1.tscn` .. `bolum_8.tscn` — bölümler (Bölüm 2: 3 katlı, `max_klon = 2`; 3: lazer tanıtımı; 4: tek yönlü platformlu kule, 3 klon; 5: şalter + lazer; 6: geçit + lazer; 7: üç klonlu karışık; 8: final spiral kule, `max_klon = 2`). Taslaklar ve çözümler `docs/devir/bolum_N_taslak.md` ve `docs/kararlar.md`'de. Menüde "Oyna" ilerleme haritasını (`scenes/harita.tscn`, `scripts/harita.gd`) açar (kilit yok); sonuç ekranında "Sonraki bölüm" vardır.
- `scripts/harita.gd`, `scripts/harita_dugumu.gd`, `scripts/harita_arkaplan.gd` — ilerleme haritası (çizgiler `Line2D`, düğümler altıgen; çizim sırası: Arkaplan < Baglantilar < Dugumler)
- `scripts/bolumler_listesi.gd` — bölüm kayıtları tek yerde (`BolumListesi.BOLUMLER`: `yol`, `konum`, `onceki`); yeni bölüm = listeye bir kayıt, harita kodu değişmez. `scripts/ana_menu.gd` — ana menü, `scripts/sonuc_ekrani.gd` — sonuç ekranı
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

- `tasarimci` (sonnet, salt okunur) — yeni bölüm taslağı üretir.
- `uygulayici` (sonnet, yazma) — onaylı taslağı sahneye/koda döker, teste dokunmaz.
- `test-yazari` (sonnet, yazma, bağımsız) — testleri taslağa göre yazar ve koşar, kodu düzeltmez.
- `gozden-gecirici` (sonnet, salt okunur) — işi denetler, düzeltmez.
- `grafik` (sonnet, yazma, sınırlı) — yalnızca görünüm değiştirir, `docs/stil.md` yazar.

Devir klasörü: `docs/devir/` (akış ve dosya adları için `docs/devir/README.md`; güncel durum `docs/devir/durum.md`).
Bölüm 8: `max_klon = 2` (kullanıcı kararı, `docs/kararlar.md`).
Not: ajanlar yalnızca yeni bölüm üretirken kullanılır, küçük düzeltmeler tek oturumda yapılır.
