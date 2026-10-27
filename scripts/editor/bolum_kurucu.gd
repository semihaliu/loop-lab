class_name BolumKurucu
extends RefCounted
## JSON bölüm verisinden (BolumVerisi biçimi) bir bölüm kök düğümü kurar. Kök, mevcut
## `bolum.gd` betiğini paylaşır; nesneler mevcut sahne örnekleri (scenes/*.tscn) ve mevcut
## betiklerdir, mantık kopyalanmaz. Blok, plaka, asansör ve kapı için hazır sahne olmadığından
## bunlar satır içi kurulur (özellik, katman ve düğüm adları resmî bölümlerle aynıdır).
##
## Kurulan düğümler ağaca EKLENMEZ (`_ready` çalışmaz): sahneye paketlenince varsayılan değerler
## resmî `.tscn` dosyalarındakiyle aynı kalır. Rastgelelik ve gerçek saat yoktur.

## bolum.gd `Kayitlar` otomatik yüklemesine bağlıdır; `--script` kipinde derleme sırasında yüklenemediği
## için preload yerine çalışma anında yüklenir.
const BOLUM_BETIGI_YOLU := "res://scripts/bolum.gd"
const PLAKA_BETIGI := preload("res://scripts/basinc_plakasi.gd")
const ASANSOR_BETIGI := preload("res://scripts/asansor.gd")
const KAPI_BETIGI := preload("res://scripts/kapi.gd")
## Sahne sabitleri yol metnidir (preload DEĞİL): yüklenen PackedScene kalıcı önbellekte
## tutulursa içindeki paylaşılan şekil (özellikle lazer.tscn) fizik RID sırasını kaydırır ve
## Bölüm 13/14 bitiş karesi 1 kare oynar (2026-10-20, `tests/dene_fizik_testleri.gd`).
## `_ornekle` her seferinde `load` eder, sahne kaynağı elde tutulmaz.
const OYUNCU_SAHNESI := "res://scenes/oyuncu.tscn"
const GECIT_SAHNESI := "res://scenes/gecit.tscn"
const LAZER_SAHNESI := "res://scenes/lazer.tscn"
const SALTER_SAHNESI := "res://scenes/salter.tscn"
const KUTU_SAHNESI := "res://scenes/kutu.tscn"
const TEK_YONLU_SAHNESI := "res://scenes/tek_yonlu.tscn"
const BANT_SAHNESI := "res://scenes/tasima_bandi.tscn"
const ZIPLATICI_SAHNESI := "res://scenes/yayli_ziplatici.tscn"
const ZAMANLI_PLAKA_SAHNESI := "res://scenes/zamanli_plaka.tscn"
const MANDAL_PLAKA_SAHNESI := "res://scenes/mandal_plaka.tscn"

## Ağaç sırası kategorisi (K5): 0..6 JSON sırasıyla, ardından Kapi, ardından 8 (kutu).
## Plaka, şalter, asansör, geçit ve lazer karakterlerden önce gelir.
const KATEGORI := {
	"blok": 0, "tek_yonlu": 0, "bant": 0,
	"plaka": 1, "zamanli_plaka": 1, "mandal_plaka": 1,
	"salter": 2, "ziplatici": 3, "asansor": 4, "gecit": 5, "lazer": 6, "kutu": 8,
}

## Sabit değerler (resmî bölümlerdeki gerçek değerler; taslak §1.3).
const ASANSOR_HIZI := 120.0
const GECIT_HIZI := 120.0
const BANT_HIZI := 100.0
const ZIPLATICI_HIZI := 820.0
const VARSAYILAN_TUTMA_KARE := 180
const VARSAYILAN_YUKSEKLIK := 180
const VARSAYILAN_KAYMA_MESAFESI := 100
const VARSAYILAN_UZUNLUK := 200

## Resmî bölümlerdeki renkler (satır içi Gorsel düğümleri).
const BLOK_RENGI := Color(0.3, 0.3, 0.35, 1)
const PLAKA_RENGI := Color(0.6, 0.55, 0.25, 1)
const ASANSOR_RENGI := Color(0.5, 0.5, 0.6, 1)
const KAPI_RENGI := Color(0.45, 0.25, 0.1, 1)

const LAZER_YONLERI := {
	"asagi": Vector2(0, 1), "yukari": Vector2(0, -1), "sag": Vector2(1, 0), "sol": Vector2(-1, 0),
}

## Geçici sahne dosyalarının sayaçları (dizin + önek -> son verilen n). Aynı yolun yeniden
## verilmemesi için: eski dosya silinse bile sayaç geri dönmez (kaynak önbelleği tuzağı).
static var _sayaclar: Dictionary = {}


# --- Kök kurulumu ---------------------------------------------------------------------

## Ağaca eklenmemiş bölüm kökü: `bolum.gd` betikli Node2D. Kategori sırası: 0..6 (JSON sırası) ->
## Kapi -> kategori 8 (kutu) -> Oyuncu -> Bilgi -> EditorHud. Owner kuralı: kökün doğrudan
## çocukları ve satır içi düğümlerin çocukları köke bağlanır; sahne örneklerinin iç çocuklarına
## owner atanmaz. Veri geçerli (D1-D3) varsayılır; denetim bu işlevin işi değildir.
static func kur(veri: Dictionary) -> Node2D:
	var kok := Node2D.new()
	kok.name = "Bolum"
	kok.set_script(load(BOLUM_BETIGI_YOLU))
	kok.set("max_klon", int(veri.get("max_klon", 2)))
	kok.set("ipucu_klon", 0)
	kok.set_meta("editor_ad", str(veri.get("ad", "")))
	kok.set_meta("cozum_yok", not (BolumVerisi.dogrulama_guncel_mi(veri) and str(veri.get("dogrulama", {}).get("durum", "")) == "dogrulandi"))

	var nesneler: Array = veri.get("nesneler", [])
	var dugumler := {}   # id -> Node
	var siralar: Array[Array] = []   # kategori başına nesne listesi
	for i in 9:
		siralar.append([])
	for n in nesneler:
		var kat: int = KATEGORI.get(str(n.get("tur", "")), -1)
		if kat >= 0:
			siralar[kat].append(n)

	for kat in 7:
		for n in siralar[kat]:
			var d := nesne_kur(n, veri)
			dugumler[str(n["id"])] = d
			_ekle(kok, d)

	var kapi := _kapi_kur(_nokta(veri["cikis"]) + Vector2(0, -24))
	_ekle(kok, kapi)

	for n in siralar[8]:
		var d := nesne_kur(n, veri)
		dugumler[str(n["id"])] = d
		_ekle(kok, d)

	var oyuncu := _ornekle(OYUNCU_SAHNESI)
	oyuncu.name = "Oyuncu"
	oyuncu.position = _nokta(veri["baslangic"]) + Vector2(0, -24)
	_ekle(kok, oyuncu)

	var bilgi := Label.new()
	bilgi.name = "Bilgi"
	bilgi.offset_left = 16.0
	bilgi.offset_top = 12.0
	bilgi.offset_right = 600.0
	bilgi.offset_bottom = 40.0
	_ekle(kok, bilgi)

	var hud := EditorHud.new()
	hud.name = "EditorHud"
	_ekle(kok, hud)

	# Düğüm referansı gerektiren bağlantılar (asansör -> plaka).
	for n in nesneler:
		if str(n.get("tur", "")) == "asansor" and dugumler.has(str(n.get("plaka", ""))):
			dugumler[str(n["id"])].set("plaka", dugumler[str(n["plaka"])])
	return kok


## Sahne örneği. GEN_EDIT_STATE_INSTANCE ZORUNLU: bu olmadan `PackedScene.pack`, örnek
## kökünün özelliklerini yalnızca betik varsayılanıyla karşılaştırır. Sonuçlar: gecit.tscn'nin
## sahne varsayılanı (kayma_mesafe 200) betik varsayılanından (100) farklı olduğu için
## kayma_mesafe = 100 paketlenmez (yüklenince 200 olur) ve örnek köküne gereksiz `script`
## geçersiz kılması yazılır. Edit durumu yalnızca editör (TOOLS_ENABLED) motorunda vardır.
static func _ornekle(sahne_yolu: String) -> Node:
	return (load(sahne_yolu) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)


## Düğümü köke ekler ve owner kuralını uygular: satır içi düğümün çocukları da köke bağlanır;
## sahne örneğinin (scene_file_path dolu) iç çocuklarına owner atanmaz.
static func _ekle(kok: Node, d: Node) -> void:
	kok.add_child(d)
	d.owner = kok
	if d.scene_file_path == "":
		_cocuklari_bagla(d, kok)


static func _cocuklari_bagla(d: Node, kok: Node) -> void:
	for c in d.get_children():
		c.owner = kok
		if c.scene_file_path == "":
			_cocuklari_bagla(c, kok)


# --- Tek nesne ------------------------------------------------------------------------

## Tek nesne düğümü (önizleme de kullanır); owner atamaz, ağaca eklemez. Geçit/lazer
## `tetikleyici_yollari` (`NodePath("../<id>")`) ve kablo meta'ları yazılır. Asansörün `plaka`
## düğüm referansı burada bağlanamaz (kardeş düğüm gerekir): `kur` bağlar, önizleme çağıranı bağlar.
static func nesne_kur(nesne: Dictionary, veri: Dictionary) -> Node:
	var tur := str(nesne["tur"])
	var d: Node
	match tur:
		"blok":
			d = _blok_kur(nesne)
		"tek_yonlu":
			d = _ornekle(TEK_YONLU_SAHNESI)
		"bant":
			d = _ornekle(BANT_SAHNESI)
			d.set("yon", int(nesne.get("yon", 1)))
			d.set("hiz", BANT_HIZI)
		"plaka":
			d = _plaka_kur()
		"zamanli_plaka":
			d = _ornekle(ZAMANLI_PLAKA_SAHNESI)
			d.set("tutma_kare", int(nesne.get("tutma_kare", VARSAYILAN_TUTMA_KARE)))
		"mandal_plaka":
			d = _ornekle(MANDAL_PLAKA_SAHNESI)
		"salter":
			d = _ornekle(SALTER_SAHNESI)
			d.set("baslangic_sagda", bool(nesne.get("baslangic_sagda", false)))
		"ziplatici":
			d = _ornekle(ZIPLATICI_SAHNESI)
			d.set("firlatma_hizi", ZIPLATICI_HIZI)
		"asansor":
			d = _asansor_kur(nesne)
		"gecit":
			d = _ornekle(GECIT_SAHNESI)
			d.set("kayma_yonu", Vector2(0, -1))
			d.set("kayma_mesafe", float(int(nesne.get("kayma_mesafe", VARSAYILAN_KAYMA_MESAFESI))))
			d.set("hiz", GECIT_HIZI)
			d.set("acik_taraf_sag", bool(nesne.get("acik_taraf_sag", true)))
			d.set("tetikleyici_yollari", _tetik_yollari(nesne))
		"lazer":
			d = _ornekle(LAZER_SAHNESI)
			d.set("yon", LAZER_YONLERI[str(nesne.get("yon", "asagi"))])
			d.set("uzunluk", float(nesne.get("uzunluk", VARSAYILAN_UZUNLUK)))
			d.set("tetikleyici_yollari", _tetik_yollari(nesne))
			d.set("acik_taraf_sag", bool(nesne.get("acik_taraf_sag", true)))
			d.set("tetik_aktifken_kapali", bool(nesne.get("tetik_aktifken_kapali", true)))
		"kutu":
			d = _ornekle(KUTU_SAHNESI)
		_:
			push_error("BolumKurucu: bilinmeyen tür: %s" % tur)
			return null
	d.name = str(nesne["id"])
	d.position = nesne_konumu(nesne)
	_kablo_meta_yaz(d, nesne, veri)
	return d


## Düğüm `position` değeri (taslak §1.3 çapa tablosu).
static func nesne_konumu(n: Dictionary) -> Vector2:
	match str(n["tur"]):
		"blok":
			var a: Array = n["alan"]
			return Vector2(a[0] + a[2] / 2.0, a[1] + a[3] / 2.0)
		"tek_yonlu":
			return _nokta(n["konum"]) + Vector2(0, 6)
		"bant":
			return _nokta(n["konum"]) + Vector2(0, 8)
		"plaka", "zamanli_plaka", "mandal_plaka":
			return _nokta(n["konum"]) + Vector2(0, -8)
		"salter", "lazer":
			return _nokta(n["konum"])
		"ziplatici":
			return _nokta(n["konum"]) + Vector2(0, -6)
		"asansor":
			return _nokta(n["konum"]) + Vector2(0, 10)
		"gecit":
			return _nokta(n["konum"]) + Vector2(0, -100)
		"kutu":
			return _nokta(n["konum"]) + Vector2(0, -20)
	return Vector2.ZERO


static func _nokta(v: Variant) -> Vector2:
	return Vector2(float(v[0]), float(v[1]))


static func _tetik_yollari(nesne: Dictionary) -> Array[NodePath]:
	var yollar: Array[NodePath] = []
	for t in nesne.get("tetikleyiciler", []):
		yollar.append(NodePath("../" + str(t)))
	return yollar


# --- Satır içi nesneler ---------------------------------------------------------------

## Her satır içi gövde kendi `RectangleShape2D`'sini alır; Gorsel şekil boyutundadır (K6, K7).
static func _gorsel_kur(boyut: Vector2, renk: Color) -> ColorRect:
	var g := ColorRect.new()
	g.name = "Gorsel"
	g.offset_left = -boyut.x / 2.0
	g.offset_top = -boyut.y / 2.0
	g.offset_right = boyut.x / 2.0
	g.offset_bottom = boyut.y / 2.0
	g.color = renk
	return g


static func _sekil_kur(boyut: Vector2) -> CollisionShape2D:
	var s := CollisionShape2D.new()
	s.name = "CollisionShape2D"
	var dikdortgen := RectangleShape2D.new()
	dikdortgen.size = boyut
	s.shape = dikdortgen
	return s


static func _blok_kur(nesne: Dictionary) -> StaticBody2D:
	var a: Array = nesne["alan"]
	var boyut := Vector2(float(a[2]), float(a[3]))
	var b := StaticBody2D.new()
	b.add_child(_sekil_kur(boyut))
	b.add_child(_gorsel_kur(boyut, BLOK_RENGI))
	return b


static func _plaka_kur() -> Area2D:
	var p := Area2D.new()
	p.set_script(PLAKA_BETIGI)
	p.add_child(_sekil_kur(Vector2(60, 16)))
	p.add_child(_gorsel_kur(Vector2(60, 16), PLAKA_RENGI))
	return p


static func _asansor_kur(nesne: Dictionary) -> AnimatableBody2D:
	var a := AnimatableBody2D.new()
	a.set_script(ASANSOR_BETIGI)
	a.set("yukseklik", float(int(nesne.get("yukseklik", VARSAYILAN_YUKSEKLIK))))
	a.set("hiz", ASANSOR_HIZI)
	a.add_child(_sekil_kur(Vector2(120, 20)))
	a.add_child(_gorsel_kur(Vector2(120, 20), ASANSOR_RENGI))
	return a


static func _kapi_kur(konum: Vector2) -> Area2D:
	var k := Area2D.new()
	k.name = "Kapi"
	k.position = konum
	k.set_script(KAPI_BETIGI)
	k.add_child(_sekil_kur(Vector2(36, 48)))
	k.add_child(_gorsel_kur(Vector2(36, 48), KAPI_RENGI))
	return k


# --- Kablo ----------------------------------------------------------------------------

## k. tetikleyicinin kablo meta adı: k == 0 -> "kablo", k >= 1 -> "kablo_%d" % (k + 1).
static func kablo_meta_adi(k: int) -> String:
	if k <= 0:
		return "kablo"
	return "kablo_%d" % (k + 1)


## Hedef nesnenin k. kablosunun noktaları (k: tetikleyici sırası; asansörde 0).
## `uclar` varsa aynen, yoksa hesaplanan uçlar (tetikleyici merkezi ve hedef noktası);
## arada `ara`. `ara` boş ve `uclar` yoksa otomatik L: tetikleyici -> (tetikleyici.x, hedef.y) -> hedef.
## Gizliyse ya da bağlantı yoksa boş dizi.
static func kablo_noktalari(hedef: Dictionary, k: int, veri: Dictionary) -> PackedVector2Array:
	var bos := PackedVector2Array()
	var tur := str(hedef.get("tur", ""))
	var kayit: Dictionary = {}
	var tetik_id := ""
	if tur == "asansor":
		if k != 0:
			return bos
		tetik_id = str(hedef.get("plaka", ""))
		if tetik_id == "":
			return bos
		var kk: Variant = hedef.get("kablo", {})
		if typeof(kk) == TYPE_DICTIONARY:
			kayit = kk
	elif tur == "gecit" or tur == "lazer":
		var tetikler: Array = hedef.get("tetikleyiciler", [])
		if k < 0 or k >= tetikler.size():
			return bos
		tetik_id = str(tetikler[k])
		for kb in hedef.get("kablolar", []):
			if typeof(kb) == TYPE_DICTIONARY and str(kb.get("tetik", "")) == tetik_id:
				kayit = kb
				break
	else:
		return bos
	if bool(kayit.get("gizli", false)):
		return bos

	var ara: Array = kayit.get("ara", [])
	var noktalar := PackedVector2Array()
	if kayit.has("uclar"):
		var u: Array = kayit["uclar"]
		noktalar.append(_nokta(u[0]))
		for p in ara:
			noktalar.append(_nokta(p))
		noktalar.append(_nokta(u[1]))
		return noktalar

	var tetik_nesnesi := _nesne_bul(veri, tetik_id)
	if tetik_nesnesi.is_empty():
		return bos
	var bas := nesne_konumu(tetik_nesnesi)
	var son := _hedef_noktasi(hedef)
	noktalar.append(bas)
	if ara.is_empty():
		noktalar.append(Vector2(bas.x, son.y))
	else:
		for p in ara:
			noktalar.append(_nokta(p))
	noktalar.append(son)
	return noktalar


## Hedef noktası: geçitte geçidin ortası (düğüm konumu), lazerde yayıcı, asansörde alt konumdaki
## üst yüzeyin ortası (JSON `konum`).
static func _hedef_noktasi(hedef: Dictionary) -> Vector2:
	if str(hedef["tur"]) == "asansor":
		return _nokta(hedef["konum"])
	return nesne_konumu(hedef)


static func _nesne_bul(veri: Dictionary, id: String) -> Dictionary:
	for n in veri.get("nesneler", []):
		if str(n.get("id", "")) == id:
			return n
	return {}


## Hedef düğüme kablo meta'larını yazar (`gizli` olan için yazılmaz).
static func _kablo_meta_yaz(d: Node, nesne: Dictionary, veri: Dictionary) -> void:
	var tur := str(nesne["tur"])
	if tur == "asansor":
		var p := kablo_noktalari(nesne, 0, veri)
		if p.size() > 0:
			d.set_meta("kablo", p)
	elif tur == "gecit" or tur == "lazer":
		var sayi: int = nesne.get("tetikleyiciler", []).size()
		for k in sayi:
			var p := kablo_noktalari(nesne, k, veri)
			if p.size() > 0:
				d.set_meta(kablo_meta_adi(k), p)


# --- Kaydetme, geçici yol -------------------------------------------------------------

## Kurar, `PackedScene.pack` ile paketler, `yol`a kaydeder ve kökü serbest bırakır.
## Dizin yoksa oluşturulur. Dönüş: OK ya da hata kodu.
static func sahneye_kaydet(veri: Dictionary, yol: String) -> Error:
	var dizin := yol.get_base_dir()
	if dizin != "" and not DirAccess.dir_exists_absolute(dizin):
		var h := DirAccess.make_dir_recursive_absolute(dizin)
		if h != OK:
			return h
	var kok := kur(veri)
	var paket := PackedScene.new()
	var sonuc := paket.pack(kok)
	kok.free()
	if sonuc != OK:
		return sonuc
	return ResourceSaver.save(paket, yol)


## "<dizin><onek>_%03d.tscn": bir sonraki n (dizindeki en büyük n ve bu oturumdaki sayaç + 1).
## Dizindeki eski `<onek>_*.tscn` dosyaları (ve .uid eşleri) silinir. Aynı yol iki kez verilmez.
static func yeni_gecici_yol(dizin: String, onek: String) -> String:
	if dizin != "" and not dizin.ends_with("/"):
		dizin += "/"
	var anahtar := dizin + onek
	var en_buyuk: int = _sayaclar.get(anahtar, 0)
	var d := DirAccess.open(dizin)
	if d != null:
		var silinecek: Array[String] = []
		for dosya in d.get_files():
			if dosya.begins_with(onek + "_") and (dosya.ends_with(".tscn") or dosya.ends_with(".tscn.uid")):
				var sayi := dosya.trim_prefix(onek + "_").get_slice(".", 0)
				if sayi.is_valid_int():
					en_buyuk = maxi(en_buyuk, sayi.to_int())
				silinecek.append(dosya)
		for dosya in silinecek:
			d.remove(dosya)
	var n := en_buyuk + 1
	_sayaclar[anahtar] = n
	return "%s%s_%03d.tscn" % [dizin, onek, n]
