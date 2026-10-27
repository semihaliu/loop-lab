class_name CanliBolumler
extends RefCounted
## "Canlıya al" (taslak §8.1, A12): Bölümlerim'deki bir bölümü oyun zincirine, kullanıcının seçtiği yere ekler.
## Kurulum ve denetim yalnız burada yapılır; `BolumListesi.liste()` yalnız okur.
##
## Dosyalar (`<kök>canli/`):
##   <kimlik>.json         canlıya alma anındaki DONDURULMUŞ kopya (Bölümlerim'deki düzenleme oyuna yansımaz)
##   <kimlik>_v<NNN>.tscn  kurulmuş sahne; "Canlıyı güncelle" her seferinde yeni sürüm yolu kullanır, eski dosya
##                         silinir (aynı yol yeniden yazılırsa kaynak önbelleği eski sahneyi döndürebilir)
##   sira.json             {"surum": 1, "canli": [{kimlik, ad, sahne, sonra, icerik_ozeti, cozum_yok}, ...]}
## `sonra` numara saklamaz: "" (en başa), resmî sahne yolu ya da "canli:<kimlik>".
## .tscn dosyaları yeniden adlandırılmaz; numara birleşik listenin sırasından türer.
## Her yazma işlemi sonunda `BolumListesi.yenile()` çağrılır.

const SIRA_SURUMU := 1
const KOD_ZATEN_CANLI := "C1"
const KOD_SIRA := "C2"
const KOD_SINIR := "C3"
const KOD_DEGIL := "C4"
const KOD_YAZMA := "C5"
const KOD_BOZUK_SIRA := "C6"

## Bu oturumda verilen sürümler (dizin + kimlik -> son n); silinen yol yeniden verilmez.
static var _surumler: Dictionary = {}


# --- Okuma ------------------------------------------------------------------------------------------

## `sira.json` kayıtları (geçerli olanlar, dosya sırasıyla); sahne dosyasının varlığına bakmaz.
static func sira_oku(kok: String) -> Array:
	return BolumListesi.sira_kayitlari(kok)


## Kimliğin sıra kaydı ({} = canlı değil).
static func kayit(kimlik: String, kok: String) -> Dictionary:
	for k in sira_oku(kok):
		if k["kimlik"] == kimlik:
			return k
	return {}


static func canli_mi(kimlik: String, kok: String) -> bool:
	return not kayit(kimlik, kok).is_empty()


## Canlı bölümün sahne yolu ("" = canlı değil).
static func sahne_yolu(kimlik: String, kok: String) -> String:
	var k := kayit(kimlik, kok)
	if k.is_empty():
		return ""
	return BolumYollari.canli_dizini(kok) + str(k["sahne"])


## Canlı bölümün oyundaki numarası (birleşik sıra + 1); canlı değilse 0.
static func numara(kimlik: String, kok: String) -> int:
	var yol := sahne_yolu(kimlik, kok)
	if yol == "":
		return 0
	var l := BolumListesi.olustur(kok)
	for i in l.size():
		if l[i]["yol"] == yol:
			return i + 1
	return 0


## Canlı kopya, Bölümlerim'deki güncel içerikten farklı mı? (veri = Bölümlerim'deki JSON)
static func degisti_mi(veri: Dictionary, kok: String) -> bool:
	var k := kayit(str(veri.get("kimlik", "")), kok)
	return not k.is_empty() and str(k["icerik_ozeti"]) != BolumVerisi.icerik_ozeti(veri)


## Sıra seçenekleri: [{"etiket": "En başa" | "Şundan sonra: Bölüm 10 · Hat", "sonra": <sonra değeri>}, ...].
## `haric_kimlik` verilirse o canlı bölüm listede gösterilmez.
static func sira_secenekleri(kok: String, haric_kimlik: String = "") -> Array:
	var cikti: Array = [{"etiket": "En başa", "sonra": ""}]
	var l := BolumListesi.olustur(kok)
	for i in l.size():
		var r: Dictionary = l[i]
		if haric_kimlik != "" and r["kimlik"] == haric_kimlik:
			continue
		var sonra := str(r["yol"]) if r["kaynak"] == "resmi" else "canli:" + str(r["kimlik"])
		var ad := str(r["ad"])
		var baslik := BolumListesi.baslik_metni(i + 1, ad)
		cikti.append({"etiket": "Şundan sonra: %s" % baslik, "sonra": sonra})
	return cikti


# --- Yazma ------------------------------------------------------------------------------------------

## Bölümü canlıya alır. `sonra`: "" (en başa), resmî sahne yolu ya da "canli:<kimlik>".
## Dönüş: sorun listesi; boşsa başarılı. Statik HATA, geçersiz sıra, zaten canlı olma ve 40 sınırı engeller;
## çözümsüzlük ENGEL DEĞİLDİR (S4) — uyarıyı çağıran gösterir.
static func canliya_al(veri: Dictionary, sonra: String, kok: String) -> Array[Dictionary]:
	var hatalar := _hatalar(veri)
	if not hatalar.is_empty():
		return hatalar
	var kimlik := str(veri["kimlik"])
	if canli_mi(kimlik, kok):
		return [_sorun(KOD_ZATEN_CANLI, kimlik, "Bu bölüm zaten canlı; güncellemek için \"Canlıyı güncelle\" kullanın")]
	if not _sira_saglam(kok):
		return [_sorun(KOD_BOZUK_SIRA, kimlik, SIRA_BOZUK_MESAJI)]
	var sira := sira_oku(kok)
	if not _sonra_gecerli(sonra, sira):
		return [_sorun(KOD_SIRA, kimlik, "Seçilen sıra geçersiz: %s" % sonra)]
	if BolumListesi.olustur(kok).size() >= BolumListesi.AZAMI_BOLUM:
		return [_sorun(KOD_SINIR, kimlik, "Oyunda en çok %d bölüm olabilir; önce bir canlı bölümü kaldırın" % BolumListesi.AZAMI_BOLUM)]

	var dizin := BolumYollari.canli_dizini(kok)
	var sahne := _yeni_sahne_adi(kimlik, kok)
	var yazilan := _sahne_yaz(veri, dizin, sahne)
	if not yazilan.is_empty():
		return yazilan
	var kayit_yeni := _kayit_uret(veri, sahne, sonra)
	# Aynı yere daha önce eklenmiş kayıtlar yeni kaydın ardına geçer: seçilen bölümden HEMEN sonra yeni kayıt gelir.
	for k in sira:
		if k["sonra"] == sonra:
			k["sonra"] = "canli:" + kimlik
	sira.append(kayit_yeni)
	if _sira_yaz(kok, sira) != OK or _kopya_yaz(veri, dizin) != OK:
		_sil(dizin + sahne)
		_sil(dizin + kimlik + ".json")
		return [_sorun(KOD_YAZMA, kimlik, "canli/sira.json ya da dondurulmuş kopya yazılamadı")]
	_ayna_yaz(kok, kimlik, kayit_yeni)
	BolumListesi.yenile()
	return []


## Canlı kopyayı Bölümlerim'deki güncel içerikle değiştirir (Y1). Sıra (`sonra`) korunur.
static func guncelle(veri: Dictionary, kok: String) -> Array[Dictionary]:
	var hatalar := _hatalar(veri)
	if not hatalar.is_empty():
		return hatalar
	var kimlik := str(veri["kimlik"])
	if not _sira_saglam(kok):
		return [_sorun(KOD_BOZUK_SIRA, kimlik, SIRA_BOZUK_MESAJI)]
	var sira := sira_oku(kok)
	var i := -1
	for k in sira.size():
		if sira[k]["kimlik"] == kimlik:
			i = k
	if i < 0:
		return [_sorun(KOD_DEGIL, kimlik, "Bu bölüm canlı değil")]
	var eski_sahne: String = sira[i]["sahne"]
	var dizin := BolumYollari.canli_dizini(kok)
	var sahne := _yeni_sahne_adi(kimlik, kok)
	var yazilan := _sahne_yaz(veri, dizin, sahne)
	if not yazilan.is_empty():
		return yazilan
	var yeni := _kayit_uret(veri, sahne, str(sira[i]["sonra"]))
	sira[i] = yeni
	# Önce sıra kaydı, en son dondurulmuş JSON: sıra yazılamazsa eski kopya ve eski sahne olduğu gibi kalır.
	if _sira_yaz(kok, sira) != OK:
		_sil(dizin + sahne)
		return [_sorun(KOD_YAZMA, kimlik, "canli/sira.json yazılamadı")]
	_kopya_yaz(veri, dizin)
	if eski_sahne != sahne:
		_sil(dizin + eski_sahne)
	_ayna_yaz(kok, kimlik, yeni)
	BolumListesi.yenile()
	return []


## Canlıdan kaldırır: kayıt, dondurulmuş kopya ve sahne silinir; Bölümlerim'deki bölüm kalır.
## Kaldırılana bağlı canlı kayıtların `sonra` değeri, kaldırılanın `sonra` değerine devredilir (sıra korunur).
static func kaldir(kimlik: String, kok: String) -> Error:
	if not _sira_saglam(kok):
		return ERR_FILE_CORRUPT
	var sira := sira_oku(kok)
	var i := -1
	for k in sira.size():
		if sira[k]["kimlik"] == kimlik:
			i = k
	if i < 0:
		return ERR_DOES_NOT_EXIST
	var silinen: Dictionary = sira[i]
	# Bağlı kayıtlar kaldırılanın dosyadaki yerine taşınır ve `sonra` değerini devralır: kardeşlerle göreli sıra korunur.
	var yeni_sira: Array = []
	for k in sira:
		if k["kimlik"] == kimlik:
			for d in sira:
				if d["sonra"] == "canli:" + kimlik:
					d["sonra"] = silinen["sonra"]
					yeni_sira.append(d)
		elif k["sonra"] != "canli:" + kimlik:
			yeni_sira.append(k)
	sira = yeni_sira
	var h := _sira_yaz(kok, sira)
	if h != OK:
		return h
	var dizin := BolumYollari.canli_dizini(kok)
	_sil(dizin + str(silinen["sahne"]))
	_sil(dizin + kimlik + ".json")
	_ayna_yaz(kok, kimlik, {})
	BolumListesi.yenile()
	return OK


# --- Yardımcılar ------------------------------------------------------------------------------------

const SIRA_BOZUK_MESAJI := "canli/sira.json bozuk ya da geçersiz kayıt içeriyor; onarılmadan canlı kayıtlar değiştirilemez (dosyayı onarın ya da silin)"


## sira.json okunabilir ve her kaydı geçerli mi? (Değilse yazma işlemleri reddedilir: üstüne yazmak canlı kayıtları kaybettirirdi.)
static func _sira_saglam(kok: String) -> bool:
	var uyarilar: Array[String] = []
	BolumListesi.sira_kayitlari(kok, uyarilar)
	return uyarilar.is_empty()


static func _sorun(kod: String, nesne: String, mesaj: String) -> Dictionary:
	return {"kod": kod, "seviye": "HATA", "nesne": nesne, "alan": "", "mesaj": mesaj}


## Statik HATA'lar (şema dahil); boşsa canlıya alınabilir.
static func _hatalar(veri: Dictionary) -> Array[Dictionary]:
	var cikti: Array[Dictionary] = []
	if veri.is_empty():
		cikti.append(_sorun("D2", "", "Bölüm verisi boş"))
		return cikti
	for o in BolumDenetci.statik(veri):
		if str(o.get("seviye", "")) == "HATA":
			cikti.append(o)
	return cikti


static func _sonra_gecerli(sonra: String, sira: Array) -> bool:
	if sonra == "":
		return true
	if sonra.begins_with("canli:"):
		for k in sira:
			if "canli:" + str(k["kimlik"]) == sonra:
				return true
		return false
	for r in BolumListesi.BOLUMLER:
		if r["yol"] == sonra:
			return true
	return false


static func _kayit_uret(veri: Dictionary, sahne: String, sonra: String) -> Dictionary:
	var cozumlu: bool = BolumVerisi.dogrulama_guncel_mi(veri) and str(veri.get("dogrulama", {}).get("durum", "")) == "dogrulandi"
	return {
		"kimlik": str(veri["kimlik"]),
		"ad": str(veri.get("ad", "")),
		"sahne": sahne,
		"sonra": sonra,
		"icerik_ozeti": BolumVerisi.icerik_ozeti(veri),
		"cozum_yok": not cozumlu,
	}


## Sahneyi kurup yazar. Dönüş: sorun listesi (boşsa başarılı).
static func _sahne_yaz(veri: Dictionary, dizin: String, sahne: String) -> Array[Dictionary]:
	var kopya: Dictionary = veri.duplicate(true)
	kopya.erase("canli")
	var h := BolumKurucu.sahneye_kaydet(kopya, dizin + sahne)
	if h != OK:
		_sil(dizin + sahne)
		return [_sorun(KOD_YAZMA, str(veri["kimlik"]), "Sahne kurulamadı (hata %d)" % h)]
	return []


## Dondurulmuş JSON kopyasını (`canli` aynası olmadan) yazar.
static func _kopya_yaz(veri: Dictionary, dizin: String) -> Error:
	var kopya: Dictionary = veri.duplicate(true)
	kopya.erase("canli")
	return BolumVerisi.yaz(kopya, dizin + str(veri["kimlik"]) + ".json")


## `<kimlik>_v<NNN>.tscn`: dizindeki en büyük sürüm ve bu oturumdaki sayaçtan bir fazlası.
static func _yeni_sahne_adi(kimlik: String, kok: String) -> String:
	var dizin := BolumYollari.canli_dizini(kok)
	var anahtar := dizin + kimlik
	var en_buyuk: int = _surumler.get(anahtar, 0)
	var onek := kimlik + "_v"
	if DirAccess.dir_exists_absolute(dizin):
		for f in DirAccess.get_files_at(dizin):
			if f.begins_with(onek) and f.ends_with(".tscn"):
				var sayi := f.trim_prefix(onek).get_slice(".", 0)
				if sayi.is_valid_int():
					en_buyuk = maxi(en_buyuk, sayi.to_int())
	for k in sira_oku(kok):   # sira.json'daki (dosyası silinmiş olsa bile) sürümler de atlanır
		if k["kimlik"] == kimlik and str(k["sahne"]).begins_with(onek):
			var sayi2 := str(k["sahne"]).trim_prefix(onek).get_slice(".", 0)
			if sayi2.is_valid_int():
				en_buyuk = maxi(en_buyuk, sayi2.to_int())
	_surumler[anahtar] = en_buyuk + 1
	return "%s_v%03d.tscn" % [kimlik, en_buyuk + 1]


static func _sira_yaz(kok: String, sira: Array) -> Error:
	var dizin := BolumYollari.canli_dizini(kok)
	if not DirAccess.dir_exists_absolute(dizin):
		var h := DirAccess.make_dir_recursive_absolute(dizin)
		if h != OK:
			return h
	# Önce geçici dosyaya yazılır, tamamlanınca yerine geçer: yarım yazılmış sira.json oluşmaz.
	var gecici := dizin + "sira.json.tmp"
	var f := FileAccess.open(gecici, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(JSON.stringify({"surum": SIRA_SURUMU, "canli": sira}, "  ", true))
	f.close()
	if FileAccess.file_exists(dizin + "sira.json"):
		DirAccess.remove_absolute(dizin + "sira.json")
	return DirAccess.rename_absolute(gecici, dizin + "sira.json")


## Bölümlerim'deki JSON'un `canli` aynasını günceller (boş sözlük = aynayı kaldır). Dosya yoksa/bozuksa dokunmaz.
static func _ayna_yaz(kok: String, kimlik: String, kayit_: Dictionary) -> void:
	var yol := BolumYollari.bolumler_dizini(kok) + kimlik + ".json"
	if not FileAccess.file_exists(yol):
		return
	var sonuc := BolumVerisi.oku(yol)
	var veri: Dictionary = sonuc["veri"]
	if veri.is_empty():
		return
	if kayit_.is_empty():
		veri.erase("canli")
	else:
		veri["canli"] = {"alindi": true, "sonra": kayit_["sonra"], "sahne": kayit_["sahne"], "canli_ozet": kayit_["icerik_ozeti"]}
	BolumVerisi.yaz(veri, yol)


static func _sil(yol: String) -> void:
	if FileAccess.file_exists(yol):
		DirAccess.remove_absolute(yol)
