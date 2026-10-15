# Aşama 2 — Bölüm 3..8 yol haritası (kullanıcı onaylı üretim)

Tema: "terk edilmiş zaman laboratuvarı". Her bölüm bir fikri öğretir, zorluk kademeli artar.
Her çözüm en az 2 klon gerektirir; max_klon en çok 3; tur başına bekleme en fazla ~10 sn.
Nesneler: plaka, asansör, kapı, şalter, geçit, LAZER (scenes/lazer.tscn), TEK YÖNLÜ PLATFORM (scenes/tek_yonlu.tscn).
Lazer en az 3 bölümde çözümün parçası olmalı. Başka yeni mekanik YOK. Fizik: 28x48 kutu, HIZ 300, zıplama -520, yerçekimi 1400.
Lazer notları: canlı oyuncu ölürse tur yeniden başlar (klon sayısı değişmez); klon ölürse donar ve etkisiz kalır (çözüm klonun ölmesine dayanmamalı, yalnızca lazeri kapatan tetikleyicide bırakılmış klon güvenlidir). Ölü klon havada asılı kalabilir: klonun asansör üstünde lazerde ölmesi tasarlanmaz.
Işın duvarlarda kesilmez. Ağaç sırası: plaka/şalter/asansör/geçit/lazer karakterlerden ÖNCE.

## Önerilen sıra (tasarımcı gerekçeyle değiştirebilir)
- B3: Lazer tanıtımı (plaka lazeri kapatır; klon plakada bekler).
- B4: Tek yönlü platform + asansör/plaka (dikey).
- B5: Şalter + lazer (tetik_aktifken_kapali=false veya acik_taraf_sag).
- B6: Geçit (VEYA) + lazer; iki klon, farklı görevler.
- B7: Karışık, 3 klon sınırı.
- B8: Final: tüm nesneler, 3 klon.
Harita konumları: 1152x648 içinde, bağlı zincir/dallanma (bkz. scripts/bolumler_listesi.gd).
