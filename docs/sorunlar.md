# Sorunlar / bulgular

## 2026-10-15 Bölüm 9: kutuda takılan asansör F2'ye basamak olur (pay ~0,5 px)
- Ölçüm testi: `Bölüm 9 ölçüm: asansör kutuda takılıp basamak olur; 2 klonla bölüm yine de bitmez` (tests/test_runner.gd).
- Senaryo: k1 Plaka1'i tutar; ikinci klon Plaka2'ye basıp asansörü kaldırır, sonra plakadan iner; oyuncu kutuyu yukarıdaki asansörün altına (x~590) iter. Asansör inerken kutuya oturur (merkez y=546, üst yüz ~536). Oyuncu bu basamaktan zıplayıp F2'ye çıkabiliyor (ayak y min 435,7; zıplama tepesi 96,5 px, basamak yüksekliği 96 px, pay ~0,5 px).
- Sonuç: tasarım iddiası "F2'ye zeminden/kutudan çıkılamaz" asansör+kutu birleşimiyle fiziksel olarak delinir. F2'de L1 (Plaka3 boş) ve G (PlakaKutu boş) kaldığından 2 klonla bölüm bitmiyor; 3 klonla (k1, plaka tutucu, kutuyu iten+Plaka3) yine G'yi açacak kimse kalmadığı için bitmiyor (analiz, test yok). Yani bölüm çözümü bozulmuyor, ama kenar payı çok dar; fiziksel değişiklikle (asansör hızı, kutu boyu) kolayca yol açabilir.
- Karar kullanıcıya: kabul edilir mi, yoksa asansör yukarısına kutu üstü + 100,9 px sınırı garanti edilsin mi (örn. kutu üstü 560 yerine yüzey farkı > 100,9).

## 2026-10-15 Bölüm 6: geçit altı park (röle) kısayoluyla TEK KLONLA bitiyor (max_klon=2, taslak min 2)
- Ölçüm testi: `Bölüm 6 röle araştırması (ölçüm)` (tests/test_runner.gd, `--b12` ya da tam koşu).
- Çözüm: tur 1'de tek klon PlakaA'da T kare bekler, sonra tam D=117 kare `sag` basar (kör kayıt, gerçek dünyada kayıt turunda klon kapalı geçide takılır, yani oyuncunun yapabileceği girdi). Son turda oyuncu geçidin altına (x 575..585) yürüyüp park eder, klon PlakaA'dan ayrılınca geçit oyuncunun başına çarpıp ~48 px'te kalır, klon altından geçip PlakaL'e varır (lazer kapanır, asansör kalkar); oyuncu klon geçince normal son turu oynar. T=100/120/150/200 x park x=575/580/585 = 12/12 varyant bitti (343-443 kare, ölüm 0).
- Etki: Bölüm 6 "min klon 2" iddiası yanlış; 1 klonla bitiyor. Kök neden: `gecit.gd` kapanırken altında karakter varsa durur ve klon girdiyi oynatır (konumu değil).
- Karar kullanıcıya: kabul / geçit kuralı değişsin (örn. parkta bile kapansın, geçit kapanırken karakter ezilmesin tek yönlü) / bölüm yeniden ayarlansın. Mevcut testler değiştirilmedi.

## 2026-10-15 Bölüm 7, 9, 10: röle kısayolu klon sayısını düşürmüyor (ölçüm)
- Bölüm 7: tek geçit şalterle açılır (plaka tutucusu yok), park anlamsız. Z' klonu PlakaB'de T=0/30/60/100 kare durup PlakaC'ye geçer (rolleri birleştirme): L1 açılınca Z' ışına girer, A+Z' ile bitmedi (4/4). Asansör altında park: A ayrılınca asansör parktaki karakterin üstünde y=538'de kalır (F2 için ≤390 gerek), asansörü yüksekte tutmaz.
- Bölüm 9: tek geçit (G) yalnız son oyuncunun yolunda; klonların geçmesi gereken plaka-tutulan geçit yok. Oyuncunun Plaka1'i tutup k2'yi geçirmesi sonra L0'ı kendisinin geçememesi (tutucu yok, ışında ölür), 2 klonla bitmedi (2/2).
- Bölüm 10: G yalnız oyuncunun yolunda, PE ve P2 aynı anda basılı olmalı (aralarında 40 px). Tek klon P2'de T=20/40/80 durup PE'ye geçince (+C ya da tek) bitmedi (6/6).
- Sonuç: yalnız Bölüm 6 (ve Bölüm 12 tasarım gereği "ortak plaka" yapısı) etkileniyor; 7, 9, 10 için 3 klon iddiaları ölçümle korunuyor.

## 2026-10-15 Bölüm 12 ölçüm bulguları (taslakla farklar; hepsi raporlandı, kod değiştirilmedi)
- Taslak §10.5 "Y2 kutu inmeden Zıplatıcı'ya girerse kutu/karakter çarpışması, çözüm bozulur" tam doğru değil: kutu karakterlerle çarpışmaz (yalnız `it()` ile itilir). Y2 `x>=477`'den sonra 10+ kare beklerse (kutu ~55 kare havada) çözüm yine tamamlanır; 1..6 kare beklerse kutu R üstünde x=500'e kayar ve çözüm bitmez (kilitlenme değil, R duvarları içinde). Pencere alt sınırı 6 (başarısız) ile 10 (başarılı) kare arasında (taslak ~55 kare öngörüyordu).
- Kutu basamağı payı taslakta 6,5 px; ölçülen kutu üstünden zıplama tepesi ayak y=278,2 (R2 üstü 290): pay 11,8 px. Kutu x=500..580 hepsinde (sağ+zıpla) R2'ye çıkılır.
- Oyuncunun Y2'yi izleme gecikmesi L=0..38 çalışır (L=0'da çift itme bozmaz); L>=40 başarısız: GK, plakadan ayrılan kutu yüzünden ~50 karede tam kapanır, geç gelen oyuncu GK'yı geçemez (alternatif: PlakaK'da bekleme).
- GK yarışı payı: Y2 PlakaK'dan ayrıldıktan sonra en çok 3 kare durabilir (açıklık 56 px, gerek 48); taslak ~3,6 kare.
- Y2 başlangıç gecikmesi s>=20 (s=18 başarısız); fırlama sonrası `sag` en geç 4. kareden sonra başlamamalı (gec<=4), en az 5 kare sürmeli.
- Yığma: oyuncu zıplatıcıda fırlayan kutunun üstündeyse kutuyla taşınır ve tepede zıplayıp R2'ye çıkar (ayak y min 188). Tek başına yapılamaz (kutuyu iten gerekir); gerçekte kutuyla GK'dan geçemez (kutu 40 + oyuncu 48 = 88 px, GK en çok ~60 px açık kalır). Klon sayısını azaltmaz (aşağıdaki tarama).
- Röle: mekanizma GK'da doğrulandı (park eden oyuncu varken plakada bekleyip ayrılan klon GK'yı 50 px açıklıkta geçti, parksız 356'da takıldı). Bölümde tek klon x 5 klon varyantı x 8 oyuncu stratejisi (+3 gerçek park-röle) = 43 deneme, 0 bitti. Park-röle (oyuncu kutuyu çıkarıp GA1 altında, klon PlakaA'yı tutup sonra rotayı yürür) klon GK'da (x=356) takılır: kutu plakadan ayrılınca GK'yı tutan yok.
- Kutu GK'ya takılması (kilitlenme): Y2 PlakaK'dan ayrılınca 8-16 kare durursa kutu GK altında 42 px açıklıkta kalır (kutu itilemez, oyuncu geçemez); 20+ kare durursa geçit kapanıp kutuyu x=350'ye iter. İkisi de "Baştan başla" gerektirir (taslak §9.3 doğrulandı).
