class_name BolumListesi
extends RefCounted
## Bölüm kayıtları tek yerde. Yeni bölüm eklemek = listeye bir kayıt; harita, sonuç ekranı
## ve menü kodu değişmez.
##   yol    : bölüm sahnesi
##   ad     : (isteğe bağlı) haritada hover'da gösterilen bölüm adı
##   konum  : harita ekranındaki düğüm merkezi (1152x648 içinde)
##   onceki : bağlı olduğu önceki bölümün sahne yolu (başlangıç düğümü için boş)
## "Sonraki bölüm" listedeki sıraya göre çalışır.

const BOLUMLER: Array[Dictionary] = [
	{
		"yol": "res://scenes/bolumler/bolum_1.tscn",
		"ad": "Giriş",
		"konum": Vector2(140, 165),
		"onceki": "",
	},
	{
		"yol": "res://scenes/bolumler/bolum_2.tscn",
		"ad": "İkiz",
		"konum": Vector2(320, 165),
		"onceki": "res://scenes/bolumler/bolum_1.tscn",
	},
	{
		"yol": "res://scenes/bolumler/bolum_3.tscn",
		"ad": "Lazer",
		"konum": Vector2(500, 165),
		"onceki": "res://scenes/bolumler/bolum_2.tscn",
	},
	{
		"yol": "res://scenes/bolumler/bolum_4.tscn",
		"ad": "Kule",
		"konum": Vector2(680, 165),
		"onceki": "res://scenes/bolumler/bolum_3.tscn",
	},
	{
		"yol": "res://scenes/bolumler/bolum_5.tscn",
		"ad": "Uzaktan Anahtar",
		"konum": Vector2(860, 165),
		"onceki": "res://scenes/bolumler/bolum_4.tscn",
	},
	{
		"yol": "res://scenes/bolumler/bolum_6.tscn",
		"ad": "Nöbetçi Geçit",
		"konum": Vector2(1040, 165),
		"onceki": "res://scenes/bolumler/bolum_5.tscn",
	},
	{
		"yol": "res://scenes/bolumler/bolum_7.tscn",
		"ad": "Üç Anahtar",
		"konum": Vector2(1040, 280),
		"onceki": "res://scenes/bolumler/bolum_6.tscn",
	},
	{
		"yol": "res://scenes/bolumler/bolum_8.tscn",
		"ad": "Zaman Kulesi",
		"konum": Vector2(860, 280),
		"onceki": "res://scenes/bolumler/bolum_7.tscn",
	},
	{
		"yol": "res://scenes/bolumler/bolum_9.tscn",
		"ad": "Yük",
		"konum": Vector2(680, 280),
		"onceki": "res://scenes/bolumler/bolum_8.tscn",
	},
	{
		"yol": "res://scenes/bolumler/bolum_10.tscn",
		"ad": "Hat",
		"konum": Vector2(500, 280),
		"onceki": "res://scenes/bolumler/bolum_9.tscn",
	},
	{
		"yol": "res://scenes/bolumler/bolum_11.tscn",
		"ad": "Yay",
		"konum": Vector2(320, 280),
		"onceki": "res://scenes/bolumler/bolum_10.tscn",
	},
	{
		"yol": "res://scenes/bolumler/bolum_12.tscn",
		"ad": "Kargo",
		"konum": Vector2(140, 280),
		"onceki": "res://scenes/bolumler/bolum_11.tscn",
	},
	{
		"yol": "res://scenes/bolumler/bolum_13.tscn",
		"ad": "Kuyu",
		"konum": Vector2(140, 395),
		"onceki": "res://scenes/bolumler/bolum_12.tscn",
	},
	{
		"yol": "res://scenes/bolumler/bolum_14.tscn",
		"ad": "Çekirdek",
		"konum": Vector2(320, 395),
		"onceki": "res://scenes/bolumler/bolum_13.tscn",
	},
	{
		"yol": "res://scenes/bolumler/bolum_15.tscn",
		"ad": "Fitil",
		"konum": Vector2(500, 395),
		"onceki": "res://scenes/bolumler/bolum_14.tscn",
	},
	{
		"yol": "res://scenes/bolumler/bolum_16.tscn",
		"ad": "Mandal",
		"konum": Vector2(680, 395),
		"onceki": "res://scenes/bolumler/bolum_15.tscn",
	},
	{
		"yol": "res://scenes/bolumler/bolum_17.tscn",
		"ad": "Çifte Mühür",
		"konum": Vector2(860, 395),
		"onceki": "res://scenes/bolumler/bolum_16.tscn",
	},
	{
		"yol": "res://scenes/bolumler/bolum_18.tscn",
		"ad": "Vardiya",
		"konum": Vector2(1040, 395),
		"onceki": "res://scenes/bolumler/bolum_17.tscn",
	},
	{
		"yol": "res://scenes/bolumler/bolum_19.tscn",
		"ad": "Büyük Saat",
		"konum": Vector2(1040, 510),
		"onceki": "res://scenes/bolumler/bolum_18.tscn",
	},
	{
		"yol": "res://scenes/bolumler/bolum_20.tscn",
		"ad": "Mandal",
		"konum": Vector2(860, 510),
		"onceki": "res://scenes/bolumler/bolum_19.tscn",
	},
	{
		"yol": "res://scenes/bolumler/bolum_21.tscn",
		"ad": "Fitil ve Mühür",
		"konum": Vector2(680, 510),
		"onceki": "res://scenes/bolumler/bolum_20.tscn",
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


## Bölümün adı (kayıtta "ad" yoksa veya bölüm listede yoksa boş metin).
static func ad(yol: String) -> String:
	var i := indeks(yol)
	if i < 0:
		return ""
	return str(BOLUMLER[i].get("ad", ""))


## HUD başlığı: "Bölüm 14 · Çekirdek"; ad boşsa yalnız "Bölüm 14".
static func baslik_metni(numara: int, ad: String) -> String:
	if ad == "":
		return "Bölüm %d" % numara
	return "Bölüm %d · %s" % [numara, ad]


## Bölümün HUD başlığı. Numara listedeki sıradan (indeks + 1), ad kayıttan gelir;
## bölüm listede yoksa (ör. test sahnesi) boş metin.
static func baslik(yol: String) -> String:
	var i := indeks(yol)
	if i < 0:
		return ""
	return baslik_metni(i + 1, ad(yol))
