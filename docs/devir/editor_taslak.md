# Oyun içi bölüm editörü: tasarım taslağı (rev. 4)

Durum: **TASLAK, onay bekliyor.** Kullanıcı S1–S5'i kesinleştirdi. Y1 ve Y2 için önerilen seçenekler varsayılan karar olarak yazıldı (§11). Açık soru yok. Onaydan önce kod, sahne ya da test yazılmayacak.
Tarih: 2026-10-19 · Dal: `uretim` · Hazırlayan: tasarimci (salt okunur inceleme)

Revizyonlar:
- rev. 2: gözden geçirici düzeltmeleri.
- rev. 3: kullanıcı kararları (S1 "Canlıya al", S2 1:1 tuval, S3 ızgara, S4 çözümsüz bölüm de oynanabilir, S5 sürüklenebilir kablo), yeni A12 aşaması, numaraya bağlı testlerin listesi (§8.4), A1–A4 için ayrıntılı uygulama sözleşmesi.
- rev. 4:
  - Kabloya isteğe bağlı `uclar` alanı eklendi (B21 eşitliği için).
  - `liste()` artık yan etkisiz bir okuyucu; kip tespiti çekirdek `BolumYollari` sınıfına taşındı.
  - A1/A2 sözleşmesi tamamlandı: imzalar, sorun biçimi, kimlik kuralı, `EditorHud`, kablo meta eşlemesi, rol paylaşımı.
  - T21–T22 eklendi; canlı sahne yolu sayaçlı oldu; B20 onay notuna girdi.
  - Test sayıları gerçekçi hale getirildi.
  - Y1 ve Y2 varsayılan karar olarak yazıldı.

**Değişmez kararlar (kullanıcı):**
- Editör oyunun içinde çalışır; ana menüde "Editör" butonu olur.
- Yeni bölümler JSON olarak saklanır. Mevcut 21 `.tscn` dosyasına dokunulmaz ve **yeniden adlandırılmaz**.
- Aynı çizim (`gorunum.gd`), aynı fizik ve aynı nesne betikleri ya da sahneleri kullanılır. JSON, mevcut sahne ve betiklerin örneklenmesiyle kurulur; nesne mantığı kopyalanmaz.
- Kalıcı kurallar geçerli: görünürlük, okunabilirlik, determinizm, fizik değerleri değişmez, `max_klon <= 3`, ilerleme kaydı ya da kilit sistemi yok.

**Terim notu:** Kodda `Kapi` bölümün **hedefi (çıkış)** demektir; hiçbir tetikleyiciye bağlanmaz. Tetikleyiciyle açılıp kapanan kayar kapı `Gecit`tir. Görevdeki "plaka -> kapı" ifadesi "plaka -> geçit" olarak okunur. Arayüzde "Çıkış" ve "Geçit" ayrı yazılır.

**Varsayılan kararlar (rev. 2'den, geçerli):**
- Hız değerleri sabit: asansör ve geçit 120, bant 100 (yönü ±1), zıplatıcı 820.
- `ipucu_klon` v1'de sabit 0 (`kararlar.md:383`).
- Blok, plaka, asansör ve kapı satır içi, kodla kurulur.
- Dene, özel ve canlı kipleri sahne yolundan anlaşılır. Bunu tek yerde çekirdek `scripts/bolum_yollari.gd` (`BolumYollari`) yapar (§5.2).
- Çekirdek dosyalar (`bolumler_listesi.gd`, `bolum.gd`, `sonuc_ekrani.gd`, `ekran_butonlari.gd`, `harita.gd`) `scripts/editor/` altındaki hiçbir betiğe bağımlı olmaz. Yalnızca `BolumYollari`'nı kullanır.
- **Y1 (varsayılan, itiraz edilebilir):** canlıya alınan bölümün kopyası dondurulur. Bölümlerim'de yapılan düzenleme oyuna yalnızca "Canlıyı güncelle" ile yansır.
- **Y2 (varsayılan, itiraz edilebilir):** haritadaki birleşik listenin üst sınırı 40 bölümdür.
- A1–A11 boyunca mevcut testlere dokunulmaz. `test_runner.gd`'ye yalnızca ekleme yapılır. Numaraya bağlı testler A12'de ele alınır.

---

## 0. Koddan çıkan kısıtlar

| # | Gerçek (kodda ya da belgede ölçüldü) | Editöre etkisi |
|---|---|---|
| K1 | `bolum.gd` kökte `$Oyuncu`, `$Bilgi` ve `$Kapi` düğümlerini arar. | Kurulan kökte bu üç ad tam olarak bulunur: 1 başlangıç, 1 çıkış. |
| K2 | R, ölüm, T, "Baştan başla" ve "Tekrar oyna" hep `reload_current_scene()` çağırır; bu da sahneyi `scene_file_path`'ten yeniden yükler. | JSON'dan kurulan sahne bir dosyaya kaydedilmek zorunda (§5.1). |
| K3 | HUD etiketi ve "Sonraki bölüm" `BolumListesi.baslik/sonraki(scene_file_path)` kullanır. | Canlı bölümler birleşik listede olduğu için kendiliğinden doğru çalışır. Dene ve özel kipler `baslik()` için küçük bir ek ister (§8.3). |
| K4 | `Kayitlar` otomatik yüklenen bir düğümdür (yalnızca `turlar` tutar). `sifirla()` harita, sonuç ekranı ve ev butonunda çağrılır. | Dene'ye girişte ve editöre dönüşte `sifirla()` zorunlu. |
| K5 | Ağaç sırası: plaka, şalter, asansör, geçit ve lazer karakterlerden önce gelir. Fikstür olarak seçilen B1, B5, B10, B14 ve B21'de gözlenen sıra: statik (blok, tek yönlü, bant; dosya sırasıyla karışık) → plakalar (üç tür, karışık) → şalter → zıplatıcı → asansör → geçit → lazer → Kapi → kutu → Oyuncu → Bilgi. B2'de şalter asansörden sonra gelir; kural yine sağlanır ama kategori sırası farklıdır, bu yüzden B2 fikstür değildir. | Kurucu bu kategori sırasını sabit uygular; kategori içinde JSON sırası korunur. |
| K6 | `_gorunumu_kur` yalnızca `StaticBody2D` + `Gorsel` olan düğümleri çizer. `asansor.gd` ve `kapi.gd` `$Gorsel` düğümüne doğrudan erişir. | Kurucu `Gorsel`'i şekil boyutunda kurar. |
| K7 | Plaka, asansör, kapı ve blok satır içi düğümlerdir. Sahne örneklerinin şekil alt kaynakları paylaşılır. | Satır içi türler kodla kurulur ve her biri kendi şeklini alır. Sahne örneklerinin boyutu sabit kalır. |
| K8 | `Asansor.plaka` yalnızca tek bir `BasincPlakasi` alır. `Gecit` ve `Lazer` `tetikleyici_yollari` alır (plaka ya da şalter, VEYA mantığı). | Bağlantı kuralları (§4) buna göre. |
| K9 | Kablo meta'sı (`kablo`, `kablo_2`) yalnızca görünümdür. Yalnızca geçit ve lazerde çizilir, yalnızca `basili_mi()` doğruysa yanar; şalter kablosu hiç yanmaz, asansörde kablo yoktur. | A11'de görünüm eki (§4.3). |
| K10 | Test yardımcıları (`_senaryo`, `_girdi_uygula`) oyun içinden çağrılamaz. | Tek kaynak olarak oyun betikleri yazılır (§6, §7); testler bunları çağırır. |
| K11 | `BOLUMLER` bir `const`. `harita.gd:30-31` ve `bolumler_listesi.gd:144,166,172,181` bu sabite doğrudan bağlı. Testlerin birçoğu da `BolumListesi.BOLUMLER`'i doğrudan okur. | Birleşik liste için statik bir katman gerekir (§8.1). Numaraya bağlı testlerin listesi §8.4'te. |
| K12 | Ölçüler: karakter 28x48; 5 px/kare; zıplama tepesi ≈ 96,6 px kuramsal, ≈ 100,9 px ölçülen; zıplatıcı ≈ 240 px; ekran 1152x648; sınır duvarları sol, sağ ve üstte (alt yok). | Denetim eşikleri bunlardan türer. |
| K13 | "Koridor 100 px" Bölüm 2 için tasarım değeridir (`kararlar.md:90`). Mevcut koridorlar 100 ile 300 px arasında. | D14 yalnızca uyarıdır. |
| K14 | Canlı oyuncu ile klonun ayrışması: dikişlerde en çok 11,67 px (B10, B13, B14); bant üstünde ya da yanında duraksarken 30 kare içinde 20 px'e kadar (B20, `sorunlar.md:70`). Çözüm yolunda 0. | D19 uyarısı. |
| K15 | Bazı değerler nesnenin `_ready`'sinde bir kez hesaplanır: asansör `alt_y`, geçit `kapali_konum`, lazer ışın şekli, bant hızı, şalter `sagda`. | Önizlemede parametre değişince düğüm yeniden kurulur (§3.3). |
| K16 | `bitti` bayrağı ile `_bolumu_bitir` (`call_deferred`) arasında fazladan kare işlenebilir. Ölümde yeniden yükleme de `call_deferred` ile yapılır. | Çözüm ölçütü bitiş karesidir (§6.3). Ölüm döngüsü D23 ile yakalanır. |
| K17 | `kararlar.md:237`: kutu başlangıçtan en az 40 px uzak olmalı; asansör tepesi ile tavan arasında en az 40 px + pay olmalı. | D24, D25. |
| K18 | Harita: 6 sütun (x 140..1040, aralık 180) × 4 satır (y 165..510, aralık 115), yılan sırası. Kutu alanı x 40..1112, y 105..576. Düğümler arası en az 100 px. Hover etiketi 280x30 boyutunda, düğümün y+48..78 aralığında. | Harita konum algoritması bu kurala dayanır (§8.2). |

---

## 1. JSON bölüm biçimi

### 1.1 Üst alanlar

| Alan | Tür | Zorunlu | Açıklama |
|---|---|---|---|
| `bicim` | metin | evet | `"loop_lab_bolum"` |
| `surum` | tamsayı | evet | `1` |
| `kimlik` | metin | evet | İlk kayıtta üretilir, **bir daha değişmez**. Biçim: `^[a-z0-9_]{1,36}_[0-9]{3}$` (en çok 40 karakter). Slug 36 karaktere kesilir, sona `_NNN` eklenir (§9.1 A1). Dosya adı, canlı sıra kaydı ve canlı sahne adı bundan türer. |
| `ad` | metin | evet | 1–40 karakter |
| `max_klon` | tamsayı | evet | 1..3 |
| `ipucu_klon` | tamsayı | hayır | v1'de yalnızca 0 |
| `baslangic` | `[x, y]` | evet | Oyuncunun ayak noktası; düğüm konumu `(x, y − 24)` |
| `cikis` | `[x, y]` | evet | Kapi'nin ayak noktası; düğüm konumu `(x, y − 24)` |
| `nesneler` | dizi | evet | §1.3 |
| `cozum` | nesne | hayır | §6.1 |
| `dogrulama` | nesne | hayır | Doğrulama özeti: `{"durum": "taslak"\|"dogrulandi", "icerik_ozeti": "<sha256>", "bitis_kare": int, "hata": int, "uyari": int}`. İçerik özeti tutmazsa durum "taslak" sayılır. |
| `canli` | nesne | hayır | A12 için ayna kayıt: `{"alindi": bool, "sonra": "<res:// yolu ya da canli:<kimlik> ya da boş>", "sahne": "<kimlik>_v<NNN>.tscn", "canli_ozet": "<sha256>"}`. Doğruluk kaynağı `user://canli/sira.json`'dır (§8.1); ikisi çelişirse sıra dosyası kazanır ve ayna düzeltilir. |
| `notlar` | metin | hayır | Oyunda görünmez |

Harita **konumu JSON'da saklanmaz**; sıradan hesaplanır (§8.2). Sayılar tamsayı yazılır, okunurken `int()` uygulanır.

### 1.2 Ortak nesne alanları

`{"tur": "...", "id": "...", ...}`. `id` düğüm adıdır: `[A-Za-z][A-Za-z0-9_]{0,23}`, bölüm içinde benzersiz. `Oyuncu`, `Bilgi`, `Kapi` ve `SinirDuvarlari` ayrılmış adlardır.

### 1.3 Nesne tipleri

Boyutlar mevcut sahnelerle birebir aynıdır (S3 kararı); sabit boyutlar değiştirilemez.

| `tur` | Düzenlenebilir alanlar (varsayılan) | Sabit değerler | Çapa → düğüm `position` | Kurulum |
|---|---|---|---|---|
| `blok` | `alan: [x, y, gen, yuk]`, gen ve yuk ≥ 10 | – | (x + gen/2, y + yuk/2) | satır içi: `StaticBody2D` (katman 1, maske 0) + `CollisionShape2D` (yeni `RectangleShape2D`) + `Gorsel` |
| `tek_yonlu` | `konum` = üst orta | 120x12 | (x, y + 6) | `tek_yonlu.tscn` |
| `bant` | `konum` = üst orta, `yon` 1 ya da −1 (1) | 160x16, `hiz` 100 | (x, y + 8) | `tasima_bandi.tscn` |
| `plaka` | `konum` = ayak | 60x16 | (x, y − 8) | satır içi: `Area2D` + `basinc_plakasi.gd` + şekil + `Gorsel` (B1'deki yapı) |
| `zamanli_plaka` | `konum`, `tutma_kare` (180) | 60x16 | (x, y − 8) | `zamanli_plaka.tscn` |
| `mandal_plaka` | `konum` | 60x16 | (x, y − 8) | `mandal_plaka.tscn` |
| `salter` | `konum` = ayak, `baslangic_sagda` (false) | – | (x, y) | `salter.tscn` |
| `ziplatici` | `konum` = ayak | 60x12, 820 | (x, y − 6) | `yayli_ziplatici.tscn` |
| `asansor` | `konum` = alt konumdaki üst yüzey ortası, `yukseklik` (180), `plaka` (tek, zorunlu), `kablo` (§4) | 120x20, `hiz` 120 | (x, y + 10) | satır içi: `AnimatableBody2D` + `asansor.gd` + şekil + `Gorsel` |
| `gecit` | `konum` = kapalıyken alt kenar ortası, `kayma_mesafe` (100), `tetikleyiciler`, `acik_taraf_sag` (true), `kablolar` | 20x200, `hiz` 120, `kayma_yonu` (0, −1) | (x, y − 100) | `gecit.tscn` |
| `lazer` | `konum` = yayıcı, `yon` (asagi/yukari/sag/sol), `uzunluk` (200), `tetikleyiciler`, `tetik_aktifken_kapali` (true), `acik_taraf_sag` (true), `kablolar` | ışın 6 px | (x, y) | `lazer.tscn` |
| `kutu` | `konum` = ayak | 40x40 | (x, y − 20) | `kutu.tscn` |

- Hızların dayanağı: `hiz = 120.0` 22 satır (asansör ve geçit), `hiz = 100.0` 7 satır (bantların tamamı), `firlatma_hizi = 820.0` 12 satır (tamamı).
- `kayma_mesafe` için JSON varsayılanı 100'dür. `gecit.tscn` sahne varsayılanı 200, `gecit.gd` varsayılanı 100'dür. Kurucu değeri her zaman açıkça yazar.
- **Kablo alanı (S5):** bir bağlantının kablosu hedef nesnede durur.
  - Geçit ve lazer: `"kablolar": [{"tetik": "<id>", "ara": [[x, y], ...], "uclar": [[x0, y0], [x1, y1]], "gizli": false}]`, tetikleyici başına bir kayıt.
  - Asansör: tek kayıt, `"kablo": {"ara": [...], "uclar": [...], "gizli": false}`.
  - `uclar` isteğe bağlıdır:
    - Varsa kurucu iki ucu **olduğu gibi** yazar.
    - Yoksa uçlar her kurulumda nesne konumlarından hesaplanır (tetikleyici merkezi ve hedef noktası, §4.2).
    - Editör `uclar` alanını yalnızca dışarıdan gelen veride korur. Kullanıcı tetikleyiciyi ya da hedefi taşıyınca alan silinir ve hesaplanan uçlara geçilir.
    - Gerekçe: B21'deki kabloların uçları elle ayarlanmıştır. Örnekler: GecitG kablosu x=170'te, PlakaZ ise x=180'de; `kablo_2` (110, 372)'de başlar, PlakaM (80, 372)'dedir; LazerA kablosu (508, 584)'te başlar, PlakaA ise x=520'dedir. Birebir eşitlik ancak bu alanla sağlanır.
  - `ara` boş ve `uclar` yoksa otomatik L yolu kullanılır.
  - `gizli: true` ise o bağlantı için **hiçbir kablo meta'sı yazılmaz**.
  - Kablo kaydı olmayan bağlantı varsayılan olarak `gizli: false` sayılır ve otomatik L çizilir. Kablosuz resmî bölümlerden (B5, B10, B14) üretilen fikstürlerde her bağlantı `gizli: true` olur.
- v1'de olmayanlar: yüksek ya da askılı plaka, 20x100 geçit, yatay geçit, birden çok çıkış.

### 1.4 Örnek (Bölüm 1'in birebir karşılığı)

```json
{
  "bicim": "loop_lab_bolum", "surum": 1,
  "kimlik": "deneme_asansoru_001", "ad": "Deneme Asansörü",
  "max_klon": 2, "ipucu_klon": 0,
  "baslangic": [200, 594], "cikis": [1050, 420],
  "nesneler": [
    {"tur": "blok", "id": "Zemin", "alan": [0, 600, 1152, 40]},
    {"tur": "blok", "id": "Cikinti", "alan": [680, 420, 472, 40]},
    {"tur": "plaka", "id": "Plaka", "konum": [350, 600]},
    {"tur": "asansor", "id": "Asansor", "konum": [620, 600], "yukseklik": 180, "plaka": "Plaka",
     "kablo": {"ara": [], "gizli": true}}
  ]
}
```

Bu örnek `bolum_1.tscn` ile aynı düğüm konumlarını üretir: Zemin (576, 620), Cikinti (916, 440), Plaka (350, 592), Asansor (620, 610), Kapi (1050, 396), Oyuncu (200, 570). Fikstürde kablo gizlidir; B1'de kablo yoktur.

### 1.5 Dosya konumları (kök `kok` varsayılan olarak `"user://"`; testlerde `"user://test_editor/"`)

| Yol | İçerik |
|---|---|
| `<kok>bolumler/<kimlik>.json` | Bölümlerim (düzenlenen kopya) |
| `<kok>editor/dene_<NNN>.tscn` | Dene ve doğrulama için geçici sahne (sayaçlı; bir öncekini siler) |
| `<kok>oyna/oyna_<NNN>.tscn` | Bölümlerim'den "Oyna" ile açılan geçici sahne |
| `<kok>canli/<kimlik>.json` | Canlıya alınan bölümün **dondurulmuş** kopyası (§8.1) |
| `<kok>canli/<kimlik>_v<NNN>.tscn` | Canlı bölümün kurulmuş sahnesi; her "Canlıyı güncelle"de sürüm sayacı artar, eski dosya silinir (önbellek tuzağına karşı). Oyunda ve haritada bu yol kullanılır. |
| `<kok>canli/sira.json` | Canlı sıra kaydı (§8.1) |

Yalnızca JSON okunur, en çok 200 nesne. Bilinmeyen tür ya da alan reddedilir.

---

## 2. Nesne tipleri ve editör kapsamı

Sayım 21 sahnenin tamamından yapıldı: 141 sahne örneği (Oyuncu hariç 120), 120 satır içi `StaticBody2D`, 76 satır içi `Area2D` (55 plaka + 21 kapı), 15 satır içi `AnimatableBody2D` (14 asansör + B2 geçidi).

| Nesne | Mevcut sayı | Kurulum | Editörde | Sıra |
|---|---|---|---|---|
| Blok | 120 | satır içi | evet | 1 |
| Başlangıç | 21 | `oyuncu.tscn` | evet, tek | 1 |
| Çıkış | 21 (36x48) | satır içi | evet, tek | 1 |
| Plaka | 55 (54 tane 60x16, 1 tane 60x32) | satır içi | evet (60x16) | 2 |
| Geçit | 19 örnek + 1 satır içi | `gecit.tscn` | evet (20x200) | 3 |
| Asansör | 14 (120x20) | satır içi | evet | 4 |
| Kutu | 6 | `kutu.tscn` | evet | 5 |
| Zıplatıcı | 12 | `yayli_ziplatici.tscn` | evet | 6 |
| Bant | 7 | `tasima_bandi.tscn` | evet | 7 |
| Tek yönlü | 21 | `tek_yonlu.tscn` | evet | 8 |
| Lazer | 41 | `lazer.tscn` | evet | 9 |
| Şalter | 6 | `salter.tscn` | evet | 10 |
| Zamanlı plaka | 4 | `zamanli_plaka.tscn` | evet | 11 |
| Mandal plaka | 4 | `mandal_plaka.tscn` | evet | 12 |
| Bilgi | 21 | satır içi | otomatik | – |
| Askılı plaka, kablo meta | 1 / 8 | meta | askı yok; kablo bağlantıdan | – |

---

## 3. Editör ekranı (S2 kararı: 1:1 tuval, gizlenebilen panel)

### 3.1 Yerleşim

```
+--------------------------------------------------------------------------------------------+
| [Yeni][Bölümlerim][Kaydet] Ad:[__________] Klon:[2v] | [Geri al][Yinele] | Izgara:[20 ✓] | [Dene ▶][Doğrula ✓][Menü] |  <- 36 px, H gizler
+------+-------------------------------------------------------------------------------------+
| PALET|                                                                                     |
| Blok |              T U V A L   (1152x648, oyunla birebir aynı piksel)                     |
| Başl.|                                                                                     |
| Çıkış|      [Plaka]════╗ (kablo: ince metal hat, ara noktada halka)                        |
| Plaka|                 ╚═══════● [Geçit]   (açık konum hayaleti kesik çizgiyle)            |
| Geçit|                                                                                     |
| ...  |                                                                                     |
| Bağla|                                                                                     |
+------+-------------------------------------------------------------------------------------+
| Seçili: Asansor1 yükseklik[180] plaka: Plaka1 [×] | Durum: Taslak (çözüm yok ▲) | 0 hata, 2 uyarı |  <- 32 px
+--------------------------------------------------------------------------------------------+
```

- Palet ve çubuklar tuvalin üstüne yarı saydam olarak biner. `Tab` paleti, `H` üst çubuğu gizler. Fare yaklaşınca palet karşı tarafa kayar. Tuval ölçeklenmez.
- `ipucu_klon` için arayüz yok. Görsel ayrıntılar `grafik` ajanına bırakılır (`LabTema`).

### 3.2 Etkileşim

| Eylem | Yol |
|---|---|
| Yerleştir | Paletten tür seç, tıkla. Çapa ızgaraya oturur; zemine oturan türler 40 px içindeki ilk katı üst kenara mıknatıslanır. |
| Seç | Tıkla; çoklu seçim için `Shift` + tıkla. |
| Taşı | Sürükle. Ok tuşu bir ızgara adımı, `Shift` + ok 1 px kaydırır. |
| Boyut | Blokta köşe ve kenar tutamaçları. Asansör üst tutamacı yüksekliği, lazer uç tutamacı uzunluk ve yönü, geçit üst tutamacı kayma mesafesini ayarlar. |
| Kablo | Kablonun üstüne tıklayıp basılı tutarak sürükle: yeni ara nokta eklenir ya da var olan sürüklenir. Ara noktaya çift tıklayınca silinir (§4.2). |
| Sil | `Del` ya da sağ tık; o nesneye giden bağlantılar da silinir. |
| Geri al / yinele | `Ctrl+Z` / `Ctrl+Y`. Her değişiklikte bütün verinin kopyası saklanır (en çok 100). |
| Bölümlerim | Liste ekranı (§8.1): Aç, Oyna, Sil, Canlıya al / Canlıdan kaldır / Canlıyı güncelle. |
| Dene | `F5`. Statik HATA varsa açılmaz. Çözümün olmaması engel değildir (S4). |
| Doğrula | §6.4 |

**Izgara (S3 kararı):** 20 px; `Shift` basılıyken 10 px; ekran kenarları (0, 1152, 648) mıknatıs görevi görür. Izgara üst çubuktaki onay kutusuyla ya da `G` ile kapatılabilir; kapalıyken konumlar 1 px adımla serbesttir, mıknatıs da kapanır. Sabit nesne boyutları (§1.3) ızgaradan bağımsızdır.

Editör ayrı bir sahnedir: `scenes/editor.tscn`, `scripts/editor/editor.gd`.

### 3.3 Önizleme

- Tuvaldeki nesneler kurucunun ürettiği gerçek düğümlerdir. `Onizleme` düğümü altında `PROCESS_MODE_DISABLED` ile durur. Bloklara `bolum.gd:_gorunumu_kur`'daki aynı `Gorunum.ekle` çağrısı yapılır.
- Düzenleme yapılınca (konum, boyut, parametre, bağlantı, kablo) ilgili düğüm silinip yeniden kurulur (K15). Bağlantı değişirse hedef nesne de yeniden kurulur.
- `DISABLED` iken `Gorunum._process` çalışmaz. Vurgu ya da hayalet değiştiğinde ilgili `Gorunum` için elle `queue_redraw()` çağrılır. Önizlemede animasyon yoktur.
- Editöre özgü çizimler (hayaletler, tutamaçlar, ara nokta halkaları, seçim çerçevesi) ayrı bir `EditorKatmani`'nda çizilir ve oyun sahnesine girmez.

---

## 4. Bağlantı ve kablo

### 4.1 Bağlantı kurma

1. "Bağla" aracı seçilir (ya da seçili tetikleyicide `B` tuşuna basılır).
2. Tetikleyiciye tıklanır (plaka türleri ya da şalter).
3. Hedefe tıklanır (geçit, lazer ya da asansör). Bağlantı yoksa kurulur, varsa kaldırılır. `Esc` iptal eder.

Kurallar (K8):
- Bir asansöre tam 1 plaka bağlanır; şalter reddedilir. İkinci bir plaka bağlanırsa onay sorulup öncekinin yerine geçer.
- Geçide ve lazere 0..n plaka ya da şalter bağlanabilir. Tetikleyicisiz lazer hep açıktır. Tetikleyicisiz geçit hep kapalıdır (D20 uyarısı).
- Hedef nesnede gerekirse `acik_taraf_sag` ve `tetik_aktifken_kapali` alanları görünür.

### 4.2 Kablo yolu (S5 kararı)

- Her bağlantıya kablo otomatik çizilir. Varsayılan yol L biçimindedir (B21'deki kabloların deseni): `tetikleyici_merkezi → (tetikleyici.x, hedef_y) → hedef_noktasi`. Hedef noktası geçitte geçidin ortası, lazerde yayıcı, asansörde alt konumdaki üst yüzeyin ortasıdır.
- **Ara noktaları sürükleme:** kablo parçasının üstüne (6 px içinde) tıklayıp basılı tutmak o noktada yeni bir ara nokta yaratır ve sürükletir. Var olan bir ara noktaya (8 px içinde) basılı tutmak onu taşır. Çift tıklama ara noktayı siler. Ara noktalar ızgaraya oturur (ızgara kapalıysa serbest). İlk düzenlemeyle L yolu açık bir ara nokta listesine dönüşür. "Kabloyu sıfırla" otomatik yola döner. "Gizle" kabloyu çizmez, bağlantı yine çalışır.
- Kablo çarpışmaz ve oyun mantığına girmez. Kurucu çoklu çizgiyi `[uc0] + ara + [uc1]` olarak kurar. Uçlar `uclar` alanından alınır, yoksa hesaplanır (§1.3). Meta eşlemesi kesindir:
  - Geçit ve lazerde `tetikleyiciler[k]`: k = 0 ise `metadata/kablo`, k ≥ 1 ise `metadata/kablo_%d` % (k + 1). Yani 2. tetikleyici `kablo_2`, 3. tetikleyici `kablo_3` alır.
  - Asansörde `metadata/kablo`.
  - `gizli` olan bağlantı için meta yazılmaz.
  - Mevcut `gorunum.gd` yalnızca `kablo` ve `kablo_2` meta'larını çizer. `kablo_3` ve sonrası A11'e kadar görünmez; asansör kablosu da A11'e kadar görünmez. Bunu editör D26'nın yanında BİLGİ olarak gösterir.

### 4.3 Kablo görünümü ve lazerden ayırt edilmesi

| Özellik | Lazer ışını (mevcut) | Kablo (mevcut + A11 eki) |
|---|---|---|
| Renk | Kırmızı (`UYARI`) hale + açık çekirdek; kapalıyken kırmızı noktalı kılavuz | Hiç kırmızı ya da amber kullanılmaz. Söndüğünde `METAL`, yandığında `CAMGOBEGI` |
| Kalınlık | 14 px hale, 7 px orta, 2,5 px çekirdek | 3 px iç, 5 px koyu `KENAR` dış hat |
| Biçim | Yayıcıdan tek düz çizgi, nabız atar | Kırık çizgi; uçlarda ve **her ara noktada** küçük perçin halkası (3,5 px koyu, 2 px metal ya da yeşil) |
| Uçlar | Yayıcı gövde + alıcı soket | Tetikleyici ve hedefte halka |
| Hareket | Nabız | Yok (durağan) |

Ek denetim D26 (UYARI): bir kablo parçası bir lazer ışınıyla 8 px içinde paralel giderse görsel karışma riski olduğu bildirilir.

**A11 görünüm eki (`gorunum.gd`, grafik ajanı; fizik ve mantık değişmez):**
- `_kablo` genelleşir: her tetikleyici için `kablo_<i>` çizilir. Geriye uyum korunur: `kablo` = 0. tetikleyici, `kablo_2` = 1. tetikleyici; mevcut B21 çizimi aynı kalır.
- Şalter kablosu, hedefin `acik_taraf_sag` değeri `sagda` ile eşleşince yanar.
- Asansör kablosu çizilir: `_asansor` içinde `metadata/kablo` okunur, `plaka.basili_mi()` ile yanar. Kablo z −1'de, asansörle birlikte gömülü çizilir.
- Ara nokta perçin halkaları eklenir. Mevcut B21 kablolarının köşeleri bu halkaları alır; bu küçük bir görsel değişikliktir, A11'de elle kontrol listesine girer.

---

## 5. Dene modu

### 5.1 Sahnenin kurulması (`bolum.gd` değişmez)

1. `BolumKurucu.kur(veri)` kökü `Node2D` + `bolum.gd` olarak kurar; ağaca eklemeden, K5'teki kategori sırasıyla. `max_klon` atanır, `ipucu_klon = 0`; kök `metadata/editor_ad` alır.
2. Owner kuralı: kökün doğrudan çocukları ile satır içi düğümlerin çocukları köke bağlanır. Sahne örneklerinin iç çocuklarına owner atanmaz.
3. Dışa aktarılan alanlar ağaçtan önce atanır: `plaka` düğüm referansıyla, `tetikleyici_yollari` `NodePath("../<id>")` ile; kablo meta'ları da yazılır.
4. Sahne `PackedScene.pack` + `ResourceSaver.save` ile sayaçlı yeni bir yola kaydedilir, önceki dosya silinir, kök `free()` edilir.
5. `Kayitlar.sifirla()`, ardından `change_scene_to_file(yol)`.

### 5.2 Kip tespiti (yoldan)

Çekirdek `BolumYollari.kip(yol)` tek kural uygular:
- Yol `user://` ile başlamıyorsa kip `&"resmi"` olur.
- Başlıyorsa `d = yol.get_base_dir().get_file()` (yolun bulunduğu dizinin adı) ve `f = yol.get_file()` (dosya adı) alınır:
  - `d == "editor"` ve `f` `dene_` ile başlıyorsa: `&"dene"`
  - `d == "oyna"` ve `f` `oyna_` ile başlıyorsa: `&"ozel"`
  - `d == "canli"` ve `f` `.tscn` ile bitiyorsa: `&"canli"`
  - Hiçbiri değilse: `&""`
- `dene_mi`, `ozel_mi` ve `canli_mi` yalnızca `kip()` sonucunu karşılaştırır.

Kök dizinden bağımsızdır: `user://test_editor/editor/dene_001.tscn` de dene kipidir. `EditorOturumu` (statik) yalnızca veri taşır: düzenlenen bölüm, geri alma yığını, Dene'den gelen çözüm.

### 5.3 Butonlar

| Yer | Resmî ve canlı bölüm (değişmez) | Dene | Özel (Bölümlerim → Oyna) |
|---|---|---|---|
| Ev butonu | `sifirla` + ana menü | `sifirla` + editöre dön | `sifirla` + Bölümlerim |
| T, R, ölüm | aynı | aynı | aynı |
| Sonuç: Sonraki | birleşik listede sıradaki | gizli; yerine "Çözümü kaydet ve editöre dön" | gizli |
| Sonuç: Tekrar | aynı | aynı | aynı |
| Sonuç: Menü | ana menü | "Editöre dön" | Bölümlerim |
| HUD | "Bölüm N · Ad" (N birleşik sıradan) | "Deneme · Ad" | "Özel · Ad" |
| Çözüm yoksa | – | HUD altında amber uyarı satırı: "Bu bölümün doğrulanmış çözümü yok" (S4; oynanabilir) | aynı |

Değişen dosyalar: `ekran_butonlari.gd`, `sonuc_ekrani.gd`, `bolumler_listesi.gd` (§8), `ana_menu.tscn/.gd`. Uyarı satırı `bolum.gd`'ye eklenmez:
- Kurucu kökün `metadata/cozum_yok` alanına `not (BolumVerisi.dogrulama_guncel_mi(veri) and veri.dogrulama.durum == "dogrulandi")` değerini yazar.
- Ağaçta Bilgi'den sonra bir `EditorHud` düğümü ekler (§9.1 A2). Bu düğüm yalnızca görseldir.
- Canlı bölümde değer, canlıya alma ya da güncelleme anındaki duruma göre sahneye paketlenir.

---

## 6. Çözüm kaydı ve doğrulama

### 6.1 Kayıt

- Dene'de bölüm bitince `Kayitlar.turlar` (klon turları) ve `oyuncu.kayit_girdileri` (son tur; bitiş sonrası fazladan kareler içerebilir, K16) okunur.
- "Çözümü kaydet" bunları `EditorOturumu`'na yazar. Dosyaya ancak editörde "Kaydet" denince yazılır; sonuç ekranı dosya yazmaz.
- JSON'da çalıştırma uzunluğu kodlaması kullanılır: `[[n, yon, zipla 0/1, asagi 0/1], ...]`. Eksik `asagi` yanlış sayılır.
- `cozum` alanları: `{"turlar", "oyuncu"}`. Doğrulama sonucu ayrıca `dogrulama` alanına yazılır (§1.1).

### 6.2 Tek kaynak: `CozumDogrulayici`

`scripts/editor/cozum_dogrulayici.gd`, hem oyun hem test tarafından kullanılır (API §9.1).
- `root` altına eklenir; `process_physics_priority` **en yüksek** değerdedir (2026-10-20, A3 sapması): bir sonraki karenin girdisi karenin sonunda basılır, böylece gerçek tuş olayı gibi bir sonraki fizik karesinde `just_pressed` görülür. En düşük öncelikte zıplama klona göre bir kare geç etki ediyordu (ölçüldü). İlk karenin girdisi oynatma başında basılır.
- Çok adımlı işler (`determinizm`, `BolumDenetci.dinamik`) `toplu_basla()`/`toplu_bitir()` kullanır; iptal bayrağı adımlar arasında sıfırlanmaz.
- Her oynatma şu adımlarla ilerler:
  1. `Kayitlar` doldurulur, ardından `change_scene_to_file` çağrılır.
  2. Her karede bütün oyun eylemleri bırakılır ve kaydın o karesi `action_press` ile basılır.
  3. Durum türlere göre örneklenir (`_n_ornekle` mantığının genel hâli).
  4. `bolum.bitti` olduğu karede `bitis_kare = oyuncu.kare` alınır.
  5. Ölüm ya da süre sınırı (en uzun tur + 120 kare) olursa sonuç "bitmedi" olur.
- `Engine.time_scale` kullanılmaz; oynatma gerçek zamanlı ilerler.

### 6.3 Ölçüt

1. Oynatma bölümü bitirir, ölüm olmaz ve `bitis_kare` son tur kaydının uzunluğundan büyük olmaz. Kayıt uzunluğuyla birebir eşitlik beklenmez.
2. Oyun içinde 3, testte 100 tekrarda `bitis_kare` hep aynıdır ve 0..`bitis_kare` arasındaki tüm örnekler birebir eşittir (0,0 px). Kayıtlı `dogrulama.bitis_kare` varsa ona da eşittir.
3. Tur sayısı ≤ `max_klon`.
4. 600 kareyi aşan tur olursa UYARI (D21).

### 6.4 Oyun içi doğrulama akışı

- Önce statik denetimler (§7) çalışır, ardından en çok 10 oynatma yapılır: 3 kez çözüm, 1 kez klonsuz son tur, 3 saf betik, en çok 3 kez "bir klon eksik". Tahmini süre en çok yaklaşık 100 saniyedir.
- Ekranda ilerleme şeridi görünür; `Esc` ya da İptal doğrulamayı durdurur. İptalde hiçbir şey yazılmaz ve `Kayitlar` boşaltılır.
- Sonuç: `dogrulama.durum` "dogrulandi" ya da "taslak" olur.
- **S4:** doğrulama sonucu hiçbir oynama yolunu engellemez (Dene, Oyna, Canlıya al); yalnızca uyarıları belirler. Canlıya alırken engel olan şey yalnızca statik HATA'lardır (§8.1).

---

## 7. Otomatik denetimler

Seviyeler:
- **HATA:** statik HATA sahneyi kurulamaz ya da oynanamaz yapar; Dene, Oyna ve Canlıya al'ı engeller. Dinamik HATA (D9–D12) yalnızca "Doğrulandı" durumunu engeller.
- **UYARI:** listede görünür.
- **BİLGİ:** sayaca girmez; yalnızca seçili nesnenin panelinde gösterilir.

Statik denetimler `scripts/editor/bolum_denetci.gd`'de, dinamik denetimler `CozumDogrulayici`'dadır. Testler bu betikleri çağırır.

| # | Denetim | Seviye | Ölçüm |
|---|---|---|---|
| D1 | Tam 1 başlangıç ve 1 çıkış | HATA | Şema |
| D2 | Şema ve aralıklar: tür ve alanlar; `max_klon` 1..3; `ipucu_klon` = 0; `tutma_kare` 1..600; `yukseklik` 20..600; `kayma_mesafe` 10..200; `uzunluk` > 0 (üst sınır yok, D5 bakar); `gen`, `yuk` ≥ 10; `id` benzersiz ve ayrılmış değil; `kimlik` biçimi; en çok 200 nesne; kablo `tetik`'i gerçekten bağlı bir tetikleyici | HATA | Okuyucu |
| D3 | Bağlantılar: asansörün tam 1 plakası var, hedefler mevcut, şalter asansöre bağlı değil | HATA | Veri |
| D4 | Çizimsiz nesne | HATA | `BolumDenetci.gorunurluk_tara`, `_gr_bolum_tara` ile aynı kurallar (mevcut test değişmez; A4'te eşdeğerlik testi) |
| D5 | Ekran dışı (lazer ucu, asansörün üst konumu, geçidin açık konumu ve kablo ara noktaları dahil). **Geçit istisnası (2026-10-20, varsayılan karar):** açılırken tavanın içine kayabilir (B8, B12, B19); geçitte yalnız x ve alt kenar denetlenir, üstten taşma serbest. Blok yalnız tamamen ekran dışındaysa HATA | HATA | `Rect2(0,0,1152,648)` |
| D6 | Alt sınır açık | HATA | y = 648'e değen bloklar x 0..1152'yi örtmeli |
| D7 | Ağaç sırası | HATA | Tetikleyici ve mekanizmaların `get_index()` değeri Oyuncu'nunkinden küçük |
| D8 | Başlangıç, çıkış ya da kutu katı içinde; plaka ya da zıplatıcı gömülü | HATA | Dikdörtgen kesişimi |
| D9 | Çözüm yok, eski ya da bitmiyor | HATA (yalnızca "Doğrulandı" için; S4) | §6.3 (1) |
| D10 | Determinizm | HATA ("Doğrulandı" için) | §6.3 (2) |
| D11 | Klon sınırı aşımı | HATA ("Doğrulandı" için) | Tur sayısı |
| D12 | Klonsuz kısayol | HATA ("Doğrulandı" için) | §6.4 |
| D13 | Daha az klonla çözülme şüphesi | UYARI | Bir klon eksik oynatma bitiriyorsa |
| D14 | Koridor yüksekliği | UYARI | < 50 px: "karakter ayakta geçemez; bilinçli mi?"; 50..99 px: "dar". HATA yok; kasıtlı 40 px aralık içeren fikstür bunu sınar |
| D15 | Geçit koridoru tam kapatmıyor; açık aralık < 50 px | UYARI | Geçit üst kenarı blok içinde, alt kenarı yüzeyde mi |
| D16 | Lazer ışını bir bloktan geçiyor | UYARI | Kesişim |
| D17 | Tek yönlü platform üstündeki plakaya alttan baş değebilir | UYARI | Alt yüzey ile plaka arası ≤ 48 + 101 px (`kararlar.md:187`) |
| D18 | Aşılabilir yükseklik etiketi | BİLGİ | ≤ 101 px zıplamayla, ≤ 240 px zıplatıcıyla aşılabilir |
| D19 | Canlı/klon ayrışma riski | UYARI | (a) bant ile aynı y'de bitişik blok ya da asansör (dikiş); (b) bant varsa genel not; (c) çözümde karakter bant üstünde ya da 20 px yakınında ≥ 8 kare `yon == 0` duruyorsa |
| D20 | İşlevsiz tetikleyici; tetikleyicisiz geçit | UYARI | Veri |
| D21 | Bir tur 600 kareden uzun | UYARI | Çözüm |
| D22 | Klon asansör altında kilitleniyor | – | Ayrı denetim yok; D9 yakalar |
| D23 | Başlangıç noktası bir lazer ışınının içinde (açık ya da açılabilir) | HATA | Başlangıç dikdörtgeni ile ışın dikdörtgeni kesişiyor; aksi hâlde ölüm-yeniden yükleme döngüsü oluşur (K16) |
| D24 | Kutu başlangıca 40 px'ten yakın | HATA | `kararlar.md:237` |
| D25 | Asansör tepesi ile tavan arası | < 42 px HATA, 42..49 px UYARI | 40 + 2 pay (`kararlar.md:237`); 50 = karakter 48 + 2. Eşikler önerilmiştir, fikstürle doğrulanacak |
| D26 | Kablo lazer ışınına paralel ve yakın | UYARI | 8 px içinde paralel parça |

---

## 8. Bölümlerim, Canlıya al, numaralama ve harita (S1 kararı)

### 8.1 Bölümlerim ve Canlıya al

- **Bölümlerim**, `<kok>bolumler/*.json` listesidir (dosya adına göre sıralı). Her satırda ad, durum (Taslak ya da Doğrulandı), uyarı sayısı ve canlıysa "Canlı: Bölüm N" yazar. Düğmeler: Aç, Oyna, Sil, Canlıya al (ya da Canlıdan kaldır / Canlıyı güncelle).
- **Canlıya al:**
  1. Statik HATA varsa işlem engellenir ve hatalar listelenir.
  2. Çözüm yoksa ya da eskiyse uyarı onayı çıkar: "Bu bölümün doğrulanmış çözümü yok. Yine de canlıya alınsın mı?" (S4: izin verilir).
  3. Kullanıcı sırayı seçer: birleşik listedeki bölümler gösterilir, "şu bölümden sonra" seçilir (ör. Bölüm 10'dan sonra). En başa ekleme de bir seçenektir.
  4. **Bu adımda (ve yalnızca burada) denetim ve kurulum yapılır** (`CanliBolumler.canliya_al`, editör kodu):
     - JSON `<kok>canli/<kimlik>.json` olarak **dondurulmuş kopya** şeklinde yazılır.
     - Sahne `BolumKurucu` ile `<kok>canli/<kimlik>_v<NNN>.tscn` olarak kurulur.
     - `sira.json`'a kayıt eklenir.
     - Bölümlerim'deki JSON'un `canli` aynası güncellenir.
  5. `BolumListesi.yenile()` çağrılır.
- **Canlıyı güncelle (Y1 varsayılanı):** Bölümlerim'deki düzenleme canlı kopyayı değiştirmez; oyuna ancak bu düğmeyle yansır. Adımlar canlıya almayla aynıdır: statik denetim, çözüm uyarısı, onay. Sahne yeni bir sürüm sayacıyla kurulur (`_v<NNN+1>.tscn`) ve eski dosya silinir. `sira.json`'daki `sahne` alanı güncellenir, `yenile()` çağrılır. Gerekçe: oyundaki bölüm yanlışlıkla bozulmaz, önbellekten eski sahne dönmez.
- Canlıdan kaldırma: sıra kaydı ve canlı dosyalar silinir; Bölümlerim'deki kopya kalır. Kaldırılan bölümden sonra gelen canlı kayıtların `sonra` alanı, kaldırılanın `sonra` değerine devredilir; böylece sıra korunur.
- **`sira.json` biçimi:**

  ```json
  {"surum": 1, "canli": [
    {"kimlik": "deneme_asansoru_001", "ad": "Deneme Asansörü",
     "sahne": "deneme_asansoru_001_v002.tscn", "sonra": "res://scenes/bolumler/bolum_10.tscn",
     "icerik_ozeti": "<sha256>", "cozum_yok": true},
    {"kimlik": "ikinci_002", "ad": "İkinci", "sahne": "ikinci_002_v001.tscn",
     "sonra": "canli:deneme_asansoru_001", "icerik_ozeti": "<sha256>", "cozum_yok": false}
  ]}
  ```

  - `sonra` alanı numara saklamaz. Resmî bölüm için `res://` sahne yolu, canlı bölüm için `canli:<kimlik>` yazılır; canlı bölümün sahne dosya adı güncellemeyle değiştiği için kimlik kullanılır. Boş metin "en başa" demektir.
  - `sahne` dosya adı `canli/` dizinine göredir.
  - `ad` ve `cozum_yok` bilgileri, `liste()` JSON ayrıştırmak zorunda kalmasın diye buraya da yazılır.
- **Birleşik liste: `BOLUMLER` const kalır, `liste()` SAF OKUYUCUDUR**

  ```
  # bolumler_listesi.gd (A12); editör betiklerine bağımlı değil, yalnız BolumYollari ve HaritaYerlesimi kullanır
  const BOLUMLER := [...]               # 21 resmî kayıt, değişmez
  const AZAMI_BOLUM := 40               # Y2 varsayılanı
  static var kullanici_kok := "user://"
  static var _birlesik: Array = []       # önbellek
  static var son_uyarilar: Array[String] = []
  static func liste() -> Array           # {yol, ad, konum, onceki, kaynak: "resmi"|"canli", kimlik, cozum_yok}
  static func yenile() -> void           # _birlesik = []; son_uyarilar = []
  ```

  `liste()` yalnızca **okur**: `FileAccess` ile `sira.json`'u açar ve `FileAccess.file_exists` ile sahne dosyasını yoklar. **Hiçbir dosya yazmaz ve kurmaz, denetim çalıştırmaz, `BolumKurucu`, `BolumDenetci` ya da `CanliBolumler`'i çağırmaz.** Bu yüzden "Sonuç ekranı kalıcı dosya yazmaz" testi (`test_runner.gd` 10596–10718, `user://` anlık görüntüsü) etkilenmez.

  Algoritma:
  1. `BOLUMLER` kopyalanır (`kaynak: "resmi"`).
  2. `sira.json` okunur. Dosya yoksa ya da bozuksa canlı kayıt alınmaz; bozuksa uyarı eklenir.
  3. Sahne dosyası yoksa ilgili kayıt atlanır ve `son_uyarilar`'a eklenir (ayrıca `push_warning`). Canlı kayıtlar dosya sırasıyla işlenir.
  4. Yerleştirme:
     - `sonra == ""` olanlar en başa eklenir.
     - Liste baştan gezilir; her X kaydından hemen sonra, `sonra` değeri X'i gösteren canlı kayıtlar eklenir. "X'i göstermek": resmî bir X için `X.yol` eşitliği, canlı bir X için `"canli:" + X.kimlik` eşitliği.
     - Eklenen kayıtlar da sırayla gezildiği için zincirleme ekleme çalışır.
     - Yeri bulunamayan kayıt sona eklenir ve uyarı verilir.
  5. 40'ı aşan canlı kayıtlar alınmaz ve uyarı verilir (canlıya almada zaten engellenir).
  6. `onceki` alanı listedeki bir önceki kaydın yoludur. `konum` alanı `HaritaYerlesimi.konum(i, n)` ile hesaplanır.

  Mevcut statik işlevler (`yollar`, `sonraki`, `indeks`, `baglantilar`, `ad`, `baslik`) ve `harita.gd:30-31` artık `liste()`'yi okur. Canlı kayıt yoksa `liste()` 21 resmî kaydı verir; konum ve onceki alanları bugünküyle birebir aynıdır (A12 testi).
- **Numara** her zaman `indeks + 1`'dir, yani birleşik sıradan türer. Sonraki bölümlerin numarası kendiliğinden bir artar; `.tscn` dosyaları yeniden adlandırılmaz.
- Canlı bölümün kipi oyunda "resmî" gibi davranır: ev butonu ana menüye götürür, "Sonraki bölüm" çalışır, HUD "Bölüm N · Ad" gösterir. Çözüm yoksa §5.3'teki uyarı satırı canlıda da görünür (kurucu meta'sı).

### 8.2 Harita konumu (otomatik)

`scripts/harita_yerlesimi.gd`, `class_name HaritaYerlesimi`, `static func konum(i: int, n: int) -> Vector2`:
- **Satır sayısı 4 sabit** (y = 165, 280, 395, 510; aralık 115). Bunun nedeni, 5 satırda aralığın (510 − 165) / 4 = 86 px olması; bu 100 px'lik en kısa düğüm mesafesi kuralını bozar.
- **Sütun sayısı** `c = max(6, ceil(n / 4))`. x aralığı `d = 900 / (c − 1)`, x = 140 + j·d. Yılan sırası: satır r çift sayıysa soldan sağa, tekse sağdan sola. Düğüm i için r = i / c, j = i % c (tek satırda ters).
- n ≤ 24 için c = 6, d = 180; konumlar bugünkü tabloyla (`harita_yerlesim.md`) birebir aynıdır. 21 resmî bölüm için konum değişmez.
- 25..40 bölümde c 7..10 olur (d 150 … 100). Bütün konumlar yeniden hesaplanır; d ≥ 100 kuralı sağlanır.
- Bağlantılar yalnızca yatay ya da dikey olduğu için çizgiler kesişmez. Satır geçişi kenar sütunda dikeydir.
- Hover etiketi 280 px genişliğinde; aynı anda tek etiket görünür. Etiket, alttaki satırın düğümüne binmez (y+78 < y+115−34).
- **Üst sınır 40 bölümdür (Y2 varsayılanı, itiraz edilebilir):** c = 10 iken d = 100. Liste 40'a ulaşınca "Canlıya al" reddedilir ve gerekçe yazılır. 40'tan fazlası (sayfalama ya da kaydırma) ayrı bir karar konusudur.
- Harita testleri resmî tablo yerine `HaritaYerlesimi.konum`'u ve mevcut `_ar_yerlesim_denetle` kısıtlarını kullanır; 22, 30 ve 40 düğümlük yapay listelerle de denenir (A12).

### 8.3 HUD

`BolumListesi.baslik(yol)`:
- Yol `liste()` içindeyse "Bölüm N · Ad" döner; resmî ve canlı bölümler buna dahildir.
- Değilse ve `BolumYollari.dene_mi(yol)` ya da `ozel_mi(yol)` doğruysa "Deneme · Ad" ya da "Özel · Ad" döner. Ad, `load(yol).get_state()` ile kök düğümün `metadata/editor_ad` değerinden okunur.
- Hiçbiri değilse `""` döner (test sahnesi davranışı korunur).

A1–A11 boyunca `liste()` henüz yoktur; dene ve özel dalları `BOLUMLER` ile çalışır.

### 8.4 Numaraya ya da `BOLUMLER` sabitine bağlı mevcut testler (A12'de düzeltilecek; A1–A11'de dokunulmaz)

Testin, kullanıcının kendi canlı bölümlerinden etkilenmemesi için ön koşul: A12'de `test_runner.gd:_initialize` içinde `BolumListesi.kullanici_kok = "user://test_editor/"` ve `yenile()` çağrılır. Bu tek satırlık bir ekleme olsa da **mevcut test dosyasında değişiklik** sayılır ve onaylanması gerekir. Bu yapıldığında aşağıdaki testler canlı bölüm yokken bugünkü gibi geçer. Kırılma ancak A12 testleri geçici canlı bölüm eklediğinde, ya da ön koşul yapılmadan kullanıcının `user://canli/` klasörü doluyken ortaya çıkar.

| # | Yer (`tests/test_runner.gd`) | Ne bekliyor | Canlıya alınınca neden kırılır | Önerilen düzeltme |
|---|---|---|---|---|
| T1 | 1161 | `yollar().size() == BOLUMLER.size()` | `yollar()` birleşik listeyi, `BOLUMLER` 21 kaydı sayar | `liste().size()` ile karşılaştır |
| T2 | 1165–1184 | Bölüm 1 "Sonraki" → `scene_file_path == BOLUM_2` | 1 ile 2 arasına canlı eklenirse sonraki o olur | Beklenen = `BolumListesi.sonraki(BOLUM)` |
| T3 | 1217–1241 | Düğüm sayısı ve konum `BOLUMLER[i]`'den; numara yazısı `str(i+1)` | Harita `liste()` kullanır, sayı ve konum farklı | `liste()` + `HaritaYerlesimi.konum(i, n)` |
| T4 | 1246–1248 | `Dugum2` → `BOLUM_2` | Araya ekleme düğüm 2'yi değiştirir | Beklenen = `liste()[1].yol` |
| T5 | 1271–1306 | Çizgi sayısı ve uçları `BOLUMLER` konumlarından | Sayı ve konum farklı | `liste()` |
| T6 | 1335–1375 | Kesişim denetimi `BOLUMLER` ile | Aynı | `liste()` |
| T7 | 1384 `_liste_yollari` | `BOLUMLER` yolları | Harita ve zincirle uyuşmaz | `liste()` |
| T8 | 1392–1398 | "İlk 8 yol `bolum_1..8` sıralı" | İlk 8'e canlı eklenirse sıra bozulur | Yalnızca `kaynak == "resmi"` kayıtları süz; `bolum_1..21` göreli sırası korunmuş mu bak |
| T9 | 1427–1454 | `n` `BOLUMLER`'den, `sonraki()` zinciri `yollar()`'dan | `n` ile zincir uyuşmaz | Hepsi `liste()` |
| T10 | 1458–1490 | Düğüm sayısı = `_liste_yollari().size()`, `Dugum%d` → `yollar[i]` | Sayı farkı | `liste()` |
| T11 | 7843 | İpucu: diğer bölümlerde ikon yok (`BOLUMLER` döngüsü) | Kırılmaz (canlıda ipucu 0), ama canlıları kapsamaz | `liste()` (kapsam) |
| T12 | 11034–11054 | Hover "Bölüm %d: %s" (`BOLUMLER` + `Dugum%d`) | Harita `liste()` ile kurulur, düğüm ve ad kayar | `liste()` |
| T13 | 11056–11063 | Kayıt N konumu = `harita_yerlesim.md` tablo satırı N; tablo ≥ kayıt sayısı | n > 21'de tablo kısa kalır; c > 6 olunca konumlar kayar | Beklenen = `HaritaYerlesimi.konum(i, n)`; tablo yalnızca n ≤ 24 için belge |
| T14 | 11083–11087 | Tablo ≥ 21 satır ve "rezerve" satırlar kayıtlara 100 px'ten yakın değil | Rezerve konumlar artık canlılara verilebilir | Rezerve denetimi kaldır; yapay 22/30/40 listeyle `_ar_yerlesim_denetle` |
| T15 | 15488–15509 | Görünürlük taraması `BOLUMLER` üzerinde, "B%d" adlandırma | Kırılmaz, ama canlıları taramaz | `liste()`; adlandırmada yol kullan |
| T16 | 15529–15537 | Kayıt sayısı = `bolum_*.tscn` dosya sayısı | Canlı kayıtlar `bolum_*.tscn` değildir | Yalnızca resmî kayıtları say |
| T17 | 15540–15556 | Kayıt N → `bolum_N.tscn`; `onceki` = `bolum_(N−1).tscn` | Araya eklemede N kayar; `onceki` canlı olabilir | Resmî kayıtların göreli sırası `bolum_1..21`; `onceki` = listedeki bir önceki yol |
| T18 | 15563–15565 | HUD sabit numaralar `{1: "Bölüm 1 · Giriş", …, 14: "Bölüm 14 · Çekirdek", …, 21: …}` | Öne ekleme numaraları kaydırır | Anahtar sahne yolu; beklenen = `"Bölüm %d · %s" % [indeks(yol) + 1, ad]` |
| T19 | 15569–15593 | HUD döngüsü `BOLUMLER` indeksiyle | Canlıları kapsamaz, numara kayar | `liste()` |
| T21 | 11063–11075 | Kayıt sayısı (`BOLUMLER`) kadar düğüm için yerleşim denetimi (`_ar_yerlesim_denetle`): mesafe ≥ 100, kesişim yok, sınır içinde, hover etiketi binmiyor | Harita `liste()` ile kurulur; düğüm sayısı ve konumlar (c > 6'da) farklı olur | `liste()` konumlarıyla aynı denetim; ek olarak 22/30/40 düğümlük yapay `HaritaYerlesimi` listeleri |
| T22 | 10596–10718 | Sonuç ekranı testinin `user://` anlık görüntüsü öncesi ile sonrası eşit | Kırılmaz: `liste()` dosya yazmaz, kurulum yalnız "Canlıya al"da yapılır. Ancak editör testleri bu pencerenin içinde `user://test_editor/`'a yazarsa ya da test kökü ayarı silmeyi geciktirirse kırılır | Editör testleri bu pencerenin dışında (tam koşunun sonunda) çalışır ve kendi dizinini temizler; A12'de "`liste()` çağrısı `user://` görüntüsünü değiştirmez" testi |
| T20 | Test adları ("Bölüm 4 çözümü" vb., ör. 545, 1072, 2328) | Yalnızca metin; yükleme `BOLUM_N` **yol** sabitleriyle | Kırılmaz, ama ad yanıltıcı olur | İsteğe bağlı: adlarda sahne dosya adını kullan |

Çözüm, kısayol, determinizm ve bölüme özel bütün testler (`BOLUM_3`…`BOLUM_21`, `IPUCU_BOLUM_4/6`, `AR_B1/B4/B6`) **sahne yolu sabitleriyle** yükler; numaradan etkilenmez. Oyun kodunda `BOLUMLER`'e doğrudan bağlı yerler: `harita.gd:30-31` ile `bolumler_listesi.gd:144, 166, 172, 181`.

---

## 9. Aşamalı uygulama planı

Her aşama ayrı prompt, ayrı commit ve testli ilerler. Mevcut ~583 test GEÇTİ kalmalıdır.

**Test kuralı:**
- Yeni testler yalnızca `tests/editor/fikstur/*.json` dosyalarını okur.
- Yalnızca `user://test_editor/` dizinine yazar ve grup sonunda bu dizini siler.
- Tam koşuda en sonda çalışır; sonuç ekranının `user://` anlık görüntüsü penceresinin (T22) dışında kalır.
- Kullanıcının `user://bolumler/`, `user://canli/`, `user://editor/` ve `user://oyna/` dizinlerine dokunmaz.

**Test dosyası ve bayrak:**
- Testler `tests/editor_testleri.gd` dosyasındadır: `extends RefCounted`, **`class_name` yok**; küresel sınıf kaydı olmaz.
- `test_runner.gd`'ye **yalnızca ekleme** yapılır:
  - `const EDITOR_TESTLERI := preload("res://tests/editor_testleri.gd")`
  - `-- --editor` dalı: `await EDITOR_TESTLERI.new(self).hepsi()`, ardından GEÇTİ/KALDI yazdırma (mevcut bayrak dallarıyla aynı kalıp).
  - Tam koşunun sonunda aynı çağrı.
- `editor_testleri.gd` içinde `func _init(r: SceneTree)`, `func hepsi() -> void` (coroutine) bulunur. Sonuçlar `r._kaydi(ad, gecti, ayrinti)` ile yazılır. Fizik beklemesi `await r.physics_frame` ile yapılır. Test yardımcıları (`_bolumu_yukle`, `_senaryo`, `_betik`, `_dogru_kayit_betigi`, `_cozum_betigi`) `r` üzerinden çağrılır.

**Rol paylaşımı (CLAUDE.md: uygulayıcı teste dokunmaz):**
- **uygulayıcı:** `scripts/**` altındaki kod ve gerekiyorsa sahneler. Test dosyası, fikstür ve `test_runner.gd` yazmaz. Kendi denemesi için geçici dosyayı yalnızca `user://test_editor/` altında açar ve commit'e koymaz.
- **test-yazari:** `tests/editor_testleri.gd`, `tests/editor/fikstur/*.json` ve `test_runner.gd`'deki ekleme. Fikstürler resmî `.tscn` dosyalarından elle, ölçülerek yazılır (B21 kabloları `uclar` ve `ara` ile birebir). Testleri bu sözleşmeye göre bağımsız yazar ve koşar, kodu düzeltmez.
- Aşama sırası: önce uygulayıcı (kod), sonra test-yazarı (fikstür + test), sonra gözden geçirici.

### 9.1 A1–A4 uygulama sözleşmesi (kod yazacak ajanlara doğrudan prompt)

**Sorun öğesi biçimi (bütün denetimler için ortak):**

```
{"kod": "D2", "seviye": "HATA", "nesne": "Asansor1", "alan": "yukseklik", "mesaj": "yükseklik 20..600 olmalı (verilen: 700)"}
```

- `kod`: tam olarak `"D1"` … `"D26"` (§7 numaraları, başında sıfır yok).
- `seviye`: `"HATA"`, `"UYARI"` ya da `"BILGI"` (ASCII).
- `nesne`: nesne `id`'si; bölüm geneli için `""`.
- `alan`: alan adı ya da `""`.
- `mesaj`: Türkçe kullanıcı metni.
- Dosya okunamaz, JSON ayrıştırılamaz, `bicim` ya da `surum` yanlışsa `kod` `"D2"`, `nesne` `""`, `alan` `"bicim"`, `"surum"` ya da `""` olur ve `veri` boş sözlük döner.

**A1 — çekirdek `scripts/bolum_yollari.gd` (`class_name BolumYollari extends RefCounted`) + `scripts/editor/bolum_verisi.gd` (`class_name BolumVerisi extends RefCounted`)**

`BolumYollari` çekirdek dosyadır. `bolumler_listesi.gd`, `sonuc_ekrani.gd` ve `ekran_butonlari.gd` yalnızca bunu kullanır.

```
# BolumYollari
const VARSAYILAN_KOK := "user://"
static func bolumler_dizini(kok: String = VARSAYILAN_KOK) -> String   # kok + "bolumler/"
static func editor_dizini(kok: String = VARSAYILAN_KOK) -> String     # kok + "editor/"
static func oyna_dizini(kok: String = VARSAYILAN_KOK) -> String       # kok + "oyna/"
static func canli_dizini(kok: String = VARSAYILAN_KOK) -> String      # kok + "canli/"
static func kip(yol: String) -> StringName       # &"resmi" | &"dene" | &"ozel" | &"canli" | &""  (§5.2 kuralı)
static func dene_mi(yol: String) -> bool          # kip(yol) == &"dene"
static func ozel_mi(yol: String) -> bool          # kip(yol) == &"ozel"
static func canli_mi(yol: String) -> bool         # kip(yol) == &"canli"

# BolumVerisi
const BICIM := "loop_lab_bolum"
const SURUM := 1
const TURLER: Array[String] = ["blok","tek_yonlu","bant","plaka","zamanli_plaka","mandal_plaka","salter","ziplatici","asansor","gecit","lazer","kutu"]
const AYRILMIS: Array[String] = ["Oyuncu","Bilgi","Kapi","SinirDuvarlari","EditorHud"]
const AZAMI_NESNE := 200
static func bos(ad: String, kimlik: String) -> Dictionary                 # geçerli, nesnesiz bölüm (zemin yok: D6 verir)
static func ayristir(metin: String) -> Dictionary                         # {"veri": Dictionary, "sorunlar": Array[Dictionary]}
static func oku(yol: String) -> Dictionary                                # aynı dönüş; dosya yoksa D2
static func yaz(veri: Dictionary, yol: String) -> Error                   # JSON.stringify(veri, "  ", true); dizini oluşturur
static func sema_denetle(veri: Dictionary) -> Array[Dictionary]           # yalnız D1, D2, D3
static func kanonik_metin(veri: Dictionary) -> String                     # cozum, dogrulama, canli, notlar alanları atılır; JSON.stringify(v, "", true)
static func icerik_ozeti(veri: Dictionary) -> String                      # kanonik_metin(veri).sha256_text()
static func dogrulama_guncel_mi(veri: Dictionary) -> bool                 # veri.dogrulama.icerik_ozeti == icerik_ozeti(veri)
static func kayit_kodla(tur: Array) -> Array                              # [{yon,zipla,asagi},...] -> [[n, yon, z01, a01], ...]
static func kayit_coz(rle: Array) -> Array                                # tersi; yon float, zipla/asagi bool, eksik asagi = false
static func slug(ad: String) -> String
static func yeni_kimlik(ad: String, kok: String = BolumYollari.VARSAYILAN_KOK) -> String
```

- **`slug` kuralı:**
  - Küçük harfe çevrilir; Türkçe harfler eşlenir: ç→c, ğ→g, ı→i, i̇→i, ö→o, ş→s, ü→u.
  - `[a-z0-9]` dışındaki her dizi tek `_` olur; baştaki ve sondaki `_` kırpılır.
  - En çok 36 karaktere **kesilir**; kesimden sonra sondaki `_` yine kırpılır.
  - Sonuç boşsa `"bolum"` kullanılır.
- **`yeni_kimlik`:** `slug(ad) + "_%03d" % n` (en çok 36 + 4 = 40 karakter). En küçük boş n (1..999) seçilir. Dolu sayılanlar:
  - `bolumler_dizini(kok)` içindeki `*.json` adları,
  - `canli_dizini(kok)` içindeki `*.json` adları,
  - `canli/sira.json` içindeki `kimlik` değerleri.
  999'u aşarsa `""` döner ve çağıran D2 hatası gösterir.

Testler (~18):
- Gidiş-dönüş eşitliği.
- B1 fikstürü okunur.
- D1–D3 ihlalleri için 9 fikstür doğru `kod`/`nesne`/`alan` üretir: başlangıç yok, iki çıkış, bilinmeyen tür, aralık dışı `yukseklik`, `kayma_mesafe` 250, `ipucu_klon` 1, yinelenen `id`, ayrılmış `id`, asansöre şalter.
- Bozuk JSON D2 verir.
- Özet kararlıdır, içerik değişince değişir, `cozum`/`dogrulama`/`canli` alanlarından etkilenmez.
- Çalıştırma uzunluğu kodlaması gidiş-dönüş eşittir (eksik `asagi` dahil).
- `slug("Çifte Mühür") == "cifte_muhur"`; 60 karakterlik ad 36'ya kesilir; boş ad `"bolum"` olur.
- `yeni_kimlik`, `bolumler/` ve `canli/` dizinlerindeki dolu numaraları atlar.
- `BolumYollari.kip`: 4 kip × doğru/yanlış örnek, test kökü (`user://test_editor/editor/dene_001.tscn`) dahil.

Büyüklük: küçük.

**A2 — `scripts/editor/bolum_kurucu.gd` (`class_name BolumKurucu extends RefCounted`) + `scripts/editor/editor_hud.gd` (`extends CanvasLayer`, `class_name EditorHud`)**

```
const KATEGORI := {"blok":0,"tek_yonlu":0,"bant":0,"plaka":1,"zamanli_plaka":1,"mandal_plaka":1,
                   "salter":2,"ziplatici":3,"asansor":4,"gecit":5,"lazer":6,"kutu":8}
# Ağaç: kategori 0..6 (JSON sırası) -> Kapi -> kategori 8 (kutu) -> Oyuncu -> Bilgi -> EditorHud
static func kur(veri: Dictionary) -> Node2D                         # ağaca eklenmemiş kök (bolum.gd); owner kuralı uygulanmış
static func nesne_kur(nesne: Dictionary, veri: Dictionary) -> Node  # tek nesne; önizleme de kullanır; owner atamaz
static func kablo_noktalari(hedef: Dictionary, k: int, veri: Dictionary) -> PackedVector2Array
    # k: tetikleyici sırası (asansörde 0). uclar varsa aynen, yoksa hesaplanan uçlar; ara arada. Gizliyse boş dizi.
static func kablo_meta_adi(k: int) -> String                        # k == 0 -> "kablo", k >= 1 -> "kablo_%d" % (k + 1)
static func sahneye_kaydet(veri: Dictionary, yol: String) -> Error   # kur + pack + save + free; dizini oluşturur
static func yeni_gecici_yol(dizin: String, onek: String) -> String   # "<dizin><onek>_%03d.tscn" (bir sonraki n); dizindeki eski <onek>_*.tscn silinir
```

- **Kök meta'ları:**
  - `metadata/editor_ad = veri.ad`
  - `metadata/cozum_yok = not (BolumVerisi.dogrulama_guncel_mi(veri) and str(veri.get("dogrulama", {}).get("durum", "")) == "dogrulandi")`
- **`EditorHud`:**
  - Kurucu tarafından eklenir, adı `EditorHud`, `layer = 8`, owner köktür.
  - `_ready()` içinde kökün `metadata/cozum_yok` değerini okur. Değer doğruysa `Label` `Uyari` çocuğunu kurar: metin "Bu bölümün doğrulanmış çözümü yok", amber renk (`LabPaleti.AMBER`), `mouse_filter = IGNORE`, konum `Bilgi.position + (0, 56)` (Bilgi satırının ve klon yuvalarının altı).
  - Değer yanlışsa çocuk kurmaz.
  - Fizik ve oyun durumu okumaz, yazmaz. Headless'ta da düğüm kurulur (testler varlığa bakar).
- **Kablo:** `gizli: true` ise o tetikleyici için meta yazılmaz. Bağlantının kablo kaydı yoksa otomatik L çizilir. `uclar` varsa aynen kullanılır.

Testler (~30):
- **Yapısal eşdeğerlik (5 test):** B1, B5, B10, B14 ve B21 fikstürleri kurulur, `user://test_editor/` altına kaydedilip **diskten yeniden yüklenir** ve orijinal `.tscn` örneğiyle karşılaştırılır. Karşılaştırılanlar: kök çocuklarının adı, sınıfı ya da `scene_file_path`'i, sırası, `position`; dışa aktarılan alanlar (`max_klon`, `ipucu_klon`, `yukseklik`, `hiz`, `kayma_mesafe`, `kayma_yonu`, `uzunluk`, `yon`, `tetik_aktifken_kapali`, `acik_taraf_sag`, `baslangic_sagda`, `tutma_kare`, `mandal`, `firlatma_hizi`); satır içi şekil boyutları ve `Gorsel` offsetleri; `plaka` ve `tetikleyici_yollari` çözümü.
  - B21'de ayrıca **bütün kablo meta'ları birebir** (`uclar` sayesinde): GecitG `kablo` (170,584)→(170,376), `kablo_2` (110,372)…(160,300); GecitM, LazerA ve LazerB.
  - B5, B10 ve B14'te kablo meta'sı **yoktur** (fikstürde her bağlantı `gizli: true`).
  - Fazladan düğüm olarak yalnızca `EditorHud` kabul edilir.
- **Diskten yükleme, boyutlar aynı mı:** farklı boyutlu üç blok kaydedilip yüklenir; her şekil kendi boyutundadır ve şekiller ayrı nesnelerdir.
- İki geçit örneğinin şekli 20x200 kalır (paylaşılan alt kaynak bozulmamış).
- `kayma_mesafe` açıkça yazılmıştır; fikstürde 100 iken sahne varsayılanı 200'e düşmez.
- Sahne örneklerinin iç çocuklarında owner yoktur.
- Kategori sırası ve D7: karışık sıralı JSON doğru sırayla kurulur.
- Kablo: otomatik L noktaları; ara noktalı yol; `uclar` aynen; `gizli` olunca meta yok; 3 tetikleyicide `kablo`, `kablo_2`, `kablo_3` adları.
- `metadata/editor_ad` doğru yazılır.
- `cozum_yok`: çözümsüz bölümde true ve `EditorHud/Uyari` var; güncel `dogrulandi` bölümde false ve `Uyari` yok; içerik değişince yeniden true.
- `EditorHud` fareyi yutmaz; B1 fikstüründe 100x determinizm `EditorHud` ile de 0 sapma verir (A3'teki testle ortak).
- Geçici sahnede R, ölüm ve T (`reload_current_scene`) çalışır (3 test).
- Önbellek: ardışık iki farklı kurulumda ikincisinin içeriği yüklenir.
- `yeni_gecici_yol` eski dosyayı siler.
- B1 fikstüründe mevcut B1 betikleri (`r._dogru_kayit_betigi()` ile kayıt, `r._cozum_betigi()` ile çözüm, `r._senaryo`) bölümü bitirir.

Büyüklük: büyük.

**A3 — `scripts/editor/cozum_dogrulayici.gd`, `class_name CozumDogrulayici extends Node`**

```
signal ilerleme(adim: int, toplam: int, aciklama: String)
signal bitti(sonuc: Dictionary)
func oynat(sahne_yolu: String, klon_turlari: Array, son_tur: Array, ornekle := true) -> Dictionary
    # await edilir; {"bitti": bool, "oldu": bool, "bitis_kare": int, "kareler": Array[int], "ornekler": Array}
func determinizm(sahne_yolu: String, cozum: Dictionary, tekrar: int) -> Dictionary
    # {"gecti", "sapmali", "maks_sapma", "bitis_kare"}
func iptal() -> void
static func ornekle(bolum: Node) -> Dictionary   # tür tabanlı: oyuncu/klon konumları, plaka basili, lazer acik, geçit/asansör y, kutu konumu
const SURE_PAYI := 120
```

Testler (~12):
- Öncelikli düğümden `action_press` ile `just_pressed` zıplaması aynı karede gerçekleşir.
- B1 fikstürü + bilinen kayıtla bitirir.
- `bitis_kare` ≤ kayıt uzunluğu.
- 100x sapma 0.
- Yanlış kayıt (erken betik) "bitmedi" verir.
- Lazere yürüyen kayıt `oldu` verir.
- Süre sınırı çalışır.
- İptal yarıda durdurur ve `Kayitlar` boş kalır.
- Klon sayısı `max_klon`'u aşan kayıt reddedilir.
- `Engine.time_scale == 1` ve `physics_ticks_per_second == 60` korunur.

Büyüklük: orta.

**A4 — `scripts/editor/bolum_denetci.gd`, `class_name BolumDenetci extends RefCounted`**

```
static func statik(veri: Dictionary) -> Array               # D1-D8, D14-D20, D23-D26 (veri + kurulan sahne)
static func gorunurluk_tara(sahne: Node) -> Dictionary      # {"sayi","cizimsiz","sorun"}; _gr_bolum_tara ile aynı kural
static func dinamik(veri: Dictionary, dogrulayici: CozumDogrulayici, sahne_yolu: String) -> Array  # D9-D13, D19c, D21
static func ozet(sorunlar: Array) -> Dictionary             # {"hata": int, "uyari": int, "bilgi": int}
```

Testler (~56):
- D1–D26 arasında ayrı denetimi olan 25 kalem var (D22'nin ayrı denetimi yok). Her biri için olumlu fikstür (sorun yok) ve olumsuz fikstür (doğru `kod`, `seviye` ve `nesne`): yaklaşık 50 test. D1–D3, A1'de sınanan `sema_denetle`'nin `statik()` içinden de çağrıldığını gösteren tek bir testle geçilir.
- D14 için 40 px kasıtlı aralık fikstürü yalnızca uyarı almalı.
- D23: başlangıç ışın içinde.
- D24: kutu 30 px uzakta.
- D25: 41 / 45 / 60 px.
- Eşdeğerlik: `gorunurluk_tara`, 21 resmî bölümde `_gr_bolum_tara` ile aynı sonucu verir (21 alt karşılaştırma, tek test).
- Klonsuz kısayollu fikstür D12 verir.
- Bir klonu gereksiz fikstür D13 verir.
- `user://test_editor/` test sonunda boştur.

Büyüklük: büyük.

### 9.2 Aşama tablosu

| Aşama | Bağımlı | İçerik | "Bitti" ölçütü | Büyüklük |
|---|---|---|---|---|
| A0 | – | Onay; kararların `kararlar.md`'ye tarihli notu | Kullanıcı onayı | – |
| A1 | A0 | §9.1 A1 | ~18 test GEÇTİ | küçük |
| A2 | A1 | §9.1 A2 (bütün türler + `EditorHud`) | ~30 test GEÇTİ | büyük |
| A3 | A2 | §9.1 A3 | ~12 test GEÇTİ | orta |
| A4 | A2, A3 | §9.1 A4 | ~56 test GEÇTİ | büyük |
| A5 | A2 | Editör iskeleti: ana menüde "Editör" butonu, `scenes/editor.tscn`, `scripts/editor/editor.gd`, önizleme (§3.3), palet (blok, başlangıç, çıkış), seç/taşı/boyut/sil, ızgara (20/10/kapalı, mıknatıs), geri al/yinele, Yeni/Kaydet ve basit Aç | Programatik yerleştirme doğru JSON üretir; parametre değişince önizleme düğümü yeniden kurulur; ızgara kapatılabilir; geri al zinciri doğru; Kaydet → Aç eşit; ana menü testi 4 düğmeyle geçer (~18) | büyük |
| A6 | A5 | Dene akışı: `EditorOturumu`, yol tespiti, ev butonu ve sonuç ekranı dalları, "Çözümü kaydet ve editöre dön", `baslik()` dene/özel dalı, çözüm yok uyarı satırı (`EditorHud`) | Dene girişi temiz; ev → editör; çözüm `EditorOturumu`'na alınır, `Kayitlar` boşalır; çözümsüz bölüm **oynanır** ve uyarı görünür; HUD "Deneme · Ad"; resmî bölümlerde arayüz testleri değişmez (~12) | orta |
| A7 | A5 | Arayüz: plaka, geçit, asansör + Bağla + kablo sürükleme (ara nokta ekle/taşı/sil, sıfırla, gizle) | Bağla kuralları; silmede bağlantı temizliği; ara noktalar JSON'a yazılır ve kurulan meta ile eşleşir; D26 tetiklenir (~14) | orta |
| A8 | A7 | Arayüz: kutu, zıplatıcı, bant, tek yönlü, lazer, şalter, zamanlı plaka, mandal plaka | Her tür paletten eklenir ve düzenlenir; tutamaçlar doğru alanı yazar; aralıklar D2 ile uyumlu (~12) | orta |
| A9 | A3, A4, A6 | "Doğrula": §6.4, ilerleme ve iptal, `dogrulama` alanı | Geçerli fikstür "dogrulandi" olur; kısayollu fikstür "taslak" kalır ama **Dene ve Oyna açık kalır** (S4); iptal hiçbir şey yazmaz; içerik değişince durum "taslak" olur (~10) | orta |
| A10 | A9 | Bölümlerim ekranı: liste, Aç, Oyna (`user://oyna/`), Sil, durum ve uyarı göstergesi; "Özel · Ad" | Çözümsüz bölüm uyarıyla **oynanır**; statik HATA'lı bölüm oynanmaz; sıra deterministiktir; ev ve menü dönüşü Bölümlerim'e gider (~8) | küçük-orta |
| A11 | A7 | `gorunum.gd` kablo eki (grafik ajanı): `kablo_<i>`, şalter kablosunun yanması, asansör kablosu, ara nokta halkaları; ardından v1 son denetimi (`gozden-gecirici`) | Görünürlük testleri geçer; B21 kablosu aynı noktalardan çizilir; şalter ve asansör kablosu durumla yanar (headless'ta düğüm/meta testi, ~6); elle kontrol listesi; tam koşu GEÇTİ, denetim KABUL | küçük-orta |
| **A12** | A10, A11 | Canlıya al. Editör kodu: `scripts/editor/canli_bolumler.gd` (`class_name CanliBolumler`): `canliya_al(veri: Dictionary, sonra: String, kok: String) -> Array[Dictionary]` (sorunlar; boşsa başarılı), `guncelle(veri, kok) -> Array[Dictionary]`, `kaldir(kimlik: String, kok: String) -> Error`, `sira_oku(kok) -> Array`. Çekirdek: `scripts/harita_yerlesimi.gd`, `BolumListesi.liste()/yenile()/kullanici_kok/son_uyarilar` (**saf okuyucu**, editör betiklerine bağımlı değil) ve `harita.gd` → `liste()`. **Mevcut test değişiklikleri T1–T22** (§8.4) ve `_initialize` içinde test kökü ayarı | Canlı yokken `liste()` = 21 kayıt, konum ve onceki bugünküyle birebir. **`liste()` saflığı:** çağrı öncesi ve sonrası `user://` görüntüsü eşit; `bolumler_listesi.gd` kaynağında `BolumKurucu`, `BolumDenetci` ve `CanliBolumler` geçmez; eksik sahne dosyası atlanır ve `son_uyarilar` dolar. Araya ekleme (10–11) numaraları +1 kaydırır; HUD ve harita doğru. Zincirleme (`canli:<kimlik>`) ve en başa ekleme; kaldırmada `sonra` devri; yeri bulunamayan kayıt sona eklenir; 40 sınırı. **"Canlıyı güncelle" sonrası yeni içerik yüklenir** (yeni `_v<NNN>` yolu, eski dosya silinmiş, ad ve nesne değişikliği oyunda görünür). `HaritaYerlesimi` 21/22/30/40 düğümde mesafe ≥ 100, kesişim yok, etiket binmez. Çözümsüz canlıya alma uyarı ve onayla geçer, statik HATA engeller. T1–T22'nin düzeltilmiş hâlleri hem 0 hem 2 canlı bölümle geçer. `.tscn` dosyaları yeniden adlandırılmaz (~32) | büyük |

Toplam yaklaşık 228 yeni test: A1 18 + A2 30 + A3 12 + A4 56 + A5 18 + A6 12 + A7 14 + A8 12 + A9 10 + A10 8 + A11 6 + A12 32. A12'deki mevcut test düzeltmeleri bu sayıya dahil değildir. 100x determinizm testleri tam koşuya süre ekler (ölçülmedi).

**Onay metninde açıkça belirtilecekler:**
- **Mevcut koda dokunulan yerler:**
  - A1: yeni çekirdek `bolum_yollari.gd`.
  - A5–A6: `ekran_butonlari.gd`, `sonuc_ekrani.gd`, `bolumler_listesi.gd:baslik`, `ana_menu.tscn/.gd`.
  - A11: `gorunum.gd`.
  - A12: `harita.gd`, `bolumler_listesi.gd` birleşik liste.
- **A11 görünüm eki mevcut bölümleri de etkiler:** B20'deki 3 kablo meta'sı (`bolum_20.tscn:127, 135, 143`) ve B21'deki 5 kablo meta'sı. Ara nokta perçin halkaları bu kabloların köşelerinde de görünür. Noktalar ve yanma mantığı aynı kalır. Bu iki bölüm A11'in elle kontrol listesine girer.
- **Mevcut test değişikliği:**
  - A1–A11'de yok. Yalnızca `preload` sabiti, `--editor` dalı ve tam koşu sonuna çağrı eklenir.
  - A12'de T1–T22 ve `_initialize` içinde test kökü ayarı.
  - `_gr_bolum_tara` hiçbir aşamada değiştirilmez.

---

## 10. Riskler

1. **`PackedScene.pack` davranışı** (owner, ayrı şekil alt kaynakları, `node_paths`) motora bağlıdır. A2'de diskten yükleyerek kanıtlanacak.
2. **Kaynak önbelleği:** sayaçlı dosya adı kullanılır; A2'de test edilir.
3. **Girdi enjeksiyonu:** `just_pressed` ve öncelik davranışı. A3'ün ilk testi; yedek olarak `physics_frame` sinyali.
4. **Canlı/klon ayrışması** (K14): D19 ile uyarılır.
5. **Önizleme bayatlığı** (K15): yeniden kurma ve elle `queue_redraw` ile önlenir.
6. **Kısayol kanıtlanamaz:** D12 ve D13 yalnızca taramadır. Kullanıcının **doğrulanmamış bölümü de canlıya alınabilir** (S4); bu bölümler resmî zincirde çözülemez olabilir. Önlem: uyarı onayı, HUD uyarı satırı ve Bölümlerim'deki durum göstergesi.
7. **Doğrulama süresi** en çok yaklaşık 100 saniye; iptal edilebilir.
8. **İki görünürlük kuralı kopyası** (`_gr_bolum_tara` ve `BolumDenetci`): A4 eşdeğerlik testi her koşuda çalışır.
9. **Kullanıcı verisinin testleri etkilemesi** (A12): test kökü ayarı yapılmazsa kullanıcının canlı bölümleri numaraya bağlı testleri değiştirir. Önlem: `_initialize` ayarı ve T1–T20 düzeltmeleri.
10. **Bozuk ya da eksik canlı dosya:** `liste()` kaydı atlar ve `son_uyarilar`'a yazar; numaralar o oturumda kayar. Oyun çökmez. Onarım için Bölümlerim'de "Canlıyı güncelle" kullanılır (`liste()` kendiliğinden kurulum yapmaz).
11. **Harita 40 düğüm sınırı** (Y2 varsayılanı).
12. **B21 kablo uçları elle ayarlı:** `uclar` alanı olmadan birebir eşitlik sağlanamaz. Fikstürü yazarken uçların B21'den aynen kopyalanması gerekir; test-yazarı sorumludur.
13. **`liste()` önbelleği:** `yenile()` çağrılmazsa eski liste döner. Canlıya al, güncelle ve kaldır işlemleri `yenile()` çağırmak zorundadır; A12'de test edilir.
12. **Kalıcılık:** kullanıcı içerik dosyaları ve `sira.json` yeni bir kalıcılık türüdür (ilerleme kaydı değildir) ve `kararlar.md`'ye yazılmalıdır.
13. **`main.tscn`**, var olmayan `main.gd` dosyasına başvuruyor (kullanılmıyor, editörle ilgisiz).

---

## 11. Kesinleşen kararlar (kullanıcı, 2026-10-19)

- **S1:** Bölümler editördeki "Bölümlerim" listesinde durur. "Canlıya al", bölümü kullanıcının seçtiği yere ekler; sonraki numaralar kendiliğinden bir artar; numara `bolumler_listesi` sırasından türer; HUD ve harita buna uyar; `.tscn` dosyaları yeniden adlandırılmaz; testler sahne yoluna bağlanır (§8, A12).
- **S2:** 1:1 tuval, gizlenebilen panel (§3).
- **S3:** Nesne boyutları mevcutla birebir aynı; ızgara 20 px, `Shift` ile 10 px, ekran kenarı mıknatıs, ızgara kapatılabilir (§3.2).
- **S4:** Çözümsüz bölüm Dene'de ve Bölümlerim'de oynanabilir, yalnızca uyarı çıkar. Canlıya almadan önce de uyarı çıkar ama izin verilir. "Doğrulandı" yalnızca bir durum etiketidir (§6.4, §8.1).
- **S5:** Kablo otomatik çizilir; ara noktalar basılı tutup sürüklenerek ayarlanır ve JSON'da saklanır; kablo çarpışmaz; lazerden renk, kalınlık, biçim ve halkalarla ayrılır; `gorunum.gd` eki A11'dedir (§4).

### Varsayılan kararlar (kullanıcı cevap vermedi; önerilen seçenek uygulanır, **itiraz edilebilir**)

- **Y1 (varsayılan, itiraz edilebilir):** canlıya alınan bölümün kopyası dondurulur. Bölümlerim'de yapılan düzenleme oyuna yalnızca "Canlıyı güncelle" ile yansır; bu adımda da denetim, çözüm uyarısı ve onay vardır. Reddedilen seçenekler: canlı bölüm her zaman son hâli kullanır (yarım düzenleme oyuna geçer); canlı bölüm kilitlenir (her düzenlemede sıra yeniden seçilir).
- **Y2 (varsayılan, itiraz edilebilir):** birleşik listede en çok 40 bölüm olur (4 satır × 10 sütun, aralık 100 px); fazlası canlıya alınamaz. Reddedilen seçenekler: harita sayfaları, kaydırmalı harita (ikisi de `harita.gd` ve testlerini büyütür).

Açık soru yok.

---


## Kod incelemesinde dayanılan dosyalar

- `CLAUDE.md`, `docs/kararlar.md` (90, 187, 237, 383. satırlar), `docs/sorunlar.md` (70), `docs/stil.md`, `docs/devir/README.md`, `durum.md`, `harita_yerlesim.md`, `.claude/agents/tasarimci.md`, `project.godot`
- `scripts/`: `bolum.gd`, `kayitlar.gd`, `player.gd`, `gorunum.gd`, `basinc_plakasi.gd`, `asansor.gd`, `kapi.gd`, `gecit.gd`, `lazer.gd`, `salter.gd`, `kutu.gd`, `yayli_ziplatici.gd`, `tasima_bandi.gd`, `harita.gd`, `harita_dugumu.gd`, `bolumler_listesi.gd`, `ana_menu.gd`, `sonuc_ekrani.gd`, `ekran_butonlari.gd`
- `scenes/`: `oyuncu`, `gecit`, `lazer`, `salter`, `kutu`, `tek_yonlu`, `tasima_bandi`, `yayli_ziplatici`, `zamanli_plaka`, `mandal_plaka`, `main`, `ana_menu`, `sonuc_ekrani` (`.tscn`); `scenes/bolumler/bolum_1.tscn` (tam), `bolum_2`, `bolum_4`, `bolum_5`, `bolum_10`, `bolum_14`, `bolum_19`, `bolum_21` (düğüm sırası ve özellikler); 21 sahnenin tamamında özellik, meta, şekil ve sahne örneği sayımı
- `tests/test_runner.gd`: yardımcılar (`_betik`, `_girdi_uygula`, `_bolumu_yukle`, `_tur_oyna`, `_kaydet`, `_senaryo`, `_r_bas`, `_yeni_sahne_bekle`, `_n_*`, `_b13_a`), `_test_bolum_secimi` (1153–1263), `_test_harita_cizgisi/_kesisim/_dugumleri`, `_test_bolum_listesi` (1391–1454), `_ipucu_testleri` (7785–7866), `_ar_yerlesim_tablosu/_denetle`, `_ar_harita` (10967–11091), `_ar_ana_menu`, `_gr_bolum_tara`, `_gorunurluk_testleri` (15422–15556), `_ar_hud_bolum_etiketi` (15562–15604); `tests/sahneler/gecit_test.tscn`, `lazer_test.tscn`

## Ek not (A2 uygulaması, 2026-10-20)
- `tests/test_runner.gd` editör testlerini `preload` yerine `load(EDITOR_TESTLERI_YOLU)` ile, kullanılacakları anda yükler. Gerekçe: başlangıçta preload, yükleme sırasını değiştirip B13/B14/B19 canlı-klon ölçümlerini (geniş-faz sırası kısıtı, `durum.md`) eşiğin üstüne kaydırıyordu.
- A5 uyarısı: `BolumKurucu` yüklenince 13 betik/sahneyi preload eder. Ana menü ya da oyun başlangıcı ona başvurursa resmî bölüm fiziği aynı şekilde kayabilir; editör girişinde gecikmeli `load` kullanılmalı.
- §1.3 düzeltmesi: blok çarpışma maskesi resmî `.tscn` dosyalarıyla aynı, varsayılan 1'dir (maske 0 değil).
- `nesne_kur` bilinmeyen türde null döndürür; doğrudan çağıranlar (A5 önizleme) null denetler.
