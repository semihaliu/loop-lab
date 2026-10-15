extends SceneTree
## Klon mantığı için otomatik testler. Oyun koduna dokunmaz; canlı oyuncunun
## girdisini Input.action_press ile enjekte eder, her şey fizik karesine bağlıdır.
##
## Çalıştırma (tek komut, gerçek saatten bağımsız):
##   Godot --headless --path . --fixed-fps 60 --script res://tests/test_runner.gd
## Rapor dosyasına yazmak için sonuna `-- --rapor` ekle (docs/testler.md).
## Çıkış kodu: hepsi geçtiyse 0, değilse 1.

const BOLUM := "res://scenes/bolumler/bolum_1.tscn"

## Şu an yüklenecek bölüm sahnesi (şalter/geçit testleri test sahnesine geçer).
var aktif_bolum := BOLUM
const TEKRAR := 100
const KLON_KARE := 300      # determinizm testinde klonun oynatılacağı kare sayısı
const COZUM_SINIR := 700    # bir turun en fazla süreceği kare (takılmaya karşı)

var sonuclar: Array = []    # {ad, gecti, ayrinti}
var rapor_satirlari: Array = []


func _initialize() -> void:
	# --script + headless modunda kök pencere 64x64 açılır, oyundaki gibi 1152x648 görünmez.
	# İçerik ölçeğiyle viewport'u proje ayarındaki gerçek boyuta sabitle (oyun kodu değişmez).
	root.content_scale_size = Vector2i(
		ProjectSettings.get_setting("display/window/size/viewport_width", 1152),
		ProjectSettings.get_setting("display/window/size/viewport_height", 648))
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	_calistir()


func _calistir() -> void:
	var baslangic := Time.get_ticks_msec()
	if Engine.physics_ticks_per_second != 60:
		print("UYARI: fizik kare hızı 60 değil: ", Engine.physics_ticks_per_second)

	if "--b12" in OS.get_cmdline_user_args():
		aktif_bolum = BOLUM_12
		await _b12_calistir()
		for s in sonuclar:
			print("[%s] %s | %s" % ["GEÇTİ" if s["gecti"] else "KALDI", s["ad"], s["ayrinti"]])
		quit(0)
		return
	if "--b11" in OS.get_cmdline_user_args():
		aktif_bolum = BOLUM_11
		await _test_bolum11_cozum()
		await _test_bolum11_atlanamaz()
		await _test_bolum11_basarisizlik()
		await _test_bolum11_kisayol()
		await _test_bolum11_hassasiyet()
		await _test_bolum11_plaka_ucus()
		await _test_bolum11_klon_siniri()
		await _test_bolum11_determinizm()
		for s in sonuclar:
			print("[%s] %s | %s" % ["GEÇTİ" if s["gecti"] else "KALDI", s["ad"], s["ayrinti"]])
		quit(0)
		return
	if "--b10" in OS.get_cmdline_user_args():
		aktif_bolum = BOLUM_10
		await _test_bolum10_cozum()
		await _test_bolum10_bant()
		await _test_bolum10_atlanamaz()
		await _test_bolum10_atlanamaz_l2_kapali()
		await _test_bolum10_kisayol()
		await _test_bolum10_basarisizlik()
		await _test_bolum10_klon_siniri()
		await _test_bolum10_determinizm()
		for s in sonuclar:
			print("[%s] %s | %s" % ["GEÇTİ" if s["gecti"] else "KALDI", s["ad"], s["ayrinti"]])
		quit(0)
		return
	if "--b9" in OS.get_cmdline_user_args():
		aktif_bolum = BOLUM_9
		await _test_bolum9_cozum()
		await _test_bolum9_alternatif()
		await _test_bolum9_atlanamaz()
		await _test_bolum9_kisayol()
		await _test_bolum9_basarisizlik()
		await _test_bolum9_klon_siniri()
		await _test_bolum9_kutu_tasima()
		await _test_bolum9_ek_olcumler()
		await _test_bolum9_determinizm()
		for s in sonuclar:
			print("[%s] %s | %s" % ["GEÇTİ" if s["gecti"] else "KALDI", s["ad"], s["ayrinti"]])
		quit(0)
		return
	if "--kutu" in OS.get_cmdline_user_args():
		await _asamab_testleri()
		for s in sonuclar:
			print("[%s] %s" % ["GEÇTİ" if s["gecti"] else "KALDI", s["ad"]])
		quit(0)
		return
	await _determinizm_testi()
	await _cozum_testi()
	await _basarisizlik_testleri()
	await _test_klon_asansore_binemez()
	await _test_duvarlar()
	await _test_asansor_durur()
	await _test_klon_siniri()
	await _test_yeniden_baslat()
	aktif_bolum = GECIT_TEST
	await _test_salter_itme()
	await _test_salter_klon()
	await _test_salter_icinden_gecis()
	await _test_gecit_plaka()
	await _test_gecit_salter()
	await _test_gecit_veya()
	await _test_gecit_durur()
	aktif_bolum = BOLUM_2
	await _test_bolum2()
	aktif_bolum = BOLUM
	await _test_bolum_secimi()
	await _test_harita_cizgisi()
	await _test_harita_kesisim()
	await _test_bolum_listesi()
	await _test_harita_dugumleri()
	aktif_bolum = LAZER_TEST
	await _test_lazer_oyuncu_olur()
	await _test_lazer_tetikleyici()
	await _test_lazer_klon()
	await _test_tek_yonlu()
	await _test_lazer_determinizm()
	aktif_bolum = BOLUM_3
	await _test_bolum3_cozum()
	await _test_bolum3_basarisizlik()
	await _test_bolum3_klon_siniri()
	await _test_bolum3_determinizm()
	aktif_bolum = BOLUM_4
	await _test_bolum4_cozum()
	await _test_bolum4_atlanamaz()
	await _test_bolum4_basarisizlik()
	await _test_bolum4_klon_siniri()
	await _test_bolum4_tek_yonlu()
	await _test_bolum4_determinizm()
	aktif_bolum = BOLUM_5
	await _test_bolum5_cozum()
	await _test_bolum5_atlanamaz()
	await _test_bolum5_basarisizlik()
	await _test_bolum5_klon_siniri()
	await _test_bolum5_salter_kalici()
	await _test_bolum5_erken_ayrilma()
	await _test_bolum5_determinizm()
	aktif_bolum = BOLUM_6
	await _test_bolum6_cozum()
	await _test_bolum6_atlanamaz()
	await _test_bolum6_basarisizlik()
	await _test_bolum6_klon_siniri()
	await _test_bolum6_veya()
	await _test_bolum6_determinizm()
	aktif_bolum = BOLUM_7
	await _test_bolum7_cozum()
	await _test_bolum7_atlanamaz()
	await _test_bolum7_basarisizlik()
	await _test_bolum7_klon_siniri()
	await _test_bolum7_uc_klon_gereki()
	await _test_bolum7_determinizm()
	await _test_bolum7_ek_isin()
	await _test_bolum7_ek_kose()
	aktif_bolum = BOLUM_8
	await _test_bolum8_cozum()
	await _test_bolum8_atlanamaz()
	await _test_bolum8_basarisizlik()
	await _test_bolum8_klon_siniri()
	await _test_bolum8_uc_klon_gereki()
	await _test_bolum8_tek_yonlu()
	await _test_bolum8_determinizm()
	aktif_bolum = BOLUM_9
	await _test_bolum9_cozum()
	await _test_bolum9_alternatif()
	await _test_bolum9_atlanamaz()
	await _test_bolum9_kisayol()
	await _test_bolum9_basarisizlik()
	await _test_bolum9_klon_siniri()
	await _test_bolum9_kutu_tasima()
	await _test_bolum9_ek_olcumler()
	await _test_bolum9_determinizm()
	aktif_bolum = BOLUM_10
	await _test_bolum10_cozum()
	await _test_bolum10_bant()
	await _test_bolum10_atlanamaz()
	await _test_bolum10_atlanamaz_l2_kapali()
	await _test_bolum10_kisayol()
	await _test_bolum10_basarisizlik()
	await _test_bolum10_klon_siniri()
	await _test_bolum10_determinizm()
	aktif_bolum = BOLUM_11
	await _test_bolum11_cozum()
	await _test_bolum11_atlanamaz()
	await _test_bolum11_basarisizlik()
	await _test_bolum11_kisayol()
	await _test_bolum11_hassasiyet()
	await _test_bolum11_plaka_ucus()
	await _test_bolum11_klon_siniri()
	await _test_bolum11_determinizm()
	aktif_bolum = BOLUM_12
	await _b12_calistir()
	aktif_bolum = GECIT_TEST
	await _test_olu_klon_gecit()
	await _test_olu_klon_salter()
	aktif_bolum = BOLUM_3
	await _test_olu_klon_kapi()
	await _asamab_testleri()
	aktif_bolum = BOLUM
	_kayitlar().sifirla()

	var sure := (Time.get_ticks_msec() - baslangic) / 1000.0
	var hepsi := true
	print("\n===== SONUÇ =====")
	for s in sonuclar:
		hepsi = hepsi and s["gecti"]
		print("[%s] %s" % ["GEÇTİ" if s["gecti"] else "KALDI", s["ad"]])
	print("Toplam süre: %.1f sn (gerçek saat) -> %s" % [sure, "GEÇTİ" if hepsi else "KALDI"])
	if "--rapor" in OS.get_cmdline_user_args():
		_rapor_yaz(sure, hepsi)
	quit(0 if hepsi else 1)


# ---------------------------------------------------------------- yardımcılar

## [[kare_sayisi, yon, zipla], ...] parçalarını kare başına girdi dizisine açar.
func _betik(parcalar: Array) -> Array:
	var cikti: Array = []
	for p in parcalar:
		for i in range(p[0]):
			cikti.append({"yon": float(p[1]), "zipla": bool(p[2]) and i == 0})
	return cikti


func _girdi_uygula(g: Dictionary) -> void:
	for a in ["sol", "sag", "zipla"]:
		Input.action_release(a)
	if g["yon"] > 0.0:
		Input.action_press("sag")
	elif g["yon"] < 0.0:
		Input.action_press("sol")
	if g["zipla"]:
		Input.action_press("zipla")


func _kayitlar() -> Node:
	return root.get_node("Kayitlar")


## Bölümü sıfırdan yükler ve yeni sahnenin hazır olmasını bekler.
func _bolumu_yukle() -> Node:
	paused = false
	var eski := current_scene
	change_scene_to_file(aktif_bolum)
	for i in range(20):
		await physics_frame
		if current_scene != null and current_scene != eski and current_scene.is_node_ready():
			return current_scene
	push_error("Bölüm yüklenemedi")
	return null


func _klonlar(bolum: Node) -> Array:
	var liste: Array = []
	for c in bolum.get_children():
		if c is CharacterBody2D and c.get("klon") == true:
			liste.append(c)
	return liste


## Bir turu oynatır: girdi betiğini canlı oyuncuya verir.
## bitis_kare: en çok bu kadar kare oyna. Bölüm biterse erken çıkar.
func _tur_oyna(bolum: Node, betik: Array, bitis_kare: int, izleyici := Callable()) -> Dictionary:
	var oyuncu: CharacterBody2D = bolum.get_node("Oyuncu")
	var klonlar: Array = _klonlar(bolum)
	var izler: Array = []
	for k in klonlar:
		izler.append([])
	var asansor: Node2D = bolum.get_node_or_null("Asansor")
	var asansor_iz: Array = []
	var oyuncu_iz: Array = []
	var ozel_iz: Array = []
	while oyuncu.kare < bitis_kare and not bolum.bitti:
		var k: int = oyuncu.kare
		_girdi_uygula(betik[k] if k < betik.size() else {"yon": 0.0, "zipla": false})
		for i in range(klonlar.size()):
			izler[i].append(klonlar[i].global_position)
		oyuncu_iz.append(oyuncu.global_position)
		if izleyici.is_valid():
			ozel_iz.append(izleyici.call(bolum))
		if asansor != null:
			asansor_iz.append(asansor.global_position)
		await physics_frame
	_girdi_uygula({"yon": 0.0, "zipla": false})
	# Bölüm bittiyse bolum.gd sonuç ekranını ertelenmiş çağrıyla kurar; bitmesini bekle.
	for i in range(3):
		await physics_frame
	return {
		"kare": oyuncu.kare,
		"bitti": bolum.bitti,
		"klon_izleri": izler,
		"oyuncu_iz": oyuncu_iz,
		"ozel_iz": ozel_iz,
		"asansor_iz": asansor_iz,
		"butonlar_gorunur": bolum.butonlar.visible,
		"oyuncu_konum": oyuncu.global_position,
	}


## Girdi betiğini canlı oyunla kaydeder (tur 1) ve girdi kaydını döndürür.
func _kaydet(betik: Array) -> Array:
	_kayitlar().sifirla()
	var bolum: Node = await _bolumu_yukle()
	var oyuncu: CharacterBody2D = bolum.get_node("Oyuncu")
	await _tur_oyna(bolum, betik, betik.size())
	return oyuncu.kayit_girdileri.duplicate(true)


## Verilen tur kayıtlarını klon olarak yükler ve canlı oyuncuya betik uygular.
func _senaryo(kayitlar: Array, betik: Array, bitis_kare: int, hazirlik := Callable(), izleyici := Callable()) -> Dictionary:
	_kayitlar().sifirla()
	for k in kayitlar:
		_kayitlar().tur_kaydet(k.duplicate(true))
	var bolum: Node = await _bolumu_yukle()
	if hazirlik.is_valid():
		hazirlik.call(bolum)
	var sonuc: Dictionary = await _tur_oyna(bolum, betik, bitis_kare, izleyici)
	paused = false
	return sonuc


func _kaydi(ad: String, gecti: bool, ayrinti: String) -> void:
	sonuclar.append({"ad": ad, "gecti": gecti, "ayrinti": ayrinti})
	rapor_satirlari.append("- **%s:** %s — %s" % [ad, "GEÇTİ" if gecti else "KALDI", ayrinti])
	print("%s: %s | %s" % [ad, "GEÇTİ" if gecti else "KALDI", ayrinti])


# ---------------------------------------------------------------- testler

# Doğru zamanlama: klon 90 kare bekleyip plakaya yürür. Yanlış: hemen yürür.
func _dogru_kayit_betigi() -> Array:
	return _betik([[90, 0, false], [30, 1, false], [10, 0, false]])


func _erken_kayit_betigi() -> Array:
	return _betik([[30, 1, false], [10, 0, false]])


# Oyuncu asansöre klon plakaya basmadan önce biner, yükselince kapıya yürür.
func _cozum_betigi() -> Array:
	return _betik([[84, 1, false], [130, 0, false], [150, 1, false]])


## 1) Aynı kaydı 100 kez klon olarak oynat, her karedeki konumu karşılaştır.
func _determinizm_testi() -> void:
	var betik := _betik([[5, 0, false], [25, 1, false], [1, 1, true], [40, 1, false],
		[10, -1, false], [20, 0, false], [30, 1, false]])
	var kayit: Array = await _kaydet(betik)
	var referans: Array = []
	var ilk_sapma_kare := -1
	var maks_sapma := 0.0
	var sapmali_calistirma := 0
	for n in range(TEKRAR):
		var s: Dictionary = await _senaryo([kayit], [], KLON_KARE)
		var iz: Array = s["klon_izleri"][0]
		if n == 0:
			referans = iz
			continue
		var bu_sapmali := iz.size() != referans.size()
		for f in range(min(iz.size(), referans.size())):
			var d: float = (iz[f] - referans[f]).length()
			if d > 0.0:
				bu_sapmali = true
				maks_sapma = max(maks_sapma, d)
				if ilk_sapma_kare == -1:
					ilk_sapma_kare = f
					print("  İlk sapma: çalıştırma %d, kare %d, %.4f px" % [n, f, d])
		if bu_sapmali:
			sapmali_calistirma += 1
	# Klonun gerçekten hareket ettiğinden emin ol (boş test olmasın).
	var min_y := 1.0e9
	var maks_x := -1.0e9
	for p in referans:
		min_y = min(min_y, p.y)
		maks_x = max(maks_x, p.x)
	var hareket_var: bool = min_y < referans[0].y - 20.0 and maks_x > referans[0].x + 100.0
	var gecti: bool = sapmali_calistirma == 0 and hareket_var
	var ayrinti := "%d çalıştırma x %d kare, sapmalı çalıştırma: %d, en büyük sapma: %.4f px" % [
		TEKRAR, referans.size(), sapmali_calistirma, maks_sapma]
	if ilk_sapma_kare >= 0:
		ayrinti += ", ilk sapma karesi: %d" % ilk_sapma_kare
	if not hareket_var:
		ayrinti += " (UYARI: klon beklenen şekilde hareket etmedi)"
	_kaydi("Determinizm", gecti, ayrinti)


## 2) Bölüm 1 çözümü: tur 1 plakaya bas ve bekle, tur 2 asansörle çıkıp kapıya git.
func _cozum_testi() -> void:
	var kayit: Array = await _kaydet(_dogru_kayit_betigi())
	var s: Dictionary = await _senaryo([kayit], _cozum_betigi(), COZUM_SINIR)
	var konum: Vector2 = s["oyuncu_konum"]
	_kaydi("Bölüm 1 çözümü", s["bitti"],
		"bölüm bitti: %s, bitiş karesi: %d (%.2f sn), oyuncu konumu: (%.0f, %.0f)" % [
			s["bitti"], s["kare"], s["kare"] / 60.0, konum.x, konum.y])
	_kaydi("Sonuç ekranında ekran butonları gizli", s["bitti"] and not s["butonlar_gorunur"],
		"butonlar görünür: %s (beklenen: false)" % s["butonlar_gorunur"])


## 3) Yanlış zamanlamalarda bölüm bitmemeli.
func _basarisizlik_testleri() -> void:
	var dogru: Array = await _kaydet(_dogru_kayit_betigi())
	var erken: Array = await _kaydet(_erken_kayit_betigi())

	# a) Oyuncu asansöre geç gelir: asansör çoktan yukarıda, binemez.
	var s: Dictionary = await _senaryo([dogru], _betik([[150, 0, false], [400, 1, false]]), COZUM_SINIR)
	_kaydi("Başarısızlık: oyuncu asansöre geç geliyor", not s["bitti"],
		"bölüm bitti: %s (beklenen: false), %d kare oynandı, oyuncu x=%.0f" % [
			s["bitti"], s["kare"], s["oyuncu_konum"].x])

	# b) Klon plakaya çok erken basar: asansör oyuncu varmadan yükselir.
	s = await _senaryo([erken], _cozum_betigi(), COZUM_SINIR)
	_kaydi("Başarısızlık: klon plakaya erken basıyor", not s["bitti"],
		"bölüm bitti: %s (beklenen: false), %d kare oynandı, oyuncu x=%.0f" % [
			s["bitti"], s["kare"], s["oyuncu_konum"].x])

	# c) Klon yok: plaka basılmaz, asansör çıkmaz.
	s = await _senaryo([], _cozum_betigi(), COZUM_SINIR)
	_kaydi("Başarısızlık: klon yok, plaka basılmıyor", not s["bitti"],
		"bölüm bitti: %s (beklenen: false), %d kare oynandı, oyuncu x=%.0f" % [
			s["bitti"], s["kare"], s["oyuncu_konum"].x])


# ---------------------------------------------------------------- yeni testler

## Sahnenin değişmesini bekler (R veya buton sonrası yeniden yükleme).
func _sahne_degisimini_bekle(eski: Node) -> Node:
	for i in range(20):
		await physics_frame
		if current_scene != null and current_scene != eski and current_scene.is_node_ready():
			return current_scene
	return null


## A) Asansör yukarıda kalır, ikinci klon altına yürür ama binemez.
func _test_klon_asansore_binemez() -> void:
	var k1: Array = await _kaydet(_dogru_kayit_betigi())
	# İkinci klon: asansör yükseldikten sonra (kare ~210) altına yürür (x~620).
	var k2: Array = await _kaydet(_betik([[220, 0, false], [84, 1, false], [20, 0, false]]))
	var s: Dictionary = await _senaryo([k1, k2], [], 450)
	var iz2: Array = s["klon_izleri"][1]
	var asansor_iz: Array = s["asansor_iz"]
	var min_y := 1.0e9
	for f in range(10, iz2.size()):   # ilk kareler doğma konumundan zemine düşüş
		min_y = min(min_y, iz2[f].y)
	var son: Vector2 = iz2[iz2.size() - 1]
	var son_asansor_y: float = asansor_iz[asansor_iz.size() - 1].y
	var ust_y: float = 610.0 - 180.0
	var altinda: bool = son.x > 560.0 and son.x < 680.0
	var gecti: bool = (not s["bitti"]) and altinda and min_y > 570.0 \
		and absf(son_asansor_y - ust_y) < 0.01
	_kaydi("A) Klon asansöre binemez", gecti,
		"klon-2 son konum: (%.0f, %.0f), asansörün altında: %s, klon-2 en yüksek y: %.0f (zemin 576), asansör y: %.0f (yukarı: %.0f), bölüm bitti: %s" % [
			son.x, son.y, altinda, min_y, son_asansor_y, ust_y, s["bitti"]])


## B) Sol/sağ/üst duvar: konum hiçbir karede sınırı aşmaz; asansörle çıkılır.
func _test_duvarlar() -> void:
	# Klon plakaya geç (kare ~540) basar; oyuncu önce duvarlara gider, sonra asansöre biner.
	var klon: Array = await _kaydet(_betik([[520, 0, false], [30, 1, false], [10, 0, false]]))
	var betik := _betik([
		[80, -1, false],                       # sol duvara (x -> 14)
		[1, -1, true], [30, -1, false],        # zıpla, duvara yaslan
		[40, 1, false], [1, 1, true], [200, 1, false], [1, 1, true], [40, 1, false],  # sağ duvara, zıplayarak
		[110, -1, false],                      # asansöre dön (x ~ 620)
		[140, 0, false],                       # klon plakaya basana ve asansör çıkana kadar bekle
		[1, 0, true], [60, 0, false],          # asansör üstünde zıpla
		[200, 1, false],                       # kapıya yürü
	])
	var s: Dictionary = await _senaryo([klon], betik, 1000)
	var alan := root.content_scale_size
	var yarim_genislik := 14.0
	var yarim_boy := 24.0
	var ihlal := 0
	var min_x := 1.0e9
	var maks_x := -1.0e9
	var min_y := 1.0e9
	for p in s["oyuncu_iz"]:
		min_x = min(min_x, p.x)
		maks_x = max(maks_x, p.x)
		min_y = min(min_y, p.y)
		if p.x < yarim_genislik - 0.01 or p.x > alan.x - yarim_genislik + 0.01 or p.y < yarim_boy - 0.01:
			ihlal += 1
	# Tavan açıklığı: asansörün üstündeki karakterin kafası ile tavan (y=0) arası.
	var asansor_ust_yuzey := 610.0 - 180.0 - 10.0
	var tavan_acikligi := asansor_ust_yuzey - 2.0 * yarim_boy
	var duvara_vardi: bool = min_x < yarim_genislik + 0.5 and maks_x > alan.x - yarim_genislik - 0.5
	var yukari_cikti: bool = min_y < 420.0 - yarim_boy + 1.0
	var gecti: bool = ihlal == 0 and duvara_vardi and yukari_cikti and tavan_acikligi > 0.0
	_kaydi("B) Sol/sağ/üst duvar", gecti,
		"%d kare izlendi, sınır ihlali: %d, x aralığı: [%.0f, %.0f] (sınır 14..%.0f), en yüksek y: %.0f (tavan sınırı 24), asansör üstündeki karakterin kafası ile tavan arası: %.0f px, bölüm bitti: %s" % [
			s["oyuncu_iz"].size(), ihlal, min_x, maks_x, alan.x - yarim_genislik, min_y, tavan_acikligi, s["bitti"]])


## C) Plaka bırakılınca inen asansör altındaki karakterde durur, ezmez; karakter çekilince iner.
func _test_asansor_durur() -> void:
	var betik := _betik([
		[30, 1, false],     # plakaya (x~350)
		[100, 0, false],    # asansör tamamen yükselsin
		[54, 1, false],     # plakadan çık, asansörün altına yürü (x~620)
		[120, 0, false],    # altında bekle: asansör durmalı
		[100, -1, false],   # çekil: asansör inmeye devam etmeli
		[100, 0, false],
	])
	var s: Dictionary = await _senaryo([], betik, betik.size())
	var oiz: Array = s["oyuncu_iz"]
	var aiz: Array = s["asansor_iz"]
	var alt_y := 610.0
	var en_dar_bosluk := 1.0e9
	for f in range(oiz.size()):
		var yatay_ust_uste: bool = absf(oiz[f].x - aiz[f].x) < 60.0 + 14.0
		if yatay_ust_uste and oiz[f].y > aiz[f].y:   # karakter asansörün altında
			en_dar_bosluk = min(en_dar_bosluk, (oiz[f].y - 24.0) - (aiz[f].y + 10.0))
	var bekleme_basi := 30 + 100 + 54 + 15
	var bekleme_sonu := 30 + 100 + 54 + 120 - 1
	var durdu: bool = absf(aiz[bekleme_basi].y - aiz[bekleme_sonu].y) < 0.01 \
		and aiz[bekleme_sonu].y < alt_y - 5.0
	var ezilmedi: bool = absf(oiz[bekleme_sonu].y - 576.0) < 1.0
	var bosluk_ok: bool = en_dar_bosluk >= -0.01
	var son_y: float = aiz[aiz.size() - 1].y
	var devam_etti: bool = absf(son_y - alt_y) < 0.01
	var gecti: bool = durdu and ezilmedi and bosluk_ok and devam_etti
	_kaydi("C) Asansör altında karakter varken durur", gecti,
		"durdu: %s (y=%.0f, alt=%.0f), en dar boşluk: %.2f px (>=0 beklenir), karakter y: %.0f (ezilmedi: %s), çekilince alta indi: %s (y=%.0f)" % [
			durdu, aiz[bekleme_sonu].y, alt_y, en_dar_bosluk, oiz[bekleme_sonu].y, ezilmedi, devam_etti, son_y])


## R tuşunu bir fizik karesi basılı tutar.
func _r_bas() -> void:
	Input.action_press("tur_bitir")
	await physics_frame
	Input.action_release("tur_bitir")


## D) Klon sınırı: max_klon kadar klon kaydedilince R yeni klon oluşturmaz.
func _test_klon_siniri() -> void:
	_kayitlar().sifirla()
	var bolum: Node = await _bolumu_yukle()
	var maks: int = bolum.max_klon
	var ayrinti: Array = []
	var gecti := maks == 2
	for n in range(maks + 1):
		for i in range(5):
			_girdi_uygula({"yon": 1.0, "zipla": false})
			await physics_frame
		_girdi_uygula({"yon": 0.0, "zipla": false})
		var eski: Node = current_scene
		await _r_bas()
		var yeni: Node = await _sahne_degisimini_bekle(eski)
		var sayi: int = _kayitlar().turlar.size()
		if n < maks:
			gecti = gecti and yeni != null and sayi == n + 1
			bolum = yeni
		else:
			var yazi: String = bolum.bilgi.text
			gecti = gecti and yeni == null and sayi == maks and yazi.contains("Klon hakkı bitti") \
				and yazi.contains("%d/%d" % [maks, maks])
			ayrinti.append("sınırda etiket: \"%s\"" % yazi)
		ayrinti.append("R #%d -> kayıtlı klon: %d" % [n + 1, sayi])
	_kaydi("D) Klon sınırı", gecti, "max_klon=%d; %s" % [maks, ", ".join(ayrinti)])


## E) Baştan başla (dönen ok): tüm klon kayıtları silinir, tur 1'e döner; çözüm baştan uygulanabilir.
func _test_yeniden_baslat() -> void:
	# Gerçek akışla 2 klon kaydet (R), klon hakkı bitsin.
	_kayitlar().sifirla()
	var bolum: Node = await _bolumu_yukle()
	for n in range(2):
		for i in range(5):
			_girdi_uygula({"yon": 1.0, "zipla": false})
			await physics_frame
		_girdi_uygula({"yon": 0.0, "zipla": false})
		var eski_tur: Node = current_scene
		await _r_bas()
		bolum = await _sahne_degisimini_bekle(eski_tur)
	var once_sayi: int = _kayitlar().turlar.size()
	var once_yazi: String = bolum.bilgi.text
	var hak_bitti: bool = once_yazi.contains("Klon hakkı bitti") and once_yazi.contains("2/2")

	var eski: Node = current_scene
	bolum.get_node("EkranButonlari/Kutu/YenidenDugmesi").pressed.emit()
	var yeni: Node = await _sahne_degisimini_bekle(eski)
	var kayit_bos: bool = _kayitlar().turlar.size() == 0
	var klon_sayisi: int = _klonlar(yeni).size()
	var yazi: String = yeni.bilgi.text
	var etiket_ok: bool = yazi.begins_with("Tur 1 ") and yazi.contains("Klon: 0/2") and yazi.contains("R: turu bitir")
	var gecti: bool = hak_bitti and once_sayi == 2 and kayit_bos and klon_sayisi == 0 and etiket_ok
	_kaydi("E) Baştan başla: tam sıfırlama", gecti,
		"öncesi: %d klon, \"%s\"; sonrası: Kayitlar boş: %s, klon sayısı: %d, etiket: \"%s\"" % [
			once_sayi, once_yazi, kayit_bos, klon_sayisi, yazi])

	# E3) Sıfırlamadan sonra Bölüm 1 gerçek akışla (R ile) baştan çözülür.
	var tur1 := _dogru_kayit_betigi()
	await _tur_oyna(yeni, tur1, tur1.size())
	var eski2: Node = current_scene
	await _r_bas()
	var tur2_sahne: Node = await _sahne_degisimini_bekle(eski2)
	var s: Dictionary = await _tur_oyna(tur2_sahne, _cozum_betigi(), COZUM_SINIR)
	_kaydi("E3) Sıfırlama sonrası Bölüm 1 baştan çözülür", s["bitti"] and _kayitlar().turlar.size() == 1,
		"bölüm bitti: %s, bitiş karesi: %d, kayıtlı klon: %d" % [s["bitti"], s["kare"], _kayitlar().turlar.size()])

	# Ev butonu: kayıtlar silinir, ana menüye gidilir. (Bölüm bitti, butonlar gizli: yeni bölüm yükle.)
	_kayitlar().tur_kaydet([])
	var bolum2: Node = await _bolumu_yukle()
	var onceki: Node = current_scene
	bolum2.get_node("EkranButonlari/Kutu/EvDugmesi").pressed.emit()
	var menu: Node = await _sahne_degisimini_bekle(onceki)
	var menude: bool = menu != null and menu.scene_file_path.ends_with("ana_menu.tscn")
	var bosaldi: bool = _kayitlar().turlar.size() == 0
	_kaydi("E2) Ev butonu ana menüye döner", menude and bosaldi,
		"ana menüde: %s, kayıtlar silindi: %s" % [menude, bosaldi])


# ---------------------------------------------------------------- şalter ve geçit testleri

const GECIT_TEST := "res://tests/sahneler/gecit_test.tscn"
const GECIT_KAPALI_Y := 500.0
const GECIT_ACIK_Y := 300.0


func _iz_ornekle(b: Node) -> Dictionary:
	return {
		"plaka": b.get_node("Plaka").basili_mi(),
		"salter": b.get_node("Salter").sagda,
		"gecit_y": b.get_node("Gecit").position.y,
	}


## Geçit tetikleyicilerini bölüm yüklenir yüklenmez ayarlayan hazırlık işlevi üretir.
func _tetikleyici_ayari(adlar: Array) -> Callable:
	return func(b: Node) -> void:
		var dugumler: Array = []
		for ad in adlar:
			dugumler.append(b.get_node(ad))
		b.get_node("Gecit").tetikleyicileri_ayarla(dugumler)


## Şalter durumunun değiştiği kare indeksleri.
func _salter_gecisleri(iz: Array) -> Array:
	var liste: Array = []
	for f in range(1, iz.size()):
		if iz[f]["salter"] != iz[f - 1]["salter"]:
			liste.append(f)
	return liste


## F) Şalter itme: doğru yönde çevirir, yanlış yönden çevirmez, konum kalır.
func _test_salter_itme() -> void:
	# 1) Soldan sağa yürü (sağa geçmeli), uzaklaş ve bekle (kalmalı), sağdan sola yürü (sola geçmeli).
	var betik := _betik([[72, 1, false], [30, 0, false], [60, -1, false], [20, 0, false]])
	var s: Dictionary = await _senaryo([], betik, betik.size(), Callable(), _iz_ornekle)
	var iz: Array = s["ozel_iz"]
	var basta_sol: bool = iz[0]["salter"] == false
	var saga_gecti: bool = iz[101]["salter"] == true   # 72 sağ + 30 bekleme: konum KALIR
	var sola_gecti: bool = iz[iz.size() - 1]["salter"] == false
	var gecisler := _salter_gecisleri(iz)
	var tam_iki: bool = gecisler.size() == 2

	# 2) Yanlış yön: şalter solda iken sağ yarıdan sola basmak çevirmez.
	# Şalterin üstünden zıplayıp (alanlara değmeden) sağ yarıya inilir, sonra sola yürünür.
	var betik2 := _betik([[36, 1, false], [1, 1, true], [45, 1, false], [100, -1, false], [10, 0, false]])
	var s2: Dictionary = await _senaryo([], betik2, betik2.size(), Callable(), _iz_ornekle)
	var iz2: Array = s2["ozel_iz"]
	var hic_cevrilmedi := true
	for o in iz2:
		if o["salter"]:
			hic_cevrilmedi = false
	var min_x := 1.0e9
	var maks_x := -1.0e9
	for p in s2["oyuncu_iz"]:
		min_x = min(min_x, p.x)
		maks_x = max(maks_x, p.x)
	var sagdan_sola_yurudu: bool = maks_x > 580.0 and min_x < 440.0

	var gecti: bool = basta_sol and saga_gecti and sola_gecti and tam_iki and hic_cevrilmedi and sagdan_sola_yurudu
	_kaydi("F) Şalter itme", gecti,
		"başta sol: %s, sağa yürüyünce sağda: %s (ve 30 kare sonra konum kaldı), sola yürüyünce solda: %s, geçiş sayısı: %d (beklenen 2) @kare %s; yanlış yönden (sağ yarıdan sola) çevrilmedi: %s (x aralığı %.0f..%.0f)" % [
			basta_sol, saga_gecti, sola_gecti, gecisler.size(), str(gecisler), hic_cevrilmedi, min_x, maks_x])


## G) Şalter klonla: klon aynı karede iter; 100 tekrar sapma 0.0000 px.
func _test_salter_klon() -> void:
	var betik := _betik([[100, 1, false], [20, 0, false]])
	var kayit: Array = await _kaydet(betik)
	var tur1: Dictionary = await _senaryo([], betik, betik.size(), Callable(), _iz_ornekle)
	var tur1_gecis := _salter_gecisleri(tur1["ozel_iz"])
	var referans_klon: Array = []
	var referans_salter: Array = []
	var klon_gecis: Array = []
	var sapmali := 0
	var maks_sapma := 0.0
	var ilk_sapma := -1
	for n in range(TEKRAR):
		var s: Dictionary = await _senaryo([kayit], [], 160, Callable(), _iz_ornekle)
		var klon_iz: Array = s["klon_izleri"][0]
		var oz: Array = s["ozel_iz"]
		if n == 0:
			referans_klon = klon_iz
			referans_salter = oz
			klon_gecis = _salter_gecisleri(oz)
			continue
		var bu_sapmali := klon_iz.size() != referans_klon.size() or oz.size() != referans_salter.size()
		for f in range(min(klon_iz.size(), referans_klon.size())):
			var d: float = (klon_iz[f] - referans_klon[f]).length()
			d = max(d, absf(oz[f]["gecit_y"] - referans_salter[f]["gecit_y"]))
			if d > 0.0 or oz[f]["salter"] != referans_salter[f]["salter"]:
				bu_sapmali = true
				maks_sapma = max(maks_sapma, d)
				if ilk_sapma < 0:
					ilk_sapma = f
		if bu_sapmali:
			sapmali += 1
	var ayni_kare: bool = tur1_gecis.size() == 1 and klon_gecis.size() == 1 and tur1_gecis[0] == klon_gecis[0]
	var gecti: bool = ayni_kare and sapmali == 0 and referans_salter[referans_salter.size() - 1]["salter"]
	var ayrinti := "tur 1 çevirme karesi: %s, klonla: %s (aynı kare: %s), son konum sağda, %d tekrar, sapmalı çalıştırma: %d, en büyük sapma: %.4f px" % [
		str(tur1_gecis), str(klon_gecis), ayni_kare, TEKRAR, sapmali, maks_sapma]
	if ilk_sapma >= 0:
		ayrinti += ", ilk sapma karesi: %d" % ilk_sapma
	_kaydi("G) Şalter klonla + determinizm", gecti, ayrinti)


## H) İçinden geçerek yürümek: bir kez çevrilir, aynı yönde devam edince tekrar çevrilmez.
func _test_salter_icinden_gecis() -> void:
	var betik := _betik([[100, 1, false], [10, 0, false]])   # x: 200 -> 700, şalter x=500 içinden
	var s: Dictionary = await _senaryo([], betik, betik.size(), Callable(), _iz_ornekle)
	var iz: Array = s["ozel_iz"]
	var gecisler := _salter_gecisleri(iz)
	var son: bool = iz[iz.size() - 1]["salter"]
	_kaydi("H) Şalterin içinden geçerek yürümek", gecisler.size() == 1 and son,
		"çevirme sayısı: %d (beklenen 1) @kare %s, son konum sağda: %s (bilinçli eksi: içinden geçerken çevirir)" % [
			gecisler.size(), str(gecisler), son])


## I) Geçit plaka ile: basılıyken açılır, bırakılınca kapanır, kapalıyken geçilemez.
func _test_gecit_plaka() -> void:
	var ayar := _tetikleyici_ayari(["Plaka"])
	# a) Klon plakada 40 kare durur, sonra çekilir.
	var klon: Array = await _kaydet(_betik([[30, 1, false], [40, 0, false], [30, -1, false]]))
	var s: Dictionary = await _senaryo([klon], [], 300, ayar, _iz_ornekle)
	var iz: Array = s["ozel_iz"]
	var en_yuksek := 1.0e9
	var ihlal := 0
	for f in range(iz.size() - 1):
		en_yuksek = min(en_yuksek, iz[f]["gecit_y"])
		var dy: float = iz[f + 1]["gecit_y"] - iz[f]["gecit_y"]
		var ayni: bool = iz[f]["plaka"] == iz[f + 1]["plaka"] and (f == 0 or iz[f - 1]["plaka"] == iz[f]["plaka"])
		if ayni and iz[f]["plaka"] and dy > 0.01:
			ihlal += 1   # plaka basılıyken kapanmamalı
		if ayni and not iz[f]["plaka"] and dy < -0.01:
			ihlal += 1   # plaka bırakılınca açılmamalı
	var acildi: bool = en_yuksek < GECIT_KAPALI_Y - 40.0
	var kapandi: bool = absf(iz[iz.size() - 1]["gecit_y"] - GECIT_KAPALI_Y) < 0.01
	# b) Klon yok: geçit kapalı, oyuncu geçemez.
	var s2: Dictionary = await _senaryo([], _betik([[400, 1, false]]), 400, ayar, _iz_ornekle)
	var maks_x := -1.0e9
	for p in s2["oyuncu_iz"]:
		maks_x = max(maks_x, p.x)
	var gecemedi: bool = (not s2["bitti"]) and maks_x < 800.0 - 10.0
	# c) Klon plakada kalır: geçit açılır, oyuncu geçip kapıya ulaşır.
	var klon2: Array = await _kaydet(_betik([[30, 1, false], [400, 0, false]]))
	var s3: Dictionary = await _senaryo([klon2], _betik([[250, 1, false]]), 300, ayar, _iz_ornekle)
	var gecti: bool = acildi and kapandi and ihlal == 0 and gecemedi and s3["bitti"]
	_kaydi("I) Geçit plaka ile", gecti,
		"açıldı (en yüksek y=%.0f, kapalı %.0f): %s, bırakılınca kapandı: %s, yön ihlali: %d; kapalıyken geçemedi (en uzak x=%.0f, bitti=%s): %s; açıkken geçti ve bölüm bitti: %s" % [
			en_yuksek, GECIT_KAPALI_Y, acildi, kapandi, ihlal, maks_x, s2["bitti"], gecemedi, s3["bitti"]])


## J) Geçit şalter ile: şalter sağda iken açılır, orada kaldıkça açık kalır.
func _test_gecit_salter() -> void:
	var ayar := _tetikleyici_ayari(["Salter"])
	# Oyuncu şalteri sağa iter, ilerleyip durur, geçit açık kalmalı.
	var betik := _betik([[70, 1, false], [250, 0, false]])
	var s: Dictionary = await _senaryo([], betik, betik.size(), ayar, _iz_ornekle)
	var iz: Array = s["ozel_iz"]
	var acik_kare := -1
	for f in range(iz.size()):
		if absf(iz[f]["gecit_y"] - GECIT_ACIK_Y) < 0.01:
			acik_kare = f
			break
	var acik_kaldi := acik_kare >= 0
	for f in range(max(acik_kare, 0), iz.size()):
		if absf(iz[f]["gecit_y"] - GECIT_ACIK_Y) > 0.01 or not iz[f]["salter"]:
			acik_kaldi = false
	# Şalter ilk karelerde soldaydı, geçit kapalıydı.
	var basta_kapali: bool = absf(iz[0]["gecit_y"] - GECIT_KAPALI_Y) < 0.01 and not iz[0]["salter"]
	# Açıkken oyuncu geçidi geçip kapıya ulaşır.
	var s2: Dictionary = await _senaryo([], _betik([[170, 1, false]]), 200, ayar, _iz_ornekle)
	var gecti: bool = basta_kapali and acik_kare >= 0 and acik_kaldi and s2["bitti"]
	_kaydi("J) Geçit şalter ile", gecti,
		"başta kapalı: %s, tam açık olduğu kare: %d, sonuna kadar açık kaldı: %s, açıkken geçip bitirdi: %s" % [
			basta_kapali, acik_kare, acik_kaldi, s2["bitti"]])


## K) Geçit VEYA: plaka veya şalterden biri aktifse açılır, ikisi de pasifse kapanır.
func _test_gecit_veya() -> void:
	var ayar := _tetikleyici_ayari(["Plaka", "Salter"])
	var klon: Array = await _kaydet(_betik([[30, 1, false], [30, 0, false], [30, -1, false]]))
	# Oyuncu: bekle, şalteri sağa it (sağda kal), geri dönüp sola it (ikisi de pasif).
	var betik := _betik([[80, 0, false], [100, 1, false], [60, 0, false], [100, -1, false], [150, 0, false]])
	var s: Dictionary = await _senaryo([klon], betik, betik.size(), ayar, _iz_ornekle)
	var iz: Array = s["ozel_iz"]
	var yalniz_plaka_acti := false
	var yalniz_salter_acti := false
	var pasifken_kapandi := false
	var ihlal := 0
	for f in range(1, iz.size() - 1):
		var aktif: bool = iz[f]["plaka"] or iz[f]["salter"]
		var degisti: bool = (iz[f - 1]["plaka"] or iz[f - 1]["salter"]) != aktif \
			or (iz[f + 1]["plaka"] or iz[f + 1]["salter"]) != aktif
		if degisti:
			continue
		var dy: float = iz[f + 1]["gecit_y"] - iz[f]["gecit_y"]
		if aktif and dy > 0.01:
			ihlal += 1
		if not aktif and dy < -0.01:
			ihlal += 1
		if iz[f]["plaka"] and not iz[f]["salter"] and dy < -0.01:
			yalniz_plaka_acti = true
		if iz[f]["salter"] and not iz[f]["plaka"] and dy < -0.01:
			yalniz_salter_acti = true
		if not aktif and dy > 0.01:
			pasifken_kapandi = true
	var son_kapali: bool = absf(iz[iz.size() - 1]["gecit_y"] - GECIT_KAPALI_Y) < 0.01
	var gecti: bool = yalniz_plaka_acti and yalniz_salter_acti and pasifken_kapandi and ihlal == 0 and son_kapali
	_kaydi("K) Geçit VEYA mantığı", gecti,
		"yalnız plaka aktifken açıldı: %s, yalnız şalter aktifken açıldı: %s, ikisi pasifken kapandı: %s, yön ihlali: %d, sonunda kapalı: %s" % [
			yalniz_plaka_acti, yalniz_salter_acti, pasifken_kapandi, ihlal, son_kapali])


## L) Geçit durur: kapanırken içinde karakter varsa ezmez, çıkınca kapanır.
func _test_gecit_durur() -> void:
	var ayar := _tetikleyici_ayari(["Plaka"])
	var klon: Array = await _kaydet(_betik([[30, 1, false], [150, 0, false], [30, -1, false]]))
	var betik := _betik([[120, 1, false], [240, 0, false], [100, 1, false]])
	var s: Dictionary = await _senaryo([klon], betik, 460, ayar, _iz_ornekle)
	var oiz: Array = s["oyuncu_iz"]
	var iz: Array = s["ozel_iz"]
	var en_dar := 1.0e9
	for f in range(min(oiz.size(), iz.size())):
		if absf(oiz[f].x - 800.0) < 10.0 + 14.0 and oiz[f].y > iz[f]["gecit_y"]:
			en_dar = min(en_dar, (oiz[f].y - 24.0) - (iz[f]["gecit_y"] + 100.0))
	var a := 120 + 120   # klonun plakadan çekildiği kareden sonra, oyuncu hâlâ bekliyor
	var b := 120 + 240 - 1
	var durdu: bool = absf(iz[a + 100]["gecit_y"] - iz[b]["gecit_y"]) < 0.01 \
		and iz[b]["gecit_y"] > GECIT_ACIK_Y + 5.0 and iz[b]["gecit_y"] < GECIT_KAPALI_Y - 5.0
	var ezilmedi: bool = absf(oiz[b].y - 576.0) < 1.0
	var son_y: float = iz[iz.size() - 1]["gecit_y"]
	var kapandi: bool = absf(son_y - GECIT_KAPALI_Y) < 0.01
	var gecti: bool = durdu and ezilmedi and en_dar >= -0.01 and kapandi
	_kaydi("L) Geçit içinde karakter varken durur", gecti,
		"durdu: %s (y=%.0f, kapalı %.0f), en dar boşluk: %.2f px (>=0 beklenir), karakter y=%.0f (ezilmedi: %s), çıkınca kapandı: %s (y=%.0f)" % [
			durdu, iz[b]["gecit_y"], GECIT_KAPALI_Y, en_dar, oiz[b].y, ezilmedi, kapandi, son_y])


# ---------------------------------------------------------------- Bölüm 2 testleri

const BOLUM_2 := "res://scenes/bolumler/bolum_2.tscn"
const B2_GECIT_KAPALI_Y := 230.0
const B2_GECIT_ACIK_Y := 160.0   # 70 px yukarı: altından 70 px boşluk


func _b2_ornekle(b: Node) -> Dictionary:
	return {
		"salter": b.get_node("Salter").sagda,
		"gecit_y": b.get_node("Gecit").position.y,
		"e1_y": b.get_node("Asansor1").position.y,
		"e2_y": b.get_node("Asansor2").position.y,
	}


# Tur 1 (klon A): bekle, P1'e (x=300) yürü ve orada kal.
func _b2_betik_a(bekleme := 200) -> Array:
	return _betik([[bekleme, 0, false], [40, 1, false], [10, 0, false]])


# Tur 2 (klon B): E1'e bin (x=960), yüksel, F2'de sola yürü, P2'ye (x=130) çık.
func _b2_betik_b() -> Array:
	return _betik([[172, 1, false], [158, 0, false], [166, -1, false], [10, 0, false]])


# Tur 3: E1'e bin, E2'nin üstünde (x=360) B'nin P2'ye basmasını bekle, F3'te sağa yürü.
func _b2_betik_son(sag_kare := 260) -> Array:
	return _betik([[172, 1, false], [158, 0, false], [120, -1, false], [130, 0, false], [sag_kare, 1, false]])


## Önceki klonlar oynarken canlı oyuncuya betik uygulatıp kaydını döndürür (yeni klon kaydı).
func _kaydet_klonlu(onceki: Array, betik: Array) -> Array:
	_kayitlar().sifirla()
	for k in onceki:
		_kayitlar().tur_kaydet(k.duplicate(true))
	var bolum: Node = await _bolumu_yukle()
	var oyuncu: CharacterBody2D = bolum.get_node("Oyuncu")
	await _tur_oyna(bolum, betik, betik.size())
	return oyuncu.kayit_girdileri.duplicate(true)


## Bölüm 2 çözümünü oynatır; sonuç ve izler döner.
func _b2_cozum_oyna(son_betik: Array, bitis := 1200, hazirlik := Callable()) -> Dictionary:
	var a: Array = await _kaydet(_b2_betik_a())
	var b: Array = await _kaydet_klonlu([a], _b2_betik_b())
	return await _senaryo([a, b], son_betik, bitis, hazirlik, _b2_ornekle)


func _test_bolum2() -> void:
	# 1) Planlanan çözüm.
	var s: Dictionary = await _b2_cozum_oyna(_b2_betik_son())
	var konum: Vector2 = s["oyuncu_konum"]
	var klonlar_son: Array = []
	for iz in s["klon_izleri"]:
		klonlar_son.append(iz[iz.size() - 1])
	var a_son: Vector2 = klonlar_son[0]
	var b_son: Vector2 = klonlar_son[1]
	# Klonlar asansör boşluklarının altında kalmamalı (E1: x 900..1020, E2: x 300..420).
	var a_altinda := a_son.x > 886.0 and a_son.x < 1034.0
	var b_altinda := b_son.x > 286.0 and b_son.x < 434.0
	var maks_e1 := 1.0e9
	for o in s["ozel_iz"]:
		maks_e1 = min(maks_e1, o["e1_y"])
	var gecti: bool = s["bitti"] and not a_altinda and not b_altinda and s["ozel_iz"][s["ozel_iz"].size() - 1]["salter"]
	_kaydi("Bölüm 2 çözümü", gecti,
		"bölüm bitti: %s, bitiş karesi: %d (%.2f sn), oyuncu (%.0f, %.0f), klon A (%.0f, %.0f), klon B (%.0f, %.0f), klonlar asansör altında değil: %s, E1 en yüksek y=%.0f" % [
			s["bitti"], s["kare"], s["kare"] / 60.0, konum.x, konum.y, a_son.x, a_son.y, b_son.x, b_son.y,
			not a_altinda and not b_altinda, maks_e1])

	# 2) Başarısızlık: klon A yok, E1 çıkmaz, oyuncu F2'ye çıkamaz.
	var b: Array = await _kaydet(_b2_betik_b())
	var s1: Dictionary = await _senaryo([b], _b2_betik_son(), 900, Callable(), _b2_ornekle)
	_kaydi("Bölüm 2 başarısızlık: plaka klonu (A) yok", (not s1["bitti"]) and s1["oyuncu_konum"].y > 500.0,
		"bölüm bitti: %s, oyuncu y=%.0f (F1 ≈ 576, F2 ≈ 416)" % [s1["bitti"], s1["oyuncu_konum"].y])

	# 3) Başarısızlık: klon B yok, E2 çıkmaz, oyuncu F3'e varamaz.
	var a: Array = await _kaydet(_b2_betik_a())
	var s2: Dictionary = await _senaryo([a], _b2_betik_son(), 900, Callable(), _b2_ornekle)
	_kaydi("Bölüm 2 başarısızlık: P2 klonu (B) yok", (not s2["bitti"]) and s2["oyuncu_konum"].y > 340.0,
		"bölüm bitti: %s, oyuncu y=%.0f (F2 ≈ 416, F3 ≈ 256)" % [s2["bitti"], s2["oyuncu_konum"].y])

	# 4) Başarısızlık: A plakaya çok erken basar, E1 oyuncu binmeden yükselir.
	var a_erken: Array = await _kaydet(_b2_betik_a(0))
	var b2: Array = await _kaydet_klonlu([a], _b2_betik_b())
	var s3: Dictionary = await _senaryo([a_erken, b2], _b2_betik_son(), 900, Callable(), _b2_ornekle)
	_kaydi("Bölüm 2 başarısızlık: klon A plakaya erken basıyor", (not s3["bitti"]) and s3["oyuncu_konum"].y > 500.0,
		"bölüm bitti: %s, oyuncu y=%.0f" % [s3["bitti"], s3["oyuncu_konum"].y])

	# 5) Kapalı geçit atlanamaz: F3'te geçit tetikleyicisiz (kapalı) bırakılır, oyuncu zıplayarak ilerler.
	var betik := _b2_betik_son(0)
	for i in range(20):
		betik.append_array(_betik([[1, 1, true], [24, 1, false]]))
	var kapali := func(bb: Node) -> void:
		bb.get_node("Gecit").tetikleyicileri_ayarla([])
	var s4: Dictionary = await _b2_cozum_oyna(betik, betik.size(), kapali)
	var f3_de: bool = s4["oyuncu_konum"].y < 300.0
	var maks_x := -1.0e9
	for p in s4["oyuncu_iz"]:
		if p.y < 300.0:
			maks_x = max(maks_x, p.x)
	_kaydi("Bölüm 2: kapalı geçit atlanamaz", f3_de and maks_x < 790.0 and not s4["bitti"],
		"oyuncu F3'te: %s, F3'te en uzak x=%.0f (geçit x=800, sınır 776), bölüm bitti: %s" % [f3_de, maks_x, s4["bitti"]])

	# 6) Kapı cebinin sol duvarı: F2 koridorundan zıplayarak cebe girilemez.
	var a2: Array = await _kaydet(_b2_betik_a())
	var duvar_betik := _betik([[172, 1, false], [158, 0, false]])
	for i in range(8):
		duvar_betik.append_array(_betik([[1, 1, true], [24, 1, false]]))
	var s5: Dictionary = await _senaryo([a2], duvar_betik, duvar_betik.size(), Callable(), _b2_ornekle)
	var f2_de: bool = s5["oyuncu_konum"].y > 340.0 and s5["oyuncu_konum"].y < 450.0
	var maks_x2 := -1.0e9
	for p in s5["oyuncu_iz"]:
		maks_x2 = max(maks_x2, p.x)
	_kaydi("Bölüm 2: F2 koridorundan cebe zıplayarak girilemez", f2_de and maks_x2 < 1040.0 and not s5["bitti"],
		"oyuncu F2'de: %s, en uzak x=%.0f (duvar x=1040, sınır 1026), bölüm bitti: %s" % [f2_de, maks_x2, s5["bitti"]])

	# 7) Şalter geri yürüyüş: S sağa çevrilip G açıldıktan sonra içinden sola dönersen S sola döner, G kapanır.
	var geri := _betik([[172, 1, false], [158, 0, false], [120, -1, false], [130, 0, false],
		[70, 1, false], [20, 0, false], [60, -1, false], [90, 0, false]])
	var s6: Dictionary = await _b2_cozum_oyna(geri, geri.size())
	var oz: Array = s6["ozel_iz"]
	var gecisler: Array = []
	var en_acik := 1.0e9
	for f in range(1, oz.size()):
		if oz[f]["salter"] != oz[f - 1]["salter"]:
			gecisler.append([f, oz[f]["salter"]])
		en_acik = min(en_acik, oz[f]["gecit_y"])
	var son: Dictionary = oz[oz.size() - 1]
	var gecti_geri: bool = gecisler.size() == 2 and gecisler[0][1] == true and gecisler[1][1] == false \
		and absf(en_acik - B2_GECIT_ACIK_Y) < 0.01 and absf(son["gecit_y"] - B2_GECIT_KAPALI_Y) < 0.01 \
		and not son["salter"]
	_kaydi("Bölüm 2: S'nin içinden sola dönünce S sola döner, G kapanır", gecti_geri,
		"çevirmeler (kare, sağda mı): %s, G en açık y=%.0f (açık %.0f), son G y=%.0f (kapalı %.0f), son S sağda: %s" % [
			str(gecisler), en_acik, B2_GECIT_ACIK_Y, son["gecit_y"], B2_GECIT_KAPALI_Y, son["salter"]])


# ---------------------------------------------------------------- bölüm seçimi ve sonraki bölüm

const MENU := "res://scenes/ana_menu.tscn"


func _sonraki_dugmesi(bolum: Node) -> Button:
	return bolum.find_child("SonrakiDugmesi", true, false)


func _test_bolum_secimi() -> void:
	# 1) Liste her iki bölümü içerir ve sahneler yüklenebilir.
	var yollar: Array = BolumListesi.yollar()
	var yuklenebilir := true
	for y in yollar:
		var sahne = load(y)
		if not (sahne is PackedScene and sahne.can_instantiate()):
			yuklenebilir = false
	var listede: bool = yollar.has(BOLUM) and yollar.has(BOLUM_2) and yollar.size() == BolumListesi.BOLUMLER.size() and yollar.size() >= 2
	_kaydi("Bölüm listesi", listede and yuklenebilir,
		"yollar: %s, hepsi yüklenebilir: %s" % [str(yollar), yuklenebilir])

	# 2) Bölüm 1 sonuç ekranında "Sonraki bölüm" görünür; basınca Bölüm 2, klon 0, tur 1.
	aktif_bolum = BOLUM
	var kayit: Array = await _kaydet(_dogru_kayit_betigi())
	var s: Dictionary = await _senaryo([kayit], _cozum_betigi(), COZUM_SINIR)
	var bolum1: Node = current_scene
	var dugme: Button = _sonraki_dugmesi(bolum1)
	var gorunur1: bool = s["bitti"] and dugme != null and dugme.visible
	_kaydi("Bölüm 1 sonuç ekranında \"Sonraki bölüm\" görünür", gorunur1,
		"bölüm bitti: %s, buton görünür: %s, metin: \"%s\"" % [s["bitti"], dugme != null and dugme.visible, dugme.text if dugme else ""])
	var kayitli_once: int = _kayitlar().turlar.size()
	var eski: Node = current_scene
	dugme.pressed.emit()
	var yeni: Node = await _sahne_degisimini_bekle(eski)
	var bolum2_mi: bool = yeni != null and yeni.scene_file_path == BOLUM_2
	var klon_sayisi: int = _klonlar(yeni).size() if yeni != null else -1
	var tur1: bool = yeni != null and yeni.bilgi.text.begins_with("Tur 1 ") and yeni.bilgi.text.contains("Klon: 0/")
	var bos: bool = _kayitlar().turlar.size() == 0
	_kaydi("\"Sonraki bölüm\": Bölüm 2, klon 0, tur 1", bolum2_mi and klon_sayisi == 0 and tur1 and bos and kayitli_once == 1 and not paused,
		"öncesinde kayıtlı klon: %d, yüklenen bölüm 2: %s, klon sayısı: %d, tur etiketi: \"%s\", Kayitlar boş: %s" % [
			kayitli_once, bolum2_mi, klon_sayisi, yeni.bilgi.text.get_slice("|", 0).strip_edges() if yeni != null else "", bos])

	# 3) Bölüm 2 sonuç ekranında "Sonraki bölüm": listede sonraki varsa görünür ve ona gider, yoksa gizli.
	aktif_bolum = BOLUM_2
	var s2: Dictionary = await _b2_cozum_oyna(_b2_betik_son())
	var dugme2: Button = _sonraki_dugmesi(current_scene)
	var sonraki2: String = BolumListesi.sonraki(BOLUM_2)
	var beklenen_gorunur: bool = sonraki2 != ""
	var gizli2: bool = s2["bitti"] and dugme2 != null and dugme2.visible == beklenen_gorunur
	_kaydi("Bölüm 2 sonuç ekranında \"Sonraki bölüm\" listeye göre", gizli2,
		"bölüm bitti: %s, buton var: %s, görünür: %s, beklenen görünür: %s" % [s2["bitti"], dugme2 != null, dugme2 != null and dugme2.visible, beklenen_gorunur])
	if beklenen_gorunur and dugme2 != null and dugme2.visible:
		var eski2: Node = current_scene
		dugme2.pressed.emit()
		var yeni2: Node = await _sahne_degisimini_bekle(eski2)
		var dogru2: bool = yeni2 != null and yeni2.scene_file_path == sonraki2 and _klonlar(yeni2).size() == 0
		_kaydi("Bölüm 2 \"Sonraki bölüm\" listedeki sonrakine gider", dogru2,
			"beklenen: %s, yüklenen: %s" % [sonraki2, yeni2.scene_file_path if yeni2 != null else ""])
	aktif_bolum = BOLUM
	paused = false

	# 4) Menü "Oyna" -> ilerleme haritası.
	_kayitlar().sifirla()
	var onceki: Node = current_scene
	change_scene_to_file(MENU)
	var menu: Node = await _sahne_degisimini_bekle(onceki)
	var onceki_menu: Node = current_scene
	menu.get_node("%OynaDugmesi").pressed.emit()
	var harita: Node = await _sahne_degisimini_bekle(onceki_menu)
	var harita_acildi: bool = harita != null and harita.scene_file_path.ends_with("harita.tscn")
	_kaydi("Menü \"Oyna\" ilerleme haritasını açar", harita_acildi, "harita açıldı: %s" % harita_acildi)

	# 5) Harita: her bölüm için düğüm, doğru bağlantı sayısı, odaksız butonlar, konumlar listeden.
	var kayitlar: Array = BolumListesi.BOLUMLER
	var dugumler: Array = harita.get_node("Dugumler").get_children().filter(func(c): return c is Button)
	var beklenen_baglanti := 0
	for k in kayitlar:
		if k["onceki"] != "":
			beklenen_baglanti += 1
	var alan := Vector2(root.content_scale_size)
	var konum_ok := dugumler.size() == kayitlar.size()
	var odak_ok := true
	var yazi_ok := true
	for i in range(min(dugumler.size(), kayitlar.size())):
		var merkez: Vector2 = dugumler[i].position + dugumler[i].size / 2.0
		if (merkez - kayitlar[i]["konum"]).length() > 0.01:
			konum_ok = false
		if not Rect2(Vector2.ZERO, alan).encloses(Rect2(dugumler[i].position, dugumler[i].size)):
			konum_ok = false
		if dugumler[i].focus_mode != Control.FOCUS_NONE:
			odak_ok = false
		if dugumler[i].text != str(i + 1):
			yazi_ok = false
	var geri: Button = harita.get_node("GeriDugmesi")
	var baglanti_ok: bool = harita.baglantilar.size() == beklenen_baglanti and beklenen_baglanti == kayitlar.size() - 1
	_kaydi("Harita ekranı", konum_ok and odak_ok and yazi_ok and baglanti_ok and geri.focus_mode == Control.FOCUS_NONE,
		"düğüm sayısı: %d (liste: %d), bağlantı: %d (beklenen %d), konumlar listeden ve ekran içinde: %s, numara yazıları: %s, focus_mode=NONE: %s" % [
			dugumler.size(), kayitlar.size(), harita.baglantilar.size(), beklenen_baglanti, konum_ok, yazi_ok, odak_ok])

	# 6) Düğüm butonu: temiz klon listesiyle doğru bölümü yükler (önce eski bir kayıt bırak).
	_kayitlar().tur_kaydet([])
	var once_harita: Node = current_scene
	harita.get_node("Dugumler/Dugum2").pressed.emit()
	var girilen: Node = await _sahne_degisimini_bekle(once_harita)
	var dogru: bool = girilen != null and girilen.scene_file_path == BOLUM_2
	var klon0: bool = girilen != null and _klonlar(girilen).size() == 0 and _kayitlar().turlar.size() == 0
	var tur_1: bool = girilen != null and girilen.bilgi.text.begins_with("Tur 1 ")
	_kaydi("Harita düğümü: doğru bölüm, klon 0, tur 1", dogru and klon0 and tur_1,
		"Bölüm 2 yüklendi: %s, klon sayısı 0 ve Kayitlar boş: %s, tur etiketi Tur 1: %s" % [dogru, klon0, tur_1])

	# 7) Geri butonu ana menüye döner.
	var menu_oncesi: Node = current_scene
	change_scene_to_file("res://scenes/harita.tscn")
	var harita2: Node = await _sahne_degisimini_bekle(menu_oncesi)
	var harita_oncesi: Node = current_scene
	harita2.get_node("GeriDugmesi").pressed.emit()
	var menuye: Node = await _sahne_degisimini_bekle(harita_oncesi)
	var menude: bool = menuye != null and menuye.scene_file_path.ends_with("ana_menu.tscn")
	_kaydi("Harita \"Geri\" ana menüye döner", menude, "ana menüde: %s" % menude)
	_kayitlar().sifirla()


## Harita bağlantı çizgisi: gerçek bir Line2D oluşur, uçları düğüm kenarında, arka plandan önde çizilir.
func _test_harita_cizgisi() -> void:
	var onceki: Node = current_scene
	change_scene_to_file("res://scenes/harita.tscn")
	var harita: Node = await _sahne_degisimini_bekle(onceki)
	var kayitlar: Array = BolumListesi.BOLUMLER
	var yaricap: float = harita.HEX_YARICAP
	var beklenen := 0
	var uclar_ok := true
	var ayrinti: Array = []
	for i in range(kayitlar.size()):
		if kayitlar[i]["onceki"] == "":
			continue
		beklenen += 1
		var a: Vector2 = kayitlar[BolumListesi.indeks(kayitlar[i]["onceki"])]["konum"]
		var b: Vector2 = kayitlar[i]["konum"]
		var yon := (b - a).normalized()
		for ad in ["Cizgi%d_Dis", "Cizgi%d_Ic"]:
			var cizgi: Line2D = harita.get_node_or_null("Baglantilar/" + ad % beklenen)
			if cizgi == null or cizgi.points.size() != 2:
				uclar_ok = false
				continue
			var bas: Vector2 = cizgi.points[0]
			var son: Vector2 = cizgi.points[1]
			# Uçlar iki düğümün merkezinden yarıçap kadar uzakta, doğru üzerinde.
			if absf(bas.distance_to(a) - yaricap) > 0.01 or absf(son.distance_to(b) - yaricap) > 0.01:
				uclar_ok = false
			if (bas - a).normalized().distance_to(yon) > 0.001 or (b - son).normalized().distance_to(yon) > 0.001:
				uclar_ok = false
			ayrinti.append("%s: (%.0f,%.0f)->(%.0f,%.0f), kalınlık %.0f" % [cizgi.name, bas.x, bas.y, son.x, son.y, cizgi.width])
	var cizgi_sayisi: int = harita.get_node("Baglantilar").get_child_count()
	# Çizim sırası: Arkaplan < Baglantilar < Dugumler (kardeş sırası = çizim sırası).
	var sira_ok: bool = harita.get_node("Arkaplan").get_index() < harita.get_node("Baglantilar").get_index() \
		and harita.get_node("Baglantilar").get_index() < harita.get_node("Dugumler").get_index()
	var katman_ok: bool = true
	for c in harita.get_node("Baglantilar").get_children():
		katman_ok = katman_ok and c.visible and c.z_index >= 0
	var iki_katman: bool = cizgi_sayisi == beklenen * 2
	_kaydi("Harita bağlantı çizgisi", beklenen == kayitlar.size() - 1 and uclar_ok and sira_ok and katman_ok and iki_katman,
		"bağlantı: %d, çizgi nesnesi: %d (koyu dış + açık iç), uçlar düğüm kenarında: %s, çizim sırası arka plan < çizgi < düğüm: %s, %s" % [
			beklenen, cizgi_sayisi, uclar_ok, sira_ok, "; ".join(ayrinti)])
	# Başlangıç düğümü farklı renkte.
	var d1: Node = harita.get_node("Dugumler/Dugum1")
	var d2: Node = harita.get_node("Dugumler/Dugum2")
	_kaydi("Harita başlangıç düğümü farklı renkte", d1.renk != d2.renk,
		"düğüm 1 renk: %s, düğüm 2 renk: %s" % [str(d1.renk), str(d2.renk)])


## Harita bağlantı çizgileri (liste geneli): komşu olmayan iki çizgi kesişmez; ortak düğümü paylaşan
## çizgiler üst üste binmez; hiçbir çizgi kendi uçları dışındaki bir düğümün altıgenine girmez.
## Çizgiler gerçek Line2D noktalarından okunur (Cizgi{n}_Ic).
func _segment_kesisir(p1: Vector2, p2: Vector2, p3: Vector2, p4: Vector2) -> bool:
	var d1 := (p2 - p1).cross(p3 - p1)
	var d2 := (p2 - p1).cross(p4 - p1)
	var d3 := (p4 - p3).cross(p1 - p3)
	var d4 := (p4 - p3).cross(p2 - p3)
	return d1 * d2 < 0.0 and d3 * d4 < 0.0


func _nokta_parca_uzakligi(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
	return p.distance_to(a + ab * t)


func _test_harita_kesisim() -> void:
	var onceki: Node = current_scene
	change_scene_to_file("res://scenes/harita.tscn")
	var harita: Node = await _sahne_degisimini_bekle(onceki)
	var kayitlar: Array = BolumListesi.BOLUMLER
	var yaricap: float = harita.HEX_YARICAP
	var parcalar: Array = []   # [bas, son, onceki_indeks, bu_indeks]
	var sayac := 0
	var eksik := false
	for i in range(kayitlar.size()):
		if kayitlar[i]["onceki"] == "":
			continue
		sayac += 1
		var cizgi: Line2D = harita.get_node_or_null("Baglantilar/Cizgi%d_Ic" % sayac)
		if cizgi == null or cizgi.points.size() != 2:
			eksik = true
			continue
		parcalar.append([cizgi.points[0], cizgi.points[1], BolumListesi.indeks(kayitlar[i]["onceki"]), i])
	var sorun: Array = []
	for i in range(parcalar.size()):
		for j in range(i + 1, parcalar.size()):
			var pi: Array = parcalar[i]
			var pj: Array = parcalar[j]
			var ortak: bool = pi[2] == pj[2] or pi[2] == pj[3] or pi[3] == pj[2] or pi[3] == pj[3]
			if _segment_kesisir(pi[0], pi[1], pj[0], pj[1]):
				sorun.append("çizgi %d x çizgi %d kesişiyor" % [i + 1, j + 1])
			elif ortak:
				# Ortak düğümden DIŞARI giden iki yön aynı doğrultudaysa (açı < 10 derece) çizgiler üst üste biner.
				var orta: int = pi[2] if (pi[2] == pj[2] or pi[2] == pj[3]) else pi[3]
				var mi: Vector2 = kayitlar[orta]["konum"]
				var uc_i: int = pi[3] if pi[2] == orta else pi[2]
				var uc_j: int = pj[3] if pj[2] == orta else pj[2]
				var yi: Vector2 = (kayitlar[uc_i]["konum"] - mi).normalized()
				var yj: Vector2 = (kayitlar[uc_j]["konum"] - mi).normalized()
				if yi.dot(yj) > 0.985:
					sorun.append("çizgi %d ve %d ortak düğümde üst üste biniyor" % [i + 1, j + 1])
		for k in range(kayitlar.size()):
			if k == parcalar[i][2] or k == parcalar[i][3]:
				continue
			var d: float = _nokta_parca_uzakligi(kayitlar[k]["konum"], parcalar[i][0], parcalar[i][1])
			if d < yaricap:
				sorun.append("çizgi %d, düğüm %d'ye giriyor (%.0f px < %.0f)" % [i + 1, k + 1, d, yaricap])
	_kaydi("Harita: bağlantı çizgileri birbirini ve başka düğümleri kesmez (liste geneli, %d kayıt)" % kayitlar.size(),
		not eksik and sorun.is_empty() and parcalar.size() == kayitlar.size() - 1,
		"çizgi: %d, eksik Line2D: %s, sorunlar: %s" % [parcalar.size(), eksik, str(sorun)])
	_kayitlar().sifirla()


# ---------------------------------------------------------------- bölüm listesi ve harita
# Not: bölüm sayısı BolumListesi.BOLUMLER.size()'dan türetilir (en az 8); yeni bölüm eklenince bu testler kırılmaz.

func _liste_yollari() -> Array:
	var yollar: Array = []
	for k in BolumListesi.BOLUMLER:
		yollar.append(k["yol"])
	return yollar


## Liste verisi: en az 8 kayıt, ilk 8 yol sıralı, dosyalar var/yüklenebilir/örneklenebilir,
## Kapi ve Oyuncu var, bağlantılar tutarlı, konumlar ekran içinde ve çakışmasız, sonraki zinciri.
func _test_bolum_listesi() -> void:
	var kayitlar: Array = BolumListesi.BOLUMLER
	var n: int = kayitlar.size()
	var yollar: Array = BolumListesi.yollar()
	var ilk8: bool = n >= 8
	for i in range(mini(n, 8)):
		ilk8 = ilk8 and yollar[i] == "res://scenes/bolumler/bolum_%d.tscn" % (i + 1)
	_kaydi("Bölüm listesi en az 8 kayıt, ilk 8 yol bolum_1..8 sıralı", ilk8 and yollar == _liste_yollari(),
		"kayıt: %d, yollar: %s" % [n, str(yollar)])

	var dosya_ok := true
	var dugum_ok := true
	var eksik: Array = []
	for y in yollar:
		if not ResourceLoader.exists(y):
			dosya_ok = false
			eksik.append(y + " (dosya yok)")
			continue
		var sahne = load(y)
		if not (sahne is PackedScene and sahne.can_instantiate()):
			dosya_ok = false
			eksik.append(y + " (yüklenemez)")
			continue
		var ornek: Node = sahne.instantiate()
		if ornek.get_node_or_null("Kapi") == null or ornek.get_node_or_null("Oyuncu") == null:
			dugum_ok = false
			eksik.append(y + " (Kapi/Oyuncu yok)")
		ornek.free()
	_kaydi("Listedeki %d bölüm sahnesi var, yüklenir, örneklenir" % n, dosya_ok, "sorunlar: %s" % str(eksik))
	_kaydi("Her bölümde Kapi ve Oyuncu düğümü var", dugum_ok, "sorunlar: %s" % str(eksik))

	# Bağlantılar ve konumlar
	var alan := Rect2(Vector2.ZERO, Vector2(1152, 648))
	var onceki_ok := true
	var konum_ok := true
	var sorun: Array = []
	for i in range(n):
		var onceki: String = kayitlar[i]["onceki"]
		if i == 0:
			if onceki != "":
				onceki_ok = false
				sorun.append("1. kayıt onceki boş değil")
		elif not yollar.has(onceki):
			onceki_ok = false
			sorun.append("kayıt %d onceki listede yok" % (i + 1))
		if not alan.has_point(kayitlar[i]["konum"]):
			konum_ok = false
			sorun.append("kayıt %d ekran dışı" % (i + 1))
		for j in range(i + 1, n):
			var d: float = (kayitlar[i]["konum"] - kayitlar[j]["konum"]).length()
			if d < 2.0 * 34.0:
				konum_ok = false
				sorun.append("kayıt %d-%d çakışıyor (%.0f px)" % [i + 1, j + 1, d])
	_kaydi("Bağlantılar: her onceki listede, bölüm 1 boş", onceki_ok, "sorunlar: %s" % str(sorun))
	_kaydi("Düğüm konumları 1152x648 içinde ve çakışmasız (>= 68 px)", konum_ok, "sorunlar: %s" % str(sorun))

	# Sonraki zinciri: listenin sonuna kadar, son bölümden sonra boş.
	var zincir_ok := true
	for i in range(n - 1):
		if BolumListesi.sonraki(yollar[i]) != yollar[i + 1]:
			zincir_ok = false
	var son_bos: bool = BolumListesi.sonraki(yollar[n - 1]) == ""
	_kaydi("Sonraki bölüm zinciri 1->%d, son bölümden sonra boş" % n, zincir_ok and son_bos,
		"zincir doğru: %s, son bölümden sonra boş: %s" % [zincir_ok, son_bos])


## Harita ekranı: liste kadar düğüm, her düğüm gerçek pressed yoluyla ilgili bölümü temiz yükler.
func _test_harita_dugumleri() -> void:
	var onceki: Node = current_scene
	change_scene_to_file("res://scenes/harita.tscn")
	var harita: Node = await _sahne_degisimini_bekle(onceki)
	var yollar: Array = _liste_yollari()
	var n: int = yollar.size()
	var dugumler: Array = harita.get_node("Dugumler").get_children().filter(func(c): return c is Button)
	_kaydi("Harita liste kadar (%d) düğüm oluşturur" % n, harita != null and dugumler.size() == n, "düğüm: %d, liste: %d" % [dugumler.size(), n])

	for i in range(n):
		var yol: String = yollar[i]
		# Önceki kayıt bırak: düğüm temizlemek zorunda.
		_kayitlar().tur_kaydet([])
		var harita_node: Node = current_scene
		var dugme: Button = harita_node.get_node_or_null("Dugumler/Dugum%d" % (i + 1))
		if dugme == null:
			_kaydi("Harita düğümü %d bölümü yükler" % (i + 1), false, "düğüm yok")
			continue
		dugme.pressed.emit()
		var bolum: Node = await _sahne_degisimini_bekle(harita_node)
		var yol_ok: bool = bolum != null and bolum.scene_file_path == yol
		var klon0: bool = bolum != null and _klonlar(bolum).size() == 0 and _kayitlar().turlar.size() == 0
		var oyuncu: bool = bolum != null and bolum.get_node_or_null("Oyuncu") != null
		var mk: int = bolum.max_klon if bolum != null else -1
		var tur1: bool = bolum != null and bolum.bilgi.text.begins_with("Tur 1 ")
		_kaydi("Harita düğümü %d: bölüm %d, klon 0, Tur 1, max_klon 1..3" % [i + 1, i + 1],
			yol_ok and klon0 and oyuncu and mk >= 1 and mk <= 3 and tur1,
			"yol doğru: %s, klon 0 ve Kayitlar boş: %s, oyuncu: %s, max_klon: %d, Tur 1: %s" % [yol_ok, klon0, oyuncu, mk, tur1])
		# Haritaya dön
		var bolum_node: Node = current_scene
		change_scene_to_file("res://scenes/harita.tscn")
		await _sahne_degisimini_bekle(bolum_node)
	_kayitlar().sifirla()


# ---------------------------------------------------------------- lazer ve tek yönlü platform
#
# Test sahnesi (tests/sahneler/lazer_test.tscn), zemin yüzeyi y=600, oyuncu x=200'de doğar:
#   Salter x=270, Plaka x=350, TekYonlu (120x12) x=450 y=536, Asansor x=620 (Plaka'ya bağlı),
#   Lazer x=700 dikey (yukarı, 120 px; y 500..620), tetikleyicisiz, Kapı x=1000.
# Sağa yürüyen karakter 5 px/kare gider: x=700'e ~97. karede ulaşır.

const LAZER_TEST := "res://tests/sahneler/lazer_test.tscn"
const LAZER_X := 700.0


## Sahne değişimini örnek kimliğiyle bekler (eski düğüm silinmiş olabilir, kimlik güvenlidir).
func _yeni_sahne_bekle(eski_id: int) -> Node:
	for i in range(40):
		if current_scene != null and current_scene.get_instance_id() != eski_id and current_scene.is_node_ready():
			return current_scene
		await physics_frame
	return null


## _tur_oyna'nın ölüme dayanıklı sürümü: oyuncu ölünce bölüm yeniden yüklenir, o yüzden
## oyuncu.kare'ye bakmaz; kendi kare sayacını kullanır ve bölüm bitince/silinince çıkar.
func _lazer_oyna(bolum: Node, betik: Array, bitis_kare: int, izleyici := Callable()) -> Dictionary:
	var oyuncu: CharacterBody2D = bolum.get_node("Oyuncu")
	var klonlar: Array = _klonlar(bolum)
	var klon_iz: Array = []
	for k in klonlar:
		klon_iz.append([])
	var oyuncu_iz: Array = []
	var ozel: Array = []
	var kare := 0
	while kare < bitis_kare:
		if not is_instance_valid(bolum) or bolum.bitti:
			break
		_girdi_uygula(betik[kare] if kare < betik.size() else {"yon": 0.0, "zipla": false})
		for i in range(klonlar.size()):
			klon_iz[i].append(klonlar[i].global_position)
		oyuncu_iz.append(oyuncu.global_position)
		if izleyici.is_valid():
			ozel.append(izleyici.call(bolum))
		await physics_frame
		kare += 1
	_girdi_uygula({"yon": 0.0, "zipla": false})
	return {"kare": kare, "tamamlandi": kare >= bitis_kare, "klon_izleri": klon_iz,
		"oyuncu_iz": oyuncu_iz, "ozel_iz": ozel}


## Kayıtları klon olarak yükler, oyuncuya betik uygular. Oyuncu ölürse yeniden yüklenen
## sahneyi bekler ve "yeni_sahne" olarak döndürür. "oyuncu_oldu": sinyal sayısı.
func _lazer_senaryo(kayitlar: Array, betik: Array, bitis: int, hazirlik := Callable(), izleyici := Callable()) -> Dictionary:
	_kayitlar().sifirla()
	for k in kayitlar:
		_kayitlar().tur_kaydet(k.duplicate(true))
	var bolum: Node = await _bolumu_yukle()
	var sayac := [0]
	bolum.get_node("Oyuncu").oyuncu_oldu.connect(func() -> void: sayac[0] += 1)
	var eski_id := bolum.get_instance_id()
	if hazirlik.is_valid():
		hazirlik.call(bolum)
	var s: Dictionary = await _lazer_oyna(bolum, betik, bitis, izleyici)
	s["oyuncu_oldu"] = sayac[0]
	s["yeni_sahne"] = null
	if sayac[0] > 0:
		s["yeni_sahne"] = await _yeni_sahne_bekle(eski_id)
	return s


## Lazeri tetikleyicilere bağlar (Plaka, Salter adlarıyla) ve istenirse taşır.
func _lazer_ayari(tetik: Array, kapali := true, sag := true, konum := Vector2.ZERO) -> Callable:
	return func(b: Node) -> void:
		var l: Node = b.get_node("Lazer")
		var dugumler: Array = []
		for ad in tetik:
			dugumler.append(b.get_node(ad))
		l.tetik_aktifken_kapali = kapali
		l.acik_taraf_sag = sag
		l.tetikleyicileri_ayarla(dugumler)
		if konum != Vector2.ZERO:
			l.position = konum


func _lazer_ornekle(b: Node) -> Dictionary:
	var l: Node = b.get_node("Lazer")
	return {
		"acik": l.acik_mi(),
		"gorunur": l.get_node("IsinGorsel").visible,
		"izleme": l.monitoring,
		"plaka": b.get_node("Plaka").basili_mi(),
		"salter": b.get_node("Salter").sagda,
		"asansor_y": b.get_node("Asansor").position.y,
	}


## Girdi yön ve zıplama betiği için kısaltma: sağa n kare.
func _saga(n: int) -> Array:
	return _betik([[n, 1, false]])


## 1) Lazer canlı oyuncuyu öldürür; tur yeniden başlar, kayıtlar ve tur sayısı değişmez.
func _test_lazer_oyuncu_olur() -> void:
	var onceki_klon: Array = _betik([[40, 1, false], [20, 0, false]])
	var s: Dictionary = await _lazer_senaryo([onceki_klon], _saga(200), 200, Callable(), _lazer_ornekle)
	var yeni: Node = s["yeni_sahne"]
	var turlar: Array = _kayitlar().turlar
	var oyuncu_x: float = s["oyuncu_iz"][s["oyuncu_iz"].size() - 1].x
	var oldu_ok: bool = s["oyuncu_oldu"] == 1 and not s["tamamlandi"] and s["kare"] > 80 and s["kare"] < 115
	var konum_ok: bool = oyuncu_x > LAZER_X - 40.0 and oyuncu_x < LAZER_X
	var yeniden_ok := false
	var tur_ok := false
	var kare_ok := false
	if yeni != null:
		var yo: Node = yeni.get_node("Oyuncu")
		yeniden_ok = yeni.scene_file_path == LAZER_TEST and _klonlar(yeni).size() == 1 and not yo.oldu
		tur_ok = turlar.size() == 1 and turlar[0] == onceki_klon \
			and yeni.bilgi.text.begins_with("Tur 2 ") and yeni.bilgi.text.contains("Klon: 1/")
		kare_ok = yo.kare <= 3 and yo.kayit_girdileri.size() <= 3
	_kaydi("Lazer 1a) Canlı oyuncu ölür, tur yeniden başlar (kayıt korunur)",
		oldu_ok and konum_ok and yeniden_ok and tur_ok and kare_ok,
		"ölüm sinyali: %d (beklenen 1), ölüm karesi ~%d, son x=%.0f (ışın x=%.0f), yeni sahne: %s, klon: %d, kayıtlı tur: %d (beklenen 1, aynı içerik: %s), etiket: \"%s\", yeni oyuncu kare<=3: %s" % [
			s["oyuncu_oldu"], s["kare"], oyuncu_x, LAZER_X, yeni != null, _klonlar(yeni).size() if yeni != null else -1,
			turlar.size(), tur_ok, yeni.bilgi.text if yeni != null else "-", kare_ok])

	# Klonsuz: ölüm yeni klon kaydetmez, Tur 1 kalır.
	var s2: Dictionary = await _lazer_senaryo([], _saga(200), 200)
	var yeni2: Node = s2["yeni_sahne"]
	var bos_ok: bool = s2["oyuncu_oldu"] == 1 and yeni2 != null and _kayitlar().turlar.size() == 0 \
		and _klonlar(yeni2).size() == 0 and yeni2.bilgi.text.begins_with("Tur 1 ")
	_kaydi("Lazer 1b) Klonsuz ölüm: kayıt eklenmez, Tur 1 kalır", bos_ok,
		"ölüm sinyali: %d, kayıtlı tur: %d (beklenen 0), etiket: \"%s\"" % [
			s2["oyuncu_oldu"], _kayitlar().turlar.size(), yeni2.bilgi.text if yeni2 != null else "-"])
	# Tekrarlanan ölümler tur sayısını artırmaz (yeniden yüklenen sahnede tekrar öl).
	var s3: Dictionary = {}
	if yeni2 != null:
		var sayac := [0]
		yeni2.get_node("Oyuncu").oyuncu_oldu.connect(func() -> void: sayac[0] += 1)
		var eski_id := yeni2.get_instance_id()
		var bitti: Dictionary = await _lazer_oyna(yeni2, _saga(200), 200)
		var yeni3: Node = await _yeni_sahne_bekle(eski_id)
		s3 = {"sayac": sayac[0], "sahne": yeni3, "kare": bitti["kare"]}
	var tekrar_ok: bool = not s3.is_empty() and s3["sayac"] == 1 and s3["sahne"] != null \
		and _kayitlar().turlar.size() == 0 and s3["sahne"].bilgi.text.begins_with("Tur 1 ")
	_kaydi("Lazer 1c) Art arda ölümde tur sayısı artmaz", tekrar_ok,
		"ikinci ölüm sinyali: %s, kayıtlı tur: %d, etiket: \"%s\"" % [
			str(s3.get("sayac", -1)), _kayitlar().turlar.size(), s3["sahne"].bilgi.text if s3.get("sahne") != null else "-"])
	_kayitlar().sifirla()


## İlk kare indeksinden sonra, verilen koşulun en az n art arda karede sürdüğü kareleri döndürür.
func _kararli(iz: Array, anahtar: String, deger: bool, n := 4) -> int:
	var seri := 0
	for f in range(iz.size()):
		if iz[f][anahtar] == deger:
			seri += 1
			if seri >= n:
				return f
		else:
			seri = 0
	return -1


## 2) Tetikleyiciler: plaka/şalter lazeri kapatır; tetik_aktifken_kapali=false açar; tetikleyicisiz hep açık.
func _test_lazer_tetikleyici() -> void:
	# a) Tetikleyicisiz: plaka basılsa da lazer hep açık, ışık görünür, izleme açık.
	var klon_plakada: Array = _betik([[30, 1, false], [200, 0, false]])
	var sa: Dictionary = await _lazer_senaryo([klon_plakada], [], 120, Callable(), _lazer_ornekle)
	var hep_acik: bool = sa["ozel_iz"].size() >= 100
	var plaka_basildi := false
	for o in sa["ozel_iz"]:
		hep_acik = hep_acik and o["acik"]
		if o["plaka"]:
			plaka_basildi = true
	var son_a: Dictionary = sa["ozel_iz"][sa["ozel_iz"].size() - 1]
	hep_acik = hep_acik and son_a["gorunur"] and son_a["izleme"]
	_kaydi("Lazer 2a) Tetikleyicisiz lazer hep açık", hep_acik and plaka_basildi,
		"%d kare, hep açık: %s, plaka basıldı (anlamlı test): %s, görünür: %s, izleme: %s" % [
			sa["ozel_iz"].size(), hep_acik, plaka_basildi, son_a["gorunur"], son_a["izleme"]])

	# b) Plaka (tetik_aktifken_kapali=true): klon plakadayken lazer kapalı, oyuncu ışından sağ çıkar.
	var ayar_b := _lazer_ayari(["Plaka"], true)
	var sb: Dictionary = await _lazer_senaryo([klon_plakada], _saga(130), 130, ayar_b, _lazer_ornekle)
	var izb: Array = sb["ozel_iz"]
	var basta_acik: bool = izb.size() > 5 and izb[3]["acik"] and not izb[3]["plaka"]
	var kapali_kare := _kararli(izb, "plaka", true)
	var kapali_ok := kapali_kare >= 0
	var hepsi_kapali := true
	if kapali_ok:
		for f in range(kapali_kare, izb.size()):
			if izb[f]["plaka"] and (izb[f]["acik"] or izb[f]["gorunur"] or izb[f]["izleme"]):
				hepsi_kapali = false
	var xb: float = sb["oyuncu_iz"][sb["oyuncu_iz"].size() - 1].x
	var hayatta: bool = sb["tamamlandi"] and sb["oyuncu_oldu"] == 0 and xb > LAZER_X + 80.0
	_kaydi("Lazer 2b) Plaka lazeri kapatır (klon plakadayken oyuncu geçer)",
		basta_acik and kapali_ok and hepsi_kapali and hayatta,
		"başta açık: %s, plaka basılıyken kapalı+gizli+izleme kapalı: %s (kare %d'den), oyuncu hayatta: %s, son x=%.0f (ışın %.0f)" % [
			basta_acik, hepsi_kapali, kapali_kare, hayatta, xb, LAZER_X])

	# b2) Klon yok: plaka bırakılınca lazer yeniden açılır ve oyuncuyu öldürür.
	var sb2: Dictionary = await _lazer_senaryo([], _saga(130), 130, ayar_b, _lazer_ornekle)
	var olum_b2: bool = sb2["oyuncu_oldu"] == 1 and not sb2["tamamlandi"]
	_kaydi("Lazer 2b2) Plaka bırakılınca lazer tekrar ölümcül", olum_b2,
		"oyuncu ölüm sinyali: %d (beklenen 1), ölüm karesi ~%d" % [sb2["oyuncu_oldu"], sb2["kare"]])

	# c) tetik_aktifken_kapali=false: yalnız plaka basılıyken açık.
	var ayar_c := _lazer_ayari(["Plaka"], false)
	var sc: Dictionary = await _lazer_senaryo([], _saga(130), 130, ayar_c, _lazer_ornekle)
	var izc: Array = sc["ozel_iz"]
	var basta_kapali: bool = izc.size() > 8 and not izc[5]["acik"] and not izc[5]["plaka"]
	var plakada_acik := false
	for f in range(izc.size()):
		if izc[f]["plaka"] and f > 0 and izc[f - 1]["plaka"] and izc[f]["acik"]:
			plakada_acik = true
	var xc: float = sc["oyuncu_iz"][sc["oyuncu_iz"].size() - 1].x
	var gecti_c: bool = sc["tamamlandi"] and sc["oyuncu_oldu"] == 0 and xc > LAZER_X + 80.0
	_kaydi("Lazer 2c) tetik_aktifken_kapali=false: plakasızken kapalı, plakadayken açık", basta_kapali and plakada_acik and gecti_c,
		"başta kapalı: %s, plakadayken açık görüldü: %s, plaka bırakılmış oyuncu ışından sağ çıktı: %s (son x=%.0f)" % [
			basta_kapali, plakada_acik, gecti_c, xc])
	# c2) Klon plakada: lazer açık, oyuncu ölür.
	var sc2: Dictionary = await _lazer_senaryo([klon_plakada], _saga(130), 130, ayar_c, _lazer_ornekle)
	_kaydi("Lazer 2c2) tetik_aktifken_kapali=false: klon plakadayken lazer öldürür",
		sc2["oyuncu_oldu"] == 1 and not sc2["tamamlandi"],
		"oyuncu ölüm sinyali: %d (beklenen 1), ölüm karesi ~%d" % [sc2["oyuncu_oldu"], sc2["kare"]])

	# d) Şalter: sağ konumda lazer kapanır (acik_taraf_sag=true); aksi taraf için tersi.
	var sd: Dictionary = await _lazer_senaryo([], _saga(130), 130, _lazer_ayari(["Salter"], true, true), _lazer_ornekle)
	var izd: Array = sd["ozel_iz"]
	var d_basta_acik: bool = izd.size() > 5 and izd[1]["acik"] and not izd[1]["salter"]
	var d_sonra_kapali := false
	for f in range(izd.size()):
		if izd[f]["salter"] and izd[f]["acik"] == false and f > 0 and izd[f - 1]["salter"]:
			d_sonra_kapali = true
	var xd: float = sd["oyuncu_iz"][sd["oyuncu_iz"].size() - 1].x
	var d_gecti: bool = sd["tamamlandi"] and sd["oyuncu_oldu"] == 0 and xd > LAZER_X + 80.0
	_kaydi("Lazer 2d) Şalter sağdayken lazer kapanır (acik_taraf_sag=true)", d_basta_acik and d_sonra_kapali and d_gecti,
		"başta açık (şalter solda): %s, şalter sağa itilince kapandı: %s, oyuncu ışından geçti: %s (son x=%.0f)" % [
			d_basta_acik, d_sonra_kapali, d_gecti, xd])
	var sd2: Dictionary = await _lazer_senaryo([], _saga(130), 130, _lazer_ayari(["Salter"], true, false), _lazer_ornekle)
	var izd2: Array = sd2["ozel_iz"]
	var d2_basta_kapali: bool = izd2.size() > 5 and not izd2[1]["acik"] and not izd2[1]["salter"]
	_kaydi("Lazer 2d2) acik_taraf_sag=false: şalter sağa itilince lazer açılıp öldürür",
		d2_basta_kapali and sd2["oyuncu_oldu"] == 1 and not sd2["tamamlandi"],
		"başta (şalter solda) kapalı: %s, ölüm sinyali: %d (beklenen 1)" % [d2_basta_kapali, sd2["oyuncu_oldu"]])


## 3) Klon ışına değince ölür: yerinde kalır, plakayı basılı tutmaz, asansörü durdurmaz, deterministik.
func _test_lazer_klon() -> void:
	var yuru: Array = _betik([[200, 1, false]])
	# a) Ölüm, yerinde donma, katmanlar, iki koşuda aynı oldu_kare.
	var ornek := func(b: Node) -> Dictionary:
		var k: Node = _klonlar(b)[0]
		return {"oldu": k.oldu, "oldu_kare": k.oldu_kare, "x": k.global_position.x,
			"katman": k.collision_layer, "maske": k.collision_mask}
	var s1: Dictionary = await _lazer_senaryo([yuru], [], 160, Callable(), ornek)
	var s2: Dictionary = await _lazer_senaryo([yuru], [], 160, Callable(), ornek)
	var son1: Dictionary = s1["ozel_iz"][s1["ozel_iz"].size() - 1]
	var son2: Dictionary = s2["ozel_iz"][s2["ozel_iz"].size() - 1]
	var iz: Array = s1["klon_izleri"][0]
	var ok_k: bool = son1["oldu"] and son1["oldu_kare"] > 80 and son1["oldu_kare"] < 115
	var ayni_kare: bool = son1["oldu_kare"] == son2["oldu_kare"] and son1["x"] == son2["x"]
	var yerinde := true
	for f in range(son1["oldu_kare"] + 3, iz.size()):
		if (iz[f] - iz[iz.size() - 1]).length() > 0.0:
			yerinde = false
	var x_ok: bool = son1["x"] > LAZER_X - 40.0 and son1["x"] < LAZER_X
	var katman_ok: bool = son1["katman"] == 0 and son1["maske"] == 0
	var oyuncu_saglam: bool = s1["tamamlandi"] and s1["oyuncu_oldu"] == 0
	_kaydi("Lazer 3a) Klon ışına değince ölür, yerinde kalır, oldu_kare deterministik",
		ok_k and ayni_kare and yerinde and x_ok and katman_ok and oyuncu_saglam,
		"oldu_kare: %d ve %d (aynı: %s), son x=%.1f, ışın x=%.0f, yerinde donmuş: %s, katman/maske=%d/%d (beklenen 0/0), oyuncu etkilenmedi: %s" % [
			son1["oldu_kare"], son2["oldu_kare"], ayni_kare, son1["x"], LAZER_X, yerinde, son1["katman"], son1["maske"], oyuncu_saglam])

	# b) Plakanın üstünde ölen klon plakayı basılı tutmaz. Lazer plakanın üstüne taşınır.
	var plaka_ustu := _lazer_ayari([], true, true, Vector2(350.0, 620.0))
	var ornek_b := func(b: Node) -> Dictionary:
		var k: Node = _klonlar(b)[0]
		return {"oldu": k.oldu, "x": k.global_position.x, "plaka": b.get_node("Plaka").basili_mi()}
	var sb: Dictionary = await _lazer_senaryo([yuru], [], 100, plaka_ustu, ornek_b)
	var izb: Array = sb["ozel_iz"]
	var basildi := false
	var olum_f := -1
	for f in range(izb.size()):
		if izb[f]["plaka"] and not izb[f]["oldu"]:
			basildi = true
		if izb[f]["oldu"] and olum_f < 0:
			olum_f = f
	var sonra_bos := olum_f >= 0
	for f in range(maxi(olum_f, 0) + 4, izb.size()):
		if izb[f]["plaka"]:
			sonra_bos = false
	var son_x: float = izb[izb.size() - 1]["x"]
	var plaka_ustunde: bool = absf(son_x - 350.0) < 44.0   # hâlâ plakanın alanı içinde
	_kaydi("Lazer 3b) Ölen klon plakayı basılı tutmaz", basildi and sonra_bos and plaka_ustunde,
		"ölmeden önce plaka basıldı: %s, ölüm karesi: %d, ölümden sonra plaka boş: %s, klon x=%.0f (plaka x=350, hâlâ üstünde: %s)" % [
			basildi, olum_f, sonra_bos, son_x, plaka_ustunde])

	# c) Ölü klon asansörü durdurmaz. Klon 1 plakada durup çekilir (asansör iner), klon 2 asansörün
	# altında ışında ölür. Kontrol: ışın yoksa klon 2 canlı kalır ve asansörü durdurur.
	var k1: Array = _betik([[30, 1, false], [100, 0, false], [40, -1, false], [200, 0, false]])
	var k2: Array = _betik([[81, 1, false], [400, 0, false]])
	var asansor_ornek := func(b: Node) -> Dictionary:
		var k: Node = _klonlar(b)[1]
		return {"asansor_y": b.get_node("Asansor").position.y, "oldu": k.oldu, "x": k.global_position.x,
			"plaka": b.get_node("Plaka").basili_mi()}
	var hazir_olu := func(b: Node) -> void:
		b.get_node("Lazer").position = Vector2(620.0, 620.0)
	var hazir_kontrol := func(b: Node) -> void:
		b.get_node("Lazer").position = Vector2(-400.0, 620.0)
	var sc: Dictionary = await _lazer_senaryo([k1, k2], [], 320, hazir_olu, asansor_ornek)
	var sk: Dictionary = await _lazer_senaryo([k1, k2], [], 320, hazir_kontrol, asansor_ornek)
	var izc: Array = sc["ozel_iz"]
	var izk: Array = sk["ozel_iz"]
	var en_yuksek := 1.0e9
	for o in izc:
		en_yuksek = minf(en_yuksek, o["asansor_y"])
	var son_c: Dictionary = izc[izc.size() - 1]
	var son_k: Dictionary = izk[izk.size() - 1]
	var iner: bool = absf(son_c["asansor_y"] - 610.0) < 0.01 and en_yuksek < 450.0
	var olu: bool = son_c["oldu"] and son_c["x"] > 560.0 and son_c["x"] < 680.0
	var kontrol_takili: bool = (not son_k["oldu"]) and son_k["asansor_y"] < 590.0 and son_k["x"] > 560.0 and son_k["x"] < 680.0
	_kaydi("Lazer 3c) Ölü klon asansörü durdurmaz", iner and olu and kontrol_takili,
		"asansör en yüksek y=%.0f, sonunda y=%.0f (alt=610, beklenen iner: %s), klon 2 ölü ve asansörün altında: %s (x=%.0f); kontrol (ışın yok): klon 2 canlı, asansör takıldı y=%.0f: %s" % [
			en_yuksek, son_c["asansor_y"], iner, olu, son_c["x"], son_k["asansor_y"], kontrol_takili])


## 4) Tek yönlü platform: aşağıdan zıplayınca geçilir, üstünde durulur.
func _test_tek_yonlu() -> void:
	# x=450'de zıpla (platformun tam altında), başka girdi yok.
	var betik := _betik([[50, 1, false], [1, 0, true], [140, 0, false]])
	var s: Dictionary = await _lazer_senaryo([], betik, betik.size())
	var iz: Array = s["oyuncu_iz"]
	var platform_ust := 536.0 - 6.0
	var durus_y := platform_ust - 24.0   # karakter merkezi platformun üstünde
	var baslangic_y: float = iz[49].y
	var min_y := 1.0e9
	var maks_x := -1.0e9
	var min_x := 1.0e9
	for f in range(50, iz.size()):
		min_y = minf(min_y, iz[f].y)
		maks_x = maxf(maks_x, iz[f].x)
		min_x = minf(min_x, iz[f].x)
	var son: Vector2 = iz[iz.size() - 1]
	var kararli := true
	for f in range(iz.size() - 30, iz.size()):
		if absf(iz[f].y - son.y) > 0.5:
			kararli = false
	var asagidan_basladi: bool = baslangic_y > platform_ust + 12.0 + 24.0 - 1.0   # tüm gövde platformun altında
	var gecti_yukari: bool = min_y < durus_y - 5.0 or absf(min_y - durus_y) < 1.5
	var ustunde: bool = absf(son.y - durus_y) < 1.5 and kararli
	var yatay_ok: bool = maks_x - min_x < 2.0
	_kaydi("Tek yönlü platform: aşağıdan geçilir, üstünde durulur",
		asagidan_basladi and gecti_yukari and ustunde and yatay_ok and s["tamamlandi"],
		"başlangıç y=%.0f (zemin 576, platform alt kenarı 542), en yüksek y=%.1f, son y=%.1f (platform üstü %.0f, beklenen merkez %.0f), son 30 karede kararlı: %s, yatay sapma: %.1f px" % [
			baslangic_y, min_y, son.y, platform_ust, durus_y, kararli, maks_x - min_x])

	# Kontrol: platformun yanından zıplayınca üstüne çıkılamaz, yani platform gerçekten orada.
	# Platformun altındayken yukarı hareket takılmamıştır (tepe y platformun üstünde): zaten üstte.
	# Ayrıca üstünden aşağı inen karakter geçmeden durur: platformdan sağa yürüyerek düş, tekrar yukarı çık.
	var betik2 := _betik([[50, 1, false], [1, 0, true], [60, 0, false], [30, 1, false], [60, 0, false]])
	var s2: Dictionary = await _lazer_senaryo([], betik2, betik2.size())
	var iz2: Array = s2["oyuncu_iz"]
	# Platformdan (x 390..510) sağa yürüyen karakter kenardan düşer ve zemine iner.
	var yerde: bool = absf(iz2[iz2.size() - 1].y - 576.0) < 1.5
	var platformdaydi: bool = absf(iz2[110].y - durus_y) < 1.5
	_kaydi("Tek yönlü platform: üstünden yürüyüp zemine inilir", yerde and platformdaydi and s2["tamamlandi"],
		"kare 110'da platform üstünde: %s (y=%.1f), sonunda zeminde: %s (y=%.1f)" % [
			platformdaydi, iz2[110].y, yerde, iz2[iz2.size() - 1].y])


## 5) Determinizm: lazer + plaka + asansör senaryosu 100 kez, her karede aynı.
func _test_lazer_determinizm() -> void:
	var a: Array = _betik([[30, 1, false], [400, 0, false]])   # plakada durur, asansör çıkar
	var b: Array = _betik([[200, 1, false]])                   # ışında ölür
	var ornek := func(bb: Node) -> Dictionary:
		var kl: Array = _klonlar(bb)
		return {"b_oldu": kl[1].oldu, "b_oldu_kare": kl[1].oldu_kare, "plaka": bb.get_node("Plaka").basili_mi(),
			"asansor_y": bb.get_node("Asansor").position.y, "acik": bb.get_node("Lazer").acik_mi()}
	var referans: Dictionary = {}
	var sapmali := 0
	var maks_sapma := 0.0
	for n in range(TEKRAR):
		var s: Dictionary = await _lazer_senaryo([a, b], [], 220, Callable(), ornek)
		if n == 0:
			referans = s
			continue
		var bu: bool = s["ozel_iz"].size() != referans["ozel_iz"].size()
		for f in range(mini(s["ozel_iz"].size(), referans["ozel_iz"].size())):
			if s["ozel_iz"][f] != referans["ozel_iz"][f]:
				bu = true
			for ki in range(2):
				var d: float = (s["klon_izleri"][ki][f] - referans["klon_izleri"][ki][f]).length()
				if d > 0.0:
					bu = true
					maks_sapma = maxf(maks_sapma, d)
		if bu:
			sapmali += 1
	var ref_son: Dictionary = referans["ozel_iz"][referans["ozel_iz"].size() - 1]
	var min_asansor := 1.0e9
	for o in referans["ozel_iz"]:
		min_asansor = minf(min_asansor, o["asansor_y"])
	var anlamli: bool = ref_son["b_oldu"] and ref_son["b_oldu_kare"] > 0 and min_asansor < 500.0
	_kaydi("Lazer 5) Determinizm (100x lazer + plaka + asansör)", sapmali == 0 and anlamli,
		"%d çalıştırma x %d kare, sapmalı çalıştırma: %d, en büyük konum sapması: %.4f px, klon B ölüm karesi: %d, asansör en yüksek y=%.0f (anlamlı senaryo: %s)" % [
			TEKRAR, referans["ozel_iz"].size(), sapmali, maks_sapma, ref_son["b_oldu_kare"], min_asansor, anlamli])


# ---------------------------------------------------------------- Bölüm 3 testleri
#
# Taslak: docs/devir/bolum_3_taslak.md. Tek koridor (y 400..600), L1 x=480 (P1 x=260 kapatır),
# L2 x=860 (P2 x=640 kapatır), kapı x=1060, max_klon=2. Çözüm: A P1'i, B P2'yi tutar.

const BOLUM_3 := "res://scenes/bolumler/bolum_3.tscn"


func _b3_betik_a() -> Array:
	return _betik([[32, 1, false], [28, 0, false]])


func _b3_betik_b() -> Array:
	return _betik([[108, 1, false], [30, 0, false]])


func _b3_ornekle(b: Node) -> Dictionary:
	return {
		"l1": b.get_node("Lazer1").acik_mi(),
		"l2": b.get_node("Lazer2").acik_mi(),
		"p1": b.get_node("Plaka1").basili_mi(),
		"p2": b.get_node("Plaka2").basili_mi(),
	}


## Önceki klonlarla bölümü yükler, betiği oynatır, oyuncunun kayıt girdisini döndürür.
## Oyuncu ölürse boş dizi döner (kayıt atılır).
func _b3_kaydet(onceki: Array, betik: Array) -> Array:
	_kayitlar().sifirla()
	for k in onceki:
		_kayitlar().tur_kaydet(k.duplicate(true))
	var bolum: Node = await _bolumu_yukle()
	var oyuncu: CharacterBody2D = bolum.get_node("Oyuncu")
	await _lazer_oyna(bolum, betik, betik.size())
	if not is_instance_valid(oyuncu) or oyuncu.oldu:
		return []
	return oyuncu.kayit_girdileri.duplicate(true)


## 1) Gerçek yol: tur 1 (A) -> R, tur 2 (B) -> R, tur 3 sağ tuş basılı -> kapı.
func _test_bolum3_cozum() -> void:
	_kayitlar().sifirla()
	var bolum: Node = await _bolumu_yukle()
	var olumler := 0
	var etiketler: Array = []
	var betikler := [_b3_betik_a(), _b3_betik_b()]
	for i in range(2):
		var sayac := [0]
		bolum.get_node("Oyuncu").oyuncu_oldu.connect(func() -> void: sayac[0] += 1)
		await _lazer_oyna(bolum, betikler[i], betikler[i].size())
		olumler += sayac[0]
		if not is_instance_valid(bolum):
			break
		etiketler.append(bolum.bilgi.text)
		var eski_id := bolum.get_instance_id()
		await _r_bas()
		bolum = await _yeni_sahne_bekle(eski_id)
		if bolum == null:
			break
	if bolum == null or not is_instance_valid(bolum) or etiketler.size() < 2:
		_kaydi("Bölüm 3 çözümü (3 tur, gerçek R/girdi yolu)", false,
			"tur 1/2 tamamlanamadı (ölüm: %d, etiket sayısı: %d)" % [olumler, etiketler.size()])
		return
	var sayac3 := [0]
	bolum.get_node("Oyuncu").oyuncu_oldu.connect(func() -> void: sayac3[0] += 1)
	var son_etiket: String = bolum.bilgi.text
	var klonlar_basta: int = _klonlar(bolum).size()
	var s: Dictionary = await _lazer_oyna(bolum, _saga(400), 400, _b3_ornekle)
	var bitti: bool = is_instance_valid(bolum) and bolum.bitti
	for w in range(3):
		await physics_frame   # sonuç ekranının ertelenmiş kurulumu bitsin
	var klon_son: Array = []
	for iz in s["klon_izleri"]:
		klon_son.append(iz[iz.size() - 1])
	var oz_son: Dictionary = s["ozel_iz"][s["ozel_iz"].size() - 1] if s["ozel_iz"].size() > 0 else {"l1": true, "l2": true}
	var turlar: int = _kayitlar().turlar.size()
	var gecti: bool = bitti and olumler == 0 and sayac3[0] == 0 and klonlar_basta == 2 and turlar == 2 \
		and klon_son.size() == 2 and absf(klon_son[0].x - 260.0) < 30.0 and absf(klon_son[1].x - 640.0) < 30.0 \
		and not oz_son["l1"] and not oz_son["l2"] and s["kare"] > 150 and s["kare"] < 260
	_kaydi("Bölüm 3 çözümü (3 tur, gerçek R/girdi yolu)", gecti,
		"bölüm bitti: %s, bitiş karesi: %d (%.2f sn), tur 1-2 ölüm: %d, tur 3 ölüm: %d, klon (tur 3 başı): %d, kayıtlı tur: %d, klon A x=%.0f (P1 260), klon B x=%.0f (P2 640), son karede L1 açık: %s, L2 açık: %s; etiketler: \"%s\" / \"%s\" / \"%s\"" % [
			bitti, s["kare"], s["kare"] / 60.0, olumler, sayac3[0], klonlar_basta, turlar,
			klon_son[0].x if klon_son.size() > 0 else -1.0, klon_son[1].x if klon_son.size() > 1 else -1.0,
			oz_son["l1"], oz_son["l2"], etiketler[0].get_slice("|", 0).strip_edges(),
			etiketler[1].get_slice("|", 0).strip_edges(), son_etiket.get_slice("|", 0).strip_edges()])
	paused = false


## 2) Başarısızlık ve atlanamazlık senaryoları.
func _test_bolum3_basarisizlik() -> void:
	var a: Array = await _b3_kaydet([], _b3_betik_a())
	var b: Array = await _b3_kaydet([a], _b3_betik_b())
	var kayit_ok: bool = a.size() > 0 and b.size() > 0
	_kaydi("Bölüm 3 hazırlık: A ve B kayıtları sağ kalır", kayit_ok,
		"A kayıt kare: %d, B kayıt kare: %d (0 = oyuncu öldü, kayıt atıldı)" % [a.size(), b.size()])

	# a) Klonsuz yürüyüş: L1'de ölür, Kayitlar değişmez, bölüm bitmez.
	var s: Dictionary = await _lazer_senaryo([], _saga(250), 250, Callable(), _b3_ornekle)
	var x: float = s["oyuncu_iz"][s["oyuncu_iz"].size() - 1].x
	var ok_a: bool = s["oyuncu_oldu"] == 1 and not s["tamamlandi"] and s["kare"] > 55 and s["kare"] < 100 \
		and x < 480.0 and _kayitlar().turlar.size() == 0 and s["yeni_sahne"] != null \
		and s["yeni_sahne"].bilgi.text.begins_with("Tur 1 ") and not s["yeni_sahne"].bitti
	_kaydi("Bölüm 3 başarısızlık: klonsuz yürüyüş L1'de ölür", ok_a,
		"ölüm sinyali: %d, ölüm karesi ~%d, son x=%.0f (L1 x=480), kayıtlı tur: %d (beklenen 0), etiket: \"%s\"" % [
			s["oyuncu_oldu"], s["kare"], x, _kayitlar().turlar.size(),
			s["yeni_sahne"].bilgi.text if s["yeni_sahne"] != null else "-"])

	# b) Yalnız A: L1 kapalı, oyuncu L1'i geçer ama L2'de ölür.
	var sb: Dictionary = await _lazer_senaryo([a], _saga(300), 300, Callable(), _b3_ornekle)
	var maks_x := -1.0e9
	for p in sb["oyuncu_iz"]:
		maks_x = maxf(maks_x, p.x)
	var ok_b: bool = sb["oyuncu_oldu"] == 1 and not sb["tamamlandi"] and maks_x > 520.0 and maks_x < 860.0 \
		and sb["kare"] > 120 and sb["kare"] < 190 and _kayitlar().turlar.size() == 1
	_kaydi("Bölüm 3 başarısızlık: yalnız A klonuyla L2'de ölür", ok_b,
		"ölüm sinyali: %d, ölüm karesi ~%d, en uzak x=%.0f (L1 480 geçildi, L2 860 geçilmedi), kayıtlı tur: %d (değişmedi)" % [
			sb["oyuncu_oldu"], sb["kare"], maks_x, _kayitlar().turlar.size()])

	# c) A plakada değil (x=200): L1 açık kalır, oyuncu L1'de ölür.
	var yanlis_a: Array = await _b3_kaydet([], _betik([[20, 1, false], [40, 0, false]]))
	var izleyici_c := func(bb: Node) -> Dictionary:
		var o := _b3_ornekle(bb)
		o["klon_x"] = _klonlar(bb)[0].global_position.x
		return o
	var sc: Dictionary = await _lazer_senaryo([yanlis_a], _saga(250), 250, Callable(), izleyici_c)
	var maks_c := -1.0e9
	for p in sc["oyuncu_iz"]:
		maks_c = maxf(maks_c, p.x)
	var klon_x_c: float = sc["ozel_iz"][sc["ozel_iz"].size() - 1]["klon_x"]
	var ok_c: bool = sc["oyuncu_oldu"] == 1 and not sc["tamamlandi"] and maks_c < 480.0 		and klon_x_c < 225.0 and sc["ozel_iz"][sc["ozel_iz"].size() - 1]["l1"]
	_kaydi("Bölüm 3 başarısızlık: A plakada değilken L1'de ölür", ok_c,
		"ölüm sinyali: %d, ölüm karesi ~%d, en uzak x=%.0f (L1 x=480), klon A x=%.0f (P1 plaka x 230..290 dışında), L1 son karede açık: %s" % [
			sc["oyuncu_oldu"], sc["kare"], maks_c, klon_x_c, sc["ozel_iz"][sc["ozel_iz"].size() - 1]["l1"]])

	# d) Yalnız B (A yok): B L1'de ölür, P2 hiç basılmaz, oyuncu da L1'de ölür.
	var izleyici_d := func(bb: Node) -> Dictionary:
		var o := _b3_ornekle(bb)
		var k: Node = _klonlar(bb)[0]
		o["klon_oldu"] = k.oldu
		o["klon_x"] = k.global_position.x
		return o
	# Oyuncu yerinde bekler (sahne yeniden yüklenmez), yalnız klon B gözlenir.
	var ed: Dictionary = await _lazer_senaryo([b], [], 200, Callable(), izleyici_d)
	var son_d: Dictionary = ed["ozel_iz"][ed["ozel_iz"].size() - 1]
	var p2_basildi := false
	for o in ed["ozel_iz"]:
		if o["p2"]:
			p2_basildi = true
	var ok_d: bool = son_d["klon_oldu"] and son_d["klon_x"] < 480.0 and not p2_basildi and ed["oyuncu_oldu"] == 0
	_kaydi("Bölüm 3 başarısızlık: A olmadan B L1'de ölür, P2 basılmaz", ok_d,
		"klon B ölü: %s (x=%.0f, L1 480), P2 hiç basılmadı: %s" % [
			son_d["klon_oldu"], son_d["klon_x"], not p2_basildi])

	# e) Işın zıplayarak aşılamaz: ışın zeminden (y=600) tavana (y=400) tam kapatır.
	var zipla: Array = []
	for i in range(14):
		zipla.append_array(_betik([[1, 1, true], [20, 1, false]]))
	var izleyici_e := func(bb: Node) -> Dictionary:
		var l1: Node = bb.get_node("Lazer1")
		var l2: Node = bb.get_node("Lazer2")
		return {"l1_alt": l1.position.y + l1.uzunluk, "l1_ust": l1.position.y,
			"l2_alt": l2.position.y + l2.uzunluk, "l2_ust": l2.position.y,
			"tavan_alt": bb.get_node("Tavan").position.y + 150.0}
	var se: Dictionary = await _lazer_senaryo([], zipla, zipla.size(), Callable(), izleyici_e)
	var maks_e := -1.0e9
	var min_y_e := 1.0e9
	for p in se["oyuncu_iz"]:
		maks_e = maxf(maks_e, p.x)
		min_y_e = minf(min_y_e, p.y)
	var g: Dictionary = se["ozel_iz"][0]
	var kapsam: bool = g["l1_alt"] >= 600.0 and g["l1_ust"] <= g["tavan_alt"] and g["l2_alt"] >= 600.0 and g["l2_ust"] <= g["tavan_alt"]
	var ok_e: bool = se["oyuncu_oldu"] == 1 and maks_e < 480.0 and kapsam
	_kaydi("Bölüm 3 başarısızlık: ışın zıplayarak aşılamaz", ok_e,
		"ölüm sinyali: %d, en uzak x=%.0f (L1 x=480), ışınlar y %.0f..%.0f ve %.0f..%.0f (zemin 600, tavan alt kenarı %.0f): tam kapatıyor: %s, en yüksek y=%.0f" % [
			se["oyuncu_oldu"], maks_e, g["l1_ust"], g["l1_alt"], g["l2_ust"], g["l2_alt"], g["tavan_alt"], kapsam, min_y_e])
	_kayitlar().sifirla()


## 3) max_klon=2: üçüncü R yeni klon kaydetmez.
func _test_bolum3_klon_siniri() -> void:
	_kayitlar().sifirla()
	var bolum: Node = await _bolumu_yukle()
	var maks: int = bolum.max_klon
	var gecti := maks == 2
	var ayrinti: Array = []
	for n in range(maks + 1):
		for i in range(5):
			_girdi_uygula({"yon": 1.0, "zipla": false})
			await physics_frame
		_girdi_uygula({"yon": 0.0, "zipla": false})
		var eski_id := bolum.get_instance_id()
		await _r_bas()
		var yeni: Node = await _yeni_sahne_bekle(eski_id)
		var sayi: int = _kayitlar().turlar.size()
		if n < maks:
			gecti = gecti and yeni != null and sayi == n + 1
			if yeni == null:
				break
			bolum = yeni
		else:
			var yazi: String = bolum.bilgi.text
			gecti = gecti and yeni == null and sayi == maks and yazi.contains("Klon hakkı bitti") \
				and yazi.contains("2/2")
			ayrinti.append("sınırda etiket: \"%s\"" % yazi)
		ayrinti.append("R #%d -> kayıtlı klon: %d" % [n + 1, sayi])
	_kaydi("Bölüm 3: klon sınırı (üçüncü R klon kaydetmez)", gecti, "max_klon=%d; %s" % [maks, ", ".join(ayrinti)])
	_kayitlar().sifirla()


## 5) Determinizm: çözümün 3. turu 100 kez, her karede aynı iz.
func _test_bolum3_determinizm() -> void:
	var a: Array = await _b3_kaydet([], _b3_betik_a())
	var b: Array = await _b3_kaydet([a], _b3_betik_b())
	var referans: Dictionary = {}
	var sapmali := 0
	var maks_sapma := 0.0
	var bitmeyen := 0
	for n in range(TEKRAR):
		var s: Dictionary = await _lazer_senaryo([a, b], _saga(400), 400, Callable(), _b3_ornekle)
		# Bölüm sonu ekranının ertelenmiş kurulumu bitsin (sahne hemen değişmesin).
		for w in range(3):
			await physics_frame
		# Bölüm erken bittiyse (tamamlandi=false) ve oyuncu ölmediyse kapıya ulaşılmıştır.
		var bitti: bool = not s["tamamlandi"] and s["oyuncu_oldu"] == 0
		if not bitti:
			bitmeyen += 1
		if n == 0:
			referans = s
			continue
		var bu: bool = s["ozel_iz"].size() != referans["ozel_iz"].size() or s["kare"] != referans["kare"]
		for f in range(mini(s["ozel_iz"].size(), referans["ozel_iz"].size())):
			if s["ozel_iz"][f] != referans["ozel_iz"][f]:
				bu = true
			var d: float = (s["oyuncu_iz"][f] - referans["oyuncu_iz"][f]).length()
			for ki in range(2):
				d = maxf(d, (s["klon_izleri"][ki][f] - referans["klon_izleri"][ki][f]).length())
			if d > 0.0:
				bu = true
				maks_sapma = maxf(maks_sapma, d)
		if bu:
			sapmali += 1
	_kaydi("Bölüm 3: determinizm (100x çözüm)", sapmali == 0 and bitmeyen == 0,
		"%d çalıştırma x %d kare, sapmalı çalıştırma: %d, en büyük sapma: %.4f px, bölümü bitirmeyen çalıştırma: %d" % [
			TEKRAR, referans["kare"], sapmali, maks_sapma, bitmeyen])
	_kayitlar().sifirla()
	paused = false


# ---------------------------------------------------------------- Bölüm 4 testleri
#
# Taslak: docs/devir/bolum_4_taslak.md ("Kule"). 3 katlı dikey yapı, max_klon=3.
# Kare sayıları HEDEFTİR; betikler sabit kareye değil KOŞULA (asansör yukarıda mı,
# plaka basılı mı, konum eşiği) bağlıdır. Kayıt, bu koşullu oyundan üretilir.

const BOLUM_4 := "res://scenes/bolumler/bolum_4.tscn"
const B4_AYAK := 24.0   # karakter merkezinden ayağa uzaklık

var _b4_onbellek: Array = []   # [a0, a, b] kayıtları (bir kez üretilir)


func _b4_a(yon: float, kosul := Callable(), maks := 300, zipla := false) -> Dictionary:
	return {"yon": yon, "kosul": kosul, "maks": maks, "zipla": zipla}


func _b4_x_ge(v: float) -> Callable:
	return func(b: Node) -> bool: return b.get_node("Oyuncu").global_position.x >= v


func _b4_x_le(v: float) -> Callable:
	return func(b: Node) -> bool: return b.get_node("Oyuncu").global_position.x <= v


func _b4_yukari(ad: String, y: float) -> Callable:
	return func(b: Node) -> bool: return b.get_node(ad).position.y <= y + 0.5


func _b4_durdu(ymax: float, xmin := -1.0e9) -> Callable:
	return func(b: Node) -> bool:
		var o: CharacterBody2D = b.get_node("Oyuncu")
		return o.is_on_floor() and o.global_position.y <= ymax and o.global_position.x >= xmin


func _b4_plakada(ad: String) -> Callable:
	return func(b: Node) -> bool:
		return b.get_node(ad).basili_mi() and b.get_node("Oyuncu").is_on_floor()


func _b4_bitti_k() -> Callable:
	return func(b: Node) -> bool: return b.bitti


func _b4_tur1() -> Array:
	return [_b4_a(1, _b4_x_ge(200.0), 100), _b4_a(0, Callable(), 10)]


func _b4_tur2() -> Array:
	return [
		_b4_a(1, _b4_x_ge(440.0), 150),
		_b4_a(1, _b4_durdu(497.0, 520.0), 150, true),     # E0 üstüne
		_b4_a(0, _b4_durdu(422.5), 120, true),            # PA'ya dikey zıpla
		_b4_a(1, _b4_x_ge(680.0), 80),
		_b4_a(0, Callable(), 10)]


func _b4_e1_cik() -> Array:
	return [_b4_a(1, _b4_x_ge(340.0), 100), _b4_a(0, _b4_yukari("Asansor1", 340.0), 500)]


func _b4_tur3() -> Array:
	return _b4_e1_cik() + [_b4_a(1, _b4_plakada("PlakaC"), 500), _b4_a(0, Callable(), 10)]


func _b4_tur4() -> Array:
	return _b4_e1_cik() + [
		_b4_a(1, _b4_x_ge(760.0), 200),
		_b4_a(0, _b4_yukari("Asansor2", 210.0), 700),
		_b4_a(1, _b4_bitti_k(), 300)]


func _b4_ornekle(b: Node) -> Dictionary:
	return {
		"e0": b.get_node("Asansor0").position.y, "e1": b.get_node("Asansor1").position.y,
		"e2": b.get_node("Asansor2").position.y, "p0": b.get_node("Plaka0").basili_mi(),
		"pa": b.get_node("PlakaA").basili_mi(), "pc": b.get_node("PlakaC").basili_mi()}


## Adımları koşula kadar oynatır. Koşul sağlanınca adım biter (maks kare aşılırsa karşılanmamış sayılır).
func _b4_kosullu(bolum: Node, adimlar: Array) -> Dictionary:
	var oyuncu: CharacterBody2D = bolum.get_node("Oyuncu")
	var klonlar: Array = _klonlar(bolum)
	var klon_iz: Array = []
	for k in klonlar:
		klon_iz.append([])
	var iz: Array = []
	var ozel: Array = []
	var baslangic: Array = []
	var tamam: Array = []
	var kare := 0
	for a in adimlar:
		baslangic.append(iz.size())
		var n := 0
		var karsilandi: bool = not a["kosul"].is_valid()
		while n < a["maks"]:
			if not is_instance_valid(bolum) or bolum.bitti:
				break
			_girdi_uygula({"yon": a["yon"], "zipla": a["zipla"] and n == 0})
			iz.append(oyuncu.global_position)
			ozel.append(_b4_ornekle(bolum))
			for i in range(klonlar.size()):
				klon_iz[i].append(klonlar[i].global_position)
			await physics_frame
			n += 1
			kare += 1
			if a["kosul"].is_valid() and a["kosul"].call(bolum):
				karsilandi = true
				break
		tamam.append(karsilandi)
		if bolum.bitti:
			break
	_girdi_uygula({"yon": 0.0, "zipla": false})
	for i in range(3):
		await physics_frame
	return {"kare": kare, "bitti": bolum.bitti, "iz": iz, "ozel": ozel, "klon_izleri": klon_iz,
		"baslangic": baslangic, "tamam": tamam,
		"kayit": oyuncu.kayit_girdileri.duplicate(true)}


## Önceki klonlarla bölümü yükler, adımları oynatır.
func _b4_senaryo(kayitlar: Array, adimlar: Array, hazirlik := Callable()) -> Dictionary:
	_kayitlar().sifirla()
	for k in kayitlar:
		_kayitlar().tur_kaydet(k.duplicate(true))
	var bolum: Node = await _bolumu_yukle()
	if hazirlik.is_valid():
		hazirlik.call(bolum)
	var s: Dictionary = await _b4_kosullu(bolum, adimlar)
	paused = false
	return s


func _b4_ayak_min(iz: Array, bas := 0, son := -1) -> float:
	var m := 1.0e9
	var bitis: int = iz.size() if son < 0 else mini(son, iz.size())
	for f in range(bas, bitis):
		m = minf(m, iz[f].y + B4_AYAK)
	return m


func _b4_kayitlar() -> Array:
	if _b4_onbellek.is_empty():
		var s1: Dictionary = await _b4_senaryo([], _b4_tur1())
		var s2: Dictionary = await _b4_senaryo([s1["kayit"]], _b4_tur2())
		var s3: Dictionary = await _b4_senaryo([s1["kayit"], s2["kayit"]], _b4_tur3())
		_b4_onbellek = [s1["kayit"], s2["kayit"], s3["kayit"]]
	return _b4_onbellek


func _b4_en_ust(ozel: Array, anahtar: String) -> float:
	var m := 1.0e9
	for o in ozel:
		m = minf(m, o[anahtar])
	return m


func _b4_hic(ozel: Array, anahtar: String) -> bool:
	for o in ozel:
		if o[anahtar]:
			return true
	return false


## 1) Gerçek yol: R ile 3 klon, 4. turda kapıya.
func _test_bolum4_cozum() -> void:
	_kayitlar().sifirla()
	var bolum: Node = await _bolumu_yukle()
	var turlar: Array = [_b4_tur1(), _b4_tur2(), _b4_tur3()]
	var kareler: Array = []
	var tamam_hepsi := true
	var olumsuz := ""
	for i in range(3):
		var s: Dictionary = await _b4_kosullu(bolum, turlar[i])
		kareler.append(s["kare"])
		if s["tamam"].has(false):
			tamam_hepsi = false
			olumsuz += " tur%d adım karşılanmadı %s;" % [i + 1, str(s["tamam"])]
		var eski_id := bolum.get_instance_id()
		await _r_bas()
		bolum = await _yeni_sahne_bekle(eski_id)
		if bolum == null:
			break
	if bolum == null:
		_kaydi("Bölüm 4 çözümü (4 tur, gerçek R/girdi yolu)", false, "tur %d sonrası sahne yüklenmedi;%s" % [kareler.size(), olumsuz])
		return
	var klon_basta: int = _klonlar(bolum).size()
	var son_etiket: String = bolum.bilgi.text
	var s4: Dictionary = await _b4_kosullu(bolum, _b4_tur4())
	if s4["tamam"].has(false):
		tamam_hepsi = false
		olumsuz += " tur4 adım karşılanmadı %s;" % str(s4["tamam"])
	var gecti: bool = s4["bitti"] and klon_basta == 3 and _kayitlar().turlar.size() == 3 \
		and son_etiket.contains("Klon: 3/3") and son_etiket.contains("Klon hakkı bitti") and tamam_hepsi \
		and s4["kare"] <= 600
	_kaydi("Bölüm 4 çözümü (4 tur, gerçek R/girdi yolu)", gecti,
		"bölüm bitti: %s, tur kareleri: %s + %d (%.2f sn), klon: %d, kayıtlı tur: %d, etiket: \"%s\", E1 y min=%.0f (hedef 340 = üst yüzey 330), E2 y min=%.0f (hedef 210 = üst yüzey 200)%s" % [
			s4["bitti"], str(kareler), s4["kare"], s4["kare"] / 60.0, klon_basta, _kayitlar().turlar.size(),
			son_etiket, _b4_en_ust(s4["ozel"], "e1"), _b4_en_ust(s4["ozel"], "e2"), olumsuz])
	_kayitlar().sifirla()
	paused = false


## 2) Atlanamazlık: klonsuz zeminden PA ve K'ya zıplama.
func _test_bolum4_atlanamaz() -> void:
	var adimlar: Array = [_b4_a(1, _b4_x_ge(660.0), 200)]
	for i in range(6):
		adimlar.append(_b4_a(0, Callable(), 60, true))
	adimlar.append(_b4_a(1, _b4_x_ge(1070.0), 300))
	var k_yuru := adimlar.size() - 1
	for i in range(6):
		adimlar.append(_b4_a(0, Callable(), 60, true))
	var s: Dictionary = await _b4_senaryo([], adimlar)
	var pa_min := _b4_ayak_min(s["iz"], s["baslangic"][1], s["baslangic"][k_yuru])
	var k_min := _b4_ayak_min(s["iz"], s["baslangic"][k_yuru + 1])
	var zipladi: bool = pa_min < 590.0 and k_min < 590.0
	var gecti: bool = pa_min > 445.0 and k_min > 445.0 and zipladi and not s["bitti"]
	_kaydi("Bölüm 4 atlanamaz: klonsuz zeminden PA/K'ya çıkılmaz", gecti,
		"PA altında ayak y min=%.1f (PA üstü 445, beklenen ~499), K altında ayak y min=%.1f (zıpladı: %s), bölüm bitti: %s" % [
			pa_min, k_min, zipladi, s["bitti"]])
	# Revizyon 1: zeminden zıplayan HİÇBİR karede plakayı basmamalı (platform üstü 445, plaka 429..445).
	var plaka_ok: bool = not _b4_hic(s["ozel"], "pa") and not _b4_hic(s["ozel"], "pc")
	_kaydi("Bölüm 4 atlanamaz: zeminden zıplayan plakaya basmaz", plaka_ok,
		"P_a basıldı: %s, P_c basıldı: %s (beklenen ikisi de false), E1 en yüksek y=%.0f (aşağı 610, yukarı 340; asansör konumu = merkez, üst yüzey 330), E2 en yüksek y=%.0f (aşağı 340, yukarı 210; üst yüzey 200)" % [
			_b4_hic(s["ozel"], "pa"), _b4_hic(s["ozel"], "pc"), _b4_en_ust(s["ozel"], "e1"), _b4_en_ust(s["ozel"], "e2")])


## 3) Başarısızlık senaryoları.
func _test_bolum4_basarisizlik() -> void:
	var kay: Array = await _b4_kayitlar()
	var a0: Array = kay[0]
	var a: Array = kay[1]
	var kayit_ok: bool = a0.size() > 0 and a.size() > 0 and kay[2].size() > 0
	_kaydi("Bölüm 4 hazırlık: A0, A, B kayıtları üretildi", kayit_ok,
		"kare sayıları: A0 %d, A %d, B %d" % [a0.size(), a.size(), kay[2].size()])

	# a) Yalnız A0: oyuncu E0 ile PA'ya çıkar, P_a basar, E1 yükselir ama oyuncu üstünde değil.
	var adim_a: Array = [
		_b4_a(1, _b4_x_ge(440.0), 150),
		_b4_a(1, _b4_durdu(497.0, 520.0), 150, true),
		_b4_a(0, _b4_durdu(422.5), 120, true),
		_b4_a(1, _b4_x_ge(680.0), 80),
		_b4_a(0, Callable(), 300),
		_b4_a(-1, _b4_x_le(340.0), 400),
		_b4_a(0, Callable(), 150)]
	var sa: Dictionary = await _b4_senaryo([a0], adim_a)
	var min_a := _b4_ayak_min(sa["iz"])
	var ok_a: bool = not sa["bitti"] and _b4_hic(sa["ozel"], "pa") and _b4_en_ust(sa["ozel"], "e1") <= 340.5 and min_a > 400.0
	_kaydi("Bölüm 4 başarısızlık: yalnız A0 (oyuncu E1'e binemez)", ok_a,
		"P_a basıldı: %s, E1 en yüksek y=%.0f (yukarıda), oyuncu ayak y min=%.1f (PA üstü 445, F2 330), bölüm bitti: %s, adımlar: %s" % [
			_b4_hic(sa["ozel"], "pa"), _b4_en_ust(sa["ozel"], "e1"), min_a, sa["bitti"], str(sa["tamam"])])

	# b) Yalnız A (A0 yok): PA'ya ulaşılmaz, P_a basılmaz (klon A da, oyuncu da).
	var adim_b: Array = [_b4_a(1, _b4_x_ge(620.0), 200)]
	for i in range(6):
		adim_b.append(_b4_a(0, Callable(), 60, true))
	adim_b.append(_b4_a(0, Callable(), 200))
	var sb: Dictionary = await _b4_senaryo([a], adim_b)
	var min_b := _b4_ayak_min(sb["iz"])
	var min_klon := _b4_ayak_min(sb["klon_izleri"][0])
	var ok_b: bool = not sb["bitti"] and not _b4_hic(sb["ozel"], "pa") and min_b > 445.0 and min_klon > 445.0
	_kaydi("Bölüm 4 başarısızlık: yalnız A (A0 yok), P_a basılmaz", ok_b,
		"P_a hiç basılmadı: %s, oyuncu ayak y min=%.1f, klon A ayak y min=%.1f (PA üstü 445), bölüm bitti: %s" % [
			not _b4_hic(sb["ozel"], "pa"), min_b, min_klon, sb["bitti"]])

	# c) A0+A, oyuncu F2'den K'ya düşer: K'dan F2'ye çıkamaz, E2'ye binemez.
	var adim_c: Array = _b4_e1_cik() + [_b4_a(1, _b4_plakada("PlakaC"), 500)]
	adim_c.append(_b4_a(0, Callable(), 100))   # K'da dur: E2 tamamen yükselsin
	var j0 := adim_c.size()
	for i in range(4):
		adim_c.append(_b4_a(0, Callable(), 60, true))
	for i in range(4):
		adim_c.append(_b4_a(-1, Callable(), 50, true))
	var sc: Dictionary = await _b4_senaryo([a0, a], adim_c)
	var min_c := _b4_ayak_min(sc["iz"], sc["baslangic"][j0] if sc["baslangic"].size() > j0 else 0)
	var k_ulasildi: bool = sc["tamam"].size() >= j0 and not sc["tamam"].slice(0, j0).has(false)
	var ok_c: bool = k_ulasildi and not sc["bitti"] and min_c > 330.0 and _b4_en_ust(sc["ozel"], "e2") <= 210.5
	_kaydi("Bölüm 4 başarısızlık: K'dan F2'ye çıkılamaz (2 klon)", ok_c,
		"K'ya ulaşıldı: %s, E2 y min=%.0f (yukarı), K'dan zıplarken ayak y min=%.1f (F2 üstü 330), bölüm bitti: %s" % [
			k_ulasildi, _b4_en_ust(sc["ozel"], "e2"), min_c, sc["bitti"]])

	# d) B yön hatası: B sola yürür, P_c basılmaz, E2 çıkmaz, bölüm bitmez.
	var adim_bb: Array = _b4_e1_cik() + [_b4_a(-1, Callable(), 120)]
	var sbb: Dictionary = await _b4_senaryo([a0, a], adim_bb)
	var b_yanlis: Array = sbb["kayit"]
	var adim_d: Array = _b4_e1_cik() + [
		_b4_a(1, _b4_x_ge(760.0), 200), _b4_a(0, _b4_yukari("Asansor2", 210.0), 200), _b4_a(1, _b4_bitti_k(), 300)]
	var sd: Dictionary = await _b4_senaryo([a0, a, b_yanlis], adim_d)
	# Oyuncu son adımda F2'nin ucundan düşüp K'ya inebilir (P_c'ye kendisi basar); klon B'nin
	# etkisi yalnız o adıma kadar ölçülür (E2 beklenirken).
	var son_adim: int = sd["baslangic"][4] if sd["baslangic"].size() > 4 else sd["ozel"].size()
	var oz_d: Array = sd["ozel"].slice(0, son_adim)
	var min_d := _b4_ayak_min(sd["iz"])
	var ok_d: bool = not sd["bitti"] and not _b4_hic(oz_d, "pc") and _b4_en_ust(oz_d, "e2") > 339.0 and min_d > 310.0
	_kaydi("Bölüm 4 başarısızlık: B yön hatası (P_c basılmaz, bölüm bitmez)", ok_d,
		"B beklenirken (%d kare) P_c hiç basılmadı: %s, E2 en yüksek y=%.0f (aşağı 340), oyuncu ayak y min=%.1f (F3 200), bölüm bitti: %s" % [
			son_adim, not _b4_hic(oz_d, "pc"), _b4_en_ust(oz_d, "e2"), min_d, sd["bitti"]])
	_kayitlar().sifirla()


## 4) max_klon=3: dördüncü R yeni klon kaydetmez.
func _test_bolum4_klon_siniri() -> void:
	_kayitlar().sifirla()
	var bolum: Node = await _bolumu_yukle()
	var maks: int = bolum.max_klon
	var gecti := maks == 3
	var ayrinti: Array = []
	for n in range(maks + 1):
		for i in range(5):
			_girdi_uygula({"yon": 1.0, "zipla": false})
			await physics_frame
		_girdi_uygula({"yon": 0.0, "zipla": false})
		var eski_id := bolum.get_instance_id()
		await _r_bas()
		var yeni: Node = await _yeni_sahne_bekle(eski_id)
		var sayi: int = _kayitlar().turlar.size()
		if n < maks:
			gecti = gecti and yeni != null and sayi == n + 1
			if yeni == null:
				break
			bolum = yeni
		else:
			var yazi: String = bolum.bilgi.text
			gecti = gecti and yeni == null and sayi == maks and yazi.contains("Klon hakkı bitti") \
				and yazi.contains("3/3")
			ayrinti.append("sınırda etiket: \"%s\"" % yazi)
		ayrinti.append("R #%d -> kayıtlı klon: %d" % [n + 1, sayi])
	_kaydi("Bölüm 4: klon sınırı (dördüncü R klon kaydetmez)", gecti, "max_klon=%d; %s" % [maks, ", ".join(ayrinti)])
	_kayitlar().sifirla()


## 5) Tek yönlü platform: aşağıdan geçiş, yan geçiş, üstten düşünce üstünde kalma.
func _test_bolum4_tek_yonlu() -> void:
	var kay: Array = await _b4_kayitlar()
	# a) E0 yukarıdayken (A0 plakada) altından zıpla: gövde PA'dan geçer, üstüne oturur.
	var adim_a: Array = [
		_b4_a(1, _b4_x_ge(440.0), 150),
		_b4_a(1, _b4_durdu(497.0, 520.0), 150, true),
		_b4_a(0, _b4_durdu(422.5), 120, true),
		_b4_a(0, Callable(), 30)]
	var sa: Dictionary = await _b4_senaryo([kay[0]], adim_a)
	var ba: int = sa["baslangic"][2]
	var kare_a: int = sa["baslangic"][3] - ba
	var min_y := 1.0e9
	for f in range(ba, sa["iz"].size()):
		min_y = minf(min_y, sa["iz"][f].y)
	var son_y: float = sa["iz"][sa["iz"].size() - 1].y
	var ok_a: bool = not sa["tamam"].has(false) and absf(son_y - 421.0) < 1.5 and min_y < 421.0 - 1.0 \
		and sa["iz"][ba].y > 421.0 + 40.0
	_kaydi("Bölüm 4 tek yönlü: aşağıdan geçilir, PA üstüne oturur", ok_a,
		"E0 üstünden zıplama başlangıç y=%.0f, PA üstüne oturma süresi: %d kare, en yüksek y=%.1f, son y=%.1f (beklenen 421), adımlar tamam: %s" % [
			sa["iz"][ba].y, kare_a, min_y, son_y, str(sa["tamam"])])

	# b) Yan geçiş: oyuncu PA bandının içinde (y=480) yürür; platform yatayda engellemez.
	var hazir_b := func(b: Node) -> void: b.get_node("Oyuncu").global_position = Vector2(560.0, 480.0)
	var sb: Dictionary = await _b4_senaryo([], [_b4_a(1, _b4_x_ge(760.0), 100), _b4_a(0, Callable(), 60)], hazir_b)
	var son_b: Vector2 = sb["iz"][sb["iz"].size() - 1]
	var ok_b: bool = not sb["tamam"].has(false) and son_b.x >= 760.0 and absf(son_b.y - 576.0) < 1.5
	_kaydi("Bölüm 4 tek yönlü: yan yüzden geçilir", ok_b,
		"başlangıç (560,480) PA sol kenarı x=600, son konum (%.0f, %.0f) (beklenen x>=760, y=576), adım karşılandı: %s" % [
			son_b.x, son_b.y, str(sb["tamam"])])

	# c) Üstten düşen üstünde kalır: K'nın üstüne y=300'den bırak.
	var hazir_c := func(b: Node) -> void: b.get_node("Oyuncu").global_position = Vector2(1070.0, 300.0)
	var sc: Dictionary = await _b4_senaryo([], [_b4_a(0, Callable(), 120)], hazir_c)
	var son_c: float = sc["iz"][sc["iz"].size() - 1].y
	var ok_c: bool = absf(son_c - 421.0) < 1.5 and _b4_hic(sc["ozel"], "pc")
	_kaydi("Bölüm 4 tek yönlü: üstten düşen K üstünde kalır", ok_c,
		"son y=%.1f (beklenen 421), P_c basıldı: %s" % [son_c, _b4_hic(sc["ozel"], "pc")])
	_kayitlar().sifirla()


## 6) Determinizm: 4. turun kaydı 100 kez, her karede aynı iz ve hep kapıya ulaşır.
func _test_bolum4_determinizm() -> void:
	var kay: Array = await _b4_kayitlar()
	var s0: Dictionary = await _b4_senaryo(kay, _b4_tur4())
	var betik: Array = s0["kayit"]
	var ornek := func(b: Node) -> Dictionary: return _b4_ornekle(b)
	var referans: Dictionary = {}
	var sapmali := 0
	var bitmeyen := 0
	var maks_sapma := 0.0
	for n in range(TEKRAR):
		var s: Dictionary = await _senaryo(kay, betik, 700, Callable(), ornek)
		if not s["bitti"]:
			bitmeyen += 1
		if n == 0:
			referans = s
			continue
		var bu: bool = s["ozel_iz"].size() != referans["ozel_iz"].size() or s["kare"] != referans["kare"]
		for f in range(mini(s["ozel_iz"].size(), referans["ozel_iz"].size())):
			if s["ozel_iz"][f] != referans["ozel_iz"][f]:
				bu = true
			var d: float = (s["oyuncu_iz"][f] - referans["oyuncu_iz"][f]).length()
			for ki in range(3):
				d = maxf(d, (s["klon_izleri"][ki][f] - referans["klon_izleri"][ki][f]).length())
			if d > 0.0:
				bu = true
				maks_sapma = maxf(maks_sapma, d)
		if bu:
			sapmali += 1
	_kaydi("Bölüm 4: determinizm (100x çözüm)", sapmali == 0 and bitmeyen == 0 and s0["bitti"],
		"%d çalıştırma x %d kare, sapmalı: %d, en büyük sapma: %.4f px, bitirmeyen çalıştırma: %d, kayıt turu bitti: %s" % [
			TEKRAR, referans["kare"], sapmali, maks_sapma, bitmeyen, s0["bitti"]])
	_kayitlar().sifirla()
	paused = false


# ---------------------------------------------------------------- Bölüm 5 testleri
# Taslak: docs/devir/bolum_5_taslak.md ("Uzaktan Anahtar"). max_klon=2, şalter + iki lazer.
# Betikler sabit kareye değil KOŞULA (asansör yukarıda mı, şalter yönü, lazer açık mı, x eşiği)
# bağlıdır. Ölüm: oyuncu_oldu sinyali sayılır (bolum.bitti ölümde de true olur).

const BOLUM_5 := "res://scenes/bolumler/bolum_5.tscn"

var _b5_onbellek: Array = []   # [A, B] kayıtları


func _b5_ornekle(b: Node) -> Dictionary:
	return {
		"asansor": b.get_node("Asansor").position.y, "plaka": b.get_node("Plaka").basili_mi(),
		"salter": b.get_node("Salter").sagda,
		"l1": b.get_node("Lazer1").acik_mi(), "l2": b.get_node("Lazer2").acik_mi()}


func _b5_salter_sagda() -> Callable:
	return func(b: Node) -> bool: return b.get_node("Salter").sagda


func _b5_salter_solda() -> Callable:
	return func(b: Node) -> bool: return not b.get_node("Salter").sagda


func _b5_lazer_kapali(ad: String) -> Callable:
	return func(b: Node) -> bool: return not b.get_node(ad).acik_mi()


func _b5_tur1() -> Array:
	return [_b4_a(0, Callable(), 90), _b4_a(-1, _b4_x_le(40.0), 60), _b4_a(0, Callable(), 10)]


## Klon B: asansöre bin, yüksel, şalteri sağa it, x=590'da bekle, geri sola it (sola çevir).
func _b5_tur2() -> Array:
	return [
		_b4_a(1, _b4_x_ge(390.0), 100),
		_b4_a(0, _b4_yukari("Asansor", 480.0), 300),
		_b4_a(1, _b5_salter_sagda(), 100),
		_b4_a(1, _b4_x_ge(590.0), 40),
		_b4_a(0, Callable(), 60),
		_b4_a(-1, _b5_salter_solda(), 40),
		_b4_a(0, Callable(), 5)]


func _b5_tur3() -> Array:
	return [
		_b4_a(1, _b4_x_ge(660.0), 150),
		_b4_a(0, _b5_lazer_kapali("Lazer1"), 300),
		_b4_a(1, _b4_x_ge(850.0), 80),
		_b4_a(0, _b5_lazer_kapali("Lazer2"), 300),
		_b4_a(1, _b4_bitti_k(), 200)]


## _b4_kosullu'nun B5 sürümü: ölüme dayanıklı, kendi örnekleyicisi var.
func _b5_kosullu(bolum: Node, adimlar: Array, sayac: Array) -> Dictionary:
	var oyuncu: CharacterBody2D = bolum.get_node("Oyuncu")
	var klonlar: Array = _klonlar(bolum)
	var klon_iz: Array = []
	for k in klonlar:
		klon_iz.append([])
	var iz: Array = []
	var ozel: Array = []
	var baslangic: Array = []
	var tamam: Array = []
	var kare := 0
	for a in adimlar:
		baslangic.append(iz.size())
		var n := 0
		var karsilandi: bool = not a["kosul"].is_valid()
		while n < a["maks"]:
			if not is_instance_valid(bolum) or bolum.bitti:
				break
			_girdi_uygula({"yon": a["yon"], "zipla": a["zipla"] and n == 0})
			iz.append(oyuncu.global_position)
			ozel.append(_b5_ornekle(bolum))
			for i in range(klonlar.size()):
				klon_iz[i].append(klonlar[i].global_position)
			await physics_frame
			n += 1
			kare += 1
			if a["kosul"].is_valid() and is_instance_valid(bolum) and a["kosul"].call(bolum):
				karsilandi = true
				break
		tamam.append(karsilandi)
		if not is_instance_valid(bolum) or bolum.bitti:
			break
	_girdi_uygula({"yon": 0.0, "zipla": false})
	var bitti_son: bool = is_instance_valid(bolum) and bolum.bitti
	var kayit: Array = []
	if is_instance_valid(oyuncu):
		kayit = oyuncu.kayit_girdileri.duplicate(true)
	for i in range(3):
		await physics_frame
	return {"kare": kare, "bitti": bitti_son and sayac[0] == 0, "oldu": sayac[0], "iz": iz, "ozel": ozel,
		"klon_izleri": klon_iz, "baslangic": baslangic, "tamam": tamam, "kayit": kayit}


func _b5_senaryo(kayitlar: Array, adimlar: Array) -> Dictionary:
	_kayitlar().sifirla()
	for k in kayitlar:
		_kayitlar().tur_kaydet(k.duplicate(true))
	var bolum: Node = await _bolumu_yukle()
	var sayac := [0]
	bolum.get_node("Oyuncu").oyuncu_oldu.connect(func() -> void: sayac[0] += 1)
	var s: Dictionary = await _b5_kosullu(bolum, adimlar, sayac)
	paused = false
	return s


func _b5_kayitlar() -> Array:
	if _b5_onbellek.is_empty():
		var s1: Dictionary = await _b5_senaryo([], _b5_tur1())
		var s2: Dictionary = await _b5_senaryo([s1["kayit"]], _b5_tur2())
		_b5_onbellek = [s1["kayit"], s2["kayit"]]
	return _b5_onbellek


func _b5_maks_x(iz: Array) -> float:
	var m := -1.0e9
	for p in iz:
		m = maxf(m, p.x)
	return m


## 1) Gerçek yol: R ile 2 klon, 3. turda kapıya.
func _test_bolum5_cozum() -> void:
	_kayitlar().sifirla()
	var bolum: Node = await _bolumu_yukle()
	var turlar: Array = [_b5_tur1(), _b5_tur2()]
	var kareler: Array = []
	var olumsuz := ""
	for i in range(2):
		var sayac := [0]
		bolum.get_node("Oyuncu").oyuncu_oldu.connect(func() -> void: sayac[0] += 1)
		var s: Dictionary = await _b5_kosullu(bolum, turlar[i], sayac)
		kareler.append(s["kare"])
		if s["tamam"].has(false) or s["oldu"] > 0:
			olumsuz += " tur%d adım karşılanmadı %s oldu=%d;" % [i + 1, str(s["tamam"]), s["oldu"]]
		var eski_id := bolum.get_instance_id()
		await _r_bas()
		bolum = await _yeni_sahne_bekle(eski_id)
		if bolum == null:
			_kaydi("Bölüm 5 çözümü (3 tur, gerçek R/girdi yolu)", false, "tur %d sonrası sahne yüklenmedi;%s" % [i + 1, olumsuz])
			return
	var klon_basta: int = _klonlar(bolum).size()
	var etiket: String = bolum.bilgi.text
	var sayac3 := [0]
	bolum.get_node("Oyuncu").oyuncu_oldu.connect(func() -> void: sayac3[0] += 1)
	var s3: Dictionary = await _b5_kosullu(bolum, _b5_tur3(), sayac3)
	if s3["tamam"].has(false):
		olumsuz += " tur3 adım karşılanmadı %s;" % str(s3["tamam"])
	var gecti: bool = s3["bitti"] and klon_basta == 2 and _kayitlar().turlar.size() == 2 \
		and etiket.contains("Klon: 2/2") and etiket.contains("Klon hakkı bitti") \
		and olumsuz == "" and s3["kare"] <= 600
	_kaydi("Bölüm 5 çözümü (3 tur, gerçek R/girdi yolu)", gecti,
		"bölüm bitti: %s, tur kareleri: %s + %d (%.2f sn, sınır 10 sn), klon: %d, kayıtlı tur: %d, ölüm: %d, etiket: \"%s\", asansör y min=%.0f (hedef 480), şalter sağda görüldü: %s, adım başlangıçları: %s%s" % [
			s3["bitti"], str(kareler), s3["kare"], s3["kare"] / 60.0, klon_basta, _kayitlar().turlar.size(),
			s3["oldu"], etiket, _b4_en_ust(s3["ozel"], "asansor"), _b4_hic(s3["ozel"], "salter"),
			str(s3["baslangic"]), olumsuz])
	_kayitlar().sifirla()
	paused = false


## 2) Atlanamazlık.
func _test_bolum5_atlanamaz() -> void:
	# a) Klonsuz yürüyüş: L1'de ölür, Kayitlar değişmez, tur yeniden başlar.
	var sa: Dictionary = await _b5_senaryo([], [_b4_a(1, Callable(), 400)])
	var son_a: Vector2 = sa["iz"][sa["iz"].size() - 1]
	var ok_a: bool = sa["oldu"] == 1 and not sa["bitti"] and son_a.x > 690.0 and son_a.x < 735.0 \
		and _kayitlar().turlar.size() == 0
	_kaydi("Bölüm 5 atlanamaz: klonsuz yürüyüş L1'de ölür", ok_a,
		"ölüm: %d (beklenen 1), son x=%.0f (L1 x=720), kayıtlı tur: %d (beklenen 0), bölüm bitti: %s" % [
			sa["oldu"], son_a.x, _kayitlar().turlar.size(), sa["bitti"]])

	# b) Zeminden zıplayarak sahanlığa (üst yüzey y=470) çıkılmaz.
	var adim_b: Array = [_b4_a(1, _b4_x_ge(300.0), 100)]
	for i in range(8):
		adim_b.append(_b4_a(0, Callable(), 60, true))
	adim_b.append(_b4_a(1, _b4_x_ge(470.0), 100))
	for i in range(8):
		adim_b.append(_b4_a(0, Callable(), 60, true))
	adim_b.append(_b4_a(1, _b4_x_ge(560.0), 100))
	for i in range(8):
		adim_b.append(_b4_a(0, Callable(), 60, true))
	var sb: Dictionary = await _b5_senaryo([], adim_b)
	var min_b := _b4_ayak_min(sb["iz"])
	var zipladi: bool = min_b < 595.0
	var ok_b: bool = min_b > 470.0 and zipladi and sb["oldu"] == 0 and not _b4_hic(sb["ozel"], "salter")
	_kaydi("Bölüm 5 atlanamaz: zeminden zıplayarak sahanlığa çıkılmaz", ok_b,
		"ayak y min=%.1f (sahanlık üstü 470, beklenen > 470), zıpladı: %s, en uzak x=%.0f, ölüm: %d" % [
			min_b, zipladi, _b5_maks_x(sb["iz"]), sb["oldu"]])

	# c) Işın zıplayarak aşılamaz (ışın y 400..600 tavandan zemine).
	var adim_c: Array = [_b4_a(1, _b4_x_ge(640.0), 150)]
	for i in range(3):
		adim_c.append(_b4_a(1, Callable(), 40, true))
	adim_c.append(_b4_a(1, Callable(), 100))
	var sc: Dictionary = await _b5_senaryo([], adim_c)
	var son_c: Vector2 = sc["iz"][sc["iz"].size() - 1]
	var ok_c: bool = sc["oldu"] == 1 and not sc["bitti"] and son_c.x < 740.0
	_kaydi("Bölüm 5 atlanamaz: ışın zıplayarak aşılamaz", ok_c,
		"ölüm: %d (beklenen 1), son konum (%.0f, %.0f), L1 x=720, bölüm bitti: %s" % [sc["oldu"], son_c.x, son_c.y, sc["bitti"]])
	_kayitlar().sifirla()


## 3) Başarısızlık senaryoları.
func _test_bolum5_basarisizlik() -> void:
	var kay: Array = await _b5_kayitlar()
	var a: Array = kay[0]
	var b: Array = kay[1]
	_kaydi("Bölüm 5 hazırlık: A, B kayıtları üretildi", a.size() > 0 and b.size() > 0,
		"kare sayıları: A %d, B %d" % [a.size(), b.size()])
	var adim_yuru: Array = [_b4_a(1, Callable(), 400)]

	# a) Yalnız A: asansör kalkar, şalteri kimse geri çevirmez, L2'de ölünür.
	var adim_a: Array = [
		_b4_a(1, _b4_x_ge(390.0), 100),
		_b4_a(0, _b4_yukari("Asansor", 480.0), 300),
		_b4_a(1, Callable(), 400)]
	var sa: Dictionary = await _b5_senaryo([a], adim_a)
	var son_a: Vector2 = sa["iz"][sa["iz"].size() - 1]
	var ok_a: bool = not sa["bitti"] and sa["oldu"] == 1 and _b4_hic(sa["ozel"], "plaka") \
		and _b4_en_ust(sa["ozel"], "asansor") <= 480.5 and not sa["tamam"].slice(0, 2).has(false)
	_kaydi("Bölüm 5 başarısızlık: yalnız A (L2'de ölünür)", ok_a,
		"bölüm bitti: %s, ölüm: %d, son konum (%.0f, %.0f) (L2 x=900), asansör y min=%.0f, adımlar: %s" % [
			sa["bitti"], sa["oldu"], son_a.x, son_a.y, _b4_en_ust(sa["ozel"], "asansor"), str(sa["tamam"])])

	# b) A yok, B var: asansör kalkmaz, şalter dönmez, L1'de ölünür.
	var sb: Dictionary = await _b5_senaryo([b], adim_yuru)
	var son_b: Vector2 = sb["iz"][sb["iz"].size() - 1]
	var ok_b: bool = not sb["bitti"] and sb["oldu"] == 1 and _b4_en_ust(sb["ozel"], "asansor") > 609.0 \
		and not _b4_hic(sb["ozel"], "salter") and not _b4_hic(sb["ozel"], "plaka") \
		and son_b.x > 690.0 and son_b.x < 735.0
	_kaydi("Bölüm 5 başarısızlık: A yok, B var (asansör kalkmaz, L1'de ölünür)", ok_b,
		"ölüm: %d, son x=%.0f (L1 x=720), asansör y min=%.0f (aşağı 610), şalter sağda görüldü: %s, plaka basıldı: %s" % [
			sb["oldu"], son_b.x, _b4_en_ust(sb["ozel"], "asansor"), _b4_hic(sb["ozel"], "salter"), _b4_hic(sb["ozel"], "plaka")])

	# c) B yalnız sağa iter, sola dönmez: L1 kapanır ama L2 açık kalır.
	var adim_bsag: Array = [
		_b4_a(1, _b4_x_ge(390.0), 100),
		_b4_a(0, _b4_yukari("Asansor", 480.0), 300),
		_b4_a(1, _b5_salter_sagda(), 100),
		_b4_a(1, _b4_x_ge(590.0), 40),
		_b4_a(0, Callable(), 10)]
	var s_bsag: Dictionary = await _b5_senaryo([a], adim_bsag)
	var b_sag: Array = s_bsag["kayit"]
	var sc: Dictionary = await _b5_senaryo([a, b_sag], _b5_tur3())
	var son_c: Vector2 = sc["iz"][sc["iz"].size() - 1]
	var l1_kapandi := false
	var l2_hep_acik := true
	for o in sc["ozel"]:
		if o["salter"]:
			l1_kapandi = l1_kapandi or not o["l1"]
			l2_hep_acik = l2_hep_acik and o["l2"]
	var ok_c: bool = not sc["bitti"] and sc["oldu"] == 1 and l1_kapandi and l2_hep_acik \
		and son_c.x > 860.0 and son_c.x < 920.0
	_kaydi("Bölüm 5 başarısızlık: B yalnız sağa iter (L2 açık kalır)", ok_c,
		"ölüm: %d, son x=%.0f (L2 x=900), L1 kapandı: %s, şalter sağdayken L2 hep açık: %s, bölüm bitti: %s, adımlar: %s" % [
			sc["oldu"], son_c.x, l1_kapandi, l2_hep_acik, sc["bitti"], str(sc["tamam"])])

	# d) L1'e şalter sağa dönmeden (klonlar sahanlığa varmadan) girmek: ölüm.
	var adim_d: Array = [_b4_a(1, _b4_x_ge(660.0), 150), _b4_a(1, Callable(), 100)]
	var sd: Dictionary = await _b5_senaryo([a, b], adim_d)
	var son_d: Vector2 = sd["iz"][sd["iz"].size() - 1]
	var ok_d: bool = not sd["bitti"] and sd["oldu"] == 1 and son_d.x > 690.0 and son_d.x < 735.0
	_kaydi("Bölüm 5 başarısızlık: L1'e şalter dönmeden girmek ölüm", ok_d,
		"ölüm: %d, son x=%.0f (L1 x=720), %d. karede, bölüm bitti: %s" % [
			sd["oldu"], son_d.x, sd["iz"].size(), sd["bitti"]])
	_kayitlar().sifirla()


## 4) max_klon=2: üçüncü R yeni klon kaydetmez.
func _test_bolum5_klon_siniri() -> void:
	_kayitlar().sifirla()
	var bolum: Node = await _bolumu_yukle()
	var maks: int = bolum.max_klon
	var gecti := maks == 2
	var ayrinti: Array = []
	for n in range(maks + 1):
		for i in range(5):
			_girdi_uygula({"yon": 1.0, "zipla": false})
			await physics_frame
		_girdi_uygula({"yon": 0.0, "zipla": false})
		var eski_id := bolum.get_instance_id()
		await _r_bas()
		var yeni: Node = await _yeni_sahne_bekle(eski_id)
		var sayi: int = _kayitlar().turlar.size()
		if n < maks:
			gecti = gecti and yeni != null and sayi == n + 1
			if yeni == null:
				break
			bolum = yeni
		else:
			var yazi: String = bolum.bilgi.text
			gecti = gecti and yeni == null and sayi == maks and yazi.contains("Klon hakkı bitti") \
				and yazi.contains("2/2")
			ayrinti.append("sınırda etiket: \"%s\"" % yazi)
		ayrinti.append("R #%d -> kayıtlı klon: %d" % [n + 1, sayi])
	_kaydi("Bölüm 5: klon sınırı (üçüncü R klon kaydetmez)", gecti, "max_klon=%d; %s" % [maks, ", ".join(ayrinti)])
	_kayitlar().sifirla()


## 5) Şalter kalıcılığı: klon itip sahanlığın ucuna uzaklaşınca şalter sağda kalır.
func _test_bolum5_salter_kalici() -> void:
	var a: Array = (await _b5_kayitlar())[0]
	var adim_k: Array = [
		_b4_a(1, _b4_x_ge(390.0), 100),
		_b4_a(0, _b4_yukari("Asansor", 480.0), 300),
		_b4_a(1, _b5_salter_sagda(), 100),
		_b4_a(1, _b4_x_ge(632.0), 60),
		_b4_a(0, Callable(), 120)]
	var sk: Dictionary = await _b5_senaryo([a], adim_k)
	var kl: Array = sk["kayit"]
	# Oyuncu hareket etmez; yalnız bu klon çalışır.
	var s: Dictionary = await _b5_senaryo([a, kl], [_b4_a(0, Callable(), 420)])
	var gecis := 0
	var ilk := -1
	for f in range(1, s["ozel"].size()):
		if s["ozel"][f]["salter"] != s["ozel"][f - 1]["salter"]:
			gecis += 1
			if ilk < 0:
				ilk = f
	var klon_iz: Array = s["klon_izleri"][1]
	var uzaklasti := false
	var uzak_sonra_sagda := true
	for f in range(maxi(ilk, 0), klon_iz.size()):
		if klon_iz[f].x >= 626.0:
			uzaklasti = true
		if uzaklasti and not s["ozel"][f]["salter"]:
			uzak_sonra_sagda = false
	var son: Dictionary = s["ozel"][s["ozel"].size() - 1]
	var ok: bool = gecis == 1 and uzaklasti and uzak_sonra_sagda and son["salter"] \
		and not son["l1"] and son["l2"] and s["oldu"] == 0
	_kaydi("Bölüm 5: şalter kalıcılığı (klon itip uzaklaşınca durum kalır)", ok,
		"geçiş sayısı: %d (beklenen 1) @kare %d, klon x>=626'ya uzaklaştı: %s, sonra hep sağda: %s, sonda L1 kapalı: %s, L2 açık: %s, klon son x=%.0f" % [
			gecis, ilk, uzaklasti, uzak_sonra_sagda, not son["l1"], son["l2"], klon_iz[klon_iz.size() - 1].x])
	_kayitlar().sifirla()


## Denetçi uyarısı: oyuncu plakada E1 tepedeyken bekler, plakadan ayrılıp E1'e koşarak zıplar.
## Plakadan ayrılınca E1 iner (130 px, ~65 kare); oyuncu E1'e ~58 karede varır, E1 dibe yakındır.
## İlk zıplama zamanı taranır, ardından tekrarlı zıplama denenir; ayak y > 470 kalmalı.
func _test_bolum5_erken_ayrilma() -> void:
	var en_kucuk := 1.0e9
	var en_n := -1
	var salter := false
	var e1_tepede := true
	for n in range(0, 100, 2):
		var ad: Array = [
			_b4_a(-1, _b4_x_le(40.0), 60),
			_b4_a(0, _b4_yukari("Asansor", 480.0), 120)]
		if n > 0:
			ad.append(_b4_a(1, Callable(), n))
		for i in range(28):
			ad.append(_b4_a(1, Callable(), 1, true))
			ad.append(_b4_a(1, Callable(), 1))
		var s: Dictionary = await _b5_senaryo([], ad)
		e1_tepede = e1_tepede and s["tamam"][1]
		var m := _b4_ayak_min(s["iz"], s["baslangic"][2])
		salter = salter or _b4_hic(s["ozel"], "salter")
		if m < en_kucuk:
			en_kucuk = m
			en_n = n
	var ok: bool = e1_tepede and en_kucuk > 470.0 and en_kucuk < 595.0 and not salter
	_kaydi("Bölüm 5: plakada bekleyip E1'e koşarak sahanlığa çıkılamaz (zıplama zamanı taraması)", ok,
		"E1 her denemede tepeye çıktı: %s, ayak y min=%.1f (sahanlık üstü 470; pay %.1f px) @bekleme %d kare, şalter hiç dönmedi: %s" % [
			e1_tepede, en_kucuk, en_kucuk - 470.0, en_n, not salter])
	_kayitlar().sifirla()


## 6) Determinizm: 3. turun kaydı 100 kez, her karede aynı iz ve hep kapıya ulaşır.
func _test_bolum5_determinizm() -> void:
	var kay: Array = await _b5_kayitlar()
	var s0: Dictionary = await _b5_senaryo(kay, _b5_tur3())
	var betik: Array = s0["kayit"]
	var ornek := func(b: Node) -> Dictionary: return _b5_ornekle(b)
	var referans: Dictionary = {}
	var sapmali := 0
	var bitmeyen := 0
	var maks_sapma := 0.0
	for n in range(TEKRAR):
		var s: Dictionary = await _senaryo(kay, betik, 700, Callable(), ornek)
		if not s["bitti"]:
			bitmeyen += 1
		if n == 0:
			referans = s
			continue
		var bu: bool = s["ozel_iz"].size() != referans["ozel_iz"].size() or s["kare"] != referans["kare"]
		for f in range(mini(s["ozel_iz"].size(), referans["ozel_iz"].size())):
			if s["ozel_iz"][f] != referans["ozel_iz"][f]:
				bu = true
			var d: float = (s["oyuncu_iz"][f] - referans["oyuncu_iz"][f]).length()
			for ki in range(2):
				d = maxf(d, (s["klon_izleri"][ki][f] - referans["klon_izleri"][ki][f]).length())
			if d > 0.0:
				bu = true
				maks_sapma = maxf(maks_sapma, d)
		if bu:
			sapmali += 1
	_kaydi("Bölüm 5: determinizm (100x çözüm)", sapmali == 0 and bitmeyen == 0 and s0["bitti"],
		"%d çalıştırma x %d kare, sapmalı: %d, en büyük sapma: %.4f px, bitirmeyen çalıştırma: %d, kayıt turu bitti: %s" % [
			TEKRAR, referans["kare"], sapmali, maks_sapma, bitmeyen, s0["bitti"]])
	_kayitlar().sifirla()
	paused = false


# ---------------------------------------------------------------- Bölüm 6 testleri
# Taslak: docs/devir/bolum_6_taslak.md ("Nöbetçi Geçit"). max_klon=2, geçit (VEYA) + lazer + asansör.
# Betikler sabit kareye değil KOŞULA (plaka basılı, geçit açıklığı, lazer kapalı, asansör üstte,
# x eşikleri) bağlıdır. Ölüm: oyuncu_oldu sinyali sayılır.

const BOLUM_6 := "res://scenes/bolumler/bolum_6.tscn"
const B6_GECIT_KAPALI_Y := 500.0
const B6_GECIT_ACIK_Y := 300.0
const B6_ASANSOR_UST_Y := 530.0   # merkez; üst yüzey 520

var _b6_onbellek: Array = []   # [A, B] kayıtları


func _b6_ornekle(b: Node) -> Dictionary:
	return {
		"asansor": b.get_node("Asansor").position.y, "pa": b.get_node("PlakaA").basili_mi(),
		"pl": b.get_node("PlakaL").basili_mi(), "lazer": b.get_node("Lazer").acik_mi(),
		"kapali": not b.get_node("Lazer").acik_mi(),
		"gecit": b.get_node("Gecit").position.y}


func _b6_lazer_kapali() -> Callable:
	return func(b: Node) -> bool: return not b.get_node("Lazer").acik_mi()


func _b6_pl_basili() -> Callable:
	return func(b: Node) -> bool: return b.get_node("PlakaL").basili_mi()


func _b6_tur1() -> Array:
	return [_b4_a(-1, _b4_x_le(40.0), 60), _b4_a(0, Callable(), 10)]


func _b6_tur2() -> Array:
	return [_b4_a(1, _b4_x_ge(660.0), 250), _b4_a(0, _b6_pl_basili(), 40), _b4_a(0, Callable(), 12)]


## Oyuncu: ışına kadar yürü, lazer kapanana kadar bekle, asansör üstte olunca iki ardışık zıpla.
## Ölçüm: ilk zıplama x<=800'de çalışır (810'da baş asansörün altına çarpar; taslaktaki x~800 sınırda).
## Bu yüzden orta güvenli bölge x=740 seçildi.
func _b6_tur3(zipla_x := 740.0) -> Array:
	return [
		_b4_a(1, _b4_x_ge(700.0), 250),
		_b4_a(0, _b6_lazer_kapali(), 150),
		_b4_a(1, _b4_x_ge(zipla_x), 100),
		_b4_a(0, _b4_yukari("Asansor", B6_ASANSOR_UST_Y), 120),
		_b4_a(1, _b4_durdu(500.0, 835.0), 60, true),      # 1. zıplama: asansör üstüne
		_b4_a(1, _b4_durdu(500.0, 900.0), 80),
		_b4_a(1, Callable(), 40, true),                   # 2. zıplama: sekiye
		_b4_a(1, _b4_bitti_k(), 200)]


func _b6_kosullu(bolum: Node, adimlar: Array, sayac: Array) -> Dictionary:
	var oyuncu: CharacterBody2D = bolum.get_node("Oyuncu")
	var klonlar: Array = _klonlar(bolum)
	var klon_iz: Array = []
	for k in klonlar:
		klon_iz.append([])
	var iz: Array = []
	var ozel: Array = []
	var baslangic: Array = []
	var tamam: Array = []
	var kare := 0
	for a in adimlar:
		baslangic.append(iz.size())
		var n := 0
		var karsilandi: bool = not a["kosul"].is_valid()
		while n < a["maks"]:
			if not is_instance_valid(bolum) or bolum.bitti:
				break
			_girdi_uygula({"yon": a["yon"], "zipla": a["zipla"] and n == 0})
			iz.append(oyuncu.global_position)
			ozel.append(_b6_ornekle(bolum))
			for i in range(klonlar.size()):
				klon_iz[i].append(klonlar[i].global_position)
			await physics_frame
			n += 1
			kare += 1
			if a["kosul"].is_valid() and is_instance_valid(bolum) and a["kosul"].call(bolum):
				karsilandi = true
				break
		tamam.append(karsilandi)
		if not is_instance_valid(bolum) or bolum.bitti:
			break
	_girdi_uygula({"yon": 0.0, "zipla": false})
	var bitti_son: bool = is_instance_valid(bolum) and bolum.bitti
	var kayit: Array = []
	if is_instance_valid(oyuncu):
		kayit = oyuncu.kayit_girdileri.duplicate(true)
	for i in range(3):
		await physics_frame
	return {"kare": kare, "bitti": bitti_son and sayac[0] == 0, "oldu": sayac[0], "iz": iz, "ozel": ozel,
		"klon_izleri": klon_iz, "baslangic": baslangic, "tamam": tamam, "kayit": kayit}


func _b6_senaryo(kayitlar: Array, adimlar: Array, hazirlik := Callable()) -> Dictionary:
	_kayitlar().sifirla()
	for k in kayitlar:
		_kayitlar().tur_kaydet(k.duplicate(true))
	var bolum: Node = await _bolumu_yukle()
	if hazirlik.is_valid():
		hazirlik.call(bolum)
	var sayac := [0]
	bolum.get_node("Oyuncu").oyuncu_oldu.connect(func() -> void: sayac[0] += 1)
	var s: Dictionary = await _b6_kosullu(bolum, adimlar, sayac)
	paused = false
	return s


func _b6_kayitlar() -> Array:
	if _b6_onbellek.is_empty():
		var s1: Dictionary = await _b6_senaryo([], _b6_tur1())
		var s2: Dictionary = await _b6_senaryo([s1["kayit"]], _b6_tur2())
		_b6_onbellek = [s1["kayit"], s2["kayit"]]
	return _b6_onbellek


func _b6_en_buyuk(ozel: Array, anahtar: String) -> float:
	var m := -1.0e9
	for o in ozel:
		m = maxf(m, o[anahtar])
	return m


## 1) Gerçek yol: R ile 2 klon, 3. turda kapıya.
func _test_bolum6_cozum() -> void:
	_kayitlar().sifirla()
	var bolum: Node = await _bolumu_yukle()
	var turlar: Array = [_b6_tur1(), _b6_tur2()]
	var kareler: Array = []
	var olumsuz := ""
	for i in range(2):
		var sayac := [0]
		bolum.get_node("Oyuncu").oyuncu_oldu.connect(func() -> void: sayac[0] += 1)
		var s: Dictionary = await _b6_kosullu(bolum, turlar[i], sayac)
		kareler.append(s["kare"])
		if s["tamam"].has(false) or s["oldu"] > 0:
			olumsuz += " tur%d adım karşılanmadı %s oldu=%d;" % [i + 1, str(s["tamam"]), s["oldu"]]
		var eski_id := bolum.get_instance_id()
		await _r_bas()
		bolum = await _yeni_sahne_bekle(eski_id)
		if bolum == null:
			_kaydi("Bölüm 6 çözümü (3 tur, gerçek R/girdi yolu)", false, "tur %d sonrası sahne yüklenmedi;%s" % [i + 1, olumsuz])
			return
	var klon_basta: int = _klonlar(bolum).size()
	var etiket: String = bolum.bilgi.text
	var sayac3 := [0]
	bolum.get_node("Oyuncu").oyuncu_oldu.connect(func() -> void: sayac3[0] += 1)
	var s3: Dictionary = await _b6_kosullu(bolum, _b6_tur3(), sayac3)
	if s3["tamam"].has(false):
		olumsuz += " tur3 adım karşılanmadı %s;" % str(s3["tamam"])
	var gecti: bool = s3["bitti"] and klon_basta == 2 and _kayitlar().turlar.size() == 2 \
		and etiket.contains("Klon: 2/2") and etiket.contains("Klon hakkı bitti") \
		and olumsuz == "" and s3["kare"] <= 600
	_kaydi("Bölüm 6 çözümü (3 tur, gerçek R/girdi yolu)", gecti,
		"bölüm bitti: %s, tur kareleri: %s + %d (%.2f sn), klon: %d, kayıtlı tur: %d, ölüm: %d, etiket: \"%s\", geçit y min=%.0f (açık 300), asansör y min=%.0f (hedef 530), lazer kapalı görüldü: %s, adım başlangıçları: %s%s" % [
			s3["bitti"], str(kareler), s3["kare"], s3["kare"] / 60.0, klon_basta, _kayitlar().turlar.size(),
			s3["oldu"], etiket, _b4_en_ust(s3["ozel"], "gecit"), _b4_en_ust(s3["ozel"], "asansor"),
			_b4_hic(s3["ozel"], "kapali"), str(s3["baslangic"]), olumsuz])
	_kayitlar().sifirla()
	paused = false


## 2) Atlanamazlık.
func _test_bolum6_atlanamaz() -> void:
	# a) Klonsuz sprint: PlakaA'da 100 kare bekle, sağa koş; geçitte sıkışır.
	var sa: Dictionary = await _b6_senaryo([], [_b4_a(-1, _b4_x_le(40.0), 60), _b4_a(0, Callable(), 100), _b4_a(1, Callable(), 300)])
	var maks_x: float = _b5_maks_x(sa["iz"])
	var bas_ust: float = sa["iz"][sa["iz"].size() - 1].y - 24.0
	var gecit_alt: float = sa["ozel"][sa["ozel"].size() - 1]["gecit"] + 100.0
	var ok_a: bool = not sa["bitti"] and sa["oldu"] == 0 and maks_x < 562.0 and gecit_alt > bas_ust
	_kaydi("Bölüm 6 atlanamaz: klonsuz sprint geçitte sıkışır", ok_a,
		"en uzak x=%.1f (geçit sol kenarı 570, beklenen < 562), son kare geçit alt kenarı y=%.0f > baş üstü y=%.0f: %s, geçit y min=%.0f, bölüm bitti: %s, ölüm: %d" % [
			maks_x, gecit_alt, bas_ust, gecit_alt > bas_ust, _b4_en_ust(sa["ozel"], "gecit"), sa["bitti"], sa["oldu"]])

	# b) Asansör aşağıdayken yerinde zıplayarak seki'ye çıkılmaz (oyuncu asansör kolonuna ışınlanır).
	var hazir := func(b: Node) -> void: b.get_node("Oyuncu").global_position = Vector2(930.0, 576.0)
	var adim_b: Array = []
	for i in range(8):
		adim_b.append(_b4_a(0, Callable(), 60, true))
	var sb: Dictionary = await _b6_senaryo([], adim_b, hazir)
	var min_b := _b4_ayak_min(sb["iz"])
	var zipladi_b: bool = min_b < 595.0
	var asansor_asagi: bool = _b4_en_ust(sb["ozel"], "asansor") > 609.0
	var ok_b: bool = min_b > 450.0 and zipladi_b and asansor_asagi and not sb["bitti"] and sb["oldu"] == 0
	_kaydi("Bölüm 6 atlanamaz: asansör aşağıdayken seki'ye zeminden çıkılmaz", ok_b,
		"ayak y min=%.1f (seki üstü 450, taslak ~499), zıpladı: %s, asansör hiç kalkmadı: %s (y min=%.0f), bölüm bitti: %s" % [
			min_b, zipladi_b, asansor_asagi, _b4_en_ust(sb["ozel"], "asansor"), sb["bitti"]])

	# c) Oyuncu PlakaL'e kendisi basar (A klonu geçidi açar): ışın kapanır ama plakadan inince geri gelir.
	var adim_c: Array = [
		_b4_a(1, _b4_x_ge(660.0), 250),
		_b4_a(0, _b4_yukari("Asansor", B6_ASANSOR_UST_Y), 120),
		_b4_a(1, Callable(), 300)]
	var kay: Array = await _b6_kayitlar()
	var sc: Dictionary = await _b6_senaryo([kay[0]], adim_c)
	var son_c: Vector2 = sc["iz"][sc["iz"].size() - 1]
	var ok_c: bool = not sc["bitti"] and sc["oldu"] == 1 and not sc["tamam"].slice(0, 2).has(false) \
		and _b4_en_ust(sc["ozel"], "asansor") <= B6_ASANSOR_UST_Y + 0.5 and son_c.x < 770.0
	_kaydi("Bölüm 6 atlanamaz: oyuncu kendi PlakaL'ine basıp ışını geçemez", ok_c,
		"ölüm: %d (beklenen 1), son konum (%.0f, %.0f) (ışın x=760), asansör y min=%.0f, adımlar: %s, bölüm bitti: %s" % [
			sc["oldu"], son_c.x, son_c.y, _b4_en_ust(sc["ozel"], "asansor"), str(sc["tamam"]), sc["bitti"]])
	_kayitlar().sifirla()


## 3) Başarısızlık senaryoları (taslak 2..7).
func _test_bolum6_basarisizlik() -> void:
	var kay: Array = await _b6_kayitlar()
	var a: Array = kay[0]
	var b: Array = kay[1]
	_kaydi("Bölüm 6 hazırlık: A, B kayıtları üretildi", a.size() > 0 and b.size() > 0,
		"kare sayıları: A %d, B %d" % [a.size(), b.size()])
	var yuru: Array = [_b4_a(1, Callable(), 400)]

	# 2) Yalnız A: geçit açılır, PlakaL basılmaz, ışında ölünür.
	var s2: Dictionary = await _b6_senaryo([a], yuru)
	var son2: Vector2 = s2["iz"][s2["iz"].size() - 1]
	var ok2: bool = not s2["bitti"] and s2["oldu"] == 1 and son2.x > 735.0 and son2.x < 790.0
	_kaydi("Bölüm 6 başarısızlık 2: yalnız A (ışında ölünür)", ok2,
		"ölüm: %d, son x=%.0f (ışın 760), geçit y min=%.0f (açıldı), bölüm bitti: %s" % [
			s2["oldu"], son2.x, _b4_en_ust(s2["ozel"], "gecit"), s2["bitti"]])

	# 3) A kaydı boş: geçit açılmaz, B geçitte takılır, oyuncu da geçemez.
	var s3: Dictionary = await _b6_senaryo([[], b], yuru)
	var ok3: bool = not s3["bitti"] and s3["oldu"] == 0 and _b4_en_ust(s3["ozel"], "gecit") > 499.0 \
		and not _b4_hic(s3["ozel"], "pl") and _b5_maks_x(s3["iz"]) < 562.0 \
		and _b5_maks_x(s3["klon_izleri"][1]) < 562.0
	_kaydi("Bölüm 6 başarısızlık 3: A kaydı boş (B geçitte takılır)", ok3,
		"geçit y min=%.0f (kapalı 500), PlakaL hiç basılmadı: %s, oyuncu en uzak x=%.0f, klon B en uzak x=%.0f, bölüm bitti: %s" % [
			_b4_en_ust(s3["ozel"], "gecit"), not _b4_hic(s3["ozel"], "pl"), _b5_maks_x(s3["iz"]),
			_b5_maks_x(s3["klon_izleri"][1]), s3["bitti"]])

	# 4) A erken ayrılır (10 kare bekle sonra sağa): geçit kapanır, B takılır.
	var s_erken: Dictionary = await _b6_senaryo([], [_b4_a(-1, _b4_x_le(40.0), 60), _b4_a(0, Callable(), 10), _b4_a(1, Callable(), 30)])
	var s4: Dictionary = await _b6_senaryo([s_erken["kayit"], b], yuru)
	var ok4: bool = not s4["bitti"] and s4["oldu"] == 0 and not _b4_hic(s4["ozel"], "pl") \
		and _b5_maks_x(s4["klon_izleri"][1]) < 562.0
	_kaydi("Bölüm 6 başarısızlık 4: A erken ayrılır (geçit kapanır, B takılır)", ok4,
		"geçit en açık y=%.0f, PlakaL hiç basılmadı: %s, klon B en uzak x=%.0f, oyuncu en uzak x=%.0f, bölüm bitti: %s" % [
			_b4_en_ust(s4["ozel"], "gecit"), not _b4_hic(s4["ozel"], "pl"), _b5_maks_x(s4["klon_izleri"][1]),
			_b5_maks_x(s4["iz"]), s4["bitti"]])

	# 5) B plaka dışında (x~735): lazer açık kalır, oyuncu ölür.
	var s_bdis: Dictionary = await _b6_senaryo([a], [_b4_a(1, _b4_x_ge(735.0), 250), _b4_a(0, Callable(), 12)])
	var s5: Dictionary = await _b6_senaryo([a, s_bdis["kayit"]], [_b4_a(1, Callable(), 300)])
	var son5: Vector2 = s5["iz"][s5["iz"].size() - 1]
	var ok5: bool = not s5["bitti"] and s5["oldu"] == 1 and son5.x > 735.0 and son5.x < 790.0
	_kaydi("Bölüm 6 başarısızlık 5: B plaka dışında (ışında ölünür)", ok5,
		"oyuncu ölüm: %d, son x=%.0f (ışın 760), bölüm bitti: %s" % [s5["oldu"], son5.x, s5["bitti"]])

	# 6) B yön hatası (sola yürür): PlakaL klon tarafından basılmaz, oyuncu ışında ölür.
	var s_byon: Dictionary = await _b6_senaryo([a], [_b4_a(-1, Callable(), 120)])
	var s6: Dictionary = await _b6_senaryo([a, s_byon["kayit"]], [_b4_a(1, Callable(), 300)])
	var pl_once := false   # oyuncu plakaya varmadan (x<610) PlakaL basılmamalı
	for f in range(s6["iz"].size()):
		if s6["iz"][f].x < 610.0 and s6["ozel"][f]["pl"]:
			pl_once = true
	var ok6: bool = not s6["bitti"] and s6["oldu"] == 1 and not pl_once
	_kaydi("Bölüm 6 başarısızlık 6: B yön hatası (PlakaL basılmaz)", ok6,
		"oyuncu ölüm: %d, oyuncu plakaya varmadan PlakaL basıldı: %s (beklenen false), bölüm bitti: %s" % [
			s6["oldu"], pl_once, s6["bitti"]])

	# 7) Asansör aşağıdayken koşarak zıplama: seki'ye ulaşılmaz.
	var hazir := func(bb: Node) -> void: bb.get_node("Oyuncu").global_position = Vector2(800.0, 576.0)
	var adim7: Array = []
	for i in range(12):
		adim7.append(_b4_a(1, Callable(), 20, true))
	var s7: Dictionary = await _b6_senaryo([], adim7, hazir)
	var min7 := _b4_ayak_min(s7["iz"])
	var ok7: bool = min7 > 450.0 and min7 < 595.0 and not s7["bitti"] and s7["oldu"] == 0 \
		and _b4_en_ust(s7["ozel"], "asansor") > 609.0
	_kaydi("Bölüm 6 başarısızlık 7: asansör aşağıdayken zıplama seki'ye ulaşmaz", ok7,
		"ayak y min=%.1f (seki üstü 450, taslak ~499), asansör y min=%.0f (aşağı 610), son x=%.0f, bölüm bitti: %s" % [
			min7, _b4_en_ust(s7["ozel"], "asansor"), s7["iz"][s7["iz"].size() - 1].x, s7["bitti"]])
	_kayitlar().sifirla()


## 4) max_klon=2.
func _test_bolum6_klon_siniri() -> void:
	_kayitlar().sifirla()
	var bolum: Node = await _bolumu_yukle()
	var maks: int = bolum.max_klon
	var gecti := maks == 2
	var ayrinti: Array = []
	for n in range(maks + 1):
		for i in range(5):
			_girdi_uygula({"yon": 1.0, "zipla": false})
			await physics_frame
		_girdi_uygula({"yon": 0.0, "zipla": false})
		var eski_id := bolum.get_instance_id()
		await _r_bas()
		var yeni: Node = await _yeni_sahne_bekle(eski_id)
		var sayi: int = _kayitlar().turlar.size()
		if n < maks:
			gecti = gecti and yeni != null and sayi == n + 1
			if yeni == null:
				break
			bolum = yeni
		else:
			var yazi: String = bolum.bilgi.text
			gecti = gecti and yeni == null and sayi == maks and yazi.contains("Klon hakkı bitti") \
				and yazi.contains("2/2")
			ayrinti.append("sınırda etiket: \"%s\"" % yazi)
		ayrinti.append("R #%d -> kayıtlı klon: %d" % [n + 1, sayi])
	_kaydi("Bölüm 6: klon sınırı (üçüncü R klon kaydetmez)", gecti, "max_klon=%d; %s" % [maks, ", ".join(ayrinti)])
	_kayitlar().sifirla()


## 5) VEYA: PlakaL basılıyken A plakadan ayrılsa da geçit açık kalır; B yoksa kapanır.
func _test_bolum6_veya() -> void:
	var a_gec: Dictionary = await _b6_senaryo([], [_b4_a(-1, _b4_x_le(40.0), 60), _b4_a(0, Callable(), 150), _b4_a(1, Callable(), 40)])
	var b_g: Dictionary = await _b6_senaryo([a_gec["kayit"]], _b6_tur2())
	var s: Dictionary = await _b6_senaryo([a_gec["kayit"], b_g["kayit"]], [_b4_a(0, Callable(), 340)])
	var oz: Array = s["ozel"]
	var f_l := -1
	var f_ayril := -1
	for f in range(oz.size()):
		if f_l < 0 and oz[f]["pl"]:
			f_l = f
		if f_l >= 0 and f_ayril < 0 and not oz[f]["pa"]:
			f_ayril = f
	var yalniz_l := 0
	var kapanma := false
	if f_ayril >= 0:
		for f in range(f_ayril, oz.size()):
			if oz[f]["pl"] and not oz[f]["pa"]:
				yalniz_l += 1
				if oz[f]["gecit"] > B6_GECIT_ACIK_Y + 0.01:
					kapanma = true
	var ok_veya: bool = f_l >= 0 and f_ayril > f_l and yalniz_l > 30 and not kapanma
	# Kontrol: B yok -> A ayrılınca geçit kapanır.
	var sk: Dictionary = await _b6_senaryo([a_gec["kayit"]], [_b4_a(0, Callable(), 340)])
	var son_k: float = sk["ozel"][sk["ozel"].size() - 1]["gecit"]
	var ok_k: bool = son_k > B6_GECIT_KAPALI_Y - 0.01
	_kaydi("Bölüm 6: VEYA mantığı (PlakaL basılıyken A ayrılsa da geçit açık)", ok_veya and ok_k,
		"PlakaL ilk basılış karesi=%d, A'nın ayrıldığı kare=%d, yalnız PlakaL basılı kare sayısı=%d, o sırada geçit kapanmaya başladı: %s, geçit son y=%.0f; kontrol (B yok): son y=%.0f (kapalı 500)" % [
			f_l, f_ayril, yalniz_l, kapanma, oz[oz.size() - 1]["gecit"], son_k])
	_kayitlar().sifirla()


## 6) Determinizm: 3. turun kaydı 100 kez.
func _test_bolum6_determinizm() -> void:
	var kay: Array = await _b6_kayitlar()
	var s0: Dictionary = await _b6_senaryo(kay, _b6_tur3())
	var betik: Array = s0["kayit"]
	var ornek := func(b: Node) -> Dictionary: return _b6_ornekle(b)
	var referans: Dictionary = {}
	var sapmali := 0
	var bitmeyen := 0
	var maks_sapma := 0.0
	for n in range(TEKRAR):
		var s: Dictionary = await _senaryo(kay, betik, 700, Callable(), ornek)
		if not s["bitti"]:
			bitmeyen += 1
		if n == 0:
			referans = s
			continue
		var bu: bool = s["ozel_iz"].size() != referans["ozel_iz"].size() or s["kare"] != referans["kare"]
		for f in range(mini(s["ozel_iz"].size(), referans["ozel_iz"].size())):
			if s["ozel_iz"][f] != referans["ozel_iz"][f]:
				bu = true
			var d: float = (s["oyuncu_iz"][f] - referans["oyuncu_iz"][f]).length()
			for ki in range(2):
				d = maxf(d, (s["klon_izleri"][ki][f] - referans["klon_izleri"][ki][f]).length())
			if d > 0.0:
				bu = true
				maks_sapma = maxf(maks_sapma, d)
		if bu:
			sapmali += 1
	_kaydi("Bölüm 6: determinizm (100x çözüm)", sapmali == 0 and bitmeyen == 0 and s0["bitti"],
		"%d çalıştırma x %d kare, sapmalı: %d, en büyük sapma: %.4f px, bitirmeyen çalıştırma: %d, kayıt turu bitti: %s" % [
			TEKRAR, referans["kare"], sapmali, maks_sapma, bitmeyen, s0["bitti"]])
	_kayitlar().sifirla()
	paused = false


# ---------------------------------------------------------------- Bölüm 7 testleri
# Taslak: docs/devir/bolum_7_taslak.md ("Üç Anahtar"). max_klon=3: A (PlakaA/asansör), Z (PlakaB/L1),
# Y (PlakaC/L2) + oyuncu. Betikler KOŞULA bağlıdır (asansör üstte, plaka basılı, x eşikleri).
# Ölüm: oyuncu_oldu sinyali sayılır; klonun ölümü klon.oldu ile okunur.

const BOLUM_7 := "res://scenes/bolumler/bolum_7.tscn"
const B7_ASANSOR_UST_Y := 390.0   # taslak: asansör position.y <= 390 olunca F2'ye geçilir

var _b7_onbellek: Array = []   # [A, Z, Y]


func _b7_ornekle(b: Node) -> Dictionary:
	return {
		"asansor": b.get_node("Asansor").position.y, "gecit": b.get_node("Gecit").position.y,
		"salter": b.get_node("Salter").sagda,
		"pa": b.get_node("PlakaA").basili_mi(), "pb": b.get_node("PlakaB").basili_mi(),
		"pc": b.get_node("PlakaC").basili_mi(),
		"l1": b.get_node("Lazer1").acik_mi(), "l2": b.get_node("Lazer2").acik_mi()}


func _b7_plaka(ad: String) -> Callable:
	return func(b: Node) -> bool: return b.get_node(ad).basili_mi()


## Tur 1: A. Bekle, PlakaA'ya (x<=70) yürü ve orada kal.
func _b7_tur1(bekle := 170) -> Array:
	return [_b4_a(0, Callable(), bekle), _b4_a(-1, _b4_x_le(70.0), 60), _b4_a(0, Callable(), 10)]


## Ortak yol: sağa koş (şalter, geçit), x>=900'de asansörü bekle (position.y <= 390).
func _b7_yukari() -> Array:
	return [_b4_a(1, _b4_x_ge(900.0), 250),
		_b4_a(0, _b4_yukari("Asansor", B7_ASANSOR_UST_Y), 400)]


## Tur 2: Z. F2'de sola, PlakaB'ye (x=700) basıp kal.
func _b7_tur2(durak_x := 700.0, plaka_bekle := true) -> Array:
	var a: Array = _b7_yukari() + [_b4_a(-1, _b4_x_le(durak_x), 300)]
	if plaka_bekle:
		a.append(_b4_a(0, _b7_plaka("PlakaB"), 60))
	a.append(_b4_a(0, Callable(), 10))
	return a


## Tur 3: Y. PlakaB'yi geçip PlakaC'ye (x=500) basıp kal.
func _b7_tur3() -> Array:
	return _b7_yukari() + [_b4_a(-1, _b4_x_le(500.0), 400), _b4_a(0, _b7_plaka("PlakaC"), 60),
		_b4_a(0, Callable(), 10)]


## Tur 4: oyuncu. F2'de sola kapıya (bölüm biter).
func _b7_tur4() -> Array:
	return _b7_yukari() + [_b4_a(-1, _b4_bitti_k(), 400)]


func _b7_kosullu(bolum: Node, adimlar: Array, sayac: Array) -> Dictionary:
	var oyuncu: CharacterBody2D = bolum.get_node("Oyuncu")
	var klonlar: Array = _klonlar(bolum)
	var klon_iz: Array = []
	for k in klonlar:
		klon_iz.append([])
	var iz: Array = []
	var ozel: Array = []
	var baslangic: Array = []
	var tamam: Array = []
	var kare := 0
	for a in adimlar:
		baslangic.append(iz.size())
		var n := 0
		var karsilandi: bool = not a["kosul"].is_valid()
		while n < a["maks"]:
			if not is_instance_valid(bolum) or bolum.bitti:
				break
			_girdi_uygula({"yon": a["yon"], "zipla": a["zipla"] and n == 0})
			iz.append(oyuncu.global_position)
			ozel.append(_b7_ornekle(bolum))
			for i in range(klonlar.size()):
				klon_iz[i].append(klonlar[i].global_position)
			await physics_frame
			n += 1
			kare += 1
			if a["kosul"].is_valid() and is_instance_valid(bolum) and a["kosul"].call(bolum):
				karsilandi = true
				break
		tamam.append(karsilandi)
		if not is_instance_valid(bolum) or bolum.bitti:
			break
	_girdi_uygula({"yon": 0.0, "zipla": false})
	var bitti_son: bool = is_instance_valid(bolum) and bolum.bitti
	var kayit: Array = []
	if is_instance_valid(oyuncu):
		kayit = oyuncu.kayit_girdileri.duplicate(true)
	var klon_oldu: Array = []
	for k in klonlar:
		klon_oldu.append(is_instance_valid(k) and k.oldu)
	for i in range(3):
		await physics_frame
	return {"kare": kare, "bitti": bitti_son and sayac[0] == 0, "oldu": sayac[0], "iz": iz, "ozel": ozel,
		"klon_izleri": klon_iz, "baslangic": baslangic, "tamam": tamam, "kayit": kayit,
		"klon_oldu": klon_oldu}


func _b7_senaryo(kayitlar: Array, adimlar: Array, hazirlik := Callable()) -> Dictionary:
	_kayitlar().sifirla()
	for k in kayitlar:
		_kayitlar().tur_kaydet(k.duplicate(true))
	var bolum: Node = await _bolumu_yukle()
	if hazirlik.is_valid():
		hazirlik.call(bolum)
	var sayac := [0]
	bolum.get_node("Oyuncu").oyuncu_oldu.connect(func() -> void: sayac[0] += 1)
	var s: Dictionary = await _b7_kosullu(bolum, adimlar, sayac)
	paused = false
	return s


## [A, Z, Y] kayıtları (gerçek bölümde, önceki klonlarla ardışık kaydedilir).
func _b7_kayitlar() -> Array:
	if _b7_onbellek.is_empty():
		var s1: Dictionary = await _b7_senaryo([], _b7_tur1())
		var s2: Dictionary = await _b7_senaryo([s1["kayit"]], _b7_tur2())
		var s3: Dictionary = await _b7_senaryo([s1["kayit"], s2["kayit"]], _b7_tur3())
		_b7_onbellek = [s1["kayit"], s2["kayit"], s3["kayit"]]
	return _b7_onbellek


func _b7_min(ozel: Array, anahtar: String) -> float:
	var m := 1.0e9
	for o in ozel:
		m = minf(m, o[anahtar])
	return m


## Oyuncunun asansör beklediği evreye (sola dönüşten önce) kadar olan örneklerde en küçük değer.
## Sonraki evrede oyuncu zeminde PlakaA'ya yürür; bu, asansörü meşru olarak kaldırır.
func _b7_min_bekleme(s: Dictionary, anahtar: String) -> float:
	var son: int = s["baslangic"][2] if s["baslangic"].size() > 2 else s["ozel"].size()
	return _b7_min(s["ozel"].slice(0, son), anahtar)


func _b7_hic(ozel: Array, anahtar: String) -> bool:
	for o in ozel:
		if o[anahtar]:
			return true
	return false


func _b7_hic_degil(ozel: Array, anahtar: String) -> bool:
	for o in ozel:
		if not o[anahtar]:
			return true
	return false


func _b7_klon_min_x(s: Dictionary, i: int) -> float:
	var m := 1.0e9
	for f in range(150, s["klon_izleri"][i].size()):   # doğma konumunu (x=100) atla
		m = minf(m, s["klon_izleri"][i][f].x)
	return m


func _b7_son_x(s: Dictionary) -> float:
	return s["iz"][s["iz"].size() - 1].x


## 1) Gerçek yol: R ile 3 klon, 4. turda kapıya.
func _test_bolum7_cozum() -> void:
	_kayitlar().sifirla()
	var bolum: Node = await _bolumu_yukle()
	var turlar: Array = [_b7_tur1(), _b7_tur2(), _b7_tur3()]
	var kareler: Array = []
	var olumsuz := ""
	for i in range(3):
		var sayac := [0]
		bolum.get_node("Oyuncu").oyuncu_oldu.connect(func() -> void: sayac[0] += 1)
		var s: Dictionary = await _b7_kosullu(bolum, turlar[i], sayac)
		kareler.append(s["kare"])
		if s["tamam"].has(false) or s["oldu"] > 0 or s["kare"] > 600:
			olumsuz += " tur%d adım karşılanmadı %s oldu=%d kare=%d;" % [i + 1, str(s["tamam"]), s["oldu"], s["kare"]]
		var eski_id := bolum.get_instance_id()
		await _r_bas()
		bolum = await _yeni_sahne_bekle(eski_id)
		if bolum == null:
			_kaydi("Bölüm 7 çözümü (4 tur, gerçek R/girdi yolu)", false, "tur %d sonrası sahne yüklenmedi;%s" % [i + 1, olumsuz])
			return
	var klon_basta: int = _klonlar(bolum).size()
	var etiket: String = bolum.bilgi.text
	var sayac4 := [0]
	bolum.get_node("Oyuncu").oyuncu_oldu.connect(func() -> void: sayac4[0] += 1)
	var s4: Dictionary = await _b7_kosullu(bolum, _b7_tur4(), sayac4)
	if s4["tamam"].slice(0, 2).has(false):
		olumsuz += " tur4 adım karşılanmadı %s;" % str(s4["tamam"])
	var gecit_acildi: bool = _b7_min(s4["ozel"], "gecit") <= 440.5
	var l1_kapandi: bool = _b7_hic_degil(s4["ozel"], "l1")
	var l2_kapandi: bool = _b7_hic_degil(s4["ozel"], "l2")
	var gecti: bool = s4["bitti"] and klon_basta == 3 and _kayitlar().turlar.size() == 3 \
		and etiket.contains("Klon: 3/3") and etiket.contains("Klon hakkı bitti") \
		and olumsuz == "" and s4["kare"] <= 600 and gecit_acildi and l1_kapandi and l2_kapandi
	_kaydi("Bölüm 7 çözümü (4 tur, gerçek R/girdi yolu)", gecti,
		"bölüm bitti: %s, tur kareleri: %s + %d (%.2f sn), klon: %d, kayıtlı tur: %d, ölüm: %d, etiket: \"%s\", geçit y min=%.0f (açık 440), asansör y min=%.0f (<=390), L1 kapandı: %s, L2 kapandı: %s, adım başlangıçları: %s%s" % [
			s4["bitti"], str(kareler), s4["kare"], s4["kare"] / 60.0, klon_basta, _kayitlar().turlar.size(),
			s4["oldu"], etiket, _b7_min(s4["ozel"], "gecit"), _b7_min(s4["ozel"], "asansor"),
			l1_kapandi, l2_kapandi, str(s4["baslangic"]), olumsuz])
	_kayitlar().sifirla()
	paused = false


## 2) Atlanamazlık.
func _test_bolum7_atlanamaz() -> void:
	# a) Klonsuz: oyuncu şalteri çevirip asansör sütununa varır, asansör kalkmaz; zeminden zıplayarak çıkılmaz.
	var adim_a: Array = [_b4_a(1, _b4_x_ge(900.0), 250), _b4_a(0, Callable(), 60)]
	for i in range(6):
		adim_a.append(_b4_a(0, Callable(), 70, true))
	var sa: Dictionary = await _b7_senaryo([], adim_a)
	var min_a := _b4_ayak_min(sa["iz"])
	var ok_a: bool = not sa["bitti"] and sa["oldu"] == 0 and _b7_min(sa["ozel"], "asansor") > 609.0 \
		and min_a >= 400.0 and sa["iz"][sa["iz"].size() - 1].x > 880.0
	_kaydi("Bölüm 7 atlanamaz: klonsuz F2'ye çıkılamaz", ok_a,
		"asansör y min=%.0f (aşağı 610), ayak y min=%.1f (Kat2 üstü 340, >=400 beklenir), oyuncu son x=%.0f, ölüm: %d, bölüm bitti: %s" % [
			_b7_min(sa["ozel"], "asansor"), min_a, sa["iz"][sa["iz"].size() - 1].x, sa["oldu"], sa["bitti"]])

	# b) Kat2 altından (x=800) tekrar tekrar zıplama: baş döşemeye çarpar, ayak y hep > 400.
	var hazir_b := func(b: Node) -> void: b.get_node("Oyuncu").global_position = Vector2(800.0, 576.0)
	var adim_b: Array = []
	for i in range(8):
		adim_b.append(_b4_a(0, Callable(), 60, true))
	var sb: Dictionary = await _b7_senaryo([], adim_b, hazir_b)
	var min_b := _b4_ayak_min(sb["iz"])
	var ok_b: bool = min_b >= 440.0 and min_b < 595.0 and not sb["bitti"] and sb["oldu"] == 0
	_kaydi("Bölüm 7 atlanamaz: zeminden zıplayarak Kat2'ye çıkılamaz", ok_b,
		"ayak y min=%.1f (Kat2 alt kenarı 400 + 48 = 448 beklenir; çıkış için <400), zıpladı: %s, bölüm bitti: %s" % [
			min_b, min_b < 595.0, sb["bitti"]])

	# c) F2'de (klonsuz, ışınlanarak) L1 açıkken geçilemez: ışında ölünür.
	var hazir_c := func(b: Node) -> void: b.get_node("Oyuncu").global_position = Vector2(800.0, 316.0)
	var sc: Dictionary = await _b7_senaryo([], [_b4_a(-1, Callable(), 150)], hazir_c)
	var son_c := _b7_son_x(sc)
	var ok_c: bool = not sc["bitti"] and sc["oldu"] == 1 and son_c > 600.0 and son_c < 640.0
	_kaydi("Bölüm 7 atlanamaz: F2'de ışın (L1) geçilemez", ok_c,
		"ölüm: %d (beklenen 1), son x=%.0f (ışın x=600), L1 açıktı: %s, bölüm bitti: %s" % [
			sc["oldu"], son_c, sc["ozel"][0]["l1"], sc["bitti"]])
	_kayitlar().sifirla()


## 3) Başarısızlık senaryoları (taslak 1..7).
func _test_bolum7_basarisizlik() -> void:
	var kay: Array = await _b7_kayitlar()
	var a: Array = kay[0]
	var z: Array = kay[1]
	var y: Array = kay[2]
	_kaydi("Bölüm 7 hazırlık: A, Z, Y kayıtları üretildi", a.size() > 0 and z.size() > 0 and y.size() > 0,
		"kare sayıları: A %d, Z %d, Y %d" % [a.size(), z.size(), y.size()])
	var oyuncu_adim: Array = _b7_yukari() + [_b4_a(-1, Callable(), 400)]

	# 1) Klonsuz: asansör kalkmaz.
	var s1: Dictionary = await _b7_senaryo([], oyuncu_adim)
	var ok1: bool = not s1["bitti"] and _b7_min_bekleme(s1, "asansor") > 609.0
	_kaydi("Bölüm 7 başarısızlık 1: klonsuz (E1 inik)", ok1,
		"asansör y min (bekleme evresi)=%.0f, bölüm bitti: %s, ölüm: %d" % [_b7_min_bekleme(s1, "asansor"), s1["bitti"], s1["oldu"]])

	# 2) Yalnız A: oyuncu PlakaB'yi kendisi tutar, L1'e girince ölür.
	var s2: Dictionary = await _b7_senaryo([a], oyuncu_adim)
	var son2 := _b7_son_x(s2)
	var ok2: bool = not s2["bitti"] and s2["oldu"] == 1 and son2 > 595.0 and son2 < 640.0
	_kaydi("Bölüm 7 başarısızlık 2: yalnız A (L1'de ölünür)", ok2,
		"ölüm: %d, son x=%.0f (L1 x=600), PlakaB oyuncuyla basıldı: %s, bölüm bitti: %s" % [
			s2["oldu"], son2, _b7_hic(s2["ozel"], "pb"), s2["bitti"]])

	# 3) A+Z (Y yok): L1 geçilir, L2'de ölünür.
	var s3: Dictionary = await _b7_senaryo([a, z], oyuncu_adim)
	var son3 := _b7_son_x(s3)
	var ok3: bool = not s3["bitti"] and s3["oldu"] == 1 and son3 > 375.0 and son3 < 425.0 \
		and _b7_hic_degil(s3["ozel"], "l1")
	_kaydi("Bölüm 7 başarısızlık 3: A+Z, Y yok (L2'de ölünür)", ok3,
		"ölüm: %d, son x=%.0f (L2 x=380), L1 kapanıp geçildi: %s (oyuncu yürürken PlakaC'ye kendisi basar, sonra L2 geri açılır), bölüm bitti: %s" % [
			s3["oldu"], son3, _b7_hic_degil(s3["ozel"], "l1"), s3["bitti"]])

	# 4) A erken basar (~20. kare): E1 yukarıda, oyuncu binemez, bölüm bitmez.
	var a_erken: Dictionary = await _b7_senaryo([], _b7_tur1(20))
	var s4: Dictionary = await _b7_senaryo([a_erken["kayit"], z, y],
		[_b4_a(1, _b4_x_ge(900.0), 250), _b4_a(0, Callable(), 100), _b4_a(-1, Callable(), 300)])
	var ok4: bool = not s4["bitti"] and s4["oldu"] == 0 and _b7_min(s4["ozel"], "asansor") < 360.0
	_kaydi("Bölüm 7 başarısızlık 4: A erken basar (E1 yukarıda, binilemez)", ok4,
		"asansör y min=%.0f (üstte 350), oyuncu en uzak x=%.0f, ölüm: %d, bölüm bitti: %s" % [
			_b7_min(s4["ozel"], "asansor"), _b5_maks_x(s4["iz"]), s4["oldu"], s4["bitti"]])

	# 5) Z yanlış yerde (x=640): PlakaB basılmaz, L1 açık, oyuncu ölür.
	var z_yanlis: Dictionary = await _b7_senaryo([a], _b7_tur2(640.0, false))
	var s5: Dictionary = await _b7_senaryo([a, z_yanlis["kayit"], y], oyuncu_adim)
	var son5 := _b7_son_x(s5)
	var ok5: bool = not s5["bitti"] and s5["oldu"] == 1 and son5 > 595.0 and son5 < 640.0 \
		and _b7_klon_min_x(s5, 1) > 630.0 and _b7_klon_min_x(s5, 1) < 650.0
	_kaydi("Bölüm 7 başarısızlık 5: Z yanlış yerde (L1 açık, ölünür)", ok5,
		"ölüm: %d, son x=%.0f (L1 x=600), klon Z en sol x=%.0f (plaka 670..730'a girmez; oyuncu sonradan kendisi basabilir), bölüm bitti: %s" % [
			s5["oldu"], son5, _b7_klon_min_x(s5, 1), s5["bitti"]])

	# 6) Şalter çevrilmez (üzerinden zıplanır): geçit kapalı kalır, bölüm bitmez.
	var adim6: Array = [_b4_a(1, _b4_x_ge(150.0), 100), _b4_a(1, Callable(), 1, true), _b4_a(1, Callable(), 400)]
	var s6: Dictionary = await _b7_senaryo([], adim6)
	var ok6: bool = not s6["bitti"] and s6["oldu"] == 0 and not _b7_hic(s6["ozel"], "salter") \
		and _b7_min(s6["ozel"], "gecit") > 499.0 and _b5_maks_x(s6["iz"]) < 430.0
	_kaydi("Bölüm 7 başarısızlık 6: şalter çevrilmez (geçit kapalı)", ok6,
		"şalter hiç sağa geçmedi: %s, geçit y min=%.0f (kapalı 500), oyuncu en uzak x=%.0f (geçit x=440), bölüm bitti: %s" % [
			not _b7_hic(s6["ozel"], "salter"), _b7_min(s6["ozel"], "gecit"), _b5_maks_x(s6["iz"]), s6["bitti"]])

	# 7) Y, Z basmadan L1'i geçer: klon ölür, PlakaC basılmaz; oyuncu da geçemez.
	var s7: Dictionary = await _b7_senaryo([a, y], [_b4_a(1, _b4_x_ge(900.0), 250), _b4_a(0, Callable(), 450)])
	var ok7: bool = not s7["bitti"] and s7["klon_oldu"].size() == 2 and s7["klon_oldu"][1] \
		and not _b7_hic(s7["ozel"], "pc") and s7["oldu"] == 0
	_kaydi("Bölüm 7 başarısızlık 7: Y, Z basmadan L1'i geçer (klon ölür)", ok7,
		"klon ölü durumları [A, Y]: %s, PlakaC hiç basılmadı: %s, oyuncu ölüm: %d, bölüm bitti: %s" % [
			str(s7["klon_oldu"]), not _b7_hic(s7["ozel"], "pc"), s7["oldu"], s7["bitti"]])
	_kayitlar().sifirla()


## 4) max_klon=3.
func _test_bolum7_klon_siniri() -> void:
	_kayitlar().sifirla()
	var bolum: Node = await _bolumu_yukle()
	var maks: int = bolum.max_klon
	var gecti := maks == 3
	var ayrinti: Array = []
	for n in range(maks + 1):
		for i in range(5):
			_girdi_uygula({"yon": 1.0, "zipla": false})
			await physics_frame
		_girdi_uygula({"yon": 0.0, "zipla": false})
		var eski_id := bolum.get_instance_id()
		await _r_bas()
		var yeni: Node = await _yeni_sahne_bekle(eski_id)
		var sayi: int = _kayitlar().turlar.size()
		if n < maks:
			gecti = gecti and yeni != null and sayi == n + 1
			if yeni == null:
				break
			bolum = yeni
		else:
			var yazi: String = bolum.bilgi.text
			gecti = gecti and yeni == null and sayi == maks and yazi.contains("Klon hakkı bitti") \
				and yazi.contains("3/3")
			ayrinti.append("sınırda etiket: \"%s\"" % yazi)
		ayrinti.append("R #%d -> kayıtlı klon: %d" % [n + 1, sayi])
	_kaydi("Bölüm 7: klon sınırı (dördüncü R klon kaydetmez)", gecti, "max_klon=%d; %s" % [maks, ", ".join(ayrinti)])
	_kayitlar().sifirla()


## 5) "3 klon gereği": A olmadan E1 kalkmaz; Y olmadan L2'de ölünür; Z olmadan bitmez.
func _test_bolum7_uc_klon_gereki() -> void:
	var kay: Array = await _b7_kayitlar()
	var oyuncu_adim: Array = _b7_yukari() + [_b4_a(-1, Callable(), 400)]
	var s_a: Dictionary = await _b7_senaryo([kay[1], kay[2]], oyuncu_adim)
	var ok_a: bool = not s_a["bitti"] and _b7_min_bekleme(s_a, "asansor") > 609.0
	var s_y: Dictionary = await _b7_senaryo([kay[0], kay[1]], oyuncu_adim)
	var son_y := _b7_son_x(s_y)
	var ok_y: bool = not s_y["bitti"] and s_y["oldu"] == 1 and son_y > 375.0 and son_y < 425.0 \
		and _b7_hic_degil(s_y["ozel"], "l1")
	var s_z: Dictionary = await _b7_senaryo([kay[0], kay[2]], oyuncu_adim)
	var ok_z: bool = not s_z["bitti"]
	_kaydi("Bölüm 7: 3 klon gereği (A, Y veya Z eksikse bitmez)", ok_a and ok_y and ok_z,
		"A yok: asansör y min (bekleme evresi)=%.0f (aşağı 610), bitti: %s; Y yok: ölüm %d son x=%.0f, L1 kapandı: %s; Z yok: bitti: %s, ölüm: %d" % [
			_b7_min_bekleme(s_a, "asansor"), s_a["bitti"], s_y["oldu"], son_y,
			_b7_hic_degil(s_y["ozel"], "l1"), s_z["bitti"], s_z["oldu"]])
	_kayitlar().sifirla()


## 6) Determinizm: 4. turun kaydı 100 kez.
func _test_bolum7_determinizm() -> void:
	var kay: Array = await _b7_kayitlar()
	var s0: Dictionary = await _b7_senaryo(kay, _b7_tur4())
	var betik: Array = s0["kayit"]
	var ornek := func(b: Node) -> Dictionary: return _b7_ornekle(b)
	var referans: Dictionary = {}
	var sapmali := 0
	var bitmeyen := 0
	var maks_sapma := 0.0
	for n in range(TEKRAR):
		var s: Dictionary = await _senaryo(kay, betik, 700, Callable(), ornek)
		if not s["bitti"]:
			bitmeyen += 1
		if n == 0:
			referans = s
			continue
		var bu: bool = s["ozel_iz"].size() != referans["ozel_iz"].size() or s["kare"] != referans["kare"]
		for f in range(mini(s["ozel_iz"].size(), referans["ozel_iz"].size())):
			if s["ozel_iz"][f] != referans["ozel_iz"][f]:
				bu = true
			var d: float = (s["oyuncu_iz"][f] - referans["oyuncu_iz"][f]).length()
			for ki in range(3):
				d = maxf(d, (s["klon_izleri"][ki][f] - referans["klon_izleri"][ki][f]).length())
			if d > 0.0:
				bu = true
				maks_sapma = maxf(maks_sapma, d)
		if bu:
			sapmali += 1
	_kaydi("Bölüm 7: determinizm (100x çözüm)", sapmali == 0 and bitmeyen == 0 and s0["bitti"],
		"%d çalıştırma x %d kare, sapmalı: %d, en büyük sapma: %.4f px, bitirmeyen çalıştırma: %d, kayıt turu bitti: %s" % [
			TEKRAR, referans["kare"], sapmali, maks_sapma, bitmeyen, s0["bitti"]])
	_kayitlar().sifirla()
	paused = false


# ---------------------------------------------------------------- Bölüm 7 ek testleri

## Bölüm 7: F2'de zıplayarak L1/L2 aşılamaz (tavan payı: baş >= 191 > ışın üstü 180).
func _test_bolum7_ek_isin() -> void:
	var adim: Array = []
	for i in range(8):
		adim.append(_b4_a(-1, Callable(), 20, true))
	var hz1 := func(b: Node) -> void: b.get_node("Oyuncu").global_position = Vector2(800.0, 316.0)
	var s1: Dictionary = await _b7_senaryo([], adim, hz1)
	var son1 := _b7_son_x(s1)
	var bas1 := 1.0e9
	for p in s1["iz"]:
		bas1 = minf(bas1, p.y - 24.0)
	var ok1: bool = not s1["bitti"] and s1["oldu"] == 1 and son1 > 595.0 and son1 < 640.0 and bas1 >= 180.0
	_kaydi("Bölüm 7 atlanamaz: F2'de zıplayarak L1 aşılamaz (tavan payı)", ok1,
		"ölüm: %d (beklenen 1), son x=%.0f (ışın x=600), baş y min=%.1f (tavan alt 180), zıpladı: %s" % [
			s1["oldu"], son1, bas1, bas1 < 292.0])
	var hz2 := func(b: Node) -> void: b.get_node("Oyuncu").global_position = Vector2(460.0, 316.0)
	var s2: Dictionary = await _b7_senaryo([], adim, hz2)
	var son2 := _b7_son_x(s2)
	var bas2 := 1.0e9
	for p in s2["iz"]:
		bas2 = minf(bas2, p.y - 24.0)
	var ok2: bool = not s2["bitti"] and s2["oldu"] == 1 and son2 > 375.0 and son2 < 425.0 and bas2 >= 180.0
	_kaydi("Bölüm 7 atlanamaz: F2'de zıplayarak L2 aşılamaz (tavan payı)", ok2,
		"ölüm: %d (beklenen 1), son x=%.0f (ışın x=380), baş y min=%.1f (tavan alt 180), bölüm bitti: %s" % [
			s2["oldu"], son2, bas2, s2["bitti"]])
	_kayitlar().sifirla()


## Bölüm 7: Kat2 köşesi / asansör kolonundan (x≈830..850) zıplayarak F2'ye çıkılamaz.
func _test_bolum7_ek_kose() -> void:
	var gecti := true
	var ayrinti: Array = []
	for cfg in [[835.0, 0.0], [832.0, 1.0], [850.0, -1.0]]:
		var adim: Array = []
		for i in range(6):
			adim.append(_b4_a(cfg[1], Callable(), 50, true))
		var hz := func(b: Node) -> void: b.get_node("Oyuncu").global_position = Vector2(cfg[0], 576.0)
		var s: Dictionary = await _b7_senaryo([], adim, hz)
		var m := _b4_ayak_min(s["iz"])
		var ok: bool = m >= 440.0 and m < 595.0 and not s["bitti"] and s["oldu"] == 0
		gecti = gecti and ok
		ayrinti.append("x=%.0f yon=%.0f: ayak y min=%.1f" % [cfg[0], cfg[1], m])
	_kaydi("Bölüm 7 atlanamaz: Kat2/asansör kolonu köşesinden zıplayarak F2'ye çıkılamaz", gecti,
		"; ".join(ayrinti) + " (F2 yüzeyi 340; çıkış için ayak <340, köşe başı 448 beklenir)")
	_kayitlar().sifirla()


# ---------------------------------------------------------------- Bölüm 8
const BOLUM_8 := "res://scenes/bolumler/bolum_8.tscn"
const B8_E1_UST_Y := 410.0        # E1 position.y <= 410: üst yüzey F2 (400) hizasında
const B8_GECIT_ACIK_Y := 50.5     # geçit merkezi (kapalı 140, açık 40): alt kenar <= 150 (baş 152)

var _b8_onbellek: Array = []   # [X, B] (max_klon=2 çözümü)


func _b8_ornekle(b: Node) -> Dictionary:
	return {
		"e1": b.get_node("Asansor").position.y, "gecit": b.get_node("Gecit").position.y,
		"salter": b.get_node("Salter").sagda,
		"pa": b.get_node("PlakaA").basili_mi(), "pc": b.get_node("PlakaC").basili_mi(),
		"l1": b.get_node("Lazer1").acik_mi(), "l2": b.get_node("Lazer2").acik_mi(),
		"l3": b.get_node("Lazer3").acik_mi()}


func _b8_salter_sagda() -> Callable:
	return func(b: Node) -> bool: return b.get_node("Salter").sagda


func _b8_salter_solda() -> Callable:
	return func(b: Node) -> bool: return not b.get_node("Salter").sagda


func _b8_gecit_acik() -> Callable:
	return func(b: Node) -> bool: return b.get_node("Gecit").position.y <= B8_GECIT_ACIK_Y


func _b8_l2_kapali() -> Callable:
	return func(b: Node) -> bool: return not b.get_node("Lazer2").acik_mi()


## Tur 1 -> A: PlakaA'ya (x=260) yürü ve tüm tur orada kal.
func _b8_tur1(bekle := 10, ayrilir := false) -> Array:
	var a: Array = [_b4_a(1, _b4_x_ge(260.0), 60), _b4_a(0, _b4_plakada("PlakaA"), 40)]
	if ayrilir:
		a.append(_b4_a(0, Callable(), 150))
		a.append(_b4_a(1, Callable(), 60))
	a.append(_b4_a(0, Callable(), bekle))
	return a


## Ortak yol: E1 ile F2 -> sağ -> a -> b -> K3 (zıplamalar koşula bağlı).
func _b8_yol(zipla_x := 680.0) -> Array:
	return [
		_b4_a(0, _b4_yukari("Asansor", B8_E1_UST_Y), 250),
		_b4_a(1, _b4_x_ge(zipla_x), 300),
		_b4_a(1, _b4_durdu(306.5, 780.0), 120, true),     # a (üst 330)
		_b4_a(-1, _b4_durdu(236.5, 700.0), 120, true),    # b (üst 260)
		_b4_a(-1, _b4_durdu(176.5), 120, true)]          # K3 (üst 200)


## _b7_kosullu ile aynı (ölüme dayanıklı), Bölüm 8 örnekleyicisiyle.
func _b8_kosullu(bolum: Node, adimlar: Array, sayac: Array) -> Dictionary:
	var oyuncu: CharacterBody2D = bolum.get_node("Oyuncu")
	var klonlar: Array = _klonlar(bolum)
	var klon_iz: Array = []
	for k in klonlar:
		klon_iz.append([])
	var iz: Array = []
	var ozel: Array = []
	var baslangic: Array = []
	var tamam: Array = []
	var kare := 0
	for a in adimlar:
		baslangic.append(iz.size())
		var n := 0
		var karsilandi: bool = not a["kosul"].is_valid()
		while n < a["maks"]:
			if not is_instance_valid(bolum) or bolum.bitti:
				break
			_girdi_uygula({"yon": a["yon"], "zipla": a["zipla"] and n == 0})
			iz.append(oyuncu.global_position)
			ozel.append(_b8_ornekle(bolum))
			for i in range(klonlar.size()):
				klon_iz[i].append(klonlar[i].global_position)
			await physics_frame
			n += 1
			kare += 1
			if a["kosul"].is_valid() and is_instance_valid(bolum) and a["kosul"].call(bolum):
				karsilandi = true
				break
		tamam.append(karsilandi)
		if not is_instance_valid(bolum) or bolum.bitti:
			break
	_girdi_uygula({"yon": 0.0, "zipla": false})
	var bitti_son: bool = is_instance_valid(bolum) and bolum.bitti
	var kayit: Array = []
	if is_instance_valid(oyuncu):
		kayit = oyuncu.kayit_girdileri.duplicate(true)
	var klon_oldu: Array = []
	for k in klonlar:
		klon_oldu.append(is_instance_valid(k) and k.oldu)
	for i in range(3):
		await physics_frame
	return {"kare": kare, "bitti": bitti_son and sayac[0] == 0, "oldu": sayac[0], "iz": iz, "ozel": ozel,
		"klon_izleri": klon_iz, "baslangic": baslangic, "tamam": tamam, "kayit": kayit,
		"klon_oldu": klon_oldu}


func _b8_senaryo(kayitlar: Array, adimlar: Array, hazirlik := Callable()) -> Dictionary:
	_kayitlar().sifirla()
	for k in kayitlar:
		_kayitlar().tur_kaydet(k.duplicate(true))
	var bolum: Node = await _bolumu_yukle()
	if hazirlik.is_valid():
		hazirlik.call(bolum)
	var sayac := [0]
	bolum.get_node("Oyuncu").oyuncu_oldu.connect(func() -> void: sayac[0] += 1)
	var s: Dictionary = await _b8_kosullu(bolum, adimlar, sayac)
	paused = false
	return s


## [X, B] kayıtları (gerçek bölümdeki gibi ardışık, önceki klonlarla kaydedilir).
func _b8_kayitlar() -> Array:
	if _b8_onbellek.is_empty():
		var s1: Dictionary = await _b8_senaryo([], _b8k_x())
		var s2: Dictionary = await _b8_senaryo([s1["kayit"]], _b8k_b())
		_b8_onbellek = [s1["kayit"], s2["kayit"]]
	return _b8_onbellek


## E1'in beklendiği evrede (adım 0) örneklerin en küçüğü.
func _b8_min_bekleme(s: Dictionary, anahtar: String) -> float:
	var son: int = s["baslangic"][1] if s["baslangic"].size() > 1 else s["ozel"].size()
	return _b7_min(s["ozel"].slice(0, son), anahtar)


func _b8_zipla_dizisi(n: int, yon: float, kare: int) -> Array:
	var a: Array = []
	for i in range(n):
		a.append(_b4_a(yon, Callable(), kare, true))
	return a


func _b8_son_ayak(s: Dictionary) -> float:
	return s["iz"][s["iz"].size() - 1].y + B4_AYAK


## 1) Gerçek yol: R ile 2 klon (X, B), 3. turda kapıya (max_klon=2).
func _test_bolum8_cozum() -> void:
	_kayitlar().sifirla()
	var bolum: Node = await _bolumu_yukle()
	var turlar: Array = [_b8k_x(), _b8k_b()]
	var kareler: Array = []
	var olumsuz := ""
	for i in range(2):
		var sayac := [0]
		bolum.get_node("Oyuncu").oyuncu_oldu.connect(func() -> void: sayac[0] += 1)
		var s: Dictionary = await _b8_kosullu(bolum, turlar[i], sayac)
		kareler.append(s["kare"])
		if s["tamam"].has(false) or s["oldu"] > 0 or s["kare"] > 600:
			olumsuz += " tur%d adım karşılanmadı %s oldu=%d kare=%d;" % [i + 1, str(s["tamam"]), s["oldu"], s["kare"]]
		var eski_id := bolum.get_instance_id()
		await _r_bas()
		bolum = await _yeni_sahne_bekle(eski_id)
		if bolum == null:
			_kaydi("Bölüm 8 çözümü (3 tur, 2 klon, gerçek R/girdi yolu)", false, "tur %d sonrası sahne yüklenmedi;%s" % [i + 1, olumsuz])
			return
	var klon_basta: int = _klonlar(bolum).size()
	var etiket: String = bolum.bilgi.text
	var sayac3 := [0]
	bolum.get_node("Oyuncu").oyuncu_oldu.connect(func() -> void: sayac3[0] += 1)
	var s3: Dictionary = await _b8_kosullu(bolum, _b8k_oyuncu(), sayac3)
	if s3["tamam"].slice(0, s3["tamam"].size() - 1).has(false):
		olumsuz += " tur3 adım karşılanmadı %s;" % str(s3["tamam"])
	var gecit_min: float = _b7_min(s3["ozel"], "gecit")
	var e1_min: float = _b7_min(s3["ozel"], "e1")
	var l1_kapandi: bool = _b7_hic_degil(s3["ozel"], "l1")
	var l3_kapandi: bool = _b7_hic_degil(s3["ozel"], "l3")
	var l2_acildi: bool = _b7_hic(s3["ozel"], "l2")
	var gecti: bool = s3["bitti"] and klon_basta == 2 and _kayitlar().turlar.size() == 2 \
		and etiket.contains("Klon: 2/2") and etiket.contains("Klon hakkı bitti") \
		and olumsuz == "" and s3["kare"] <= 600 and gecit_min <= B8_GECIT_ACIK_Y \
		and l1_kapandi and l3_kapandi and l2_acildi and e1_min <= B8_E1_UST_Y
	_kaydi("Bölüm 8 çözümü (3 tur, 2 klon, gerçek R/girdi yolu)", gecti,
		"bölüm bitti: %s, tur kareleri: %s + %d (%.2f sn), klon: %d, kayıtlı tur: %d, ölüm: %d, etiket: \"%s\", geçit y min=%.0f (açık 40), E1 y min=%.0f (<=410), L1 kapandı: %s, L3 kapandı: %s, L2 açıldı: %s, adım başlangıçları: %s%s" % [
			s3["bitti"], str(kareler), s3["kare"], s3["kare"] / 60.0, klon_basta, _kayitlar().turlar.size(),
			s3["oldu"], etiket, gecit_min, e1_min, l1_kapandi, l3_kapandi, l2_acildi,
			str(s3["baslangic"]), olumsuz])
	_kayitlar().sifirla()
	paused = false


## 2) Atlanamazlık.
func _test_bolum8_atlanamaz() -> void:
	# a) Klonsuz: E1 inik; E1 üstünden ve K2 altından zıplayarak F2'ye çıkılamaz.
	var adim_a: Array = _b8_zipla_dizisi(5, 0.0, 60)
	adim_a.append(_b4_a(1, _b4_x_ge(330.0), 100))
	adim_a += _b8_zipla_dizisi(5, 0.0, 50)
	var sa: Dictionary = await _b8_senaryo([], adim_a)
	var min_a := _b4_ayak_min(sa["iz"])
	var ok_a: bool = not sa["bitti"] and sa["oldu"] == 0 and min_a >= 480.0 and min_a < 595.0
	_kaydi("Bölüm 8 atlanamaz: klonsuz F2'ye çıkılamaz", ok_a,
		"ayak y min=%.1f (F2 yüzeyi 400, çıkış için <400; zıplama tepesi ~499, K2 altı >=488), zıpladı: %s, ölüm: %d, bölüm bitti: %s" % [
			min_a, min_a < 595.0, sa["oldu"], sa["bitti"]])

	# b) Zeminden K2 altında (x=700) ve E1 kenarında (x=145, sağa itip) zıplama.
	var hz_b1 := func(b: Node) -> void: b.get_node("Oyuncu").global_position = Vector2(700.0, 576.0)
	var sb1: Dictionary = await _b8_senaryo([], _b8_zipla_dizisi(8, 0.0, 60), hz_b1)
	var hz_b2 := func(b: Node) -> void: b.get_node("Oyuncu").global_position = Vector2(145.0, 570.0)
	var sb2: Dictionary = await _b8_senaryo([], _b8_zipla_dizisi(6, 1.0, 40), hz_b2)
	var m1 := _b4_ayak_min(sb1["iz"])
	var m2 := _b4_ayak_min(sb2["iz"])
	var ok_b: bool = m1 >= 480.0 and m1 < 595.0 and m2 >= 480.0 and m2 < 595.0 \
		and not sb1["bitti"] and not sb2["bitti"] and sb1["oldu"] == 0 and sb2["oldu"] == 0
	_kaydi("Bölüm 8 atlanamaz: zeminden zıplayarak K2'ye (ayak y<400) çıkılamaz", ok_b,
		"K2 altı x=700: ayak y min=%.1f; E1 kenarı x=145 (sağa): ayak y min=%.1f (K2 alt kenarı 440 + 48 = 488 beklenir; çıkış için <400)" % [m1, m2])

	# c) F2'den K3'e basamaksız: K3 altında (x=500) zıplama; baş K3 alt kenarına (240) çarpar.
	var hz_c := func(b: Node) -> void: b.get_node("Oyuncu").global_position = Vector2(500.0, 376.0)
	var sc: Dictionary = await _b8_senaryo([], _b8_zipla_dizisi(8, 0.0, 60), hz_c)
	var min_c := _b4_ayak_min(sc["iz"])
	var ok_c: bool = min_c >= 280.0 and min_c < 395.0 and not sc["bitti"] and sc["oldu"] == 0
	_kaydi("Bölüm 8 atlanamaz: F2'den K3'e basamaksız çıkılamaz", ok_c,
		"ayak y min=%.1f (K3 yüzeyi 200; K3 alt 240 + 48 = 288 beklenir), zıpladı: %s" % [min_c, min_c < 395.0])

	# d) a'dan K3'e doğrudan: tek zıplamada ayak tepesi ~229 (> K3 yüzeyi 200), inişi b'ye (260) olur.
	var hz_d := func(b: Node) -> void: b.get_node("Oyuncu").global_position = Vector2(850.0, 306.0)
	var sd: Dictionary = await _b8_senaryo([], [_b4_a(-1, Callable(), 70, true)], hz_d)
	var min_d := _b4_ayak_min(sd["iz"])
	var son_d := _b8_son_ayak(sd)
	var ok_d: bool = min_d >= 222.0 and son_d >= 250.0 and not sd["bitti"] and sd["oldu"] == 0
	_kaydi("Bölüm 8 atlanamaz: a'dan K3'e doğrudan (tek zıplama) çıkılamaz", ok_d,
		"ayak y min=%.1f (tepe ~229, K3 yüzeyi 200), son ayak y=%.1f (b üstü 260 / a üstü 330), son x=%.0f" % [
			min_d, son_d, _b7_son_x(sd)])

	# e) Işınlar zıplayarak aşılamaz: L1 (F2), L3 (F3) ve şalter SAĞdayken L_L (F3).
	var hz_e1 := func(b: Node) -> void: b.get_node("Oyuncu").global_position = Vector2(640.0, 376.0)
	var se1: Dictionary = await _b8_senaryo([], _b8_zipla_dizisi(8, -1.0, 25), hz_e1)
	var son1 := _b7_son_x(se1)
	var bas1 := 1.0e9
	for p in se1["iz"]:
		bas1 = minf(bas1, p.y - 24.0)
	var ok_e1: bool = se1["oldu"] == 1 and not se1["bitti"] and son1 > 545.0 and son1 < 600.0 and bas1 >= 240.0
	_kaydi("Bölüm 8 atlanamaz: F2'de zıplayarak L1 aşılamaz", ok_e1,
		"ölüm: %d (beklenen 1), son x=%.0f (ışın x=560), baş y min=%.1f (K3 alt 240)" % [se1["oldu"], son1, bas1])
	var hz_e3 := func(b: Node) -> void: b.get_node("Oyuncu").global_position = Vector2(240.0, 176.0)
	var se3: Dictionary = await _b8_senaryo([], _b8_zipla_dizisi(8, -1.0, 25), hz_e3)
	var son3 := _b7_son_x(se3)
	var ok_e3: bool = se3["oldu"] == 1 and not se3["bitti"] and son3 > 195.0 and son3 < 235.0
	_kaydi("Bölüm 8 atlanamaz: F3'te zıplayarak L3 aşılamaz", ok_e3,
		"ölüm: %d (beklenen 1), son x=%.0f (ışın x=190)" % [se3["oldu"], son3])
	var hz_el := func(b: Node) -> void:
		b.get_node("Salter").sagda = true
		b.get_node("Oyuncu").global_position = Vector2(290.0, 176.0)
	var sel: Dictionary = await _b8_senaryo([], _b8_zipla_dizisi(8, -1.0, 25), hz_el)
	var sonl := _b7_son_x(sel)
	var ok_el: bool = sel["oldu"] == 1 and not sel["bitti"] and sonl > 255.0 and sonl < 292.0 \
		and _b7_hic(sel["ozel"], "l2")
	_kaydi("Bölüm 8 atlanamaz: F3'te zıplayarak L_L (şalter SAĞda) aşılamaz", ok_el,
		"ölüm: %d (beklenen 1), son x=%.0f (ışın x=250), L_L açıktı: %s" % [
			sel["oldu"], sonl, _b7_hic(sel["ozel"], "l2")])
	_kayitlar().sifirla()


## 3) Başarısızlık senaryoları (taslak 1..7, max_klon=2 çözümüne uyarlanmış).
func _test_bolum8_basarisizlik() -> void:
	var kay: Array = await _b8_kayitlar()
	var x_k: Array = kay[0]
	var b_k: Array = kay[1]
	var a_s: Dictionary = await _b8_senaryo([], _b8_tur1())
	var a: Array = a_s["kayit"]
	_kaydi("Bölüm 8 hazırlık: X, B (ve A) kayıtları üretildi", x_k.size() > 0 and b_k.size() > 0 and a.size() > 0,
		"kare sayıları: X %d, B %d, A %d" % [x_k.size(), b_k.size(), a.size()])

	# 1) Klonsuz: E1 inik.
	var s1: Dictionary = await _b8_senaryo([], _b8k_oyuncu())
	var ok1: bool = not s1["bitti"] and _b8_min_bekleme(s1, "e1") > 609.0
	_kaydi("Bölüm 8 başarısızlık 1: klonsuz (E1 inik)", ok1,
		"E1 y min (bekleme evresi)=%.0f (aşağı 610), bölüm bitti: %s, ölüm: %d" % [
			_b8_min_bekleme(s1, "e1"), s1["bitti"], s1["oldu"]])

	# 2) Yalnız A (C'ye giden yok): L1'de ölünür.
	var s2: Dictionary = await _b8_senaryo([a], _b8k_oyuncu())
	var son2 := _b7_son_x(s2)
	var ok2: bool = not s2["bitti"] and s2["oldu"] == 1 and son2 > 520.0 and son2 < 570.0
	_kaydi("Bölüm 8 başarısızlık 2: yalnız A, C'ye giden yok (L1'de ölünür)", ok2,
		"ölüm: %d, son x=%.0f (L1 x=560), bölüm bitti: %s" % [s2["oldu"], son2, s2["bitti"]])

	# 3) Yalnız X (B yok): geçit kapalı, G önünde takılır.
	var s3: Dictionary = await _b8_senaryo([x_k], _b8k_oyuncu())
	var son3 := _b7_son_x(s3)
	var ok3: bool = not s3["bitti"] and s3["oldu"] == 0 and _b7_min(s3["ozel"], "gecit") > 100.0 \
		and son3 > 335.0 and son3 < 352.0 and not _b7_hic(s3["ozel"], "salter")
	_kaydi("Bölüm 8 başarısızlık 3: yalnız X, B yok (geçit kapalı, G önünde kalır)", ok3,
		"geçit y min=%.0f (kapalı 140; geçiş için <=50), son x=%.0f (G x=320, sağ yüzü 330 + 14), şalter hiç sağa geçmedi: %s, ölüm: %d, bölüm bitti: %s" % [
			_b7_min(s3["ozel"], "gecit"), son3, not _b7_hic(s3["ozel"], "salter"), s3["oldu"], s3["bitti"]])

	# 4) B şalteri çok erken SOLA çevirir: geçit tam açılmadan kapanır.
	var b_erken: Dictionary = await _b8_senaryo([x_k], _b8k_b(6))
	var s4: Dictionary = await _b8_senaryo([x_k, b_erken["kayit"]], _b8k_oyuncu())
	var ok4: bool = not s4["bitti"] and s4["oldu"] == 0 and _b7_min(s4["ozel"], "gecit") > 70.0
	_kaydi("Bölüm 8 başarısızlık 4: B şalteri çok erken SOLA çevirir (geçit geçilemez)", ok4,
		"geçit y min=%.0f (geçiş için <=50), şalter sağa geçti: %s, ölüm: %d, bölüm bitti: %s" % [
			_b7_min(s4["ozel"], "gecit"), _b7_hic(s4["ozel"], "salter"), s4["oldu"], s4["bitti"]])

	# 5) X C'ye basmaz (x=840'ta durur): L1 açık kalır, ölünür.
	var x_yanlis: Dictionary = await _b8_senaryo([], _b8k_x(840.0))
	var s5: Dictionary = await _b8_senaryo([x_yanlis["kayit"], b_k], _b8k_oyuncu())
	var son5 := _b7_son_x(s5)
	var ok5: bool = not s5["bitti"] and s5["oldu"] == 1 and son5 > 520.0 and son5 < 570.0 \
		and not _b7_hic(s5["ozel"], "pc")
	_kaydi("Bölüm 8 başarısızlık 5: X C'ye basmaz, yanlış yerde (L1 açık, ölünür)", ok5,
		"ölüm: %d, son x=%.0f (L1 x=560), PlakaC hiç basılmadı: %s, bölüm bitti: %s" % [
			s5["oldu"], son5, not _b7_hic(s5["ozel"], "pc"), s5["bitti"]])

	# 6) X A'ya geri dönmez (plakadan ayrılır): L3 açılır, ölünür.
	var x_donmez: Dictionary = await _b8_senaryo([], _b8k_x(900.0, false))
	var s6: Dictionary = await _b8_senaryo([x_donmez["kayit"], b_k], _b8k_oyuncu())
	var son6 := _b7_son_x(s6)
	var ok6: bool = not s6["bitti"] and s6["oldu"] == 1 and son6 > 190.0 and son6 < 240.0 \
		and _b7_hic(s6["ozel"], "l3")
	_kaydi("Bölüm 8 başarısızlık 6: X A'ya dönmez, A plakası boş (L3 açılır, ölünür)", ok6,
		"ölüm: %d, son x=%.0f (L3 x=190), L3 açıldı: %s, bölüm bitti: %s" % [
			s6["oldu"], son6, _b7_hic(s6["ozel"], "l3"), s6["bitti"]])

	# 7) İlk zıplama erken (x<~584) veya geç (x>~730): a'ya inilmez, F2'ye düşer (ölüm yok).
	# Ölçülen pencere (6 px adımla tarandı): ~584..~728 iner, <=578 ve >=734 inemez.
	var onc: Array = _b8k_onc()
	var kontrol: Dictionary = await _b8_senaryo(kay, onc + _b8_yol(680.0).slice(1))
	var ok_k: bool = not kontrol["tamam"].has(false)
	var ayr7: Array = ["kontrol x=680: adımlar %s" % str(kontrol["tamam"])]
	var ok7 := ok_k
	var pencere: Array = []
	for x in [580.0, 600.0, 624.0, 650.0, 716.0, 750.0, 770.0, 800.0]:
		var s7: Dictionary = await _b8_senaryo(kay, onc + _b8_yol(x).slice(1, 3))
		var iz_son := _b8_son_ayak(s7)
		var indi: bool = s7["tamam"][onc.size() + 1]
		if indi:
			pencere.append(int(x))
		var icinde: bool = x >= 600.0 and x <= 716.0
		var disinda: bool = x <= 580.0 or x >= 750.0
		if icinde:
			ok7 = ok7 and indi and iz_son <= 331.0
		if disinda:
			ok7 = ok7 and not indi and not s7["bitti"] and iz_son >= 399.0
		ok7 = ok7 and s7["oldu"] == 0
		ayr7.append("x>=%.0f: a'ya inildi: %s (son ayak y=%.1f)" % [x, indi, iz_son])
	ayr7.append("a'ya inilen zıplama x değerleri: %s (ölçülen pencere ~584..~728; 600/624/650/716 iner, 580 ve 750+ F2'ye düşer, ölüm yok)" % str(pencere))
	_kaydi("Bölüm 8 başarısızlık 7: zıplama penceresi (pencerede a'ya iner; erken/geç inilmez, ölüm yok)", ok7, "; ".join(ayr7))
	_kayitlar().sifirla()


## 4) max_klon=2.
func _test_bolum8_klon_siniri() -> void:
	_kayitlar().sifirla()
	var bolum: Node = await _bolumu_yukle()
	var maks: int = bolum.max_klon
	var gecti := maks == 2
	var ayrinti: Array = []
	for n in range(maks + 1):
		for i in range(5):
			_girdi_uygula({"yon": 1.0, "zipla": false})
			await physics_frame
		_girdi_uygula({"yon": 0.0, "zipla": false})
		var eski_id := bolum.get_instance_id()
		await _r_bas()
		var yeni: Node = await _yeni_sahne_bekle(eski_id)
		var sayi: int = _kayitlar().turlar.size()
		if n < maks:
			gecti = gecti and yeni != null and sayi == n + 1
			if yeni == null:
				break
			bolum = yeni
		else:
			var yazi: String = bolum.bilgi.text
			gecti = gecti and yeni == null and sayi == maks and yazi.contains("Klon hakkı bitti") \
				and yazi.contains("2/2")
			ayrinti.append("sınırda etiket: \"%s\"" % yazi)
		ayrinti.append("R #%d -> kayıtlı klon: %d" % [n + 1, sayi])
	_kaydi("Bölüm 8: klon sınırı (üçüncü R klon kaydetmez)", gecti, "max_klon=%d; %s" % [maks, ", ".join(ayrinti)])
	_kayitlar().sifirla()


## 5) İki klon gerekir: yalnız X, yalnız B, X'siz (bekleyen klon + B), B'siz (X + bekleyen klon) bitmez.
func _test_bolum8_uc_klon_gereki() -> void:
	var kay: Array = await _b8_kayitlar()
	var bos: Array = []
	for i in range(60):
		bos.append({"yon": 0.0, "zipla": false})
	var s_x: Dictionary = await _b8_senaryo([kay[0]], _b8k_oyuncu())
	var s_b: Dictionary = await _b8_senaryo([kay[1]], _b8k_oyuncu())
	var s_xsiz: Dictionary = await _b8_senaryo([bos, kay[1]], _b8k_oyuncu())
	var s_bsiz: Dictionary = await _b8_senaryo([kay[0], bos], _b8k_oyuncu())
	# Yalnız X / B'siz: geçit kapalı kalır, şalteri çeviren yok.
	var ok_x: bool = not s_x["bitti"] and _b7_min(s_x["ozel"], "gecit") > 100.0
	var ok_bsiz: bool = not s_bsiz["bitti"] and _b7_min(s_bsiz["ozel"], "gecit") > 100.0
	# Yalnız B / X'siz: E1 tutan yok, E1 F2 hizasına (<=410) hiç ulaşmaz.
	var ok_b: bool = not s_b["bitti"] and _b7_min(s_b["ozel"], "e1") > B8_E1_UST_Y
	var ok_xsiz: bool = not s_xsiz["bitti"] and _b7_min(s_xsiz["ozel"], "e1") > B8_E1_UST_Y
	_kaydi("Bölüm 8: 2 klon gerekir (yalnız X, yalnız B, X'siz, B'siz bitmez)", ok_x and ok_b and ok_xsiz and ok_bsiz,
		"yalnız X: bitti=%s geçit y min=%.0f; yalnız B: bitti=%s E1 y min=%.0f; X'siz: bitti=%s E1 y min=%.0f; B'siz: bitti=%s geçit y min=%.0f" % [
			s_x["bitti"], _b7_min(s_x["ozel"], "gecit"), s_b["bitti"], _b7_min(s_b["ozel"], "e1"),
			s_xsiz["bitti"], _b7_min(s_xsiz["ozel"], "e1"), s_bsiz["bitti"], _b7_min(s_bsiz["ozel"], "gecit")])
	_kayitlar().sifirla()


## Kısayol (max_klon=2 çözümü): klon X (A'yı tutar, E1 çıkınca C'ye gider, L1 kapanınca A'ya döner) + B (şalter operatörü).
## durak_x < 900: X C'ye basmaz; doner=false: X A'ya geri dönmez (başarısızlık testleri için).
func _b8k_x(durak_x := 900.0, doner := true, bekc := 30) -> Array:
	var a: Array = [
		_b4_a(1, _b4_x_ge(260.0), 60),
		_b4_a(0, _b4_yukari("Asansor", B8_E1_UST_Y), 250),
		_b4_a(1, _b4_x_ge(durak_x), 300)]
	if durak_x >= 900.0:
		a.append(_b4_a(0, _b4_plakada("PlakaC"), 60))
		a.append(_b4_a(0, _b5_lazer_kapali("Lazer1"), 200))
	a.append(_b4_a(0, Callable(), bekc))
	if doner:
		a.append(_b4_a(-1, _b4_x_le(262.0), 250))
	a.append(_b4_a(0, Callable(), 10))
	return a


func _b8k_onc() -> Array:
	return [
		_b4_a(0, _b4_yukari("Asansor", B8_E1_UST_Y), 250),
		_b4_a(1, _b4_x_ge(520.0), 200),
		_b4_a(0, _b5_lazer_kapali("Lazer1"), 300)]


func _b8k_b(bekle := 66) -> Array:
	return _b8k_onc() + _b8_yol().slice(1) + [
		_b4_a(-1, _b4_x_le(480.0), 120),
		_b4_a(0, _b4_durdu(96.5), 150, true),
		_b4_a(-1, Callable(), 4),
		_b4_a(1, _b8_salter_sagda(), 10),
		_b4_a(0, Callable(), bekle),
		_b4_a(-1, _b8_salter_solda(), 10),
		_b4_a(0, Callable(), 10)]


func _b8k_oyuncu() -> Array:
	return _b8k_onc() + _b8_yol().slice(1) + [
		_b4_a(-1, _b8_gecit_acik(), 300),
		_b4_a(-1, _b4_x_le(276.0), 100),
		_b4_a(0, _b8_l2_kapali(), 100),
		_b4_a(-1, _b4_bitti_k(), 200)]


## 6) Tek yönlü basamaklara aşağıdan geçiş (a, b, sekme): üstten çıkıp üstünde durulur.
func _test_bolum8_tek_yonlu() -> void:
	var gecti := true
	var ayrinti: Array = []
	for cfg in [["a (F2'den)", Vector2(840.0, 376.0), 330.0], ["b (a'dan)", Vector2(800.0, 306.0), 260.0],
			["sekme (K3'ten)", Vector2(480.0, 176.0), 120.0]]:
		var hz := func(b: Node) -> void: b.get_node("Oyuncu").global_position = cfg[1]
		var s: Dictionary = await _b8_senaryo([], [_b4_a(0, Callable(), 80, true)], hz)
		var m := _b4_ayak_min(s["iz"])
		var son := _b8_son_ayak(s)
		var ok: bool = m < cfg[2] - 5.0 and absf(son - cfg[2]) < 1.5 and s["oldu"] == 0
		gecti = gecti and ok
		ayrinti.append("%s: tepe ayak y=%.1f, son ayak y=%.1f (yüzey %.0f)" % [cfg[0], m, son, cfg[2]])
	_kaydi("Bölüm 8: tek yönlü basamaklara aşağıdan geçilir ve üstünde durulur", gecti, "; ".join(ayrinti))
	_kayitlar().sifirla()


## 7) Determinizm: 4. turun kaydı 100 kez.
func _test_bolum8_determinizm() -> void:
	var kay: Array = await _b8_kayitlar()
	var s0: Dictionary = await _b8_senaryo(kay, _b8k_oyuncu())
	var betik: Array = s0["kayit"]
	var ornek := func(b: Node) -> Dictionary: return _b8_ornekle(b)
	var referans: Dictionary = {}
	var sapmali := 0
	var bitmeyen := 0
	var maks_sapma := 0.0
	for n in range(TEKRAR):
		var s: Dictionary = await _senaryo(kay, betik, 700, Callable(), ornek)
		if not s["bitti"]:
			bitmeyen += 1
		if n == 0:
			referans = s
			continue
		var bu: bool = s["ozel_iz"].size() != referans["ozel_iz"].size() or s["kare"] != referans["kare"]
		for f in range(mini(s["ozel_iz"].size(), referans["ozel_iz"].size())):
			if s["ozel_iz"][f] != referans["ozel_iz"][f]:
				bu = true
			var d: float = (s["oyuncu_iz"][f] - referans["oyuncu_iz"][f]).length()
			for ki in range(2):
				d = maxf(d, (s["klon_izleri"][ki][f] - referans["klon_izleri"][ki][f]).length())
			if d > 0.0:
				bu = true
				maks_sapma = maxf(maks_sapma, d)
		if bu:
			sapmali += 1
	_kaydi("Bölüm 8: determinizm (100x çözüm)", sapmali == 0 and bitmeyen == 0 and s0["bitti"],
		"%d çalıştırma x %d kare, sapmalı: %d, en büyük sapma: %.4f px, bitirmeyen çalıştırma: %d, kayıt turu bitti: %s" % [
			TEKRAR, referans["kare"], sapmali, maks_sapma, bitmeyen, s0["bitti"]])
	_kayitlar().sifirla()
	paused = false


# ---------------------------------------------------------------- Bölüm 9 (kutu)
# Taslak: docs/devir/bolum_9_taslak.md. Çözüm: k1 Plaka1, k2 Plaka2 (platform), k3 kutuyu asansörle F2'ye
# taşıyıp Plaka3'e gider, oyuncu kutuyu PlakaKutu'ya iter. Alternatif S2: kutu Plaka3'te, k3 PlakaKutu'da.
const BOLUM_9 := "res://scenes/bolumler/bolum_9.tscn"
const B9_ASANSOR_UST_Y := 450.0    # asansör merkezi (üst yüzey 440 = F2 hizası)
const B9_GECIT_ACIK_Y := 270.5     # geçit merkezi (kapalı 340, açık 270)

var _b9_onbellek: Array = []   # [k1, k2, k3]


func _b9_ornekle(b: Node) -> Dictionary:
	return {
		"as": b.get_node("Asansor").position.y, "g": b.get_node("Gecit").position.y,
		"p1": b.get_node("Plaka1").basili_mi(), "p2": b.get_node("Plaka2").basili_mi(),
		"p3": b.get_node("Plaka3").basili_mi(), "pk": b.get_node("PlakaKutu").basili_mi(),
		"l0": b.get_node("Lazer1").acik_mi(), "l1": b.get_node("Lazer2").acik_mi(),
		"kutu": b.get_node("Kutu").global_position}


## Tur 1 -> k1: Plaka1'e (x=170) yürü, orada kal.
func _b9_k1() -> Array:
	return [_b4_a(1, _b4_x_ge(170.0), 60), _b4_a(0, _b4_plakada("Plaka1"), 40), _b4_a(0, Callable(), 10)]


## Tur 2 -> k2: L0'ı geçip platforma zıpla, Plaka2'ye bas. bekle: zıplamadan önceki bekleme (kare).
func _b9_k2(bekle := 120) -> Array:
	return [_b4_a(1, _b4_x_ge(350.0), 100), _b4_a(0, Callable(), bekle),
		_b4_a(0, _b4_durdu(510.0), 120, true), _b4_a(1, _b4_x_ge(380.0), 40),
		_b4_a(0, _b4_plakada("Plaka2"), 60), _b4_a(0, Callable(), 10)]


## Ortak: kutuyu asansöre yükle, asansör üstte olunca (position.y <= 450) bekleme biter.
func _b9_yukle() -> Array:
	return [_b4_a(1, _b4_x_ge(620.0), 200), _b4_a(0, _b4_yukari("Asansor", B9_ASANSOR_UST_Y), 400)]


## Tur 3 -> k3: kutuyu F2'ye taşı, Plaka3'e (x=760) bas.
func _b9_k3() -> Array:
	return _b9_yukle() + [_b4_a(1, _b4_x_ge(760.0), 100), _b4_a(0, _b4_plakada("Plaka3"), 60), _b4_a(0, Callable(), 10)]


## Alternatif S2 k3: kutuyu Plaka3'e iter (x=726), üstünden zıplayıp PlakaKutu'ya basar.
func _b9_k3_s2() -> Array:
	return _b9_yukle() + [_b4_a(1, _b4_x_ge(726.0), 100), _b4_a(0, Callable(), 8, true),
		_b4_a(1, _b4_x_ge(930.0), 80), _b4_a(0, _b4_plakada("PlakaKutu"), 60), _b4_a(0, Callable(), 10)]


## Tur 4 -> oyuncu (S1): kutuyu PlakaKutu'ya (x~930) iter, üstünden zıplar, G'nin altından kapıya.
func _b9_oyuncu() -> Array:
	return _b9_yukle() + [_b4_a(1, _b4_x_ge(896.0), 150), _b4_a(0, Callable(), 8, true),
		_b4_a(1, _b4_x_ge(956.0), 40), _b4_a(0, _b4_durdu(441.0), 80), _b4_a(1, _b4_bitti_k(), 300)]


## S2'de oyuncu kutuya dokunmaz: Plaka3'teki kutunun üstünden zıplar.
func _b9_oyuncu_s2() -> Array:
	return _b9_yukle() + [_b4_a(1, _b4_x_ge(690.0), 100), _b4_a(0, Callable(), 8, true),
		_b4_a(1, _b4_x_ge(900.0), 80), _b4_a(0, _b4_durdu(441.0), 80), _b4_a(1, _b4_bitti_k(), 300)]


## _b7_kosullu ile aynı; Bölüm 9 örnekleyicisiyle.
func _b9_kosullu(bolum: Node, adimlar: Array, sayac: Array) -> Dictionary:
	var oyuncu: CharacterBody2D = bolum.get_node("Oyuncu")
	var klonlar: Array = _klonlar(bolum)
	var klon_iz: Array = []
	for k in klonlar:
		klon_iz.append([])
	var iz: Array = []
	var ozel: Array = []
	var baslangic: Array = []
	var tamam: Array = []
	var kare := 0
	for a in adimlar:
		baslangic.append(iz.size())
		var n := 0
		var karsilandi: bool = not a["kosul"].is_valid()
		while n < a["maks"]:
			if not is_instance_valid(bolum) or bolum.bitti:
				break
			_girdi_uygula({"yon": a["yon"], "zipla": a["zipla"] and n == 0})
			iz.append(oyuncu.global_position)
			ozel.append(_b9_ornekle(bolum))
			for i in range(klonlar.size()):
				klon_iz[i].append(klonlar[i].global_position)
			await physics_frame
			n += 1
			kare += 1
			if a["kosul"].is_valid() and is_instance_valid(bolum) and a["kosul"].call(bolum):
				karsilandi = true
				break
		tamam.append(karsilandi)
		if not is_instance_valid(bolum) or bolum.bitti:
			break
	_girdi_uygula({"yon": 0.0, "zipla": false})
	var bitti_son: bool = is_instance_valid(bolum) and bolum.bitti
	var kayit: Array = []
	if is_instance_valid(oyuncu):
		kayit = oyuncu.kayit_girdileri.duplicate(true)
	var klon_oldu: Array = []
	for k in klonlar:
		klon_oldu.append(is_instance_valid(k) and k.oldu)
	for i in range(3):
		await physics_frame
	return {"kare": kare, "bitti": bitti_son and sayac[0] == 0, "oldu": sayac[0], "iz": iz, "ozel": ozel,
		"klon_izleri": klon_iz, "baslangic": baslangic, "tamam": tamam, "kayit": kayit,
		"klon_oldu": klon_oldu}


func _b9_senaryo(kayitlar: Array, adimlar: Array, hazirlik := Callable()) -> Dictionary:
	_kayitlar().sifirla()
	for k in kayitlar:
		_kayitlar().tur_kaydet(k.duplicate(true))
	var bolum: Node = await _bolumu_yukle()
	if hazirlik.is_valid():
		hazirlik.call(bolum)
	var sayac := [0]
	bolum.get_node("Oyuncu").oyuncu_oldu.connect(func() -> void: sayac[0] += 1)
	var s: Dictionary = await _b9_kosullu(bolum, adimlar, sayac)
	paused = false
	return s


## [k1, k2, k3] kayıtları (gerçek bölümdeki gibi ardışık, önceki klonlarla kaydedilir).
func _b9_kayitlar() -> Array:
	if _b9_onbellek.is_empty():
		var s1: Dictionary = await _b9_senaryo([], _b9_k1())
		var s2: Dictionary = await _b9_senaryo([s1["kayit"]], _b9_k2())
		var s3: Dictionary = await _b9_senaryo([s1["kayit"], s2["kayit"]], _b9_k3())
		_b9_onbellek = [s1["kayit"], s2["kayit"], s3["kayit"]]
	return _b9_onbellek


## Kutunun eksen değerinin (x/y) örnekler boyunca en küçük/en büyüğü.
func _b9_kutu_aralik(ozel: Array, eksen: String) -> Vector2:
	var lo := 1.0e9
	var hi := -1.0e9
	for o in ozel:
		var v: float = o["kutu"][eksen]
		lo = minf(lo, v)
		hi = maxf(hi, v)
	return Vector2(lo, hi)


func _b9_kutu_son(s: Dictionary) -> Vector2:
	return s["ozel"][s["ozel"].size() - 1]["kutu"]


func _b9_yerlestir(oyuncu: Vector2) -> Callable:
	return func(b: Node) -> void: b.get_node("Oyuncu").global_position = oyuncu


## 1) Gerçek yol: R ile 3 klon (k1, k2, k3), 4. turda kapıya; her tur <= 600 kare.
func _test_bolum9_cozum() -> void:
	_kayitlar().sifirla()
	var bolum: Node = await _bolumu_yukle()
	var turlar: Array = [_b9_k1(), _b9_k2(), _b9_k3()]
	var kareler: Array = []
	var olumsuz := ""
	for i in range(3):
		var sayac := [0]
		bolum.get_node("Oyuncu").oyuncu_oldu.connect(func() -> void: sayac[0] += 1)
		var s: Dictionary = await _b9_kosullu(bolum, turlar[i], sayac)
		kareler.append(s["kare"])
		if s["tamam"].has(false) or s["oldu"] > 0 or s["kare"] > 600:
			olumsuz += " tur%d adım karşılanmadı %s oldu=%d kare=%d;" % [i + 1, str(s["tamam"]), s["oldu"], s["kare"]]
		var eski_id := bolum.get_instance_id()
		await _r_bas()
		bolum = await _yeni_sahne_bekle(eski_id)
		if bolum == null:
			_kaydi("Bölüm 9 çözümü (4 tur, 3 klon, gerçek R/girdi yolu)", false, "tur %d sonrası sahne yüklenmedi;%s" % [i + 1, olumsuz])
			return
	var klon_basta: int = _klonlar(bolum).size()
	var etiket: String = bolum.bilgi.text
	var sayac4 := [0]
	bolum.get_node("Oyuncu").oyuncu_oldu.connect(func() -> void: sayac4[0] += 1)
	var s4: Dictionary = await _b9_kosullu(bolum, _b9_oyuncu(), sayac4)
	if s4["tamam"].slice(0, s4["tamam"].size() - 1).has(false):
		olumsuz += " tur4 adım karşılanmadı %s;" % str(s4["tamam"])
	var gecit_min: float = _b7_min(s4["ozel"], "g")
	var l0_kapandi: bool = _b7_hic_degil(s4["ozel"], "l0")
	var l1_kapandi: bool = _b7_hic_degil(s4["ozel"], "l1")
	var pk: bool = _b7_hic(s4["ozel"], "pk")
	var gecti: bool = s4["bitti"] and klon_basta == 3 and _kayitlar().turlar.size() == 3 \
		and etiket.contains("Klon: 3/3") and etiket.contains("Klon hakkı bitti") \
		and olumsuz == "" and s4["kare"] <= 600 and gecit_min <= B9_GECIT_ACIK_Y \
		and l0_kapandi and l1_kapandi and pk
	_kaydi("Bölüm 9 çözümü (4 tur, 3 klon, gerçek R/girdi yolu)", gecti,
		"bölüm bitti: %s, tur kareleri: %s + %d (%.2f sn), klon: %d, kayıtlı tur: %d, ölüm: %d, etiket: \"%s\", geçit y min=%.0f (açık 270), L0 kapandı: %s, L1 kapandı: %s, PlakaKutu basıldı: %s, adım başlangıçları: %s%s" % [
			s4["bitti"], str(kareler), s4["kare"], s4["kare"] / 60.0, klon_basta, _kayitlar().turlar.size(),
			s4["oldu"], etiket, gecit_min, l0_kapandi, l1_kapandi, pk, str(s4["baslangic"]), olumsuz])
	_kayitlar().sifirla()
	paused = false


## 2) Alternatif S2: kutu Plaka3'te (L1 kapalı), k3 PlakaKutu'yu tutar, oyuncu kutuya dokunmaz.
func _test_bolum9_alternatif() -> void:
	var kay: Array = await _b9_kayitlar()
	var k3s: Dictionary = await _b9_senaryo([kay[0], kay[1]], _b9_k3_s2())
	var s: Dictionary = await _b9_senaryo([kay[0], kay[1], k3s["kayit"]], _b9_oyuncu_s2())
	var kutu_son: Vector2 = _b9_kutu_son(s)
	var ok_k3: bool = not k3s["tamam"].slice(0, k3s["tamam"].size() - 1).has(false) and k3s["oldu"] == 0 and k3s["kare"] <= 600
	var gecti: bool = ok_k3 and s["bitti"] and s["oldu"] == 0 and s["kare"] <= 600 \
		and _b7_min(s["ozel"], "g") <= B9_GECIT_ACIK_Y and kutu_son.x > 730.0 and kutu_son.x < 790.0
	_kaydi("Bölüm 9 alternatif S2 (kutu Plaka3'te, k3 PlakaKutu'yu tutar) bitirir", gecti,
		"k3 tur kare=%d adımlar=%s ölüm=%d; oyuncu turu: bitti=%s kare=%d ölüm=%d adımlar=%s, geçit y min=%.0f, son kutu=(%.0f,%.0f) (Plaka3 x=760)" % [
			k3s["kare"], str(k3s["tamam"]), k3s["oldu"], s["bitti"], s["kare"], s["oldu"], str(s["tamam"]),
			_b7_min(s["ozel"], "g"), kutu_son.x, kutu_son.y])
	_kayitlar().sifirla()


## 3) Atlanamazlık.
func _test_bolum9_atlanamaz() -> void:
	# a) Klonsuz: L0'da (x=290) ölünür, Kayitlar değişmez.
	var sa: Dictionary = await _b9_senaryo([], [_b4_a(1, _b4_x_ge(330.0), 120)])
	var kayit_n: int = _kayitlar().turlar.size()
	_kaydi("Bölüm 9 atlanamaz: klonsuz L0'da ölünür, Kayitlar değişmez", sa["oldu"] >= 1 and not sa["bitti"] and kayit_n == 0,
		"ölüm: %d, bitti: %s, kayıtlı tur: %d, L0 açık: %s" % [sa["oldu"], sa["bitti"], kayit_n, _b7_hic(sa["ozel"], "l0")])

	# b) Zeminden Kat2 duvarına yaslanıp zıplayarak F2'ye (ayak y<440) çıkılamaz.
	var sb: Dictionary = await _b9_senaryo([], [_b4_a(1, _b4_x_ge(686.0), 200)] + _b8_zipla_dizisi(6, 1.0, 50),
		_b9_yerlestir(Vector2(660.0, 570.0)))
	var mb := _b4_ayak_min(sb["iz"])
	_kaydi("Bölüm 9 atlanamaz: zeminden zıplayarak F2'ye (ayak y<440) çıkılamaz", mb >= 490.0 and mb < 599.0 and not sb["bitti"] and sb["oldu"] == 0,
		"ayak y min=%.1f (zıplama tepesi ~503, F2 yüzeyi 440), zıpladı: %s, ölüm: %d" % [mb, mb < 595.0, sb["oldu"]])

	# c) Kutu basamak: kutuyu Kat2'ye (x=702) kadar iter, üstüne çıkıp zıpla; ayak y>=440 kalır.
	var adim_c: Array = [_b4_a(1, _b4_x_ge(640.0), 400)] + _b8_zipla_dizisi(2, 1.0, 25) + _b8_zipla_dizisi(5, 1.0, 40)
	var sc: Dictionary = await _b9_senaryo([], adim_c, _b9_yerlestir(Vector2(440.0, 570.0)))
	var mc := _b4_ayak_min(sc["iz"])
	var kc: Vector2 = _b9_kutu_aralik(sc["ozel"], "x")
	_kaydi("Bölüm 9 atlanamaz: kutu basamak yapılarak F2'ye çıkılamaz", mc >= 445.0 and not sc["bitti"] and sc["oldu"] == 0,
		"ayak y min=%.1f (kutu üstü 560, zıplama tepesi ~463; F2 440), kutu x: %.0f..%.0f (Kat2 duvarı 702 -> en çok 682), ölüm: %d" % [
			mc, kc.x, kc.y, sc["oldu"]])

	# d) Platformdan F2'ye atlanamaz (yatay 242 px): platform sağ ucundan sağa zıpla.
	var sd: Dictionary = await _b9_senaryo([], _b8_zipla_dizisi(6, 1.0, 50), _b9_yerlestir(Vector2(450.0, 506.0)))
	var f2_d := false
	var maks_x_d := -1.0
	for p in sd["iz"]:
		if p.x >= 702.0 and p.y + B4_AYAK <= 445.0:
			f2_d = true
		maks_x_d = maxf(maks_x_d, p.x)
	_kaydi("Bölüm 9 atlanamaz: platformdan F2'ye atlanamaz", not f2_d and not sd["bitti"],
		"F2'ye çıktı: %s, en büyük x=%.0f (Kat2 sol kenarı 702), ölüm: %d" % [f2_d, maks_x_d, sd["oldu"]])

	# e) L1 (x=860, F2) zıplayarak aşılamaz; kapalı G aşılamaz; L0 aşılamaz.
	var se: Dictionary = await _b9_senaryo([], _b8_zipla_dizisi(8, 1.0, 25), _b9_yerlestir(Vector2(780.0, 416.0)))
	var bas_e := 1.0e9
	for p in se["iz"]:
		bas_e = minf(bas_e, p.y - 24.0)
	_kaydi("Bölüm 9 atlanamaz: F2'de zıplayarak L1 aşılamaz", se["oldu"] >= 1 and not se["bitti"] and bas_e >= 300.0 and _b7_hic(se["ozel"], "l1"),
		"ölüm: %d (beklenen >=1), baş y min=%.1f (tavan 300), L1 açıktı: %s" % [se["oldu"], bas_e, _b7_hic(se["ozel"], "l1")])
	var sg: Dictionary = await _b9_senaryo([], [_b4_a(1, Callable(), 80)] + _b8_zipla_dizisi(6, 1.0, 30), _b9_yerlestir(Vector2(990.0, 416.0)))
	var son_g := 0.0
	for p in sg["iz"]:
		son_g = maxf(son_g, p.x)
	_kaydi("Bölüm 9 atlanamaz: kapalı G yürüyerek/zıplayarak aşılamaz", son_g < 1050.0 and not sg["bitti"] and sg["oldu"] == 0 \
		and _b7_min(sg["ozel"], "g") > 335.0,
		"en büyük x=%.0f (G sol yüzü 1060, bedel 14), geçit y min=%.0f (kapalı 340), ölüm: %d, bitti: %s" % [
			son_g, _b7_min(sg["ozel"], "g"), sg["oldu"], sg["bitti"]])
	var sl: Dictionary = await _b9_senaryo([], _b8_zipla_dizisi(8, 1.0, 25), _b9_yerlestir(Vector2(200.0, 570.0)))
	_kaydi("Bölüm 9 atlanamaz: zıplayarak L0 aşılamaz", sl["oldu"] >= 1 and not sl["bitti"] and _b7_hic(sl["ozel"], "l0"),
		"ölüm: %d, L0 açıktı: %s" % [sl["oldu"], _b7_hic(sl["ozel"], "l0")])
	_kayitlar().sifirla()


## 4) Kısayol taraması (bağımsız): eksik klon kombinasyonları ve röle denemeleri bitmez.
func _test_bolum9_kisayol() -> void:
	var kay: Array = await _b9_kayitlar()
	var k1: Array = kay[0]
	var k2: Array = kay[1]
	var k3: Array = kay[2]
	var ayr: Array = []
	var hepsi := true
	var kombinler := [["yalnız k1", [k1]], ["k1+k2 (k3 yok)", [k1, k2]], ["k1+k3 (k2 yok)", [k1, k3]],
		["k2+k3 (k1 yok)", [k2, k3]]]
	for k in kombinler:
		# Oyuncu iki yolu dener: S1 (kutuyu G'ye götür) ve S2 (kutuyu Plaka3'e iter, PlakaKutu'ya geçer).
		var s1: Dictionary = await _b9_senaryo(k[1], _b9_oyuncu())
		var oyuncu_s2: Array = _b9_yukle() + [_b4_a(1, _b4_x_ge(726.0), 100), _b4_a(0, Callable(), 8, true),
			_b4_a(1, _b4_x_ge(930.0), 80), _b4_a(0, Callable(), 100), _b4_a(1, _b4_bitti_k(), 200)]
		var s2: Dictionary = await _b9_senaryo(k[1], oyuncu_s2)
		var ok: bool = not s1["bitti"] and not s2["bitti"]
		hepsi = hepsi and ok
		ayr.append("%s: S1 bitti=%s (ölüm %d, kare %d), S2 bitti=%s (ölüm %d, kare %d)" % [
			k[0], s1["bitti"], s1["oldu"], s1["kare"], s2["bitti"], s2["oldu"], s2["kare"]])
	_kaydi("Bölüm 9 kısayol: eksik klonla (k1; k1+k2; k1+k3; k2+k3) bitmez", hepsi, "; ".join(ayr))

	# Röle: bir klon önce Plaka1'i tutup sonra Plaka2'ye gider (L0'ı geçerken Plaka1 boş kalır -> ölür).
	var role: Array = [_b4_a(1, _b4_x_ge(170.0), 60), _b4_a(0, _b4_plakada("Plaka1"), 40), _b4_a(0, Callable(), 40),
		_b4_a(1, _b4_x_ge(350.0), 100), _b4_a(0, Callable(), 10, true), _b4_a(1, _b4_x_ge(380.0), 40),
		_b4_a(0, _b4_plakada("Plaka2"), 60), _b4_a(0, Callable(), 10)]
	var sr: Dictionary = await _b9_senaryo([], role)
	var rk: Array = sr["kayit"]
	var r1: Dictionary = await _b9_senaryo([rk, k3], _b9_oyuncu())
	# Röle 2: k3 kutuyu PlakaKutu'ya itip sonra Plaka3'e döner (L1'i Plaka3 boşken geçmek zorunda -> ölür).
	var role3: Array = _b9_yukle() + [_b4_a(1, _b4_x_ge(896.0), 150), _b4_a(0, Callable(), 8, true),
		_b4_a(1, _b4_x_ge(956.0), 40), _b4_a(0, Callable(), 30), _b4_a(-1, _b4_x_le(760.0), 200), _b4_a(0, Callable(), 10)]
	var sr3: Dictionary = await _b9_senaryo([k1, k2], role3)
	var r3: Dictionary = await _b9_senaryo([k1, k2, sr3["kayit"]], _b9_oyuncu())
	var ok_r: bool = not r1["bitti"] and not r3["bitti"] and sr["oldu"] >= 1 and sr3["oldu"] >= 1
	_kaydi("Bölüm 9 kısayol: röle (Plaka1->Plaka2; PlakaKutu->Plaka3) ile bitmez, röle klonları L0/L1'de ölür", ok_r,
		"röle1 klonu ölüm/bitti: %d/%s, röle1+k3: bitti=%s (ölüm %d, asansör y min=%.0f); röle2 (k3 yerine) ölüm/bitti: %d/%s, k1+k2+röle2+oyuncu: bitti=%s (ölüm %d)" % [
			sr["oldu"], sr["bitti"], r1["bitti"], r1["oldu"], _b7_min(r1["ozel"], "as"),
			sr3["oldu"], sr3["bitti"], r3["bitti"], r3["oldu"]])
	_kayitlar().sifirla()


## 5) Başarısızlık senaryoları.
func _test_bolum9_basarisizlik() -> void:
	var kay: Array = await _b9_kayitlar()
	var k1: Array = kay[0]
	var k2: Array = kay[1]
	var k3: Array = kay[2]
	var ok_h: bool = k1.size() > 0 and k2.size() > 0 and k3.size() > 0
	_kaydi("Bölüm 9 hazırlık: k1, k2, k3 kayıtları üretildi", ok_h, "kare sayıları: %d, %d, %d" % [k1.size(), k2.size(), k3.size()])

	# 1) k2 erken basar (plaka ~kare 87): asansör kutu yüklenmeden çıkar, kutu yerde kalır, bitmez.
	var k2e: Dictionary = await _b9_senaryo([k1], _b9_k2(0))
	var s1: Dictionary = await _b9_senaryo([k1, k2e["kayit"], k3], _b9_oyuncu())
	var kutu1: Vector2 = _b9_kutu_son(s1)
	var kutu1_aralik: Vector2 = _b9_kutu_aralik(s1["ozel"], "y")
	var f2_oyuncu := false
	for p in s1["iz"]:
		if p.x >= 702.0 and p.y + B4_AYAK <= 445.0:
			f2_oyuncu = true
	var ok1: bool = not s1["bitti"] and kutu1.x < 702.0 and not f2_oyuncu
	_kaydi("Bölüm 9 başarısızlık: k2 erken basar, kutu F2'ye ulaşmaz, bitmez", ok1,
		"k2 adımları %s; bitti: %s, ölüm: %d, son kutu=(%.0f,%.0f) (kutu asansörün üstünde ama F2'ye ulaşmadı: x<702), kutu y min=%.0f, asansör y min=%.0f, oyuncu F2'ye çıktı: %s" % [
			str(k2e["tamam"]), s1["bitti"], s1["oldu"], kutu1.x, kutu1.y, kutu1_aralik.x, _b7_min(s1["ozel"], "as"), f2_oyuncu])

	# 2) Kutu PlakaKutu'yu aşıp G'ye itilir: plaka boş kalır, G kapanır, bitmez.
	var asiri: Array = _b9_yukle() + [_b4_a(1, _b4_x_ge(1000.0), 250), _b4_a(1, _b4_bitti_k(), 150)]
	var s2: Dictionary = await _b9_senaryo([k1, k2, k3], asiri)
	var kutu2: Vector2 = _b9_kutu_son(s2)
	var son_g: float = s2["ozel"][s2["ozel"].size() - 1]["g"]
	var son_pk: bool = s2["ozel"][s2["ozel"].size() - 1]["pk"]
	var ok2: bool = not s2["bitti"] and kutu2.x > 965.0 and not son_pk
	_kaydi("Bölüm 9 başarısızlık: kutu PlakaKutu'yu aşıp G'ye itilir, bitmez", ok2,
		"bitti: %s, ölüm: %d, son kutu x=%.0f (plaka 900..960, G 1060), PlakaKutu basılı: %s, geçit y=%.0f (kapalı 340)" % [
			s2["bitti"], s2["oldu"], kutu2.x, son_pk, son_g])

	# 3) k3 asansöre binmez (x=540'ta durur, kutu yerde): oyuncu kutuyu kendisi taşımak zorunda -> L1 açık, bitmez.
	var k3k: Array = [_b4_a(1, _b4_x_ge(540.0), 100), _b4_a(0, Callable(), 10)]
	var k3_yanlis: Dictionary = await _b9_senaryo([k1, k2], k3k)
	var s3: Dictionary = await _b9_senaryo([k1, k2, k3_yanlis["kayit"]], _b9_oyuncu())
	var kutu3: Vector2 = _b9_kutu_son(s3)
	_kaydi("Bölüm 9 başarısızlık: k3 asansöre binmez, bitmez", not s3["bitti"],
		"bitti: %s, ölüm: %d, Plaka3 hiç basılmadı: %s, son kutu=(%.0f,%.0f), asansör y min=%.0f" % [
			s3["bitti"], s3["oldu"], not _b7_hic(s3["ozel"], "p3"), kutu3.x, kutu3.y, _b7_min(s3["ozel"], "as")])
	_kayitlar().sifirla()


## 6) max_klon=3: dördüncü R klon kaydetmez.
func _test_bolum9_klon_siniri() -> void:
	_kayitlar().sifirla()
	var bolum: Node = await _bolumu_yukle()
	var maks: int = bolum.max_klon
	var gecti := maks == 3
	var ayrinti: Array = []
	for n in range(maks + 1):
		for i in range(5):
			_girdi_uygula({"yon": 1.0, "zipla": false})
			await physics_frame
		_girdi_uygula({"yon": 0.0, "zipla": false})
		var eski_id := bolum.get_instance_id()
		await _r_bas()
		var yeni: Node = await _yeni_sahne_bekle(eski_id)
		var sayi: int = _kayitlar().turlar.size()
		if n < maks:
			gecti = gecti and yeni != null and sayi == n + 1
			if yeni == null:
				break
			bolum = yeni
		else:
			var yazi: String = bolum.bilgi.text
			gecti = gecti and yeni == null and sayi == maks and yazi.contains("Klon hakkı bitti") \
				and yazi.contains("3/3")
			ayrinti.append("sınırda etiket: \"%s\"" % yazi)
		ayrinti.append("R #%d -> kayıtlı klon: %d" % [n + 1, sayi])
	_kaydi("Bölüm 9: klon sınırı (dördüncü R klon kaydetmez)", gecti, "max_klon=%d; %s" % [maks, ", ".join(ayrinti)])
	_kayitlar().sifirla()


## 7) Kutu asansörle F2'ye taşınır (konum ölçümü): oyuncu bekler, 3 klon çalışır.
func _test_bolum9_kutu_tasima() -> void:
	var kay: Array = await _b9_kayitlar()
	var s: Dictionary = await _b9_senaryo(kay, [_b4_a(0, Callable(), 340)])
	var tasindi := false          # asansörle yükselirken (y<560, 580<x<700)
	var ilk_f2 := -1
	var bagil_maks := 0.0
	for i in range(s["ozel"].size()):
		var o: Dictionary = s["ozel"][i]
		if o["kutu"].x < 700.0 and o["kutu"].x > 580.0 and o["kutu"].y < 560.0:
			tasindi = true
			bagil_maks = maxf(bagil_maks, absf(o["kutu"].y - (o["as"] - 30.0)))
		if ilk_f2 < 0 and o["kutu"].x >= 722.0 and absf(o["kutu"].y - 420.0) <= 2.0:
			ilk_f2 = i
	var son: Vector2 = _b9_kutu_son(s)
	var as_son: float = s["ozel"][s["ozel"].size() - 1]["as"]
	var ok: bool = tasindi and bagil_maks <= 5.0 and ilk_f2 > 0 and absf(son.y - 420.0) <= 2.0 \
		and son.x > 722.0 and absf(as_son - 450.0) <= 1.5 and s["oldu"] == 0
	_kaydi("Bölüm 9: kutu asansörle F2'ye taşınır (konum ölçümü)", ok,
		"asansörle yükseldi: %s (kutu-asansör bağıl sapma en çok %.2f px), F2'ye ilk geçiş kare %d, son kutu=(%.1f,%.1f) (F2 yüzeyi 440 -> y 420), asansör y=%.1f (üstte 450), klon ölümleri: %s, oyuncu ölümü: %d" % [
			tasindi, bagil_maks, ilk_f2, son.x, son.y, as_son, str(s["klon_oldu"]), s["oldu"]])
	_kayitlar().sifirla()


## 8) Ek ölçümler: G sınırı, asansör-kutu takılması, kutunun F2'den itilmesi.
func _test_bolum9_ek_olcumler() -> void:
	var kay: Array = await _b9_kayitlar()
	var k1: Array = kay[0]
	var g_acik := func(b: Node) -> bool: return b.get_node("Gecit").position.y <= B9_GECIT_ACIK_Y + 0.5

	# a) PlakaKutu'nun sağ ucundan ayrılıp G'ye sprint: G kapanır, geçilemez (üç zıplama gecikmesi).
	# Açıkken geçit y=270, ayakta geçiş için y<=292 gerekir; G sol yüzü 1060 (karakter merkezi >= 1046).
	var ayr_a: Array = []
	var ok_a := true
	for gecikme in [0, 6, 12]:
		var adim_a: Array = [_b4_a(0, g_acik, 150), _b4_a(1, Callable(), gecikme), _b4_a(1, Callable(), 1, true),
			_b4_a(1, Callable(), 150)]
		var sa: Dictionary = await _b9_senaryo([], adim_a, _b9_yerlestir(Vector2(950.0, 416.0)))
		var maks := -1.0
		for p in sa["iz"]:
			maks = maxf(maks, p.x)
		var ilk := -1
		for f in range(sa["iz"].size()):
			if sa["iz"][f].x >= 1041.0:
				ilk = f
				break
		var g_ilk: float = sa["ozel"][ilk]["g"] if ilk >= 0 else -1.0
		var ok: bool = not sa["bitti"] and sa["oldu"] == 0 and maks < 1046.0 and sa["tamam"][0] \
			and (ilk < 0 or g_ilk >= 292.0)
		ok_a = ok_a and ok
		ayr_a.append("gecikme %d: en büyük x=%.1f, x>=1041 kare=%d, o karede G y=%.0f (geçiş için <=292), bitti=%s, ölüm=%d" % [
			gecikme, maks, ilk, g_ilk, sa["bitti"], sa["oldu"]])
	_kaydi("Bölüm 9 atlanamaz: PlakaKutu'dan ayrılıp G'ye sprint (düz ve zıplayarak) geçemez", ok_a, "; ".join(ayr_a))

	# b) Asansör kutuda takılıp basamak olur: k2 yerine plakayı sonradan bırakan klon; kutu yukarıdaki
	# asansörün altına itilir, klon inince asansör kutuya oturur (üst yüz ~540). Bu basamaktan F2'ye
	# (ayak y<440) çıkılır mı ÖLÇÜLÜR: asansör üstü ~536, zıplama tepesi ~96,5 -> pay ~0,5 px (F2'ye çıkılabilir,
	# bkz. docs/sorunlar.md). Ama F2'de L1 (Plaka3 boş) ve G (PlakaKutu boş) kalır: 2 klonla bölüm bitmez.
	var k2_birak: Array = [_b4_a(1, _b4_x_ge(350.0), 100), _b4_a(0, Callable(), 120),
		_b4_a(0, _b4_durdu(510.0), 120, true), _b4_a(1, _b4_x_ge(380.0), 40),
		_b4_a(0, _b4_plakada("Plaka2"), 60), _b4_a(0, Callable(), 230),
		_b4_a(-1, _b4_x_le(330.0), 80), _b4_a(0, Callable(), 10)]
	var sk2: Dictionary = await _b9_senaryo([k1], k2_birak)
	var asansor_ust := func(b: Node) -> bool: return b.get_node("Asansor").position.y <= B9_ASANSOR_UST_Y + 0.5
	var asansor_indi := func(b: Node) -> bool:
		var y: float = b.get_node("Asansor").position.y
		return y >= 545.0
	var adim_b: Array = [_b4_a(1, _b10_kutu_x_ge(535.0), 200), _b4_a(0, asansor_ust, 500),
		_b4_a(1, _b10_kutu_x_ge(590.0), 60), _b4_a(0, asansor_indi, 400), _b4_a(0, Callable(), 20)]
	adim_b += _b8_zipla_dizisi(1, 1.0, 20) + [_b4_a(1, _b4_x_ge(690.0), 80)] + _b8_zipla_dizisi(6, 1.0, 40)
	var sb: Dictionary = await _b9_senaryo([k1, sk2["kayit"]], adim_b)
	var mb := _b4_ayak_min(sb["iz"], sb["baslangic"][5] if sb["baslangic"].size() > 5 else 0)
	var as_ara: float = sb["ozel"][sb["baslangic"][5] if sb["baslangic"].size() > 5 else 0]["as"]
	var f2_b := false
	for p in sb["iz"]:
		if p.x >= 702.0 and p.y + B4_AYAK <= 445.0:
			f2_b = true
	_kaydi("Bölüm 9 ölçüm: asansör kutuda takılıp basamak olur; 2 klonla bölüm yine de bitmez",
		not sk2["tamam"].has(false) and not sb["tamam"].slice(0, 5).has(false) \
		and as_ara > 535.0 and as_ara < 600.0 and not sb["bitti"],
		"klon adımları %s, oyuncu adımları %s, asansör basamak anında y=%.1f (kutuda takılı ~550; inik 610), basamaktan ayak y min=%.1f (F2 yüzeyi 440), F2'ye ÇIKTI: %s (ölçüm; L1'de ölür), bitti: %s, ölüm: %d" % [
			str(sk2["tamam"]), str(sb["tamam"]), as_ara, mb, f2_b, sb["bitti"], sb["oldu"]])

	# c) Kutu F2'de, oyuncu sola iter: kutu F2 kenarından düşer, platforma (x 340..460, yüzey 530)
	# ulaşamaz, zeminde kalır; bölüm bitmez.
	var yer_c := func(b: Node) -> void:
		b.get_node("Oyuncu").global_position = Vector2(800.0, 416.0)
		b.get_node("Kutu").global_position = Vector2(760.0, 420.0)
	var sc: Dictionary = await _b9_senaryo([], [_b4_a(-1, _b4_x_le(450.0), 250), _b4_a(0, Callable(), 60)], yer_c)
	var kc: Vector2 = _b9_kutu_aralik(sc["ozel"], "x")
	var kson: Vector2 = _b9_kutu_son(sc)
	var platformda := false
	for o in sc["ozel"]:
		if o["kutu"].x <= 470.0 and o["kutu"].y < 560.0:
			platformda = true
	_kaydi("Bölüm 9 ölçüm: F2'deki kutu sola itilince kenardan düşer, platforma ulaşamaz",
		kson.y > 570.0 and kson.x > 470.0 and kc.x > 470.0 and not platformda and not sc["bitti"],
		"kutu x aralığı %.0f..%.0f, son kutu=(%.1f,%.1f) (F2 yüzeyi 420, zemin 580, platform 340..460/y~510), platformda: %s, oyuncu ölümü: %d" % [
			kc.x, kc.y, kson.x, kson.y, platformda, sc["oldu"]])
	_kayitlar().sifirla()


## 9) Determinizm: 4. turun kaydı 100 kez (3 klon + kutu).
func _test_bolum9_determinizm() -> void:
	var kay: Array = await _b9_kayitlar()
	var s0: Dictionary = await _b9_senaryo(kay, _b9_oyuncu())
	var betik: Array = s0["kayit"]
	var ornek := func(b: Node) -> Dictionary: return _b9_ornekle(b)
	var referans: Dictionary = {}
	var sapmali := 0
	var bitmeyen := 0
	var maks_sapma := 0.0
	for n in range(TEKRAR):
		var s: Dictionary = await _senaryo(kay, betik, 700, Callable(), ornek)
		if not s["bitti"]:
			bitmeyen += 1
		if n == 0:
			referans = s
			continue
		var bu: bool = s["ozel_iz"].size() != referans["ozel_iz"].size() or s["kare"] != referans["kare"]
		for f in range(mini(s["ozel_iz"].size(), referans["ozel_iz"].size())):
			if s["ozel_iz"][f] != referans["ozel_iz"][f]:
				bu = true
			var d: float = (s["oyuncu_iz"][f] - referans["oyuncu_iz"][f]).length()
			for ki in range(3):
				d = maxf(d, (s["klon_izleri"][ki][f] - referans["klon_izleri"][ki][f]).length())
			if d > 0.0:
				bu = true
				maks_sapma = maxf(maks_sapma, d)
		if bu:
			sapmali += 1
	_kaydi("Bölüm 9: determinizm (100x çözüm)", sapmali == 0 and bitmeyen == 0 and s0["bitti"],
		"%d çalıştırma x %d kare, sapmalı: %d, en büyük sapma: %.4f px, bitirmeyen çalıştırma: %d, kayıt turu bitti: %s" % [
			TEKRAR, referans["kare"], sapmali, maks_sapma, bitmeyen, s0["bitti"]])
	_kayitlar().sifirla()
	paused = false


# ---------------------------------------------------------------- Bölüm 10 (taşıma bandı)
# Taslak: docs/devir/bolum_10_taslak.md. A: kutuyu P1'e yollar, PE'ye basar; B: P2'de durur;
# C: asansörle çıkıp PG'de durur; oyuncu F2'de B2 üstünden G'ye koşar.
const BOLUM_10 := "res://scenes/bolumler/bolum_10.tscn"
const B10_ASANSOR_UST_Y := 450.0
const B10_GECIT_ACIK_Y := 240.5

var _b10_onbellek: Array = []   # [A, B, C]


func _b10_ornekle(b: Node) -> Dictionary:
	return {
		"as": b.get_node("Asansor").position.y, "g": b.get_node("Gecit").position.y,
		"p1": b.get_node("PlakaP1").basili_mi(), "p2": b.get_node("PlakaP2").basili_mi(),
		"pe": b.get_node("PlakaPE").basili_mi(), "pg": b.get_node("PlakaPG").basili_mi(),
		"l1": b.get_node("Lazer1").acik_mi(), "l2": b.get_node("Lazer2").acik_mi(),
		"kutu": b.get_node("Kutu").global_position}


func _b10_kutu_x_ge(v: float) -> Callable:
	return func(b: Node) -> bool: return b.get_node("Kutu").global_position.x >= v


func _b10_kutu_x_le(v: float) -> Callable:
	return func(b: Node) -> bool: return b.get_node("Kutu").global_position.x <= v


func _b10_kare_ge(n: int) -> Callable:
	return func(b: Node) -> bool: return b.get_node("Oyuncu").kare >= n


func _b10_l1_kapali() -> Callable:
	return func(b: Node) -> bool: return not b.get_node("Lazer1").acik_mi()


## Ortak giriş: kutuyu bantla P1'e yolla, L1 kapanınca kutu+duvarın üstünden zıpla, x~508'e in.
func _b10_giris(zipla_x := 285.0) -> Array:
	return [_b4_a(1, _b10_kutu_x_ge(300.0), 80), _b4_a(-1, Callable(), 4),
		_b4_a(0, _b10_l1_kapali(), 250), _b4_a(1, _b4_x_ge(zipla_x), 100),
		_b4_a(1, Callable(), 1, true), _b4_a(1, Callable(), 45)]


func _b10_a(basma_kare := 230) -> Array:
	return _b10_giris() + [_b4_a(1, _b4_x_ge(560.0), 60), _b4_a(0, _b10_kare_ge(basma_kare), 400),
		_b4_a(1, Callable(), 10), _b4_a(0, _b4_plakada("PlakaPE"), 60), _b4_a(0, Callable(), 10)]


func _b10_b() -> Array:
	return [_b4_a(0, _b10_kare_ge(50), 100)] + _b10_giris() + [_b4_a(1, _b4_x_ge(510.0), 60),
		_b4_a(0, _b4_plakada("PlakaP2"), 60), _b4_a(0, Callable(), 10)]


func _b10_c() -> Array:
	return [_b4_a(0, _b10_kare_ge(50), 100)] + _b10_giris() + [_b4_a(1, _b4_x_ge(555.0), 60),
		_b4_a(1, Callable(), 1, true), _b4_a(1, _b4_x_ge(750.0), 150),
		_b4_a(0, _b4_yukari("Asansor", B10_ASANSOR_UST_Y), 500),
		_b4_a(1, _b4_plakada("PlakaPG"), 120), _b4_a(0, Callable(), 10)]


func _b10_oyuncu() -> Array:
	return _b10_giris() + [_b4_a(1, _b4_x_ge(750.0), 150),
		_b4_a(0, _b4_yukari("Asansor", B10_ASANSOR_UST_Y), 500), _b4_a(1, _b4_bitti_k(), 400)]


func _b10_kosullu(bolum: Node, adimlar: Array, sayac: Array) -> Dictionary:
	var oyuncu: CharacterBody2D = bolum.get_node("Oyuncu")
	var klonlar: Array = _klonlar(bolum)
	var klon_iz: Array = []
	for k in klonlar:
		klon_iz.append([])
	var iz: Array = []
	var ozel: Array = []
	var baslangic: Array = []
	var tamam: Array = []
	var kare := 0
	for a in adimlar:
		baslangic.append(iz.size())
		var n := 0
		var karsilandi: bool = not a["kosul"].is_valid()
		while n < a["maks"]:
			if not is_instance_valid(bolum) or bolum.bitti:
				break
			_girdi_uygula({"yon": a["yon"], "zipla": a["zipla"] and n == 0})
			iz.append(oyuncu.global_position)
			ozel.append(_b10_ornekle(bolum))
			for i in range(klonlar.size()):
				klon_iz[i].append(klonlar[i].global_position)
			await physics_frame
			n += 1
			kare += 1
			if a["kosul"].is_valid() and is_instance_valid(bolum) and a["kosul"].call(bolum):
				karsilandi = true
				break
		tamam.append(karsilandi)
		if not is_instance_valid(bolum) or bolum.bitti:
			break
	_girdi_uygula({"yon": 0.0, "zipla": false})
	var bitti_son: bool = is_instance_valid(bolum) and bolum.bitti
	var kayit: Array = []
	if is_instance_valid(oyuncu):
		kayit = oyuncu.kayit_girdileri.duplicate(true)
	for i in range(3):
		await physics_frame
	return {"kare": kare, "bitti": bitti_son and sayac[0] == 0, "bitti_ham": bitti_son, "oldu": sayac[0],
		"iz": iz, "ozel": ozel, "klon_izleri": klon_iz, "baslangic": baslangic, "tamam": tamam, "kayit": kayit}


func _b10_senaryo(kayitlar: Array, adimlar: Array, hazirlik := Callable()) -> Dictionary:
	_kayitlar().sifirla()
	for k in kayitlar:
		_kayitlar().tur_kaydet(k.duplicate(true))
	var bolum: Node = await _bolumu_yukle()
	if hazirlik.is_valid():
		hazirlik.call(bolum)
	var sayac := [0]
	bolum.get_node("Oyuncu").oyuncu_oldu.connect(func() -> void: sayac[0] += 1)
	var s: Dictionary = await _b10_kosullu(bolum, adimlar, sayac)
	paused = false
	return s


## [A, B, C] kayıtları (gerçek bölümdeki gibi ardışık).
func _b10_kayitlar() -> Array:
	if _b10_onbellek.is_empty():
		var s1: Dictionary = await _b10_senaryo([], _b10_a())
		var s2: Dictionary = await _b10_senaryo([s1["kayit"]], _b10_b())
		var s3: Dictionary = await _b10_senaryo([s1["kayit"], s2["kayit"]], _b10_c())
		_b10_onbellek = [s1["kayit"], s2["kayit"], s3["kayit"]]
	return _b10_onbellek


func _b10_yerlestir(oyuncu: Vector2, kutu := Vector2(-1.0, -1.0)) -> Callable:
	return func(b: Node) -> void:
		b.get_node("Oyuncu").global_position = oyuncu
		if kutu.x >= 0.0:
			b.get_node("Kutu").global_position = kutu


func _b10_kutu_son(s: Dictionary) -> Vector2:
	return s["ozel"][s["ozel"].size() - 1]["kutu"]


## 1) Gerçek yol: R ile 3 klon (A, B, C), 4. turda kapıya.
func _test_bolum10_cozum() -> void:
	_kayitlar().sifirla()
	var bolum: Node = await _bolumu_yukle()
	var turlar: Array = [_b10_a(), _b10_b(), _b10_c()]
	var kareler: Array = []
	var olumsuz := ""
	for i in range(3):
		var sayac := [0]
		bolum.get_node("Oyuncu").oyuncu_oldu.connect(func() -> void: sayac[0] += 1)
		var s: Dictionary = await _b10_kosullu(bolum, turlar[i], sayac)
		kareler.append(s["kare"])
		if s["tamam"].has(false) or s["oldu"] > 0 or s["kare"] > 600:
			olumsuz += " tur%d adım karşılanmadı %s oldu=%d kare=%d;" % [i + 1, str(s["tamam"]), s["oldu"], s["kare"]]
		var eski_id := bolum.get_instance_id()
		await _r_bas()
		bolum = await _yeni_sahne_bekle(eski_id)
		if bolum == null:
			_kaydi("Bölüm 10 çözümü (4 tur, 3 klon, gerçek R/girdi yolu)", false, "tur %d sonrası sahne yüklenmedi;%s" % [i + 1, olumsuz])
			return
	var klon_basta: int = _klonlar(bolum).size()
	var etiket: String = bolum.bilgi.text
	var sayac4 := [0]
	bolum.get_node("Oyuncu").oyuncu_oldu.connect(func() -> void: sayac4[0] += 1)
	var s4: Dictionary = await _b10_kosullu(bolum, _b10_oyuncu(), sayac4)
	if s4["tamam"].slice(0, s4["tamam"].size() - 1).has(false):
		olumsuz += " tur4 adım karşılanmadı %s;" % str(s4["tamam"])
	var l1_k: bool = _b7_hic_degil(s4["ozel"], "l1")
	var l2_k: bool = _b7_hic_degil(s4["ozel"], "l2")
	var as_ust: float = _b7_min(s4["ozel"], "as")
	var g_min: float = _b7_min(s4["ozel"], "g")
	var gecti: bool = s4["bitti"] and klon_basta == 3 and _kayitlar().turlar.size() == 3 \
		and etiket.contains("Klon: 3/3") and olumsuz == "" and s4["kare"] <= 600 and s4["oldu"] == 0 \
		and l1_k and l2_k and as_ust <= B10_ASANSOR_UST_Y + 1.0 and g_min <= B10_GECIT_ACIK_Y + 1.0
	_kaydi("Bölüm 10 çözümü (4 tur, 3 klon, gerçek R/girdi yolu)", gecti,
		"bitti: %s, tur kareleri: %s + %d (%.2f sn), klon: %d, kayıtlı tur: %d, ölüm: %d, etiket: \"%s\", L1 kapandı: %s, L2 kapandı: %s, asansör y min=%.0f (üst 450), geçit y min=%.0f (açık 240), adım başlangıçları: %s%s" % [
			s4["bitti"], str(kareler), s4["kare"], s4["kare"] / 60.0, klon_basta, _kayitlar().turlar.size(),
			s4["oldu"], etiket, l1_k, l2_k, as_ust, g_min, str(s4["baslangic"]), olumsuz])
	_kayitlar().sifirla()
	paused = false


## 2) Bant ölçümleri.
func _test_bolum10_bant() -> void:
	# a) Kutu bantta girdisiz: ~1,667 px/kare, duvara dayanır, P1 basılı, titreme yok.
	var sa: Dictionary = await _b10_senaryo([], [_b4_a(0, Callable(), 220)], _b10_yerlestir(Vector2(50, 570), Vector2(300, 580)))
	var xs: Array = []
	for o in sa["ozel"]:
		xs.append(o["kutu"].x)
	var hiz_ort := 0.0
	var hiz_n := 0
	for f in range(3, 40):
		hiz_ort += xs[f + 1] - xs[f]
		hiz_n += 1
	hiz_ort /= maxf(hiz_n, 1)
	var son_x: float = xs[xs.size() - 1]
	var tit := 0.0
	var p1_hep := true
	var l1_hep_kapali := true
	for f in range(xs.size() - 120, xs.size()):
		tit = maxf(tit, absf(xs[f] - son_x))
		p1_hep = p1_hep and sa["ozel"][f]["p1"]
		l1_hep_kapali = l1_hep_kapali and not sa["ozel"][f]["l1"]
	_kaydi("Bölüm 10 bant: kutu girdisiz 1,667 px/kare gider, duvara dayanır, P1 basılı, titremez",
		absf(hiz_ort - 1.6667) < 0.05 and son_x > 405.0 and son_x <= 410.5 and tit < 0.1 and p1_hep and l1_hep_kapali,
		"ortalama hız=%.4f px/kare, son x=%.2f (duvar 430 -> 410), son 120 karede x oynaması=%.4f px, P1 hep basılı: %s, L1 hep kapalı: %s" % [
			hiz_ort, son_x, tit, p1_hep, l1_hep_kapali])

	# b) Bantta bekleyen oyuncu ışına sürüklenir ve ölür.
	var sb: Dictionary = await _b10_senaryo([], [_b4_a(0, Callable(), 80)], _b10_yerlestir(Vector2(290, 576)))
	var d: float = (sb["iz"][14].x - sb["iz"][4].x) / 10.0
	_kaydi("Bölüm 10 bant: bantta bekleyen oyuncu ışına sürüklenir (ölür)", sb["oldu"] >= 1 and absf(d - 1.6667) < 0.1,
		"başlangıç hızı=%.3f px/kare, ölüm: %d, bitti: %s" % [d, sb["oldu"], sb["bitti"]])

	# c) B2 üstünde yön girdisi: sağa (ters) 3,33, sola (bant yönü) 6,67 px/kare. B1'de sağa 6,67.
	var sc: Dictionary = await _b10_senaryo([], [_b4_a(1, Callable(), 25)], _b10_yerlestir(Vector2(920, 416)))
	var dc: float = (sc["iz"][20].x - sc["iz"][8].x) / 12.0
	var sd: Dictionary = await _b10_senaryo([], [_b4_a(-1, Callable(), 25)], _b10_yerlestir(Vector2(1020, 416)))
	var dd: float = (sd["iz"][12].x - sd["iz"][4].x) / 8.0
	var se: Dictionary = await _b10_senaryo([], [_b4_a(1, Callable(), 7)], _b10_yerlestir(Vector2(290, 576), Vector2(150, 580)))
	var de: float = (se["iz"][4].x - se["iz"][1].x) / 3.0
	_kaydi("Bölüm 10 bant: B2 üstünde ters girdi 3,33; bant yönünde 6,67; B1'de sağa 6,67 px/kare",
		absf(dc - 3.3333) < 0.1 and absf(dd + 6.6667) < 0.1 and absf(de - 6.6667) < 0.1,
		"B2 sağ: %.3f (beklenen +3,333), B2 sol: %.3f (beklenen -6,667), B1 sağ: %.3f (beklenen +6,667)" % [dc, dd, de])
	_kayitlar().sifirla()


## 3) Atlanamazlık.
func _test_bolum10_atlanamaz() -> void:
	# a) Klonsuz: oyuncu kutuyu P1'e gönderip geçer ama PE'ye kimse basmaz -> asansör inik, bitmez.
	var sa: Dictionary = await _b10_senaryo([], _b10_giris() + [_b4_a(1, _b4_x_ge(540.0), 60),
		_b4_a(1, Callable(), 1, true), _b4_a(1, _b4_x_ge(750.0), 150), _b4_a(0, Callable(), 200)])
	var as_a: float = _b7_min(sa["ozel"], "as")
	_kaydi("Bölüm 10 atlanamaz: klonsuz bitmez (asansör kalkmaz)", not sa["bitti_ham"] and as_a > 609.0 and _b4_ayak_min(sa["iz"]) >= 490.0,
		"bitti: %s, ölüm: %d, asansör y min=%.0f (inik 610), ayak y min=%.1f" % [
			sa["bitti_ham"], sa["oldu"], as_a, _b4_ayak_min(sa["iz"])])

	# b) Zeminden zıplayarak F2'ye (ayak y<440) çıkılamaz.
	var sb: Dictionary = await _b10_senaryo([], [_b4_a(1, _b4_x_ge(786.0), 200)] + _b8_zipla_dizisi(6, 1.0, 50),
		_b10_yerlestir(Vector2(740, 576)))
	var mb := _b4_ayak_min(sb["iz"])
	_kaydi("Bölüm 10 atlanamaz: zeminden zıplayarak F2'ye (ayak y<440) çıkılamaz", mb >= 490.0 and not sb["bitti_ham"],
		"ayak y min=%.1f (zıplama tepesi ~500, F2 440), ölüm: %d" % [mb, sb["oldu"]])

	# c) Kutu basamak: kutu Kat2'ye dayalı, üstüne çıkıp zıpla; ayak y>=440 kalır.
	var adim_c: Array = _b8_zipla_dizisi(2, 1.0, 25) + _b8_zipla_dizisi(5, 1.0, 40)
	var sc: Dictionary = await _b10_senaryo([], adim_c, _b10_yerlestir(Vector2(740, 576), Vector2(790, 580)))
	var mc := _b4_ayak_min(sc["iz"])
	_kaydi("Bölüm 10 atlanamaz: kutu basamak yapılarak F2'ye çıkılamaz", mc >= 445.0 and not sc["bitti_ham"],
		"ayak y min=%.1f (kutu üstü 560 + zıplama ~460; F2 440), ölüm: %d, son kutu x=%.0f" % [mc, sc["oldu"], _b10_kutu_son(sc).x])

	# d) Kutu bantta sola itilir (P1'e basmaz): L1 açık kalır, zıplayarak aşılamaz (ölür).
	var sd: Dictionary = await _b10_senaryo([], _b8_zipla_dizisi(6, 1.0, 40), _b10_yerlestir(Vector2(320, 576)))
	var bas_d := 1.0e9
	for p in sd["iz"]:
		bas_d = minf(bas_d, p.y - 24.0)
	_kaydi("Bölüm 10 atlanamaz: L1 zıplayarak aşılamaz (açıkken ölür)", sd["oldu"] >= 1 and not sd["bitti_ham"] and bas_d >= 300.0 \
		and _b7_hic(sd["ozel"], "l1"),
		"ölüm: %d, baş y min=%.1f (tavan 300), L1 açıktı: %s" % [sd["oldu"], bas_d, _b7_hic(sd["ozel"], "l1")])

	# e) P2 boşken L2 açıktır: zeminde dikey zıplayan oyuncu ışına girer ve ölür (asansörle çıkış YOK,
	# asansör inik; L2 kapalıyken durum _test_bolum10_atlanamaz_l2_kapali içinde).
	var se: Dictionary = await _b10_senaryo([], _b8_zipla_dizisi(5, 0.0, 40), _b10_yerlestir(Vector2(750, 576)))
	_kaydi("Bölüm 10 atlanamaz: P2 boşken L2 açıktır, zıplayan oyuncu ışına girip ölür", se["oldu"] >= 1 and not se["bitti_ham"],
		"ölüm: %d, L2 açıktı: %s" % [se["oldu"], _b7_hic(se["ozel"], "l2")])

	# f) G: PG'den ayrılıp G'ye sprint: G kapanır, geçilemez.
	var sf: Dictionary = await _b10_senaryo([], [_b4_a(1, Callable(), 200)], _b10_yerlestir(Vector2(850, 416)))
	var maks_x := -1.0
	for p in sf["iz"]:
		maks_x = maxf(maks_x, p.x)
	_kaydi("Bölüm 10 atlanamaz: PG'den G'ye sprint geçemez (G kapanır)", not sf["bitti_ham"] and maks_x < 1045.0 and sf["oldu"] == 0 \
		and _b7_min(sf["ozel"], "g") < B10_GECIT_ACIK_Y + 150.0,
		"en büyük x=%.1f (G sol yüzü 1055 -> merkez 1041), bitti: %s, ölüm: %d, geçit y min=%.0f, son geçit y=%.0f" % [
			maks_x, sf["bitti_ham"], sf["oldu"], _b7_min(sf["ozel"], "g"), sf["ozel"][sf["ozel"].size() - 1]["g"]])
	_kayitlar().sifirla()


## 3b) L2 KAPALIYKEN atlanamazlık: B tek başına kaydedilir (kendi kutusunu P1'e iter, P2'de durur); klon P2'yi
## basılı tutarken L2 kapanır. Böylece zeminden/kutudan F2'ye çıkma denemeleri ışında ölerek "boş geçmez".
func _test_bolum10_atlanamaz_l2_kapali() -> void:
	var sb0: Dictionary = await _b10_senaryo([], _b10_b())
	var kb: Array = sb0["kayit"]
	var p2_bas := func(b: Node) -> bool: return b.get_node("PlakaP2").basili_mi()
	_kaydi("Bölüm 10 hazırlık: tek başına B kaydı P2'ye basar", not sb0["tamam"].has(false) and sb0["oldu"] == 0 \
		and _b7_hic(sb0["ozel"], "p2"),
		"adımlar %s, ölüm: %d, P2 basıldı: %s, kare: %d" % [str(sb0["tamam"]), sb0["oldu"], _b7_hic(sb0["ozel"], "p2"), sb0["kare"]])

	# b) L2 kapalı: zeminden zıplayarak F2'ye (ayak y<440) çıkılamaz.
	var adim_b: Array = [_b4_a(0, p2_bas, 500), _b4_a(1, _b4_x_ge(786.0), 200)] + _b8_zipla_dizisi(6, 1.0, 50)
	var sb: Dictionary = await _b10_senaryo([kb], adim_b, _b10_yerlestir(Vector2(740, 576)))
	var mb := _b4_ayak_min(sb["iz"], sb["baslangic"][1] if sb["baslangic"].size() > 1 else 0)
	var l2_kapali_b := false
	for o in sb["ozel"]:
		if not o["l2"]:
			l2_kapali_b = true
	_kaydi("Bölüm 10 atlanamaz (L2 kapalı, P2'ye basan klonla): zeminden zıplayarak F2'ye çıkılamaz",
		sb["tamam"][0] and l2_kapali_b and sb["oldu"] == 0 and mb >= 490.0 and mb < 599.0 and not sb["bitti_ham"],
		"adımlar %s, L2 kapandı: %s, ölüm: %d (beklenen 0), ayak y min=%.1f (zıplama tepesi ~500, F2 440), bitti: %s" % [
			str(sb["tamam"]), l2_kapali_b, sb["oldu"], mb, sb["bitti_ham"]])

	# c) L2 kapalı: kutu Kat2'ye dayalı (klon P2'yi tutarken oyuncu ve kutu yerleştirilir), kutu basamak.
	var tasi := func(b: Node) -> bool:
		b.get_node("Oyuncu").global_position = Vector2(740, 576)
		b.get_node("Kutu").global_position = Vector2(790, 580)
		return true
	var adim_c: Array = [_b4_a(0, p2_bas, 500), _b4_a(0, tasi, 5), _b4_a(0, Callable(), 10)] \
		+ _b8_zipla_dizisi(2, 1.0, 25) + _b8_zipla_dizisi(5, 1.0, 40)
	var sc: Dictionary = await _b10_senaryo([kb], adim_c)
	var mc := _b4_ayak_min(sc["iz"], sc["baslangic"][3] if sc["baslangic"].size() > 3 else 0)
	var l2_kapali_c := false
	for o in sc["ozel"]:
		if not o["l2"]:
			l2_kapali_c = true
	_kaydi("Bölüm 10 atlanamaz (L2 kapalı, P2'ye basan klonla): kutu basamak yapılarak F2'ye çıkılamaz",
		sc["tamam"][0] and l2_kapali_c and sc["oldu"] == 0 and mc >= 445.0 and mc < 599.0 and not sc["bitti_ham"],
		"adımlar %s, L2 kapandı: %s, ölüm: %d (beklenen 0), ayak y min=%.1f (kutu üstü 560 + zıplama ~460; F2 440), son kutu x=%.0f, bitti: %s" % [
			str(sc["tamam"]), l2_kapali_c, sc["oldu"], mc, _b10_kutu_son(sc).x, sc["bitti_ham"]])

	# d) G'ye ZIPLAYARAK sprint: PG'den ayrılıp zıpla+sağ; x>=1041 iken G y>=292 olmalı (geçilemez).
	var g_acik := func(b: Node) -> bool: return b.get_node("Gecit").position.y <= B10_GECIT_ACIK_Y + 0.5
	var ayr_d: Array = []
	var ok_d := true
	for gecikme in [0, 8, 16, 24]:
		var adim_d: Array = [_b4_a(0, g_acik, 150), _b4_a(1, Callable(), gecikme), _b4_a(1, Callable(), 1, true),
			_b4_a(1, Callable(), 200)]
		var sd: Dictionary = await _b10_senaryo([], adim_d, _b10_yerlestir(Vector2(850, 416)))
		var maks := -1.0
		for p in sd["iz"]:
			maks = maxf(maks, p.x)
		var ilk := -1
		for f in range(sd["iz"].size()):
			if sd["iz"][f].x >= 1040.5:
				ilk = f
				break
		var g_ilk: float = sd["ozel"][ilk]["g"] if ilk >= 0 else -1.0
		var ok: bool = not sd["bitti_ham"] and sd["oldu"] == 0 and maks < 1045.0 and sd["tamam"][0] \
			and (ilk < 0 or g_ilk >= 292.0)
		ok_d = ok_d and ok
		ayr_d.append("gecikme %d: en büyük x=%.1f, x>=1040,5 kare=%d, G y=%.0f (geçiş için <=292), bitti=%s, ölüm=%d" % [
			gecikme, maks, ilk, g_ilk, sd["bitti_ham"], sd["oldu"]])
	_kaydi("Bölüm 10 atlanamaz: PG'den ayrılıp G'ye ZIPLAYARAK sprint geçemez", ok_d, "; ".join(ayr_d))
	_kayitlar().sifirla()


## 4) Kısayol taraması.
func _test_bolum10_kisayol() -> void:
	var kay: Array = await _b10_kayitlar()
	var a: Array = kay[0]
	var b: Array = kay[1]
	var c: Array = kay[2]
	var ayr: Array = []
	var hepsi := true
	var kombinler := [["klonsuz", []], ["yalnız A", [a]], ["A+B (C yok)", [a, b]], ["B+C (A yok)", [b, c]],
		["A+C (B yok)", [a, c]]]
	for k in kombinler:
		var s: Dictionary = await _b10_senaryo(k[1], _b10_oyuncu())
		var ok: bool = not s["bitti_ham"]
		hepsi = hepsi and ok
		ayr.append("%s: bitti=%s (ölüm %d, kare %d)" % [k[0], s["bitti_ham"], s["oldu"], s["kare"]])
	_kaydi("Bölüm 10 kısayol: eksik klonla (A; A+B; B+C; A+C) bitmez", hepsi, "; ".join(ayr))

	# Röle: tek klon önce PE'ye basar, sonra P2'ye gider (ikisini aynı anda tutamaz).
	var role: Array = _b10_giris() + [_b4_a(1, _b4_x_ge(560.0), 60), _b4_a(0, _b10_kare_ge(230), 400),
		_b4_a(1, Callable(), 10), _b4_a(0, _b4_plakada("PlakaPE"), 60), _b4_a(0, Callable(), 60),
		_b4_a(-1, _b4_x_le(510.0), 100), _b4_a(0, _b4_plakada("PlakaP2"), 60), _b4_a(0, Callable(), 10)]
	var sr: Dictionary = await _b10_senaryo([], role)
	var r1: Dictionary = await _b10_senaryo([sr["kayit"]], _b10_oyuncu())
	var r2: Dictionary = await _b10_senaryo([sr["kayit"], c], _b10_oyuncu())
	var r3: Dictionary = await _b10_senaryo([sr["kayit"], b, c], _b10_oyuncu())
	var ok_r: bool = not r1["bitti_ham"] and not r2["bitti_ham"] and not r3["bitti_ham"]
	_kaydi("Bölüm 10 kısayol: röle (önce PE sonra P2) tek başına / C ile / B+C ile bitmez", ok_r,
		"röle kaydı adımları %s; röle: bitti=%s (ölüm %d); röle+C: bitti=%s (ölüm %d); röle+B+C: bitti=%s (ölüm %d)" % [
			str(sr["tamam"]), r1["bitti_ham"], r1["oldu"], r2["bitti_ham"], r2["oldu"], r3["bitti_ham"], r3["oldu"]])
	_kayitlar().sifirla()


## 5) Başarısızlık senaryoları.
func _test_bolum10_basarisizlik() -> void:
	var kay: Array = await _b10_kayitlar()
	var a: Array = kay[0]
	var b: Array = kay[1]
	var c: Array = kay[2]
	_kaydi("Bölüm 10 hazırlık: A, B, C kayıtları üretildi", a.size() > 0 and b.size() > 0 and c.size() > 0,
		"kare sayıları: %d, %d, %d" % [a.size(), b.size(), c.size()])

	# 1) Kutu bandın dışına sola itilir: P1 hiç basılmaz, L1 hiç kapanmaz.
	var itme: Array = [_b4_a(-1, _b10_kutu_x_le(200.0), 100), _b4_a(0, Callable(), 150)]
	var s1: Dictionary = await _b10_senaryo([], itme, _b10_yerlestir(Vector2(320, 576), Vector2(285, 580)))
	var k1: Vector2 = _b10_kutu_son(s1)
	var ok1: bool = k1.x < 270.0 and not _b7_hic(s1["ozel"], "p1") and _b7_hic(s1["ozel"], "l1") \
		and not _b7_hic_degil(s1["ozel"], "l1")
	_kaydi("Bölüm 10 başarısızlık: kutu bandın dışına sola itilir, L1 hiç kapanmaz", ok1,
		"adımlar %s, son kutu=(%.0f,%.0f), P1 hiç basılmadı: %s, L1 hep açık: %s" % [
			str(s1["tamam"]), k1.x, k1.y, not _b7_hic(s1["ozel"], "p1"), not _b7_hic_degil(s1["ozel"], "l1")])

	# 2) A, C binmeden PE'ye basar: asansör C'den önce çıkar, C binemez, bitmez.
	var a_erken: Dictionary = await _b10_senaryo([], _b10_a(140))
	var c2: Dictionary = await _b10_senaryo([a_erken["kayit"], b], _b10_c())
	var c_ayak := _b4_ayak_min(c2["iz"])
	var s2: Dictionary = await _b10_senaryo([a_erken["kayit"], b, c2["kayit"]], _b10_oyuncu())
	_kaydi("Bölüm 10 başarısızlık: A, C binmeden basar -> C binemez, bitmez",
		c_ayak >= 490.0 and not s2["bitti_ham"] and not _b7_hic(c2["ozel"], "pg"),
		"C turu adımları %s, C ayak y min=%.1f (zıplama tepesi ~499; asansör üstü 440 olsaydı <460), PG basıldı: %s; oyuncu turu bitti: %s (ölüm %d)" % [
			str(c2["tamam"]), c_ayak, _b7_hic(c2["ozel"], "pg"), s2["bitti_ham"], s2["oldu"]])

	# 3) Zıplamadan yürüyen kutu+duvarda durur (kutu 40 px yüksekliğinde engel).
	var s3: Dictionary = await _b10_senaryo([], [_b4_a(1, _b10_kutu_x_ge(300.0), 80), _b4_a(-1, Callable(), 4),
		_b4_a(0, _b10_l1_kapali(), 250), _b4_a(1, Callable(), 120)])
	var maks3 := -1.0
	for p in s3["iz"]:
		maks3 = maxf(maks3, p.x)
	_kaydi("Bölüm 10 başarısızlık: zıplamadan yürüyen kutuda durur", maks3 < 380.0 and not s3["bitti_ham"] and s3["oldu"] == 0,
		"en büyük x=%.1f (kutu sol kenarı 390 -> merkez 376), ölüm: %d" % [maks3, s3["oldu"]])

	# 4) TASLAK SAPMASI (ölçüm): kalkış penceresi iddiası fiziksel olarak geçerli değil; kutu+duvar
	# yalnız 40 px yüksekliğinde, bitişikten bile zıplanınca aşılır. Beklenen davranış = geçer.
	var ayr4: Array = []
	var hepsi4 := true
	for x0 in [240.0, 300.0, 370.0]:
		var s4: Dictionary = await _b10_senaryo([], _b10_giris(x0) + [_b4_a(1, Callable(), 60)])
		var maks4 := -1.0
		for p in s4["iz"]:
			maks4 = maxf(maks4, p.x)
		hepsi4 = hepsi4 and maks4 >= 464.0 and s4["oldu"] == 0
		ayr4.append("x0=%.0f -> en büyük x=%.0f, ölüm %d" % [x0, maks4, s4["oldu"]])
	_kaydi("Bölüm 10 ölçüm: kalkış penceresi [267,350] yok; kutu+duvar her x0'dan zıplanarak aşılır (taslak iddiası geçersiz)",
		hepsi4, "; ".join(ayr4))
	_kayitlar().sifirla()


## 6) max_klon=3.
func _test_bolum10_klon_siniri() -> void:
	_kayitlar().sifirla()
	var bolum: Node = await _bolumu_yukle()
	var maks: int = bolum.max_klon
	var gecti := maks == 3
	var ayrinti: Array = []
	for n in range(maks + 1):
		for i in range(5):
			_girdi_uygula({"yon": 1.0, "zipla": false})
			await physics_frame
		_girdi_uygula({"yon": 0.0, "zipla": false})
		var eski_id := bolum.get_instance_id()
		await _r_bas()
		var yeni: Node = await _yeni_sahne_bekle(eski_id)
		var sayi: int = _kayitlar().turlar.size()
		if n < maks:
			gecti = gecti and yeni != null and sayi == n + 1
			if yeni == null:
				break
			bolum = yeni
		else:
			var yazi: String = bolum.bilgi.text
			gecti = gecti and yeni == null and sayi == maks and yazi.contains("Klon hakkı bitti") \
				and yazi.contains("3/3")
			ayrinti.append("sınırda etiket: \"%s\"" % yazi)
		ayrinti.append("R #%d -> kayıtlı klon: %d" % [n + 1, sayi])
	_kaydi("Bölüm 10: klon sınırı (dördüncü R klon kaydetmez)", gecti, "max_klon=%d; %s" % [maks, ", ".join(ayrinti)])
	_kayitlar().sifirla()


## 7) Determinizm.
func _test_bolum10_determinizm() -> void:
	var kay: Array = await _b10_kayitlar()
	var s0: Dictionary = await _b10_senaryo(kay, _b10_oyuncu())
	var betik: Array = s0["kayit"]
	var ornek := func(b: Node) -> Dictionary: return _b10_ornekle(b)
	var referans: Dictionary = {}
	var sapmali := 0
	var bitmeyen := 0
	var maks_sapma := 0.0
	for n in range(TEKRAR):
		var s: Dictionary = await _senaryo(kay, betik, 700, Callable(), ornek)
		if not s["bitti"]:
			bitmeyen += 1
		if n == 0:
			referans = s
			continue
		var bu: bool = s["ozel_iz"].size() != referans["ozel_iz"].size() or s["kare"] != referans["kare"]
		for f in range(mini(s["ozel_iz"].size(), referans["ozel_iz"].size())):
			if s["ozel_iz"][f] != referans["ozel_iz"][f]:
				bu = true
			var d: float = (s["oyuncu_iz"][f] - referans["oyuncu_iz"][f]).length()
			for ki in range(3):
				d = maxf(d, (s["klon_izleri"][ki][f] - referans["klon_izleri"][ki][f]).length())
			if d > 0.0:
				bu = true
				maks_sapma = maxf(maks_sapma, d)
		if bu:
			sapmali += 1
	_kaydi("Bölüm 10: determinizm (100x çözüm)", sapmali == 0 and bitmeyen == 0 and s0["bitti"],
		"%d çalıştırma x %d kare, sapmalı: %d, en büyük sapma: %.4f px, bitirmeyen çalıştırma: %d, kayıt turu bitti: %s" % [
			TEKRAR, referans["kare"], sapmali, maks_sapma, bitmeyen, s0["bitti"]])
	_kayitlar().sifirla()
	paused = false


# ---------------------------------------------------------------- Bölüm 11 (yaylı zıplatıcı)
# Taslak: docs/devir/bolum_11_taslak.md. A: Z1'den sola fırlayıp Raf/PlakaPA'ya iner (L1 kapalı);
# B: Z1+Z2 ile fırlayıp havada PlakaPB'den geçer (L2 ~14 kare kapanır; PlakaPB x 668..728, y 144..176,
# F3 üstünde durarak basılamaz) ve F3'e iner; oyuncu Z2'yi zıplayarak atlar, cepte DURUR, B'nin uçuşu L2'yi
# kapatınca ışını (~7 kare) geçip kapıya gider.
const BOLUM_11 := "res://scenes/bolumler/bolum_11.tscn"

var _b11_onbellek: Array = []   # [A, B]


func _b11_ornekle(b: Node) -> Dictionary:
	return {"l1": b.get_node("Lazer1").acik_mi(), "l2": b.get_node("Lazer2").acik_mi(),
		"pa": b.get_node("PlakaPA").basili_mi(), "pb": b.get_node("PlakaPB").basili_mi()}


func _b11_a(sol_n := 24, sag_n := 48) -> Array:
	return [_b4_a(1, Callable(), sag_n), _b4_a(-1, Callable(), sol_n),
		_b4_a(0, _b4_plakada("PlakaPA"), 150), _b4_a(0, Callable(), 10)]


## B: sağ basılı sürekli (Z1, sonra Z2 kendiliğinden); gecikme = başlangıçta bekleme karesi.
## Z2 fırlatması havada PlakaPB'den geçer (L2 ~14 kare kapanır), F3'e inip birkaç kare daha yürür, durur.
func _b11_b(gecikme := 40) -> Array:
	var d: Array = []
	if gecikme > 0:
		d.append(_b4_a(0, Callable(), gecikme))
	return d + [_b4_a(1, _b4_durdu(170.0, 780.0), 400), _b4_a(1, Callable(), 10), _b4_a(0, Callable(), 10)]


## Alternatif B: F3'e inince sol basılı kenardan düşer (plakadan yine geçer), F2'ye iner.
func _b11_b_alt(gecikme := 40) -> Array:
	var d: Array = []
	if gecikme > 0:
		d.append(_b4_a(0, Callable(), gecikme))
	return d + [_b4_a(1, _b4_durdu(170.0, 780.0), 400), _b4_a(-1, _b11_f2_de(), 200), _b4_a(0, Callable(), 10)]


func _b11_f2_de() -> Callable:
	return func(b: Node) -> bool:
		var o: CharacterBody2D = b.get_node("Oyuncu")
		return o.is_on_floor() and o.global_position.y >= 300.0


func _b11_l2_kapali() -> Callable:
	return func(b: Node) -> bool: return not b.get_node("Lazer2").acik_mi()


## Oyuncu: F2'ye iner, x0'da zıplayıp Z2'yi atlar, cepte x~855'te DURUR (L1 A ile kapalı, L2 açık),
## B'nin uçuşu PlakaPB'yi basınca (L2 kapanır) gecikme kare sonra sağ ile ışını geçip kapıya gider.
## beklesin=false: kapanmayı beklemeden ışına koşar.
func _b11_oyuncu(x0 := 540.0, gecikme := 0, beklesin := true) -> Array:
	var adim: Array = [_b4_a(1, _b4_durdu(357.0), 300)]
	if x0 < 520.0:
		adim.append(_b4_a(-1, _b4_x_le(x0), 150))
	else:
		adim.append(_b4_a(1, _b4_x_ge(x0), 150))
	adim += [_b4_a(1, Callable(), 1, true), _b4_a(1, _b4_x_ge(855.0), 300)]
	if beklesin:
		adim.append(_b4_a(0, _b11_l2_kapali(), 500))
		if gecikme > 0:
			adim.append(_b4_a(0, Callable(), gecikme))
	else:
		adim.append(_b4_a(1, Callable(), 150))
	return adim + [_b4_a(1, _b4_bitti_k(), 400)]


## Klonsuz/eksik kısayol denemesi: sağ basılı, f. karede bir zıplama.
func _b11_tek_ziplama(f: int, toplam := 420) -> Array:
	return [_b4_a(1, Callable(), f), _b4_a(1, Callable(), 1, true), _b4_a(1, Callable(), toplam - f)]


func _b11_kosullu(bolum: Node, adimlar: Array, sayac: Array) -> Dictionary:
	var oyuncu: CharacterBody2D = bolum.get_node("Oyuncu")
	var klonlar: Array = _klonlar(bolum)
	var klon_iz: Array = []
	for k in klonlar:
		klon_iz.append([])
	var iz: Array = []
	var ozel: Array = []
	var baslangic: Array = []
	var tamam: Array = []
	var kare := 0
	for a in adimlar:
		baslangic.append(iz.size())
		var n := 0
		var karsilandi: bool = not a["kosul"].is_valid()
		while n < a["maks"]:
			if not is_instance_valid(bolum) or bolum.bitti:
				break
			_girdi_uygula({"yon": a["yon"], "zipla": a["zipla"] and n == 0})
			iz.append(oyuncu.global_position)
			ozel.append(_b11_ornekle(bolum))
			for i in range(klonlar.size()):
				klon_iz[i].append(klonlar[i].global_position)
			await physics_frame
			n += 1
			kare += 1
			if a["kosul"].is_valid() and is_instance_valid(bolum) and a["kosul"].call(bolum):
				karsilandi = true
				break
		tamam.append(karsilandi)
		if not is_instance_valid(bolum) or bolum.bitti:
			break
	_girdi_uygula({"yon": 0.0, "zipla": false})
	var bitti_son: bool = is_instance_valid(bolum) and bolum.bitti
	var kayit: Array = []
	if is_instance_valid(oyuncu):
		kayit = oyuncu.kayit_girdileri.duplicate(true)
	for i in range(3):
		await physics_frame
	return {"kare": kare, "bitti": bitti_son and sayac[0] == 0, "bitti_ham": bitti_son, "oldu": sayac[0],
		"iz": iz, "ozel": ozel, "klon_izleri": klon_iz, "baslangic": baslangic, "tamam": tamam, "kayit": kayit}


func _b11_senaryo(kayitlar: Array, adimlar: Array, hazirlik := Callable()) -> Dictionary:
	_kayitlar().sifirla()
	for k in kayitlar:
		_kayitlar().tur_kaydet(k.duplicate(true))
	var bolum: Node = await _bolumu_yukle()
	if hazirlik.is_valid():
		hazirlik.call(bolum)
	var sayac := [0]
	bolum.get_node("Oyuncu").oyuncu_oldu.connect(func() -> void: sayac[0] += 1)
	var s: Dictionary = await _b11_kosullu(bolum, adimlar, sayac)
	paused = false
	return s


func _b11_kayitlar() -> Array:
	if _b11_onbellek.is_empty():
		var s1: Dictionary = await _b11_senaryo([], _b11_a())
		var s2: Dictionary = await _b11_senaryo([s1["kayit"]], _b11_b())
		_b11_onbellek = [s1["kayit"], s2["kayit"]]
	return _b11_onbellek


func _b11_yerlestir(oyuncu: Vector2) -> Callable:
	return func(b: Node) -> void: b.get_node("Oyuncu").global_position = oyuncu


## Ayak y'nin en küçük (en yüksek) değeri ve en büyük x.
func _b11_ulasim(s: Dictionary) -> Vector2:
	var y := 1.0e9
	var x := -1.0e9
	for p in s["iz"]:
		y = minf(y, p.y + B4_AYAK)
		x = maxf(x, p.x)
	return Vector2(x, y)


## 1) Gerçek yol: R ile 2 klon (A, B), 3. turda kapıya.
func _test_bolum11_cozum() -> void:
	_kayitlar().sifirla()
	var bolum: Node = await _bolumu_yukle()
	var turlar: Array = [_b11_a(), _b11_b()]
	var kareler: Array = []
	var olumsuz := ""
	for i in range(2):
		var sayac := [0]
		bolum.get_node("Oyuncu").oyuncu_oldu.connect(func() -> void: sayac[0] += 1)
		var s: Dictionary = await _b11_kosullu(bolum, turlar[i], sayac)
		kareler.append(s["kare"])
		if s["tamam"].has(false) or s["oldu"] > 0 or s["kare"] > 600:
			olumsuz += " tur%d adım karşılanmadı %s oldu=%d kare=%d;" % [i + 1, str(s["tamam"]), s["oldu"], s["kare"]]
		var eski_id := bolum.get_instance_id()
		await _r_bas()
		bolum = await _yeni_sahne_bekle(eski_id)
		if bolum == null:
			_kaydi("Bölüm 11 çözümü (3 tur, 2 klon, gerçek R/girdi yolu)", false, "tur %d sonrası sahne yüklenmedi;%s" % [i + 1, olumsuz])
			return
	var klon_basta: int = _klonlar(bolum).size()
	var etiket: String = bolum.bilgi.text
	var sayac3 := [0]
	bolum.get_node("Oyuncu").oyuncu_oldu.connect(func() -> void: sayac3[0] += 1)
	var s3: Dictionary = await _b11_kosullu(bolum, _b11_oyuncu(), sayac3)
	if s3["tamam"].slice(0, s3["tamam"].size() - 1).has(false):
		olumsuz += " tur3 adım karşılanmadı %s;" % str(s3["tamam"])
	var l1_k: bool = _b7_hic_degil(s3["ozel"], "l1")
	var l2_k: bool = _b7_hic_degil(s3["ozel"], "l2")
	var gecti: bool = s3["bitti"] and klon_basta == 2 and _kayitlar().turlar.size() == 2 \
		and etiket.contains("Klon: 2/2") and olumsuz == "" and s3["kare"] <= 600 and s3["oldu"] == 0 \
		and l1_k and l2_k and (kareler[0] <= 600 and kareler[1] <= 600)
	_kaydi("Bölüm 11 çözümü (3 tur, 2 klon, gerçek R/girdi yolu)", gecti,
		"bitti: %s, tur kareleri: %s + %d (%.2f sn), klon: %d, kayıtlı tur: %d, ölüm: %d, etiket: \"%s\", L1 kapandı: %s, L2 kapandı: %s, adım başlangıçları: %s%s" % [
			s3["bitti"], str(kareler), s3["kare"], s3["kare"] / 60.0, klon_basta, _kayitlar().turlar.size(),
			s3["oldu"], etiket, l1_k, l2_k, str(s3["baslangic"]), olumsuz])
	_kayitlar().sifirla()
	paused = false


## 2) Atlanamazlık.
func _test_bolum11_atlanamaz() -> void:
	# a) F1'den (Kat2 duvarı yanından) zıplayarak F2'ye (ayak y<380) çıkılamaz; duvar 220 > 100,9.
	var sa: Dictionary = await _b11_senaryo([], [_b4_a(1, Callable(), 30)] + _b8_zipla_dizisi(6, 1.0, 50),
		_b11_yerlestir(Vector2(395, 576)))
	var ua: Vector2 = _b11_ulasim(sa)
	_kaydi("Bölüm 11 atlanamaz: F1'den duvar dibinde zıplayarak F2'ye çıkılamaz", ua.y >= 480.0 and not sa["bitti_ham"],
		"ayak y min=%.1f (zıplama tepesi ~499, F2 380), en büyük x=%.0f, ölüm: %d" % [ua.y, ua.x, sa["oldu"]])

	# b) Raf zeminden zıplayarak çıkılamaz (180 > 100,9): Raf altında dikey ve yan zıplama.
	var sb: Dictionary = await _b11_senaryo([], _b8_zipla_dizisi(4, 0.0, 50) + _b8_zipla_dizisi(1, 1.0, 25) + _b8_zipla_dizisi(2, 0.0, 50),
		_b11_yerlestir(Vector2(150, 576)))   # sağ toplam ~ +125 px: Z1 bölgesine (x>=296) girmez
	var ub: Vector2 = _b11_ulasim(sb)
	_kaydi("Bölüm 11 atlanamaz: Raf'a (üst y=420) zeminden zıplayarak çıkılamaz", ub.y >= 480.0 and not sb["bitti_ham"] \
		and not _b7_hic(sb["ozel"], "pa"),
		"ayak y min=%.1f (zıplama tepesi ~499, Raf 420), PlakaPA basıldı: %s" % [ub.y, _b7_hic(sb["ozel"], "pa")])

	# c) F2'den (Z2 bölgesi dışında, x=715) zıplayarak F3'e (ayak y 160) çıkılamaz; Kat3 yüzü x=760.
	var sc: Dictionary = await _b11_senaryo([], _b8_zipla_dizisi(8, 1.0, 40), _b11_yerlestir(Vector2(715, 356)))
	var uc: Vector2 = _b11_ulasim(sc)
	_kaydi("Bölüm 11 atlanamaz: F2'den zıplayarak F3'e (ayak y<=160) çıkılamaz (Z2 dışı)", uc.y >= 270.0 and not sc["bitti_ham"],
		"ayak y min=%.1f (F2 380 - 101 = ~279, F3 160), en büyük x=%.0f, ölüm: %d" % [uc.y, uc.x, sc["oldu"]])

	# d) Yalnız Z1 fırlatması F3'e erişemez: sağ basılı, Z2'ye varmadan x=560'ta durur; ayak y>=340.
	var sd: Dictionary = await _b11_senaryo([], [_b4_a(1, _b4_x_ge(560.0), 250), _b4_a(0, Callable(), 30)])
	var ud: Vector2 = _b11_ulasim(sd)
	_kaydi("Bölüm 11 atlanamaz: yalnız Z1 fırlatması F3'e erişemez (ayak y>=340)", ud.y >= 340.0 and not sd["bitti_ham"] \
		and sd["oldu"] == 0,
		"ayak y min=%.1f (beklenen ~353; F3 160), en büyük x=%.0f" % [ud.y, ud.x])

	# e) Cepte ışınlar açıkken zıplayarak geçilemez.
	var se: Dictionary = await _b11_senaryo([], [_b4_a(1, Callable(), 1)] + _b8_zipla_dizisi(8, 1.0, 20),
		_b11_yerlestir(Vector2(790, 356)))
	var ue: Vector2 = _b11_ulasim(se)
	_kaydi("Bölüm 11 atlanamaz: cepte ışınlar açıkken zıplayarak geçilemez (ölür)", se["oldu"] >= 1 and not se["bitti_ham"] \
		and _b7_hic(se["ozel"], "l1") and _b7_hic(se["ozel"], "l2"),
		"ölüm: %d, ayak y min=%.1f (cep 100 px), bitti: %s" % [se["oldu"], ue.y, se["bitti_ham"]])

	# f) Cep tavanı: cepte zıplamak 280'in üstüne çıkamaz (Kat3 alt kenarı).
	var sf: Dictionary = await _b11_senaryo([], [_b4_a(0, Callable(), 1)] + _b8_zipla_dizisi(4, 0.0, 50),
		_b11_yerlestir(Vector2(800, 356)))
	var uf: Vector2 = _b11_ulasim(sf)
	var bas_f := 1.0e9
	for p in sf["iz"]:
		bas_f = minf(bas_f, p.y - B4_AYAK)
	_kaydi("Bölüm 11 atlanamaz: cep tavanı (Kat3 alt kenarı y=280) aşılamaz", bas_f >= 279.0 and sf["oldu"] == 0,
		"baş y min=%.1f (tavan 280), ayak y min=%.1f" % [bas_f, uf.y])
	_kayitlar().sifirla()


## 3) Başarısızlık senaryoları.
func _test_bolum11_basarisizlik() -> void:
	var kay: Array = await _b11_kayitlar()
	var a: Array = kay[0]
	var b: Array = kay[1]
	_kaydi("Bölüm 11 hazırlık: A ve B kayıtları üretildi", a.size() > 0 and b.size() > 0,
		"kare sayıları: %d, %d" % [a.size(), b.size()])

	# 1) Klonsuz: cepte durup bekler (bitmez), ışına koşarsa ölür.
	var s1: Dictionary = await _b11_senaryo([], _b11_oyuncu())
	var kos: Array = _b11_oyuncu(540.0, 0, false)   # kapanmayı beklemeden ışına koşar
	var s1b: Dictionary = await _b11_senaryo([], kos)
	_kaydi("Bölüm 11 başarısızlık: klonsuz bitmez; ışına koşan oyuncu ölür", not s1["bitti_ham"] and s1b["oldu"] >= 1 \
		and not s1b["bitti_ham"],
		"bekleyen: bitti=%s ölüm=%d; koşan: bitti=%s ölüm=%d" % [s1["bitti_ham"], s1["oldu"], s1b["bitti_ham"], s1b["oldu"]])

	# 2) Yalnız A: L2 açık kalır.
	var s2: Dictionary = await _b11_senaryo([a], _b11_oyuncu())
	var s2b: Dictionary = await _b11_senaryo([a], kos)
	_kaydi("Bölüm 11 başarısızlık: yalnız A -> L2 açık kalır, bitmez / ışında ölür",
		not s2["bitti_ham"] and not s2b["bitti_ham"] and s2b["oldu"] >= 1 and _b7_hic(s2["ozel"], "pa") \
		and not _b7_hic_degil(s2["ozel"], "l2"),
		"bekleyen: bitti=%s ölüm=%d; koşan: bitti=%s ölüm=%d; PlakaPA basıldı: %s; L2 hep açık: %s" % [
			s2["bitti_ham"], s2["oldu"], s2b["bitti_ham"], s2b["oldu"], _b7_hic(s2["ozel"], "pa"), not _b7_hic_degil(s2["ozel"], "l2")])

	# 3) Yalnız B: L1 açık kalır.
	var s3: Dictionary = await _b11_senaryo([b], _b11_oyuncu())
	var s3b: Dictionary = await _b11_senaryo([b], kos)
	_kaydi("Bölüm 11 başarısızlık: yalnız B -> L1 açık kalır, bitmez / ışında ölür",
		not s3["bitti_ham"] and not s3b["bitti_ham"] and s3b["oldu"] >= 1 and _b7_hic(s3["ozel"], "pb") \
		and not _b7_hic_degil(s3["ozel"], "l1"),
		"bekleyen: bitti=%s ölüm=%d; koşan: bitti=%s ölüm=%d; PlakaPB basıldı: %s; L1 hep açık: %s" % [
			s3["bitti_ham"], s3["oldu"], s3b["bitti_ham"], s3b["oldu"], _b7_hic(s3["ozel"], "pb"), not _b7_hic_degil(s3["ozel"], "l1")])

	# 4) A çok uzun sol (n=40): Raf'ı kaçırır, L1 açık kalır; B doğru olsa da bitmez.
	var a_uzun: Dictionary = await _b11_senaryo([], _b11_a(40) + [_b4_a(0, Callable(), 40)])
	var s4: Dictionary = await _b11_senaryo([a_uzun["kayit"], b], _b11_oyuncu())
	_kaydi("Bölüm 11 başarısızlık: A çok uzun sol (n=40) Raf'ı kaçırır, L1 açık, bitmez",
		not a_uzun["ozel"][a_uzun["ozel"].size() - 1]["pa"] and not s4["bitti_ham"],
		"A turu sonunda PlakaPA basılı: %s (uçuşta anlık değme: %s); oyuncu turu: bitti=%s, ölüm=%d, L1 hiç kapanmadı: %s" % [
			a_uzun["ozel"][a_uzun["ozel"].size() - 1]["pa"], _b7_hic(a_uzun["ozel"], "pa"), s4["bitti_ham"], s4["oldu"],
			not _b7_hic_degil(s4["ozel"], "l1")])

	# 5) Oyuncu zıplamadan Z2 üstüne iner: F3'e fırlar, cebe girmez, bitmez.
	var s5: Dictionary = await _b11_senaryo([a, b], [_b4_a(1, Callable(), 300), _b4_a(0, Callable(), 30)])
	var u5: Vector2 = _b11_ulasim(s5)
	_kaydi("Bölüm 11 başarısızlık: Z2 üstüne inen oyuncu F3'e fırlar, bitmez", not s5["bitti_ham"] and s5["oldu"] == 0 and u5.y <= 170.0,
		"ayak y min=%.1f (F3 160), en büyük x=%.0f, ölüm: %d, bitti: %s" % [u5.y, u5.x, s5["oldu"], s5["bitti_ham"]])

	# 6) A çok kısa sol (n=10): Raf'a inmez, bitmez.
	var a_kisa: Dictionary = await _b11_senaryo([], _b11_a(10) + [_b4_a(0, Callable(), 40)])
	var s6: Dictionary = await _b11_senaryo([a_kisa["kayit"], b], _b11_oyuncu())
	_kaydi("Bölüm 11 başarısızlık: A çok kısa sol (n=10) Raf'a inmez, bitmez",
		not _b7_hic(a_kisa["ozel"], "pa") and not s6["bitti_ham"],
		"A turu PlakaPA basıldı: %s; oyuncu turu: bitti=%s, ölüm=%d" % [_b7_hic(a_kisa["ozel"], "pa"), s6["bitti_ham"], s6["oldu"]])

	# 7) B çok erken (gecikme 0 ve 20): PB basılır ama oyuncu cepte değilken L2 yeniden açılır; oyuncu ölür, bitmez.
	var erken: Array = []
	var erken_gecti := true
	for g in [0, 20]:
		var sb: Dictionary = await _b11_senaryo([a], _b11_b(g))
		var se: Dictionary = await _b11_senaryo([a, sb["kayit"]], _b11_oyuncu())
		erken_gecti = erken_gecti and _b7_hic(sb["ozel"], "pb") and not se["bitti_ham"] and se["oldu"] >= 1
		erken.append("g=%d: bitti=%s ölüm=%d" % [g, se["bitti_ham"], se["oldu"]])
	_kaydi("Bölüm 11 başarısızlık: B çok erken (gecikme 0/20) -> oyuncu pencereyi kaçırır, ölür, bitmez", erken_gecti, "; ".join(erken))

	# 8) Oyuncu ışını geç geçer (L2 kapandıktan 8-12 kare sonra): L2 yeniden açılır, ölür.
	var gec: Array = []
	var gec_gecti := true
	for d in [8, 12]:
		var sg: Dictionary = await _b11_senaryo([a, b], _b11_oyuncu(540.0, d))
		gec_gecti = gec_gecti and not sg["bitti_ham"] and sg["oldu"] >= 1
		gec.append("gecikme %d: bitti=%s ölüm=%d" % [d, sg["bitti_ham"], sg["oldu"]])
	_kaydi("Bölüm 11 başarısızlık: oyuncu ışını geç geçerse (>=8 kare gecikme) ölür", gec_gecti, "; ".join(gec))
	_kayitlar().sifirla()


## 4) Kısayol taraması.
func _test_bolum11_kisayol() -> void:
	var kay: Array = await _b11_kayitlar()
	var a: Array = kay[0]
	var b: Array = kay[1]
	var ayr: Array = []
	var hepsi := true

	# a) Klon kombinasyonları, standart oyuncu rotası.
	for k in [["klonsuz", []], ["yalnız A", [a]], ["yalnız B", [b]]]:
		var s: Dictionary = await _b11_senaryo(k[1], _b11_oyuncu())
		hepsi = hepsi and not s["bitti_ham"]
		ayr.append("%s: bitti=%s" % [k[0], s["bitti_ham"]])
	var sref: Dictionary = await _b11_senaryo([a, b], _b11_oyuncu())
	ayr.append("A+B: bitti=%s (kare %d)" % [sref["bitti_ham"], sref["kare"]])
	hepsi = hepsi and sref["bitti_ham"]
	_kaydi("Bölüm 11 kısayol: klonsuz/tek klonla bitmez, A+B ile biter", hepsi, "; ".join(ayr))

	# b) Klonsuz tek zıplama taraması (sağ basılı, f. karede zıplama).
	var bitiren := 0
	var kosu := 0
	var f3_sayisi := 0
	var en_yuksek := 1.0e9
	var ayr_b: Array = []
	for m in [0, 8, 16, 24, 32, 40, 44, 46, 48, 50, 52, 56, 60, 64, 70, 80, 90, 100, 110, 120, 130, 140, 150, 170]:
		var s: Dictionary = await _b11_senaryo([], _b11_tek_ziplama(m))
		kosu += 1
		if s["bitti_ham"]:
			bitiren += 1
		var u: Vector2 = _b11_ulasim(s)
		en_yuksek = minf(en_yuksek, u.y)
		if u.y <= 170.0:
			f3_sayisi += 1
		if s["oldu"] > 0:
			ayr_b.append("m=%d ölüm %d" % [m, s["oldu"]])
	_kaydi("Bölüm 11 kısayol: klonsuz tek-zıplama taraması (24 varyant) hiçbiri bitirmez", bitiren == 0,
		"koşu: %d, bitiren: %d, F3'e (ayak<=170) çıkan: %d, ulaşılan en yüksek ayak y=%.1f, ölenler: %s" % [
			kosu, bitiren, f3_sayisi, en_yuksek, str(ayr_b)])

	# c) Tek klon varyantları + oyuncu standart rota.
	var klon_var: Array = []
	for l in [0, 6, 12, 18, 24, 30, 36, 48, 60]:
		klon_var.append(["A sol%d" % l, _b11_a(l) + [_b4_a(0, Callable(), 60)]])
	for m in [0, 20, 40, 47, 60, 90, 120]:
		klon_var.append(["B-zıpla %d" % m, _b11_tek_ziplama(m, 300) + [_b4_a(0, Callable(), 40)]])
	klon_var.append(["B gecikme 12", _b11_b(12)])
	klon_var.append(["B gecikme 30", _b11_b(30)])
	var bit_c := 0
	var ikisi_c := 0
	var oz_c: Array = []
	for kv in klon_var:
		var sk: Dictionary = await _b11_senaryo([], kv[1])
		var so: Dictionary = await _b11_senaryo([sk["kayit"]], _b11_oyuncu())
		if so["bitti_ham"]:
			bit_c += 1
			oz_c.append(kv[0])
		for o in so["ozel"]:
			if not o["l1"] and not o["l2"]:
				ikisi_c += 1
				break
	_kaydi("Bölüm 11 kısayol: tek klon (%d varyant) + oyuncu standart rota hiçbiri bitirmez" % klon_var.size(),
		bit_c == 0 and ikisi_c == 0,
		"varyant: %d, bitiren: %d %s, iki ışının birden kapandığı varyant: %d" % [klon_var.size(), bit_c, str(oz_c), ikisi_c])

	# d) Röle: tek klon önce PlakaPA'da durur, sonra PlakaPB'ye gider.
	var role: Array = _b11_a() + [_b4_a(1, Callable(), 1), _b4_a(1, _b4_x_ge(300.0), 100)]
	var sr: Dictionary = await _b11_senaryo([], role + _b11_b(0))
	var so2: Dictionary = await _b11_senaryo([sr["kayit"]], _b11_oyuncu())
	var role_ikisi := false
	for o in so2["ozel"]:
		if not o["l1"] and not o["l2"]:
			role_ikisi = true
	_kaydi("Bölüm 11 kısayol: röle (PA sonra PB) tek klonla iki ışını birlikte kapatamaz, bitmez", not so2["bitti_ham"] and not role_ikisi,
		"röle kaydı adımları %s, kayıt kare: %d; oyuncu: bitti=%s, ölüm=%d, iki ışın birden kapandı: %s" % [
			str(sr["tamam"]), sr["kayit"].size(), so2["bitti_ham"], so2["oldu"], role_ikisi])

	# e) Oyuncu kendi plakasında: PlakaPA'da durur (B klon) ya da Z2 uçuşuyla PlakaPB'yi kendisi basar (A klon).
	var s_pa: Dictionary = await _b11_senaryo([b], _b11_a())
	var s_pb: Dictionary = await _b11_senaryo([a], _b11_b())
	# Oyuncu uçuşla PB'yi basıp F3'e iner; sonra sola düşüp cebe yürür ve ışına gider: L2 açık, ölür.
	var geri: Array = _b11_b(0) + [_b4_a(-1, _b4_x_le(750.0), 100), _b4_a(0, _b11_f2_de(), 100), _b4_a(1, Callable(), 250)]
	var s_pb2: Dictionary = await _b11_senaryo([a], geri)
	_kaydi("Bölüm 11 kısayol: oyuncu kendi plakasında (PA'da dururak / Z2 uçuşuyla PB'yi basarak) bölüm bitmez",
		not s_pa["bitti_ham"] and not s_pb["bitti_ham"] and not s_pb2["bitti_ham"] and s_pa["oldu"] == 0 \
		and s_pb["oldu"] == 0 and s_pb2["oldu"] >= 1 and _b7_hic(s_pb["ozel"], "pb"),
		"PA'da durur (B klon): bitti=%s; Z2 uçuşu (A klon): bitti=%s, PB basıldı=%s; uçuş sonrası cebe geri yürür: bitti=%s, ölüm=%d" % [
			s_pa["bitti_ham"], s_pb["bitti_ham"], _b7_hic(s_pb["ozel"], "pb"), s_pb2["bitti_ham"], s_pb2["oldu"]])
	_kayitlar().sifirla()


## PlakaPB basılı kare sayısı (x) ve en uzun ardışık basılı dizi (y).
func _b11_pb_olcu(ozel: Array) -> Vector2i:
	var toplam := 0
	var en_uzun := 0
	var seri := 0
	for o in ozel:
		if o["pb"]:
			toplam += 1
			seri += 1
			en_uzun = maxi(en_uzun, seri)
		else:
			seri = 0
	return Vector2i(toplam, en_uzun)


## Örnek dizisinde anahtarın ilk kez deger olduğu kare indeksi (yoksa -1).
func _b11_ilk(ozel: Array, anahtar: String, deger: bool) -> int:
	for f in range(ozel.size()):
		if ozel[f][anahtar] == deger:
			return f
	return -1


## 5) Hassasiyet ölçümü (zorluk verisi): A sol süresi, B başlangıç gecikmesi, oyuncu geçiş gecikmesi, zıplama x0.
func _test_bolum11_hassasiyet() -> void:
	var kay: Array = await _b11_kayitlar()
	var a_ok: Array = []
	for n in range(4, 50, 2):
		var s: Dictionary = await _b11_senaryo([], _b11_a(n) + [_b4_a(0, Callable(), 30)])
		if _b7_hic(s["ozel"], "pa") and not s["tamam"].has(false):
			a_ok.append(n)
	# B gecikmesi: B kaydı (A klon) PB'yi basar mı; sonra standart oyuncu (bekle-geç) bitirir mi.
	var b_ok: Array = []
	var b_ayr: Array = []
	for g in [0, 20, 30, 31, 32, 33, 38, 40, 60, 100]:
		var sb: Dictionary = await _b11_senaryo([kay[0]], _b11_b(g))
		var pb_f: int = _b11_ilk(sb["ozel"], "pb", true)
		var so: Dictionary = await _b11_senaryo([kay[0], sb["kayit"]], _b11_oyuncu())
		var vardi: int = so["baslangic"][4] if so["baslangic"].size() > 4 else -1
		var biter: bool = so["bitti_ham"] and so["oldu"] == 0
		if biter:
			b_ok.append(g)
		b_ayr.append("g=%d: PB ilk kare %d, oyuncu cepte %d, %s (ölüm %d)" % [g, pb_f, vardi, "BİTTİ" if biter else "bitmedi", so["oldu"]])
	# Oyuncunun L2 kapandıktan sonraki geçiş gecikmesi (B gecikmesi 40: kayıt kay[1]).
	var d_ok: Array = []
	for d in range(0, 13):
		var s: Dictionary = await _b11_senaryo(kay, _b11_oyuncu(540.0, d))
		if s["bitti_ham"] and s["oldu"] == 0:
			d_ok.append(d)
	var x_ok: Array = []
	var x_kotu: Array = []
	for x0 in range(440, 641, 5):
		var s: Dictionary = await _b11_senaryo(kay, _b11_oyuncu(float(x0)))
		if s["bitti_ham"] and s["oldu"] == 0:
			x_ok.append(x0)
		else:
			x_kotu.append("%d(ölüm %d, adım %s)" % [x0, s["oldu"], str(s["tamam"])])
	var gecti: bool = a_ok.size() > 0 and b_ok.has(40) and not b_ok.has(0) and d_ok.has(0) and not d_ok.has(12) and x_ok.size() > 0
	_kaydi("Bölüm 11 ölçüm: zamanlama pencereleri (A sol n, B gecikme, oyuncu geçiş gecikmesi, zıplama x0)", gecti,
		"A sol n çalışanlar (4..48 adım 2): %s; B başlangıç gecikmesi tam çözümü bitirenler (0,20,30,31,32,33,38,40,60,100): %s [%s]; oyuncu geçiş gecikmesi 0..12 çalışanlar: %s; oyuncu x0 çalışanlar (440..640 adım 5): %s; çalışmayanlar: %s" % [
			str(a_ok), str(b_ok), "; ".join(b_ayr), str(d_ok), str(x_ok), str(x_kotu)])
	_kayitlar().sifirla()


## 5b) PlakaPB (havada, F3 üstünde durarak basılamaz) ve uçuş darbesi uzunluğu.
func _test_bolum11_plaka_ucus() -> void:
	var kay: Array = await _b11_kayitlar()
	# a) F3 üstünde durarak: hiç basılmaz (3 konum, idle 60 kare).
	var idle_toplam := 0
	for x in [762.0, 800.0, 846.0]:
		var s: Dictionary = await _b11_senaryo([], [_b4_a(0, Callable(), 60)], _b11_yerlestir(Vector2(x, 136)))
		idle_toplam += _b11_pb_olcu(s["ozel"]).x
	# b) F3'te zıplayarak (yerinde) ve zıpla+sol: yalnız kısa değme, sonda basılı değil.
	var zip_en := 0
	var zip_son := false
	for x in [770.0, 846.0]:
		var s1: Dictionary = await _b11_senaryo([], _b8_zipla_dizisi(8, 0.0, 40), _b11_yerlestir(Vector2(x, 136)))
		zip_en = maxi(zip_en, _b11_pb_olcu(s1["ozel"]).y)
		var s2: Dictionary = await _b11_senaryo([], _b8_zipla_dizisi(6, -1.0, 40), _b11_yerlestir(Vector2(x, 136)))
		zip_en = maxi(zip_en, _b11_pb_olcu(s2["ozel"]).y)
		zip_son = zip_son or s1["ozel"][s1["ozel"].size() - 1]["pb"] or s2["ozel"][s2["ozel"].size() - 1]["pb"]
	# c) F3 kenarından sol basılı düşüş.
	var sk: Dictionary = await _b11_senaryo([], [_b4_a(-1, Callable(), 120)], _b11_yerlestir(Vector2(770, 136)))
	var kenar: Vector2i = _b11_pb_olcu(sk["ozel"])
	# d) Doğal uçuş (Z2 fırlatması) ve alternatif B (kenardan düşen).
	var sn: Dictionary = await _b11_senaryo([kay[0]], _b11_b())
	var dogal: Vector2i = _b11_pb_olcu(sn["ozel"])
	var sa: Dictionary = await _b11_senaryo([kay[0]], _b11_b_alt())
	var alt: Vector2i = _b11_pb_olcu(sa["ozel"])
	var l2_kapali := 0
	for o in sn["ozel"]:
		if not o["l2"]:
			l2_kapali += 1
	var kenar_son: bool = sk["ozel"][sk["ozel"].size() - 1]["pb"]
	var gecti: bool = idle_toplam == 0 and zip_en < 20 and not zip_son and not kenar_son and kenar.y < 20 \
		and dogal.y >= 8 and dogal.y < 20 and alt.y < 20 and not sn["tamam"].has(false)
	_kaydi("Bölüm 11 PlakaPB: F3'te durarak/zıplayarak kalıcı basılamaz; uçuş darbesi kısa", gecti,
		"idle (3 konum x 60 kare) basılı kare: %d; zıplama/zıpla+sol en uzun ardışık: %d (sonda basılı: %s); kenardan sol düşüş: toplam %d, en uzun %d (sonda basılı: %s); doğal Z2 uçuşu: toplam %d, en uzun %d, L2 kapalı kare: %d; alternatif B (kenardan düşer): toplam %d, en uzun %d" % [
			idle_toplam, zip_en, zip_son, kenar.x, kenar.y, kenar_son, dogal.x, dogal.y, l2_kapali, alt.x, alt.y])

	# e) Alternatif B (kenardan düşen) tam çözümü de bitirir.
	var so: Dictionary = await _b11_senaryo([kay[0], sa["kayit"]], _b11_oyuncu())
	_kaydi("Bölüm 11 alternatif B (F3 kenarından düşerek plakadan geçer) de çözer", so["bitti_ham"] and so["oldu"] == 0,
		"bitti=%s, ölüm=%d, kare=%d" % [so["bitti_ham"], so["oldu"], so["kare"]])
	_kayitlar().sifirla()


## 6) max_klon=2.
func _test_bolum11_klon_siniri() -> void:
	_kayitlar().sifirla()
	var bolum: Node = await _bolumu_yukle()
	var maks: int = bolum.max_klon
	var gecti := maks == 2
	var ayrinti: Array = []
	for n in range(maks + 1):
		for i in range(5):
			_girdi_uygula({"yon": 1.0, "zipla": false})
			await physics_frame
		_girdi_uygula({"yon": 0.0, "zipla": false})
		var eski_id := bolum.get_instance_id()
		await _r_bas()
		var yeni: Node = await _yeni_sahne_bekle(eski_id)
		var sayi: int = _kayitlar().turlar.size()
		if n < maks:
			gecti = gecti and yeni != null and sayi == n + 1
			if yeni == null:
				break
			bolum = yeni
		else:
			var yazi: String = bolum.bilgi.text
			gecti = gecti and yeni == null and sayi == maks and yazi.contains("Klon hakkı bitti") \
				and yazi.contains("2/2")
			ayrinti.append("sınırda etiket: \"%s\"" % yazi)
		ayrinti.append("R #%d -> kayıtlı klon: %d" % [n + 1, sayi])
	_kaydi("Bölüm 11: klon sınırı (üçüncü R klon kaydetmez)", gecti, "max_klon=%d; %s" % [maks, ", ".join(ayrinti)])
	_kayitlar().sifirla()


## 7) Determinizm.
func _test_bolum11_determinizm() -> void:
	var kay: Array = await _b11_kayitlar()
	var s0: Dictionary = await _b11_senaryo(kay, _b11_oyuncu())
	var betik: Array = s0["kayit"]
	var ornek := func(b: Node) -> Dictionary: return _b11_ornekle(b)
	var referans: Dictionary = {}
	var sapmali := 0
	var bitmeyen := 0
	var maks_sapma := 0.0
	for n in range(TEKRAR):
		var s: Dictionary = await _senaryo(kay, betik, 700, Callable(), ornek)
		if not s["bitti"]:
			bitmeyen += 1
		if n == 0:
			referans = s
			continue
		var bu: bool = s["ozel_iz"].size() != referans["ozel_iz"].size() or s["kare"] != referans["kare"]
		for f in range(mini(s["ozel_iz"].size(), referans["ozel_iz"].size())):
			if s["ozel_iz"][f] != referans["ozel_iz"][f]:
				bu = true
			var d: float = (s["oyuncu_iz"][f] - referans["oyuncu_iz"][f]).length()
			for ki in range(2):
				d = maxf(d, (s["klon_izleri"][ki][f] - referans["klon_izleri"][ki][f]).length())
			if d > 0.0:
				bu = true
				maks_sapma = maxf(maks_sapma, d)
		if bu:
			sapmali += 1
	_kaydi("Bölüm 11: determinizm (100x çözüm)", sapmali == 0 and bitmeyen == 0 and s0["bitti"],
		"%d çalıştırma x %d kare, sapmalı: %d, en büyük sapma: %.4f px, bitirmeyen çalıştırma: %d, kayıt turu bitti: %s" % [
			TEKRAR, referans["kare"], sapmali, maks_sapma, bitmeyen, s0["bitti"]])
	_kayitlar().sifirla()
	paused = false


# ---------------------------------------------------------------- Bölüm 12 (Kargo)
# Taslak: docs/devir/bolum_12_taslak.md. Y1: PlakaA'da durur (GA1+GA2 açık). Y2: kutuyu iter, GecitK'yı
# yarışıp geçer, kutuyu Zıplatıcı'dan R rafına fırlatır, kendisi fırlayıp kutu basamağıyla R2'ye çıkar,
# PlakaB'de durur. Oyuncu: Y2'yi gecikmeyle izler, GA1/GB/GA2'den geçip kapıya gider.
const BOLUM_12 := "res://scenes/bolumler/bolum_12.tscn"

var _b12_onbellek: Array = []   # [Y1, Y2]


func _b12_ornekle(b: Node) -> Dictionary:
	var o: CharacterBody2D = b.get_node("Oyuncu")
	return {"pk": b.get_node("PlakaK").basili_mi(), "pa": b.get_node("PlakaA").basili_mi(),
		"pb": b.get_node("PlakaB").basili_mi(),
		"gk": b.get_node("GecitK").position.y, "ga1": b.get_node("GecitA1").position.y,
		"gb": b.get_node("GecitB").position.y, "ga2": b.get_node("GecitA2").position.y,
		"kutu": b.get_node("Kutu").global_position, "zemin": o.is_on_floor()}


func _b12_kutu_r() -> Callable:
	return func(b: Node) -> bool:
		var k: CharacterBody2D = b.get_node("Kutu")
		return k.is_on_floor() and k.global_position.y < 405.0 and k.global_position.x > 480.0


func _b12_havada(ymax := 570.0) -> Callable:
	return func(b: Node) -> bool:
		var o: CharacterBody2D = b.get_node("Oyuncu")
		return not o.is_on_floor() and o.global_position.y < ymax


## Y1: PlakaA'ya yürüyüp durur.
func _b12_y1(bekle := 10) -> Array:
	return [_b4_a(-1, _b4_x_le(40.0), 100), _b4_a(0, _b4_plakada("PlakaA"), 40), _b4_a(0, Callable(), bekle)]


## Y2: s kare bekler, PlakaK'dan ayrılınca (x>=246) `durak` kare durur, kutuyu iter (x>=477),
## kutu R'ye inince (erken_n>0 ise yalnız o kadar kare bekleyip) Zıplatıcı'ya girer; fırlayınca
## `gec` kare bekler, sag `sag_n` kare, `sol_k` karede sol 8 kare; kutu üstünde zıplar,
## R2'den PlakaB'ye yürür.
func _b12_y2(s := 30, sag_n := 8, sol_k := 26, durak := 0, erken_n := 0, gec := 0, sol_n := 8) -> Array:
	var d: Array = []
	if s > 0:
		d.append(_b4_a(0, Callable(), s))
	d.append(_b4_a(1, _b4_x_ge(246.0), 100))
	if durak > 0:
		d.append(_b4_a(0, Callable(), durak))
	d.append(_b4_a(1, _b4_x_ge(477.0), 200))
	if erken_n > 0:
		d.append(_b4_a(0, Callable(), erken_n))
	else:
		d.append(_b4_a(0, _b12_kutu_r(), 150))
	d.append(_b4_a(1, _b12_havada(), 40))
	if gec > 0:
		d.append(_b4_a(0, Callable(), gec))
	d.append(_b4_a(1, Callable(), sag_n))
	if sol_k > sag_n:
		d.append(_b4_a(0, Callable(), sol_k - sag_n))
	d += [_b4_a(-1, Callable(), sol_n),
		_b4_a(0, _b4_durdu(360.0, 480.0), 100),
		_b4_a(0, _b4_durdu(270.0, 480.0), 60, true),
		_b4_a(1, _b4_x_ge(735.0), 150),
		_b4_a(0, _b4_plakada("PlakaB"), 40),
		_b4_a(0, Callable(), 10)]
	return d


## Girdi kaydını (kare başına {yon, zipla}) adım listesine çevirir; gecikme kare başta bekler.
func _b12_kayittan(kayit: Array, gecikme := 0, sonuna := true) -> Array:
	var d: Array = []
	if gecikme > 0:
		d.append(_b4_a(0, Callable(), gecikme))
	for g in kayit:
		d.append(_b4_a(float(g["yon"]), Callable(), 1, bool(g["zipla"])))
	if sonuna:
		d.append(_b4_a(1, _b4_bitti_k(), 400))
	return d


func _b12_kosullu(bolum: Node, adimlar: Array, sayac: Array) -> Dictionary:
	var oyuncu: CharacterBody2D = bolum.get_node("Oyuncu")
	var klonlar: Array = _klonlar(bolum)
	var klon_iz: Array = []
	for k in klonlar:
		klon_iz.append([])
	var iz: Array = []
	var ozel: Array = []
	var baslangic: Array = []
	var tamam: Array = []
	var kare := 0
	for a in adimlar:
		baslangic.append(iz.size())
		var n := 0
		var karsilandi: bool = not a["kosul"].is_valid()
		while n < a["maks"]:
			if not is_instance_valid(bolum) or bolum.bitti:
				break
			_girdi_uygula({"yon": a["yon"], "zipla": a["zipla"] and n == 0})
			iz.append(oyuncu.global_position)
			ozel.append(_b12_ornekle(bolum))
			for i in range(klonlar.size()):
				klon_iz[i].append(klonlar[i].global_position)
			await physics_frame
			n += 1
			kare += 1
			if a["kosul"].is_valid() and is_instance_valid(bolum) and a["kosul"].call(bolum):
				karsilandi = true
				break
		tamam.append(karsilandi)
		if not is_instance_valid(bolum) or bolum.bitti:
			break
	_girdi_uygula({"yon": 0.0, "zipla": false})
	var bitti_son: bool = is_instance_valid(bolum) and bolum.bitti
	var kayit: Array = []
	if is_instance_valid(oyuncu):
		kayit = oyuncu.kayit_girdileri.duplicate(true)
	for i in range(3):
		await physics_frame
	return {"kare": kare, "bitti": bitti_son and sayac[0] == 0, "bitti_ham": bitti_son, "oldu": sayac[0],
		"iz": iz, "ozel": ozel, "klon_izleri": klon_iz, "baslangic": baslangic, "tamam": tamam, "kayit": kayit}


func _b12_senaryo(kayitlar: Array, adimlar: Array, hazirlik := Callable()) -> Dictionary:
	_kayitlar().sifirla()
	for k in kayitlar:
		_kayitlar().tur_kaydet(k.duplicate(true))
	var bolum: Node = await _bolumu_yukle()
	if hazirlik.is_valid():
		hazirlik.call(bolum)
	var sayac := [0]
	bolum.get_node("Oyuncu").oyuncu_oldu.connect(func() -> void: sayac[0] += 1)
	var s: Dictionary = await _b12_kosullu(bolum, adimlar, sayac)
	paused = false
	return s


func _b12_kayitlar() -> Array:
	if _b12_onbellek.is_empty():
		var s1: Dictionary = await _b12_senaryo([], _b12_y1())
		var s2: Dictionary = await _b12_senaryo([s1["kayit"]], _b12_y2())
		_b12_onbellek = [s1["kayit"], s2["kayit"]]
	return _b12_onbellek


func _b12_yerlestir(oyuncu: Vector2, kutu := Vector2(-1.0, -1.0)) -> Callable:
	return func(b: Node) -> void:
		b.get_node("Oyuncu").global_position = oyuncu
		if kutu.x >= 0.0:
			b.get_node("Kutu").global_position = kutu


## Ayak y'nin en küçük değeri (y) ve en büyük x (x).
func _b12_ulasim(s: Dictionary) -> Vector2:
	var y := 1.0e9
	var x := -1.0e9
	for p in s["iz"]:
		y = minf(y, p.y + B4_AYAK)
		x = maxf(x, p.x)
	return Vector2(x, y)


## Y2 değişkenini (Y1 klon) kaydeder, sonra oyuncu Y2'yi `gecikme` kare gecikmeyle izler.
func _b12_tam(y2_adimlar: Array, gecikme := 2) -> Dictionary:
	var kay: Array = await _b12_kayitlar()
	var sy: Dictionary = await _b12_senaryo([kay[0]], y2_adimlar)
	var sp: Dictionary = await _b12_senaryo([kay[0], sy["kayit"]], _b12_kayittan(sy["kayit"], gecikme))
	return {"y2": sy, "p": sp, "bitti": sp["bitti_ham"] and sp["oldu"] == 0}


func _b12_kutu_son(s: Dictionary) -> Vector2:
	return s["ozel"][s["ozel"].size() - 1]["kutu"]


func _b12_ilk(ozel: Array, anahtar: String, deger: bool) -> int:
	for f in range(ozel.size()):
		if ozel[f][anahtar] == deger:
			return f
	return -1


func _b12_calistir() -> void:
	await _test_bolum12_cozum()
	await _test_bolum12_atlanamaz()
	await _test_bolum12_basarisizlik()
	await _test_bolum12_kisayol()
	await _test_bolum12_hassasiyet()
	await _test_bolum12_kutu_kilit()
	await _test_bolum12_klon_siniri()
	await _test_bolum12_determinizm()
	await _test_role_bolum6()
	await _test_role_bolum7()
	await _test_role_bolum9()
	await _test_role_bolum10()







## 1) Gerçek yol: R ile 2 klon (Y1, Y2), 3. turda kapıya.
func _test_bolum12_cozum() -> void:
	_kayitlar().sifirla()
	var bolum: Node = await _bolumu_yukle()
	var kareler: Array = []
	var olumsuz := ""
	var y2_kayit: Array = []
	var turlar: Array = [_b12_y1(), _b12_y2()]
	for i in range(2):
		var sayac := [0]
		bolum.get_node("Oyuncu").oyuncu_oldu.connect(func() -> void: sayac[0] += 1)
		var s: Dictionary = await _b12_kosullu(bolum, turlar[i], sayac)
		kareler.append(s["kare"])
		if i == 1:
			y2_kayit = s["kayit"]
		if s["tamam"].has(false) or s["oldu"] > 0 or s["kare"] > 600:
			olumsuz += " tur%d adım karşılanmadı %s oldu=%d kare=%d;" % [i + 1, str(s["tamam"]), s["oldu"], s["kare"]]
		var eski_id := bolum.get_instance_id()
		await _r_bas()
		bolum = await _yeni_sahne_bekle(eski_id)
		if bolum == null:
			_kaydi("Bölüm 12 çözümü (3 tur, 2 klon, gerçek R/girdi yolu)", false, "tur %d sonrası sahne yüklenmedi;%s" % [i + 1, olumsuz])
			return
	var klon_basta: int = _klonlar(bolum).size()
	var etiket: String = bolum.bilgi.text
	var sayac3 := [0]
	bolum.get_node("Oyuncu").oyuncu_oldu.connect(func() -> void: sayac3[0] += 1)
	var s3: Dictionary = await _b12_kosullu(bolum, _b12_kayittan(y2_kayit, 2), sayac3)
	var gecti: bool = s3["bitti"] and klon_basta == 2 and _kayitlar().turlar.size() == 2 \
		and etiket.contains("Klon: 2/2") and olumsuz == "" and s3["kare"] <= 600 and s3["oldu"] == 0 \
		and kareler[0] <= 600 and kareler[1] <= 600
	_kaydi("Bölüm 12 çözümü (3 tur, 2 klon, gerçek R/girdi yolu)", gecti,
		"bitti: %s, tur kareleri: %s + %d (%.2f sn), klon: %d, kayıtlı tur: %d, ölüm: %d, etiket: \"%s\"%s" % [
			s3["bitti"], str(kareler), s3["kare"], s3["kare"] / 60.0, klon_basta, _kayitlar().turlar.size(),
			s3["oldu"], etiket, olumsuz])
	_kayitlar().sifirla()
	paused = false


## 2) Atlanamazlık hesapları (§8).
func _test_bolum12_atlanamaz() -> void:
	# a) R'den R2'ye kutusuz zıplama (kutu zeminde uzakta; yatay x<515: Zıplatıcı dışı).
	var sa: Dictionary = await _b12_senaryo([], _b8_zipla_dizisi(6, 0.0, 50) + _b8_zipla_dizisi(3, -1.0, 40),
		_b12_yerlestir(Vector2(500, 396)))
	var ua: Vector2 = _b12_ulasim(sa)
	_kaydi("Bölüm 12 atlanamaz: R'den R2'ye kutusuz zıplayarak çıkılamaz (R2 üstü 290)",
		ua.y >= 310.0 and not sa["bitti_ham"] and sa["oldu"] == 0,
		"ayak y min=%.1f (R 420 - 100,9 = ~319; R2 290), en büyük x=%.0f" % [ua.y, ua.x])

	# b) Zıplatıcıdan fırlayış: farklı yön tuşlarıyla R2'ye çıkılamaz (ayak y>=330).
	var en_yuksek := 1.0e9
	var ayr_b: Array = []
	var r2_b := false
	for yon in [0.0, 1.0, -1.0]:
		var sb: Dictionary = await _b12_senaryo([], [_b4_a(yon, Callable(), 90), _b4_a(0, Callable(), 30)],
			_b12_yerlestir(Vector2(560, 576)))
		var ub: Vector2 = _b12_ulasim(sb)
		en_yuksek = minf(en_yuksek, ub.y)
		ayr_b.append("yon %d: ayak min %.1f" % [int(yon), ub.y])
		for p in sb["iz"]:
			if p.y + B4_AYAK <= 291.0 and p.x >= 480.0:
				r2_b = true
	_kaydi("Bölüm 12 atlanamaz: zıplatıcıdan doğrudan R2'ye (ayak y<=290) çıkılamaz", en_yuksek >= 330.0 and not r2_b,
		"ayak y min=%.1f (beklenen ~353; R2 290), %s" % [en_yuksek, "; ".join(ayr_b)])

	# c) Zeminden R: dikey/yan zıplama ve zemin kutusuyla (kutu üstü 560 -> 459 > 420).
	var sc: Dictionary = await _b12_senaryo([], _b8_zipla_dizisi(6, 0.0, 50) + _b8_zipla_dizisi(3, -1.0, 40),
		_b12_yerlestir(Vector2(500, 576), Vector2(200, 580)))
	var uc: Vector2 = _b12_ulasim(sc)
	var sc2: Dictionary = await _b12_senaryo([], _b8_zipla_dizisi(6, 0.0, 50) + _b8_zipla_dizisi(3, -1.0, 40),
		_b12_yerlestir(Vector2(495, 536), Vector2(495, 580)))
	var uc2: Vector2 = _b12_ulasim(sc2)
	_kaydi("Bölüm 12 atlanamaz: zeminden (kutusuz/zemin kutusu üstünden) R'ye çıkılamaz (R üstü 420)",
		uc.y >= 470.0 and uc2.y >= 440.0 and not sc["bitti_ham"] and not sc2["bitti_ham"],
		"zeminden ayak min=%.1f (~499); zemin kutusu üstünden ayak min=%.1f (~459), R 420" % [uc.y, uc2.y])

	# d) Kapalı geçitler (plaka boş): GK, GA1, GB, GA2 önünden zıplayarak geçilemez.
	var g_ayr: Array = []
	var g_gecti := true
	var konumlar: Array = [["GK", Vector2(330, 576), Vector2(300, 580), 370.0, 400.0],
		["GA1", Vector2(640, 266), Vector2(-1, -1), 690.0, 140.0],
		["GB", Vector2(900, 266), Vector2(-1, -1), 970.0, 140.0],
		["GA2", Vector2(1010, 266), Vector2(-1, -1), 1050.0, 140.0]]
	for g in konumlar:
		var yer: Vector2 = g[1]
		var kutu_k: Vector2 = g[2]
		var sg: Dictionary = await _b12_senaryo([], _b8_zipla_dizisi(10, 1.0, 40) + [_b4_a(1, Callable(), 60)],
			_b12_yerlestir(yer, kutu_k))
		var maks_x := -1.0e9
		var bas := 1.0e9
		for p in sg["iz"]:
			maks_x = maxf(maks_x, p.x)
			bas = minf(bas, p.y - B4_AYAK)
		var ok: bool = maks_x <= float(g[3]) - 13.0 and not sg["bitti_ham"] and bas >= float(g[4]) - 1.0
		g_gecti = g_gecti and ok
		g_ayr.append("%s: en büyük x=%.1f (sol yüz %.0f), baş y min=%.1f" % [g[0], maks_x, float(g[3]), bas])
	_kaydi("Bölüm 12 atlanamaz: kapalı geçitler (GK, GA1, GB, GA2) zıplayarak/yürüyerek geçilemez", g_gecti, "; ".join(g_ayr))

	# e) PlakaB -> GB yarışı: oyuncu plakada 80 kare durur (GB tam açık), sonra GB'ye koşar.
	var se: Dictionary = await _b12_senaryo([], [_b4_a(0, Callable(), 80), _b4_a(1, Callable(), 150)],
		_b12_yerlestir(Vector2(740, 266)))
	var f_ayr := -1
	for f in range(80, se["ozel"].size()):
		if not se["ozel"][f]["pb"]:
			f_ayr = f
			break
	var gb_acik_y: float = se["ozel"][79]["gb"]
	var maks_xe := -1.0e9
	for p in se["iz"]:
		maks_xe = maxf(maks_xe, p.x)
	var f_var := -1
	for f in range(80, se["iz"].size()):
		if se["iz"][f].x >= 955.0:
			f_var = f
			break
	var acik := -1.0
	if f_var >= 0:
		acik = 290.0 - (se["ozel"][f_var]["gb"] + 100.0)
	_kaydi("Bölüm 12 atlanamaz: PlakaB'den GB'ye koşarak geçilemez (34,4 kare > 26)",
		not se["bitti_ham"] and se["oldu"] == 0 and maks_xe <= 957.0 and gb_acik_y <= 91.0,
		"GB tam açıkken (y=%.0f) plakadan ayrılış kare %d, GB sol yüzüne varış (merkez>=955) kare %d (%d kare), varışta açıklık=%.1f px (gerek >=48), en büyük x=%.1f, bitti: %s" % [
			gb_acik_y, f_ayr, f_var, f_var - f_ayr if f_var >= 0 else -1, acik, maks_xe, se["bitti_ham"]])
	_kayitlar().sifirla()


## 3) Başarısızlık senaryoları (§10).
func _test_bolum12_basarisizlik() -> void:
	var kay: Array = await _b12_kayitlar()
	var y1: Array = kay[0]
	var y2: Array = kay[1]
	_kaydi("Bölüm 12 hazırlık: Y1 ve Y2 kayıtları üretildi", y1.size() > 0 and y2.size() > 0,
		"kare sayıları: %d, %d" % [y1.size(), y2.size()])

	# 1) Klonsuz: Y2 rotasını kendisi yürür (kutuyu R'ye çıkarır, R2'ye gelir), GA1 önünde kalır.
	var s1: Dictionary = await _b12_senaryo([], _b12_kayittan(y2, 0))
	var u1: Vector2 = _b12_ulasim(s1)
	_kaydi("Bölüm 12 başarısızlık: klonsuz bitmez (GA1 kapalı, PlakaA boş)", not s1["bitti_ham"] and s1["oldu"] == 0 and u1.x < 690.0,
		"bitti=%s, en büyük x=%.0f (GA1 sol yüzü 690), ayak y min=%.1f (R2'ye çıkabildi: %s), GA1 hiç açılmadı: %s" % [
			s1["bitti_ham"], u1.x, u1.y, u1.y <= 291.0, str(not _b12_acildi(s1["ozel"], "ga1", 190.0))])

	# 2) Yalnız Y1: oyuncu Y2 rotasını yürür, PlakaB'ye basar ve GB'ye koşar.
	var kosu: Array = _b12_kayittan(y2, 0)
	var s2: Dictionary = await _b12_senaryo([y1], kosu)
	var s2b: Dictionary = await _b12_senaryo([y1], _b12_kayittan(y2, 0, false) + [_b4_a(0, Callable(), 40), _b4_a(1, Callable(), 150)])
	var u2: Vector2 = _b12_ulasim(s2b)
	_kaydi("Bölüm 12 başarısızlık: yalnız Y1 -> GB kapalı kalır, bitmez", not s2["bitti_ham"] and not s2b["bitti_ham"] and u2.x <= 957.0 \
		and _b7_hic(s2b["ozel"], "pb"),
		"Y2 rotası+sağ: bitti=%s; plakada 40 kare durup GB'ye koş: bitti=%s, en büyük x=%.0f (GB sol yüz 970), PlakaB basıldı: %s" % [
			s2["bitti_ham"], s2b["bitti_ham"], u2.x, _b7_hic(s2b["ozel"], "pb")])

	# 3) Yalnız Y2 (Y1'siz): GA1 kapalı, hem Y2 hem oyuncu GA1 önünde kalır.
	var s3: Dictionary = await _b12_senaryo([y2], _b12_kayittan(y2, 2))
	var ky: float = 0.0
	for p in s3["klon_izleri"][0]:
		ky = maxf(ky, p.x)
	_kaydi("Bölüm 12 başarısızlık: yalnız Y2 (Y1'siz) -> GA1 önünde kalır, bitmez", not s3["bitti_ham"] and ky < 690.0 \
		and not _b7_hic(s3["ozel"], "pb"),
		"bitti=%s, klon en büyük x=%.0f (GA1 sol yüz 690), PlakaB basıldı: %s" % [s3["bitti_ham"], ky, _b7_hic(s3["ozel"], "pb")])

	# 4) Y2 başlangıç gecikmesi s küçük (0,5,10,15): GK kapanır, kutu/Y2 geçmez.
	var ayr4: Array = []
	var k4_gecti := true
	for sg in [0, 5, 10, 15]:
		var t: Dictionary = await _b12_tam(_b12_y2(sg))
		var tamam_y2: bool = not t["y2"]["tamam"].has(false)
		var ky4: Vector2 = _b12_kutu_son(t["y2"])
		k4_gecti = k4_gecti and not t["bitti"]
		ayr4.append("s=%d: bitti=%s, Y2 adımları tamam=%s, kutu son=(%.0f,%.0f)" % [sg, t["bitti"], tamam_y2, ky4.x, ky4.y])
	_kaydi("Bölüm 12 başarısızlık: Y2 başlangıç gecikmesi s<20 -> GK kapanır, bitmez", k4_gecti, "; ".join(ayr4))

	# 5) Y2 kutu inmeden Zıplatıcı'ya girer (x>=477 sonrası yalnız n kare bekler; kutu ~55 kare havada).
	#    Taslak: "kutu/karakter çarpışır, kutu kayar". Kutu karakterlerle çarpışmaz (yalnız it() ile itilir).
	var ayr5: Array = []
	var k5_gecti := true
	var bitenler5: Array = []
	for n in [1, 3, 6, 10, 20, 35, 50]:
		var t5: Dictionary = await _b12_tam(_b12_y2(30, 8, 26, 0, n))
		var kk: Vector2 = _b12_kutu_son(t5["y2"])
		k5_gecti = k5_gecti and kk.x >= 500.0 and kk.x <= 580.0 and kk.y > 398.0 and kk.y < 402.0
		if t5["bitti"]:
			bitenler5.append(n)
		ayr5.append("n=%d: bitti=%s, kutu son=(%.0f,%.0f)" % [n, t5["bitti"], kk.x, kk.y])
	_kaydi("Bölüm 12 ölçüm: Y2 kutu havadayken Zıplatıcı'ya girer (taslak §10.5): kutu R içinde kalır, kilitlenme olmaz", k5_gecti,
		"bitiren n: %s (taslak: başarısız bekleniyordu); %s" % [str(bitenler5), "; ".join(ayr5)])

	# 6) Y2 fırlayınca `sag` geç başlar (gec=6,10,14): kutu sütununda kalıp baş çarpar.
	var ayr6: Array = []
	var gec_ok: Array = []
	for g in [0, 2, 4, 6, 8, 10, 14]:
		var t6: Dictionary = await _b12_tam(_b12_y2(30, 8, 26, 0, 0, g))
		if t6["bitti"]:
			gec_ok.append(g)
		ayr6.append("gec=%d:%s" % [g, "BİTTİ" if t6["bitti"] else "bitmedi"])
	_kaydi("Bölüm 12 başarısızlık: Y2 fırlama sonrası sağ geç başlarsa (>~5 kare) bitmez", gec_ok.has(0) and not gec_ok.has(14),
		"çalışan gec değerleri: %s; %s" % [str(gec_ok), "; ".join(ayr6)])

	# 7) Oyuncu PlakaB'de durup GB'ye koşar (B'yi tutacak klon yok): Y2'nin yolunu PlakaB'ye kadar izler.
	var y2_b_yok: Array = _b12_y2(30)
	y2_b_yok = y2_b_yok.slice(0, y2_b_yok.size() - 3) + [_b4_a(1, _b4_x_ge(640.0), 100), _b4_a(0, Callable(), 400)]
	var sy7: Dictionary = await _b12_senaryo([y1], y2_b_yok)
	var s7: Dictionary = await _b12_senaryo([y1, sy7["kayit"]],
		_b12_kayittan(sy7["kayit"], 2, false) + [_b4_a(1, _b4_x_ge(735.0), 100), _b4_a(0, _b4_plakada("PlakaB"), 40),
			_b4_a(0, Callable(), 60), _b4_a(1, Callable(), 150)])
	var u7: Vector2 = _b12_ulasim(s7)
	_kaydi("Bölüm 12 başarısızlık: oyuncu PlakaB'den GB'ye koşar (34,4 > 26 kare) -> bitmez", not s7["bitti_ham"] and u7.x <= 957.0 \
		and _b7_hic(s7["ozel"], "pb"),
		"Y2 yolu hazır, PlakaB basıldı: %s, bitti=%s, en büyük x=%.0f" % [_b7_hic(s7["ozel"], "pb"), s7["bitti_ham"], u7.x])

	_kayitlar().sifirla()


func _b12_acildi(ozel: Array, anahtar: String, kapali_y: float) -> bool:
	for o in ozel:
		if o[anahtar] < kapali_y - 0.5:
			return true
	return false

## Oyuncunun (y2 kaydı olmadan) tek başına sürdüğü tam Y2 rotası + sonda sağa koşu.
func _b12_solo(s := 0) -> Array:
	return _b12_y2(s) + [_b4_a(1, _b4_bitti_k(), 300)]


## 4) Kısayol taraması (§5 tablosu).
func _test_bolum12_kisayol() -> void:
	var kay: Array = await _b12_kayitlar()
	var y1: Array = kay[0]
	var y2: Array = kay[1]

	# Satır 1-3: klonsuz, yalnız Y1, yalnız Y2 (oyuncu tam rotayı kendi sürer, sonra kapıya koşar).
	var ayr: Array = []
	var hepsi := true
	for k in [["klonsuz", []], ["yalnız Y1", [y1]], ["yalnız Y2", [y2]]]:
		var s: Dictionary = await _b12_senaryo(k[1], _b12_solo(0))
		hepsi = hepsi and not s["bitti_ham"]
		ayr.append("%s: bitti=%s" % [k[0], s["bitti_ham"]])
	var sref: Dictionary = await _b12_senaryo([y1, y2], _b12_kayittan(y2, 2))
	hepsi = hepsi and sref["bitti_ham"]
	ayr.append("Y1+Y2 (gerçek çözüm): bitti=%s" % sref["bitti_ham"])
	_kaydi("Bölüm 12 kısayol: klonsuz/yalnız Y1/yalnız Y2 ile bitmez, Y1+Y2 ile biter", hepsi, "; ".join(ayr))

	# Satır 4: oyuncu PlakaA'yı tutar (Y2 klon var, Y1 yok): plakadan ayrılınca GK kapanmıştır (kutu K'dan
	# ayrıldı) ve GA1 kapalıdır; oyuncu GK'da takılır, klon GA1'e varsa bile kapalıdır. Bitmez.
	var s4: Dictionary = await _b12_senaryo([y2], [_b4_a(-1, _b4_x_le(40.0), 100), _b4_a(0, Callable(), 80),
		_b4_a(1, Callable(), 300)])
	var u4: Vector2 = _b12_ulasim(s4)
	var kx4 := -1.0e9
	for p4 in s4["klon_izleri"][0]:
		kx4 = maxf(kx4, p4.x)
	var gk4: float = s4["ozel"][s4["ozel"].size() - 1]["gk"]
	var ga4: float = s4["ozel"][s4["ozel"].size() - 1]["ga1"]
	_kaydi("Bölüm 12 kısayol: oyuncu PlakaA'yı tutar (Y2 klon var) -> plakadan ayrılınca GK kapalı kalır, bitmez",
		not s4["bitti_ham"] and u4.x <= 357.0 and gk4 >= 499.0 and _b7_hic(s4["ozel"], "pa"),
		"bitti=%s, oyuncu en büyük x=%.0f (GK sol yüz 370: GK kapandı, son y=%.0f), klon en büyük x=%.0f, son GA1 y=%.0f (kapalı 190), PlakaA basıldı: %s" % [
			s4["bitti_ham"], u4.x, gk4, kx4, ga4, _b7_hic(s4["ozel"], "pa")])

	# Satır 6: kutu PlakaA'yı tutsun: oyuncu kutunun sağından sola iter (kutu gerçekten A'ya gider),
	# sonra çözümü dener: kutu R'de olmadığından R2'ye çıkış yok.
	var s6: Dictionary = await _b12_senaryo([], [_b4_a(-1, Callable(), 220), _b4_a(0, Callable(), 30)]
		+ _b8_zipla_dizisi(6, 1.0, 40) + [_b4_a(1, Callable(), 150)], _b12_yerlestir(Vector2(260, 576)))
	var u6: Vector2 = _b12_ulasim(s6)
	var kk6: Vector2 = _b12_kutu_son(s6)
	var kutu_a: bool = false
	for o6 in s6["ozel"]:
		if o6["pa"] and o6["kutu"].x < 75.0 and o6["kutu"].y > 560.0:
			kutu_a = true
			break
	_kaydi("Bölüm 12 kısayol: kutu PlakaA'yı tutar (gerçekten A'ya itilir) -> R2'ye çıkış yok, bitmez",
		not s6["bitti_ham"] and kutu_a and kk6.x < 75.0 and u6.y > 330.0,
		"kutu PlakaA üstünde (PlakaA basılı, kutu x<75): %s, kutu son=(%.0f,%.0f), oyuncu ayak y min=%.1f, bitti=%s" % [kutu_a, kk6.x, kk6.y, u6.y, s6["bitti_ham"]])

	# Satır 7: kutu basamak zeminde: zemin kutusu üstü 560 -> 459 > 420 (atlanamaz c ile aynı ölçüm, kutu x=520 yakını).
	var s7: Dictionary = await _b12_senaryo([], _b8_zipla_dizisi(8, 0.0, 40) + _b8_zipla_dizisi(4, -1.0, 40),
		_b12_yerlestir(Vector2(500, 536), Vector2(500, 580)))
	var u7: Vector2 = _b12_ulasim(s7)
	_kaydi("Bölüm 12 kısayol: zemin kutusu basamak olarak R'ye yetmez (en az 43,5 px kısa)", u7.y >= 440.0 and not s7["bitti_ham"],
		"ayak y min=%.1f (kutu üstü 560 - 100,9 = ~459; R 420)" % u7.y)

	# Satır 9: kutu geçit altında: Y2 PlakaK'dan ayrılınca durursa (D kare) GK kapanırken kutuya oturur
	# (açıklık 40..48 < karakter 48): oyuncu geçemez, kutu da geçit altından çıkarılamaz.
	var ayr9: Array = []
	var g9 := true
	for d9 in [8, 12, 16]:
		var s9: Dictionary = await _b12_senaryo([], [_b4_a(0, Callable(), 30), _b4_a(1, _b4_x_ge(246.0), 100),
			_b4_a(0, Callable(), d9), _b4_a(1, Callable(), 150)])
		var u9: Vector2 = _b12_ulasim(s9)
		var gk9: float = s9["ozel"][s9["ozel"].size() - 1]["gk"]
		var kk9: Vector2 = _b12_kutu_son(s9)
		var ac9: float = 500.0 - gk9
		g9 = g9 and u9.x <= 357.0 and not s9["bitti_ham"] and ac9 >= 40.0 and ac9 < 48.0 and kk9.x > 360.0 and kk9.x < 400.0
		ayr9.append("D=%d: oyuncu en büyük x=%.0f (GK sol yüz 370), GK açıklık=%.0f px, kutu son x=%.0f" % [d9, u9.x, ac9, kk9.x])
	_kaydi("Bölüm 12 kısayol: kutu GK altında açıklığı 40..48 px'te tutar, oyuncu geçemez (kutu da çıkarılamaz)", g9, "; ".join(ayr9))

	# Satır 10: kutu R'de iken sağa/sola itilir: R duvarlarıyla sınırlı kalır (kutu_kilit testinde).

	# Satır 11: yığma. Kutu üstündeki oyuncu kutuyla birlikte fırlar (kutu ona platform olur) ve R2'ye çıkar.
	#   a) tek başına (kutuyu iten yok): oyuncu zıplatıcının yanında zemin kutusunun üstünde durur -> fırlama yok.
	var sya: Dictionary = await _b12_senaryo([], _b8_zipla_dizisi(6, 0.0, 30) + _b8_zipla_dizisi(4, -1.0, 30),
		_b12_yerlestir(Vector2(500, 536), Vector2(500, 580)))
	var ua: Vector2 = _b12_ulasim(sya)
	#   b) kutu zıplatıcıda fırlarken üstündeki oyuncu (kutu x=515: sensörde) taşınır; tepede zıplayınca R2'ye iner.
	var syb: Dictionary = await _b12_senaryo([], _b8_zipla_dizisi(8, 0.0, 10) + [_b4_a(0, Callable(), 60)],
		_b12_yerlestir(Vector2(515, 536), Vector2(515, 580)))
	var ub: Vector2 = _b12_ulasim(syb)
	var sonb: Vector2 = syb["iz"][syb["iz"].size() - 1]
	var r2_b: bool = sonb.y + B4_AYAK <= 291.0 and sonb.x >= 480.0
	#   c) gerçek yol: Y2 klonu iterken oyuncu kutunun üstüne binip birlikte fırlar (Y1+Y2 klon var).
	var kay11: Array = await _b12_kayitlar()
	var y2_gec: Dictionary = await _b12_senaryo([kay11[0]], _b12_y2(70))
	var ride: Array = [_b4_a(1, _b4_x_ge(128.0), 40), _b4_a(1, Callable(), 12, true),
		_b4_a(0, func(b: Node) -> bool:
			var o: CharacterBody2D = b.get_node("Oyuncu")
			return o.is_on_floor() and o.global_position.y <= 545.0, 80),
		_b4_a(0, func(b: Node) -> bool: return b.get_node("Kutu").global_position.x >= 201.0, 150),
		_b4_a(0, func(b: Node) -> bool: return b.get_node("Kutu").global_position.y < 565.0, 200)] 		+ _b8_zipla_dizisi(8, 0.0, 10) + [_b4_a(1, _b4_x_ge(735.0), 200),
		_b4_a(0, _b4_plakada("PlakaB"), 40), _b4_a(1, _b4_bitti_k(), 300)]
	var syc: Dictionary = await _b12_senaryo([kay11[0], y2_gec["kayit"]], ride)
	var uc: Vector2 = _b12_ulasim(syc)
	#   (c, kutu ve oyuncu GK'dan birlikte geçemez: kutu 40 + oyuncu 48 = 88 px gerekir, kutu plakadan
	#   ayrılınca GK en çok ~60 px açık kalır; oyuncu kutuyla GK'ya varınca takılır.)
	_kaydi("Bölüm 12 ölçüm: yığma (kutuyla fırlayan oyuncu R2'ye çıkar) tek başına yapılamaz; kutuya binerek GK geçilemez",
		ua.y >= 440.0 and ub.y <= 290.0 and r2_b and uc.x <= 357.0 and not syc["bitti_ham"],
		"a) tek başına zemin kutusu üstü: ayak y min=%.1f (fırlama yok); b) kutu zıplatıcıda fırlarken üstündeki oyuncu: ayak y min=%.1f, son=(%.0f,%.0f) R2'de: %s; c) Y2 kutuyu iterken oyuncu üstüne binip yürür: en büyük x=%.0f (GK sol yüz 370, oyuncu+kutu 88 px gerek), bitti=%s" % [
			ua.y, ub.y, sonb.x, sonb.y, r2_b, uc.x, syc["bitti_ham"]])

	# Satır 5: geçit altı park / röle: bkz. _test_bolum12_role (ayrı ölçüm).
	await _test_bolum12_role(y1, y2)
	_kayitlar().sifirla()


## Geçit altı park (röle) kısayolu bu bölüm için ölçümü.
## (a) mekanizma GK'da (zemin düzeyinde, ulaşılabilir): klon plakada bekler, oyuncu geçit altında
##     park eder; klon plakadan ayrılınca geçit 48 px'te kalır ve klon geçer.
## (b) bölümde tek klonla çözüm taraması: Y2 (kör) / plakada bekleyen Y2 / Y1 klonu x oyuncu stratejileri.
func _test_bolum12_role(y1: Array, y2: Array) -> void:
	# (a) mekanizma
	var hz := func(b: Node) -> void:
		b.get_node("Kutu").global_position = Vector2(470, 580)
	var c_adim: Array = [_b4_a(1, _b4_x_ge(190.0), 60), _b4_a(0, Callable(), 100), _b4_a(1, _b4_x_ge(250.0), 40),
		_b4_a(0, Callable(), 70), _b4_a(1, Callable(), 150)]
	var sc: Dictionary = await _b12_senaryo([], c_adim, hz)
	var c: Array = sc["kayit"]
	var park: Array = [_b4_a(1, _b4_x_ge(380.0), 100), _b4_a(0, Callable(), 320)]
	var s_park: Dictionary = await _b12_senaryo([c], park, hz)
	var s_bos: Dictionary = await _b12_senaryo([c], [_b4_a(0, Callable(), 320)], hz)
	var kx_park := -1.0e9
	for p in s_park["klon_izleri"][0]:
		kx_park = maxf(kx_park, p.x)
	var kx_bos := -1.0e9
	for p in s_bos["klon_izleri"][0]:
		kx_bos = maxf(kx_bos, p.x)
	var gk_park := -1.0e9
	var f0: int = _b12_ilk(s_park["ozel"], "pk", false)
	for f in range(100, s_park["ozel"].size()):
		gk_park = maxf(gk_park, s_park["ozel"][f]["gk"])
	_kaydi("Bölüm 12 röle (mekanizma, GK): oyuncu geçit altında park eder, plakada bekleyen klon geçer; park yoksa geçemez",
		kx_park >= 420.0 and kx_bos <= 356.0 and gk_park <= 455.0,
		"klon en büyük x: parklı=%.0f, parksız=%.0f (GK sol yüz 370); parklı turda GK en alçak y=%.0f (açıklık %.0f px; karakter 48)" % [
			kx_park, kx_bos, gk_park, 500.0 - gk_park])

	# (b) tek klonla bölüm çözümü taraması
	var klon_varyant: Array = [
		["Y2 kör (Y1'siz kaydı)", _b12_y2(30)],
		["Y2 kör, s=0", _b12_y2(0)],
		["Y1 (PlakaA'da bekler)", _b12_y1()],
		["PlakaA'da 150 kare, sonra Y2", [_b4_a(-1, _b4_x_le(40.0), 100), _b4_a(0, Callable(), 150)] + _b12_y2(0)],
		["PlakaA'da 300 kare, sonra Y2", [_b4_a(-1, _b4_x_le(40.0), 100), _b4_a(0, Callable(), 300)] + _b12_y2(0)],
	]
	var oyuncu_strat: Array = [
		["PlakaA'da 100 kare, sonra tam rota", [_b4_a(-1, _b4_x_le(40.0), 100), _b4_a(0, Callable(), 100)] + _b12_solo(0)],
		["PlakaA'da 250 kare, sonra tam rota", [_b4_a(-1, _b4_x_le(40.0), 100), _b4_a(0, Callable(), 250)] + _b12_solo(0)],
		["PlakaA'da 400 kare, sonra tam rota", [_b4_a(-1, _b4_x_le(40.0), 100), _b4_a(0, Callable(), 400)] + _b12_solo(0)],
		["hemen tam rota", _b12_solo(0)],
		["gecikmeli tam rota (s=30)", _b12_solo(30)],
	]
	var bitirenler: Array = []
	var denenen := 0
	var en_ileri := -1.0e9
	var ayr: Array = []
	for kv in klon_varyant:
		var sk: Dictionary = await _b12_senaryo([], kv[1])
		var k_x := -1.0e9
		var pb_k := _b7_hic(sk["ozel"], "pb")
		for p in sk["iz"]:
			k_x = maxf(k_x, p.x)
		for ov in oyuncu_strat:
			var so: Dictionary = await _b12_senaryo([sk["kayit"]], ov[1])
			denenen += 1
			var ox := -1.0e9
			for p in so["iz"]:
				ox = maxf(ox, p.x)
			en_ileri = maxf(en_ileri, ox)
			if so["bitti_ham"]:
				bitirenler.append("%s + %s" % [kv[0], ov[0]])
		# klon oyuncu rotasını izlesin (kayit kaydırma)
		for L in [0, 2, 40]:
			var sf: Dictionary = await _b12_senaryo([sk["kayit"]], _b12_kayittan(sk["kayit"], L))
			denenen += 1
			if sf["bitti_ham"]:
				bitirenler.append("%s + izle(L=%d)" % [kv[0], L])
		ayr.append("%s: kayıtlı klon en büyük x=%.0f PlakaB basıldı=%s" % [kv[0], k_x, pb_k])
	# (c) Gerçek röle: oyuncu kutuyu kendisi R'ye çıkarıp R2'den GA1 altında (x=700) park eder; klon PlakaA'da T
	#     kare tutup sonra rotayı (kör) yürür. Klon GA1'i park sayesinde geçebilir mi, PlakaB'ye varır mı?
	var park_adim: Array = _b12_y2(30).slice(0, 13) + [_b4_a(1, _b4_x_ge(700.0), 100), _b4_a(0, Callable(), 500)]
	var ayr_c: Array = []
	var role_bitti: Array = []
	for T in [290, 330, 380]:
		var ck: Dictionary = await _b12_senaryo([], [_b4_a(-1, _b4_x_le(40.0), 100), _b4_a(0, Callable(), T)] + _b12_y2(30))
		var sp: Dictionary = await _b12_senaryo([ck["kayit"]], park_adim)
		var kx := -1.0e9
		for p2 in sp["klon_izleri"][0]:
			kx = maxf(kx, p2.x)
		var ox := -1.0e9
		for p2 in sp["iz"]:
			ox = maxf(ox, p2.x)
		denenen += 1
		if sp["bitti_ham"]:
			role_bitti.append("T=%d" % T)
		ayr_c.append("T=%d: klon en büyük x=%.0f (GK sol yüz 370, GA1 690), PlakaB basıldı=%s, oyuncu en büyük x=%.0f, bitti=%s" % [
			T, kx, _b7_hic(sp["ozel"], "pb"), ox, sp["bitti_ham"]])
	bitirenler += role_bitti
	ayr.append("park-röle (oyuncu kutuyu çıkarıp GA1 altında park): " + " | ".join(ayr_c))
	_kaydi("Bölüm 12 röle (bölümde): tek klonla (5 klon x 8 oyuncu stratejisi) bitirilemez", bitirenler.is_empty(),
		"denenen: %d, bitiren: %s, oyuncunun ulaştığı en büyük x=%.0f; %s" % [denenen, str(bitirenler), en_ileri, " | ".join(ayr)])
	_kayitlar().sifirla()


func _b12_gk_gap(s: Dictionary, x_esik: float) -> float:
	# Oyuncunun x_esik'e ilk vardığı karedeki GK açıklığı (px).
	for f in range(s["iz"].size()):
		if s["iz"][f].x >= x_esik:
			return 500.0 - s["ozel"][f]["gk"]
	return -1.0


## 5) Hassasiyet ölçümü (zorluk verisi).
func _test_bolum12_hassasiyet() -> void:
	var kay: Array = await _b12_kayitlar()
	# a) Y2 başlangıç gecikmesi s.
	var s_ok: Array = []
	for sg in [0, 10, 14, 16, 18, 20, 22, 24, 26, 28, 30, 45, 100]:
		var t: Dictionary = await _b12_tam(_b12_y2(sg))
		if t["bitti"]:
			s_ok.append(sg)
	# b) GK yarışı payı: Y2 PlakaK'dan ayrıldıktan sonra `durak` kare durur.
	var d_ok: Array = []
	for d in [0, 1, 2, 3, 4, 5, 6, 8, 12]:
		var t: Dictionary = await _b12_tam(_b12_y2(30, 8, 26, d))
		if t["bitti"]:
			d_ok.append(d)
	# GK açıklığı: standart çözümde Y2'nin x=356'ya (GK sol yüzü - 14) vardığı karede ve kutunun (x=370-20=350..) geçişinde.
	var sy: Dictionary = await _b12_senaryo([kay[0]], _b12_y2(30))
	var gap_y2: float = _b12_gk_gap(sy, 356.0)
	# c) Fırlamadan sonra sag süresi, sol başlangıcı, sol süresi.
	var sag_ok: Array = []
	for n in [2, 3, 4, 5, 6, 8, 10, 14]:
		var t: Dictionary = await _b12_tam(_b12_y2(30, n, maxi(26, n)))
		if t["bitti"]:
			sag_ok.append(n)
	var sol_ok: Array = []
	for k in [10, 14, 18, 22, 26, 30, 36, 44]:
		var t: Dictionary = await _b12_tam(_b12_y2(30, 8, k))
		if t["bitti"]:
			sol_ok.append(k)
	var soln_ok: Array = []
	for n in [2, 4, 6, 8, 10, 12, 16]:
		var t: Dictionary = await _b12_tam(_b12_y2(30, 8, 26, 0, 0, 0, n))
		if t["bitti"]:
			soln_ok.append(n)
	# d) Oyuncunun Y2'yi izleme gecikmesi L.
	var l_ok: Array = []
	var y2k: Array = kay[1]
	for L in [0, 1, 2, 3, 5, 10, 14, 18, 20, 22, 24, 26, 28, 30, 32, 34, 36, 38, 40, 80]:
		var sp: Dictionary = await _b12_senaryo([kay[0], y2k], _b12_kayittan(y2k, L))
		if sp["bitti_ham"] and sp["oldu"] == 0 and sp["kare"] <= 600:
			l_ok.append(L)
	# e) Kutu basamağı payı: kutu R'de (x=520), oyuncu üstünde; yerinde zıpla, sonra sağ+zıpla.
	var sb: Dictionary = await _b12_senaryo([], [_b4_a(0, Callable(), 3), _b4_a(0, Callable(), 70, true)],
		_b12_yerlestir(Vector2(520, 356), Vector2(520, 400)))
	var ub: Vector2 = _b12_ulasim(sb)
	var bx_ok: Array = []
	for kx in [500, 510, 520, 540, 560, 580]:
		var sx: Dictionary = await _b12_senaryo([], [_b4_a(0, Callable(), 3), _b4_a(1, Callable(), 30, true),
			_b4_a(0, Callable(), 40)], _b12_yerlestir(Vector2(kx, 356), Vector2(kx, 400)))
		var son: Vector2 = sx["iz"][sx["iz"].size() - 1]
		if son.y + B4_AYAK <= 291.0 and son.x >= 480.0:
			bx_ok.append(kx)
	var gecti: bool = s_ok.has(30) and not s_ok.has(0) and d_ok.has(0) and not d_ok.has(12) and sag_ok.has(8) \
		and l_ok.has(2) and l_ok.has(0) and not l_ok.has(80) and ub.y < 290.0 and ub.y >= 270.0
	_kaydi("Bölüm 12 ölçüm: zamanlama pencereleri (Y2 gecikme s, GK yarışı payı, fırlama sonrası tuşlar, izleme gecikmesi L, kutu basamağı)", gecti,
		"Y2 s çalışanlar [0,10,14,16,18,20,22,24,26,28,30,45,100]: %s; PlakaK'dan ayrılınca durak d çalışanlar [0,1,2,3,4,5,6,8,12]: %s (standart Y2'nin GK'ya vardığı karede açıklık %.0f px, gerek >=48); sag_n çalışanlar [2,3,4,5,6,8,10,14]: %s; sol başlangıcı çalışanlar [10,14,18,22,26,30,36,44]: %s; sol süresi çalışanlar [2,4,6,8,10,12,16]: %s; oyuncu gecikmesi L çalışanlar [0,1,2,3,5,10,14,18,20,22,24,26,28,30,32,34,36,38,40,80]: %s; kutu basamağı (kutu x=520): zıplama tepesi ayak y=%.1f (R2 üstü 290, pay %.1f px), sağ+zıpla ile R2'ye çıkan kutu x: %s" % [
			str(s_ok), str(d_ok), gap_y2, str(sag_ok), str(sol_ok), str(soln_ok), str(l_ok), ub.y, 290.0 - ub.y, str(bx_ok)])
	_kayitlar().sifirla()


## 6) Kutu geri alınamaz / kilitlenme davranışı (§9).
func _test_bolum12_kutu_kilit() -> void:
	# a) Kutu R'de: sağdan/soldan itilir; R duvarlarıyla sınırlı kalır, R'den düşmez.
	var sa: Dictionary = await _b12_senaryo([], [_b4_a(1, Callable(), 90)], _b12_yerlestir(Vector2(500, 396), Vector2(530, 400)))
	var sa2: Dictionary = await _b12_senaryo([], [_b4_a(-1, Callable(), 90)], _b12_yerlestir(Vector2(590, 396), Vector2(560, 400)))
	var ka: Vector2 = _b12_kutu_son(sa)
	var ka2: Vector2 = _b12_kutu_son(sa2)
	# Kutu en uç x'leri (tüm örnekler).
	var kx_min := 1.0e9
	var kx_maks := -1.0e9
	var ky_maks := -1.0e9
	for s in [sa, sa2]:
		for o in s["ozel"]:
			kx_min = minf(kx_min, o["kutu"].x)
			kx_maks = maxf(kx_maks, o["kutu"].x)
			ky_maks = maxf(ky_maks, o["kutu"].y)
	_kaydi("Bölüm 12 kutu: R'deki kutu itilince R duvarları (480..600) içinde kalır, R'den düşmez; kilitlenme değil",
		kx_min >= 500.0 - 0.5 and kx_maks <= 580.0 + 0.5 and ky_maks <= 401.0 and not sa["bitti_ham"],
		"sağa itme: kutu son=(%.0f,%.0f); sola itme: kutu son=(%.0f,%.0f); kutu x aralığı %.0f..%.0f (R 480..600, kutu 40), en büyük y=%.1f (R üstü 420 -> 400)" % [
			ka.x, ka.y, ka2.x, ka2.y, kx_min, kx_maks, ky_maks])

	# b) Kutu zeminde sola duvara itilir: geri alınamaz (Baştan başla gerekir).
	var sb: Dictionary = await _b12_senaryo([], [_b4_a(-1, Callable(), 80)] + [_b4_a(-1, Callable(), 220)] + [_b4_a(0, Callable(), 20)]
		+ _b8_zipla_dizisi(6, 1.0, 40) + _b8_zipla_dizisi(4, -1.0, 40) + [_b4_a(1, Callable(), 100)],
		_b12_yerlestir(Vector2(280, 576)))
	var kb: Vector2 = _b12_kutu_son(sb)
	var kb_min := 1.0e9
	for o in sb["ozel"]:
		kb_min = minf(kb_min, o["kutu"].x)
	_kaydi("Bölüm 12 kutu: sola duvara itilen kutu geri alınamaz (oyuncu kutunun solunda duramaz)", kb.x <= kb_min + 1.0 and kb.x < 80.0 and not sb["bitti_ham"],
		"kutu en sol x=%.0f, son x=%.0f (oyuncu zıplayıp sağa dönse de kutu aynı), bitti=%s" % [kb_min, kb.x, sb["bitti_ham"]])

	# c) Kutu GK altında kalır: Y2 PlakaK'dan ayrılınca D kare durursa kutu geçidin altında (D=12) ya da
	#    geçit kapanıp kutuyu geri iterek (D=30) kalır. İkisi de kilitlenme: kutu plakaya geri dönemez.
	var ayr_c: Array = []
	var gecti_c := true
	for dd in [12, 30]:
		var sc: Dictionary = await _b12_senaryo([], [_b4_a(0, Callable(), 30), _b4_a(1, _b4_x_ge(246.0), 100),
			_b4_a(0, Callable(), dd), _b4_a(1, Callable(), 150), _b4_a(-1, Callable(), 60), _b4_a(1, Callable(), 100)])
		var kc: Vector2 = _b12_kutu_son(sc)
		var gkc: float = sc["ozel"][sc["ozel"].size() - 1]["gk"]
		var oc: Vector2 = _b12_ulasim(sc)
		var plaka_son: bool = sc["ozel"][sc["ozel"].size() - 1]["pk"]
		gecti_c = gecti_c and not sc["bitti_ham"] and kc.x < 400.0 and kc.x > 330.0 and not plaka_son
		ayr_c.append("D=%d: kutu son=(%.0f,%.0f), GK son y=%.0f (açıklık %.0f), oyuncu en büyük x=%.0f, PlakaK basılı: %s" % [
			dd, kc.x, kc.y, gkc, 500.0 - gkc, oc.x, plaka_son])
	_kaydi("Bölüm 12 kutu: GK'ya takılan kutu geri alınamaz (itilemez, plakaya dönemez): kilitlenme, Baştan başla gerekir", gecti_c,
		"; ".join(ayr_c))
	_kayitlar().sifirla()


## 7) max_klon=2.
func _test_bolum12_klon_siniri() -> void:
	_kayitlar().sifirla()
	var bolum: Node = await _bolumu_yukle()
	var maks: int = bolum.max_klon
	var gecti := maks == 2
	var ayrinti: Array = []
	for n in range(maks + 1):
		for i in range(5):
			_girdi_uygula({"yon": 1.0, "zipla": false})
			await physics_frame
		_girdi_uygula({"yon": 0.0, "zipla": false})
		var eski_id := bolum.get_instance_id()
		await _r_bas()
		var yeni: Node = await _yeni_sahne_bekle(eski_id)
		var sayi: int = _kayitlar().turlar.size()
		if n < maks:
			gecti = gecti and yeni != null and sayi == n + 1
			if yeni == null:
				break
			bolum = yeni
		else:
			var yazi: String = bolum.bilgi.text
			gecti = gecti and yeni == null and sayi == maks and yazi.contains("Klon hakkı bitti") \
				and yazi.contains("2/2")
			ayrinti.append("sınırda etiket: \"%s\"" % yazi)
		ayrinti.append("R #%d -> kayıtlı klon: %d" % [n + 1, sayi])
	_kaydi("Bölüm 12: klon sınırı (üçüncü R klon kaydetmez)", gecti, "max_klon=%d; %s" % [maks, ", ".join(ayrinti)])
	_kayitlar().sifirla()


## 8) Determinizm.
func _test_bolum12_determinizm() -> void:
	var kay: Array = await _b12_kayitlar()
	var s0: Dictionary = await _b12_senaryo(kay, _b12_kayittan(kay[1], 2))
	var betik: Array = s0["kayit"]
	var ornek := func(b: Node) -> Dictionary: return _b12_ornekle(b)
	var referans: Dictionary = {}
	var sapmali := 0
	var bitmeyen := 0
	var maks_sapma := 0.0
	for n in range(TEKRAR):
		var s: Dictionary = await _senaryo(kay, betik, 700, Callable(), ornek)
		if not s["bitti"]:
			bitmeyen += 1
		if n == 0:
			referans = s
			continue
		var bu: bool = s["ozel_iz"].size() != referans["ozel_iz"].size() or s["kare"] != referans["kare"]
		for f in range(mini(s["ozel_iz"].size(), referans["ozel_iz"].size())):
			if s["ozel_iz"][f] != referans["ozel_iz"][f]:
				bu = true
			var d: float = (s["oyuncu_iz"][f] - referans["oyuncu_iz"][f]).length()
			for ki in range(2):
				d = maxf(d, (s["klon_izleri"][ki][f] - referans["klon_izleri"][ki][f]).length())
			if d > 0.0:
				bu = true
				maks_sapma = maxf(maks_sapma, d)
		if bu:
			sapmali += 1
	_kaydi("Bölüm 12: determinizm (100x çözüm)", sapmali == 0 and bitmeyen == 0 and s0["bitti_ham"],
		"%d çalıştırma x %d kare, sapmalı: %d, en büyük sapma: %.4f px, bitirmeyen çalıştırma: %d, kayıt turu bitti: %s" % [
			TEKRAR, referans["kare"], sapmali, maks_sapma, bitmeyen, s0["bitti_ham"]])
	_kayitlar().sifirla()
	paused = false




# ---------------------------------------------------------------- Röle (geçit altı park) araştırması
# Ölçüm: tek klon + oyuncunun geçit altında beklemesiyle bölüm bitiyor mu? (Bölüm 12 taslağı §0.)
# Mevcut bölüm testleri değişmez; yalnız onların yardımcıları kullanılır. Test her zaman "ölçüm" olarak
# GEÇTİ yazar; bulgu ayrıntıdadır (bitti=True ise taslağın min klon sayısı tek klonla aşılıyordur).

## Bölüm 6: klon A PlakaA'da T kare bekler, sonra D kare sağa yürür (kayıt GERÇEK dünyada, geçit kapalı:
## kayıt turunda klon geçide takılır, yani oyuncunun gerçekten yapabileceği kördür); oyuncu geçidin altında
## (x=px) park eder, klon geçince son turu normal oynar. D, geçit çarpışması kapalıyken PlakaL'e varma
## süresinden (yalnız kare sayısı hesabı için) ölçülür.
func _test_role_bolum6() -> void:
	aktif_bolum = BOLUM_6
	var kapat := func(b: Node) -> void: b.get_node("Gecit").collision_layer = 0
	var ayr: Array = []
	var bitenler: Array = []
	var denenen := 0
	var dsag := 0
	var k0: Dictionary = await _b6_senaryo([], [_b4_a(-1, _b4_x_le(40.0), 60), _b4_a(0, Callable(), 100),
		_b4_a(1, _b6_pl_basili(), 250), _b4_a(0, Callable(), 30)], kapat)
	dsag = k0["baslangic"][3] - k0["baslangic"][2]
	for T in [100, 120, 150, 200]:
		# Kör kayıt: gerçek dünyada, geçit çarpışması AÇIK (klon geçide takılır).
		var sc: Dictionary = await _b6_senaryo([], [_b4_a(-1, _b4_x_le(40.0), 60), _b4_a(0, Callable(), T),
			_b4_a(1, Callable(), dsag), _b4_a(0, Callable(), 30)])
		var gecide_takildi: bool = sc["iz"][sc["iz"].size() - 1].x < 566.0
		for px in [575.0, 580.0, 585.0]:
			var oyuncu: Array = [_b4_a(1, _b4_x_ge(px), 150),
				_b4_a(0, func(b: Node) -> bool:
					var kl: Array = _klonlar(b)
					return kl.size() > 0 and kl[0].global_position.x >= 600.0, 500)] + _b6_tur3()
			var so: Dictionary = await _b6_senaryo([sc["kayit"]], oyuncu)
			denenen += 1
			ayr.append("T=%d px=%d: bitti=%s ölüm=%d kare=%d" % [T, int(px), so["bitti"], so["oldu"], so["kare"]])
			if so["bitti"]:
				bitenler.append("T=%d px=%d" % [T, int(px)])
		ayr.append("(T=%d kör kayıt turunda klon geçitte takılı kaldı: %s)" % [T, gecide_takildi])
	_kaydi("Bölüm 6 röle araştırması (ölçüm): tek klon + geçit altında park ile bölüm bitiyor mu", true,
		"TEK KLONLA BİTEN: %d/%d %s; kör kayıt D=%d kare sağ; %s" % [bitenler.size(), denenen,
			str(bitenler) if not bitenler.is_empty() else "YOK", dsag, "; ".join(ayr)])
	_kayitlar().sifirla()


## Bölüm 7: geçit yalnız şalterle açılır (plaka tutucusu yok) -> geçit altı park uygulanamaz. Denenenler:
##  (a) Z' klonu PlakaB'de T kare durup PlakaC'ye geçer (roller birleşir; L1 açılınca Z' ışına girer).
##  (b) A klonu bir süre PlakaA'yı tutup ayrılır, oyuncu asansörün altında park eder (asansör yüksekte kalmaz).
func _test_role_bolum7() -> void:
	aktif_bolum = BOLUM_7
	var kay: Array = await _b7_kayitlar()
	var ayr: Array = []
	var bitenler: Array = []
	var denenen := 0
	for T in [0, 30, 60, 100]:
		var zp: Array = _b7_yukari() + [_b4_a(-1, _b4_x_le(700.0), 300), _b4_a(0, _b7_plaka("PlakaB"), 60),
			_b4_a(0, Callable(), T), _b4_a(-1, _b4_x_le(500.0), 200), _b4_a(0, _b7_plaka("PlakaC"), 60),
			_b4_a(0, Callable(), 10)]
		var sz: Dictionary = await _b7_senaryo([kay[0]], zp)
		var so: Dictionary = await _b7_senaryo([kay[0], sz["kayit"]], _b7_tur4())
		denenen += 1
		if so["bitti"]:
			bitenler.append("birleşik Z' T=%d" % T)
		ayr.append("Z' T=%d (A+Z', Y yok): kayıt tamam=%s, bitti=%s ölüm=%d" % [T, str(not sz["tamam"].has(false)), so["bitti"], so["oldu"]])
	# (b) asansör altında park
	var a_gec: Array = [_b4_a(0, Callable(), 40), _b4_a(-1, _b4_x_le(70.0), 60), _b4_a(0, Callable(), 150),
		_b4_a(1, Callable(), 30)]
	var sa: Dictionary = await _b7_senaryo([], a_gec)
	var sp: Dictionary = await _b7_senaryo([sa["kayit"]], [_b4_a(1, _b4_x_ge(900.0), 250), _b4_a(0, Callable(), 400)])
	var as_min := 1.0e9
	var as_son: float = sp["ozel"][sp["ozel"].size() - 1]["asansor"]
	for o in sp["ozel"]:
		as_min = minf(as_min, o["asansor"])
	ayr.append("asansör altında park: A ~190. karede PlakaA'dan ayrılır; asansör en yüksek y=%.0f (üst 390), park sonu y=%.0f (park asansörü F2'de tutmaz)" % [as_min, as_son])
	_kaydi("Bölüm 7 röle araştırması (ölçüm): tek geçit şalter geçidi; roller birleştirme/asansör park ile klon azaltılamıyor", bitenler.is_empty(),
		"TEK/İKİ KLONLA BİTEN: %s (denenen %d); %s" % [str(bitenler) if not bitenler.is_empty() else "YOK", denenen, "; ".join(ayr)])
	_kayitlar().sifirla()


## Bölüm 9: geçit (G) yalnız son oyuncunun yolundadır; plaka tutucusu klonların geçmesi gereken bir geçit
## yok. Denenen: k1' Plaka1'i oyuncu tutarken L0'ı geçip Plaka2'ye gider (oyuncu plakada T kare durur);
## sonra oyuncu L0'ı kendisi geçmek zorundadır (tutucu yok).
func _test_role_bolum9() -> void:
	aktif_bolum = BOLUM_9
	var ayr: Array = []
	var bitenler: Array = []
	var denenen := 0
	var kay: Array = await _b9_kayitlar()
	for T in [150, 220]:
		# k1': Plaka1 yerine doğrudan k2 rotası, ancak L0'ı oyuncunun Plaka1'de durduğu sırada geçer.
		var k2b: Dictionary = await _b9_senaryo([], _b9_k2(T))
		var oyuncu: Array = [_b4_a(1, _b4_x_ge(170.0), 60), _b4_a(0, _b4_plakada("Plaka1"), 40), _b4_a(0, Callable(), T + 80)] + _b9_k3() 			+ [_b4_a(1, _b4_bitti_k(), 300)]
		var so: Dictionary = await _b9_senaryo([k2b["kayit"], kay[2]], oyuncu)
		denenen += 1
		if so["bitti"]:
			bitenler.append("k2' T=%d" % T)
		ayr.append("k1 yerine oyuncu Plaka1'de T=%d tutar, klonlar k2'+k3: bitti=%s ölüm=%d" % [T, so["bitti"], so["oldu"]])
	_kaydi("Bölüm 9 röle araştırması (ölçüm): plaka-geçit rölesi yok (G klonların yolunda değil); oyuncu-tutucu denemesi klon azaltmıyor",
		bitenler.is_empty(), "İKİ KLONLA BİTEN: %s (denenen %d); %s" % [str(bitenler) if not bitenler.is_empty() else "YOK", denenen, "; ".join(ayr)])
	_kayitlar().sifirla()


## Bölüm 10: geçit (G) yalnız son oyuncunun yolundadır. Denenen: tek klon P2 -> PE (zaman paylaşımlı) ve
## C klonu ile; asansörle çıkan karakter L2 kapalıyken geçmeli, PE ve P2 aynı anda basılı olmalı.
func _test_role_bolum10() -> void:
	aktif_bolum = BOLUM_10
	var kay: Array = await _b10_kayitlar()
	var ayr: Array = []
	var bitenler: Array = []
	var denenen := 0
	for T in [20, 40, 80]:
		var xp: Array = _b10_giris() + [_b4_a(1, _b4_x_ge(510.0), 60), _b4_a(0, _b4_plakada("PlakaP2"), 60),
			_b4_a(0, Callable(), T), _b4_a(1, _b4_x_ge(580.0), 60), _b4_a(0, _b4_plakada("PlakaPE"), 60),
			_b4_a(0, Callable(), 10)]
		var sx: Dictionary = await _b10_senaryo([], xp)
		var so: Dictionary = await _b10_senaryo([sx["kayit"], kay[2]], _b10_oyuncu())
		var so2: Dictionary = await _b10_senaryo([sx["kayit"]], _b10_oyuncu())
		denenen += 2
		if so["bitti_ham"]:
			bitenler.append("X' T=%d + C" % T)
		if so2["bitti_ham"]:
			bitenler.append("X' T=%d tek" % T)
		ayr.append("X' (P2 T=%d sonra PE): +C bitti=%s ölüm=%d; tek bitti=%s ölüm=%d" % [T, so["bitti_ham"], so["oldu"], so2["bitti_ham"], so2["oldu"]])
	_kaydi("Bölüm 10 röle araştırması (ölçüm): P2->PE zaman paylaşımı ve G altı park klon sayısını düşürmüyor", bitenler.is_empty(),
		"TEK/İKİ KLONLA BİTEN: %s (denenen %d); %s" % [str(bitenler) if not bitenler.is_empty() else "YOK", denenen, "; ".join(ayr)])
	_kayitlar().sifirla()


# ---------------------------------------------------------------- ölü klon etkisizliği
# Not: ölümde set_deferred kullanıldığı için tam kareye iddia kurulmaz; yalnız
# ölümden sonra sürekli geçerli koşullar (son durum, kararlı durum) denetlenir.

## Gecit_test sahnesine lazer ekler (ağaçta Oyuncu'dan önce).
func _lazer_ekle(konum: Vector2) -> Callable:
	return func(b: Node) -> void:
		var l: Node = load("res://scenes/lazer.tscn").instantiate()
		l.yon = Vector2(0, 1)
		l.uzunluk = 200.0
		l.position = konum
		b.add_child(l)
		b.move_child(l, b.get_node("Oyuncu").get_index())


## Geçit: ölü klon geçidin kapanmasını engellemez (canlı klon engeller: kontrol).
func _test_olu_klon_gecit() -> void:
	var plaka_ayar := _tetikleyici_ayari(["Plaka"])
	var a: Array = await _kaydet(_betik([[30, 1, false], [110, 0, false], [30, -1, false]]))
	var b: Array = await _kaydet(_betik([[200, 1, false]]))
	var ornek := func(bb: Node) -> Dictionary:
		var k: Node = _klonlar(bb)[1]
		return {"gecit_y": bb.get_node("Gecit").position.y, "plaka": bb.get_node("Plaka").basili_mi(),
			"oldu": k.oldu, "x": k.global_position.x}
	# Ölü: lazer x=800'de B'yi öldürür (B x~783, geçit alanı x 790..810 ile örtüşür).
	var lazer_ayar: Callable = _lazer_ekle(Vector2(800, 450))
	var hazir_olu := func(bb: Node) -> void:
		plaka_ayar.call(bb)
		lazer_ayar.call(bb)
	var so: Dictionary = await _lazer_senaryo([a, b], [], 330, hazir_olu, ornek)
	# Kontrol: B canlı, 120 kare yürüyüp geçit altında (x=800) durur.
	var b_canli: Array = await _kaydet(_betik([[120, 1, false], [100, 0, false]]))
	var sk: Dictionary = await _lazer_senaryo([a, b_canli], [], 330, plaka_ayar, ornek)
	var son_o: Dictionary = so["ozel_iz"][so["ozel_iz"].size() - 1]
	var son_k: Dictionary = sk["ozel_iz"][sk["ozel_iz"].size() - 1]
	var en_acik := 1.0e9
	for o in so["ozel_iz"]:
		en_acik = minf(en_acik, o["gecit_y"])
	var olu_ok: bool = son_o["oldu"] and son_o["x"] > 770.0 and son_o["x"] < 800.0 and not son_o["plaka"] \
		and absf(son_o["gecit_y"] - GECIT_KAPALI_Y) < 0.01 and en_acik < GECIT_ACIK_Y + 1.0
	var kontrol_ok: bool = (not son_k["oldu"]) and son_k["x"] > 780.0 and not son_k["plaka"] \
		and son_k["gecit_y"] > GECIT_ACIK_Y + 5.0 and son_k["gecit_y"] < GECIT_KAPALI_Y - 5.0
	_kaydi("Ölü klon geçidin kapanmasını engellemez", olu_ok and kontrol_ok,
		"ölü B: ölü=%s x=%.0f, geçit en açık y=%.0f, sonunda y=%.0f (kapalı %.0f): kapandı: %s; kontrol (B canlı altında): x=%.0f, geçit y=%.0f (arada takıldı: %s)" % [
			son_o["oldu"], son_o["x"], en_acik, son_o["gecit_y"], GECIT_KAPALI_Y, olu_ok, son_k["x"], son_k["gecit_y"], kontrol_ok])


## Şalter: ölü klonun kaydı ölümden sonra oynamaya devam etmez; şalter çevrilmez (kontrol: canlıda çevrilir).
## Sınır: ölüm anındaki tek kare girdi okuması set_deferred yüzünden ayırt edilemez; bu yüzden
## klon şalter alanına varmadan (x~423 < 480) öldürülür.
func _test_olu_klon_salter() -> void:
	var yuru: Array = await _kaydet(_betik([[100, 1, false], [20, 0, false]]))
	var ornek := func(bb: Node) -> Dictionary:
		var k: Node = _klonlar(bb)[0]
		return {"salter": bb.get_node("Salter").sagda, "oldu": k.oldu, "x": k.global_position.x}
	var olu: Dictionary = await _lazer_senaryo([yuru], [], 160, _lazer_ekle(Vector2(440, 450)), ornek)
	var kontrol: Dictionary = await _lazer_senaryo([yuru], [], 160, Callable(), ornek)
	var son_o: Dictionary = olu["ozel_iz"][olu["ozel_iz"].size() - 1]
	var son_k: Dictionary = kontrol["ozel_iz"][kontrol["ozel_iz"].size() - 1]
	var hic_cevrilmedi := true
	for o in olu["ozel_iz"]:
		if o["salter"]:
			hic_cevrilmedi = false
	var ok: bool = son_o["oldu"] and son_o["x"] < 480.0 and hic_cevrilmedi and (not son_k["oldu"]) and son_k["salter"]
	_kaydi("Ölü klon şalteri çevirmez", ok,
		"ölü klon: ölü=%s x=%.0f, şalter hiç sağa geçmedi: %s; kontrol (klon canlı): şalter sağda: %s" % [
			son_o["oldu"], son_o["x"], hic_cevrilmedi, son_k["salter"]])


## Kapı: klon (canlı ya da ölü) kapıya ulaşsa bölüm bitmez; yalnız canlı oyuncu bitirir.
func _test_olu_klon_kapi() -> void:
	# Kayıt formatı {yon, zipla} olduğu için betik doğrudan klon kaydı olarak kullanılır.
	var yuru: Array = _betik([[230, 1, false]])
	var ornek := func(bb: Node) -> Dictionary:
		var k: Node = _klonlar(bb)[0]
		return {"oldu": k.oldu, "x": k.global_position.x, "kapi_acik": bb.get_node("Kapi").acik, "bitti": bb.bitti}
	# a) Işınlar uzağa taşınır: klon kapıya (x=1060) varır, bölüm bitmez.
	var uzak := func(bb: Node) -> void:
		bb.get_node("Lazer1").position = Vector2(-400, 400)
		bb.get_node("Lazer2").position = Vector2(-400, 400)
	var sa: Dictionary = await _lazer_senaryo([yuru], [], 260, uzak, ornek)
	var son_a: Dictionary = sa["ozel_iz"][sa["ozel_iz"].size() - 1]
	var ok_a: bool = sa["tamamlandi"] and not son_a["oldu"] and son_a["x"] > 1040.0 \
		and not son_a["kapi_acik"] and not son_a["bitti"]
	# b) Işınlar yerinde: klon L1'de ölür, kapı kapalı kalır.
	var sb: Dictionary = await _lazer_senaryo([yuru], [], 260, Callable(), ornek)
	var son_b: Dictionary = sb["ozel_iz"][sb["ozel_iz"].size() - 1]
	var ok_b: bool = sb["tamamlandi"] and son_b["oldu"] and son_b["x"] < 480.0 \
		and not son_b["kapi_acik"] and not son_b["bitti"]
	_kaydi("Klon kapıya ulaşsa da bölüm bitmez (canlı ve ölü klon)", ok_a and ok_b,
		"canlı klon x=%.0f kapı açık: %s, bölüm bitti: %s; ölü klon x=%.0f ölü: %s kapı açık: %s" % [
			son_a["x"], son_a["kapi_acik"], son_a["bitti"], son_b["x"], son_b["oldu"], son_b["kapi_acik"]])


## Aşama B (kutu, zıplatıcı, bant) testleri; `-- --kutu` ile yalnız bunlar koşulur (hızlı geliştirme).
func _asamab_testleri() -> void:
	aktif_bolum = KUTU_TEST
	await _test_kutu_itme()
	await _test_kutu_dusme()
	await _test_kutu_klon_determinizm()
	await _test_kutu_lazer()
	await _test_kutu_ustune_cik()
	await _test_kutu_zincir_yok()
	aktif_bolum = KUTU_PLAKA_TEST
	await _test_kutu_plaka()
	await _test_kutu_asansor_tasir()
	await _test_kutu_ezmez()
	aktif_bolum = ZIP_BANT_TEST
	await _test_ziplatici()
	await _test_tasima_bandi()


# ---------------------------------------------------------------- Aşama B: kutu, zıplatıcı, bant
# Taslak (docs/devir/asamaB_nesneler.md) iddialarına göre, gerçek Input yolu ve test sahneleriyle.

const KUTU_TEST := "res://tests/sahneler/kutu_test.tscn"
const KUTU_PLAKA_TEST := "res://tests/sahneler/kutu_plaka_test.tscn"
const ZIP_BANT_TEST := "res://tests/sahneler/ziplatici_bant_test.tscn"


## Her karede örneklenen durum: oyuncu, kutular, asansör, geçit, plaka, hızlar.
func _kb_ornek(b: Node) -> Dictionary:
	var d := {"o": b.get_node("Oyuncu").global_position, "ovy": b.get_node("Oyuncu").velocity.y}
	for ad in ["Kutu", "Kutu2", "Asansor", "Gecit"]:
		var n: Node2D = b.get_node_or_null(ad)
		if n != null:
			d[ad] = n.global_position
	var k: Node = b.get_node_or_null("Kutu")
	if k != null:
		d["kvy"] = k.velocity.y
	var p: Node = b.get_node_or_null("Plaka")
	if p != null:
		d["plaka"] = p.basili_mi()
	var l: Node = b.get_node_or_null("Lazer")
	if l != null:
		d["lazer_acik"] = l.acik_mi()
		d["lazerde_kutu"] = k != null and l.get_overlapping_bodies().has(k)
	var kl: Array = _klonlar(b)
	if kl.size() > 0:
		d["klon"] = kl[0].global_position
	return d


## Düğümleri verilen konumlara yerleştirir (asansör/geçit: yalnızca position; alt/kapalı konum sahnedeki kalır).
func _kb_yerlestir(konumlar: Dictionary) -> Callable:
	return func(b: Node) -> void:
		for ad in konumlar:
			var n: Node2D = b.get_node(ad)
			n.global_position = konumlar[ad]


func _kb_hepsi(iz: Array, anahtar: String, f: Callable, bas := 0, son := -1) -> bool:
	var s := iz.size() if son < 0 else mini(son, iz.size())
	for i in range(bas, s):
		if not f.call(iz[i][anahtar]):
			return false
	return true


func _kb_aralik(iz: Array, anahtar: String, eksen: String, bas: int, son: int) -> float:
	var lo := 1.0e9
	var hi := -1.0e9
	for i in range(bas, mini(son, iz.size())):
		var v: float = iz[i][anahtar][eksen]
		lo = minf(lo, v)
		hi = maxf(hi, v)
	return hi - lo


func _kb_min_y(iz: Array, anahtar: String) -> float:
	var m := 1.0e9
	for d in iz:
		m = minf(m, d[anahtar].y)
	return m


## 1) Oyuncu yürüyerek kutuyu iter, kutu dünya duvarında durur (sağ ve sol).
func _test_kutu_itme() -> void:
	var yer := {"Lazer": Vector2(-400, 400)}
	var s: Dictionary = await _lazer_senaryo([], _saga(400), 400, _kb_yerlestir(yer), _kb_ornek)
	var iz: Array = s["ozel_iz"]
	var son: Dictionary = iz[iz.size() - 1]
	var x60: float = iz[60]["Kutu"].x
	var sag_ok: bool = s["tamamlandi"] and x60 > 160.0 + 50.0 \
		and absf(son["Kutu"].x - 1132.0) <= 1.0 and absf(son["Kutu"].y - 580.0) <= 0.5 \
		and _kb_hepsi(iz, "Kutu", func(v): return v.x <= 1132.5) \
		and absf(son["o"].x - (1132.0 - 20.0 - 14.0)) <= 3.0
	_kaydi("Kutu 1a) Oyuncu sağa iter, kutu sağ duvarda durur", sag_ok,
		"kare 60 kutu x=%.1f (başlangıç 160), son kutu x=%.1f (beklenen 1132, duvar iç kenarı 1152), oyuncu x=%.1f, oyuncu_oldu=%d" % [
			x60, son["Kutu"].x, son["o"].x, s["oyuncu_oldu"]])
	yer = {"Lazer": Vector2(-400, 400), "Oyuncu": Vector2(700, 576), "Kutu": Vector2(600, 580)}
	s = await _lazer_senaryo([], _betik([[400, -1, false]]), 400, _kb_yerlestir(yer), _kb_ornek)
	iz = s["ozel_iz"]
	son = iz[iz.size() - 1]
	var sol_ok: bool = s["tamamlandi"] and absf(son["Kutu"].x - 20.0) <= 1.0 and absf(son["Kutu"].y - 580.0) <= 0.5 \
		and _kb_hepsi(iz, "Kutu", func(v): return v.x >= 19.5)
	_kaydi("Kutu 1b) Oyuncu sola iter, kutu sol duvarda durur", sol_ok,
		"son kutu x=%.1f (beklenen 20), oyuncu x=%.1f" % [son["Kutu"].x, son["o"].x])


## 2) Kutu raf kenarından düşer, zeminde durur.
func _test_kutu_dusme() -> void:
	var yer := {"Lazer": Vector2(-400, 400), "Oyuncu": Vector2(880, 496), "Kutu": Vector2(1000, 500)}
	var s: Dictionary = await _lazer_senaryo([], _saga(260), 260, _kb_yerlestir(yer), _kb_ornek)
	var iz: Array = s["ozel_iz"]
	var son: Dictionary = iz[iz.size() - 1]
	var ilk_dusus := -1
	for i in range(iz.size()):
		if iz[i]["Kutu"].y > 505.0:
			ilk_dusus = i
			break
	var rafta_ok: bool = _kb_hepsi(iz, "Kutu", func(v): return absf(v.y - 500.0) <= 0.5, 0, 20)
	var kenar_ok: bool = ilk_dusus > 0 and iz[ilk_dusus]["Kutu"].x > 1100.0
	var oynama: float = _kb_aralik(iz, "Kutu", "y", iz.size() - 30, iz.size())
	var durdu_ok: bool = absf(son["Kutu"].y - 580.0) <= 0.5 and oynama < 0.01 \
		and son["Kutu"].x > 1100.0 and son["Kutu"].x <= 1132.5
	_kaydi("Kutu 2) Platform kenarından düşer ve zeminde durur", rafta_ok and kenar_ok and durdu_ok,
		"rafta y=500 (ilk 20 kare): %s, düşüş karesi %d x=%.1f (kenar 1100), son y=%.2f (beklenen 580), son 30 karede y oynaması %.4f" % [
			rafta_ok, ilk_dusus, iz[ilk_dusus]["Kutu"].x if ilk_dusus >= 0 else -1.0, son["Kutu"].y, oynama])


## 3) Kutu plakayı basılı tutar; itilip plakadan çıkınca bırakır (oyuncu plakada değilken).
func _test_kutu_plaka() -> void:
	var yer := {"Oyuncu": Vector2(760, 576), "Kutu": Vector2(600, 580)}
	var s: Dictionary = await _lazer_senaryo([], _betik([[150, -1, false]]), 150, _kb_yerlestir(yer), _kb_ornek)
	var iz: Array = s["ozel_iz"]
	var bas_ok := true      # yalnız kutu plakada (oyuncu uzakta): basılı
	for i in range(4, 20):
		bas_ok = bas_ok and iz[i]["plaka"] and iz[i]["o"].x > 660.0
	var tut_ok := true      # kutu plakayla çakışıyor, oyuncu çakışmıyor: her zaman basılı
	var tut_n := 0
	var birak_ok := true    # ikisi de plakadan açıkta: basılı değil
	var birak_n := 0
	# Plaka durumu fizik adımında 1-2 kare gecikmeli okunur: koşul önceki 3 kare için de sağlanmalı.
	for i in range(3, iz.size()):
		var d: Dictionary = iz[i]
		var onceki: Dictionary = iz[i - 3]
		var kd: float = maxf(absf(d["Kutu"].x - 600.0), absf(onceki["Kutu"].x - 600.0))
		var od: float = minf(absf(d["o"].x - 600.0), absf(onceki["o"].x - 600.0))
		var kd_en_az: float = minf(absf(d["Kutu"].x - 600.0), absf(onceki["Kutu"].x - 600.0))
		if kd < 45.0 and od > 44.0 and d["Kutu"].y > 570.0:
			tut_n += 1
			tut_ok = tut_ok and d["plaka"]
		if kd_en_az > 55.0 and od > 50.0:
			birak_n += 1
			birak_ok = birak_ok and not d["plaka"]
	var son: Dictionary = iz[iz.size() - 1]
	var itildi: bool = son["Kutu"].x < 540.0
	_kaydi("Kutu 3) Kutu plakayı basılı tutar, itilince bırakır",
		bas_ok and tut_ok and birak_ok and tut_n > 5 and birak_n > 5 and itildi,
		"yalnız kutuyla basılı: %s, çakışırken basılı (%d kare): %s, ayrılınca bırakılmış (%d kare): %s, son kutu x=%.1f" % [
			bas_ok, tut_n, tut_ok, birak_n, birak_ok, son["Kutu"].x])


## 4) Klon aynı kod yoluyla iter: canlı oyuncuyla aynı kayıtta kutu ve konum birebir aynı; 100x determinizm.
func _test_kutu_klon_determinizm() -> void:
	var betik := _betik([[70, 1, false], [20, 0, false], [30, -1, false]])
	var kayit: Array = await _kaydet(betik)
	var canli: Dictionary = await _lazer_senaryo([], betik, 130, Callable(), _kb_ornek)
	var klon: Dictionary = await _lazer_senaryo([kayit], [], 130, Callable(), _kb_ornek)
	var cz: Array = canli["ozel_iz"]
	var kz: Array = klon["ozel_iz"]
	var maks := 0.0
	var n := mini(cz.size(), kz.size())
	for i in range(n):
		maks = maxf(maks, (cz[i]["Kutu"] - kz[i]["Kutu"]).length())
		maks = maxf(maks, (cz[i]["o"] - kz[i]["klon"]).length())
	var itti: bool = n == 130 and cz[69]["Kutu"].x > 160.0 + 100.0
	_kaydi("Kutu 4a) Klon kutuyu oyuncuyla aynı kod yoluyla iter", n == 130 and maks == 0.0 and itti,
		"%d kare, canlı oyuncu/kutu ile klon/kutu en büyük fark %.4f px (beklenen 0), kutu kare 69'da x=%.1f (başlangıç 160)" % [
			n, maks, cz[69]["Kutu"].x])
	var ref: Array = []
	var sapmali := 0
	var maks_sapma := 0.0
	for r in range(TEKRAR):
		var s: Dictionary = await _lazer_senaryo([kayit], [], 130, Callable(), _kb_ornek)
		var iz: Array = s["ozel_iz"]
		if r == 0:
			ref = iz
			continue
		var sap := iz.size() != ref.size()
		for i in range(mini(iz.size(), ref.size())):
			var d := maxf((iz[i]["Kutu"] - ref[i]["Kutu"]).length(), (iz[i]["klon"] - ref[i]["klon"]).length())
			if d > 0.0:
				sap = true
				maks_sapma = maxf(maks_sapma, d)
		if sap:
			sapmali += 1
	_kaydi("Kutu 4b) Klon + kutu determinizmi (%dx)" % TEKRAR, sapmali == 0 and ref.size() == 130,
		"%d çalıştırma, sapmalı: %d, en büyük sapma: %.4f px" % [TEKRAR, sapmali, maks_sapma])


## 5) Asansör kutuyla birlikte yükselir (kutu üstünde taşınır).
func _test_kutu_asansor_tasir() -> void:
	var yer := {"Oyuncu": Vector2(600, 576), "Kutu": Vector2(850, 580)}
	var s: Dictionary = await _lazer_senaryo([], [], 200, _kb_yerlestir(yer), _kb_ornek)
	var iz: Array = s["ozel_iz"]
	var son: Dictionary = iz[iz.size() - 1]
	var maks_bagil := 0.0
	for d in iz:
		maks_bagil = maxf(maks_bagil, absf(d["Kutu"].y - (d["Asansor"].y - 30.0)))
	var ok: bool = maks_bagil <= 5.0 and absf(son["Asansor"].y - 430.0) <= 1.5 \
		and absf(son["Kutu"].y - 400.0) <= 2.0 and absf(son["Kutu"].x - 850.0) <= 1.0
	_kaydi("Kutu 5) Asansör kutuyla birlikte yükselir", ok,
		"son asansör y=%.1f (beklenen 430), son kutu y=%.1f (beklenen 400) x=%.1f, kutu-asansör bağıl sapma en çok %.2f px" % [
			son["Asansor"].y, son["Kutu"].y, son["Kutu"].x, maks_bagil])


## 6) Asansör inerken altındaki kutuya ezmez/durur; geçit kapanırken altındaki kutuya durur.
## (AnimatableBody'nin konumu fizik dışında ayarlanamaz: Asansor2 yukarıda başlar, alt_y/geçit konumları değişkenle verilir.)
func _kb_ezme_ayari(kutu: Variant) -> Callable:
	return func(b: Node) -> void:
		b.get_node("Asansor2").alt_y = 610.0      # sahnede yukarıda başlar, plaka basılı değil: inmek ister
		var g: Node = b.get_node("Gecit2")        # sahnede açık konumda başlar, kapanmak ister
		g.kapali_konum = Vector2(500, 500)
		g.acik_konum = Vector2(500, 300)
		if kutu != null:
			b.get_node("Kutu").global_position = kutu


func _test_kutu_ezmez() -> void:
	# a) Asansör yukarıda (430), altında kutu: kutunun üstünde durur.
	var s: Dictionary = await _lazer_senaryo([], [], 200, _kb_ezme_ayari(Vector2(1000, 580)), func(b: Node) -> Dictionary:
		var d := _kb_ornek(b)
		d["A2"] = b.get_node("Asansor2").global_position
		return d)
	var iz: Array = s["ozel_iz"]
	var son: Dictionary = iz[iz.size() - 1]
	var maks_y := -1.0e9
	for d in iz:
		maks_y = maxf(maks_y, d["A2"].y)
	var a_ok: bool = maks_y <= 551.0 and son["A2"].y >= 535.0 		and _kb_hepsi(iz, "Kutu", func(v): return absf(v.y - 580.0) <= 0.5 and absf(v.x - 1000.0) <= 0.5)
	# kontrol: kutu yoksa asansör dibe (610) iner.
	var c: Dictionary = await _lazer_senaryo([], [], 200, _kb_ezme_ayari(null), func(b: Node) -> Dictionary:
		return {"A2": b.get_node("Asansor2").global_position})
	var c_son: Dictionary = c["ozel_iz"][c["ozel_iz"].size() - 1]
	var kontrol_ok: bool = absf(c_son["A2"].y - 610.0) <= 1.0
	_kaydi("Kutu 6a) Asansör inerken altındaki kutuya durur, ezmez", a_ok and kontrol_ok,
		"en alçak asansör y=%.1f (kutu üstü 560 -> <=551), son y=%.1f, kutu yerinde: %s; kutusuz kontrol son y=%.1f (beklenen 610)" % [
			maks_y, son["A2"].y, a_ok, c_son["A2"].y])
	# b) Geçit açık konumdan (300) kapanırken altında kutu var (kutu üstü 560 -> geçit alt kenarı <= 560).
	s = await _lazer_senaryo([], [], 200, _kb_ezme_ayari(Vector2(500, 580)), func(b: Node) -> Dictionary:
		var d := _kb_ornek(b)
		d["G2"] = b.get_node("Gecit2").global_position
		return d)
	iz = s["ozel_iz"]
	son = iz[iz.size() - 1]
	var maks_g := -1.0e9
	for d in iz:
		maks_g = maxf(maks_g, d["G2"].y)
	var b_ok: bool = maks_g <= 461.0 and son["G2"].y >= 440.0 		and _kb_hepsi(iz, "Kutu", func(v): return absf(v.y - 580.0) <= 0.5 and absf(v.x - 500.0) <= 0.5)
	var gc: Dictionary = await _lazer_senaryo([], [], 200, _kb_ezme_ayari(null), func(b: Node) -> Dictionary:
		return {"G2": b.get_node("Gecit2").global_position})
	var gc_son: Dictionary = gc["ozel_iz"][gc["ozel_iz"].size() - 1]
	_kaydi("Kutu 6b) Geçit kapanırken altındaki kutuya durur", b_ok and absf(gc_son["G2"].y - 500.0) <= 1.0,
		"en alçak geçit y=%.1f (kutu üstü 560 -> <=461), son y=%.1f; kutusuz kontrol son y=%.1f (beklenen 500)" % [
			maks_g, son["G2"].y, gc_son["G2"].y])


## 7) Lazer kutuyu yok etmez, engel sayılmaz; aynı yerde oyuncu ölür (kontrol).
func _test_kutu_lazer() -> void:
	var s: Dictionary = await _lazer_senaryo([], [], 120, _kb_yerlestir({"Kutu": Vector2(700, 580)}), _kb_ornek)
	var iz: Array = s["ozel_iz"]
	var ok: bool = s["tamamlandi"] and s["oyuncu_oldu"] == 0 \
		and _kb_hepsi(iz, "Kutu", func(v): return absf(v.x - 700.0) <= 0.5 and absf(v.y - 580.0) <= 0.5) \
		and _kb_hepsi(iz, "lazer_acik", func(v): return v) and _kb_hepsi(iz, "lazerde_kutu", func(v): return not v)
	var c: Dictionary = await _lazer_senaryo([], [], 60, _kb_yerlestir({"Oyuncu": Vector2(700, 576)}), _kb_ornek)
	_kaydi("Kutu 7) Lazer kutuyu yok etmez/engel sayılmaz", ok and c["oyuncu_oldu"] == 1,
		"kutu ışının içinde 120 kare yerinde: %s, ışın açık, kutu ışın alanında sayılmıyor; aynı noktada oyuncu ölümü: %d (beklenen 1)" % [
			ok, c["oyuncu_oldu"]])


## 8) Oyuncu kutunun üstüne çıkar ve ayakta durur.
func _test_kutu_ustune_cik() -> void:
	var yer := {"Oyuncu": Vector2(230, 576), "Kutu": Vector2(300, 580)}
	var s: Dictionary = await _lazer_senaryo([], _betik([[1, 1, true], [13, 1, false]]), 120, _kb_yerlestir(yer), _kb_ornek)
	var iz: Array = s["ozel_iz"]
	var son: Dictionary = iz[iz.size() - 1]
	var ok: bool = absf(son["o"].y - 536.0) <= 1.0 and son["o"].x > 266.0 and son["o"].x < 334.0 \
		and _kb_aralik(iz, "o", "y", iz.size() - 20, iz.size()) < 0.01 \
		and absf(son["Kutu"].x - 300.0) <= 0.5 and absf(son["Kutu"].y - 580.0) <= 0.5
	_kaydi("Kutu 8) Oyuncu kutunun üstüne çıkar, ayakta durur", ok,
		"son oyuncu (%.1f, %.1f) (beklenen y=536, x 266..334), kutu (%.1f, %.1f) yerinde" % [
			son["o"].x, son["o"].y, son["Kutu"].x, son["Kutu"].y])


## 9) Zincirleme itme yok: itilen kutu diğerine dayanınca durur, diğeri kımıldamaz.
func _test_kutu_zincir_yok() -> void:
	var yer := {"Oyuncu": Vector2(200, 576), "Kutu": Vector2(300, 580), "Kutu2": Vector2(400, 580)}
	var s: Dictionary = await _lazer_senaryo([], _saga(200), 200, _kb_yerlestir(yer), _kb_ornek)
	var iz: Array = s["ozel_iz"]
	var son: Dictionary = iz[iz.size() - 1]
	var ok: bool = _kb_hepsi(iz, "Kutu2", func(v): return absf(v.x - 400.0) <= 0.01 and absf(v.y - 580.0) <= 0.5) \
		and son["Kutu"].x > 357.0 and son["Kutu"].x <= 360.5 \
		and _kb_hepsi(iz, "Kutu", func(v): return v.x <= 360.5) and son["o"].x < 340.0
	_kaydi("Kutu 9) Kutu başka kutuyu zincirleme itmez", ok,
		"itilen kutu son x=%.2f (beklenen ~360), diğer kutu x=%.2f (beklenen 400, hiç kımıldamadı: %s), oyuncu x=%.1f" % [
			son["Kutu"].x, son["Kutu2"].x, ok, son["o"].x])


## Skaler hız dizisini {"v": ...} sözlük dizisine çevirir.
func _kb_hizlar(iz: Array, anahtar: String) -> Array:
	var c: Array = []
	for d in iz:
		c.append(d[anahtar])
	return c


## Fırlatıldıktan sonra tepeye kadar hız artışı yalnız yerçekimi kadar mı (yeniden tetikleme yok)?
func _kb_tek_tetik(v: Array) -> bool:
	var b := -1
	for i in range(v.size()):
		if v[i] < -700.0:
			b = i
			break
	if b < 0:
		return false
	var j := b + 1
	while j < v.size() and v[j] < 0.0:
		var fark: float = v[j] - v[j - 1]
		if fark <= 0.0 or fark > 24.0:
			return false
		j += 1
	return j > b + 20   # tepeye kadar en az 20 kare yükseldi


## YAYLI ZIPLATICI: karakter, klon ve kutu ~240 px (±15) yükselir; tek tetik; 100x determinizm.
func _test_ziplatici() -> void:
	# Oyuncu
	var s: Dictionary = await _lazer_senaryo([], [], 100, _kb_yerlestir({"Oyuncu": Vector2(300, 576)}), _kb_ornek)
	var iz: Array = s["ozel_iz"]
	var yuk: float = 576.0 - _kb_min_y(iz, "o")
	var tek: bool = _kb_tek_tetik(_kb_hizlar(iz, "ovy"))
	_kaydi("Zıplatıcı 1a) Oyuncu ~240 px yükselir, yükselirken tekrar tetiklenmez",
		absf(yuk - 240.0) <= 15.0 and tek,
		"yükselme %.1f px (beklenen 240 +-15), tek tetik: %s" % [yuk, tek])
	# Zıplama tuşu fırlatmayı zayıflatmaz: pad üstünde aynı karede zıpla basılı
	var ssz: Dictionary = await _lazer_senaryo([], _betik([[1, 0, true], [99, 0, false]]), 100, _kb_yerlestir({"Oyuncu": Vector2(300, 576)}), _kb_ornek)
	var yuk_z: float = 576.0 - _kb_min_y(ssz["ozel_iz"], "o")
	_kaydi("Zıplatıcı 1d) Pad üstünde zıplama tuşu fırlatmayı zayıflatmaz",
		yuk_z >= 235.0 and absf(yuk_z - yuk) <= 5.0,
		"tuşlu yükselme %.1f px (en az 235), tuşsuz %.1f px (fark <= 5)" % [yuk_z, yuk])
	# Kutu üst sınır duvarına çarpar, ekran dışına çıkmaz
	var ust := func(b: Node) -> void:
		b.get_node("Ziplatici2").global_position = Vector2(520, 130)
		b.get_node("Kutu").global_position = Vector2(520, 100)
		b.get_node("Oyuncu").global_position = Vector2(60, 576)
	var su: Dictionary = await _lazer_senaryo([], [], 120, ust, _kb_ornek)
	var uiz: Array = su["ozel_iz"]
	var ky_min := _kb_min_y(uiz, "Kutu")
	var yuksel: bool = false
	for d in uiz:
		if d["Kutu"].y < 100.0 - 20.0:
			yuksel = true
	_kaydi("Zıplatıcı 1e) Kutu üst sınır duvarına çarpar, ekran dışına çıkmaz",
		yuksel and ky_min >= 0.0,
		"kutu en yüksek merkez y=%.1f (>= 0 beklenir), yükseldi: %s" % [ky_min, yuksel])
	# Klon (gerçek kayıt, yürüyerek zıplatıcıya girer)
	var kayit: Array = await _kaydet(_betik([[48, 1, false], [100, 0, false]]))
	var sk: Dictionary = await _lazer_senaryo([kayit], [], 140, Callable(), _kb_ornek)
	var kmin := 1.0e9
	for p in sk["klon_izleri"][0]:
		kmin = minf(kmin, p.y)
	var klon_yuk: float = 576.0 - kmin
	_kaydi("Zıplatıcı 1b) Klon ~240 px yükselir", absf(klon_yuk - 240.0) <= 15.0,
		"klon yükselme %.1f px (beklenen 240 +-15)" % klon_yuk)
	# Kutu
	var sb: Dictionary = await _lazer_senaryo([], [], 100, _kb_yerlestir({"Kutu": Vector2(520, 580)}), _kb_ornek)
	var biz: Array = sb["ozel_iz"]
	var kutu_yuk: float = 580.0 - _kb_min_y(biz, "Kutu")
	var kt: bool = _kb_tek_tetik(_kb_hizlar(biz, "kvy"))
	_kaydi("Zıplatıcı 1c) Kutu ~240 px yükselir, tek tetik", absf(kutu_yuk - 240.0) <= 15.0 and kt,
		"kutu yükselme %.1f px (beklenen 240 +-15), tek tetik: %s" % [kutu_yuk, kt])
	# Determinizm: klon + oyuncu + kutu
	var yer := _kb_yerlestir({"Oyuncu": Vector2(300, 576), "Kutu": Vector2(520, 580)})
	var ref: Array = []
	var sapmali := 0
	var maks_sapma := 0.0
	for r in range(TEKRAR):
		var d: Dictionary = await _lazer_senaryo([kayit], [], 150, yer, _kb_ornek)
		var z: Array = d["ozel_iz"]
		if r == 0:
			ref = z
			continue
		var sap := z.size() != ref.size()
		for i in range(mini(z.size(), ref.size())):
			for a in ["o", "Kutu", "klon"]:
				var df: float = (z[i][a] - ref[i][a]).length()
				if df > 0.0:
					sap = true
					maks_sapma = maxf(maks_sapma, df)
		if sap:
			sapmali += 1
	var hareketli: bool = 580.0 - _kb_min_y(ref, "Kutu") > 200.0 and 576.0 - _kb_min_y(ref, "o") > 200.0
	_kaydi("Zıplatıcı 2) Yön/hız determinizmi (%dx: oyuncu+klon+kutu)" % TEKRAR, sapmali == 0 and hareketli,
		"%d çalıştırma, sapmalı: %d, en büyük sapma: %.4f px, hareket var: %s" % [TEKRAR, sapmali, maks_sapma, hareketli])


## TAŞIMA BANDI: girdisiz yön*hız kayma (iki yön), kutu da taşınır, bandan inince etki biter.
func _test_tasima_bandi() -> void:
	var durumlar := [
		["Oyuncu sağ bant", {"Oyuncu": Vector2(700, 560)}, "o", 50.0],
		["Oyuncu sol bant", {"Oyuncu": Vector2(950, 560)}, "o", -50.0],
		["Kutu sağ bant", {"Kutu": Vector2(700, 564)}, "Kutu", 50.0],
		["Kutu sol bant", {"Kutu": Vector2(950, 564)}, "Kutu", -50.0],
	]
	var hepsi := true
	var ayr: Array = []
	for t in durumlar:
		var s: Dictionary = await _lazer_senaryo([], [], 70, _kb_yerlestir(t[1]), _kb_ornek)
		var iz: Array = s["ozel_iz"]
		var dx: float = iz[50][t[2]].x - iz[20][t[2]].x
		hepsi = hepsi and absf(dx - t[3]) <= 3.0
		ayr.append("%s: 30 karede dx=%.1f (beklenen %.0f)" % [t[0], dx, t[3]])
	_kaydi("Bant 1) Üstündeki oyuncu ve kutu girdisiz yön*hız ile kayar (iki yön)", hepsi, "; ".join(ayr))
	# Bandan inince etki biter: oyuncu ve kutu ayrı koşularda sağ uçtan düşer.
	var ayr2: Array = []
	var hepsi2 := true
	for t in [["Oyuncu", {"Oyuncu": Vector2(760, 560)}, 576.0], ["Kutu", {"Kutu": Vector2(770, 564)}, 580.0]]:
		var s: Dictionary = await _lazer_senaryo([], [], 200, _kb_yerlestir(t[1]), _kb_ornek)
		var z: Array = s["ozel_iz"]
		var an: String = "o" if t[0] == "Oyuncu" else "Kutu"
		var son: Dictionary = z[z.size() - 1]
		var oyn: float = _kb_aralik(z, an, "x", z.size() - 40, z.size())
		hepsi2 = hepsi2 and son[an].x > 794.0 and absf(son[an].y - t[2]) <= 1.0 and oyn < 0.01
		ayr2.append("%s: son (%.1f, %.1f), son 40 karede x oynaması %.4f" % [t[0], son[an].x, son[an].y, oyn])
	_kaydi("Bant 2) Bandan inince etki biter (zeminde kaymaz)", hepsi2, "; ".join(ayr2))


# ---------------------------------------------------------------- rapor

func _rapor_yaz(sure: float, hepsi: bool) -> void:
	var yol := "res://docs/testler.md"
	var metin := ""
	if FileAccess.file_exists(yol):
		metin = FileAccess.get_file_as_string(yol)
	else:
		metin = "# Otomatik test sonuçları\n\nÇalıştırma: `--headless --path . --fixed-fps 60 --script res://tests/test_runner.gd -- --rapor`\n"
	var t := Time.get_datetime_dict_from_system()
	var damga := "%04d-%02d-%02d %02d:%02d" % [t["year"], t["month"], t["day"], t["hour"], t["minute"]]
	metin += "\n## %s — %s\n\n" % [damga, "GEÇTİ" if hepsi else "KALDI"]
	metin += "\n".join(rapor_satirlari)
	metin += "\n- **Toplam süre (gerçek saat, yalnızca bilgi):** %.1f sn\n" % sure
	var f := FileAccess.open(yol, FileAccess.WRITE)
	f.store_string(metin)
	f.close()
