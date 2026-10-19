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

## Taşıma bandı ve plaka askısı (2026-10-15)

- Taşıma bandı (`Gorunum.Tur.BANT`, 2026-10-16 yenilendi): koyu kehribar kemer (`BANT_ZEMIN`), üst kenarda parlak amber şerit (`BANT_OK`), uçlarda açık metal makara (4 kollu, amber göbek), kemer üstünde 20 px aralıklı kalın amber ok (chevron) ve aralarında koyu oluk (`BANT_OLUK`). Oklar ve oluklar sürekli akar, makaralar döner; ok ucu, akış ve dönüş yönü bandın `yon` (±1) ve `hiz` değerinden okunur (ters bant = ters akış; B10 Bant2, B17, B20). Faz yalnızca `_process` (görsel zaman) ile ilerler, fizik karesine/oyun mantığına karışmaz. Genişlik gerçek çarpışma şeklinden ölçeklenir. `bolum.gd:_gorunumu_kur` kendi `Gorunum` çocuğu olan gövdeyi atlar (eski hata: bandın üstüne ikinci DUVAR çizimi kemeri örtüyordu).
- Yüksek plaka (şekil yüksekliği > 20 px, örn. Bölüm 11 PlakaPB 60x32): şeklin tamamını kaplayan kalın blok, üstte basınç yüzeyi (basılıyken alçalır, camgöbeği), lamba.
- Plaka askısı (`Gorunum.Tur.ASKI`): plaka düğümünde `aski_tavan_y` / `aski_duvar_x` meta değeri varsa tavana iki halat, duvara kol çizilir; z -1 (plakanın arkasında), çarpışmasız.

## Kutu ve yaylı zıplatıcı (2026-10-15)

- Kutu (`Gorunum.Tur.KUTU`): metal takviyeli ahşap kasa; paslı gövde, köşe metal plakaları + perçin, koyu iç panel, amber çapraz bağ, üst kenar ışığı. Boyut gerçek çarpışma şeklinden okunur (40x40 varsayılan). Sabit tasarım, durum okumaz; eski `Gorsel` ColorRect gizlenir.
- Yaylı zıplatıcı (`Gorunum.Tur.ZIPLATICI`): taban plakası, zigzag bobin yay, yeşil üst ped. Üzerindeki gövdenin `velocity.y` fırlatma hızına yakınsa (yalnızca okunur) ped ~16 fizik karesi boyunca sıkışıp geri uzar ve hafif parlar. Pedin üstünde soluk camgöbeği yukarı oklar etkin alanı gösterir.
- Yeni nesneler mevcut palet ve `_cerceve`/`_percin` yardımcılarını kullanır; Bölüm 9–13'te ek tür gerekmedi.

## Sonuç ekranı, klon göstergesi ve geçiş (2026-10-15)

- Sonuç ekranı: süre `mm:ss.s` (tüm turların fizik karesi / 60), tur sayısı, kullanılan klon; `ipucu_klon` > 0 ve klon <= ipucu ise amber "Az klonla çözüldü" rozeti. Yalnızca o oturumda gösterilir, kalıcı kayıt yok.
- Bölüm içi HUD: metin etiketi (Bilgi) korunur; altında klon yuvaları (`KlonGostergesi/Yuva1..N`, klon renginde; dolu = kullanılan) ve amber "R" tuş rozeti (`TusRozeti`, yalnız hak varken).
- Geçiş: bölüm/tur yüklenince koyu perde (`GecisKatmani/Perde`) 0,25 sn'de solar; mouse_filter IGNORE, fiziğe karışmaz, headless'ta atlanır.

## Zamanlı ve mandal plaka (2026-10-15)
- Taban çizim normal plakayla aynıdır (`_plaka`); üstüne ek çizilir, çarpışma değişmez.
- Zamanlı (`Tur.PLAKA_ZAMANLI`): plakanın üstünde 40 px şerit; camgöbeği dolgu kalan süreyle azalır, son %34'te uyarı rengine döner; altında 5 tik çizgisi.
- Mandal (`Tur.PLAKA_MANDAL`): asma kilit; basılana dek kanca kalkık, gövde pasli, lamba koyu. Basılınca kanca oturur, gövde metal, lamba yeşil + hale (kalıcı).
- İkisi de durumu üst düğümden okur (`kalan_kare`, `tutma_kare`, `kilitli`), headless'ta çizilmez.

## 2026-10-15 — Ana menü, kontroller ekranı, harita 20 bölüm (güncel: 21, bkz. aşağıdaki not)

- Ana menü: büyük camgöbeği başlık + ince ayraç, yavaş dönen kadran halkası ve yükselen kabarcıklar (`menu_animasyon.gd`, yalnızca `_process`; ekransız modda kapalı), "Oyna / Kontroller / Çıkış" butonları.
- Kontroller ekranı (`scenes/kontroller.tscn`): tuş adları InputMap'ten okunur; amber tuş metni, "Geri" butonu `focus_mode = NONE`.
- Harita: 20 bölüm için 5x4 yılan yerleşim (`docs/devir/harita_yerlesim.md`); düğüm üstünde "Bölüm N: Ad" etiketi (`ad` alanı isteğe bağlı).

## Düzeltme: eksik çizimler ve kontrast (2026-10-16)
- `Gorunum._draw` match'ine dört kol eklendi: `KUTU`, `ZIPLATICI`, `PLAKA_ZAMANLI` (`_plaka` + `_plaka_sayac`), `PLAKA_MANDAL` (`_plaka` + `_plaka_mandal`). Önceden bu nesneler çarpışıyor/tetikliyor ama çizilmiyordu (görünürlük raporu).
- Kutu: paslı kasa, koyu `KENAR` dış hat, açık metal köşe plakaları ve üst kenar vurgusu; `PANEL` zeminden hem renk (sıcak pas ↔ soğuk panel) hem hatla ayrışır.
- Yaylı zıplatıcı: taban plakası + metal bobin yay + parlak yeşil ped (`YESIL`, ince açık kenar) ve pedin üstünde akan camgöbeği oklar; zeminde yeşil çizgi + oklar bir bakışta okunur.
- Zamanlı plaka: normal plaka + üstünde 40 px `KENAR` çerçeveli şerit; camgöbeği dolgu kalan süreyle azalır, son %34'te `UYARI` (kırmızı), altında 5 tik.
- Mandal plaka: normal plaka + üstünde asma kilit. Açıkken (basılmamış) kanca kalkık, gövde paslı, lamba KIRMIZI (`UYARI`; eskiden `UYARI_KOYU` zeminde seçilmiyordu). Kilitliyken kanca oturur, gövde metal, lamba yeşil + hale.
- Palete eklendi: `BANT_ZEMIN #3a2610`, `BANT_OK #ffc94d`, `BANT_OLUK #120b04`.

## 2026-10-16 — Bölüm 21/22 kablo çizimi
- Plaka-geçit/lazer eşleşmesi için ince kablo (`metadata/kablo`, B22'de `kablo_2`): yalnız görünüm, tetikleyici etkinken camgöbeği, değilken soluk metal. Harita 22 bölüm için 6x4 yılan ızgara.

## 2026-10-19 — Bölüm 19 kaldırıldı; harita 21 bölüm
- Oyunda 21 bölüm var (6x4 yılan ızgaranın son satırında 3 düğüm: 19 @ (1040, 510), 20 @ (860, 510), 21 @ (680, 510); zincir 18 -> 19 -> 20 -> 21). Yerleşim: `docs/devir/harita_yerlesim.md`, numara eşlemesi: `docs/devir/numara_esleme.md`.
- Yukarıdaki 2026-10-15 ve 2026-10-16 girişlerindeki bölüm numaraları/sayıları (20, 22; "Bölüm 21/22 kablo") o günkü numaralarla yazılmıştır; yeni karşılığı için eşleme tablosuna bak.

## 2026-10-19 — HUD: bölüm numarası ve adı
- Her bölümde HUD'un sol üstünde "Bölüm 14 · Çekirdek" (adı yoksa "Bölüm 14"): 20 px, `LabPaleti.ONLUK`, koyu kenar çizgisi; "Tur | Klon | R" satırının (Bilgi) hemen üstünde. Bilgi satırı 28 px aşağı kayar; klon yuvaları ve "?" ikonu Bilgi'ye göre dizildiği için birlikte kayar.
- Numara listedeki sıradan (`indeks + 1`), ad kayıttan gelir (`BolumListesi.baslik`); yeni bölümde kod değişmeden doğru çıkar. Yalnızca görsel (`BolumKatmani`, fareyi yutmaz). Bölüm 1 ve 2'nin adları tahmin ("Giriş", "İkiz"), olduğu gibi bırakıldı.
