# Aşama 1 — Mekanik: Lazer + Tek yönlü platform (kullanıcı onaylı)

Kullanıcı, CLAUDE.md'deki "başka mekanik ekleme" kuralının istisnası olarak bunları açıkça onayladı.
Tema: "terk edilmiş zaman laboratuvarı". Mevcut 27+ test, fizik değerleri ve Bölüm 1-2 davranışı AYNEN korunur.

## 1. Lazer (`scenes/lazer.tscn`, `scripts/lazer.gd`)
- Kök: `Area2D`. Sabit yayıcı (görsel: küçük ColorRect gövde) + ışın alanı (`CollisionShape2D`, RectangleShape2D).
- `collision_layer = 0`, `collision_mask = (1<<1)|(1<<2)` (oyuncu + klon). Rastgelelik yok, `_physics_process`.
- @export:
  - `yon: Vector2 = Vector2.RIGHT` (ışının yayıcıdan gittiği yön, normalize edilir; yatay/dikey kullanılır)
  - `uzunluk: float = 200.0` (piksel), kalınlık sabit 6 px
  - `tetikleyici_yollari: Array[NodePath] = []` (plaka/şalter; Geçit gibi VEYA mantığı)
  - `acik_taraf_sag: bool = true` (şalter için "aktif" taraf, Gecit ile aynı)
  - `tetik_aktifken_kapali: bool = true` (true: tetikleyici aktifken lazer KAPANIR; false: tetikleyici aktifken AÇILIR)
- Tetikleyicisiz lazer hep açıktır.
- Açık ve bir oyuncu/klon ışın alanıyla çakışıyorsa o karakterin `oldur()` metodu çağrılır.
- Işın duvarlarda kesilmez (raycast yok), sade tutuldu.
- `aktif_mi()` / `acik_mi()` metodu genel olsun (test erişimi). Kapalıyken ışın alanı `monitoring` kapalı + görsel gizli.
- Ağaç sırası kuralı: plaka/şalter/asansör/geçit/lazer karakterlerden ÖNCE.

## 2. Ölüm (player.gd)
- `oldur()` metodu: iki ayrı davranış.
  - **Klon:** `oldu = true`, `oldu_kare = kare` kaydedilir; hız sıfırlanır, `collision_layer = 0` ve `collision_mask = 0` yapılır (plakayı basılı tutmaz, asansörü durdurmaz, kapıya/geçide etkisiz), fizik işlemesi durur (yerinde kalır). Görünüm: ölü klon biraz soluk/koyu. Ölüm karesi deterministik olmalı.
  - **Canlı oyuncu:** `oyuncu_oldu` sinyali yayar (bir kez). `bolum.gd` bunu dinler ve turu YENİDEN başlatır: `Kayitlar.turlar` DEĞİŞMEZ, tur sayısı artmaz, o turda kaydedilen girdi atılır (`tur_kaydet` ÇAĞRILMAZ), sahne `reload_current_scene` ile (deferred) yüklenir.
- Ölü klon `_physics_process`te hareket etmez ve kare sayacı kayıt dışı bir sorun yaratmaz.

## 3. Tek yönlü platform (`scenes/tek_yonlu.tscn`)
- Neden: dikey bulmacaya yeni bir fikir (aşağıdan atlayıp çıkılır, üstünde durulur), karmaşık fizik yok, yalnızca Godot'un yerleşik `one_way_collision` özelliği.
- `StaticBody2D`, `collision_layer = 1`, bir `CollisionShape2D` (`one_way_collision = true`, `one_way_collision_margin` makul), boyut 120x12; görsel ColorRect.
- Betik gerekmez. Oyuncu/klon aşağıdan geçip üstüne çıkabilir.

## 4. Kapsam dışı
- Başka nesne ekleme. Fizik değerlerini, 28x48 çarpışma kutusunu, mevcut sahneleri değiştirme.
- Görsel iyileştirme Aşama 3'te (grafik ajanı). Burada yalnızca işlevsel düz renkli ColorRect görsel.

## 5. Doğrulama
- `--headless --path . --quit` hatasız; mevcut tüm testler GEÇTİ.
- Test yazarı sonra bağımsız test yazacak: lazer oyuncuyu öldürür, tetikleyici lazeri kapatır, klon ölünce etkisiz kalır (plakayı bırakır), yeniden başlatma kayıtları korur, determinizm 100x.
- Test sahnesi için `tests/sahneler/` altında sahneyi test yazarı kuracak; uygulayıcı yalnızca `scenes/` ve `scripts/` altında çalışır.

## 6. Kayıt
- `docs/kararlar.md`ye tarihli not: lazer ve tek yönlü platform, her biri için neden + artı/eksi, ölüm davranışı.
- CLAUDE.md "Yapı" ve "Kapsam" bölümleri ana oturumca Aşama 4'te güncellenecek (uygulayıcı dokunmaz).
