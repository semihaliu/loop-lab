extends RefCounted
## Fizik kayması testi (docs/devir/editor_taslak.md §9, A6): editör sınıfları (bolum_kurucu.gd ve
## bağımlıları) yüklenmeden önce Bölüm 13/14/19 çözümleri oynatılır (iz A); sonra editör sahnesi
## yüklenir, Dene'ye girilip çıkılır ve aynı çözümler yeniden oynatılır (iz B). A == B olmalıdır.
## Bu dosya editör sınıflarına KOD İÇİNDE başvurmaz (yalnız sahne yolları, load, call/get/set,
## düğüm adları); aksi halde derleme o sınıfları yükler ve öncül bozulur. `class_name` yoktur.
## Yalnızca user://test_editor/ altına yazar ve sonda siler.

const KOK := "user://test_editor/"
const EDITOR_SAHNESI := "res://scenes/editor.tscn"
const FIKSTUR := "res://tests/editor/fikstur/"
const LAZER_SAHNESI := "res://scenes/lazer.tscn"
const KURUCU_BETIGI := "res://scripts/editor/bolum_kurucu.gd"
const BOLUMLER := {
	13: "res://scenes/bolumler/bolum_13.tscn",
	14: "res://scenes/bolumler/bolum_14.tscn",
	19: "res://scenes/bolumler/bolum_19.tscn",
}

var r: SceneTree


func _init(runner: SceneTree) -> void:
	r = runner


func _kaydi(ad: String, gecti: bool, ayrinti: String) -> void:
	r.call("_kaydi", "Dene fizik: " + ad, gecti, ayrinti)


func _dizin_sil(yol: String) -> void:
	var d := DirAccess.open(yol)
	if d == null:
		return
	for alt in d.get_directories():
		_dizin_sil(yol.path_join(alt))
	for dosya in d.get_files():
		DirAccess.remove_absolute(yol.path_join(dosya))
	DirAccess.remove_absolute(yol)


func _sahne_bekle(eski_id: int) -> Node:
	var s: Node = await r.call("_yeni_sahne_bekle", eski_id)
	await r.physics_frame
	return s


## Bölüm 13/14/19 tam çözümünü (kayıtlar baştan üretilir) oynatır; iz, klon izleri, bitiş karesi.
func _oyna(kod: int) -> Dictionary:
	var s: Dictionary
	r.set("aktif_bolum", BOLUMLER[kod])
	if kod == 13:
		r.set("_b13_onbellek", [])
		var kay: Array = await r.call("_b13_kayitlar")
		s = await r.call("_b13_senaryo", kay, r.call("_b13_oyuncu", r.call("_b13_salter_sola"), 10))
	elif kod == 14:
		r.set("_b14_onbellek", [])
		var kay14: Array = await r.call("_b14_kayitlar")
		s = await r.call("_b14_senaryo", kay14, r.call("_b14_oyuncu"))
	else:
		r.set("_n19_onb", [])
		var kay19: Array = await r.call("_n19_kayitlar")
		s = await r.call("_n_senaryo", kay19, r.call("_n19_o"))
	return {"iz": s["iz"], "klon": s["klon_izleri"], "kare": s["kare"], "bitti": s["bitti"]}


func _fark(a: Dictionary, b: Dictionary) -> Dictionary:
	var maks := 0.0
	var ayni: bool = (a["iz"] as Array).size() == (b["iz"] as Array).size() and (a["klon"] as Array).size() == (b["klon"] as Array).size()
	if ayni:
		for i in (a["iz"] as Array).size():
			maks = maxf(maks, (a["iz"][i] as Vector2).distance_to(b["iz"][i]))
		for k in (a["klon"] as Array).size():
			if (a["klon"][k] as Array).size() != (b["klon"][k] as Array).size():
				ayni = false
				break
			for i in (a["klon"][k] as Array).size():
				maks = maxf(maks, (a["klon"][k][i] as Vector2).distance_to(b["klon"][k][i]))
	return {"maks": maks, "uzunluk": ayni}


func _bekle(kare: int) -> void:
	for i in kare:
		await r.physics_frame


## Editör sahnesini açar, fikstür bölümünü (lazer, kutu, bant, plaka, geçit...) dosyadan açar; Dene'ye girer.
## Dönüş: Dene sahnesi (null: girilemedi).
func _editorde_dene(fikstur: String) -> Array:
	var e: Node = await r.call("_ar_sahne_yukle", EDITOR_SAHNESI)
	await r.process_frame
	e.set("kok", KOK)
	var sorunlar: Array = e.call("ac", FIKSTUR + fikstur)
	var eid := e.get_instance_id()
	var girdi: bool = e.call("dene_baslat")
	var dene: Node = await _sahne_bekle(eid) if girdi else null
	return [girdi and dene != null and str(dene.scene_file_path).begins_with(KOK + "editor/dene_"), dene, sorunlar.size()]


## Editöre dönen sahneyi bekler ve Menü ile ana menüye çıkar (kirliyse onaylar). Dönüş: ana menü açıldı mı.
func _editorden_menuye(eski: Node) -> bool:
	var eid := eski.get_instance_id()
	var e2: Node = await _sahne_bekle(eid)
	if e2 == null or not str(e2.scene_file_path).ends_with("editor.tscn"):
		return false
	e2.set("kok", KOK)
	var id2 := e2.get_instance_id()
	e2.call("menu_iste")
	if e2.onay_diyalogu.visible:
		e2.call("onay_kabul")
	var menu: Node = await _sahne_bekle(id2)
	return menu != null and str(menu.scene_file_path).ends_with("ana_menu.tscn")


func _karsilastir(ad_on: String, a: Dictionary) -> void:
	var b := {}
	for kod in [13, 14, 19]:
		b[kod] = await _oyna(kod)
	for kod in [13, 14, 19]:
		var f := _fark(a[kod], b[kod])
		var tam: bool = f["uzunluk"] and float(f["maks"]) == 0.0 and a[kod]["kare"] == b[kod]["kare"] and a[kod]["bitti"] == b[kod]["bitti"]
		_kaydi("%s: Bölüm %d çözüm izi (oyuncu + klonlar) iz A ile birebir aynı, aynı bitiş karesi" % [ad_on, kod],
			tam and bool(a[kod]["bitti"]),
			"maks fark=%.4f px, uzunluk eşit=%s, kare A=%d B=%d, bitti A=%s B=%s" % [
				f["maks"], f["uzunluk"], a[kod]["kare"], b[kod]["kare"], a[kod]["bitti"], b[kod]["bitti"]])


func hepsi() -> void:
	r.paused = false
	_dizin_sil(KOK)
	var kayitlar: Node = r.call("_kayitlar")
	var onceki_aktif: Variant = r.get("aktif_bolum")

	# (a) iz A: editör sınıfları yüklenmemişken
	var onbos := not ResourceLoader.has_cached(KURUCU_BETIGI)
	_kaydi("öncül: iz A alınmadan önce editör sınıfları yüklenmemiş (bolum_kurucu.gd önbellekte değil)", onbos,
		"has_cached(%s) = %s" % [KURUCU_BETIGI, not onbos])
	var a := {}
	for kod in [13, 14, 19]:
		a[kod] = await _oyna(kod)
	# Kontrol: editör hâlâ yüklenmemişken aynı çözümü yeniden oynat (A2). A2 != A ise fark editörden değil, süreçten gelir.
	var a2 := {}
	for kod in [13, 14, 19]:
		a2[kod] = await _oyna(kod)
	for kod in [13, 14, 19]:
		var f0 := _fark(a[kod], a2[kod])
		_kaydi("kontrol Bölüm %d: editörsüz tekrar oynatma (A2) iz A ile birebir aynı" % kod,
			f0["uzunluk"] and float(f0["maks"]) == 0.0 and a[kod]["kare"] == a2[kod]["kare"],
			"maks fark=%.4f px, uzunluk eşit=%s, kare A=%d A2=%d" % [f0["maks"], f0["uzunluk"], a[kod]["kare"], a2[kod]["kare"]])
	var a_sonra_bos := not ResourceLoader.has_cached(KURUCU_BETIGI)
	_kaydi("iz A alınırken editör sınıfları hâlâ yüklenmemiş", a_sonra_bos, "has_cached = %s" % (not a_sonra_bos))
	var lazer_a := ResourceLoader.has_cached(LAZER_SAHNESI)

	# (b1) YOL 1: fikstür bölümü (lazer, kutu, bant) Dene'de; çözümü kaydetmeden ev butonuyla editöre, Menü ile ana menüye
	var g1: Array = await _editorde_dene("b10.json")
	var ev_menu := false
	if g1[0]:
		g1[1].butonlar.ev_dugmesi.pressed.emit()
		ev_menu = await _editorden_menuye(g1[1])
	_kaydi("yol 1 (ev): lazer/kutu/bant içeren fikstür Dene'ye girer, ev ile editöre, Menü ile ana menüye; Kayitlar boş",
		g1[0] and ev_menu and (kayitlar.turlar as Array).is_empty(), "dene=%s ana menü=%s sorun=%d" % [g1[0], ev_menu, g1[2]])
	await _bekle(5)
	_kaydi("ana menüde lazer.tscn önbellekte değil (editör çıkışı + sahne serbest, yol 1)", not ResourceLoader.has_cached(LAZER_SAHNESI),
		"has_cached(lazer.tscn)=%s (iz A sonunda %s)" % [ResourceLoader.has_cached(LAZER_SAHNESI), lazer_a])
	_kaydi("editör sınıfları artık yüklü (Dene gerçekten kullanıldı)", ResourceLoader.has_cached(KURUCU_BETIGI), "")
	await _karsilastir("yol 1 (ev)", a)

	# (b2) YOL 2: Dene'de bir tur oyna, sonuç ekranında 'Çözümü kaydet ve editöre dön'
	var g2: Array = await _editorde_dene("b14.json")
	var cozum_menu := false
	if g2[0]:
		var dene2: Node = g2[1]
		await _bekle(10)
		await r.call("_r_bas")
		var d2b: Node = await _sahne_bekle(dene2.get_instance_id())
		await _bekle(10)
		dene2 = d2b
		dene2.call("_bolumu_bitir")
		await r.process_frame
		var sonuc2: Node = dene2.get_node_or_null("SonucEkrani")
		if sonuc2 != null and sonuc2.get("cozum_dugmesi") != null:
			sonuc2.cozum_dugmesi.pressed.emit()
			cozum_menu = await _editorden_menuye(dene2)
		r.paused = false
	_kaydi("yol 2 (çözümü kaydet): lazer içeren fikstür Dene'de oynanır, çözüm kaydedilip editöre dönülür, Menü ile ana menü; Kayitlar boş",
		g2[0] and cozum_menu and (kayitlar.turlar as Array).is_empty(), "dene=%s ana menü=%s" % [g2[0], cozum_menu])
	await _bekle(5)
	_kaydi("ana menüde lazer.tscn önbellekte değil (yol 2)", not ResourceLoader.has_cached(LAZER_SAHNESI), "has_cached(lazer.tscn)=%s" % ResourceLoader.has_cached(LAZER_SAHNESI))
	await _karsilastir("yol 2 (çözümü kaydet)", a)

	# (b3) YOL 3: sonuç ekranında 'Editöre dön'
	var g3: Array = await _editorde_dene("b10.json")
	var don_menu := false
	if g3[0]:
		var dene3: Node = g3[1]
		await _bekle(5)
		dene3.call("_bolumu_bitir")
		await r.process_frame
		var sonuc3: Node = dene3.get_node_or_null("SonucEkrani")
		if sonuc3 != null:
			sonuc3.menu_dugmesi.pressed.emit()
			don_menu = await _editorden_menuye(dene3)
		r.paused = false
	_kaydi("yol 3 (sonuç ekranı 'Editöre dön'): lazer/kutu/bant fikstür, editöre dönüş, Menü ile ana menü; Kayitlar boş",
		g3[0] and don_menu and (kayitlar.turlar as Array).is_empty(), "dene=%s ana menü=%s" % [g3[0], don_menu])
	await _bekle(5)
	_kaydi("ana menüde lazer.tscn önbellekte değil (yol 3)", not ResourceLoader.has_cached(LAZER_SAHNESI), "has_cached(lazer.tscn)=%s" % ResourceLoader.has_cached(LAZER_SAHNESI))
	await _karsilastir("yol 3 (Editöre dön)", a)

	r.set("aktif_bolum", onceki_aktif)
	r.paused = false
	kayitlar.sifirla()
	_dizin_sil(KOK)
