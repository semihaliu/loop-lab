# Aşama B — Yeni nesneler: KUTU, YAYLI ZIPLATICI, TAŞIMA BANDI (kullanıcı onaylı)

Kullanıcı CLAUDE.md'deki "başka mekanik ekleme" kuralının istisnası olarak yalnızca bu üç nesneyi açıkça onayladı. Bunların dışında nesne EKLEME. Tema "terk edilmiş zaman laboratuvarı". Mevcut davranış, fizik değerleri (HIZ 300, zıplama -520, yerçekimi 1400, 28x48), mevcut testler ve Bölüm 1–8 AYNEN korunur. Katmanlar: 1 = dünya, 2 = oyuncu, 3 = klon, 4 = kutu (yeni, sorgu katmanı).

## 1. KUTU (`scenes/kutu.tscn`, `scripts/kutu.gd`)
- `CharacterBody2D`, kendi basit kinematik kodu (RigidBody KULLANMA), `_physics_process`, rastgelelik yok. Boyut 40x40 (`CollisionShape2D` RectangleShape2D; sahnede ayarlanabilir).
- `collision_layer = 1 | (1 << 3)` (dünya + kutu katmanı: oyuncu/klon mask=1 ile onunla çarpışır; asansör/geçit/plaka katman 4'ü ayrıca sorgular), `collision_mask = 1` (dünya, asansör, geçit, platformlar, diğer kutular; karakterlerle çarpışmaz, onların itmesi `it()` ile gelir). Katman 4'e `1 << 3` sabitiyle bak.
- Yerçekimi 1400 ile düşer (`move_and_slide`, `velocity.y`), zeminde durur, `velocity.x = 0` (sürtünme yok, itilmedikçe kımıldamaz). Üstüne oyuncu/klon çıkabilir. Asansör üstündeyken `move_and_slide` platformla taşır (mevcut AnimatableBody2D platform hızı).
- `func it(dx: float)`: o kare için yatay yer değiştirme isteği; `move_and_collide(Vector2(dx, 0))` ile dünyaya karşı uygulanır (duvara/başka kutuya çarparsa durur). Zincirleme itme YOK.
- Sahne her turda yeniden yüklendiği için kutu başlangıç konumunda başlar; hiçbir durum kalıcı değildir.
- Lazere değerse yok olmaz (lazer maskesi katman 4'ü içermez). Kutu öldürülmez.
- Ağaç sırası: plaka/şalter/asansör/geçit/lazer KUTUDAN ve karakterlerden önce; kutu karakterlerden ÖNCE (Oyuncu'dan önce).
- Etkileşimler:
  - Oyuncu ve klon aynı kod yolu: `player.gd`'de `move_and_slide()` sonrası, uygulanan `yon` != 0 iken yatay çarpışma (normal.x'in büyüklüğü > 0.9 ve işareti yönle ters) yapan collider `it` metoduna sahipse `collider.it(yon * HIZ * delta)` çağrılır. Bu tek ekleme `player.gd` dışında oyun davranışını değiştirmez (kutusuz bölümlerde etkisiz).
  - Plakayı basılı tutar: `basinc_plakasi.gd` maskesine `1 << 3` eklenir (plaka kutuyu da algılar).
  - Asansör inerken altında kutu varsa durur (`asansor.gd` KARAKTER_KATMANLARI'na `1 << 3`); geçit kapanırken altındaysa durur (`gecit.gd` aynı). Ezmez.
  - Asansör yükselirken üstünde duran kutu taşınır.

## 2. YAYLI ZIPLATICI (`scenes/yayli_ziplatici.tscn`, `scripts/yayli_ziplatici.gd`)
- `Area2D`, sensör bölgesi 60x12 (zemine/platforma yerleştirilir, üst yüzeyine oturur). `collision_layer = 0`, `collision_mask = (1<<1)|(1<<2)|(1<<3)`.
- @export `firlatma_hizi := 820.0` (px/sn). Her fizik karesinde çakışan gövdelerden `velocity.y >= 0` olanlara `velocity.y = -firlatma_hizi` verir (oyuncu, klon, kutu; hepsi `velocity` alanına sahip). `velocity.y < 0` ise dokunmaz (çoklu tetikleme yok). Yükseklik ≈ 240 px.
- Ağaçta karakterlerden ve kutudan ÖNCE.

## 3. TAŞIMA BANDI (`scenes/tasima_bandi.tscn`, `scripts/tasima_bandi.gd`)
- `StaticBody2D`, `collision_layer = 1`, yüzeyi katı (zemin gibi). @export `yon := 1` (1 sağ, -1 sol), `hiz := 100.0`; `_ready`'de `constant_linear_velocity = Vector2(yon * hiz, 0)` (Godot'un yerleşik sabit platform hızı; üstündeki oyuncu/klon/kutu `move_and_slide` ile bu hızı taşır). Başka kod yok, rastgelelik yok.
- Boyut 160x16 (sahnede ayarlanabilir).

## Kapsam dışı
- Başka nesne ekleme. Görünüm iyileştirmesi Aşama D'de (burada yalnızca düz renkli ColorRect görsel; `Gorsel` adlı çocuk).
- `tests/` altına DOKUNMA (uygulayıcı için). Test sahneleri `tests/sahneler/` altında test yazarına aittir.

## Doğrulama
- `--headless --path . --quit` hatasız; mevcut tüm testler GEÇTİ.
- Test yazarı bağımsız yazacak: itme, düşme, plakada kalma, klon itme determinizmi (100x), asansörle taşıma, ezmeme (asansör altında kutu / geçit altında kutu), zıplatıcı (karakter ve kutu), bant (karakter ve kutu, her iki yön).

## Kayıt
`docs/kararlar.md`ye tarihli not: her nesne için neden + artı/eksi.
