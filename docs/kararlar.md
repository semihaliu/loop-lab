# Tasarım Kararları

## 2026-10-13 — Proje kurulumu ve oyuncu hareketi

- **Motor / dil:** Godot 4 (GDScript), 2D.
- **Sabit fizik karesi:** `physics_ticks_per_second = 60`, tüm mantık `_physics_process` içinde. Gerekçe: klon tekrarının deterministik olması için kare sayısı sabit olmalı.
- **Yerçekimi sabiti kodda:** `ProjectSettings` yerine `player.gd` içinde sabit. Gerekçe: proje ayarı değişirse kayıtlı turlar bozulmasın.
- **Girdi / hareket ayrımı:** `girdi_al()` klavyeyi okur, `hareket_uygula(girdi, delta)` hareketi uygular. Gerekçe: klonlar aynı hareket kodunu kayıtlı girdiyle çalıştıracak, böylece "klon gerçek karakter gibi davranır" kuralı doğal olarak sağlanır.
- **Girdi eşlemeleri:** `sol` (←/A), `sag` (→/D), `zipla` (Boşluk/↑/W).
- **Hareket modeli:** anlık yatay hız (ivmelenme yok), sabit zıplama hızı. Gerekçe: en basit ve en öngörülebilir model; bulmaca için hassas kontrol yeterli. Dezavantaj: "his" daha sert; gerekirse sonra yumuşatılır.

## 2026-10-13 — Girdi kaydı ve klon geri oynatma

Kullanıcı seçimleri (seçenekler artı/eksileriyle sunuldu):
- **Kayıt formatı: kare başına girdi.** Her fizik karesi için `{yon, zipla}` dizide tutulur, klon karede `i` kayıt[i]'yi okur. Artı: basit, determinizm kolay doğrulanır. Eksi: bellek tur uzunluğuyla büyür (ölçek için önemsiz).
- **Sıfırlama: sahneyi yeniden yükle.** Kayıtlar `Kayitlar` autoload'unda saklanır. Artı: dünya her turda kesin başlangıç durumunda, "unutulmuş durum" hatası olmaz. Eksi: kayıtların sahne dışında yaşaması gerekir.
- **Tur sonu: oyuncu R'ye basınca.** Artı: zaman baskısı yok, bulmaca için doğal. Eksi: kayıt uzunluğu oyuncuya bağlı.
- **Klon yapısı: aynı sahne/betik, girdi kaynağı farklı.** `oyuncu.tscn` hem oyuncu hem klon için kullanılır; `klon` bayrağı girdiyi klavye yerine kayıttan okutur. Artı: "klon hayalet değil" kuralı tek kod yoluyla garanti.

Uygulama ayrıntıları:
- Kayıt bittiğinde klon boş girdiyle **yerinde bekler** (yerçekimi ve fizik uygulanmaya devam eder).
- Klonlar sahneye tur sırasıyla eklenir; ağaç sırası sabit olduğundan simülasyon sırası her turda aynıdır.

**Karar (kesin): oyuncu ve klonlar birbirini engellemez.** Hepsi yalnızca dünya nesneleriyle (zemin, asansör, kapı) çarpışır. Katmanlar: 1 = dünya, 2 = oyuncu, 3 = klon; oyuncu ve klonların maskesi yalnızca katman 1'dir. Asansör ve kapı eklendiğinde katman 1'de olmalıdır.
- Gerekçe: tüm klonlar ve oyuncu aynı noktada doğar; çarpışma olsaydı itişme/titreme çıkar, bu da simülasyonun deterministikliğini ve öngörülebilirliğini bozardı. Ayrıca bir klonun oyuncuyu kazara engellemesi bulmacayı tur sayısına bağlı, sinir bozucu hale getirirdi.
- "Klonlar gerçek karakter gibi davranır" kuralı korunur: klon dünyayla (asansör, kapı, zemin) oyuncuyla aynı kuralları paylaşır; asansör yukarıdaysa binemez. Tek istisna, karakterlerin birbirine fiziksel olarak dokunmamasıdır.
- Eksi (bilerek kabul edildi): klonun üstüne çıkılamaz, klon kapıyı/oyuncuyu fiziksel olarak tıkayamaz.

## 2026-10-13 — Basınç plakası, asansör, kapı, sonuç ekranı ve menü

Kullanıcı seçimleri:
- **Kapı = bölüm hedefi, yalnız canlı oyuncu.** Canlı oyuncu kapıya değince kapı açılır ve bölüm biter; klonlar kapıdan geçse de bir şey olmaz. Artı: CLAUDE.md'deki "hedef kapıya ulaşmak" ile birebir uyumlu, klonlar yardımcı kalır. Eksi: klon kapıya varınca görsel geri bildirim yok. Kapı katı değildir (çarpışma yok), yalnızca alan algılar (maske: katman 2).
- **Bölüm sonu:** simülasyon durur (`get_tree().paused`), sonuç ekranı çıkar: süre, tur sayısı, "Tekrar oyna", "Menüye dön". Süre **gerçek saatten değil**, bölümü bitiren turda geçen fizik karesinden hesaplanır (`kare / physics_ticks_per_second`); gerekçe: determinizm ve tekrarlanabilir sonuç.
- **Menü:** basit ana menü (Oyna, Çık). Bölüm seçme ekranı sonraya bırakıldı.
- **Bölümler ayrı sahne:** `scenes/bolumler/bolum_N.tscn`, hepsi `scripts/bolum.gd`'yi paylaşır. Yeni bölüm eklemek = yeni sahne (içinde `Oyuncu`, `Kapi`, `Bilgi` düğümleri olmalı). Menüdeki `ILK_BOLUM` sabiti şimdilik tek bölümü gösterir; bölüm seçimi eklenince burası değişecek.

Uygulama kararları (tasarım seçeneği gerektirmeyen):
- **Plaka durumu çakışmadan okunur** (`has_overlapping_bodies`), ayrı bir durum değişkeni tutulmaz. Oyuncu veya klon (katman 2 ve 3) basar. Kayıt bitince klon yerinde beklediği için plakada kalmışsa plakayı basılı tutmaya devam eder (bulmacanın temel mekaniği).
- **Asansör sabit hızla hareket eder** (`AnimatableBody2D`, 120 px/sn, 180 px yükseklik): plaka basılıyken yukarı hedefe, değilken aşağı hedefe `move_toward`. Anında ışınlanma yok, gerçek bir platform gibi taşır; klon yukarıdayken binemez, aşağıda kalır.
- **Güncelleme sırası:** sahne ağacında plaka ve asansör karakterlerden önce durur; her karede önce dünya, sonra oyuncu ve klonlar güncellenir (sıra sabit = deterministik).
- **Tur ve sıfırlama:** `Kayitlar.sifirla()` bölüm bitince "Tekrar oyna" veya "Menüye dön" ile ve menüden "Oyna" ile çağrılır; yeni oyun temiz klon listesiyle başlar.

## 2026-10-14 — Sınır duvarları, asansör güvenliği, ekran butonları, klon sınırı

Kullanıcıyla netleştirilen kararlar:
- **Sınır duvarları (sol, sağ, üst).** `bolum.gd` viewport'un gerçek boyutundan (`get_viewport_rect()`) üç görünmez `StaticBody2D` duvarı kurar (katman 1, kalınlık 100 px, ekran dışında). Alt sınır zaten zemin. Gerekçe: oyuncu ve klon dünyadan düşüp kaybolmasın, asansörle çıkan karakter ekranın üstüne taşmasın. Boyut koda sabit yazılmaz; pencere/viewport ayarı değişirse duvarlar uyar. Tavan kontrolü (Bölüm 1): asansör üst konumunda yüzey y=420, karakter boyu 48, kafa y=372; tavan y=0 → 372 px boşluk, sıkışma yok (testle doğrulanır).
- **Asansör altında biri varken durur.** İnerken, asansörün hemen altında o karede kat edeceği mesafe (+2 px pay) kadar bölgede oyuncu/klon (katman 2-3) varsa asansör bekler; karakter çekilince inmeye devam eder. Üstünde duran karakter bu bölgeye girmez, normal taşınır. Gerekçe: ezme veya içinden geçme olmasın, klon kaydı tekrarlandığında sonuç aynı kalsın. Sorgu sabit fizik karesinde, rastgelelik olmadan yapılır; güncelleme sırası değişmedi. Eksi: bir klon asansörün altında kalırsa asansör inemez (bulmaca tasarımında dikkate alınmalı).
- **Ekran butonları (sağ üst, `CanvasLayer`).** Ev ikonu: `Kayitlar.sifirla()` + ana menü. **[Güncellendi: aşağıdaki "tam sıfırlama" kararı bu davranışın yerini aldı.]** Yeniden başlat ikonu (eski davranış): sahneyi yeniden yükler, `Kayitlar` değişmez, tur sayısı artmaz, o turun girdisi atılır (kayıt oyuncu düğümünde tutulduğu için kendiliğinden gider). Butonlar `FOCUS_NONE`, böylece Boşluk (zıpla) butona basmaz. Sonuç ekranı açılınca butonlar gizlenir ve devre dışı kalır. İkonlar `assets/ikonlar/` altında SVG; tooltip'ler "Ana menü" ve "Turu yeniden başlat". Butonlar `scenes/ekran_butonlari.tscn` olarak `bolum.gd` tarafından eklenir; yeni bölüm sahnesinde ek iş gerekmez.
- **Bölüm başına klon sınırı.** `bolum.gd` içinde `@export var max_klon: int = 2`; her bölüm sahnesi kendi değerini ayarlar (Bölüm 1 = 2). Ekranda "Klon: X/Y". Sınıra ulaşınca R (turu bitir) çalışmaz ve "Klon hakkı bitti" yazar; o turu yalnızca "Baştan başla" butonuyla (tam sıfırlama) yeniden denemek mümkündür. Gerekçe: bulmacayı sınırlı kaynakla çözmeye zorlamak, sınırsız klonla her bölümün kaba kuvvetle geçilmesini engellemek.
- **Tur süresi bilinçli olarak sınırsız.** Bir turun uzunluğuna üst sınır konmadı; oyuncu istediği kadar bekleyebilir. Gerekçe: zaman baskısı bulmaca düşünmeyi bozar, ayrıca süre sınırı kayıt boyutunu ve test senaryolarını gereksiz karmaşıklaştırırdı. Süre yalnızca sonuç ekranında bilgi olarak gösterilir (fizik karesinden hesaplanır).

Test notu: Godot `--headless --script` modunda kök pencere 64x64 açıldığı için test betiği viewport'u proje ayarındaki boyuta (1152x648) içerik ölçeğiyle sabitler; oyun kodu bundan etkilenmez.

## 2026-10-14 — Yeniden başlat butonu tam sıfırlamaya çevrildi (kullanıcı kararı)

Dönen ok butonu artık **"Baştan başla"**: `Kayitlar.sifirla()` çağırır (tüm klon kayıtları silinir, tur sayısı 1'e döner), ardından mevcut bölüm sahnesi yeniden yüklenir. Ev butonu değişmedi (`Kayitlar.sifirla()` + ana menü). Oyun içinde "bu turu kaydetmeden yeniden başlat" yolu artık yoktur.

- **Eski "bu turu kaydetmeden yeniden başlat" kararının yerini alır** (2026-10-14, "Ekran butonları" kararı): o davranışta klon kayıtları korunuyordu.
- Gerekçe: önceki davranışta yanlış kaydedilmiş klonlar oyuncuyu kilitliyordu. Örnek: "Klon: 2/2" ve "Klon hakkı bitti" durumunda, kayıtlı klonlar bölümü çözmeye yetmiyorsa tek çıkış ana menüye dönmekti. Tam sıfırlama ile oyuncu her zaman bölümü baştan deneyebilir.
- Eksi (bilerek kabul edildi): bir turda hata yapınca önceki iyi turlar da gider; oyuncu en baştan başlamak zorundadır.
- Butonun konumu, `FOCUS_NONE` ayarı ve sonuç ekranında gizlenmesi aynen korundu; tooltip "Baştan başla". Dosya/düğüm adları (`yeniden.svg`, `YenidenDugmesi`) değişmedi.

## 2026-10-14 — Şalter ve geçit (kullanıcı kararı; "başka mekanik ekleme" kuralının istisnası)

Kullanıcı iki yeni mekanik ve kapsamlarını açıkça onayladı.

**Şalter (`scripts/salter.gd`, `scenes/salter.tscn`) — itilerek çalışır.**
- Yere sabit, iki konumlu (sol / sağ), başlangıç konumu `@export baslangic_sagda` (varsayılan sol). Konum **kalıcıdır**: karakter çekilip gidince yerinde kalır (basınç plakası gibi üstünde durmak gerekmez).
- Etkileşim tuşu (E vb.) **reddedildi**: yeni girdi eşlemesi eklenmedi, kayıt formatı `{yon, zipla}` **değişmedi**. Gerekçe: determinizm ve klonların oyuncuyla aynı kodu kullanması; ayrı bir "etkileşim" girdisi kayıt formatını, test betiklerini ve klon davranışını karmaşıklaştırırdı.
- Düzen: iki `Area2D` (sol yarı, sağ yarı; maske katman 2 ve 3). Şalter katı değildir, karakter içinden geçer.
- Kural: solda iken sol yarıdaki karakter `yon > 0` verirse sağa; sağda iken sağ yarıdaki karakter `yon < 0` verirse sola geçer. Bakılan şey hız değil, o karede uygulanacak girdidir (`girdi_al()`; oyuncuda klavye, klonda kayıt: aynı kod yolu).
- Birden fazla karakter: "herhangi biri tetiklerse bir kez geçer" kuralı seçildi. Kare başına en fazla bir geçiş olur ve sonuç karakter sırasından bağımsızdır (alternatif "ağaç sırasıyla tek karakter" daha az öngörülebilirdi).
- Güncelleme sırası: şalter ağaçta karakterlerden önce durur. Karakterler `kare` indeksini kendi `_physics_process`'lerinin sonunda artırdığı için, şalter kendi karesinde `girdi_al()` ile o karede uygulanacak girdiyi okur: **bir kare gecikme oluşmaz**. Yalnızca çakışma bilgisi bir önceki fizik adımından gelir; bu da her çalıştırmada aynı olduğundan deterministiktir.
- Her tur sahne yeniden yüklendiğinden şalter başlangıç konumunda başlar; klonlar tekrar iter. Testle doğrulandı: klon şalteri oyuncuyla aynı karede çevirir, 100 tekrarda sapma 0.0000 px.
- **Bilinçli eksi:** şalterin içinden geçerek yürümek şalteri çevirir (soldan sağa yürüyen karakter geçerken çevirir; devam ederken tekrar çevirmez). Şalterin üzerinden zıplamak çevirmez. Bulmaca tasarımında dikkate alınmalı.

**Geçit (`scripts/gecit.gd`, `scenes/gecit.tscn`).**
- Hedef kapısı olan `Kapi`'dan ayrı bir nesnedir (adı bu yüzden "Gecit"); `AnimatableBody2D`, katman 1, katı. `kayma_yonu` ve `kayma_mesafe` ile duvarın içine kayarak açılır; sabit hız (`move_toward`), ışınlanma yok.
- Tetikleyiciler (`tetikleyici_yollari`): plaka aktif = basılı, şalter aktif = `acik_taraf_sag` konumunda (varsayılan sağ). **VEYA mantığı:** herhangi biri aktifse açılır, hiçbiri aktif değilse kapanır. Gerekçe: tek kural, öngörülebilir; VE mantığı gerekirse sonradan eklenir.
- **Durma kuralı:** kapanırken kapanacağı bölgede oyuncu/klon varsa geçit durur (asansördeki kural), çıkınca kapanmaya devam eder. Ezme ve içinden geçme olmaz.
- Ağaç sırası: plaka/şalterden sonra, karakterlerden önce.
- Test sahnesi `tests/sahneler/gecit_test.tscn`; oyun bölümlerine henüz yerleştirilmedi.

**Bilinen kısıt (bilinçli kabul):** bir klon asansörün altında kalırsa asansör inemez (klon kayıt bitince yerinde beklediği için sürekli orada kalır). Bölüm tasarlanırken klonun asansör altında bitmemesine dikkat edilmeli.

## 2026-10-14 — Bölüm 2 tasarımı (`scenes/bolumler/bolum_2.tscn`, `max_klon = 2`)

Kullanıcı onaylı tasarım: 3 katlı, koridorlu, yılan gibi tek ekranlık (1152x648) harita. Nesneler: basınç plakası, asansör, şalter, geçit, hedef kapısı; yeni mekanik yok. Menü şimdilik Bölüm 1'de kalır (bölüm seçimi ayrı adım).

**Ölçüler (oyuncu değerlerinden hesaplandı):** yatay hız 300 px/sn, zıplama tepesi ≈ 96 px, karakter 28x48. Koridor yüksekliği **100 px**, kat arası döşeme 60 px (tavan döşemesi 70 px). Zemin yüzeyleri F1 y=600, F2 y=440, F3 y=280. Çözüm hiçbir yerde zıplama gerektirmez; 100 px koridorda tavana 52 px pay kaldığı için şalterin veya kapalı geçidin üstünden zıplayarak geçmek mümkün değildir.

**Akış:** F1 sağa → E1 ile F2'ye → F2 sola → E2 ile F3'e → F3 sağa → sağ uçtaki boşluktan düşüp F2'deki kapalı cebe → kapı.

**Nesneler:** P1 plaka (F1, x=300) → E1 asansör (F1→F2, x 900..1020). P2 plaka (F2, x=130, E2'nin solunda ölü uçta) → E2 asansör (F2→F3, x 300..420). Şalter S (F3, x=560, yürüme yolunun üstünde). Geçit G (F3, x=800, koridoru zeminden tavana kapatır; 70 px yukarı kayıp tavan döşemesine gizlenir, altında 70 px boşluk kalır; tek tetikleyici S, sağ konum). Kapı: F2'nin sağ ucundaki cepte (x≈1090); cebin sol duvarı (x 1040..1050) F2 koridorunu zeminden tavana kapatır, cebe yalnız F3'teki boşluktan düşerek girilir.

**Çözüm sırası (max_klon = 2):**
1. **Tur 1 → klon A (P1'i tutar):** oyuncu 200 kare bekler, P1'e yürür, R. A sonra P1'de kalır.
2. **Tur 2 → klon B (P2'yi tutar):** A ~231. karede P1'e basar, E1 yükselir. Oyuncu E1'e biner (x=960), yükselince F2'de sola yürür, E2'nin üstünden geçip P2'ye çıkar, R.
3. **Tur 3 (R kapalı, "Klon: 2/2"):** oyuncu E1'e biner, A'nın basmasıyla çıkar; F2'de sola yürüyüp E2'nin üstünde durur; B P2'ye basınca E2 oyuncuyla F3'e çıkar; oyuncu sağa yürür, S'yi iter, G açılır, altından geçer, boşluktan düşer, kapıya değer.

**Şalter durumu:** başta sol. Tur 3'te canlı oyuncu F3'te soldan sağa yürürken tek geçişte S sağa geçer (G açık). A, B ve önceki turlardaki oyuncu F3'e hiç çıkmadığı için S'ye yalnızca son turda canlı oyuncu dokunur; yanlışlıkla çevrilme riski yok. Oyuncu S'nin içinden sola geri yürürse S sola döner ve G kapanır (kural gereği; testle doğrulandı).

**Klonlar asansör altında kilitlenmez:** A F1'de x=300'de (E1 boşluğu 900..1020), B F2'de x=130'da (E2 boşluğu 300..420) bekler; ikisi de bir asansörün altında değildir. Asansörler B/oyuncu bindikten sonra yükselir ve plakalar bırakılmadığı için bir daha inmez.

**Gerekçe:**
- Her nesne çözümde zorunlu: P1/E1 ve P2/E2 klon (A ve B) olmadan yükselmez; S olmadan G açılmaz. İki klon şart, tek klonla bölüm geçilemez (testle doğrulandı).
- E2'yi tutan plakayı E2'nin solunda ölü uca koymak, B'nin E2'nin üstünden yürüyüp gitmesini ve oyuncunun E2'de ona kendiliğinden beklemesini sağlar; ekstra gecikme gerekmez.
- Cep duvarı kapı cebini F2 koridorundan ayırır; böylece düşme boşluğu (iniş) zorunlu yoldur.
- Tüm çözüm zıplamasız yürüyüşle yapılır; zorluk zamanlama ve sıralamadadır.

**Testler:** çözüm; klon A yok, klon B yok, A çok erken basıyor (bölüm bitmemeli); kapalı geçit atlanamaz; cebe zıplayarak girilemez; S'den sola geri yürümek G'yi kapatır.

## 2026-10-14 — Bölüm seçme ekranı ve "Sonraki bölüm" butonu (kullanıcı kararı)

- **Bölüm listesi tek yerde:** `scripts/bolumler_listesi.gd` (`BolumListesi`; sonradan haritaya çevrildi, aşağıya bak). Yeni bölüm eklemek = listeye bir satır; menü ve sonuç ekranı buradan okur. Menüdeki `ILK_BOLUM` sabiti kaldırıldı.
- **Bölüm seçme ekranı:** Ana menüde "Oyna" artık bölüm seçme ekranını açar: listedeki her bölüm için bir buton ("Bölüm 1", "Bölüm 2", ...) ve "Geri". Butonlar listeden kodla üretilir. Bölüme girerken `Kayitlar.sifirla()` çağrılır, her giriş temiz klon listesiyle başlar.
- **Sonuç ekranı:** "Sonraki bölüm" butonu `Kayitlar.sifirla()` yapıp listedeki sonraki bölümü yükler; son bölümde (ve listede olmayan sahnelerde) gizlidir. "Tekrar oyna" ve "Menüye dön" aynen kaldı.
- **Kilit yok, tüm bölümler baştan açık.** Gerekçe: kayıt dosyası gerektirmez (ilerleme kalıcı saklanmaz, `Kayitlar` yalnızca bellekte), rapor sırasında ve testlerde herhangi bir bölüme doğrudan girmek kolay. Eksi (bilerek kabul edildi): ilerleme hissi yok; oyuncu bölümleri sırayla açma hissini yaşamaz.

## 2026-10-14 — Bölüm seçme ekranı ilerleme haritasına çevrildi (kullanıcı kararı)

Ana menüde "Oyna" artık `scenes/harita.tscn` (betik: `scripts/harita.gd`) ekranını açar; önceki buton listesi kaldırıldı. Bu, aynı günün "Bölüm seçme ekranı" kararındaki buton listesinin yerini alır; "Sonraki bölüm" ve kilit yok kararları aynen geçerlidir.

- **Veri odaklı düğüm yapısı:** `BolumListesi.BOLUMLER` her bölüm için sahne yolu (`yol`), harita konumu (`konum`, düğüm merkezi) ve bağlı olduğu önceki bölüm (`onceki`, başlangıç düğümü için boş) tutar. Şimdilik Bölüm 1 başlangıç düğümü, Bölüm 2 ona bağlıdır. Yeni bölüm eklemek = listeye bir kayıt; harita, sonuç ekranı ve menü kodu değişmez. Çizgiler `onceki` alanından üretilir, konumlar listeden ayarlanır (1152x648 içinde kalmalı; testle kontrol edilir).
- **Harita:** düğümler listedeki konumlara yerleşir, bağlı düğümler çizgiyle birleşir, düğümün içinde bölüm numarası yazar. Tüm düğümler tıklanabilir; üzerine gelince düğüm vurgulanır ve altında "Bölüm N" etiketi çıkar. Düğüme basınca `Kayitlar.sifirla()` ve o bölüm yüklenir. Sol altta "Geri" ana menüye döner. Düğümler ve "Geri" `FOCUS_NONE`.
- **Kilit ve kayıt yok:** ilerleme kalıcı saklanmaz, tüm düğümler baştan açıktır. Gerekçe: kayıt dosyası gerektirmez, rapor ve testlerde herhangi bir bölüme doğrudan girmek kolay. Eksi (bilerek kabul edildi): ilerleme hissi yok.
- **Görseller koddan çizildi:** düğümler yuvarlak köşeli `StyleBoxFlat` düğmeleri, bağlantılar `draw_line` ile çizilir, renkler kodda tanımlıdır. Başka oyunların görselleri, ikonları veya haritaları **kullanılmadı ve kopyalanmadı**; yalnızca "bölümleri bağlı düğümler olarak gösteren harita" genel fikri kullanıldı.

## 2026-10-14 — Harita ekranı: çizgi hatası düzeltmesi ve görünüm iyileştirmesi

**Hata:** Bölüm 1 ile Bölüm 2 düğümleri arasındaki bağlantı çizgisi ekranda görünmüyordu.
- **Kök neden (çizim sırası):** Çizgiler harita kök düğümünün `_draw()` işlevinde çiziliyordu. Bir `CanvasItem` kendi çizimini **çocuklarından önce** yapar; tam ekran `Arkaplan` (`ColorRect`) kökün çocuğu olduğu için çizgilerin üstüne çiziliyordu ve onları örtüyordu. Bağlantı verisi doğruydu (boş değildi), çizgi gerçekten çiziliyordu, yalnızca arka planın altında kalıyordu.
- **Testler neden yakalamadı:** Harita testleri yalnızca veriyi (`baglantilar` dizisinin boyutunu) ve düğüm konumlarını sınıyordu; piksel/çizim sırasını sınamıyordu. Headless çalıştırmada ekran görüntüsü alınamaz, bu yüzden "veri doğru ama görünmez" sınıfındaki hata geçti.
- **Düzeltme:** Çizgiler artık ayrı `Line2D` düğümleridir (`Baglantilar` altında) ve kardeş sırası Arkaplan < Baglantilar < Dugumler olarak sabittir. Çizgi uçları düğüm merkezinden değil altıgenin kenarından (merkezden yarıçap kadar uzakta) başlar. Yeni test (`Harita bağlantı çizgisi`) gerçek `Line2D` nesnelerini, uçlarının iki düğümün konumlarına göre doğru yerde olduğunu ve çizim sırasını doğrular.
- **Gerçek çıktı kontrolü:** Düzeltme, `--write-movie` ile gerçek bir kare üretilip bakılarak da doğrulandı (çizgi görünür, numaralar okunur).

**Görünüm (hepsi koddan çizildi, harici görsel/ikon kullanılmadı):**
- Arka plan: koyu dikey degrade + ince nokta ızgarası (`scripts/harita_arkaplan.gd`).
- Bağlantı: iki katmanlı (koyu dış 12 px + açık iç 7 px), yuvarlak uçlu `Line2D`.
- Düğümler: altıgen (`scripts/harita_dugumu.gd`), koyu dış kenar, renkli iç dolgu, gölge, üst yarıda hafif parlak şerit, büyük koyu hatlı numara. Başlangıç düğümü turuncu, diğerleri mavi. Numara `Button` metninden değil `_draw` içinde çizilir (düğme metni altıgenin altında kalıyordu; metin yine `Button.text` olarak durur).
- Hover: düğüm hafif büyür (tween, 1,12x), parlar, "Bölüm N" etiketi çıkar, imleç el işaretine döner.
- Başlık: büyük font, gölge, altında ince ayraç. "< Geri": sol altta, çerçeveli, hover'da vurgulu, `FOCUS_NONE`.
- Bölüm 1 ve 2 konumları dengelendi: (330, 400) ve (820, 270). Düğüm sayısı artınca konumlar listeden ayarlanır, ekran kodu değişmez.


## 2026-10-14 — 5 rollü ajan yapısı (kullanıcı kararı)

Yeni bölüm üretimi için `.claude/agents/` altında 5 alt ajan tanımlandı: `tasarimci`, `uygulayici`, `test-yazari`, `gozden-gecirici`, `grafik`. Kullanımı kullanıcının açık kararıdır; yalnızca yeni bölüm üretirken kullanılır, küçük düzeltmeler tek oturumda yapılır.

- **Yetki sınırları:** `tasarimci` ve `gozden-gecirici` salt okunurdur (gözden geçirici yalnızca salt okunur Bash kullanır). Yazma yetkisi `uygulayici`, `test-yazari` ve `grafik`'tedir; her birinin alanı talimatında sınırlıdır (uygulayıcı teste, grafik oyun mantığına dokunmaz). Gerekçe: tasarlayan ve denetleyen kendi işini sessizce düzeltemesin.
- **Dosya üzerinden devir:** ajanlar bağlamı sıfırdan başlatır, bilgi `docs/devir/` dosyalarıyla taşınır (`bolum_N_taslak.md`). Akış: tasarımcı → kullanıcı onayı → uygulayıcı ve test yazarı → gözden geçirici → grafik. Salt okunur ajanların çıktısını ana oturum kaydeder.
- **Test yazarının uygulayıcıdan bağımsızlığı:** testler uygulayıcının koduna değil taslağın iddialarına göre yazılır; test yazarı kodu düzeltmez. Gerekçe: harita çizgisi hatası testten kaçtı (testler yalnızca veriyi sınıyordu, çizim sırasını sınamıyordu); kodu yazanla aynı kişi test de yazarsa aynı kör noktayı paylaşır. Zayıf "doğrudan çağırdım" testleri yerine gerçek buton/sinyal/sahne yolu kullanılır.
- **Grafik ajanı yalnızca görünüm değiştirir:** çarpışma şekilleri, boyutlar, konumlar, fizik, girdi ve oyun mantığına dokunmaz; mekanik sabitlendikten sonra çalışır, testler kırılırsa değişikliği geri alır. Harici oyunların görselleri kopyalanmaz.

## 2026-10-14 — Üretim dalı: Lazer ve tek yönlü platform (kullanıcı kararı)

Kullanıcı "başka mekanik ekleme" kuralının istisnası olarak lazer ve en fazla 2 basit yeni nesneyi açıkça onayladı. Tema "terk edilmiş zaman laboratuvarı" sabittir. Eklenenler: **lazer** ve **tek yönlü platform** (üçüncü bir nesne eklenmedi).

**Lazer** (`scenes/lazer.tscn`, `scripts/lazer.gd`): sabit yayıcı + `Area2D` ışın alanı; `yon`, `uzunluk`, `tetikleyici_yollari`, `acik_taraf_sag`, `tetik_aktifken_kapali` export'ları. Tetikleyiciler Geçit gibi VEYA mantığıyla çalışır; tetikleyicisiz lazer hep açıktır. Işın duvarlarda kesilmez (raycast yok).
- Artı: plaka/şalter/geçit ile aynı kalıp, yeni fizik yok; "klon bir şeye basarken lazeri kapatır" bulmacası ve risk fikri getirir.
- Eksi: yanlış zamanlama turu kaybettirir (oyuncu ölünce tur yeniden başlar); ışının duvara takılmaması dünyada ışın geçirmeyen bölgelerde dikkat ister.

**Ölüm davranışı:**
- Canlı oyuncu: tur yeniden başlar, `Kayitlar.turlar` değişmez, tur sayısı artmaz, o turun girdisi atılır (`tur_kaydet` çağrılmaz).
- Klon: yerinde donar ve etkisiz kalır (katmanlar 0: plakayı basılı tutmaz, asansörü durdurmaz, kapıya/geçide etkisiz). Ölüm kare numarası deterministiktir (`oldu_kare`). Katman sıfırlaması `set_deferred` ile ertelenir, bu yüzden aynı karede plaka/asansör ölü klonu bir kare daha görebilir; her çalıştırmada aynıdır.
- Eksi (bilerek kabul edildi): ölü klon bölümde duran bir hayalet gibi kalır; çözüm klonun ölmeyeceği şekilde planlanmalıdır.

**Tek yönlü platform** (`scenes/tek_yonlu.tscn`): `StaticBody2D`, Godot'un yerleşik `one_way_collision` özelliği, 120x12.
- Neden: dikey bulmacaya yeni bir fikir (aşağıdan atlayıp üstüne çıkılır), betik ve karmaşık fizik yok.
- Artı: sıfır kod, deterministik. Eksi: zıplama yüksekliğiyle sınırlı kullanım; çok katlı bölümlerde dikkatli yerleşim ister.

**Gözden geçirme notları (Aşama 1):**
- `bolum.gd` `_physics_process` içine `bitti` erken dönüşü eklendi: hedefe ulaşıldıktan veya ölümden sonra, sahne değişene kadar `R` yok sayılır. Bölüm 1-2 davranışı değişmez (hedefte sahne zaten duraklatılır; tek fark bir karelik pencere).
- Ölü klon asansör/geçit üzerinde havada asılı kalabilir: öldüğü yerde donar, taşıyıcı hareket etse bile onunla gitmez. Bilinen kısıt; bölüm tasarımında klonun asansörde lazerde ölmesinden kaçınılır.
- Aynı karede hedefe ulaşma ile ölüm çakışırsa önce gelen kazanır (ağaç sırası sabit, deterministik).
- Test boşluğu (kabul edildi, Bölüm 3+ testlerinde kapatılacak): ölü klonun kapı/geçit/şalter etkisizliği.

## 2026-10-14 - Bölüm 3 uygulandı
- `scenes/bolumler/bolum_3.tscn` taslağa (`docs/devir/bolum_3_taslak.md`) birebir uygulandı: tek kat, iki plaka, iki dikey lazer (plaka basılıyken kapanır), `max_klon = 2`.
- `scripts/bolumler_listesi.gd`'ye kayıt eklendi (konum (1010,440), önceki Bölüm 2); harita kodu değişmedi.

**Bölüm 3 ek notları:** Aşama 2'de taslakların kullanıcı onayı beklenmeden uygulanması kullanıcının açık kararıdır (üretim görevi). Atlanamazlık: ışınlar x 477..483 / 857..863, y 400..600; zemin yüzeyi y=600, tavan alt kenarı y=400, boşluk yok; zıplama tepesi ~97 px < 200 px. Tur süreleri 1,0 / 2,3 / 3,1 sn. Önceki "ölü klon kapı/geçit/şalter test boşluğu" kapandı (`_test_olu_klon_*`). Liste bağımlı testler (bölüm sayısı, harita bağlantı sayısı, "Sonraki bölüm" görünürlüğü) bölüm eklenince kırılmasın diye `BolumListesi`'nden türetilir hale getirildi (anlam korunarak).

## 2026-10-14 - Bölüm 4 uygulandı
- `docs/devir/bolum_4_taslak.md` taslağı olduğu gibi `scenes/bolumler/bolum_4.tscn` olarak yazıldı (max_klon = 3, tek yönlü platformlar `scenes/tek_yonlu.tscn` örnekleri) ve `bolumler_listesi.gd`'ye kayıt eklendi. Gerçek fizik ölçümü (zıplama tepesi 100,9 > 96,5 riski) test yazarına bırakıldı.

**Bölüm 4 revizyonu (REVİZYON 1, test bulgusu):** İlk testte zeminden zıplayan karakterin başı (ayak min y=499 → baş y=451) PA/K üstündeki plakanın alanına (y 454..470) girip plakayı basılı saydı; "zeminden plakaya basılamaz" iddiası tutmadı. Düzeltme: PA/K üst yüzü y=445 (baş 451 > 445), plakalar y=437 (alt kenar 445), E0 `yukseklik=80` (üst 520), F2 yüzeyi y=330 (konum (680,350)), E1 `yukseklik=270`, E2 konum (760,340) `yukseklik=130`. Yeni mesafeler: E0 üstü→PA 75 px (erişilir), zeminden PA/K 155 px (erişilmez), K→F2 115 px (kare tepesi ~100,9; pay ~14), F2→F3 130 px. Ders: plaka platform üstündeyse zıplayanın başı plaka alt kenarının üstünde kalmalı. Ölçülen: tur kareleri 30/163/442, son tur 532 kare (8,9 sn). Not: Asansor2 dinlenmede F2 gövdesinin içindedir (fizikte sorun yok, çarpışmaz); grafikte F2'de boşluk kesilmesi/örtülmesi düşünülmeli. E0 yukarıdayken altından yürünebilir (60 px), çözümü etkilemez.

## 2026-10-14 - Bölüm 5 uygulandı
- `docs/devir/bolum_5_taslak.md` taslağı olduğu gibi `scenes/bolumler/bolum_5.tscn` olarak yazıldı (şalter + iki zıt lazer, asansör, `max_klon = 2`) ve `bolumler_listesi.gd`'ye kayıt eklendi (konum (450,520), önceki Bölüm 4). Çözüm süresi/takılma riski (asansör-sahanlık kenarı) test yazarına bırakıldı.

## 2026-10-14 - Bölüm 6 uygulandı
- `docs/devir/bolum_6_taslak.md` taslağı olduğu gibi `scenes/bolumler/bolum_6.tscn` olarak yazıldı (geçit VEYA plakalar + lazer + asansör, `max_klon = 2`) ve `bolumler_listesi.gd`'ye kayıt eklendi (konum (620,380), önceki Bölüm 5). Geçit sprint payı (36 px) ve ardışık zıplama zamanlaması test yazarına bırakıldı.

**Bölüm 6 test notu:** birinci zıplama noktası x ≲ 800 olmalı (asansör yükselince altında 60 px boşluk var, baş 552 > 540); x=810'da başarısız olur. Çözüm testi x=740 kullanır. Geçit sprint payı: klonsuz sprintte geçit alt kenarı 600 > baş üstü 552. Tur süreleri 22 + 125 + 219 kare (3,65 sn).

## 2026-10-14 - Bölüm 7 uygulandı
- `docs/devir/bolum_7_taslak.md` taslağı olduğu gibi `scenes/bolumler/bolum_7.tscn` olarak yazıldı (3 plaka, şalter + geçit, asansör, 2 lazer, U dönüşlü iki kat, `max_klon = 3`) ve `bolumler_listesi.gd`'ye kayıt eklendi (konum (850,410), önceki Bölüm 6). Zamanlama (A'nın basma anı, E1-Kat2 2 px boşluk) test yazarına bırakıldı.

**Bölüm 7 gözlemleri:** Oyuncu F1'de zeminde yürürken PlakaA'ya kendisi basabilir (asansör kalkar ama oyuncu binemez), F2'de PlakaB/PlakaC'ye kendisi basıp ışınları geçici kapatabilir; çözümü kolaylaştırmaz (plakadan ayrılınca ışın aynı karede açılır, ışına plakadan 39/59 px). Geçit kapalıyken Kat2 alt kenarına bitişiktir; açıkken üst kısmı Kat2 içinde gizlenir (grafikte örtülmeli). Tur kareleri 186/347/387/447 (7,45 sn). Bilinen test boşluğu (bilerek kabul edildi): F2'de zıplayarak ışın geçme (tavan payı 11 px) ve Kat2/asansör kolonu köşesinden zıplama doğrudan sınanmıyor; geometri hesapla güvenli.

## 2026-10-14 - Bölüm 8 uygulandı
- `docs/devir/bolum_8_taslak.md` taslağı olduğu gibi `scenes/bolumler/bolum_8.tscn` olarak yazıldı (3 katlı spiral, tek yönlü basamaklar, şalter + geçit + 3 lazer, asansör, `max_klon = 3`) ve `bolumler_listesi.gd`'ye kayıt eklendi (konum (740,450), önceki Bölüm 7). Zamanlama, 3. zıplama köşe riski ve sekme payı test yazarına bırakıldı.

**Bölüm 8 denetim sonucu (tasarım iddiası düzeltildi):** Taslaktaki "çözüm tam 3 klon gerektirir, 2 klon yetmez" iddiası YANLIŞTI. Denetçinin bulduğu kısayol gerçek fizikte ölçüldü: tek klon X (PlakaA'da E1 tepeye çıkana kadar bekler, F1 zemininde PlakaC'ye yürür, L1 kapanınca ~30 kare bekler, PlakaA'ya döner) + şalter operatörü B ile bölüm 2 klonla bitiyor (tur kareleri 423/528/552, 9,2 sn); tek klonla (yalnız X veya yalnız B) bitmiyor. Sonuç: Bölüm 8 "en az 2 klon gerekir; 3 klonlu A+C+B yolu daha kolaydır", `max_klon=3` pay bırakır. Kullanıcının "çözüm en az 2 klon gerektirsin" koşulu sağlanıyor; yeniden tasarım yapılmadı (isteğe bağlı sıkılaştırma: L3 için ayrı bir plaka eklemek). Bölüm 7 için aynı kısayol denetimde bulunamadı (3 klon gerçekten şart). Bölüm 8 ilk zıplama penceresi ölçüldü: x ≈ 584..728 iner (taslak 624..716 idi); ≤578 ve ≥734 inemez, ölüm yok.

**Bölüm 5 asansör-plaka hilesi:** Oyuncu PlakaA'da ~65 kare bekleyip plakadan ayrılarak inen asansöre binip sahanlığa zıplayamaz (ayak y min 499, sahanlık 470, pay 29 px; şalter dönmez); `_test_bolum5_erken_ayrilma`. Not: bu, Godot'un `platform_on_leave` varsayılanına (ADD_VELOCITY) bağlıdır; sürüm değişirse test yakalar. Fizik değeri değiştirilmedi.

## 2026-10-14 — Aşama 3: görsel katman (tema: terk edilmiş zaman laboratuvarı, kullanıcı kararı)

- **Tema ve rehber:** palet ve nesne görünümleri `docs/stil.md`'de; renkler `scripts/lab_paleti.gd`. Hepsi koddan çizildi, harici oyun görseli/ikonu kullanılmadı.
- **Mimari:** ortak çizici `Gorunum` (`scripts/gorunum.gd`) nesnenin çocuğu olarak eklenir, durumu üst düğümden OKUR, yazmaz (plaka basılı mı, asansör konumu, geçit açıklığı, şalter tarafı, lazer açık mı). İnsan karakter, klon ve ölü klon `scripts/oyuncu_gorunum.gd` (poz: `velocity`, `is_on_floor()`, `oldu`, fizik karesi sayacından; rastgelelik yok). Bölüm `.tscn` dosyaları ve çarpışma/konum/boyut değişmedi.
- **Eski `Gorsel` ColorRect'ler silinmedi, gizlendi** (`visible=false` / alfa 0): testler düğüm adlarına ve özelliklerine (`Gorsel`, `IsinGorsel`) bakıyor, düğüm adları korunur.
- **Asansör/geçit `z_index = -1`:** zemine/kata/tavana gömülü kısımlar örtülür (Bölüm 4 E2/F2, Bölüm 7 geçit/Kat2, Bölüm 8 G). Asansörün zemine gömülü dinlenme konumunda yüzey üstüne ince amber-siyah işaret şeridi çizilir. Eksi: gömülü platform kendisi görünmez, yalnızca ray ve işaret.
- **Headless'ta çizim atlanır** (`LabPaleti.ekransiz()`: `DisplayServer.get_name() == "headless"`; yalnızca `_process`/`_draw` içinde). Neden: görsel katman eklenince `--headless` test süresi ~38 sn'den ~346 sn'ye çıkmıştı (her kare ve her sahne yüklemesinde yüzlerce çizim çağrısı, 100x determinizm × çok bölüm); atlayınca 43 sn. Oyun durumuna etkisi yoktur (hiçbir `_physics_process`/mantık yolunda kullanılmaz). Gerçek görsel doğrulama `--write-movie` ile yapılır.
- **Anchor uyarısı:** `LabArkaplani` CanvasLayer altında hem anchor hem boyut veriyordu ("size overridden after _ready()", ~1000 satır log); artık CanvasLayer altında yalnızca boyut, aksi halde yalnızca anchor verilir.
- **Bilinen/elle kontrol:** sonuç ekranı ve ekran butonları teması gerçek kareyle bakılmadı; koşma döngüsü (5 karede bir değişir) ve klon/oyuncu pozlarının hareketli akıcılığı gözle kontrol edilmeli.

## 2026-10-14 — Bölüm 8: max_klon = 2 (kullanıcı kararı, açık nokta kapandı)

Kullanıcı, Bölüm 8'in 2 klonla çözülebilmesi bulgusuna karşı seçenek 1'i seçti: `max_klon` 3'ten 2'ye düşürüldü (`scenes/bolumler/bolum_8.tscn`), bölüm "en az 2 klon, tam 2 klonlu çözüm" olarak kalır. Testler 2 klonlu çözüme (X: PlakaA→PlakaC→PlakaA, B: şalter operatörü) göre güncellendi; tur kareleri 423/528/552 (≤600). Eski A+C+B üç klonlu yol artık hak olmadığı için yapılamaz. Bölüm 8'in "tam 3 klon" iddiası ve taslak notu bu karar ile geçersizdir. Zorluk artık "3 klon" değil, 2 klonun zamanlamasıdır (2/2 sınırına tam oturur, pay yok). Eski "Bölüm 8 en az 2 klonla çözülebilir" açık noktası KAPANDI.

## 2026-10-14 — Aşama B: kutu, yaylı zıplatıcı, taşıma bandı (kullanıcı onaylı istisna)

Kullanıcı "başka mekanik ekleme" kuralının istisnası olarak yalnızca bu üç nesneyi onayladı (`docs/devir/asamaB_nesneler.md`). Katman 4 (`1 << 3`) kutu sorgu katmanıdır. Mevcut bölümler kutusuz olduğundan davranış değişmedi; mevcut testler GEÇTİ.

- **Kutu** (`scenes/kutu.tscn`, `scripts/kutu.gd`): `CharacterBody2D`, kendi kinematik kodu; itme `it(dx)` ile (`player.gd` yatay çarpışmada çağırır, oyuncu ve klon aynı kod yolu). Plakayı basılı tutar, asansör/geçit altında kutu varsa durur (ezmez). Neden: kutu-plaka-klon bulmacaları. Artı: RigidBody'siz olduğu için deterministik, zincirleme itme yok. Eksi: kutu kendi hareket ederken karakterlerle çarpışmaz (yalnızca karakter yönünden engel); klon asansör altında kalırsa mevcut kısıt kutu için de geçerli.
- **Yaylı zıplatıcı** (`scenes/yayli_ziplatici.tscn`): `Area2D`, `velocity.y >= 0` olan gövdeye `-firlatma_hizi` (820, ~240 px). Neden: dikey ilerleme için asansörsüz alternatif. Artı: tek kısa betik, durumsuz. Eksi: yükseklik sabit; zıplatıcıya zıplama tuşuyla birleşmez (üstüne basarken velocity ezilir).
- **Taşıma bandı** (`scenes/tasima_bandi.tscn`): `StaticBody2D.constant_linear_velocity`. Neden: ek mantık gerektirmeden yatay sürükleme. Artı: yerleşik, deterministik. Eksi: bandı terk edince `platform_on_leave` davranışı Godot sürümüne bağlıdır.
- Yeni nesnelerde `Gorsel` düz ColorRect; `Gorunum`'a tür eklenmedi (Aşama D).

## 2026-10-14 — Aşama B ek notu: denetim düzeltmeleri ve bilinen kısıtlar

- **Zincirleme itme:** `kutu.gd` `it()` artık `test_only` sorgu + `safe_margin` kullanır; ölçülen sızıntı 0,02 px/kare idi, 0'a indi.
- **Katman 4 gerekçesi:** kutu dünya katmanı 1 ile birlikte 4'tedir. Karakterler 1'le çarpışır; asansör/geçit/plaka katman 4'ü ayrı sorgulayarak kutuyu algılar (plakayı tutar, altındaysa durur).
- **Zıplatıcı + zıplama tuşu:** zıplatıcı aynı karede `velocity.y = -820` verip kullanıcı zıplarsa `player.gd` `-520` ile ezip fırlatmayı zayıflatıyordu. Çözüm: `velocity.y = minf(velocity.y, ZIPLAMA_HIZI)`; yerdeyken `velocity.y >= 0` olduğundan mevcut davranış aynı, daha güçlü olan korunur.
- **Bilinen kısıtlar:** kutu yalnızca itilir, çekilemez; köşeye/uçuruma giden kutu geri alınamaz (çözüm "Baştan başla"). Kutu oyuncu başlangıcından >= 40 px uzak yerleştirilmeli (doğum çakışması). Asansör tepe noktasıyla tavan arası >= 40 px + pay bırakılmalı. Kutu zıplatıcı üstünde sekmeye devam eder. Kutu zıplatıcıyla 240 px yükseğe taşınabilir.
- **Bölüm tasarımı uyarıları:** kutu basamak olur (yükseklik hesabına kat); kutuyla plaka tutmak klon tasarrufu sağlar (`max_klon` hesabını etkiler); geçit altındaki kutu yolu açık tutar.

## 2026-10-15 — Harita yeniden yerleşimi (Aşama C, ana oturum kararı, kolay geri alınır)

14 bölüm için mevcut yay/spiral yerleşimde iç alan tükendiği için (Bölüm 9'dan sonra hiçbir çizgiyi kesmeden yer yok) Bölüm 6–8'in harita konumları değiştirildi: 6 (620,380)→(230,480), 7 (850,410)→(150,330), 8 (740,450)→(230,190); Bölüm 1–5 aynen kalır; 9–14 dış halka (9 (440,230), 10 (640,190), 11 (850,175), 12 (1030,230), 13 (1070,350), 14 (1070,545)). Yalnızca `bolumler_listesi.gd` verisi; harita kodu değişmez. Gerekçe: tasarımcı çizgi kesişimi ve düğüm mesafelerini (≥100 px) kontrol etti. Eksi: Bölüm 6–8'in önceki "spiral iç" görünümü kaybolur.

## 2026-10-15 — Bölüm 9 uygulandı (Aşama C)

`scenes/bolumler/bolum_9.tscn` taslağa (`docs/devir/bolum_9_taslak.md`) birebir kuruldu (`max_klon = 3`, kutu + 4 plaka + asansör + geçit + 2 lazer + tek yönlü platform). `bolumler_listesi.gd`'ye kayıt eklendi (konum (440,230), önceki Bölüm 8); Bölüm 6–8 konumları taslaktaki yeni yerleşime güncellendi. Çözülebilirlik testleri test yazarının işidir.

## 2026-10-15 — Bölüm 10 uygulandı (Aşama C)

`scenes/bolumler/bolum_10.tscn` taslağa (`docs/devir/bolum_10_taslak.md`) birebir kuruldu (`max_klon = 3`; 2 taşıma bandı, kutu, 4 plaka, asansör, geçit, 2 lazer, kapı). `bolumler_listesi.gd`'ye kayıt eklendi (konum (640,190), önceki Bölüm 9). Çözülebilirlik testleri test yazarının işidir.

**Bölüm 9 bağımsız kısayol taraması (gozden-gecirici):** 2 klonlu çözüm BULUNAMADI (minimum 3 klon, kutu olmasa 4). Notlar: (1) asansör kutuyu "basamak" olarak sabitleyebilir (asansör kutu üstünde y≈546'da takılır, üst yüzey ~536; oradan F2'ye 96 px zıplama, pay ~4,9 px): bu, Plaka2 tutucusu olmadan F2'ye çıkış sağlar ama F2'de L1 ve G için iki tutucu yine gerekir, klon sayısı 3'ten düşmez; farklı bir 3 klonlu yoldur (A=Plaka1, C=Plaka3, D=PlakaKutu). (2) G'yi oyuncunun tek başına geçmesi: en iyi durumda (PlakaKutu'nun sağ ucundan ayrılıp tam açık geçitten) pay ~3 kare / ~17 px; ölçülen en uzak x=1045,98 (G sol yüzü 1060). Geçit hızı/konumu değişirse bu yol açılabilir; sınır testi eklenecek. (3) "Kutu platforma çıkamaz" iddiası kesin değil: kutu asansörle F2 yüksekliğine çıkıp sola itilirse düşme sonrası x≈452'de platforma inebilir (Plaka2 alanından ~2 px ıskalar); ölçülmedi, klon sayısını etkilemez. (4) Harita testleri çizgi kesişimini ölçmüyor (yalnız mesafe ve ekran içi); 1–9 zincirinde elle hesaplandı kesişim yok.

**Bölüm 10 test bulguları:** taslaktaki "kalkış penceresi x0 ∈ [267,350]" iddiası fiziksel olarak YANLIŞ: kutu+duvar yalnız 40 px yüksek, zıplama ~100 px; kutuya bitişikten (x0=370) ve erken kalkıştan (x0=240) da aşılır. Gerçek kısıt: L1 kapalıyken geçmek ve kutuyu P1'e yollamak. C'nin PE üstünden zıplaması sınırda (kalkış x≈555'te sağ kenar plaka x=580'e değer, PE 1 kare basılır, asansör 2 px kalkar; zararsız, önerilen kalkış x≤540). Ölçülen: tur kareleri 251/187/336 + oyuncu 394 (6,57 sn); kutu bantta 1,667 px/kare, duvara dayanınca titreme 0,074 px/120 kare; bant+girdi 6,667, ters 3,333 px/kare.

## 2026-10-15 — Bölüm 11 uygulandı (Aşama C)

`scenes/bolumler/bolum_11.tscn` taslağa (`docs/devir/bolum_11_taslak.md`) birebir kuruldu (`max_klon = 2`; 2 yaylı zıplatıcı, tek yönlü raf, 2 plaka, 2 yan yana lazer, kapı). `bolumler_listesi.gd`'ye kayıt eklendi (konum (850,175), önceki Bölüm 10). Çözülebilirlik testleri test yazarının işidir.

## 2026-10-15 — Bölüm 11: PlakaPB havaya taşındı ("belirgin zor" ölçütüne yaklaştırma, tasarımcı önerisi)

`scenes/bolumler/bolum_11.tscn` içinde yalnızca PlakaPB değişti: (950,152) -> (698,160), boyut 60x32 (x 668..728, y 144..176; Z2 fırlatma yörüngesinde havada, F3 üstünde durarak basılamaz). Etki: B artık plakada duramaz; uçuşta 14 kare basar, L2 yalnız 14 kare kapanır ve B'nin başlama zamanı (>= 32 kare gecikme) ile oyuncunun cepte bekleyip ışını 0-3 karelik pencerede geçmesi gerekir. Test yazarı ölçümleri ve pencere genişlikleri `docs/devir/bolum_11_taslak.md` güncelleme notunda. Atlanamazlık testleri değişmedi; kısayol (klonsuz, tek klon, röle, oyuncunun kendi uçuşuyla PB'yi basması) bulunamadı. Not: tasarımcının "oyuncu ışın penceresi ~7 kare (0-6 gecikme)" tahmini ölçümde 0..3 kareye düştü (Z2 üstünden zıplama sonrası cepte durma ve ışın genişliği nedeniyle); B gecikme alt sınırı tahmin edilen ~33 yerine 32.

## 2026-10-15 — Bölüm 12 uygulandı (Aşama C)

`scenes/bolumler/bolum_12.tscn` taslağa (`docs/devir/bolum_12_taslak.md`) birebir kuruldu (`max_klon = 2`; kutu, yaylı zıplatıcı, 2 tek yönlü raf, 3 plaka, 4 geçit [PlakaA iki geçite bağlı], kapı). `bolumler_listesi.gd`'ye kayıt eklendi (konum (1030,230), önceki Bölüm 11). Çözülebilirlik ve kısayol (geçit altı park/röle dahil) testleri test yazarının işidir.

## 2026-10-15 — Bölüm 12: ölçülen pencereler (test-yazarı) ve AÇIK KARAR

Ölçümler (tests/test_runner.gd `--b12`): çözüm 3 tur / 2 klon / 371 kare, determinizm 100x sapmasız; kutu basamağı payı 11,8 px (taslak 6,5); GK yarışı payı 3 kare; Y2 s>=20; fırlama sonrası sag gecikmesi <=4 kare ve >=5 kare süre; oyuncu izleme gecikmesi L=0..38; kutu inmeden Zıplatıcı'ya girişte çarpışma yok (en az ~10 kare bekleme). Bölüm 12'de röle kısayolu çalışmaz (43 deneme, 0 çözüm), min klon 2 korunur. Yığma (kutuyla fırlayan oyuncu R2'ye çıkar) mümkün ama klon azaltmaz.

**AÇIK KARAR:** Bölüm 6 tek klonla (geçit altı park/röle) çözülüyor (12/12 varyant, `max_klon=2`, taslak min 2); kabul / geçit kuralı değişsin / bölüm yeniden ayarlansın. Kullanıcı kararı bekliyor (bkz. docs/sorunlar.md). Bölüm 7, 9, 10 etkilenmiyor.

## 2026-10-15 - Tek yönlü platformdan aşağı düşme (kullanıcı kararı)
- Karar: `asagi` eylemi (S / Aşağı ok). Karakter tek yönlü platformun üstündeyken basılıysa o platform yalnızca o karakter için 12 fizik karesi (`ASAGI_DUSME_KARE`) çarpışma istisnasına alınır (`add_collision_exception_with`), sonra tekrar katı olur. Kutu ve diğer karakterler etkilenmez; normal zemin, kutu, asansör, geçit üstünde etkisizdir (yalnızca `one_way_collision` şekilleri). Oyuncu ve klon aynı kod yolunu kullanır; gerçek saat/rastgelelik yok.
- Kayıt formatı `{yon, zipla}` -> `{yon, zipla, asagi}`; `asagi` her karede kaydedilir. Okuma `.get("asagi", false)`: eski kayıtlar bozulmaz.
- Artı: oyuncuya kontrol kazandırır, bölüm tasarımında yeni olasılıklar. Eksi: "başka mekanik ekleme" kuralının istisnasıdır; mevcut bölümlerde kısa yollar açabilir (tasarımcı gözden geçirmeli).
- Kısıt: 12 kare sonra karakter hâlâ platformun içindeyse tek yönlü olduğu için takılmaz, aşağı doğru geçip çıkar.

## 2026-10-15 - Klon ipucu ikonu (kullanıcı kararı)
- `bolum.gd`'ye `@export var ipucu_klon: int = 0`. 0 ise ikon yoktur; doluysa HUD'da "Klon: X/Y" satırının yanında "?" ikonu (`IpucuIkonu`) çıkar, üstüne gelince altında "N klonla çözülebilir" (`IpucuMetni`, yalnızca hover'da görünür) yazar. Yalnızca Bölüm 4 (`ipucu_klon = 2`, `max_klon = 3`) ve Bölüm 6 (`ipucu_klon = 1`) için ayarlıdır.
- Yalnızca HUD: oyun mantığı, kayıt ve fiziğe karışmaz; fare yalnızca ikonu yakalar, tuş girdisini etkilemez; ekran butonlarıyla (sağ üst) çakışmaz.

## 2026-10-15 - Oyun adı "Loop Lab", bant ve askı görünümü
- Oyun adı "Loop Lab": `project.godot` `config/name` (pencere başlığı), ana menü başlığı, CLAUDE.md başlığı. Klasör adı değişmedi.
- Görünüm: taşıma bandı kayan oklu kemer + makara; Bölüm 11 PlakaPB (konum/çarpışma aynı) tavana ve Kat3 duvarına görsel askıyla bağlı. Yalnızca görsel; mantık, fizik, kayıt değişmedi.

## 2026-10-15 — Bölüm 13 uygulandı (Aşama C)

`scenes/bolumler/bolum_13.tscn` taslağa (`docs/devir/bolum_13_taslak.md`) birebir kuruldu (`max_klon = 3`; 2 taşıma bandı, yaylı zıplatıcı, şalter, 4 lazer, 3 plaka, tek yönlü kapak, kapı kuyuda). `bolumler_listesi.gd`'ye kayıt eklendi (konum (1070,350), önceki Bölüm 12). `ipucu_klon` verilmedi. Çözülebilirlik ve kısayol testleri test yazarının işidir.

**Bölüm 13 ölçüm notu (2026-10-15):** "taslağa birebir" ifadesi K1 ilk yürüyüşü hariç geçerlidir (taslakta `sag` 8 kare yazıyordu, ölçülen çalışan aralık 11..18; testler 12 kullanır). Ayrıntı: `docs/devir/bolum_13_taslak.md` başındaki UYARI ve `docs/sorunlar.md`.

## 2026-10-15 — Kutu ve yaylı zıplatıcı görünümü (Aşama D)

Kutu ve yaylı zıplatıcı düz renkli kutu yerine `Gorunum` türleriyle (`KUTU`, `ZIPLATICI`) çizilir; yalnızca görsel. Çarpışma, fizik, kayıt formatı değişmedi. Zıplatıcı sıkışma animasyonu görsel zamanlayıcıdan türer, `velocity` salt okunur.

## 2026-10-15 — Bölüm 14 uygulandı (Aşama C)

`scenes/bolumler/bolum_14.tscn` taslağa (`docs/devir/bolum_14_taslak.md`) birebir kuruldu (`max_klon = 3`; taşıma bandı, 2 yaylı zıplatıcı, 2 geçit, 3 lazer, 5 plaka, kutu, raf + 2 kapak tek yönlü, kapı çıkıntıda). `bolumler_listesi.gd`'ye kayıt eklendi (konum (1070,545), önceki Bölüm 13). `ipucu_klon` verilmedi. Çözülebilirlik ve kısayol testleri test yazarının işidir.

**Bölüm 14 ölçüm notu (2026-10-15):** "taslağa birebir" yalnızca nesne konumları için geçerlidir; kare/pencere sayıları ölçümle düzeltildi (bkz. `docs/devir/bolum_14_taslak.md` başındaki UYARI). **AÇIK KARAR (kullanıcıya):** canlı oyuncu/klon tekrarı, eş düzlemli bant/zemin dikişlerinde (Bölüm 14 UL1|Bant x≈490, Bölüm 13 BantA|ZeminSag x=260, Bölüm 10 ZeminSol|Bant1 x=270, asansör-zemin hizası) motorun platform seçimi yüzünden ≤11,67 px ayrışıyor (kök neden `player.gd` değil, fizik geniş-faz sırası; dünyada boşta klon sayısı değişince sonuç değişiyor). Seçenekler: A) kabul + test sınırı (uygulandı: ayrışma üst sınırı testle izleniyor), C) bant etkisini motor platform hızından ayırıp deterministik uygulamak (player/kutu/bant fiziği değişir, bant pencereleri yeniden ölçülür). Karar kullanıcıda; şimdilik A.

## 2026-10-15 — Arayüz: sonuç özeti, klon yuvaları, geçiş perdesi

Yalnızca görsel. Süre fizik karesinden (kayıt uzunlukları + canlı kare) hesaplanır, kayıt dosyası yok. Geçiş yalnızca yeni sahne yüklenince solma olarak uygulandı (çıkış solması reload'u geciktireceği için yok). Fizik, kayıt formatı, determinizm değişmedi.

## 2026-10-15 — Zamanlı ve mandal plaka (kullanıcı onaylı istisna, en çok 2 yeni basit nesne)

`BasincPlakasi`'ye iki isteğe bağlı kip eklendi; varsayılanlar (`tutma_kare = 0`, `mandal = false`) mevcut davranışı birebir korur (`basili_mi()` yine yalnızca `has_overlapping_bodies()`).
- **Zamanlı plaka** (`scenes/zamanli_plaka.tscn`, `tutma_kare = 180`): fiziksel basış bittikten sonra `tutma_kare` fizik karesi daha basılı sayılır; yeniden basılırsa sayaç yenilenir.
- **Mandal plaka** (`scenes/mandal_plaka.tscn`, `mandal = true`): bir kez basılınca tur sonuna (sahne yeniden kurulana kadar) basılı kalır.
- Tek sorgu noktası `basili_mi()`; asansör, geçit, lazer ve kutu algılaması değişmeden yeni durumu okur. Sayaç yalnızca `Engine.get_physics_frames()` ile karede bir kez ilerler (gerçek saat/rastgelelik yok), sahne her turda yeniden yüklendiği için durum tur başında sıfırlanır. Kayıt formatı `{yon, zipla, asagi}`, klon sınırı ve tur mantığı değişmedi.
- Ölü klon plakayı fiziksel olarak tutmaz (katmanları kapanır); zamanlı sayaç klon ölse de yalnızca kalan süreyi sürdürür, klon ölmeden basılmış mandal kalır.
- Görünüm: `Gorunum.Tur.PLAKA_ZAMANLI` (üstte azalan şerit + tik işaretleri), `PLAKA_MANDAL` (asma kilit, basılınca kalıcı yeşil). Çarpışma/fizik aynı.
- Artı: yeni bulmaca türleri (zaman penceresi, kalıcı anahtar) yeni sınıf/kod yolu açmadan; mevcut bölümler etkilenmez. Eksi: mandal, "dünya her turda baştan" ilkesine bir tur içi hafıza ekler; zamanlı plaka klonu "ben burada durmadan" etki yaratabildiği için bölüm tasarımında ve çözülebilirlik testlerinde dikkat ister. Yeni bölüm/test yazımı gerektirir (sonradan Bölüm 15–20 kullandı: zamanlı 15, 17, 18, 19; mandal 16, 17).

## 2026-10-15 — Harita yerleşimi ve bölüm adı
Harita 20 bölüm için yılan ızgara (5 sütun x 4 satır, yalnızca yatay/dikey bağlantı) yerleşir; böylece çizgi kesişimi ve düğüm üstüne binme yapısal olarak yok. `BolumListesi` kaydına isteğe bağlı `ad` alanı eklendi (`BolumListesi.ad(yol)`); konum verisi dışında oyun mantığı değişmedi. Ana menüye Kontroller ekranı eklendi.

## 2026-10-16 — Bölüm 15/16/17 uygulandı
`scenes/bolumler/bolum_15.tscn` (Fitil, zamanlı plaka, `max_klon = 3`, çözüm en az 2 klon), `bolum_16.tscn` (Mandal, mandal plaka, 3 klon), `bolum_17.tscn` (Çifte Mühür, zamanlı + mandal plaka + ters bant, 3 klon; `tutma_kare = 70`) taslaklara (`docs/devir/bolum_15..17_taslak.md`) birebir kuruldu ve `BolumListesi`'ne eklendi (konumlar `harita_yerlesim.md`). Taslaktaki kare/piksel sayıları tahmindir; çözüm testi ve ölçüm henüz yapılmadı (test-yazari işi). `ipucu_klon` verilmedi. Mevcut testler (harita 17 kayıt dahil) geçti.

## 2026-10-16 - Bölüm 18/19/20 uygulandı
`scenes/bolumler/bolum_18.tscn` (Vardiya, zamanlı plakalı asansör, `max_klon = 3`, çözüm en az 2 klon), `bolum_19.tscn` (Karşı Ağırlık, iki asansör + geçit, 3 klon), `bolum_20.tscn` (Büyük Saat, zıplatıcı + asansör + geçit + ters bant + şalter, 3 klon) taslaklara (`docs/devir/bolum_18..20_taslak.md`) birebir kuruldu ve `BolumListesi`'ne eklendi (konumlar `harita_yerlesim.md`: 18 (580,510), 19 (360,510), 20 (140,510)). `ipucu_klon` verilmedi. Taslak sayıları tahmindir; ölçüm ve çözüm testleri test-yazari işidir.

**Bölüm 15/16/17 ölçüm notu (2026-10-16):** çözüm testleri ve kısayol taramaları yapıldı (57 test GEÇTİ; bağımsız denetim: kısayol yok, atlanamazlık ve kilitlenme sorunsuz, zamanlı/mandal plaka mantığı determinist). "Taslağa birebir" yalnızca nesne konumları için geçerlidir; kare/pencere sayıları ve bazı senaryolar (uçuşta `sag` bırakma, "ışına inme", kutu kilidi) ölçümle düzeltildi: bkz. her taslağın başındaki ÖLÇÜM NOTU ve `docs/sorunlar.md`.

**Bölüm 18/19/20 ölçüm notu (2026-10-16):** çözüm testleri ve kısayol taramaları yapıldı (58 test GEÇTİ: B18 18, B19 19, B20 21; tam suit 526; bulgular docs/sorunlar.md "Bölüm 18–20"). Min klon: B18 2, B19 3, B20 3 doğrulandı, kısayol yok; ölçülen hiçbir pencere 12 px altında değil (en dar: B20 C_A geç basış 8 kare = 40 px, şalter geri bas ~40 px). Taslak sayı sapmaları her taslağın başındaki ÖLÇÜM NOTU'nda.

## 2026-10-16 — Kalıcı kurallar: görünürlük, okunabilirlik, gözden geçirici kapısı (kullanıcı kararı)
- **Görünürlük:** çarpışması, tetikleyicisi veya etkisi olan her nesnenin net bir görünümü olur; çizimsiz çarpışma, görünmez plaka/blok, gizli işlev yasak.
- **Okunabilirlik:** her bölüm yalnızca ekrana bakarak çözülebilir olmalı; çözüm görünmeyen şeye ya da tahmin edilemeyen zamanlamaya dayanmaz. Zor olabilir, haksız olamaz.
- **Kapı:** `gozden-gecirici` her bölümde çizimsiz çarpışma/tetikleyici arar; bulursa bölüm kabul edilmez. Yeni bölüm taslağı kullanıcı onayı olmadan uygulanmaz.
- **Ajan modelleri:** `tasarimci` ve `gozden-gecirici` opus; `uygulayici`, `test-yazari`, `grafik` sonnet.

## 2026-10-16 - T tuşu: baştan başla (kullanıcı kararı)
- T (`bastan` eylemi) ekran butonlarındaki dönen okla aynı işlemi yapar (`EkranButonlari.bastan_basla()`: `Kayitlar.sifirla()` + sahneyi yeniden yükle). Sistem tuşudur: kayıt formatı `{yon, zipla, asagi}` değişmez, oyuncu girdisi olarak kaydedilmez. Sonuç ekranı açıkken ve ölüm/geçiş sırasında (`bitti`) çalışmaz.
- HUD etiketine "T: baştan başla" eklendi; Kontroller ekranı tuş adlarını Türkçe gösterir (Sol ok, Sağ ok, Yukarı ok, Aşağı ok, Boşluk; diğerleri OS adıyla) ve "Baştan başla" satırı vardır. Test: `-- --tustu` (tam koşuya dahil).

## 2026-10-16 — Görünürlük düzeltmeleri, Parça 1 (grafik; yalnızca görünüm)
- Kök neden: `Gorunum._draw` match'inde `KUTU`, `ZIPLATICI`, `PLAKA_ZAMANLI`, `PLAKA_MANDAL` kolları yoktu (24 çizimsiz çarpışma/tetikleyici, rapor: `docs/devir/gorunurluk_raporu.md`). Dört kol eklendi; eski düz `Gorsel` kutuları zaten gizliydi, çizim alanları çarpışma şeklinden türediği için çarpışmayı kapsar, z_index 0 ve ağaç sırası nedeniyle zemin/kat çiziminin üstündedir.
- Taşıma bantlarında (B10 x2, B13 x2, B14, B17, B20) `bolum.gd:_gorunumu_kur` artık kendi `Gorunum` çocuğu olan gövdeyi atlar (ikinci DUVAR çizimi kemeri örtüyordu). Bant çizimi yenilendi: koyu kehribar kemer, parlak amber oklar sürekli akar, makaralar döner; yön/hız `yon`/`hiz`'dan okunur, yalnızca `_process`. Palete `BANT_ZEMIN/BANT_OK/BANT_OLUK` eklendi. Mandal plaka kilit lambası açıkken `UYARI` (kırmızı) yapıldı.
- Bölüm 14 `PlakaR` +20 px sağa denemesi (kullanıcı onaylı konum değişimi) GERİ ALINDI: 520'de çözüm KALDI (bant, plakadaki klonu sürükler; 10 test), 510'da çözüm GEÇTİ ama başarısızlık 5/10 ve zamanlama ölçümü bozulur (bant payı 2,4 -> 8 kare; bölüm kolaylaşır). Konum 500'de duruyor; karar bekliyor (bkz. `docs/sorunlar.md`).
- B10 `PlakaPG` ve `PlakaP1` kasıtlı olabileceği için DOKUNULMADI (karar notu `docs/sorunlar.md`).


## 2026-10-16 — Bölüm 9 ince ayar (Parça 2 madde 3, kullanıcı onaylı)
- **Karar:** Fikir (kutu tanıtımı) ve çözüm (3 klon, 4 tur) korunarak geometri ince ayarlandı: F2 yüzeyi 440 -> 430 (Kat2 450x170, asansör `yukseklik` 170, Plaka3/PlakaKutu y 422, Kapı y 406, Geçit y 330, L1 `uzunluk` 130), PlakaKutu x 930 -> 910. Çözüm betiğinde k2 beklemesi 120 -> 60 kare. Ayrıntılı önce/sonra tablosu: `docs/devir/bolum_9_ayar.md`.
- **Gerekçe:** ölçümde (`_test_bolum9_pencereler`) oyuncu pencereleri zaten >= 15 kare idi; zorluk boş beklemelerden (tur 2: 120 kare, asansörde ~185 kare) ve iki dar güvenlik payından geliyordu: takılı-asansör basamağından F2'ye çıkılabiliyordu (-4,9 px; ayrık zıplama tepesi ~100,9) ve G sprint payı 2-4 kareydi. Sonra: basamak +5 px (çıkılamaz), G sprint 6-8 kare, k3/oyuncu geç kalma payı 50 kare, tur süreleri 25/224/329/407 -> 25/164/274/348.
- **Test değişikliği:** B9 sabitleri geometriye bağlandı (`B9_F2_Y`, `B9_PK_X`, `B9_GECIT_KAPALI_Y`, `B9_K2_BEKLE`); tur 4 betiği L1 kapanana kadar x=800'de bekler (ekrana bakarak oynama); basamak ölçüm testi artık "F2'ye çıkılamaz"ı doğrular; yeni ölçüm testi pencere paylarını (>= 8 kare) ve tur sürelerini (<= 600) denetler. Atlanamazlık/kısayol/başarısızlık testleri aynen kaldı ve geçti.
- **Alternatif (seçilmedi):** k2'nin tek taraflı "binişten sonra bas" koşulunu kaldırmak (tur yapısı/nesne değişikliği; ince ayar kapsamı dışında). Kalan not `docs/sorunlar.md`.
## 2026-10-16 — Bölüm 9 kabul, Bölüm 18 ipucu ikonu (kullanıcı kararı)
- **Bölüm 9:** kullanıcı mevcut (ince ayarlı) halinden memnun; sonraki değişiklik yok, `docs/sorunlar.md`'deki açık madde kapatıldı.
- **Bölüm 18 "Vardiya":** `ipucu_klon = 2` (`max_klon` 3 kalır). "?" ikonu ve hover metni "2 klonla çözülebilir" Bölüm 4 ve 6'daki gibi. İkon yalnızca Bölüm 4, 6 ve 18'de; başka bölüme konmaz. Yalnızca HUD, oyun mantığı değişmez.

## 2026-10-16 — Plakaları bandın üstüne oturtma (B14 PlakaR, B10 PlakaPG/PlakaP1; kullanıcı isteği)
- **Bölüm 10 `PlakaP1`:** merkez x 410 -> 400 (x370..430): tam Bant1 üstünde, Duvar (x430..450) örtüşmesi giderildi. Tutucu kutu bantla Duvar'a dayanıp durduğu için davranış aynı; L1 6 kare erken kapanır (79 -> 73), A'nın PE basma penceresi (180..330 kare) ve 3 klon korunur, A canlı/klon farkı 3,33 -> 1,67 px. Tüm B10 testleri geçti.
- **Bölüm 14 `PlakaR` ve Bölüm 10 `PlakaPG`: değişiklik YOK.** (B14) bandı 20 px sola uzatma ve plakayı 520'ye alma ayrı ayrı ölçüldü, ikisi de 10 test KALDI; uzatmada çözümün tutma noktası UL1|Bant dikişine düşüp C3 canlı/klon farkını 1,67 -> 13,33 px'e çıkarıyor, bant yarışı payı 2 -> 0. (B10) Bant2'yi 70 px sola uzatmada C klonu PG'den sürüklenip plaka 117 kare boş kalıyor. Gerekçe: bant üstündeki plakayı hareketsiz tutan karakter ancak bant dışında, dikişte (canlı/klon belirsiz) ya da bant yönünde bir engele dayalı durabilir; ikisinde de tutucu karakterdir ve engel yoktur. Alternatifler (onay gerekir): görünür durdurucu ekleme, plakayı bandın engelli ucuna taşıyıp yeniden tasarlama, bant etkisini motordan ayırma. Ölçümler `docs/devir/gece_notlari.md`, açık madde `docs/sorunlar.md`.
- **Test:** `_test_bolum10_pg_tutma` (C klonu son turda PG'de sabit, PG hep basılı; PG çevresinde girdisiz duruş) ve `_test_bolum10_p1_pencere` (P1 bant üstünde/Duvar'a değmez, L1 kapanışı, A basma penceresi pay >= 8 kare) eklendi (`--b10` ve tam koşu). B10 canlı/klon testinin ölçüm metni güncellendi (sınırlar aynı).

## 2026-10-16 — Bölüm 21 "Mandal" uygulandı; harita 6x4 (22 düğüm)
- **Bölüm 21:** onaylı taslak (`docs/devir/bolum_21_taslak.md`) birebir `scenes/bolumler/bolum_21.tscn` olarak kuruldu (`max_klon = 2`, çözüm 2 klon, `ipucu_klon = 0`; mandal plaka dersi). Eski B16/B17 oyunda aynen kalır. Geçit LazerA'dan sonra (taslak önerisi).
- **Kablo çizimi (yalnız görünüm):** geçit/lazer çiziminde isteğe bağlı `kablo` meta'sı (`gorunum.gd:_kablo`); plaka etkinken yanar. Mekanik/çarpışma yok; meta olmayan bölümler değişmez.
- **Harita:** bölüm sayısı 22 olacağından 5x4 ızgara yerine 6x4 yılan ızgara (x aralığı 180, y 165..510); 1..21 konumları güncellendi, 22. ayrıldı. Ayrıntı `docs/devir/harita_yerlesim.md`. Düğüm sayısı sabit kodlu testler (20) test-yazari tarafından güncellenecek.

## 2026-10-16 — Bölüm 22 "Fitil ve Mühür" uygulandı
- **Bölüm 22:** onaylı taslak (`docs/devir/bolum_22_taslak.md`) birebir `scenes/bolumler/bolum_22.tscn` olarak kuruldu (`max_klon = 2`, çözüm 2 klon, `ipucu_klon = 0`; zamanlı plaka 180 kare varsayılan, sahnede değiştirilmedi). Eski B16/B17 oyunda aynen kalır. Harita: 22. kayıt "Fitil ve Mühür", konum (500, 510), önceki bölüm 21.
- **Oda geçidi (G):** taslak önerisi: tetikleyiciler [PlakaZ (fitil), PlakaM (mühür)] VEYA; mühür odayı kalıcı açar, oda tuzak olmaz. Ad: "Fitil ve Mühür" (taslak önerisi).
- **Kablo (yalnız görünüm):** B21'deki `metadata/kablo` mekanizması; G iki tetikleyicili olduğundan `gorunum.gd`'ye isteğe bağlı ikinci meta `kablo_2` eklendi (`_kablo` -> `_kablo_ciz`): `kablo_2` varsa her kablo kendi tetikleyicisiyle yanar (kablo -> 1., kablo_2 -> 2.), yoksa eskisi gibi herhangi biri. B21 ve eski bölümler değişmez. Çarpışma/mekanik yok. Rotalar: ZP->G (170,584)-(170,376) (kuyuda dikey, zeminin arkasından); M->G (110,372)-(125,372)-(125,300)-(160,300); M->GM (110,372)-(125,372)-(125,190)-(650,190); PA->LA (508,584)-(508,184)-(520,184); PB->LB (820,372)-(880,372)-(880,184)-(903,184). Alternatif: tek meta (ZP kablosu yok, dikey hizaya güvenmek); ikinci kablo yeni görünüm kodu gerektirdiği için seçilmedi. Not: kablo ekranlı gözle doğrulanmadı.

## 2026-10-16 — Kapanış: bölüm sayısı 22
- Oyunda 22 bölüm var (1–20 + 21 "Mandal" + 22 "Fitil ve Mühür"); eski B16/B17 değişmedi. Madde 3 (plaka/bant) sonucu: B10 PlakaP1 uygulandı; B14 PlakaR ve B10 PlakaPG ölçüldü, geri alındı (sorunlar.md). Bölüm 9 değişmedi; Bölüm 18 `ipucu_klon = 2`.

## 2026-10-19 — Bölüm 19 "Karşı Ağırlık" kaldırıldı (kullanıcı kararı); oyunda 21 bölüm
- **Karar:** Bölüm 19 ile Bölüm 20 ("Büyük Saat") çok benziyor; Bölüm 19 oyundan çıkarıldı, yerine yenisi YAPILMAYACAK. Sahnesi silinmedi: `scenes/bolumler/arsiv/bolum_19_arsiv.tscn`. Taslağı `docs/devir/arsiv/bolum_19_taslak.md`. Testleri kaldırıldı (test_runner.gd'de "arşivlendi" notu).
- **Numaralar:** eski 20 -> 19 "Büyük Saat", eski 21 -> 20 "Mandal", eski 22 -> 21 "Fitil ve Mühür"; toplam 21. Tablo: `docs/devir/numara_esleme.md`.
- **Dosya adı kararı:** sahne dosyaları yeniden adlandırıldı (`bolum_20/21/22.tscn` -> `bolum_19/20/21.tscn`), disk ve liste tutarlı. Gerekçe: numara zaten listedeki sıradan türetilir; dosya adı sıradan bağımsız bırakılırsa "Bölüm 19 = bolum_20.tscn" kafa karıştırır ve testlerdeki sahne yolları ile gösterilen numara ayrışırdı. Eşleme testlerle (tam koşu) doğrulandı: çözüm/başarısızlık/atlanamazlık testleri yeni adlarla geçiyor. Test işlevleri/sabitleri/bayrakları (`--b20` vb.) aynı eşlemeyle yeniden adlandırıldı. Sahne içeriği (fizik, kayıt formatı) değişmedi.
- **Harita:** zincir 18 -> 19 -> 20 -> 21; 19 @ (1040, 510), 20 @ (860, 510), 21 @ (680, 510); eski 22. konum (500, 510) boşaldı. `harita_yerlesim.md` tablosu 21 satır; ilgili test eşikleri (`tablo.size() >= 21`, `dosya_say >= 21`) güncellendi.
- **Not:** bu günlükte, `gece_notlari.md`'de ve eski raporlarda önceki girişler eski numaralarla yazılmıştır (tarihsel kayıt); `numara_esleme.md` ile okunur.

## 2026-10-19 — Bölüm 18: max_klon = 2, "?" ikonu kaldırıldı (kullanıcı kararı)
- **Karar:** Bölüm 18 "Vardiya" `max_klon = 3` -> `2`; `ipucu_klon = 2` -> `0` (ikon ve hover metni yok). Kullanıcı bölümü 2 klonla çözdü. İkon yalnızca Bölüm 4 (2) ve Bölüm 6 (1)'da kalır. Önceki karar (2026-10-16, "Bölüm 18 ipucu ikonu") geçersiz.
- **Doğrulama:** çözüm 2 klonla (A, B + oyuncu, gerçek R/girdi yolu) `max_klon = 2` altında geçiyor; `--b18` 18/18, `--ipucu` 11/11. Çözüm 2 klonda tutmadığı için "yapma, sorunlar.md'ye yaz" şartı doğmadı.
- **Test güncellemeleri:** B18 çözüm/klon sınırı testleri 2'ye; kilitlenme testi etiketi "1/2"; ipucu testlerinden B18 çıkarıldı (ikon yalnız 4 ve 6; "diğer tüm bölümlerde ikon yok" taraması B18'i artık kapsıyor). B18 ikon görünürlük testi kalktı.

## 2026-10-19 — HUD: bölüm numarası ve adı (kullanıcı kararı)
- **Karar:** her bölümde HUD'da "Bölüm 14 · Çekirdek" (adı yoksa "Bölüm 14") görünür. Numara `BolumListesi` sırasından (indeks + 1), ad kayıttan okunur; kod yeni bölümde değişmeden doğru çıkar. Bölüm 1 ve 2 adları ("Giriş", "İkiz") tahmin olarak bırakıldı.
- **Yerleşim kararı:** etiket "Tur | Klon | R" satırının hemen üstünde ayrı bir `Label` (`BolumEtiketi`, `BolumKatmani`); Bilgi metni (`bilgi.text`) DEĞİŞMEDİ (mevcut testler ve oyun mantığı aynı), yalnız Bilgi satırı 28 px aşağı kaydı. Çizim, çarpışma, fizik, kayıt formatı değişmedi.
- **Test:** `--arayuz` içinde "HUD bölüm etiketi" (tüm 21 bölüm metni/konumu, sabit örnekler 1, 2, 4, 14, 18, 19, 20, 21; ad yoksa "Bölüm N"; test sahnesinde etiket yok).

## 2026-10-19 — Editör: karar bekliyor
- Oyun içi bölüm editörü için taslak yazıldı: `docs/devir/editor_taslak.md` (rev. 2; tasarımcı yazdı, gözden geçirici eleştirdi, düzeltmeler işlendi). KOD YAZILMADI; taslak onaylanana kadar yazılmayacak.
- Kullanıcı kararları (değişmez): editör oyunun içinde (ana menüde "Editör"), yeni bölümler JSON, mevcut 21 .tscn dokunulmaz, aynı çizim/fizik/nesne kodu, kalıcı kurallar geçerli, max_klon <= 3.
- Bekleyen kullanıcı kararları (S1–S5, taslak §10): bölümlerin nerede görüneceği, ekran düzeni, ızgara adımı, çözüm zorunluluğu, kablo. Taslakta yapılan varsayılanlar: hızlar sabit, ipucu_klon v1'de 0, testler kullanıcı klasörünü kullanmaz.

## 2026-10-19 — Editör: S1–S5 kesinleşti (kullanıcı kararı), taslak rev. 4
- **S1:** yapılan bölümler editörde "Bölümlerim" listesinde; "Canlıya al" bölümü oyun zincirine kullanıcının seçtiği sıraya ekler, sonraki numaralar otomatik +1 (numara `bolumler_listesi.gd` sırasından türer, mevcut .tscn dosyaları yeniden adlandırılmaz). Doğrulanmamış bölümde canlıya almadan önce uyarı, yine de izin. Numaraya bağlı mevcut testler taslak §8.4'te (T1–T22) listelendi; A12'de sahne yoluna bağlanacak.
- **S2:** 1:1 tuval, gizlenebilen panel. **S3:** nesne boyutları mevcutla birebir, ızgara 20 px (Shift 10 px, ekran kenarı mıknatıs, kapatılabilir). **S4:** çözümsüz bölüm Dene'de ve Bölümlerim'de oynanır, yalnız uyarı. **S5:** kablo otomatik, ara noktalar sürüklenerek ayarlanır, çarpışmaz, lazerden görsel olarak ayrışır; `gorunum.gd` görünüm eki (şalter/asansör kablosu) A11'de (B20 ve B21 kablolarını da etkiler).
- **Varsayılanlar (kullanıcı itiraz edebilir):** Y1 canlı kopya dondurulur, "Canlıyı güncelle" ile yansır; Y2 harita üst sınırı 40 bölüm.
- Yeni aşama A12: Canlıya al + yeniden numaralama + harita konumu. A1–A4 (arka plan işleri) bu turda uygulanır; mevcut testler A1–A11'de değişmez.


## 2026-10-20 — Editör A3/A4 sapmaları (gözden geçirici koşulları)
- **Doğrulayıcı girdi önceliği:** `CozumDogrulayici` `process_physics_priority` en yüksek değerde; girdi karenin sonunda basılır. Taslağın ilk hâli (en düşük) zıplamayı klona göre 1 kare geç gösteriyordu; testle (canlı/klon yörüngesi 0 px fark) doğrulandı.
- **D5 geçit istisnası:** resmî B8/B12/B19 geçitleri açılırken tavana kayar; editörde HATA alıp kurulamaz olmasın diye geçitte üstten taşma serbest (varsayılan karar, itiraz edilebilir).
- **D6 eşiği 640 px**, **D15** üstte ≥ 50 px boşluk uyarı vermez (B14 GecitA), **D24** merkez mesafesi (varsayılan kararlar).

## 2026-10-20 — Editör A5 kapsam kararları
- **Kapsam:** yalnız iskelet: Editör butonu, 1:1 tuval, gizlenebilen palet (Tab) ve çubuklar (H), ızgara (20 px, Shift 10 px, G ile kapanır, kenar mıknatısı), Blok/Başlangıç/Çıkış, seç/taşı/boyutla/sil, geri al/yinele (100), Yeni/Kaydet/Aç. Dene, Doğrula, bağlantı/kablo, Bölümlerim, Canlıya al A6+ aşamalarına bırakıldı (buton bile yok).
- **Ana menü** editör sınıflarına başvurmaz (yalnız sahne yolu): `BolumKurucu` 13 betik preload ettiği için fizik sırası kayabilir; editör ancak girilince yüklenir.
- **Varsayılan kararlar:** kimlik ilk Kaydet'te kilitlenir; şema HATA'lı dosya Aç ile reddedilir; ad alanı yalnız tıklamayla odaklanır; başlangıç/çıkış `@baslangic`/`@cikis` seçim kimlikleri.

## 2026-10-20 — Editör A6 (Dene akışı) kararları
- **Dene:** üst çubukta "Dene" (ve F5): önce `BolumDenetci.statik`; HATA varsa açılmaz (durum çubuğunda ilk hata), çözümsüzlük engel değil (S4). Durum `EditorOturumu` (statik veri) ile taşınır; dönüşte geri yüklenir. Menüden açılan editör hep boş başlar ve oturumu temizler.
- **Dene kipi** yalnız `BolumYollari.dene_mi` iken: ev butonu ve "Editöre dön" editöre gider, "Sonraki" yerine "Çözümü kaydet ve editöre dön" (çözüm yalnız oturuma yazılır, dosyaya Kaydet ile). Resmî bölüm davranışı ve `bolum.gd` değişmedi; `EditorOturumu`'na yalnız dene dalında `load` ile başvurulur.
- **A5 düzeltmeleri:** durum çubuğu şeffaf (outline'lı yazı) ve tuvali örtmez; Yeni/Aç/Menü kaydedilmemiş işi sormadan atmaz (`kirli_mi`, `OnayDiyalogu`).
- **Fizik kayması bulgusu (A6, 2026-10-20) ve çözümü:** `bolum_kurucu.gd` yüklenince Bölüm 13/14 çözümünün bitiş karesi 1 kare kayıyordu (231→230, 556→557; konumlar ortak karelerde 0,0000 px). Kök neden (ölçüldü): `const LAZER_SAHNESI := preload("res://scenes/lazer.tscn")`; paylaşılan `RectangleShape2D` kalıcı önbellekte tutulunca fizik RID sırası (geniş-faz) değişiyor. Çözüm: 10 sahne sabiti yol metni, `_ornekle` her seferinde `load` eder. Kural: `lazer.tscn`'yi (ya da paylaşılan şekilli bir sahneyi) kalıcı önbelleğe sokan hiçbir `preload`/statik başvuru eklenmez; `tests/dene_fizik_testleri.gd` bunu yakalar.
- **Bilinen, A6'dan bağımsız:** `change_scene_to_file` yeni sahneyi eski sahne canlıyken yüklediği için lazerli bölümden "Sonraki/Tekrar/Baştan başla" ile geçişte de aynı ±1 kare bitiş kayması görülebilir (iz 0 px aynı). `docs/sorunlar.md`'deki canlı/klon geniş-faz kırılganlığı (A/C kararı) ile aynı aile; bu değişiklik onu çözmez.
- **Çözüm kaydı geri al/yinele'de korunur** (anlık görüntüye de yazılır); Enter'sız yazılan ad kirlilik ve kayıt öncesinde işlenir.

## 2026-10-21 — Editör A7 (bağlantı ve kablo arayüzü) kararları
- **Kapsam:** palet: Plaka, Geçit, Asansör, Bağla, "Kabloyu sıfırla", "Kabloyu gizle/göster". Diğer türler (kutu, zıplatıcı, bant, tek yönlü, lazer, şalter, zamanlı/mandal plaka) A8'de geldi. Veri işlemleri ayrı sınıfta: `scripts/editor/baglanti_islemleri.gd` (`BaglantiIslemleri`, saf veri, testlenebilir); arayüz `editor.gd`'de.
- **Bağla (K8):** önce tetikleyici, sonra hedef; zaten bağlıysa kaldırır. Asansöre tam 1 plaka; ikinci plaka onay diyaloğuyla öncekinin yerine geçer (eski kablo kaydı silinir); şalter asansöre reddedilir. Geçit/lazere 0..n tetikleyici. `B` seçili tetikleyiciyle başlatır, `Esc` iptal eder. Yerleşen asansör plakasız D3 HATA verir (Dene açılmaz) — bilinçli: asansörün plakası zorunlu.
- **Silme:** nesne silinince ona giden bağlantılar (tetikleyiciler, kablo kayıtları, asansör `plaka`) aynı geri al adımında temizlenir.
- **Kablo:** yol hedefte saklanır (`kablolar[]` / `kablo`). İlk düzenlemede otomatik L köşesi açık `ara` listesine dönüşür. Parçaya basıp sürükleme yeni ara nokta doğurur (8 px nokta, 6 px parça eşiği; ızgaraya oturur), ara noktaya çift tık siler; liste boşalınca kayıt silinir ve yol otomatik L'ye döner. Kablo, blok/başlangıç/çıkış ile çakışırsa kablo öncelikli; plaka/geçit/asansör gövdesi kablodan öncelikli (ara nokta hariç).
- **`uclar`:** dışarıdan gelen veride korunur; tetikleyici ya da hedef taşınınca o bağlantının `uclar` alanı silinir ve uçlar hesaplanır. Taşınan tetikleyiciye bağlı hedefler yeniden kurulur (kablo meta'sı tetikleyici konumundan gelir).
- **Gizli kablo:** meta yazılmaz, bağlantı çalışır; editör kesik çizgiyle gösterir ve seçilip tekrar gösterilebilir.
- **Önizleme:** tuvalin arka planı artık `Zemin` düğümü (z_index −100): geçit/asansör görünümü `z_index −1` kullandığı için eskiden tuval arka planının altında kalıyordu. Geçit/lazer `_ready`'de `get_node` yaptığından önizleme önce tetikleyicileri sonra hedefleri kurar (sonra JSON sırasına dizer); eksik tetikleyiciye giden yol atlanır.
- **Parametre tutamağı:** seçili asansörün üst konumu / geçidin açık konumu üst kenarındaki tutamak yükseklik (20..600) / kayma mesafesi (10..200) ayarlar; açık konum kesik çizgili hayalet.
- **Bilgi:** `gorunum.gd` yalnız ilk iki geçit/lazer kablosunu çizer; asansör ve 3. kablo A11'e kadar oyunda görünmez, editör bunu durum satırında "Bilgi" olarak yazar. Editör tüm kabloları kendi katmanında ince çizgiyle gösterir (oyun görünümüne ek, ona dokunmaz).
- **Ertelenenler:** 40 px zemin mıknatısı, Shift+tık çoklu seçim, `acik_taraf_sag`/`tetik_aktifken_kapali` arayüzü (şalter/lazer A8), D26 için ayrı arayüz bilgisi.

## 2026-10-21 — Editör A8 (kalan türler, özellik paneli, lazer ucu) kararları
- **Kapsam:** palete zamanlı plaka, mandal plaka, şalter, lazer, kutu, zıplatıcı, bant, tek yönlü eklendi; palet 16 araçla iki sütuna geçti (tek sütun tuvale fazla biniyordu). Yerleştirme tek kod yoluyla (`yerlesen_turler`), kimlikler `ZamanliPlaka1`, `MandalPlaka1`, `Salter1`, `Lazer1`, `Kutu1`, `Ziplatici1`, `Bant1`, `TekYonlu1`.
- **Varsayılanlar (taslak §1.3):** zamanlı plaka `tutma_kare` 180, şalter `baslangic_sagda` false, bant `yon` 1, lazer `yon` asagi / `uzunluk` 200 / `tetik_aktifken_kapali` true / `acik_taraf_sag` true. Kutu, zıplatıcı, tek yönlü ve mandal plakanın ayarlanabilir alanı yoktur.
- **Özellik paneli** (sağ üst, seçili nesneye göre satırlar): bant yönü düğmesi, zamanlı plaka tutma süresi (1..600 kare), şalter başlangıç tarafı, lazer yönü / uzunluğu (10..1100) / "Tetikleyici basılıyken kapalı", geçit ve lazer "Şalter sağdayken açık" (`acik_taraf_sag`), geçit kayma mesafesi, asansör yüksekliği. Tek doğrulama noktası `ozellik_ata(id, alan, değer)`: aralık dışı sayı kıstırılır, tür/değer uyumsuzluğu reddedilir, aynı değer geri al kaydı atmaz. Alan adı panelde kullanıcıya sade metinle yazılır (taslak bunları "gerektiğinde görünür" demişti).
- **Lazer ucu tutamağı:** ışının ucundaki tutamak yayıcıdan uzağa sürüklenince baskın eksen yönü, o eksendeki uzaklık uzunluğu belirler (10..1100; taslak §3.2 "uç tutamacı uzunluk ve yönü"). Işın 6 px incedir; seçmek için yayıcı çevresindeki 24x24 px de lazeri seçer.
- **Bilinçli sınırlar:** 40 px zemin mıknatısı ve Shift+tık çoklu seçim hâlâ ertelenmiş; `uzunluk` üst sınırı arayüzde 1100 (şema üst sınır koymaz, D5 bakar); `tutma_kare` için fare tutamağı yok, yalnız panel.

## 2026-10-21 — Editör A9 (Doğrula) kararları
- **Akış (taslak §6.4):** "Doğrula" düğmesi / F6. Statik HATA varsa ve çözüm kayıtlı değilse başlamaz (mesaj). Çözümsüzlük Dene'yi engellemez (S4). Doğrulama bölüm sahnesini defalarca yeniden yüklediği için editör sahnesi yok olur: `scripts/editor/editor_dogrulama.gd` (`EditorDogrulama`, `root` altında CanvasLayer) şeridi ve İptal düğmesini gösterir, `CozumDogrulayici` + `BolumDenetci.dinamik` çalıştırır, sonucu `EditorOturumu.dogrulama`'ya yazıp editöre döner; editör `_oturumdan_yukle`'de `veri["dogrulama"]`yı işler (geçmişe kayıt atılmaz).
- **`dogrulama` kaydı:** `{durum, icerik_ozeti, hata, uyari, bitis_kare}`; `durum` "dogrulandi" ancak dinamik HATA (D9–D12) yoksa. `hata` yalnız dinamik HATA sayısıdır, `uyari` statik + dinamik UYARI. İçerik değişince özet tutmaz → "Taslak (doğrulanmadı)"; geri alınca özet yine tutar. Durum çubuğunda "Doğrulandı / Taslak (doğrulanmadı) / Taslak (çözüm yok)".
- **İptal:** Esc ya da İptal; hiçbir şey yazılmaz (önceki kayıt aynen kalır), `Kayitlar` boşalır. Bekleme sırasında gelen iptal `toplu_basla` yüzünden kaybolmasın diye `dinamik` iptalde hiç başlatılmaz (gözden geçirici bulgusu).
- **Girdi sızıntısı önlemi:** doğrulama sürerken bütün klavye olayları şerit katmanında tüketilir (sonuç ekranı düğmesi ve oyun kısayolları karışmaz) ve `bastan`/`tur_bitir` eylemleri her fizik karesinde oyun düğümlerinden önce bırakılır. Bilinen kalan kısıt: `Input` eylem durumu olay dağıtımından önce güncellendiği için fiziksel yön/zıplama tuşları engellenemez; şerit "tuşlara basmayın" der. `CozumDogrulayici` (A3) değiştirilmedi.
- **Çift başlatma:** doğrulama sürerken Doğrula ve Dene başlamaz.
- **D10 kayıt karşılaştırması tek seferliktir:** kayıtlı bitiş karesi ölçülenden farklıysa sonuç "taslak" olur ama yeni ölçüm kayda yazıldığı için ikinci Doğrula geçer (kayıt yeniden temel alınır). Taslakta yazılı değildi; varsayılan karar.
- **Açık soru:** `kirli_mi` çözüm ve doğrulamayı saymaz (A6'dan beri çözüm için aynı): Doğrula'dan sonra Kaydet'siz Menü/Yeni onay sormaz, doğrulama kaybolur (yeniden hesaplanabilir). Kullanıcı kararı bekliyor.
- **Ertelenen:** D12 kısayol fikstürü ve çok klonlu (D13 eksik klon) uçtan uca testi; "Oyna açık kalır" A10'da.

## 2026-10-21 — Editör A10 (Bölümlerim ekranı) kararları

- **Giriş:** Bölümlerim'e editör çubuğundaki "Bölümlerim" düğmesinden girilir (kirliyse onay sorar; doğrulama sürerken girilmez). Ana menüye düğme eklenmedi: ana menü editör sınıflarına başvurmaz (fizik sırası kırılganlığı).
- **Liste:** `<kok>bolumler/*.json`, dosya adına göre sıralı (deterministik). Satır: "Ad · durum · N hata · N uyarı". Durum metni `BolumVerisi.dogrulama_durumu` ile editörle ortaktır. Okunamayan ya da şema HATA'lı dosya "Bozuk" gösterilir (şema HATA'sı varsa başka hiçbir alan okunmaz); Aç ve Oyna kapalı, Sil açık kalır (bozuk dosya silinebilsin).
- **Oyna:** `<kok>oyna/oyna_NNN.tscn` (bir öncekini siler). Çözümsüz/doğrulanmamış bölüm uyarıyla oynanır (S4, HUD amber satırı); statik HATA'lı bölüm oynanmaz. Kip `ozel`: HUD "Özel · Ad", sonuç ekranında "Sonraki" gizli, "Menü" = "Bölümlerim'e dön", ev butonu Bölümlerim'e gider (`BolumYollari.ev_sahnesi`).
- **Aç:** `EditorOturumu.ac_yolu` + `EditorOturumu.kok` ile editöre geçilir; editör `_ready`'de dosyayı yükler (şema HATA'lı dosya açılmaz). Aç, statik HATA'lı ama şeması geçerli dosyaya izin verir (editörde düzeltilsin diye).
- **Sil:** her zaman onaylıdır (`sil_iste` → diyalog → `sil_onayla`); yalnız `bolumler/` altındaki o JSON silinir. Canlı kopyalar A12'de gelecek.
- **Kök taşıma:** `EditorOturumu.kok` Bölümlerim, Oyna, editör ve Dene arasında dosya kökünü taşır (gerçek oyunda hep `user://`; testlerde `user://test_editor/`).
- **Açık:** "Oyna açık kalır" sorusu bu parçada kapandı (çözümsüz bölüm oynanıyor). Oyna, tıklama anında dosyayı yeniden okur ama statik denetimi yeniden çalıştırmaz (liste ile tıklama arasında dosya dışarıdan değişirse risk; çok düşük).

## 2026-10-21 — Pencere 1920x1080, iç çözünürlük 1152x648
- **Karar (kullanıcı):** Pencere 1920x1080 açılır, oyunun iç çözünürlüğü (viewport) 1152x648 kalır. `project.godot` `[display]`: `viewport_width=1152`, `viewport_height=648`, `window_width_override=1920`, `window_height_override=1080`, `stretch/mode="canvas_items"`, `stretch/aspect="keep"`.
- **Neden bu yol:** Viewport sabit kaldığı için fizik, bölüm koordinatları ve editör yerleşimi değişmez; yalnızca çıktı ölçeklenir (1920/1152 = 1,667x). `canvas_items` çizimi hedef çözünürlükte yaptığı için çizgiler ve yazılar keskin kalır; `keep` farklı en-boy oranında siyah bant bırakır, görüntü bozulmaz.
- **Tam ekran:** `scripts/tam_ekran.gd` (autoload `TamEkran`) F11'de pencere / tam ekran arasında geçer. `_input` kullanır, böylece editör doğrulama şeridi klavyeyi tüketirken de çalışır. Headless'ta işlem yapmaz. Oyun durumunu okumaz, yazmaz.
- **Bilinçli sınır:** F11 `InputMap` eylemi değil, sabit tuştur (Kontroller ekranında listelenmez).

## 2026-10-21 — Editör A11 (kablo görünüm eki) ve kirli_mi düzeltmesi (kullanıcı onaylı)
- **Kablo eki (`scripts/gorunum.gd`, yalnızca görünüm):** `_kablo` genelleşti: `kablo_plani(p)` her `kablo_<N>` için sıra verir (kablo = 1. tetikleyici, `kablo_N` = N. tetikleyici); yalnız `kablo` varsa eski kural (herhangi bir tetikleyici yakar) aynen sürer. Şalter kablosu hedefin `acik_taraf_sag` değeriyle eşleşince yanar. Asansör kablosu `_asansor` içinde çizilir (z −1, `plaka.basili_mi()` ile yanar). Her ara noktada uçlardaki gibi perçin halkası. `kablo_yanik_mi` / `kablo_plani` genel işlevleridir (headless test noktası); çizim hâlâ headless'ta atlanır.
- **Lazerden ayrım (taslak §4.3):** kablo kodunda kırmızı/amber yok (test okur), 3 px iç + 5 px koyu dış hat, durağan; lazer kırmızı, kalın, nabızlı. Elle ekran görüntüsü kontrolü yapıldı (şalter, asansör, lazer aynı sahnede).
- **Resmî bölümlerde kanıt:** 21 bölümün 90. fizik karesindeki ekran görüntüleri değişiklik öncesi/sonrası piksel piksel karşılaştırıldı: B1–B19 birebir aynı. Yalnız B20 (`GecitG` kablosunun 2 ara noktası) ve B21 (5 ara nokta) farklı; farklı olan her piksel bu ara noktaların 8 px çevresinde (perçin halkası, taslak §9.2'de önceden bildirilen değişiklik). Fizik, çarpışma ve sahne dosyaları değişmedi.
- **`kirli_mi` düzeltmesi:** `BolumVerisi.kirlilik_metni` = içerik özeti + çözüm kaydı + doğrulama sonucu. Çözüm ya da doğrulama Kaydet'siz kalırsa Yeni/Aç/Menü/Bölümlerim onay sorar. (A9'daki "açık soru" kapandı; içerik özeti ve D10 mantığı değişmedi, çünkü `kanonik_metin` hâlâ çözüm/doğrulamayı atar.) Editörde "Ev" düğmesi yoktur; Dene'deki Ev editöre döner ve kirlilik oturumla taşınır.
- **Bölüm 16/17 v2 kaydı düzeltildi:** v2 taslakları 2026-10-16'da onaylandı ve uygulandı; bugün Bölüm 20 "Mandal" ve Bölüm 21 "Fitil ve Mühür" (ilk numaraları 21/22'ydi). Sahnedeki 16/17 eski (v1) sürümdür, bilinçli kalır. `CLAUDE.md` ve `durum.md` buna göre düzeltildi.
- **Test koşucusu:** `--ed-a11` bayrağı eklendi (yalnız A11 grubu, hızlı).

## 2026-10-27 — Editör A12 (Canlıya al, birleşik liste, harita yerleşimi) (kullanıcı onaylı)
- **Kapsam (kullanıcı):** Bölümlerim'deki bölüm, oyun zincirinde seçilen sıraya eklenir; sonraki numaralar +1; numara `BolumListesi.liste()` sırasından (`indeks + 1`) türer; HUD ve harita buna uyar; mevcut `.tscn` dosyaları yeniden adlandırılmaz; çözümü doğrulanmamış bölümde "Çözüm doğrulanmadı, yine de ekleyeyim mi?" uyarısı çıkar ama izin verilir (S4); canlıdan kaldırma numaraları geri kaydırır.
- **Çekirdek:** `BolumListesi.BOLUMLER` 21 resmî kayıt olarak değişmez. `liste()` (önbellekli, SAF OKUYUCU: dosya yazmaz, sahne kurmaz, denetim çalıştırmaz; kaynağında BolumKurucu/BolumDenetci/CanliBolumler geçmez, testle korunur) resmî + `<kök>canli/sira.json` kayıtlarını birleştirir. `yenile()` önbelleği atar; canlıya al/güncelle/kaldır hep çağırır. `kullanici_kok` varsayılan `user://`, test koşucusu `_initialize`'da `user://test_editor/` yapar (gerçek canlı bölümler testleri etkilemesin). `yollar/sonraki/indeks/baglantilar/ad/baslik` ve `harita.gd` artık `liste()` okur. `olustur(kok)` önbelleksiz kurucudur (Bölümlerim kendi kökü için kullanır).
- **Yerleştirme:** `sonra` = "" (en başa), resmî sahne yolu ya da `canli:<kimlik>`. Zincirleme çalışır. Yeri bulunamayan (silinmiş hedef, döngü) kayıt, ona bağlı olanlarla birlikte sona eklenir ve `son_uyarilar` dolar. Sahne dosyası olmayan ya da yinelenen kayıt atlanır (uyarı). Bozuk `sira.json` canlıları yok sayar (uyarı), oyun açılır.
- **Harita (`HaritaYerlesimi.konum(i, n)`):** 4 satır sabit (y 165..510, aralık 115), sütun = max(6, ceil(n/4)), x aralığı 900/(c-1), yılan sırası. n <= 24 için 21 resmî bölümün bugünkü konumlarıyla birebir aynı (testle). Üst sınır 40 bölüm (Y2); sınırda en yakın iki düğüm 100 px. Canlıya al 40'ta reddedilir (C3); `sira.json`'a elle girilen fazlalık alınmaz (uyarı).
- **`CanliBolumler` (editör kodu):** `canliya_al(veri, sonra, kok)`, `guncelle(veri, kok)`, `kaldir(kimlik, kok)`, `sira_oku`, `numara`, `degisti_mi`, `sira_secenekleri`. Statik HATA engeller (C1 zaten canlı, C2 geçersiz sıra, C3 sınır, C4 canlı değil, C5 yazma hatası); çözümsüzlük engel değildir. Dondurulmuş kopya `canli/<kimlik>.json` (Y1), sahne `canli/<kimlik>_v<NNN>.tscn`; her güncellemede yeni sürüm yolu, eski dosya silinir (kaynak önbelleği tuzağı); kaldır + yeniden ekle de eski yolu yeniden kullanmaz (oturum sayacı + sira.json taraması). Bölümlerim JSON'una `canli` aynası yazılır (içerik özetine girmez).
- **Kaldırma:** kayıt, JSON ve sahne silinir; kaldırılana bağlı canlıların `sonra` değeri kaldırılanın `sonra` değerine devredilir; Bölümlerim'deki kopya kalır. Canlı bölüm Bölümlerim'den silinemez (önce "Canlıdan kaldır"); aksi halde canlı kopya arayüzsüz öksüz kalırdı.
- **Arayüz (Bölümlerim):** "Canlıya al" (çözümsüzse uyarı onayı, sonra "Şundan sonra: Bölüm N · Ad" seçicisi, varsayılan en sonda; "En başa" ilk seçenek), canlıysa "Canlıdan kaldır" (onaylı) ve "Canlıyı güncelle" (yalnız içerik ya da çözüm durumu canlı kopyadan farklıysa açık, onaylı). Satır "… · Canlı: Bölüm N (değişti)". Seçenek metni ek getirmez (Türkçe "'dan/'tan" uyumu sorunu yüzünden "Şundan sonra: …").
- **Editör durum notu:** "asansör ve 3. kablo oyunda henüz çizilmez" bilgisi (A11'den beri yanlış) kaldırıldı; A7 testi artık editördeki her kablo meta'sının oyun çizim planında (`Gorunum.kablo_plani`) karşılığı olduğunu doğrular.
- **Testler (T1–T22):** `BOLUMLER` döngüleri `liste()`'ye, sabit numaralar sahne yoluna bağlandı (bkz. `testler.md`); hiçbiri silinerek geçilmedi. Düzeltilmiş hâlleri A12 grubunda iki canlı bölümle de (araya ve zincirleme) yeniden koşar ("[A12: canlı bölümlerle]" önekiyle). `harita_yerlesim.md` tablosu yalnız 21 bölümlük belgedir, `HaritaYerlesimi.konum(i, 21)` ile eşitliği testlenir; "rezerve konum" denetimi kaldırıldı (konumlar artık canlılara verilebilir).

## 2026-10-27 — Editör A12 görsel düzeltmeleri (pencereli ekran görüntüsü incelemesi sonrası, kullanıcı onaylı)
- **İnceleme yöntemi:** pencereli Godot ile 26 ekran görüntüsü alındı (ana menü, editör, Bölümlerim, canlıya al akışı, harita, canlı bölüm HUD, Dene, Doğrula); bulgular aşağıdaki beş düzeltmeyle giderildi, aynı görüntüler yeniden alınıp doğrulandı. Resmî düğüm/bölüm ekranları piksel piksel karşılaştırıldı (ana menü, bölüm 10 ve sonuç ekranı birebir aynı; haritada yalnız canlı düğümün halkası farklı, bir düğümdeki fark gerçek fare imlecinin hover'ı).
- **Bölümlerim satırı:** iki satır. Üstte ad (`Metin`, uzunsa "…" ile kısalır, tam metin ipucunda), altta `DurumSatiri`: durum · "Canlı: Bölüm N" · hata/uyarı sayısı; bu satır kırpılmaz, gerekirse sarar. Hatalı satırın alt satırı amber. Panel 760 → 900 px (40 karakterlik ad ve beş düğme sığar). Düğümler `Satir_<ad>` altında doğrudan çocuk kaldı (testler/yollar aynı). `satir_metni` aynı çıktıyı verir (= ad + " · " + `durum_metni`).
- **Sıra diyaloğu:** açıklama metni (`SiraAciklama`) ve `OptionButton` tek `VBoxContainer`'da (açıklama üstte); eskiden seçici dialog_text'i örtüyordu. `dialog_text` boş bırakıldı.
- **Diyalog başlıkları:** Godot varsayılanı İngilizce ("Please Confirm...") idi. Bölümlerim onay (sil/kaldır/güncelle) "Onayla", çözüm uyarısı "Uyarı", sıra seçimi "Hangi bölümden sonra?", editör onayı "Onayla". Kaynak taraması testi: `scripts/` altında oluşturulan her diyalog için bir `.title =` ataması şart (yeni diyalog başlıksız eklenirse test kalır).
- **Harita işareti:** canlı düğüm ince açık altıgen halka (`HaritaDugumu.canli`, yarıçap 38,5 px, 80x80 kutunun içinde); hover etiketi "Bölüm N: Ad · Canlı". Resmî düğüm ve etiketlerin çizimi değişmedi (`canli` false iken `_draw` yolu aynı; etiket 280 px, aynı konum). Uzun canlı etiket genişler, düğümün altında ortalanır, ekran kenarına kenetlenir; ölçüm ağaçtan bağımsız yazı tipiyle yapılır (ilk denemede ağaca eklenmemiş Label ölçümü yanlıştı: gözden geçirici yakaladı, ekran görüntüsüyle doğrulandı).
- **Doğrulama şeridi:** "Doğrulama sürerken tuşlara basmayın." METAL (~3,3:1) → AMBER (~5:1, WCAG AA); testle korunur.
- **Bilinçli sınırlar:** çok uzun canlı etiket komşu bağlantı çizgisinin üstünden geçebilir (yazı konturlu, okunur); çözümsüz bölümde "(değişti)" mantığı aynı. Başarılı "Doğrulandı" yolu bu incelemede ekranda yeniden görülmedi (testler kapsıyor).
