class_name BolumListesi
extends RefCounted
## Bölüm kayıtları tek yerde. Yeni bölüm eklemek = listeye bir kayıt; harita, sonuç ekranı
## ve menü kodu değişmez.
##   yol    : bölüm sahnesi
##   konum  : harita ekranındaki düğüm merkezi (1152x648 içinde)
##   onceki : bağlı olduğu önceki bölümün sahne yolu (başlangıç düğümü için boş)
## "Sonraki bölüm" listedeki sıraya göre çalışır.

const BOLUMLER: Array[Dictionary] = [
	{
		"yol": "res://scenes/bolumler/bolum_1.tscn",
		"konum": Vector2(330, 400),
		"onceki": "",
	},
	{
		"yol": "res://scenes/bolumler/bolum_2.tscn",
		"konum": Vector2(820, 270),
		"onceki": "res://scenes/bolumler/bolum_1.tscn",
	},
	{
		"yol": "res://scenes/bolumler/bolum_3.tscn",
		"konum": Vector2(1010, 440),
		"onceki": "res://scenes/bolumler/bolum_2.tscn",
	},
	{
		"yol": "res://scenes/bolumler/bolum_4.tscn",
		"konum": Vector2(700, 530),
		"onceki": "res://scenes/bolumler/bolum_3.tscn",
	},
	{
		"yol": "res://scenes/bolumler/bolum_5.tscn",
		"konum": Vector2(450, 520),
		"onceki": "res://scenes/bolumler/bolum_4.tscn",
	},
	{
		"yol": "res://scenes/bolumler/bolum_6.tscn",
		"konum": Vector2(230, 480),
		"onceki": "res://scenes/bolumler/bolum_5.tscn",
	},
	{
		"yol": "res://scenes/bolumler/bolum_7.tscn",
		"konum": Vector2(150, 330),
		"onceki": "res://scenes/bolumler/bolum_6.tscn",
	},
	{
		"yol": "res://scenes/bolumler/bolum_8.tscn",
		"konum": Vector2(230, 190),
		"onceki": "res://scenes/bolumler/bolum_7.tscn",
	},
	{
		"yol": "res://scenes/bolumler/bolum_9.tscn",
		"konum": Vector2(440, 230),
		"onceki": "res://scenes/bolumler/bolum_8.tscn",
	},
	{
		"yol": "res://scenes/bolumler/bolum_10.tscn",
		"konum": Vector2(640, 190),
		"onceki": "res://scenes/bolumler/bolum_9.tscn",
	},
	{
		"yol": "res://scenes/bolumler/bolum_11.tscn",
		"konum": Vector2(850, 175),
		"onceki": "res://scenes/bolumler/bolum_10.tscn",
	},
	{
		"yol": "res://scenes/bolumler/bolum_12.tscn",
		"konum": Vector2(1030, 230),
		"onceki": "res://scenes/bolumler/bolum_11.tscn",
	},
]


## Bölüm sahne yolları, liste sırasıyla.
static func yollar() -> Array[String]:
	var liste: Array[String] = []
	for kayit in BOLUMLER:
		liste.append(kayit["yol"])
	return liste


## Verilen bölümden sonraki bölümün yolu; son bölümse (veya listede yoksa) boş metin.
static func sonraki(yol: String) -> String:
	var liste := yollar()
	var i := liste.find(yol)
	if i < 0 or i + 1 >= liste.size():
		return ""
	return liste[i + 1]


## Bölümün listedeki indeksi (yoksa -1).
static func indeks(yol: String) -> int:
	return yollar().find(yol)


## Harita çizgileri için bağlantılar: [önceki düğüm konumu, bu düğüm konumu] çiftleri.
static func baglantilar() -> Array:
	var cikti: Array = []
	for kayit in BOLUMLER:
		var onceki: String = kayit["onceki"]
		if onceki == "":
			continue
		var i := indeks(onceki)
		if i >= 0:
			cikti.append([BOLUMLER[i]["konum"], kayit["konum"]])
	return cikti
