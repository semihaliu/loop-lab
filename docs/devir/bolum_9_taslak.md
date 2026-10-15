# Bölüm 9 taslağı: "Yük" (`scenes/bolumler/bolum_9.tscn`)
(Tasarımcı çıktısı; Aşama C'de onaysız uygulama kullanıcı kararı.)

Yeni fikir: KUTU. Kutu itilir, plakada tutulur, asansörle F2'ye çıkar ve orada geçidi açık tutar. Nesneler: plaka x4, asansör, geçit, lazer x2, tek yönlü platform, kutu, kapı. Şalter/zıplatıcı/bant YOK. `max_klon = 3` (tam 3 klon; kutu olmasa 4 gerekirdi).
Sabitler: 28x48, HIZ 300 (5 px/kare), zıplama tepesi 96,5 (kare ~100,9), g 1400; kutu 40x40 katman 1+4, yalnız itilir. Asansör/geçit 120 px/sn, asansör position.y merkez (üst yüzey 10 px yukarıda). Zemin yüzeyi 600, oyuncu (100,570). Tek yönlü 120x12 (üst = merkez-6).

## Kat planı
Zemin koridoru y 300..600; asansör E x 580..700, KAT2 yüzü x=702 (2 px boşluk); F2 koridoru y 300..440, x 702..1152. Plaka1 L0'ın SOL tarafında; Plaka2 L0'ın ÖTESİNDE ve platform üstünde (röle kısayolunu kapatır).

## Nesneler (merkez)
| Düğüm | Tür | Konum | Ayrıntı |
|---|---|---|---|
| Zemin | StaticBody2D | (576,620) | 1152x40 |
| Kat2 | StaticBody2D | (927,520) | 450x160 (x 702..1152, y 440..600) |
| Tavan | StaticBody2D | (576,150) | 1152x300 (y 0..300) |
| Platform | scenes/tek_yonlu.tscn | (400,536) | üst 530, x 340..460 |
| Plaka1 | basinc_plakasi | (170,592) | 60x16, Lazer1'i kapatır |
| Plaka2 | basinc_plakasi | (400,522) | 60x16 platform üstünde, asansörü kaldırır |
| Plaka3 | basinc_plakasi | (760,432) | 60x16 KAT2 üstünde, Lazer2'yi kapatır |
| PlakaKutu | basinc_plakasi | (930,432) | 60x16 KAT2 üstünde, Gecit'i açar |
| Asansor | asansor.gd | (640,610) | 120x20, plaka=../Plaka2, yukseklik=160 (üst yüzey 440), x 580..700 |
| Gecit | scenes/gecit.tscn | (1070,340) | 20x200 (y 240..440), kayma_yonu=(0,-1), kayma_mesafe=70, hiz=120, tetikleyici_yollari=[../PlakaKutu]; açıkken açıklık 70 px |
| Lazer1 (L0) | scenes/lazer.tscn | (290,300) | yon=(0,1), uzunluk=300, tetikleyici_yollari=[../Plaka1], tetik_aktifken_kapali=true |
| Lazer2 (L1) | scenes/lazer.tscn | (860,300) | yon=(0,1), uzunluk=140, tetikleyici_yollari=[../Plaka3], tetik_aktifken_kapali=true |
| Kapi | kapi.gd Area2D | (1120,416) | 36x48 |
| Kutu | scenes/kutu.tscn | (500,580) | 40x40 zeminde |
| Oyuncu | oyuncu.tscn | (100,570) | |
| Bilgi | Label | (16,12)-(600,40) | |

Ağaç sırası: Zemin, Kat2, Tavan, Platform, Plaka1, Plaka2, Plaka3, PlakaKutu, Asansor, Gecit, Lazer1, Lazer2, Kapi, Kutu, Oyuncu, Bilgi (kutu karakterlerden ve dünya nesnelerinden SONRA, Oyuncu'dan ÖNCE). Export kalıpları bolum_8.tscn'den. Başlangıç: asansör aşağıda, geçit kapalı, L0 ve L1 açık.

## Roller
k1: Plaka1'i tutar (L0 kapalı). k2: L0'ı geçip platforma düz zıplar, Plaka2'yi tutar (asansör yukarıda; basma anı kutu yüklendikten SONRA). k3: kutuyu iterek asansöre yükler, F2'ye çıkar, Plaka3'e gider. Kutu F2'de PlakaKutu'yu tutar (geçit açık).

## Çözüm (kare; testler "koşula kadar bekle")
- Tur 1 → k1: sağ 14 kare (x=170), ~10 bekle, R.
- Tur 2 → k2: sağ 50 kare (x=350), J≈170'e kadar bekle, düz yukarı zıpla (platforma x≈350'de iner), inince sağ 6 kare (x≈380, plakaya basar f_A≈207), birkaç kare bekle, R. Asansör f_A+1'den 80 karede yükselir.
- Tur 3 → k3: sağ basılı; kutuya ~73'te değer ve iter; x=620'de (~104) asansörde dur; asansör üstte (position.y ≤ 450, ~288) olunca sağ 28 kare: kutuyu F2'ye iter, x=760'ta dur (Plaka3 basılı, L1 kapalı); ~10 bekle, R.
- Tur 4 (R kapalı "Klon: 3/3"): oyuncu k3 yürüyüşünü yapar; asansör üstte olunca sağa kutuyu iterek PlakaKutu'ya (x≈930) götürür; kutunun üstünden/solundan geçip G'nin altından (açıklık 70>48) kapıya (~410. kare, ~6,9 sn).
Süreler ≈ 0,5 / 3,7 / 5,4 / 6,9 sn (≤600 kare).
Alternatif S2 (aynı klon sayısı): tur 3'te k3 kutuyu Plaka3'e iter (kutu L1'i kapatır), kendisi PlakaKutu'yu tutar; son turda oyuncu kutuya dokunmaz.

## Atlanamazlık
F2'ye zeminden 160 > 100,9; kutu basamak: kutu üstü 560, gereken 119 > 100,9; platformdan F2'ye yatay 242 px >> ~140. L0 zeminden tavana tam; L1 y 300..440 (tavan 300); G tavana bitişik.

## Klon gereği ve KISAYOL TARAMASI (tasarımcının sonucu; gozden-gecirici bağımsız kontrol edecek)
Klonsuz: L0'da ölür. Yalnız k1: asansör inik. k1+k2 (k3 yok): F2'de L1 açık ya da G kapalı (iki iş, bir kutu). k1+k3 (k2 yok): asansör kalkmaz. k2+k3 (k1 yok): L0 açık. Röle k1 (Plaka1→Plaka2): Plaka2 L0'ın ötesinde, k1 bırakınca ışına girer. Röle k3 (PlakaKutu→Plaka3): L1'i geçmek zorunda, bırakınca açılır. Kutu basamak: 119>100,9. Kutu Plaka1/Plaka2'de k1/k2 yerine: kutu L0'ın ötesinde, platforma çıkamaz. Sonuç: minimum 3 klon.

## Kilitlenme (hepsi "Baştan başla" ile giderilir)
k2 erken basar (kutu yerde kalır); kutu asansör yukarıdayken asansör altına itilir; kutu PlakaKutu'yu aşıp G'ye gider; kutu sola duvara itilir; k3 kaydı hatalı.

## Başarısızlık senaryoları
1. Klonsuz: x=290'da L0'da ölür. 2. k1+k2 (k3 yok): L1'de ölür / G kapalı. 3. k2 erken basar (f_A≈60): kutusuz yükselir, bitmez. 4. k3 asansöre binmez: L1 açık, ölür. 5. Kutu PlakaKutu'yu aşar: G kapanır, bitmez. 6. R'ye k3 kutuyu yüklemeden basılır.

## Riskler
Zemin-asansör dikişinde kutu takılması (asansör y 611); kutu-KAT2 2 px boşluk (Kat2 sol kenarı 700); platform dikey zıplama sol ucu payı 6 px (platform merkezi 410); çift itme ölçülmeli; asansör f_A zamanlaması ≥~150.

## Harita
Güncel yerleşim planı (14 düğümlü dış halka, çizgi kesişimi yok): 1 (330,400), 2 (820,270), 3 (1010,440), 4 (700,530), 5 (450,520) DEĞİŞMEZ; 6 (230,480), 7 (150,330), 8 (230,190) YENİ konum; 9 (440,230), 10 (640,190), 11 (850,175), 12 (1030,230), 13 (1070,350), 14 (1070,545). Bölüm 9 kaydı: `{"yol": "res://scenes/bolumler/bolum_9.tscn", "konum": Vector2(440, 230), "onceki": "res://scenes/bolumler/bolum_8.tscn"}`. Bölüm 6–8'in konumları güncellenir (testler konumu listeden türetir; sabit konum varsa uyarla).
