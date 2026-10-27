class_name BolumDenetci
extends RefCounted
## Editör bölüm denetçisi (taslak §7, §9.1 A4). Sorun öğesi biçimi BolumVerisi ile aynıdır:
##   {"kod": "D5", "seviye": "HATA", "nesne": "Asansor1", "alan": "yukseklik", "mesaj": "..."}
##
## statik(veri)      : D1-D8, D14-D20, D23-D26 (veri + gerekirse BolumKurucu ile kurulan, ağaca
##                     eklenmeyen kök); eşzamanlıdır.
## gorunurluk_tara   : ağaçtaki canlı sahnede çizimsiz çarpışma taraması (tests/test_runner.gd
##                     içindeki `_gr_bolum_tara` ile aynı kural).
## dinamik(...)      : D9-D13, D19c, D21; CozumDogrulayici ile oynatır (await edilir).
## ozet(sorunlar)    : seviye sayıları.
## Rastgelelik ve gerçek saat kullanılmaz.

## Ekran dikdörtgeni (D5).
const EKRAN := Rect2(0, 0, 1152, 648)
## Oyuncu gövdesi (28x48), çıkış (36x48), kutu (40x40).
const KARAKTER := Vector2(28, 48)
const CIKIS_BOYUTU := Vector2(36, 48)
const KUTU_BOYUTU := Vector2(40, 40)
## Lazer ışın kalınlığı (scripts/lazer.gd KALINLIK ile aynı).
const ISIN_KALINLIGI := 6.0
## D6: alt sınıra "değen" blok = alt kenarı en az bu değerde olan blok (resmî zeminler 600..640).
const ALT_SINIR_ESIGI := 640.0
## D17/D18: zıplama tepesi (ölçülen ≈ 100,9) ve zıplatıcı yüksekliği.
const ZIPLAMA_YUKSEKLIGI := 101.0
const ZIPLATICI_YUKSEKLIGI := 240.0
## D14: koridor yükseklik eşikleri.
const KORIDOR_GECILMEZ := 50.0
const KORIDOR_DAR := 100.0
## D24: kutu ile başlangıç merkezleri arası en az mesafe.
const KUTU_BASLANGIC_MESAFESI := 40.0
## D25: asansör tepesi ile tavan arası eşikleri (40 + 2 pay; 50 = karakter 48 + 2).
const TAVAN_HATA := 42.0
const TAVAN_UYARI := 50.0
## D26: kablo ile lazer arası "yakın" mesafe.
const KABLO_LAZER_MESAFESI := 8.0
## D19c: bant yakını ve bekleme eşikleri.
const BANT_YAKINLIK := 20.0
const BANT_BEKLEME_KARE := 8
## D21: tur uzunluğu üst sınırı.
const UZUN_TUR_KARE := 600
## D12: saf betik uzunluğu (kare).
const SAF_BETIK_KARE := 600

const LAZER_YONLERI := {
	"asagi": Vector2(0, 1), "yukari": Vector2(0, -1), "sag": Vector2(1, 0), "sol": Vector2(-1, 0),
}
const SAF_BETIK_ADLARI: Array[String] = ["sağa yürüme", "sağa yürüme ve zıplama", "ileri-geri yürüme ve zıplama"]


# --- Genel API ------------------------------------------------------------------------

## Statik denetimler. Şema (D1-D3) HATA verirse veri güvenilmez olduğundan yalnız onlar döner.
static func statik(veri: Dictionary) -> Array:
	var s: Array = []
	s.append_array(BolumVerisi.sema_denetle(veri))
	for o in s:
		if o["seviye"] == "HATA":
			return s
	_d4(veri, s)
	_d5(veri, s)
	_d6(veri, s)
	_d7(veri, s)
	_d8(veri, s)
	_d14(veri, s)
	_d15(veri, s)
	_d16(veri, s)
	_d17(veri, s)
	_d18(veri, s)
	_d19_statik(veri, s)
	_d20(veri, s)
	_d23(veri, s)
	_d24(veri, s)
	_d25(veri, s)
	_d26(veri, s)
	return s


## Seviye sayıları: {"hata": int, "uyari": int, "bilgi": int}.
static func ozet(sorunlar: Array) -> Dictionary:
	var r := {"hata": 0, "uyari": 0, "bilgi": 0}
	for o in sorunlar:
		match str(o.get("seviye", "")):
			"HATA":
				r["hata"] += 1
			"UYARI":
				r["uyari"] += 1
			"BILGI":
				r["bilgi"] += 1
	return r


## Çizimsiz çarpışma taraması (D4'ün canlı hâli). `sahne` ağaçta olmalı ve `_ready`'si
## çalışmış olmalıdır (Gorunum düğümleri `_ready`'de eklenir; çağıran birkaç kare beklemelidir).
## Kural `_gr_bolum_tara` ile aynıdır; tek fark `cizimsiz`/`sorun` girdilerinde "B<no>/" öneki
## yoktur (yalnız sahneye göre düğüm yolu). Dönüş: {"sayi": int, "cizimsiz": Array, "sorun": Array}.
static func gorunurluk_tara(sahne: Node) -> Dictionary:
	var sonuc := {"sayi": 0, "cizimsiz": [], "sorun": []}
	var sekiller: Array = sahne.find_children("*", "CollisionShape2D", true, false)
	for sk in sekiller:
		var sekil: CollisionShape2D = sk
		var sahip: Node = sekil.get_parent()
		if not (sahip is CollisionObject2D):
			continue
		if _gr_haric_mi(sahip, sahne):
			continue
		sonuc["sayi"] += 1
		var ad: String = str(sahne.get_path_to(sahip))
		var gorunum: Gorunum = null
		var gsahip: Node = sahip
		while gsahip != null and gsahip != sahne:
			gorunum = _gr_gorunum_bul(gsahip)
			if gorunum != null:
				break
			gsahip = gsahip.get_parent()
		if gorunum != null:
			_gr_gorunum_denetle(gorunum, gsahip, sekil, ad, sonuc)
			continue
		var kendi := false
		var n: Node = sahip
		while n != null and n != sahne:
			if _gr_kendi_cizim(n):
				kendi = true
				break
			n = n.get_parent()
		if not kendi:
			sonuc["cizimsiz"].append(ad)
	return sonuc


# --- Sorun yardımcıları ---------------------------------------------------------------

static func _sorun(kod: String, seviye: String, nesne: String, alan: String, mesaj: String) -> Dictionary:
	return {"kod": kod, "seviye": seviye, "nesne": nesne, "alan": alan, "mesaj": mesaj}


static func _ekle(s: Array, kod: String, seviye: String, nesne: String, alan: String, mesaj: String) -> void:
	s.append(_sorun(kod, seviye, nesne, alan, mesaj))


# --- Geometri yardımcıları ------------------------------------------------------------

static func _p(v: Variant) -> Vector2:
	return Vector2(float(v[0]), float(v[1]))


static func _nesneler(veri: Dictionary) -> Array:
	return veri.get("nesneler", [])


## Dinlenme durumundaki dikdörtgen (çapa tablosu: taslak §1.3). Lazerde ışın dikdörtgeni.
static func nesne_dikdortgeni(n: Dictionary) -> Rect2:
	var tur := str(n.get("tur", ""))
	if tur == "blok":
		var a: Array = n["alan"]
		return Rect2(float(a[0]), float(a[1]), float(a[2]), float(a[3]))
	if tur == "lazer":
		return isin_dikdortgeni(n)
	var k := _p(n["konum"])
	match tur:
		"tek_yonlu":
			return Rect2(k.x - 60.0, k.y, 120.0, 12.0)
		"bant":
			return Rect2(k.x - 80.0, k.y, 160.0, 16.0)
		"plaka", "zamanli_plaka", "mandal_plaka":
			return Rect2(k.x - 30.0, k.y - 16.0, 60.0, 16.0)
		"salter":
			return Rect2(k.x - 40.0, k.y - 48.0, 80.0, 48.0)
		"ziplatici":
			return Rect2(k.x - 30.0, k.y - 12.0, 60.0, 12.0)
		"asansor":
			return Rect2(k.x - 60.0, k.y, 120.0, 20.0)
		"gecit":
			return Rect2(k.x - 10.0, k.y - 200.0, 20.0, 200.0)
		"kutu":
			return Rect2(k.x - 20.0, k.y - 40.0, 40.0, 40.0)
	return Rect2()


## Lazer ışın dikdörtgeni (scripts/lazer.gd `_ready` ile aynı boyut ve konum).
static func isin_dikdortgeni(n: Dictionary) -> Rect2:
	var d: Vector2 = LAZER_YONLERI[str(n.get("yon", "asagi"))]
	var uz := float(n.get("uzunluk", BolumKurucu.VARSAYILAN_UZUNLUK))
	var boyut := Vector2(absf(d.x) * uz + absf(d.y) * ISIN_KALINLIGI, absf(d.y) * uz + absf(d.x) * ISIN_KALINLIGI)
	var merkez := _p(n["konum"]) + d * uz / 2.0
	return Rect2(merkez - boyut / 2.0, boyut)


static func _kaydir(r: Rect2, fark: Vector2) -> Rect2:
	return Rect2(r.position + fark, r.size)


static func _asansor_ust(n: Dictionary) -> Rect2:
	return _kaydir(nesne_dikdortgeni(n), Vector2(0, -float(n.get("yukseklik", BolumKurucu.VARSAYILAN_YUKSEKLIK))))


static func _gecit_acik(n: Dictionary) -> Rect2:
	return _kaydir(nesne_dikdortgeni(n), Vector2(0, -float(n.get("kayma_mesafe", BolumKurucu.VARSAYILAN_KAYMA_MESAFESI))))


static func _baslangic_dikdortgeni(veri: Dictionary) -> Rect2:
	var b := _p(veri["baslangic"])
	return Rect2(b.x - KARAKTER.x / 2.0, b.y - KARAKTER.y, KARAKTER.x, KARAKTER.y)


static func _cikis_dikdortgeni(veri: Dictionary) -> Rect2:
	var c := _p(veri["cikis"])
	return Rect2(c.x - CIKIS_BOYUTU.x / 2.0, c.y - CIKIS_BOYUTU.y, CIKIS_BOYUTU.x, CIKIS_BOYUTU.y)


## Alan > 0 olan gerçek kesişim (kenar teması sayılmaz).
static func _kesisir(a: Rect2, b: Rect2) -> bool:
	return a.position.x < b.end.x and a.end.x > b.position.x and a.position.y < b.end.y and a.end.y > b.position.y


## Verilen türlerdeki nesneler: [{"id", "tur", "n", "r"}] (r: dinlenme dikdörtgeni).
static func _liste(veri: Dictionary, turler: Array) -> Array:
	var cikti: Array = []
	for n in _nesneler(veri):
		if turler.has(str(n.get("tur", ""))):
			cikti.append({"id": str(n["id"]), "tur": str(n["tur"]), "n": n, "r": nesne_dikdortgeni(n)})
	return cikti




# --- D4: çizimsiz nesne (ağaçsız hafif tarama) ----------------------------------------

## Kurulan kök ağaca eklenmediği için `_ready` çalışmaz: sahne örnekleri (Gorunum'u kendi
## betiği ekler) çizimli sayılır, satır içi gövdelerin görünür `Gorsel`'i aranır. Canlı sahne
## taraması için `gorunurluk_tara`.
static func _d4(veri: Dictionary, s: Array) -> void:
	var kok := BolumKurucu.kur(veri)
	for sk in kok.find_children("*", "CollisionShape2D", true, false):
		var sahip: Node = sk.get_parent()
		if not (sahip is CollisionObject2D) or _gr_haric_mi(sahip, kok):
			continue
		if _agacsiz_cizimli_mi(sahip, kok):
			continue
		var ust: Node = sahip
		while ust.get_parent() != null and ust.get_parent() != kok:
			ust = ust.get_parent()
		_ekle(s, "D4", "HATA", str(ust.name), "", "çarpışması olan nesnenin ekranda çizimi yok")
	kok.free()


static func _agacsiz_cizimli_mi(sahip: Node, kok: Node) -> bool:
	var n: Node = sahip
	while n != null and n != kok:
		if n.scene_file_path != "" or _gr_kendi_cizim(n):
			return true
		n = n.get_parent()
	return false


# --- gorunurluk_tara yardımcıları (test_runner `_gr_*` ile aynı kurallar) ------------

static func _gr_haric_mi(d: Node, kok: Node) -> bool:
	var n: Node = d
	while n != null and n != kok:
		if n.name == "SinirDuvarlari" or n.name == "Oyuncu" or n.get("klon") != null:
			return true
		n = n.get_parent()
	return false


static func _gr_gorunum_bul(d: Node) -> Gorunum:
	for c in d.get_children():
		if c is Gorunum and c.name == "Gorunum":
			return c
	return null


static func _gr_kendi_cizim(d: Node) -> bool:
	for c in d.get_children():
		if (c is Polygon2D or c is ColorRect or c is Sprite2D) and c.visible:
			return true
	return false


static func _gr_dikdortgen(sekil: CollisionShape2D) -> Rect2:
	if sekil.shape is RectangleShape2D:
		var b: Vector2 = sekil.shape.size
		return Rect2(sekil.position - b / 2.0, b)
	return Rect2()


static func _gr_gorunum_denetle(gorunum: Gorunum, gsahip: Node, sekil: CollisionShape2D, ad: String, sonuc: Dictionary) -> void:
	if not Gorunum.Tur.values().has(int(gorunum.tur)):
		sonuc["sorun"].append(ad + " (geçersiz tür)")
	if gorunum.alan.size != Vector2.ZERO:
		var r := _gr_dikdortgen(sekil)
		if r.size != Vector2.ZERO:
			var a: Vector2 = gorunum.to_local(sekil.global_position) - r.size / 2.0
			var r2 := Rect2(a, r.size)
			if not gorunum.alan.grow(1.0).encloses(r2):
				sonuc["sorun"].append("%s (alan şekli kapsamıyor: alan %s, şekil %s)" % [ad, str(gorunum.alan), str(r2)])
	if gsahip is BasincPlakasi:
		var bp: BasincPlakasi = gsahip
		var beklenen := Gorunum.Tur.PLAKA
		if bp.mandal:
			beklenen = Gorunum.Tur.PLAKA_MANDAL
		elif bp.tutma_kare > 0:
			beklenen = Gorunum.Tur.PLAKA_ZAMANLI
		if gorunum.tur != beklenen:
			sonuc["sorun"].append("%s (plaka türü uyumsuz)" % ad)


# --- D5: ekran dışı -------------------------------------------------------------------

## Başlangıç, çıkış ve her nesne (asansörün üst konumu, geçidin açık konumu, lazer ucu, kablo
## noktaları dahil) ekran içinde olmalı. Bloklar yalnız tamamen ekran dışındaysa HATA verir
## (duvar/zemin bloklarının ekran kenarından taşması olağandır).
static func _d5(veri: Dictionary, s: Array) -> void:
	if not EKRAN.encloses(_baslangic_dikdortgeni(veri)):
		_ekle(s, "D5", "HATA", "", "baslangic", "başlangıç ekran dışında")
	if not EKRAN.encloses(_cikis_dikdortgeni(veri)):
		_ekle(s, "D5", "HATA", "", "cikis", "çıkış ekran dışında")
	for n in _nesneler(veri):
		var id := str(n["id"])
		var tur := str(n["tur"])
		if tur == "blok":
			if not EKRAN.intersects(nesne_dikdortgeni(n)):
				_ekle(s, "D5", "HATA", id, "alan", "blok tamamen ekran dışında")
			continue
		var r := nesne_dikdortgeni(n)
		var alan := "konum"
		if tur == "asansor":
			r = r.merge(_asansor_ust(n))
			alan = "yukseklik"
		elif tur == "gecit":
			# Resmî bölümlerde geçit açılırken tavanın içine kayar (B8, B12, B19);
			# üstten taşma serbest, yalnız x ve alt kenar ekranda olmalı.
			var ac := _gecit_acik(n).merge(r)
			r = Rect2(ac.position.x, maxf(ac.position.y, 0.0), ac.size.x, ac.end.y - maxf(ac.position.y, 0.0))
			alan = "kayma_mesafe"
		elif tur == "lazer":
			alan = "uzunluk"
		if not EKRAN.encloses(r):
			_ekle(s, "D5", "HATA", id, alan, "nesne (tüm konumlarıyla) ekran dışına taşıyor: %s" % str(r))
		_d5_kablo(veri, n, s)


static func _d5_kablo(veri: Dictionary, n: Dictionary, s: Array) -> void:
	for k in _kablo_sayisi(n):
		for nokta in BolumKurucu.kablo_noktalari(n, k, veri):
			if nokta.x < EKRAN.position.x or nokta.x > EKRAN.end.x or nokta.y < EKRAN.position.y or nokta.y > EKRAN.end.y:
				_ekle(s, "D5", "HATA", str(n["id"]), "kablolar" if str(n["tur"]) != "asansor" else "kablo", "kablo noktası ekran dışında: %s" % str(nokta))
				break


## Hedefin kablo sayısı (asansörde 1, geçit/lazerde tetikleyici sayısı).
static func _kablo_sayisi(n: Dictionary) -> int:
	match str(n["tur"]):
		"asansor":
			return 1
		"gecit", "lazer":
			return n.get("tetikleyiciler", []).size()
	return 0


# --- D6: alt sınır açık ---------------------------------------------------------------

## Alt kenarı ALT_SINIR_ESIGI'ne ulaşan blokların x aralıkları 0..1152'yi örtmeli.
static func _d6(veri: Dictionary, s: Array) -> void:
	var araliklar: Array = []
	for b in _liste(veri, ["blok"]):
		var r: Rect2 = b["r"]
		if r.end.y >= ALT_SINIR_ESIGI and r.position.y < EKRAN.end.y:
			araliklar.append([r.position.x, r.end.x])
	araliklar.sort_custom(func(a, b): return a[0] < b[0])
	var ulasilan := EKRAN.position.x
	for a in araliklar:
		if a[0] > ulasilan + 0.5:
			break
		ulasilan = maxf(ulasilan, a[1])
	if ulasilan < EKRAN.end.x - 0.5:
		_ekle(s, "D6", "HATA", "", "", "alt sınır açık: alt kenara değen bloklar x %d'den sonra örtmüyor (x 0..1152 örtülmeli)" % int(ulasilan))


# --- D7: ağaç sırası ------------------------------------------------------------------

## Kurulan kökte tetikleyici ve mekanizmaların indeksi Oyuncu'nunkinden küçük olmalı.
static func _d7(veri: Dictionary, s: Array) -> void:
	var kok := BolumKurucu.kur(veri)
	var oyuncu := kok.get_node_or_null("Oyuncu")
	if oyuncu == null:
		_ekle(s, "D7", "HATA", "", "", "kurulan sahnede Oyuncu yok")
		kok.free()
		return
	var oyuncu_sira := oyuncu.get_index()
	for n in _nesneler(veri):
		var kat: int = BolumKurucu.KATEGORI.get(str(n["tur"]), -1)
		if kat < 1 or kat > 6:
			continue
		var d := kok.get_node_or_null(str(n["id"]))
		if d == null or d.get_index() > oyuncu_sira:
			_ekle(s, "D7", "HATA", str(n["id"]), "", "ağaçta Oyuncu'dan önce gelmeli (tetikleyici/mekanizma sırası)")
	kok.free()


# --- D8: gömülü başlangıç/çıkış/kutu/plaka/zıplatıcı ----------------------------------

## Katı sayılanlar: blok, bant, kapalı geçit, alt konumdaki asansör.
static func _kati_listesi(veri: Dictionary) -> Array:
	return _liste(veri, ["blok", "bant", "gecit", "asansor"])


static func _d8(veri: Dictionary, s: Array) -> void:
	var katilar := _kati_listesi(veri)
	var b := _baslangic_dikdortgeni(veri)
	var c := _cikis_dikdortgeni(veri)
	for k in katilar:
		if _kesisir(b, k["r"]):
			_ekle(s, "D8", "HATA", "", "baslangic", "başlangıç %s içinde (katı)" % k["id"])
			break
	for k in katilar:
		if _kesisir(c, k["r"]):
			_ekle(s, "D8", "HATA", "", "cikis", "çıkış %s içinde (katı)" % k["id"])
			break
	var gomulecek := ["kutu", "plaka", "zamanli_plaka", "mandal_plaka", "ziplatici"]
	for o in _liste(veri, gomulecek):
		for k in katilar:
			if _kesisir(o["r"], k["r"]):
				_ekle(s, "D8", "HATA", o["id"], "konum", "%s, %s içine gömülü" % [o["tur"], k["id"]])
				break


# --- D14: koridor yüksekliği ----------------------------------------------------------

## Taban (blok/bant/tek yönlü) ile hemen üstündeki tavan (blok/bant ya da ekran üstü) arasındaki
## boşluk; ortak genişlik en az karakter genişliği olmalı, arada başka katı olmamalı.
static func _d14(veri: Dictionary, s: Array) -> void:
	var tabanlar := _liste(veri, ["blok", "bant", "tek_yonlu"])
	var tavanlar := _liste(veri, ["blok", "bant"])
	var engeller := tavanlar
	tavanlar = tavanlar.duplicate()
	tavanlar.append({"id": "", "tur": "ekran", "n": {}, "r": Rect2(0, -100, 1152, 100)})
	for f in tabanlar:
		for c in tavanlar:
			if c["id"] == f["id"]:
				continue
			var fr: Rect2 = f["r"]
			var cr: Rect2 = c["r"]
			var bosluk := fr.position.y - cr.end.y
			if bosluk <= 0.0 or bosluk >= KORIDOR_DAR:
				continue
			var x0 := maxf(fr.position.x, cr.position.x)
			var x1 := minf(fr.end.x, cr.end.x)
			if x1 - x0 < KARAKTER.x or _arada_engel(engeller, f["id"], c["id"], x0, x1, cr.end.y, fr.position.y):
				continue
			var tavan_adi: String = c["id"] if c["id"] != "" else "ekran üstü"
			if bosluk < KORIDOR_GECILMEZ:
				_ekle(s, "D14", "UYARI", f["id"], "", "koridor %d px: karakter ayakta geçemez (tavan: %s); bilinçli mi?" % [int(bosluk), tavan_adi])
			else:
				_ekle(s, "D14", "UYARI", f["id"], "", "koridor dar: %d px (tavan: %s)" % [int(bosluk), tavan_adi])


## [x0, x1] genişliğinde, y0..y1 bandına giren üçüncü bir katı var mı?
static func _arada_engel(engeller: Array, id_a: String, id_b: String, x0: float, x1: float, y0: float, y1: float) -> bool:
	for e in engeller:
		if e["id"] == id_a or e["id"] == id_b:
			continue
		var r: Rect2 = e["r"]
		if r.position.x < x1 and r.end.x > x0 and r.position.y < y1 and r.end.y > y0:
			return true
	return false


# --- D15: geçit koridoru tam kapatmıyor ------------------------------------------------

## Kapalı geçidin üst kenarı bir blokta (ya da ekran tavanında), alt kenarı bir yüzeyde olmalı.
static func _d15(veri: Dictionary, s: Array) -> void:
	var katilar := _liste(veri, ["blok", "bant"])
	for g in _liste(veri, ["gecit"]):
		var r: Rect2 = g["r"]
		var cx := r.get_center().x
		var ust_acik := _gecit_ust_boslugu(katilar, r, cx)
		var alt_acik := _gecit_alt_boslugu(katilar, r, cx)
		# Üstte 50 px'ten geniş boşluk bilinçli yükseklik engeli olabilir (ör. B14 GecitA); yalnız
		# dar sızıntı (1..50 px) ve altta herhangi bir boşluk geçidin kapattığı sanılan yolu açık bırakır.
		var ust_sizinti := ust_acik > 1.0 and ust_acik < KORIDOR_GECILMEZ
		if not ust_sizinti and alt_acik <= 1.0:
			continue
		_ekle(s, "D15", "UYARI", g["id"], "konum", "kapalı geçit koridoru tam kapatmıyor (üstte %d px, altta %d px açık)" % [int(ust_acik), int(alt_acik)])


## Geçidin üst kenarı ile üstündeki en yakın tavan arası (kenar blokta/tavanda ise 0).
static func _gecit_ust_boslugu(katilar: Array, r: Rect2, cx: float) -> float:
	if r.position.y <= 1.0:
		return 0.0
	var tavan := 0.0
	for k in katilar:
		var br: Rect2 = k["r"]
		if br.position.x >= cx or br.end.x <= cx:
			continue
		if br.position.y <= r.position.y + 1.0 and br.end.y >= r.position.y - 1.0:
			return 0.0
		if br.end.y < r.position.y:
			tavan = maxf(tavan, br.end.y)
	return r.position.y - tavan


## Geçidin alt kenarı ile altındaki en yakın yüzey arası (kenar yüzeyde/gömülü ise 0).
static func _gecit_alt_boslugu(katilar: Array, r: Rect2, cx: float) -> float:
	var zemin := EKRAN.end.y
	for k in katilar:
		var br: Rect2 = k["r"]
		if br.position.x >= cx or br.end.x <= cx:
			continue
		if br.position.y <= r.end.y + 1.0 and br.end.y >= r.end.y - 1.0:
			return 0.0
		if br.position.y > r.end.y:
			zemin = minf(zemin, br.position.y)
	return zemin - r.end.y


# --- D16: lazer ışını bloktan geçiyor -------------------------------------------------

## Işın dikdörtgeni ile blok kesişimi ışın ekseninde 4 px'ten uzunsa (yayıcı yüzeye oturur,
## 4 px'e kadar gömülü olabilir).
static func _d16(veri: Dictionary, s: Array) -> void:
	var bloklar := _liste(veri, ["blok"])
	for l in _liste(veri, ["lazer"]):
		var isin: Rect2 = l["r"]
		var yatay: bool = isin.size.x > isin.size.y
		for b in bloklar:
			var kesisim: Rect2 = isin.intersection(b["r"])
			var boy: float = kesisim.size.x if yatay else kesisim.size.y
			if kesisim.has_area() and boy > 4.0:
				_ekle(s, "D16", "UYARI", l["id"], "uzunluk", "lazer ışını %s bloğundan geçiyor (ışın duvarlarda kesilmez)" % b["id"])
				break


# --- D17: tek yönlü platform üstündeki plakaya alttan baş değebilir -------------------

## Plakanın alt kenarı bir tek yönlü platformun üstündeyse; platformun altındaki bir yüzeyden
## (ortak genişlik, arada katı yok) plaka alt kenarına uzaklık ≤ 48 + 101 ise UYARI.
static func _d17(veri: Dictionary, s: Array) -> void:
	var tek_yonlular := _liste(veri, ["tek_yonlu"])
	if tek_yonlular.is_empty():
		return
	var yuzeyler := _liste(veri, ["blok", "bant", "tek_yonlu"])
	var engeller := _liste(veri, ["blok", "bant"])
	var erisim := KARAKTER.y + ZIPLAMA_YUKSEKLIGI
	for p in _liste(veri, ["plaka", "zamanli_plaka", "mandal_plaka"]):
		var pr: Rect2 = p["r"]
		for t in tek_yonlular:
			var tr: Rect2 = t["r"]
			if absf(tr.position.y - pr.end.y) > 2.0 or not (tr.position.x < pr.end.x and tr.end.x > pr.position.x):
				continue
			var en_yakin := INF
			for y in yuzeyler:
				var yr: Rect2 = y["r"]
				if y["id"] == t["id"] or yr.position.y <= tr.position.y + 1.0:
					continue
				var x0 := maxf(yr.position.x, pr.position.x)
				var x1 := minf(yr.end.x, pr.end.x)
				if x1 - x0 < KARAKTER.x or _arada_engel(engeller, y["id"], t["id"], x0, x1, pr.end.y, yr.position.y):
					continue
				en_yakin = minf(en_yakin, yr.position.y - pr.end.y)
			if en_yakin <= erisim:
				_ekle(s, "D17", "UYARI", p["id"], "konum", "tek yönlü platform üstündeki plakaya alttan baş değebilir (alttaki yüzey %d px aşağıda; sınır %d px)" % [int(en_yakin), int(erisim)])
				break


# --- D18: aşılabilir yükseklik etiketi (BİLGİ) ----------------------------------------

## Blok/tek yönlü/bant için hemen altındaki en yakın yüzeye göre yükseklik etiketi.
static func _d18(veri: Dictionary, s: Array) -> void:
	var yuzeyler := _liste(veri, ["blok", "bant", "tek_yonlu"])
	for o in yuzeyler:
		var r: Rect2 = o["r"]
		var yukseklik := INF
		for y in yuzeyler:
			var yr: Rect2 = y["r"]
			if y["id"] == o["id"] or yr.position.y <= r.position.y + 0.5:
				continue
			if yr.position.x < r.end.x and yr.end.x > r.position.x:
				yukseklik = minf(yukseklik, yr.position.y - r.position.y)
		if yukseklik == INF:
			continue
		var h := int(yukseklik)
		var etiket := "zıplatıcıyla da aşılamaz"
		if yukseklik <= ZIPLAMA_YUKSEKLIGI:
			etiket = "zıplayarak aşılabilir"
		elif yukseklik <= ZIPLATICI_YUKSEKLIGI:
			etiket = "zıplatıcıyla aşılabilir"
		_ekle(s, "D18", "BILGI", o["id"], "", "altındaki yüzeye göre yükseklik %d px: %s (≤ 101 zıplama, ≤ 240 zıplatıcı)" % [h, etiket])


# --- D19: canlı/klon ayrışma riski (statik kısım: a, b) -------------------------------

static func _d19_statik(veri: Dictionary, s: Array) -> void:
	var bantlar := _liste(veri, ["bant"])
	if bantlar.is_empty():
		return
	var komsular := _liste(veri, ["blok"])
	var asansorler := _liste(veri, ["asansor"])
	for b in bantlar:
		var br: Rect2 = b["r"]
		for k in komsular:
			if _dikis_mi(br, k["r"]):
				_ekle(s, "D19", "UYARI", b["id"], "konum", "bant ile %s aynı yükseklikte bitişik (dikiş): canlı oyuncu ile klon ayrışabilir" % k["id"])
				break
		for a in asansorler:
			if _dikis_mi(br, a["r"]) or _dikis_mi(br, _asansor_ust(a["n"])):
				_ekle(s, "D19", "UYARI", b["id"], "konum", "bant ile %s aynı yükseklikte bitişik (dikiş): canlı oyuncu ile klon ayrışabilir" % a["id"])
				break
	_ekle(s, "D19", "UYARI", "", "", "bölümde taşıma bandı var: bant üstünde duraksamak canlı oyuncu ile klonu ayrıştırabilir (en çok ~20 px)")


## Üst yüzeyleri aynı yükseklikte (±1 px) ve yanlarından bitişik (±2 px) mi?
static func _dikis_mi(bant: Rect2, diger: Rect2) -> bool:
	if absf(diger.position.y - bant.position.y) > 1.0 or diger.end.y <= bant.position.y:
		return false
	return absf(diger.position.x - bant.end.x) <= 2.0 or absf(diger.end.x - bant.position.x) <= 2.0


# --- D20: işlevsiz tetikleyici, tetikleyicisiz geçit ----------------------------------

static func _d20(veri: Dictionary, s: Array) -> void:
	var kullanilan := {}
	for n in _nesneler(veri):
		match str(n["tur"]):
			"asansor":
				kullanilan[str(n.get("plaka", ""))] = true
			"gecit", "lazer":
				for t in n.get("tetikleyiciler", []):
					kullanilan[str(t)] = true
	for t in _liste(veri, BolumVerisi.TETIK_TURLERI):
		if not kullanilan.has(t["id"]):
			_ekle(s, "D20", "UYARI", t["id"], "", "işlevsiz tetikleyici: hiçbir asansöre, geçide ya da lazere bağlı değil")
	for g in _liste(veri, ["gecit"]):
		if g["n"].get("tetikleyiciler", []).is_empty():
			_ekle(s, "D20", "UYARI", g["id"], "tetikleyiciler", "tetikleyicisiz geçit hep kapalı kalır")


# --- D23: başlangıç lazer ışınının içinde ---------------------------------------------

static func _d23(veri: Dictionary, s: Array) -> void:
	var b := _baslangic_dikdortgeni(veri)
	for l in _liste(veri, ["lazer"]):
		if _kesisir(b, l["r"]):
			_ekle(s, "D23", "HATA", l["id"], "konum", "başlangıç noktası lazer ışınının içinde (ölüm-yeniden yükleme döngüsü)")


# --- D24: kutu başlangıca yakın -------------------------------------------------------

## Mesafe: kutu merkezi ile başlangıç (oyuncu) merkezi arası; < 40 px HATA.
static func _d24(veri: Dictionary, s: Array) -> void:
	var oyuncu_merkezi := _baslangic_dikdortgeni(veri).get_center()
	for k in _liste(veri, ["kutu"]):
		var mesafe: float = (k["r"] as Rect2).get_center().distance_to(oyuncu_merkezi)
		if mesafe < KUTU_BASLANGIC_MESAFESI:
			_ekle(s, "D24", "HATA", k["id"], "konum", "kutu başlangıca %d px yakın (en az %d px olmalı)" % [int(mesafe), int(KUTU_BASLANGIC_MESAFESI)])


# --- D25: asansör tepesi ile tavan arası ----------------------------------------------

## Üst konumdaki asansör yüzeyi ile üstündeki en yakın blok/bant alt kenarı (yoksa ekran tavanı
## y=0) arası: < 42 HATA, 42..49 UYARI.
static func _d25(veri: Dictionary, s: Array) -> void:
	var katilar := _liste(veri, ["blok", "bant"])
	for a in _liste(veri, ["asansor"]):
		var ust: Rect2 = _asansor_ust(a["n"])
		var tavan := 0.0
		for k in katilar:
			var kr: Rect2 = k["r"]
			if kr.position.x < ust.end.x and kr.end.x > ust.position.x and kr.end.y <= ust.position.y + 0.5:
				tavan = maxf(tavan, kr.end.y)
		var bosluk := ust.position.y - tavan
		if bosluk < TAVAN_HATA:
			_ekle(s, "D25", "HATA", a["id"], "yukseklik", "asansör tepesi ile tavan arası %d px (en az %d px olmalı)" % [int(bosluk), int(TAVAN_HATA)])
		elif bosluk < TAVAN_UYARI:
			_ekle(s, "D25", "UYARI", a["id"], "yukseklik", "asansör tepesi ile tavan arası %d px (karakter için %d px önerilir)" % [int(bosluk), int(TAVAN_UYARI)])


# --- D26: kablo lazer ışınına paralel ve yakın ----------------------------------------

## Eksene paralel kablo parçası bir lazer ışınına ≤ 8 px paralel yakınlıkta ve ışın boyunca
## örtüşüyorsa UYARI. Lazerin kendi kabloları (yayıcıya varan parça) hariç tutulur.
static func _d26(veri: Dictionary, s: Array) -> void:
	var lazerler := _liste(veri, ["lazer"])
	if lazerler.is_empty():
		return
	for n in _nesneler(veri):
		var tur := str(n["tur"])
		if tur != "gecit" and tur != "lazer" and tur != "asansor":
			continue
		var bulundu := false
		for k in _kablo_sayisi(n):
			var p := BolumKurucu.kablo_noktalari(n, k, veri)
			for i in range(p.size() - 1):
				for l in lazerler:
					if l["id"] == str(n["id"]):
						continue
					if _paralel_yakin(p[i], p[i + 1], l["r"]):
						_ekle(s, "D26", "UYARI", str(n["id"]), "kablolar" if tur != "asansor" else "kablo", "kablo parçası %s lazer ışınına paralel ve %d px içinde (görsel karışma riski)" % [l["id"], int(KABLO_LAZER_MESAFESI)])
						bulundu = true
						break
				if bulundu:
					break
			if bulundu:
				break


static func _paralel_yakin(a: Vector2, b: Vector2, isin: Rect2) -> bool:
	var yatay_isin := isin.size.x > isin.size.y
	var c := isin.get_center()
	if yatay_isin and is_equal_approx(a.y, b.y):
		return absf(a.y - c.y) <= KABLO_LAZER_MESAFESI and minf(maxf(a.x, b.x), isin.end.x) - maxf(minf(a.x, b.x), isin.position.x) > 0.0
	if not yatay_isin and is_equal_approx(a.x, b.x):
		return absf(a.x - c.x) <= KABLO_LAZER_MESAFESI and minf(maxf(a.y, b.y), isin.end.y) - maxf(minf(a.y, b.y), isin.position.y) > 0.0
	return false


# --- Dinamik denetimler ---------------------------------------------------------------

## Dinamik denetimler (D9-D13, D19c, D21); await edilir. `sahne_yolu`: bölümün BolumKurucu ile
## kaydedilmiş sahnesi. Akış (§6.4): 3 kez çözüm (D9/D10, D19c), klonsuz son tur (D12), 3 saf
## betik (D12), bir klon eksik (D13, en çok 3). `dogrulayici.ilerleme(adim, toplam, aciklama)`
## yayılır. İptalde (dogrulayici.iptal()) boş dizi döner.
static func dinamik(veri: Dictionary, dogrulayici: CozumDogrulayici, sahne_yolu: String) -> Array:
	dogrulayici.toplu_basla()
	var s: Array = await _dinamik_ic(veri, dogrulayici, sahne_yolu)
	dogrulayici.toplu_bitir()
	return s


static func _dinamik_ic(veri: Dictionary, dogrulayici: CozumDogrulayici, sahne_yolu: String) -> Array:
	var s: Array = []
	var cozum: Dictionary = veri.get("cozum", {})
	var turlar: Array = []
	for t in cozum.get("turlar", []):
		turlar.append(_coz(t))
	var son: Array = _coz(cozum.get("oyuncu", []))
	_d21(turlar, son, s)
	if son.is_empty():
		_ekle(s, "D9", "HATA", "", "cozum", "çözüm yok: son tur kaydı boş")
		return s
	if turlar.size() > int(veri.get("max_klon", 0)):
		_ekle(s, "D11", "HATA", "", "cozum", "çözüm %d klon kullanıyor, max_klon %d" % [turlar.size(), int(veri.get("max_klon", 0))])
		return s

	var plan := _plan(turlar)
	var adim := 0
	# 1) Çözüm 3 kez: D9, D10, D19c.
	var kosular: Array = []
	for i in 3:
		adim += 1
		dogrulayici.ilerleme.emit(adim, plan, "Çözüm oynatılıyor %d/3" % (i + 1))
		var o: Dictionary = await dogrulayici.oynat(sahne_yolu, turlar, son, true)
		if o.has("iptal"):
			return []
		if o.has("hata"):
			_ekle(s, "D9", "HATA", "", "cozum", "çözüm oynatılamadı (%s)" % str(o["hata"]))
			return s
		kosular.append(o)
	if not _d9(kosular[0], son, s):
		return s
	_d10(veri, kosular, s)
	_d19_dinamik(veri, kosular[0], turlar, son, s)

	# 2) Klonsuz son tur ve saf betikler: D12.
	if not turlar.is_empty():
		adim += 1
		dogrulayici.ilerleme.emit(adim, plan, "Klonsuz son tur")
		var o2: Dictionary = await dogrulayici.oynat(sahne_yolu, [], son, false)
		if o2.has("iptal"):
			return []
		if o2.get("bitti", false):
			_ekle(s, "D12", "HATA", "", "cozum", "klonsuz kısayol: son tur kaydı klon olmadan bölümü bitiriyor")
	for i in 3:
		adim += 1
		dogrulayici.ilerleme.emit(adim, plan, "Saf betik: %s" % SAF_BETIK_ADLARI[i])
		var o3: Dictionary = await dogrulayici.oynat(sahne_yolu, [], _saf_betik(i), false)
		if o3.has("iptal"):
			return []
		if o3.get("bitti", false):
			_ekle(s, "D12", "HATA", "", "cozum", "klonsuz kısayol: saf betik (%s) klon olmadan bölümü bitiriyor" % SAF_BETIK_ADLARI[i])

	# 3) Bir klon eksik: D13.
	if turlar.size() >= 2:
		for i in mini(3, turlar.size()):
			adim += 1
			dogrulayici.ilerleme.emit(adim, plan, "Bir klon eksik %d/%d" % [i + 1, mini(3, turlar.size())])
			var eksik: Array = turlar.duplicate()
			eksik.remove_at(i)
			var o4: Dictionary = await dogrulayici.oynat(sahne_yolu, eksik, son, false)
			if o4.has("iptal"):
				return []
			if o4.get("bitti", false):
				_ekle(s, "D13", "UYARI", "", "cozum", "%d. klon çıkarılınca da bölüm bitiyor: daha az klonla çözülebilir" % (i + 1))
				break
	return s


## Toplam oynatma adımı sayısı.
static func _plan(turlar: Array) -> int:
	var n := 3 + 3
	if not turlar.is_empty():
		n += 1
	if turlar.size() >= 2:
		n += mini(3, turlar.size())
	return n


## D9: ilk koşu bölümü bitirmeli ve bitiş karesi son tur kaydından uzun olmamalı. Geçerliyse true.
static func _d9(ilk: Dictionary, son: Array, s: Array) -> bool:
	if ilk.get("oldu", false):
		_ekle(s, "D9", "HATA", "", "cozum", "çözüm bölümü bitirmiyor: karakter ölüyor")
		return false
	if not ilk.get("bitti", false):
		_ekle(s, "D9", "HATA", "", "cozum", "çözüm bölümü bitirmiyor (süre doldu)")
		return false
	if int(ilk["bitis_kare"]) > son.size():
		_ekle(s, "D9", "HATA", "", "cozum", "bitiş karesi (%d) son tur kaydından (%d) uzun: kayıt eski olabilir" % [int(ilk["bitis_kare"]), son.size()])
		return false
	return true


## D10: 3 koşunun bitiş karesi ve tüm örnekleri eşit olmalı; güncel doğrulama kaydı varsa bitiş karesi ona da eşit.
static func _d10(veri: Dictionary, kosular: Array, s: Array) -> void:
	var maks := 0.0
	for i in range(1, kosular.size()):
		maks = maxf(maks, _sapma(kosular[0], kosular[i]))
	if maks > 0.0:
		_ekle(s, "D10", "HATA", "", "cozum", "determinizm bozuk: koşular arası sapma %s" % ("bitiş karesi/örnek farkı" if maks >= 1.0e9 else "%.3f px" % maks))
	var kayit: Variant = veri.get("dogrulama")
	if typeof(kayit) == TYPE_DICTIONARY and kayit.has("bitis_kare") and BolumVerisi.dogrulama_guncel_mi(veri):
		if int(kayit["bitis_kare"]) != int(kosular[0]["bitis_kare"]):
			_ekle(s, "D10", "HATA", "", "dogrulama", "kayıtlı bitiş karesi (%d) ölçülenden (%d) farklı" % [int(kayit["bitis_kare"]), int(kosular[0]["bitis_kare"])])


## İki koşu arası en büyük sapma (CozumDogrulayici._sapma ile aynı mantık; sayısal olmayan fark 1.0).
static func _sapma(a: Dictionary, b: Dictionary) -> float:
	if int(a["bitis_kare"]) != int(b["bitis_kare"]) or a["ornekler"].size() != b["ornekler"].size():
		return 1.0e9
	var maks := 0.0
	for f in range(a["ornekler"].size()):
		var x: Dictionary = a["ornekler"][f]
		var y: Dictionary = b["ornekler"][f]
		if x.size() != y.size():
			return 1.0e9
		for anahtar in x:
			if not y.has(anahtar):
				return 1.0e9
			var u: Variant = x[anahtar]
			var v: Variant = y[anahtar]
			if u is Vector2 and v is Vector2:
				maks = maxf(maks, (u - v).length())
			elif (u is float or u is int) and (v is float or v is int):
				maks = maxf(maks, absf(float(u) - float(v)))
			elif u != v:
				maks = maxf(maks, 1.0)
	return maks


## D19c: bir karakter (canlı ya da klon) bant üstünde ya da 20 px yakınında ≥ 8 kare ardışık
## yon == 0 ile duruyorsa UYARI (bant başına en çok bir kez).
static func _d19_dinamik(veri: Dictionary, kosu: Dictionary, turlar: Array, son: Array, s: Array) -> void:
	var bantlar := _liste(veri, ["bant"])
	if bantlar.is_empty():
		return
	var kayitlar := {"oyuncu": son}
	for j in turlar.size():
		kayitlar["klon_%d" % j] = turlar[j]
	var bildirilen := {}
	for b in bantlar:
		var br: Rect2 = b["r"]
		for anahtar in kayitlar:
			if bildirilen.has(b["id"]):
				break
			var kayit: Array = kayitlar[anahtar]
			var seri := 0
			for i in kosu["ornekler"].size():
				var konum: Variant = kosu["ornekler"][i].get(anahtar)
				var k: int = kosu["kareler"][i]
				var duruyor := k < kayit.size() and float(kayit[k].get("yon", 0.0)) == 0.0
				if konum is Vector2 and duruyor and _bant_yakininda(konum, br):
					seri += 1
					if seri >= BANT_BEKLEME_KARE:
						_ekle(s, "D19", "UYARI", b["id"], "cozum", "çözümde karakter bant üstünde/yakınında ≥ %d kare duruyor: canlı oyuncu ile klon ayrışabilir" % BANT_BEKLEME_KARE)
						bildirilen[b["id"]] = true
						break
				else:
					seri = 0


## Karakter merkezi: ayakları bant üst yüzeyinde (±3 px) ve x bant genişliği ±20 px içinde mi?
static func _bant_yakininda(konum: Vector2, bant: Rect2) -> bool:
	return absf(konum.y + KARAKTER.y / 2.0 - bant.position.y) <= 3.0 and konum.x >= bant.position.x - BANT_YAKINLIK and konum.x <= bant.end.x + BANT_YAKINLIK


## D21: çözümdeki bir tur 600 kareden uzunsa UYARI.
static func _d21(turlar: Array, son: Array, s: Array) -> void:
	for i in turlar.size():
		if turlar[i].size() > UZUN_TUR_KARE:
			_ekle(s, "D21", "UYARI", "", "cozum", "%d. klon turu %d kare (> %d)" % [i + 1, turlar[i].size(), UZUN_TUR_KARE])
	if son.size() > UZUN_TUR_KARE:
		_ekle(s, "D21", "UYARI", "", "cozum", "son tur %d kare (> %d)" % [son.size(), UZUN_TUR_KARE])


## Çalıştırma uzunluğu kodlu kaydı ([[n, yon, z, a], ...]) açar; açık kayıt aynen döner.
static func _coz(tur: Array) -> Array:
	if tur.size() > 0 and tur[0] is Array:
		return BolumVerisi.kayit_coz(tur)
	return tur


## D12 saf betikleri (SAF_BETIK_KARE kare): 0 sağa yürü; 1 sağa yürü + 40 karede bir zıpla;
## 2 ileri-geri (120'şer kare) + 40 karede bir zıpla.
static func _saf_betik(no: int) -> Array:
	var b: Array = []
	for k in SAF_BETIK_KARE:
		var yon := 1.0
		var zipla := false
		if no >= 1:
			zipla = k % 40 == 0
		if no == 2 and (k / 120) % 2 == 1:
			yon = -1.0
		b.append({"yon": yon, "zipla": zipla, "asagi": false})
	return b
