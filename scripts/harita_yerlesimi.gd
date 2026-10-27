class_name HaritaYerlesimi
extends RefCounted
## Harita düğüm konumları (taslak §8.2, A12): n bölümlük yılan ızgarası. Saf hesaptır, dosya okumaz.
## n <= 24 için 6 sütun, 4 satır (21 resmî bölümün bugünkü konumlarıyla birebir aynı);
## 25..40 için sütun sayısı artar, en yakın iki düğüm yine >= 100 px uzakta kalır.

const SATIR_SAYISI := 4
const SUTUN_EN_AZ := 6
const X_BASI := 140.0
const X_GENISLIK := 900.0
const Y_BASI := 165.0
const Y_ARALIK := 115.0
## Bu sayının üstünde düğüm aralığı 100 px'in altına düşer; BolumListesi.AZAMI_BOLUM ile aynı olmalı.
const AZAMI := 40


## Sütun sayısı: max(6, ceil(n / 4)).
static func sutun_sayisi(n: int) -> int:
	return maxi(SUTUN_EN_AZ, ceili(n / float(SATIR_SAYISI)))


## Yatay düğüm aralığı (px).
static func aralik(n: int) -> float:
	return X_GENISLIK / float(sutun_sayisi(n) - 1)


## i. düğümün merkezi (n toplam düğüm). Çift satır soldan sağa, tek satır sağdan sola.
static func konum(i: int, n: int) -> Vector2:
	var c := sutun_sayisi(n)
	var r := i / c
	var j := i % c
	if r % 2 == 1:
		j = c - 1 - j
	return Vector2(X_BASI + j * aralik(n), Y_BASI + r * Y_ARALIK)
