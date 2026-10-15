# Aşama C — Bölüm 9..14 yol haritası (kullanıcı onaylı üretim)

Tema: "terk edilmiş zaman laboratuvarı". Her bölüm bir fikri öğretir; Bölüm 1–8'den belirgin daha zor (ama tur başına ≤10 sn/600 kare). Her çözüm en az 2 klon gerektirsin (max_klon ≤3). KISAYOL TARAMASI zorunlu: tasarımcı her bölüm için "daha az klonla / klonsuz çözülebilir mi?" kontrolünü açıkça yazar; gozden-gecirici bağımsız kontrol eder.
Nesneler: plaka, asansör, kapı, şalter, geçit, lazer, tek yönlü platform, KUTU (`scenes/kutu.tscn`), YAYLI ZIPLATICI (`scenes/yayli_ziplatici.tscn`), TAŞIMA BANDI (`scenes/tasima_bandi.tscn`). Başka mekanik YOK. Kutu en az 3 bölümde, her yeni nesne (zıplatıcı, bant) en az 2 bölümde çözümün parçası olsun (kutu da).

## Önerilen sıra (tasarımcı gerekçeyle değiştirebilir)
- B9: KUTU tanıtımı (kutuyu plakaya it; klon ve kutu birlikte; küçük çıkış).
- B10: TAŞIMA BANDI + kutu (bant kutuyu/karakteri taşır; yön kararı).
- B11: YAYLI ZIPLATICI (+ lazer ya da tek yönlü; yükseklik/kat atlama).
- B12: kutu + zıplatıcı + geçit/şalter.
- B13: bant + zıplatıcı + şalter + lazer (zamanlama).
- B14: final: tüm yeni nesneler, 3 klon.

## Nesne davranış özeti (kodtan okunmuş; ayrıntı için scripts/kutu.gd, yayli_ziplatici.gd, tasima_bandi.gd, docs/kararlar.md Aşama B notları)
- Kutu 40x40 (sahnede ayarlanabilir), katman 1+4; yerçekimi 1400; yalnızca İTİLİR (çekilmez), zincirleme itme yok; plakayı basılı tutar; asansör üstünde taşınır; asansör inerken/geçit kapanırken altında kalırsa durdurur; lazer etkilemez, bloklamaz; her tur başlangıç konumundan başlar.
- Yaylı zıplatıcı: Area2D sensör 60x12, `firlatma_hizi` 820 px/sn → ~240 px yükseklik (ölçülen 247 px); yalnızca velocity.y ≥ 0 iken tetiklenir; oyuncu, klon, kutu hepsi fırlar; zıplama tuşu fırlatmayı zayıflatmaz.
- Taşıma bandı: StaticBody2D `constant_linear_velocity`, `yon` ±1, `hiz` 100 px/sn; üstündeki oyuncu/klon/kutu girdisiz yön*hiz ile kayar; inince etki biter.
- Güvenlik payları: kutuyu oyuncu başlangıcından ≥40 px uzağa koy; asansör tepesi ile tavan arası ≥40 px+pay; kutu uçuruma/köşeye itilirse geri alınamaz ("Baştan başla" yeter ama kilitlenme analizinde yaz); zıplatıcı üzerinde kutu sekmeye devam eder; zıplatıcıyla kutu 240 px yükseğe taşınabilir.
- Lessons (Bölüm 4–8): plaka platform üstündeyse zıplayan başı (ayak min y=499 → baş 451) alt kenar altına inen plakaya girer; kare tepesi zıplama ~100,9 px; asansör position.y merkezdir; asansör yükselince altındaki boşluk <48 ise altına girip zıplayan kafasını çarpar; geçit alt kenar/tavan bitişikliği; testler "koşula kadar bekle" ile yazılır; klonun lazerde ölmesine güvenme (ölü klon donar, etkisiz).
- KUTUNUN ÇÖZÜMÜ KISALTABİLECEĞİ yollar (tasarımcı bunları özellikle kapatmalı): basamak yapma (40 px + zıplama 100 px), plakayı kutuyla tutma (klon tasarrufu), geçit altına kutu bırakıp açık tutma, bant üstünde kutuyu uzak plakaya taşıma, kutu + zıplatıcı ile yükseğe taşıma.
