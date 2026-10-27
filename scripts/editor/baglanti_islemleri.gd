class_name BaglantiIslemleri
extends RefCounted
## Tetikleyici -> hedef bağlantıları ve kablo yolları üzerinde saf veri işlemleri (A7, taslak §4).
## Hepsi `BolumVerisi` sözlüğünü yerinde değiştirir; geri al kaydı, önizleme ve çizim editörün
## işidir. Kablo yalnızca görünümdür (K9): bağlantının kendisi `tetikleyiciler` / `plaka` alanındadır,
## kablo ise hedefteki `kablolar` (geçit/lazer) ya da `kablo` (asansör) kaydında durur.

const ARA_NOKTA_ESIGI := 8.0
const PARCA_ESIGI := 6.0


static func nesne(veri: Dictionary, id: String) -> Dictionary:
	for n in veri.get("nesneler", []):
		if str(n.get("id", "")) == id:
			return n
	return {}


static func tetikleyici_mi(n: Dictionary) -> bool:
	return BolumVerisi.TETIK_TURLERI.has(str(n.get("tur", "")))


static func hedef_mi(n: Dictionary) -> bool:
	return ["gecit", "lazer", "asansor"].has(str(n.get("tur", "")))


## Hedefin bu tetikleyiciyle bağlantı sırası (kablo meta numarası); bağlı değilse -1.
static func sira(hedef: Dictionary, tetik_id: String) -> int:
	if str(hedef.get("tur", "")) == "asansor":
		return 0 if str(hedef.get("plaka", "")) == tetik_id and tetik_id != "" else -1
	var t: Variant = hedef.get("tetikleyiciler", [])
	return (t as Array).find(tetik_id) if typeof(t) == TYPE_ARRAY else -1


## Tüm bağlantılar: [{"hedef", "tetik", "k"}]. Tetikleyicisi bulunmayan bağlantı atlanır.
static func baglantilar(veri: Dictionary) -> Array:
	var sonuc: Array = []
	for n in veri.get("nesneler", []):
		var tur := str(n.get("tur", ""))
		var id := str(n.get("id", ""))
		if tur == "asansor":
			var p := str(n.get("plaka", ""))
			if p != "" and not nesne(veri, p).is_empty():
				sonuc.append({"hedef": id, "tetik": p, "k": 0})
		elif (tur == "gecit" or tur == "lazer") and typeof(n.get("tetikleyiciler")) == TYPE_ARRAY:
			for k in n["tetikleyiciler"].size():
				var t := str(n["tetikleyiciler"][k])
				if not nesne(veri, t).is_empty():
					sonuc.append({"hedef": id, "tetik": t, "k": k})
	return sonuc


## Bağlantının kablo kaydı (referans; `olustur` yoksa bulunamazsa geçici boş sözlük).
static func kayit(hedef: Dictionary, tetik_id: String, olustur: bool) -> Dictionary:
	if str(hedef.get("tur", "")) == "asansor":
		var kk: Variant = hedef.get("kablo")
		if typeof(kk) == TYPE_DICTIONARY:
			return kk
		if olustur:
			hedef["kablo"] = {}
			return hedef["kablo"]
		return {}
	if typeof(hedef.get("kablolar")) == TYPE_ARRAY:
		for kb in hedef["kablolar"]:
			if typeof(kb) == TYPE_DICTIONARY and str(kb.get("tetik", "")) == tetik_id:
				return kb
	if olustur:
		if typeof(hedef.get("kablolar")) != TYPE_ARRAY:
			hedef["kablolar"] = []
		var yeni := {"tetik": tetik_id}
		hedef["kablolar"].append(yeni)
		return yeni
	return {}


## Yalnızca varsayılanları taşıyan (boş) kayıt silinir; JSON sade kalır.
static func _kayit_temizle(hedef: Dictionary, tetik_id: String) -> void:
	var kay := kayit(hedef, tetik_id, false)
	if kay.is_empty():
		return
	for anahtar in kay.keys():
		if anahtar != "tetik":
			return
	_kayit_sil(hedef, tetik_id)


static func _kayit_sil(hedef: Dictionary, tetik_id: String) -> void:
	if str(hedef.get("tur", "")) == "asansor":
		hedef.erase("kablo")
		return
	if typeof(hedef.get("kablolar")) == TYPE_ARRAY:
		for i in range(hedef["kablolar"].size() - 1, -1, -1):
			var kb: Variant = hedef["kablolar"][i]
			if typeof(kb) == TYPE_DICTIONARY and str(kb.get("tetik", "")) == tetik_id:
				hedef["kablolar"].remove_at(i)
		if hedef["kablolar"].is_empty():
			hedef.erase("kablolar")


# --- Bağla ----------------------------------------------------------------------------

## Tetikleyiciyi hedefe bağlar; zaten bağlıysa kaldırır (K8). Sonuç sözlüğü:
## {"sonuc": "baglandi" | "kaldirildi" | "onay" | "red", "mesaj"}. "onay": asansörün başka plakası var,
## `onayli` true ile tekrar çağrılırsa yenisi öncekinin yerine geçer.
static func bagla(veri: Dictionary, tetik_id: String, hedef_id: String, onayli: bool = false) -> Dictionary:
	var t := nesne(veri, tetik_id)
	var h := nesne(veri, hedef_id)
	if t.is_empty() or h.is_empty():
		return _sonuc("red", "Bağlanacak nesne bulunamadı")
	if not tetikleyici_mi(t):
		return _sonuc("red", "Kaynak bir plaka ya da şalter olmalı")
	match str(h["tur"]):
		"asansor":
			if not BolumVerisi.PLAKA_TURLERI.has(str(t["tur"])):
				return _sonuc("red", "Şalter asansöre bağlanamaz; yalnızca plaka bağlanır")
			var mevcut := str(h.get("plaka", ""))
			if mevcut == tetik_id:
				h.erase("plaka")
				h.erase("kablo")
				return _sonuc("kaldirildi", "Bağlantı kaldırıldı: %s -> %s" % [tetik_id, hedef_id])
			if mevcut != "" and not onayli:
				return _sonuc("onay", "%s zaten %s plakasına bağlı. Yenisiyle (%s) değiştirilsin mi?" % [hedef_id, mevcut, tetik_id])
			h["plaka"] = tetik_id
			h.erase("kablo")
			return _sonuc("baglandi", "Bağlandı: %s -> %s" % [tetik_id, hedef_id])
		"gecit", "lazer":
			var liste: Array = h["tetikleyiciler"] if typeof(h.get("tetikleyiciler")) == TYPE_ARRAY else []
			var i := liste.find(tetik_id)
			if i >= 0:
				liste.remove_at(i)
				h["tetikleyiciler"] = liste
				_kayit_sil(h, tetik_id)
				return _sonuc("kaldirildi", "Bağlantı kaldırıldı: %s -> %s" % [tetik_id, hedef_id])
			liste.append(tetik_id)
			h["tetikleyiciler"] = liste
			return _sonuc("baglandi", "Bağlandı: %s -> %s" % [tetik_id, hedef_id])
	return _sonuc("red", "Hedef bir geçit, lazer ya da asansör olmalı")


static func _sonuc(s: String, m: String) -> Dictionary:
	return {"sonuc": s, "mesaj": m}


## Silinen nesneye giden bağlantıları temizler. Dönüş: değişen hedeflerin kimlikleri.
static func referanslari_sil(veri: Dictionary, id: String) -> Array:
	var etkilenen: Array = []
	for n in veri.get("nesneler", []):
		var nid := str(n.get("id", ""))
		if nid == id:
			continue
		if str(n.get("tur", "")) == "asansor":
			if str(n.get("plaka", "")) == id:
				n.erase("plaka")
				n.erase("kablo")
				etkilenen.append(nid)
		elif typeof(n.get("tetikleyiciler")) == TYPE_ARRAY and (n["tetikleyiciler"] as Array).has(id):
			var yeni: Array = []
			for t in n["tetikleyiciler"]:
				if str(t) != id:
					yeni.append(t)
			n["tetikleyiciler"] = yeni
			_kayit_sil(n, id)
			etkilenen.append(nid)
	return etkilenen


## Taşınan nesne (tetikleyici ya da hedef) için elle ayarlı `uclar` geçersizdir (§1.3): silinir ve
## uçlar yeniden hesaplanır. Dönüş: kablosu değişen hedeflerin kimlikleri (nesnenin kendisi dahil).
static func uclari_sil(veri: Dictionary, id: String) -> Array:
	var etkilenen: Array = []
	for b in baglantilar(veri):
		if b["hedef"] != id and b["tetik"] != id:
			continue
		var h := nesne(veri, b["hedef"])
		var kay := kayit(h, b["tetik"], false)
		if kay.has("uclar"):
			kay.erase("uclar")
			_kayit_temizle(h, b["tetik"])
			if not etkilenen.has(b["hedef"]):
				etkilenen.append(b["hedef"])
	return etkilenen


# --- Kablo yolu ------------------------------------------------------------------------

## Bağlantının kablo noktaları; `gizliyi_say` true ise gizli kablo da hesaplanır (editör çizimi için).
static func yol(veri: Dictionary, hedef_id: String, tetik_id: String, gizliyi_say: bool = false) -> PackedVector2Array:
	var h := nesne(veri, hedef_id)
	var k := sira(h, tetik_id) if not h.is_empty() else -1
	if k < 0:
		return PackedVector2Array()
	if gizliyi_say:
		h = h.duplicate(true)
		var kay := kayit(h, tetik_id, false)
		if not kay.is_empty():
			kay["gizli"] = false
	return BolumKurucu.kablo_noktalari(h, k, veri)


static func gizli_mi(veri: Dictionary, hedef_id: String, tetik_id: String) -> bool:
	return bool(kayit(nesne(veri, hedef_id), tetik_id, false).get("gizli", false))


static func ara_noktalar(veri: Dictionary, hedef_id: String, tetik_id: String) -> Array:
	var ara: Variant = kayit(nesne(veri, hedef_id), tetik_id, false).get("ara", [])
	return ara if typeof(ara) == TYPE_ARRAY else []


## İlk düzenlemede otomatik L yolu açık bir ara nokta listesine dönüşür.
static func ara_ac(veri: Dictionary, hedef_id: String, tetik_id: String) -> void:
	var h := nesne(veri, hedef_id)
	if h.is_empty() or sira(h, tetik_id) < 0:
		return
	var kay := kayit(h, tetik_id, true)
	if kay.has("uclar") or (kay.has("ara") and (kay["ara"] as Array).size() > 0):
		if not kay.has("ara"):
			kay["ara"] = []
		return
	var p := yol(veri, hedef_id, tetik_id, true)
	var ara: Array = []
	if p.size() == 3 and p[1] != p[0] and p[1] != p[2]:
		ara.append([roundi(p[1].x), roundi(p[1].y)])
	kay["ara"] = ara


## Yola en yakın parçanın sonrasına yeni ara nokta ekler. Dönüş: ara nokta sırası (-1: eklenemedi).
static func ara_ekle(veri: Dictionary, hedef_id: String, tetik_id: String, nokta: Vector2) -> int:
	ara_ac(veri, hedef_id, tetik_id)
	var p := yol(veri, hedef_id, tetik_id, true)
	if p.size() < 2:
		return -1
	var en_i := 0
	var en_d := INF
	for i in p.size() - 1:
		var d := _parca_mesafesi(nokta, p[i], p[i + 1])
		if d < en_d:
			en_d = d
			en_i = i
	var kay := kayit(nesne(veri, hedef_id), tetik_id, true)
	# Bozuk L'de (köşe uçla çakışınca) ara boş kalabilir: sıra liste boyuna kıstırılır.
	en_i = mini(en_i, (kay["ara"] as Array).size())
	kay["ara"].insert(en_i, [roundi(nokta.x), roundi(nokta.y)])
	return en_i


static func ara_tasi(veri: Dictionary, hedef_id: String, tetik_id: String, i: int, nokta: Vector2) -> bool:
	var kay := kayit(nesne(veri, hedef_id), tetik_id, false)
	if not kay.has("ara") or i < 0 or i >= (kay["ara"] as Array).size():
		return false
	kay["ara"][i] = [roundi(nokta.x), roundi(nokta.y)]
	return true


static func ara_sil(veri: Dictionary, hedef_id: String, tetik_id: String, i: int) -> bool:
	var h := nesne(veri, hedef_id)
	var kay := kayit(h, tetik_id, false)
	if not kay.has("ara") or i < 0 or i >= (kay["ara"] as Array).size():
		return false
	kay["ara"].remove_at(i)
	if (kay["ara"] as Array).is_empty() and not kay.has("uclar"):
		# Boşalan liste otomatik L yoluna döner (kayıt gereksizse silinir).
		kay.erase("ara")
		_kayit_temizle(h, tetik_id)
	return true


## "Kabloyu sıfırla": ara noktalar ve elle uçlar gider, otomatik yola dönülür (gizli durumu korunur).
static func sifirla(veri: Dictionary, hedef_id: String, tetik_id: String) -> bool:
	var h := nesne(veri, hedef_id)
	var kay := kayit(h, tetik_id, false)
	if kay.is_empty() or not (kay.has("ara") or kay.has("uclar")):
		return false
	kay.erase("ara")
	kay.erase("uclar")
	_kayit_temizle(h, tetik_id)
	return true


static func gizle(veri: Dictionary, hedef_id: String, tetik_id: String, gizli: bool) -> bool:
	var h := nesne(veri, hedef_id)
	if h.is_empty() or sira(h, tetik_id) < 0 or gizli_mi(veri, hedef_id, tetik_id) == gizli:
		return false
	if gizli:
		kayit(h, tetik_id, true)["gizli"] = true
	else:
		kayit(h, tetik_id, false).erase("gizli")
		_kayit_temizle(h, tetik_id)
	return true


## Noktanın üstündeki kablo (önce ara nokta 8 px, sonra parça 6 px): {"hedef","tetik","nokta","parca"}
## ("nokta" ara nokta sırası ya da -1; "parca" parça sırası). Bulunamazsa boş sözlük.
static func en_yakin(veri: Dictionary, p: Vector2) -> Dictionary:
	var en: Dictionary = {}
	var en_d := ARA_NOKTA_ESIGI + 0.001
	var yollar: Array = []
	for b in baglantilar(veri):
		var yl := yol(veri, b["hedef"], b["tetik"], true)
		if yl.size() < 2:
			continue
		yollar.append([b, yl])
		for i in range(1, yl.size() - 1):
			var d := p.distance_to(yl[i])
			if d <= en_d:
				en_d = d
				en = {"hedef": b["hedef"], "tetik": b["tetik"], "nokta": i - 1, "parca": -1}
	if not en.is_empty():
		return en
	en_d = PARCA_ESIGI + 0.001
	for e in yollar:
		var yl: PackedVector2Array = e[1]
		for i in yl.size() - 1:
			var d := _parca_mesafesi(p, yl[i], yl[i + 1])
			if d <= en_d:
				en_d = d
				en = {"hedef": e[0]["hedef"], "tetik": e[0]["tetik"], "nokta": -1, "parca": i}
	return en


static func _parca_mesafesi(p: Vector2, a: Vector2, b: Vector2) -> float:
	return p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b))
