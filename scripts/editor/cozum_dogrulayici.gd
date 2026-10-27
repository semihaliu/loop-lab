class_name CozumDogrulayici
extends Node
## Çözüm doğrulayıcı (editör taslağı §6.2, §9.1 A3): bir bölüm sahnesini verilen klon
## turları ve son tur kaydıyla gerçek zamanlı (60 fps fizik) oynatır. Girdi
## `Input.action_press` ile enjekte edilir; `Engine.time_scale` ve fizik hızı değişmez.
## Başka betik/sahne `preload` edilmez; her şey çalışma anında çözülür.

signal ilerleme(adim: int, toplam: int, aciklama: String)
signal bitti(sonuc: Dictionary)

## Süre sınırı: en uzun tur uzunluğu + bu kadar kare.
const SURE_PAYI := 120
const _EYLEMLER: Array[String] = ["sol", "sag", "zipla", "asagi"]

var _iptal := false
var _calisiyor := false
## Sıradaki karenin girdisi; en düşük öncelikli `_physics_process` içinde basılır.
var _bekleyen: Variant = null
var _toplu := false


func _init() -> void:
	# En yüksek öncelik değeri: girdi karenin sonunda basılır; gerçek tuş olayı gibi
	# bir sonraki fizik karesinde `just_pressed` görülür.
	process_physics_priority = 2147483647
	process_mode = Node.PROCESS_MODE_ALWAYS


func _physics_process(_delta: float) -> void:
	if _bekleyen != null:
		_girdi_uygula(_bekleyen)
		_bekleyen = null


## Süren oynatmayı/determinizm koşusunu bir sonraki karede durdurur.
## Durdurulan koşuda hiçbir şey yazılmaz, `Kayitlar` boşaltılır.
func iptal() -> void:
	_iptal = true


## Bölümü oynatır (await edilir). Dönüş:
## {"bitti": bool, "oldu": bool, "bitis_kare": int, "kareler": Array[int], "ornekler": Array}
## `kareler[i]` = `ornekler[i]` örneğinin alındığı kare (oyuncu.kare). Hata/iptal durumunda
## ek `hata` ("klon_siniri", "yuklenemedi", "mesgul") ya da `iptal` anahtarı bulunur.
func oynat(sahne_yolu: String, klon_turlari: Array, son_tur: Array, ornekle := true) -> Dictionary:
	if not _toplu:
		_iptal = false
	var sonuc: Dictionary = await _oynat_ic(sahne_yolu, klon_turlari, son_tur, ornekle)
	# Süren işin sinyali başka bir çağrının "mesgul" dönüşüyle karışmasın.
	if sonuc.get("hata", "") != "mesgul":
		bitti.emit(sonuc)
	return sonuc


## Çok adımlı bir işin (determinizm, `BolumDenetci.dinamik`) başında `toplu_basla()`,
## sonunda `toplu_bitir()` çağrılır. Arada iptal bayrağı oynatmalar arasında
## sıfırlanmaz, böylece son karelerde gelen iptal kaybolmaz.
func toplu_basla() -> void:
	_toplu = true
	_iptal = false


func toplu_bitir() -> void:
	_toplu = false


## Aynı çözümü `tekrar` kez oynatır; 0. çalıştırmayı referans alıp bütün örnekleri
## karşılaştırır. `cozum`: {"turlar": Array, "oyuncu": Array} (açık ya da çalıştırma
## uzunluğu kodlu kayıt). Dönüş: {"gecti", "sapmali", "maks_sapma", "bitis_kare"}.
func determinizm(sahne_yolu: String, cozum: Dictionary, tekrar: int) -> Dictionary:
	toplu_basla()
	var turlar: Array = []
	for t in cozum.get("turlar", []):
		turlar.append(_coz(t))
	var son_tur: Array = _coz(cozum.get("oyuncu", []))
	var referans: Dictionary = {}
	var sapmali := 0
	var maks_sapma := 0.0
	var hepsi_bitti := true
	for n in range(tekrar):
		ilerleme.emit(n + 1, tekrar, "Determinizm %d/%d" % [n + 1, tekrar])
		var s: Dictionary = await _oynat_ic(sahne_yolu, turlar, son_tur, true)
		if s.has("hata") or s.has("iptal"):
			var iptalli := {"gecti": false, "sapmali": sapmali, "maks_sapma": maks_sapma,
				"bitis_kare": int(referans.get("bitis_kare", -1))}
			toplu_bitir()
			bitti.emit(iptalli)
			return iptalli
		if not s["bitti"]:
			hepsi_bitti = false
		if n == 0:
			referans = s
			continue
		var d := _sapma(referans, s)
		if d > 0.0:
			sapmali += 1
			maks_sapma = maxf(maks_sapma, d)
	var sonuc := {
		"gecti": hepsi_bitti and sapmali == 0 and maks_sapma == 0.0 and not referans.is_empty(),
		"sapmali": sapmali,
		"maks_sapma": maks_sapma,
		"bitis_kare": int(referans.get("bitis_kare", -1)),
	}
	toplu_bitir()
	bitti.emit(sonuc)
	return sonuc


## Bölümün anlık durumunu tür tabanlı ad -> değer sözlüğüne yazar (yalnız okur):
## oyuncu/klon konumu, plaka basılı, lazer açık, geçit/asansör y, şalter, kutu konumu.
static func ornekle(bolum: Node) -> Dictionary:
	var d := {}
	var klon_no := 0
	for c in bolum.get_children():
		if c is CharacterBody2D and c.get("klon") != null:
			if c.klon:
				d["klon_%d" % klon_no] = c.global_position
				d["klon_%d_oldu" % klon_no] = c.oldu
				klon_no += 1
			else:
				d["oyuncu"] = c.global_position
				d["oyuncu_oldu"] = c.oldu
		elif c.has_method("basili_mi"):
			d[str(c.name)] = c.basili_mi()
		elif c.has_method("acik_mi"):
			d[str(c.name)] = c.acik_mi()
		elif c is AnimatableBody2D:
			d[str(c.name)] = c.position.y
		elif c.has_method("it"):
			d[str(c.name)] = c.global_position
		elif c.get("sagda") != null:
			d[str(c.name)] = c.sagda
	return d


# ---------------------------------------------------------------- iç işleyiş

func _oynat_ic(sahne_yolu: String, klon_turlari: Array, son_tur: Array, ornekle_mi: bool) -> Dictionary:
	var sonuc := {"bitti": false, "oldu": false, "bitis_kare": -1,
		"kareler": [] as Array[int], "ornekler": []}
	if _calisiyor:
		sonuc["hata"] = "mesgul"
		return sonuc
	_calisiyor = true
	var agac := get_tree()
	var kayitlar := get_node_or_null("/root/Kayitlar")
	agac.paused = false
	if kayitlar != null:
		kayitlar.sifirla()
		for t in klon_turlari:
			kayitlar.tur_kaydet(_coz(t).duplicate(true))
	var bolum := await _yukle(sahne_yolu)
	if bolum == null:
		sonuc["hata"] = "yuklenemedi"
		_temizle(kayitlar)
		return sonuc
	if klon_turlari.size() > int(bolum.get("max_klon")):
		sonuc["hata"] = "klon_siniri"
		_temizle(kayitlar)
		return sonuc
	var oyuncu: CharacterBody2D = bolum.get_node("Oyuncu")
	var son: Array = _coz(son_tur)
	_girdi_uygula(_girdi_kare(son, 0))
	var en_uzun := son.size()
	for t in klon_turlari:
		en_uzun = maxi(en_uzun, _coz(t).size())
	var sinir: int = en_uzun + SURE_PAYI
	while oyuncu.kare < sinir:
		if _iptal:
			sonuc["iptal"] = true
			break
		if oyuncu.oldu:
			sonuc["oldu"] = true
			break
		if bolum.bitti:
			sonuc["bitti"] = true
			sonuc["bitis_kare"] = oyuncu.kare
			break
		var k: int = oyuncu.kare
		_bekleyen = _girdi_kare(son, k + 1)
		if ornekle_mi:
			sonuc["kareler"].append(k)
			sonuc["ornekler"].append(ornekle(bolum))
		await agac.physics_frame
		if not is_instance_valid(bolum) or not is_instance_valid(oyuncu):
			# Canlı oyuncu ölünce sahne ertelenmiş çağrıyla yeniden yüklenir.
			sonuc["oldu"] = true
			break
	_bekleyen = null
	_girdi_birak()
	# Bölüm bittiyse sonuç ekranı ertelenmiş çağrıyla kurulur; bitmesini bekle.
	for i in range(3):
		await agac.physics_frame
	if not sonuc["bitti"] and not sonuc["oldu"] and not sonuc.has("iptal"):
		# Döngü çıkışında son durum (ör. bitiş tam sınır karesinde).
		if is_instance_valid(bolum) and bolum.get("bitti") == true and is_instance_valid(oyuncu) and not oyuncu.oldu:
			sonuc["bitti"] = true
			sonuc["bitis_kare"] = oyuncu.kare
	if _iptal:
		sonuc["iptal"] = true
	_temizle(kayitlar)
	return sonuc


func _temizle(kayitlar: Node) -> void:
	_bekleyen = null
	_girdi_birak()
	get_tree().paused = false
	if kayitlar != null:
		kayitlar.sifirla()
	_calisiyor = false


## Sahneyi sıfırdan yükler, hazır olmasını bekler (en çok 30 fizik karesi).
func _yukle(sahne_yolu: String) -> Node:
	var agac := get_tree()
	var eski := agac.current_scene
	agac.change_scene_to_file(sahne_yolu)
	for i in range(30):
		await agac.physics_frame
		var b := agac.current_scene
		if b != null and b != eski and b.is_node_ready() and b.get_node_or_null("Oyuncu") != null:
			return b
	return null


func _girdi_kare(kayit: Array, k: int) -> Dictionary:
	return kayit[k] if k < kayit.size() else {"yon": 0.0, "zipla": false, "asagi": false}


func _girdi_birak() -> void:
	for a in _EYLEMLER:
		Input.action_release(a)


## Önce bütün oyun eylemleri bırakılır, sonra kaydın o karesi basılır.
func _girdi_uygula(g: Dictionary) -> void:
	_girdi_birak()
	if g.get("asagi", false):
		Input.action_press("asagi")
	var yon: float = g.get("yon", 0.0)
	if yon > 0.0:
		Input.action_press("sag")
	elif yon < 0.0:
		Input.action_press("sol")
	if g.get("zipla", false):
		Input.action_press("zipla")


## Çalıştırma uzunluğu kodlu kaydı ([[n, yon, z, a], ...]) açar; açık kayıt aynen döner.
func _coz(tur: Array) -> Array:
	if tur.size() > 0 and tur[0] is Array:
		return BolumVerisi.kayit_coz(tur)
	return tur


## İki oynatma arasındaki en büyük sapma (px; sayısal olmayan farklar 1.0 sayılır).
func _sapma(a: Dictionary, b: Dictionary) -> float:
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
			var u = x[anahtar]
			var v = y[anahtar]
			if u is Vector2 and v is Vector2:
				maks = maxf(maks, (u - v).length())
			elif (u is float or u is int) and (v is float or v is int):
				maks = maxf(maks, absf(float(u) - float(v)))
			elif u != v:
				maks = maxf(maks, 1.0)
	return maks
