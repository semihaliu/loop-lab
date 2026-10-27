class_name BolumVerisi
extends RefCounted
## Editör bölüm verisi (JSON biçimi): ayrıştırma, okuma/yazma, D1-D3 şema denetimi,
## içerik özeti, çözüm kaydı için çalıştırma uzunluğu (RLE) kodlaması, slug ve kimlik üretimi.
## Sahne kurmaz, oyun düğümlerine dokunmaz; rastgelelik ve gerçek saat kullanmaz.
##
## Sorun öğesi biçimi (bütün denetimler için ortak):
##   {"kod": "D2", "seviye": "HATA", "nesne": "Asansor1", "alan": "yukseklik", "mesaj": "..."}
## `nesne` nesne id'si (bölüm geneli için ""), `alan` alan adı ya da "".

const BICIM := "loop_lab_bolum"
const SURUM := 1
const TURLER: Array[String] = ["blok", "tek_yonlu", "bant", "plaka", "zamanli_plaka", "mandal_plaka", "salter", "ziplatici", "asansor", "gecit", "lazer", "kutu"]
const AYRILMIS: Array[String] = ["Oyuncu", "Bilgi", "Kapi", "SinirDuvarlari", "EditorHud"]
const AZAMI_NESNE := 200

## Plaka türleri (asansöre bağlanabilen tetikleyiciler).
const PLAKA_TURLERI: Array[String] = ["plaka", "zamanli_plaka", "mandal_plaka"]
## Geçit ve lazerin tetikleyicisi olabilen türler (plakalar + şalter).
const TETIK_TURLERI: Array[String] = ["plaka", "zamanli_plaka", "mandal_plaka", "salter"]
const LAZER_YONLERI: Array[String] = ["asagi", "yukari", "sag", "sol"]
const KIMLIK_DESENI := "^[a-z0-9_]{1,36}_[0-9]{3}$"
const ID_DESENI := "^[A-Za-z][A-Za-z0-9_]{0,23}$"
const SLUG_AZAMI := 36
const AD_AZAMI := 40

const UST_ALANLAR: Array[String] = ["bicim", "surum", "kimlik", "ad", "max_klon", "ipucu_klon", "baslangic", "cikis", "nesneler", "cozum", "dogrulama", "canli", "notlar"]
const UST_ZORUNLU: Array[String] = ["bicim", "surum", "kimlik", "ad", "max_klon", "baslangic", "cikis", "nesneler"]
## Kanonik özete girmeyen alanlar (içerik değil, kayıt/ayna bilgisi).
const OZET_DISI: Array[String] = ["cozum", "dogrulama", "canli", "notlar"]

## Tür başına zorunlu alanlar (tur ve id her nesnede zorunludur).
const ZORUNLU := {
	"blok": ["alan"],
	"tek_yonlu": ["konum"],
	"bant": ["konum"],
	"plaka": ["konum"],
	"zamanli_plaka": ["konum"],
	"mandal_plaka": ["konum"],
	"salter": ["konum"],
	"ziplatici": ["konum"],
	"asansor": ["konum"],
	"gecit": ["konum"],
	"lazer": ["konum"],
	"kutu": ["konum"],
}
## Tür başına isteğe bağlı alanlar.
const ISTEGE_BAGLI := {
	"blok": [],
	"tek_yonlu": [],
	"bant": ["yon"],
	"plaka": [],
	"zamanli_plaka": ["tutma_kare"],
	"mandal_plaka": [],
	"salter": ["baslangic_sagda"],
	"ziplatici": [],
	"asansor": ["yukseklik", "plaka", "kablo"],
	"gecit": ["kayma_mesafe", "tetikleyiciler", "acik_taraf_sag", "kablolar"],
	"lazer": ["yon", "uzunluk", "tetikleyiciler", "tetik_aktifken_kapali", "acik_taraf_sag", "kablolar"],
	"kutu": [],
}


# --- Sorun yardımcıları ---------------------------------------------------------------

static func _sorun(kod: String, seviye: String, nesne: String, alan: String, mesaj: String) -> Dictionary:
	return {"kod": kod, "seviye": seviye, "nesne": nesne, "alan": alan, "mesaj": mesaj}


static func _hata(kod: String, nesne: String, alan: String, mesaj: String) -> Dictionary:
	return _sorun(kod, "HATA", nesne, alan, mesaj)


## Tamsayı mı? (Tamsayı değerli float da kabul edilir; okuyucu zaten int'e çevirir.)
static func _tam(v: Variant) -> bool:
	if typeof(v) == TYPE_INT:
		return true
	if typeof(v) == TYPE_FLOAT:
		return is_finite(v) and v == floorf(v)
	return false


static func _sayi(v: Variant) -> bool:
	return (typeof(v) == TYPE_INT) or (typeof(v) == TYPE_FLOAT and is_finite(v))


static func _nokta_mi(v: Variant) -> bool:
	return typeof(v) == TYPE_ARRAY and v.size() == 2 and _tam(v[0]) and _tam(v[1])


## Tamsayı aralığı denetimi; sorunsa listeye D2 ekler.
static func _aralik(s: Array[Dictionary], nesne: String, alan: String, ad: String, v: Variant, alt: int, ust: int) -> void:
	if not _tam(v):
		s.append(_hata("D2", nesne, alan, "%s tamsayı olmalı (verilen: %s)" % [ad, str(v)]))
	elif int(v) < alt or int(v) > ust:
		s.append(_hata("D2", nesne, alan, "%s %d..%d olmalı (verilen: %d)" % [ad, alt, ust, int(v)]))


# --- Oluşturma, okuma, yazma ----------------------------------------------------------

## Geçerli, nesnesiz bölüm. Zemin yoktur: alt sınır açık olduğundan D6 verir.
static func bos(ad: String, kimlik: String) -> Dictionary:
	return {
		"bicim": BICIM,
		"surum": SURUM,
		"kimlik": kimlik,
		"ad": ad,
		"max_klon": 2,
		"ipucu_klon": 0,
		"baslangic": [200, 594],
		"cikis": [1050, 594],
		"nesneler": [],
	}


## JSON metnini ayrıştırır ve şema denetimini (D1-D3) çalıştırır.
## Dönüş: {"veri": Dictionary, "sorunlar": Array[Dictionary]}.
## JSON ayrıştırılamaz, kök sözlük değil ya da `bicim`/`surum` yanlışsa veri boş sözlüktür.
static func ayristir(metin: String) -> Dictionary:
	var sorunlar: Array[Dictionary] = []
	var json := JSON.new()
	var hata := json.parse(metin)
	if hata != OK:
		sorunlar.append(_hata("D2", "", "", "JSON ayrıştırılamadı (satır %d): %s" % [json.get_error_line(), json.get_error_message()]))
		return {"veri": {}, "sorunlar": sorunlar}
	if typeof(json.data) != TYPE_DICTIONARY:
		sorunlar.append(_hata("D2", "", "", "bölüm dosyasının kökü bir nesne olmalı"))
		return {"veri": {}, "sorunlar": sorunlar}
	var veri: Dictionary = _normalle(json.data)
	if str(veri.get("bicim", "")) != BICIM:
		sorunlar.append(_hata("D2", "", "bicim", "bicim \"%s\" olmalı" % BICIM))
		return {"veri": {}, "sorunlar": sorunlar}
	if not veri.has("surum") or not _tam(veri["surum"]) or int(veri["surum"]) != SURUM:
		sorunlar.append(_hata("D2", "", "surum", "surum %d olmalı (verilen: %s)" % [SURUM, str(veri.get("surum", "yok"))]))
		return {"veri": {}, "sorunlar": sorunlar}
	sorunlar.append_array(sema_denetle(veri))
	return {"veri": veri, "sorunlar": sorunlar}


## Dosyadan okur; dosya yoksa ya da açılamazsa D2 verir.
static func oku(yol: String) -> Dictionary:
	if not FileAccess.file_exists(yol):
		var yok: Array[Dictionary] = [_hata("D2", "", "", "dosya bulunamadı: %s" % yol)]
		return {"veri": {}, "sorunlar": yok}
	var f := FileAccess.open(yol, FileAccess.READ)
	if f == null:
		var acilamadi: Array[Dictionary] = [_hata("D2", "", "", "dosya açılamadı: %s (hata %d)" % [yol, FileAccess.get_open_error()])]
		return {"veri": {}, "sorunlar": acilamadi}
	var metin := f.get_as_text()
	f.close()
	return ayristir(metin)


## JSON.stringify(veri, "  ", true) ile yazar; dizini oluşturur.
static func yaz(veri: Dictionary, yol: String) -> Error:
	var dizin := yol.get_base_dir()
	if dizin != "" and not DirAccess.dir_exists_absolute(dizin):
		var h := DirAccess.make_dir_recursive_absolute(dizin)
		if h != OK:
			return h
	var f := FileAccess.open(yol, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(JSON.stringify(_normalle(veri), "  ", true))
	f.close()
	return OK


## Tamsayı değerli float'ları int'e çevirir (özyinelemeli kopya döner).
static func _normalle(v: Variant) -> Variant:
	match typeof(v):
		TYPE_DICTIONARY:
			var d := {}
			for k in v.keys():
				d[k] = _normalle(v[k])
			return d
		TYPE_ARRAY:
			var a := []
			for e in v:
				a.append(_normalle(e))
			return a
		TYPE_FLOAT:
			if is_finite(v) and v == floorf(v) and absf(v) < 9.0e15:
				return int(v)
			return v
	return v


# --- D1-D3 şema denetimi --------------------------------------------------------------

## Yalnız D1 (başlangıç/çıkış), D2 (şema ve aralıklar), D3 (bağlantılar). Hepsi HATA.
static func sema_denetle(veri: Dictionary) -> Array[Dictionary]:
	var s: Array[Dictionary] = []
	for k in veri.keys():
		if not UST_ALANLAR.has(str(k)):
			s.append(_hata("D2", "", str(k), "bilinmeyen alan: %s" % str(k)))
	for k in UST_ZORUNLU:
		if not veri.has(k) and k != "baslangic" and k != "cikis":
			s.append(_hata("D2", "", k, "zorunlu alan eksik: %s" % k))

	if veri.has("bicim") and str(veri["bicim"]) != BICIM:
		s.append(_hata("D2", "", "bicim", "bicim \"%s\" olmalı" % BICIM))
	if veri.has("surum") and (not _tam(veri["surum"]) or int(veri["surum"]) != SURUM):
		s.append(_hata("D2", "", "surum", "surum %d olmalı (verilen: %s)" % [SURUM, str(veri["surum"])]))

	if veri.has("kimlik"):
		var re := RegEx.new()
		re.compile(KIMLIK_DESENI)
		if typeof(veri["kimlik"]) != TYPE_STRING or re.search(veri["kimlik"]) == null:
			s.append(_hata("D2", "", "kimlik", "kimlik biçimi ^[a-z0-9_]{1,36}_[0-9]{3}$ olmalı (verilen: %s)" % str(veri["kimlik"])))
	if veri.has("ad"):
		if typeof(veri["ad"]) != TYPE_STRING or String(veri["ad"]).length() < 1 or String(veri["ad"]).length() > AD_AZAMI:
			s.append(_hata("D2", "", "ad", "ad 1..%d karakter olmalı" % AD_AZAMI))
	if veri.has("max_klon"):
		_aralik(s, "", "max_klon", "max_klon", veri["max_klon"], 1, 3)
	if veri.has("ipucu_klon"):
		if not _tam(veri["ipucu_klon"]) or int(veri["ipucu_klon"]) != 0:
			s.append(_hata("D2", "", "ipucu_klon", "ipucu_klon v1'de yalnızca 0 olabilir (verilen: %s)" % str(veri["ipucu_klon"])))
	if veri.has("notlar") and typeof(veri["notlar"]) != TYPE_STRING:
		s.append(_hata("D2", "", "notlar", "notlar metin olmalı"))
	_kayit_alanlari_denetle(veri, s)

	_nokta_alani_denetle(veri, "baslangic", "başlangıç", s)
	_nokta_alani_denetle(veri, "cikis", "çıkış", s)

	var nesneler: Array = []
	if veri.has("nesneler"):
		if typeof(veri["nesneler"]) != TYPE_ARRAY:
			s.append(_hata("D2", "", "nesneler", "nesneler bir dizi olmalı"))
		else:
			nesneler = veri["nesneler"]
			if nesneler.size() > AZAMI_NESNE:
				s.append(_hata("D2", "", "nesneler", "en çok %d nesne olabilir (verilen: %d)" % [AZAMI_NESNE, nesneler.size()]))

	var gorulen := {}   # id -> tur (yalnız geçerli nesneler)
	for n in nesneler:
		if typeof(n) != TYPE_DICTIONARY:
			s.append(_hata("D2", "", "nesneler", "nesne bir sözlük olmalı"))
			continue
		_nesne_denetle(n, s, gorulen)
	_baglanti_denetle(nesneler, gorulen, s)
	return s


## `baslangic` / `cikis`: tam 1 nokta (D1) ve biçim (D2).
static func _nokta_alani_denetle(veri: Dictionary, alan: String, ad: String, s: Array[Dictionary]) -> void:
	if not veri.has(alan):
		s.append(_hata("D1", "", alan, "tam 1 %s noktası olmalı (yok)" % ad))
		return
	var v: Variant = veri[alan]
	if typeof(v) == TYPE_ARRAY and v.size() >= 1 and typeof(v[0]) == TYPE_ARRAY:
		s.append(_hata("D1", "", alan, "tam 1 %s noktası olmalı (verilen: %d)" % [ad, v.size()]))
	elif not _nokta_mi(v):
		s.append(_hata("D2", "", alan, "%s [x, y] tamsayı çifti olmalı" % ad))


## cozum / dogrulama / canli alanlarının hafif tür denetimi.
static func _kayit_alanlari_denetle(veri: Dictionary, s: Array[Dictionary]) -> void:
	if veri.has("cozum"):
		var c: Variant = veri["cozum"]
		if typeof(c) != TYPE_DICTIONARY:
			s.append(_hata("D2", "", "cozum", "cozum bir nesne olmalı"))
		else:
			for k in c.keys():
				if str(k) != "turlar" and str(k) != "oyuncu":
					s.append(_hata("D2", "", "cozum", "cozum içinde bilinmeyen alan: %s" % str(k)))
			if c.has("turlar") and typeof(c["turlar"]) != TYPE_ARRAY:
				s.append(_hata("D2", "", "cozum", "cozum.turlar bir dizi olmalı"))
			if c.has("oyuncu") and typeof(c["oyuncu"]) != TYPE_ARRAY:
				s.append(_hata("D2", "", "cozum", "cozum.oyuncu bir dizi olmalı"))
	if veri.has("dogrulama"):
		var d: Variant = veri["dogrulama"]
		if typeof(d) != TYPE_DICTIONARY:
			s.append(_hata("D2", "", "dogrulama", "dogrulama bir nesne olmalı"))
		elif d.has("durum") and str(d["durum"]) != "taslak" and str(d["durum"]) != "dogrulandi":
			s.append(_hata("D2", "", "dogrulama", "dogrulama.durum \"taslak\" ya da \"dogrulandi\" olmalı"))
	if veri.has("canli") and typeof(veri["canli"]) != TYPE_DICTIONARY:
		s.append(_hata("D2", "", "canli", "canli bir nesne olmalı"))


## Tek nesnenin D1/D2 denetimi. Geçerli kimlikli nesneler `gorulen`e (id -> tur) yazılır.
static func _nesne_denetle(n: Dictionary, s: Array[Dictionary], gorulen: Dictionary) -> void:
	var tur: String = str(n.get("tur", ""))
	var id := ""
	var id_re := RegEx.new()
	id_re.compile(ID_DESENI)
	if typeof(n.get("id")) == TYPE_STRING:
		id = n["id"]
	var id_biciminde := id != "" and id_re.search(id) != null
	var id_kullanilabilir := false
	if not n.has("id"):
		s.append(_hata("D2", "", "id", "nesnede id eksik (tur: %s)" % tur))
	elif not id_biciminde:
		s.append(_hata("D2", id, "id", "id biçimi ^[A-Za-z][A-Za-z0-9_]{0,23}$ olmalı (verilen: %s)" % str(n["id"])))
	elif AYRILMIS.has(id):
		s.append(_hata("D2", id, "id", "%s ayrılmış bir addır" % id))
	elif gorulen.has(id):
		s.append(_hata("D2", id, "id", "yinelenen id: %s" % id))
	else:
		id_kullanilabilir = true
	var id_gecerli := id_biciminde
	var kayit_adi := id if id_gecerli else ""

	if not n.has("tur") or typeof(n["tur"]) != TYPE_STRING:
		s.append(_hata("D2", kayit_adi, "tur", "nesnede tur eksik ya da metin değil"))
		return
	# Başlangıç ve çıkış nesne olarak yazılamaz: tam 1 tane üst alanlarda durur.
	if tur == "baslangic" or tur == "cikis":
		s.append(_hata("D1", kayit_adi, "tur", "tam 1 %s olmalı; ek %s nesnesi eklenemez" % ["başlangıç" if tur == "baslangic" else "çıkış", "başlangıç" if tur == "baslangic" else "çıkış"]))
		return
	if not TURLER.has(tur):
		s.append(_hata("D2", kayit_adi, "tur", "bilinmeyen tür: %s" % tur))
		return
	if id_kullanilabilir:
		gorulen[id] = tur

	var zorunlu: Array = ZORUNLU[tur]
	var istege: Array = ISTEGE_BAGLI[tur]
	for k in n.keys():
		var ks := str(k)
		if ks != "tur" and ks != "id" and not zorunlu.has(ks) and not istege.has(ks):
			s.append(_hata("D2", kayit_adi, ks, "%s türünde bilinmeyen alan: %s" % [tur, ks]))
	for k in zorunlu:
		if not n.has(k):
			s.append(_hata("D2", kayit_adi, k, "zorunlu alan eksik: %s" % k))

	if n.has("alan"):
		var a: Variant = n["alan"]
		if typeof(a) != TYPE_ARRAY or a.size() != 4 or not (_tam(a[0]) and _tam(a[1]) and _tam(a[2]) and _tam(a[3])):
			s.append(_hata("D2", kayit_adi, "alan", "alan [x, y, gen, yuk] tamsayı dörtlüsü olmalı"))
		elif int(a[2]) < 10 or int(a[3]) < 10:
			s.append(_hata("D2", kayit_adi, "alan", "gen ve yuk en az 10 olmalı (verilen: %d x %d)" % [int(a[2]), int(a[3])]))
	if n.has("konum") and not _nokta_mi(n["konum"]):
		s.append(_hata("D2", kayit_adi, "konum", "konum [x, y] tamsayı çifti olmalı"))
	if n.has("yon"):
		if tur == "bant":
			if not _tam(n["yon"]) or (int(n["yon"]) != 1 and int(n["yon"]) != -1):
				s.append(_hata("D2", kayit_adi, "yon", "bant yönü 1 ya da -1 olmalı (verilen: %s)" % str(n["yon"])))
		elif typeof(n["yon"]) != TYPE_STRING or not LAZER_YONLERI.has(n["yon"]):
			s.append(_hata("D2", kayit_adi, "yon", "lazer yönü asagi, yukari, sag ya da sol olmalı (verilen: %s)" % str(n["yon"])))
	if n.has("tutma_kare"):
		_aralik(s, kayit_adi, "tutma_kare", "tutma_kare", n["tutma_kare"], 1, 600)
	if n.has("yukseklik"):
		_aralik(s, kayit_adi, "yukseklik", "yükseklik", n["yukseklik"], 20, 600)
	if n.has("kayma_mesafe"):
		_aralik(s, kayit_adi, "kayma_mesafe", "kayma_mesafe", n["kayma_mesafe"], 10, 200)
	if n.has("uzunluk") and (not _sayi(n["uzunluk"]) or float(n["uzunluk"]) <= 0.0):
		s.append(_hata("D2", kayit_adi, "uzunluk", "uzunluk 0'dan büyük bir sayı olmalı (verilen: %s)" % str(n["uzunluk"])))
	for bayrak in ["baslangic_sagda", "acik_taraf_sag", "tetik_aktifken_kapali"]:
		if n.has(bayrak) and typeof(n[bayrak]) != TYPE_BOOL:
			s.append(_hata("D2", kayit_adi, bayrak, "%s true ya da false olmalı" % bayrak))
	if n.has("plaka") and typeof(n["plaka"]) != TYPE_STRING:
		s.append(_hata("D2", kayit_adi, "plaka", "plaka bir nesne id'si (metin) olmalı"))

	var tetikler: Array = []
	if n.has("tetikleyiciler"):
		var t: Variant = n["tetikleyiciler"]
		if typeof(t) != TYPE_ARRAY:
			s.append(_hata("D2", kayit_adi, "tetikleyiciler", "tetikleyiciler bir dizi olmalı"))
		else:
			for e in t:
				if typeof(e) != TYPE_STRING:
					s.append(_hata("D2", kayit_adi, "tetikleyiciler", "tetikleyiciler nesne id'leri (metin) içermeli"))
				else:
					tetikler.append(e)
	if n.has("kablolar"):
		_kablolar_denetle(n["kablolar"], tetikler, kayit_adi, s)
	if n.has("kablo"):
		_kablo_denetle(n["kablo"], false, tetikler, kayit_adi, "kablo", s)


static func _kablolar_denetle(kablolar: Variant, tetikler: Array, nesne: String, s: Array[Dictionary]) -> void:
	if typeof(kablolar) != TYPE_ARRAY:
		s.append(_hata("D2", nesne, "kablolar", "kablolar bir dizi olmalı"))
		return
	var kullanilan := {}
	for k in kablolar:
		_kablo_denetle(k, true, tetikler, nesne, "kablolar", s)
		if typeof(k) == TYPE_DICTIONARY and typeof(k.get("tetik")) == TYPE_STRING:
			if kullanilan.has(k["tetik"]):
				s.append(_hata("D2", nesne, "kablolar", "aynı tetikleyici için birden çok kablo kaydı: %s" % k["tetik"]))
			kullanilan[k["tetik"]] = true


## Tek kablo kaydı: {"tetik"?, "ara", "uclar", "gizli"}. `tetikli` true ise (geçit/lazer) tetik zorunludur.
static func _kablo_denetle(k: Variant, tetikli: bool, tetikler: Array, nesne: String, alan: String, s: Array[Dictionary]) -> void:
	if typeof(k) != TYPE_DICTIONARY:
		s.append(_hata("D2", nesne, alan, "kablo kaydı bir nesne olmalı"))
		return
	var izinli: Array = ["ara", "uclar", "gizli"]
	if tetikli:
		izinli.append("tetik")
	for anahtar in k.keys():
		if not izinli.has(str(anahtar)):
			s.append(_hata("D2", nesne, alan, "kablo kaydında bilinmeyen alan: %s" % str(anahtar)))
	if tetikli:
		if typeof(k.get("tetik")) != TYPE_STRING:
			s.append(_hata("D2", nesne, alan, "kablo kaydında tetik (nesne id'si) zorunlu"))
		elif not tetikler.has(k["tetik"]):
			s.append(_hata("D2", nesne, alan, "kablonun tetik'i bu nesneye bağlı bir tetikleyici değil: %s" % k["tetik"]))
	if k.has("ara"):
		if typeof(k["ara"]) != TYPE_ARRAY:
			s.append(_hata("D2", nesne, alan, "kablo ara noktaları bir dizi olmalı"))
		else:
			for p in k["ara"]:
				if not _nokta_mi(p):
					s.append(_hata("D2", nesne, alan, "kablo ara noktası [x, y] tamsayı çifti olmalı"))
					break
	if k.has("uclar"):
		var u: Variant = k["uclar"]
		if typeof(u) != TYPE_ARRAY or u.size() != 2 or not _nokta_mi(u[0]) or not _nokta_mi(u[1]):
			s.append(_hata("D2", nesne, alan, "kablo uclar iki [x, y] noktası olmalı"))
	if k.has("gizli") and typeof(k["gizli"]) != TYPE_BOOL:
		s.append(_hata("D2", nesne, alan, "kablo gizli true ya da false olmalı"))


## D3: bağlantılar. Hedefler mevcut, asansörün tam 1 plakası var, şalter asansöre bağlı değil.
static func _baglanti_denetle(nesneler: Array, gorulen: Dictionary, s: Array[Dictionary]) -> void:
	for n in nesneler:
		if typeof(n) != TYPE_DICTIONARY or typeof(n.get("id")) != TYPE_STRING or not gorulen.has(n["id"]):
			continue
		var id: String = n["id"]
		var tur: String = str(n.get("tur", ""))
		if gorulen[id] != tur:
			continue   # yinelenen id'nin ikinci nesnesi: denetlenmez
		if tur == "asansor":
			var p: String = ""
			if typeof(n.get("plaka")) == TYPE_STRING:
				p = n["plaka"]
			elif n.has("plaka"):
				continue   # tür hatası D2'de bildirildi
			if p == "":
				s.append(_hata("D3", id, "plaka", "asansörün tam 1 plakası olmalı (yok)"))
			elif not gorulen.has(p):
				s.append(_hata("D3", id, "plaka", "asansörün plakası bulunamadı: %s" % p))
			elif gorulen[p] == "salter":
				s.append(_hata("D3", id, "plaka", "şalter asansöre bağlanamaz (%s); yalnızca plaka bağlanır" % p))
			elif not PLAKA_TURLERI.has(gorulen[p]):
				s.append(_hata("D3", id, "plaka", "asansörün plakası bir plaka olmalı (%s: %s)" % [p, gorulen[p]]))
		elif (tur == "gecit" or tur == "lazer") and typeof(n.get("tetikleyiciler")) == TYPE_ARRAY:
			for t in n["tetikleyiciler"]:
				if typeof(t) != TYPE_STRING:
					continue
				if not gorulen.has(t):
					s.append(_hata("D3", id, "tetikleyiciler", "tetikleyici bulunamadı: %s" % t))
				elif not TETIK_TURLERI.has(gorulen[t]):
					s.append(_hata("D3", id, "tetikleyiciler", "tetikleyici plaka ya da şalter olmalı (%s: %s)" % [t, gorulen[t]]))


# --- İçerik özeti ---------------------------------------------------------------------

## Deterministik kanonik metin: cozum, dogrulama, canli ve notlar alanları atılır; tamsayı
## değerli float'lar int'e çevrilir; anahtarlar (iç içe de) sıralı yazılır, girinti yok.
## Dizi sırası korunur (nesne sırası içeriğin parçasıdır).
static func kanonik_metin(veri: Dictionary) -> String:
	var v: Dictionary = _normalle(veri)
	for k in OZET_DISI:
		v.erase(k)
	return JSON.stringify(v, "", true)


## Kaydedilmemiş iş denetimi için metin: içerik (kanonik_metin) + çözüm kaydı + doğrulama sonucu.
## İçerik özetine girmeyen çözüm ve doğrulama da kullanıcının emeğidir; Kaydet'siz kaybolmasın.
static func kirlilik_metni(veri: Dictionary) -> String:
	var ek: Variant = _normalle({"cozum": veri.get("cozum", {}), "dogrulama": veri.get("dogrulama", {})})
	return kanonik_metin(veri) + "|" + JSON.stringify(ek, "", true)


## kanonik_metin(veri).sha256_text()
static func icerik_ozeti(veri: Dictionary) -> String:
	return kanonik_metin(veri).sha256_text()


## Kayıtlı doğrulama özeti şimdiki içerikle tutuyor mu?
static func dogrulama_guncel_mi(veri: Dictionary) -> bool:
	var d: Variant = veri.get("dogrulama")
	if typeof(d) != TYPE_DICTIONARY:
		return false
	var o: Variant = d.get("icerik_ozeti")
	return typeof(o) == TYPE_STRING and o == icerik_ozeti(veri)


## Çözüm ve doğrulama durumu metni: "Doğrulandı" yalnız kayıt güncel içerikle tutuyorsa;
## çözüm varsa "Taslak (doğrulanmadı)", yoksa "Taslak (çözüm yok)". Editör ve Bölümlerim ortak kullanır.
static func dogrulama_durumu(veri: Dictionary) -> String:
	var d: Variant = veri.get("dogrulama")
	if typeof(d) == TYPE_DICTIONARY and str(d.get("durum", "")) == "dogrulandi" and dogrulama_guncel_mi(veri):
		return "Doğrulandı"
	var c: Variant = veri.get("cozum")
	if typeof(c) == TYPE_DICTIONARY and typeof(c.get("oyuncu")) == TYPE_ARRAY and not (c["oyuncu"] as Array).is_empty():
		return "Taslak (doğrulanmadı)"
	return "Taslak (çözüm yok)"


# --- Çalıştırma uzunluğu (RLE) kodlaması ----------------------------------------------

## [{yon, zipla, asagi}, ...] -> [[n, yon, zipla 0/1, asagi 0/1], ...]. Eksik asagi = false.
## Ardışık özdeş (yon, zipla, asagi) kareler tek öğede toplanır.
static func kayit_kodla(tur: Array) -> Array:
	var cikti: Array = []
	for g in tur:
		var yon: float = float(g.get("yon", 0.0))
		var z: int = 1 if bool(g.get("zipla", false)) else 0
		var a: int = 1 if bool(g.get("asagi", false)) else 0
		var son: Variant = null
		if not cikti.is_empty():
			son = cikti[cikti.size() - 1]
		if son != null and float(son[1]) == yon and son[2] == z and son[3] == a:
			son[0] += 1
		else:
			cikti.append([1, _yon_degeri(yon), z, a])
	return cikti


## Tamsayı yön -1/0/1 int yazılır (JSON'da sade durur); küsuratlıysa float kalır.
static func _yon_degeri(yon: float) -> Variant:
	if yon == floorf(yon):
		return int(yon)
	return yon


## kayit_kodla'nın tersi: yon float, zipla/asagi bool. Eksik (3 elemanlı) asagi = false.
## Bozuk öğeler (n < 1 ya da eksik alan) atlanır.
static func kayit_coz(rle: Array) -> Array:
	var cikti: Array = []
	for oge in rle:
		if typeof(oge) != TYPE_ARRAY or oge.size() < 3 or not _sayi(oge[0]) or int(oge[0]) < 1:
			continue
		var yon: float = float(oge[1])
		var z: bool = int(oge[2]) != 0
		var a: bool = oge.size() >= 4 and int(oge[3]) != 0
		for i in int(oge[0]):
			cikti.append({"yon": yon, "zipla": z, "asagi": a})
	return cikti


# --- Slug ve kimlik -------------------------------------------------------------------

## Ad -> küçük harf ASCII slug (en çok 36 karakter; boşsa "bolum").
static func slug(ad: String) -> String:
	var eslem := {
		"ç": "c", "Ç": "c", "ğ": "g", "Ğ": "g", "ı": "i", "İ": "i", "I": "i",
		"ö": "o", "Ö": "o", "ş": "s", "Ş": "s", "ü": "u", "Ü": "u",
	}
	var s := ""
	var onceki_alt := true   # baştaki ayırıcıları atlamak için
	for i in ad.length():
		var c := ad.substr(i, 1)
		if c == "̇":   # birleşik nokta (i̇): yok say
			continue
		if eslem.has(c):
			c = eslem[c]
		c = c.to_lower()
		var kod := c.unicode_at(0) if c.length() == 1 else -1
		var uygun := (kod >= 97 and kod <= 122) or (kod >= 48 and kod <= 57)
		if uygun:
			s += c
			onceki_alt = false
		elif not onceki_alt:
			s += "_"
			onceki_alt = true
	s = s.substr(0, SLUG_AZAMI)
	while s.ends_with("_"):
		s = s.substr(0, s.length() - 1)
	if s == "":
		return "bolum"
	return s


## slug(ad) + "_%03d": bolumler/ ve canli/ dizinlerindeki *.json adlarında ve canli/sira.json
## kimliklerinde dolu olmayan en küçük n (1..999). 999'u aşarsa "".
static func yeni_kimlik(ad: String, kok: String = BolumYollari.VARSAYILAN_KOK) -> String:
	var govde := slug(ad)
	var dolu := {}
	for dizin in [BolumYollari.bolumler_dizini(kok), BolumYollari.canli_dizini(kok)]:
		var d := DirAccess.open(dizin)
		if d == null:
			continue
		for dosya in d.get_files():
			if dosya.ends_with(".json"):
				dolu[dosya.get_basename()] = true
	var sira_yolu := BolumYollari.canli_dizini(kok) + "sira.json"
	if FileAccess.file_exists(sira_yolu):
		var f := FileAccess.open(sira_yolu, FileAccess.READ)
		if f != null:
			var veri: Variant = JSON.parse_string(f.get_as_text())
			f.close()
			if typeof(veri) == TYPE_DICTIONARY and typeof(veri.get("canli")) == TYPE_ARRAY:
				for kayit in veri["canli"]:
					if typeof(kayit) == TYPE_DICTIONARY and kayit.has("kimlik"):
						dolu[str(kayit["kimlik"])] = true
	for n in range(1, 1000):
		var kimlik := "%s_%03d" % [govde, n]
		if not dolu.has(kimlik):
			return kimlik
	return ""
