# Bölüm 9 "Yük" ince ayar (2026-10-16, Parça 2 madde 3, kullanıcı onaylı)

Amaç: zorluğu azaltmak. Her kritik pencerede en az 8-10 kare pay, her tur ~600 karenin altında, gereksiz bekleme yok.
Fikir (kutu tanıtımı) ve çözüm (3 klon: k1 Plaka1, k2 Plaka2, k3 kutuyu asansörle F2'ye taşır + Plaka3; 4. tur oyuncu kutuyu PlakaKutu'ya iter) KORUNDU.
Ölçüm: `tests/test_runner.gd` `_test_bolum9_pencereler` (her satırda ilgili tur yeniden kaydedilir, sonraki turlar betikle yeniden üretilir, sonuç "bölüm bitti" ile ölçülür). Sabitler: 5 px/kare yürüme, ayrık karede zıplama tepesi ~100,9 px.

## Önce: ölçülen pencereler ve sorunlar

| Pencere | Ölçülen (önce) | Sorun |
|---|---|---|
| k2'nin Plaka2'ye basma anı (en erken geçerli) | bekleme 0 -> basış kare 90 KALDI; bekleme 10 -> kare 100 GEÇTİ (sınır ~91-100) | Tek taraflı: k3 ve kutu asansöre binmeden basılırsa asansör boş kalkar. Koşarak zıplayan k2 ~55-65. karede basar, yani k2 her durumda beklemeli. |
| Çözümdeki k2 basışı | kare 210 (120 kare boş bekleme) | Gereksiz uzun: k2 2 sn boş bekler. |
| k3 / oyuncu asansöre geç kalma payı | 100 kare (120'de kalır) | Pay bol ama bedeli bekleme. |
| k3 ve oyuncunun asansörde beklemesi | biniş ~105, asansör üstte ~290: ~185 kare (~3 sn) | Uzun bekleme (80'i yükseliş). |
| k3'ün asansörde durduğu x (kutu önde) | 570..645 (75 px, ~15 kare); "kutu duvara dayanana kadar sağ basılı" da geçer | Sorun yok. |
| Tur 4: kutunun PlakaKutu'da bırakıldığı yer (kutu merkezi) | 880..970 (90 px, 18 kare) | Sorun yok. |
| Tur 4: kutunun üstünden geçiş (dikey zıplama sonrası sağa basma karesi) | 1..26 (taramanın sınırı; kutu üstüne de inilebiliyor) | Sorun yok. |
| Güvenlik: PlakaKutu'dan ayrılıp G'ye koşma (oyuncu tek başına geçemesin) | G'nin geçilebilir olmasına 2-4 kare (4-8 px) kala varılıyor | Dar: konum/hız değişimi kısayol açabilir. |
| Güvenlik: asansör kutuda takılı basamak (üst ~536) -> F2 | basamaktan ayak y min 435 < F2 440: F2'ye ÇIKILIYORDU (pay -4,9 px) | `docs/sorunlar.md` bulgusu; çözümü bozmuyordu ama kenar payı yoktu. |
| Tur süreleri (kare) | 25 / 224 / 329 / 407 (toplam 985, ~16,4 sn) | Hepsi <600, ama 2-4. turlarda ~2-3 sn boş bekleme. |

## Yapılan ayar

| Değişiklik | Önce | Sonra | Neden |
|---|---|---|---|
| Kat2 (F2) yüzeyi | y 440 (Kat2 450x160, merkez y 520) | y 430 (450x170, merkez y 515) | Takılı-asansör basamağından F2'ye 96 -> 106 px (> ~100,9): basamak yolu kapandı (+5 px). |
| Asansör `yukseklik` | 160 | 170 | Üst yüzey yine F2 hizası (430); yükseliş 80 -> 85 kare. |
| Plaka3 | (760, 432) | (760, 422) | F2 yüzeyine oturur. |
| PlakaKutu | (930, 432) | (910, 422) | G'ye koşu mesafesi +20 px: G sprint payı 2-4 -> 6-8 kare. L1 ışınından (x 860) 20 px sağda, görünür. |
| Gecit | (1070, 340) | (1070, 330) | Alt ucu F2 hizasında; açıkken baş payı aynı (22 px). |
| Lazer2 (L1) `uzunluk` | 140 | 130 | Tavandan F2'ye tam boy. |
| Kapi | (1120, 416) | (1120, 406) | F2 yüzeyine oturur. |
| Çözüm betiği k2 beklemesi | 120 kare (basış 210) | 60 kare (basış 150) | Gereksiz beklemeyi keser; k3/oyuncuya 50 kare geç kalma payı bırakır. |
| Tur 4 betiği | L1'e bakmadan iter | x=800'de L1 kapanana kadar bekler (normal akışta zaten kapalı) | Ekrana bakarak oynama; k3 asansörde duvara dayalı durunca (x~648) oyuncu k3'ü geçip açık L1'e giriyordu (betik hatası, bölüm değil). |

Fizik, kayıt formatı, nesne türleri, klon sayısı, tur yapısı değişmedi. Diğer nesneler (Zemin, Tavan, Platform, Plaka1, Plaka2, Asansör x, Lazer1, Kutu, Oyuncu) aynı.

## Sonra: ölçülen pencereler

| Pencere | Önce | Sonra |
|---|---|---|
| k2 basma anı en erken geçerli | ~91-100 | ~91-100 (rota değişmedi) |
| Çözümde k2 basışı / k2 için pay | 210 / ~110 kare | 150 / ~50-59 kare |
| k3 geç kalma payı | 100 kare | 50 kare (>= 8) |
| Oyuncu (tur 4) geç kalma payı | 100 kare | 50 kare (>= 8) |
| k3 asansörde durma x | 570..645 (15 kare) | 570..645 (15 kare) |
| Kutu bırakma (kutu merkezi) | 880..970 (18 kare) | 860..950 (18 kare) |
| Kutu üstünden geçiş (sağa basma karesi) | 1..26 (tarama sınırı) | 1..27 (27 kare; tarama 1..40) |
| G sprint güvenlik payı | 2-4 kare | 6-8 kare |
| Takılı-asansör basamağı -> F2 | -4,9 px (çıkılıyordu) | +5 px (çıkılamıyor; ayak y min 435 > 430) |
| Asansörde bekleme (biniş -> üstte) | ~185 kare | ~130 kare (45 bekleme + 85 yükseliş) |
| Tur süreleri | 25 / 224 / 329 / 407 (985) | 25 / 164 / 274 / 348 (811, ~13,5 sn) |

Atlanamazlık (L0, L1, kapalı G, zeminden/kutudan/platformdan F2), kısayol (eksik klon, röle), başarısızlık (k2 erken basar, kutu G'ye itilir, k3 asansöre binmez), klon sınırı, determinizm testleri yeni geometride GEÇTİ.

## Kalan not (okunabilirlik)
k2'nin "k3 ve kutu asansöre binince bas" koşulu yapı gereği tek taraflıdır: 2. turda k3 henüz yoktur, k2 en az ~1,6 sn (kare ~95) beklemelidir. Üst sınır yoktur (geç basmak yalnızca yavaşlatır), yanlış basış 3. turda görünür olur (asansör boş kalkar). Bu ayar beklemeyi kısalttı ama koşulu kaldırmadı. Kaldırmak, tur yapısı ya da nesne değişikliği ister (bkz. `docs/sorunlar.md`).
