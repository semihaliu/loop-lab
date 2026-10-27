extends RefCounted
## Bölüm editörü testleri (docs/devir/editor_taslak.md §9.1). `class_name` yoktur.
## Aşama başına bir işlev: a1_testleri() şimdilik; A2-A4 aynı dosyaya eklenecek.
## Sonuçlar runner'ın `_kaydi(ad, gecti, ayrinti)` işleviyle yazılır.
## Yalnızca tests/editor/fikstur/*.json okunur; yalnızca user://test_editor/ altına yazılır
## ve grup sonunda o dizin tamamen silinir (kullanıcının user://bolumler/ vb. dizinlerine dokunulmaz).

const FIKSTUR := "res://tests/editor/fikstur/"
const KOK := "user://test_editor/"

var r: SceneTree


func _init(runner: SceneTree) -> void:
	r = runner


## Tam koşunun sonunda ve `--editor` bayrağında çağrılır.
func hepsi() -> void:
	await a1_testleri()
	await a2_testleri()
	await a3_testleri()
	await a4_testleri()
	await a4_ek_testleri()
	await a5_testleri()
	await a5_ek_testleri()
	await a6_testleri()
	await a6_ek_testleri()
	await a7_testleri()
	await a8_testleri()
	await a9_testleri()
	await a10_testleri()
	await a11_testleri()
	await a12_testleri()


func _kaydi(ad: String, gecti: bool, ayrinti: String) -> void:
	r.call("_kaydi", ad, gecti, ayrinti)


# ---------------------------------------------------------------- yardımcılar

func _dizin_sil(yol: String) -> void:
	var d := DirAccess.open(yol)
	if d == null:
		return
	for alt in d.get_directories():
		_dizin_sil(yol.path_join(alt))
	for dosya in d.get_files():
		DirAccess.remove_absolute(yol.path_join(dosya))
	DirAccess.remove_absolute(yol)


func _metin_yaz(yol: String, metin: String) -> void:
	DirAccess.make_dir_recursive_absolute(yol.get_base_dir())
	var f := FileAccess.open(yol, FileAccess.WRITE)
	f.store_string(metin)
	f.close()


## Fikstürü okur: {"veri", "sorunlar"}.
func _fikstur(ad: String) -> Dictionary:
	return BolumVerisi.oku(FIKSTUR + ad)


## Sorunlar içinde kod/seviye/nesne/alan tutan öğe sayısı.
func _say(sorunlar: Array, kod: String, nesne: String, alan: String) -> int:
	var n := 0
	for s in sorunlar:
		if s["kod"] == kod and s["seviye"] == "HATA" and s["nesne"] == nesne and s["alan"] == alan:
			n += 1
	return n


func _ozet_metni(sorunlar: Array) -> String:
	var p: PackedStringArray = []
	for s in sorunlar:
		p.append("%s/%s/%s/%s" % [s["kod"], s["seviye"], s["nesne"], s["alan"]])
	return "[" + ", ".join(p) + "]"


## Bir ihlal fikstürü: beklenen (kod, nesne, alan) üretilir ve veri hâlâ okunur (boş sözlük değil).
func _ihlal_testi(ad: String, dosya: String, kod: String, nesne: String, alan: String) -> void:
	var o := _fikstur(dosya)
	var sorunlar: Array = o["sorunlar"]
	var tam := _say(sorunlar, kod, nesne, alan)
	_kaydi("Editör A1: " + ad, tam >= 1 and not (o["veri"] as Dictionary).is_empty(),
		"beklenen %s/%s/%s, bulunan sorunlar: %s" % [kod, nesne, alan, _ozet_metni(sorunlar)])


# ---------------------------------------------------------------- A1

func a1_testleri() -> void:
	_dizin_sil(KOK)

	# 1) Gidiş-dönüş
	var b1 := _fikstur("b1.json")
	var veri: Dictionary = b1["veri"]
	var yol := KOK + "bolumler/gidis_donus_001.json"
	var yaz_h := BolumVerisi.yaz(veri, yol)
	var geri := BolumVerisi.oku(yol)
	var esit := (geri["veri"] as Dictionary) == veri and (geri["sorunlar"] as Array).is_empty()
	var ozet_esit := BolumVerisi.icerik_ozeti(geri["veri"]) == BolumVerisi.icerik_ozeti(veri)
	_kaydi("Editör A1: yaz -> oku gidiş-dönüş eşit", yaz_h == OK and esit and ozet_esit,
		"yaz=%d, veri eşit=%s, özet eşit=%s" % [yaz_h, esit, ozet_esit])

	# 2) B1 fikstürü
	var v: Dictionary = b1["veri"]
	var nes: Array = v.get("nesneler", [])
	var turler: Array = []
	for n in nes:
		turler.append(n["tur"])
	var b1_ok: bool = (b1["sorunlar"] as Array).is_empty() \
		and v.get("kimlik") == "deneme_asansoru_001" and v.get("ad") == "Deneme Asansörü" \
		and int(v.get("max_klon", 0)) == 2 and v.get("baslangic") == [200, 594] and v.get("cikis") == [1050, 420] \
		and turler == ["blok", "blok", "plaka", "asansor"] \
		and int(nes[3]["yukseklik"]) == 180 and nes[3]["plaka"] == "Plaka" and nes[3]["kablo"]["gizli"] == true
	_kaydi("Editör A1: B1 fikstürü sorunsuz okunur", b1_ok,
		"sorunlar=%s, türler=%s" % [_ozet_metni(b1["sorunlar"]), str(turler)])

	# 3-11) D1-D3 ihlalleri
	_ihlal_testi("D1 başlangıç yok", "ihlal_baslangic_yok.json", "D1", "", "baslangic")
	_ihlal_testi("D1 iki çıkış (cikis dizisi iki nokta)", "ihlal_iki_cikis.json", "D1", "", "cikis")
	_ihlal_testi("D2 bilinmeyen tür", "ihlal_bilinmeyen_tur.json", "D2", "Portal1", "tur")
	_ihlal_testi("D2 yukseklik 700 aralık dışı", "ihlal_yukseklik.json", "D2", "Asansor", "yukseklik")
	_ihlal_testi("D2 kayma_mesafe 250 aralık dışı", "ihlal_kayma_mesafe.json", "D2", "Gecit1", "kayma_mesafe")
	_ihlal_testi("D2 ipucu_klon 1", "ihlal_ipucu_klon.json", "D2", "", "ipucu_klon")
	_ihlal_testi("D2 yinelenen id", "ihlal_yinelenen_id.json", "D2", "Plaka", "id")
	_ihlal_testi("D2 ayrılmış id (Kapi)", "ihlal_ayrilmis_id.json", "D2", "Kapi", "id")
	_ihlal_testi("D3 asansöre şalter bağlanamaz", "ihlal_asansore_salter.json", "D3", "Asansor", "plaka")

	# 12) Ek: iki çıkışın nesneler içinde tur "cikis" biçimi de D1 sayılır (uygulayıcı davranışı)
	var iki: Dictionary = v.duplicate(true)
	(iki["nesneler"] as Array).append({"tur": "cikis", "id": "Cikis2", "konum": [900, 594]})
	var iki_s := BolumVerisi.sema_denetle(iki)
	_kaydi("Editör A1: nesneler içinde ek 'cikis' nesnesi D1 verir", _say(iki_s, "D1", "Cikis2", "tur") == 1,
		"sorunlar: " + _ozet_metni(iki_s))

	# 13) Bozuk JSON
	var bozuk := BolumVerisi.ayristir("{ \"bicim\": \"loop_lab_bolum\", ")
	var yok := BolumVerisi.oku(KOK + "yok/olmayan.json")
	var yanlis_bicim := BolumVerisi.ayristir("{\"bicim\": \"baska\", \"surum\": 1}")
	var yanlis_surum := BolumVerisi.ayristir("{\"bicim\": \"loop_lab_bolum\", \"surum\": 2}")
	var kok_dizi := BolumVerisi.ayristir("[1, 2]")
	var bozuk_ok: bool = (bozuk["veri"] as Dictionary).is_empty() and _say(bozuk["sorunlar"], "D2", "", "") == 1 \
		and (yok["veri"] as Dictionary).is_empty() and _say(yok["sorunlar"], "D2", "", "") == 1 \
		and (yanlis_bicim["veri"] as Dictionary).is_empty() and _say(yanlis_bicim["sorunlar"], "D2", "", "bicim") == 1 \
		and (yanlis_surum["veri"] as Dictionary).is_empty() and _say(yanlis_surum["sorunlar"], "D2", "", "surum") == 1 \
		and (kok_dizi["veri"] as Dictionary).is_empty() and (kok_dizi["sorunlar"] as Array).size() == 1
	_kaydi("Editör A1: bozuk JSON / eksik dosya / yanlış bicim-surum D2 verir, veri boş", bozuk_ok,
		"bozuk=%s yok=%s bicim=%s surum=%s kök=%s" % [_ozet_metni(bozuk["sorunlar"]), _ozet_metni(yok["sorunlar"]),
			_ozet_metni(yanlis_bicim["sorunlar"]), _ozet_metni(yanlis_surum["sorunlar"]), _ozet_metni(kok_dizi["sorunlar"])])

	# 14) Özet kararlı; içerik değişince değişir
	var o1 := BolumVerisi.icerik_ozeti(veri)
	var o2 := BolumVerisi.icerik_ozeti(veri.duplicate(true))
	var ad_degisti: Dictionary = veri.duplicate(true)
	ad_degisti["ad"] = "Başka Ad"
	var nesne_degisti: Dictionary = veri.duplicate(true)
	nesne_degisti["nesneler"][2]["konum"] = [351, 600]
	var sira_degisti: Dictionary = veri.duplicate(true)
	var tmp: Variant = sira_degisti["nesneler"][0]
	sira_degisti["nesneler"][0] = sira_degisti["nesneler"][1]
	sira_degisti["nesneler"][1] = tmp
	var ust_sira: Dictionary = {}
	var anahtarlar: Array = veri.keys()
	anahtarlar.reverse()
	for k in anahtarlar:
		ust_sira[k] = veri[k]
	var kararli: bool = o1 == o2 and o1.length() == 64 and o1 == BolumVerisi.icerik_ozeti(ust_sira)
	var degisir: bool = o1 != BolumVerisi.icerik_ozeti(ad_degisti) and o1 != BolumVerisi.icerik_ozeti(nesne_degisti) \
		and o1 != BolumVerisi.icerik_ozeti(sira_degisti)
	_kaydi("Editör A1: içerik özeti kararlı (anahtar sırasından bağımsız), içerik değişince değişir", kararli and degisir,
		"kararlı=%s, değişir=%s" % [kararli, degisir])

	# 15) Özet cozum/dogrulama/canli/notlar'dan etkilenmez; dogrulama_guncel_mi
	var ekli: Dictionary = veri.duplicate(true)
	ekli["cozum"] = {"turlar": [[[5, 1, 0, 0]]], "oyuncu": [[10, 0, 1, 0]]}
	ekli["canli"] = {"alindi": true, "sonra": "", "sahne": "x_001_v001.tscn", "canli_ozet": "abc"}
	ekli["notlar"] = "not"
	var etkilenmez: bool = BolumVerisi.icerik_ozeti(ekli) == o1
	ekli["dogrulama"] = {"durum": "dogrulandi", "icerik_ozeti": o1, "bitis_kare": 100, "hata": 0, "uyari": 0}
	var ozet_ayni := BolumVerisi.icerik_ozeti(ekli) == o1
	var guncel := BolumVerisi.dogrulama_guncel_mi(ekli)
	ekli["nesneler"][2]["konum"] = [360, 600]
	var eskidi := not BolumVerisi.dogrulama_guncel_mi(ekli)
	var yok_dogr := not BolumVerisi.dogrulama_guncel_mi(veri)
	var sema_ok := (BolumVerisi.sema_denetle(ekli) as Array).is_empty()
	_kaydi("Editör A1: özet cozum/dogrulama/canli/notlar'dan etkilenmez; dogrulama_guncel_mi", etkilenmez and ozet_ayni and guncel and eskidi and yok_dogr and sema_ok,
		"etkilenmez=%s, ozet_ayni=%s, güncel=%s, eskidi=%s, doğrulamasız=%s, şema=%s" % [etkilenmez, ozet_ayni, guncel, eskidi, yok_dogr, sema_ok])

	# 16) RLE gidiş-dönüş
	var tur: Array = []
	for i in 5:
		tur.append({"yon": 1.0, "zipla": false, "asagi": false})
	for i in 3:
		tur.append({"yon": 1.0, "zipla": true, "asagi": false})
	for i in 4:
		tur.append({"yon": -1.0, "zipla": false, "asagi": true})
	tur.append({"yon": 0.0, "zipla": false})            # eksik asagi
	tur.append({"yon": 0.0, "zipla": false, "asagi": false})
	tur.append({"yon": 0.5, "zipla": true, "asagi": true})
	var kod := BolumVerisi.kayit_kodla(tur)
	var coz := BolumVerisi.kayit_coz(kod)
	var rle_ok: bool = coz.size() == tur.size()
	for i in mini(coz.size(), tur.size()):
		rle_ok = rle_ok and float(coz[i]["yon"]) == float(tur[i]["yon"]) \
			and bool(coz[i]["zipla"]) == bool(tur[i]["zipla"]) \
			and bool(coz[i]["asagi"]) == bool(tur[i].get("asagi", false))
	var toplam := 0
	for e in kod:
		toplam += int(e[0])
	var kisa_ok: bool = kod.size() == 5 and toplam == tur.size() and kod[0] == [5, 1, 0, 0] and kod[3] == [2, 0, 0, 0]
	# JSON üzerinden de gidiş-dönüş (int/float normalleşmesi)
	var json_geri: Array = JSON.parse_string(JSON.stringify(kod))
	var json_ok: bool = BolumVerisi.kayit_coz(json_geri).size() == tur.size()
	# Eksik (3 elemanlı) asagi = false; bozuk öğe atlanır
	var eski := BolumVerisi.kayit_coz([[2, 1, 1], [0, 1, 0, 0], "x"])
	var eski_ok: bool = eski.size() == 2 and eski[0]["asagi"] == false and eski[0]["zipla"] == true and eski[0]["yon"] == 1.0
	_kaydi("Editör A1: çalıştırma uzunluğu kodlaması gidiş-dönüş (eksik asagi dahil)", rle_ok and kisa_ok and json_ok and eski_ok,
		"gidiş-dönüş=%s, sıkıştırma=%s (%s), json=%s, eski kayıt=%s" % [rle_ok, kisa_ok, str(kod), json_ok, eski_ok])

	# 17) slug
	var s1 := BolumVerisi.slug("Çifte Mühür")
	var uzun := "a".repeat(60)
	var s2 := BolumVerisi.slug(uzun)
	var s3 := BolumVerisi.slug("")
	var s4 := BolumVerisi.slug("  ---  ")
	var s5 := BolumVerisi.slug("Şığ Ğöl  Üçü!")
	var s6 := BolumVerisi.slug("a".repeat(35) + " bcd")        # kesim '_' üstünde biter: 35 a + '_' -> kırpılır
	var slug_ok: bool = s1 == "cifte_muhur" and s2 == "a".repeat(36) and s3 == "bolum" and s4 == "bolum" \
		and s5 == "sig_gol_ucu" and s6 == "a".repeat(35)
	_kaydi("Editör A1: slug (Çifte Mühür, 60 karakter -> 36, boş -> bolum, kesimde sondaki _ kırpılır)", slug_ok,
		"'%s' '%s' '%s' '%s' '%s' '%s'" % [s1, s2, s3, s4, s5, s6])

	# 18) yeni_kimlik dolu numaraları atlar
	var k0 := BolumVerisi.yeni_kimlik("Çifte Mühür", KOK)
	_metin_yaz(KOK + "bolumler/cifte_muhur_001.json", "{}")
	var k1 := BolumVerisi.yeni_kimlik("Çifte Mühür", KOK)
	_metin_yaz(KOK + "canli/cifte_muhur_002.json", "{}")
	var k2 := BolumVerisi.yeni_kimlik("Çifte Mühür", KOK)
	_metin_yaz(KOK + "canli/sira.json", JSON.stringify({"surum": 1, "canli": [
		{"kimlik": "cifte_muhur_003", "ad": "x", "sahne": "x.tscn", "sonra": "", "icerik_ozeti": "", "cozum_yok": true}]}))
	var k3 := BolumVerisi.yeni_kimlik("Çifte Mühür", KOK)
	# başka ad etkilenmez, sonuç kimlik desenine uyar
	var k4 := BolumVerisi.yeni_kimlik("Başka", KOK)
	var re := RegEx.new()
	re.compile(BolumVerisi.KIMLIK_DESENI)
	var uzun_kimlik := BolumVerisi.yeni_kimlik(uzun, KOK)
	var kimlik_ok: bool = k0 == "cifte_muhur_001" and k1 == "cifte_muhur_002" and k2 == "cifte_muhur_003" \
		and k3 == "cifte_muhur_004" and k4 == "baska_001" and re.search(k3) != null \
		and uzun_kimlik == "a".repeat(36) + "_001" and uzun_kimlik.length() == 40 and re.search(uzun_kimlik) != null
	_kaydi("Editör A1: yeni_kimlik bolumler/ + canli/ + sira.json dolu numaralarını atlar", kimlik_ok,
		"%s %s %s %s %s %s" % [k0, k1, k2, k3, k4, uzun_kimlik])

	# 19) BolumYollari.kip: 4 kip x doğru/yanlış örnek, test kökü dahil
	var ornekler := [
		["res://scenes/bolumler/bolum_1.tscn", &"resmi"],
		["res://tests/sahneler/lazer_test.tscn", &"resmi"],
		["user://editor/dene_001.tscn", &"dene"],
		["user://test_editor/editor/dene_001.tscn", &"dene"],
		["user://oyna/oyna_007.tscn", &"ozel"],
		["user://test_editor/oyna/oyna_001.tscn", &"ozel"],
		["user://canli/ornek_001_v002.tscn", &"canli"],
		["user://test_editor/canli/ornek_001_v001.tscn", &"canli"],
		["user://editor/oyna_001.tscn", &""],          # dizin dene, ad oyna_
		["user://oyna/dene_001.tscn", &""],
		["user://canli/ornek_001.json", &""],            # canli ama .tscn değil
		["user://bolumler/x_001.tscn", &""],
		["user://baska/dene_001.tscn", &""],
	]
	var kip_ok := true
	var kip_kotu: PackedStringArray = []
	for o in ornekler:
		var k: StringName = BolumYollari.kip(o[0])
		if k != o[1]:
			kip_ok = false
			kip_kotu.append("%s -> %s (beklenen %s)" % [o[0], k, o[1]])
	# Yardımcılar yalnız kendi kipinde true
	var yard_ok: bool = BolumYollari.dene_mi("user://test_editor/editor/dene_001.tscn") \
		and not BolumYollari.ozel_mi("user://test_editor/editor/dene_001.tscn") \
		and not BolumYollari.canli_mi("user://test_editor/editor/dene_001.tscn") \
		and BolumYollari.ozel_mi("user://oyna/oyna_001.tscn") and not BolumYollari.dene_mi("user://oyna/oyna_001.tscn") \
		and BolumYollari.canli_mi("user://canli/a_001_v001.tscn") and not BolumYollari.ozel_mi("user://canli/a_001_v001.tscn") \
		and not BolumYollari.dene_mi("res://scenes/bolumler/bolum_1.tscn") \
		and not BolumYollari.ozel_mi("res://scenes/bolumler/bolum_1.tscn") \
		and not BolumYollari.canli_mi("res://scenes/bolumler/bolum_1.tscn")
	_kaydi("Editör A1: BolumYollari.kip 4 kip x doğru/yanlış örnek (test kökü dahil)", kip_ok and yard_ok,
		"kötü: %s, yardımcılar=%s" % [str(kip_kotu), yard_ok])

	# 20) Dizin yardımcıları (kök varsayılanı ve "/" ekleme)
	var diz_ok: bool = BolumYollari.bolumler_dizini() == "user://bolumler/" \
		and BolumYollari.editor_dizini() == "user://editor/" \
		and BolumYollari.oyna_dizini() == "user://oyna/" \
		and BolumYollari.canli_dizini() == "user://canli/" \
		and BolumYollari.bolumler_dizini("user://test_editor/") == "user://test_editor/bolumler/" \
		and BolumYollari.canli_dizini("user://test_editor") == "user://test_editor/canli/"
	_kaydi("Editör A1: BolumYollari dizin yardımcıları", diz_ok, "ok=%s" % diz_ok)

	# Temizlik: test dizini tamamen silinir
	_dizin_sil(KOK)
	var silindi := not DirAccess.dir_exists_absolute(KOK)
	_kaydi("Editör A1: user://test_editor/ test sonunda tamamen silindi", silindi, "dizin yok=%s" % silindi)
	await r.physics_frame


# ---------------------------------------------------------------- A2

const ATLA_OZELLIK := ["owner", "scene_file_path", "script", "unique_name_in_owner", "name", "plaka", "tetikleyici_yollari"]
const ATLA_META := ["editor_ad", "cozum_yok"]
const GECIT_SAHNESI := "res://scenes/gecit.tscn"


func _v(nesneler: Array, ad := "Deneme") -> Dictionary:
	var v := BolumVerisi.bos(ad, "deneme_001")
	v["nesneler"] = nesneler
	return v


func _zemin() -> Dictionary:
	return {"tur": "blok", "id": "Zemin", "alan": [0, 600, 1152, 40]}


func _pl(id: String, x: int, y: int) -> Dictionary:
	return {"tur": "plaka", "id": id, "konum": [x, y]}


func _p(noktalar: Array) -> PackedVector2Array:
	var a := PackedVector2Array()
	for n in noktalar:
		a.append(Vector2(float(n[0]), float(n[1])))
	return a


## Kurar, user://test_editor/editor/ altına sayaçlı yola kaydeder; yol ("" = hata).
## Aynı önekli eski dosyalar silinir (yeni_gecici_yol), bu yüzden farklı sahneler için farklı önek kullanılır.
func _kayit_yolu(veri: Dictionary, onek := "dene") -> String:
	var yol := BolumKurucu.yeni_gecici_yol(KOK + "editor/", onek)
	return yol if BolumKurucu.sahneye_kaydet(veri, yol) == OK else ""


## Diskten, önbelleği yok sayarak yükler ve örnekler (ağaca eklenmez). Çağıran free() eder.
func _diskten(yol: String) -> Node:
	var p := ResourceLoader.load(yol, "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	return p.instantiate() if p != null else null


func _kur_diskten(veri: Dictionary) -> Node:
	return _diskten(_kayit_yolu(veri))


func _tum_alt(d: Node) -> Array:
	var a: Array = []
	for c in d.get_children():
		a.append(c)
		a.append_array(_tum_alt(c))
	return a


func _ozellikler(d: Node, kok_mu: bool) -> Dictionary:
	var s := {}
	for p in d.get_property_list():
		if (p.usage & PROPERTY_USAGE_STORAGE) and not (p.usage & PROPERTY_USAGE_INTERNAL):
			var ad: String = p.name
			if ad in ATLA_OZELLIK or ad.begins_with("metadata/"):
				continue
			s[ad] = d.get(ad)
	for m in d.get_meta_list():
		if kok_mu and str(m) in ATLA_META:
			continue
		s["meta/" + str(m)] = d.get_meta(m)
	return s


## Tek düğüm çifti: sınıf, scene_file_path, betik, kayıtlı özellikler (collision_layer/mask dahil), metalar,
## şekil boyutu, plaka ve tetikleyici_yollari. derin: çocuklara da iner (satır içi düğümler).
func _karsilastir(o: Node, y: Node, yol: String, derin: bool, kok_mu: bool, farklar: Array) -> void:
	if o.get_class() != y.get_class():
		farklar.append("%s sınıf %s/%s" % [yol, o.get_class(), y.get_class()])
	if not kok_mu and o.scene_file_path != y.scene_file_path:
		farklar.append("%s scene_file_path %s/%s" % [yol, o.scene_file_path, y.scene_file_path])
	var bo: String = o.get_script().resource_path if o.get_script() != null else ""
	var by: String = y.get_script().resource_path if y.get_script() != null else ""
	if bo != by:
		farklar.append("%s betik %s/%s" % [yol, bo, by])
	var so := _ozellikler(o, kok_mu)
	var sy := _ozellikler(y, kok_mu)
	for k in so.keys() + sy.keys():
		if not so.has(k) or not sy.has(k):
			farklar.append("%s özellik eksik: %s" % [yol, k])
			continue
		var vo: Variant = so[k]
		var vy: Variant = sy[k]
		if typeof(vo) == TYPE_OBJECT or typeof(vy) == TYPE_OBJECT:
			if k == "shape":
				if vo == null or vy == null or vo.get_class() != vy.get_class() or vo.get("size") != vy.get("size"):
					farklar.append("%s şekil farkı" % yol)
			continue
		if vo != vy:
			farklar.append("%s %s: %s / %s" % [yol, k, str(vo), str(vy)])
	var po: Variant = o.get("plaka")
	if po is Node:
		var py: Variant = y.get("plaka")
		if not (py is Node) or str(o.get_path_to(po)) != str(y.get_path_to(py)):
			farklar.append("%s plaka yolu" % yol)
	var to: Variant = o.get("tetikleyici_yollari")
	if to != null and to != y.get("tetikleyici_yollari"):
		farklar.append("%s tetikleyici_yollari %s / %s" % [yol, str(to), str(y.get("tetikleyici_yollari"))])
	if derin:
		if o.get_child_count() != y.get_child_count():
			farklar.append("%s çocuk sayısı %d/%d" % [yol, o.get_child_count(), y.get_child_count()])
			return
		for i in o.get_child_count():
			var c := o.get_child(i)
			if c.name != y.get_child(i).name:
				farklar.append("%s çocuk adı %s/%s" % [yol, c.name, y.get_child(i).name])
				continue
			_karsilastir(c, y.get_child(i), yol + "/" + str(c.name), c.scene_file_path == "", false, farklar)


## Kök: kök özellikleri/metaları (editor_ad, cozum_yok hariç) + çocuk adı/sırası; fazladan yalnız EditorHud.
func _kok_karsilastir(o: Node, y: Node) -> Array:
	var farklar: Array = []
	_karsilastir(o, y, "kök", false, true, farklar)
	var adlar_o: Array = []
	for c in o.get_children():
		adlar_o.append(str(c.name))
	var adlar_y: Array = []
	for c in y.get_children():
		adlar_y.append(str(c.name))
	if adlar_y != adlar_o + ["EditorHud"]:
		farklar.append("çocuk adları/sırası: orijinal=%s yeni=%s" % [str(adlar_o), str(adlar_y)])
		return farklar
	for i in o.get_child_count():
		var c := o.get_child(i)
		_karsilastir(c, y.get_child(i), str(c.name), c.scene_file_path == "", false, farklar)
	return farklar


func _esdeger_testi(ad: String, fikstur: String, orijinal: String) -> void:
	var o_f := _fikstur(fikstur)
	var veri: Dictionary = o_f["veri"]
	var yol := _kayit_yolu(veri)
	var y := _diskten(yol)
	var orj: Node = (load(orijinal) as PackedScene).instantiate()
	var farklar: Array = []
	if y == null:
		farklar.append("sahne diskten yüklenemedi: " + yol)
	else:
		farklar = _kok_karsilastir(orj, y)
	var sorunsuz: bool = (o_f["sorunlar"] as Array).is_empty() and BolumVerisi.sema_denetle(veri).is_empty()
	var dosya_ok: bool = yol.begins_with(KOK) and FileAccess.file_exists(yol)
	_kaydi("Editör A2: yapısal eşdeğerlik " + ad, farklar.is_empty() and sorunsuz and dosya_ok,
		"fark=%d %s, fikstür sorunsuz=%s, dosya=%s" % [farklar.size(), str(farklar.slice(0, 6)), sorunsuz, dosya_ok])
	if y != null:
		y.free()
	orj.free()


func _kablo_meta_adlari(d: Node) -> Array:
	var a: Array = []
	for n in d.get_children():
		for m in n.get_meta_list():
			if str(m).begins_with("kablo"):
				a.append("%s/%s" % [n.name, m])
	return a


## Her türden bir nesne; özel değerlerle (alan değerleri ve çapa testleri).
func _tum_turler_verisi() -> Dictionary:
	var v := _v([
		{"tur": "blok", "id": "Blok", "alan": [100, 300, 200, 20]},
		{"tur": "tek_yonlu", "id": "Raf", "konum": [380, 380]},
		{"tur": "bant", "id": "Bant", "konum": [570, 400], "yon": -1},
		_pl("Plaka", 87, 600),
		{"tur": "zamanli_plaka", "id": "PlakaZ", "konum": [120, 600], "tutma_kare": 240},
		{"tur": "mandal_plaka", "id": "PlakaM", "konum": [160, 600]},
		{"tur": "salter", "id": "Salter", "konum": [500, 600], "baslangic_sagda": true},
		{"tur": "ziplatici", "id": "Z", "konum": [370, 600]},
		{"tur": "asansor", "id": "Asansor", "konum": [750, 600], "yukseklik": 250, "plaka": "Plaka"},
		{"tur": "gecit", "id": "G", "konum": [265, 600], "kayma_mesafe": 100, "tetikleyiciler": ["Plaka"], "acik_taraf_sag": false},
		{"tur": "lazer", "id": "L", "konum": [900, 300], "yon": "sol", "uzunluk": 350, "tetikleyiciler": ["Salter"],
			"tetik_aktifken_kapali": false, "acik_taraf_sag": false},
		{"tur": "kutu", "id": "Kutu", "konum": [675, 600]}])
	v["max_klon"] = 3
	return v


func a2_testleri() -> void:
	_dizin_sil(KOK)
	var saklanan_bolum: Variant = r.get("aktif_bolum")

	# ---- 1-5) Yapısal eşdeğerlik
	_esdeger_testi("B1", "b1.json", "res://scenes/bolumler/bolum_1.tscn")
	_esdeger_testi("B5", "b5.json", "res://scenes/bolumler/bolum_5.tscn")
	_esdeger_testi("B10", "b10.json", "res://scenes/bolumler/bolum_10.tscn")
	_esdeger_testi("B14", "b14.json", "res://scenes/bolumler/bolum_14.tscn")
	_esdeger_testi("B21", "b21.json", "res://scenes/bolumler/bolum_21.tscn")

	# ---- 6) Kablo meta'ları: B21'de 5 tane birebir; B5/B10/B14'te yok
	var b21 := _kur_diskten(_fikstur("b21.json")["veri"])
	var gg: Node = b21.get_node("GecitG")
	var gm: Node = b21.get_node("GecitM")
	var la: Node = b21.get_node("LazerA")
	var lb: Node = b21.get_node("LazerB")
	var b21_ok: bool = _kablo_meta_adlari(b21).size() == 5 \
		and gg.get_meta("kablo") == _p([[170, 584], [170, 376]]) \
		and gg.get_meta("kablo_2") == _p([[110, 372], [125, 372], [125, 300], [160, 300]]) \
		and gm.get_meta("kablo") == _p([[110, 372], [125, 372], [125, 190], [650, 190]]) \
		and la.get_meta("kablo") == _p([[508, 584], [508, 184], [520, 184]]) \
		and lb.get_meta("kablo") == _p([[820, 372], [880, 372], [880, 184], [903, 184]])
	var orj21: Node = (load("res://scenes/bolumler/bolum_21.tscn") as PackedScene).instantiate()
	var meta_esit := true
	for ad in ["GecitG", "GecitM", "LazerA", "LazerB"]:
		var mo: Array = orj21.get_node(ad).get_meta_list()
		var my: Array = b21.get_node(ad).get_meta_list()
		mo.sort()
		my.sort()
		meta_esit = meta_esit and mo == my
		for m in mo:
			meta_esit = meta_esit and orj21.get_node(ad).get_meta(m) == b21.get_node(ad).get_meta(m)
	_kaydi("Editör A2: B21'de 5 kablo meta'sı birebir (orijinalle de aynı)", b21_ok and meta_esit,
		"meta=%s, beklenen değerler=%s, orijinalle eşit=%s" % [str(_kablo_meta_adlari(b21)), b21_ok, meta_esit])
	b21.free()
	orj21.free()
	var yok_ok := true
	var yok_ayr := ""
	for f in ["b5.json", "b10.json", "b14.json"]:
		var yd := _kur_diskten(_fikstur(f)["veri"])
		var mm := _kablo_meta_adlari(yd)
		yok_ok = yok_ok and mm.is_empty()
		yok_ayr += "%s=%s " % [f, str(mm)]
		yd.free()
	_kaydi("Editör A2: B5/B10/B14'te kablo meta'sı yok (gizli bağlantılar)", yok_ok, yok_ayr)

	# ---- 7) Diskten yükleme: üç farklı boyutlu blok
	var boyut_v := _v([
		{"tur": "blok", "id": "A", "alan": [0, 600, 1152, 40]},
		{"tur": "blok", "id": "B", "alan": [100, 300, 200, 20]},
		{"tur": "blok", "id": "C", "alan": [500, 200, 37, 91]}])
	var bd := _kur_diskten(boyut_v)
	var beklenen_boyut := {"A": Vector2(1152, 40), "B": Vector2(200, 20), "C": Vector2(37, 91)}
	var boyut_ok := true
	var sekiller: Array = []
	var boyut_ayr := ""
	for ad in beklenen_boyut:
		var sk: RectangleShape2D = bd.get_node(ad + "/CollisionShape2D").shape
		var gr: ColorRect = bd.get_node(ad + "/Gorsel")
		var bv: Vector2 = beklenen_boyut[ad]
		boyut_ok = boyut_ok and sk.size == bv \
			and gr.offset_left == -bv.x / 2.0 and gr.offset_right == bv.x / 2.0 \
			and gr.offset_top == -bv.y / 2.0 and gr.offset_bottom == bv.y / 2.0
		sekiller.append(sk)
		boyut_ayr += "%s=%s " % [ad, str(sk.size)]
	var ayri_ok: bool = sekiller[0] != sekiller[1] and sekiller[1] != sekiller[2] and sekiller[0] != sekiller[2]
	_kaydi("Editör A2: diskten yükleme, üç farklı boyutlu blok kendi boyutunda ve ayrı şekil nesneleri", boyut_ok and ayri_ok,
		"%s ayrı nesneler=%s" % [boyut_ayr, ayri_ok])
	bd.free()

	# ---- 8) İki geçit şekli 20x200 (paylaşılan alt kaynak bozulmamış)
	var gecit_v := _v([_zemin(),
		{"tur": "gecit", "id": "G1", "konum": [800, 500], "kayma_mesafe": 100},
		{"tur": "gecit", "id": "G2", "konum": [900, 500], "kayma_mesafe": 200}])
	var gd := _kur_diskten(gecit_v)
	var gecit_ref: Node = (load(GECIT_SAHNESI) as PackedScene).instantiate()
	var s1: Vector2 = gd.get_node("G1/CollisionShape2D").shape.size
	var s2: Vector2 = gd.get_node("G2/CollisionShape2D").shape.size
	var sr: Vector2 = gecit_ref.get_node("CollisionShape2D").shape.size
	_kaydi("Editör A2: iki geçit örneğinin şekli 20x200 kalır", s1 == Vector2(20, 200) and s2 == Vector2(20, 200) and sr == Vector2(20, 200),
		"G1=%s G2=%s gecit.tscn=%s" % [str(s1), str(s2), str(sr)])
	gecit_ref.free()
	gd.free()

	# ---- 9) kayma_mesafe açıkça yazılı: 100 iken sahne varsayılanı 200'e düşmez
	var km_v := _v([_zemin(),
		{"tur": "gecit", "id": "G100", "konum": [300, 500], "kayma_mesafe": 100},
		{"tur": "gecit", "id": "G200", "konum": [500, 500], "kayma_mesafe": 200},
		{"tur": "gecit", "id": "G150", "konum": [700, 500], "kayma_mesafe": 150},
		{"tur": "gecit", "id": "Gvarsayilan", "konum": [900, 500]}])
	var km := _kur_diskten(km_v)
	var gecit_ref2: Node = (load(GECIT_SAHNESI) as PackedScene).instantiate()
	var sahne_200: bool = float(gecit_ref2.get("kayma_mesafe")) == 200.0
	var km_ok: bool = float(km.get_node("G100").get("kayma_mesafe")) == 100.0 \
		and float(km.get_node("G200").get("kayma_mesafe")) == 200.0 \
		and float(km.get_node("G150").get("kayma_mesafe")) == 150.0 \
		and float(km.get_node("Gvarsayilan").get("kayma_mesafe")) == 100.0
	_kaydi("Editör A2: kayma_mesafe açıkça yazılı (100 iken sahne varsayılanı 200'e düşmez)", km_ok and sahne_200,
		"100->%s 200->%s 150->%s yok->%s, gecit.tscn varsayılanı=%s" % [km.get_node("G100").get("kayma_mesafe"),
			km.get_node("G200").get("kayma_mesafe"), km.get_node("G150").get("kayma_mesafe"),
			km.get_node("Gvarsayilan").get("kayma_mesafe"), gecit_ref2.get("kayma_mesafe")])
	gecit_ref2.free()
	km.free()

	# ---- 10) Sahne örneklerinin iç çocuklarında owner yok
	var tum_v := _tum_turler_verisi()
	var kok := BolumKurucu.kur(tum_v)
	var owner_ok := true
	var owner_ayr := ""
	var ornek_say := 0
	for c in kok.get_children():
		if c.owner != kok:
			owner_ok = false
			owner_ayr += "doğrudan çocuk owner'ı köke bağlı değil: %s; " % c.name
		if c.scene_file_path != "":
			ornek_say += 1
			for alt in _tum_alt(c):
				if alt.owner == kok:
					owner_ok = false
					owner_ayr += "iç çocuk köke bağlı: %s/%s; " % [c.name, alt.name]
		else:
			for alt in _tum_alt(c):
				if alt.owner != kok:
					owner_ok = false
					owner_ayr += "satır içi alt düğüm owner eksik: %s/%s; " % [c.name, alt.name]
	kok.free()
	# Diske yazılan metinde de iç çocuk satırı yoktur (parent="<örnek>" biçimi satır içi düğümlere özgüdür).
	var metin := FileAccess.get_file_as_string(_kayit_yolu(tum_v))
	for id in ["Raf", "Bant", "PlakaZ", "PlakaM", "Salter", "Z", "G", "L", "Kutu"]:
		if metin.contains('parent="%s"' % id):
			owner_ok = false
			owner_ayr += "dosyada iç çocuk satırı: %s; " % id
	_kaydi("Editör A2: sahne örneklerinin iç çocuklarında owner yok, satır içi alt düğümler köke bağlı", owner_ok and ornek_say >= 9,
		"örnek sayısı=%d %s" % [ornek_say, owner_ayr])

	# ---- 11) Kategori sırası ve D7
	var karisik := _v([
		{"tur": "kutu", "id": "Kutu1", "konum": [600, 600]},
		{"tur": "lazer", "id": "LazerX", "konum": [900, 300], "yon": "asagi", "uzunluk": 200, "tetikleyiciler": ["PlakaB"]},
		{"tur": "gecit", "id": "G1", "konum": [700, 600], "kayma_mesafe": 100, "tetikleyiciler": ["PlakaB"]},
		{"tur": "asansor", "id": "AsansorX", "konum": [300, 600], "yukseklik": 180, "plaka": "PlakaA"},
		{"tur": "ziplatici", "id": "Z1", "konum": [450, 600]},
		{"tur": "salter", "id": "Salter1", "konum": [500, 600]},
		{"tur": "mandal_plaka", "id": "MandalP", "konum": [80, 600]},
		_pl("PlakaB", 400, 600),
		{"tur": "bant", "id": "BantX", "konum": [800, 600], "yon": 1},
		{"tur": "zamanli_plaka", "id": "ZamanliP", "konum": [120, 600], "tutma_kare": 180},
		_pl("PlakaA", 160, 600),
		{"tur": "blok", "id": "Blok1", "alan": [0, 600, 1152, 40]},
		{"tur": "tek_yonlu", "id": "Tek1", "konum": [1000, 400]}])
	var kd := _kur_diskten(karisik)
	var adlar: Array = []
	for c in kd.get_children():
		adlar.append(str(c.name))
	var beklenen_sira: Array = ["BantX", "Blok1", "Tek1", "MandalP", "PlakaB", "ZamanliP", "PlakaA", "Salter1", "Z1",
		"AsansorX", "G1", "LazerX", "Kapi", "Kutu1", "Oyuncu", "Bilgi", "EditorHud"]
	var oyuncu_i: int = kd.get_node("Oyuncu").get_index()
	var d7_ok := true
	for id in ["MandalP", "PlakaB", "ZamanliP", "PlakaA", "Salter1", "Z1", "AsansorX", "G1", "LazerX", "Kapi"]:
		d7_ok = d7_ok and kd.get_node(id).get_index() < oyuncu_i
	_kaydi("Editör A2: karışık sıralı JSON kategori sırasıyla kurulur, mekanizmalar Oyuncu'dan önce (D7)", adlar == beklenen_sira and d7_ok,
		"sıra=%s d7=%s" % [str(adlar), d7_ok])
	kd.free()

	# ---- 12) Çapa -> position tablosu (taslak 1.3) ve B1 örneği
	var b1d := _kur_diskten(_fikstur("b1.json")["veri"])
	var b1_ok: bool = b1d.get_node("Zemin").position == Vector2(576, 620) and b1d.get_node("Cikinti").position == Vector2(916, 440) \
		and b1d.get_node("Plaka").position == Vector2(350, 592) and b1d.get_node("Asansor").position == Vector2(620, 610) \
		and b1d.get_node("Kapi").position == Vector2(1050, 396) and b1d.get_node("Oyuncu").position == Vector2(200, 570)
	var td := _kur_diskten(tum_v)
	var tablo := {"Blok": Vector2(200, 310), "Raf": Vector2(380, 386), "Bant": Vector2(570, 408), "Plaka": Vector2(87, 592),
		"PlakaZ": Vector2(120, 592), "PlakaM": Vector2(160, 592), "Salter": Vector2(500, 600), "Z": Vector2(370, 594),
		"Asansor": Vector2(750, 610), "G": Vector2(265, 500), "L": Vector2(900, 300), "Kutu": Vector2(675, 580)}
	var tablo_ok := true
	var tablo_ayr := ""
	for id in tablo:
		var pz: Vector2 = td.get_node(id).position
		if pz != tablo[id]:
			tablo_ok = false
			tablo_ayr += "%s=%s (beklenen %s); " % [id, str(pz), str(tablo[id])]
	_kaydi("Editör A2: çapa -> düğüm position (B1 örneği ve her tür)", b1_ok and tablo_ok,
		"B1=%s %s" % [b1_ok, tablo_ayr])
	b1d.free()

	# ---- 13) Alan değerleri diskten: hız sabitleri, özel değerler
	var h_ok := true
	var h_ayr := ""
	var kontrol := {
		"Asansor.hiz": float(td.get_node("Asansor").get("hiz")) == 120.0,
		"Asansor.yukseklik": float(td.get_node("Asansor").get("yukseklik")) == 250.0,
		"G.hiz": float(td.get_node("G").get("hiz")) == 120.0,
		"G.kayma_yonu": td.get_node("G").get("kayma_yonu") == Vector2(0, -1),
		"G.acik_taraf_sag": td.get_node("G").get("acik_taraf_sag") == false,
		"Bant.hiz": float(td.get_node("Bant").get("hiz")) == 100.0,
		"Bant.yon": int(td.get_node("Bant").get("yon")) == -1,
		"Z.firlatma_hizi": float(td.get_node("Z").get("firlatma_hizi")) == 820.0,
		"PlakaZ.tutma_kare": int(td.get_node("PlakaZ").get("tutma_kare")) == 240,
		"PlakaM.mandal": bool(td.get_node("PlakaM").get("mandal")),
		"Salter.baslangic_sagda": bool(td.get_node("Salter").get("baslangic_sagda")),
		"L.yon": td.get_node("L").get("yon") == Vector2(-1, 0),
		"L.uzunluk": float(td.get_node("L").get("uzunluk")) == 350.0,
		"L.tetik_aktifken_kapali": td.get_node("L").get("tetik_aktifken_kapali") == false,
		"L.acik_taraf_sag": td.get_node("L").get("acik_taraf_sag") == false,
		"kök.max_klon": int(td.get("max_klon")) == 3,
		"kök.ipucu_klon": int(td.get("ipucu_klon")) == 0,
	}
	for k in kontrol:
		if not kontrol[k]:
			h_ok = false
			h_ayr += k + " "
	_kaydi("Editör A2: diskten yüklenen alan değerleri (hızlar, tutma_kare, yön, uzunluk, max_klon, ipucu_klon)", h_ok,
		"yanlış: [%s]" % h_ayr)
	td.free()

	# ---- 14-18) Kablo
	_a2_kablo_testleri()

	# ---- 19) editor_ad
	var ad_v := _v([_zemin()], "Çifte Mühür")
	var ak := BolumKurucu.kur(ad_v)
	var ad_kur: String = str(ak.get_meta("editor_ad", "?"))
	ak.free()
	var ad_disk := _kur_diskten(ad_v)
	var ad_d: String = str(ad_disk.get_meta("editor_ad", "?"))
	ad_disk.free()
	_kaydi("Editör A2: metadata/editor_ad doğru yazılır (kurulumda ve diskte)", ad_kur == "Çifte Mühür" and ad_d == "Çifte Mühür",
		"kur=%s disk=%s" % [ad_kur, ad_d])

	# ---- 20-23) cozum_yok + EditorHud
	await _a2_hud_testleri()

	# ---- 24) Önbellek
	var vA := _fikstur("b1.json")["veri"] as Dictionary
	var vB := _fikstur("b5.json")["veri"] as Dictionary
	var yolA := _kayit_yolu(vA)
	var pA := load(yolA) as PackedScene
	var iA := pA.instantiate()
	var yolB := _kayit_yolu(vB)
	var pB := load(yolB) as PackedScene
	var iB := pB.instantiate()
	var onbellek_ok: bool = yolA != yolB and iA.get_node_or_null("Lazer1") == null and iA.get_node_or_null("Asansor") != null \
		and iB.get_node_or_null("Lazer1") != null and iB.get_node_or_null("Salter") != null and pB.resource_path == yolB
	_kaydi("Editör A2: ardışık iki farklı kurulumda ikincisinin içeriği yüklenir (önbellek)", onbellek_ok,
		"yolA=%s yolB=%s A'da Lazer1=%s B'de Lazer1=%s" % [yolA, yolB, iA.get_node_or_null("Lazer1") != null, iB.get_node_or_null("Lazer1") != null])
	iA.free()
	iB.free()

	# ---- 25) yeni_gecici_yol eski dosyayı siler
	var yg := KOK + "yg"
	var y1 := BolumKurucu.yeni_gecici_yol(yg, "dene")
	var k1 := BolumKurucu.sahneye_kaydet(vA, y1)
	var y1_var := FileAccess.file_exists(y1)
	_metin_yaz(yg + "/oyna_005.tscn", "x")
	_metin_yaz(yg + "/dene_notu.txt", "x")
	var y2 := BolumKurucu.yeni_gecici_yol(yg + "/", "dene")
	var y1_silindi := not FileAccess.file_exists(y1)
	var k2 := BolumKurucu.sahneye_kaydet(vB, y2)
	var y2_var := FileAccess.file_exists(y2)
	var y3 := BolumKurucu.yeni_gecici_yol(yg, "dene")
	var y2_silindi := not FileAccess.file_exists(y2)
	var re := RegEx.new()
	re.compile("^user://test_editor/yg/dene_[0-9]{3}\\.tscn$")
	var yg_ok: bool = k1 == OK and k2 == OK and y1_var and y1_silindi and y2_var and y2_silindi \
		and re.search(y1) != null and re.search(y2) != null and re.search(y3) != null \
		and y1 != y2 and y2 != y3 and y1 != y3 \
		and FileAccess.file_exists(yg + "/oyna_005.tscn") and FileAccess.file_exists(yg + "/dene_notu.txt")
	_kaydi("Editör A2: yeni_gecici_yol eski dosyayı siler, başka önek/dosyaya dokunmaz, yol yeniden verilmez", yg_ok,
		"y1=%s y2=%s y3=%s y1 silindi=%s y2 silindi=%s" % [y1, y2, y3, y1_silindi, y2_silindi])

	# ---- 26-30) Geçici sahnede oyun yolu
	await _a2_oyun_testleri()

	r.set("aktif_bolum", saklanan_bolum)
	r.paused = false
	r.root.get_node("Kayitlar").call("sifirla")
	_dizin_sil(KOK)
	var silindi := not DirAccess.dir_exists_absolute(KOK)
	_kaydi("Editör A2: user://test_editor/ test sonunda tamamen silindi", silindi, "dizin yok=%s" % silindi)
	await r.physics_frame


# ---------------------------------------------------------------- A2 kablo

func _kablo_verisi(g_kablolar: Array, a_kablo: Variant = null) -> Dictionary:
	var g := {"tur": "gecit", "id": "G", "konum": [700, 600], "kayma_mesafe": 100,
		"tetikleyiciler": ["PlakaA", "PlakaB", "PlakaC"]}
	if not g_kablolar.is_empty():
		g["kablolar"] = g_kablolar
	var a := {"tur": "asansor", "id": "Asansor", "konum": [1000, 600], "yukseklik": 180, "plaka": "PlakaC"}
	if a_kablo != null:
		a["kablo"] = a_kablo
	var l := {"tur": "lazer", "id": "L", "konum": [900, 300], "yon": "asagi", "uzunluk": 200, "tetikleyiciler": ["PlakaA"]}
	return _v([_zemin(), _pl("PlakaA", 300, 600), _pl("PlakaB", 400, 600), _pl("PlakaC", 500, 600), g, a, l])


func _a2_kablo_testleri() -> void:
	# Otomatik L (geçit, lazer, asansör): kablo kaydı yok -> gizli değil
	var v := _kablo_verisi([])
	var d := _kur_diskten(v)
	var n: Array = v["nesneler"]
	var g_ok: bool = d.get_node("G").get_meta("kablo") == _p([[300, 592], [300, 500], [700, 500]])
	var l_ok: bool = d.get_node("L").get_meta("kablo") == _p([[300, 592], [300, 300], [900, 300]])
	var a_ok: bool = d.get_node("Asansor").get_meta("kablo") == _p([[500, 592], [500, 600], [1000, 600]])
	var fn_ok: bool = BolumKurucu.kablo_noktalari(n[4], 0, v) == _p([[300, 592], [300, 500], [700, 500]]) \
		and BolumKurucu.kablo_noktalari(n[5], 0, v) == _p([[500, 592], [500, 600], [1000, 600]])
	_kaydi("Editör A2: kablo otomatik L yolu (geçit, lazer, asansör; tetikleyici -> (tetik.x, hedef.y) -> hedef)", g_ok and l_ok and a_ok and fn_ok,
		"gecit=%s lazer=%s asansör=%s kablo_noktalari=%s" % [g_ok, l_ok, a_ok, fn_ok])
	d.free()

	# Ara noktalı
	var v2 := _kablo_verisi([{"tetik": "PlakaB", "ara": [[400, 450], [650, 450]]}])
	var d2 := _kur_diskten(v2)
	var ara_ok: bool = d2.get_node("G").get_meta("kablo_2") == _p([[400, 592], [400, 450], [650, 450], [700, 500]]) \
		and d2.get_node("G").get_meta("kablo") == _p([[300, 592], [300, 500], [700, 500]])
	_kaydi("Editör A2: kablo ara noktalı yol ([tetikleyici] + ara + [hedef]); kayıtsız bağlantı otomatik L", ara_ok,
		"kablo_2=%s" % str(d2.get_node("G").get_meta("kablo_2", null)))
	d2.free()

	# uclar aynen
	var v3 := _kablo_verisi([
		{"tetik": "PlakaA", "ara": [[10, 10]], "uclar": [[1, 2], [3, 4]]},
		{"tetik": "PlakaB", "ara": [], "uclar": [[5, 6], [7, 8]]}])
	var d3 := _kur_diskten(v3)
	var uc_ok: bool = d3.get_node("G").get_meta("kablo") == _p([[1, 2], [10, 10], [3, 4]]) \
		and d3.get_node("G").get_meta("kablo_2") == _p([[5, 6], [7, 8]]) \
		and d3.get_node("G").get_meta("kablo_3") == _p([[500, 592], [500, 500], [700, 500]])
	_kaydi("Editör A2: kablo uclar aynen yazılır (ara ile ve araşız)", uc_ok,
		"kablo=%s kablo_2=%s" % [str(d3.get_node("G").get_meta("kablo", null)), str(d3.get_node("G").get_meta("kablo_2", null))])
	d3.free()

	# Gizli: meta yok; diğer bağlantılar etkilenmez; asansör de gizlenebilir
	var v4 := _kablo_verisi([{"tetik": "PlakaA", "gizli": true}], {"gizli": true})
	var d4 := _kur_diskten(v4)
	var g4: Node = d4.get_node("G")
	var gizli_ok: bool = not g4.has_meta("kablo") and g4.has_meta("kablo_2") and g4.has_meta("kablo_3") \
		and not d4.get_node("Asansor").has_meta("kablo") and BolumKurucu.kablo_noktalari(v4["nesneler"][4], 0, v4).is_empty() \
		and BolumKurucu.kablo_noktalari(v4["nesneler"][5], 0, v4).is_empty()
	_kaydi("Editör A2: gizli kablo için meta yazılmaz (geçit tetikleyicisi ve asansör)", gizli_ok,
		"G metaları=%s asansör kablo=%s" % [str(g4.get_meta_list()), d4.get_node("Asansor").has_meta("kablo")])
	d4.free()

	# 3 tetikleyici: kablo, kablo_2, kablo_3
	var d5 := _kur_diskten(_kablo_verisi([]))
	var g5: Node = d5.get_node("G")
	var ad_ok: bool = BolumKurucu.kablo_meta_adi(0) == "kablo" and BolumKurucu.kablo_meta_adi(1) == "kablo_2" \
		and BolumKurucu.kablo_meta_adi(2) == "kablo_3" and BolumKurucu.kablo_meta_adi(3) == "kablo_4"
	var uc_adlar_ok: bool = g5.get_meta("kablo") == _p([[300, 592], [300, 500], [700, 500]]) \
		and g5.get_meta("kablo_2") == _p([[400, 592], [400, 500], [700, 500]]) \
		and g5.get_meta("kablo_3") == _p([[500, 592], [500, 500], [700, 500]]) and not g5.has_meta("kablo_4")
	_kaydi("Editör A2: 3 tetikleyicili geçitte kablo, kablo_2, kablo_3 meta adları", ad_ok and uc_adlar_ok,
		"adlar=%s meta=%s" % [ad_ok, str(g5.get_meta_list())])
	d5.free()


# ---------------------------------------------------------------- A2 cozum_yok ve EditorHud

func _sahne_ac(veri: Dictionary) -> Node:
	var yol := _kayit_yolu(veri)
	r.set("aktif_bolum", yol)
	r.root.get_node("Kayitlar").call("sifirla")
	return await r.call("_bolumu_yukle")


func _a2_hud_testleri() -> void:
	var temel := _fikstur("b1.json")["veri"] as Dictionary

	# Çözümsüz: meta true, Uyari var
	var b: Node = await _sahne_ac(temel)
	var hud := b.get_node_or_null("EditorHud") as CanvasLayer
	var uyari: Label = hud.get_node_or_null("Uyari") if hud != null else null
	var bilgi: Label = b.get_node("Bilgi")
	var yok_ok: bool = hud != null and uyari != null and bool(b.get_meta("cozum_yok", false)) \
		and uyari.text == "Bu bölümün doğrulanmış çözümü yok" and uyari.position.y > bilgi.position.y \
		and hud.layer == 8 and hud.get_index() > bilgi.get_index() and bilgi.get_index() > b.get_node("Oyuncu").get_index()
	_kaydi("Editör A2: çözümsüz bölümde cozum_yok=true ve EditorHud/Uyari var", yok_ok,
		"hud=%s uyari=%s meta=%s" % [hud != null, uyari != null, b.get_meta("cozum_yok", null)])

	# EditorHud fareyi yutmaz
	var fare_ok: bool = hud != null and uyari != null and uyari.mouse_filter == Control.MOUSE_FILTER_IGNORE
	var fare_ayr := ""
	if hud != null:
		for c in _tum_alt(hud):
			if c is Control and (c as Control).mouse_filter != Control.MOUSE_FILTER_IGNORE:
				fare_ok = false
				fare_ayr += "%s " % c.name
		# Bölümün ekran butonu fareyi hâlâ alır (HUD onun üstünde fareyi yutmaz)
		var dugme := b.get_node("EkranButonlari/Kutu/YenidenDugmesi") as Button
		fare_ok = fare_ok and dugme.mouse_filter != Control.MOUSE_FILTER_IGNORE
	_kaydi("Editör A2: EditorHud fareyi yutmaz (tüm Control'ler MOUSE_FILTER_IGNORE)", fare_ok, "yutan: [%s]" % fare_ayr)

	# Güncel doğrulandı: false, Uyari yok
	var dv: Dictionary = temel.duplicate(true)
	dv["dogrulama"] = {"durum": "dogrulandi", "icerik_ozeti": BolumVerisi.icerik_ozeti(dv), "bitis_kare": 200, "hata": 0, "uyari": 0}
	b = await _sahne_ac(dv)
	var hud2 := b.get_node_or_null("EditorHud")
	var g_ok: bool = hud2 != null and hud2.get_node_or_null("Uyari") == null and not bool(b.get_meta("cozum_yok", true))
	_kaydi("Editör A2: güncel doğrulanmış bölümde cozum_yok=false ve Uyari yok", g_ok,
		"hud=%s uyari var=%s meta=%s" % [hud2 != null, hud2 != null and hud2.get_node_or_null("Uyari") != null, b.get_meta("cozum_yok", null)])

	# İçerik değişince (özet eski) yine true; durum "taslak" ise de true
	var eski: Dictionary = dv.duplicate(true)
	eski["nesneler"][2]["konum"] = [360, 600]
	b = await _sahne_ac(eski)
	var hud3 := b.get_node_or_null("EditorHud")
	var e_ok: bool = hud3 != null and hud3.get_node_or_null("Uyari") != null and bool(b.get_meta("cozum_yok", false))
	var taslak: Dictionary = temel.duplicate(true)
	taslak["dogrulama"] = {"durum": "taslak", "icerik_ozeti": BolumVerisi.icerik_ozeti(taslak), "bitis_kare": 0, "hata": 0, "uyari": 0}
	b = await _sahne_ac(taslak)
	var hud4 := b.get_node_or_null("EditorHud")
	var t_ok: bool = hud4 != null and hud4.get_node_or_null("Uyari") != null and bool(b.get_meta("cozum_yok", false))
	_kaydi("Editör A2: içerik değişince (eski özet) ya da durum taslak ise yine cozum_yok=true ve Uyari var", e_ok and t_ok,
		"eski özet=%s taslak=%s" % [e_ok, t_ok])


# ---------------------------------------------------------------- A2 oyun yolu (geçici sahne)

func _a2_oyun_testleri() -> void:
	var temel := _fikstur("b1.json")["veri"] as Dictionary
	var kayitlar: Node = r.root.get_node("Kayitlar")

	# B1 bitirilir (mevcut B1 betikleriyle); yanlış zamanlama bitirmez
	var yol := _kayit_yolu(temel, "b1")
	r.set("aktif_bolum", yol)
	var dogru: Array = await r.call("_kaydet", r.call("_dogru_kayit_betigi"))
	var s: Dictionary = await r.call("_senaryo", [dogru], r.call("_cozum_betigi"), 700)
	var erken: Array = await r.call("_kaydet", r.call("_erken_kayit_betigi"))
	var s_hata: Dictionary = await r.call("_senaryo", [erken], r.call("_cozum_betigi"), 700)
	_kaydi("Editör A2: B1 fikstüründen kurulan sahnede B1 betikleriyle bölüm bitirilir; erken klon bitirmez",
		bool(s["bitti"]) and not bool(s_hata["bitti"]),
		"doğru: bitti=%s kare=%s; erken klon: bitti=%s" % [s["bitti"], s["kare"], s_hata["bitti"]])
	r.paused = false

	# 100x determinizm (EditorHud + Uyari ile)
	r.set("aktif_bolum", yol)
	var betik: Array = r.call("_betik", [[5, 0, false], [25, 1, false], [1, 1, true], [40, 1, false],
		[10, -1, false], [20, 0, false], [30, 1, false]])
	var kayit: Array = await r.call("_kaydet", betik)
	var referans: Array = []
	var sapmali := 0
	var maks_sapma := 0.0
	for n in 100:
		var sn: Dictionary = await r.call("_senaryo", [kayit], [], 300)
		var iz: Array = sn["klon_izleri"][0]
		if n == 0:
			referans = iz
			continue
		var bu := iz.size() != referans.size()
		for f in mini(iz.size(), referans.size()):
			var dd: float = (iz[f] - referans[f]).length()
			if dd > 0.0:
				bu = true
				maks_sapma = maxf(maks_sapma, dd)
		if bu:
			sapmali += 1
	var min_y := 1.0e9
	var maks_x := -1.0e9
	for p in referans:
		min_y = minf(min_y, p.y)
		maks_x = maxf(maks_x, p.x)
	var hareket: bool = min_y < referans[0].y - 20.0 and maks_x > referans[0].x + 100.0
	var hud_var: bool = r.current_scene != null and r.current_scene.get_node_or_null("EditorHud/Uyari") != null
	_kaydi("Editör A2: B1 fikstüründe 100x determinizm EditorHud ile de 0 sapma", sapmali == 0 and hareket and hud_var,
		"100 çalıştırma x %d kare, sapmalı=%d, en büyük sapma=%.4f px, klon hareket etti=%s, HUD uyarısı var=%s" % [
			referans.size(), sapmali, maks_sapma, hareket, hud_var])

	# R: yeni klon, aynı geçici sahne yeniden yüklenir
	kayitlar.call("sifirla")
	r.paused = false
	var b: Node = await r.call("_bolumu_yukle")
	var kimlik0: int = b.get_instance_id()
	for i in 5:
		r.call("_girdi_uygula", {"yon": 1.0, "zipla": false})
		await r.physics_frame
	r.call("_girdi_uygula", {"yon": 0.0, "zipla": false})
	await r.call("_r_bas")
	var y1: Node = await r.call("_yeni_sahne_bekle", kimlik0)
	var r_ok: bool = y1 != null and y1.scene_file_path == yol and kayitlar.turlar.size() == 1 \
		and (r.call("_klonlar", y1) as Array).size() == 1 and y1.get_node_or_null("EditorHud") != null \
		and y1.get_node("Oyuncu").position == Vector2(200, 570) and str(y1.get_meta("editor_ad", "")) == "Deneme Asansörü"
	_kaydi("Editör A2: geçici sahnede R (tur bitir) aynı sahneyi yeniden yükler, klon oluşur", r_ok,
		"yeni sahne=%s yol eşit=%s kayıt=%d" % [y1 != null, y1 != null and y1.scene_file_path == yol, kayitlar.turlar.size()])

	# T: baştan başla
	var kimlik1: int = y1.get_instance_id() if y1 != null else 0
	await r.call("_t_bas")
	var y2: Node = await r.call("_yeni_sahne_bekle", kimlik1)
	var t_ok: bool = y2 != null and y2.scene_file_path == yol and kayitlar.turlar.size() == 0 \
		and (r.call("_klonlar", y2) as Array).size() == 0 and y2.get_node_or_null("EditorHud") != null \
		and str(y2.bilgi.text).begins_with("Tur 1 ")
	_kaydi("Editör A2: geçici sahnede T (baştan başla) kayıtları siler, aynı sahne yeniden yüklenir", t_ok,
		"yeni sahne=%s kayıt=%d etiket=%s" % [y2 != null, kayitlar.turlar.size(), str(y2.bilgi.text) if y2 != null else "-"])

	# Ölüm: lazere yürü
	var olum_v := _v([_zemin(),
		{"tur": "lazer", "id": "Lazer", "konum": [500, 400], "yon": "asagi", "uzunluk": 300}])
	var yol_o := _kayit_yolu(olum_v, "olum")
	r.set("aktif_bolum", yol_o)
	kayitlar.call("sifirla")
	var o: Node = await r.call("_bolumu_yukle")
	var kimlik_o: int = o.get_instance_id()
	var yeni_o: Node = null
	for i in 150:
		r.call("_girdi_uygula", {"yon": 1.0, "zipla": false})
		await r.physics_frame
		if r.current_scene != null and r.current_scene.get_instance_id() != kimlik_o and r.current_scene.is_node_ready():
			yeni_o = r.current_scene
			break
	r.call("_girdi_uygula", {"yon": 0.0, "zipla": false})
	var o_ok: bool = yeni_o != null and yeni_o.scene_file_path == yol_o and kayitlar.turlar.size() == 0 \
		and yeni_o.get_node_or_null("EditorHud") != null and yeni_o.get_node("Oyuncu").position == Vector2(200, 570)
	_kaydi("Editör A2: geçici sahnede ölüm turu yeniden başlatır (tur sayısı artmaz, aynı sahne)", o_ok,
		"yeniden yüklendi=%s kayıt=%d" % [yeni_o != null, kayitlar.turlar.size()])

	# Toparla: ölüm sahnesinden çık
	r.set("aktif_bolum", yol)
	kayitlar.call("sifirla")
	r.paused = false
	await r.call("_bolumu_yukle")


# ---------------------------------------------------------------- A3 CozumDogrulayici

func _dogrulayici() -> CozumDogrulayici:
	var d := CozumDogrulayici.new()
	r.root.add_child(d)
	return d


func _a3_bitir(d: CozumDogrulayici) -> void:
	d.queue_free()
	r.paused = false
	for a in ["sol", "sag", "zipla", "asagi"]:
		Input.action_release(a)


func a3_testleri() -> void:
	var kayitlar: Node = r.root.get_node("Kayitlar")
	var temel := _fikstur("b1.json")["veri"] as Dictionary
	var b1_yol := _kayit_yolu(temel, "a3b1")
	var dogru: Array = r.call("_dogru_kayit_betigi")
	var cozum: Array = r.call("_cozum_betigi")
	var d := _dogrulayici()
	var ts0 := Engine.time_scale
	var tps0 := Engine.physics_ticks_per_second

	# B1 + bilinen kayıt: biter, ölmez, bitis_kare <= kayıt uzunluğu
	var s: Dictionary = await d.oynat(b1_yol, [dogru], cozum)
	var kare_ok: bool = (s["kareler"] as Array).size() > 0 and int(s["kareler"][0]) == 0 		and s["kareler"].size() == s["ornekler"].size()
	_kaydi("Editör A3: B1 fikstürü + bilinen kayıt bölümü bitirir (ölmez)", bool(s["bitti"]) and not bool(s["oldu"]) and not s.has("hata") and kare_ok,
		"bitti=%s oldu=%s bitis_kare=%s örnek=%d" % [s["bitti"], s["oldu"], s["bitis_kare"], s["ornekler"].size()])
	_kaydi("Editör A3: bitis_kare, son tur kaydı uzunluğunu (%d) aşmaz" % cozum.size(),
		bool(s["bitti"]) and int(s["bitis_kare"]) > 0 and int(s["bitis_kare"]) <= cozum.size(),
		"bitis_kare=%s kayıt=%d" % [s["bitis_kare"], cozum.size()])
	var bitis_ref: int = int(s["bitis_kare"])

	# Yanlış (erken) klon betiği: bitmedi, ölmedi
	var erken: Array = r.call("_erken_kayit_betigi")
	var se: Dictionary = await d.oynat(b1_yol, [erken], cozum)
	_kaydi("Editör A3: erken (yanlış zamanlı) klon kaydıyla bölüm 'bitmedi' olur", not bool(se["bitti"]) and not bool(se["oldu"]) and int(se["bitis_kare"]) == -1,
		"bitti=%s oldu=%s bitis_kare=%s" % [se["bitti"], se["oldu"], se["bitis_kare"]])

	# Süre sınırı: boş son tur, 10 kare kayıt -> 10 + SURE_PAYI kare
	var bos_tur: Array = r.call("_betik", [[10, 0, false]])
	var ss: Dictionary = await d.oynat(b1_yol, [], bos_tur)
	var bekl: int = 10 + CozumDogrulayici.SURE_PAYI
	_kaydi("Editör A3: süre sınırı (en uzun tur + SURE_PAYI) dolunca oynatma durur, sonuç 'bitmedi'",
		not bool(ss["bitti"]) and not bool(ss["oldu"]) and not ss.has("hata") and (ss["kareler"] as Array).size() == bekl,
		"örnek sayısı=%d beklenen=%d bitti=%s" % [(ss["kareler"] as Array).size(), bekl, ss["bitti"]])

	# Aynı karede zıplama: enjekte edilen action_press, aynı kayıtla oynayan klonla (kayıt kare k'da
	# zıplar) aynı karede etki eder: canlı oyuncu ve klon y yörüngesi 0 px farklı olmalı.
	var zv := _v([_zemin()], "Ziplama")
	var z_yol := _kayit_yolu(zv, "a3z")
	var zt: Array = r.call("_betik", [[40, 0, false], [20, 0, true]])
	var sz: Dictionary = await d.oynat(z_yol, [], zt)               # canlı oyuncu zıplar
	var sk2: Dictionary = await d.oynat(z_yol, [zt], [])            # klon aynı kaydı oynar
	var oz: Array = sz["ornekler"]
	var ok2: Array = sk2["ornekler"]
	var n_ok: int = mini(oz.size(), ok2.size())
	var maks_fark := 0.0
	var ilk_oyuncu := -1
	var ilk_klon := -1
	for q in range(n_ok):
		var yo: float = oz[q]["oyuncu"].y
		var yk: float = ok2[q]["klon_0"].y
		maks_fark = maxf(maks_fark, absf(yo - yk))
		if ilk_oyuncu < 0 and yo < oz[0]["oyuncu"].y - 0.5 and q > 20:
			ilk_oyuncu = q
		if ilk_klon < 0 and yk < ok2[0]["klon_0"].y - 0.5 and q > 20:
			ilk_klon = q
	_kaydi("Editör A3: öncelikli düğümden action_press ile zıplama aynı karede gerçekleşir (klonla aynı kare)",
		n_ok >= 50 and ilk_klon > 0 and ilk_oyuncu == ilk_klon and maks_fark == 0.0,
		"canlı oyuncu ilk yükselme örneği=%d, klon=%d, en büyük y farkı=%.3f px (örnek %d)" % [ilk_oyuncu, ilk_klon, maks_fark, n_ok])

	# Lazere yürüyen kayıt: oldu
	var lv := _v([_zemin(),
		{"tur": "lazer", "id": "Lazer", "konum": [500, 400], "yon": "asagi", "uzunluk": 300}], "Lazerli")
	var l_yol := _kayit_yolu(lv, "a3l")
	var sl: Dictionary = await d.oynat(l_yol, [], r.call("_betik", [[250, 1, false]]))
	_kaydi("Editör A3: lazere yürüyen kayıt 'oldu' verir (bitmedi)", bool(sl["oldu"]) and not bool(sl["bitti"]),
		"oldu=%s bitti=%s örnek=%d" % [sl["oldu"], sl["bitti"], (sl["ornekler"] as Array).size()])

	# Klon sınırı: max_klon (2) aşılır
	var uc: Array = [dogru, dogru, dogru]
	var sk: Dictionary = await d.oynat(b1_yol, uc, cozum)
	_kaydi("Editör A3: klon sayısı max_klon'u aşan kayıt reddedilir (hata=klon_siniri, oynatma yok)",
		str(sk.get("hata", "")) == "klon_siniri" and not bool(sk["bitti"]) and (sk["ornekler"] as Array).is_empty() and kayitlar.turlar.size() == 0,
		"hata=%s örnek=%d Kayitlar.turlar=%d" % [sk.get("hata", "-"), (sk["ornekler"] as Array).size(), kayitlar.turlar.size()])

	# Zaman ölçeği/fizik hızı korunur (bu ana kadar yapılan tüm oynatmalardan sonra)
	_kaydi("Editör A3: Engine.time_scale == 1 ve physics_ticks_per_second == 60 korunur",
		Engine.time_scale == 1.0 and Engine.physics_ticks_per_second == 60 and ts0 == 1.0 and tps0 == 60,
		"time_scale=%s (önce %s) tps=%d (önce %d)" % [Engine.time_scale, ts0, Engine.physics_ticks_per_second, tps0])

	# İptal: yarıda durur, iptal anahtarı, Kayitlar boş
	var kutu := {"s": null}
	d.bitti.connect(func(x: Dictionary) -> void: kutu["s"] = x)
	d.oynat(b1_yol, [dogru], cozum)   # await edilmez; iptal edilecek
	for i in 40:
		await r.physics_frame
	var once_bos: bool = kayitlar.turlar.size() > 0
	d.iptal()
	for i in 10:
		await r.physics_frame
		if kutu["s"] != null:
			break
	var si: Dictionary = kutu["s"] if kutu["s"] != null else {}
	_kaydi("Editör A3: iptal oynatmayı yarıda durdurur, Kayitlar boş kalır",
		once_bos and si.has("iptal") and not bool(si.get("bitti", true)) and (si.get("ornekler", []) as Array).size() < 100 and kayitlar.turlar.size() == 0,
		"çalışırken Kayitlar dolu=%s iptal=%s örnek=%d Kayitlar.turlar=%d" % [once_bos, si.has("iptal"), (si.get("ornekler", []) as Array).size(), kayitlar.turlar.size()])
	for i in 5:
		await r.physics_frame

	# 100x determinizm (kurucunun eklediği EditorHud ile; B1 çözümsüz olduğundan Uyari da var)
	var dt: Dictionary = await d.determinizm(b1_yol, {"turlar": [dogru], "oyuncu": cozum}, 100)
	var hud_var: bool = r.current_scene != null and r.current_scene.get_node_or_null("EditorHud/Uyari") != null
	_kaydi("Editör A3: B1 fikstüründe 100x determinizm (EditorHud ile) sapma 0 ve bitis_kare sabit",
		bool(dt["gecti"]) and int(dt["sapmali"]) == 0 and float(dt["maks_sapma"]) == 0.0 and int(dt["bitis_kare"]) == bitis_ref and hud_var,
		"gecti=%s sapmalı=%s maks_sapma=%s bitis_kare=%s (tek oynatma %d) HUD uyarısı=%s" % [dt["gecti"], dt["sapmali"], dt["maks_sapma"], dt["bitis_kare"], bitis_ref, hud_var])

	# Determinizm: RLE kodlu kayıtla da aynı sonuç, kısa tekrar
	var rle := {"turlar": [BolumVerisi.kayit_kodla(dogru)], "oyuncu": BolumVerisi.kayit_kodla(cozum)}
	var dr: Dictionary = await d.determinizm(b1_yol, rle, 3)
	_kaydi("Editör A3: çalıştırma uzunluğu kodlu kayıtla determinizm aynı bitis_kare'yi verir",
		bool(dr["gecti"]) and int(dr["bitis_kare"]) == bitis_ref,
		"gecti=%s bitis_kare=%s beklenen=%d" % [dr["gecti"], dr["bitis_kare"], bitis_ref])

	_a3_bitir(d)
	kayitlar.call("sifirla")
	_dizin_sil(KOK)


# ---------------------------------------------------------------- A4 BolumDenetci (D1-D26)

func _t(ek: Array, ad := "Denetim") -> Dictionary:
	var l: Array = [_zemin()]
	l.append_array(ek)
	return _v(l, ad)


func _sd(v: Dictionary) -> Array:
	return BolumDenetci.statik(v)


## kod (+ isteğe bağlı seviye/nesne/alan; "*" = herhangi) tutan sorun sayısı.
func _n(s: Array, kod: String, seviye := "*", nesne := "*", alan := "*") -> int:
	var c := 0
	for o in s:
		if o["kod"] == kod and (seviye == "*" or o["seviye"] == seviye) and (nesne == "*" or o["nesne"] == nesne) and (alan == "*" or o["alan"] == alan):
			c += 1
	return c


func _k4(ad: String, ok: bool, ayr: String) -> void:
	_kaydi("Editör A4: " + ad, ok, ayr)


## Olumlu: veri şemadan geçer (denetim boşuna atlanmaz) ve kod hiç çıkmaz.
func _temiz(ad: String, v: Dictionary, kod: String) -> void:
	var sema: Array = BolumVerisi.sema_denetle(v)
	var s := _sd(v)
	_k4(ad, sema.is_empty() and _n(s, kod) == 0, "şema=%s; sorunlar: %s" % [_ozet_metni(sema), _ozet_metni(s)])


## Olumsuz: veri şemadan geçer ve (kod, seviye, nesne, alan) en az bir kez çıkar.
func _sorunlu(ad: String, v: Dictionary, kod: String, seviye: String, nesne: String, alan: String) -> Array:
	var sema: Array = BolumVerisi.sema_denetle(v)
	var s := _sd(v)
	_k4(ad, sema.is_empty() and _n(s, kod, seviye, nesne, alan) >= 1,
		"beklenen %s/%s/%s/%s; şema=%s; sorunlar: %s" % [kod, seviye, nesne, alan, _ozet_metni(sema), _ozet_metni(s)])
	return s


## Dinamik denetim: sahneyi kaydeder, CozumDogrulayici'yı ağaca ekler (1 process + 1 physics karesi bekler).
func _din(veri: Dictionary, onek: String) -> Array:
	var yol := _kayit_yolu(veri, onek)
	var d := _dogrulayici()
	await r.process_frame
	await r.physics_frame
	var s: Array = await BolumDenetci.dinamik(veri, d, yol)
	_a3_bitir(d)
	r.root.get_node("Kayitlar").call("sifirla")
	return s


func _yuru_betik(sag: int, bekle := 0) -> Array:
	var p: Array = [[sag, 1, false]]
	if bekle > 0:
		p.append([bekle, 0, false])
	return r.call("_betik", p)


func _bant_verisi() -> Dictionary:
	return _v([
		{"tur": "blok", "id": "ZSol", "alan": [0, 600, 120, 40]},
		{"tur": "blok", "id": "Alt", "alan": [120, 616, 160, 24]},
		{"tur": "bant", "id": "Bant", "konum": [200, 600], "yon": 1},
		{"tur": "blok", "id": "ZSag", "alan": [280, 600, 872, 40]}], "Bantli")


## Gözden geçirici sonrası eklemeler: D5 geçit kuralı, toplu işte iptal, 'mesgul'.
func a4_ek_testleri() -> void:
	var kayitlar: Node = r.root.get_node("Kayitlar")
	var temel := _fikstur("b1.json")["veri"] as Dictionary

	# --- (a) D5 geçit. Resmî .tscn'de geçit konumu gövde MERKEZİdir (200 px yüksek, 20 px geniş);
	# veri formatında konum alt-orta noktadır: konum = (merkez.x, merkez.y + 100). kayma_mesafe 100.
	var resmi := [["B8 Gecit (320,140)", 320, 140], ["B12 GecitA1 (700,190)", 700, 190],
		["B12 GecitB (980,190)", 980, 190], ["B12 GecitA2 (1060,190)", 1060, 190], ["B19 GecitG (790,60)", 790, 60]]
	for e in resmi:
		var vg := _t([{"tur": "gecit", "id": "G", "konum": [e[1], e[2] + 100], "kayma_mesafe": 100}])
		var sg := _sd(vg)
		_k4("D5 geçit olumlu: resmî %s (açılırken tavana kayar) D5 vermez" % e[0],
			BolumVerisi.sema_denetle(vg).is_empty() and _n(sg, "D5") == 0, _ozet_metni(sg))
	var vgal := _t([{"tur": "gecit", "id": "G", "konum": [320, 700], "kayma_mesafe": 100}])
	_sorunlu("D5 geçit olumsuz: alt kenar ekran dışı (y 700 > 648) HATA", vgal, "D5", "HATA", "G", "kayma_mesafe")
	var vgsag := _t([{"tur": "gecit", "id": "G", "konum": [1145, 400], "kayma_mesafe": 100}])
	_sorunlu("D5 geçit olumsuz: x sağda ekran dışı (1145+10 > 1152) HATA", vgsag, "D5", "HATA", "G", "kayma_mesafe")
	var vgsol := _t([{"tur": "gecit", "id": "G", "konum": [5, 400], "kayma_mesafe": 100}])
	_sorunlu("D5 geçit olumsuz: x solda ekran dışı (5-10 < 0) HATA", vgsol, "D5", "HATA", "G", "kayma_mesafe")

	# --- (b) toplu işte iptal
	var b1_yol := _kayit_yolu(temel, "a4ek")
	var dogru: Array = r.call("_dogru_kayit_betigi")
	var cozum: Array = r.call("_cozum_betigi")
	var vb: Dictionary = temel.duplicate(true)
	vb["cozum"] = {"turlar": [dogru], "oyuncu": cozum}
	var d := _dogrulayici()
	await r.process_frame
	await r.physics_frame
	var ilk := {"adim": 0, "toplam": 0}
	d.ilerleme.connect(func(a: int, t: int, _x: String) -> void:
		ilk["adim"] = a
		ilk["toplam"] = t)
	var kutu := {"s": null, "bitti": false}
	var calis := func() -> void:
		kutu["s"] = await BolumDenetci.dinamik(vb, d, b1_yol)
		kutu["bitti"] = true
	calis.call()
	for i in 60:
		await r.physics_frame
	var adim_iptal: int = ilk["adim"]
	d.iptal()
	var bekle := 0
	while not kutu["bitti"] and bekle < 900:
		await r.physics_frame
		bekle += 1
	var adim_son: int = ilk["adim"]
	for i in 90:
		await r.physics_frame
	var sonuc_i: Array = kutu["s"] if kutu["s"] != null else [1]
	_k4("Dinamik iptal: iptal() sürerken çağrılınca dinamik() [] döner",
		bool(kutu["bitti"]) and sonuc_i.is_empty(), "bitti=%s sonuç=%s bekleme=%d kare" % [kutu["bitti"], _ozet_metni(sonuc_i), bekle])
	_k4("Dinamik iptal: sonraki oynatmalar çalışmaz (ilerleme sayacı tam değil, iptal sonrası artmaz; %d/%d)" % [adim_son, ilk["toplam"]],
		int(ilk["toplam"]) > 0 and adim_son < int(ilk["toplam"]) and int(ilk["adim"]) == adim_son and kayitlar.turlar.size() == 0,
		"iptal anındaki adım=%d, bitişte=%d, sonra=%d, toplam=%d, Kayitlar.turlar=%d" % [adim_iptal, adim_son, ilk["adim"], ilk["toplam"], kayitlar.turlar.size()])

	# Aynı doğrulayıcıyla yeni dinamik(): bayrak toplu_basla ile sıfırlanır, tam koşar.
	ilk["adim"] = 0
	ilk["toplam"] = 0
	var s2: Array = await BolumDenetci.dinamik(vb, d, b1_yol)
	_k4("Dinamik iptal: iptalden sonra aynı doğrulayıcıyla yeni dinamik() normal çalışır (tüm adımlar, D9 yok)",
		int(ilk["toplam"]) > 0 and int(ilk["adim"]) == int(ilk["toplam"]) and _n(s2, "D9") == 0,
		"adım=%d/%d; sorunlar: %s" % [ilk["adim"], ilk["toplam"], _ozet_metni(s2)])

	# --- (c) 'mesgul': süren oynat sırasında ikinci oynat; bitti yalnız süren iş için bir kez
	var say := {"n": 0, "son": null}
	d.bitti.connect(func(x: Dictionary) -> void:
		say["n"] += 1
		say["son"] = x)
	var ilk_kutu := {"s": null}
	var ilk_oynat := func() -> void:
		ilk_kutu["s"] = await d.oynat(b1_yol, [dogru], cozum)
	ilk_oynat.call()
	for i in 20:
		await r.physics_frame
	var ikinci: Dictionary = await d.oynat(b1_yol, [dogru], cozum)
	var n_ikinci: int = say["n"]
	var ilk_bitmemis: bool = ilk_kutu["s"] == null
	bekle = 0
	while ilk_kutu["s"] == null and bekle < 1500:
		await r.physics_frame
		bekle += 1
	for i in 10:
		await r.physics_frame
	var fs: Dictionary = ilk_kutu["s"] if ilk_kutu["s"] != null else {}
	_k4("Mesgul: süren oynat sırasında ikinci oynat hata=mesgul döner, örnek yok, bitti sinyali yaymaz",
		ilk_bitmemis and str(ikinci.get("hata", "")) == "mesgul" and (ikinci["ornekler"] as Array).is_empty() and n_ikinci == 0,
		"ikinci hata=%s, ikinci dönüşte sinyal sayısı=%d, ilk süreniyordu=%s" % [ikinci.get("hata", "-"), n_ikinci, ilk_bitmemis])
	_k4("Mesgul: bitti sinyali yalnız süren iş için bir kez yayılır (hatasız, bitti=true)",
		int(say["n"]) == 1 and not fs.is_empty() and not fs.has("hata") and bool(fs.get("bitti", false)) and say["son"] == fs,
		"sinyal sayısı=%d, ilk sonuç bitti=%s hata=%s" % [say["n"], fs.get("bitti", "-"), fs.get("hata", "-")])

	_a3_bitir(d)
	kayitlar.call("sifirla")
	_dizin_sil(KOK)


func a4_testleri() -> void:
	var kayitlar: Node = r.root.get_node("Kayitlar")
	var temel := _fikstur("b1.json")["veri"] as Dictionary

	# --- D1-D3: statik() içinden çağrılır; şema HATA verirse yalnız şema döner
	var sema_ok := true
	var sema_ayr := ""
	for e in [["ihlal_baslangic_yok.json", "D1", "", "baslangic"], ["ihlal_yukseklik.json", "D2", "Asansor", "yukseklik"],
			["ihlal_asansore_salter.json", "D3", "Asansor", "plaka"]]:
		var v := _fikstur(e[0])["veri"] as Dictionary
		var s := _sd(v)
		var sema: Array = BolumVerisi.sema_denetle(v)
		var yalniz_sema := s.size() == sema.size()
		for o in s:
			yalniz_sema = yalniz_sema and (o["kod"] in ["D1", "D2", "D3"])
		var bu := yalniz_sema and _n(s, e[1], "HATA", e[2], e[3]) >= 1
		sema_ok = sema_ok and bu
		sema_ayr += "%s: %s %s; " % [e[0], bu, _ozet_metni(s)]
	_k4("D1-D3: statik() şema denetimini çağırır; şema HATA'sında yalnız D1-D3 döner", sema_ok, sema_ayr)

	# --- D4
	var tum := _tum_turler_verisi()
	var s4 := _sd(tum)
	_k4("D4 olumlu: her türlü nesne çizimli; statik() D4 üretmez", BolumVerisi.sema_denetle(tum).is_empty() and _n(s4, "D4") == 0, _ozet_metni(s4))
	var b1_sahne: Node = await _sahne_ac(temel)
	await r.process_frame
	await r.physics_frame
	var g1 := BolumDenetci.gorunurluk_tara(b1_sahne)
	_k4("D4 olumlu: kurulan B1 fikstür sahnesinde gorunurluk_tara çizimsiz bulmaz", int(g1["sayi"]) > 0 and (g1["cizimsiz"] as Array).is_empty() and (g1["sorun"] as Array).is_empty(),
		"sayi=%s cizimsiz=%s sorun=%s" % [g1["sayi"], g1["cizimsiz"], g1["sorun"]])
	var gizli := Node2D.new()
	var gb := StaticBody2D.new()
	gb.name = "Gizli"
	var gs := CollisionShape2D.new()
	gs.shape = RectangleShape2D.new()
	gb.add_child(gs)
	gizli.add_child(gb)
	var cb := StaticBody2D.new()
	cb.name = "Cizimli"
	var cs := CollisionShape2D.new()
	cs.shape = RectangleShape2D.new()
	cb.add_child(cs)
	var cg := ColorRect.new()
	cb.add_child(cg)
	gizli.add_child(cb)
	r.root.add_child(gizli)
	await r.process_frame
	var g2 := BolumDenetci.gorunurluk_tara(gizli)
	_k4("D4 olumsuz: çizimsiz çarpışma gövdesi 'cizimsiz' listesinde (çizimli olan değil)", int(g2["sayi"]) == 2 and (g2["cizimsiz"] as Array) == ["Gizli"],
		"sayi=%s cizimsiz=%s" % [g2["sayi"], g2["cizimsiz"]])
	gizli.queue_free()
	await r.process_frame

	# --- D5
	_temiz("D5 olumlu: ekran içindeki bölüm", temel, "D5")
	var plk := _pl("P", 100, 600)
	var vd := _t([plk, {"tur": "asansor", "id": "Asn", "konum": [400, 150], "yukseklik": 200, "plaka": "P"}])
	_sorunlu("D5 olumsuz: asansörün üst konumu ekran dışı (Asn/yukseklik)", vd, "D5", "HATA", "Asn", "yukseklik")
	var vc := _t([])
	vc["cikis"] = [1140, 594]
	_sorunlu("D5 olumsuz: çıkış ekran dışı (alan cikis)", vc, "D5", "HATA", "", "cikis")
	var vk := _t([plk, {"tur": "gecit", "id": "G", "konum": [900, 600], "tetikleyiciler": ["P"], "kablolar": [{"tetik": "P", "ara": [[1200, 500]]}]}])
	_sorunlu("D5 olumsuz: kablo noktası ekran dışı (G/kablolar)", vk, "D5", "HATA", "G", "kablolar")
	var vl := _t([{"tur": "lazer", "id": "L", "konum": [600, 500], "yon": "asagi", "uzunluk": 300}])
	_sorunlu("D5 olumsuz: lazer ucu ekran dışı (L/uzunluk)", vl, "D5", "HATA", "L", "uzunluk")

	# --- D6
	_temiz("D6 olumlu: zemin x 0..1152 örtüyor", _t([]), "D6")
	var v6 := _v([{"tur": "blok", "id": "Zemin", "alan": [0, 600, 1000, 40]}])
	_sorunlu("D6 olumsuz: zemin 1000'de bitiyor, alt sınır açık", v6, "D6", "HATA", "", "")

	# --- D7 (kurucu sırayı hep doğru kurar; olumsuz durum veriyle üretilemez, rapora bakınız)
	var s7 := _sd(tum)
	_k4("D7 olumlu: tüm türlerde tetikleyici/mekanizmalar Oyuncu'dan önce", BolumVerisi.sema_denetle(tum).is_empty() and _n(s7, "D7") == 0, _ozet_metni(s7))

	# --- D8
	_temiz("D8 olumlu: hiçbir şey gömülü değil", _t([_pl("P", 500, 600), {"tur": "kutu", "id": "K", "konum": [700, 600]}]), "D8")
	_sorunlu("D8 olumsuz: başlangıç blok içinde", _t([{"tur": "blok", "id": "Duv", "alan": [180, 540, 60, 60]}]), "D8", "HATA", "", "baslangic")
	_sorunlu("D8 olumsuz: çıkış blok içinde", _t([{"tur": "blok", "id": "Duv", "alan": [1020, 540, 60, 60]}]), "D8", "HATA", "", "cikis")
	_sorunlu("D8 olumsuz: kutu zemine gömülü (K/konum)", _t([{"tur": "kutu", "id": "K", "konum": [500, 620]}]), "D8", "HATA", "K", "konum")
	_sorunlu("D8 olumsuz: plaka zemine gömülü (P/konum)", _t([_pl("P", 500, 610)]), "D8", "HATA", "P", "konum")
	_sorunlu("D8 olumsuz: zıplatıcı zemine gömülü (Z/konum)", _t([{"tur": "ziplatici", "id": "Z", "konum": [500, 610]}]), "D8", "HATA", "Z", "konum")

	# --- D14 (taban Raf/tavan Tav başlangıçtan uzak: D8 çıkmaz)
	var raf := {"tur": "blok", "id": "Raf", "alan": [500, 400, 300, 20]}
	_temiz("D14 olumlu: 100 px koridor uyarı vermez", _t([raf, {"tur": "blok", "id": "Tav", "alan": [500, 280, 300, 20]}]), "D14")
	var s14 := _sorunlu("D14 olumsuz: 80 px koridor 'dar' UYARI (nesne Raf)", _t([raf, {"tur": "blok", "id": "Tav", "alan": [500, 300, 300, 20]}]), "D14", "UYARI", "Raf", "")
	var v40 := _t([raf, {"tur": "blok", "id": "Tav", "alan": [500, 340, 300, 20]}])
	var s40 := _sd(v40)
	var oz40 := BolumDenetci.ozet(s40)
	var m40 := ""
	for o in s40:
		if o["kod"] == "D14":
			m40 = o["mesaj"]
	_k4("D14: kasıtlı 40 px aralık yalnız UYARI verir (HATA yok, 'ayakta geçemez')",
		BolumVerisi.sema_denetle(v40).is_empty() and _n(s40, "D14", "UYARI", "Raf") == 1 and _n(s40, "D14", "HATA") == 0 and int(oz40["hata"]) == 0 and m40.contains("ayakta geçemez"),
		"özet=%s mesaj=%s sorunlar=%s" % [oz40, m40, _ozet_metni(s40)])

	# --- D15
	var gecit := {"tur": "gecit", "id": "G", "konum": [600, 600], "tetikleyiciler": ["P"]}
	_temiz("D15 olumlu: geçit tavan ve zemine oturuyor", _t([plk, gecit, {"tur": "blok", "id": "Tavan", "alan": [0, 0, 1152, 400]}]), "D15")
	_sorunlu("D15 olumsuz: geçit üstünde 20 px sızıntı (G/konum)", _t([plk, gecit, {"tur": "blok", "id": "Tavan", "alan": [0, 0, 1152, 380]}]), "D15", "UYARI", "G", "konum")

	# --- D16
	var lz := {"tur": "lazer", "id": "L", "konum": [600, 300], "yon": "asagi", "uzunluk": 300}
	_temiz("D16 olumlu: ışın yalnız zemine değer, bloktan geçmez", _t([lz]), "D16")
	_sorunlu("D16 olumsuz: ışın Engel bloğundan geçiyor (L/uzunluk)", _t([lz, {"tur": "blok", "id": "Engel", "alan": [550, 450, 100, 20]}]), "D16", "UYARI", "L", "uzunluk")

	# --- D17
	_temiz("D17 olumlu: alttaki yüzey 300 px aşağıda", _t([{"tur": "tek_yonlu", "id": "Raf", "konum": [600, 300]}, _pl("P", 600, 300)]), "D17")
	_sorunlu("D17 olumsuz: tek yönlü üstündeki plakaya alttan baş değer (P/konum)", _t([{"tur": "tek_yonlu", "id": "Raf", "konum": [600, 520]}, _pl("P", 600, 520)]), "D17", "UYARI", "P", "konum")

	# --- D18
	_temiz("D18 olumlu: tek yüzey, etiket yok", _t([]), "D18")
	var etiketler := [[520, 80, "zıplayarak aşılabilir"], [400, 200, "zıplatıcıyla aşılabilir"], [300, 300, "zıplatıcıyla da aşılamaz"]]
	var e_ok := true
	var e_ayr := ""
	for e in etiketler:
		var se := _sd(_t([{"tur": "tek_yonlu", "id": "Raf", "konum": [600, e[0]]}]))
		var m := ""
		for o in se:
			if o["kod"] == "D18" and o["nesne"] == "Raf":
				m = o["mesaj"] + ("|" + o["seviye"])
		var bu: bool = m.contains(e[2]) and m.ends_with("|BILGI") and m.contains("%d px" % e[1])
		e_ok = e_ok and bu
		e_ayr += "%d px: %s; " % [e[1], m]
	_k4("D18 olumsuz: yükseklik etiketi BİLGİ (80 zıplama, 200 zıplatıcı, 300 aşılamaz)", e_ok, e_ayr)

	# --- D19 statik
	_temiz("D19 olumlu: bantsız bölümde D19 yok", _t([]), "D19")
	var sb := _sd(_bant_verisi())
	_k4("D19a olumsuz: bant ile aynı yükseklikte bitişik blok (dikiş), UYARI nesne Bant",
		BolumVerisi.sema_denetle(_bant_verisi()).is_empty() and _n(sb, "D19", "UYARI", "Bant", "konum") >= 1, _ozet_metni(sb))
	_k4("D19b olumsuz: bant varsa genel not (nesne boş) UYARI", _n(sb, "D19", "UYARI", "", "") == 1, _ozet_metni(sb))
	var sd2 := _sd(_t([{"tur": "bant", "id": "Bant", "konum": [500, 600], "yon": 1}]))
	_k4("D19a olumlu: bant sürekli zemine gömülü (dikiş yok): yalnız genel not", _n(sd2, "D19", "UYARI", "Bant", "konum") == 0 and _n(sd2, "D19", "UYARI", "", "") == 1, _ozet_metni(sd2))

	# --- D20
	_temiz("D20 olumlu: B1'de plaka asansöre bağlı", temel, "D20")
	_sorunlu("D20 olumsuz: işlevsiz plaka (P)", _t([_pl("P", 500, 600)]), "D20", "UYARI", "P", "")
	_sorunlu("D20 olumsuz: tetikleyicisiz geçit (G/tetikleyiciler)", _t([{"tur": "gecit", "id": "G", "konum": [600, 600]}]), "D20", "UYARI", "G", "tetikleyiciler")

	# --- D23
	_temiz("D23 olumlu: ışın başlangıcın yanından geçer (x 230)", _t([{"tur": "lazer", "id": "L", "konum": [230, 300], "yon": "asagi", "uzunluk": 280}]), "D23")
	_sorunlu("D23 olumsuz: başlangıç ışının içinde (L/konum)", _t([{"tur": "lazer", "id": "L", "konum": [200, 300], "yon": "asagi", "uzunluk": 280}]), "D23", "HATA", "L", "konum")

	# --- D24 (başlangıç merkezi (200, 570); kutu merkezi (x, y-20))
	_sorunlu("D24 olumsuz: kutu merkezi 30 px uzakta (K/konum)", _t([{"tur": "kutu", "id": "K", "konum": [230, 590]}]), "D24", "HATA", "K", "konum")
	_temiz("D24 olumlu: kutu tam 40 px uzakta temiz", _t([{"tur": "kutu", "id": "K", "konum": [240, 590]}]), "D24")
	_temiz("D24 olumlu: kutu 60 px uzakta temiz", _t([{"tur": "kutu", "id": "K", "konum": [260, 590]}]), "D24")

	# --- D25 (asansör üst yüzeyi y = 400 - yukseklik; tavan alt kenarı 100)
	var tavan := {"tur": "blok", "id": "Tavan", "alan": [0, 0, 1152, 100]}
	var asn := func(h: int) -> Dictionary:
		return _t([tavan, plk, {"tur": "asansor", "id": "Asn", "konum": [400, 400], "yukseklik": h, "plaka": "P"}])
	_sorunlu("D25 olumsuz: tavan arası 41 px HATA (Asn/yukseklik)", asn.call(259), "D25", "HATA", "Asn", "yukseklik")
	var s45 := _sorunlu("D25 olumsuz: tavan arası 45 px UYARI (HATA değil)", asn.call(255), "D25", "UYARI", "Asn", "yukseklik")
	_temiz("D25 olumlu: tavan arası 60 px temiz", asn.call(240), "D25")
	var s42 := _sd(asn.call(258))
	var s49 := _sd(asn.call(251))
	var s50 := _sd(asn.call(250))
	var s_tavansiz := _sd(_t([plk, {"tur": "asansor", "id": "Asn", "konum": [400, 100], "yukseklik": 70, "plaka": "P"}]))
	_k4("D25 sınırlar: 42 ve 49 px UYARI, 50 px temiz, ekran tavanına 30 px HATA, 45 px'te HATA yok",
		_n(s42, "D25", "UYARI") == 1 and _n(s42, "D25", "HATA") == 0 and _n(s49, "D25", "UYARI") == 1 and _n(s49, "D25", "HATA") == 0
		and _n(s50, "D25") == 0 and _n(s_tavansiz, "D25", "HATA", "Asn") == 1 and _n(s45, "D25", "HATA") == 0,
		"42=%s 49=%s 50=%s tavansız=%s" % [_ozet_metni(s42), _ozet_metni(s49), _ozet_metni(s50), _ozet_metni(s_tavansiz)])

	# --- D26 (dikey ışın x 697..703; kablo dikey parçası plaka x'inde)
	var l26 := {"tur": "lazer", "id": "L", "konum": [700, 300], "yon": "asagi", "uzunluk": 250}
	var g26 := {"tur": "gecit", "id": "G", "konum": [900, 600], "tetikleyiciler": ["P"]}
	_sorunlu("D26 olumsuz: kablo ışına 4 px paralel (G/kablolar)", _t([_pl("P", 704, 600), g26, l26]), "D26", "UYARI", "G", "kablolar")
	_temiz("D26 olumlu: kablo ışından 40 px uzakta", _t([_pl("P", 740, 600), g26, l26]), "D26")
	var s708 := _sd(_t([_pl("P", 708, 600), g26, l26]))
	var s709 := _sd(_t([_pl("P", 709, 600), g26, l26]))
	_k4("D26 sınır: 8 px UYARI, 9 px temiz", _n(s708, "D26", "UYARI", "G") == 1 and _n(s709, "D26") == 0, "8=%s 9=%s" % [_ozet_metni(s708), _ozet_metni(s709)])

	# --- ozet()
	var oz := BolumDenetci.ozet([{"seviye": "HATA"}, {"seviye": "UYARI"}, {"seviye": "UYARI"}, {"seviye": "BILGI"}, {"seviye": "BILGI"}, {"seviye": "BILGI"}])
	_k4("ozet(): seviye sayıları {hata, uyari, bilgi}", oz == {"hata": 1, "uyari": 2, "bilgi": 3} and BolumDenetci.ozet([]) == {"hata": 0, "uyari": 0, "bilgi": 0}, str(oz))

	# --- Resmî fikstürler statik HATA vermez
	for ad in ["b1", "b5", "b10", "b14", "b21"]:
		var ov := _fikstur(ad + ".json")["veri"] as Dictionary
		var so := _sd(ov)
		var hata_metni: PackedStringArray = []
		for o in so:
			if o["seviye"] == "HATA":
				hata_metni.append("%s/%s/%s: %s" % [o["kod"], o["nesne"], o["alan"], o["mesaj"]])
		_k4("%s resmî fikstürü statik denetimde HATA vermez" % ad.to_upper(), not ov.is_empty() and hata_metni.is_empty(),
			"HATA: %s; özet=%s" % [", ".join(hata_metni), BolumDenetci.ozet(so)])

	# --- Dinamik denetimler (CozumDogrulayici ağaçta; D9-D13, D19c, D21)
	var dogru: Array = r.call("_dogru_kayit_betigi")
	var cozum: Array = r.call("_cozum_betigi")
	var b1_yol := _kayit_yolu(temel, "a4olc")
	var d0 := _dogrulayici()
	await r.process_frame
	await r.physics_frame
	var ol: Dictionary = await d0.oynat(b1_yol, [dogru], cozum)
	_a3_bitir(d0)
	var bk := int(ol["bitis_kare"])
	var va: Dictionary = temel.duplicate(true)
	va["cozum"] = {"turlar": [dogru], "oyuncu": cozum}
	va["dogrulama"] = {"durum": "dogrulandi", "icerik_ozeti": BolumVerisi.icerik_ozeti(va), "bitis_kare": bk, "hata": 0, "uyari": 0}
	var sa: Array = await _din(va, "a4a")
	var ma := "bitis_kare=%d; sorunlar=%s" % [bk, _ozet_metni(sa)]
	_k4("D9 olumlu: B1 doğru çözümü bölümü bitirir (D9 yok)", bk > 0 and _n(sa, "D9") == 0, ma)
	_k4("D10 olumlu: 3 koşu özdeş ve kayıtlı bitiş karesi ölçülenle aynı (D10 yok)", bk > 0 and _n(sa, "D10") == 0, ma)
	_k4("D11 olumlu: 1 klon <= max_klon 2 (D11 yok)", _n(sa, "D11") == 0, ma)
	_k4("D12 olumlu: B1'de klonsuz son tur ve saf betikler bölümü bitirmez (D12 yok)", _n(sa, "D12") == 0, ma)
	_k4("D13 olumlu: tek klonlu çözümde D13 yok", _n(sa, "D13") == 0, ma)
	_k4("D19c olumlu: bantsız çözümde dinamik D19 yok", _n(sa, "D19") == 0, ma)
	_k4("D21 olumlu: turlar 600 kareyi aşmaz (D21 yok)", _n(sa, "D21") == 0 and cozum.size() <= 600, ma)

	var vb: Dictionary = va.duplicate(true)
	vb["dogrulama"]["bitis_kare"] = bk + 7
	var sbk: Array = await _din(vb, "a4b")
	_k4("D10 olumsuz: kayıtlı bitiş karesi ölçülenden farklı (alan dogrulama)", _n(sbk, "D10", "HATA", "", "dogrulama") == 1 and _n(sbk, "D9") == 0,
		"kayıtlı=%d ölçülen=%d; %s" % [bk + 7, bk, _ozet_metni(sbk)])

	var ve: Dictionary = temel.duplicate(true)
	ve["cozum"] = {"turlar": [r.call("_erken_kayit_betigi")], "oyuncu": cozum}
	var se: Array = await _din(ve, "a4e")
	_k4("D9 olumsuz: yanlış zamanlı klon, bölüm bitmez (D9 HATA, alan cozum)", _n(se, "D9", "HATA", "", "cozum") == 1 and _n(se, "D10") == 0 and _n(se, "D12") == 0, _ozet_metni(se))
	var vy: Dictionary = temel.duplicate(true)
	vy["cozum"] = {"turlar": [dogru], "oyuncu": []}
	var sy: Array = await _din(vy, "a4y")
	_k4("D9 olumsuz: son tur kaydı boş, çözüm yok (D9 HATA)", _n(sy, "D9", "HATA", "", "cozum") == 1 and sy.size() == 1, _ozet_metni(sy))

	var v3: Dictionary = temel.duplicate(true)
	v3["cozum"] = {"turlar": [dogru, dogru, dogru], "oyuncu": cozum}
	var s3: Array = await _din(v3, "a4c")
	_k4("D11 olumsuz: 3 klon, max_klon 2 (D11 HATA, oynatma yok)", _n(s3, "D11", "HATA", "", "cozum") == 1 and s3.size() == 1, _ozet_metni(s3))

	# Klonsuz kısayol: düz zeminde sağa yürümek bölümü klonsuz bitirir
	var vyu: Dictionary = _t([], "Yuru")
	vyu["cozum"] = {"turlar": [r.call("_betik", [[10, 0, false]])], "oyuncu": _yuru_betik(500)}
	var syu: Array = await _din(vyu, "a4yu")
	_k4("D12 olumsuz: klonsuz kısayol (son tur klonsuz bitiriyor) D12 HATA; tek klon olduğundan D13 yok",
		_n(syu, "D12", "HATA", "", "cozum") >= 1 and _n(syu, "D9") == 0 and _n(syu, "D13") == 0, _ozet_metni(syu))
	var syu_son: bool = false
	for o in syu:
		if o["kod"] == "D12" and (o["mesaj"] as String).contains("son tur kaydı"):
			syu_son = true
	_k4("D12 olumsuz: kısayol iletisi 'son tur kaydı' (klonsuz son tur denemesi) üretir", syu_son, _ozet_metni(syu))

	# Gereksiz klon: 2 boş klon, düz zemin; bir klon eksik de bitiyor (>= 2 tur gerekir)
	var vg: Dictionary = _t([], "Gereksiz")
	var bos10: Array = r.call("_betik", [[10, 0, false]])
	vg["cozum"] = {"turlar": [bos10, bos10.duplicate(true)], "oyuncu": _yuru_betik(500)}
	var sg: Array = await _din(vg, "a4g")
	_k4("D13 olumsuz: 2 turlu gereksiz klonlu fikstür D13 UYARI (1. klon çıkarılınca bitiyor)", _n(sg, "D13", "UYARI", "", "cozum") == 1, _ozet_metni(sg))
	# B1: gerekli klon + fazladan boş klon; D12 çıkmaz, yalnız D13
	var vg2: Dictionary = temel.duplicate(true)
	vg2["cozum"] = {"turlar": [dogru, bos10], "oyuncu": cozum}
	var sg2: Array = await _din(vg2, "a4g2")
	_k4("D13 olumsuz: B1'de gerekli + gereksiz klon: D13 UYARI '2. klon', D12/D9 yok", _n(sg2, "D13", "UYARI", "", "cozum") == 1 and _n(sg2, "D12") == 0 and _n(sg2, "D9") == 0
		and (sg2.filter(func(o): return o["kod"] == "D13")[0]["mesaj"] as String).begins_with("2."), _ozet_metni(sg2))

	# D19c: bant üstünde 20 kare duran çözüm / durmayan çözüm
	var vbd: Dictionary = _bant_verisi()
	vbd["cozum"] = {"turlar": [], "oyuncu": _yuru_betik(500)}
	var sbd: Array = await _din(vbd, "a4bd")
	_k4("D19c olumlu: bant üstünde durmadan yürüyen çözümde dinamik D19 (alan cozum) yok", _n(sbd, "D19", "UYARI", "Bant", "cozum") == 0 and _n(sbd, "D9") == 0, _ozet_metni(sbd))
	var vbt: Dictionary = _bant_verisi()
	vbt["cozum"] = {"turlar": [], "oyuncu": r.call("_betik", [[20, 0, false], [500, 1, false]])}
	var sbt: Array = await _din(vbt, "a4bt")
	_k4("D19c olumsuz: bant üstünde 20 kare duran çözüm D19 UYARI (Bant, alan cozum)", _n(sbt, "D19", "UYARI", "Bant", "cozum") == 1 and _n(sbt, "D9") == 0, _ozet_metni(sbt))

	# D21: 650 karelik son tur
	var vu: Dictionary = _t([], "Uzun")
	vu["cozum"] = {"turlar": [], "oyuncu": _yuru_betik(400, 250)}
	var su: Array = await _din(vu, "a4u")
	_k4("D21 olumsuz: 650 karelik son tur D21 UYARI", _n(su, "D21", "UYARI", "", "cozum") == 1, _ozet_metni(su))

	# --- Eşdeğerlik: gorunurluk_tara == _gr_bolum_tara (21 resmî bölüm)
	var bolumler: Array = BolumListesi.BOLUMLER
	var farklar: PackedStringArray = []
	var toplam := 0
	r.paused = false
	for i in bolumler.size():
		var yol: String = bolumler[i]["yol"]
		var ref: Dictionary = await r.call("_gr_bolum_tara", yol, i + 1)
		kayitlar.call("sifirla")
		var sahne: Node = (load(yol) as PackedScene).instantiate()
		r.root.add_child(sahne)
		await r.process_frame
		await r.physics_frame
		var bu := BolumDenetci.gorunurluk_tara(sahne)
		sahne.queue_free()
		await r.process_frame
		var onek := "B%d/" % (i + 1)
		var ref_c: Array = (ref["cizimsiz"] as Array).map(func(x): return (x as String).trim_prefix(onek))
		var ref_s: Array = (ref["sorun"] as Array).map(func(x): return (x as String).trim_prefix(onek))
		toplam += int(bu["sayi"])
		if int(ref["sayi"]) != int(bu["sayi"]) or ref_c != bu["cizimsiz"] or ref_s != bu["sorun"]:
			farklar.append("B%d: ref(%s,%s,%s) bu(%s,%s,%s)" % [i + 1, ref["sayi"], ref_c, ref_s, bu["sayi"], bu["cizimsiz"], bu["sorun"]])
	_k4("Eşdeğerlik: gorunurluk_tara, %d resmî bölümde _gr_bolum_tara ile aynı sonuç (sayı, çizimsiz, sorun)" % bolumler.size(),
		bolumler.size() == 21 and farklar.is_empty() and toplam > 0, "bölüm=%d toplam şekil=%d farklar=%s" % [bolumler.size(), toplam, ", ".join(farklar)])

	# --- Temizlik
	kayitlar.call("sifirla")
	r.paused = false
	_dizin_sil(KOK)
	var td := DirAccess.open(KOK)
	_k4("user://test_editor/ test sonunda boş (silindi)", td == null or (td.get_files().is_empty() and td.get_directories().is_empty()),
		"dizin var=%s" % DirAccess.dir_exists_absolute(KOK))


# ---------------------------------------------------------------- A5

const EDITOR_SAHNESI := "res://scenes/editor.tscn"


func _k5(ad: String, ok: bool, ayr: String) -> void:
	_kaydi("Editör A5: " + ad, ok, ayr)


## Editör sahnesini yükler, dosya kökünü test dizinine çevirir ve boş bölümle yeniden başlatır.
func _ed() -> Node:
	var e: Node = await r.call("_ar_sahne_yukle", EDITOR_SAHNESI)
	await r.process_frame
	e.set("kok", KOK)
	e.call("yeni")
	return e


func a5_testleri() -> void:
	r.paused = false
	_dizin_sil(KOK)
	var e: Node = await _ed()

	# --- boş başlangıç
	var d6: Dictionary = BolumDenetci.ozet(BolumDenetci.statik(e.veri))
	_k5("sahne boş bölümle başlar (nesne yok, önizleme boş, durum satırında D6 HATA bilgisi)",
		e.veri["nesneler"].is_empty() and e.onizleme.get_child_count() == 0 and int(d6["hata"]) >= 1
		and e.durum_etiketi.text.contains("Nesne: 0") and e.durum_etiketi.text.contains("HATA"),
		"durum: %s" % e.durum_etiketi.text)

	# --- blok_ekle
	var i1: String = e.blok_ekle([100, 100, 200, 40])
	var i2: String = e.blok_ekle([400, 300, 80, 20])
	var i3: String = e.blok_ekle([600.4, 200.6, 50, 50])
	var sira_ok: bool = [i1, i2, i3] == ["Blok1", "Blok2", "Blok3"] and e.veri["nesneler"].size() == 3
	var json_ok: bool = e.veri["nesneler"][0] == {"tur": "blok", "id": "Blok1", "alan": [100, 100, 200, 40]} \
		and e.veri["nesneler"][2]["alan"] == [600, 201, 50, 50]
	_k5("blok_ekle: kimlikler sıralı (Blok1..3), JSON tur/id/alan doğru ve tamsayıya yuvarlanır",
		sira_ok and json_ok, "ids=%s %s" % [[i1, i2, i3], JSON.stringify(e.veri["nesneler"])])
	e.nesne_sil("Blok2")
	var i4: String = e.blok_ekle([10, 10, 30, 30])
	var benzersiz := {}
	for n in e.veri["nesneler"]:
		benzersiz[n["id"]] = true
	_k5("blok_ekle: silinen sonrası kimlik çakışmaz (benzersiz)", benzersiz.size() == e.veri["nesneler"].size() and i4 == "Blok2",
		"yeni=%s" % i4)
	var i5: String = e.blok_ekle([10, 10, 3, 4])
	_k5("blok_ekle: gen/yuk 10'dan küçükse 10'a yükselir", e._nesne(i5)["alan"] == [10, 10, 10, 10], JSON.stringify(e._nesne(i5)))
	var yanlis: String = e.blok_ekle([1, 2, 3])
	_k5("blok_ekle: eksik alan dizisi reddedilir ('')", yanlis == "", "dönen=%s" % yanlis)

	# --- başlangıç / çıkış / taşıma
	e.baslangic_koy(Vector2(300.4, 500.6))
	e.cikis_koy(Vector2(900, 400))
	_k5("başlangıç/çıkış koyma: JSON'da tamsayı konum", e.veri["baslangic"] == [300, 501] and e.veri["cikis"] == [900, 400],
		"%s %s" % [e.veri["baslangic"], e.veri["cikis"]])
	e.nesne_tasi("@baslangic", Vector2(20, -10))
	e.nesne_tasi("@cikis", Vector2(-100, 0))
	_k5("nesne_tasi: başlangıç ve çıkış işaretleri kayar", e.veri["baslangic"] == [320, 491] and e.veri["cikis"] == [800, 400],
		"%s %s" % [e.veri["baslangic"], e.veri["cikis"]])
	e.nesne_tasi("Blok1", Vector2(40, 20))
	_k5("nesne_tasi: blokta yalnız konum kayar, boyut aynı kalır", e._nesne("Blok1")["alan"] == [140, 120, 200, 40],
		JSON.stringify(e._nesne("Blok1")))
	var gorunumlu := true
	for id in ["Blok1", "Blok3"]:
		var dn: Node = e.onizleme_dugumu(id)
		gorunumlu = gorunumlu and dn != null and dn.get_node_or_null("Gorunum") != null
	_k5("önizleme: düğümler var ve her blokta Gorunum çizimi bulunur", gorunumlu, "")
	var kapali := true
	for dn in e.dugumler.values():
		kapali = kapali and (dn as Node).process_mode == Node.PROCESS_MODE_DISABLED
	_k5("önizleme düğümleri PROCESS_MODE_DISABLED", kapali and e.dugumler.size() == e.veri["nesneler"].size(),
		"düğüm=%d nesne=%d" % [e.dugumler.size(), e.veri["nesneler"].size()])

	# --- boyutlama ve önizleme yeniden kurma
	var eski: Node = e.onizleme_dugumu("Blok1")
	var eski_id := eski.get_instance_id()
	e.blok_boyutla("Blok1", [140, 120, 300, 80])
	var yeni_d: Node = e.onizleme_dugumu("Blok1")
	var gorsel := yeni_d.get_node_or_null("Gorsel") as ColorRect
	var boyut_ok: bool = gorsel != null and gorsel.size == Vector2(300, 80)
	_k5("blok_boyutla: JSON güncellenir; önizleme düğümü yeni örnekle yeniden kurulur, yeni boyut yansır",
		e._nesne("Blok1")["alan"] == [140, 120, 300, 80] and yeni_d.get_instance_id() != eski_id
		and e.onizleme.get_child_count() == e.veri["nesneler"].size() and boyut_ok,
		"eski=%d yeni=%d gorsel=%s" % [eski_id, yeni_d.get_instance_id(), gorsel.size if gorsel != null else "yok"])
	e.blok_boyutla("Blok1", [140, 120, 4, 2])
	_k5("blok_boyutla: en küçük boyut 10 uygulanır", e._nesne("Blok1")["alan"] == [140, 120, 10, 10], JSON.stringify(e._nesne("Blok1")))

	# --- silme
	var onceki: int = e.veri["nesneler"].size()
	e.sec("Blok3")
	e.nesne_sil("Blok3")
	_k5("nesne_sil: JSON'dan ve önizlemeden kalkar, seçim temizlenir",
		e._nesne("Blok3").is_empty() and e.onizleme_dugumu("Blok3") == null and e.veri["nesneler"].size() == onceki - 1 and e.secili == "",
		"nesne=%d" % e.veri["nesneler"].size())

	# --- ızgara
	var ok_ap: bool = e.izgara_adimi(false) == 20 and e.izgara_adimi(true) == 10
	var ok_m: bool = e.miknatis(Vector2(33, 47), false) == Vector2(40, 40) and e.miknatis(Vector2(33, 47), true) == Vector2(30, 50)
	var ok_kenar: bool = e.miknatis(Vector2(1143, 100), false) == Vector2(1152, 100) and e.miknatis(Vector2(500, 641), false) == Vector2(500, 648) \
		and e.miknatis(Vector2(3, 5), false) == Vector2(0, 0)
	_k5("ızgara açık: adım 20, Shift 10; ekran kenarı mıknatısı çeker", ok_ap and ok_m and ok_kenar,
		"%s %s %s" % [ok_ap, ok_m, ok_kenar])
	e.izgara_ac_kapa(false)
	var kapali_ok: bool = e.izgara_adimi(false) == 1 and e.izgara_adimi(true) == 1 and not e.izgara_acik \
		and e.miknatis(Vector2(33.4, 47.6), false) == Vector2(33, 48) and e.miknatis(Vector2(1143, 641), false) == Vector2(1143, 641)
	_k5("ızgara kapatılabilir: adım 1 px, mıknatıs yok (kenara da çekmez)", kapali_ok, "")
	e.izgara_ac_kapa(true)

	# --- geri al / yinele zinciri
	e.yeni()
	e.blok_ekle([0, 0, 50, 50])
	e.blok_ekle([100, 0, 50, 50])
	e.blok_ekle([200, 0, 50, 50])
	e.geri_al()
	e.geri_al()
	var iki_geri: bool = e.veri["nesneler"].size() == 1 and e.onizleme.get_child_count() == 1
	e.geri_al()
	e.geri_al()   # başta: etkisiz
	var basta: bool = e.veri["nesneler"].is_empty() and e.onizleme.get_child_count() == 0
	e.yinele()
	e.yinele()
	var yinele_ok: bool = e.veri["nesneler"].size() == 2 and e.onizleme.get_child_count() == 2
	_k5("geri al zinciri: çok adım geri, başta etkisiz, yinele ile ileri (önizleme eşlenir)", iki_geri and basta and yinele_ok,
		"%s %s %s" % [iki_geri, basta, yinele_ok])
	e.blok_ekle([300, 0, 50, 50])
	var son_i: int = e.gecmis_i
	e.yinele()
	_k5("yeni eylem yineleme yığınını siler", e.gecmis_i == son_i and e.gecmis_i == e.gecmis.size() - 1 and e.veri["nesneler"].size() == 3
		and e.veri["nesneler"][2]["alan"][0] == 300, "gecmis_i=%d boy=%d" % [e.gecmis_i, e.gecmis.size()])
	e.nesne_tasi("Blok1", Vector2(7, 9))
	e.geri_al()
	_k5("geri al taşımayı da geri alır", e._nesne("Blok1")["alan"] == [0, 0, 50, 50], JSON.stringify(e._nesne("Blok1")))

	# --- 100 sınırı ve 200 nesne sınırı
	e.yeni()
	for k in 105:
		e.blok_ekle([k, 0, 10, 10])
	for k in 150:
		e.geri_al()
	_k5("geri al en çok 100 adım: 105 eylemden sonra 150 geri al → 5 nesne kalır, geçmiş 101 kayıt",
		e.veri["nesneler"].size() == 5 and e.gecmis.size() == 101, "nesne=%d geçmiş=%d" % [e.veri["nesneler"].size(), e.gecmis.size()])
	e.yeni()
	for k in 200:
		e.blok_ekle([k, 0, 10, 10])
	var fazla: String = e.blok_ekle([0, 0, 10, 10])
	_k5("200 nesne sınırı: 201. blok reddedilir", e.veri["nesneler"].size() == 200 and fazla == "", "boy=%d dönen='%s'" % [e.veri["nesneler"].size(), fazla])

	# --- kimlik
	e.yeni()
	var k0: String = e.veri["kimlik"]
	e.ad_ata("Deneme Bir")
	var k1: String = e.veri["kimlik"]
	e.ad_ata("Deneme Iki")
	var k2: String = e.veri["kimlik"]
	var degisiyor: bool = k1 != k0 and k2 != k1 and k1.begins_with("deneme_bir") and k2.begins_with("deneme_iki")
	var h: int = e.kaydet()
	var kilitli: String = e.veri["kimlik"]
	e.ad_ata("Tamamen Baska")
	e.blok_ekle([10, 10, 50, 50])
	e.geri_al()
	_k5("kimlik ilk Kaydet'e kadar ad ile değişir, sonra sabit kalır (ad_ata ve geri al dahil)",
		degisiyor and h == OK and e.veri["kimlik"] == kilitli and kilitli == k2 and e.veri["ad"] == "Tamamen Baska",
		"%s -> %s -> %s; kayıt sonrası %s" % [k0, k1, k2, e.veri["kimlik"]])

	# --- Kaydet -> Aç
	e.yeni()
	e.ad_ata("Kayit Acma")
	e.blok_ekle([0, 600, 1152, 48])
	e.blok_ekle([300, 400, 200, 20])
	e.baslangic_koy(Vector2(100, 600))
	e.cikis_koy(Vector2(1000, 600))
	e.klon_ata(3)
	var once: String = BolumVerisi.kanonik_metin(e.veri)
	var kh: int = e.kaydet()
	var yol: String = e.son_yol
	e.yeni()
	var sorunlar: Array = e.ac(yol)
	var sonra: String = BolumVerisi.kanonik_metin(e.veri)
	_k5("Kaydet → Aç: kanonik veri eşit, önizleme yeniden kurulur, kimlik kilitli",
		kh == OK and FileAccess.file_exists(yol) and once == sonra and e.dugumler.size() == 2 and e.kimlik_kilitli and sorunlar.is_empty(),
		"kaydet=%d yol=%s sorun=%s" % [kh, yol, _ozet_metni(sorunlar)])

	# --- ac() geçersiz dosya
	_metin_yaz(KOK + "bozuk.json", "{ bu json degil")
	var oncesi: String = BolumVerisi.kanonik_metin(e.veri)
	var bs: Array = e.ac(KOK + "bozuk.json")
	var yok_s: Array = e.ac(KOK + "yok_dosya.json")
	_k5("ac(): geçersiz/olmayan dosyada bölüm değişmez, sorun döner",
		BolumVerisi.kanonik_metin(e.veri) == oncesi and bs.size() > 0 and yok_s.size() > 0 and e.dugumler.size() == 2,
		"bozuk sorun=%d yok sorun=%d" % [bs.size(), yok_s.size()])

	# --- fare yolu
	e.yeni()
	e.arac_sec("blok")
	e._fare_bas(Vector2(100, 100), false)
	e._fare_hareket(Vector2(200, 160), false)
	e._fare_birak(Vector2(200, 160), false)
	var fare_blok: bool = e.veri["nesneler"].size() == 1 and e._nesne("Blok1")["alan"] == [100, 100, 100, 60] and e.secili == "Blok1"
	_k5("fare: blok aracıyla bas-hareket-bırak blok üretir (ızgaraya oturur)", fare_blok, JSON.stringify(e.veri["nesneler"]))
	e.arac_sec("sec")
	e._fare_bas(Vector2(150, 130), false)
	e._fare_hareket(Vector2(190, 130), false)
	e._fare_birak(Vector2(190, 130), false)
	var tasindi: bool = e._nesne("Blok1")["alan"] == [140, 100, 100, 60]
	e.geri_al()
	var geri_ok: bool = e._nesne("Blok1")["alan"] == [100, 100, 100, 60]
	e.yinele()
	_k5("fare: seç aracıyla sürükleme bloğu taşır (tek geri al kaydı)", tasindi and geri_ok, JSON.stringify(e.veri["nesneler"]))
	# tutamaç 4 = sağ alt köşe (240,160)
	e._fare_bas(Vector2(240, 160), false)
	var boyut_basladi: bool = e.surukle == "boyut"
	e._fare_hareket(Vector2(300, 220), false)
	e._fare_birak(Vector2(300, 220), false)
	_k5("fare: tutamaçla sürükleme boyutlandırır, önizleme yeniden kurulur",
		boyut_basladi and e._nesne("Blok1")["alan"] == [140, 100, 160, 120] and (e.onizleme_dugumu("Blok1").get_node("Gorsel") as ColorRect).size == Vector2(160, 120),
		JSON.stringify(e.veri["nesneler"]))
	e._sag_tik(Vector2(200, 150))
	_k5("fare: sağ tık bloğu siler", e.veri["nesneler"].is_empty() and e.dugumler.is_empty(), "nesne=%d" % e.veri["nesneler"].size())
	e.arac_sec("blok")
	e._fare_bas(Vector2(100, 100), false)
	e._fare_hareket(Vector2(103, 101), false)
	e._fare_birak(Vector2(103, 101), false)
	e.izgara_ac_kapa(false)
	e._fare_bas(Vector2(100, 100), false)
	e._fare_hareket(Vector2(102, 102), false)
	e._fare_birak(Vector2(102, 102), false)
	_k5("fare: 4 px'ten kısa sürükleme blok üretmez (ızgaralı ve ızgarasız)", e.veri["nesneler"].is_empty(), "nesne=%d" % e.veri["nesneler"].size())
	e.izgara_ac_kapa(true)
	e.arac_sec("baslangic")
	e._fare_bas(Vector2(333, 411), false)
	e.arac_sec("cikis")
	e._fare_bas(Vector2(901, 500), true)
	_k5("fare: başlangıç/çıkış araçları tıklamayla konum koyar (ızgara/Shift)", e.veri["baslangic"] == [340, 420] and e.veri["cikis"] == [900, 500],
		"%s %s" % [e.veri["baslangic"], e.veri["cikis"]])

	# --- klavye kısayolları (gerçek olay)
	e.yeni()
	e.arac_sec("sec")
	var gid: String = e.blok_ekle([100, 100, 50, 50])
	e.sec(gid)
	var ok_olay := InputEventKey.new()
	ok_olay.keycode = KEY_RIGHT
	ok_olay.pressed = true
	e._unhandled_key_input(ok_olay)
	var z_olay := InputEventKey.new()
	z_olay.keycode = KEY_Z
	z_olay.ctrl_pressed = true
	z_olay.pressed = true
	var sag_ok: bool = e._nesne(gid)["alan"][0] == 120
	e._unhandled_key_input(z_olay)
	_k5("klavye: ok tuşu ızgara adımı kadar taşır, Ctrl+Z geri alır", sag_ok and e._nesne(gid)["alan"][0] == 100, JSON.stringify(e._nesne(gid)))

	# --- ana menü
	var kaynak := FileAccess.get_file_as_string("res://scripts/ana_menu.gd")
	var yasak: Array = []
	for t in ["BolumKurucu", "BolumVerisi", "BolumDenetci", "preload(", "scripts/editor"]:
		if kaynak.contains(t):
			yasak.append(t)
	_k5("ana_menu.gd kaynağı editör/kurucu sınıflarına başvurmaz (yalnız sahne yolu; preload kayması riski)", yasak.is_empty(), "bulunan: %s" % str(yasak))
	r.call("_kayitlar").sifirla()
	var m: Node = await r.call("_ar_sahne_yukle", "res://scenes/ana_menu.tscn")
	await r.physics_frame
	var dg: Dictionary = {}
	for ad in ["OynaDugmesi", "EditorDugmesi", "KontrollerDugmesi", "CikDugmesi"]:
		dg[ad] = m.find_child(ad, true, false)
	var dort := true
	for ad in dg:
		dort = dort and dg[ad] is Button
	_k5("ana menü 4 düğmeyle: Oyna, Editör, Kontroller, Çıkış var (mevcut 3 korunur)", dort and dg["EditorDugmesi"].text.length() > 0,
		"düğmeler: %s" % str(dg.keys()))
	if dort:
		var mid := m.get_instance_id()
		await r.call("_ar_tikla", dg["EditorDugmesi"])
		var ed: Node = await r.call("_yeni_sahne_bekle", mid)
		var tikla: bool = ed != null and ed.scene_file_path.ends_with("editor.tscn")
		if not tikla:
			dg["EditorDugmesi"].pressed.emit()
			ed = await r.call("_yeni_sahne_bekle", mid)
		_k5("ana menü: Editör düğmesi basılınca current_scene editor.tscn olur (gerçek tıklama: %s)" % ("evet" if tikla else "hayır, sinyalle"),
			ed != null and ed.scene_file_path.ends_with("editor.tscn") and r.current_scene == ed, "sahne: %s" % (ed.scene_file_path if ed != null else "yok"))

	r.paused = false
	_dizin_sil(KOK)
	var td := DirAccess.open(KOK)
	_k5("user://test_editor/ test sonunda silindi", td == null, "dizin var=%s" % DirAccess.dir_exists_absolute(KOK))


## Gözden geçirici sonrası A5 eklemeleri: şema hatalı dosya reddi, Tab/H, alt çubuk tıklama geçirgenliği, Enter'sız kaydet.
func a5_ek_testleri() -> void:
	r.paused = false
	_dizin_sil(KOK)
	var e: Node = await _ed()
	var vp: Viewport = e.get_viewport()

	# --- (1) şema HATA'lı ama ayrıştırılabilen dosyalar reddedilir
	e.ad_ata("Sabit Bolum")
	e.blok_ekle([100, 300, 200, 20])
	e.kaydet()
	var kimlik0: String = e.veri["kimlik"]
	var temel: Dictionary = BolumVerisi.bos("Dis Dosya", "dis_001")
	var vakalar := {}
	var v: Dictionary = temel.duplicate(true); v.erase("nesneler"); vakalar["nesneler_yok"] = v
	v = temel.duplicate(true); v.erase("ad"); vakalar["ad_yok"] = v
	v = temel.duplicate(true); v.erase("kimlik"); vakalar["kimlik_yok"] = v
	v = temel.duplicate(true); v.erase("baslangic"); vakalar["baslangic_yok"] = v
	v = temel.duplicate(true); v["nesneler"] = [5]; vakalar["nesne_sayi"] = v
	v = temel.duplicate(true); v["nesneler"] = [{"tur": "blok", "alan": [0, 0, 50, 50]}]; vakalar["id_yok"] = v
	v = temel.duplicate(true); v["nesneler"] = [{"tur": "ucan_halı", "id": "X", "konum": [10, 10]}]; vakalar["bilinmeyen_tur"] = v
	var hepsi_ok := true
	var ayr: PackedStringArray = []
	var onc: String = BolumVerisi.kanonik_metin(e.veri)
	var onc_dugum: int = e.dugumler.size()
	for ad in vakalar:
		var yol: String = KOK + "sema_%s.json" % ad
		_metin_yaz(yol, JSON.stringify(vakalar[ad]))
		var s: Array = e.ac(yol)
		var hata_var := false
		for o in s:
			hata_var = hata_var or str(o.get("seviye", "")) == "HATA"
		var ok: bool = hata_var and BolumVerisi.kanonik_metin(e.veri) == onc and e.dugumler.size() == onc_dugum \
			and e.veri["kimlik"] == kimlik0 and e.kilit_kimlik == kimlik0 and e.kimlik_kilitli
		hepsi_ok = hepsi_ok and ok
		ayr.append("%s=%s(%d sorun)" % [ad, ok, s.size()])
	_k5("ac(): şema HATA'lı dosyalar reddedilir (veri, önizleme, kimlik kilidi değişmez, sorunlar döner)", hepsi_ok, ", ".join(ayr))
	var yeni_id: String = e.blok_ekle([400, 300, 50, 20])
	e.geri_al()
	_k5("ac() reddinden sonra düzenleme ve geri al hatasız çalışır", yeni_id != "" and e.veri["nesneler"].size() == 1 and e.dugumler.size() == 1,
		"id=%s nesne=%d" % [yeni_id, e.veri["nesneler"].size()])

	# --- (2) Tab: gerçek olay, palet gizlenir, odak AdAlani'na geçmez, kısayollar nesneye gider
	e.yeni()
	e.arac_sec("sec")
	var gid: String = e.blok_ekle([100, 100, 50, 50])
	e.sec(gid)
	await r.process_frame
	var tab := InputEventKey.new()
	tab.keycode = KEY_TAB
	tab.pressed = true
	var gorunur0: bool = e.palet.visible
	vp.push_input(tab)
	await r.process_frame
	var gizlendi: bool = not e.palet.visible
	var odak: Control = vp.gui_get_focus_owner()
	var odak_ad_degil: bool = odak != e.ad_alani and not e.ad_alani.has_focus()
	var tab_yukari := InputEventKey.new()
	tab_yukari.keycode = KEY_TAB
	tab_yukari.pressed = false
	vp.push_input(tab_yukari)
	vp.push_input(tab)
	await r.process_frame
	_k5("Tab: palet gizlenir/gösterilir, odak AdAlani'na geçmez", gorunur0 and gizlendi and odak_ad_degil and e.palet.visible,
		"önce=%s sonra gizli=%s tekrar görünür=%s odak=%s" % [gorunur0, gizlendi, e.palet.visible, odak])
	var sag := InputEventKey.new()
	sag.keycode = KEY_RIGHT
	sag.pressed = true
	vp.push_input(sag)
	await r.process_frame
	var tasi_ok: bool = e._nesne(gid)["alan"][0] == 120
	var ctrlz := InputEventKey.new()
	ctrlz.keycode = KEY_Z
	ctrlz.ctrl_pressed = true
	ctrlz.pressed = true
	vp.push_input(ctrlz)
	await r.process_frame
	var geri_ok: bool = e._nesne(gid)["alan"][0] == 100
	var del := InputEventKey.new()
	del.keycode = KEY_DELETE
	del.pressed = true
	vp.push_input(del)
	await r.process_frame
	_k5("Tab sonrası ok tuşu taşır, Ctrl+Z geri alır, Del siler (gerçek push_input)", tasi_ok and geri_ok and e.veri["nesneler"].is_empty(),
		"taşı=%s geri=%s nesne=%d" % [tasi_ok, geri_ok, e.veri["nesneler"].size()])

	# --- H: üst ve alt çubuk birlikte
	var h_olay := InputEventKey.new()
	h_olay.keycode = KEY_H
	h_olay.pressed = true
	vp.push_input(h_olay)
	await r.process_frame
	var ikisi_gizli: bool = not e.ust_cubuk.visible and not e.durum_cubugu.visible
	vp.push_input(h_olay)
	await r.process_frame
	_k5("H: üst ve durum çubuğu birlikte gizlenir, tekrar basınca ikisi de görünür", ikisi_gizli and e.ust_cubuk.visible and e.durum_cubugu.visible, "")

	# --- (3) durum çubuğunun altındaki tuvale tıklama geçer (y=630)
	e.yeni()
	e.arac_sec("sec")
	var zid: String = e.blok_ekle([0, 620, 1152, 28])
	e.sec("")
	await r.process_frame
	var hareket := InputEventMouseMotion.new()
	hareket.position = Vector2(500, 630)
	hareket.global_position = hareket.position
	vp.push_input(hareket, true)
	await r.physics_frame
	var bas := InputEventMouseButton.new()
	bas.button_index = MOUSE_BUTTON_LEFT
	bas.pressed = true
	bas.position = Vector2(500, 630)
	bas.global_position = bas.position
	bas.button_mask = MOUSE_BUTTON_MASK_LEFT
	vp.push_input(bas, true)
	await r.physics_frame
	var birak := InputEventMouseButton.new()
	birak.button_index = MOUSE_BUTTON_LEFT
	birak.pressed = false
	birak.position = bas.position
	birak.global_position = bas.position
	vp.push_input(birak, true)
	await r.physics_frame
	await r.process_frame
	_k5("durum çubuğu üzerinden tıklama tuvale geçer: y=630'daki zemin bloğu seçilir (gerçek push_input)",
		e.secili == zid and e.durum_cubugu.mouse_filter == Control.MOUSE_FILTER_IGNORE, "seçili='%s'" % e.secili)

	# --- (4) Enter'sız kaydet
	e.yeni()
	e.ad_alani.text = "Yeni Ad"
	var kh: int = e.kaydet()
	var dosya: String = BolumYollari.bolumler_dizini(KOK) + "yeni_ad_001.json"
	var yuk: Dictionary = BolumVerisi.oku(dosya)["veri"]
	_k5("kaydet(): Enter'sız yazılan ad işlenir; dosya ve kimlik yeni adla (yeni_ad_001)",
		kh == OK and e.veri["ad"] == "Yeni Ad" and e.veri["kimlik"] == "yeni_ad_001" and FileAccess.file_exists(dosya)
		and str(yuk.get("ad", "")) == "Yeni Ad" and str(yuk.get("kimlik", "")) == "yeni_ad_001",
		"kh=%d ad=%s kimlik=%s dosya=%s" % [kh, e.veri["ad"], e.veri["kimlik"], FileAccess.file_exists(dosya)])

	r.paused = false
	_dizin_sil(KOK)
	_k5("ek testler sonunda user://test_editor/ silindi", DirAccess.open(KOK) == null, "")


# ---------------------------------------------------------------- A6


func _k6(ad: String, ok: bool, ayr: String) -> void:
	_kaydi("Editör A6: " + ad, ok, ayr)


## En küçük HATA'sız bölüm: zemin [0,600,1152,48], başlangıç [150,600], çıkış [900,600].
func _gecerli(e: Node, ad := "Deneme Bir") -> void:
	e.yeni()
	e.ad_ata(ad)
	e.blok_ekle([0, 600, 1152, 48])
	e.baslangic_koy(Vector2(150, 600))
	e.cikis_koy(Vector2(900, 600))


func _sahne_bekle(eski_id: int) -> Node:
	var s: Node = await r.call("_yeni_sahne_bekle", eski_id)
	await r.physics_frame
	return s


## Editörde Dene'ye girer; dönüş: açılan dene sahnesi (null: girilemedi).
func _dene_gir(e: Node) -> Node:
	var id := e.get_instance_id()
	if not e.dene_baslat():
		return null
	return await _sahne_bekle(id)


func _tus(yon: float, kare: int) -> void:
	for i in kare:
		r.call("_girdi_uygula", {"yon": yon, "zipla": false})
		await r.physics_frame
	r.call("_girdi_uygula", {"yon": 0.0, "zipla": false})


func _sonuc_ac(bolum: Node) -> Node:
	bolum._bolumu_bitir()
	await r.process_frame
	return bolum.get_node_or_null("SonucEkrani")



func a6_testleri() -> void:
	r.paused = false
	_dizin_sil(KOK)
	r.call("_kayitlar").sifirla()
	EditorOturumu.temizle()
	var e: Node = await _ed()

	# --- (1) Dene girişi
	e.yeni()
	var hatali: bool = e.dene_baslat()
	_k6("Dene: statik HATA'lı bölümde dene_baslat false, durum mesajı, sahne değişmez",
		not hatali and r.current_scene == e and e.durum_mesaji.contains("Dene açılamadı") and not EditorOturumu.donus,
		"dönen=%s mesaj='%s'" % [hatali, e.durum_mesaji])
	_gecerli(e)
	e.sec("Blok1")
	var g0: int = e.gecmis.size()
	var dene: Node = await _dene_gir(e)
	var yol: String = dene.scene_file_path if dene != null else ""
	_k6("Dene: geçerli bölümde true; editor/dene_N.tscn açılır, BolumYollari.dene_mi",
		dene != null and yol.begins_with(KOK + "editor/dene_") and yol.ends_with(".tscn") and BolumYollari.dene_mi(yol) and r.current_scene == dene and EditorOturumu.donus,
		"yol=%s" % yol)
	var etiket: Label = dene.get_node_or_null("BolumKatmani/BolumEtiketi") as Label if dene != null else null
	_k6("Dene: HUD başlığı 'Deneme · Ad'", etiket != null and etiket.text == "Deneme · Deneme Bir" and BolumListesi.baslik(yol) == "Deneme · Deneme Bir",
		"etiket='%s'" % (etiket.text if etiket != null else "yok"))
	var hud: Node = dene.get_node_or_null("EditorHud")
	_k6("Dene (çözümsüz bölüm): EditorHud uyarı satırı var ve doğru metin",
		hud != null and hud.get("uyari") != null and (hud.get("uyari") as Label).text == EditorHud.UYARI_METNI, "hud=%s" % hud)
	var sonuc: Node = await _sonuc_ac(dene)
	var cd: Button = sonuc.get("cozum_dugmesi") if sonuc != null else null
	_k6("Dene sonuç ekranı: Sonraki gizli, CozumKaydetDugmesi görünür, Menü düğmesi 'Editöre dön'",
		sonuc != null and sonuc.get("dene_kipi") == true and not sonuc.sonraki_dugmesi.visible and cd != null and cd.visible
		and cd.name == "CozumKaydetDugmesi" and sonuc.menu_dugmesi.text == "Editöre dön",
		"sonuc=%s sonraki görünür=%s menü='%s'" % [sonuc, sonuc.sonraki_dugmesi.visible if sonuc != null else "-", sonuc.menu_dugmesi.text if sonuc != null else "-"])
	r.paused = false

	# --- (2) çözümsüz bölüm oynanır: tur bitir → klon
	var bolum2: Node = await r.call("_ar_sahne_yukle", yol)
	await r.physics_frame
	await _tus(1.0, 20)
	var id2 := bolum2.get_instance_id()
	await r.call("_r_bas")
	var bolum3: Node = await _sahne_bekle(id2)
	var klonlar: Array = r.call("_klonlar", bolum3) if bolum3 != null else []
	_k6("çözümsüz bölüm oynanabilir: R ile tur biter, klon oluşur, Kayitlar.turlar 1",
		bolum3 != null and klonlar.size() == 1 and r.call("_kayitlar").turlar.size() == 1 and bolum3.get_node_or_null("EditorHud") != null,
		"klon=%d tur=%d" % [klonlar.size(), r.call("_kayitlar").turlar.size()])

	# --- (3) Çözümü kaydet → editöre dön
	await _tus(-1.0, 15)
	var oyuncu: Node = bolum3.get_node("Oyuncu")
	var beklenen_tur: Array = (r.call("_kayitlar").turlar[0] as Array).duplicate(true)
	var beklenen_oyuncu: Array = (oyuncu.kayit_girdileri as Array).duplicate(true)
	var sonuc3: Node = await _sonuc_ac(bolum3)
	var id3 := bolum3.get_instance_id()
	sonuc3.cozum_dugmesi.pressed.emit()
	var e3: Node = await _sahne_bekle(id3)
	var ayr3 := "editör açılmadı"
	if e3 != null and e3.scene_file_path.ends_with("editor.tscn"):
		e3.kok = KOK
		var cz: Dictionary = e3.veri.get("cozum", {})
		var rle_tur: Array = []
		if cz.has("turlar") and (cz["turlar"] as Array).size() > 0:
			rle_tur = cz["turlar"][0]
		var rle_oy: Array = cz.get("oyuncu", [])
		var rle_ok: bool = cz.has("turlar") and (cz["turlar"] as Array).size() == 1 and rle_tur == BolumVerisi.kayit_kodla(beklenen_tur) \
			and rle_oy == BolumVerisi.kayit_kodla(beklenen_oyuncu)
		var acik_tur: Array = BolumVerisi.kayit_coz(rle_tur)
		var acik_oy: Array = BolumVerisi.kayit_coz(rle_oy)
		var geri_esit: bool = acik_tur.size() == beklenen_tur.size() and acik_oy.size() == beklenen_oyuncu.size()
		if geri_esit:
			for i in beklenen_tur.size():
				geri_esit = geri_esit and float(acik_tur[i]["yon"]) == float(beklenen_tur[i]["yon"]) and bool(acik_tur[i]["zipla"]) == bool(beklenen_tur[i]["zipla"]) \
					and bool(acik_tur[i].get("asagi", false)) == bool(beklenen_tur[i].get("asagi", false))
			for i in beklenen_oyuncu.size():
				geri_esit = geri_esit and float(acik_oy[i]["yon"]) == float(beklenen_oyuncu[i]["yon"]) and bool(acik_oy[i]["zipla"]) == bool(beklenen_oyuncu[i]["zipla"]) \
					and bool(acik_oy[i].get("asagi", false)) == bool(beklenen_oyuncu[i].get("asagi", false))
		ayr3 = "rle eşit=%s geri açınca eşit=%s (tur %d, oyuncu %d kare)" % [rle_ok, geri_esit, beklenen_tur.size(), beklenen_oyuncu.size()]
		_k6("Çözümü kaydet: editöre döner, veri['cozum'] RLE doğru (kayit_coz ile geri açınca kayıtla eşit)", rle_ok and geri_esit, ayr3)
		_k6("Çözümü kaydet: Kayitlar boş, geçmişe kayıt atılmaz, veri/seçim/önizleme korunur, oturum temiz",
			r.call("_kayitlar").turlar.is_empty() and e3.gecmis.size() == g0 and e3.secili == "Blok1"
			and e3.veri["nesneler"].size() == 1 and e3.dugumler.size() == 1 and EditorOturumu.cozum.is_empty() and not EditorOturumu.donus
			and e3.veri["ad"] == "Deneme Bir" and e3.veri["baslangic"] == [150, 600],
			"kayitlar=%d gecmis=%d/%d secili='%s'" % [r.call("_kayitlar").turlar.size(), e3.gecmis.size(), g0, e3.secili])
	else:
		_k6("Çözümü kaydet: editöre döner, veri['cozum'] RLE doğru", false, ayr3)
		_k6("Çözümü kaydet: Kayitlar boş, geçmiş/veri/seçim korunur", false, ayr3)
	r.paused = false

	# --- (4) Dene'de ev butonu editöre döner, çözüm yazılmaz
	var e4: Node = await _ed()
	_gecerli(e4)
	var dene4: Node = await _dene_gir(e4)
	r.call("_kayitlar").tur_kaydet([{"yon": 1.0, "zipla": false, "asagi": false}])
	var id4 := dene4.get_instance_id()
	dene4.butonlar.ev_dugmesi.pressed.emit()
	var e4b: Node = await _sahne_bekle(id4)
	if e4b != null:
		e4b.kok = KOK
	_k6("Dene'de ev butonu editöre döner, Kayitlar boşalır, çözüm yazılmaz, veri korunur",
		e4b != null and e4b.scene_file_path.ends_with("editor.tscn") and r.call("_kayitlar").turlar.is_empty()
		and not e4b.veri.has("cozum") and e4b.veri["nesneler"].size() == 1 and e4b.veri["ad"] == "Deneme Bir",
		"sahne=%s" % (e4b.scene_file_path if e4b != null else "yok"))

	# --- (5) Dene → editör → Menü (temizken) → ana menü; sonra editör boş başlar
	var e5: Node = await _ed()
	_gecerli(e5)
	e5.kaydet()
	var dene5: Node = await _dene_gir(e5)
	var id5 := dene5.get_instance_id()
	dene5.butonlar.ev_dugmesi.pressed.emit()
	var e5b: Node = await _sahne_bekle(id5)
	e5b.kok = KOK
	var temiz_mi: bool = not e5b.kirli_mi()
	var id5b := e5b.get_instance_id()
	r.call("_kayitlar").tur_kaydet([{"yon": 1.0, "zipla": false, "asagi": false}])
	e5b.menu_iste()
	var menu: Node = await _sahne_bekle(id5b)
	_k6("Dene'den dönüşte Menü: ana menü açılır, Kayitlar boş, EditorOturumu temiz",
		temiz_mi and menu != null and menu.scene_file_path.ends_with("ana_menu.tscn") and r.call("_kayitlar").turlar.is_empty()
		and EditorOturumu.veri.is_empty() and not EditorOturumu.donus and EditorOturumu.cozum.is_empty() and EditorOturumu.son_yol == "",
		"temiz=%s sahne=%s" % [temiz_mi, menu.scene_file_path if menu != null else "yok"])
	var idm := menu.get_instance_id()
	(menu.find_child("EditorDugmesi", true, false) as Button).pressed.emit()
	var e5c: Node = await _sahne_bekle(idm)
	_k6("ana menüden editör girişi boş bölümle başlar (eski oturum kalıntısı yok)",
		e5c != null and e5c.scene_file_path.ends_with("editor.tscn") and e5c.veri["nesneler"].is_empty() and e5c.veri["ad"] == "Yeni Bölüm"
		and not e5c.kimlik_kilitli and e5c.gecmis.size() == 1,
		"ad=%s nesne=%d" % [e5c.veri["ad"] if e5c != null else "-", e5c.veri["nesneler"].size() if e5c != null else -1])

	# --- (6) regresyon: resmî bölüm
	var b1: Node = await r.call("_ar_sahne_yukle", "res://scenes/bolumler/bolum_1.tscn")
	await r.physics_frame
	var et1 := b1.get_node_or_null("BolumKatmani/BolumEtiketi") as Label
	var sn1: Node = await _sonuc_ac(b1)
	_k6("resmî Bölüm 1: başlıkta 'Deneme' yok, sonuç ekranında Sonraki görünür, çözüm düğmesi yok, Menü düğmesi değişmemiş",
		et1 != null and et1.text.begins_with("Bölüm 1") and not et1.text.contains("Deneme") and sn1 != null and sn1.get("dene_kipi") == false
		and sn1.sonraki_dugmesi.visible and sn1.get("cozum_dugmesi") == null and sn1.menu_dugmesi.text != "Editöre dön",
		"etiket='%s' menü='%s'" % [et1.text if et1 != null else "yok", sn1.menu_dugmesi.text if sn1 != null else "-"])
	var id6 := b1.get_instance_id()
	sn1.menu_dugmesi.pressed.emit()
	var m6: Node = await _sahne_bekle(id6)
	var menu_ok: bool = m6 != null and m6.scene_file_path.ends_with("ana_menu.tscn")
	var b1b: Node = await r.call("_ar_sahne_yukle", "res://scenes/bolumler/bolum_1.tscn")
	await r.physics_frame
	r.call("_kayitlar").tur_kaydet([{"yon": 1.0, "zipla": false, "asagi": false}])
	var id6b := b1b.get_instance_id()
	b1b.butonlar.ev_dugmesi.pressed.emit()
	var m6b: Node = await _sahne_bekle(id6b)
	_k6("resmî Bölüm 1: sonuç ekranı Menü ve ev butonu hâlâ ana menüye gider (editöre değil), Kayitlar boşalır",
		menu_ok and m6b != null and m6b.scene_file_path.ends_with("ana_menu.tscn") and r.call("_kayitlar").turlar.is_empty(),
		"menü düğmesi=%s ev=%s" % [menu_ok, m6b.scene_file_path if m6b != null else "yok"])
	r.paused = false

	# --- (7) A5 düzeltmeleri: kirli_mi ve onay diyaloğu, durum çubuğu
	var e7: Node = await _ed()
	var k_yeni: bool = e7.kirli_mi()
	e7.blok_ekle([100, 100, 50, 50])
	var k_blok: bool = e7.kirli_mi()
	e7.ad_ata("Kirli Deneme")
	e7.kaydet()
	var k_kaydet: bool = e7.kirli_mi()
	var kayit_yolu: String = e7.son_yol
	e7.blok_ekle([300, 100, 50, 50])
	var k_kirli: bool = e7.kirli_mi()
	e7.yeni()
	var k_yeni2: bool = e7.kirli_mi()
	e7.ac(kayit_yolu)
	var k_ac: bool = e7.kirli_mi()
	_k6("kirli_mi: yeni false, blok_ekle sonrası true, kaydet/yeni/ac sonrası false",
		not k_yeni and k_blok and not k_kaydet and k_kirli and not k_yeni2 and not k_ac,
		"yeni=%s blok=%s kaydet=%s blok2=%s yeni()=%s ac=%s" % [k_yeni, k_blok, k_kaydet, k_kirli, k_yeni2, k_ac])
	e7.blok_ekle([10, 10, 50, 50])
	e7.yeni_iste()
	var d1: bool = e7.onay_diyalogu.visible and e7.veri["nesneler"].size() == 2
	e7.onay_iptal()
	var iptal_ok: bool = not e7.onay_diyalogu.visible and e7.veri["nesneler"].size() == 2 and e7.kirli_mi()
	e7.ac_iste(kayit_yolu)
	var d2: bool = e7.onay_diyalogu.visible and e7.veri["nesneler"].size() == 2
	e7.onay_iptal()
	var sahne7: Node = r.current_scene
	e7.menu_iste()
	var d3: bool = e7.onay_diyalogu.visible and r.current_scene == sahne7 and r.current_scene == e7
	e7.onay_iptal()
	_k6("kirliyken yeni_iste/ac_iste/menu_iste: OnayDiyalogu görünür, işlem yürümez; onay_iptal veriyi korur",
		d1 and iptal_ok and d2 and d3, "yeni=%s iptal=%s ac=%s menü=%s" % [d1, iptal_ok, d2, d3])
	e7.yeni_iste()
	e7.onay_kabul()
	var kabul_yeni: bool = e7.veri["nesneler"].is_empty() and not e7.onay_diyalogu.visible and not e7.kirli_mi()
	e7.blok_ekle([10, 10, 50, 50])
	e7.ac_iste(kayit_yolu)
	e7.onay_kabul()
	var kabul_ac: bool = e7.veri["nesneler"].size() == 1 and e7.veri["nesneler"][0]["alan"][0] == 100 and not e7.kirli_mi()
	_k6("onay_kabul bekleyen işlemi yürütür (yeni ve ac)", kabul_yeni and kabul_ac, "yeni=%s ac=%s" % [kabul_yeni, kabul_ac])
	e7.yeni()
	e7.yeni_iste()
	var temiz_diyalog: bool = e7.onay_diyalogu.visible
	e7.blok_ekle([10, 10, 50, 50])
	e7.kaydet()
	e7.yeni_iste()
	_k6("temizken diyalog çıkmaz, işlem hemen yürür", not temiz_diyalog and not e7.onay_diyalogu.visible and e7.veri["nesneler"].is_empty(),
		"diyalog=%s nesne=%d" % [e7.onay_diyalogu.visible, e7.veri["nesneler"].size()])
	var panel_stili: StyleBox = e7.durum_cubugu.get_theme_stylebox("panel")
	_k6("durum çubuğu paneli şeffaf (StyleBoxEmpty) ve mouse_filter IGNORE",
		panel_stili is StyleBoxEmpty and e7.durum_cubugu.mouse_filter == Control.MOUSE_FILTER_IGNORE,
		"stil=%s filtre=%d" % [panel_stili, e7.durum_cubugu.mouse_filter])

	r.paused = false
	r.call("_kayitlar").sifirla()
	EditorOturumu.temizle()
	_dizin_sil(KOK)
	_k6("A6 sonunda user://test_editor/ silindi", DirAccess.open(KOK) == null, "")


## Gözden geçirici sonrası A6 eklemeleri: çözüm geçmişte kalıcı, Enter'sız ad kirliliği, diyalog iptali, kirliyken Dene.
func a6_ek_testleri() -> void:
	r.paused = false
	_dizin_sil(KOK)
	r.call("_kayitlar").sifirla()
	EditorOturumu.temizle()

	# --- 1) çözümü kaydet → geri al → yinele
	var e: Node = await _ed()
	_gecerli(e)
	e.kaydet()
	var e1: Node = await _cozum_akisi(e)
	var cozum_var: bool = e1 != null and e1.veri.has("cozum")
	var gi0: int = e1.gecmis_i if e1 != null else -1
	var gs0: int = e1.gecmis.size() if e1 != null else -1
	e1.geri_al()
	var geri_cozumsuz: bool = not e1.veri.has("cozum")
	e1.yinele()
	_k6("çözümü kaydet → geri al → yinele: veri['cozum'] geri gelir (anlık görüntüye yazılmış)",
		cozum_var and e1.veri.has("cozum") and e1.gecmis_i == gi0 and e1.gecmis.size() == gs0,
		"cozum var=%s geri alınca çözümsüz=%s yineleyince var=%s" % [cozum_var, geri_cozumsuz, e1.veri.has("cozum")])
	var cozum_kopya: Dictionary = (e1.veri["cozum"] as Dictionary).duplicate(true)
	e1.blok_ekle([300, 400, 100, 20])
	var blok_cozumlu: bool = e1.veri.has("cozum")
	e1.geri_al()
	var bir_geri: bool = e1.veri.has("cozum") and e1.veri["cozum"] == cozum_kopya and e1.veri["nesneler"].size() == 1
	e1.geri_al()
	var iki_geri: bool = e1.veri.has("cozum")
	_k6("çözümü kaydet → blok ekle → geri al: çözüm kaydındaki anlık görüntüye dönülür, çözüm aynı",
		blok_cozumlu and bir_geri, "blok sonrası çözüm=%s 1 geri: %s" % [blok_cozumlu, bir_geri])
	# Çözüm kaydedildiği anlık görüntüyle birlikte yaşar: bir öncesine dönünce (içerik farklı) yoktur,
	# yinelenince geri gelir.
	e1.yinele()
	e1.yinele()
	var iki_ileri: bool = e1.veri.has("cozum") and e1.veri["cozum"] == cozum_kopya
	_k6("çözümü kaydet → blok ekle → 2 geri al: kayıt öncesi görüntüde çözüm yok; 2 yinele: çözüm geri gelir",
		not iki_geri and iki_ileri,
		"2 geri sonrası çözüm var=%s, 2 yinele sonrası aynı çözüm=%s" % [iki_geri, iki_ileri])

	# --- 2) Enter'sız ad: yeni_iste / ac_iste / menu_iste diyalog açar, iptalde ad korunur
	var e2: Node = await _ed()
	_gecerli(e2, "Ilk Ad")
	e2.kaydet()
	var yol2: String = e2.son_yol
	var temiz0: bool = not e2.kirli_mi()
	e2.ad_alani.text = "Yazilan Ad Bir"
	e2.yeni_iste()
	var y_ok: bool = e2.onay_diyalogu.visible and e2.veri["ad"] == "Yazilan Ad Bir"
	e2.onay_iptal()
	var y_iptal: bool = not e2.onay_diyalogu.visible and e2.veri["ad"] == "Yazilan Ad Bir" and e2.veri["nesneler"].size() == 1
	e2.ad_alani.text = "Yazilan Ad Iki"
	e2.ac_iste(yol2)
	var a_ok: bool = e2.onay_diyalogu.visible and e2.veri["ad"] == "Yazilan Ad Iki"
	e2.onay_iptal()
	var a_iptal: bool = e2.veri["ad"] == "Yazilan Ad Iki" and e2.ad_alani.text == "Yazilan Ad Iki"
	e2.ad_alani.text = "Yazilan Ad Uc"
	var sahne2: Node = r.current_scene
	e2.menu_iste()
	var m_ok: bool = e2.onay_diyalogu.visible and r.current_scene == sahne2 and e2.veri["ad"] == "Yazilan Ad Uc"
	e2.onay_iptal()
	_k6("Enter'sız yazılan ad kirlilik sayılır: yeni_iste/ac_iste/menu_iste OnayDiyalogu açar, iptalde ad korunur",
		temiz0 and y_ok and y_iptal and a_ok and a_iptal and m_ok,
		"temiz=%s yeni=%s/%s ac=%s/%s menü=%s" % [temiz0, y_ok, y_iptal, a_ok, a_iptal, m_ok])

	# --- 3) geri al sonrası kirli_mi
	var e3: Node = await _ed()
	_gecerli(e3, "Kirlilik")
	e3.kaydet()
	var t3: bool = not e3.kirli_mi()
	e3.blok_ekle([10, 10, 50, 50])
	var k3: bool = e3.kirli_mi()
	e3.geri_al()
	var g3: bool = not e3.kirli_mi()
	e3.yinele()
	var y3: bool = e3.kirli_mi()
	_k6("geri al sonrası kirli_mi: kayıtlı hâle dönünce false, yinele ile tekrar true",
		t3 and k3 and g3 and y3, "temiz=%s kirli=%s geri=%s yinele=%s" % [t3, k3, g3, y3])

	# --- 4) diyalog canceled (Esc/X) bekleyen işlemi atar
	e3.yeni_iste()
	var v4: bool = e3.onay_diyalogu.visible
	e3.onay_diyalogu.canceled.emit()
	var gizli4: bool = not e3.onay_diyalogu.visible
	e3.onay_kabul()   # bekleyen işlem atıldığı için hiçbir şey yürümemeli
	_k6("onay diyaloğu canceled (Esc/X) bekleyen işlemi atar: sonraki onay_kabul işlem yürütmez",
		v4 and gizli4 and e3.veri["nesneler"].size() == 2, "görünür=%s kapandı=%s nesne=%d" % [v4, gizli4, e3.veri["nesneler"].size()])

	# --- 5) kirliyken dene_baslat onay sormaz; dönüşte kirlilik korunur, Menü sorar
	var e5: Node = await _ed()
	_gecerli(e5, "Kirli Dene")
	e5.kaydet()
	e5.blok_ekle([400, 300, 60, 20])
	var kirli5: bool = e5.kirli_mi()
	var id5 := e5.get_instance_id()
	var girdi5: bool = e5.dene_baslat()
	var dialog5: bool = e5.onay_diyalogu.visible
	var dene5: Node = await _sahne_bekle(id5)
	var dene_ok5: bool = dene5 != null and BolumYollari.dene_mi(dene5.scene_file_path)
	var did5 := dene5.get_instance_id()
	dene5.butonlar.ev_dugmesi.pressed.emit()
	var e5b: Node = await _sahne_bekle(did5)
	e5b.kok = KOK
	var hala_kirli: bool = e5b.kirli_mi()
	var sahne5: Node = r.current_scene
	e5b.menu_iste()
	var sorar: bool = e5b.onay_diyalogu.visible and r.current_scene == sahne5
	e5b.onay_iptal()
	_k6("kirliyken dene_baslat onay sormaz; dönüşte kirlilik korunur ve Menü sorar",
		kirli5 and girdi5 and not dialog5 and dene_ok5 and hala_kirli and sorar,
		"kirli=%s giriş=%s diyalog=%s dönüşte kirli=%s menü sorar=%s" % [kirli5, girdi5, dialog5, hala_kirli, sorar])

	# --- 7) bonus: statik EditorOturumu değerleri editör serbest kalınca yaşar
	var e7: Node = await _ed()
	EditorOturumu.donus = true
	EditorOturumu.veri = {"ad": "Kalici", "nesneler": []}
	EditorOturumu.son_yol = "user://test_editor/kalici.json"
	var id7 := e7.get_instance_id()
	var ana: Node = await r.call("_ar_sahne_yukle", "res://scenes/ana_menu.tscn")
	await r.physics_frame
	await r.physics_frame
	var serbest: bool = not is_instance_valid(e7)
	_k6("EditorOturumu statik değerleri editör serbest kalınca (sahne değişimi) yaşar",
		serbest and ana != null and EditorOturumu.donus and EditorOturumu.veri.get("ad", "") == "Kalici" and EditorOturumu.son_yol == "user://test_editor/kalici.json",
		"editör serbest=%s donus=%s veri=%s" % [serbest, EditorOturumu.donus, EditorOturumu.veri])
	EditorOturumu.temizle()

	r.paused = false
	r.call("_kayitlar").sifirla()
	EditorOturumu.temizle()
	_dizin_sil(KOK)
	_k6("A6 ek testler sonunda user://test_editor/ silindi", DirAccess.open(KOK) == null, "")


## Geçerli bölümle Dene'ye girer, bir tur oynayıp klon üretir, sonuç ekranında 'Çözümü kaydet' ile editöre döner.
func _cozum_akisi(e: Node) -> Node:
	var dene: Node = await _dene_gir(e)
	if dene == null:
		return null
	await _tus(1.0, 20)
	var id := dene.get_instance_id()
	await r.call("_r_bas")
	var b2: Node = await _sahne_bekle(id)
	await _tus(-1.0, 10)
	var sonuc: Node = await _sonuc_ac(b2)
	var id2 := b2.get_instance_id()
	sonuc.cozum_dugmesi.pressed.emit()
	var e2: Node = await _sahne_bekle(id2)
	r.paused = false
	if e2 != null:
		e2.kok = KOK
	return e2



# ---------------------------------------------------------------- A7: bağlantı ve kablo

func _k7(ad: String, ok: bool, ayr: String) -> void:
	_kaydi("Editör A7: " + ad, ok, ayr)


func _pn(a: PackedVector2Array) -> Array:
	var s: Array = []
	for p in a:
		s.append([roundi(p.x), roundi(p.y)])
	return s


## Kurucunun (BolumKurucu.kur) ürettiği hedef düğümün kablo meta noktaları.
func _kurulan_meta(veri: Dictionary, hedef: String, meta: String) -> Array:
	var kok: Node2D = BolumKurucu.kur(veri)
	var d: Node = kok.get_node_or_null(hedef)
	var sonuc: Array = _pn(d.get_meta(meta)) if d != null and d.has_meta(meta) else []
	kok.free()
	return sonuc


func _ara(e: Node, hedef: String, tetik: String) -> Array:
	return BaglantiIslemleri.ara_noktalar(e.veri, hedef, tetik)


func a7_testleri() -> void:
	r.paused = false
	_dizin_sil(KOK)
	var e: Node = await _ed()
	var vp: Viewport = e.get_viewport()

	# --- nesne_ekle
	_gecerli(e, "Baglanti Denemesi")
	var pid: String = e.nesne_ekle("plaka", Vector2(200, 600))
	var gid: String = e.nesne_ekle("gecit", Vector2(500, 600))
	var aid: String = e.nesne_ekle("asansor", Vector2(700, 500))
	_k7("nesne_ekle: kimlikler Plaka1/Gecit1/Asansor1 ve düğümler önizlemede", [pid, gid, aid] == ["Plaka1", "Gecit1", "Asansor1"]
		and e.onizleme_dugumu("Plaka1") != null and e.onizleme_dugumu("Gecit1") != null and e.onizleme_dugumu("Asansor1") != null,
		"%s" % [[pid, gid, aid]])
	_k7("nesne_ekle: JSON alanları (plaka konum; geçit kayma 100, boş tetikleyiciler; asansör yükseklik 180, plaka yok)",
		e._nesne("Plaka1") == {"tur": "plaka", "id": "Plaka1", "konum": [200, 600]}
		and e._nesne("Gecit1") == {"tur": "gecit", "id": "Gecit1", "konum": [500, 600], "kayma_mesafe": 100, "tetikleyiciler": [], "acik_taraf_sag": true}
		and e._nesne("Asansor1") == {"tur": "asansor", "id": "Asansor1", "konum": [700, 500], "yukseklik": 180},
		JSON.stringify(e.veri["nesneler"].slice(1)))
	_k7("nesne_ekle: düğüm konumları çapa tablosuna uyar (plaka y-8, geçit y-100, asansör y+10)",
		e.onizleme_dugumu("Plaka1").position == Vector2(200, 592) and e.onizleme_dugumu("Gecit1").position == Vector2(500, 500)
		and e.onizleme_dugumu("Asansor1").position == Vector2(700, 510), "%s %s %s" % [e.onizleme_dugumu("Plaka1").position, e.onizleme_dugumu("Gecit1").position, e.onizleme_dugumu("Asansor1").position])
	_k7("nesne_ekle: desteklenmeyen tür ('ucak', 'blok') reddedilir", e.nesne_ekle("ucak", Vector2(10, 10)) == "" and e.nesne_ekle("blok", Vector2(10, 10)) == "", "")

	# --- statik denetim: bağlanmamış asansör D3 HATA, bağlanınca düzelir
	var s0: Array = BolumDenetci.statik(e.veri)
	_k7("bağlanmamış asansör D3 HATA verir (Dene açılmaz)", _n(s0, "D3", "HATA", "Asansor1", "plaka") == 1 and not e.dene_baslat(), "D3=%d" % _n(s0, "D3", "HATA"))

	# --- bağla: asansör
	_k7("bagla: plaka -> asansör 'baglandi', JSON plaka alanı, D3 hatası kalkar",
		e.bagla("Plaka1", "Asansor1") == "baglandi" and e._nesne("Asansor1")["plaka"] == "Plaka1"
		and _n(BolumDenetci.statik(e.veri), "D3", "HATA") == 0, JSON.stringify(e._nesne("Asansor1")))
	_k7("bagla: önizlemede asansörün plaka referansı bağlanır", e.onizleme_dugumu("Asansor1").get("plaka") == e.onizleme_dugumu("Plaka1"), "")
	var ikinci: String = e.nesne_ekle("plaka", Vector2(900, 600))
	var onc_ikinci: String = BolumVerisi.kanonik_metin(e.veri)
	var sonuc_onay: String = e.bagla(ikinci, "Asansor1")
	_k7("bagla: asansöre ikinci plaka 'onay' ister, diyalog açılır, veri değişmez",
		sonuc_onay == "onay" and e.onay_diyalogu.visible and e.onay_diyalogu.dialog_text.contains("Plaka1")
		and BolumVerisi.kanonik_metin(e.veri) == onc_ikinci, "sonuç=%s metin=%s" % [sonuc_onay, e.onay_diyalogu.dialog_text])
	e.onay_iptal()
	_k7("bagla: onay iptal edilirse bağlantı aynı kalır ve diyalog metni eski haline döner",
		e._nesne("Asansor1")["plaka"] == "Plaka1" and e.onay_diyalogu.dialog_text == e.ONAY_METNI and not e.onay_diyalogu.visible, "")
	e.bagla(ikinci, "Asansor1")
	e.onay_kabul()
	_k7("bagla: onaylanınca yeni plaka eskisinin yerine geçer; eski kablo kaydı silinir",
		e._nesne("Asansor1")["plaka"] == ikinci and not e._nesne("Asansor1").has("kablo") and e.onay_diyalogu.dialog_text == e.ONAY_METNI, JSON.stringify(e._nesne("Asansor1")))
	_k7("bagla: aynı plakaya tekrar bağlanmak bağlantıyı kaldırır (plaka alanı ve kablo gider)",
		e.bagla(ikinci, "Asansor1") == "kaldirildi" and not e._nesne("Asansor1").has("plaka"), JSON.stringify(e._nesne("Asansor1")))
	e.bagla("Plaka1", "Asansor1")

	# --- bağla: geçit, reddedilenler
	_k7("bagla: geçite plaka eklenir ve ikinci çağrı kaldırır (tetikleyiciler dizisi)",
		e.bagla("Plaka1", "Gecit1") == "baglandi" and e._nesne("Gecit1")["tetikleyiciler"] == ["Plaka1"]
		and e.bagla("Plaka1", "Gecit1") == "kaldirildi" and e._nesne("Gecit1")["tetikleyiciler"] == [], JSON.stringify(e._nesne("Gecit1")))
	e.veri["nesneler"].append({"tur": "salter", "id": "Salter1", "konum": [300, 600]})
	e._onizlemeyi_kur()
	_k7("bagla: şalter asansöre reddedilir, geçide bağlanabilir",
		e.bagla("Salter1", "Asansor1") == "red" and e._nesne("Asansor1")["plaka"] == "Plaka1" and e.bagla("Salter1", "Gecit1") == "baglandi"
		and e._nesne("Gecit1")["tetikleyiciler"] == ["Salter1"], JSON.stringify(e._nesne("Gecit1")))
	e.bagla("Salter1", "Gecit1")
	_k7("bagla: kaynak tetikleyici değilse, hedef hedef değilse, olmayan kimlikte 'red'",
		e.bagla("Gecit1", "Asansor1") == "red" and e.bagla("Plaka1", "Plaka1") == "red" and e.bagla("YOK", "Gecit1") == "red"
		and e.bagla("Plaka1", "YOK") == "red", "")
	e.nesne_sil(ikinci)
	e.nesne_sil("Salter1")

	# --- kablo yolu: otomatik L ve kurucu eşleşmesi
	e.bagla("Plaka1", "Gecit1")
	var yol0: Array = _pn(e.kablo_yolu("Gecit1", "Plaka1"))
	_k7("kablo: varsayılan yol L biçimindedir (tetikleyici merkezi, (tetik.x, hedef.y), hedef)", yol0 == [[200, 592], [200, 500], [500, 500]], str(yol0))
	_k7("kablo: önizleme düğümünün 'kablo' meta'sı yolla ve kurucu çıktısıyla aynı",
		_pn(e.onizleme_dugumu("Gecit1").get_meta("kablo")) == yol0 and _kurulan_meta(e.veri, "Gecit1", "kablo") == yol0, str(yol0))
	_k7("kablo: asansör kablosu hedef noktası alt konumdaki üst yüzey ortası",
		_pn(e.kablo_yolu("Asansor1", "Plaka1")) == [[200, 592], [200, 500], [700, 500]], str(_pn(e.kablo_yolu("Asansor1", "Plaka1"))))

	# --- ara noktalar
	var i_ek: int = e.ara_nokta_ekle("Gecit1", "Plaka1", Vector2(200, 540))
	_k7("ara_nokta_ekle: ilk düzenleme L'yi açık listeye çevirir, yeni nokta doğru parçaya girer, ızgaraya oturur",
		i_ek == 0 and _ara(e, "Gecit1", "Plaka1") == [[200, 540], [200, 500]], "i=%d %s" % [i_ek, JSON.stringify(_ara(e, "Gecit1", "Plaka1"))])
	var yol1: Array = _pn(e.kablo_yolu("Gecit1", "Plaka1"))
	_k7("ara noktalar JSON'a yazılır ve kurulan meta ile eşleşir",
		yol1 == [[200, 592], [200, 540], [200, 500], [500, 500]] and _pn(e.onizleme_dugumu("Gecit1").get_meta("kablo")) == yol1
		and _kurulan_meta(e.veri, "Gecit1", "kablo") == yol1, str(yol1))
	e.ara_nokta_tasi("Gecit1", "Plaka1", 0, Vector2(340, 540))
	_k7("ara_nokta_tasi: nokta taşınır, yol ve meta güncellenir",
		_ara(e, "Gecit1", "Plaka1")[0] == [340, 540] and _pn(e.onizleme_dugumu("Gecit1").get_meta("kablo"))[1] == [340, 540], JSON.stringify(_ara(e, "Gecit1", "Plaka1")))
	e.geri_al()
	var geri_ok: bool = _ara(e, "Gecit1", "Plaka1")[0] == [200, 540]
	e.yinele()
	_k7("kablo düzenlemesi geri al/yinele ile gidip gelir", geri_ok and _ara(e, "Gecit1", "Plaka1")[0] == [340, 540], "")
	e.ara_nokta_sil("Gecit1", "Plaka1", 0)
	e.ara_nokta_sil("Gecit1", "Plaka1", 0)
	_k7("ara_nokta_sil: son nokta silinince kablo kaydı kalkar ve yol otomatik L'ye döner",
		not e._nesne("Gecit1").has("kablolar") and _pn(e.kablo_yolu("Gecit1", "Plaka1")) == yol0, JSON.stringify(e._nesne("Gecit1")))
	e.ara_nokta_ekle("Gecit1", "Plaka1", Vector2(200, 540))
	_k7("kablo_sifirla: ara noktalar silinir, otomatik yola dönülür",
		e.kablo_sifirla("Gecit1", "Plaka1") and _pn(e.kablo_yolu("Gecit1", "Plaka1")) == yol0 and not e._nesne("Gecit1").has("kablolar"), "")

	# --- gizle
	_k7("kablo_gizle_degistir: gizli kabloda meta yazılmaz, bağlantı durur, editör yolu yine hesaplar",
		e.kablo_gizle_degistir("Gecit1", "Plaka1") and not e.onizleme_dugumu("Gecit1").has_meta("kablo")
		and e._nesne("Gecit1")["tetikleyiciler"] == ["Plaka1"] and _pn(e.kablo_yolu("Gecit1", "Plaka1")) == yol0
		and _kurulan_meta(e.veri, "Gecit1", "kablo").is_empty(), JSON.stringify(e._nesne("Gecit1")))
	_k7("kablo_gizle_degistir: yeniden çağrı kabloyu gösterir (kayıt gizli:false ile kirlenmez)",
		e.kablo_gizle_degistir("Gecit1", "Plaka1") and e.onizleme_dugumu("Gecit1").has_meta("kablo") and not e._nesne("Gecit1").has("kablolar"), "")

	# --- üç tetikleyici: meta adları, bilgi notu
	var p2: String = e.nesne_ekle("plaka", Vector2(300, 600))
	var p3: String = e.nesne_ekle("plaka", Vector2(400, 600))
	e.bagla(p2, "Gecit1")
	e.bagla(p3, "Gecit1")
	var adlar: Array = []
	for m in e.onizleme_dugumu("Gecit1").get_meta_list():
		if str(m).begins_with("kablo"):
			adlar.append(str(m))
	adlar.sort()
	# A12: oyun artık asansör kablosunu ve 3. kabloyu da çizer (A11); durum satırı "çizilmez" bilgisi vermez,
	# editördeki her kablo meta'sı oyunun çizim planında (Gorunum.kablo_plani) karşılığını bulur.
	var gor := Gorunum.new()
	var gecit_plani: Array = []
	for k in gor.kablo_plani(e.onizleme_dugumu("Gecit1")):
		gecit_plani.append("%s:%d" % [k[0], k[1]])
	var asansor_plani: Array = []
	for k in gor.kablo_plani(e.onizleme_dugumu("Asansor1")):
		asansor_plani.append("%s:%d" % [k[0], k[1]])
	gor.free()
	_k7("üç tetikleyicide meta adları kablo, kablo_2, kablo_3 ve üçü de oyun çizim planında; durum satırı 'henüz çizilmez' demez",
		adlar == ["kablo", "kablo_2", "kablo_3"] and gecit_plani == ["kablo:0", "kablo_2:1", "kablo_3:2"]
		and not e.durum_etiketi.text.contains("henüz çizilmez") and not e.durum_etiketi.text.contains("Bilgi:"),
		"%s | plan=%s | %s" % [adlar, gecit_plani, e.durum_etiketi.text])
	_k7("asansör kablosu oyun çizim planında (kablo meta'sı var, plan 'kablo' çizer)",
		e.onizleme_dugumu("Asansor1").has_meta("kablo") and asansor_plani == ["kablo:-1"], str(asansor_plani))
	e.nesne_sil(p3)
	e.nesne_sil(p2)

	# --- silme temizliği
	e.ara_nokta_ekle("Gecit1", "Plaka1", Vector2(200, 540))
	e.nesne_sil("Plaka1")
	_k7("nesne_sil: silinen plakaya giden bağlantılar (geçit tetikleyicileri, kablo kaydı, asansör plakası) temizlenir",
		e._nesne("Gecit1")["tetikleyiciler"] == [] and not e._nesne("Gecit1").has("kablolar") and not e._nesne("Asansor1").has("plaka")
		and not e._nesne("Asansor1").has("kablo") and e.onizleme_dugumu("Gecit1") != null and not e.onizleme_dugumu("Gecit1").has_meta("kablo"),
		JSON.stringify([e._nesne("Gecit1"), e._nesne("Asansor1")]))
	_k7("nesne_sil sonrası denetim: asansör plakasız D3 HATA, geçitte dangling bağlantı yok",
		_n(BolumDenetci.statik(e.veri), "D3", "HATA", "Asansor1", "plaka") == 1 and _n(BolumDenetci.statik(e.veri), "D3", "HATA", "Gecit1") == 0, "")
	e.geri_al()
	_k7("nesne_sil geri alınınca bağlantılar da geri gelir", e._nesne("Gecit1")["tetikleyiciler"] == ["Plaka1"] and e._nesne("Asansor1")["plaka"] == "Plaka1", "")

	# --- taşıma: bağlı kablo yeni konuma gider
	e.nesne_tasi("Plaka1", Vector2(40, 0))
	_k7("tetikleyici taşınınca bağlı kablolar yeni konumdan başlar",
		_pn(e.kablo_yolu("Gecit1", "Plaka1"))[0] == [240, 592] and _pn(e.onizleme_dugumu("Gecit1").get_meta("kablo"))[0] == [240, 592]
		and _pn(e.kablo_yolu("Asansor1", "Plaka1"))[0] == [240, 592], str(_pn(e.kablo_yolu("Gecit1", "Plaka1"))))
	e.nesne_tasi("Plaka1", Vector2(-40, 0))

	# --- B21 fikstürü: dışarıdan gelen uclar korunur, taşıyınca silinir
	e.ac(FIKSTUR + "b21.json")
	var b21_kablo: Array = _pn(e.kablo_yolu("GecitG", "PlakaZ"))
	_k7("B21: dışarıdan gelen 'uclar' aynen çizilir ve ara nokta eklemek uçları korur",
		b21_kablo == [[170, 584], [170, 376]] and e.ara_nokta_ekle("GecitG", "PlakaZ", Vector2(180, 480)) == 0
		and _pn(e.kablo_yolu("GecitG", "PlakaZ")) == [[170, 584], [180, 480], [170, 376]]
		and BaglantiIslemleri.kayit(e._nesne("GecitG"), "PlakaZ", false)["uclar"] == [[170, 584], [170, 376]], str(_pn(e.kablo_yolu("GecitG", "PlakaZ"))))
	e.nesne_tasi("PlakaZ", Vector2(20, 0))
	_k7("B21: tetikleyici taşınınca o bağlantının 'uclar' alanı silinir, diğer kabloların uçları dokunulmaz",
		not BaglantiIslemleri.kayit(e._nesne("GecitG"), "PlakaZ", false).has("uclar")
		and BaglantiIslemleri.kayit(e._nesne("GecitG"), "PlakaM", false).has("uclar")
		and _pn(e.kablo_yolu("GecitG", "PlakaZ"))[0] == [200, 592], str(_pn(e.kablo_yolu("GecitG", "PlakaZ"))))
	e.ac(FIKSTUR + "b21.json")
	var meta_gecit: Array = _pn(e.onizleme_dugumu("GecitG").get_meta("kablo_2"))
	_k7("B21: açılan bölümde 2. kablo (kablo_2) ara noktalarıyla önizleme meta'sına yazılır",
		meta_gecit == [[110, 372], [125, 372], [125, 300], [160, 300]], str(meta_gecit))
	var b21_sorun: int = _n(BolumDenetci.statik(e.veri), "D3", "HATA") + _n(BolumDenetci.statik(e.veri), "D2", "HATA")
	_k7("B21: editörde açılınca D2/D3 hatası yok ve 5 bağlantı listelenir", b21_sorun == 0 and BaglantiIslemleri.baglantilar(e.veri).size() == 5,
		"D2+D3=%d bağlantı=%d" % [b21_sorun, BaglantiIslemleri.baglantilar(e.veri).size()])

	# --- JSON sırası: hedef tetikleyiciden önce gelen dosya hatasız kurulur
	var ters: Dictionary = BolumVerisi.bos("Ters Sira", "ters_001")
	ters["nesneler"] = [
		{"tur": "blok", "id": "Z", "alan": [0, 600, 1152, 48]},
		{"tur": "gecit", "id": "G", "konum": [500, 600], "tetikleyiciler": ["P"]},
		{"tur": "plaka", "id": "P", "konum": [200, 600]}]
	_metin_yaz(KOK + "ters.json", BolumVerisi.kanonik_metin(ters))
	e.ac(KOK + "ters.json")
	var sirali: bool = e.onizleme.get_child_count() == 3 and e.onizleme.get_child(0).name == "Z" and e.onizleme.get_child(1).name == "G" and e.onizleme.get_child(2).name == "P"
	_k7("hedefi tetikleyiciden önce yazılmış dosya önizlemede çözülür, çizim sırası JSON sırasıdır",
		sirali and e.onizleme_dugumu("G") != null and e.onizleme_dugumu("G").tetikleyici_yollari.size() == 1, "çocuk=%d" % e.onizleme.get_child_count())
	e.nesne_sil("P")
	e._nesne("G")["tetikleyiciler"] = ["YOK"]
	e._onizlemeyi_kur()
	_k7("eksik tetikleyiciye giden yol önizlemede atlanır (düğüm kurulur, yol çözülmeye çalışılmaz)",
		e.onizleme_dugumu("G") != null and e.onizleme_dugumu("G").tetikleyici_yollari.is_empty(), "")

	# --- fare akışı
	e.yeni()
	_gecerli(e, "Fare Akisi")
	e.arac_sec("plaka")
	e._fare_bas(Vector2(203, 598), false)
	e._fare_birak(Vector2(203, 598), false)
	e.arac_sec("gecit")
	e._fare_bas(Vector2(502, 601), false)
	e._fare_birak(Vector2(502, 601), false)
	e.arac_sec("asansor")
	e._fare_bas(Vector2(700, 500), false)
	e._fare_birak(Vector2(700, 500), false)
	_k7("fare: Plaka/Geçit/Asansör araçları tıklanan yere (ızgaraya oturarak) nesne ekler ve seçer",
		e._nesne("Plaka1")["konum"] == [200, 600] and e._nesne("Gecit1")["konum"] == [500, 600] and e._nesne("Asansor1")["konum"] == [700, 500] and e.secili == "Asansor1", JSON.stringify(e.veri["nesneler"].slice(1)))
	e.arac_sec("bagla")
	e._fare_bas(Vector2(200, 592), false)
	var kaynak_ok: bool = e.bagla_kaynak == "Plaka1"
	e._fare_bas(Vector2(500, 500), false)
	_k7("fare: Bağla aracı önce tetikleyiciye sonra hedefe tıklanınca bağlar", kaynak_ok and e.bagla_kaynak == "" and e._nesne("Gecit1")["tetikleyiciler"] == ["Plaka1"], JSON.stringify(e._nesne("Gecit1")))
	e._fare_bas(Vector2(200, 592), false)
	var kaynak_var: bool = e.bagla_kaynak == "Plaka1"
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	vp.push_input(esc)
	await r.process_frame
	_k7("fare: Esc bağlama işlemini iptal eder", kaynak_var and e.bagla_kaynak == "" and e._nesne("Gecit1")["tetikleyiciler"] == ["Plaka1"], "")
	e.arac_sec("sec")
	e.sec("Plaka1")
	var b_tusu := InputEventKey.new()
	b_tusu.keycode = KEY_B
	b_tusu.pressed = true
	vp.push_input(b_tusu)
	await r.process_frame
	_k7("B tuşu: seçili tetikleyiciyle Bağla aracını başlatır", e.arac == "bagla" and e.bagla_kaynak == "Plaka1", "arac=%s kaynak=%s" % [e.arac, e.bagla_kaynak])
	e.arac_sec("sec")

	# --- fare ile kablo sürükleme
	var gecmis0: int = e.gecmis.size()
	e._fare_bas(Vector2(200, 540), false)
	var secili_ok: bool = e.secili_kablo == ["Gecit1", "Plaka1"] and not e.kablo_sifirla_dugmesi.disabled
	e._fare_hareket(Vector2(260, 540), false)
	e._fare_hareket(Vector2(340, 520), false)
	e._fare_birak(Vector2(340, 520), false)
	_k7("fare: kablo parçasından sürüklemek yeni ara nokta doğurur ve ızgaraya oturtur; tek geçmiş kaydı",
		secili_ok and _ara(e, "Gecit1", "Plaka1") == [[340, 520], [200, 500]] and e.gecmis.size() == gecmis0 + 1,
		"%s geçmiş %d->%d" % [JSON.stringify(_ara(e, "Gecit1", "Plaka1")), gecmis0, e.gecmis.size()])
	_k7("fare: sürüklenen kablo önizleme meta'sına yansır", _pn(e.onizleme_dugumu("Gecit1").get_meta("kablo")) == _pn(e.kablo_yolu("Gecit1", "Plaka1")), "")
	e._fare_bas(Vector2(342, 521), false)
	e._fare_hareket(Vector2(380, 560), false)
	e._fare_birak(Vector2(380, 560), false)
	_k7("fare: var olan ara noktaya basıp sürüklemek onu taşır (nokta sayısı aynı)",
		_ara(e, "Gecit1", "Plaka1") == [[380, 560], [200, 500]], JSON.stringify(_ara(e, "Gecit1", "Plaka1")))
	e._fare_bas(Vector2(381, 561), false, true)
	e._fare_birak(Vector2(381, 561), false)
	_k7("fare: ara noktaya çift tıklamak onu siler", _ara(e, "Gecit1", "Plaka1") == [[200, 500]], JSON.stringify(_ara(e, "Gecit1", "Plaka1")))
	e.kablo_gizle_degistir()
	_k7("düğmeler: seçili kablo gizlenince 'Kabloyu göster' yazar",
		e.kablo_gizle_dugmesi.text == "Kabloyu göster" and BaglantiIslemleri.gizli_mi(e.veri, "Gecit1", "Plaka1"), e.kablo_gizle_dugmesi.text)
	e.kablo_gizle_dugmesi.pressed.emit()
	e.kablo_sifirla_dugmesi.pressed.emit()
	_k7("düğmeler: Kabloyu göster ve Kabloyu sıfırla basılınca kayıt tamamen temizlenir",
		not e._nesne("Gecit1").has("kablolar") and not e.kablo_gizle_dugmesi.disabled, JSON.stringify(e._nesne("Gecit1")))
	e.sec("Plaka1")
	_k7("nesne seçilince kablo seçimi kalkar, düğmeler pasif", e.secili_kablo.is_empty() and e.kablo_sifirla_dugmesi.disabled and e.kablo_gizle_dugmesi.disabled, "")

	# --- tutamaklar
	e.sec("Asansor1")
	var tut: Vector2 = e.parametre_tutamaci("Asansor1")
	e._fare_bas(tut, false)
	e._fare_hareket(Vector2(700, 380), false)
	e._fare_birak(Vector2(700, 380), false)
	_k7("asansör üst tutamacı sürüklenince yükseklik değişir (500 - 380 = 120)", e._nesne("Asansor1")["yukseklik"] == 120 and e.onizleme_dugumu("Asansor1").yukseklik == 120.0,
		"%s tutamak=%s" % [JSON.stringify(e._nesne("Asansor1")), tut])
	_k7("parametre_ata: asansör 20..600, geçit 10..200 aralığına kıstırılır",
		e.parametre_ata("Asansor1", 5) and e._nesne("Asansor1")["yukseklik"] == 20 and e.parametre_ata("Asansor1", 9999) and e._nesne("Asansor1")["yukseklik"] == 600
		and e.parametre_ata("Gecit1", 500) and e._nesne("Gecit1")["kayma_mesafe"] == 200 and e.parametre_ata("Gecit1", 0) and e._nesne("Gecit1")["kayma_mesafe"] == 10
		and not e.parametre_ata("Plaka1", 50), "")
	e.parametre_ata("Gecit1", 100)
	e.parametre_ata("Asansor1", 180)

	# --- gözden geçirici sonrası: tek tık, L köşesi, bozuk L, bağla geri al
	e.arac_sec("sec")
	e.sec("")
	var onc_k: String = BolumVerisi.kanonik_metin(e.veri)
	var g_k: int = e.gecmis.size()
	e._fare_bas(Vector2(200, 540), false)
	e._fare_birak(Vector2(200, 540), false)
	_k7("fare: kabloya tek tık yalnız seçer (veri ve geçmiş değişmez)",
		e.secili_kablo == ["Gecit1", "Plaka1"] and BolumVerisi.kanonik_metin(e.veri) == onc_k and e.gecmis.size() == g_k, JSON.stringify(e._nesne("Gecit1")))
	e._fare_bas(Vector2(202, 501), false)
	e._fare_hareket(Vector2(240, 480), false)
	e._fare_birak(Vector2(240, 480), false)
	_k7("fare: otomatik L köşesi tutulup sürüklenebilir (köşe ara noktaya dönüşür)", _ara(e, "Gecit1", "Plaka1") == [[240, 480]], JSON.stringify(_ara(e, "Gecit1", "Plaka1")))
	e.kablo_sifirla()
	e._fare_bas(Vector2(200, 500), false, true)
	e._fare_birak(Vector2(200, 500), false)
	_k7("fare: otomatik L köşesine çift tık köşeyi siler, kayıt artığı kalmaz, hata yok",
		_ara(e, "Gecit1", "Plaka1").is_empty() and not e._nesne("Gecit1").has("kablolar") and _pn(e.kablo_yolu("Gecit1", "Plaka1")).size() == 3, JSON.stringify(e._nesne("Gecit1")))
	e.izgara_ac_kapa(false)
	var p_bozuk: String = e.nesne_ekle("plaka", Vector2(400, 508))
	e.bagla(p_bozuk, "Gecit1")
	var yol_bozuk: Array = _pn(e.kablo_yolu("Gecit1", p_bozuk))
	var i_bozuk: int = e.ara_nokta_ekle("Gecit1", p_bozuk, Vector2(450, 500))
	_k7("bozuk L (tetikleyici ve hedef aynı y): ara nokta eklenir, sıra geçerli, hata/artık yok",
		yol_bozuk.size() == 3 and i_bozuk == 0 and _ara(e, "Gecit1", p_bozuk) == [[450, 500]], "yol=%s i=%d ara=%s" % [yol_bozuk, i_bozuk, JSON.stringify(_ara(e, "Gecit1", p_bozuk))])
	e.nesne_sil(p_bozuk)
	e.izgara_ac_kapa(true)
	e.bagla("Plaka1", "Asansor1")
	e.geri_al()
	var bag_geri: bool = not e._nesne("Asansor1").has("plaka")
	e.yinele()
	_k7("bagla geri al/yinele: veri ve önizlemedeki asansör plaka referansı tutarlı",
		bag_geri and e._nesne("Asansor1")["plaka"] == "Plaka1" and e.onizleme_dugumu("Asansor1").get("plaka") == e.onizleme_dugumu("Plaka1"), "")
	e.geri_al()
	var dolu: Dictionary = BolumVerisi.bos("Dolu", "dolu_001")
	for i in BolumVerisi.AZAMI_NESNE:
		dolu["nesneler"].append({"tur": "blok", "id": "B%d" % i, "alan": [0, 0, 10, 10]})
	var e_veri: Dictionary = e.veri
	e.veri = dolu
	_k7("nesne_ekle: nesne sınırı dolunca reddedilir", e.nesne_ekle("plaka", Vector2(10, 10)) == "", "")
	e.veri = e_veri

	# --- dosyaya yaz, aç, gerçek sahnede bağlantılar
	e.bagla("Plaka1", "Asansor1")
	e.ara_nokta_ekle("Gecit1", "Plaka1", Vector2(200, 540))
	e.ad_ata("Fare Akisi")
	_k7("kaydet/aç: bağlantılar ve ara noktalar JSON'dan geri gelir, şema sorunu yok",
		e.kaydet() == OK and (e.ac(e.son_yol) as Array).is_empty() and e._nesne("Asansor1")["plaka"] == "Plaka1"
		and _ara(e, "Gecit1", "Plaka1") == [[200, 540], [200, 500]], "")
	var kok_d: Node = _kur_diskten(e.veri)
	var gd: Node = kok_d.get_node_or_null("Gecit1")
	var ad_d: Node = kok_d.get_node_or_null("Asansor1")
	_k7("kurulan sahne: geçit tetikleyici yolu ve asansör plaka referansı gerçek düğümleri bulur, kablo meta'sı diskte saklı",
		gd != null and gd.tetikleyici_yollari == [NodePath("../Plaka1")] and ad_d != null and ad_d.plaka == kok_d.get_node("Plaka1")
		and gd.has_meta("kablo") and _pn(gd.get_meta("kablo")) == [[200, 592], [200, 540], [200, 500], [500, 500]], "")
	kok_d.free()

	# --- hedef taşınınca uclar silinir; yalnız uclar taşıyan kayıt artık bırakmaz
	e.ac(FIKSTUR + "b21.json")
	e.nesne_tasi("GecitG", Vector2(20, 0))
	_k7("B21: hedef (geçit) taşınınca bağlantılarının 'uclar' alanları silinir, başka hedefinkiler kalır",
		not BaglantiIslemleri.kayit(e._nesne("GecitG"), "PlakaZ", false).has("uclar") and not BaglantiIslemleri.kayit(e._nesne("GecitG"), "PlakaM", false).has("uclar")
		and BaglantiIslemleri.kayit(e._nesne("GecitM"), "PlakaM", false).has("uclar"), "")
	var yalniz: Dictionary = {"nesneler": [{"tur": "plaka", "id": "P", "konum": [100, 100]},
		{"tur": "gecit", "id": "G", "konum": [200, 100], "tetikleyiciler": ["P"], "kablolar": [{"tetik": "P", "uclar": [[1, 1], [2, 2]]}]}]}
	BaglantiIslemleri.uclari_sil(yalniz, "P")
	_k7("uclari_sil: yalnız 'uclar' taşıyan kayıt tamamen silinir", not yalniz["nesneler"][1].has("kablolar"), JSON.stringify(yalniz["nesneler"][1]))

	r.paused = false
	_dizin_sil(KOK)
	_k7("A7 testleri sonunda user://test_editor/ silindi", DirAccess.open(KOK) == null, "")


# ================================================================ A8: kalan türler, özellik paneli, lazer ucu

func _k8(ad: String, ok: bool, ayr: String) -> void:
	_kaydi("Editör A8: " + ad, ok, ayr)


func a8_testleri() -> void:
	r.paused = false
	_dizin_sil(KOK)
	var e: Node = await _ed()

	# --- palet ve yerleştirme
	var yeni_turler: Array = ["plaka", "zamanli_plaka", "mandal_plaka", "salter", "gecit", "asansor", "lazer", "kutu", "ziplatici", "bant", "tek_yonlu"]
	var palet_tam: bool = e.arac_dugmeleri.size() == 16
	for tur in yeni_turler:
		palet_tam = palet_tam and e.arac_dugmeleri.has(tur) and e.yerlesen_turler.has(tur)
	_k8("palet: 16 araç düğmesi, 11 tür tek tıkla yerleşir", palet_tam, str(e.arac_dugmeleri.size()))

	_gecerli(e, "A8 Denemesi")
	var beklenen: Array = ["Plaka1", "ZamanliPlaka1", "MandalPlaka1", "Salter1", "Gecit1", "Asansor1", "Lazer1", "Kutu1", "Ziplatici1", "Bant1", "TekYonlu1"]
	var idler: Array = []
	var x := 80
	for tur in yeni_turler:
		idler.append(e.nesne_ekle(tur, Vector2(x, 400)))
		x += 90
	var dugumler_tamam := true
	for id in idler:
		dugumler_tamam = dugumler_tamam and e.onizleme_dugumu(id) != null
	_k8("nesne_ekle: 11 tür beklenen kimliklerle eklenir ve önizlemede düğümü vardır", idler == beklenen and dugumler_tamam, str(idler))
	_k8("ikinci lazer Lazer2 olur, aynı kimlik verilmez", e.nesne_ekle("lazer", Vector2(300, 300)) == "Lazer2", "")
	e.nesne_sil("Lazer2")

	var z: Dictionary = e._nesne("ZamanliPlaka1")
	var s: Dictionary = e._nesne("Salter1")
	var la: Dictionary = e._nesne("Lazer1")
	var b: Dictionary = e._nesne("Bant1")
	_k8("varsayılan alanlar: tutma 180, şalter solda, bant +1, lazer aşağı/200/varsayılan bayraklar",
		int(z["tutma_kare"]) == 180 and s["baslangic_sagda"] == false and int(b["yon"]) == 1
		and la["yon"] == "asagi" and int(la["uzunluk"]) == 200 and la["tetikleyiciler"] == [] and la["tetik_aktifken_kapali"] == true and la["acik_taraf_sag"] == true,
		JSON.stringify(la))
	e.bagla("Plaka1", "Asansor1")   # asansörün plakası zorunlu (D3)
	var kay_h: Error = e.kaydet()
	var kay_sorun: Array = e.ac(e.son_yol)
	_k8("yeni bölüm şemaya uyar: kaydet/aç sorunsuz", kay_h == OK and kay_sorun.is_empty(), str(kay_h) + " " + JSON.stringify(kay_sorun))

	# --- fareyle yerleştirme (her araç seçilip tıklanır)
	_gecerli(e, "A8 Fare")
	var fare_tamam := true
	var fx := 100
	for tur in yeni_turler:
		e.arac_sec(tur)
		e._fare_bas(Vector2(fx, 300), false)
		fare_tamam = fare_tamam and e.secili != "" and str(e._nesne(e.secili)["tur"]) == tur and e.arac == tur
		fx += 80
	_k8("fare: her tür seçilip tıklanınca yerleşir ve seçilir", fare_tamam and e.veri["nesneler"].size() == 12, str(e.veri["nesneler"].size()))
	e.arac_sec("sec")

	# --- ozellik_ata
	_gecerli(e, "A8 Ozellik")
	for tur in yeni_turler:
		e.nesne_ekle(tur, Vector2(100 + 80 * yeni_turler.find(tur), 400))
	var gecmis0: int = e.gecmis.size()
	var bant_yazildi: bool = e.ozellik_ata("Bant1", "yon", -1)
	var bant_tekrar: bool = e.ozellik_ata("Bant1", "yon", -1)
	_k8("ozellik_ata: bant yönü -1 yazılır, aynı değer tekrar değişiklik sayılmaz",
		bant_yazildi and int(e._nesne("Bant1")["yon"]) == -1 and not bant_tekrar and e.gecmis.size() == gecmis0 + 1, "")
	_k8("ozellik_ata: bant yönü 2 reddedilir", not e.ozellik_ata("Bant1", "yon", 2) and int(e._nesne("Bant1")["yon"]) == -1, "")
	var t0: bool = e.ozellik_ata("ZamanliPlaka1", "tutma_kare", 0)
	var t0_deger: int = int(e._nesne("ZamanliPlaka1")["tutma_kare"])
	var t9: bool = e.ozellik_ata("ZamanliPlaka1", "tutma_kare", 9999)
	_k8("ozellik_ata: tutma_kare 1..600'e kıstırılır (0 -> 1, 9999 -> 600)", t0 and t0_deger == 1 and t9 and int(e._nesne("ZamanliPlaka1")["tutma_kare"]) == 600, "")
	var sag_ok: bool = e.ozellik_ata("Salter1", "baslangic_sagda", true)
	_k8("ozellik_ata: şalter başlangıç tarafı bool, sayı reddedilir",
		sag_ok and e._nesne("Salter1")["baslangic_sagda"] == true and not e.ozellik_ata("Salter1", "baslangic_sagda", 1), "")
	var l1: bool = e.ozellik_ata("Lazer1", "yon", "sol")
	var l2: bool = e.ozellik_ata("Lazer1", "uzunluk", 350)
	var l3: bool = e.ozellik_ata("Lazer1", "tetik_aktifken_kapali", false)
	var l4: bool = e.ozellik_ata("Lazer1", "acik_taraf_sag", false)
	var l5: bool = e.ozellik_ata("Lazer1", "yon", "capraz")
	var l6: bool = e.ozellik_ata("Lazer1", "uzunluk", "uzun")
	_k8("ozellik_ata: lazer yön/uzunluk/bayraklar yazılır; bilinmeyen yön ve metin uzunluk reddedilir",
		l1 and l2 and l3 and l4 and not l5 and not l6 and e._nesne("Lazer1")["yon"] == "sol" and int(e._nesne("Lazer1")["uzunluk"]) == 350, JSON.stringify(e._nesne("Lazer1")))
	var g1: bool = e.ozellik_ata("Gecit1", "acik_taraf_sag", false)
	_k8("ozellik_ata: geçit açık tarafı yazılır; türle uyumsuz alan ve bilinmeyen nesne reddedilir",
		g1 and not e.ozellik_ata("Plaka1", "uzunluk", 50) and not e.ozellik_ata("Kutu1", "yon", 1) and not e.ozellik_ata("YOK", "yon", 1), "")
	var u5: bool = e.ozellik_ata("Lazer1", "uzunluk", 5)
	var u5_deger: int = int(e._nesne("Lazer1")["uzunluk"])
	var u50: bool = e.ozellik_ata("Lazer1", "uzunluk", 5000)
	_k8("ozellik_ata: lazer uzunluğu 10..1100'e kıstırılır", u5 and u5_deger == 10 and u50 and int(e._nesne("Lazer1")["uzunluk"]) == 1100, "")
	e.ozellik_ata("Lazer1", "uzunluk", 350)
	var sonra: String = BolumVerisi.kanonik_metin(e.veri)
	e.geri_al()
	var geri: bool = int(e._nesne("Lazer1")["uzunluk"]) == 1100
	e.yinele()
	_k8("geri al/yinele özellik değişikliğini taşır", geri and BolumVerisi.kanonik_metin(e.veri) == sonra, "")

	# --- gerçek düğümler: özellikler kurulan sahneye gider
	e.ozellik_ata("ZamanliPlaka1", "tutma_kare", 240)
	var kok_n: Node2D = BolumKurucu.kur(e.veri)
	var ln: Node = kok_n.get_node("Lazer1")
	_k8("kurulan sahne: lazer yön/uzunluk/bayraklar, zamanlı tutma, şalter tarafı, bant yönü, geçit tarafı yazılan alanlarla aynı",
		ln.get("yon") == Vector2(-1, 0) and float(ln.get("uzunluk")) == 350.0 and ln.get("tetik_aktifken_kapali") == false and ln.get("acik_taraf_sag") == false
		and int(kok_n.get_node("ZamanliPlaka1").get("tutma_kare")) == 240 and kok_n.get_node("Salter1").get("baslangic_sagda") == true
		and int(kok_n.get_node("Bant1").get("yon")) == -1 and kok_n.get_node("Gecit1").get("acik_taraf_sag") == false, "")
	_k8("kurulan sahne: mandal plaka mandal=true, kutu/zıplatıcı/tek yönlü sahne örneği olarak vardır",
		bool(kok_n.get_node("MandalPlaka1").get("mandal")) and kok_n.get_node_or_null("Kutu1") != null
		and kok_n.get_node_or_null("Ziplatici1") != null and kok_n.get_node_or_null("TekYonlu1") != null, "")
	kok_n.free()

	# --- özellik paneli
	e.sec("Bant1")
	var pnl: Control = e.ozellik_paneli
	var bant_dugme: Button = e.ozellik_satirlari["bant_yon"]["kontrol"]
	_k8("panel: bant seçilince görünür, yalnız bant satırı açık, düğme yönü gösterir (sola)",
		pnl.visible and e.ozellik_satirlari["bant_yon"]["satir"].visible and not e.ozellik_satirlari["uzunluk"]["satir"].visible
		and bant_dugme.text.contains("Sola"), bant_dugme.text)
	bant_dugme.pressed.emit()
	_k8("panel: bant düğmesi yönü çevirir (-1 -> +1)", int(e._nesne("Bant1")["yon"]) == 1 and bant_dugme.text.contains("Sağa"), bant_dugme.text)
	e.sec("Plaka1")
	_k8("panel: düzenlenecek alanı olmayan nesnede (plaka) gizlenir", not pnl.visible, "")
	e.sec("")
	_k8("panel: seçim yokken gizli", not pnl.visible, "")
	e.sec("ZamanliPlaka1")
	var sp: SpinBox = e.ozellik_satirlari["tutma_kare"]["kontrol"]
	var sp_ilk: int = int(sp.value)
	sp.value_changed.emit(300.0)
	_k8("panel: zamanlı plaka SpinBox'ı mevcut değeri gösterir ve değer girilince alanı yazar",
		pnl.visible and sp_ilk == 240 and int(e._nesne("ZamanliPlaka1")["tutma_kare"]) == 300 and int(sp.value) == 300, str(sp.value))
	e.sec("Lazer1")
	var yon_sec: OptionButton = e.ozellik_satirlari["lazer_yon"]["kontrol"]
	_k8("panel: lazer satırları (yön, uzunluk, iki bayrak) açık, yön seçici mevcut yönü gösterir",
		e.ozellik_satirlari["lazer_yon"]["satir"].visible and e.ozellik_satirlari["uzunluk"]["satir"].visible and e.ozellik_satirlari["tetik_aktifken_kapali"]["satir"].visible
		and e.ozellik_satirlari["lazer_acik_sag"]["satir"].visible and not e.ozellik_satirlari["acik_taraf_sag"]["satir"].visible and yon_sec.selected == BolumVerisi.LAZER_YONLERI.find("sol"), str(yon_sec.selected))
	yon_sec.item_selected.emit(1)
	_k8("panel: yön seçici lazer yönünü yazar (yukarı)", e._nesne("Lazer1")["yon"] == "yukari", str(e._nesne("Lazer1")["yon"]))
	var kapali_kutu: CheckBox = e.ozellik_satirlari["tetik_aktifken_kapali"]["kontrol"]
	kapali_kutu.toggled.emit(true)
	_k8("panel: onay kutusu bayrağı yazar", e._nesne("Lazer1")["tetik_aktifken_kapali"] == true, "")
	e.sec("Gecit1")
	_k8("panel: geçitte yalnız 'Şalter sağdayken açık' ve kayma mesafesi",
		e.ozellik_satirlari["acik_taraf_sag"]["satir"].visible and e.ozellik_satirlari["kayma_mesafe"]["satir"].visible and not e.ozellik_satirlari["uzunluk"]["satir"].visible, "")

	# kablo seçilince panel eşitlenir, düzenleme sessizce kaybolmaz
	e.nesne_ekle("plaka", Vector2(100, 600))
	e.bagla("Plaka1", "Gecit1")
	e.sec("Lazer1")
	var gorunur_once: bool = e.ozellik_paneli.visible
	e.kablo_sec("Gecit1", "Plaka1")
	_k8("kablo seçilince özellik paneli gizlenir (seçim boşalır)", gorunur_once and not e.ozellik_paneli.visible, "")
	e.sec("ZamanliPlaka1")
	e.ozellik_ata("ZamanliPlaka1", "tutma_kare", 77)
	e.geri_al()
	_k8("geri al sonrası panel SpinBox'ı verinin yeni değerini gösterir",
		int((e.ozellik_satirlari["tutma_kare"]["kontrol"] as SpinBox).value) == int(e._nesne("ZamanliPlaka1")["tutma_kare"]), "")
	e.yinele()
	_k8("yinele sonrası panel SpinBox'ı 77 gösterir", int((e.ozellik_satirlari["tutma_kare"]["kontrol"] as SpinBox).value) == 77, "")
	e.sec("Lazer1")
	e.arac_sec("sec")
	e._fare_bas(e.parametre_tutamaci("Lazer1"), false)
	e._fare_hareket(e.parametre_tutamaci("Lazer1") + Vector2(0, 100), false)
	var panel_uz: int = int((e.ozellik_satirlari["uzunluk"]["kontrol"] as SpinBox).value)
	e._fare_birak(Vector2.ZERO, false)
	_k8("lazer ucu sürüklenirken panel uzunluğu güncellenir", panel_uz == int(e._nesne("Lazer1")["uzunluk"]), str(panel_uz))

	# --- lazer ucu tutamağı (fare)
	_gecerli(e, "A8 Lazer Ucu")
	var lid: String = e.nesne_ekle("lazer", Vector2(400, 300))
	e.sec(lid)
	var tut: Vector2 = e.parametre_tutamaci(lid)
	_k8("lazer tutamağı ışının ucundadır (400,500)", tut == Vector2(400, 500), str(tut))
	e.arac_sec("sec")
	e._fare_bas(tut, false)
	e._fare_hareket(Vector2(620, 305), false)
	e._fare_birak(Vector2(620, 305), false)
	_k8("lazer ucunu yana sürüklemek yönü sağa, uzunluğu 220 yapar", e._nesne(lid)["yon"] == "sag" and int(e._nesne(lid)["uzunluk"]) == 220, JSON.stringify(e._nesne(lid)))
	var tut2: Vector2 = e.parametre_tutamaci(lid)
	e._fare_bas(tut2, false)
	e._fare_hareket(Vector2(420, 100), false)
	e._fare_birak(Vector2(420, 100), false)
	_k8("lazer ucunu yukarı sürüklemek yönü yukarı, uzunluğu 200 yapar", e._nesne(lid)["yon"] == "yukari" and int(e._nesne(lid)["uzunluk"]) == 200, JSON.stringify(e._nesne(lid)))
	var tut3: Vector2 = e.parametre_tutamaci(lid)
	e._fare_bas(tut3, false)
	e._fare_hareket(Vector2(400, 300), false)
	e._fare_birak(Vector2(400, 300), false)
	_k8("lazer ucu yayıcıya çekilince uzunluk en az 10 kalır", int(e._nesne(lid)["uzunluk"]) == 10, JSON.stringify(e._nesne(lid)))
	e.geri_al()
	_k8("tek sürükleme tek geri al adımıdır (son sürükleme geri alınınca 200)", int(e._nesne(lid)["uzunluk"]) == 200 and e._nesne(lid)["yon"] == "yukari", JSON.stringify(e._nesne(lid)))
	_k8("lazer yayıcı gövdesine tıklamak lazeri seçer (ışın 6 px incedir)", e.nesne_bul(Vector2(404, 296)) == lid and e.nesne_bul(Vector2(390, 310)) == lid, e.nesne_bul(Vector2(404, 296)))
	# yayıcı dalı: ışın yukarı gittiği için (390,310) ışının dışında, yalnız yayıcı kutusunda kalır
	_k8("ışının dışındaki yayıcı kutusu noktası ışın dikdörtgeninde değil", not e.secim_dikdortgeni(lid).grow(2.0).has_point(Vector2(390, 310)), "")
	_k8("olmayan nesnenin tutamağı yoktur", e.parametre_tutamaci("YOK") == Vector2.INF, "")

	# --- bağlantı: lazer ve şalter
	_gecerli(e, "A8 Baglanti")
	e.nesne_ekle("zamanli_plaka", Vector2(200, 600))
	e.nesne_ekle("mandal_plaka", Vector2(300, 600))
	e.nesne_ekle("salter", Vector2(400, 600))
	e.nesne_ekle("lazer", Vector2(600, 300))
	e.nesne_ekle("gecit", Vector2(700, 600))
	e.nesne_ekle("asansor", Vector2(800, 600))
	var c1: String = e.bagla("ZamanliPlaka1", "Lazer1")
	var c2: String = e.bagla("MandalPlaka1", "Lazer1")
	var c3: String = e.bagla("Salter1", "Lazer1")
	var c4: String = e.bagla("Salter1", "Gecit1")
	_k8("zamanlı plaka, mandal plaka, şalter lazere; şalter geçide bağlanır",
		c1 == "baglandi" and c2 == "baglandi" and c3 == "baglandi" and c4 == "baglandi"
		and e._nesne("Lazer1")["tetikleyiciler"] == ["ZamanliPlaka1", "MandalPlaka1", "Salter1"], str(e._nesne("Lazer1")))
	var c5: String = e.bagla("Salter1", "Asansor1")
	var c6: String = e.bagla("ZamanliPlaka1", "Asansor1")
	_k8("şalter asansöre bağlanamaz, zamanlı plaka asansöre bağlanır", c5 == "red" and c6 == "baglandi", c5 + " " + c6)
	var kok_b: Node2D = BolumKurucu.kur(e.veri)
	var lb: Node = kok_b.get_node("Lazer1")
	_k8("kurulan sahne: lazerin 3 tetikleyici yolu ve kablo / kablo_2 / kablo_3 meta'ları, asansörün plakası vardır",
		lb.get("tetikleyici_yollari").size() == 3 and lb.has_meta("kablo") and lb.has_meta("kablo_2") and lb.has_meta("kablo_3")
		and kok_b.get_node("Asansor1").get("plaka") == kok_b.get_node("ZamanliPlaka1"), "")
	kok_b.free()
	e.nesne_sil("Salter1")
	_k8("şalter silinince lazer ve geçitten referansı kalkar", e._nesne("Lazer1")["tetikleyiciler"] == ["ZamanliPlaka1", "MandalPlaka1"]
		and e._nesne("Gecit1")["tetikleyiciler"] == [], "")

	# --- taşıma ve silme
	e.nesne_ekle("kutu", Vector2(500, 600))
	e.nesne_ekle("ziplatici", Vector2(560, 600))
	e.nesne_ekle("tek_yonlu", Vector2(620, 500))
	e.nesne_tasi("Kutu1", Vector2(40, -20))
	e.nesne_tasi("Ziplatici1", Vector2(20, 0))
	e.nesne_tasi("TekYonlu1", Vector2(0, 20))
	_k8("kutu, zıplatıcı, tek yönlü taşınır, düğüm konumu çapayla uyumlu",
		e._nesne("Kutu1")["konum"] == [540, 580] and e._nesne("Ziplatici1")["konum"] == [580, 600] and e._nesne("TekYonlu1")["konum"] == [620, 520]
		and (e.onizleme_dugumu("Kutu1") as Node2D).position == BolumKurucu.nesne_konumu(e._nesne("Kutu1")), "")
	e.nesne_sil("Kutu1")
	e.nesne_sil("Ziplatici1")
	e.nesne_sil("TekYonlu1")
	_k8("üç tür silinince düğümleri kalkar", e.onizleme_dugumu("Kutu1") == null and e.onizleme_dugumu("Ziplatici1") == null and e.onizleme_dugumu("TekYonlu1") == null, "")

	# --- diske yaz / aç / sahnede özellikler
	e.ozellik_ata("ZamanliPlaka1", "tutma_kare", 90)
	e.ozellik_ata("Lazer1", "uzunluk", 420)
	e.ozellik_ata("Lazer1", "yon", "sag")
	e.ad_ata("A8 Kaydet")
	_k8("kaydet/aç: özellikler JSON'dan geri gelir, şema sorunu yok",
		e.kaydet() == OK and (e.ac(e.son_yol) as Array).is_empty() and int(e._nesne("ZamanliPlaka1")["tutma_kare"]) == 90
		and e._nesne("Lazer1")["yon"] == "sag" and int(e._nesne("Lazer1")["uzunluk"]) == 420, "")
	var kok_d: Node = _kur_diskten(e.veri)
	var dl: Node = kok_d.get_node_or_null("Lazer1")
	_k8("diske kurulan sahne: lazer 420 px sağa, zamanlı plaka 90 kare",
		dl != null and dl.get("yon") == Vector2(1, 0) and float(dl.get("uzunluk")) == 420.0 and int(kok_d.get_node("ZamanliPlaka1").get("tutma_kare")) == 90, "")
	kok_d.free()
	_k8("statik denetimde HATA yok (yeni türlerle dolu bölüm)", int(BolumDenetci.ozet(BolumDenetci.statik(e.veri))["hata"]) == 0,
		str(BolumDenetci.ozet(BolumDenetci.statik(e.veri))))

	r.paused = false
	_dizin_sil(KOK)
	_k8("A8 testleri sonunda user://test_editor/ silindi", DirAccess.open(KOK) == null, "")


# ================================================================ A9: Doğrula (ilerleme, iptal, dogrulama alanı)

func _k9(ad: String, ok: bool, ayr: String) -> void:
	_kaydi("Editör A9: " + ad, ok, ayr)


## Doğrulama bitip editör yeniden açılana kadar bekler; dönüş: yeni editör (null: zaman aşımı).
func _dogr_bekle(eski_id: int, azami: int) -> Node:
	for i in azami:
		await r.physics_frame
		var s: Node = r.current_scene
		if r.root.get_node_or_null("EditorDogrulama") == null and s != null and s.get_instance_id() != eski_id \
				and s.scene_file_path.ends_with("editor.tscn"):
			await r.process_frame
			await r.physics_frame
			return r.current_scene
	return null


## B1 fikstürü + verilen çözüm (açık kayıtlar kodlanarak yazılır); editöre yüklenir.
func _cozumlu_yukle(e: Node, turlar: Array, oyuncu: Array) -> void:
	var v: Dictionary = (_fikstur("b1.json")["veri"] as Dictionary).duplicate(true)
	var kodlu: Array = []
	for t in turlar:
		kodlu.append(BolumVerisi.kayit_kodla(t))
	v["cozum"] = {"turlar": kodlu, "oyuncu": BolumVerisi.kayit_kodla(oyuncu)}
	v.erase("dogrulama")
	e.kok = KOK   # doğrulayıcının açtığı editör varsayılan kökü (kullanıcı dizini) kullanır; teste çevir
	e.veri = v
	e.secili = ""
	e._gecmisi_sifirla()
	e._onizlemeyi_kur()
	e._arayuzu_esitle()
	e._durum_guncelle()
	e._temizi_isaretle()


func a9_testleri() -> void:
	r.paused = false
	_dizin_sil(KOK)
	r.call("_kayitlar").sifirla()
	EditorOturumu.temizle()
	var e: Node = await _ed()
	var dogru: Array = r.call("_dogru_kayit_betigi")
	var cozum: Array = r.call("_cozum_betigi")

	# --- engeller: statik HATA ve çözümsüzlük
	_k9("palette ve çubukta Doğrula düğmesi var", e.find_child("DogrulaDugmesi", true, false) != null, "")
	e.yeni()
	var h1: bool = e.dogrula_baslat()
	_k9("statik HATA'lı bölümde Doğrula başlamaz, mesaj verir, sahne değişmez", not h1 and e.durum_mesaji.contains("Doğrulanamadı") and r.current_scene == e
		and r.root.get_node_or_null("EditorDogrulama") == null, e.durum_mesaji)
	_gecerli(e)
	_k9("çözümsüz bölümde durum 'Taslak (çözüm yok)', Doğrula başlamaz",
		e.dogrulama_durumu() == "Taslak (çözüm yok)" and not e.dogrula_baslat() and e.durum_mesaji.contains("çözüm yok"), e.dogrulama_durumu())
	var dene_acik: bool = e.dene_baslat()
	_k9("çözümsüz bölümde Dene yine de açılır (S4)", dene_acik, "")
	if dene_acik:
		e = await _ed()

	# --- geçerli çözüm: doğrulandı
	_cozumlu_yukle(e, [dogru], cozum)
	_k9("çözüm yüklenince durum 'Taslak (doğrulanmadı)'", e.dogrulama_durumu() == "Taslak (doğrulanmadı)", e.dogrulama_durumu())
	var eski_id: int = e.get_instance_id()
	var basladi: bool = e.dogrula_baslat()
	var dd: Node = r.root.get_node_or_null("EditorDogrulama")
	_k9("Doğrula başlar: EditorDogrulama root altında, şerit ve İptal düğmesi var, oturum yazılı",
		basladi and dd != null and dd.get("serit") != null and dd.get("iptal_dugmesi") != null and EditorOturumu.donus, "")
	var serit_goruldu := false
	for i in 400:
		await r.physics_frame
		if dd == null or not is_instance_valid(dd):
			break
		var sr: ProgressBar = dd.get("serit")
		if sr != null and sr.max_value >= 6.0 and (dd.get("etiket") as Label).text.begins_with("Doğrulanıyor"):
			serit_goruldu = true
			break
	_k9("ilerleme şeridi adım sayısını (en az 6) ve açıklamayı gösterir", serit_goruldu, "")
	var e2: Node = await _dogr_bekle(eski_id, 20000)
	_k9("doğrulama bitince editör yeniden açılır, EditorDogrulama düğümü kalkar", e2 != null and r.root.get_node_or_null("EditorDogrulama") == null, "")
	if e2 == null:
		return
	e2.kok = KOK
	var dg: Dictionary = e2.veri.get("dogrulama", {})
	_k9("geçerli çözüm 'dogrulandi' olur: güncel içerik özeti, bitiş karesi > 0, hata 0",
		dg.get("durum", "") == "dogrulandi" and BolumVerisi.dogrulama_guncel_mi(e2.veri) and int(dg.get("bitis_kare", 0)) > 0 and int(dg.get("hata", -1)) == 0, JSON.stringify(dg))
	_k9("durum çubuğu metni 'Doğrulandı', mesaj 'Doğrulandı'", e2.dogrulama_durumu() == "Doğrulandı" and e2.durum_mesaji.begins_with("Doğrulandı")
		and e2.durum_etiketi.text.contains("Doğrulandı"), e2.durum_mesaji)
	_k9("oturum sonucu tüketildi, Kayitlar boş, çözüm korunur", EditorOturumu.dogrulama.is_empty() and r.call("_kayitlar").turlar.is_empty()
		and (e2.veri["cozum"]["oyuncu"] as Array).size() > 0 and not EditorOturumu.donus, "")
	var kok_k: Node2D = BolumKurucu.kur(e2.veri)
	_k9("doğrulanmış bölümün kurulan sahnesinde cozum_yok=false", kok_k.get_meta("cozum_yok") == false, "")
	kok_k.free()
	e2.blok_ekle([400, 500, 100, 20])
	_k9("içerik değişince durum 'Taslak (doğrulanmadı)' olur", e2.dogrulama_durumu() == "Taslak (doğrulanmadı)", e2.dogrulama_durumu())
	e2.geri_al()
	_k9("değişiklik geri alınınca özet yine tutar: 'Doğrulandı'", e2.dogrulama_durumu() == "Doğrulandı", e2.dogrulama_durumu())
	_k9("Kaydet/Aç: dogrulama alanı dosyada kalır ve güncel sayılır", e2.kaydet() == OK and (e2.ac(e2.son_yol) as Array).is_empty()
		and e2.dogrulama_durumu() == "Doğrulandı", e2.dogrulama_durumu())

	# --- başarısız doğrulama: taslak, Dene açık
	_cozumlu_yukle(e2, [], r.call("_betik", [[60, 0, false]]))
	var eski2: int = e2.get_instance_id()
	var ok2: bool = e2.dogrula_baslat()
	var e3: Node = await _dogr_bekle(eski2, 20000)
	if e3 == null:
		_k9("bitmeyen çözüm doğrulaması tamamlandı", false, "zaman aşımı")
		return
	e3.kok = KOK
	var dg3: Dictionary = e3.veri.get("dogrulama", {})
	_k9("çözüm bölümü bitirmiyorsa durum 'taslak', hata sayısı > 0, mesaj 'Taslak'",
		ok2 and dg3.get("durum", "") == "taslak" and int(dg3.get("hata", 0)) > 0 and e3.durum_mesaji.begins_with("Taslak")
		and e3.dogrulama_durumu() == "Taslak (doğrulanmadı)", JSON.stringify(dg3) + " | " + e3.durum_mesaji)
	var dene3: bool = e3.dene_baslat()
	_k9("başarısız doğrulamadan sonra Dene yine açılır (S4)", dene3, "")
	if dene3:
		e3 = await _ed()

	# --- iptal: hiçbir şey yazılmaz
	_cozumlu_yukle(e3, [dogru], cozum)
	e3.kok = KOK
	var ozet0: String = BolumVerisi.kanonik_metin(e3.veri)
	var eski3: int = e3.get_instance_id()
	e3.dogrula_baslat()
	var dd4: Node = r.root.get_node_or_null("EditorDogrulama")
	for i in 30:
		await r.physics_frame
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	if dd4 != null:
		dd4._input(esc)
	var e4: Node = await _dogr_bekle(eski3, 20000)
	if e4 == null:
		_k9("iptal edilen doğrulama tamamlandı", false, "zaman aşımı")
		return
	_k9("Esc ile iptal: dogrulama alanı yazılmaz, mesaj 'iptal', içerik aynı, çözüm duruyor",
		not e4.veri.has("dogrulama") and e4.durum_mesaji.contains("iptal") and BolumVerisi.kanonik_metin(e4.veri) == ozet0
		and e4.dogrulama_durumu() == "Taslak (doğrulanmadı)", e4.durum_mesaji)
	_k9("iptalde Kayitlar boşaltılır, oturum sonucu tüketilir", r.call("_kayitlar").turlar.is_empty() and EditorOturumu.dogrulama.is_empty(), "")
	# İptal düğmesi
	e4.kok = KOK
	var eski4: int = e4.get_instance_id()
	e4.dogrula_baslat()
	var dd5: Node = r.root.get_node_or_null("EditorDogrulama")
	for i in 30:
		await r.physics_frame
	if dd5 != null:
		(dd5.get("iptal_dugmesi") as Button).pressed.emit()
	var e5: Node = await _dogr_bekle(eski4, 20000)
	_k9("İptal düğmesi de iptal eder, hiçbir şey yazmaz", e5 != null and not e5.veri.has("dogrulama") and e5.durum_mesaji.contains("iptal"), "")

	# --- D10: eski kayıt aynı içerik ama farklı bitiş karesi -> taslak; ikinci doğrulamada kayıt yenilenir
	if e5 == null:
		return
	e5.kok = KOK
	_cozumlu_yukle(e5, [dogru], cozum)
	e5.veri["dogrulama"] = {"durum": "dogrulandi", "icerik_ozeti": BolumVerisi.icerik_ozeti(e5.veri), "bitis_kare": 1, "hata": 0, "uyari": 0}
	var eski5: int = e5.get_instance_id()
	e5.dogrula_baslat()
	var e6: Node = await _dogr_bekle(eski5, 20000)
	if e6 == null:
		_k9("D10 kayıt uyuşmazlığı doğrulaması tamamlandı", false, "zaman aşımı")
		return
	e6.kok = KOK
	var dg6: Dictionary = e6.veri.get("dogrulama", {})
	_k9("kayıtlı bitiş karesi ölçülenden farklıysa (D10) durum 'taslak', hata > 0",
		dg6.get("durum", "") == "taslak" and int(dg6.get("hata", 0)) > 0 and e6.dogrulama_durumu() == "Taslak (doğrulanmadı)", JSON.stringify(dg6))
	var eski6: int = e6.get_instance_id()
	e6.dogrula_baslat()
	var e7: Node = await _dogr_bekle(eski6, 20000)
	if e7 == null:
		_k9("ikinci doğrulama tamamlandı", false, "zaman aşımı")
		return
	e7.kok = KOK
	_k9("ikinci doğrulamada kayıt ölçülene eşitlenir ve 'dogrulandi' olur (kayıt yeniden temel alınır)",
		e7.veri["dogrulama"]["durum"] == "dogrulandi" and int(e7.veri["dogrulama"]["bitis_kare"]) == int(dg6.get("bitis_kare", -2)), JSON.stringify(e7.veri["dogrulama"]))

	# --- kayıtlıyken iptal: önceki 'dogrulandi' kaydı aynen kalır
	var onceki: Dictionary = (e7.veri["dogrulama"] as Dictionary).duplicate(true)
	var eski7: int = e7.get_instance_id()
	e7.dogrula_baslat()
	var cift: bool = e7.dogrula_baslat()
	_k9("doğrulama sürerken ikinci Doğrula ve Dene başlamaz", not cift and not e7.dene_baslat(), "")
	var dd8: Node = r.root.get_node_or_null("EditorDogrulama")
	if dd8 != null:
		dd8.iptal_et()   # hiç kare beklemeden: ilk iki karedeki iptal kaybolmamalı
	var kare_say := 0
	var e8: Node = null
	for i in 3000:
		await r.physics_frame
		kare_say += 1
		var sn: Node = r.current_scene
		if r.root.get_node_or_null("EditorDogrulama") == null and sn != null and sn.get_instance_id() != eski7 and sn.scene_file_path.ends_with("editor.tscn"):
			e8 = sn
			break
	await r.process_frame
	if e8 == null:
		_k9("erken iptal tamamlandı", false, "zaman aşımı")
		return
	_k9("başlar başlamaz iptal: tam doğrulama koşmaz (3000 kareden çok az), kayıtlı doğrulama aynen kalır",
		kare_say < 600 and e8.veri.get("dogrulama", {}) == onceki and e8.durum_mesaji.contains("iptal"), "kare=%d" % kare_say)

	EditorOturumu.temizle()
	r.paused = false
	_dizin_sil(KOK)
	_k9("A9 testleri sonunda user://test_editor/ silindi", DirAccess.open(KOK) == null, "")


# ================================================================ A10: Bölümlerim (liste, Aç, Oyna, Sil)

const BOLUMLERIM_SAHNESI := "res://scenes/bolumlerim.tscn"


func _k10(ad: String, ok: bool, ayr: String) -> void:
	_kaydi("Editör A10: " + ad, ok, ayr)


## Test kökü altına dört bölüm yazar: a_dogrulanmis, b_cozumsuz, c_hatali (statik HATA), d_bozuk (bozuk JSON).
func _a10_dosyalar(e: Node) -> void:
	var dogru: Array = r.call("_dogru_kayit_betigi")
	var cozum: Array = r.call("_cozum_betigi")
	_cozumlu_yukle(e, [dogru], cozum)
	e.veri["ad"] = "A Dogrulanmis"
	e._arayuzu_esitle()
	e.kimlik_kilitli = false
	e.kaydet()   # kimlik içeriğe girer: doğrulama özeti kimlik atandıktan sonra hesaplanmalı
	e.veri["dogrulama"] = {"durum": "dogrulandi", "icerik_ozeti": BolumVerisi.icerik_ozeti(e.veri), "hata": 0, "uyari": 0, "bitis_kare": 120}
	e.kaydet()
	_gecerli(e, "B Cozumsuz")
	e.kimlik_kilitli = false
	e.kaydet()
	e.yeni()
	e.ad_ata("C Hatali")
	e.kimlik_kilitli = false
	e.kaydet()
	_metin_yaz(BolumYollari.bolumler_dizini(KOK) + "d_bozuk.json", "{ bu json degil")
	# JSON geçerli ama şema HATA'lı: cozum.oyuncu dizi değil (liste bunu betik hatası vermeden "Bozuk" göstermeli).
	var sema: Dictionary = (_fikstur("b1.json")["veri"] as Dictionary).duplicate(true)
	sema["ad"] = "E Sema Hatali"
	sema["kimlik"] = "e_sema_001"
	sema["cozum"] = {"turlar": [], "oyuncu": "x"}
	_metin_yaz(BolumYollari.bolumler_dizini(KOK) + "e_sema_001.json", JSON.stringify(sema))


func a10_testleri() -> void:
	r.paused = false
	_dizin_sil(KOK)
	r.call("_kayitlar").sifirla()
	EditorOturumu.temizle()
	var e: Node = await _ed()

	# --- saf yardımcılar: ev sahnesi ve HUD başlığı
	_k10("ev_sahnesi: resmî → ana menü, dene → editör, özel → Bölümlerim",
		BolumYollari.ev_sahnesi("res://scenes/bolumler/bolum_1.tscn") == BolumYollari.MENU_SAHNESI
		and BolumYollari.ev_sahnesi("user://editor/dene_001.tscn") == BolumYollari.EDITOR_SAHNESI
		and BolumYollari.ev_sahnesi("user://oyna/oyna_001.tscn") == BolumYollari.BOLUMLERIM_SAHNESI
		and BolumYollari.ev_sahnesi("user://test_editor/oyna/oyna_007.tscn") == BolumYollari.BOLUMLERIM_SAHNESI, "")
	_k10("özel olmayan user:// yolları ve oyna_ öneki taşımayan dosya özel sayılmaz",
		not BolumYollari.ozel_mi("user://oyna/baska.tscn") and not BolumYollari.ozel_mi("user://editor/oyna_001.tscn")
		and not BolumYollari.ozel_mi("res://scenes/bolumler/bolum_1.tscn"), "")

	# --- boş liste
	EditorOturumu.kok = KOK   # Bölümlerim açılışta kullanıcı dizinini taramasın
	var bo: Node = await r.call("_ar_sahne_yukle", BOLUMLERIM_SAHNESI)
	bo.kok = KOK
	bo.yenile()
	_k10("kayıtlı bölüm yokken liste boş, 'Bos' etiketi görünür", bo.kayitlar.is_empty() and bo.liste_kutusu.get_node_or_null("Bos") != null, "")

	# --- dosyaları yaz, listele
	e = await _ed()
	_a10_dosyalar(e)
	EditorOturumu.kok = KOK
	var bl: Node = await r.call("_ar_sahne_yukle", BOLUMLERIM_SAHNESI)
	bl.kok = KOK
	bl.yenile()
	var adlar: Array = []
	for k in bl.kayitlar:
		adlar.append(k["dosya"])
	_k10("liste dosya adına göre sıralı ve deterministik (5 satır)", adlar.size() == 5 and adlar == _sirali(adlar)
		and String(adlar[0]).begins_with("a_") and String(adlar[1]).begins_with("b_") and String(adlar[2]).begins_with("c_") and adlar[3] == "d_bozuk.json" and adlar[4] == "e_sema_001.json", str(adlar))
	var s_a: Dictionary = bl.kayitlar[0]
	var s_b: Dictionary = bl.kayitlar[1]
	var s_c: Dictionary = bl.kayitlar[2]
	var s_d: Dictionary = bl.kayitlar[3]
	var s_e: Dictionary = bl.kayitlar[4]
	_k10("JSON geçerli ama şema HATA'lı dosya: Bozuk, oynanamaz, mesaj dolu, betik hatası yok",
		s_e["bozuk"] == true and s_e["durum"] == "Bozuk" and s_e["oynanabilir"] == false and str(s_e["hata_metni"]) != "" and not bl.ac(s_e["dosya"]) and not bl.oyna(s_e["dosya"]),
		str(s_e["hata_metni"]))
	_k10("durum göstergeleri: Doğrulandı / Taslak (çözüm yok) / bozuk",
		s_a["durum"] == "Doğrulandı" and s_b["durum"] == "Taslak (çözüm yok)" and s_d["durum"] == "Bozuk" and s_d["bozuk"] == true,
		"%s | %s | %s" % [s_a["durum"], s_b["durum"], s_d["durum"]])
	_k10("oynanabilirlik: doğrulanmış ve çözümsüz oynanır, statik HATA'lı ve bozuk oynanmaz",
		s_a["oynanabilir"] == true and s_b["oynanabilir"] == true and s_c["oynanabilir"] == false and s_c["hata"] > 0 and s_d["oynanabilir"] == false,
		"%s %s %s %s" % [s_a["oynanabilir"], s_b["oynanabilir"], s_c["oynanabilir"], s_d["oynanabilir"]])
	_k10("satır metni ad, durum ve hata sayısını içerir",
		Bolumlerim.satir_metni(s_a).contains("A Dogrulanmis") and Bolumlerim.satir_metni(s_a).contains("Doğrulandı")
		and Bolumlerim.satir_metni(s_c).contains("hata") and Bolumlerim.satir_metni(s_d).contains("Bozuk"), Bolumlerim.satir_metni(s_c))
	var satir_dugumu: Node = bl.liste_kutusu.get_child(2)
	_k10("ekran: 5 satır; hatalı bölümde Oyna kapalı, Aç açık; bozukta Aç ve Oyna kapalı, Sil açık",
		bl.liste_kutusu.get_child_count() == 5 and (satir_dugumu.get_node("OynaDugmesi") as Button).disabled and not (satir_dugumu.get_node("AcDugmesi") as Button).disabled
		and (bl.liste_kutusu.get_child(3).get_node("AcDugmesi") as Button).disabled and (bl.liste_kutusu.get_child(3).get_node("OynaDugmesi") as Button).disabled
		and not (bl.liste_kutusu.get_child(3).get_node("SilDugmesi") as Button).disabled, "")

	# --- statik HATA'lı ve bozuk bölüm oynanmaz / açılmaz
	var h_oyna: bool = bl.oyna(s_c["dosya"])
	_k10("statik HATA'lı bölüm oynanmaz: false, mesaj 'Oynanamaz', sahne değişmez, oyna/ dizini yok",
		not h_oyna and bl.durum_mesaji.contains("Oynanamaz") and r.current_scene == bl and DirAccess.open(BolumYollari.oyna_dizini(KOK)) == null, bl.durum_mesaji)
	_k10("bozuk dosya açılmaz: false, mesaj 'Açılamadı'", not bl.ac(s_d["dosya"]) and bl.durum_mesaji.contains("Açılamadı") and r.current_scene == bl, bl.durum_mesaji)

	# --- Oyna: çözümsüz bölüm uyarıyla oynanır, HUD "Özel · Ad"
	var id_bl: int = bl.get_instance_id()
	var h_b: bool = bl.oyna(s_b["dosya"])
	var oyna_s: Node = await _sahne_bekle(id_bl)
	var yol_b: String = oyna_s.scene_file_path if oyna_s != null else ""
	_k10("Oyna: çözümsüz bölüm açılır (S4); oyna/oyna_N.tscn, kip 'ozel'",
		h_b and oyna_s != null and yol_b.begins_with(KOK + "oyna/oyna_") and BolumYollari.ozel_mi(yol_b) and not BolumYollari.dene_mi(yol_b), yol_b)
	var etiket: Label = oyna_s.get_node_or_null("BolumKatmani/BolumEtiketi") as Label if oyna_s != null else null
	_k10("HUD başlığı 'Özel · Ad'", etiket != null and etiket.text == "Özel · B Cozumsuz" and BolumListesi.baslik(yol_b) == "Özel · B Cozumsuz",
		"etiket='%s'" % (etiket.text if etiket != null else "yok"))
	var hud: Node = oyna_s.get_node_or_null("EditorHud") if oyna_s != null else null
	_k10("çözümsüz özel bölümde amber uyarı satırı var", hud != null and hud.get("uyari") != null and (hud.get("uyari") as Label).text == EditorHud.UYARI_METNI, "")
	var sonuc: Node = await _sonuc_ac(oyna_s)
	_k10("özel bölüm sonuç ekranı: Sonraki gizli, Menü düğmesi 'Bölümlerim'e dön', Çözümü kaydet yok",
		sonuc != null and sonuc.get("ozel_kipi") == true and not sonuc.sonraki_dugmesi.visible and sonuc.menu_dugmesi.text == "Bölümlerim'e dön" and sonuc.get("cozum_dugmesi") == null, "")
	r.paused = false
	var id_o: int = oyna_s.get_instance_id()
	sonuc.menu_dugmesi.pressed.emit()
	var bl2: Node = await _sahne_bekle(id_o)
	_k10("sonuç ekranı Menü → Bölümlerim açılır, aynı kök okunur, liste 5 satır",
		bl2 != null and bl2.scene_file_path.ends_with("bolumlerim.tscn") and bl2.kok == KOK and bl2.kayitlar.size() == 5 and r.call("_kayitlar").turlar.is_empty(),
		bl2.scene_file_path if bl2 != null else "yok")

	# --- ev butonu özel bölümde Bölümlerim'e götürür; doğrulanmış bölümde uyarı satırı yok
	var id_b2: int = bl2.get_instance_id()
	bl2.oyna(bl2.kayitlar[0]["dosya"])
	var oyna_a: Node = await _sahne_bekle(id_b2)
	var hud_a: Node = oyna_a.get_node_or_null("EditorHud") if oyna_a != null else null
	_k10("doğrulanmış özel bölümde uyarı satırı yok; HUD 'Özel · A Dogrulanmis'",
		oyna_a != null and hud_a != null and hud_a.get("uyari") == null and BolumListesi.baslik(oyna_a.scene_file_path) == "Özel · A Dogrulanmis", "")
	var id_a: int = oyna_a.get_instance_id()
	oyna_a.butonlar.ev_dugmesi.pressed.emit()
	var bl3: Node = await _sahne_bekle(id_a)
	_k10("ev butonu: özel bölümden Bölümlerim'e döner, Kayitlar boş",
		bl3 != null and bl3.scene_file_path.ends_with("bolumlerim.tscn") and bl3.kok == KOK and r.call("_kayitlar").turlar.is_empty(), "")
	_k10("oyna/ dizininde bir önceki oyna dosyası silinir (yalnız biri kalır)",
		_oyna_dosya_sayisi() == 1, str(_oyna_dosya_sayisi()))

	# --- Aç: editör dosyayı yükler, kök korunur
	var id_b3: int = bl3.get_instance_id()
	var yol_b_json: String = bl3.kayitlar[1]["yol"]
	var ac_ok: bool = bl3.ac(bl3.kayitlar[1]["dosya"])
	var e_ac: Node = await _sahne_bekle(id_b3)
	_k10("Aç: editör açılır, bölüm yüklenir, kimlik kilitli, son_yol dosya, kök korunur",
		ac_ok and e_ac != null and e_ac.scene_file_path.ends_with("editor.tscn") and e_ac.veri["ad"] == "B Cozumsuz" and e_ac.kimlik_kilitli
		and e_ac.son_yol == yol_b_json and e_ac.kok == KOK and not e_ac.kirli_mi() and e_ac.dugumler.size() > 0,
		"%s" % (e_ac.veri.get("ad", "?") if e_ac != null else "yok"))
	_k10("Aç sonrası EditorOturumu.ac_yolu tüketildi (ikinci editör boş açılır)", EditorOturumu.ac_yolu == "", EditorOturumu.ac_yolu)

	# --- editörden Bölümlerim'e: temizken doğrudan, kirliyken onayla
	e_ac.kok = KOK
	var id_e: int = e_ac.get_instance_id()
	_k10("editör çubuğunda Bölümlerim düğmesi var", e_ac.find_child("BolumlerimDugmesi", true, false) != null, "")
	e_ac.blok_ekle([400, 500, 100, 20])
	var n_kirli: int = (e_ac.veri["nesneler"] as Array).size()
	var yol_kayit: String = e_ac.son_yol
	e_ac.bolumlerim_iste()
	await r.process_frame
	_k10("kirli editörden Bölümlerim: önce onay (diyalog açık, işlem bekliyor), sahne değişmez", r.current_scene == e_ac and e_ac.onay_diyalogu.visible and e_ac._bekleyen.is_valid(), "")
	e_ac.onay_kabul()
	var bl4: Node = await _sahne_bekle(id_e)
	_k10("onaydan sonra Bölümlerim açılır, kayıt değişmedi (kirli blok yazılmadı), kök korunur",
		bl4 != null and bl4.scene_file_path.ends_with("bolumlerim.tscn") and bl4.kok == KOK
		and (BolumVerisi.oku(yol_kayit)["veri"]["nesneler"] as Array).size() == n_kirli - 1, "")
	var id_b4: int = bl4.get_instance_id()
	bl4.ac(bl4.kayitlar[0]["dosya"])
	var e_t: Node = await _sahne_bekle(id_b4)
	e_t.kok = KOK
	var id_t: int = e_t.get_instance_id()
	e_t.bolumlerim_iste()
	var bl5: Node = await _sahne_bekle(id_t)
	_k10("temiz editörden Bölümlerim onaysız açılır", bl5 != null and bl5.scene_file_path.ends_with("bolumlerim.tscn"), "")

	# --- Sil: onay, iptal, silme
	bl5.kok = KOK
	bl5.yenile()
	var n0: int = bl5.kayitlar.size()
	bl5.sil_iste(bl5.kayitlar[3]["dosya"])
	bl5.sil_iptal()
	_k10("Sil iptal edilirse dosya kalır", bl5.kayitlar.size() == n0 and FileAccess.file_exists(bl5.kayitlar[3]["yol"]) and not bl5.sil_onayla(), "")
	var silinen: String = bl5.kayitlar[3]["dosya"]
	var silinen_yol: String = bl5.kayitlar[3]["yol"]
	bl5.sil_iste(silinen)
	var sildi: bool = bl5.sil_onayla()
	_k10("Sil onaylanınca dosya diskten kalkar, liste bir azalır, mesaj 'Silindi'",
		sildi and not FileAccess.file_exists(silinen_yol) and bl5.kayitlar.size() == n0 - 1 and bl5.satir(silinen).is_empty() and bl5.durum_mesaji.begins_with("Silindi"), bl5.durum_mesaji)
	var oteki_tamam := true
	for k in bl5.kayitlar:
		oteki_tamam = oteki_tamam and FileAccess.file_exists(k["yol"])
	_k10("silmede öteki bölümlerin sırası değişmez ve dosyaları yerinde",
		oteki_tamam and String(bl5.kayitlar[0]["dosya"]).begins_with("a_") and String(bl5.kayitlar[1]["dosya"]).begins_with("b_") and String(bl5.kayitlar[2]["dosya"]).begins_with("c_")
		and bl5.kayitlar[3]["dosya"] == "e_sema_001.json", "")
	# Satırdaki Sil düğmesi doğrudan silmez: yalnız onay ister.
	var sil_btn: Button = bl5.liste_kutusu.get_child(0).get_node("SilDugmesi")
	var ilk_yol: String = bl5.kayitlar[0]["yol"]
	sil_btn.pressed.emit()
	_k10("satırdaki Sil düğmesi doğrudan silmez (dosya yerinde, onay bekliyor); iptalle kalır", FileAccess.file_exists(ilk_yol) and bl5._silinecek != "", "")
	bl5.sil_iptal()
	_k10("Sil onaysız çağrılamaz: bekleyen yokken sil_onayla false", not bl5.sil_onayla(), "")

	# --- Yeni bölüm ve Ana menü
	var id_b5: int = bl5.get_instance_id()
	bl5.yeni_bolum()
	var e_y: Node = await _sahne_bekle(id_b5)
	_k10("Yeni bölüm: boş editör açılır (nesne yok, kimlik kilitli değil)", e_y != null and e_y.scene_file_path.ends_with("editor.tscn") and (e_y.veri["nesneler"] as Array).is_empty() and not e_y.kimlik_kilitli, "")
	e_y.kok = KOK
	var id_y: int = e_y.get_instance_id()
	e_y.bolumlerim_iste()
	var bl6: Node = await _sahne_bekle(id_y)
	var id_b6: int = bl6.get_instance_id()
	bl6.ana_menuye_don()
	var menu: Node = await _sahne_bekle(id_b6)
	_k10("Ana menü: ana menü açılır, EditorOturumu temiz", menu != null and menu.scene_file_path.ends_with("ana_menu.tscn") and EditorOturumu.kok == "" and EditorOturumu.ac_yolu == "", "")

	EditorOturumu.temizle()
	r.paused = false
	_dizin_sil(KOK)
	_k10("A10 testleri sonunda user://test_editor/ silindi", DirAccess.open(KOK) == null, "")


func _oyna_dosya_sayisi() -> int:
	var n := 0
	for f in DirAccess.get_files_at(BolumYollari.oyna_dizini(KOK)):
		if f.ends_with(".tscn"):
			n += 1
	return n


func _sirali(a: Array) -> Array:
	var b := a.duplicate()
	b.sort()
	return b


# ---------------------------------------------------------------- A11 (kablo görünümü eki)

func _k11(ad: String, ok: bool, ayr: String) -> void:
	_kaydi("Editör A11: " + ad, ok, ayr)


func _a11_gorunum(d: Node) -> Gorunum:
	return d.get_node_or_null("Gorunum") as Gorunum


func _a11_plan_adlari(g: Gorunum, hedef: Node) -> String:
	var parca: Array = []
	for k in g.kablo_plani(hedef):
		parca.append("%s:%d" % [k[0], k[1]])
	return ",".join(parca)


## Çizim headless'ta atlanır; yanma kararı `kablo_plani` / `kablo_yanik_mi` ile sınanır.
func a11_testleri() -> void:
	# Mandal plakanın `kilitli` alanı basılı sayılmasını sağlar (fiziksel basış gerekmez).
	var v := _v([_zemin(),
		{"tur": "salter", "id": "S", "konum": [200, 600]},
		{"tur": "mandal_plaka", "id": "PM1", "konum": [300, 600]},
		{"tur": "mandal_plaka", "id": "PM2", "konum": [400, 600]},
		{"tur": "mandal_plaka", "id": "PM3", "konum": [500, 600]},
		{"tur": "gecit", "id": "G", "konum": [700, 600], "kayma_mesafe": 100,
			"tetikleyiciler": ["S", "PM1", "PM2"], "acik_taraf_sag": true},
		{"tur": "asansor", "id": "A", "konum": [1000, 600], "yukseklik": 180, "plaka": "PM3"}])
	var b: Node = await _sahne_ac(v)
	var g: Node = b.get_node("G")
	var a: Node = b.get_node("A")
	var salter: Node = b.get_node("S")
	var pm1: BasincPlakasi = b.get_node("PM1")
	var pm2: BasincPlakasi = b.get_node("PM2")
	var pm3: BasincPlakasi = b.get_node("PM3")
	var gg := _a11_gorunum(g)
	var ga := _a11_gorunum(a)
	_k11("geçit ve asansörün Gorunum düğümü var", gg != null and ga != null,
		"geçit=%s asansör=%s" % [gg != null, ga != null])
	if gg == null or ga == null:
		return

	# Şalter + iki plaka bağlı geçit: üç ayrı kablo, her biri kendi tetikleyicisiyle
	var plan := _a11_plan_adlari(gg, g)
	_k11("geçit: 3 tetikleyici -> kablo, kablo_2, kablo_3 (sıra 0,1,2)", plan == "kablo:0,kablo_2:1,kablo_3:2",
		"plan=" + plan)
	_k11("kablo_3 (şalter+2 plaka) meta'dan okunur ve çizilir (3 meta da var)",
		g.has_meta("kablo") and g.has_meta("kablo_2") and g.has_meta("kablo_3"), str(_kablo_meta_adlari(g)))

	# Şalter kablosu: şalter solda + acik_taraf_sag=true -> sönük; sağa geçince yanar
	var s_sonuk: bool = not gg.kablo_yanik_mi(g, 0)
	salter.sagda = true
	var s_yanik: bool = gg.kablo_yanik_mi(g, 0)
	_k11("şalter kablosu: şalter sağa geçince (acik_taraf_sag=true) yanar, solda sönük", s_sonuk and s_yanik,
		"solda sönük=%s sağda yanık=%s" % [s_sonuk, s_yanik])
	g.acik_taraf_sag = false
	var ters: bool = not gg.kablo_yanik_mi(g, 0)
	salter.sagda = false
	var ters2: bool = gg.kablo_yanik_mi(g, 0)
	_k11("şalter kablosu hedefin acik_taraf_sag değerine uyar (false: soldayken yanar)", ters and ters2,
		"sağda sönük=%s solda yanık=%s" % [ters, ters2])
	g.acik_taraf_sag = true
	salter.sagda = false

	# Plaka kabloları yalnız kendi sıralarıyla yanar; kablo_3 hiç tetik 3 değil, 3. kablo = PM2
	pm1.kilitli = true
	var p1: bool = gg.kablo_yanik_mi(g, 1) and not gg.kablo_yanik_mi(g, 2) and not gg.kablo_yanik_mi(g, 0)
	pm1.kilitli = false
	pm2.kilitli = true
	await r.physics_frame
	var p2: bool = gg.kablo_yanik_mi(g, 2) and not gg.kablo_yanik_mi(g, 1) and not gg.kablo_yanik_mi(g, 0)
	_k11("kablo_2 yalnız 2., kablo_3 yalnız 3. tetikleyiciyle yanar", p1 and p2, "pm1=%s pm2=%s" % [p1, p2])

	# Asansör kablosu: meta'sı var, plaka basılınca yanar
	var a_plan := _a11_plan_adlari(ga, a)
	var a_sonuk: bool = not ga.kablo_yanik_mi(a, -1)
	pm3.kilitli = true
	await r.physics_frame
	var a_yanik: bool = ga.kablo_yanik_mi(a, -1)
	_k11("asansör kablosu: kablo meta'sı var, plaka basılınca yanar, değilken sönük",
		a.has_meta("kablo") and a_plan == "kablo:-1" and a_sonuk and a_yanik,
		"meta=%s plan=%s sönük=%s yanık=%s" % [a.has_meta("kablo"), a_plan, a_sonuk, a_yanik])

	# Kablo çarpışmaz ve mantığa girmez: Gorunum bir çarpışma nesnesi ya da çocuklu düğüm değil
	var sade: bool = not ((gg as Node) is CollisionObject2D) and gg.get_child_count() == 0 and ga.get_child_count() == 0
	_k11("kablo çizimi çarpışma ya da fizik düğümü eklemez", sade, "çocuk=%d/%d" % [gg.get_child_count(), ga.get_child_count()])

	# Lazerden ayırt edilme: kablo kodunda kırmızı/amber (UYARI, AMBER) yok
	var kaynak := FileAccess.get_file_as_string("res://scripts/gorunum.gd")
	var bas := kaynak.find("# ---------- plaka kablosu")
	var son := kaynak.find("# ---------- şalter ----------")
	var bolge := kaynak.substr(bas, son - bas)
	var kirmizi_yok: bool = bas >= 0 and son > bas and bolge.find("UYARI") < 0 and bolge.find("AMBER") < 0
	_k11("kablo çizimi kırmızı/amber kullanmaz (lazer ışınından ayırt edilir)", kirmizi_yok, "bölge %d karakter" % bolge.length())

	# Gizli 2. kablo: tek görünür `kablo` 1. tetikleyicidir, 2. plakaya basınca yanmaz
	var vg := _v([_zemin(), _pl("P1", 300, 600), _pl("P2", 400, 600),
		{"tur": "gecit", "id": "G2", "konum": [700, 600], "kayma_mesafe": 100, "tetikleyiciler": ["P1", "P2"],
			"kablolar": [{"tetik": "P2", "gizli": true}]}])
	var bg: Node = await _sahne_ac(vg)
	var g2: Node = bg.get_node("G2")
	var gg2 := _a11_gorunum(g2)
	var p2m: BasincPlakasi = bg.get_node("P2")
	p2m.mandal = true
	p2m.kilitli = true
	await r.physics_frame
	_k11("gizli 2. kablo: görünür kablo yalnız 1. plakayla yanar (2. plaka basılıyken sönük)",
		g2.has_meta("kablo") and not g2.has_meta("kablo_2") and _a11_plan_adlari(gg2, g2) == "kablo:0" and not gg2.kablo_yanik_mi(g2, 0),
		"plan=%s meta=%s" % [_a11_plan_adlari(gg2, g2), str(g2.get_meta_list())])

	# B20: 3 tek tetikleyicili kablo, eski eşleme
	r.set("aktif_bolum", "res://scenes/bolumler/bolum_20.tscn")
	r.root.get_node("Kayitlar").call("sifirla")
	var b20: Node = await r.call("_bolumu_yukle")
	var ok20 := true
	for ad in ["GecitG", "LazerA", "LazerB"]:
		var gx := _a11_gorunum(b20.get_node(ad))
		ok20 = ok20 and gx != null and _a11_plan_adlari(gx, b20.get_node(ad)) == "kablo:-1"
	_k11("B20 kablo eşlemesi aynı (GecitG, LazerA, LazerB: tek tetikleyici, herhangi biri)", ok20, "")

	# Eski bölümler (B21): eski eşleme aynı kalır
	r.set("aktif_bolum", "res://scenes/bolumler/bolum_21.tscn")
	r.root.get_node("Kayitlar").call("sifirla")
	var b21: Node = await r.call("_bolumu_yukle")
	var gb := _a11_gorunum(b21.get_node("GecitG"))
	var gm := _a11_gorunum(b21.get_node("GecitM"))
	var la := _a11_gorunum(b21.get_node("LazerA"))
	var ok21: bool = gb != null and gm != null and la != null 		and _a11_plan_adlari(gb, b21.get_node("GecitG")) == "kablo:0,kablo_2:1" 		and _a11_plan_adlari(gm, b21.get_node("GecitM")) == "kablo:-1" 		and _a11_plan_adlari(la, b21.get_node("LazerA")) == "kablo:-1"
	_k11("B21 eski kablo eşlemesi aynı (GecitG: kablo=1., kablo_2=2.; GecitM/LazerA: herhangi biri)", ok21, "")
	await _a11_kirli_testleri()


# ---------------------------------------------------------------- A11 / kirli_mi: çözüm ve doğrulama da kaydedilmemiş iştir

## Menü/Yeni/Aç/Bölümlerim isteği: onay diyaloğu açılır ve sahne değişmez mi?
func _a11_onay_sorar(e: Node, islem: String) -> bool:
	var sahne := r.current_scene
	match islem:
		"menu": e.menu_iste()
		"yeni": e.yeni_iste()
		"ac": e.ac_iste(KOK + "bolumler/yok_dosya.json")
		"bolumlerim": e.bolumlerim_iste()
	var sordu: bool = e.onay_diyalogu.visible and r.current_scene == sahne
	e.onay_iptal()
	return sordu and not e.onay_diyalogu.visible


func _a11_kirli_testleri() -> void:
	var e: Node = await _ed()
	_gecerli(e, "Kirli Cozum")
	e.kaydet()
	var temiz0: bool = not e.kirli_mi()
	var e2: Node = await _cozum_akisi(e)
	_k11("kirli_mi: Dene'den 'Çözümü kaydet' ile gelen çözüm kaydedilmemiş iş sayılır", e2 != null and temiz0 and e2.kirli_mi(),
		"temiz0=%s kirli=%s" % [temiz0, e2 != null and e2.kirli_mi()])
	if e2 == null:
		return
	var cozumsuz: Dictionary = e2.veri.duplicate(true)
	cozumsuz.erase("cozum")
	cozumsuz.erase("dogrulama")
	var icerik_ayni: bool = e2.veri.has("cozum") and BolumVerisi.kanonik_metin(e2.veri) == BolumVerisi.kanonik_metin(cozumsuz) 		and BolumVerisi.kirlilik_metni(e2.veri) != BolumVerisi.kirlilik_metni(cozumsuz)
	var sorar: Array = []
	for islem in ["menu", "yeni", "ac", "bolumlerim"]:
		sorar.append(_a11_onay_sorar(e2, islem))
	_k11("çözüm kaydı içerik özetine girmez (D10 etkilenmez) ama kirlilik metnine girer; Menü / Yeni / Aç / Bölümlerim onay sorar, sahne değişmez",
		icerik_ayni and sorar == [true, true, true, true], "onaylar=%s" % str(sorar))
	var kaydedildi: bool = e2.kaydet() == OK and not e2.kirli_mi()
	_k11("Kaydet çözümü de kaydeder: sonra kirli_mi false",
		kaydedildi, "kirli=%s" % e2.kirli_mi())

	# Doğrulama sonucu
	e2._dogrulama_isle({"iptal": true})
	var iptal_temiz: bool = not e2.kirli_mi()
	_k11("doğrulama iptali hiçbir şey yazmaz: kirli_mi false kalır", iptal_temiz, "")
	e2._dogrulama_isle({"durum": "dogrulandi", "hata": 0, "uyari": 0, "bitis_kare": 100})
	var dog_kirli: bool = e2.kirli_mi()
	var dog_sorar: bool = _a11_onay_sorar(e2, "menu") and _a11_onay_sorar(e2, "bolumlerim")
	_k11("doğrulama sonucu (Kaydet'siz) kaydedilmemiş iş sayılır; Menü ve Bölümlerim onay sorar",
		dog_kirli and dog_sorar, "kirli=%s sorar=%s" % [dog_kirli, dog_sorar])
	var dog_kayit: bool = e2.kaydet() == OK and not e2.kirli_mi()
	_k11("doğrulama sonucu Kaydet ile temizlenir", dog_kayit, "")

	# Dosyadan açınca çözüm ve doğrulama temizdir (yanlış alarm yok)
	var yol: String = e2.son_yol
	var e3: Node = await _ed()
	e3.ac(yol)
	_k11("çözümlü ve doğrulanmış dosya açılınca kirli_mi false (yanlış alarm yok)",
		not e3.kirli_mi() and e3.veri.has("cozum") and e3.veri.has("dogrulama"), "kirli=%s" % e3.kirli_mi())
	# Çözüm yeniden yazılınca (aynı içerik, farklı çözüm) yine kirli
	var v3: Dictionary = e3.veri
	var oyuncu: Array = (v3["cozum"] as Dictionary)["oyuncu"]
	(v3["cozum"] as Dictionary)["oyuncu"] = oyuncu + [[1, 0, false]]
	_k11("yalnız çözüm değişirse (içerik aynı) kirli_mi true", e3.kirli_mi(), "")
	_dizin_sil(KOK)


# ---------------------------------------------------------------- A12 (Canlıya al, birleşik liste, harita yerleşimi)

const A12_BOLUM_1 := "res://scenes/bolumler/bolum_1.tscn"
const A12_BOLUM_9 := "res://scenes/bolumler/bolum_9.tscn"
const A12_BOLUM_10 := "res://scenes/bolumler/bolum_10.tscn"
const A12_BOLUM_11 := "res://scenes/bolumler/bolum_11.tscn"
const A12_BOLUM_21 := "res://scenes/bolumler/bolum_21.tscn"
const A12_HARITA := "res://scenes/harita.tscn"


func _k12(ad: String, ok: bool, ayr: String) -> void:
	_kaydi("Editör A12: " + ad, ok, ayr)


## B1 fikstüründen verilen kimlik/adla geçerli bölüm; `dogrulanmis` ise güncel "dogrulandi" kaydı taşır.
func _a12_veri(kimlik: String, ad: String, dogrulanmis := false) -> Dictionary:
	var v: Dictionary = (_fikstur("b1.json")["veri"] as Dictionary).duplicate(true)
	v["kimlik"] = kimlik
	v["ad"] = ad
	v.erase("cozum")
	v.erase("dogrulama")
	v.erase("canli")
	if dogrulanmis:
		v["dogrulama"] = {"durum": "dogrulandi", "icerik_ozeti": BolumVerisi.icerik_ozeti(v), "hata": 0, "uyari": 0, "bitis_kare": 120}
	return v


## `user://` altındaki dosyalar ve boyutları (logs hariç): saf okuma kanıtı için anlık görüntü.
func _a12_goruntu(yol: String, cikti: Dictionary) -> Dictionary:
	var d := DirAccess.open(yol)
	if d == null:
		return cikti
	for alt in d.get_directories():
		if alt != "logs":
			_a12_goruntu(yol.path_join(alt), cikti)
	for f in d.get_files():
		var fa := FileAccess.open(yol.path_join(f), FileAccess.READ)
		cikti[yol.path_join(f)] = fa.get_length() if fa != null else -1
	return cikti


func _a12_canli_temizle() -> void:
	_dizin_sil(KOK + "canli")
	BolumListesi.yenile()


## Başka bir test işlevini çalıştırır ve o sırada kaydedilen sonuçların adına önek koyar.
func _a12_canlili(isl: String) -> void:
	var bas: int = r.sonuclar.size()
	await r.call(isl)
	for k in range(bas, r.sonuclar.size()):
		r.sonuclar[k]["ad"] = "[A12: canlı bölümlerle] " + str(r.sonuclar[k]["ad"])


func _a12_sira_kimlikleri() -> Array:
	var cikti: Array = []
	for k in BolumListesi.liste():
		cikti.append(k["yol"].get_file().get_basename() if k["kaynak"] == "resmi" else k["kimlik"])
	return cikti


func a12_testleri() -> void:
	r.paused = false
	_dizin_sil(KOK)
	BolumListesi.kullanici_kok = KOK
	BolumListesi.yenile()
	r.call("_kayitlar").sifirla()
	EditorOturumu.temizle()

	await _a12_harita_yerlesimi_testleri()
	await _a12_liste_ve_ekleme_testleri()
	await _a12_hata_ve_sinir_testleri()
	await _a12_sira_sagligi_testleri()
	await _a12_guncelle_testleri()
	await _a12_arayuz_testleri()
	await _a12_gorsel_testleri()

	_dizin_sil(KOK)
	BolumListesi.yenile()
	EditorOturumu.temizle()


func _a12_harita_yerlesimi_testleri() -> void:
	var esit21 := BolumListesi.BOLUMLER.size() == 21
	for i in 21:
		var b: Dictionary = BolumListesi.BOLUMLER[i]
		esit21 = esit21 and (HaritaYerlesimi.konum(i, 21) - (b["konum"] as Vector2)).length() < 0.001
	_k12("HaritaYerlesimi.konum(i, 21) bugünkü 21 resmî konumla birebir aynı", esit21, "")

	var en_yakin := 1.0e9
	var sinir_ok := true
	var tekil_ok := true
	var ayr := ""
	for m in range(2, HaritaYerlesimi.AZAMI + 1):
		for i in m:
			var p := HaritaYerlesimi.konum(i, m)
			sinir_ok = sinir_ok and p.x >= 139.99 and p.x <= 1040.01 and p.y >= 164.99 and p.y <= 510.01
			for j in range(i + 1, m):
				var d := p.distance_to(HaritaYerlesimi.konum(j, m))
				en_yakin = minf(en_yakin, d)
				if d < 0.5:
					tekil_ok = false
					ayr += " n=%d:%d~%d" % [m, i, j]
	_k12("HaritaYerlesimi: n = 2..40 için en yakın iki düğüm >= 100 px, hepsi haritada, hiçbiri çakışmaz",
		en_yakin >= 99.99 and sinir_ok and tekil_ok, "en yakın %.2f px, sınır=%s,%s" % [en_yakin, sinir_ok, ayr])

	var ardisik_ok := true
	for m in [22, 30, 40]:
		for i in range(m - 1):
			var a := HaritaYerlesimi.konum(i, m)
			var b := HaritaYerlesimi.konum(i + 1, m)
			var yatay: bool = absf(a.y - b.y) < 0.01 and absf(a.x - b.x) > 0.01
			var dikey: bool = absf(a.x - b.x) < 0.01 and absf(a.y - b.y) > 0.01
			ardisik_ok = ardisik_ok and (yatay or dikey)
	_k12("HaritaYerlesimi: ardışık düğümler yalnız yatay ya da dikey bağlanır (çizgiler kesişmez)", ardisik_ok, "")
	_k12("HaritaYerlesimi sütun sayısı: n<=24 için 6, 25 için 7, 40 için 10",
		HaritaYerlesimi.sutun_sayisi(21) == 6 and HaritaYerlesimi.sutun_sayisi(24) == 6 and HaritaYerlesimi.sutun_sayisi(25) == 7
		and HaritaYerlesimi.sutun_sayisi(40) == 10, "")


func _a12_liste_ve_ekleme_testleri() -> void:
	_a12_canli_temizle()
	# --- canlı yokken liste = 21 resmî kayıt, bugünküyle birebir
	var l0 := BolumListesi.liste()
	var l0_ok := l0.size() == 21
	for i in range(mini(21, l0.size())):
		var b: Dictionary = BolumListesi.BOLUMLER[i]
		l0_ok = l0_ok and l0[i]["yol"] == b["yol"] and l0[i]["ad"] == b["ad"] and (l0[i]["konum"] - b["konum"]).length() < 0.001 \
			and l0[i]["onceki"] == b["onceki"] and l0[i]["kaynak"] == "resmi"
	_k12("canlı yokken liste() 21 resmî kayıt; yol, ad, konum, onceki BOLUMLER ile birebir", l0_ok, str(l0.size()))
	_k12("canlı yokken son_uyarilar boş, baglantilar 20 çift", BolumListesi.son_uyarilar.is_empty() and BolumListesi.baglantilar().size() == 20, "")

	# --- Canlıya al: bölüm 10 ile 11 arası
	var va := _a12_veri("canli_a_001", "Canli A")
	var sorun_a := CanliBolumler.canliya_al(va, A12_BOLUM_10, KOK)
	_k12("canliya_al (10'dan sonra) başarılı: sorun yok", sorun_a.is_empty(), _ozet_metni(sorun_a))
	var l1 := BolumListesi.liste()
	var canli_yol: String = l1[10]["yol"] if l1.size() > 10 else ""
	_k12("araya ekleme: liste 22 kayıt, canlı bölüm 11. sırada, bölüm 11 artık 12., bölüm 10 yerinde",
		l1.size() == 22 and l1[10]["kimlik"] == "canli_a_001" and l1[10]["kaynak"] == "canli" and BolumListesi.indeks(A12_BOLUM_11) == 11
		and BolumListesi.indeks(A12_BOLUM_10) == 9, str(_a12_sira_kimlikleri()))
	_k12("canlı sahne yolu user://.../canli/<kimlik>_v001.tscn, kip 'canli'; Sonraki zinciri 10 -> canlı -> 11",
		canli_yol == KOK + "canli/canli_a_001_v001.tscn" and BolumYollari.canli_mi(canli_yol)
		and BolumListesi.sonraki(A12_BOLUM_10) == canli_yol and BolumListesi.sonraki(canli_yol) == A12_BOLUM_11, canli_yol)
	_k12("HUD başlıkları listeden türer: canlı 'Bölüm 11 · Canli A', eski bölüm 11 'Bölüm 12 · Yay', bölüm 10 değişmez",
		BolumListesi.baslik(canli_yol) == "Bölüm 11 · Canli A" and BolumListesi.baslik(A12_BOLUM_11) == "Bölüm 12 · Yay"
		and BolumListesi.baslik(A12_BOLUM_10) == "Bölüm 10 · Hat" and BolumListesi.baslik(A12_BOLUM_21) == "Bölüm 22 · Fitil ve Mühür",
		"%s | %s" % [BolumListesi.baslik(canli_yol), BolumListesi.baslik(A12_BOLUM_11)])
	var konum_ok := true
	for i in l1.size():
		konum_ok = konum_ok and (l1[i]["konum"] - HaritaYerlesimi.konum(i, l1.size())).length() < 0.001 and l1[i]["onceki"] == ("" if i == 0 else l1[i - 1]["yol"])
	_k12("harita konumları HaritaYerlesimi.konum(i, 22) ve onceki = listedeki bir önceki; 21 bağlantı", konum_ok and BolumListesi.baglantilar().size() == 21, "")

	# --- .tscn dosyaları yeniden adlandırılmaz
	var dosya_ok := true
	var say := 0
	var d := DirAccess.open("res://scenes/bolumler")
	for f in d.get_files():
		if f.begins_with("bolum_") and f.ends_with(".tscn"):
			say += 1
		elif f.contains("canli"):
			dosya_ok = false
	for i in 21:
		dosya_ok = dosya_ok and ResourceLoader.exists("res://scenes/bolumler/bolum_%d.tscn" % (i + 1)) \
			and BolumListesi.BOLUMLER[i]["yol"] == "res://scenes/bolumler/bolum_%d.tscn" % (i + 1)
	_k12("resmî .tscn dosyaları yeniden adlandırılmadı: bolum_1..21 yerinde (21 dosya), scenes/bolumler'e canlı dosya yazılmadı",
		dosya_ok and say == 21, "bolum_*.tscn: %d" % say)

	# --- diskteki dosyalar ve sıra kaydı
	var sira := CanliBolumler.sira_oku(KOK)
	_k12("canli/ altında dondurulmuş JSON, sahne ve sira.json var; kayıt alanları doğru (sonra = bölüm 10 yolu, cozum_yok true)",
		FileAccess.file_exists(KOK + "canli/canli_a_001.json") and FileAccess.file_exists(canli_yol) and FileAccess.file_exists(KOK + "canli/sira.json")
		and sira.size() == 1 and sira[0]["sonra"] == A12_BOLUM_10 and sira[0]["sahne"] == "canli_a_001_v001.tscn" and sira[0]["cozum_yok"] == true
		and sira[0]["icerik_ozeti"] == BolumVerisi.icerik_ozeti(va), JSON.stringify(sira))

	# --- liste() saf okuyucudur: dosya yazmaz/silmez
	var kaynak := FileAccess.get_file_as_string("res://scripts/bolumler_listesi.gd")
	var yasak: Array = []
	for t in ["BolumKurucu", "BolumDenetci", "CanliBolumler", "ResourceSaver", "FileAccess.WRITE", "store_string", "remove_absolute", "make_dir", "PackedScene.new"]:
		if kaynak.contains(t):
			yasak.append(t)
	var once := _a12_goruntu("user://", {})
	BolumListesi.yenile()
	BolumListesi.liste()
	BolumListesi.yollar()
	BolumListesi.baglantilar()
	BolumListesi.baslik(canli_yol)
	BolumListesi.olustur(KOK)
	BolumListesi.yenile()
	BolumListesi.liste()
	var sonra := _a12_goruntu("user://", {})
	_k12("liste() saf okuyucu: çağrılardan önce ve sonra user:// görüntüsü eşit; kaynak BolumKurucu/BolumDenetci/CanliBolumler ve yazma çağrısı içermez",
		once == sonra and once.size() > 0 and yasak.is_empty(), "yasak=%s, dosya=%d" % [str(yasak), once.size()])

	# --- Canlı sahne gerçekten oynanır: HUD numarası, çözüm uyarısı, sonuç ekranı "Sonraki"
	r.set("aktif_bolum", canli_yol)
	r.root.get_node("Kayitlar").call("sifirla")
	var cb: Node = await r.call("_bolumu_yukle")
	var et: Label = cb.find_child("BolumEtiketi", true, false) as Label if cb != null else null
	var hud := cb.get_node_or_null("EditorHud") if cb != null else null
	_k12("canlı bölüm açılır: HUD 'Bölüm 11 · Canli A', çözümsüz olduğu için uyarı satırı var, ev butonu ana menüye gider",
		cb != null and et != null and et.text == "Bölüm 11 · Canli A" and hud != null and hud.get("uyari") != null
		and BolumYollari.ev_sahnesi(canli_yol) == BolumYollari.MENU_SAHNESI, "etiket=%s" % (et.text if et != null else "yok"))
	var sonuc: Node = await _sonuc_ac(cb)
	_k12("canlı bölüm sonuç ekranı: 'Sonraki bölüm' görünür ve bölüm 11'e (listedeki sonraki) gider",
		sonuc != null and sonuc.sonraki_dugmesi.visible and sonuc.sonraki_yol == A12_BOLUM_11, str(sonuc.sonraki_yol) if sonuc != null else "yok")
	r.paused = false

	# --- harita: 22 düğüm, canlı düğüm doğru yerde ve etikette; düğüm canlı bölümü açar
	var h: Node = await r.call("_ar_sahne_yukle", A12_HARITA)
	await r.physics_frame
	var dugumler: Array = h.get_node("Dugumler").get_children().filter(func(c): return c is Button)
	var d11: Button = h.get_node_or_null("Dugumler/Dugum11")
	var e11: Label = h.get_node_or_null("Dugumler/Etiket11")
	var e12: Label = h.get_node_or_null("Dugumler/Etiket12")
	var merkez11: Vector2 = d11.position + d11.size / 2.0 if d11 != null else Vector2.ZERO
	_k12("harita: 22 düğüm, 11. düğüm canlı bölümün yerinde (HaritaYerlesimi), etiketler 'Bölüm 11: Canli A · Canlı' / 'Bölüm 12: Yay'",
		dugumler.size() == 22 and d11 != null and d11.text == "11" and (merkez11 - HaritaYerlesimi.konum(10, 22)).length() < 0.01
		and e11 != null and e11.text == "Bölüm 11: Canli A · Canlı" and e12 != null and e12.text == "Bölüm 12: Yay" and h.baglantilar.size() == 21,
		"düğüm=%d" % dugumler.size())
	var id_h: int = h.get_instance_id()
	if d11 != null:
		d11.pressed.emit()
	var girilen: Node = await _sahne_bekle(id_h)
	_k12("harita 11. düğüm canlı bölümü açar: klon 0, Tur 1",
		girilen != null and girilen.scene_file_path == canli_yol and r.call("_klonlar", girilen).size() == 0 and girilen.bilgi.text.begins_with("Tur 1 "), "")

	# --- zincirleme ekleme: canlı bölümden sonra
	var vb := _a12_veri("canli_b_001", "Canli B")
	var sorun_b := CanliBolumler.canliya_al(vb, "canli:canli_a_001", KOK)
	_k12("zincirleme: canlı A'dan sonra canlı B (sonra = canli:<kimlik>); sıra 10, A, B, 11",
		sorun_b.is_empty() and BolumListesi.liste().size() == 23 and BolumListesi.liste()[10]["kimlik"] == "canli_a_001" and BolumListesi.liste()[11]["kimlik"] == "canli_b_001"
		and BolumListesi.indeks(A12_BOLUM_11) == 12 and BolumListesi.baslik(BolumListesi.liste()[11]["yol"]) == "Bölüm 12 · Canli B",
		str(_a12_sira_kimlikleri()) + _ozet_metni(sorun_b))

	# --- T1–T22 düzeltilmiş hâlleri iki canlı bölümle de geçer
	await _a12_canlili("_test_bolum_listesi")
	await _a12_canlili("_test_harita_cizgisi")
	await _a12_canlili("_test_harita_kesisim")
	await _a12_canlili("_ar_harita")
	await _a12_canlili("_ar_hud_bolum_etiketi")
	await _a12_canlili("_test_harita_dugumleri")
	await _a12_canlili("_test_bolum_secimi")
	await _a12_canlili("_gorunurluk_testleri")
	r.paused = false
	r.call("_kayitlar").sifirla()

	# --- en başa ekleme
	var vc := _a12_veri("canli_c_001", "Canli C")
	var sorun_c := CanliBolumler.canliya_al(vc, "", KOK)
	_k12("en başa ekleme: canlı C birinci sırada, bölüm 1 ikinci, harita başlangıç düğümü C",
		sorun_c.is_empty() and BolumListesi.liste()[0]["kimlik"] == "canli_c_001" and BolumListesi.indeks(A12_BOLUM_1) == 1
		and BolumListesi.liste()[0]["onceki"] == "" and BolumListesi.liste()[1]["onceki"] == BolumListesi.liste()[0]["yol"]
		and BolumListesi.baslik(BolumListesi.liste()[0]["yol"]) == "Bölüm 1 · Canli C" and BolumListesi.baslik(A12_BOLUM_1) == "Bölüm 2 · Giriş"
		and CanliBolumler.numara("canli_c_001", KOK) == 1, str(_a12_sira_kimlikleri()))

	# --- kaldırma: numaralar geri kayar, bağlı kayıtların `sonra` değeri devredilir
	var a_yol: String = CanliBolumler.sahne_yolu("canli_a_001", KOK)
	var h_kaldir := CanliBolumler.kaldir("canli_a_001", KOK)
	var sira2 := CanliBolumler.sira_oku(KOK)
	var b_sonra := ""
	for k in sira2:
		if k["kimlik"] == "canli_b_001":
			b_sonra = k["sonra"]
	_k12("kaldir(A): B'nin sonra değeri A'nınkine (bölüm 10) devredilir; sıra C,1..10,B,11.. ve numaralar geri kayar",
		h_kaldir == OK and b_sonra == A12_BOLUM_10 and BolumListesi.liste().size() == 23
		and BolumListesi.indeks("res://scenes/bolumler/bolum_11.tscn") == 12 and BolumListesi.liste()[11]["kimlik"] == "canli_b_001"
		and CanliBolumler.numara("canli_a_001", KOK) == 0, "b_sonra=%s %s" % [b_sonra, str(_a12_sira_kimlikleri())])
	_k12("kaldir: sahne ve dondurulmuş JSON diskten silinir, öteki canlıların dosyası kalır",
		not FileAccess.file_exists(a_yol) and not FileAccess.file_exists(KOK + "canli/canli_a_001.json")
		and FileAccess.file_exists(CanliBolumler.sahne_yolu("canli_b_001", KOK)), "")
	_k12("kaldir: olmayan kimlik ERR_DOES_NOT_EXIST", CanliBolumler.kaldir("yok_999", KOK) == ERR_DOES_NOT_EXIST, "")
	CanliBolumler.kaldir("canli_b_001", KOK)
	CanliBolumler.kaldir("canli_c_001", KOK)
	_k12("hepsi kaldırılınca liste yine 21 resmî kayıt ve konumlar bugünküyle aynı",
		BolumListesi.liste().size() == 21 and (BolumListesi.liste()[20]["konum"] - Vector2(680, 510)).length() < 0.001
		and BolumListesi.indeks(A12_BOLUM_11) == 10 and CanliBolumler.sira_oku(KOK).is_empty(), "")
	_a12_canli_temizle()


func _a12_hata_ve_sinir_testleri() -> void:
	_a12_canli_temizle()
	var yol_sira := KOK + "canli/sira.json"

	# --- statik HATA engeller, hiçbir şey yazılmaz
	var vh := BolumVerisi.bos("Hatali", "hatali_001")
	var sorun_h := CanliBolumler.canliya_al(vh, "", KOK)
	_k12("statik HATA'lı bölüm canlıya alınamaz: HATA döner, canli/ dizini oluşmaz, liste 21",
		not sorun_h.is_empty() and str(sorun_h[0]["seviye"]) == "HATA" and not DirAccess.dir_exists_absolute(KOK + "canli") and BolumListesi.liste().size() == 21,
		_ozet_metni(sorun_h))

	# --- çözümsüz bölüm izinlidir (S4); doğrulanmış bölümde cozum_yok false
	var v_coz := _a12_veri("coz_yok_001", "Cozumsuz")
	var v_dog := _a12_veri("dogru_001", "Dogrulanmis", true)
	var s1 := CanliBolumler.canliya_al(v_coz, A12_BOLUM_21, KOK)
	var s2 := CanliBolumler.canliya_al(v_dog, "canli:coz_yok_001", KOK)
	var cz := {}
	for k in CanliBolumler.sira_oku(KOK):
		cz[k["kimlik"]] = k["cozum_yok"]
	_k12("çözümsüz bölüm canlıya alınabilir (cozum_yok true), doğrulanmış bölümde cozum_yok false; sona ekleme (22., 23.)",
		s1.is_empty() and s2.is_empty() and cz.get("coz_yok_001") == true and cz.get("dogru_001") == false
		and BolumListesi.liste().size() == 23 and BolumListesi.liste()[22]["kimlik"] == "dogru_001", str(cz))
	r.set("aktif_bolum", CanliBolumler.sahne_yolu("dogru_001", KOK))
	r.root.get_node("Kayitlar").call("sifirla")
	var bd: Node = await r.call("_bolumu_yukle")
	_k12("doğrulanmış canlı bölümde uyarı satırı yok, çözümsüzde var (aynı meta)",
		bd != null and bd.get_node_or_null("EditorHud") != null and bd.get_node("EditorHud").get("uyari") == null and bd.get_meta("cozum_yok") == false, "")

	# --- zaten canlı, geçersiz sıra
	var s3 := CanliBolumler.canliya_al(v_coz, "", KOK)
	var s4 := CanliBolumler.canliya_al(_a12_veri("x_001", "X"), "res://yok.tscn", KOK)
	var s5 := CanliBolumler.canliya_al(_a12_veri("y_001", "Y"), "canli:yok_999", KOK)
	_k12("zaten canlı bölüm C1; geçersiz sıra (olmayan yol / olmayan canlı kimlik) C2; ikisi de hiçbir şey yazmaz",
		not s3.is_empty() and s3[0]["kod"] == CanliBolumler.KOD_ZATEN_CANLI and not s4.is_empty() and s4[0]["kod"] == CanliBolumler.KOD_SIRA
		and not s5.is_empty() and s5[0]["kod"] == CanliBolumler.KOD_SIRA and CanliBolumler.sira_oku(KOK).size() == 2 and BolumListesi.liste().size() == 23, "")

	# --- eksik sahne dosyası atlanır, uyarı verir; yeri bulunamayan kayıt sona eklenir
	var sira := CanliBolumler.sira_oku(KOK)
	sira.append({"kimlik": "hayalet_001", "ad": "Hayalet", "sahne": "hayalet_001_v001.tscn", "sonra": "", "icerik_ozeti": "x", "cozum_yok": false})
	sira[0]["sonra"] = "res://scenes/bolumler/olmayan.tscn"
	_metin_yaz(yol_sira, JSON.stringify({"surum": 1, "canli": sira}))
	BolumListesi.yenile()
	var lh := BolumListesi.liste()
	var uyari_metni := " | ".join(BolumListesi.son_uyarilar)
	_k12("eksik sahne dosyalı kayıt atlanır (liste'de yok) ve son_uyarilar'da adı geçer",
		lh.size() == 23 and not _a12_sira_kimlikleri().has("hayalet_001") and uyari_metni.contains("hayalet_001"), uyari_metni)
	_k12("yeri bulunamayan kayıt listenin sonuna eklenir ve uyarı verilir; ona bağlı kayıt arkasından gelir",
		lh[21]["kimlik"] == "coz_yok_001" and lh[22]["kimlik"] == "dogru_001" and uyari_metni.contains("coz_yok_001"), str(_a12_sira_kimlikleri().slice(19)))

	# --- bozuk sira.json: canlı yok sayılır, uyarı verilir, oyun açılır
	_metin_yaz(yol_sira, "{ bozuk json")
	BolumListesi.yenile()
	_k12("bozuk sira.json: liste 21 resmî kayıt, uyarı var (oyun yine açılır)",
		BolumListesi.liste().size() == 21 and not BolumListesi.son_uyarilar.is_empty() and BolumListesi.baglantilar().size() == 20, " | ".join(BolumListesi.son_uyarilar))

	# --- 40 bölüm sınırı
	_a12_canli_temizle()
	var hepsi_ok := true
	for i in 19:
		var s := CanliBolumler.canliya_al(_a12_veri("sinir_%03d" % (i + 1), "Sinir %d" % (i + 1)), A12_BOLUM_21, KOK)
		hepsi_ok = hepsi_ok and s.is_empty()
	var l40 := BolumListesi.liste()
	_k12("19 canlı bölüm eklenir; liste tam 40 kayıt", hepsi_ok and l40.size() == 40, "boyut=%d" % l40.size())
	var s20 := CanliBolumler.canliya_al(_a12_veri("fazla_001", "Fazla"), "", KOK)
	_k12("40. kayıttan sonra canlıya alma reddedilir (C3), liste 40 kalır, dosya yazılmaz",
		not s20.is_empty() and s20[0]["kod"] == CanliBolumler.KOD_SINIR and BolumListesi.liste().size() == 40 and not FileAccess.file_exists(KOK + "canli/fazla_001.json"), _ozet_metni(s20))
	var konum40_ok := true
	for i in 40:
		konum40_ok = konum40_ok and (l40[i]["konum"] - HaritaYerlesimi.konum(i, 40)).length() < 0.001
	_k12("40 kayıtta konumlar HaritaYerlesimi.konum(i, 40); sonuncu (40.) düğüm 4. satırda", konum40_ok and (l40[39]["konum"] as Vector2).y == 510.0, "")
	# sira.json'a elle 41. kayıt: alınmaz, uyarı verir
	var sira40 := CanliBolumler.sira_oku(KOK)
	var kopya: Dictionary = (sira40[0] as Dictionary).duplicate()
	kopya["kimlik"] = "elle_041"
	sira40.append(kopya)
	_metin_yaz(yol_sira, JSON.stringify({"surum": 1, "canli": sira40}))
	BolumListesi.yenile()
	_k12("sira.json'daki 41. kayıt alınmaz: liste 40, uyarı sınırı söyler",
		BolumListesi.liste().size() == 40 and not _a12_sira_kimlikleri().has("elle_041") and " ".join(BolumListesi.son_uyarilar).contains("elle_041"), " | ".join(BolumListesi.son_uyarilar))
	_a12_canli_temizle()


func _a12_guncelle_testleri() -> void:
	_a12_canli_temizle()
	var va := _a12_veri("guncel_001", "Eski Ad")
	CanliBolumler.canliya_al(va, A12_BOLUM_10, KOK)
	var eski_yol: String = BolumListesi.liste()[10]["yol"]
	var eski_paket := load(eski_yol) as PackedScene   # kaynak önbelleğine girsin: güncellemeden sonra eski içerik dönmemeli
	var eski_ornek := eski_paket.instantiate()
	var eski_say: int = eski_ornek.get_child_count()
	eski_ornek.free()

	var va2: Dictionary = va.duplicate(true)
	va2["ad"] = "Yeni Ad"
	(va2["nesneler"] as Array).append({"tur": "blok", "id": "EkBlok", "alan": [300, 500, 60, 20]})
	_k12("degisti_mi: içerik değişince true, değişmemiş kopyada false",
		CanliBolumler.degisti_mi(va2, KOK) and not CanliBolumler.degisti_mi(va, KOK), "")
	var sorun := CanliBolumler.guncelle(va2, KOK)
	var yeni_yol: String = BolumListesi.liste()[10]["yol"]
	var yeni_ornek: Node = (load(yeni_yol) as PackedScene).instantiate()
	_k12("Canlıyı güncelle: yeni sürüm yolu (_v002), eski dosya silinmiş, yeni sahne yeni adı ve yeni bloğu taşır (önbellek eskiyi döndürmez)",
		sorun.is_empty() and eski_yol.ends_with("_v001.tscn") and yeni_yol.ends_with("_v002.tscn") and not FileAccess.file_exists(eski_yol)
		and str(yeni_ornek.get_meta("editor_ad")) == "Yeni Ad" and yeni_ornek.get_node_or_null("EkBlok") != null and yeni_ornek.get_child_count() == eski_say + 1,
		"%s -> %s, çocuk %d" % [eski_yol.get_file(), yeni_yol.get_file(), yeni_ornek.get_child_count()])
	yeni_ornek.free()
	_k12("güncellemeden sonra sıra korunur (10'dan sonra), ad ve HUD başlığı yeni; liste hâlâ 22",
		BolumListesi.liste().size() == 22 and BolumListesi.sonraki(A12_BOLUM_10) == yeni_yol and BolumListesi.ad(yeni_yol) == "Yeni Ad"
		and BolumListesi.baslik(yeni_yol) == "Bölüm 11 · Yeni Ad" and not CanliBolumler.degisti_mi(va2, KOK), "")
	_k12("güncelleme canlı olmayan bölümde C4 verir", CanliBolumler.guncelle(_a12_veri("hic_001", "Hic"), KOK)[0]["kod"] == CanliBolumler.KOD_DEGIL, "")
	var h := CanliBolumler.kaldir("guncel_001", KOK)
	_k12("güncellenmiş canlı bölüm kaldırılabilir: yalnız güncel sahne ve JSON silinir, canli/ altında artık dosya kalmaz",
		h == OK and not FileAccess.file_exists(yeni_yol) and _canli_tscn_say() == 0 and BolumListesi.liste().size() == 21, "")
	_a12_canli_temizle()


func _canli_tscn_say() -> int:
	var n := 0
	for f in DirAccess.get_files_at(KOK + "canli"):
		if f.ends_with(".tscn"):
			n += 1
	return n


func _a12_arayuz_testleri() -> void:
	_dizin_sil(KOK)
	BolumListesi.yenile()
	var dog := _a12_veri("a12_dog_001", "Dogrulanmis", true)
	var coz := _a12_veri("a12_coz_001", "Cozumsuz")
	var hat := BolumVerisi.bos("Hatali", "a12_hat_001")
	BolumVerisi.yaz(dog, BolumYollari.bolumler_dizini(KOK) + "a12_dog_001.json")
	BolumVerisi.yaz(coz, BolumYollari.bolumler_dizini(KOK) + "a12_coz_001.json")
	BolumVerisi.yaz(hat, BolumYollari.bolumler_dizini(KOK) + "a12_hat_001.json")
	var coz_ozet := BolumVerisi.icerik_ozeti(coz)
	EditorOturumu.kok = KOK
	var bl: Node = await r.call("_ar_sahne_yukle", BOLUMLERIM_SAHNESI)
	bl.kok = KOK
	bl.yenile()

	var s_coz: Dictionary = bl.satir("a12_coz_001.json")
	var s_dog: Dictionary = bl.satir("a12_dog_001.json")
	var s_hat: Dictionary = bl.satir("a12_hat_001.json")
	var dugme_coz: Button = bl.liste_kutusu.get_node("Satir_a12_coz_001/CanliDugmesi")
	var dugme_hat: Button = bl.liste_kutusu.get_node("Satir_a12_hat_001/CanliDugmesi")
	_k12("Bölümlerim: her satırda 'Canlıya al' düğmesi; statik HATA'lı satırda kapalı, öbürlerinde açık; canlı bilgisi yok",
		dugme_coz != null and not dugme_coz.disabled and dugme_hat != null and dugme_hat.disabled
		and not bool(s_coz["canli"]) and int(s_coz["canli_no"]) == 0 and not Bolumlerim.satir_metni(s_coz).contains("Canlı:"), "")
	_k12("statik HATA'lı bölüm canlıya alınamaz: canli_iste false, mesaj 'Canlıya alınamaz', diyalog açılmaz, liste 21",
		not bl.canli_iste("a12_hat_001.json") and bl.durum_mesaji.begins_with("Canlıya alınamaz") and not bl.uyari_diyalogu.visible
		and not bl.sira_diyalogu.visible and BolumListesi.liste().size() == 21, bl.durum_mesaji)

	# --- çözümsüz: önce uyarı, onaysız hiçbir şey eklenmez
	var basladi: bool = bl.canli_iste("a12_coz_001.json")
	_k12("çözümsüz bölüm: 'Çözüm doğrulanmadı, yine de ekleyeyim mi?' uyarısı açılır, sıra diyaloğu henüz açık değil, liste değişmez",
		basladi and bl.uyari_diyalogu.visible and bl.uyari_diyalogu.dialog_text.begins_with("Çözüm doğrulanmadı, yine de ekleyeyim mi?")
		and not bl.sira_diyalogu.visible and BolumListesi.liste().size() == 21, bl.uyari_diyalogu.dialog_text)
	bl.canli_iptal()
	_k12("uyarıya 'İptal': akış biter, hiçbir şey eklenmez, canli/ dizini oluşmaz",
		not bl.uyari_diyalogu.visible and not bl.sira_diyalogu.visible and BolumListesi.liste().size() == 21 and not DirAccess.dir_exists_absolute(KOK + "canli")
		and not bl.canli_onayla(), "")
	bl.canli_iste("a12_coz_001.json")
	bl.canli_uyari_onayla()
	var secenekler: int = bl.sira_secici.item_count
	_k12("uyarıya 'Evet' → sıra diyaloğu: 'En başa' + 21 bölüm = 22 seçenek, varsayılan en sonda; seçenek metni bölüm numarası ve adını taşır",
		bl.sira_diyalogu.visible and not bl.uyari_diyalogu.visible and secenekler == 22 and bl.sira_secici.selected == 21
		and bl.sira_secici.get_item_text(0) == "En başa" and bl.sira_secici.get_item_text(10) == "Şundan sonra: Bölüm 10 · Hat", bl.sira_secici.get_item_text(10))
	bl.canli_sira_sec(10)
	var tamam: bool = bl.canli_onayla()
	var s_coz2: Dictionary = bl.satir("a12_coz_001.json")
	_k12("sıra olarak 'Bölüm 10 · Hat' seçilince bölüm 10 ile 11 arasına eklenir: canlı bölüm 11, mesaj ve satır metni 'Canlı: Bölüm 11'",
		tamam and BolumListesi.liste().size() == 22 and BolumListesi.indeks(A12_BOLUM_11) == 11 and bool(s_coz2["canli"]) and int(s_coz2["canli_no"]) == 11
		and bl.durum_mesaji.begins_with("Canlıya alındı: Bölüm 11") and Bolumlerim.satir_metni(s_coz2).contains("Canlı: Bölüm 11"), bl.durum_mesaji)
	var satir_coz: Node = bl.liste_kutusu.get_node("Satir_a12_coz_001")
	_k12("canlı satırda 'Canlıya al' yok; 'Canlıdan kaldır' açık; değişmediği için 'Canlıyı güncelle' kapalı",
		satir_coz.get_node_or_null("CanliDugmesi") == null and not (satir_coz.get_node("KaldirDugmesi") as Button).disabled
		and (satir_coz.get_node("GuncelleDugmesi") as Button).disabled, "")
	var ayna: Dictionary = BolumVerisi.oku(str(s_coz2["yol"]))["veri"]
	_k12("Bölümlerim JSON'unda canli aynası yazılır (alindi, sonra, sahne, canli_ozet); içerik özeti değişmez",
		ayna.get("canli", {}).get("alindi") == true and ayna["canli"]["sonra"] == A12_BOLUM_10 and ayna["canli"]["sahne"] == "a12_coz_001_v001.tscn"
		and ayna["canli"]["canli_ozet"] == coz_ozet and BolumVerisi.icerik_ozeti(ayna) == coz_ozet, JSON.stringify(ayna.get("canli", {})))
	bl.sil_iste("a12_coz_001.json")
	_k12("canlı bölüm silinemez: sil_iste mesaj verir, onay beklemez, dosya yerinde",
		bl.durum_mesaji.begins_with("Canlı bölüm silinemez") and bl._silinecek == "" and FileAccess.file_exists(str(s_coz2["yol"])), bl.durum_mesaji)
	_k12("zaten canlı bölümde canli_iste false (güncelle kullanılmalı)", not bl.canli_iste("a12_coz_001.json") and bl.durum_mesaji.contains("zaten canlı"), bl.durum_mesaji)

	# --- doğrulanmış bölüm: uyarı yok, doğrudan sıra seçimi; en başa
	var basladi2: bool = bl.canli_iste("a12_dog_001.json")
	_k12("doğrulanmış bölüm: uyarı çıkmaz, doğrudan sıra diyaloğu açılır",
		basladi2 and not bl.uyari_diyalogu.visible and bl.sira_diyalogu.visible, "")
	bl.canli_sira_sec(0)
	_k12("'En başa' seçilince doğrulanmış bölüm 1. sıraya girer; çözümsüz olan 12. numaraya kayar (satırda hemen görünür)",
		bl.canli_onayla() and BolumListesi.liste()[0]["kimlik"] == "a12_dog_001" and int(bl.satir("a12_dog_001.json")["canli_no"]) == 1
		and int(bl.satir("a12_coz_001.json")["canli_no"]) == 12 and BolumListesi.liste().size() == 23, str(_a12_sira_kimlikleri()))

	# --- değişiklik → Canlıyı güncelle (onay, çözümsüz uyarısı)
	var coz_yeni: Dictionary = coz.duplicate(true)
	(coz_yeni["nesneler"] as Array).append({"tur": "blok", "id": "EkBlok", "alan": [300, 500, 60, 20]})
	BolumVerisi.yaz(coz_yeni, BolumYollari.bolumler_dizini(KOK) + "a12_coz_001.json")
	bl.yenile()
	var satir_coz2: Node = bl.liste_kutusu.get_node("Satir_a12_coz_001")
	_k12("Bölümlerim'de içerik değişince satır '(değişti)' der ve 'Canlıyı güncelle' açılır",
		bool(bl.satir("a12_coz_001.json")["canli_degisti"]) and Bolumlerim.satir_metni(bl.satir("a12_coz_001.json")).contains("(değişti)")
		and not (satir_coz2.get_node("GuncelleDugmesi") as Button).disabled, Bolumlerim.satir_metni(bl.satir("a12_coz_001.json")))
	var eski_sahne: String = CanliBolumler.sahne_yolu("a12_coz_001", KOK)
	bl.guncelle_iste("a12_coz_001.json")
	_k12("güncelle isteği onay ister: çözümsüz olduğu için metin 'Çözüm doğrulanmadı' uyarısını içerir; onaydan önce canlı kopya aynı",
		bl.onay_diyalogu.visible and bl.onay_diyalogu.dialog_text.contains("Çözüm doğrulanmadı") and CanliBolumler.sahne_yolu("a12_coz_001", KOK) == eski_sahne, bl.onay_diyalogu.dialog_text)
	bl._onay_verildi()
	var yeni_sahne: String = CanliBolumler.sahne_yolu("a12_coz_001", KOK)
	_k12("onaylanınca canlı kopya güncellenir: yeni sürüm yolu, eski dosya yok, numara 12 korunur, '(değişti)' kalkar",
		yeni_sahne != eski_sahne and yeni_sahne.ends_with("_v002.tscn") and not FileAccess.file_exists(eski_sahne) and int(bl.satir("a12_coz_001.json")["canli_no"]) == 12
		and not bool(bl.satir("a12_coz_001.json")["canli_degisti"]) and bl.durum_mesaji.begins_with("Canlı kopya güncellendi"), bl.durum_mesaji)

	# --- kaldırma: onay, iptal, onay
	bl.kaldir_iste("a12_dog_001.json")
	_k12("Canlıdan kaldır isteği onay ister (diyalog açık, mod 'kaldir'); iptalde canlı kalır",
		bl.onay_diyalogu.visible and bl._onay_modu == "kaldir" and bl.onay_diyalogu.dialog_text.contains("numarası geri kayar"), "")
	bl.sil_iptal()
	_k12("iptal: bölüm hâlâ canlı", CanliBolumler.canli_mi("a12_dog_001", KOK) and BolumListesi.liste().size() == 23, "")
	bl.kaldir_iste("a12_dog_001.json")
	bl._onay_verildi()
	var ayna2: Dictionary = BolumVerisi.oku(str(bl.satir("a12_dog_001.json")["yol"]))["veri"]
	_k12("onaylanınca canlıdan kalkar: liste 22, çözümsüz bölümün numarası 11'e geri kayar, canlı ayna silinir, Bölümlerim'de kalır, satırda 'Canlıya al' geri gelir",
		not CanliBolumler.canli_mi("a12_dog_001", KOK) and BolumListesi.liste().size() == 22 and int(bl.satir("a12_coz_001.json")["canli_no"]) == 11
		and not ayna2.has("canli") and not bool(bl.satir("a12_dog_001.json")["canli"])
		and bl.liste_kutusu.get_node("Satir_a12_dog_001").get_node_or_null("CanliDugmesi") != null and bl.durum_mesaji.begins_with("Canlıdan kaldırıldı"), bl.durum_mesaji)
	_k12("canlı sahne ve dondurulmuş JSON diskten silindi (a12_dog_001), öteki canlı kopya yerinde",
		not FileAccess.file_exists(KOK + "canli/a12_dog_001.json") and FileAccess.file_exists(KOK + "canli/a12_coz_001.json"), "")
	EditorOturumu.temizle()


## Gözden geçirici bulguları: aynı yere ikinci ekleme, kardeş sırası, bozuk sira.json, yetim kayıt, mutlak çapalar.
func _a12_sira_sagligi_testleri() -> void:
	_a12_canli_temizle()
	# --- mutlak çapalar (canlı yokken): beklenen değerler işlevden türetilmez
	_k12("canlı yokken mutlak çapalar: Bölüm 1'den sonra Bölüm 2, Bölüm 14 'Çekirdek', Bölüm 21 son",
		BolumListesi.sonraki(A12_BOLUM_1) == "res://scenes/bolumler/bolum_2.tscn" and BolumListesi.baslik("res://scenes/bolumler/bolum_14.tscn") == "Bölüm 14 · Çekirdek"
		and BolumListesi.baslik(A12_BOLUM_21) == "Bölüm 21 · Fitil ve Mühür" and BolumListesi.sonraki(A12_BOLUM_21) == "", "")

	# --- aynı yere ikinci ekleme: yeni kayıt "hemen sonra" gelir, öncekiler (ve zincirleri) arkasına geçer
	var s1 := CanliBolumler.canliya_al(_a12_veri("ilk_001", "Ilk"), A12_BOLUM_10, KOK)
	var s2 := CanliBolumler.canliya_al(_a12_veri("zincir_001", "Zincir"), "canli:ilk_001", KOK)
	var s3 := CanliBolumler.canliya_al(_a12_veri("ikinci_001", "Ikinci"), A12_BOLUM_10, KOK)
	var d1 := _a12_sira_kimlikleri().slice(9, 14)
	_k12("aynı yere (bölüm 10'dan sonra) ikinci ekleme: yeni kayıt 11. sırada, öncekiler ve zinciri arkasında",
		s1.is_empty() and s2.is_empty() and s3.is_empty() and d1 == ["bolum_10", "ikinci_001", "ilk_001", "zincir_001", "bolum_11"], str(d1))
	var s4 := CanliBolumler.canliya_al(_a12_veri("bas_a_001", "BasA"), "", KOK)
	var s5 := CanliBolumler.canliya_al(_a12_veri("bas_b_001", "BasB"), "", KOK)
	_k12("'En başa' iki kez: ikinci eklenen 1. sırada, öncekisi 2.",
		s4.is_empty() and s5.is_empty() and _a12_sira_kimlikleri().slice(0, 3) == ["bas_b_001", "bas_a_001", "bolum_1"], str(_a12_sira_kimlikleri().slice(0, 3)))

	# --- kaldırmada kardeş sırası korunur: [X'in kardeşleri A, C], B A'nın ardında -> A kalkınca X, B, C
	_a12_canli_temizle()
	CanliBolumler.canliya_al(_a12_veri("kard_c_001", "C"), A12_BOLUM_10, KOK)
	CanliBolumler.canliya_al(_a12_veri("kard_a_001", "A"), A12_BOLUM_10, KOK)   # A, C'nin önüne girer
	CanliBolumler.canliya_al(_a12_veri("kard_b_001", "B"), "canli:kard_a_001", KOK)
	var once := _a12_sira_kimlikleri().slice(9, 14)
	CanliBolumler.kaldir("kard_a_001", KOK)
	var sonra := _a12_sira_kimlikleri().slice(9, 13)
	_k12("kaldirma kardeş sırasını bozmaz: 10, A, B, C -> A kalkınca 10, B, C",
		once == ["bolum_10", "kard_a_001", "kard_b_001", "kard_c_001", "bolum_11"] and sonra == ["bolum_10", "kard_b_001", "kard_c_001", "bolum_11"], "%s -> %s" % [str(once), str(sonra)])

	# --- bozuk sira.json üstüne yazılmaz, canlı kayıtlar kaybolmaz
	_a12_canli_temizle()
	CanliBolumler.canliya_al(_a12_veri("saglam_001", "Saglam"), A12_BOLUM_10, KOK)
	var bozuk_metin := "{ yarim yazilmis"
	_metin_yaz(KOK + "canli/sira.json", bozuk_metin)
	BolumListesi.yenile()
	var s6 := CanliBolumler.canliya_al(_a12_veri("yeni_001", "Yeni"), "", KOK)
	var s7 := CanliBolumler.guncelle(_a12_veri("saglam_001", "Saglam 2"), KOK)
	var h8 := CanliBolumler.kaldir("saglam_001", KOK)
	_k12("bozuk sira.json: canlıya al/güncelle/kaldır reddedilir (C6), dosya olduğu gibi kalır, sahne dosyaları silinmez",
		not s6.is_empty() and s6[0]["kod"] == CanliBolumler.KOD_BOZUK_SIRA and not s7.is_empty() and s7[0]["kod"] == CanliBolumler.KOD_BOZUK_SIRA and h8 != OK
		and FileAccess.get_file_as_string(KOK + "canli/sira.json") == bozuk_metin and FileAccess.file_exists(KOK + "canli/saglam_001_v001.tscn")
		and not FileAccess.file_exists(KOK + "canli/yeni_001.json"), "%s %s %d" % [_ozet_metni(s6), _ozet_metni(s7), h8])
	# geçersiz tek kayıt da yazmayı engeller (üstüne yazılırsa kayıt kaybolur)
	_metin_yaz(KOK + "canli/sira.json", JSON.stringify({"surum": 1, "canli": [
		{"kimlik": "saglam_001", "ad": "Saglam", "sahne": "saglam_001_v001.tscn", "sonra": A12_BOLUM_10, "icerik_ozeti": "x", "cozum_yok": true},
		{"kimlik": "../kotu", "ad": "Kotu", "sahne": "kotu.tscn", "sonra": ""}]}))
	BolumListesi.yenile()
	var s9 := CanliBolumler.canliya_al(_a12_veri("yeni_002", "Yeni"), "", KOK)
	_k12("geçersiz kayıt içeren sira.json'a da yazılmaz (geçersiz kayıt sessizce silinmesin); liste yine geçerli kaydı gösterir",
		not s9.is_empty() and s9[0]["kod"] == CanliBolumler.KOD_BOZUK_SIRA and BolumListesi.liste().size() == 22, _ozet_metni(s9))

	# --- Bölümlerim: sira.json'da olup listede görünmeyen (sahne dosyası silinmiş) kayıt canlı sayılır, kaldırılabilir
	_a12_canli_temizle()
	var yetim := _a12_veri("yetim_001", "Yetim")
	BolumVerisi.yaz(yetim, BolumYollari.bolumler_dizini(KOK) + "yetim_001.json")
	CanliBolumler.canliya_al(yetim, A12_BOLUM_10, KOK)
	DirAccess.remove_absolute(KOK + "canli/yetim_001_v001.tscn")
	BolumListesi.yenile()
	var satirlar := Bolumlerim.tara(KOK)
	var sy: Dictionary = {}
	for k in satirlar:
		if k["kimlik"] == "yetim_001":
			sy = k
	_k12("sahne dosyası silinmiş canlı kayıt: Bölümlerim satırı yine canlı (numara 0), metin 'listede değil', Canlıya al yerine kaldırılabilir; kaldırınca kayıt silinir",
		not sy.is_empty() and sy["canli"] == true and sy["canli_no"] == 0 and Bolumlerim.satir_metni(sy).contains("listede değil")
		and CanliBolumler.kaldir("yetim_001", KOK) == OK and CanliBolumler.sira_oku(KOK).is_empty(), Bolumlerim.satir_metni(sy) if not sy.is_empty() else "satır yok")

	# --- ilk canlıya almada canli/ dizini yokken de çalışır
	_dizin_sil(KOK + "canli")
	BolumListesi.yenile()
	var s10 := CanliBolumler.canliya_al(_a12_veri("ilkdizin_001", "IlkDizin"), "", KOK)
	_k12("canli/ dizini yokken ilk canlıya alma çalışır (sahne _v001)", s10.is_empty() and FileAccess.file_exists(KOK + "canli/ilkdizin_001_v001.tscn"), _ozet_metni(s10))
	_a12_canli_temizle()


# ---------------------------------------------------------------- A12 görsel bulgu düzeltmeleri

## WCAG göreli parlaklık / kontrast oranı.
func _a12_parlaklik(c: Color) -> float:
	var kanal := func(v: float) -> float:
		return v / 12.92 if v <= 0.03928 else pow((v + 0.055) / 1.055, 2.4)
	return 0.2126 * kanal.call(c.r) + 0.7152 * kanal.call(c.g) + 0.0722 * kanal.call(c.b)


func _a12_kontrast(a: Color, b: Color) -> float:
	var la := _a12_parlaklik(a)
	var lb := _a12_parlaklik(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


## scripts/ altındaki .gd dosyaları (özyinelemeli).
func _a12_betikler(dizin: String, cikti: Array) -> Array:
	var d := DirAccess.open(dizin)
	if d == null:
		return cikti
	for alt in d.get_directories():
		_a12_betikler(dizin.path_join(alt), cikti)
	for f in d.get_files():
		if f.ends_with(".gd"):
			cikti.append(dizin.path_join(f))
	return cikti


func _a12_diyalog_ozeti(d: AcceptDialog) -> Array:
	var iptal := (d as ConfirmationDialog).cancel_button_text if d is ConfirmationDialog else "İptal"
	return [d.name, d.title, d.ok_button_text, iptal]


func _a12_gorsel_testleri() -> void:
	_dizin_sil(KOK)
	BolumListesi.yenile()
	# 40 karakterlik ad (en uzun geçerli), çözümsüz ve uyarılı bölüm + doğrulanmış kısa ad
	var uzun_ad := "Çok Uzun Bir Bölüm Adı Deneme Satırı 400"   # 40 karakter (en uzun geçerli ad)
	var uzun := _a12_veri("gorsel_uzun_001", uzun_ad)
	var kisa := _a12_veri("gorsel_kisa_001", "Kisa", true)
	BolumVerisi.yaz(uzun, BolumYollari.bolumler_dizini(KOK) + "gorsel_uzun_001.json")
	BolumVerisi.yaz(kisa, BolumYollari.bolumler_dizini(KOK) + "gorsel_kisa_001.json")
	BolumVerisi.yaz(BolumVerisi.bos("Hatali Bos", "gorsel_hata_001"), BolumYollari.bolumler_dizini(KOK) + "gorsel_hata_001.json")
	CanliBolumler.canliya_al(uzun, A12_BOLUM_10, KOK)
	CanliBolumler.canliya_al(kisa, "", KOK)
	EditorOturumu.kok = KOK
	var bl: Node = await r.call("_ar_sahne_yukle", BOLUMLERIM_SAHNESI)
	bl.kok = KOK
	bl.yenile()
	await r.process_frame
	await r.process_frame
	await r.process_frame

	# --- 1) Bölümlerim satırı: üstte ad, altta durum + canlı bilgisi
	var satir: Node = bl.liste_kutusu.get_node("Satir_gorsel_uzun_001")
	var ad_et: Label = satir.get_node("Bilgi/Metin")
	var durum_et: Label = satir.get_node("Bilgi/DurumSatiri")
	var kayit: Dictionary = bl.satir("gorsel_uzun_001.json")
	_k12g("satır iki satırlı: ad üstte (tam 40 karakter), durum/canlı/uyarı altta ayrı Label'da",
		ad_et.text == uzun_ad and uzun_ad.length() == 40 and durum_et.text.contains("Canlı: Bölüm 12") and not ad_et.text.contains("Canlı")
		and durum_et.text == Bolumlerim.durum_metni(kayit) and Bolumlerim.satir_metni(kayit) == "%s · %s" % [uzun_ad, durum_et.text], durum_et.text)
	var tam_ad := ad_et.get_theme_font("font").get_string_size(ad_et.text, HORIZONTAL_ALIGNMENT_LEFT, -1, ad_et.get_theme_font_size("font_size")).x
	_k12g("40 karakterlik ad satırda sığar (kırpılmaz): ad genişliği <= Label genişliği; kırpılsa ellipsis + tam metin ipucu ayarlı",
		ad_et.size.x >= tam_ad - 0.5 and ad_et.text_overrun_behavior == TextServer.OVERRUN_TRIM_ELLIPSIS
		and ad_et.tooltip_text == Bolumlerim.satir_metni(kayit) and durum_et.tooltip_text == Bolumlerim.satir_metni(kayit)
		and ad_et.mouse_filter != Control.MOUSE_FILTER_IGNORE, "ad %.0f px, Label %.0f px" % [tam_ad, ad_et.size.x])
	var kaydirma: Control = bl.get_node("Panel").find_child("Kaydirma", true, false) if bl.get_node_or_null("Panel") != null else null
	var panel_ok := true
	var sorun := ""
	for satir_dugumu in bl.liste_kutusu.get_children():
		var sag := (satir_dugumu as Control).get_global_rect().end.x
		var kap := kaydirma.get_global_rect().end.x if kaydirma != null else 1.0e9
		if sag > kap + 1.0:
			panel_ok = false
			sorun += " %s(sağ %.0f > %.0f)" % [satir_dugumu.name, sag, kap]
		for d in satir_dugumu.get_children():
			if d is Button and (d as Button).get_minimum_size().x > (d as Button).size.x + 0.5:
				panel_ok = false
				sorun += " %s/%s metin sığmıyor" % [satir_dugumu.name, d.name]
	_k12g("hiçbir satır kaydırma alanının sağından taşmaz, hiçbir satır düğmesinin metni kırpılmaz (panel %d px)" % Bolumlerim.PANEL_GENISLIK,
		panel_ok and Bolumlerim.PANEL_GENISLIK >= 880 and Bolumlerim.PANEL_GENISLIK <= 1100, sorun)
	var coz_ok := durum_et.autowrap_mode != TextServer.AUTOWRAP_OFF and durum_et.get_minimum_size().y > 0.0
	# Durum satırı kırpılmaz: sarar. Yüksekliği içeriğe yeter (gerekli yükseklik <= verilen yükseklik).
	var gerekli := durum_et.get_theme_font("font").get_multiline_string_size(durum_et.text, HORIZONTAL_ALIGNMENT_LEFT, maxf(durum_et.size.x, 1.0), durum_et.get_theme_font_size("font_size")).y
	_k12g("durum satırı sarar ve içeriği tam gösterir (kırpılmaz, tek satıra zorlanmaz)", coz_ok and durum_et.size.y >= gerekli - 1.0 and not durum_et.clip_text,
		"gerekli %.0f px, Label %.0f px" % [gerekli, durum_et.size.y])
	var hata_satiri: Node = bl.liste_kutusu.get_node("Satir_gorsel_hata_001")
	_k12g("hatalı bölümün alt satırı amber ve '1 hata' içerir; doğrulanmış kısa ad satırında 'Doğrulandı · Canlı: Bölüm 1'",
		(hata_satiri.get_node("Bilgi/DurumSatiri") as Label).text.contains("1 hata") and (hata_satiri.get_node("Bilgi/DurumSatiri") as Label).get_theme_color("font_color") == LabPaleti.AMBER
		and (bl.liste_kutusu.get_node("Satir_gorsel_kisa_001/Bilgi/DurumSatiri") as Label).text == "Doğrulandı · Canlı: Bölüm 1", (hata_satiri.get_node("Bilgi/DurumSatiri") as Label).text)

	# --- 2) sıra diyaloğu: açıklama görünür, OptionButton'ın üstünde
	bl.canli_iste("gorsel_hata_001.json")   # engellenir (statik HATA): akış açılmaz
	bl._canli_dosya = "gorsel_hata_001.json"
	bl.canli_sira_ac()
	await r.process_frame
	await r.process_frame
	var kap_ic: Node = bl.sira_secici.get_parent()
	var aciklama: Label = bl.sira_aciklama
	_k12g("sıra diyaloğu: açıklama metni ('hemen sonra gelir') Label olarak seçicinin ÜSTÜNDE, ikisi aynı kapta ve görünür",
		aciklama != null and aciklama.text.begins_with("Canlı bölüm, seçtiğiniz bölümden hemen sonra gelir") and aciklama.is_visible_in_tree()
		and kap_ic == aciklama.get_parent() and kap_ic.get_parent() == bl.sira_diyalogu and aciklama.get_index() < bl.sira_secici.get_index()
		and bl.sira_secici.is_visible_in_tree() and bl.sira_diyalogu.dialog_text == "", "kap=%s" % kap_ic.name)
	_k12g("sıra diyaloğu: açıklama ile seçici üst üste binmez (açıklamanın alt kenarı <= seçicinin üst kenarı)",
		aciklama.position.y + aciklama.size.y <= bl.sira_secici.position.y + 0.5 and aciklama.size.y > 0.0, "%.0f+%.0f vs %.0f" % [aciklama.position.y, aciklama.size.y, bl.sira_secici.position.y])
	bl.canli_iptal()

	# --- 3) diyalog başlıkları Türkçe (önce Bölümlerim, sonra editör: sahne değişimi öncekini siler)
	var diyaloglar: Array = []   # [ad, başlık, ok metni, iptal metni] (sahne değişince düğümler silinir)
	for dd in bl.find_children("*", "AcceptDialog", true, false):
		diyaloglar.append(_a12_diyalog_ozeti(dd))
	var bl_onay_baslik: String = bl.onay_diyalogu.title
	var bl_uyari_baslik: String = bl.uyari_diyalogu.title
	bl.sil_iste("gorsel_hata_001.json")
	_k12g("silme onayı açılınca başlık 'Onayla'", bl.onay_diyalogu.title == "Onayla" and bl.onay_diyalogu.dialog_text.begins_with(Bolumlerim.SIL_SORUSU), bl.onay_diyalogu.title)
	bl.sil_iptal()
	var ed: Node = await _ed()
	for dd in ed.find_children("*", "AcceptDialog", true, false):
		diyaloglar.append(_a12_diyalog_ozeti(dd))
	var ingilizce: Array = ["", "Please Confirm...", "Alert!", "OK", "Cancel"]
	var baslik_ok := diyaloglar.size() >= 4
	var baslik_ayr := ""
	for dy in diyaloglar:
		if ingilizce.has(dy[1]) or ingilizce.has(dy[2]) or ingilizce.has(dy[3]):
			baslik_ok = false
			baslik_ayr += " %s('%s'/'%s')" % [dy[0], dy[1], dy[2]]
	_k12g("tüm diyaloglar (Bölümlerim: onay, uyarı, sıra; editör: onay) Türkçe başlıklı, düğmeleri Türkçe",
		baslik_ok and bl_onay_baslik == "Onayla" and bl_uyari_baslik == "Uyarı" and ed.onay_diyalogu.title == "Onayla", "%d diyalog;%s" % [diyaloglar.size(), baslik_ayr])
	var kaynak_say := 0
	var baslik_say := 0
	var eksik_dosya := ""
	for yol in _a12_betikler("res://scripts", []):
		var metin := FileAccess.get_file_as_string(yol)
		var d_say := metin.count("ConfirmationDialog.new()") + metin.count("AcceptDialog.new()") + metin.count("FileDialog.new()")
		var t_say := metin.count(".title = ")
		kaynak_say += d_say
		baslik_say += t_say
		if d_say > t_say:
			eksik_dosya += " " + yol.get_file()
	_k12g("kaynak taraması: scripts/ altında oluşturulan her diyalog için bir '.title =' ataması var (varsayılan İngilizce başlık kalmaz)",
		kaynak_say >= 4 and eksik_dosya == "", "diyalog %d, title %d, eksik:%s" % [kaynak_say, baslik_say, eksik_dosya])
	ed.queue_free()

	# --- 4) haritada canlı işareti
	var h: Node = await r.call("_ar_sahne_yukle", A12_HARITA)
	await r.physics_frame
	var canli_say := 0
	var isaret_ok := true
	var etiket_ok := true
	var isaret_ayr := ""
	var kayitlar := BolumListesi.liste()
	for i in kayitlar.size():
		var dg: HaritaDugumu = h.get_node("Dugumler/Dugum%d" % (i + 1))
		var et: Label = h.get_node("Dugumler/Etiket%d" % (i + 1))
		var canli: bool = kayitlar[i]["kaynak"] == "canli"
		if canli:
			canli_say += 1
		isaret_ok = isaret_ok and dg.canli == canli
		if canli:
			etiket_ok = etiket_ok and et.text == "Bölüm %d: %s · Canlı" % [i + 1, kayitlar[i]["ad"]]
		else:
			# resmî düğüm: işaret yok, etiket eskisi gibi ("Bölüm N: Ad", 280 px, aynı konum)
			var konum: Vector2 = kayitlar[i]["konum"]
			var bek_x := clampf(konum.x - 140.0, 4.0, 1152.0 - 284.0)
			etiket_ok = etiket_ok and et.text == "Bölüm %d: %s" % [i + 1, kayitlar[i]["ad"]] and absf(et.size.x - 280.0) < 0.01 and absf(et.position.x - bek_x) < 0.01 \
				and absf(et.position.y - (konum.y + HaritaDugumu.YARICAP + 14.0)) < 0.01
			if not etiket_ok and isaret_ayr == "":
				isaret_ayr = "%d: x=%.1f/%.1f w=%.1f '%s'" % [i + 1, et.position.x, bek_x, et.size.x, et.text]
	_k12g("haritada yalnız canlı düğümler işaretli (2 canlı), resmî düğümlerde işaret yok",
		canli_say == 2 and isaret_ok, "canlı=%d" % canli_say)
	_k12g("canlı düğümün hover etiketi 'Bölüm N: Ad · Canlı'; resmî etiketler değişmedi (metin, 280 px genişlik, konum)", etiket_ok, isaret_ayr)
	var merkez := Vector2(40, 40)
	var halka := HaritaDugumu.canli_halka(merkez)
	var yaricap_ok := halka.size() == 7 and halka[0] == halka[6]
	for p in halka:
		var uz := (p - merkez).length()
		yaricap_ok = yaricap_ok and uz > HaritaDugumu.YARICAP + 1.0 and uz < HaritaDugumu.BOYUT.x / 2.0
	_k12g("canlı halka geometrisi: kapalı altıgen çizgi, düğüm altıgeninin dışında ve 80x80 kutunun içinde", yaricap_ok, str(halka.size()))
	var uzun_no := 0
	for i in kayitlar.size():
		if kayitlar[i]["kimlik"] == "gorsel_uzun_001":
			uzun_no = i + 1
	var uzun_etiket: Label = h.get_node("Dugumler/Etiket%d" % uzun_no)
	var uzun_konum: Vector2 = kayitlar[uzun_no - 1]["konum"]
	var orta_x := uzun_etiket.position.x + uzun_etiket.size.x / 2.0
	var kenetli: bool = absf(uzun_etiket.position.x - 4.0) < 0.01 or absf(uzun_etiket.position.x + uzun_etiket.size.x - 1148.0) < 0.01
	_k12g("uzun canlı etiket gerçek yazı genişliğine genişler (min boyut <= boyut), düğümün altında ortalanır (ya da ekran kenarına kenetlenir) ve ekran içinde kalır",
		uzun_etiket.size.x > 280.0 and uzun_etiket.get_minimum_size().x <= uzun_etiket.size.x + 0.01 and uzun_etiket.position.x >= 4.0 - 0.01
		and uzun_etiket.position.x + uzun_etiket.size.x <= 1148.0 + 0.01 and (absf(orta_x - uzun_konum.x) < 1.0 or kenetli),
		"w=%.0f min=%.0f x=%.0f orta=%.0f düğüm x=%.0f" % [uzun_etiket.size.x, uzun_etiket.get_minimum_size().x, uzun_etiket.position.x, orta_x, uzun_konum.x])
	# Sağ kenardaki düğümde (Bölüm 6, x=1040) uzun etiket ekrana kenetlenir ve taşmaz: aynı hesabın sınır durumu
	var sag_dugum_ok := true
	for i in range(kayitlar.size()):
		var et_i: Label = h.get_node("Dugumler/Etiket%d" % (i + 1))
		sag_dugum_ok = sag_dugum_ok and et_i.position.x >= 4.0 - 0.01 and et_i.position.x + et_i.size.x <= 1148.0 + 0.01
	_k12g("hiçbir harita etiketi ekran dışına taşmaz (tüm düğümler)", sag_dugum_ok, "")

	# --- 5) doğrulama şeridi uyarı kontrastı
	var dog := EditorDogrulama.new()
	r.root.add_child(dog)
	dog._arayuz_kur()
	var uyari_et: Label = dog.find_child("Uyari", true, false)
	var panel_stil: StyleBoxFlat = dog.find_child("Panel", true, false).get_theme_stylebox("panel")
	var yazi_rengi: Color = uyari_et.get_theme_color("font_color")
	var oran := _a12_kontrast(yazi_rengi, Color(panel_stil.bg_color, 1.0))
	var eski_oran := _a12_kontrast(LabPaleti.METAL, Color(panel_stil.bg_color, 1.0))
	_k12g("doğrulama şeridi uyarı yazısı kontrastı >= 4.5:1 (WCAG AA); eski METAL rengi bu eşiğin altındaydı",
		uyari_et != null and uyari_et.text == "Doğrulama sürerken tuşlara basmayın." and oran >= 4.5 and eski_oran < 4.5 and yazi_rengi == EditorDogrulama.UYARI_RENGI,
		"yeni %.2f:1, eski %.2f:1" % [oran, eski_oran])
	dog.queue_free()

	EditorOturumu.temizle()
	_dizin_sil(KOK)
	BolumListesi.yenile()


func _k12g(ad: String, ok: bool, ayr: String) -> void:
	_kaydi("Editör A12 görsel: " + ad, ok, ayr)
