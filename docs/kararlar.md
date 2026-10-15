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
