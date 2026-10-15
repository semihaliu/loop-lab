# Görsel Stil: "Terk edilmiş zaman laboratuvarı"

Tek tutarlı tema. Her şey koddan çizilir (`_draw`, `Line2D`, `StyleBoxFlat`); harici görsel kullanılmadı.
Yalnızca görünüm değişir: çarpışma, konum, boyut, fizik, girdi ve mantık aynıdır.
Renkler tek yerde: `scripts/lab_paleti.gd` (`LabPaleti`).

## Palet

| Ad | Hex | Kullanım |
|---|---|---|
| ARKA_UST / ARKA_ALT | `#0b1014` / `#16222a` | duvar degradesi |
| DUVAR | `#1c282e` | arka yüzeyler, panel gölgesi |
| PANEL / PANEL_ACIK | `#26353c` / `#33464f` | zemin, kat, tavan yüzeyleri, düğme dolgusu |
| KENAR | `#070b0e` | tüm nesne dış hatları |
| PASLI / PAS | `#4b4038` / `#8a5230` | pasli metal, lekeler, plaka yuvası, kapı kanadı |
| METAL / METAL_ACIK | `#6b7a82` / `#a3b4ba` | asansör, yayıcı, tek yönlü platform, perçin |
| CAMGOBEGI / CAM_SOLUK | `#5fe0cf` / `#2f7f78` | panel ışığı, basılı plaka, klon parıltısı |
| YESIL | `#7dff9b` | "açık / etkin" (kapı açık, geçit açık, şalter sağda, tek yönlü üst çizgisi) |
| AMBER | `#e3a53c` | uyarı şeridi, boşta plaka, oyuncu şeridi, başlangıç düğümü |
| UYARI / UYARI_KOYU | `#ff4a38` / `#7a1d16` | lazer, "kapalı / tehlike" lambaları |
| MOR / MOR_KOYU | `#8a6fc9` / `#3e3360` | geçit |
| ONLUK, DERI, SAC, PANTOLON | `#eef1ea`, `#e2b392`, `#4a3326`, `#3d566b` | oyuncu |
| KLON / KLON_ACIK | `#6cc8ff` / `#c8f0ff` | klon (hologram) |
| OLU | `#5a6670` | ölü klon |

Kural: sıcak renk (amber/kırmızı) = beklemede/kapalı/tehlike, soğuk-yeşil renk (camgöbeği/yeşil) = etkin/açık.

## Katman (çizim) sırası

1. `ArkaPlanKatmani` (CanvasLayer, layer -10): laboratuvar duvarı (`LabArkaplani`).
2. Asansör ve geçit `Gorunum` düğümü `z_index = -1`: zemin/kat/tavan (z 0) üstlerine çizilir, yani asansör ve geçit gömülü kaldığında örtülür (Bölüm 4 E2/F2, Bölüm 7 geçit/Kat2, Bölüm 8 G/tavan-K3). Çarpışma konumu aynıdır.
3. Zemin, duvar, plaka, şalter, lazer, kapı (z 0, ağaç sırasıyla).
4. Oyuncu ve klonlar (ağaçta son, üstte).
5. Ekran butonları (CanvasLayer 10), sonuç ekranı.

## Mekanizma

- `scripts/gorunum.gd` (`Gorunum`): nesnenin çocuğu olarak eklenen tek çizici; `Tur` enum'u ile DUVAR, TEK_YONLU, PLAKA, ASANSOR, KAPI, GECIT, SALTER, LAZER çizer. Durumu üst düğümden okur, hiçbir şeyi değiştirmez.
- Plaka, asansör, kapı, geçit, şalter ve lazer `Gorunum`'u kendi `_ready`'sinde ekler; bölüm `.tscn` dosyaları değişmedi.
- `bolum.gd` `_gorunumu_kur()`: arka planı ekler, `StaticBody2D` + `Gorsel` (ColorRect) olan zemin/duvar/tavan/kat ve tek yönlü platformları ortak çizime çevirir (eski `Gorsel` düğümü adı ve boyutuyla durur, yalnızca gizlenir).
- `scripts/oyuncu_gorunum.gd` (`OyuncuGorunum`): insan çizimi (oyuncu ve klon).
- Animasyon fizik karesinden türer (`Engine.get_physics_frames()` veya karakterin `kare` sayacı); rastgelelik yok.

## Nesneler

| Nesne | Görünüm | Durumlar |
|---|---|---|
| Zemin / duvar / tavan / kat | koyu panel, üstte soluk camgöbeği ışık şeridi, panel dikişleri, perçinler, pas lekeleri, çatlaklar | tek durum |
| Tek yönlü platform | gri metal ızgara, üstte yeşil çizgi (+ soluk parıltı) | tek durum |
| Basınç plakası | pasli yuva üstünde amber plaka, uyarı şeritleri, kırmızı-koyu lamba | boşta: plaka yüksekte, amber, lamba koyu kırmızı. Basılı: plaka çökmüş, camgöbeği, lamba parlak yeşil + hale |
| Asansör | gri metal platform, altta amber-siyah uyarı şeridi, iki yanda ray (alt-üst konum arası) | tek görünüm (konumu zaten gösterir) |
| Kapı (hedef) | metal çerçeve, iki pasli kanat, amber kadran işareti, nabız atan amber lamba | kapalı: kanatlar kapalı, amber. Açık: yeşil-beyaz ışık, yeşil lamba + hale |
| Geçit | mor lamelli metal levha, ucunda durum lambası | kapalı: parlak mor, kırmızı lamba, kenarlarda kırmızı uyarı çizgisi. Açık (yarıdan fazla kaymış): koyu mor, yeşil lamba |
| Şalter | pasli taban kutusu, eğik kol, uçta top, iki yanda küçük işaret | sol: kol sola yatık, kırmızı top. Sağ: kol sağa yatık, yeşil top |
| Lazer | koyu yayıcı gövde, karşıda alıcı soket; ışın = kırmızı hale + parlak çekirdek (hafif nabız) | açık: ışın dolu. Kapalı: ışın yok, yalnızca soluk noktalı kılavuz, yayıcı lambası koyu |

## Oyuncu ve klon

- Ölçü: çarpışma 28x48 aynen; çizim bu kutuya sığar (kafa tepesi y=-24, ayak y=+24).
- İnsan: kafa (saç, göz), laboratuvar önlüğü (yaka, cep), kollar, bacaklar, ayaklar. Sol/sağ bakış `velocity.x` işaretinden, ölçek çevirmeyle.
- Pozlar: bekleme (düz), koşma (4 adımlı döngü, 5 fizik karesinde bir kare değişir), yükseliş (kollar yukarı, bacaklar toplanık), düşüş (kollar yana açık, bacaklar açık). Poz `velocity`, `is_on_floor()` ve `kare`'den türer.
- Oyuncu: beyaz önlük, amber şerit, koyu mavi pantolon, ten ve kahverengi saç, opak.
- Klon: tamamen mavi-camsı hologram (`#6cc8ff`/`#c8f0ff`), yarı saydam (alfa 0,68), yatay tarama çizgileri ve baş çevresinde parıltı; ten/saç rengi yok. Oyuncudan renk ve saydamlıkla bir bakışta ayrılır.
- Ölü klon: gri-koyu (`#5a6670`), alfa 0,45, gözler X, hareketsiz (pozu bekleme).

## Arka plan

Degrade zemin, 96 px karo dikişleri (bazı karolar aydınlık/koyu), tavan lambası hüzmeleri, yatay/dikey borular (bağlantı halkalı), büyük soluk dişliler, saati durmuş kadran, çatlak monitörler. Hepsi düşük alfa; oyun alanının kontrastını bozmaz. Haritada aynı arka plan 0,7 yoğunlukta.

## Menü, sonuç ve harita

- `LabTema` (`scripts/lab_tema.gd`): düğme (koyu panel, camgöbeği kenar; hover'da parlak, basılıyken amber), etiket rengi. Ana menü, sonuç ekranı ve sağ üst ekran butonları kullanır.
- Ana menü: laboratuvar arka planı, camgöbeği başlık.
- Sonuç ekranı: karartma + koyu panel, yeşil "Bölüm bitti!" başlığı.
- Harita: arka plan ortak tema; bağlantılar boru gibi (koyu dış + soluk metal iç `Line2D`); düğümler altıgen, saat kadranı çizgileri; başlangıç düğümü amber, diğerleri soluk camgöbeği; hover'da parlama ve "Bölüm N". Çizim sırası Arkaplan < Baglantilar < Dugumler korunur.
