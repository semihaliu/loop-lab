# Bölüm 12 taslağı: Kargo

> **UYARI (test-yazarı ölçümü, 2026-10-15; bu taslaktaki sayılar tahmindi, aşağıdakiler ÖLÇÜLDÜ):**
> - Kutu basamağı payı 6,5 değil **11,8 px** (kutu üstünden zıplama tepesi ayak y=278,2; R2 üstü 290). §14.3 önerisi (R2'yi 294'e çekmek) gereksiz.
> - §10.5 yanlış: kutu karakterlerle çarpışmaz (yalnız `it()` ile itilir). Y2 `x>=477` sonrası kutu inmeden Zıplatıcı'ya girse de çözüm bozulmaz; en az ~10 kare beklemek yeterli (6 kare başarısız, kutu R'de x=500'e kayar). Eski "~55 kare" alt sınırı geçersiz.
> - Oyuncunun Y2'yi izleme gecikmesi L=0..38 kare çalışır (L=0 çift itme sorunu yok); L>=40 başarısız (GK kapanır).
> - Fırlama sonrası `sag` en geç 4 kare gecikmeyle başlamalı (gec<=4) ve en az 5 kare sürmeli; Y2 başlangıç gecikmesi s>=20.
> - GK yarışı: Y2 PlakaK'dan ayrıldıktan sonra en çok 3 kare durabilir (açıklık 56 px, gerek 48).
> - §0 röle kısayolu bu bölümde çalışmaz (43 deneme, 0 çözüm; klon GK'da takılır). Ama Bölüm 6'da çalışır, bkz. docs/sorunlar.md.

(Tasarımcı çıktısı; Aşama C'de onaysız uygulama kullanıcı kararı.)

(`scenes/bolumler/bolum_12.tscn`) Fizik hesapları `player.gd`, `kutu.gd`, `yayli_ziplatici.gd`, `gecit.gd`, `basinc_plakasi.gd` ve Bölüm 9–11 sahnelerinden okundu. Koşturulmadı; "ölçülecek" işaretli sayılar tahmindir.

## 0. Önce bilinmesi gereken genel bulgu: geçit altı park (röle) kısayolu
`gecit.gd` kapanırken altında oyuncu veya klon varsa geçidi durdurur (48 px açıklıkta kalır). Bu yüzden son turdaki oyuncu bir geçidin altında bekleyerek, kör kaydedilmiş tek bir klonun o geçitten geçmesini sağlayabilir. Klon girdiyi oynatır, konumu değil: kayıt dünyasında kapalı geçide yürümeye devam eden klon, son dünyada oyuncu altında dururken geçer. Geçitleri sırayla ve plakası önünde olan bölümlerde bu, "min klon" iddialarını düşürebilir.
- Bölüm 6 için analitik tahmin: PlakaA'da bekle, sonra sağa yürü kaydı, oyuncu geçit altında park eder, klon PlakaL'ye varır. Bu 1 klonla çözüm gibi görünüyor. **Test edilmedi; gozden-gecirici/test-yazari Bölüm 6, 7, 9, 10 için kontrol etmeli.**
- Bölüm 12 bu yüzden "ortak plaka" yapısıyla tasarlandı (bkz. §5).

## 1. Özet
- Yeni fikir: kutu **yaylı zıplatıcıyla** dikey olarak kata fırlatılır, tek yönlü rafa iner ve orada "basamak" olarak kalır. Oradan çıkış kutu üstünden tek yönlü ikinci rafa zıplayarak yapılır. İki geçit tek bir plakaya bağlıdır.
- Nesneler: kutu x1, yaylı zıplatıcı x1, tek yönlü x2, plaka x3, geçit x4, kapı. **YOK:** bant, lazer, şalter, asansör.
- `max_klon = 2` (tam 2 klon; en az 2 klon, bkz. §5).
- Zorluk: B11 aynı klon sayısı, ama 3 teknik üst üste (yarış geçidi + kutu fırlatma + kutu basamağı, pay 3,6 kare / 6,5 px) ve kutu geri alınamaz.

## 2. Sabitler (koddan)
Karakter 28x48, HIZ 300 (5 px/kare), zıplama tepesi 96,5 (kare ~100,9), g 1400. Kutu 40x40, itme 5 px/kare, katman 1+4. Zıplatıcı: sensör 60x12, 820 px/sn, ölçülen tepe 247 px (testte 240±15); karakter merkezi x0±44 içinde tetiklenir; kutu x0±50. Geçit 120 px/sn (2 px/kare), 20x200. Plaka 60x16 (kutuyu da algılar). Kare modeli (B11'den): R(K)=(820K-11,667K(K-1))/60 px: K=24→220,7; K=36→247 (tepe); K=47→222; K=54→181,5; havada ~71 kare.

## 3. Kat planı (yüzeyler: zemin 600, raf R 420, raf R2 ve Blok üstü 290)
```
y=0   ┌───────────────────────────── Tavan (y 0..140) ──────────────────────────────┐
y=140 │ TavanSol │ U koridoru (150 px)                                               │
      │ x0..480  │ R2 x480..600  |GA1| [PlakaB]      |GB|     |GA2|    [Kapı]        │
y=290 │ (y140..  │ ──R2(tek yönlü)─┬────────── Blok üstü (y=290) ─────────────────── │
      │  400)    │  boş "kovuk"    │                                                 │
y=400 ├──────────┤                 │ BLOK x600..1152, y290..600 (dolu)              │
      │ zemin    │ [kutu R üstünde]│                                                 │
y=420 │ koridoru │ ──R(tek yönlü)──┤  R x480..600                                    │
      │ (200 px) │                 │                                                 │
      │ [A]  O  [Kutu/PlakaK] |GK|     [Z]│                                         │
y=600 └─────────────────────────────────────────────────────────────────────────────┘
        40  110     200       380    560  600
```
- Zemin koridoru x 0..600, tavanı TavanSol alt kenarı y=400 (GK 400..600 tam kapatır, bitişik).
- x 480..600 aralığında üstte kovuk (R ve R2). R kovuğun yerden 180 px yükseğindeki cebidir, sağda Blok duvarı x=600, solda TavanSol duvarı x=480. Kutu R'den hiçbir yere düşemez.
- U koridoru yalnız R2 üstünden (kutu basamağı) ya da Blok üstünden erişilir. Kapı yalnız U'dadır.

## 4. Nesneler (merkez)
| Düğüm | Tür | Konum | Ayrıntı |
|---|---|---|---|
| Zemin | StaticBody2D | (576,620) | 1152x40 |
| Tavan | StaticBody2D | (576,70) | 1152x140 (y 0..140) |
| TavanSol | StaticBody2D | (240,270) | 480x260 (x 0..480, y 140..400) |
| Blok | StaticBody2D | (876,445) | 552x310 (x 600..1152, y 290..600) |
| Raf1 (R) | scenes/tek_yonlu.tscn | (540,426) | 120x12, üst y=420, x 480..600 |
| Raf2 (R2) | scenes/tek_yonlu.tscn | (540,296) | 120x12, üst y=290, x 480..600 |
| PlakaK | basinc_plakasi | (200,592) | 60x16, x 170..230; başlangıçta kutu üstünde; GecitK'yı açar |
| PlakaA | basinc_plakasi | (40,592) | 60x16, x 10..70; GecitA1 VE GecitA2'yi açar (ortak) |
| PlakaB | basinc_plakasi | (740,282) | 60x16, Blok üstü, x 710..770; GecitB'yi açar |
| Ziplatici | scenes/yayli_ziplatici.tscn | (560,594) | firlatma_hizi=820; yüzey y=600, bölge x 530..590 |
| GecitK | scenes/gecit.tscn | (380,500) | kayma_yonu=(0,-1), kayma_mesafe=100, hiz=120; tetikleyici=[../PlakaK]; kapalıyken y 400..600 |
| GecitA1 | scenes/gecit.tscn | (700,190) | aynı parametreler; tetikleyici=[../PlakaA]; y 90..290 (üstü Tavan içinde), x 690..710 |
| GecitB | scenes/gecit.tscn | (980,190) | tetikleyici=[../PlakaB], x 970..990 |
| GecitA2 | scenes/gecit.tscn | (1060,190) | tetikleyici=[../PlakaA], x 1050..1070 |
| Kapi | kapi.gd Area2D | (1112,266) | 36x48, x 1094..1130 |
| Kutu | scenes/kutu.tscn | (200,580) | zeminde, PlakaK üstünde |
| Oyuncu | oyuncu.tscn | (110,576) | |
| Bilgi | Label | (16,12)-(600,40) | |

Ağaç sırası: Zemin, Tavan, TavanSol, Blok, Raf1, Raf2, PlakaK, PlakaA, PlakaB, Ziplatici, GecitK, GecitA1, GecitB, GecitA2, Kapi, Kutu, Oyuncu, Bilgi (plaka/geçit karakterlerden önce, kutu Oyuncu'dan önce; B9 kalıbı). Her StaticBody2D'de `Gorsel` ColorRect. Başlangıç: tüm geçitler kapalı (GecitK, kutu plakada olduğundan ~50 karede açılır). Geçit sahnesi dönmeden/yeniden boyutlanmadan kullanılır (20x200).

Güvenlik payları:
- Kutu sol kenarı 180, oyuncu sağ kenarı 124: **56 px ≥ 40**.
- Kutu zıplatıcı tepesi: kutu üstü ~313, R2 alt yüzü 302 (11 px; R2 tek yönlü olduğundan çarpışma yok). Kutu tabanı tepede y=353 > R2 üst 290: R2'ye kutu çıkamaz.
- Asansör yok. Geçit üstü Tavan/TavanSol'a bitişik/içinde (üstten aşılamaz, B6 dersi).

## 5. Roller ve neden tam 2 klon
- **Y1:** PlakaA'ya yürüyüp sonsuza dek durur (GA1 ve GA2 açık kalır).
- **Y2:** kutuyu iter, GecitK'yı yarışla geçer, kutuyu zıplatıcıdan R'ye fırlatır, kendisi zıplatıcı + kutu basamağıyla U'ya çıkar, GA1'den geçip PlakaB'de durur (GB açık).
- **Oyuncu (son tur):** Y2'nin kurduğu düzende (kutu R'de, GK/GA/GB açık) çıkar ve kapıya yürür.

### Kısayol taraması (zorunlu; gozden-gecirici bağımsız kontrol eder)
| Deneme | Sonuç | Neden |
|---|---|---|
| Klonsuz | olmaz | PlakaA boş; GA1 kapalı. Oyuncu U'ya çıkabilir (kendi başına itip basamak yapar) ama GA1/GB/GA2 kapalı |
| Yalnız Y1 | olmaz | PlakaB boş: oyuncu PlakaB'de bekleyip GB'ye koşarsa plakadan ayrılıp GB sol yüzüne varış 34,4 kare > geçit 26 karede <48 px |
| Yalnız Y2 (Y1'siz) | olmaz | GA1 kapalı; Y2 GA1 önünde kalır |
| Oyuncu PlakaA'yı tutar (Y2 var) | olmaz | oyuncu PlakaA'dan ayrılınca GA1'e 450+ px (90 kare) |
| **Geçit altı park / röle** (bkz. §0), tek klon | olmaz | PlakaA GA2'ye (son geçit) kadar tutulmalı; oyuncu GA2'ye ancak GB'yi geçince varır, GB için PlakaB'de ayrı tutucu gerekir. Tek klon aynı anda PlakaA ve PlakaB'de olamaz; oyuncu GA2'ye GB'den önce park edemez |
| Kutu PlakaA'yı tutsun (sola it, klon tasarrufu) | olmaz | kutu R'de olmazsa U'ya çıkış yok (zıplatıcı en yüksek ayak 353 > 290; R'den R2 130 > 100,9). Tek kutu |
| Kutu basamak (zeminde) | olmaz | zemin kutusu üstü 560 + zıplama 96,5 = 463,5 > R üstü 420 (43,5 px kısa) |
| Zıplatıcıdan doğrudan U | olmaz | ayak tepesi 353 (en kötü +15 → 338) > R2 üstü 290; R2 üstü kutu olmadan 130 > 100,9 |
| Kutu geçit altına bırakıp açık tutmak | olmaz | kutu 40 px yer bırakır (<48): karakter geçemez; kutu zaten U'ya/GB'ye taşınamaz |
| Zıplatıcıyla kutuyu U'ya | olmaz | kutu yalnız dikey gider, R'de kalır (raf ve duvarlar) |
| Zıplatıcı + kutu üstünde yığma (oyuncu kutunun üstünde fırlar) | klon sayısını azaltmaz | taşıma ölçülmeli; bu yolla U'ya çıkılsa bile PlakaA ve PlakaB iki ayrı tutucu gerektirir |

Min klon = 2.

## 6. Çözüm (tuş kareleri tahminidir; testler "koşula kadar bekle")
**Tur 1 → Y1 (~0,6 sn):** `sol` ~14 kare (x 110→40), ~10 bekle, R. GA1/GA2 kare ~14'ten açılır (gap ≥48 ~kare 38, tam ~64).

**Tur 2 → Y2 (~300 kare):**
1. Başta ≥20 kare bekle (GK gap ≥ ~93 olsun; tavsiye 30).
2. `sag` basılı ~74 kare (x 110→477): kutuya ~kare s+11'de değer, iter; kutu x≈510–515 olunca Zıplatıcı bölgesine girer ve **dikey fırlar** (kutu merkezi sütun 510–515, ölçülecek). Y2 x≈478'de `sag`'ı bırakır.
3. Kutu R üstüne inene kadar bekle (kutu fırlatmadan ~54–55 kare sonra; "kutu y≈400 ve duruyor" koşulu). **Kutu havadayken Zıplatıcı'ya girme.**
4. `sag` ~8 kare: Zıplatıcı'ya girer (merkez >516), fırlar. Fırladıktan sonraki ilk 11 kare içinde en az 6 kare `sag` (kutu sütunundan sağa çık), K≥26'dan sonra `sol` ~8 kare, sonra bırak: kutu üstüne düşer (K≈47). Merkez x∈(478,546) inişte yeterli.
5. Kutu üstünden düz `zipla` (R2'ye iner, ~28 kare).
6. `sag` ~44 kare (x≈520→740): GA1 altından geçer, PlakaB'de durur; ~10 bekle, R.
GK yarışı: Y2 PlakaK'dan merkez 244'te ayrılır (sol kenar 230), GK'ya merkez 356'da girer: 22,4 kare sonra, gap 55 px ≥48: **pay ~3,6 kare**. Y2 ayrıldıktan sonra duraksamamalı.

**Tur 3 (R kapalı, "Klon: 2/2") → oyuncu (~360–400 kare):** Y2'yi L≥1 kare gecikmeyle izler: Y2'nin girdi dizisini L kare kaydırarak oynatır (L=0 çift itme riski, ölçülecek). Kutu R'ye indikten sonra Zıplatıcı'ya girer, kutu üstüne iner, `zipla` ile R2'ye çıkar, `sag` ile GA1, PlakaB (Y2 üstünde), GB, GA2'den geçip kapıya (x 1112). GB ve GA2 açık olmalı (PlakaB'ye Y2 basalı ≥24 kare).
Alternatif: PlakaK'da ≥46 kare dur, sonra kesintisiz `sag` (kendi başına GK'yı geçer; pay aynı ~3,6 kare).

Süreler ≈ 0,6 / 5 / 6–7 sn (hepsi ≤600 kare).

## 7. Beklenen zamanlama pencereleri (kare; ölçülecek)
- Y2 başlangıç gecikmesi s ≥ ~20 (alt sınır; üst sınır yok).
- GecitK yarışı: plakadan ayrıldıktan sonra kesintisiz yürüme; takılma payı ~3,6 kare (sonra gap <48 olur). Kutu için pay ~3,6 kare (gap ≥40).
- Zıplatıcı girişi: kutu R'ye indikten sonra (alt sınır ≈ kutu fırlatma + 55; üst sınır yok). Erken girişte kutu/karakter havada kesişir (kutu havada itilebilir, kutu konumu değişir).
- Fırlama sonrası: `sag` en geç ~5 kare içinde başlamalı ve ≥6 kare sürmeli (kutu sütunu temizlenir); `sol` K≥24'ten önce gelmemeli (kutu yan yüzüne çarpar, kutuyu iter).
- Kutu üstünden R2'ye zıplama: yükseklik 90 ≤ 96,5, **pay 6,5 px**; yüzey üstünde kalma penceresi ~11 kare.
- PlakaB tutucusu: GB'nin açılması için ≥24 kare önce basılı olmalı; son tur oyuncusu GB'ye PlakaB'den ≥24 kare sonra varmalı.

## 8. Atlanamazlık hesapları
- Zeminden R: 180 > 100,9; kutu (40) ile 140,9 < 180.
- R'den R2: 130 > 100,9; kutu üstünden 90 ≤ 96,5 (pay 6,5).
- Zıplatıcıdan R2: tepede ayak y=353 (≤338 en kötü) > 290 (63/48 px kısa).
- Blok yan yüzü x=600 (y 290..600) ve TavanSol x=480 (y 140..400) dikey; kovuğun üstü Tavan.
- U koridoru 150 px: ceiling zıplama tepesi baş y 146 ≥ 140; geçitler tam yükseklikte (90..290, üstü Tavan içinde).
- PlakaB→GB: ayrılma merkezi 784, GB giriş merkezi 956 → 34,4 kare > 26 (≥8,4 kare pay). PlakaA→GA1/GA2: yüzlerce px.
- PlakaK→GK: 22,4 kare giriş (pay 3,6): yarışılabilir ama yalnızca kesintisiz.

## 9. Kilitlenme analizi ("Baştan başla" ile giderilir)
1. Kutu sola itilip PlakaA/duvara gider: geri çekilemez; R'ye ulaşmaz, U erişilmez.
2. Oyuncu kutuyu sağdan zıplayıp aşıp sola iter: aynısı.
3. Kutu GecitK altında kalır (kutu 40 px, gap <48 oldu): geçit kutu üstünde durur, kutu ve itici geçemez.
4. Kutu R'de iken sola/sağa itilir: R duvarlarıyla sınırlı (480..600), basamak olmayı sürdürür. **Kilitlenme değildir**; Zıplatıcı sütunu değişebilir (inen karakterler x 546+'ya inmeli).
5. Y2 kaydı Zıplatıcı'ya kutu havadayken girer: kutu/karakter kesişir, kutu konumu kayar.
6. Y1 veya Y2'nin kaydı hatalı: "Baştan başla".
Asansör ve lazer olmadığından "asansör altında klon" ve ölüm kilitlenmeleri yok. Klon GecitK altında biterse geçit 48 px'te kalır (zararsız).

## 10. Başarısızlık senaryoları (test-yazarı için)
1. Klonsuz: GA1'de durur (kapalı).
2. Yalnız Y1: GB kapalı, bitmez.
3. Yalnız Y2 (Y1 olmadan): GA1 önünde kalır.
4. Y2 s<20: GK Y2 yürürken kapanır, kutu geçmez.
5. Y2 kutu inmeden Zıplatıcı'ya girer: kutu/karakter çarpışması, kutu kayar (R'ye inse de konumu değişir).
6. Y2 `sag` ilk ~5 karede basılmaz: karakter kutunun altında kalır (baş çarpar), düşer, yeniden fırlar.
7. Oyuncu PlakaB'den GB'ye koşar: 34,4 kare > 26 → bölüm bitmez.
8. R'den R2'ye kutusuz zıplama: ulaşılamaz.
9. R3'te üçüncü R: klon kaydetmez (max_klon=2).

## 11. Riskler / ölçülecekler
- Kutu iniş sütunu (merkez 510–515) ve R'ye iniş kare numarası.
- GK yarışı payı (3,6 kare) ve kutu+karakterin birlikte altından geçişi.
- Kutuya "iniş" sırasında kutu hâlâ düşüyorsa karakterin yan çarpışması (kutu kayması).
- Kutu üstünden R2 zıplaması (pay 6,5 px, R2 tek yönlü margin 4).
- Zıplatıcı + kutu üstünde taşıma (platform hızı): kutu karakteri taşıyor mu? Taşıyorsa yığma yolu ölçülmeli.
- GecitA1/A2 altında park eden karakterin geçidi 48 px'te tutması ve başka karakterin geçmesi (touching, margin).
- Çift itme (L=0): `it()` iki kez çağrılırsa kutu 10 px/kare olabilir.

## 12. Harita
`{"yol": "res://scenes/bolumler/bolum_12.tscn", "konum": Vector2(1030, 230), "onceki": "res://scenes/bolumler/bolum_11.tscn"}`.

## 13. Bölüm 13 ile çakışma
- B12 kullanır: kutu (zıplatıcı + tek yönlü raf + basamak), zıplatıcı, tek yönlü x2, geçit x4 (ortak plaka), plaka x3, kapı.
- B12 kullanmaz: bant, lazer, şalter, asansör. B13 (bant + zıplatıcı + şalter + lazer) bunları serbestçe kullanabilir.
- B13'te tekrarlanmaması önerilen: "kutuyu zıplatıcıyla raf kovuğuna fırlat ve basamak yap", "ortak plaka iki geçit", "geçit yarışı P→G ≈ 22 kare". B13'te zıplatıcı karakter (havada) için kullanılabilir, kutuyu fırlatmasın.

## 14. Karar gerektiren / geri dönmesi zor noktalar
1. **(Bölüm geneli, §0) Geçit altı park/röle kısayolu.** Önceki bölümlerin "min klon" iddialarını etkileyebilir; kullanıcı kararı gerekir (kabul mü, geçit kuralı mı değişsin mi, bölümler yeniden mi sayılsın).
2. **Kutu R'ye çıkınca geri alınamaz** (oyun içi kalıcı; çözümün parçası). "Baştan başla" yeterli ama oyuncu için sert. Alternatif: kutuya R'den alt kata inme yolu eklemek (yeni tasarım).
3. Basamak payı 6,5 px (R2 üstü 290, kutu üstü 380). Daha rahat istenirse R2 üstü 294'e çekilir (pay 10,5; R'den 126 > 100,9 hâlâ güvenli). Kolay geri alınır.
4. `max_klon = 2` (3'e çıkarmak istenirse PlakaB için ek geçit zinciri gerekir).
5. Ortak plaka (PlakaA iki geçit) görsel okunabilirlik: grafik katmanı bağlantıyı belli etmeli.
6. Geçit görünümü: 20x200 geçit Tavan içine 50 px gömülü; yeni görsel sorun çıkarabilir (B10 ile aynı kalıp, sorun beklenmez).
