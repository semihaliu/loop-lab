# Aşama 3 — Görsel (grafik ajanı)

Tema (DEĞİŞMEZ): "terk edilmiş zaman laboratuvarı" — eski, yarı karanlık bir laboratuvar; paslı metal, soluk yeşil/camgöbeği panel ışıkları, zamanı gösteren saat dişlisi/kadran motifleri, kırık monitörler, çatlak karolar. Tek tutarlı palet, `docs/stil.md`'ye yazılır.

## İstenenler
1. `docs/stil.md`: renk paleti (hex), her nesnenin görünümü, durumlar (plaka basılı/boşta, kapı açık/kapalı, geçit, şalter sol/sağ, lazer açık/kapalı, asansör), oyuncu-klon ayrımı, harita ekranı stili.
2. Karakter: basit koddan çizilmiş İNSAN (kafa, gövde, kollar, bacaklar; laboratuvar önlüğü/tulum). En az 3 poz: bekleme, koşma (en az 2 kare yürüme döngüsü), zıplama/havada. Çarpışma kutusu 28x48 AYNEN kalır; görünüm bu kutuya sığar, yön (sol/sağ) çevrilir. Poz seçimi yalnızca `velocity`, `is_on_floor()` ve uygulanan yön girdisinden türetilir (oyun mantığına yazma YOK, rastgelelik YOK).
3. Klon: aynı insan, şeffaf mavi-camsı görünüm (hologram/cam etkisi), oyuncudan bir bakışta ayrılır. Ölü klon (oldu=true) solgun/gri-koyu ve hareketsiz.
4. Nesneler: basınç plakası, asansör, kapı (hedef), şalter, geçit, lazer (yayıcı + ışın; açık/kapalı net), tek yönlü platform, zemin/duvarlar/tavan. Geçit ve asansörün örtülmesi: Bölüm 4 E2'nin F2 içinde, Bölüm 7 geçidin Kat2 içinde, Bölüm 8 G'nin tavana/K3'e gömülmesi görsel olarak şık dursun (çizim sırası/katmanlar ile; çarpışma/konum DEĞİŞMEZ).
5. Tema arka planı: bölümlerde ortak, katman olarak (CanvasLayer / en alt z): laboratuvar duvarı, borular, kadran/dişli, soluk ışık. Oyun alanını okunaksız yapmamalı (kontrast).
6. Harita ekranı (scenes/harita.tscn, scripts/harita*.gd) ve ana menü/sonuç ekranı: aynı tema. Harita çizim sırası kuralı (Arkaplan < Baglantilar < Dugumler) korunur; 8 düğüm okunaklı.

## Sınırlar
- Yalnızca görünüm. Çarpışma şekilleri, boyutlar, konumlar, fizik, girdi ve oyun mantığı DEĞİŞMEZ. Düğüm adları ve testlerin eriştiği düğüm/özellikler (`Gorsel`, `IsinGorsel` vb.) korunur; testler `$Gorsel.color` gibi alanlara bakıyorsa onlar çalışmaya devam etmeli (kırılırsa yapıyı uyarla ya da değişikliği geri al).
- Harici oyun görseli/ikonu/karakteri kopyalama. Her şey koddan/SVG ile üretilir (assets/ altına SVG olabilir).
- Determinizm: görsel kod `_process`/`_draw` içinde olabilir ama `_physics_process`'teki oyun durumunu etkilemez ve rastgelelik kullanmaz (animasyon kare sayacı fizik karesinden türetilebilir).
- Yorumlar Türkçe.
- Her değişiklikten sonra testleri koş; GEÇTİ olmadan bitirme.
