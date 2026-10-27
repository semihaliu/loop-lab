class_name BolumListesi
extends RefCounted
## Bölüm kayıtları tek yerde. Yeni bölüm eklemek = listeye bir kayıt; harita, sonuç ekranı
## ve menü kodu değişmez.
##   yol    : bölüm sahnesi
##   ad     : (isteğe bağlı) haritada hover'da gösterilen bölüm adı
##   konum  : harita ekranındaki düğüm merkezi (1152x648 içinde)
##   onceki : bağlı olduğu önceki bölümün sahne yolu (başlangıç düğümü için boş)
## "Sonraki bölüm" listedeki sıraya göre çalışır.
##
## A12: `BOLUMLER` 21 resmî kayıttır ve değişmez. Oyunun gördüğü sıra `liste()`dir: resmî kayıtlar ile
## kullanıcının "Canlıya al" ile eklediği bölümlerin (`<kök>canli/sira.json`) birleşimi. Numara her
## zaman `indeks + 1`'dir; sahne dosyaları yeniden adlandırılmaz. `liste()` SAF OKUYUCUDUR: dosya
## yazmaz, sahne kurmaz, denetim çalıştırmaz (editör betiklerine bağımlı değil).

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


## En çok bölüm sayısı (resmî + canlı); 4 satır x 10 sütun harita (HaritaYerlesimi.AZAMI).
const AZAMI_BOLUM := HaritaYerlesimi.AZAMI

## Canlı bölümlerin okunduğu kök dizin ("user://"); testler "user://test_editor/" verir.
static var kullanici_kok: String = BolumYollari.VARSAYILAN_KOK
## Son `liste()` kurulumunda atlanan/yeri bulunamayan kayıtların uyarıları.
static var son_uyarilar: Array[String] = []
static var _birlesik: Array = []
static var _kuruldu := false
## Canlı kimlik biçimi (BolumVerisi.KIMLIK_DESENI ile aynı; çekirdek editöre bağımlı olmasın diye burada yinelenir).
static var KIMLIK_DESENI := _desen_kur()


static func _desen_kur() -> RegEx:
	var g := RegEx.new()
	g.compile("^[a-z0-9_]{1,36}_[0-9]{3}$")
	return g


## Birleşik bölüm listesi (önbellekli): {yol, ad, konum, onceki, kaynak: "resmi"|"canli", kimlik, cozum_yok}.
## Canlı kayıt yoksa 21 resmî kayıt, konum ve onceki alanları `BOLUMLER`'le birebir aynıdır.
## Dönen dizi salt okunur sayılır. Canlıya alma/güncelleme/kaldırma sonrası `yenile()` çağrılmalıdır.
static func liste() -> Array:
	if not _kuruldu:
		var uyarilar: Array[String] = []
		_birlesik = olustur(kullanici_kok, uyarilar)
		son_uyarilar = uyarilar
		_kuruldu = true
	return _birlesik


## Önbelleği atar; sonraki `liste()` diskten yeniden kurar.
static func yenile() -> void:
	_birlesik = []
	son_uyarilar = []
	_kuruldu = false


## Verilen kök için birleşik listeyi (önbelleksiz) kurur. Uyarılar `uyarilar`a eklenir.
static func olustur(kok: String, uyarilar: Array[String] = []) -> Array:
	var canlilar := _canli_kayitlari(kok, uyarilar)
	var yerlesen: Dictionary = {}   # kimlik -> true
	var sonuc: Array = []

	var takip := func(anahtar: String, kendi: Callable) -> void:
		for c in canlilar:
			var kimlik: String = c["kimlik"]
			if yerlesen.has(kimlik) or str(c["sonra"]) != anahtar:
				continue
			yerlesen[kimlik] = true
			sonuc.append(_canli_kaydi(c, kok))
			kendi.call("canli:" + kimlik, kendi)

	takip.call("", takip)   # "en başa" olanlar
	for kayit in BOLUMLER:
		var r: Dictionary = (kayit as Dictionary).duplicate()
		r["kaynak"] = "resmi"
		r["kimlik"] = ""
		r["cozum_yok"] = false
		sonuc.append(r)
		takip.call(str(kayit["yol"]), takip)

	for c in canlilar:   # yeri bulunamayanlar (silinmiş hedef, döngü) sona
		if not yerlesen.has(c["kimlik"]):
			yerlesen[c["kimlik"]] = true
			sonuc.append(_canli_kaydi(c, kok))
			uyarilar.append("Canlı bölüm \"%s\": sonra=\"%s\" bulunamadı, listenin sonuna eklendi" % [c["kimlik"], c["sonra"]])
			takip.call("canli:" + str(c["kimlik"]), takip)   # ona bağlı kayıtlar arkasından gelir

	var fazla := sonuc.size() - AZAMI_BOLUM   # 40'ı aşan canlılar alınmaz (sondan)
	var i := sonuc.size() - 1
	while fazla > 0 and i >= 0:
		if sonuc[i]["kaynak"] == "canli":
			uyarilar.append("Canlı bölüm \"%s\": en çok %d bölüm sınırı aşıldı, alınmadı" % [sonuc[i]["kimlik"], AZAMI_BOLUM])
			sonuc.remove_at(i)
			fazla -= 1
		i -= 1

	for k in sonuc.size():
		sonuc[k]["konum"] = HaritaYerlesimi.konum(k, sonuc.size())
		sonuc[k]["onceki"] = "" if k == 0 else sonuc[k - 1]["yol"]
	for u in uyarilar:
		push_warning(u)
	return sonuc


## `sira.json` içindeki geçerli kayıtlar (dosya sırasıyla): {kimlik, ad, sahne, sonra, icerik_ozeti, cozum_yok}.
## Dosya yoksa boş; bozuksa boş ve uyarı. Yalnız okur. Sahnesi diskte olmayan ve yinelenen kayıtlar atılır.
static func _canli_kayitlari(kok: String, uyarilar: Array[String]) -> Array:
	var ham := sira_kayitlari(kok, uyarilar)
	var cikti: Array = []
	var gorulen: Dictionary = {}
	var dizin := BolumYollari.canli_dizini(kok)
	for c in ham:
		if gorulen.has(c["kimlik"]):
			uyarilar.append("Canlı bölüm \"%s\" sira.json'da yinelenmiş, ilki alındı" % c["kimlik"])
			continue
		if not FileAccess.file_exists(dizin + str(c["sahne"])):
			uyarilar.append("Canlı bölüm \"%s\": sahne dosyası yok (%s), atlandı" % [c["kimlik"], c["sahne"]])
			continue
		gorulen[c["kimlik"]] = true
		cikti.append(c)
	return cikti


## `<kok>canli/sira.json` kayıtlarını biçim denetiminden geçirip döndürür (sahne dosyasının varlığına bakmaz).
static func sira_kayitlari(kok: String, uyarilar: Array[String] = []) -> Array:
	var yol := BolumYollari.canli_dizini(kok) + "sira.json"
	if not FileAccess.file_exists(yol):
		return []
	var f := FileAccess.open(yol, FileAccess.READ)
	if f == null:
		uyarilar.append("canli/sira.json açılamadı: canlı bölümler yok sayıldı")
		return []
	var metin := f.get_as_text()
	f.close()
	var json := JSON.new()
	if json.parse(metin) != OK or typeof(json.data) != TYPE_DICTIONARY or typeof(json.data.get("canli")) != TYPE_ARRAY:
		uyarilar.append("canli/sira.json bozuk: canlı bölümler yok sayıldı")
		return []
	var cikti: Array = []
	for k in json.data["canli"]:
		if typeof(k) != TYPE_DICTIONARY:
			uyarilar.append("canli/sira.json: nesne olmayan kayıt atlandı")
			continue
		var kimlik := str(k.get("kimlik", ""))
		var sahne := str(k.get("sahne", ""))
		if not KIMLIK_DESENI.search(kimlik) or not sahne.ends_with(".tscn") 				or sahne.contains("/") or sahne.contains("\\") or sahne.contains("..") or typeof(k.get("sonra", "")) != TYPE_STRING:
			uyarilar.append("canli/sira.json: geçersiz kayıt atlandı (kimlik=\"%s\")" % kimlik)
			continue
		cikti.append({
			"kimlik": kimlik,
			"ad": str(k.get("ad", "")),
			"sahne": sahne,
			"sonra": str(k.get("sonra", "")),
			"icerik_ozeti": str(k.get("icerik_ozeti", "")),
			"cozum_yok": bool(k.get("cozum_yok", false)),
		})
	return cikti


static func _canli_kaydi(c: Dictionary, kok: String) -> Dictionary:
	return {
		"yol": BolumYollari.canli_dizini(kok) + str(c["sahne"]),
		"ad": c["ad"],
		"konum": Vector2.ZERO,
		"onceki": "",
		"kaynak": "canli",
		"kimlik": c["kimlik"],
		"cozum_yok": c["cozum_yok"],
	}


## Bölüm sahne yolları, liste sırasıyla.
static func yollar() -> Array[String]:
	var cikti: Array[String] = []
	for kayit in liste():
		cikti.append(kayit["yol"])
	return cikti


## Verilen bölümden sonraki bölümün yolu; son bölümse (veya listede yoksa) boş metin.
static func sonraki(yol: String) -> String:
	var l := yollar()
	var i := l.find(yol)
	if i < 0 or i + 1 >= l.size():
		return ""
	return l[i + 1]


## Bölümün listedeki indeksi (yoksa -1).
static func indeks(yol: String) -> int:
	return yollar().find(yol)


## Harita çizgileri için bağlantılar: [önceki düğüm konumu, bu düğüm konumu] çiftleri.
static func baglantilar() -> Array:
	var cikti: Array = []
	var l := liste()
	for kayit in l:
		var onceki: String = kayit["onceki"]
		if onceki == "":
			continue
		var i := indeks(onceki)
		if i >= 0:
			cikti.append([l[i]["konum"], kayit["konum"]])
	return cikti


## Bölümün adı (kayıtta "ad" yoksa veya bölüm listede yoksa boş metin).
static func ad(yol: String) -> String:
	var i := indeks(yol)
	if i < 0:
		return ""
	return str(liste()[i].get("ad", ""))


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
		if BolumYollari.dene_mi(yol):
			return _deneme_basligi(yol)
		if BolumYollari.ozel_mi(yol):
			return _deneme_basligi(yol, "Özel")
		return ""
	return baslik_metni(i + 1, ad(yol))


## Dene/özel sahnenin başlığı: "Deneme · Ad" ya da "Özel · Ad" (Ad, kök düğümün `metadata/editor_ad`
## değeri); sahne okunamaz ya da ad yoksa yalnız önek.
static func _deneme_basligi(yol: String, onek: String = "Deneme") -> String:
	var ad_metni := ""
	var paket := load(yol) as PackedScene
	if paket != null:
		var durum := paket.get_state()
		if durum.get_node_count() > 0:
			for k in durum.get_node_property_count(0):
				if durum.get_node_property_name(0, k) == "metadata/editor_ad":
					ad_metni = str(durum.get_node_property_value(0, k))
	if ad_metni == "":
		return onek
	return onek + " · " + ad_metni
