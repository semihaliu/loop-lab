extends SceneTree
## Klon mantığı için otomatik testler. Oyun koduna dokunmaz; canlı oyuncunun
## girdisini Input.action_press ile enjekte eder, her şey fizik karesine bağlıdır.
##
## Çalıştırma (tek komut, gerçek saatten bağımsız):
##   Godot --headless --path . --fixed-fps 60 --script res://tests/test_runner.gd
## Rapor dosyasına yazmak için sonuna `-- --rapor` ekle (docs/testler.md).
## Çıkış kodu: hepsi geçtiyse 0, değilse 1.

const BOLUM := "res://scenes/bolumler/bolum_1.tscn"
## Yüklenme gecikmeli: preload, başlangıçta bölüm fiziğini etkileyen RID/geniş-faz sırasını kaydırıyordu (B13/B14/B19 canlı-klon sınırları).
const EDITOR_TESTLERI_YOLU := "res://tests/editor_testleri.gd"
## Editör sınıfları yüklenmeden çalışması gerekir (editör grubundan ÖNCE, gecikmeli load); bu dosya editör sınıflarına başvurmaz.
const DENE_FIZIK_YOLU := "res://tests/dene_fizik_testleri.gd"

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
	# A12: kullanıcının gerçek `user://canli/` bölümleri numaraya bağlı testleri etkilemesin; testler yalnız
	# test köküne bakar (burada canlı bölüm yoksa liste 21 resmî kayıttır, A12 testleri geçici canlı ekler).
	BolumListesi.kullanici_kok = "user://test_editor/"
	BolumListesi.yenile()
	_calistir()


func _calistir() -> void:
	var baslangic := Time.get_ticks_msec()
	if Engine.physics_ticks_per_second != 60:
		print("UYARI: fizik kare hızı 60 değil: ", Engine.physics_ticks_per_second)

	if "--sdusme" in OS.get_cmdline_user_args():
		aktif_bolum = ASAGI_TEST
		await _asagi_testleri()
		var hepsi_sd := true
		for s in sonuclar:
			hepsi_sd = hepsi_sd and s["gecti"]
			print("[%s] %s" % ["GEÇTİ" if s["gecti"] else "KALDI", s["ad"]])
		quit(0 if hepsi_sd else 1)
		return
	if "--plaka" in OS.get_cmdline_user_args():
		await _plaka_testleri()
		var hepsi_pl := true
		for s in sonuclar:
			hepsi_pl = hepsi_pl and s["gecti"]
			print("[%s] %s | %s" % ["GEÇTİ" if s["gecti"] else "KALDI", s["ad"], s["ayrinti"]])
		for o in pl_olcum:
			print("ÖLÇÜM: ", o)
		quit(0 if hepsi_pl else 1)
		return
	if "--arayuz" in OS.get_cmdline_user_args():
		await _arayuz_testleri()
		var hepsi_ar := true
		for s in sonuclar:
			hepsi_ar = hepsi_ar and s["gecti"]
			print("[%s] %s | %s" % ["GEÇTİ" if s["gecti"] else "KALDI", s["ad"], s["ayrinti"]])
		quit(0 if hepsi_ar else 1)
		return
	if "--tustu" in OS.get_cmdline_user_args():
		await _tustu_testleri()
		var hepsi_tt := true
		for s in sonuclar:
			hepsi_tt = hepsi_tt and s["gecti"]
			print("[%s] %s | %s" % ["GEÇTİ" if s["gecti"] else "KALDI", s["ad"], s["ayrinti"]])
		quit(0 if hepsi_tt else 1)
		return
	if "--ipucu" in OS.get_cmdline_user_args():
		await _ipucu_testleri()
		var hepsi_ip := true
		for s in sonuclar:
			hepsi_ip = hepsi_ip and s["gecti"]
			print("[%s] %s | %s" % ["GEÇTİ" if s["gecti"] else "KALDI", s["ad"], s["ayrinti"]])
		quit(0 if hepsi_ip else 1)
		return
	var _arg_n := OS.get_cmdline_user_args()
	if "--b18" in _arg_n or "--b19" in _arg_n or "--b20" in _arg_n or "--b21" in _arg_n:
		if "--b18" in _arg_n:
			aktif_bolum = BOLUM_18
			await _b18_calistir()
		if "--b19" in _arg_n:
			aktif_bolum = BOLUM_19
			await _b19_calistir()
		if "--b20" in _arg_n:
			aktif_bolum = BOLUM_20
			await _b20_calistir()
		if "--b21" in _arg_n:
			aktif_bolum = BOLUM_21
			await _b21_calistir()
		var hepsi_y := true
		for sy in sonuclar:
			hepsi_y = hepsi_y and sy["gecti"]
			print("[%s] %s | %s" % ["GEÇTİ" if sy["gecti"] else "KALDI", sy["ad"], sy["ayrinti"]])
		print("TOPLAM: %s (%d test)" % ["GEÇTİ" if hepsi_y else "KALDI", sonuclar.size()])
		if "--rapor" in _arg_n:
			_rapor_yaz(0.0, hepsi_y)
		quit(0 if hepsi_y else 1)
		return
	if "--b15" in _arg_n or "--b16" in _arg_n or "--b17" in _arg_n:
		if "--b15" in _arg_n:
			aktif_bolum = BOLUM_15
			await _b15_calistir()
		if "--b16" in _arg_n:
			aktif_bolum = BOLUM_16
			await _b16_calistir()
		if "--b17" in _arg_n:
			aktif_bolum = BOLUM_17
			await _b17_calistir()
		var hepsi_n := true
		for sn in sonuclar:
			hepsi_n = hepsi_n and sn["gecti"]
			print("[%s] %s | %s" % ["GEÇTİ" if sn["gecti"] else "KALDI", sn["ad"], sn["ayrinti"]])
		print("TOPLAM: %s (%d test)" % ["GEÇTİ" if hepsi_n else "KALDI", sonuclar.size()])
		if "--rapor" in _arg_n:
			_rapor_yaz(0.0, hepsi_n)
		quit(0 if hepsi_n else 1)
		return
	if "--b14" in OS.get_cmdline_user_args():
		aktif_bolum = BOLUM_14
		await _b14_calistir()
		var hepsi_14 := true
		for s in sonuclar:
			hepsi_14 = hepsi_14 and s["gecti"]
			print("[%s] %s | %s" % ["GEÇTİ" if s["gecti"] else "KALDI", s["ad"], s["ayrinti"]])
		if "--rapor" in OS.get_cmdline_user_args():
			_rapor_yaz(0.0, hepsi_14)
		quit(0 if hepsi_14 else 1)
		return
	if "--b13" in OS.get_cmdline_user_args():
		aktif_bolum = BOLUM_13
		await _b13_calistir()
		for s in sonuclar:
			print("[%s] %s | %s" % ["GEÇTİ" if s["gecti"] else "KALDI", s["ad"], s["ayrinti"]])
		quit(0)
		return
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
		await _test_bolum10_klon_fark()
		await _test_bolum10_pg_tutma()
		await _test_bolum10_p1_pencere()
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
		await _test_bolum9_pencereler()
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
	if "--dene-fizik" in OS.get_cmdline_user_args():
		await load(DENE_FIZIK_YOLU).new(self).hepsi()
		var hepsi_df := true
		for s in sonuclar:
			hepsi_df = hepsi_df and s["gecti"]
			print("[%s] %s | %s" % ["GEÇTİ" if s["gecti"] else "KALDI", s["ad"], s["ayrinti"]])
		print("TOPLAM: %s (%d test)" % ["GEÇTİ" if hepsi_df else "KALDI", sonuclar.size()])
		quit(0 if hepsi_df else 1)
		return
	if "--editor" in OS.get_cmdline_user_args():
		await load(EDITOR_TESTLERI_YOLU).new(self).hepsi()
		var hepsi_ed := true
		for s in sonuclar:
			hepsi_ed = hepsi_ed and s["gecti"]
			print("[%s] %s | %s" % ["GEÇTİ" if s["gecti"] else "KALDI", s["ad"], s["ayrinti"]])
		print("TOPLAM: %s (%d test)" % ["GEÇTİ" if hepsi_ed else "KALDI", sonuclar.size()])
		quit(0 if hepsi_ed else 1)
		return
	if "--ed-a11" in OS.get_cmdline_user_args():
		await load(EDITOR_TESTLERI_YOLU).new(self).a11_testleri()
		var hepsi_a11 := true
		for s in sonuclar:
			hepsi_a11 = hepsi_a11 and s["gecti"]
			print("[%s] %s | %s" % ["GEÇTİ" if s["gecti"] else "KALDI", s["ad"], s["ayrinti"]])
		print("TOPLAM: %s (%d test)" % ["GEÇTİ" if hepsi_a11 else "KALDI", sonuclar.size()])
		quit(0 if hepsi_a11 else 1)
		return
	if "--gorunurluk" in OS.get_cmdline_user_args():
		await _gorunurluk_testleri()
		var hepsi_gr := true
		for s in sonuclar:
			hepsi_gr = hepsi_gr and s["gecti"]
			print("[%s] %s | %s" % ["GEÇTİ" if s["gecti"] else "KALDI", s["ad"], s["ayrinti"]])
		print("TOPLAM: %s (%d test)" % ["GEÇTİ" if hepsi_gr else "KALDI", sonuclar.size()])
		quit(0 if hepsi_gr else 1)
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
	await _test_bolum9_pencereler()
	aktif_bolum = BOLUM_10
	await _test_bolum10_cozum()
	await _test_bolum10_bant()
	await _test_bolum10_atlanamaz()
	await _test_bolum10_atlanamaz_l2_kapali()
	await _test_bolum10_kisayol()
	await _test_bolum10_basarisizlik()
	await _test_bolum10_klon_siniri()
	await _test_bolum10_determinizm()
	await _test_bolum10_klon_fark()
	await _test_bolum10_pg_tutma()
	await _test_bolum10_p1_pencere()
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
	aktif_bolum = BOLUM_13
	await _b13_calistir()
	aktif_bolum = BOLUM_14
	await _b14_calistir()
	aktif_bolum = BOLUM_15
	await _b15_calistir()
	aktif_bolum = BOLUM_16
	await _b16_calistir()
	aktif_bolum = BOLUM_17
	await _b17_calistir()
	aktif_bolum = BOLUM_18
	await _b18_calistir()
	aktif_bolum = BOLUM_19
	await _b19_calistir()
	aktif_bolum = BOLUM_20
	await _b20_calistir()
	aktif_bolum = BOLUM_21
	await _b21_calistir()
	aktif_bolum = GECIT_TEST
	await _test_olu_klon_gecit()
	await _test_olu_klon_salter()
	aktif_bolum = BOLUM_3
	await _test_olu_klon_kapi()
	await _asamab_testleri()
	aktif_bolum = ASAGI_TEST
	await _asagi_testleri()
	await _ipucu_testleri()
	await _plaka_testleri()
	await _arayuz_testleri()
	await _tustu_testleri()
	await _gorunurluk_testleri()
	await load(DENE_FIZIK_YOLU).new(self).hepsi()
	await load(EDITOR_TESTLERI_YOLU).new(self).hepsi()
	for o in pl_olcum:
		print("ÖLÇÜM: ", o)
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
	for a in ["sol", "sag", "zipla", "asagi"]:
		Input.action_release(a)
	if g.get("asagi", false):
		Input.action_press("asagi")
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
	var listede: bool = yollar.has(BOLUM) and yollar.has(BOLUM_2) and yollar.size() == BolumListesi.liste().size() and yollar.size() >= 2
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
	var bolum2_mi: bool = yeni != null and yeni.scene_file_path == BolumListesi.sonraki(BOLUM)   # listedeki sonraki (araya canlı eklenebilir)
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
	var kayitlar: Array = BolumListesi.liste()
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
		if (merkez - kayitlar[i]["konum"]).length() > 0.01 or (merkez - HaritaYerlesimi.konum(i, kayitlar.size())).length() > 0.01:
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
	var dogru: bool = girilen != null and girilen.scene_file_path == BolumListesi.liste()[1]["yol"]
	var klon0: bool = girilen != null and _klonlar(girilen).size() == 0 and _kayitlar().turlar.size() == 0
	var tur_1: bool = girilen != null and girilen.bilgi.text.begins_with("Tur 1 ")
	_kaydi("Harita düğümü: doğru bölüm, klon 0, tur 1", dogru and klon0 and tur_1,
		"listedeki 2. bölüm yüklendi: %s, klon sayısı 0 ve Kayitlar boş: %s, tur etiketi Tur 1: %s" % [dogru, klon0, tur_1])

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
	var kayitlar: Array = BolumListesi.liste()
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
	var kayitlar: Array = BolumListesi.liste()
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
# Not: bölüm sayısı ve sırası BolumListesi.liste()'den (resmî + canlı) türetilir; araya canlı bölüm eklenince bu testler kırılmaz.

func _liste_yollari() -> Array:
	var yollar: Array = []
	for k in BolumListesi.liste():
		yollar.append(k["yol"])
	return yollar


## Liste verisi: en az 8 kayıt, ilk 8 yol sıralı, dosyalar var/yüklenebilir/örneklenebilir,
## Kapi ve Oyuncu var, bağlantılar tutarlı, konumlar ekran içinde ve çakışmasız, sonraki zinciri.
func _test_bolum_listesi() -> void:
	var kayitlar: Array = BolumListesi.liste()
	var n: int = kayitlar.size()
	var yollar: Array = BolumListesi.yollar()
	# Resmî kayıtların göreli sırası bolum_1.. olarak korunur (araya canlı bölüm girse de); numara = liste indeksi + 1.
	var resmi_say := 0
	var ilk8: bool = n >= 8
	for k in kayitlar:
		if k["kaynak"] == "resmi":
			resmi_say += 1
			ilk8 = ilk8 and k["yol"] == "res://scenes/bolumler/bolum_%d.tscn" % resmi_say
	ilk8 = ilk8 and resmi_say >= 8
	_kaydi("Bölüm listesi en az 8 kayıt, resmî kayıtlar bolum_1.. göreli sırada", ilk8 and yollar == _liste_yollari(),
		"kayıt: %d, resmî: %d, yollar: %s" % [n, resmi_say, str(yollar)])

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
const B9_F2_Y := 430.0                         # F2 (Kat2) yüzeyi (2026-10-16 ayar: 440 -> 430)
const B9_PK_X := 910.0                         # PlakaKutu merkezi x (2026-10-16 ayar: 930 -> 910)
const B9_ASANSOR_UST_Y := B9_F2_Y + 10.0       # asansör merkezi üstte (üst yüzey = F2 hizası)
const B9_GECIT_KAPALI_Y := 330.0               # geçit merkezi kapalıyken (2026-10-16 ayar: 340 -> 330)
const B9_GECIT_ACIK_Y := B9_GECIT_KAPALI_Y - 69.5   # geçit merkezi açık (kayma 70)
const B9_GECIT_GECIS_Y := B9_F2_Y - 148.0      # geçit merkezi <= bu değerse ayakta geçilir (baş F2-48, geçit yarı boyu 100)
const B9_K2_BEKLE := 60                        # (2026-10-16 ayar: 120 -> 60) k2'nin platforma zıplamadan önceki beklemesi (kare)

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
func _b9_k2(bekle := B9_K2_BEKLE) -> Array:
	return [_b4_a(1, _b4_x_ge(350.0), 100), _b4_a(0, Callable(), bekle),
		_b4_a(0, _b4_durdu(510.0), 120, true), _b4_a(1, _b4_x_ge(380.0), 40),
		_b4_a(0, _b4_plakada("Plaka2"), 60), _b4_a(0, Callable(), 10)]


## Ortak: kutuyu asansöre yükle, asansör üstte olunca (position.y <= 450) bekleme biter.
## dur_x: oyuncunun asansörde durduğu x (kutu önünde); gecikme: yola çıkmadan önce bekleme (kare).
func _b9_yukle(dur_x := 620.0, gecikme := 0) -> Array:
	return [_b4_a(0, Callable(), gecikme), _b4_a(1, _b4_x_ge(dur_x), 200), _b4_a(0, _b4_yukari("Asansor", B9_ASANSOR_UST_Y), 400)]


## Tur 3 -> k3: kutuyu F2'ye taşı, Plaka3'e (x=760) bas.
func _b9_k3(dur_x := 620.0, gecikme := 0) -> Array:
	return _b9_yukle(dur_x, gecikme) + [_b4_a(1, _b4_x_ge(760.0), 100), _b4_a(0, _b4_plakada("Plaka3"), 60), _b4_a(0, Callable(), 10)]


## Alternatif S2 k3: kutuyu Plaka3'e iter (x=726), üstünden zıplayıp PlakaKutu'ya basar.
func _b9_k3_s2() -> Array:
	return _b9_yukle() + [_b4_a(1, _b4_x_ge(726.0), 100), _b4_a(0, Callable(), 8, true),
		_b4_a(1, _b4_x_ge(B9_PK_X), 80), _b4_a(0, _b4_plakada("PlakaKutu"), 60), _b4_a(0, Callable(), 10)]


## Tur 4 -> oyuncu (S1): kutuyu PlakaKutu'ya iter (kutu merkezi = oyuncu x + 34), üstünden zıplar, G'nin altından kapıya.
## itme_x: itmenin bittiği oyuncu x'i; zipla_bekle: dikey zıplamadan sonra sağa geçmeden önceki kare.
## Oyuncu L1'i (x=860) ekrana bakarak geçer: x=800'de L1 kapanana kadar bekler (normal akışta zaten kapalıdır).
func _b9_oyuncu(itme_x := B9_PK_X - 34.0, zipla_bekle := 8) -> Array:
	var l1_kapali := func(b: Node) -> bool: return not b.get_node("Lazer2").acik_mi()
	return _b9_yukle() + [_b4_a(1, _b4_x_ge(800.0), 150), _b4_a(0, l1_kapali, 200),
		_b4_a(1, _b4_x_ge(itme_x), 150), _b4_a(0, Callable(), zipla_bekle, true),
		_b4_a(1, _b4_x_ge(itme_x + 60.0), 40), _b4_a(0, _b4_durdu(B9_F2_Y + 1.0), 80), _b4_a(1, _b4_bitti_k(), 300)]


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
	_kaydi("Bölüm 9 atlanamaz: zeminden zıplayarak F2'ye (ayak y<430) çıkılamaz", mb >= 490.0 and mb < 599.0 and not sb["bitti"] and sb["oldu"] == 0,
		"ayak y min=%.1f (zıplama tepesi ~499, F2 yüzeyi 430), zıpladı: %s, ölüm: %d" % [mb, mb < 595.0, sb["oldu"]])

	# c) Kutu basamak: kutuyu Kat2'ye (x=702) kadar iter, üstüne çıkıp zıpla; ayak y>=430 kalır (F2 yüzeyi 430).
	var adim_c: Array = [_b4_a(1, _b4_x_ge(640.0), 400)] + _b8_zipla_dizisi(2, 1.0, 25) + _b8_zipla_dizisi(5, 1.0, 40)
	var sc: Dictionary = await _b9_senaryo([], adim_c, _b9_yerlestir(Vector2(440.0, 570.0)))
	var mc := _b4_ayak_min(sc["iz"])
	var kc: Vector2 = _b9_kutu_aralik(sc["ozel"], "x")
	_kaydi("Bölüm 9 atlanamaz: kutu basamak yapılarak F2'ye çıkılamaz", mc >= 445.0 and not sc["bitti"] and sc["oldu"] == 0,
		"ayak y min=%.1f (kutu üstü 560, zıplama tepesi ~459; F2 430), kutu x: %.0f..%.0f (Kat2 duvarı 702 -> en çok 682), ölüm: %d" % [
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
	var se: Dictionary = await _b9_senaryo([], _b8_zipla_dizisi(8, 1.0, 25), _b9_yerlestir(Vector2(780.0, B9_F2_Y - 24.0)))
	var bas_e := 1.0e9
	for p in se["iz"]:
		bas_e = minf(bas_e, p.y - 24.0)
	_kaydi("Bölüm 9 atlanamaz: F2'de zıplayarak L1 aşılamaz", se["oldu"] >= 1 and not se["bitti"] and bas_e >= 300.0 and _b7_hic(se["ozel"], "l1"),
		"ölüm: %d (beklenen >=1), baş y min=%.1f (tavan 300), L1 açıktı: %s" % [se["oldu"], bas_e, _b7_hic(se["ozel"], "l1")])
	var sg: Dictionary = await _b9_senaryo([], [_b4_a(1, Callable(), 80)] + _b8_zipla_dizisi(6, 1.0, 30), _b9_yerlestir(Vector2(990.0, B9_F2_Y - 24.0)))
	var son_g := 0.0
	for p in sg["iz"]:
		son_g = maxf(son_g, p.x)
	_kaydi("Bölüm 9 atlanamaz: kapalı G yürüyerek/zıplayarak aşılamaz", son_g < 1050.0 and not sg["bitti"] and sg["oldu"] == 0 \
		and _b7_min(sg["ozel"], "g") > B9_GECIT_KAPALI_Y - 5.0,
		"en büyük x=%.0f (G sol yüzü 1060, bedel 14), geçit y min=%.0f (kapalı %.0f), ölüm: %d, bitti: %s" % [
			son_g, _b7_min(sg["ozel"], "g"), B9_GECIT_KAPALI_Y, sg["oldu"], sg["bitti"]])
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
			_b4_a(1, _b4_x_ge(B9_PK_X), 80), _b4_a(0, Callable(), 100), _b4_a(1, _b4_bitti_k(), 200)]
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
	var role3: Array = _b9_yukle() + [_b4_a(1, _b4_x_ge(B9_PK_X - 34.0), 150), _b4_a(0, Callable(), 8, true),
		_b4_a(1, _b4_x_ge(B9_PK_X + 26.0), 40), _b4_a(0, Callable(), 30), _b4_a(-1, _b4_x_le(760.0), 200), _b4_a(0, Callable(), 10)]
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
	var ok2: bool = not s2["bitti"] and kutu2.x > B9_PK_X + 50.0 and not son_pk
	_kaydi("Bölüm 9 başarısızlık: kutu PlakaKutu'yu aşıp G'ye itilir, bitmez", ok2,
		"bitti: %s, ölüm: %d, son kutu x=%.0f (plaka %.0f..%.0f, G 1060), PlakaKutu basılı: %s, geçit y=%.0f (kapalı %.0f)" % [
			s2["bitti"], s2["oldu"], kutu2.x, B9_PK_X - 30.0, B9_PK_X + 30.0, son_pk, son_g, B9_GECIT_KAPALI_Y])

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
		if ilk_f2 < 0 and o["kutu"].x >= 722.0 and absf(o["kutu"].y - (B9_F2_Y - 20.0)) <= 2.0:
			ilk_f2 = i
	var son: Vector2 = _b9_kutu_son(s)
	var as_son: float = s["ozel"][s["ozel"].size() - 1]["as"]
	var ok: bool = tasindi and bagil_maks <= 5.0 and ilk_f2 > 0 and absf(son.y - (B9_F2_Y - 20.0)) <= 2.0 \
		and son.x > 722.0 and absf(as_son - B9_ASANSOR_UST_Y) <= 1.5 and s["oldu"] == 0
	_kaydi("Bölüm 9: kutu asansörle F2'ye taşınır (konum ölçümü)", ok,
		"asansörle yükseldi: %s (kutu-asansör bağıl sapma en çok %.2f px), F2'ye ilk geçiş kare %d, son kutu=(%.1f,%.1f) (F2 yüzeyi %.0f -> y %.0f), asansör y=%.1f (üstte %.0f), klon ölümleri: %s, oyuncu ölümü: %d" % [
			tasindi, bagil_maks, ilk_f2, son.x, son.y, B9_F2_Y, B9_F2_Y - 20.0, as_son, B9_ASANSOR_UST_Y, str(s["klon_oldu"]), s["oldu"]])
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
		var sa: Dictionary = await _b9_senaryo([], adim_a, _b9_yerlestir(Vector2(B9_PK_X + 20.0, B9_F2_Y - 24.0)))
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
			and (ilk < 0 or g_ilk >= B9_GECIT_GECIS_Y)
		ok_a = ok_a and ok
		ayr_a.append("gecikme %d: en büyük x=%.1f, x>=1041 kare=%d, o karede G y=%.0f (geçiş için <=%.0f; pay %.0f px = %.1f kare), bitti=%s, ölüm=%d" % [
			gecikme, maks, ilk, g_ilk, B9_GECIT_GECIS_Y, g_ilk - B9_GECIT_GECIS_Y, (g_ilk - B9_GECIT_GECIS_Y) / 2.0, sa["bitti"], sa["oldu"]])
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
		if p.x >= 702.0 and p.y + B4_AYAK <= B9_F2_Y + 1.0:
			f2_b = true
	# 2026-10-16 ayar: F2 440 -> 430; basamaktan F2'ye gereken 96 -> 106 px (ayrık karede zıplama tepesi ~100,9): artık F2'ye çıkılamaz.
	_kaydi("Bölüm 9 ölçüm: asansör kutuda takılıp basamak olur; basamaktan F2'ye çıkılamaz, bitmez",
		not sk2["tamam"].has(false) and not sb["tamam"].slice(0, 5).has(false) \
		and as_ara > 535.0 and as_ara < 600.0 and not sb["bitti"] and not f2_b and mb > B9_F2_Y + 1.0,
		"klon adımları %s, oyuncu adımları %s, asansör basamak anında y=%.1f (kutuda takılı ~550; inik 610), basamaktan ayak y min=%.1f (F2 yüzeyi %.0f; basamak üstü %.1f, gereken %.1f; ayrık zıplama tepesi ~100,9), F2'ye ÇIKTI: %s, bitti: %s, ölüm: %d" % [
			str(sk2["tamam"]), str(sb["tamam"]), as_ara, mb, B9_F2_Y, as_ara - 10.0, as_ara - 10.0 - B9_F2_Y, f2_b, sb["bitti"], sb["oldu"]])

	# c) Kutu F2'de, oyuncu sola iter: kutu F2 kenarından düşer, platforma (x 340..460, yüzey 530)
	# ulaşamaz, zeminde kalır; bölüm bitmez.
	var yer_c := func(b: Node) -> void:
		b.get_node("Oyuncu").global_position = Vector2(800.0, B9_F2_Y - 24.0)
		b.get_node("Kutu").global_position = Vector2(760.0, B9_F2_Y - 20.0)
	var sc: Dictionary = await _b9_senaryo([], [_b4_a(-1, _b4_x_le(450.0), 250), _b4_a(0, Callable(), 60)], yer_c)
	var kc: Vector2 = _b9_kutu_aralik(sc["ozel"], "x")
	var kson: Vector2 = _b9_kutu_son(sc)
	var platformda := false
	for o in sc["ozel"]:
		if o["kutu"].x <= 470.0 and o["kutu"].y < 560.0:
			platformda = true
	_kaydi("Bölüm 9 ölçüm: F2'deki kutu sola itilince kenardan düşer, platforma ulaşamaz",
		kson.y > 570.0 and kson.x > 470.0 and kc.x > 470.0 and not platformda and not sc["bitti"],
		"kutu x aralığı %.0f..%.0f, son kutu=(%.1f,%.1f) (F2'de kutu y %.0f, zemin 580, platform 340..460/y~510), platformda: %s, oyuncu ölümü: %d" % [
			kc.x, kc.y, kson.x, kson.y, B9_F2_Y - 20.0, platformda, sc["oldu"]])
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


## Örnekler içinde anahtarın ilk true olduğu kare (-1: hiç).
func _b9_ilk(ozel: Array, anahtar: String) -> int:
	for i in range(ozel.size()):
		if ozel[i][anahtar]:
			return i
	return -1


## Tarama sonucu: geçen değerlerin [en küçük, en büyük] aralığı ve sayısı.
func _b9_aralik(degerler: Array, gecen: Array) -> Dictionary:
	var lo := 1.0e9
	var hi := -1.0e9
	var n := 0
	for i in range(degerler.size()):
		if gecen[i]:
			lo = minf(lo, degerler[i])
			hi = maxf(hi, degerler[i])
			n += 1
	return {"lo": lo, "hi": hi, "n": n}


## 10) Ölçüm (2026-10-16, ayar): kritik pencere payları ve tur süreleri (kare). Her satırda
## ilgili tur yeniden kaydedilir, sonraki turlar betikle yeniden üretilir; sonuç "bitti" ile ölçülür.
## Eşikler: her kritik pencerede >= 8 kare pay, her tur <= 600 kare.
func _test_bolum9_pencereler() -> void:
	var kay: Array = await _b9_kayitlar()
	var k1: Array = kay[0]
	var k2: Array = kay[1]
	var k3: Array = kay[2]
	var ayr: Array = []
	var ok := true
	# a) k2 basma anı (Plaka2'nin ilk basıldığı kare): bekleme W taranır.
	var ws: Array = [0, 10, 20, 30, 40, 60, 80, 120]
	var w_gecen: Array = []
	var w_ayr: Array = []
	var bas_secili := -1
	for w in ws:
		var s2: Dictionary = await _b9_senaryo([k1], _b9_k2(w))
		var f: int = _b9_ilk(s2["ozel"], "p2")
		var s3: Dictionary = await _b9_senaryo([k1, s2["kayit"]], _b9_k3())
		var s4: Dictionary = await _b9_senaryo([k1, s2["kayit"], s3["kayit"]], _b9_oyuncu())
		w_gecen.append(s4["bitti"])
		w_ayr.append("W%d:bas%d:%s" % [w, f, "+" if s4["bitti"] else "-"])
		if w == B9_K2_BEKLE:
			bas_secili = f
	ayr.append("a) k2 basma (W:kare:bitti) " + " ".join(w_ayr))
	# b) k3 geç kalma payı (seçili k2 ile): k3 D kare geç çıkar.
	var ds: Array = [0, 10, 20, 30, 40, 50, 60, 80, 100, 120]
	var d_gecen: Array = []
	for d in ds:
		var s3: Dictionary = await _b9_senaryo([k1, k2], _b9_k3(620.0, d))
		var s4: Dictionary = await _b9_senaryo([k1, k2, s3["kayit"]], _b9_oyuncu())
		d_gecen.append(s4["bitti"])
	var d_ar: Dictionary = _b9_aralik(ds, d_gecen)
	ayr.append("b) k3 geç kalma: en çok %.0f kare (taranan %s, geçen %s)" % [d_ar["hi"], str(ds), str(d_gecen)])
	ok = ok and d_ar["lo"] == 0.0 and d_ar["hi"] >= 8.0
	# c) Oyuncu (tur 4) geç kalma payı.
	var o_gecen: Array = []
	for d in ds:
		var s4: Dictionary = await _b9_senaryo(kay, [_b4_a(0, Callable(), d)] + _b9_oyuncu())
		o_gecen.append(s4["bitti"])
	var o_ar: Dictionary = _b9_aralik(ds, o_gecen)
	ayr.append("c) oyuncu geç kalma: en çok %.0f kare (geçen %s)" % [o_ar["hi"], str(o_gecen)])
	ok = ok and o_ar["lo"] == 0.0 and o_ar["hi"] >= 8.0
	# d) k3'ün asansörde durduğu x (kutu önünde): durma aralığı.
	var xs: Array = [540.0, 560.0, 570.0, 580.0, 600.0, 620.0, 640.0, 645.0]   # 645: kutu Kat2 duvarına dayanana kadar sağ basılı (oyuncu ~648'de durur)
	var x_gecen: Array = []
	for x in xs:
		var s3: Dictionary = await _b9_senaryo([k1, k2], _b9_k3(x))
		var s4: Dictionary = await _b9_senaryo([k1, k2, s3["kayit"]], _b9_oyuncu())
		x_gecen.append(s4["bitti"])
	var x_ar: Dictionary = _b9_aralik(xs, x_gecen)
	ayr.append("d) k3 asansörde durma x: %.0f..%.0f (%.0f kare; geçen %s)" % [x_ar["lo"], x_ar["hi"], (x_ar["hi"] - x_ar["lo"]) / 5.0, str(x_gecen)])
	ok = ok and (x_ar["hi"] - x_ar["lo"]) / 5.0 >= 8.0
	# e) Tur 4: kutunun PlakaKutu'da bırakıldığı yer (kutu merkezi = itme_x + 34).
	var ks: Array = []
	for i in range(-7, 8):
		ks.append(B9_PK_X - 34.0 + i * 10.0)
	var k_gecen: Array = []
	for kx in ks:
		var s4: Dictionary = await _b9_senaryo(kay, _b9_oyuncu(kx))
		k_gecen.append(s4["bitti"])
	var k_ar: Dictionary = _b9_aralik(ks, k_gecen)
	ayr.append("e) kutu bırakma (kutu merkezi) %.0f..%.0f (%.0f kare; geçen %s)" % [k_ar["lo"] + 34.0, k_ar["hi"] + 34.0, (k_ar["hi"] - k_ar["lo"]) / 5.0, str(k_gecen)])
	ok = ok and (k_ar["hi"] - k_ar["lo"]) / 5.0 >= 8.0
	# f) Tur 4: kutunun üstünden geçiş, dikey zıplamadan sonra sağa basma karesi.
	var zs: Array = []
	for z in range(1, 41):
		zs.append(z)
	var z_gecen: Array = []
	for z in zs:
		var s4: Dictionary = await _b9_senaryo(kay, _b9_oyuncu(B9_PK_X - 34.0, z))
		z_gecen.append(s4["bitti"])
	var z_ar: Dictionary = _b9_aralik(zs, z_gecen)
	ayr.append("f) kutu üstünden geçiş: sağa basma karesi %.0f..%.0f (%d kare)" % [z_ar["lo"], z_ar["hi"], z_ar["n"]])
	ok = ok and z_ar["n"] >= 8
	# g) Tur süreleri (çözüm betiği).
	var t1: Dictionary = await _b9_senaryo([], _b9_k1())
	var t2: Dictionary = await _b9_senaryo([k1], _b9_k2())
	var t3: Dictionary = await _b9_senaryo([k1, k2], _b9_k3())
	var t4: Dictionary = await _b9_senaryo(kay, _b9_oyuncu())
	ayr.append("g) tur kareleri %d / %d / %d / %d (k2 basma karesi %d)" % [t1["kare"], t2["kare"], t3["kare"], t4["kare"], bas_secili])
	ok = ok and t4["bitti"] and maxi(maxi(t1["kare"], t2["kare"]), maxi(t3["kare"], t4["kare"])) <= 600
	_kaydi("Bölüm 9 ölçüm: kritik pencere payları (>= 8 kare) ve tur süreleri (<= 600 kare)", ok, "; ".join(ayr))
	_kayitlar().sifirla()


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

# ---------------------------------------------------------------- Aşağı düşme (asagi eylemi)
# Kullanıcı kararı (docs/kararlar.md): tek yönlü platformda `asagi` -> o karakter için 12 kare yok sayılır,
# sonra katı. Yalnızca tek yönlü platformda etkili. Kayıt {yon, zipla, asagi}; eski kayıtta asagi yok = false.
# Test sahnesi: tests/sahneler/asagi_test.tscn (zemin merkezi y=576, platform üstü merkezi y=506,
# kutu üstü 536, asansör üstü 526).

const ASAGI_TEST := "res://tests/sahneler/asagi_test.tscn"
const SD_PLATFORM_Y := 506.0
const SD_ZEMIN_Y := 576.0
const SD_BASMA := 10   # asagi darbesinin gönderildiği kare (karakter o zamana dek platformda oturmuştur)


func _asagi_testleri() -> void:
	aktif_bolum = ASAGI_TEST
	await _test_sd_duser()
	await _test_sd_basmadan_durur()
	await _test_sd_zemin_etkisiz()
	await _test_sd_kutu_asansor_etkisiz()
	await _test_sd_klon()
	await _test_sd_eski_kayit()
	await _test_sd_digerleri_etkilenmez()
	await _test_sd_tekrar_cikis()
	await _test_sd_determinizm()
	await _test_sd_duvar_duser()
	await _test_sd_duvar_zemin_etkisiz()
	await _test_sd_duvar_12_kare()
	await _test_sd_gercek_sahneler()
	aktif_bolum = ASAGI_TEST


## [[kare, yon, zipla, asagi], ...] -> girdi dizisi (zıplama yalnızca parçanın ilk karesinde).
func _sd_betik(parcalar: Array) -> Array:
	var cikti: Array = []
	for p in parcalar:
		for i in range(p[0]):
			cikti.append({"yon": float(p[1]), "zipla": bool(p[2]) and i == 0, "asagi": bool(p[3])})
	return cikti


func _sd_ornek(b: Node) -> Dictionary:
	var o: CharacterBody2D = b.get_node("Oyuncu")
	var d := {"o": o.global_position, "ist": o.get_collision_exceptions().size(),
		"k": b.get_node("Kutu").global_position, "k2": b.get_node("Kutu2").global_position,
		"a": b.get_node("Asansor").global_position, "klon": Vector2.ZERO, "kist": 0}
	var kl: Array = _klonlar(b)
	if kl.size() > 0:
		d["klon"] = kl[0].global_position
		d["kist"] = kl[0].get_collision_exceptions().size()
	return d


## Düğümleri yerleştirir; "Klon" anahtarı ilk klonu taşır. Oyuncu düğümü tutucuya eklenir.
func _sd_yerlestir(konumlar: Dictionary, tutucu: Array) -> Callable:
	return func(b: Node) -> void:
		tutucu.append(b.get_node("Oyuncu"))
		for ad in konumlar:
			if ad == "Klon":
				_klonlar(b)[0].global_position = konumlar[ad]
			else:
				b.get_node(ad).global_position = konumlar[ad]


func _sd_calistir(kayitlar: Array, betik: Array, n: int, yer: Dictionary, tutucu := []) -> Dictionary:
	return await _lazer_senaryo(kayitlar, betik, n, _sd_yerlestir(yer, tutucu), _sd_ornek)


## Verilen anahtarın y değerinin hedeften en büyük mutlak sapması, [bas, son) aralığında.
func _sd_y_sapma(iz: Array, anahtar: String, hedef: float, bas: int, son := -1) -> float:
	var m := 0.0
	var s := iz.size() if son < 0 else mini(son, iz.size())
	for i in range(bas, s):
		m = maxf(m, absf(iz[i][anahtar].y - hedef))
	return m


## y değerinin eşiği ilk aştığı kare (y > esik), yoksa -1.
func _sd_ilk_y_ustu(iz: Array, anahtar: String, esik: float, bas := 0) -> int:
	for i in range(bas, iz.size()):
		if iz[i][anahtar].y > esik:
			return i
	return -1


func _sd_ist_kare(iz: Array, anahtar := "ist") -> int:
	var n := 0
	for d in iz:
		if d[anahtar] > 0:
			n += 1
	return n


func _sd_fark(a: Array, b: Array, anahtarlar: Array) -> float:
	var m := 0.0
	if a.size() != b.size():
		return 1.0e9
	for i in range(a.size()):
		for k in anahtarlar:
			m = maxf(m, (a[i][k] - b[i][k]).length())
	return m


## 1) Oyuncu platformda `asagi` ile alttaki zemine düşer.
func _test_sd_duser() -> void:
	var betik := _sd_betik([[SD_BASMA, 0, false, false], [1, 0, false, true], [89, 0, false, false]])
	var s: Dictionary = await _sd_calistir([], betik, 100, {"Oyuncu": Vector2(200, 500)})
	var iz: Array = s["ozel_iz"]
	var oturdu: float = _sd_y_sapma(iz, "o", SD_PLATFORM_Y, 6, SD_BASMA + 1)
	var dusus := _sd_ilk_y_ustu(iz, "o", SD_PLATFORM_Y + 1.0)
	var inis := _sd_ilk_y_ustu(iz, "o", SD_ZEMIN_Y - 0.5)
	var son_sap: float = _sd_y_sapma(iz, "o", SD_ZEMIN_Y, maxi(inis, 0) + 1)
	var yatay := 0.0
	for d in iz:
		yatay = maxf(yatay, absf(d["o"].x - 200.0))
	var ist := _sd_ist_kare(iz)
	var ok: bool = s["tamamlandi"] and oturdu < 0.5 and dusus > SD_BASMA and dusus <= SD_BASMA + 3 \
		and inis > dusus and son_sap < 0.5 and yatay < 0.5 and ist >= 11 and ist <= 13
	_kaydi("Aşağı düşme 1) Platformda asagi ile alttaki zemine düşer", ok,
		"platformda y=%.1f (beklenen 506, sapma %.2f), basma karesi %d, düşüş başladı kare %d, zemine indi kare %d (düşüş süresi %d kare), son y sapma %.2f (zemin 576), yatay sapma %.2f px, platform yok sayılan kare sayısı %d (beklenen 12)" % [
			iz[SD_BASMA - 1]["o"].y, oturdu, SD_BASMA, dusus, inis, inis - dusus, son_sap, yatay, ist])


## 2) asagi basmadan düşmez.
func _test_sd_basmadan_durur() -> void:
	var s: Dictionary = await _sd_calistir([], _sd_betik([[100, 0, false, false]]), 100, {"Oyuncu": Vector2(200, 500)})
	var iz: Array = s["ozel_iz"]
	var sap: float = _sd_y_sapma(iz, "o", SD_PLATFORM_Y, 6)
	_kaydi("Aşağı düşme 2) asagi basmadan platformda kalır", s["tamamlandi"] and sap < 0.5 and _sd_ist_kare(iz) == 0,
		"kare 6..99 en büyük y sapması %.3f px (beklenen < 0.5), yok sayma kare sayısı %d (beklenen 0)" % [sap, _sd_ist_kare(iz)])


## 3) Normal zeminde asagi etkisiz: y değişmez, hareket asagi basılı olmayan kontrolle birebir aynı.
func _test_sd_zemin_etkisiz() -> void:
	var yer := {"Oyuncu": Vector2(300, 576)}
	var asagili := _sd_betik([[20, 1, false, true], [20, 0, false, true]])
	var kontrol := _sd_betik([[20, 1, false, false], [20, 0, false, false]])
	var s: Dictionary = await _sd_calistir([], asagili, 40, yer)
	var c: Dictionary = await _sd_calistir([], kontrol, 40, yer)
	var iz: Array = s["ozel_iz"]
	var sap: float = _sd_y_sapma(iz, "o", SD_ZEMIN_Y, 0)
	var fark: float = _sd_fark(iz, c["ozel_iz"], ["o"])
	var yol: float = iz[iz.size() - 1]["o"].x - 300.0
	_kaydi("Aşağı düşme 3) Normal zeminde asagi etkisiz (y değişmez, takılma yok)",
		s["tamamlandi"] and sap < 0.5 and fark == 0.0 and _sd_ist_kare(iz) == 0 and absf(yol - 100.0) < 1.5,
		"y sapma %.4f px, asagi'lı ile asagi'sız kontrol arası en büyük fark %.4f, 20 karede alınan yol %.1f px (beklenen ~100), yok sayma kare sayısı %d" % [
			sap, fark, yol, _sd_ist_kare(iz)])


## 4) Kutu üstünde ve asansör üstünde etkisiz.
func _test_sd_kutu_asansor_etkisiz() -> void:
	var betik := _sd_betik([[20, 0, false, false], [60, 0, false, true]])
	# Kutu: üst yüzey 560 -> merkez 536.
	var s: Dictionary = await _sd_calistir([], betik, 80, {"Oyuncu": Vector2(800, 520)})
	var iz: Array = s["ozel_iz"]
	var k_sap: float = _sd_y_sapma(iz, "o", 536.0, 12)
	var kutu_sap: float = _sd_y_sapma(iz, "k", 580.0, 0)
	var k_ok: bool = s["tamamlandi"] and k_sap < 0.5 and kutu_sap < 0.5 and _sd_ist_kare(iz) == 0
	_kaydi("Aşağı düşme 4a) Kutu üstünde asagi etkisiz", k_ok,
		"oyuncu y sapma %.3f (beklenen merkez 536), kutu y sapma %.3f, yok sayma kare sayısı %d (beklenen 0)" % [
			k_sap, kutu_sap, _sd_ist_kare(iz)])
	# Asansör (hareketsiz, plaka basılmaz): üst yüzey 550 -> merkez 526.
	s = await _sd_calistir([], betik, 80, {"Oyuncu": Vector2(1000, 515)})
	iz = s["ozel_iz"]
	var a_sap: float = _sd_y_sapma(iz, "o", 526.0, 12)
	var as_sap: float = _sd_y_sapma(iz, "a", 560.0, 0)
	_kaydi("Aşağı düşme 4b) Asansör üstünde asagi etkisiz", s["tamamlandi"] and a_sap < 0.5 and as_sap < 0.5 and _sd_ist_kare(iz) == 0,
		"oyuncu y sapma %.3f (beklenen merkez 526), asansör y sapma %.3f, yok sayma kare sayısı %d (beklenen 0)" % [
			a_sap, as_sap, _sd_ist_kare(iz)])


## 5) Klon kayıttan asagi ile aynı karede aynı şekilde düşer (kayıt alanı klavye yoluyla yazılır).
func _test_sd_klon() -> void:
	var betik := _sd_betik([[SD_BASMA, 0, false, false], [1, 0, false, true], [89, 0, false, false]])
	var tut := []
	var canli: Dictionary = await _sd_calistir([], betik, 100, {"Oyuncu": Vector2(200, 500)}, tut)
	var kayit: Array = tut[0].kayit_girdileri.duplicate(true)
	var asagi_n := 0
	var alan_var := true
	for g in kayit:
		alan_var = alan_var and g.has("asagi")
		if g.get("asagi", false):
			asagi_n += 1
	var kayit_ok: bool = kayit.size() == 100 and alan_var and asagi_n == 1 and kayit[SD_BASMA].get("asagi", false)
	var klon: Dictionary = await _sd_calistir([kayit], [], 100, {"Oyuncu": Vector2(60, 576), "Klon": Vector2(200, 500)})
	var cz: Array = canli["ozel_iz"]
	var kz: Array = klon["ozel_iz"]
	var maks := 0.0
	for i in range(mini(cz.size(), kz.size())):
		maks = maxf(maks, (cz[i]["o"] - kz[i]["klon"]).length())
	var c_dus := _sd_ilk_y_ustu(cz, "o", SD_PLATFORM_Y + 1.0)
	var k_dus := _sd_ilk_y_ustu(kz, "klon", SD_PLATFORM_Y + 1.0)
	var k_ist := _sd_ist_kare(kz, "kist")
	var son: Vector2 = kz[kz.size() - 1]["klon"]
	_kaydi("Aşağı düşme 5) Klon kayıttan aynı karede aynı şekilde düşer",
		kayit_ok and cz.size() == 100 and kz.size() == 100 and maks == 0.0 and c_dus == k_dus and c_dus > 0 \
			and absf(son.y - SD_ZEMIN_Y) < 0.5 and k_ist >= 11 and k_ist <= 13,
		"kayıt: %d kare, asagi=true %d kare (kare %d), tüm karelerde asagi alanı: %s; canlı düşüş karesi %d, klon düşüş karesi %d, canlı-klon en büyük fark %.4f px, klon son y=%.1f, klonun yok saydığı kare %d" % [
			kayit.size(), asagi_n, SD_BASMA, alan_var, c_dus, k_dus, maks, son.y, k_ist])


## 6) Eski kayıt formatı ({yon, zipla}) hata vermeden oynar, asagi = false.
func _test_sd_eski_kayit() -> void:
	var eski: Array = _betik([[10, 0, false], [30, 1, false], [1, 0, true], [60, 0, false]])
	var yeni: Array = []
	var alan_yok := true
	for g in eski:
		alan_yok = alan_yok and not g.has("asagi")
		var h: Dictionary = g.duplicate()
		h["asagi"] = false
		yeni.append(h)
	# Klon platform A üstünde başlar, sağa yürür, zıplar: eski ve yeni biçim birebir aynı olmalı.
	var yer := {"Oyuncu": Vector2(60, 576), "Klon": Vector2(160, 500)}
	var e: Dictionary = await _sd_calistir([eski], [], 101, yer)
	var y: Dictionary = await _sd_calistir([yeni], [], 101, yer)
	var fark: float = _sd_fark(e["ozel_iz"], y["ozel_iz"], ["klon"])
	var iz: Array = e["ozel_iz"]
	var hareket: float = iz[iz.size() - 1]["klon"].x - 160.0
	# Eski biçimli durağan kayıt platformda düşmez.
	var d: Dictionary = await _sd_calistir([_betik([[80, 0, false]])], [], 80, {"Klon": Vector2(200, 500)})
	var dsap: float = _sd_y_sapma(d["ozel_iz"], "klon", SD_PLATFORM_Y, 6)
	_kaydi("Aşağı düşme 6) Eski kayıt formatı hata vermeden oynar (asagi = false)",
		alan_yok and e["tamamlandi"] and y["tamamlandi"] and fark == 0.0 and absf(hareket) > 50.0 and dsap < 0.5 \
			and _sd_ist_kare(d["ozel_iz"], "kist") == 0,
		"kayıtta asagi alanı yok: %s, eski/yeni biçim en büyük fark %.4f px, klon x yolu %.1f px, durağan eski kayıt platformda y sapma %.3f (düşmedi)" % [
			alan_yok, fark, hareket, dsap])


## 7) Düşen karakterin ardından başka karakter ve kutu platformda kalır (istisna yalnızca basan karakter için).
func _test_sd_digerleri_etkilenmez() -> void:
	var klon_kaydi: Array = _sd_betik([[70, 0, false, false]])
	var betik := _sd_betik([[6, 0, false, false], [1, 0, false, true], [63, 0, false, false]])
	# Oyuncu ve klon platform A'da (x 150 / 250, kutudan ayrık), kutu havadan platforma iner.
	var yer := {"Oyuncu": Vector2(150, 500), "Klon": Vector2(250, 500), "Kutu2": Vector2(200, 470)}
	var s: Dictionary = await _sd_calistir([klon_kaydi], betik, 70, yer)
	var iz: Array = s["ozel_iz"]
	var dusus := _sd_ilk_y_ustu(iz, "o", SD_PLATFORM_Y + 1.0)
	var o_son: float = iz[iz.size() - 1]["o"].y
	var klon_sap: float = _sd_y_sapma(iz, "klon", SD_PLATFORM_Y, 6)
	var kutu_inis := -1
	for i in range(iz.size()):
		if iz[i]["k2"].y > 509.0:
			kutu_inis = i
			break
	var kutu_max := 0.0
	for i in range(maxi(kutu_inis, 0), iz.size()):
		kutu_max = maxf(kutu_max, iz[i]["k2"].y)
	var kutu_son: float = iz[iz.size() - 1]["k2"].y
	var ist := _sd_ist_kare(iz)
	var ok: bool = s["tamamlandi"] and dusus > 0 and absf(o_son - SD_ZEMIN_Y) < 0.5 and klon_sap < 0.5 \
		and _sd_ist_kare(iz, "kist") == 0 and kutu_inis > 0 and kutu_inis < dusus + 14 and kutu_max < 511.0 \
		and absf(kutu_son - 510.0) < 0.5 and ist >= 11 and ist <= 13
	_kaydi("Aşağı düşme 7) Düşen karakterden sonra başka karakter/kutu platformda durur", ok,
		"oyuncu kare %d'te düştü, son y=%.1f (zemin); klon platformda y sapma %.3f, klonun yok saydığı kare %d (beklenen 0); kutu kare %d'te platforma indi, en çok y=%.2f, son y=%.2f (beklenen 510); oyuncu yok sayma kare sayısı %d (12 kare sonra platform yeniden katı)" % [
			dusus, o_son, klon_sap, _sd_ist_kare(iz, "kist"), kutu_inis, kutu_max, kutu_son, ist])


## 8) Zıplayarak altından geçme bozulmadı; düştükten sonra platforma tek yönlü kuralıyla çıkılır.
func _test_sd_tekrar_cikis() -> void:
	# a) asagi darbesi, zemine iniş, altından zıplayıp platformun üstüne çıkma (platform yeniden katı olmalı).
	var betik := _sd_betik([[6, 0, false, false], [1, 0, false, true], [44, 0, false, false], [1, 0, true, false], [100, 0, false, false]])
	var s: Dictionary = await _sd_calistir([], betik, betik.size(), {"Oyuncu": Vector2(500, 500)})
	var iz: Array = s["ozel_iz"]
	var yerde: float = iz[50]["o"].y
	var min_y := 1.0e9
	for i in range(51, iz.size()):
		min_y = minf(min_y, iz[i]["o"].y)
	var son_sap: float = _sd_y_sapma(iz, "o", SD_PLATFORM_Y, iz.size() - 30)
	_kaydi("Aşağı düşme 8a) Düştükten sonra altından zıplayıp platforma çıkılır",
		s["tamamlandi"] and absf(yerde - SD_ZEMIN_Y) < 0.5 and min_y < 500.0 and son_sap < 0.5,
		"zıplamadan önce y=%.1f (zemin), zıplamadaki en yüksek y=%.1f (<500: platformun altından geçti), son 30 karede platform üstünden sapma %.3f (kararlı)" % [
			yerde, min_y, son_sap])
	# b) asagi sürekli basılıyken zıpla: yukarı geçiş engellenmez; üstte duruşta tekrar düşer, sıkışma/tünel yok.
	var betik_b := _sd_betik([[6, 0, false, false], [45, 0, false, true], [1, 0, true, true], [100, 0, false, true]])
	var sb: Dictionary = await _sd_calistir([], betik_b, betik_b.size(), {"Oyuncu": Vector2(500, 500)})
	var izb: Array = sb["ozel_iz"]
	var min_b := 1.0e9
	var maks_b := -1.0e9
	for i in range(51, izb.size()):
		min_b = minf(min_b, izb[i]["o"].y)
		maks_b = maxf(maks_b, izb[i]["o"].y)
	var son_b: float = izb[izb.size() - 1]["o"].y
	_kaydi("Aşağı düşme 8b) asagi basılıyken altından zıplayıp geçme engellenmez, sıkışma yok",
		sb["tamamlandi"] and min_b < 500.0 and maks_b < SD_ZEMIN_Y + 0.5 and absf(son_b - SD_ZEMIN_Y) < 0.5,
		"zıplamada en yüksek y=%.1f (<500), en alçak y=%.1f (zemin 576, altına inmedi), son y=%.1f (üstte tekrar düşüp zemine indi)" % [
			min_b, maks_b, son_b])


## 9) Determinizm 100x: S içeren kayıt (klon + kutu), her karede birebir aynı.
func _test_sd_determinizm() -> void:
	var betik := _sd_betik([[6, 0, false, false], [1, 0, false, true], [40, 0, false, false], [1, 0, true, false],
		[50, 0, false, false], [30, 1, false, true], [20, 0, false, true], [1, 0, true, true], [30, 0, false, false]])
	var tut := []
	await _sd_calistir([], betik, betik.size(), {"Oyuncu": Vector2(150, 500)}, tut)
	var kayit: Array = tut[0].kayit_girdileri.duplicate(true)
	var yer := {"Oyuncu": Vector2(60, 576), "Klon": Vector2(150, 500), "Kutu2": Vector2(200, 470)}
	var ref: Array = []
	var sapmali := 0
	var maks_sapma := 0.0
	for r in range(TEKRAR):
		var s: Dictionary = await _sd_calistir([kayit], [], betik.size(), yer)
		var iz: Array = s["ozel_iz"]
		if r == 0:
			ref = iz
			continue
		var f := _sd_fark(iz, ref, ["klon", "k2", "o"])
		if f != 0.0:
			sapmali += 1
			maks_sapma = maxf(maks_sapma, f)
	var inen: bool = ref.size() == betik.size() and _sd_ilk_y_ustu(ref, "klon", SD_PLATFORM_Y + 1.0) > 0
	_kaydi("Aşağı düşme 9) Determinizm (S içeren kayıt, %dx)" % TEKRAR, sapmali == 0 and inen,
		"%d çalıştırma, %d kare, sapmalı: %d, en büyük sapma %.4f px, klon düştü: %s" % [TEKRAR, ref.size(), sapmali, maks_sapma, inen])


# ---------------------------------------------------------------- ipucu ikonu
# Karar (docs/kararlar.md, 2026-10-15): ipucu_klon 0 ise ikon yok; Bölüm 4 = 2, Bölüm 6 = 1.
# İkon yalnızca HUD'dur: "?" ikonu (IpucuIkonu), hover'da altında "N klonla çözülebilir".

const IPUCU_BOLUM_4 := "res://scenes/bolumler/bolum_4.tscn"
const IPUCU_BOLUM_6 := "res://scenes/bolumler/bolum_6.tscn"


## Bölümün ipucu düğümlerini bulur (yoksa null).
func _ip_dugum(bolum: Node, ad: String) -> Control:
	return bolum.find_child(ad, true, false) as Control


func _ipucu_testleri() -> void:
	var beklenen := {IPUCU_BOLUM_4: 2, IPUCU_BOLUM_6: 1}
	var viewport_alan := Rect2(Vector2.ZERO, Vector2(
		ProjectSettings.get_setting("display/window/size/viewport_width", 1152),
		ProjectSettings.get_setting("display/window/size/viewport_height", 648)))
	# 1-3) Bölüm 4 ve 6: ikon var/görünür, metin gizli; hover aç/kapa; konum.
	for yol in beklenen:
		var n: int = beklenen[yol]
		var ad: String = yol.get_file().get_basename()
		aktif_bolum = yol
		_kayitlar().sifirla()
		var bolum: Node = await _bolumu_yukle()
		await physics_frame
		var ikon := _ip_dugum(bolum, "IpucuIkonu")
		var metin := _ip_dugum(bolum, "IpucuMetni")
		var var_mi: bool = ikon != null and metin != null
		_kaydi("İpucu %s 1) ikon düğümü var ve görünür, metin başta gizli" % ad,
			var_mi and ikon.is_visible_in_tree() and not metin.visible
			and int(bolum.get("ipucu_klon")) == n,
			"ikon: %s, görünür: %s, metin görünür: %s, ipucu_klon: %s" % [
				ikon != null, ikon != null and ikon.is_visible_in_tree(),
				metin != null and metin.visible, str(bolum.get("ipucu_klon"))])
		if not var_mi:
			continue
		ikon.mouse_entered.emit()
		await physics_frame
		var acik_gorunur: bool = metin.visible and metin.is_visible_in_tree()
		var tam_metin: bool = metin.text == "%d klonla çözülebilir" % n
		ikon.mouse_exited.emit()
		await physics_frame
		var kapali: bool = not metin.visible
		_kaydi("İpucu %s 2) mouse_entered metni gösterir (\"%d klonla çözülebilir\"), mouse_exited gizler" % [ad, n],
			acik_gorunur and tam_metin and kapali,
			"hover'da görünür: %s, metin: \"%s\", çıkınca gizli: %s" % [acik_gorunur, metin.text, kapali])
		ikon.mouse_entered.emit()
		await physics_frame
		var ir := ikon.get_global_rect()
		var mr := metin.get_global_rect()
		var asagida: bool = mr.position.y >= ir.end.y
		var hizali: bool = mr.position.x < ir.end.x and mr.end.x > ir.position.x
		var ekranda: bool = viewport_alan.encloses(ir) and viewport_alan.encloses(mr)
		_kaydi("İpucu %s 3) metin ikonun hemen altında, ekran içinde" % ad,
			asagida and hizali and ekranda and mr.position.y - ir.end.y <= 40.0,
			"ikon %s, metin %s, boşluk %.0f px, hizalı: %s, ekranda: %s" % [
				str(ir), str(mr), mr.position.y - ir.end.y, hizali, ekranda])
		ikon.mouse_exited.emit()
	# 4) Tüm listedeki bölümler: yalnız 4 ve 6'da ikon, ipucu_klon değerleri.
	var sorunlar := ""
	var sayi := 0
	for kayit in BolumListesi.liste():
		var yol: String = kayit["yol"]
		aktif_bolum = yol
		_kayitlar().sifirla()
		var b: Node = await _bolumu_yukle()
		await physics_frame
		sayi += 1
		var deger := int(b.get("ipucu_klon"))
		var bek: int = beklenen.get(yol, 0)
		var ikon_var := _ip_dugum(b, "IpucuIkonu") != null
		var metin_var := _ip_dugum(b, "IpucuMetni") != null
		if deger != bek or ikon_var != (bek > 0) or metin_var != (bek > 0):
			sorunlar += " %s(ipucu_klon=%d, ikon=%s, metin=%s)" % [yol.get_file(), deger, ikon_var, metin_var]
	_kaydi("İpucu 4) yalnız Bölüm 4 ve 6'da ikon var (Bölüm 18 ikonu kaldırıldı), diğer tüm bölümlerde yok", sorunlar == "" and sayi >= 12,
		"%d bölüm tarandı, sorunlar:%s" % [sayi, sorunlar if sorunlar != "" else " yok"])
	# 5) max_klon değerleri değişmedi.
	var mk := {}
	for yol in beklenen:
		aktif_bolum = yol
		_kayitlar().sifirla()
		var b2: Node = await _bolumu_yukle()
		mk[yol] = int(b2.get("max_klon"))
	_kaydi("İpucu 5) Bölüm 4 max_klon 3, Bölüm 6 max_klon 2", mk[IPUCU_BOLUM_4] == 3 and mk[IPUCU_BOLUM_6] == 2,
		"Bölüm 4: %d, Bölüm 6: %d" % [mk[IPUCU_BOLUM_4], mk[IPUCU_BOLUM_6]])
	# 6a) İkona hover iken girdi çalışır, oyuncu normal hareket eder; mouse_filter yalnız ikonda STOP.
	aktif_bolum = IPUCU_BOLUM_4
	var betik := _betik([[60, 1, false]])
	var hover := func(b: Node) -> void: _ip_dugum(b, "IpucuIkonu").mouse_entered.emit()
	var s_hover: Dictionary = await _senaryo([], betik, 60, hover)
	var s_yok: Dictionary = await _senaryo([], betik, 60)
	_kayitlar().sifirla()
	var bolum_f: Node = await _bolumu_yukle()
	var stop_sayisi := 0
	var katman: Node = bolum_f.find_child("IpucuKatmani", true, false)
	for c in katman.get_children():
		if c is Control and c.mouse_filter == Control.MOUSE_FILTER_STOP:
			stop_sayisi += 1
	var ikon_stop: bool = _ip_dugum(bolum_f, "IpucuIkonu").mouse_filter == Control.MOUSE_FILTER_STOP
	var metin_gecer: bool = _ip_dugum(bolum_f, "IpucuMetni").mouse_filter == Control.MOUSE_FILTER_IGNORE
	var dx: float = s_hover["oyuncu_konum"].x - s_yok["oyuncu_konum"].x
	
	_kaydi("İpucu 6a) hover iken Input eylemleri çalışır, ikon girdiyi yutmaz",
		dx == 0.0 and s_hover["oyuncu_iz"].size() > 0
		and s_hover["oyuncu_iz"][-1].x > s_hover["oyuncu_iz"][0].x + 20.0
		and ikon_stop and metin_gecer and stop_sayisi == 1,
		"hover/yok x farkı: %.4f, hareket: %.0f px, ikon STOP: %s, metin IGNORE: %s, STOP düğüm sayısı: %d (beklenen 1)" % [
			dx, s_hover["oyuncu_iz"][-1].x - s_hover["oyuncu_iz"][0].x, ikon_stop, metin_gecer, stop_sayisi])
	# 6b) Determinizm: ikonlu bölümde 100x aynı sonuç (tek klon, hover dönüşümlü).
	for yol in beklenen:
		aktif_bolum = yol
		var kayit: Array = await _kaydet(_betik([[5, 0, false], [25, 1, false], [1, 1, true],
			[40, 1, false], [10, -1, false], [20, 0, false], [30, 1, false]]))
		var ref: Array = []
		var sapmali := 0
		var maks := 0.0
		for r in range(TEKRAR):
			var h := Callable()
			if r % 2 == 1:
				h = hover
			var s: Dictionary = await _senaryo([kayit], [], KLON_KARE, h)
			var iz: Array = s["klon_izleri"][0]
			if r == 0:
				ref = iz
				continue
			var bu := iz.size() != ref.size()
			for f in range(min(iz.size(), ref.size())):
				var d: float = (iz[f] - ref[f]).length()
				if d > 0.0:
					bu = true
					maks = maxf(maks, d)
			if bu:
				sapmali += 1
		var hareketli: bool = ref.size() > 0 and (ref[-1] - ref[0]).length() > 20.0
		_kaydi("İpucu 6b) Determinizm %s (%dx, ikon/hover açık)" % [yol.get_file().get_basename(), TEKRAR],
			sapmali == 0 and hareketli,
			"%d kare, sapmalı çalıştırma: %d, en büyük sapma %.4f px, klon hareket etti: %s" % [
				ref.size(), sapmali, maks, hareketli])
	_kayitlar().sifirla()


# ---- Regresyon: duvara yaslıyken asagi (alt yoklama düzeltmesi)
# Sahnede platform B (x 440..560) iki yanında duvar (sol yüzü x=440, sağ yüzü x=560).

const SD_DUVAR_X := 454.0   # B üstünde sol duvara yaslı karakter merkezi (440 + 14)


## Duvara 30 kare yaslan (yon), sonra 1 kare asagi (yon ile), sonra 60 kare (yon) bekle.
func _sd_duvar_betik(yon: float, bekle_yon := -2.0) -> Array:
	var by: float = yon if bekle_yon < -1.5 else bekle_yon
	return _sd_betik([[30, yon, false, false], [1, yon, false, true], [60, by, false, false]])


## 1) Duvara yaslı karakter 1 kare asagi ile platformdan düşer (duvara doğru, duvarsız yön, yönsüz); oyuncu ve klon.
func _test_sd_duvar_duser() -> void:
	var ozet: Array = []
	var ok := true
	for yon in [-1.0, 0.0, 1.0]:
		var betik := _sd_duvar_betik(yon, 0.0 if yon > 0.0 else -2.0)
		var tut := []
		var s: Dictionary = await _sd_calistir([], betik, betik.size(), {"Oyuncu": Vector2(SD_DUVAR_X, 500)}, tut)
		var iz: Array = s["ozel_iz"]
		var kayit: Array = tut[0].kayit_girdileri.duplicate(true)
		var y_once: float = iz[29]["o"].y
		var son: Vector2 = iz[iz.size() - 1]["o"]
		var o_ok: bool = s["tamamlandi"] and absf(y_once - SD_PLATFORM_Y) < 0.5 and absf(son.y - SD_ZEMIN_Y) < 0.5
		var k: Dictionary = await _sd_calistir([kayit], [], betik.size(), {"Oyuncu": Vector2(60, 576), "Klon": Vector2(SD_DUVAR_X, 500)})
		var kz: Array = k["ozel_iz"]
		var kson: Vector2 = kz[kz.size() - 1]["klon"]
		var fark := 0.0
		for i in range(mini(iz.size(), kz.size())):
			fark = maxf(fark, (iz[i]["o"] - kz[i]["klon"]).length())
		var k_ok: bool = k["tamamlandi"] and absf(kson.y - SD_ZEMIN_Y) < 0.5 and fark == 0.0
		ok = ok and o_ok and k_ok
		ozet.append("yon %d: oyuncu 29. kare y=%.1f -> son y=%.1f, klon son y=%.1f (canlı-klon fark %.3f)" % [int(yon), y_once, son.y, kson.y, fark])
	_kaydi("Aşağı düşme 10) Duvara yaslı karakter asagi ile platformdan düşer (oyuncu ve klon)", ok, "; ".join(ozet))


## 2) Platform yokken duvar dibinde/zeminde asagi etkisiz (takılma, düşme, yok sayma yok).
func _test_sd_duvar_zemin_etkisiz() -> void:
	# Zeminde sol duvarın (x 420..440) dibinde: 406 = 420 - 14.
	var betik := _sd_betik([[30, 1, false, false], [40, 1, false, true]])
	var s: Dictionary = await _sd_calistir([], betik, betik.size(), {"Oyuncu": Vector2(380, 576)})
	var iz: Array = s["ozel_iz"]
	var sap: float = _sd_y_sapma(iz, "o", SD_ZEMIN_Y, 0)
	var son_x: float = iz[iz.size() - 1]["o"].x
	var ok: bool = s["tamamlandi"] and sap < 0.5 and _sd_ist_kare(iz) == 0 and absf(son_x - 406.0) < 1.5
	# Aynı yürüyüş asagi'sız: aynı konum.
	var c: Dictionary = await _sd_calistir([], _sd_betik([[70, 1, false, false]]), 70, {"Oyuncu": Vector2(380, 576)})
	var fark: float = _sd_fark(s["ozel_iz"], c["ozel_iz"], ["o"])
	_kaydi("Aşağı düşme 11) Platform yokken duvar dibinde/zeminde asagi etkisiz", ok and fark == 0.0,
		"zemin duvar dibi: y sapma %.3f, x=%.1f (beklenen 406), yok sayma kare %d, asagi'sız kontrolle fark %.4f" % [
			sap, son_x, _sd_ist_kare(iz), fark])


## 3) Duvar dibinde asagi sonrası 12 kare yok sayma, ardından platform yeniden katı (altından zıplayıp çıkılır).
func _test_sd_duvar_12_kare() -> void:
	var betik := _sd_betik([[30, -1, false, false], [1, -1, false, true], [40, -1, false, false], [1, 0, true, false], [100, 0, false, false]])
	var s: Dictionary = await _sd_calistir([], betik, betik.size(), {"Oyuncu": Vector2(SD_DUVAR_X, 500)})
	var iz: Array = s["ozel_iz"]
	var ist := _sd_ist_kare(iz)
	var yerde: float = iz[70]["o"].y
	var son_sap: float = _sd_y_sapma(iz, "o", SD_PLATFORM_Y, iz.size() - 30)
	var son_ist: int = iz[iz.size() - 1]["ist"]
	_kaydi("Aşağı düşme 12) Duvar dibinde asagi: 12 kare yok sayma, sonra yeniden katı",
		s["tamamlandi"] and ist >= 11 and ist <= 13 and absf(yerde - SD_ZEMIN_Y) < 0.5 and son_sap < 0.5 and son_ist == 0,
		"yok sayma kare sayısı %d (beklenen 12), zıplamadan önce y=%.1f (zemin), son 30 karede platform üstünden sapma %.3f, sonda yok sayma %d" % [
			ist, yerde, son_sap, son_ist])


## 4) Gerçek sahneler: platformun sol kenarında duvara yaslı karakter asagi ile düşer (oyuncu ve klon).
func _sd_gercek(sahne: String, platform_ust_merkez: Vector2, ad: String, min_dusus: float, bekle := 25) -> void:
	var onceki := aktif_bolum
	aktif_bolum = sahne
	var betik := _sd_betik([[30, -1, false, false], [1, -1, false, true], [bekle, -1, false, false]])
	var izle := func(b: Node) -> Dictionary:
		return {"o": b.get_node("Oyuncu").global_position, "ist": b.get_node("Oyuncu").get_collision_exceptions().size(),
			"klon": (_klonlar(b)[0].global_position if _klonlar(b).size() > 0 else Vector2.ZERO)}
	var tut := []
	var yer := func(b: Node) -> void:
		tut.append(b.get_node("Oyuncu"))
		b.get_node("Oyuncu").global_position = platform_ust_merkez
	var s: Dictionary = await _lazer_senaryo([], betik, betik.size(), yer, izle)
	var iz: Array = s["ozel_iz"]
	var kayit: Array = tut[0].kayit_girdileri.duplicate(true) if is_instance_valid(tut[0]) else []
	var y_once: float = iz[29]["o"].y
	var y_son: float = iz[iz.size() - 1]["o"].y
	var ist := _sd_ist_kare(iz)
	var o_ok: bool = s["oyuncu_oldu"] == 0 and y_son - y_once > min_dusus and ist >= 11 and ist <= 13
	# Klon: aynı kayıt, aynı konum.
	var yer_k := func(b: Node) -> void:
		_klonlar(b)[0].global_position = platform_ust_merkez
		b.get_node("Oyuncu").global_position = platform_ust_merkez
	var k: Dictionary = await _lazer_senaryo([kayit], [], betik.size(), yer_k, izle)
	var kz: Array = k["ozel_iz"]
	var kk_ok: bool = kz.size() > 0 and kz[kz.size() - 1]["klon"].y - kz[29]["klon"].y > min_dusus
	aktif_bolum = onceki
	_kaydi("Aşağı düşme 13) Gerçek sahne: %s duvara yaslıyken asagi düşürür" % ad, o_ok and kk_ok and kayit.size() == betik.size(),
		"oyuncu y %.1f -> %.1f (en az %.0f px düşmeli), yok sayma %d kare; klon y %.1f -> %.1f, oyuncu ölümü %d" % [
			y_once, y_son, min_dusus, ist, kz[29]["klon"].y if kz.size() > 29 else -1.0,
			kz[kz.size() - 1]["klon"].y if kz.size() > 0 else -1.0, s["oyuncu_oldu"]])


func _test_sd_gercek_sahneler() -> void:
	# Bölüm 12 Raf2 (merkez 540,296; üst 290): x=494 kovuk duvarına yakın. Merkez y = 290 - 24 - 1.
	await _sd_gercek(BOLUM_12, Vector2(494, 265), "Bölüm 12 Raf2 x=494", 40.0)
	# Bölüm 8 Basamak2 (merkez 760,266; üst 260): x=714.
	await _sd_gercek(BOLUM_8, Vector2(714, 235), "Bölüm 8 Basamak2 x=714", 40.0, 45)


# ---------------------------------------------------------------- Bölüm 13 (Kuyu)
# Taslak: docs/devir/bolum_13_taslak.md. K1 (A): BantA'da girdisiz sürüklenip PlakaA'ya darbe verir.
# K2 (B): Z1 ile kata çıkıp PlakaB'de durur. K3 (C): LazerB'yi geçip kapak kenarından döner, şalteri
# sola çevirir, PlakaC'ye bantın aksi yönünde darbe verir. Oyuncu: kapakta bekler, S ile kuyuya düşer.
const BOLUM_13 := "res://scenes/bolumler/bolum_13.tscn"

var _b13_onbellek: Array = []   # [A, B, C]


## Adım: yön, koşul, en çok kare, zıplama (ilk karede), asagi (S) basılı mı.
func _b13_a(yon: float, kosul := Callable(), maks := 300, zipla := false, asagi := false) -> Dictionary:
	return {"yon": yon, "kosul": kosul, "maks": maks, "zipla": zipla, "asagi": asagi}


func _b13_ornekle(b: Node) -> Dictionary:
	var o: CharacterBody2D = b.get_node("Oyuncu")
	return {"pa": b.get_node("PlakaA").basili_mi(), "pb": b.get_node("PlakaB").basili_mi(),
		"pc": b.get_node("PlakaC").basili_mi(),
		"la": b.get_node("LazerA").acik_mi(), "lb": b.get_node("LazerB").acik_mi(),
		"lc": b.get_node("LazerC").acik_mi(), "ld": b.get_node("LazerD").acik_mi(),
		"salter": b.get_node("Salter").sagda, "zemin": o.is_on_floor()}


func _b13_lazer_kapali(ad: String) -> Callable:
	return func(b: Node) -> bool: return not b.get_node(ad).acik_mi()


func _b13_lb_kapali_zemin() -> Callable:
	return func(b: Node) -> bool:
		return not b.get_node("LazerB").acik_mi() and b.get_node("Oyuncu").is_on_floor()


func _b13_salter_sola() -> Callable:
	return func(b: Node) -> bool: return not b.get_node("Salter").sagda


func _b13_plaka_basili(ad: String) -> Callable:
	return func(b: Node) -> bool: return b.get_node(ad).basili_mi()


## K1: bantta `sag_n` kare sağa, sonra girdisiz sürüklenir; bant sonunda (x>=262) durmasını bekler.
func _b13_k1(sag_n := 12, son_bekle := 12) -> Array:
	return [_b13_a(1, Callable(), sag_n), _b13_a(0, _b4_x_ge(262.0), 200), _b13_a(0, Callable(), son_bekle)]


## Ortak ön yol: `sag` basılı Z1'den uçar, x>=birak_x olunca bırakır (havada yatay durur, düşer).
func _b13_ortak(birak_x := 700.0) -> Array:
	return [_b13_a(1, _b4_x_ge(birak_x), 250)]


## K2: ortak yol, PlakaB üstünde durur.
func _b13_k2(birak_x := 700.0) -> Array:
	return _b13_ortak(birak_x) + [
		_b13_a(0, _b4_plakada("PlakaB"), 150), _b13_a(0, Callable(), 10)]


## K3: ortak yol, LazerB kapanınca (B tutuyor) kapak x>=dur_x'e gider, sola döner (şalter, PlakaC),
## x<=bitis_x'te durur.
func _b13_k3(dur_x := 985.0, birak_x := 700.0, bitis_x := 735.0, bekle := 0) -> Array:
	var d: Array = _b13_ortak(birak_x) + [_b13_a(0, _b13_lb_kapali_zemin(), 150)]
	if bekle > 0:
		d.append(_b13_a(0, Callable(), bekle))
	d += [_b13_a(1, _b4_x_ge(dur_x), 250),
		_b13_a(-1, _b4_x_le(bitis_x), 400),
		_b13_a(0, Callable(), 10)]
	return d


## Oyuncu: K3 gibi kapağa gider; `ref` koşulundan sonra `kayma` kare bekler, s_n kare S basar,
## kuyuda kapıya yürür.
func _b13_oyuncu(ref := Callable(), kayma := 0, dur_x := 985.0, s_n := 1) -> Array:
	var d: Array = _b13_ortak() + [_b13_a(0, _b13_lb_kapali_zemin(), 150),
		_b13_a(1, _b4_x_ge(dur_x), 250)]
	if ref.is_valid():
		d.append(_b13_a(0, ref, 400))
	if kayma > 0:
		d.append(_b13_a(0, Callable(), kayma))
	d.append(_b13_a(0, Callable(), s_n, false, true))
	d.append(_b13_a(0, _b13_kuyu_dibi(), 90))
	d.append(_b13_a(1, _b4_bitti_k(), 90))
	return d


## Oyuncu kuyu dibinde (zeminde, y>=570) mi?
func _b13_kuyu_dibi() -> Callable:
	return func(b: Node) -> bool:
		var o: CharacterBody2D = b.get_node("Oyuncu")
		return o.is_on_floor() and o.global_position.y >= 570.0 and o.global_position.x > 960.0


## Kayıt (kare başına {yon, zipla, asagi}) adım listesine çevirir; gecikme kare başta bekler.
func _b13_kayittan(kayit: Array, gecikme := 0, sonuna := true) -> Array:
	var d: Array = []
	if gecikme > 0:
		d.append(_b13_a(0, Callable(), gecikme))
	for g in kayit:
		d.append(_b13_a(float(g["yon"]), Callable(), 1, bool(g["zipla"]), bool(g.get("asagi", false))))
	if sonuna:
		d.append(_b13_a(1, _b4_bitti_k(), 300))
	return d


func _b13_kosullu(bolum: Node, adimlar: Array, sayac: Array) -> Dictionary:
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
			_girdi_uygula({"yon": a["yon"], "zipla": a["zipla"] and n == 0, "asagi": a.get("asagi", false)})
			iz.append(oyuncu.global_position)
			ozel.append(_b13_ornekle(bolum))
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
	return {"kare": kare, "bitti": bitti_son and sayac[0] == 0, "bitti_ham": bitti_son, "oldu": sayac[0],
		"iz": iz, "ozel": ozel, "klon_izleri": klon_iz, "baslangic": baslangic, "tamam": tamam,
		"kayit": kayit, "klon_oldu": klon_oldu}


func _b13_senaryo(kayitlar: Array, adimlar: Array, hazirlik := Callable()) -> Dictionary:
	_kayitlar().sifirla()
	for k in kayitlar:
		_kayitlar().tur_kaydet(k.duplicate(true))
	var bolum: Node = await _bolumu_yukle()
	if hazirlik.is_valid():
		hazirlik.call(bolum)
	var sayac := [0]
	bolum.get_node("Oyuncu").oyuncu_oldu.connect(func() -> void: sayac[0] += 1)
	var s: Dictionary = await _b13_kosullu(bolum, adimlar, sayac)
	paused = false
	return s


func _b13_yerlestir(oyuncu: Vector2) -> Callable:
	return func(b: Node) -> void:
		b.get_node("Oyuncu").global_position = oyuncu


## [K1, K2, K3] kayıtları (bir kez, gerçek dünyada klonlarla üretilir).
func _b13_kayitlar() -> Array:
	if _b13_onbellek.is_empty():
		var s1: Dictionary = await _b13_senaryo([], _b13_k1())
		var s2: Dictionary = await _b13_senaryo([s1["kayit"]], _b13_k2())
		var s3: Dictionary = await _b13_senaryo([s1["kayit"], s2["kayit"]], _b13_k3())
		_b13_onbellek = [s1["kayit"], s2["kayit"], s3["kayit"]]
	return _b13_onbellek


## Ayak y'nin en küçük değeri (y) ve en büyük x (x).
func _b13_ulasim(s: Dictionary) -> Vector2:
	var y := 1.0e9
	var x := -1.0e9
	for p in s["iz"]:
		y = minf(y, p.y + B4_AYAK)
		x = maxf(x, p.x)
	return Vector2(x, y)


func _b13_ilk(ozel: Array, anahtar: String, deger: Variant) -> int:
	for f in range(ozel.size()):
		if ozel[f][anahtar] == deger:
			return f
	return -1


## Anahtarın deger olduğu ardışık karelerin [ilk, son] aralığı ([-1,-1] yoksa); bas'tan itibaren ilk aralık.
func _b13_aralik(ozel: Array, anahtar: String, deger: Variant, bas := 0) -> Vector2i:
	var i0 := -1
	var i1 := -1
	for f in range(bas, ozel.size()):
		if ozel[f][anahtar] == deger:
			if i0 < 0:
				i0 = f
			i1 = f
		elif i0 >= 0:
			break
	return Vector2i(i0, i1)


func _b13_calistir() -> void:
	await _test_bolum13_cozum()
	await _test_bolum13_basarisizlik()
	await _test_bolum13_atlanamaz()
	await _test_bolum13_kisayol()
	await _test_bolum13_hassasiyet()
	await _test_bolum13_zamanlama()
	await _test_bolum13_klon_siniri()
	await _test_bolum13_kilitlenme()
	await _test_bolum13_determinizm()
	await _test_bolum13_klon_fark()


## K3 değişkeni: şalter alanının üstünden zıplayıp geçer (şalteri çevirmez), bantta PlakaC'ye 26 karelik darbe verir.
func _b13_k3_ziplayan() -> Array:
	return _b13_ortak() + [_b13_a(0, _b13_lb_kapali_zemin(), 150),
		_b13_a(1, _b4_x_ge(1040.0), 250), _b13_a(-1, _b4_x_le(880.0), 60, true),
		_b13_a(0, _b13_zeminde(), 60),
		_b13_a(-1, _b4_x_le(735.0), 400), _b13_a(0, Callable(), 10)]


func _b13_zeminde() -> Callable:
	return func(b: Node) -> bool: return b.get_node("Oyuncu").is_on_floor()


func _b13_son(s: Dictionary) -> Vector2:
	return s["iz"][s["iz"].size() - 1] if s["iz"].size() > 0 else Vector2.ZERO


## Oyuncu iziyle kare aralığı: gövde (28x48) bir dikdörtgenle çakışıyor mu.
func _b13_cakisir(p: Vector2, r: Rect2) -> bool:
	return Rect2(p - Vector2(14, 24), Vector2(28, 48)).intersects(r)


## Taslağın çözümü dışında kalan bir oyuncu: kare >= td olunca S basar (K3 ile aynı kapak yolu).
func _b13_oyuncu_td(td: int) -> Array:
	return _b13_oyuncu(_b13_kare_ge(td), 0, 976.0)


func _b13_kare_ge(n: int) -> Callable:
	return func(b: Node) -> bool: return b.get_node("Oyuncu").kare >= n


## Tam çözümde oyuncunun izi (kapıya varır); P0 = K3'ün dönüşte PlakaC'ye bastığı ilk kare (iz indeksi).
func _b13_referans() -> Dictionary:
	var kay: Array = await _b13_kayitlar()
	var s: Dictionary = await _b13_senaryo(kay, _b13_oyuncu(_b13_salter_sola(), 10))
	# Dönüş darbesi: şalter döndükten sonraki ilk PlakaC basılı aralığı.
	var f_salter: int = _b13_ilk(s["ozel"], "salter", false)
	var ar: Vector2i = _b13_aralik(s["ozel"], "pc", true, maxi(f_salter - 1, 0))
	var sf: int = s["baslangic"][5] if s["baslangic"].size() > 5 else -1   # S basılan ilk kare
	return {"s": s, "p0": ar.x, "p1": ar.y, "salter": f_salter, "td": sf}


# ---------------------------------------------------------------- 1) çözüm
func _test_bolum13_cozum() -> void:
	_kayitlar().sifirla()
	var bolum: Node = await _bolumu_yukle()
	var kareler: Array = []
	var olumsuz := ""
	var turlar: Array = [_b13_k1(), _b13_k2(), _b13_k3()]
	var etiketler: Array = []
	for i in range(3):
		var sayac := [0]
		bolum.get_node("Oyuncu").oyuncu_oldu.connect(func() -> void: sayac[0] += 1)
		var klon_once: int = _klonlar(bolum).size()
		var s: Dictionary = await _b13_kosullu(bolum, turlar[i], sayac)
		kareler.append(s["kare"])
		if s["tamam"].has(false) or s["oldu"] > 0 or s["kare"] > 600 or klon_once != i:
			olumsuz += " tur%d adım karşılanmadı %s oldu=%d kare=%d klon=%d;" % [i + 1, str(s["tamam"]), s["oldu"], s["kare"], klon_once]
		var eski_id := bolum.get_instance_id()
		await _r_bas()
		bolum = await _yeni_sahne_bekle(eski_id)
		if bolum == null:
			_kaydi("Bölüm 13 çözümü (4 tur, 3 klon, gerçek R/girdi yolu)", false, "tur %d sonrası sahne yüklenmedi;%s" % [i + 1, olumsuz])
			return
		etiketler.append(bolum.bilgi.text)
	var klon_basta: int = _klonlar(bolum).size()
	var etiket: String = bolum.bilgi.text
	var sayac4 := [0]
	bolum.get_node("Oyuncu").oyuncu_oldu.connect(func() -> void: sayac4[0] += 1)
	var s4: Dictionary = await _b13_kosullu(bolum, _b13_oyuncu(_b13_salter_sola(), 10), sayac4)
	var gecti: bool = s4["bitti"] and klon_basta == 3 and _kayitlar().turlar.size() == 3 \
		and etiket.contains("Klon: 3/3") and olumsuz == "" and s4["kare"] <= 600 and s4["oldu"] == 0 \
		and kareler[0] <= 600 and kareler[1] <= 600 and kareler[2] <= 600
	_kaydi("Bölüm 13 çözümü (4 tur, 3 klon, gerçek R/girdi yolu)", gecti,
		"bitti: %s, tur kareleri: %s + %d (%.2f sn), klon: %d, kayıtlı tur: %d, ölüm: %d, etiket: \"%s\"%s" % [
			s4["bitti"], str(kareler), s4["kare"], s4["kare"] / 60.0, klon_basta, _kayitlar().turlar.size(),
			s4["oldu"], etiket, olumsuz])
	_kayitlar().sifirla()
	paused = false


# ---------------------------------------------------------------- 2) başarısızlık
## Ölümün olduğu yer ve nedeni: oyuncunun son izi (ışın bölgesi).
func _b13_olum_yeri(s: Dictionary) -> String:
	var p: Vector2 = _b13_son(s)
	return "(%.0f,%.0f)" % [p.x, p.y]


func _test_bolum13_basarisizlik() -> void:
	var kay: Array = await _b13_kayitlar()
	var ref: Dictionary = await _b13_referans()
	var p0: int = ref["p0"]
	var sag_hep: Array = [_b13_a(1, Callable(), 220)]

	# 1) klonsuz: LazerA'da ölür (x 303..337 içinde).
	var s1: Dictionary = await _b13_senaryo([], sag_hep)
	var p1: Vector2 = _b13_son(s1)
	_kaydi("Bölüm 13 başarısızlık 1: klonsuz -> LazerA'da ölür", s1["oldu"] > 0 and not s1["bitti_ham"] and p1.x > 295.0 and p1.x < 345.0,
		"ölüm=%d, son konum %s (ışın x 317..323, gövde ışına 303'te girer)" % [s1["oldu"], _b13_olum_yeri(s1)])

	# 2) yalnız A: LazerB'de ölür.
	var s2: Dictionary = await _b13_senaryo([kay[0]], _b13_oyuncu())
	var p2: Vector2 = _b13_son(s2)
	_kaydi("Bölüm 13 başarısızlık 2: yalnız A -> LazerB'de ölür", s2["oldu"] > 0 and not s2["bitti_ham"] and p2.x > 735.0 and p2.x < 775.0,
		"ölüm=%d, son konum %s (LazerB x 757..763)" % [s2["oldu"], _b13_olum_yeri(s2)])

	# 3) A + B (C yok): kuyuda LazerC'de ölür. Oyuncu P0'dan bağımsız birkaç S zamanı dener.
	var ayr3: Array = []
	var ok3 := true
	for td in [186, 196, 206, 216, 230]:
		var s3: Dictionary = await _b13_senaryo([kay[0], kay[1]], _b13_oyuncu_td(td))
		var p3: Vector2 = _b13_son(s3)
		ok3 = ok3 and s3["oldu"] > 0 and not s3["bitti_ham"] and p3.x > 960.0 and p3.y > 430.0
		ayr3.append("Td=%d ölüm=%d son=%s" % [td, s3["oldu"], _b13_olum_yeri(s3)])
	_kaydi("Bölüm 13 başarısızlık 3: A + B (C yok) -> kuyuda LazerC'de ölür", ok3, "; ".join(ayr3))

	# 4) A + C (B yok): C LazerB'de donar (oyuncu bekler), oyuncu da aynı rotada ölür.
	var s4c: Dictionary = await _b13_senaryo([kay[0], kay[2]], [_b13_a(0, Callable(), 220)])
	var ckx: Vector2 = s4c["klon_izleri"][1][s4c["klon_izleri"][1].size() - 1]
	var s4: Dictionary = await _b13_senaryo([kay[0], kay[2]], _b13_oyuncu(Callable(), 0))
	var p4: Vector2 = _b13_son(s4)
	_kaydi("Bölüm 13 başarısızlık 4: A + C (B yok) -> C LazerB'de donar, oyuncu ölür",
		s4["oldu"] > 0 and not s4["bitti_ham"] and p4.x > 735.0 and p4.x < 775.0 and ckx.x < 775.0 and s4c["klon_oldu"][1],
		"ölüm=%d, oyuncu son %s, C son=(%.0f,%.0f), C öldü=%s" % [s4["oldu"], _b13_olum_yeri(s4), ckx.x, ckx.y, s4c["klon_oldu"][1]])

	# 5) S erken (Td < P0-18): LazerC'de ölür.
	var ayr5: Array = []
	var ok5 := true
	for d in [-40, -30, -24]:
		var s5: Dictionary = await _b13_senaryo(kay, _b13_oyuncu_td(p0 + d))
		var p5: Vector2 = _b13_son(s5)
		ok5 = ok5 and s5["oldu"] > 0 and not s5["bitti_ham"] and p5.y > 430.0 and p5.y < 520.0
		ayr5.append("P0%+d ölüm=%d son=%s" % [d, s5["oldu"], _b13_olum_yeri(s5)])
	_kaydi("Bölüm 13 başarısızlık 5: S erken basılır -> LazerC'de ölür", ok5, "P0=%d; %s" % [p0, "; ".join(ayr5)])

	# 6) S geç (Td > P0+2): darbe bitmiş, LazerC'de ölür.
	var ayr6: Array = []
	var ok6 := true
	for d in [6, 12, 24]:
		var s6: Dictionary = await _b13_senaryo(kay, _b13_oyuncu_td(p0 + d))
		var p6: Vector2 = _b13_son(s6)
		ok6 = ok6 and s6["oldu"] > 0 and not s6["bitti_ham"] and p6.y > 430.0 and p6.y < 520.0
		ayr6.append("P0%+d ölüm=%d son=%s" % [d, s6["oldu"], _b13_olum_yeri(s6)])
	_kaydi("Bölüm 13 başarısızlık 6: S geç basılır -> LazerC'de ölür", ok6, "P0=%d; %s" % [p0, "; ".join(ayr6)])

	# 7) C şalteri çevirmez (şalter alanının üstünden zıplar), oyuncu da çevirmez: LazerD'de ölür.
	var c_ziplayan: Array = _b13_k3_ziplayan()
	var s7c: Dictionary = await _b13_senaryo([kay[0], kay[1]], c_ziplayan)
	var ar7: Vector2i = _b13_aralik(s7c["ozel"], "pc", true, s7c["baslangic"][3] if s7c["baslangic"].size() > 3 else 0)
	var salter_hep_sagda := true
	for o in s7c["ozel"]:
		if not o["salter"]:
			salter_hep_sagda = false
	var ayr7: Array = []
	var ok7: bool = salter_hep_sagda and ar7.x > 0
	for d in [-10, -6]:
		var s7: Dictionary = await _b13_senaryo([kay[0], kay[1], s7c["kayit"]], _b13_oyuncu_td(ar7.x + d))
		var p7: Vector2 = _b13_son(s7)
		ok7 = ok7 and s7["oldu"] > 0 and not s7["bitti_ham"] and p7.y > 505.0 and p7.y < 580.0
		ayr7.append("P0'%+d ölüm=%d son=%s" % [d, s7["oldu"], _b13_olum_yeri(s7)])
	_kaydi("Bölüm 13 başarısızlık 7: C şalteri çevirmeden döner -> oyuncu LazerD'de ölür", ok7,
		"C şalteri hep sağda=%s, C darbe başlangıcı P0'=%d; %s" % [salter_hep_sagda, ar7.x, "; ".join(ayr7)])

	# 8) B iniş x >= 743: LazerB açık, B kayıt turunda ölür (tur yeniden başlar, klon hakkı harcanmaz).
	var s8: Dictionary = await _b13_senaryo([kay[0]], _b13_k2(752.0))
	var p8: Vector2 = _b13_son(s8)
	_kaydi("Bölüm 13 başarısızlık 8: B iniş x>=743 -> LazerB'de ölür", s8["oldu"] > 0 and p8.x > 735.0 and p8.x < 775.0,
		"ölüm=%d, son konum %s" % [s8["oldu"], _b13_olum_yeri(s8)])

	# 9) Kapakta x<974'te S: KatB duvarı, düşmez.
	var s9: Dictionary = await _b13_senaryo([], [_b13_a(0, Callable(), 3, false, true), _b13_a(0, Callable(), 40)],
		_b13_yerlestir(Vector2(966, 375.9)))
	var p9: Vector2 = _b13_son(s9)
	var y9 := 0.0
	for p in s9["iz"]:
		y9 = maxf(y9, p.y)
	_kaydi("Bölüm 13 başarısızlık 9: kapakta x<974'te S -> düşmez (KatB üstünde kalır)",
		s9["oldu"] == 0 and y9 < 380.0, "x=966'da S, en büyük y=%.1f (yüzey 376), ölüm=%d" % [y9, s9["oldu"]])

	# 10) K1 darbesi kısa (sürekli yürüme): K2 ve oyuncu LazerA'da ölür (kilitlenme).
	var k1_kisa: Array = [_b13_a(1, _b4_x_ge(262.0), 200), _b13_a(0, Callable(), 12)]
	var sk: Dictionary = await _b13_senaryo([], k1_kisa)
	var s10: Dictionary = await _b13_senaryo([sk["kayit"]], _b13_k2())
	var p10: Vector2 = _b13_son(s10)
	var pa_ar := _b13_aralik(sk["ozel"], "pa", true)
	_kaydi("Bölüm 13 başarısızlık 10: A kısa darbe (13 kare, geçiş penceresi dışı) -> B LazerA'da ölür",
		s10["oldu"] > 0 and p10.x > 295.0 and p10.x < 345.0,
		"A darbe süresi=%d kare (%s), B son konum %s, ölüm=%d" % [pa_ar.y - pa_ar.x + 1, str(pa_ar), _b13_olum_yeri(s10), s10["oldu"]])

	# 11) B gecikmeli iner (tutucu geç): oyuncu LazerB'ye bekleyen yürür, ölür (tutucu zorunlu).
	var b_gec: Array = [_b13_a(0, Callable(), 40)] + _b13_k2()
	var sb: Dictionary = await _b13_senaryo([kay[0]], b_gec)
	var s11: Dictionary = await _b13_senaryo([kay[0], sb["kayit"]], [_b13_a(1, Callable(), 150)])
	var p11: Vector2 = _b13_son(s11)
	_kaydi("Bölüm 13 başarısızlık 11: tutucu (B) geç gelir, oyuncu beklemeden koşar -> LazerB'de ölür",
		s11["oldu"] > 0 and p11.x > 735.0 and p11.x < 775.0, "B 40 kare gecikmeli (kayıt turunda ölüm=%d), oyuncu son %s, ölüm=%d" % [
			sb["oldu"], _b13_olum_yeri(s11), s11["oldu"]])
	_kayitlar().sifirla()


# ---------------------------------------------------------------- 3) atlanamazlık
func _test_bolum13_atlanamaz() -> void:
	# a) Zeminden kata zıplayarak çıkılamaz (kat yüzeyi 400, zıplama tepesi 100,9 px: ayak >= 499).
	var sa: Dictionary = await _b13_senaryo([], _b8_zipla_dizisi(6, 1.0, 40) + _b8_zipla_dizisi(3, 0.0, 40),
		_b13_yerlestir(Vector2(610, 576)))
	var ua: Vector2 = _b13_ulasim(sa)
	_kaydi("Bölüm 13 atlanamaz: zeminden kata zıplayarak çıkılamaz (kat 400)", ua.y >= 480.0 and sa["oldu"] == 0 and ua.x < 640.0,
		"ayak y min=%.1f (600-100,9=~499), en büyük x=%.0f (KatA sol yüzü 640)" % [ua.y, ua.x])

	# b) Z1 uçuşu: farklı çıkış x'lerinde `sag` sürekli basılı: LazerB geçilemez (alive iken x<=745).
	var ayr_b: Array = []
	var ok_b := true
	var iniş_yok := 0
	for x0 in [470.0, 500.0, 530.0, 548.0, 555.0]:
		var sb: Dictionary = await _b13_senaryo([], [_b13_a(1, Callable(), 130)], _b13_yerlestir(Vector2(x0, 576)))
		var max_x_canli := -1.0e9
		for p in sb["iz"]:
			max_x_canli = maxf(max_x_canli, p.x)
		# Ölünce iz son noktada kalır: ölüm konumu LazerB sol kenarındadır.
		ok_b = ok_b and sb["oldu"] > 0 and max_x_canli < 775.0 and not sb["bitti_ham"]
		ayr_b.append("x0=%.0f: ölüm=%d, en büyük x=%.0f" % [x0, sb["oldu"], max_x_canli])
	_kaydi("Bölüm 13 atlanamaz: Z1 uçuşu + sürekli sag LazerB'yi aşamaz (ışında ölür, x<775)", ok_b, "; ".join(ayr_b))

	# c) Z1 uçuşunda sag'ı n kare basılı tutup bırak, inince sürekli sag: hiçbir varyant LazerB'yi geçemez.
	var ayr_c: Array = []
	var ok_c := true
	for x0 in [470.0, 555.0]:
		for n in [0, 10, 25, 40, 60]:
			var sc: Dictionary = await _b13_senaryo([], [_b13_a(0, Callable(), 2), _b13_a(1, Callable(), n),
				_b13_a(0, Callable(), 70), _b13_a(1, Callable(), 100)], _b13_yerlestir(Vector2(x0, 576)))
			var xc := -1.0e9
			for p in sc["iz"]:
				xc = maxf(xc, p.x)
			ok_c = ok_c and not sc["bitti_ham"] and xc < 775.0
			ayr_c.append("x0=%.0f n=%d: ölüm=%d x max=%.0f" % [x0, n, sc["oldu"], xc])
	_kaydi("Bölüm 13 atlanamaz: Z1 uçuşunda sag süresi/çıkış x'i değişse de LazerB geçilemez", ok_c, "; ".join(ayr_c))

	# d) Kapak S'siz geçilemez: üstünde sol/sag/zıpla/girdisiz -> y 376'da kalır (hiçbiri kuyuya inmez).
	var ayr_d: Array = []
	var ok_d := true
	for g in [[0.0, false], [-1.0, false], [1.0, false], [0.0, true]]:
		var adim: Array = []
		for i in range(5):
			adim.append(_b13_a(g[0], Callable(), 8, g[1]))
		var sd: Dictionary = await _b13_senaryo([], adim, _b13_yerlestir(Vector2(1020, 375.9)))
		var yd := 0.0
		for p in sd["iz"]:
			yd = maxf(yd, p.y)
		ok_d = ok_d and yd < 380.0 and sd["oldu"] == 0
		ayr_d.append("yon=%d zipla=%s: y max=%.1f" % [int(g[0]), g[1], yd])
	_kaydi("Bölüm 13 atlanamaz: kapak S'siz geçilemez (kuyuya düşülmez)", ok_d, "; ".join(ayr_d))

	# e) Bant dikişleri: sağa ve sola yürüyüşte takılma yok (dx>0 / <0 her karede), y sabit.
	var ayr_e: Array = []
	var ok_e := true
	var olcum: Array = [["BantA/ZeminSol+ZeminSag (x 80->300)", Vector2(80, 575.9), 1.0, 300.0],
		["BantA ters (x 300->80)", Vector2(300, 575.9), -1.0, 80.0],
		["BantC/KatB (x 800->960)", Vector2(800, 375.9), 1.0, 960.0],
		["BantC/KatB ters (x 960->800)", Vector2(960, 375.9), -1.0, 800.0]]
	for o in olcum:
		var yon: float = o[2]
		var hedef: float = o[3]
		var kosul: Callable = _b4_x_ge(hedef) if yon > 0.0 else _b4_x_le(hedef)
		var se: Dictionary = await _b13_senaryo([], [_b13_a(yon, kosul, 200)], _b13_yerlestir(o[1]))
		var min_dx := 1.0e9
		var max_ysap := 0.0
		for f in range(1, se["iz"].size()):
			min_dx = minf(min_dx, (se["iz"][f].x - se["iz"][f - 1].x) * yon)
			max_ysap = maxf(max_ysap, absf(se["iz"][f].y - o[1].y))
		ok_e = ok_e and min_dx > 0.5 and max_ysap < 1.5 and se["oldu"] == 0
		ayr_e.append("%s: en küçük |dx|=%.2f px/kare, y sapma=%.2f" % [o[0], min_dx, max_ysap])
	_kaydi("Bölüm 13 atlanamaz: bant/zemin/KatB dikişlerinde yürüyüş takılmaz", ok_e, "; ".join(ayr_e))

	# f) Işın geometrisi: LazerA tavan alt kenarından (150) zemin üstüne (600), LazerB tavandan kat yüzeyine (400);
	#    LazerC/D kuyuyu duvardan duvara (960..1080) kapatır.
	_kayitlar().sifirla()
	var bolum: Node = await _bolumu_yukle()
	var ok_f := true
	var ayr_f: Array = []
	var beklenen := {"LazerA": Rect2(317, 150, 6, 450), "LazerB": Rect2(757, 150, 6, 250),
		"LazerC": Rect2(960, 467, 120, 6), "LazerD": Rect2(960, 537, 120, 6)}
	for ad in beklenen:
		var lz: Node2D = bolum.get_node(ad)
		var sh: CollisionShape2D = lz.get_node("Isin")
		var boyut: Vector2 = (sh.shape as RectangleShape2D).size
		var merkez: Vector2 = lz.global_position + sh.position
		var r := Rect2(merkez - boyut / 2.0, boyut)
		var tam: bool = absf(r.position.x - beklenen[ad].position.x) < 0.01 and absf(r.position.y - beklenen[ad].position.y) < 0.01 \
			and absf(r.size.x - beklenen[ad].size.x) < 0.01 and absf(r.size.y - beklenen[ad].size.y) < 0.01
		ok_f = ok_f and tam
		ayr_f.append("%s %s" % [ad, str(r)])
	# Işın uçları katı yüzeye değiyor mu: zemin üstü 600, kat üstü 400, tavan alt 150.
	var zemin_ust: float = bolum.get_node("ZeminSag").position.y - 20.0
	var kat_ust: float = bolum.get_node("KatA").position.y - 100.0
	var tavan_alt: float = bolum.get_node("Tavan").position.y + 75.0
	ok_f = ok_f and absf(zemin_ust - 600.0) < 0.01 and absf(kat_ust - 400.0) < 0.01 and absf(tavan_alt - 150.0) < 0.01
	_kaydi("Bölüm 13 atlanamaz: ışınlar tam (A 150..600, B 150..400, C/D kuyu genişliği)", ok_f,
		"%s; zemin üstü=%.0f, kat üstü=%.0f, tavan alt=%.0f" % ["; ".join(ayr_f), zemin_ust, kat_ust, tavan_alt])

	# g) Kapak dışından kuyuya giriş yok: kuyu tabanı/yanları dolu. Kuyunun üstünde yalnız tek yönlü kapak;
	#    sahnedeki tek yönlü parça sayısı 1, kapı kuyuda.
	var tek := 0
	var kutu_var := false
	var gecit_var := false
	for c in bolum.get_children():
		if c is StaticBody2D:
			for k in c.get_children():
				if k is CollisionShape2D and k.one_way_collision:
					tek += 1
		if String(c.name).to_lower().contains("kutu"):
			kutu_var = true
		if c.get_script() != null and String(c.get_script().resource_path).ends_with("gecit.gd") \
				or c.get_script() != null and String(c.get_script().resource_path).ends_with("asansor.gd"):
			gecit_var = true
	var kapi_p: Vector2 = bolum.get_node("Kapi").global_position
	_kaydi("Bölüm 13 atlanamaz: tek giriş kapak (1 tek yönlü), kutu/geçit/asansör yok, kapı kuyu dibinde",
		tek == 1 and not kutu_var and not gecit_var and kapi_p.y > 560.0 and kapi_p.x > 1000.0 and kapi_p.x < 1040.0,
		"tek yönlü=%d, kutu=%s, geçit/asansör=%s, kapı=%s" % [tek, kutu_var, gecit_var, str(kapi_p)])
	_kayitlar().sifirla()


# ---------------------------------------------------------------- 4) kısayol taraması
func _test_bolum13_kisayol() -> void:
	var kay: Array = await _b13_kayitlar()
	var ref: Dictionary = await _b13_referans()
	var p0: int = ref["p0"]
	var A: Array = kay[0]
	var B: Array = kay[1]
	var C: Array = kay[2]
	var ayr: Array = []
	var hepsi := true

	# --- 1: klonsuz (çeşitli girdiler). Oyuncu tek başına hiç bir yöntemle LazerA'dan geçemez.
	var kos: Array = [
		["sag sürekli", [_b13_a(1, Callable(), 250)]],
		["sağ+zıpla", [_b13_a(1, Callable(), 30)] + _b8_zipla_dizisi(5, 1.0, 40)],
		["bantta dalgalan", [_b13_a(1, Callable(), 10), _b13_a(-1, Callable(), 10), _b13_a(1, Callable(), 10),
			_b13_a(-1, Callable(), 10), _b13_a(1, Callable(), 250)]]]
	for k in kos:
		var s: Dictionary = await _b13_senaryo([], k[1])
		hepsi = hepsi and not s["bitti_ham"]
		ayr.append("1 klonsuz/%s: bitti=%s" % [k[0], s["bitti_ham"]])

	# --- 2/3/4: 1 ya da 2 klon, kayıtların tüm alt kümeleri ve sıraları; oyuncu uyarlanabilir yol (koşullu).
	var kume: Array = [["A", [A]], ["B", [B]], ["C", [C]], ["A+B", [A, B]], ["A+C", [A, C]], ["B+C", [B, C]],
		["B+A", [B, A]], ["C+A", [C, A]], ["A+A", [A, A]], ["C+B", [C, B]]]
	for k in kume:
		# Oyuncu: kapağa varabildiği kadar gider; P0'dan farklı üç S zamanı dener (P0-8, P0, kare 400 kuralsız).
		var sonuc := ""
		var bitti_mi := false
		for d in [-8, 0, 40]:
			var s: Dictionary = await _b13_senaryo(k[1], _b13_oyuncu_td(p0 + d))
			bitti_mi = bitti_mi or s["bitti_ham"]
		hepsi = hepsi and not bitti_mi
		ayr.append("2-4 %s: bitti=%s" % [k[0], bitti_mi])

	# --- 3: A+B ve oyuncu PlakaC'ye kendisi darbe verir: üç darbe biçimi (13 / 26 / 53 kare) sonra kapağa koşar, S.
	var kendi: Array = [
		["bantla yürüyerek (13)", [_b13_a(1, _b4_x_ge(900.0), 60)]],
		["bantla ters yürüyerek (26)", [_b13_a(1, _b4_x_ge(950.0), 60), _b13_a(-1, _b4_x_le(790.0), 80)]],
		["girdisiz sürüklenme (53)", [_b13_a(1, _b4_x_ge(802.0), 60), _b13_a(0, _b4_x_ge(900.0), 120)]]]
	for k in kendi:
		var adim: Array = _b13_ortak() + [_b13_a(0, _b13_lb_kapali_zemin(), 150)] + k[1] + [
			_b13_a(1, _b4_x_ge(985.0), 120), _b13_a(0, Callable(), 1, false, true),
			_b13_a(0, _b13_kuyu_dibi(), 90), _b13_a(1, _b4_bitti_k(), 90)]
		var s: Dictionary = await _b13_senaryo([A, B], adim)
		hepsi = hepsi and not s["bitti_ham"]
		ayr.append("3 A+B, oyuncu kendi darbesi %s: bitti=%s oldu=%d" % [k[0], s["bitti_ham"], s["oldu"]])

	# --- 4/5 röle: B' PlakaB'de T kare durup ayrılır (tutucu devri), C' onun yerine geçer; 2 klon, çözüm olmaz.
	for t in [10, 20, 40, 80]:
		var b_role: Array = _b13_ortak() + [_b13_a(0, _b4_plakada("PlakaB"), 150), _b13_a(0, Callable(), t)] + \
			[_b13_a(1, _b4_x_ge(985.0), 250), _b13_a(-1, _b4_x_le(735.0), 400), _b13_a(0, Callable(), 10)]
		var sr: Dictionary = await _b13_senaryo([A], b_role)
		var s: Dictionary = await _b13_senaryo([A, sr["kayit"]], _b13_oyuncu_td(p0 - 10))
		hepsi = hepsi and not s["bitti_ham"]
		ayr.append("4-5 röle T=%d: B' kayıt ölüm=%d, oyuncu bitti=%s" % [t, sr["oldu"], s["bitti_ham"]])

	# --- 6: oyuncu PlakaC'yi tutar (bantta dalgalanır), kapağa gidemez; klon yok (A+B ile): plaka-kapak aralığı.
	var s6: Dictionary = await _b13_senaryo([A, B], _b13_ortak() + [_b13_a(0, _b13_lb_kapali_zemin(), 150),
		_b13_a(1, _b4_x_ge(820.0), 100)] + [_b13_a(-1, Callable(), 8), _b13_a(1, Callable(), 8), _b13_a(-1, Callable(), 8),
		_b13_a(1, Callable(), 8)] + [_b13_a(1, _b4_x_ge(985.0), 120), _b13_a(0, Callable(), 1, false, true),
		_b13_a(0, _b13_kuyu_dibi(), 90), _b13_a(1, _b4_bitti_k(), 90)])
	hepsi = hepsi and not s6["bitti_ham"]
	ayr.append("6 oyuncu PlakaC'de dalgalanır sonra kapağa: bitti=%s" % s6["bitti_ham"])

	# --- 12: şalteri oyuncunun kendisi çevirmesi klon saymaz: [A,B,C_zıplayan] + oyuncu şalteri kendi çevirir -> BİTER;
	#     [A,B] + oyuncu şalter çeviren ise YİNE bitmez (LazerC için C gerek).
	var c_ziplayan: Array = _b13_k3_ziplayan()
	var sc: Dictionary = await _b13_senaryo([A, B], c_ziplayan)
	var arc: Vector2i = _b13_aralik(sc["ozel"], "pc", true, sc["baslangic"][3] if sc["baslangic"].size() > 3 else 0)
	# Oyuncu kapağa varır, şalteri kendisi çevirir (sol, SagAlan), kapağa geri döner, S basar.
	var kendi_salter: Array = _b13_ortak() + [_b13_a(0, _b13_lb_kapali_zemin(), 150),
		_b13_a(1, _b4_x_ge(985.0), 250), _b13_a(-1, _b13_salter_sola(), 30),
		_b13_a(1, _b4_x_ge(985.0), 30), _b13_a(0, _b13_kare_ge(arc.x - 10), 200), _b13_a(0, Callable(), 1, false, true),
		_b13_a(0, _b13_kuyu_dibi(), 90), _b13_a(1, _b4_bitti_k(), 90)]
	var s12: Dictionary = await _b13_senaryo([A, B, sc["kayit"]], kendi_salter)
	var s12b: Dictionary = await _b13_senaryo([A, B], kendi_salter)
	hepsi = hepsi and s12["bitti_ham"] and not s12b["bitti_ham"]
	ayr.append("12 şalteri oyuncu çevirir: [A,B,C_zıplayan] bitti=%s (gerek: 3 klon yine), [A,B] bitti=%s" % [s12["bitti_ham"], s12b["bitti_ham"]])

	# --- 13: S düşmenin açtığı yeni yollar: kuyudan çıkış yok (zıplatıcı kuyuda yok), yalnız kapak tek yönlü.
	var s13: Dictionary = await _b13_senaryo([], [_b13_a(0, Callable(), 3, false, true)] + _b8_zipla_dizisi(5, 0.0, 40) + _b8_zipla_dizisi(4, 1.0, 40),
		_b13_yerlestir(Vector2(1020, 375.9)))
	# Not: LazerC kapalı olmadığından ölür (lazerler açık); kuyuya girmek ışında biter, bu başlı başına çıkış değil.
	var son13: Vector2 = _b13_son(s13)
	var kuyu_ust := 1.0e9
	for p in s13["iz"]:
		if p.y > 420.0:
			kuyu_ust = minf(kuyu_ust, p.y)
	hepsi = hepsi and not s13["bitti_ham"]
	ayr.append("13 S düşme sonrası: oyuncu son=(%.0f,%.0f), bitti=%s, ölüm=%d" % [son13.x, son13.y, s13["bitti_ham"], s13["oldu"]])

	# --- 14: kutu yok (tarama: sahnede kutu/geçit/asansör düğümü yok) -> atlanamaz testinde doğrulandı.
	# --- 8: geçit altı park/röle bu bölümde uygulanamaz (geçit/asansör yok).
	_kaydi("Bölüm 13 kısayol taraması (2 klonla/klonsuz bitmez; S/bant/şalter/röle varyantları; çözüm 3 klonla)", hepsi, "; ".join(ayr))
	_kayitlar().sifirla()


# ---------------------------------------------------------------- 5) hassasiyet (pencere ölçümleri)
## Verilen oyuncu adımlarıyla (klonlu) çözümün biteceği değişken değerleri.
func _b13_bitti(kayitlar: Array, adimlar: Array) -> bool:
	var s: Dictionary = await _b13_senaryo(kayitlar, adimlar)
	return s["bitti_ham"] and s["oldu"] == 0


func _b13_aralik_yaz(deger_listesi: Array, ok_listesi: Array) -> String:
	# ardışık geçen değerleri [lo..hi] parçalarına çevirir
	var parcalar: Array = []
	var lo := -1
	var hi := -1
	for i in range(deger_listesi.size()):
		if ok_listesi[i]:
			if lo < 0:
				lo = deger_listesi[i]
			hi = deger_listesi[i]
		elif lo >= 0:
			parcalar.append("%d..%d" % [lo, hi])
			lo = -1
	if lo >= 0:
		parcalar.append("%d..%d" % [lo, hi])
	return ", ".join(parcalar) if not parcalar.is_empty() else "yok"


func _test_bolum13_hassasiyet() -> void:
	var kay: Array = await _b13_kayitlar()
	var ref: Dictionary = await _b13_referans()
	var p0: int = ref["p0"]
	var p1: int = ref["p1"]
	var td_ref: int = ref["td"]
	var s_ref: Dictionary = ref["s"]
	# --- a) Td penceresi: S basma karesi (iz indeksi) süpürmesi.
	var tdler: Array = []
	var oklar: Array = []
	for td in range(178, p0 + 24):
		var s: Dictionary = await _b13_senaryo(kay, _b13_oyuncu_td(td))
		tdler.append(td)
		oklar.append(s["bitti_ham"] and s["oldu"] == 0)
	var pencere: String = _b13_aralik_yaz(tdler, oklar)
	var kabul := 0
	for o in oklar:
		if o:
			kabul += 1
	_kaydi("Bölüm 13 ölçüm: S basma (Td) penceresi", kabul >= 5 and kabul <= 40 and oklar[tdler.find(td_ref)] if tdler.has(td_ref) else kabul >= 5,
		"P0=%d (C'nin dönüş darbesi ilk kare), darbe son kare=%d (%d kare), Td kabul edilenler: %s (%d kare genişlik; taslak P0-18..P0+2); referans oyuncu Td=%d" % [
			p0, p1, p1 - p0 + 1, pencere, kabul, td_ref])

	# --- b) Kuyu düşüş zamanı: referans oyuncunun izinden ışınlara göre kare farkları.
	var iz: Array = s_ref["iz"]
	var rc := Rect2(960, 467, 120, 6)
	var rd := Rect2(960, 537, 120, 6)
	var c_ilk := -1
	var c_son := -1
	var d_ilk := -1
	var d_son := -1
	var zemin_f := -1
	for f in range(td_ref, iz.size()):
		if _b13_cakisir(iz[f], rc):
			if c_ilk < 0:
				c_ilk = f
			c_son = f
		if _b13_cakisir(iz[f], rd):
			if d_ilk < 0:
				d_ilk = f
			d_son = f
		if zemin_f < 0 and iz[f].y >= 575.0:
			zemin_f = f
	var lc_kap: Vector2i = _b13_aralik(s_ref["ozel"], "lc", false, maxi(ref["salter"] - 1, 0))
	_kaydi("Bölüm 13 ölçüm: kuyu düşüş zamanı (S'den ışınlara)", c_ilk > 0 and d_ilk > 0 and c_ilk - td_ref >= 12,
		"S karesi=%d; LazerC ışınında kare Td+%d..Td+%d (%d kare), LazerD ışınında Td+%d..Td+%d (%d kare), zemin Td+%d (taslak C: +19..+24, D: +27..+30, zemin +32); LazerC kapalı kareler (görünür durum): %s" % [
			td_ref, c_ilk - td_ref, c_son - td_ref, c_son - c_ilk + 1, d_ilk - td_ref, d_son - td_ref, d_son - d_ilk + 1,
			zemin_f - td_ref, str(lc_kap)])

	# --- c) Lazer geçiş pencereleri: yatay 5 px/kare ile ışın genişliği: gövde 28 + ışın 6 = 34 px.
	var pen_a := 34.0 / 5.0
	_kaydi("Bölüm 13 ölçüm: lazer geçiş süreleri (kare)", true,
		"LazerA/B (6 px, yatay 5 px/kare): %.1f kare; LazerC/D düşüşte: C %d kare, D %d kare (ölçülen)" % [pen_a, c_son - c_ilk + 1, d_son - d_ilk + 1])

	# --- d) Darbe süreleri (PlakaC 88 px basma penceresi, bant 1,667 px/kare).
	var darbe: Array = []
	var senaryolar: Array = [
		["bantla yürüyerek (13,2)", Vector2(790, 375.9), [_b13_a(1, _b4_x_ge(910.0), 80)], "PlakaC"],
		["bantın aksine yürüyerek (26,4)", Vector2(930, 375.9), [_b13_a(-1, _b4_x_le(780.0), 120)], "PlakaC"],
		["girdisiz sürüklenme (52,8)", Vector2(790, 375.9), [_b13_a(0, _b4_x_ge(900.0), 150)], "PlakaC"]]
	var ok_d := true
	for sc in senaryolar:
		var sd: Dictionary = await _b13_senaryo([], sc[2], _b13_yerlestir(sc[1]))
		var key := "pc"
		var ar: Vector2i = _b13_aralik(sd["ozel"], key, true)
		var n: int = ar.y - ar.x + 1 if ar.x >= 0 else 0
		darbe.append("%s: %d kare" % [sc[0], n])
		var beklenen: int = 13 if str(sc[0]).contains("13") else (26 if str(sc[0]).contains("26") else 53)
		ok_d = ok_d and absi(n - beklenen) <= 2
	# PlakaA bantı (BantA üstünde, K1 gerçek kaydı): girdisiz sürüklenme.
	var ar_a: Vector2i = _b13_aralik(ref["s"]["ozel"], "pa", true)
	_kaydi("Bölüm 13 ölçüm: bant darbe süreleri (13 / 26 / 53 kare)", ok_d, "; ".join(darbe))

	# --- e) K1 yürüme süresi (sag_n) süpürmesi: A darbesi başlangıcı ve çözümün biteceği değerler.
	var ns: Array = []
	var ok_n: Array = []
	for n in [2, 4, 6, 8, 9, 10, 11, 12, 14, 18, 24, 30, 40]:
		var s1: Dictionary = await _b13_senaryo([], _b13_k1(n))
		var s2: Dictionary = await _b13_senaryo([s1["kayit"]], _b13_k2())
		var tamam: bool = s2["oldu"] == 0 and not s2["tamam"].has(false)
		ns.append(n)
		ok_n.append(tamam)
	_kaydi("Bölüm 13 ölçüm: K1 ilk yürüyüş süresi (BantA girişi), K2'nin LazerA'yı geçmesi", true,
		"B (K2) geçer: sag_n=%s (K1 x=60'tan sag_n*5 px yürür; sag_n<=8 BantA başı x=100 bantta takılır, ~20 kare ZeminSol üstünde bekler)" % _b13_aralik_yaz(ns, ok_n))

	# --- f) LazerA geçiş penceresi: K2 başlangıç gecikmesi s (K1 sabit).
	var ss: Array = []
	var ok_s: Array = []
	for s_g in range(-10, 60, 4):
		var gec: int = maxi(s_g, 0)
		var adim: Array = ([_b13_a(0, Callable(), gec)] if gec > 0 else []) + _b13_k2()
		var s2: Dictionary = await _b13_senaryo([kay[0]], adim)
		ss.append(s_g)
		ok_s.append(s2["oldu"] == 0 and not s2["tamam"].has(false))
	_kaydi("Bölüm 13 ölçüm: LazerA geçiş penceresi (B'nin başlangıç gecikmesi, kare)", true,
		"K2 geçer: gecikme=%s (negatif = 0 gecikme; taslak -10..+34)" % _b13_aralik_yaz(ss, ok_s))

	# --- g) B iniş x süpürmesi (bırakma x'i): LazerB açıkken ışın sol kenarı 757-14=743.
	var xs: Array = []
	var ok_x: Array = []
	var ayr_x: Array = []
	for x in range(620, 770, 10):
		var s2: Dictionary = await _b13_senaryo([kay[0]], _b13_k2(float(x)))
		var son: Vector2 = _b13_son(s2)
		var kata: bool = s2["oldu"] == 0 and not s2["tamam"].has(false) and son.y < 400.0
		xs.append(x)
		ok_x.append(kata)
		ayr_x.append("%d:%s" % [x, "PlakaB" if kata else ("öldü" if s2["oldu"] > 0 else "iniş yok")])
	_kaydi("Bölüm 13 ölçüm: B'nin bırakma x'i (PlakaB'ye iniş) penceresi", true,
		"bırakma x'i (x>=...): %s; başarılı aralık: %s (taslak 626..735)" % [" ".join(ayr_x), _b13_aralik_yaz(xs, ok_x)])

	# --- h) Z1 köşe payı (K=30'da sağ kenar 640): ortak yolda ayak y ve x.
	var s_k2: Dictionary = await _b13_senaryo([kay[0]], _b13_k2())
	var kose_ayak := 1.0e9
	var kose_f := -1
	for f in range(s_k2["iz"].size()):
		var p: Vector2 = s_k2["iz"][f]
		if p.x + 14.0 >= 640.0 and kose_f < 0:
			kose_f = f
			kose_ayak = p.y + 24.0
	var tepe_ayak := 1.0e9
	for p in s_k2["iz"]:
		tepe_ayak = minf(tepe_ayak, p.y + 24.0)
	_kaydi("Bölüm 13 ölçüm: Z1 uçuşu köşe payı", kose_f > 0 and kose_ayak < 400.0,
		"sağ kenar 640'a ilk varışta ayak y=%.1f (kat yüzeyi 400, pay %.1f px), uçuş tepesi ayak y=%.1f (taslak 353)" % [
			kose_ayak, 400.0 - kose_ayak, tepe_ayak])

	# --- i) Bant-KatB dikişi: x=926..954 arasında dikiş; sabit durma ve sürüklenme.
	var seam: Array = []
	for x0 in [920.0, 930.0, 938.0, 942.0, 950.0]:
		var sj: Dictionary = await _b13_senaryo([], [_b13_a(0, Callable(), 60)], _b13_yerlestir(Vector2(x0, 375.9)))
		var son: Vector2 = _b13_son(sj)
		seam.append("x0=%.0f -> %.1f" % [x0, son.x])
	_kaydi("Bölüm 13 ölçüm: BantC-KatB dikişinde girdisiz duruş (60 kare)", true, "; ".join(seam))

	# --- j) PlakaB-LazerB payı: plakadan ayrılış ile LazerB açılışı ve ışına varış.
	var sp: Dictionary = await _b13_senaryo([], [_b13_a(1, Callable(), 40)], _b13_yerlestir(Vector2(700, 375.9)))
	var f_pb := -1
	var f_lb_acik := -1
	var f_isin := -1
	var onceki_pb := false
	for f in range(sp["ozel"].size()):
		if onceki_pb and not sp["ozel"][f]["pb"] and f_pb < 0:
			f_pb = f
		onceki_pb = sp["ozel"][f]["pb"]
		if f_pb >= 0 and f_lb_acik < 0 and sp["ozel"][f]["lb"]:
			f_lb_acik = f
		if _b13_cakisir(sp["iz"][f], Rect2(757, 150, 6, 250)) and f_isin < 0:
			f_isin = f
	_kaydi("Bölüm 13 ölçüm: PlakaB bırakılınca LazerB açılışı ve ışına varış", f_pb > 0,
		"plaka bırakma karesi=%d, LazerB açık (görünür) +%d kare, gövde ışında +%d kare; oyuncu öldü=%d (yalnız yürürken; açılış gecikmesi %d kare)" % [
			f_pb, f_lb_acik - f_pb, f_isin - f_pb if f_isin > 0 else -1, sp["oldu"], f_lb_acik - f_pb])
	_kayitlar().sifirla()


# ---------------------------------------------------------------- 6) zamanlama: kapak x penceresi
func _test_bolum13_zamanlama() -> void:
	# S'nin düşürdüğü kapak merkez x aralığı (taslak 974..1066): lazerler açık, ölüm düşüşte; "düştü" = ölüm ya da y>440.
	var xs: Array = []
	var dus: Array = []
	var ayr: Array = []
	for x in [958, 962, 966, 970, 972, 973, 974, 975, 976, 980, 1060, 1064, 1065, 1066, 1067, 1070, 1074]:
		var s: Dictionary = await _b13_senaryo([], [_b13_a(0, Callable(), 3, false, true), _b13_a(0, Callable(), 40)],
			_b13_yerlestir(Vector2(float(x), 375.9)))
		var ymax := 0.0
		for p in s["iz"]:
			ymax = maxf(ymax, p.y)
		var dustu: bool = s["oldu"] > 0 or ymax > 400.0
		xs.append(x)
		dus.append(dustu)
		ayr.append("%d:%s" % [x, "düşer" if dustu else "durur"])
	var alt := -1
	var ust := -1
	for i in range(xs.size()):
		if dus[i]:
			if alt < 0:
				alt = xs[i]
			ust = xs[i]
	_kaydi("Bölüm 13 ölçüm: S ile düşen kapak merkez x aralığı", alt > 0,
		"düşen aralık x=%d..%d (taslak 974..1066); %s" % [alt, ust, " ".join(ayr)])
	_kayitlar().sifirla()


# ---------------------------------------------------------------- 7) klon sınırı
func _test_bolum13_klon_siniri() -> void:
	_kayitlar().sifirla()
	var bolum: Node = await _bolumu_yukle()
	var maks: int = bolum.max_klon
	var gecti := maks == 3
	var ayr: Array = []
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
			ayr.append("sınırda etiket: \"%s\"" % yazi)
		ayr.append("R #%d -> kayıtlı klon: %d" % [n + 1, sayi])
	_kaydi("Bölüm 13: klon sınırı (dördüncü R klon kaydetmez)", gecti, "max_klon=%d; %s" % [maks, ", ".join(ayr)])
	_kayitlar().sifirla()


# ---------------------------------------------------------------- 8) kilitlenme davranışı
func _test_bolum13_kilitlenme() -> void:
	# Oyuncu kuyuda ölünce tur yeniden başlar: klonlar korunur (kilitlenme değil), tur sayısı artmaz.
	var kay: Array = await _b13_kayitlar()
	_kayitlar().sifirla()
	for k in [kay[0], kay[1]]:
		_kayitlar().tur_kaydet(k.duplicate(true))
	var bolum: Node = await _bolumu_yukle()
	var sayac := [0]
	bolum.get_node("Oyuncu").oyuncu_oldu.connect(func() -> void: sayac[0] += 1)
	var eski_id := bolum.get_instance_id()
	var s: Dictionary = await _b13_kosullu(bolum, _b13_oyuncu_td(196), sayac)
	var yeni: Node = await _yeni_sahne_bekle(eski_id)
	var ok: bool = sayac[0] > 0 and yeni != null and _kayitlar().turlar.size() == 2
	var etiket := ""
	var klon_yeni := -1
	if yeni != null:
		etiket = yeni.bilgi.text
		klon_yeni = _klonlar(yeni).size()
		ok = ok and klon_yeni == 2 and etiket.contains("Tur 3") and etiket.contains("2/3")
	_kaydi("Bölüm 13 kilitlenme: kuyuda ölüm -> tur yeniden başlar, klonlar korunur", ok,
		"ölüm=%d, kayıtlı tur=%d, yeni sahnede klon=%d, etiket=\"%s\", kuyu ölüm konumu=%s" % [
			sayac[0], _kayitlar().turlar.size(), klon_yeni, etiket, _b13_olum_yeri(s)])
	# Klon LazerA'da ölürse yerinde donar (K2 hatalı kayıt): klon_oldu=true ve konumu sabit kalır.
	var k1_kisa: Array = [_b13_a(1, _b4_x_ge(262.0), 200), _b13_a(0, Callable(), 12)]
	var sk: Dictionary = await _b13_senaryo([], k1_kisa)
	var sb: Dictionary = await _b13_senaryo([sk["kayit"]], _b13_k2())   # canlı K2 LazerA'da ölür
	var sd: Dictionary = await _b13_senaryo([sk["kayit"], kay[1]], [_b13_a(0, Callable(), 150)])
	var ki: Array = sd["klon_izleri"][1]
	var sabit := true
	var donma := -1
	for f in range(1, ki.size()):
		if sd["klon_oldu"][1] and donma < 0 and f > 100 and ki[f] == ki[f - 1]:
			donma = f
	for f in range(maxi(donma, 1), ki.size()):
		if ki[f] != ki[donma if donma > 0 else 0]:
			sabit = false
	_kaydi("Bölüm 13 kilitlenme: LazerA'da ölen klon yerinde donar", sd["klon_oldu"][1] and ki[ki.size() - 1].x < 345.0,
		"B klonu öldü=%s, son konum=(%.0f,%.0f); canlı K2 ölüm=%d" % [sd["klon_oldu"][1], ki[ki.size() - 1].x, ki[ki.size() - 1].y, sb["oldu"]])
	_kayitlar().sifirla()


# ---------------------------------------------------------------- 9) determinizm
func _test_bolum13_determinizm() -> void:
	var kay: Array = await _b13_kayitlar()
	var s0: Dictionary = await _b13_senaryo(kay, _b13_oyuncu(_b13_salter_sola(), 10))
	var betik: Array = s0["kayit"]
	var ornek := func(b: Node) -> Dictionary: return _b13_ornekle(b)
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
	_kaydi("Bölüm 13: determinizm (100x çözüm)", sapmali == 0 and bitmeyen == 0 and s0["bitti_ham"],
		"%d çalıştırma x %d kare, sapmalı: %d, en büyük sapma: %.4f px, bitirmeyen çalıştırma: %d, kayıt turu bitti: %s" % [
			TEKRAR, referans["kare"], sapmali, maks_sapma, bitmeyen, s0["bitti_ham"]])
	_kayitlar().sifirla()
	paused = false



# ================================================================ BÖLÜM 14 (final: üç mıhlanmış tutucu)
# Taslak: docs/devir/bolum_14_taslak.md. C1 (raf, PlakaM) / C2 (çukur, PlakaP) / C3 (çıkıntı, PlakaU).
const BOLUM_14 := "res://scenes/bolumler/bolum_14.tscn"

var _b14_onbellek: Array = []   # [C1, C2, C3]


func _b14_ornekle(b: Node) -> Dictionary:
	var o: CharacterBody2D = b.get_node("Oyuncu")
	return {"pa": b.get_node("PlakaA").basili_mi(), "pm": b.get_node("PlakaM").basili_mi(),
		"pr": b.get_node("PlakaR").basili_mi(), "pp": b.get_node("PlakaP").basili_mi(),
		"pu": b.get_node("PlakaU").basili_mi(),
		"l1": b.get_node("Lazer1").acik_mi(), "l2": b.get_node("Lazer2").acik_mi(),
		"l3": b.get_node("Lazer3").acik_mi(),
		"ga": b.get_node("GecitA").position.y, "gr": b.get_node("GecitR").position.y,
		"kutu": b.get_node("Kutu").global_position, "zemin": o.is_on_floor()}


func _b14_kosullu(bolum: Node, adimlar: Array, sayac: Array) -> Dictionary:
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
			_girdi_uygula({"yon": a["yon"], "zipla": a["zipla"] and n == 0, "asagi": a.get("asagi", false)})
			iz.append(oyuncu.global_position)
			ozel.append(_b14_ornekle(bolum))
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
	var klon_son: Array = []
	for k in klonlar:
		klon_oldu.append(is_instance_valid(k) and k.oldu)
		klon_son.append(k.global_position if is_instance_valid(k) else Vector2.ZERO)
	for i in range(3):
		await physics_frame
	return {"kare": kare, "bitti": bitti_son and sayac[0] == 0, "bitti_ham": bitti_son, "oldu": sayac[0],
		"iz": iz, "ozel": ozel, "klon_izleri": klon_iz, "baslangic": baslangic, "tamam": tamam,
		"kayit": kayit, "klon_oldu": klon_oldu, "klon_son": klon_son}


func _b14_senaryo(kayitlar: Array, adimlar: Array, hazirlik := Callable()) -> Dictionary:
	_kayitlar().sifirla()
	for k in kayitlar:
		_kayitlar().tur_kaydet(k.duplicate(true))
	var bolum: Node = await _bolumu_yukle()
	if hazirlik.is_valid():
		hazirlik.call(bolum)
	var sayac := [0]
	bolum.get_node("Oyuncu").oyuncu_oldu.connect(func() -> void: sayac[0] += 1)
	var s: Dictionary = await _b14_kosullu(bolum, adimlar, sayac)
	paused = false
	return s


func _b14_p(ad: String) -> Callable:
	return func(b: Node) -> bool: return b.get_node(ad).basili_mi()


func _b14_kare_ge(n: int) -> Callable:
	return func(b: Node) -> bool: return b.get_node("Oyuncu").kare >= n


func _b14_laz_kapali(ad: String) -> Callable:
	return func(b: Node) -> bool: return not b.get_node(ad).acik_mi()


func _b14_kutu_x_ge(v: float) -> Callable:
	return func(b: Node) -> bool: return b.get_node("Kutu").global_position.x >= v


func _b14_zeminde() -> Callable:
	return func(b: Node) -> bool: return b.get_node("Oyuncu").is_on_floor()


func _b14_gecit_ust(ad: String, y: float) -> Callable:
	return func(b: Node) -> bool: return b.get_node(ad).position.y <= y


func _b14_son(s: Dictionary) -> Vector2:
	return s["iz"][s["iz"].size() - 1] if s["iz"].size() > 0 else Vector2.ZERO


func _b14_iz_yaz(s: Dictionary, adim := 5, bas := 0, son := -1) -> String:
	var t: Array = []
	var e: int = s["iz"].size() if son < 0 else mini(son, s["iz"].size())
	for f in range(bas, e, adim):
		var o: Dictionary = s["ozel"][f]
		t.append("%d:(%.0f,%.0f)%s%s%s%s%s L%s%s%s K%.0f,%.0f GA%.0f GR%.0f" % [f, s["iz"][f].x, s["iz"][f].y,
			"a" if o["pa"] else "", "m" if o["pm"] else "", "r" if o["pr"] else "", "p" if o["pp"] else "", "u" if o["pu"] else "",
			"1" if o["l1"] else "-", "2" if o["l2"] else "-", "3" if o["l3"] else "-",
			o["kutu"].x, o["kutu"].y, o["ga"], o["gr"]])
	return "\n".join(t)




## Taslak çözümünün turları (parametreli). C1: raf tutucusu (PlakaM).
## bekle: PlakaA'da başta bekleme; dur_g: PlakaA'dan ayrılınca (x>=140) duraksama; z1_x: Z1'e girilen x.
func _b14_t1(bekle := 36, z1_x := 318.0, dur_g := 0) -> Array:
	var d: Array = [_b13_a(0, Callable(), bekle)]
	if dur_g > 0:
		d += [_b13_a(1, _b4_x_ge(140.0), 100), _b13_a(0, Callable(), dur_g)]
	d += [_b13_a(1, _b4_x_ge(z1_x), 200), _b13_a(1, Callable(), 2),
		_b13_a(0, _b4_plakada("PlakaM"), 150), _b13_a(0, Callable(), 10)]
	return d


func _b14_l2_kapali_zemin() -> Callable:
	return func(b: Node) -> bool:
		return not b.get_node("Lazer2").acik_mi() and b.get_node("PlakaM").basili_mi() and _klonlar(b).size() > 0 \
			and _klonlar(b)[0].is_on_floor()


func _b14_bantta_zemin(x: float) -> Callable:
	return func(b: Node) -> bool: return b.get_node("Oyuncu").global_position.x >= x and b.get_node("Oyuncu").is_on_floor()


## Raf'taki klon PlakaM'de inip Lazer2 kapanana kadar bekle, Z1'den fırla, bant üstüne in, PlakaR'a (x<=sol_x) dön.
func _b14_ucus_ve_plakar(r_bekle := 60, sol_x := 475.0, ucus_kare := -1) -> Array:
	var d: Array = [_b13_a(1, _b4_x_ge(318.0), 200)]
	if ucus_kare >= 0:
		d.append(_b13_a(0, _b14_kare_ge(ucus_kare), 400))
	else:
		d.append(_b13_a(0, _b14_l2_kapali_zemin(), 200))
	d += [_b13_a(1, _b14_bantta_zemin(520.0), 120), _b13_a(-1, _b4_x_le(sol_x), 80)]
	if r_bekle > 0:
		d.append(_b13_a(0, Callable(), r_bekle))
	return d


## C2: kutuyla yarışı yapar (yaris_d: plakadan çıkınca duraksama), kutuyu kapaklara iter, Kapak1 üstünde S ile çukura iner.
func _b14_t2(s_x := 854.0, r_bekle := 60, sol_x := 475.0, yaris_d := 0, ucus_kare := -1) -> Array:
	var d: Array = _b14_ucus_ve_plakar(r_bekle, sol_x, ucus_kare)
	if yaris_d > 0:
		d += [_b13_a(1, _b4_x_ge(545.0), 60), _b13_a(0, Callable(), yaris_d)]
	d += [_b13_a(1, _b4_x_ge(s_x), 250), _b13_a(0, Callable(), 3), _b13_a(0, _b14_p("PlakaP"), 90, false, true),
		_b13_a(0, Callable(), 10)]
	return d


## C3: kutu geçitten geçtikten sonra yarışı yapar, kutuyu çıkıntı yüzüne iter, kutuya, çıkıntıya zıplar.
## f_bas: >=0 ise PlakaR'dan bu karede hareket eder (konvoy ölçümü), değilse kutu x>=kutu_x olunca.
func _b14_t3(f_bas := -1, kutu_x := 760.0, hedef_x := 979.0, z_n := 14, zipla_bekle := 14, yaris_d := 0, ucus_kare := -1) -> Array:
	var d: Array = _b14_ucus_ve_plakar(0, 475.0, ucus_kare)
	if f_bas >= 0:
		d += [_b13_a(0, _b14_kare_ge(f_bas), 400)]
	else:
		d += [_b13_a(0, _b14_kutu_x_ge(kutu_x), 300), _b13_a(0, _b14_gecit_ust("GecitR", 200.5), 100)]
	if yaris_d > 0:
		d += [_b13_a(1, _b4_x_ge(545.0), 60), _b13_a(0, Callable(), yaris_d)]
	d += [_b13_a(1, _b14_kutu_x_ge(hedef_x), 300), _b13_a(0, Callable(), 3),
		_b13_a(1, Callable(), z_n, true), _b13_a(0, _b14_zeminde(), 60),
		_b13_a(0, Callable(), zipla_bekle, true), _b13_a(1, _b14_p("PlakaU"), 60), _b13_a(0, Callable(), 10)]
	return d


## Oyuncu (son tur): Lazer1 kapanınca (C2 çukurda) yarışı yapar, kapağın üstünden yürür, kutu+çıkıntı ile kapıya gider.
func _b14_oyuncu(z_n := 14, ucus_kare := -1, bekle_laz := "Lazer1") -> Array:
	var d: Array = [_b13_a(1, _b4_x_ge(318.0), 200)]
	if ucus_kare >= 0:
		d.append(_b13_a(0, _b14_kare_ge(ucus_kare), 400))
	else:
		d.append(_b13_a(0, func(b: Node) -> bool: return not b.get_node("Lazer2").acik_mi() and _klonlar(b).size() > 0 and _klonlar(b)[0].is_on_floor(), 250))
	d += [_b13_a(1, _b14_bantta_zemin(520.0), 120), _b13_a(-1, _b4_x_le(475.0), 80)]
	if bekle_laz != "":
		d.append(_b13_a(0, _b14_laz_kapali(bekle_laz), 400))
	d += [_b13_a(0, _b14_gecit_ust("GecitR", 200.5), 150),
		_b13_a(1, _b4_x_ge(944.0), 400),
		_b13_a(1, Callable(), z_n, true), _b13_a(0, _b14_zeminde(), 60),
		_b13_a(0, Callable(), 14, true), _b13_a(1, _b4_bitti_k(), 120)]
	return d


func _b14_hepsi_kapali() -> Callable:
	return func(b: Node) -> bool:
		return not b.get_node("Lazer1").acik_mi() and not b.get_node("Lazer2").acik_mi() and not b.get_node("Lazer3").acik_mi()


## [C1, C2, C3] kayıtları (bir kez, gerçek dünyada klonlarla üretilir).
func _b14_kayitlar() -> Array:
	if _b14_onbellek.is_empty():
		var s1: Dictionary = await _b14_senaryo([], _b14_t1())
		var s2: Dictionary = await _b14_senaryo([s1["kayit"]], _b14_t2())
		var s3: Dictionary = await _b14_senaryo([s1["kayit"], s2["kayit"]], _b14_t3())
		_b14_onbellek = [s1["kayit"], s2["kayit"], s3["kayit"]]
	return _b14_onbellek


## Kaydın klon olarak oynatıldığındaki son durumu (oyuncu boşta bekler): lazer/plaka durumları.
func _b14_son_durum(kayitlar: Array, kare := 450) -> Dictionary:
	var r: Dictionary = await _b14_senaryo(kayitlar, [_b13_a(0, Callable(), kare)])
	var o: Dictionary = r["ozel"][r["ozel"].size() - 1]
	o["klon_oldu"] = r["klon_oldu"]
	o["klon_son"] = r["klon_izleri"][r["klon_izleri"].size() - 1].back() if not r["klon_izleri"].is_empty() else Vector2.ZERO
	o["klon_izleri"] = r["klon_izleri"]
	o["ozel"] = r["ozel"]
	return o


func _b14_ok1(d: Dictionary) -> bool:
	return not d["l2"] and d["pm"] and not d["klon_oldu"][0]


func _b14_ok2(d: Dictionary) -> bool:
	return not d["l1"] and d["pp"] and not d["klon_oldu"][1]


func _b14_ok3(d: Dictionary) -> bool:
	return not d["l3"] and d["pu"] and not d["klon_oldu"][2]


func _b14_yerlestir(oyuncu: Vector2, kutu := Vector2(-1.0, -1.0)) -> Callable:
	return func(b: Node) -> void:
		b.get_node("Oyuncu").global_position = oyuncu
		if kutu.x >= 0.0:
			b.get_node("Kutu").global_position = kutu


## Oyuncu izinden: en büyük/küçük x, en küçük ayak y (merkez y + 24), en büyük y.
func _b14_olc(s: Dictionary) -> Dictionary:
	var xmax := -1.0e9
	var xmin := 1.0e9
	var ayak := 1.0e9
	var ymax := -1.0e9
	for p in s["iz"]:
		xmax = maxf(xmax, p.x)
		xmin = minf(xmin, p.x)
		ayak = minf(ayak, p.y + 24.0)
		ymax = maxf(ymax, p.y)
	return {"xmax": xmax, "xmin": xmin, "ayak": ayak, "ymax": ymax}


func _b14_spam(yon: float, n := 8) -> Array:
	return _b8_zipla_dizisi(n, yon, 25)


## Bir rolün kaydını, önceki klonlar varken gerçek dünyada üretir; ölüm turu yeniden başlatır (kayıt atılır: boş kayıt).
func _b14_rol(ad: String, onceki: Array, kor := false) -> Array:
	var adim: Array = []
	if ad == "C1":
		adim = _b14_t1()
	elif ad == "C2":
		adim = _b14_t2(854.0, 60, 475.0, 0, 150 if kor else -1)
	else:
		adim = _b14_t3(-1, 760.0, 979.0, 14, 14, 0, 150 if kor else -1)
	var s: Dictionary = await _b14_senaryo(onceki, adim)
	if s["oldu"] > 0:
		return []
	return s["kayit"]


## Bir klon kümesiyle oyuncunun denediği stratejilerden biri bölümü bitirir mi.
func _b14_bitirir_mi(klonlar: Array) -> bool:
	var stratejiler: Array = [_b14_oyuncu(), _b14_oyuncu(14, 150, ""), _b14_oyuncu(14, -1, "Lazer3"),
		[_b13_a(1, Callable(), 400)]]
	for st in stratejiler:
		var s: Dictionary = await _b14_senaryo(klonlar, st)
		if s["bitti_ham"]:
			return true
	return false


func _b14_calistir() -> void:
	await _test_bolum14_cozum()
	await _test_bolum14_basarisizlik()
	await _test_bolum14_atlanamaz()
	await _test_bolum14_kisayol()
	await _test_bolum14_hassasiyet()
	await _test_bolum14_dikis()
	await _test_bolum14_klon_siniri()
	await _test_bolum14_kilitlenme()
	await _test_bolum14_determinizm()


# ---------------------------------------------------------------- 1) çözüm (gerçek R/girdi yolu)
func _test_bolum14_cozum() -> void:
	_kayitlar().sifirla()
	var bolum: Node = await _bolumu_yukle()
	var kareler: Array = []
	var olumsuz := ""
	var turlar: Array = [_b14_t1(), _b14_t2(), _b14_t3()]
	for i in range(3):
		var sayac := [0]
		bolum.get_node("Oyuncu").oyuncu_oldu.connect(func() -> void: sayac[0] += 1)
		var klon_once: int = _klonlar(bolum).size()
		var s: Dictionary = await _b14_kosullu(bolum, turlar[i], sayac)
		kareler.append(s["kare"])
		if s["tamam"].has(false) or s["oldu"] > 0 or s["kare"] > 600 or klon_once != i:
			olumsuz += " tur%d adım karşılanmadı %s oldu=%d kare=%d klon=%d;" % [i + 1, str(s["tamam"]), s["oldu"], s["kare"], klon_once]
		var eski_id := bolum.get_instance_id()
		await _r_bas()
		bolum = await _yeni_sahne_bekle(eski_id)
		if bolum == null:
			_kaydi("Bölüm 14 çözümü (4 tur, 3 klon, gerçek R/girdi yolu)", false, "tur %d sonrası sahne yüklenmedi;%s" % [i + 1, olumsuz])
			return
	var klon_basta: int = _klonlar(bolum).size()
	var etiket: String = bolum.bilgi.text
	var sayac4 := [0]
	bolum.get_node("Oyuncu").oyuncu_oldu.connect(func() -> void: sayac4[0] += 1)
	var s4: Dictionary = await _b14_kosullu(bolum, _b14_oyuncu(), sayac4)
	var gecti: bool = s4["bitti"] and klon_basta == 3 and _kayitlar().turlar.size() == 3 \
		and etiket.contains("Klon: 3/3") and olumsuz == "" and s4["kare"] <= 600 and s4["oldu"] == 0 \
		and kareler[0] <= 600 and kareler[1] <= 600 and kareler[2] <= 600 and not s4["tamam"].has(false)
	_kaydi("Bölüm 14 çözümü (4 tur, 3 klon, gerçek R/girdi yolu)", gecti,
		"bitti: %s, tur kareleri: %s + %d (%.2f sn), klon: %d, kayıtlı tur: %d, ölüm: %d, etiket: \"%s\"%s" % [
			s4["bitti"], str(kareler), s4["kare"], s4["kare"] / 60.0, klon_basta, _kayitlar().turlar.size(),
			s4["oldu"], etiket, olumsuz])
	_kayitlar().sifirla()
	paused = false


# ---------------------------------------------------------------- 2) başarısızlık senaryoları
func _test_bolum14_basarisizlik() -> void:
	var kay: Array = await _b14_kayitlar()
	var c1: Array = kay[0]
	var c2: Array = kay[1]

	# 1) klonsuz: Lazer2'de ölür.
	var s1: Dictionary = await _b14_senaryo([], [_b13_a(0, Callable(), 36), _b13_a(1, Callable(), 250)])
	var p1: Vector2 = _b14_son(s1)
	_kaydi("Bölüm 14 başarısızlık 1: klonsuz -> Lazer2'de ölür", s1["oldu"] > 0 and not s1["bitti_ham"] and p1.x > 420.0 and p1.x < 460.0,
		"36 kare bekleyip GecitA'dan geçer, Z1 ile fırlar; ölüm=%d, son konum (%.0f,%.0f) (ışın x 447..453, gövde girişi 433)" % [s1["oldu"], p1.x, p1.y])

	# 2) yalnız C1: Lazer1'de ölür.
	var s2: Dictionary = await _b14_senaryo([c1], _b14_oyuncu())
	var p2: Vector2 = _b14_son(s2)
	_kaydi("Bölüm 14 başarısızlık 2: yalnız C1 -> Lazer1'de ölür", s2["oldu"] > 0 and not s2["bitti_ham"] and p2.x > 880.0 and p2.x < 925.0,
		"ölüm=%d, son konum (%.0f,%.0f) (ışın x 912..918, gövde girişi 898)" % [s2["oldu"], p2.x, p2.y])

	# 3) C1 + C2: Lazer3'te ölür.
	var s3: Dictionary = await _b14_senaryo([c1, c2], _b14_oyuncu())
	var p3: Vector2 = _b14_son(s3)
	_kaydi("Bölüm 14 başarısızlık 3: C1 + C2 (C3 yok) -> Lazer3'te ölür", s3["oldu"] > 0 and not s3["bitti_ham"] and p3.x > 1050.0 and p3.y < 300.0,
		"ölüm=%d, son konum (%.0f,%.0f) (ışın x 1087..1093, çıkıntıda)" % [s3["oldu"], p3.x, p3.y])

	# 4) C1 PlakaA'da erken ayrılır (<32 kare bekler): GecitA'ya girerken açıklık < 48, Z1'e varamaz.
	var ayr4: Array = []
	var ok4 := true
	for b in [0, 10, 20, 28]:
		var s: Dictionary = await _b14_senaryo([], _b14_t1(b))
		var d: Dictionary = await _b14_son_durum([s["kayit"]], 250)
		var olc: Dictionary = _b14_olc(s)
		ok4 = ok4 and not _b14_ok1(d) and olc["xmax"] < 262.0
		ayr4.append("bekle=%d: en büyük x=%.0f, Lazer2 kapanır=%s" % [b, olc["xmax"], str(not d["l2"])])
	_kaydi("Bölüm 14 başarısızlık 4: C1 başta < 32 kare bekler -> GecitA'dan geçemez", ok4, "; ".join(ayr4))

	# 5) C2 PlakaR'da kısa basılı kalır: GecitR açıklığı yetmez, kutu ve C2 geçemez.
	var ayr5: Array = []
	var ok5 := true
	for rb in [0, 10]:
		var s: Dictionary = await _b14_senaryo([c1], _b14_t2(854.0, rb))
		var d: Dictionary = await _b14_son_durum([c1, s["kayit"]], 450)
		var olc: Dictionary = _b14_olc(s)
		ok5 = ok5 and not _b14_ok2(d) and olc["xmax"] < 700.0
		ayr5.append("r_bekle=%d: en büyük x=%.0f, PlakaP tutulur=%s" % [rb, olc["xmax"], str(d["pp"])])
	_kaydi("Bölüm 14 başarısızlık 5: C2 PlakaR'da kısa basılı kalır -> geçit kapanır, kutu/C2 geçemez", ok5, "; ".join(ayr5))

	# 6) C2 yanlış kapak konumunda S basar (Z2 sensörü ya da Kapak2 sınırı).
	var ayr6: Array = []
	var ok6 := true
	for x in [800.0, 830.0, 890.0]:
		var s: Dictionary = await _b14_senaryo([c1], _b14_t2(x))
		var d: Dictionary = await _b14_son_durum([c1, s["kayit"]], 450)
		ok6 = ok6 and not _b14_ok2(d)
		ayr6.append("S x>=%.0f: Lazer1 kapanır=%s" % [x, str(not d["l1"])])
	_kaydi("Bölüm 14 başarısızlık 6: C2 yanlış konumda S basar -> PlakaP tutulmaz", ok6, "; ".join(ayr6))

	# 7) C3, C2 çukura inmeden Lazer1'e varır (konvoy +0): Lazer1'de ölür.
	var f0: int = (await _b14_senaryo([c1], _b14_t2()))["baslangic"][5]
	var s7: Dictionary = await _b14_senaryo([c1, c2], _b14_t3(f0))
	var p7: Vector2 = _b14_son(s7)
	_kaydi("Bölüm 14 başarısızlık 7: C3 C2 ile aynı karede yürür (konvoy +0) -> Lazer1 açık, ölür", s7["oldu"] > 0 and p7.x > 880.0 and p7.x < 925.0,
		"C3 yürüyüşü C2 ile aynı karede (kare %d); ölüm=%d, son (%.0f,%.0f)" % [f0, s7["oldu"], p7.x, p7.y])

	# 8) Oyuncu Lazer2'ye çok erken fırlar.
	var s8: Dictionary = await _b14_senaryo([c1], _b14_oyuncu(14, 90))
	var p8: Vector2 = _b14_son(s8)
	_kaydi("Bölüm 14 başarısızlık 8: oyuncu Z1'den kare 90'da fırlar (Lazer2 henüz açık) -> ölür", s8["oldu"] > 0 and p8.x > 420.0 and p8.x < 480.0 and not s8["bitti_ham"],
		"ölüm=%d, son (%.0f,%.0f)" % [s8["oldu"], p8.x, p8.y])

	# 9) C3 çıkıntıya çıkmaz (yalnız kutuyu iter, PlakaU boş): oyuncu Lazer3'te ölür.
	var c3_yarim: Array = (await _b14_senaryo([c1, c2], _b14_t3().slice(0, 9)))["kayit"]
	var s9: Dictionary = await _b14_senaryo([c1, c2, c3_yarim], _b14_oyuncu(14, -1, "Lazer1"))
	var p9: Vector2 = _b14_son(s9)
	_kaydi("Bölüm 14 başarısızlık 9: C3 çıkıntıya çıkmaz (PlakaU boş) -> oyuncu Lazer3'te ölür", s9["oldu"] > 0 and not s9["bitti_ham"] and p9.x > 1050.0,
		"ölüm=%d, son (%.0f,%.0f)" % [s9["oldu"], p9.x, p9.y])

	# 10) C2 yarışta duraksar (PlakaR'dan çıkınca 6 kare): geçit kutuyu ve C2'yi yakalar.
	var s10: Dictionary = await _b14_senaryo([c1], _b14_t2(854.0, 60, 475.0, 6))
	var d10: Dictionary = await _b14_son_durum([c1, s10["kayit"]], 450)
	var o10: Dictionary = _b14_olc(s10)
	_kaydi("Bölüm 14 başarısızlık 10: C2 yarışta 6 kare duraksar -> geçit kapanır, PlakaP tutulmaz", not _b14_ok2(d10) and o10["xmax"] < 700.0,
		"en büyük x=%.0f (geçit sol yüzü 700), PlakaP tutulur=%s" % [o10["xmax"], str(d10["pp"])])

	# 11) C3 kutuyu çıkıntı yüzüne yaklaştırmaz (hedef x=880): çıkıntıya çıkamaz.
	var s11: Dictionary = await _b14_senaryo([c1, c2], _b14_t3(-1, 760.0, 880.0))
	var d11: Dictionary = await _b14_son_durum([c1, c2, s11["kayit"]], 560)
	_kaydi("Bölüm 14 başarısızlık 11: C3 kutuyu uzakta bırakır (x=880) -> çıkıntıya çıkamaz", not _b14_ok3(d11),
		"PlakaU tutulur=%s, Lazer3 açık=%s" % [str(d11["pu"]), str(d11["l3"])])
	_kayitlar().sifirla()
	paused = false


# ---------------------------------------------------------------- 3) atlanamazlık
func _test_bolum14_atlanamaz() -> void:
	var kay: Array = await _b14_kayitlar()
	var c1: Array = kay[0]
	var c2: Array = kay[1]
	var ayr: Array = []
	var hepsi := true

	# GecitA kapalı (PlakaA boş): sağ + zıplama ile geçilemez (üst 400, 200 px > 100,9).
	var sa: Dictionary = await _b14_senaryo([], _b14_spam(1.0, 10), _b14_yerlestir(Vector2(200, 576)))
	var oa: Dictionary = _b14_olc(sa)
	var ok: bool = oa["xmax"] <= 242.0 and oa["ayak"] > 480.0
	hepsi = hepsi and ok
	ayr.append("GecitA kapalı: en büyük x=%.0f (sol yüz 255-14=241), en yüksek ayak y=%.0f (kapak üstü 400)" % [oa["xmax"], oa["ayak"]])

	# GecitR kapalı (PlakaR boş): bant üstünden sağ + zıplama ile geçilemez (kutu basamak olsa bile).
	var sr: Dictionary = await _b14_senaryo([], _b14_spam(1.0, 12), _b14_yerlestir(Vector2(560, 376)))
	var orr: Dictionary = _b14_olc(sr)
	ok = orr["xmax"] <= 687.0 and not sr["bitti_ham"]
	hepsi = hepsi and ok
	ayr.append("GecitR kapalı: en büyük x=%.0f (sol yüz 700-14=686), ayak y min=%.0f (geçit alt kenarı 400, kutu üstü 360)" % [orr["xmax"], orr["ayak"]])

	# Z1 uçuşu (C1 var): sağ basılı + zıplama spam; GecitR kapalı kalır, x<=686.
	var sz: Dictionary = await _b14_senaryo([c1], [_b13_a(1, _b4_x_ge(318.0), 200), _b13_a(0, _b14_l2_kapali_zemin(), 200)] + _b14_spam(1.0, 14))
	var oz: Dictionary = _b14_olc(sz)
	ok = oz["xmax"] <= 687.0 and not sz["bitti_ham"]
	hepsi = hepsi and ok
	ayr.append("Z1 uçuşu + sağ/zıpla spam: en büyük x=%.0f (<=686), bitti=%s" % [oz["xmax"], sz["bitti_ham"]])
	var szu: Dictionary = await _b14_senaryo([c1], [_b13_a(1, _b4_x_ge(318.0), 200), _b13_a(0, _b14_l2_kapali_zemin(), 200), _b13_a(1, Callable(), 60)])
	var ozu: Dictionary = _b14_olc(szu)
	ok = ozu["ayak"] > 340.0 and ozu["ayak"] < 365.0
	hepsi = hepsi and ok
	ayr.append("Z1 uçuş tepesi ayak y=%.1f (taslak 353; çıkıntı yüzeyi 270: %.1f px kısa; TavanD alt 200: baş y=%.1f)" % [ozu["ayak"], ozu["ayak"] - 270.0, ozu["ayak"] - 48.0])

	# Lazerleri zıplayarak aşma: açıkken ölür, x ışının solunda kalır.
	for k in [["Lazer2", Vector2(405, 376), 447.0], ["Lazer1", Vector2(886, 376), 912.0], ["Lazer3", Vector2(1030, 246), 1087.0]]:
		var sl: Dictionary = await _b14_senaryo([], _b14_spam(1.0, 8), _b14_yerlestir(k[1]))
		var ol: Dictionary = _b14_olc(sl)
		ok = sl["oldu"] > 0 and ol["xmax"] < k[2] + 9.0
		hepsi = hepsi and ok
		ayr.append("%s zıplayarak: ölüm=%d, en büyük x=%.0f (ışın sol kenarı %.0f)" % [k[0], sl["oldu"], ol["xmax"], k[2]])

	# Çukur duvarı (UR sol yüz x=920): Lazer1 açık ve kapalı, çukur içinden sağa sağ+zıpla ile çıkış yok.
	var scn: Dictionary = await _b14_senaryo([], _b14_spam(1.0, 8), _b14_yerlestir(Vector2(880, 576)))
	var oc: Dictionary = _b14_olc(scn)
	var scn2: Dictionary = await _b14_senaryo([c1, c2], _b14_spam(1.0, 8), _b14_yerlestir(Vector2(880, 576)))
	var oc2: Dictionary = _b14_olc(scn2)
	ok = oc["xmax"] <= 907.0 and oc2["xmax"] <= 907.0
	hepsi = hepsi and ok
	ayr.append("çukur duvarı: Lazer1 açık x=%.0f ölüm=%d, kapalı (C2 var) x=%.0f ölüm=%d (sol yüz 920-14=906)" % [oc["xmax"], scn["oldu"], oc2["xmax"], scn2["oldu"]])

	# Kutu yokken çıkıntı: güvertede sağ+zıpla spam (kutu başlangıçta x=675'te): çıkıntıya (x>1000, ayak<=270) çıkılmaz.
	var sk: Dictionary = await _b14_senaryo([], _b14_spam(1.0, 8), _b14_yerlestir(Vector2(940, 376), Vector2(675, 380)))
	var ok_k: Dictionary = _b14_olc(sk)
	ok = ok_k["xmax"] <= 987.0 and ok_k["ayak"] > 270.0
	hepsi = hepsi and ok
	ayr.append("çıkıntı kutusuz: en büyük x=%.0f (<=986), en yüksek ayak y=%.1f (>270; çıkıntı 130 px > 100,9, kıtlık %.1f px)" % [ok_k["xmax"], ok_k["ayak"], ok_k["ayak"] - 270.0])

	# Kutu basamağı: kutu çıkıntı yüzünde (x=980): kutu üstünden çıkıntıya çıkılır (tek yol); ayak payı ölçülür.
	var sb: Dictionary = await _b14_senaryo([], [_b13_a(1, Callable(), 14, true), _b13_a(0, _b14_zeminde(), 60),
		_b13_a(0, Callable(), 14, true), _b13_a(1, Callable(), 40)], _b14_yerlestir(Vector2(946, 376), Vector2(980, 380)))
	var ob: Dictionary = _b14_olc(sb)
	var f_son: Vector2 = _b14_son(sb)
	ok = f_son.x > 1000.0 and f_son.y < 260.0 and ob["ayak"] < 270.0
	hepsi = hepsi and ok
	ayr.append("kutu basamağı: çıkıntıya çıkar (son=(%.0f,%.0f)), kutu üstü zıplama tepesi ayak y=%.1f (çıkıntı yüzeyi 270, pay %.1f px)" % [f_son.x, f_son.y, ob["ayak"], 270.0 - ob["ayak"]])

	# Z2 uçuşu (çukur tabanı): Lazer1 açıkken ölür; C2 çukurdayken (Lazer1 kapalı) çıkıntıya yetmez.
	var s_z2: Dictionary = await _b14_senaryo([], [_b13_a(1, Callable(), 80)], _b14_yerlestir(Vector2(790, 576)))
	var oz2: Dictionary = _b14_olc(s_z2)
	ok = s_z2["oldu"] > 0 and oz2["xmax"] <= 907.0
	hepsi = hepsi and ok
	ayr.append("Z2 uçuşu (Lazer1 açık): ölüm=%d, en büyük x=%.0f (sol yüz 906; K=20'de güverte seviyesinde gövde x 892..920 ışında)" % [s_z2["oldu"], oz2["xmax"]])
	var s_z2b: Dictionary = await _b14_senaryo([c1, c2], [_b13_a(0, _b14_kare_ge(420), 500), _b13_a(-1, _b4_x_le(800.0), 60),
		_b13_a(1, Callable(), 90)], _b14_yerlestir(Vector2(850, 576)))
	var oz2b: Dictionary = _b14_olc(s_z2b)
	ok = oz2b["ayak"] > 340.0 and not s_z2b["bitti_ham"]
	hepsi = hepsi and ok
	ayr.append("Z2 uçuşu (Lazer1 kapalı, C2 çukurda): ayak y min=%.1f (çıkıntı 270), en büyük x=%.0f, ölüm=%d, bitti=%s" % [oz2b["ayak"], oz2b["xmax"], s_z2b["oldu"], s_z2b["bitti_ham"]])

	_kaydi("Bölüm 14 atlanamazlık hesapları (geçitler, lazerler, çukur duvarı, Z1/Z2 uçuşları, kutu basamağı)", hepsi, "; ".join(ayr))
	_kayitlar().sifirla()
	paused = false


# ---------------------------------------------------------------- 4) kısayol taraması
func _test_bolum14_kisayol() -> void:
	var kay: Array = await _b14_kayitlar()
	var c1: Array = kay[0]
	var c2: Array = kay[1]
	var c3: Array = kay[2]
	var ayr: Array = []
	var hepsi := true

	# --- 1: klonsuz (çeşitli girdiler)
	var kos: Array = [
		["sag sürekli", [_b13_a(1, Callable(), 300)]],
		["bekle 36 + sag sürekli (GecitA geçilir)", [_b13_a(0, Callable(), 36), _b13_a(1, Callable(), 300)]],
		["bekle 36 + sağ+zıpla", [_b13_a(0, Callable(), 36)] + _b14_spam(1.0, 12)],
		["sağ+zıpla", _b14_spam(1.0, 12)],
		["Z1 uçuşu", [_b13_a(1, _b4_x_ge(318.0), 200), _b13_a(1, Callable(), 150)]]]
	for k in kos:
		var s: Dictionary = await _b14_senaryo([], k[1])
		hepsi = hepsi and not s["bitti_ham"]
		ayr.append("1 klonsuz/%s: bitti=%s" % [k[0], s["bitti_ham"]])

	# --- 2: tek klon (her rol), --- 3: iki klon (tüm sıralar); roller önceki klonlarla gerçek dünyada kaydedilir
	var roller: Array = ["C1", "C2", "C3"]
	var bitenler: Array = []
	var toplam := 0
	for kor in [false, true]:
		for a in roller:
			var ka: Array = await _b14_rol(a, [], kor)
			toplam += 1
			if await _b14_bitirir_mi([ka]):
				bitenler.append("%s%s" % [a, "(kör)" if kor else ""])
			for b in roller:
				var kb: Array = await _b14_rol(b, [ka], kor)
				toplam += 1
				if await _b14_bitirir_mi([ka, kb]):
					bitenler.append("%s+%s%s" % [a, b, "(kör)" if kor else ""])
	hepsi = hepsi and bitenler.is_empty()
	ayr.append("2-3 tek/iki klon (3 rol x tüm sıralar x koşullu/kör zamanlama, her biri 4 oyuncu stratejisi): %d küme, bitiren=%s" % [toplam, str(bitenler)])

	# --- 3b: taslak kayıtlarıyla tüm alt kümeler ve sıralar
	var kume: Array = [["C1", [c1]], ["C2", [c2]], ["C3", [c3]], ["C1+C2", [c1, c2]], ["C1+C3", [c1, c3]], ["C2+C3", [c2, c3]],
		["C2+C1", [c2, c1]], ["C3+C1", [c3, c1]], ["C3+C2", [c3, c2]], ["C1+C1", [c1, c1]], ["C2+C2", [c2, c2]], ["C3+C3", [c3, c3]]]
	var bitenler2: Array = []
	for k in kume:
		if await _b14_bitirir_mi(k[1]):
			bitenler2.append(k[0])
	hepsi = hepsi and bitenler2.is_empty()
	ayr.append("3b tek/iki klon, taslak kayıtları (12 küme, 4 strateji): bitiren=%s" % str(bitenler2))

	# --- min klon 3: üç tutucu aynı anda üç ayrı plakada ve çözüm 3 klonla biter
	var tam: Dictionary = await _b14_senaryo(kay, _b14_oyuncu())
	var f3 := -1
	for f in range(tam["ozel"].size()):
		var o: Dictionary = tam["ozel"][f]
		if o["pm"] and o["pp"] and o["pu"] and f3 < 0:
			f3 = f
	var f_l3 := -1
	for f in range(tam["iz"].size()):
		if tam["iz"][f].x >= 1074.0 and f_l3 < 0:
			f_l3 = f
	var ok3: bool = tam["bitti_ham"] and f3 >= 0 and f_l3 > f3
	hepsi = hepsi and ok3
	ayr.append("min klon 3: bitti=%s, PlakaM+PlakaP+PlakaU birlikte basılı ilk kare=%d, oyuncu Lazer3 ışınına (x>=1074) kare %d'de varır" % [tam["bitti_ham"], f3, f_l3])

	# --- Kutuyla plaka tutma: kutu PlakaM'ye sola itilir (Cr = PlakaR tutucusu geçidi açık tutar).
	var cr: Array = (await _b14_senaryo([c1], _b14_ucus_ve_plakar(400, 475.0)))["kayit"]
	var adim: Array = _b14_kutu_sola_adim(330.0)
	var sk: Dictionary = await _b14_senaryo([c1, cr], adim)
	var kutu_son: Vector2 = sk["ozel"][sk["ozel"].size() - 1]["kutu"]
	var kutu_m: bool = kutu_son.x > 300.0 and kutu_son.x < 360.0 and kutu_son.y > 370.0 and kutu_son.y < 390.0
	var devam: Dictionary = await _b14_senaryo([c1, cr, sk["kayit"]], _b14_oyuncu(14, -1, ""))
	hepsi = hepsi and kutu_m and not devam["bitti_ham"]
	ayr.append("kutuyla plaka tutma: kutu PlakaM üstüne sola itilebilir (kutu=(%.0f,%.0f), geçidi Cr açık tutar); kutu bu halde çıkıntı basamağı olamaz, bölüm bitmez (bitti=%s)" % [
		kutu_son.x, kutu_son.y, devam["bitti_ham"]])

	# --- Zıplatıcı + kutu: kutu Raf'ın solundan düşürülür; Z1 bölgesine (x 340..400) geri itilemez
	var sk2: Dictionary = await _b14_senaryo([c1, cr], _b14_kutu_sola_adim(200.0))
	var kutu2: Vector2 = sk2["ozel"][sk2["ozel"].size() - 1]["kutu"]
	hepsi = hepsi and kutu2.x < 280.0
	ayr.append("zıplatıcı+kutu: kutu Raf'tan düşürülürse son konum=(%.0f,%.0f) (Z1 bölgesi x 340..400 dışı, GecitA x 255..275'in solu; geri itici gerekir)" % [kutu2.x, kutu2.y])
	var sz2: Dictionary = await _b14_senaryo([], [_b13_a(0, Callable(), 30)], _b14_yerlestir(Vector2(60, 576), Vector2(820, 380)))
	var kz2: Vector2 = sz2["ozel"][sz2["ozel"].size() - 1]["kutu"]
	hepsi = hepsi and absf(kz2.y - 380.0) < 3.0
	ayr.append("kutu Kapak1 üstünde: y=%.1f (Z2 sensörü çukur tabanında, tetiklenmez)" % kz2.y)

	# --- Bant dalgalanması: oyuncu PlakaR üstünde dalgalanıp yürürse GecitR'de takılır
	var s_d: Dictionary = await _b14_senaryo([c1], [_b13_a(1, _b4_x_ge(318.0), 200), _b13_a(0, _b14_l2_kapali_zemin(), 200),
		_b13_a(1, _b14_bantta_zemin(520.0), 120), _b13_a(-1, Callable(), 8), _b13_a(1, Callable(), 8), _b13_a(-1, Callable(), 8),
		_b13_a(1, Callable(), 8), _b13_a(1, _b4_x_ge(690.0), 100)])
	var od: Dictionary = _b14_olc(s_d)
	hepsi = hepsi and not s_d["bitti_ham"] and od["xmax"] < 700.0
	ayr.append("bant dalgalanması: GecitR'de takılır (en büyük x=%.0f, bitti=%s)" % [od["xmax"], s_d["bitti_ham"]])

	# --- Geçit altı park / röle (GecitR altında park eden klon): yarışı kolaylaştırır, klon sayısını düşürmez
	var c_p: Array = (await _b14_senaryo([c1], [_b13_a(1, _b4_x_ge(318.0), 200), _b13_a(0, _b14_l2_kapali_zemin(), 200),
		_b13_a(1, _b14_bantta_zemin(520.0), 120), _b13_a(-1, _b4_x_le(475.0), 80), _b13_a(0, Callable(), 60),
		_b13_a(1, _b4_x_ge(700.0), 120), _b13_a(0, Callable(), 10)]))["kayit"]
	var s_pk: Dictionary = await _b14_senaryo([c1, c_p], _b14_t2(854.0, 60, 475.0, 20))
	var d_pk: Dictionary = await _b14_son_durum([c1, c_p, s_pk["kayit"]], 500)
	var o_pk: Dictionary = _b14_olc(s_pk)
	var park_bitti: bool = await _b14_bitirir_mi([c1, c_p])
	hepsi = hepsi and not park_bitti
	ayr.append("geçit altı park: park klonu varken C2 yarış duraksama=20 kare -> C2 PlakaP tutar=%s (en büyük x=%.0f); C1+park ile bölüm biter=%s (klon sayısını düşürmez)" % [
		str(_b14_ok2(d_pk)), o_pk["xmax"], park_bitti])

	# --- S ile iniş yolları
	var ayr_s: Array = []
	for k in [["Raf x=330", Vector2(330, 376)], ["Raf x=290", Vector2(290, 376)], ["Kapak1 x=800", Vector2(800, 376)],
			["Kapak1 x=850", Vector2(850, 376)], ["Kapak2 x=895", Vector2(895, 376)], ["Kapak2 x=940", Vector2(940, 376)],
			["Kapak2 x=970", Vector2(970, 376)]]:
		var ss: Dictionary = await _b14_senaryo([], [_b13_a(0, Callable(), 3, false, true), _b13_a(0, Callable(), 50)],
			_b14_yerlestir(k[1], Vector2(675, 380)))
		var pn: Vector2 = _b14_son(ss)
		ayr_s.append("%s: son (%.0f,%.0f)" % [k[0], pn.x, pn.y])
	ayr.append("S ile iniş (taslak: yalnız Raf ve iki kapak): " + ", ".join(ayr_s))

	_kaydi("Bölüm 14 kısayol taraması (klonsuz/1/2 klon tüm sıralar, min klon 3, kutu, plaka tutma, zıplatıcı+kutu, bant, park/röle, S)", hepsi, " || ".join(ayr))
	_kayitlar().sifirla()
	paused = false


## Oyuncu: Z1'den fırlar, bant üstüne iner, Cr geçidi açık tutarken kutunun üstünden aşar, kutuyu sola itip x<=hedef olunca durur.
func _b14_kutu_sola_adim(hedef: float) -> Array:
	return [_b13_a(1, _b4_x_ge(318.0), 200),
		_b13_a(0, func(b: Node) -> bool: return not b.get_node("Lazer2").acik_mi() and _klonlar(b)[0].is_on_floor(), 250),
		_b13_a(1, _b14_bantta_zemin(520.0), 120), _b13_a(0, _b14_p("PlakaR"), 20),
		_b13_a(1, func(b: Node) -> bool: return b.get_node("Oyuncu").global_position.x >= 628.0, 200),
		_b13_a(1, Callable(), 12, true), _b13_a(1, func(b: Node) -> bool: return b.get_node("Oyuncu").global_position.x >= 735.0, 100),
		_b13_a(0, _b14_zeminde(), 60),
		_b13_a(-1, func(b: Node) -> bool: return b.get_node("Kutu").global_position.x <= hedef, 600),
		_b13_a(0, Callable(), 40)]



# ---------------------------------------------------------------- 5) hassasiyet (pencere ölçümleri)
func _b14_ok_yaz(degerler: Array, oklar: Array) -> String:
	return _b13_aralik_yaz(degerler, oklar)


func _test_bolum14_hassasiyet() -> void:
	var kay: Array = await _b14_kayitlar()
	var c1: Array = kay[0]
	var c2: Array = kay[1]
	var ayr: Array = []
	var hepsi := true

	# W1: GecitA yarışı. (a) PlakaA'da başta bekleme, (b) plakadan ayrılınca duraksama.
	var vs: Array = []
	var os: Array = []
	for b in range(0, 64, 4):
		var s: Dictionary = await _b14_senaryo([], _b14_t1(b))
		var d: Dictionary = await _b14_son_durum([s["kayit"]], 250)
		vs.append(b)
		os.append(_b14_ok1(d))
	var pen_a: String = _b14_ok_yaz(vs, os)
	hepsi = hepsi and _b14_pen(vs, os, 36) and not os[0]
	ayr.append("W1a C1 başta bekleme (kare) başarılı: %s (taslak >=32)" % pen_a)
	vs = []
	os = []
	for g in range(0, 10):
		var s: Dictionary = await _b14_senaryo([], _b14_t1(36, 318.0, g))
		var d: Dictionary = await _b14_son_durum([s["kayit"]], 250)
		vs.append(g)
		os.append(_b14_ok1(d))
	hepsi = hepsi and os[0] and not os[9]
	ayr.append("W1b C1 PlakaA'dan ayrılınca duraksama (kare) başarılı: %s (taslak pay ~4)" % _b14_ok_yaz(vs, os))

	# W4: Z1 giriş x'i (sağ basılıyken sensöre girilen merkez x, sonra 2 kare daha sağ).
	vs = []
	os = []
	for x in range(280, 400, 6):
		var s: Dictionary = await _b14_senaryo([], _b14_t1(36, float(x)))
		var d: Dictionary = await _b14_son_durum([s["kayit"]], 250)
		vs.append(x)
		os.append(_b14_ok1(d))
	hepsi = hepsi and _b14_pen(vs, os, 322) and not os[0]
	ayr.append("W4 Z1: sağ bırakma x'i (yürüyüş x>=...) başarılı: %s (taslak sensör x0±44 = 326..)" % _b14_ok_yaz(vs, os))

	# W3: Lazer2 geçişi: oyuncu Z1'den fırlama karesi (C1 klonu referans).
	vs = []
	os = []
	for n in range(90, 160, 3):
		var s: Dictionary = await _b14_senaryo([c1], [_b13_a(1, _b4_x_ge(318.0), 200), _b13_a(0, _b14_kare_ge(n), 400),
			_b13_a(1, _b14_bantta_zemin(520.0), 120)])
		vs.append(n)
		os.append(s["oldu"] == 0 and not s["tamam"].has(false))
	hepsi = hepsi and _b14_pen(vs, os, 150) and not os[0]
	ayr.append("W3 Z1'den fırlama karesi (Lazer2) başarılı: %s (taslak >=~137; Lazer2 klon indikten sonra kapanır)" % _b14_ok_yaz(vs, os))

	# W2: GecitR yarışı: (a) PlakaR'da basılı kalma (r_bekle), (b) plakadan çıkınca duraksama (bant payı).
	vs = []
	os = []
	for rb in range(0, 60, 4):
		var s: Dictionary = await _b14_senaryo([c1], _b14_t2(854.0, rb))
		var d: Dictionary = await _b14_son_durum([c1, s["kayit"]], 450)
		vs.append(rb)
		os.append(_b14_ok2(d))
	hepsi = hepsi and _b14_pen(vs, os, 56) and not os[0]
	var ref2: Dictionary = await _b14_senaryo([c1], _b14_t2())
	var n_pr := 0
	for o in ref2["ozel"]:
		if o["pr"]:
			n_pr += 1
	ayr.append("W2a C2 PlakaR'da r_bekle (x<=475'e vardıktan sonra) başarılı: %s; referans çözümde PlakaR toplam %d kare basılı (taslak >=47)" % [_b14_ok_yaz(vs, os), n_pr])
	vs = []
	os = []
	for yd in range(0, 9):
		var s: Dictionary = await _b14_senaryo([c1], _b14_t2(854.0, 60, 475.0, yd))
		var d: Dictionary = await _b14_son_durum([c1, s["kayit"]], 450)
		vs.append(yd)
		os.append(_b14_ok2(d))
	var yarispay := 0
	for i in range(vs.size()):
		if os[i]:
			yarispay = vs[i]
	hepsi = hepsi and os[0] and not os[8]
	ayr.append("W2b C2 yarış (plakadan çıkınca duraksama, kare) başarılı: %s -> bant payı %d kare (taslak ~2,4)" % [_b14_ok_yaz(vs, os), yarispay])

	# W5: C2'nin S konumu (kaydedilen x eşiği; canlı tur ile klon tekrarının ikisi de başarılı olmalı).
	vs = []
	os = []
	var ol: Array = []
	for x in range(780, 920, 4):
		var s: Dictionary = await _b14_senaryo([c1], _b14_t2(float(x)))
		var d: Dictionary = await _b14_son_durum([c1, s["kayit"]], 450)
		var canli: bool = s["oldu"] == 0 and s["ozel"][s["ozel"].size() - 1]["pp"]
		vs.append(x)
		os.append(_b14_ok2(d))
		ol.append(canli)
	var ik: Array = []
	for i in range(vs.size()):
		ik.append(os[i] and ol[i])
	hepsi = hepsi and _b14_pen(vs, os, 852) and _b14_pen(vs, ol, 852) and not os[0]
	ayr.append("W5 C2 S eşiği (merkez x>=...): klon tekrarı başarılı=%s, canlı tur PlakaP'ye iner=%s, ikisi birden=%s (taslak 840..866; canlı/klon farkı için dikiş testi)" % [
		_b14_ok_yaz(vs, os), _b14_ok_yaz(vs, ol), _b14_ok_yaz(vs, ik)])

	# W6: C3 konvoy: C3'ün yürüyüşe başlama karesi, C2'nin yürüyüşünden (f0) d kare sonra.
	var f0: int = ref2["baslangic"][5]
	vs = []
	os = []
	var os600: Array = []
	for d in [-10, -4, 0, 1, 2, 3, 6, 12, 18, 22, 24, 26, 28, 32, 40, 60, 80, 100, 120, 140]:
		var s: Dictionary = await _b14_senaryo([c1, c2], _b14_t3(f0 + d))
		var dd: Dictionary = await _b14_son_durum([c1, c2, s["kayit"]], 760)
		vs.append(d)
		var ok_d: bool = _b14_ok3(dd) and _b14_ok2(dd) and s["oldu"] == 0
		os.append(ok_d)
		os600.append(ok_d and s["kare"] <= 600)
	hepsi = hepsi and _b14_pen(vs, os, 32) and _b14_pen_degil(vs, os, -10) and _b14_pen_degil(vs, os, 3)
	ayr.append("W6 C3 yürüyüş başlangıcı = C2 yürüyüşü (kare %d) + d, başarılı d: %s; tur <=600 kare olanlar: %s (taslak konvoy +1..+3 kare ÇALIŞMAZ: Lazer1'i C2 çukura inmeden geçemez)" % [f0, _b14_ok_yaz(vs, os), _b14_ok_yaz(vs, os600)])
	vs = []
	os = []
	for yd in range(0, 9):
		var s: Dictionary = await _b14_senaryo([c1, c2], _b14_t3(-1, 760.0, 979.0, 14, 14, yd))
		var dd: Dictionary = await _b14_son_durum([c1, c2, s["kayit"]], 560)
		vs.append(yd)
		os.append(_b14_ok3(dd) and s["oldu"] == 0)
	var c3pay := 0
	for i in range(vs.size()):
		if os[i]:
			c3pay = vs[i]
	hepsi = hepsi and os[0] and not os[8]
	ayr.append("W6b C3 kendi başına yarış (plakadan çıkınca duraksama) başarılı: %s -> pay %d kare (taslak ~2,9)" % [_b14_ok_yaz(vs, os), c3pay])

	# W7: çıkıntı çıkışı: kutu hedef x'i, kutuya zıplama sağ süresi, ikinci zıplamada sağ gecikmesi.
	vs = []
	os = []
	for hx in range(870, 1000, 10):
		var s: Dictionary = await _b14_senaryo([c1, c2], _b14_t3(-1, 760.0, float(hx)))
		var dd: Dictionary = await _b14_son_durum([c1, c2, s["kayit"]], 560)
		vs.append(hx)
		os.append(_b14_ok3(dd))
	hepsi = hepsi and _b14_pen(vs, os, 970) and not os[0]
	ayr.append("W7a kutu hedef x (kutu merkezi >=...) PlakaU'ya çıkış başarılı: %s (kutu x=980 yüze dayanık; taslak pay ~11 px)" % _b14_ok_yaz(vs, os))
	vs = []
	os = []
	for zn in range(2, 30, 2):
		var s: Dictionary = await _b14_senaryo([c1, c2], _b14_t3(-1, 760.0, 979.0, zn))
		var dd: Dictionary = await _b14_son_durum([c1, c2, s["kayit"]], 560)
		vs.append(zn)
		os.append(_b14_ok3(dd))
	hepsi = hepsi and _b14_pen(vs, os, 14)
	ayr.append("W7b kutu üstüne zıplarken sağ süresi (kare) başarılı: %s" % _b14_ok_yaz(vs, os))

	# Çıkıntıdaki zıplama tepesi ayak payı (tam çözümde C3 kaydı).
	var s3: Dictionary = await _b14_senaryo([c1, c2], _b14_t3())
	var o3: Dictionary = _b14_olc(s3)
	ayr.append("W7c C3 en yüksek ayak y=%.1f (çıkıntı yüzeyi 270: pay %.1f px; baş y=%.1f >= TavanD alt 200)" % [o3["ayak"], 270.0 - o3["ayak"], o3["ayak"] - 48.0])
	hepsi = hepsi and o3["ayak"] < 270.0 and o3["ayak"] - 48.0 >= 200.0

	# Lazer2 kapanış kareleri (C1 kaydı klon olarak): geçici (uçuşta plakadan geçerken) ve kalıcı.
	var s_l: Dictionary = await _b14_son_durum([c1], 260)
	var f_ilk := -1
	var f_kalici := -1
	var ozl: Array = s_l["ozel"]
	for f in range(ozl.size()):
		if not ozl[f]["l2"] and f_ilk < 0:
			f_ilk = f
	for f in range(ozl.size() - 1, -1, -1):
		if ozl[f]["l2"]:
			f_kalici = f + 1
			break
	ayr.append("Lazer2 ilk kapanış kare %d (C1 uçuşta PlakaM'den geçerken geçici), kalıcı kapanış kare %d (taslak ~137)" % [f_ilk, f_kalici])
	hepsi = hepsi and f_kalici > 120 and f_kalici < 170

	# PlakaR: en az basılı kalma (başarılı en küçük r_bekle ile) ve C2 durak x penceresi (ışın x 447..453, gövde 28)
	var rmin := -1
	for rb in range(0, 60, 2):
		var sx: Dictionary = await _b14_senaryo([c1], _b14_t2(854.0, rb))
		var dx: Dictionary = await _b14_son_durum([c1, sx["kayit"]], 450)
		if _b14_ok2(dx):
			rmin = rb
			var npr := 0
			for o in sx["ozel"]:
				if o["pr"]:
					npr += 1
			ayr.append("W2c en kısa başarılı C2: r_bekle=%d, PlakaR toplam basılı=%d kare (taslak >=47; GecitR açıklığı >= 92 olmalı değil: ölçülen)" % [rb, npr])
			break
	vs = []
	os = []
	var ayr_sx: Array = []
	for sx_ in [462.0, 466.0, 468.0, 470.0, 474.0, 476.0, 480.0, 485.0]:
		var sx2: Dictionary = await _b14_senaryo([c1], _b14_t2(854.0, 60, sx_))
		var dx2: Dictionary = await _b14_son_durum([c1, sx2["kayit"]], 450)
		vs.append(int(sx_))
		os.append(_b14_ok2(dx2) and sx2["oldu"] == 0)
		ayr_sx.append("%d:%s" % [int(sx_), "ok" if os[os.size() - 1] else ("öldü" if sx2["oldu"] > 0 else "x")])
	ayr.append("W2d C2 plakada durma eşiği (sol bırakma x<=...): %s (Lazer2 bu anda C1 tarafından kapalı; x>=~478'de dikiş/bant sürüklemesi C2'yi plakadan koparır)" % " ".join(ayr_sx))
	hepsi = hepsi and _b14_pen(vs, os, 470) and _b14_pen_degil(vs, os, 485)

	# Z1 uçuşu: UL1 yüzüne sürtünme ve bant üstüne iniş x'i
	var s_u: Dictionary = await _b14_senaryo([c1], [_b13_a(1, _b4_x_ge(318.0), 200), _b13_a(0, _b14_l2_kapali_zemin(), 200),
		_b13_a(1, _b14_bantta_zemin(520.0), 120)])
	var duvar := 0
	var f_ac := -1
	for f in range(s_u["iz"].size()):
		var p: Vector2 = s_u["iz"][f]
		if f_ac < 0 and p.y < 560.0:
			f_ac = f
		if f_ac >= 0 and p.x > 380.0 and p.x < 392.0 and p.y < 560.0 and p.y > 340.0:
			duvar += 1
	var ink: Vector2 = _b14_son(s_u)
	ayr.append("Z1 uçuşu: UL1 yüzünde (x~386) %d kare sürtünür, bant üstüne iniş x=%.0f (taslak ~546±6)" % [duvar, ink.x])
	_kaydi("Bölüm 14 ölçüm: zamanlama pencereleri (W1..W7, kare/px)", hepsi, " || ".join(ayr))
	_kayitlar().sifirla()
	paused = false



## Pencere süpürmesinde değer listede yoksa (find == -1) KALDI sayılır.
func _b14_pen(vs: Array, oklar: Array, v: int) -> bool:
	var i: int = vs.find(v)
	return i >= 0 and bool(oklar[i])


func _b14_pen_degil(vs: Array, oklar: Array, v: int) -> bool:
	var i: int = vs.find(v)
	return i >= 0 and not bool(oklar[i])


## Canlı turun kaydını klon olarak oynatıp en büyük konum farkını (px) döndürür.
## sen: senaryo Callable'ı (kayitlar, adimlar) -> Dictionary; onceki: önceki klon kayıtları.
func _klon_fark(sen: Callable, onceki: Array, adim: Array) -> float:
	var canli: Dictionary = await sen.call(onceki, adim)
	var tekrar: Dictionary = await sen.call(onceki + [canli["kayit"]], [_b4_a(0, Callable(), canli["kare"] + 1)])
	var idx: int = onceki.size()
	var maks := 0.0
	for f in range(mini(canli["iz"].size(), tekrar["klon_izleri"][idx].size())):
		maks = maxf(maks, (canli["iz"][f] - tekrar["klon_izleri"][idx][f]).length())
	return maks


## Bilinen, motor kaynaklı eş düzlemli zemin seçimi farkı: üst sınır aşılırsa KALDI.
func _test_bolum10_klon_fark() -> void:
	var a: Array = await _b10_kayitlar()
	var sen := func(k: Array, ad: Array) -> Dictionary: return await _b10_senaryo(k, ad)
	var f1: float = await _klon_fark(sen, [], _b10_a())
	var f3: float = await _klon_fark(sen, [a[0], a[1]], _b10_c())
	_kaydi("Bölüm 10 canlı/klon konum farkı üst sınırı (bilinen kısıt, bkz. docs/sorunlar.md)", f1 <= 4.2 and f3 <= 2.55,
		"A %.2f px (sınır 4,2; ölçüm 1,67, P1 x370..430'a alınmadan önce 3,33), C %.2f px (sınır 2,55; ölçüm 2,04)" % [f1, f3])
	_kayitlar().sifirla()
	paused = false


## Bölüm 10 PlakaPG tutma: C klonu (son turda tekrar) PG'de sabit kalır, plaka hep basılı;
## PG çevresinde girdisiz duruş (bant sürüklemesi/dikiş) ölçümü.
func _test_bolum10_pg_tutma() -> void:
	var a: Array = await _b10_kayitlar()
	var s: Dictionary = await _b10_senaryo(a, [_b4_a(0, Callable(), 520)])
	var iz: Array = s["klon_izleri"][2] if s["klon_izleri"].size() > 2 else []
	var ilk := -1
	for f in range(s["ozel"].size()):
		if s["ozel"][f]["pg"]:
			ilk = f
			break
	var bos := 0
	var xmin := 1.0e9
	var xmax := -1.0e9
	if ilk >= 0:
		for f in range(ilk, s["ozel"].size()):
			if not s["ozel"][f]["pg"]:
				bos += 1
			xmin = minf(xmin, iz[f].x)
			xmax = maxf(xmax, iz[f].x)
	var ok: bool = ilk >= 0 and bos == 0 and xmax - xmin <= 0.5
	var ayr: Array = ["C tekrarı: PG ilk basılı kare %d, sonrasında basılı olmayan kare %d, C x %.2f..%.2f" % [ilk, bos, xmin, xmax]]
	var ayr_p: Array = []
	for x in [806.0, 812.0, 830.0, 850.0, 870.0, 890.0]:
		var sp: Dictionary = await _b10_senaryo([], [_b4_a(0, Callable(), 120)], _b10_yerlestir(Vector2(x, 416)))
		var n := 0
		for o in sp["ozel"]:
			if o["pg"]:
				n += 1
		ayr_p.append("x0=%.0f: %d/120 basılı, son x=%.1f" % [x, n, sp["iz"][sp["iz"].size() - 1].x])
	ayr.append("PG girdisiz duruş: " + "; ".join(ayr_p))
	_kaydi("Bölüm 10 PlakaPG tutma: C klonu plakada sabit, PG hep basılı (bant sürüklemesi koparmaz)", ok, " || ".join(ayr))
	_kayitlar().sifirla()
	paused = false


## Bölüm 10 PlakaP1 (bant üstünde, Duvar'a değmez) ölçümü: kutu P1'e basınca Lazer1 kapanış karesi
## ve A'nın PE'ye basma karesi penceresi (C asansöre binmiş olmalı; çözüm 230'da basar, pay >= 8 kare).
func _test_bolum10_p1_pencere() -> void:
	var p1: Area2D = null
	var b: Node = await _bolumu_yukle()
	p1 = b.get_node("PlakaP1")
	var bant: Node = b.get_node("Bant1")
	var duvar: Node = b.get_node("Duvar")
	var pr: Rect2 = Gorunum.sekil_alani(p1)
	pr.position += p1.global_position
	var br: Rect2 = Gorunum.sekil_alani(bant)
	br.position += bant.global_position
	var dr: Rect2 = Gorunum.sekil_alani(duvar)
	dr.position += duvar.global_position
	var geo_ok: bool = pr.position.x >= br.position.x and pr.end.x <= br.end.x and pr.end.x <= dr.position.x
	var s1: Dictionary = await _b10_senaryo([], _b10_a())
	var l1_kapanis := -1
	for f in range(s1["ozel"].size()):
		if not s1["ozel"][f]["l1"]:
			l1_kapanis = f
			break
	var basarili: Array = []
	for bk in range(150, 331, 10):
		var a: Dictionary = await _b10_senaryo([], _b10_a(bk))
		var bb: Dictionary = await _b10_senaryo([a["kayit"]], _b10_b())
		var c: Dictionary = await _b10_senaryo([a["kayit"], bb["kayit"]], _b10_c())
		var o: Dictionary = await _b10_senaryo([a["kayit"], bb["kayit"], c["kayit"]], _b10_oyuncu())
		if o["bitti"]:
			basarili.append(bk)
	var alt: int = basarili.min() if not basarili.is_empty() else -1
	var ust: int = basarili.max() if not basarili.is_empty() else -1
	var ok: bool = geo_ok and alt >= 0 and 230 - alt >= 8 and ust - 230 >= 8
	_kaydi("Bölüm 10 ölçüm: PlakaP1 bandın üstünde (Duvar'a değmez), L1 kapanışı, A'nın PE basma penceresi (pay >= 8 kare)", ok,
		"P1 x %.0f..%.0f, Bant1 x %.0f..%.0f, Duvar x %.0f..: %s; L1 ilk kapanış kare %d (A turu); A basma karesi başarılı (10'ar adım): %s -> %d..%d (çözüm 230, pay -%d/+%d kare)" % [
			pr.position.x, pr.end.x, br.position.x, br.end.x, dr.position.x, "bant üstünde" if geo_ok else "TAŞIYOR",
			l1_kapanis, str(basarili), alt, ust, 230 - alt, ust - 230])
	_kayitlar().sifirla()
	paused = false


func _test_bolum13_klon_fark() -> void:
	var a: Array = await _b13_kayitlar()
	var sen := func(k: Array, ad: Array) -> Dictionary: return await _b13_senaryo(k, ad)
	var f1: float = await _klon_fark(sen, [], _b13_k1())
	var f2: float = await _klon_fark(sen, [a[0]], _b13_k2())
	var f3: float = await _klon_fark(sen, [a[0], a[1]], _b13_k3())
	_kaydi("Bölüm 13 canlı/klon konum farkı üst sınırı (bilinen kısıt, bkz. docs/sorunlar.md)", f1 <= 6.25 and f2 <= 2.1 and f3 <= 12.5,
		"K1 %.2f px (sınır 6,25; ölçüm 5), K2 %.2f px (sınır 2,1; ölçüm 1,67), K3 %.2f px (sınır 12,5; ölçüm 10)" % [f1, f2, f3])
	_kayitlar().sifirla()
	paused = false

# ---------------------------------------------------------------- 6) dikiş / bant: canlı ile klon tekrarı farkı, plaka sürüklenmesi
func _test_bolum14_dikis() -> void:
	var kay: Array = await _b14_kayitlar()
	var c1: Array = kay[0]
	var ayr: Array = []
	var hepsi := true
	# Canlı kaydın aynısını klon olarak oynat: konum farkı.
	for k in [["C1", [], _b14_t1(), 0], ["C2", [c1], _b14_t2(), 1], ["C3", [c1, kay[1]], _b14_t3(), 2]]:
		var canli: Dictionary = await _b14_senaryo(k[1], k[2])
		var tekrar: Dictionary = await _b14_senaryo(k[1] + [canli["kayit"]], [_b13_a(0, Callable(), canli["kare"] + 1)])
		var idx: int = k[3]
		var maks := 0.0
		var ilk := -1
		var ilk_x := 0.0
		for f in range(mini(canli["iz"].size(), tekrar["klon_izleri"][idx].size())):
			var fark: float = (canli["iz"][f] - tekrar["klon_izleri"][idx][f]).length()
			if fark > 0.01 and ilk < 0:
				ilk = f
				ilk_x = canli["iz"][f].x
			maks = maxf(maks, fark)
		ayr.append("%s canlı/klon en büyük konum farkı %.2f px (ilk sapma kare %d, x=%.0f)" % [k[0], maks, ilk, ilk_x])
		var sinir: float = [0.01, 12.5, 2.5][idx]
		hepsi = hepsi and maks <= sinir
		ayr[ayr.size() - 1] += " [sınır %.2f px, bilinen kısıt, bkz. docs/sorunlar.md]" % sinir
	# PlakaR üstünde girdisiz duruş: bantla sürüklenme ve plakanın basılı kalma süresi.
	var ayr_p: Array = []
	for x in [469.0, 476.0, 486.0, 496.0, 506.0, 520.0]:
		var sp: Dictionary = await _b14_senaryo([], [_b13_a(0, Callable(), 120)], _b14_yerlestir(Vector2(x, 376)))
		var n := 0
		for o in sp["ozel"]:
			if o["pr"]:
				n += 1
		ayr_p.append("x0=%.0f: %d/120 kare basılı, son x=%.1f" % [x, n, _b14_son(sp).x])
	ayr.append("PlakaR girdisiz duruş: " + "; ".join(ayr_p))
	# Bant girdisiz hızı (bant ortası).
	var sb: Dictionary = await _b14_senaryo([], [_b13_a(0, Callable(), 30)], _b14_yerlestir(Vector2(540, 376)))
	var hiz: float = (sb["iz"][29].x - sb["iz"][9].x) / 20.0
	ayr.append("bant girdisiz hızı %.3f px/kare (beklenen 1,667)" % hiz)
	hepsi = hepsi and absf(hiz - 1.667) < 0.05
	_kaydi("Bölüm 14 ölçüm: bant-zemin dikişi, canlı/klon farkı (bilinen kısıt, bkz. docs/sorunlar.md; C1<=0,01 C2<=12,5 C3<=2,5 px), PlakaR sürüklenmesi", hepsi, " || ".join(ayr))
	_kayitlar().sifirla()
	paused = false


# ---------------------------------------------------------------- 7) klon sınırı
func _test_bolum14_klon_siniri() -> void:
	_kayitlar().sifirla()
	var bolum: Node = await _bolumu_yukle()
	var maks: int = bolum.max_klon
	var gecti := maks == 3
	var ayr: Array = []
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
			gecti = gecti and yeni == null and sayi == maks and yazi.contains("Klon hakkı bitti") and yazi.contains("3/3")
			ayr.append("sınırda etiket: \"%s\"" % yazi)
		ayr.append("R #%d -> kayıtlı klon: %d" % [n + 1, sayi])
	_kaydi("Bölüm 14: klon sınırı (dördüncü R klon kaydetmez)", gecti, "max_klon=%d; %s" % [maks, ", ".join(ayr)])
	_kayitlar().sifirla()


# ---------------------------------------------------------------- 8) kilitlenme davranışı
func _test_bolum14_kilitlenme() -> void:
	var kay: Array = await _b14_kayitlar()
	var c1: Array = kay[0]
	var c2: Array = kay[1]
	var ayr: Array = []
	var hepsi := true

	# (a) Çukurda ölüm: oyuncu çukurdan Lazer1 açıkken çıkmaya çalışır -> tur yeniden başlar, klonlar korunur.
	_kayitlar().sifirla()
	_kayitlar().tur_kaydet(c1.duplicate(true))
	var bolum: Node = await _bolumu_yukle()
	bolum.get_node("Oyuncu").global_position = Vector2(880, 576)
	var sayac := [0]
	bolum.get_node("Oyuncu").oyuncu_oldu.connect(func() -> void: sayac[0] += 1)
	var eski_id := bolum.get_instance_id()
	bolum.get_node("Oyuncu").global_position = Vector2(790, 576)
	var s: Dictionary = await _b14_kosullu(bolum, [_b13_a(1, Callable(), 90)], sayac)
	var yeni: Node = await _yeni_sahne_bekle(eski_id)
	var ok: bool = sayac[0] > 0 and yeni != null and _kayitlar().turlar.size() == 1
	var etiket := ""
	if yeni != null:
		etiket = yeni.bilgi.text
		ok = ok and _klonlar(yeni).size() == 1 and etiket.contains("Tur 2") and etiket.contains("1/3")
	hepsi = hepsi and ok
	ayr.append("çukurda ölüm: ölüm=%d, kayıtlı tur=%d, etiket=\"%s\"" % [sayac[0], _kayitlar().turlar.size(), etiket])

	# (b) Çukurdan çıkış: Z2'den sola (Lazer1 solunda) çıkar, kilitlenme yok.
	var sc: Dictionary = await _b14_senaryo([], [_b13_a(-1, Callable(), 90)], _b14_yerlestir(Vector2(800, 576)))
	var oc: Dictionary = _b14_olc(sc)
	var son: Vector2 = _b14_son(sc)
	var ok_b: bool = sc["oldu"] == 0 and son.x < 760.0 and son.y < 400.0 and oc["xmin"] < 760.0
	hepsi = hepsi and ok_b
	ayr.append("çukurdan çıkış: Z2'den sola, son=(%.0f,%.0f), ölüm=%d" % [son.x, son.y, sc["oldu"]])

	# (c) Kutu sola itilirse Raf'tan düşer; bölüm bu turda bitmez, "Baştan başla" sıfırlar.
	var cr: Array = (await _b14_senaryo([c1], _b14_ucus_ve_plakar(400, 475.0)))["kayit"]
	var sk: Dictionary = await _b14_senaryo([c1, cr], _b14_kutu_sola_adim(200.0))
	var kutu: Vector2 = sk["ozel"][sk["ozel"].size() - 1]["kutu"]
	var dv: Dictionary = await _b14_senaryo([c1, cr, sk["kayit"]], _b14_oyuncu(14, -1, ""))
	var ok_c: bool = kutu.x < 280.0 and not dv["bitti_ham"]
	hepsi = hepsi and ok_c
	ayr.append("kutu sola itilir: kutu=(%.0f,%.0f) (Raf 280..400 dışı), sonraki turda bölüm biter=%s -> kilitlenme" % [kutu.x, kutu.y, dv["bitti_ham"]])
	# Baştan başla: tüm klonlar silinir, Tur 1, kutu başlangıçta.
	_kayitlar().sifirla()
	_kayitlar().tur_kaydet(c1.duplicate(true))
	var b2: Node = await _bolumu_yukle()
	var eski: Node = current_scene
	b2.get_node("EkranButonlari/Kutu/YenidenDugmesi").pressed.emit()
	var yeni2: Node = await _sahne_degisimini_bekle(eski)
	var kutu_bas: Vector2 = yeni2.get_node("Kutu").global_position
	var ok_d: bool = _kayitlar().turlar.size() == 0 and _klonlar(yeni2).size() == 0 and yeni2.bilgi.text.begins_with("Tur 1 ") \
		and absf(kutu_bas.x - 675.0) < 1.0
	hepsi = hepsi and ok_d
	ayr.append("Baştan başla: kayıt=%d, klon=%d, etiket=\"%s\", kutu x=%.0f" % [_kayitlar().turlar.size(), _klonlar(yeni2).size(), yeni2.bilgi.text, kutu_bas.x])

	# (d) Klon Lazer2'de ölürse yerinde donar (C2 kaydı C1'siz oynatılır).
	var sd: Dictionary = await _b14_senaryo([c2], [_b13_a(0, Callable(), 250)])
	var ki: Array = sd["klon_izleri"][0]
	var donuk: bool = sd["klon_oldu"][0] and ki[ki.size() - 1] == ki[ki.size() - 40] and ki[ki.size() - 1].x < 450.0
	hepsi = hepsi and donuk
	ayr.append("ölü klon: öldü=%s, son konum=(%.0f,%.0f), sabit=%s" % [sd["klon_oldu"][0], ki[ki.size() - 1].x, ki[ki.size() - 1].y, str(donuk)])

	_kaydi("Bölüm 14 kilitlenme: çukurda ölüm, çukurdan çıkış, kutu sola itme + Baştan başla, ölü klon", hepsi, " || ".join(ayr))
	_kayitlar().sifirla()
	paused = false


# ---------------------------------------------------------------- 9) determinizm
func _test_bolum14_determinizm() -> void:
	var kay: Array = await _b14_kayitlar()
	var s0: Dictionary = await _b14_senaryo(kay, _b14_oyuncu())
	var betik: Array = s0["kayit"]
	var ornek := func(b: Node) -> Dictionary: return _b14_ornekle(b)
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
	_kaydi("Bölüm 14: determinizm (100x çözüm)", sapmali == 0 and bitmeyen == 0 and s0["bitti_ham"],
		"%d çalıştırma x %d kare, sapmalı: %d, en büyük sapma: %.4f px, bitirmeyen çalıştırma: %d, kayıt turu bitti: %s" % [
			TEKRAR, referans["kare"], sapmali, maks_sapma, bitmeyen, s0["bitti_ham"]])
	_kayitlar().sifirla()
	paused = false



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



# ---------------------------------------------------------------- zamanlı / mandal plaka
# Kullanıcı kararı (2026-10-15): `tutma_kare` (basış bitince o kadar fizik karesi daha basılı)
# ve `mandal` (bir kez basılınca tur sonuna kadar). Test sahnesi (oyun bölümü değil):
# tests/sahneler/zamanli_plaka_test.tscn. Zemin yüzeyi y=600, oyuncu x=200, hız 5 px/kare.
#   PlakaZ (zamanlı 180) x=350, PlakaM (mandal) x=520, PlakaV (varsayılan) x=650.
#   Her plakaya bir Gecit (40 px açılır), bir Lazer (basılıyken kapanır), bir Asansor bağlı.
#   LazerOlum tetikleyicisiz, varsayılan olarak ekran dışında (testte taşınır).

const PLAKA_TEST := "res://tests/sahneler/zamanli_plaka_test.tscn"
const PL_TUTMA := 180
const PL_ANAHTARLAR := ["pZ", "fZ", "kZ", "lZ", "gZ", "aZ", "pM", "fM", "kM", "lM", "gM", "aM", "pV", "fV", "lV", "gV", "aV"]
var pl_olcum: Array = []   # rapor için ölçüm satırları


func _plaka_testleri() -> void:
	aktif_bolum = PLAKA_TEST
	await _pl_sahne_ozellikleri()
	await _pl_zamanli_olcum()
	await _pl_zamanli_yenileme()
	await _pl_varsayilan()
	await _pl_klon_kayittan()
	await _pl_olu_klon()
	await _pl_mandal()
	await _pl_tur_basi_sifirlama()
	await _pl_determinizm()
	_kayitlar().sifirla()
	paused = false


## Her karede örneklenen durum (basili_mi çağrısı kare başına bir kez ilerler, sonucu etkilemez).
func _pl_ornekle(b: Node) -> Dictionary:
	var d := {"o": b.get_node("Oyuncu").global_position.x}
	for k in ["Z", "M", "V"]:
		var p: BasincPlakasi = b.get_node("Plaka" + k)
		d["p" + k] = p.basili_mi()
		d["f" + k] = p.has_overlapping_bodies()
		d["k" + k] = p.kalan_kare
		d["l" + k] = b.get_node("Lazer" + k).acik_mi()
		d["g" + k] = b.get_node("Gecit" + k).position.y
		d["a" + k] = b.get_node("Asansor" + k).position.y
	d["kilitli"] = b.get_node("PlakaM").kilitli
	var kl: Array = _klonlar(b)
	if kl.size() > 0:
		d["klon_oldu"] = kl[0].oldu
		d["klon_x"] = kl[0].global_position.x
	return d


func _pl_calis(kayitlar: Array, betik: Array, n: int, hazirlik := Callable()) -> Dictionary:
	aktif_bolum = PLAKA_TEST
	return await _senaryo(kayitlar, betik, n, hazirlik, Callable(self, "_pl_ornekle"))


## Canlı oyuncunun kaydı (girdi dizisi), son çalıştırılan sahneden.
func _pl_kayit() -> Array:
	return current_scene.get_node("Oyuncu").kayit_girdileri.duplicate(true)


## Plaka p (basılı), f (fiziksel örtüşme) izinden: ilk/son fiziksel kare, son basıştan sonra
## kesintisiz basılı kalan kare sayısı (kuyruk), erken etkinleşme ve kesinti var mı.
func _pl_aralik(iz: Array, p: String, f: String) -> Dictionary:
	var ilk := -1
	var son := -1
	var yukselen := 0
	var onceki := false
	for i in range(iz.size()):
		var f_ok: bool = iz[i][f]
		if f_ok:
			if ilk < 0:
				ilk = i
			son = i
		if f_ok and not onceki:
			yukselen += 1
		onceki = f_ok
	var kuyruk := 0
	if son >= 0:
		var i := son + 1
		while i < iz.size() and iz[i][p] and not iz[i][f]:
			kuyruk += 1
			i += 1
	var kesintisiz := ilk >= 0
	var erken := false
	var basili_toplam := 0
	for j in range(iz.size()):
		if iz[j][p]:
			basili_toplam += 1
		if ilk >= 0 and j >= ilk and j <= son + kuyruk and not iz[j][p]:
			kesintisiz = false
		if (ilk < 0 or j < ilk) and iz[j][p]:
			erken = true
	return {"ilk": ilk, "son": son, "kuyruk": kuyruk, "kesintisiz": kesintisiz, "erken": erken,
		"basis": yukselen, "toplam": basili_toplam}


func _pl_hepsi(iz: Array, anahtar: String, deger: Variant, bas: int, son: int) -> bool:
	for i in range(maxi(bas, 0), mini(son + 1, iz.size())):
		if iz[i][anahtar] != deger:
			return false
	return true


func _pl_min(iz: Array, anahtar: String) -> float:
	var m := 1.0e9
	for o in iz:
		m = minf(m, float(o[anahtar]))
	return m


func _pl_z1_betik() -> Array:
	return _betik([[30, 1, false], [20, 0, false], [30, -1, false], [320, 0, false]])


func _pl_sahne_ozellikleri() -> void:
	var z: Node = load("res://scenes/zamanli_plaka.tscn").instantiate()
	var m: Node = load("res://scenes/mandal_plaka.tscn").instantiate()
	var z_ok: bool = z is BasincPlakasi and z.tutma_kare == PL_TUTMA and not z.mandal
	var m_ok: bool = m is BasincPlakasi and m.mandal and m.tutma_kare == 0
	z.free()
	m.free()
	_kayitlar().sifirla()
	var b: Node = await _bolumu_yukle()
	var vp: BasincPlakasi = b.get_node("PlakaV")
	var v_ok: bool = vp.tutma_kare == 0 and not vp.mandal
	var s_ok: bool = b.get_node("PlakaZ").tutma_kare == PL_TUTMA and b.get_node("PlakaM").mandal
	_kaydi("Plaka sahneleri: zamanli_plaka (tutma_kare=180), mandal_plaka (mandal), varsayılan 0/false", z_ok and m_ok and v_ok and s_ok,
		"zamanlı: %s, mandal: %s, varsayılan: %s, test sahnesinde: %s" % [z_ok, m_ok, v_ok, s_ok])


## A1) Zamanlı plaka: basılıyken açık, bıraktıktan sonra tam 180 kare açık, sonra kapanır.
func _pl_zamanli_olcum() -> void:
	var s: Dictionary = await _pl_calis([], _pl_z1_betik(), 400)
	var iz: Array = s["ozel_iz"]
	var a: Dictionary = _pl_aralik(iz, "pZ", "fZ")
	var kuyruk: int = a["kuyruk"]
	var son_dahil: int = a["son"] + kuyruk
	pl_olcum.append("zamanlı plaka (canlı oyuncu): ilk basış kare %d, son fiziksel kare %d, bıraktıktan sonra kesintisiz basılı kare = %d (beklenen %d)" % [a["ilk"], a["son"], kuyruk, PL_TUTMA])
	var kuyruk_ok: bool = absi(kuyruk - PL_TUTMA) <= 1
	_kaydi("Zamanlı plaka 1) basış bittikten sonra tam %d kare basılı, sonra bırakır (±1)" % PL_TUTMA,
		a["ilk"] >= 0 and kuyruk_ok and a["kesintisiz"] and not a["erken"] and not iz[iz.size() - 1]["pZ"],
		"ilk basış kare %d, son fiziksel kare %d, kuyruk %d kare, kesintisiz: %s, erken etkin: %s, sonda basılı: %s" % [
			a["ilk"], a["son"], kuyruk, a["kesintisiz"], a["erken"], iz[iz.size() - 1]["pZ"]])
	var lz_kapali: bool = _pl_hepsi(iz, "lZ", false, a["ilk"] + 3, son_dahil - 1)
	var lz_once: bool = _pl_hepsi(iz, "lZ", true, 0, a["ilk"] - 1)
	var lz_sonra: bool = _pl_hepsi(iz, "lZ", true, son_dahil + 3, iz.size() - 1)
	var g_min: float = _pl_min(iz, "gZ")
	var g_son: float = iz[iz.size() - 1]["gZ"]
	var a_min: float = _pl_min(iz, "aZ")
	var a_son: float = iz[iz.size() - 1]["aZ"]
	var g_ok: bool = absf(g_min - 460.0) < 0.01 and absf(g_son - 500.0) < 0.01
	var a_ok: bool = absf(a_min - 120.0) < 0.01 and absf(a_son - 300.0) < 0.01
	_kaydi("Zamanlı plaka 2) lazer, geçit ve asansör süre boyunca etkin, sonra eski haline döner",
		lz_kapali and lz_once and lz_sonra and g_ok and a_ok,
		"lazer süre boyunca kapalı: %s, öncesi açık: %s, sonrası açık: %s, geçit en açık y=%.0f sonda y=%.0f, asansör en yüksek y=%.0f sonda y=%.0f" % [
			lz_kapali, lz_once, lz_sonra, g_min, g_son, a_min, a_son])
	var yenilenir := true
	for i in range(a["ilk"], a["son"] + 1):
		if iz[i]["kZ"] != PL_TUTMA + 1:
			yenilenir = false
	_kaydi("Zamanlı plaka 3) fiziksel basış sürerken sayaç her kare tutma_kare+1'e yenilenir", yenilenir,
		"basılı kareler %d..%d, kalan_kare hep %d: %s" % [a["ilk"], a["son"], PL_TUTMA + 1, yenilenir])


## A2) Yeniden basma sayacı yeniler (iki basış, arası 180'den kısa: kesintisiz; kuyruk son basıştan 180).
func _pl_zamanli_yenileme() -> void:
	var betik := _betik([[30, 1, false], [10, 0, false], [40, -1, false], [40, 1, false],
		[10, 0, false], [40, -1, false], [300, 0, false]])
	var s: Dictionary = await _pl_calis([], betik, 470)
	var iz: Array = s["ozel_iz"]
	var a: Dictionary = _pl_aralik(iz, "pZ", "fZ")
	var bosluk := 0
	var en_uzun_bosluk := 0
	var basladi := false
	for i in range(maxi(a["ilk"], 0), a["son"] + 1):
		if iz[i]["fZ"]:
			basladi = true
			bosluk = 0
		elif basladi:
			bosluk += 1
			en_uzun_bosluk = maxi(en_uzun_bosluk, bosluk)
	var beklenen_toplam: int = (a["son"] - a["ilk"] + 1) + PL_TUTMA
	pl_olcum.append("zamanlı plaka yeniden basma: %d basış, aradaki en uzun fiziksel boşluk %d kare, son basıştan sonra kuyruk %d kare" % [a["basis"], en_uzun_bosluk, a["kuyruk"]])
	_kaydi("Zamanlı plaka 4) yeniden basılırsa sayaç yenilenir (2 basış, boşlukta kesintisiz, son basıştan sonra 180)",
		a["basis"] == 2 and en_uzun_bosluk > 20 and en_uzun_bosluk < PL_TUTMA and a["kesintisiz"] and not a["erken"]
		and absi(a["kuyruk"] - PL_TUTMA) <= 1 and absi(a["toplam"] - beklenen_toplam) <= 1,
		"basış sayısı: %d, en uzun boşluk: %d kare, kesintisiz: %s, kuyruk: %d, toplam basılı %d (beklenen %d)" % [
			a["basis"], en_uzun_bosluk, a["kesintisiz"], a["kuyruk"], a["toplam"], beklenen_toplam])


## C) Varsayılan plaka (tutma_kare 0, mandal false): yalnızca üstündeyken basılı, kuyruk 0.
func _pl_varsayilan() -> void:
	var betik := _betik([[90, 1, false], [20, 0, false], [60, -1, false], [100, 0, false]])
	var s: Dictionary = await _pl_calis([], betik, 270)
	var iz: Array = s["ozel_iz"]
	var a: Dictionary = _pl_aralik(iz, "pV", "fV")
	var ayni := true
	for i in range(iz.size()):
		if iz[i]["pV"] != iz[i]["fV"]:
			ayni = false
	var lazer_kapali := 0
	for o in iz:
		if not o["lV"]:
			lazer_kapali += 1
	var lazer_ok: bool = lazer_kapali >= a["toplam"] - 2 and lazer_kapali <= a["toplam"] + 2
	_kaydi("Varsayılan plaka çıplak: basılı == üstünde, kuyruk 0, lazer yalnız o süre kapalı",
		a["ilk"] >= 0 and ayni and a["kuyruk"] == 0 and lazer_ok and absf(_pl_min(iz, "gV") - 460.0) < 0.01
		and absf(iz[iz.size() - 1]["gV"] - 500.0) < 0.01,
		"ilk basış %d, son %d, basılı kare %d, hep p==f: %s, kuyruk %d, lazer kapalı kare %d" % [
			a["ilk"], a["son"], a["toplam"], ayni, a["kuyruk"], lazer_kapali])


func _pl_iz_esit(a: Array, b: Array, anahtarlar: Array) -> int:
	if a.size() != b.size():
		return 1000000
	var fark := 0
	for i in range(a.size()):
		for k in anahtarlar:
			if a[i][k] != b[i][k]:
				fark += 1
	return fark


## A3/B) Klon kayıttan canlı oyuncuyla aynı kare kare plaka durumunu üretir (zamanlı ve mandal).
func _pl_klon_kayittan() -> void:
	var canli: Dictionary = await _pl_calis([], _pl_z1_betik(), 400)
	var kayit: Array = _pl_kayit()
	var klon: Dictionary = await _pl_calis([kayit], [], 400)
	var ak := ["pZ", "fZ", "kZ", "lZ", "gZ", "aZ", "pM", "pV"]
	var fark: int = _pl_iz_esit(canli["ozel_iz"], klon["ozel_iz"], ak)
	var ak_a: Dictionary = _pl_aralik(klon["ozel_iz"], "pZ", "fZ")
	var canli_a: Dictionary = _pl_aralik(canli["ozel_iz"], "pZ", "fZ")
	_kaydi("Zamanlı plaka 5) klon kayıttan canlı oyuncuyla aynı kareleri üretir (kuyruk 180)",
		fark == 0 and absi(ak_a["kuyruk"] - PL_TUTMA) <= 1,
		"%d kare, farklı kare/anahtar: %d, klon kuyruğu %d, canlı kuyruğu %d" % [
			klon["ozel_iz"].size(), fark, ak_a["kuyruk"], canli_a["kuyruk"]])
	var mb := _betik([[80, 1, false], [300, 0, false]])
	var mcanli: Dictionary = await _pl_calis([], mb, 380)
	var mkayit: Array = _pl_kayit()
	var mklon: Dictionary = await _pl_calis([mkayit], [], 380)
	var mfark: int = _pl_iz_esit(mcanli["ozel_iz"], mklon["ozel_iz"], ["pM", "fM", "kilitli", "lM", "gM", "aM"])
	var ma: Dictionary = _pl_aralik(mklon["ozel_iz"], "pM", "fM")
	var son_kare: Dictionary = mklon["ozel_iz"][mklon["ozel_iz"].size() - 1]
	_kaydi("Mandal plaka 5) klon kayıttan oyuncuyla aynı kareleri üretir; yalnız klon basınca da tur sonuna kadar etkin",
		mfark == 0 and ma["ilk"] >= 0 and son_kare["pM"] and not son_kare["fM"] and son_kare["kilitli"],
		"farklı kare/anahtar: %d, klon ilk basış kare %d, sonda basılı: %s, fiziksel: %s, kilitli: %s" % [
			mfark, ma["ilk"], son_kare["pM"], son_kare["fM"], son_kare["kilitli"]])


## Test sahnesinde canlı oyuncuyla kayıt alır (lazer ekran dışında).
func _kaydet_plaka(betik: Array) -> Array:
	aktif_bolum = PLAKA_TEST
	return await _kaydet(betik)


## A4) Ölü klon plakayı basılı tutmaz; kalan süre işler (180 kare sonra bırakır).
func _pl_olu_klon() -> void:
	var kayit: Array = await _kaydet_plaka(_betik([[100, 1, false], [300, 0, false]]))
	var olum := func(b: Node) -> void:
		b.get_node("LazerOlum").position = Vector2(395, 620)
	var s: Dictionary = await _pl_calis([kayit], [], 400, olum)
	var iz: Array = s["ozel_iz"]
	var ko := -1
	for i in range(iz.size()):
		if iz[i].get("klon_oldu", false):
			ko = i
			break
	var a: Dictionary = _pl_aralik(iz, "pZ", "fZ")
	var son: Dictionary = iz[iz.size() - 1]
	var klon_x: float = son.get("klon_x", -1.0)
	var plakada: bool = absf(klon_x - 350.0) < 44.0   # ölü gövde plaka alanının içinde duruyor
	var m_hic := true
	for o in iz:
		if o["pM"] or o["fM"]:
			m_hic = false
	var tutuyor: bool = ko >= 0 and iz[mini(a["son"] + 100, iz.size() - 1)]["pZ"]
	var biraktı: bool = ko >= 0 and not iz[mini(a["son"] + PL_TUTMA + 3, iz.size() - 1)]["pZ"] and not son["pZ"]
	pl_olcum.append("zamanlı plaka, ölü klon: ölüm kare %d, son fiziksel kare %d, kuyruk %d kare, ölü gövde x=%.0f (plaka x 320..380)" % [ko, a["son"], a["kuyruk"], klon_x])
	_kaydi("Zamanlı plaka 6) ölü klon plakayı basılı tutmaz, kalan süre yine işler",
		ko >= 15 and ko < 80 and plakada and m_hic and tutuyor and biraktı and absi(a["kuyruk"] - PL_TUTMA) <= 1
		and a["kesintisiz"] and a["basis"] == 1,
		"klon ölüm karesi %d, ölü x=%.0f (plaka alanında: %s), son fiziksel kare %d, kuyruk %d, son fiziksel+100'de basılı: %s, +183'te bıraktı: %s, sonda basılı: %s, mandala hiç değmedi: %s" % [
			ko, klon_x, plakada, a["son"], a["kuyruk"], tutuyor, biraktı, son["pZ"], m_hic])


## B) Mandal: bir kez basılınca tur sonuna kadar etkin; hedefleri kalıcı etkiler.
func _pl_mandal() -> void:
	var s: Dictionary = await _pl_calis([], _betik([[80, 1, false], [300, 0, false]]), 380)
	var iz: Array = s["ozel_iz"]
	var a: Dictionary = _pl_aralik(iz, "pM", "fM")
	var ilk: int = a["ilk"]
	var kalici: bool = ilk >= 0 and _pl_hepsi(iz, "pM", true, ilk, iz.size() - 1)
	var oncesi_pasif: bool = ilk > 0 and _pl_hepsi(iz, "pM", false, 0, ilk - 1)
	var biraktı := false
	for i in range(maxi(ilk, 0), iz.size()):
		if not iz[i]["fM"] and iz[i]["pM"]:
			biraktı = true
	var son: Dictionary = iz[iz.size() - 1]
	var lm_ok: bool = _pl_hepsi(iz, "lM", true, 0, ilk - 1) and _pl_hepsi(iz, "lM", false, ilk + 3, iz.size() - 1)
	var g_ok: bool = absf(son["gM"] - 460.0) < 0.01 and _pl_hepsi(iz, "gM", 500.0, 0, ilk - 1)
	var as_ok: bool = absf(son["aM"] - 220.0) < 0.01
	_kaydi("Mandal plaka 1) bir kez basılınca tur sonuna kadar etkin (üstten çekilse de), öncesinde pasif",
		kalici and oncesi_pasif and biraktı and not son["fM"] and son["kilitli"],
		"ilk basış kare %d, o andan sonra hep basılı: %s, öncesi hep pasif: %s, üstten ayrıldıktan sonra da basılı: %s, sonda üstünde: %s, kilitli: %s" % [
			ilk, kalici, oncesi_pasif, biraktı, son["fM"], son["kilitli"]])
	_kaydi("Mandal plaka 2) kapalı hedefi (lazer, geçit, asansör) kalıcı etkiler",
		lm_ok and g_ok and as_ok,
		"lazer öncesi açık/sonrası kapalı: %s, geçit sonda y=%.0f (açık 460): %s, asansör sonda y=%.0f (üst 220): %s" % [
			lm_ok, son["gM"], g_ok, son["aM"], as_ok])
	var v_ok := true
	for o in iz:
		if o["pV"] != o["fV"]:
			v_ok = false
	_kaydi("Mandal plaka 3) varsayılan plaka mandaldan etkilenmez (aynı turda)", v_ok, "pV == fV her karede: %s" % v_ok)
	var s2: Dictionary = await _pl_calis([], _betik([[80, 1, false], [40, -1, false], [40, 1, false], [220, 0, false]]), 380)
	var iz2: Array = s2["ozel_iz"]
	var a2: Dictionary = _pl_aralik(iz2, "pM", "fM")
	_kaydi("Mandal plaka 4) tekrar basmak durumu bozmaz (hep etkin, ayrılınca da kalır)",
		a2["ilk"] >= 0 and _pl_hepsi(iz2, "pM", true, a2["ilk"], iz2.size() - 1) and a2["basis"] >= 1,
		"basış: %d, ilk %d, son fiziksel %d, sondan sonra kesintisiz: %d kare" % [a2["basis"], a2["ilk"], a2["son"], a2["kuyruk"]])


## A5) Tur başında (gerçek R yolu) sahne yeniden kurulur: sayaç ve mandal sıfırlanır.
func _pl_tur_basi_sifirlama() -> void:
	aktif_bolum = PLAKA_TEST
	_kayitlar().sifirla()
	var b: Node = await _bolumu_yukle()
	for i in range(80):
		_girdi_uygula({"yon": 1.0, "zipla": false})
		await physics_frame
	_girdi_uygula({"yon": 0.0, "zipla": false})
	await physics_frame
	var once := _pl_ornekle(b)
	var eski_id := b.get_instance_id()
	await _r_bas()
	var yeni: Node = await _yeni_sahne_bekle(eski_id)
	if yeni == null:
		_kaydi("Tur başında zamanlı sayaç ve mandal sıfırlanır", false, "yeni sahne yüklenmedi")
		return
	await physics_frame
	var sonra := _pl_ornekle(yeni)
	var once_ok: bool = once["pZ"] and once["kZ"] > 0 and once["pM"] and once["kilitli"]
	var sonra_ok: bool = not sonra["pZ"] and sonra["kZ"] == 0 and not sonra["pM"] and not sonra["kilitli"] \
		and sonra["lZ"] and sonra["lM"] and absf(sonra["gZ"] - 500.0) < 0.01 and absf(sonra["gM"] - 500.0) < 0.01 \
		and absf(sonra["aZ"] - 300.0) < 0.01 and absf(sonra["aM"] - 400.0) < 0.01
	_kaydi("Tur başında (R ile sahne yeniden kurulunca) zamanlı sayaç ve mandal sıfırlanır", once_ok and sonra_ok,
		"önce: zamanlı basılı=%s kalan=%d, mandal basılı=%s kilitli=%s; sonra: zamanlı=%s kalan=%d mandal=%s kilitli=%s, lazerler açık: %s/%s, geçitler y=%.0f/%.0f" % [
			once["pZ"], once["kZ"], once["pM"], once["kilitli"], sonra["pZ"], sonra["kZ"], sonra["pM"], sonra["kilitli"],
			sonra["lZ"], sonra["lM"], sonra["gZ"], sonra["gM"]])
	# Baştan başla (tam sıfırlama) yolu
	for i in range(30):
		_girdi_uygula({"yon": 1.0, "zipla": false})
		await physics_frame
	_girdi_uygula({"yon": 0.0, "zipla": false})
	await physics_frame
	var once2 := _pl_ornekle(yeni)
	var eski2 := yeni.get_instance_id()
	yeni.get_node("EkranButonlari/Kutu/YenidenDugmesi").pressed.emit()
	var y2: Node = await _yeni_sahne_bekle(eski2)
	await physics_frame
	var sonra2 := _pl_ornekle(y2)
	_kaydi("Baştan başla da zamanlı sayacı sıfırlar (tur 1, klon 0)",
		once2["pZ"] and not sonra2["pZ"] and sonra2["kZ"] == 0 and _klonlar(y2).size() == 0,
		"önce basılı=%s, sonra basılı=%s kalan=%d klon=%d" % [once2["pZ"], sonra2["pZ"], sonra2["kZ"], _klonlar(y2).size()])
	_kayitlar().sifirla()


## Determinizm (100x): zamanlı ve mandal birlikte, klon kayıttan.
func _pl_determinizm() -> void:
	var betik := _betik([[30, 1, false], [20, 0, false], [30, -1, false], [60, 0, false],
		[60, 1, false], [20, 0, false], [260, 0, false]])
	var s0: Dictionary = await _pl_calis([], betik, 480)
	var kayit: Array = _pl_kayit()
	var ref: Array = []
	var sapmali := 0
	var maks_fark := 0
	for r in range(TEKRAR):
		var s: Dictionary = await _pl_calis([kayit], [], 480)
		var iz: Array = s["ozel_iz"]
		if r == 0:
			ref = iz
			continue
		var f: int = _pl_iz_esit(iz, ref, PL_ANAHTARLAR)
		if f > 0:
			sapmali += 1
			maks_fark = maxi(maks_fark, f)
	var ra: Dictionary = _pl_aralik(ref, "pZ", "fZ")
	var rm: Dictionary = _pl_aralik(ref, "pM", "fM")
	_kaydi("Zamanlı + mandal determinizm (%dx, klon kayıttan)" % TEKRAR,
		sapmali == 0 and ra["ilk"] >= 0 and rm["ilk"] >= 0 and ref.size() >= 480,
		"%d kare, sapmalı çalıştırma: %d, en büyük kare farkı: %d, zamanlı kuyruk %d, mandal ilk basış %d" % [
			ref.size(), sapmali, maks_fark, ra["kuyruk"], rm["ilk"]])
	var lf: int = _pl_iz_esit(s0["ozel_iz"], ref, PL_ANAHTARLAR)
	_kaydi("Zamanlı + mandal: canlı oyuncu ile klon tekrarı aynı kareleri verir", lf == 0,
		"canlı/klon farkı: %d (anahtar x kare)" % lf)



# ---------------------------------------------------------------- arayüz (2026-10-15 gecesi)
# Sonuç ekranı, bölüm içi HUD, geçiş perdesi, ana menü, kontroller, harita yerleşimi.
# Not: KlonGostergesi/Yuva/TusRozeti/GecisKatmani headless'ta KURULMAZ (LabPaleti.ekransiz()).
# Test, ekran varken (headless olmayan çalıştırma) varlığı ve özellikleri, headless'ta
# kurulmadığını doğrular; ikisi de aynı gövdeden geçer.

const AR_B1 := "res://scenes/bolumler/bolum_1.tscn"
const AR_B4 := "res://scenes/bolumler/bolum_4.tscn"
const AR_B6 := "res://scenes/bolumler/bolum_6.tscn"
const AR_YERLESIM := "res://docs/devir/harita_yerlesim.md"


func _arayuz_testleri() -> void:
	_kayitlar().sifirla()
	paused = false
	await _ar_sonuc_ekrani()
	await _ar_sure_saatten_bagimsiz()
	await _ar_hud()
	await _ar_hud_bolum_etiketi()
	await _ar_perde()
	await _ar_ana_menu()
	await _ar_kontroller()
	await _ar_harita()
	_kayitlar().sifirla()
	paused = false


## user:// altındaki dosyalar (günlük dosyaları hariç): yol -> [değişme zamanı, boyut].
func _ar_user_goruntu() -> Dictionary:
	var cikti := {}
	var dizinler: Array = ["user://"]
	while not dizinler.is_empty():
		var d: String = dizinler.pop_back()
		var da := DirAccess.open(d)
		if da == null:
			continue
		for alt in da.get_directories():
			if alt == "logs":
				continue
			dizinler.append(d.path_join(alt))
		for f in da.get_files():
			var yol := d.path_join(f)
			var fa := FileAccess.open(yol, FileAccess.READ)
			cikti[yol] = [FileAccess.get_modified_time(yol), fa.get_length() if fa != null else -1]
	return cikti


## Verilen bölümü, `boyutlar` uzunluğunda boş klon kayıtlarıyla yükler, `bekle` kare bekler,
## canlı oyuncuyu kapıya taşır (gerçek Area2D/sinyal yolu) ve sonuç ekranını bekler.
func _ar_bitir(yol: String, boyutlar: Array, bekle := 30, gecikme_ms := 0) -> Dictionary:
	aktif_bolum = yol
	paused = false
	_kayitlar().sifirla()
	var toplam_onceki := 0
	for n in boyutlar:
		var k: Array = []
		for i in range(int(n)):
			k.append({"yon": 0.0, "zipla": false})
		_kayitlar().tur_kaydet(k)
		toplam_onceki += int(n)
	var b: Node = await _bolumu_yukle()
	for i in range(bekle):
		await physics_frame
	if gecikme_ms > 0:
		OS.delay_msec(gecikme_ms)
	var oyuncu: CharacterBody2D = b.get_node("Oyuncu")
	oyuncu.global_position = b.get_node("Kapi").global_position
	for i in range(6):
		await physics_frame
	var sonuc: Node = b.find_child("SonucEkrani", true, false)
	return {"bolum": b, "sonuc": sonuc, "kare": oyuncu.kare, "onceki": toplam_onceki, "klon": boyutlar.size(),
		"bitti": b.bitti}


func _ar_beklenen_sure(kare: int) -> String:
	var saniye := float(kare) / 60.0
	var dk := int(saniye) / 60
	return "Süre: %02d:%04.1f" % [dk, saniye - dk * 60]


func _ar_etiket(sonuc: Node, ad: String) -> Label:
	return sonuc.find_child(ad, true, false) as Label


func _ar_sonuc_ekrani() -> void:
	var once := _ar_user_goruntu()
	var r := RegEx.new()
	r.compile("^Süre: \\d\\d:\\d\\d\\.\\d$")
	# 1) Gerçek bölüm 1 çözümü (R + girdi yolu), süre fizik karesinden
	aktif_bolum = AR_B1
	var kayit: Array = await _kaydet(_dogru_kayit_betigi())
	var s: Dictionary = await _senaryo([kayit], _cozum_betigi(), COZUM_SINIR)
	var b1: Node = current_scene
	var sonuc: Node = b1.find_child("SonucEkrani", true, false)
	var toplam: int = b1.get_node("Oyuncu").kare + kayit.size()
	var sure_t := ""
	var tur_t := ""
	var klon_t := ""
	var rozet_var := false
	if sonuc != null:
		sure_t = _ar_etiket(sonuc, "SureEtiketi").text
		tur_t = _ar_etiket(sonuc, "TurEtiketi").text
		var ke := _ar_etiket(sonuc, "KlonEtiketi")
		klon_t = ke.text if ke != null else "(yok)"
		rozet_var = sonuc.find_child("AzKlonRozeti", true, false) != null
	_kaydi("Sonuç ekranı (gerçek Bölüm 1 çözümü): süre mm:ss.s fizik karesinden, tur ve klon etiketi",
		s["bitti"] and sonuc != null and sure_t == _ar_beklenen_sure(toplam) and r.search(sure_t) != null
		and tur_t == "Tur sayısı: 2" and klon_t == "Kullanılan klon: 1" and not rozet_var,
		"bitti: %s, toplam kare %d (kayıt %d + canlı %d), süre: \"%s\" (beklenen \"%s\"), tur: \"%s\", klon: \"%s\", rozet: %s" % [
			s["bitti"], toplam, kayit.size(), toplam - kayit.size(), sure_t, _ar_beklenen_sure(toplam), tur_t, klon_t, rozet_var])
	# 2) Rozet kuralı: yalnız ipucu_klon>0 ve klon<=ipucu
	var vakalar := [
		[AR_B1, [], false, "ipucu 0 (Bölüm 1), klon 0"],
		[AR_B1, [50], false, "ipucu 0 (Bölüm 1), klon 1"],
		[AR_B6, [], true, "ipucu 1 (Bölüm 6), klon 0"],
		[AR_B6, [50], true, "ipucu 1 (Bölüm 6), klon 1"],
		[AR_B6, [50, 50], false, "ipucu 1 (Bölüm 6), klon 2"],
		[AR_B4, [50, 50], true, "ipucu 2 (Bölüm 4), klon 2"],
		[AR_B4, [50, 50, 50], false, "ipucu 2 (Bölüm 4), klon 3"],
	]
	var sorun := ""
	for v in vakalar:
		var d: Dictionary = await _ar_bitir(v[0], v[1])
		var so: Node = d["sonuc"]
		var rozet: Node = so.find_child("AzKlonRozeti", true, false) if so != null else null
		var ke: Label = _ar_etiket(so, "KlonEtiketi") if so != null else null
		var beklenen_klon := "Kullanılan klon: %d" % d["klon"]
		var sure_ok: bool = so != null and _ar_etiket(so, "SureEtiketi").text == _ar_beklenen_sure(d["kare"] + d["onceki"])
		var ok: bool = so != null and (rozet != null) == v[2] and ke != null and ke.text == beklenen_klon and sure_ok
		if not ok:
			sorun += " [%s: rozet=%s beklenen=%s klon etiketi=\"%s\" süre ok=%s]" % [v[3], rozet != null, v[2], ke.text if ke != null else "yok", sure_ok]
		paused = false
	_kaydi("Sonuç ekranı: AzKlonRozeti yalnız ipucu_klon>0 ve klon<=ipucu; KlonEtiketi ve süre her vakada doğru",
		sorun == "", "%d vaka, sorunlar:%s" % [vakalar.size(), sorun if sorun != "" else " yok"])
	# 3) Süre biçimi: >1 dk
	var uzun: Dictionary = await _ar_bitir(AR_B1, [3600, 1000])
	var uso: Node = uzun["sonuc"]
	var u_t: String = _ar_etiket(uso, "SureEtiketi").text if uso != null else ""
	_kaydi("Sonuç ekranı süre biçimi dakikayı aşınca mm:ss.s (kayıtlar 3600+1000 kare)",
		uso != null and u_t == _ar_beklenen_sure(4600 + uzun["kare"]) and u_t.begins_with("Süre: 01:") and r.search(u_t) != null,
		"süre: \"%s\", beklenen \"%s\"" % [u_t, _ar_beklenen_sure(4600 + uzun["kare"])])
	paused = false
	# 4) Kalıcı dosya yazmaz
	var sonra := _ar_user_goruntu()
	var yeni_dosya: Array = []
	for yol in sonra:
		if not once.has(yol) or once[yol] != sonra[yol]:
			yeni_dosya.append(yol)
	_kaydi("Sonuç ekranı kalıcı dosya yazmaz (user:// altında yeni/değişen dosya yok)", yeni_dosya.is_empty(),
		"user:// dosya sayısı %d -> %d, yeni/değişen: %s" % [once.size(), sonra.size(), str(yeni_dosya)])
	_kayitlar().sifirla()


func _ar_sure_saatten_bagimsiz() -> void:
	var a: Dictionary = await _ar_bitir(AR_B6, [700, 40], 30, 0)
	var ta: String = _ar_etiket(a["sonuc"], "SureEtiketi").text if a["sonuc"] != null else ""
	var ka: int = a["kare"]
	var b: Dictionary = await _ar_bitir(AR_B6, [700, 40], 30, 900)   # 0,9 sn duvar saati gecikmesi
	var tb: String = _ar_etiket(b["sonuc"], "SureEtiketi").text if b["sonuc"] != null else ""
	var kb: int = b["kare"]
	paused = false
	_kaydi("Süre gerçek saatten bağımsız: aynı kayıt, farklı duvar saati -> aynı süre",
		ta != "" and ta == tb and ka == kb and ta == _ar_beklenen_sure(ka + 740),
		"çalıştırma 1: \"%s\" (%d kare), çalıştırma 2 (+900 ms gecikme): \"%s\" (%d kare)" % [ta, ka, tb, kb])
	_kayitlar().sifirla()


## Bölüm içi HUD: ekranlıda KlonGostergesi/Yuva/TusRozeti kurulur, headless'ta kurulmaz.
func _ar_hud() -> void:
	var ekransiz := LabPaleti.ekransiz()
	aktif_bolum = AR_B6
	_kayitlar().sifirla()
	var b: Node = await _bolumu_yukle()
	await physics_frame
	var bilgi_ok: bool = b.bilgi.text.begins_with("Tur 1 ") and b.bilgi.text.contains("Klon: 0/2")
	var g: Node = b.find_child("KlonGostergesi", true, false)
	if ekransiz:
		_kaydi("HUD [headless]: KlonGostergesi kurulmaz, metin etiketi (Bilgi) korunur", g == null and bilgi_ok,
			"KlonGostergesi: %s, Bilgi: \"%s\" (ekranlı doğrulama için headless olmayan çalıştırma gerekir)" % [g != null, b.bilgi.text])
		return
	var yuva_say := 0
	var dolu := 0
	var yuva_ok := true
	var rozet: Control = b.find_child("TusRozeti", true, false) as Control
	if g != null:
		for c in g.get_children():
			if c.name.begins_with("Yuva"):
				yuva_say += 1
				if (c as Control).mouse_filter != Control.MOUSE_FILTER_IGNORE:
					yuva_ok = false
				var st: StyleBoxFlat = c.get_theme_stylebox("panel")
				if st.bg_color == LabPaleti.KLON:
					dolu += 1
	var rozet_ok: bool = rozet != null and rozet.mouse_filter == Control.MOUSE_FILTER_IGNORE and (rozet as Label).text == "R"
	_kaydi("HUD [ekranlı]: klon yuvaları (max_klon adet, hepsi boş), TusRozeti, girdiyi yutmaz",
		g != null and yuva_say == 2 and dolu == 0 and yuva_ok and rozet_ok and bilgi_ok,
		"KlonGostergesi: %s, yuva: %d, dolu: %d, yuvalar IGNORE: %s, rozet: %s" % [g != null, yuva_say, dolu, yuva_ok, rozet_ok])
	# Gerçek R yolu: bir klon kaydedilince Yuva1 dolu, rozet kalır; ikinciden sonra rozet kalkar
	var ozet := ""
	var tamam := true
	for tur in range(2):
		for i in range(10):
			_girdi_uygula({"yon": 0.0, "zipla": false})
			await physics_frame
		var eski_id := b.get_instance_id()
		await _r_bas()
		b = await _yeni_sahne_bekle(eski_id)
		await physics_frame
		var g2: Node = b.find_child("KlonGostergesi", true, false)
		var d := 0
		var n := 0
		if g2 != null:
			for c in g2.get_children():
				if c.name.begins_with("Yuva"):
					n += 1
					if (c.get_theme_stylebox("panel") as StyleBoxFlat).bg_color == LabPaleti.KLON:
						d += 1
		var r2: Node = b.find_child("TusRozeti", true, false)
		var beklenen_rozet: bool = tur == 0
		var ok: bool = n == 2 and d == tur + 1 and (r2 != null) == beklenen_rozet
		tamam = tamam and ok
		ozet += " tur%d: yuva=%d dolu=%d rozet=%s;" % [tur + 2, n, d, r2 != null]
	_kaydi("HUD [ekranlı]: R sonrası dolu yuva sayısı klon sayısına eşit, hak bitince TusRozeti kalkar", tamam, ozet)
	_kayitlar().sifirla()


## Geçiş perdesi: ekranlıda kurulur (IGNORE, girdiyi yutmaz, kendiliğinden kalkar), headless'ta kurulmaz.
func _ar_perde() -> void:
	aktif_bolum = AR_B1
	_kayitlar().sifirla()
	var b: Node = await _bolumu_yukle()
	var katman: Node = b.find_child("GecisKatmani", true, false)
	if LabPaleti.ekransiz():
		await physics_frame
		_kaydi("Geçiş perdesi [headless]: GecisKatmani kurulmaz", katman == null,
			"GecisKatmani: %s (ekranlı doğrulama için headless olmayan çalıştırma gerekir)" % [katman != null])
		return
	var perde: Control = null
	var katman_no := -1
	var vardi: bool = katman != null
	if katman != null:
		perde = katman.find_child("Perde", true, false) as Control
		katman_no = (katman as CanvasLayer).layer
	var ignore_ok: bool = perde != null and perde.mouse_filter == Control.MOUSE_FILTER_IGNORE
	# Perde varken girdi çalışır: 20 kare sağa yürü
	var x0: float = b.get_node("Oyuncu").global_position.x
	for i in range(20):
		_girdi_uygula({"yon": 1.0, "zipla": false})
		await physics_frame
	_girdi_uygula({"yon": 0.0, "zipla": false})
	var hareket: float = b.get_node("Oyuncu").global_position.x - x0
	for i in range(30):
		await physics_frame
	var kalkti: bool = not is_instance_valid(katman)
	_kaydi("Geçiş perdesi [ekranlı]: katman 20, Perde mouse_filter IGNORE, girdi çalışır, kendiliğinden kalkar",
		vardi and ignore_ok and katman_no == 20 and hareket > 20.0 and kalkti,
		"katman: %s (layer %d), IGNORE: %s, perde varken hareket: %.0f px, 0,5 sn sonra kalktı: %s" % [
			vardi, katman_no, ignore_ok, hareket, kalkti])
	_kayitlar().sifirla()


func _ar_sahne_yukle(yol: String) -> Node:
	var eski_id := current_scene.get_instance_id() if current_scene != null else 0
	paused = false
	change_scene_to_file(yol)
	return await _yeni_sahne_bekle(eski_id)


## Fare tıklaması (gerçek GUI yolu): viewport koordinatında basma + bırakma.
func _ar_tikla(kontrol: Control) -> void:
	var nokta := kontrol.get_global_rect().get_center()
	var hareket := InputEventMouseMotion.new()
	hareket.position = nokta
	hareket.global_position = nokta
	root.push_input(hareket, true)
	await physics_frame
	for basili in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.position = nokta
		e.global_position = nokta
		e.pressed = basili
		if basili:
			e.button_mask = MOUSE_BUTTON_MASK_LEFT
		root.push_input(e, true)
		await physics_frame


func _ar_ana_menu() -> void:
	_kayitlar().sifirla()
	var m: Node = await _ar_sahne_yukle("res://scenes/ana_menu.tscn")
	await physics_frame
	var oyna: Button = m.find_child("OynaDugmesi", true, false)
	var kont: Button = m.get_node_or_null("%KontrollerDugmesi")
	var cik: Button = m.find_child("CikDugmesi", true, false)
	var var_ok: bool = oyna != null and kont != null and cik != null
	var odak_ok := false
	var cik_bagli := false
	var metin := ""
	if var_ok:
		odak_ok = oyna.has_focus() or oyna.focus_mode == Control.FOCUS_NONE
		cik_bagli = cik.pressed.get_connections().size() > 0
		metin = "%s/%s/%s" % [oyna.text, kont.text, cik.text]
	_kaydi("Ana menü: Oyna, Kontroller, Çıkış düğmeleri var; Çıkış bir eyleme bağlı",
		var_ok and cik_bagli, "düğmeler: %s, çıkış bağlı: %s, odak: Oyna focus_mode=%d has_focus=%s" % [
			metin, cik_bagli, oyna.focus_mode if oyna != null else -1, oyna.has_focus() if oyna != null else false])
	# Dekor düğümleri tıklamayı yutmaz: tüm tam ekran dekor Control'leri IGNORE
	var yutan: Array = []
	for c in m.get_children():
		if c is Control and c.name != "Ortala" and (c as Control).mouse_filter == Control.MOUSE_FILTER_STOP:
			yutan.append(str(c.name))
	_kaydi("Ana menü: arka plan/animasyon düğümleri fare olayını yutmaz", yutan.is_empty(),
		"STOP filtreli dekor düğümü: %s" % str(yutan))
	# Kontroller düğmesi: gerçek tıklama
	var eski_id := m.get_instance_id()
	await _ar_tikla(kont)
	var k: Node = await _yeni_sahne_bekle(eski_id)
	var gitti: bool = k != null and k.scene_file_path.ends_with("kontroller.tscn")
	if not gitti:
		# Tıklama yolu çalışmadıysa (ortam kısıtı) düğme sinyaliyle doğrula ve belirt
		kont.pressed.emit()
		k = await _yeni_sahne_bekle(eski_id)
	_kaydi("Ana menü: Kontroller düğmesi kontroller ekranını açar (gerçek tıklama: %s)" % ("evet" if gitti else "hayır, sinyalle"),
		k != null and k.scene_file_path.ends_with("kontroller.tscn"),
		"tıklama sahneyi değiştirdi: %s, sahne: %s" % [gitti, k.scene_file_path if k != null else "yok"])
	# Oyna düğmesi -> harita
	var m2: Node = await _ar_sahne_yukle("res://scenes/ana_menu.tscn")
	await physics_frame
	var oyna2: Button = m2.find_child("OynaDugmesi", true, false)
	var id2 := m2.get_instance_id()
	await _ar_tikla(oyna2)
	var h: Node = await _yeni_sahne_bekle(id2)
	var oyna_gitti: bool = h != null and h.scene_file_path.ends_with("harita.tscn")
	if not oyna_gitti:
		oyna2.pressed.emit()
		h = await _yeni_sahne_bekle(id2)
	_kaydi("Ana menü: Oyna düğmesi haritayı açar (gerçek tıklama: %s)" % ("evet" if oyna_gitti else "hayır, sinyalle"),
		h != null and h.scene_file_path.ends_with("harita.tscn"),
		"tıklama sahneyi değiştirdi: %s" % oyna_gitti)


func _ar_kontroller() -> void:
	var eylemler := ["sol", "sag", "zipla", "asagi", "tur_bitir"]
	# Geçici bir tuş ekle: etiket InputMap'ten gelmiyorsa görünmez
	var ek := InputEventKey.new()
	ek.physical_keycode = KEY_F9
	ek.keycode = KEY_F9
	InputMap.action_add_event("zipla", ek)
	var k: Node = await _ar_sahne_yukle("res://scenes/kontroller.tscn")
	await physics_frame
	var kutu: Node = k.find_child("Kutu", true, false)
	var satirlar: Array = []
	for c in kutu.get_children():
		if c is HBoxContainer:
			var etiketler: Array = c.get_children().filter(func(x): return x is Label)
			if etiketler.size() >= 2:
				satirlar.append([etiketler[0].text, etiketler[1].text])
	var sorun := ""
	var beklenen_metinler: Array = []
	for e in eylemler:
		var adlar: Array = []
		for ev in InputMap.action_get_events(e):
			if ev is InputEventKey:
				var kod: int = ev.physical_keycode if ev.physical_keycode != 0 else ev.keycode
				var ad: String = load("res://scripts/kontroller.gd").TUS_ADLARI.get(kod, OS.get_keycode_string(kod))
				if ad != "" and not adlar.has(ad):
					adlar.append(ad)
		var bek := " / ".join(adlar)
		beklenen_metinler.append(bek)
		var bulundu := false
		for s in satirlar:
			if s[1] == bek:
				bulundu = true
		if adlar.is_empty() or not bulundu:
			sorun += " %s(beklenen \"%s\")" % [e, bek]
	var f9_var := false
	for s in satirlar:
		if s[1].contains("F9"):
			f9_var = true
	InputMap.action_erase_event("zipla", ek)
	_kaydi("Kontroller ekranı: tuş adları InputMap'ten gelir (eklenen F9 görünür), 5 eylem satırı",
		sorun == "" and f9_var and satirlar.size() >= 5,
		"satırlar: %s, sorunlar:%s, geçici F9 görüldü: %s" % [str(satirlar), sorun if sorun != "" else " yok", f9_var])
	var geri: Button = k.find_child("GeriDugmesi", true, false)
	var odak_ok: bool = geri != null and geri.focus_mode == Control.FOCUS_NONE
	var id := k.get_instance_id()
	await _ar_tikla(geri)
	var m: Node = await _yeni_sahne_bekle(id)
	var tikla_ok: bool = m != null and m.scene_file_path.ends_with("ana_menu.tscn")
	if not tikla_ok:
		geri.pressed.emit()
		m = await _yeni_sahne_bekle(id)
	_kaydi("Kontroller ekranı: GeriDugmesi (focus_mode NONE) ana menüye döner (gerçek tıklama: %s)" % ("evet" if tikla_ok else "hayır, sinyalle"),
		odak_ok and m != null and m.scene_file_path.ends_with("ana_menu.tscn"),
		"focus_mode NONE: %s, dönülen sahne: %s" % [odak_ok, m.scene_file_path if m != null else "yok"])


## docs/devir/harita_yerlesim.md tablosundaki konumlar (indeks = bölüm no - 1).
func _ar_yerlesim_tablosu() -> Array:
	var metin := FileAccess.get_file_as_string(AR_YERLESIM)
	var r := RegEx.new()
	r.compile("\\|\\s*(\\d+)\\s*\\|\\s*Vector2\\(\\s*(-?\\d+)\\s*,\\s*(-?\\d+)\\s*\\)")
	var tablo: Array = []
	for m in r.search_all(metin):
		var no := int(m.get_string(1))
		while tablo.size() < no:
			tablo.append(Vector2.ZERO)
		tablo[no - 1] = Vector2(int(m.get_string(2)), int(m.get_string(3)))
	return tablo


## Düğüm konumları (zincir sırasıyla) için yerleşim denetimi: mesafe >= 100, zincir bağlantıları kesişmez
## ve komşu olmayan düğüme girmez, kutular ekran/başlık/Geri alanı içinde, hover etiketi başka düğüme binmez.
func _ar_yerlesim_denetle(tum: Array) -> Dictionary:
	var yaricap: float = HaritaDugumu.YARICAP
	var m := tum.size()
	var mesafe_sorun := ""
	var en_yakin := 1.0e9
	for i in range(m):
		for j in range(i + 1, m):
			var d: float = (tum[i] as Vector2).distance_to(tum[j])
			en_yakin = minf(en_yakin, d)
			if d < 100.0:
				mesafe_sorun += " %d-%d(%.0f)" % [i + 1, j + 1, d]
	var parcalar: Array = []
	for i in range(m - 1):
		var a: Vector2 = tum[i]
		var bb: Vector2 = tum[i + 1]
		var yon := (bb - a).normalized()
		parcalar.append([a + yon * yaricap, bb - yon * yaricap, i, i + 1])
	var kesisim := ""
	for i in range(parcalar.size()):
		for j in range(i + 1, parcalar.size()):
			if _segment_kesisir(parcalar[i][0], parcalar[i][1], parcalar[j][0], parcalar[j][1]):
				kesisim += " %d x %d" % [i + 1, j + 1]
		for k in range(m):
			if k == parcalar[i][2] or k == parcalar[i][3]:
				continue
			var dd: float = _nokta_parca_uzakligi(tum[k], parcalar[i][0], parcalar[i][1])
			if dd < yaricap + 20.0:
				kesisim += " çizgi%d~düğüm%d(%.0f)" % [i + 1, k + 1, dd]
	var alan := Rect2(Vector2(40, 105), Vector2(1152 - 80, 576 - 105))
	var geri := Rect2(Vector2(24, 576), Vector2(140, 48))
	var sinir := ""
	for i in range(m):
		var kutu := Rect2((tum[i] as Vector2) - Vector2(yaricap, yaricap), Vector2(yaricap, yaricap) * 2.0)
		if not alan.encloses(kutu) or kutu.intersects(geri):
			sinir += " %d" % [i + 1]
	var bin := ""
	for i in range(m):
		var p: Vector2 = tum[i]
		var etiket_dikd := Rect2(Vector2(clampf(p.x - 140.0, 4.0, 1152.0 - 284.0), p.y + yaricap + 14.0), Vector2(280, 30))
		for j in range(m):
			if i == j:
				continue
			var q: Vector2 = tum[j]
			var hex := Rect2(q - Vector2(yaricap, yaricap), Vector2(yaricap, yaricap) * 2.0)
			if etiket_dikd.intersects(hex):
				bin += " etiket%d~düğüm%d" % [i + 1, j + 1]
	return {"mesafe": mesafe_sorun, "en_yakin": en_yakin, "kesisim": kesisim, "sinir": sinir, "bin": bin}


func _ar_harita() -> void:
	var h: Node = await _ar_sahne_yukle("res://scenes/harita.tscn")
	await physics_frame
	var kayitlar: Array = BolumListesi.liste()
	var n: int = kayitlar.size()
	# 1) ad ve hover etiketi "Bölüm N: Ad"
	var sorun := ""
	for i in range(n):
		var ad: String = str(kayitlar[i].get("ad", ""))
		var dugme: Control = h.get_node_or_null("Dugumler/Dugum%d" % (i + 1))
		var etiket: Label = h.get_node_or_null("Dugumler/Etiket%d" % (i + 1))
		if ad == "" or dugme == null or etiket == null:
			sorun += " %d(ad=\"%s\", düğüm=%s, etiket=%s)" % [i + 1, ad, dugme != null, etiket != null]
			continue
		var beklenen := "Bölüm %d: %s" % [i + 1, ad]
		if str(kayitlar[i].get("kaynak", "resmi")) == "canli":
			beklenen += " · Canlı"
		var gizli_basta: bool = not etiket.visible
		dugme.mouse_entered.emit()
		var acik: bool = etiket.visible and etiket.text == beklenen
		dugme.mouse_exited.emit()
		var kapandi: bool = not etiket.visible
		if not (gizli_basta and acik and kapandi and BolumListesi.ad(kayitlar[i]["yol"]) == ad):
			sorun += " %d(\"%s\" gizli:%s açık:%s kapandı:%s)" % [i + 1, etiket.text, gizli_basta, acik, kapandi]
	_kaydi("Harita: her kayıtta ad var, hover etiketi \"Bölüm N: Ad\" gösterir/gizler (%d kayıt)" % n,
		sorun == "" and n >= 14, "sorunlar:%s" % (sorun if sorun != "" else " yok"))
	# 2) Konumlar: liste konumu = HaritaYerlesimi.konum(i, n); harita_yerlesim.md tablosu 21 bölümün konumudur
	# (HaritaYerlesimi.konum(i, 21) ile birebir aynı olmalı; canlı bölüm eklenince tablo değil işlev geçerlidir).
	var tablo: Array = _ar_yerlesim_tablosu()
	var konum_sorun := ""
	for i in range(n):
		if (kayitlar[i]["konum"] as Vector2).distance_to(HaritaYerlesimi.konum(i, n)) > 0.01:
			konum_sorun += " %d(kayıt %s, işlev %s)" % [i + 1, str(kayitlar[i]["konum"]), str(HaritaYerlesimi.konum(i, n))]
	var tablo_sorun := ""
	for i in range(tablo.size()):
		if (tablo[i] as Vector2).distance_to(HaritaYerlesimi.konum(i, tablo.size())) > 0.01:
			tablo_sorun += " %d(tablo %s, işlev %s)" % [i + 1, str(tablo[i]), str(HaritaYerlesimi.konum(i, tablo.size()))]
	_kaydi("Harita: liste konumları HaritaYerlesimi.konum(i, n) ile, harita_yerlesim.md tablosu HaritaYerlesimi.konum(i, %d) ile eşleşir (%d kayıt)" % [tablo.size(), n],
		konum_sorun == "" and tablo_sorun == "" and tablo.size() >= 21 and n >= 1, "liste:%s | tablo:%s" % [konum_sorun if konum_sorun != "" else " yok", tablo_sorun if tablo_sorun != "" else " yok"])
	# 3) Kayıt sayısı kadar düğümlük yerleşim (şimdiki kayıtlar): mesafe >= 100, çizgi kesmez
	var tum: Array = []
	for i in range(n):
		tum.append(kayitlar[i]["konum"])
	var r1: Dictionary = _ar_yerlesim_denetle(tum)
	_kaydi("Harita %d düğümlük yerleşim (kayıt sayısı kadar): en yakın düğümler >= 100 px, çizgiler kesişmez/düğüme girmez, ekran ve başlık/Geri alanı içinde" % n,
		r1["mesafe"] == "" and r1["kesisim"] == "" and r1["sinir"] == "" and n >= 2,
		"en yakın mesafe %.0f px, mesafe sorunu:%s, kesişim:%s, sınır dışı:%s" % [
			r1["en_yakin"], r1["mesafe"] if r1["mesafe"] != "" else " yok",
			r1["kesisim"] if r1["kesisim"] != "" else " yok", r1["sinir"] if r1["sinir"] != "" else " yok"])
	# 4) Hover etiketi başka düğüme binmez (kayıt sayısı kadar yerleşim)
	_kaydi("Harita %d düğümlük yerleşim (kayıt sayısı kadar): hover etiketi komşu düğüme binmez" % n,
		r1["bin"] == "", "binme:%s" % (r1["bin"] if r1["bin"] != "" else " yok"))
	# 5) harita_yerlesim.md'deki TÜM satırlar aynı kısıtları sağlar
	var r2: Dictionary = _ar_yerlesim_denetle(tablo)
	var tablo_bos := false
	for v in tablo:
		tablo_bos = tablo_bos or v == Vector2.ZERO
	_kaydi("Harita yerleşim tablosu (%d satır): mesafe >= 100, çizgiler kesişmez/düğüme girmez, ekran/başlık/Geri içinde, hover etiketi binmez" % tablo.size(),
		tablo.size() >= 21 and not tablo_bos and r2["mesafe"] == "" and r2["kesisim"] == "" and r2["sinir"] == "" and r2["bin"] == "",
		"satır %d, en yakın mesafe %.0f px, mesafe:%s, kesişim:%s, sınır:%s, etiket binme:%s" % [
			tablo.size(), r2["en_yakin"], r2["mesafe"] if r2["mesafe"] != "" else " yok", r2["kesisim"] if r2["kesisim"] != "" else " yok",
			r2["sinir"] if r2["sinir"] != "" else " yok", r2["bin"] if r2["bin"] != "" else " yok"])
	# 6) A12: 22 / 30 / 40 düğümlük yapay listeler (HaritaYerlesimi.konum) aynı kısıtları sağlar
	for m in [22, 25, 30, 36, 40]:
		var yapay: Array = []
		for i in range(m):
			yapay.append(HaritaYerlesimi.konum(i, m))
		var r3: Dictionary = _ar_yerlesim_denetle(yapay)
		_kaydi("Harita yerleşimi %d düğüm (HaritaYerlesimi): mesafe >= 100, çizgiler kesişmez/düğüme girmez, ekran/başlık/Geri içinde, hover etiketi binmez" % m,
			r3["mesafe"] == "" and r3["kesisim"] == "" and r3["sinir"] == "" and r3["bin"] == "",
			"en yakın mesafe %.0f px, mesafe:%s, kesişim:%s, sınır:%s, etiket binme:%s" % [
				r3["en_yakin"], r3["mesafe"] if r3["mesafe"] != "" else " yok", r3["kesisim"] if r3["kesisim"] != "" else " yok",
				r3["sinir"] if r3["sinir"] != "" else " yok", r3["bin"] if r3["bin"] != "" else " yok"])
	_kayitlar().sifirla()


# ================================================================ BÖLÜM 15-17 (Fitil / Mandal / Çifte Mühür)
# Taslaklar: docs/devir/bolum_15_taslak.md, bolum_16_taslak.md, bolum_17_taslak.md (sayılar tahmindir,
# bu bloklar ölçerek doğrular). Ortak koşullu oynatıcı: `_n_*`; adım biçimi `_b13_a`.
const BOLUM_15 := "res://scenes/bolumler/bolum_15.tscn"
const BOLUM_16 := "res://scenes/bolumler/bolum_16.tscn"
const BOLUM_17 := "res://scenes/bolumler/bolum_17.tscn"

var _n_onbellek: Dictionary = {}   # bölüm yolu -> kayıt listesi


## Bölümdeki her plaka/lazer/geçit/kutu durumunu ad -> değer sözlüğüne yazar (yalnız okur).
func _n_ornekle(b: Node) -> Dictionary:
	var d := {}
	for c in b.get_children():
		if c is BasincPlakasi:
			d[c.name] = c.basili_mi()
			d[str(c.name) + "_f"] = c.has_overlapping_bodies()
		elif c.has_method("acik_mi"):
			d[c.name] = c.acik_mi()
		elif c.get("kayma_mesafe") != null:
			d[c.name] = c.position.y
		elif c.name == "Kutu":
			d[c.name] = c.global_position
	d["zemin"] = b.get_node("Oyuncu").is_on_floor()
	d["vy"] = b.get_node("Oyuncu").velocity.y
	return d


## `_b14_kosullu` ile aynı sözleşme: adımlar koşul sağlanana ya da `maks` kareye kadar oynar.
func _n_kosullu(bolum: Node, adimlar: Array, sayac: Array) -> Dictionary:
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
			_girdi_uygula({"yon": a["yon"], "zipla": a["zipla"] and n == 0, "asagi": a.get("asagi", false)})
			iz.append(oyuncu.global_position)
			ozel.append(_n_ornekle(bolum))
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
	return {"kare": kare, "bitti": bitti_son and sayac[0] == 0, "bitti_ham": bitti_son, "oldu": sayac[0],
		"iz": iz, "ozel": ozel, "klon_izleri": klon_iz, "baslangic": baslangic, "tamam": tamam,
		"kayit": kayit, "klon_oldu": klon_oldu}


func _n_senaryo(kayitlar: Array, adimlar: Array, hazirlik := Callable()) -> Dictionary:
	_kayitlar().sifirla()
	for k in kayitlar:
		_kayitlar().tur_kaydet(k.duplicate(true))
	var bolum: Node = await _bolumu_yukle()
	if hazirlik.is_valid():
		hazirlik.call(bolum)
	var sayac := [0]
	bolum.get_node("Oyuncu").oyuncu_oldu.connect(func() -> void: sayac[0] += 1)
	var s: Dictionary = await _n_kosullu(bolum, adimlar, sayac)
	paused = false
	return s


func _n_p(ad: String) -> Callable:
	return func(b: Node) -> bool: return b.get_node(ad).basili_mi()


## Plakada basılı ve yerde.
func _n_plakada(ad: String) -> Callable:
	return func(b: Node) -> bool: return b.get_node(ad).basili_mi() and b.get_node("Oyuncu").is_on_floor()


func _n_kapali(ad: String) -> Callable:
	return func(b: Node) -> bool: return not b.get_node(ad).acik_mi()


func _n_kare_ge(n: int) -> Callable:
	return func(b: Node) -> bool: return b.get_node("Oyuncu").kare >= n


func _n_zemin() -> Callable:
	return func(b: Node) -> bool: return b.get_node("Oyuncu").is_on_floor()


## Oyuncu y'si (merkez) bu değerin altına/eşit indi.
func _n_y_le(v: float) -> Callable:
	return func(b: Node) -> bool: return b.get_node("Oyuncu").global_position.y <= v


func _n_y_ge(v: float) -> Callable:
	return func(b: Node) -> bool: return b.get_node("Oyuncu").global_position.y >= v


func _n_gecit_ust(ad: String, y: float) -> Callable:
	return func(b: Node) -> bool: return b.get_node(ad).position.y <= y


func _n_ve(a: Callable, c: Callable) -> Callable:
	return func(b: Node) -> bool: return a.call(b) and c.call(b)


func _n_son(s: Dictionary) -> Vector2:
	return s["iz"][s["iz"].size() - 1] if s["iz"].size() > 0 else Vector2.ZERO


## Oyuncu izinden en büyük/küçük x, en küçük ayak y, en büyük y.
func _n_olc(s: Dictionary) -> Dictionary:
	var xmax := -1.0e9
	var xmin := 1.0e9
	var ayak := 1.0e9
	var ymax := -1.0e9
	for p in s["iz"]:
		xmax = maxf(xmax, p.x)
		xmin = minf(xmin, p.x)
		ayak = minf(ayak, p.y + 24.0)
		ymax = maxf(ymax, p.y)
	return {"xmax": xmax, "xmin": xmin, "ayak": ayak, "ymax": ymax}


## İlk karesi: ozel[f][anahtar] == deger (yoksa -1).
func _n_ilk(s: Dictionary, anahtar: String, deger: Variant, bas := 0) -> int:
	for f in range(bas, s["ozel"].size()):
		if s["ozel"][f].get(anahtar) == deger:
			return f
	return -1


## Verilen iz üzerinde x >= v olan ilk kare (yoksa -1).
func _n_x_kare(iz: Array, v: float, bas := 0) -> int:
	for f in range(bas, iz.size()):
		if iz[f].x >= v:
			return f
	return -1


func _n_iz_yaz(s: Dictionary, adim := 5, bas := 0, son := -1, anahtarlar := []) -> String:
	var t: Array = []
	var e: int = s["iz"].size() if son < 0 else mini(son, s["iz"].size())
	for f in range(bas, e, adim):
		var o: Dictionary = s["ozel"][f]
		var ek := ""
		for a in anahtarlar:
			var v: Variant = o.get(a)
			if v is bool:
				ek += " %s=%s" % [a, "1" if v else "0"]
			elif v is float:
				ek += " %s=%.0f" % [a, v]
		t.append("%d:(%.1f,%.1f)%s%s" % [f, s["iz"][f].x, s["iz"][f].y, "z" if o["zemin"] else "", ek])
	return "\n".join(t)


func _n_kutu_x_ge(v: float) -> Callable:
	return func(b: Node) -> bool: return b.get_node("Kutu").global_position.x >= v


func _n_yerlestir(oyuncu: Vector2, kutu := Vector2(-1.0, -1.0)) -> Callable:
	return func(b: Node) -> void:
		b.get_node("Oyuncu").global_position = oyuncu
		if kutu.x >= 0.0:
			b.get_node("Kutu").global_position = kutu


## n adım: yon + zıplama basılı (her adımda yeniden basış).
func _n_spam(yon: float, n := 8, kare := 25) -> Array:
	return _b8_zipla_dizisi(n, yon, kare)


## Oyuncu girdisi bu adımlarla bölümü bitirir mi.
func _n_bitirir(klonlar: Array, adimlar: Array) -> bool:
	var s: Dictionary = await _n_senaryo(klonlar, adimlar)
	return s["bitti_ham"] and s["oldu"] == 0


## Verilen değerleri sırayla dener: f(v) -> bool (coroutine). Sonuç listesi döner.
func _n_sup(vs: Array, f: Callable) -> Array:
	var oks: Array = []
	for v in vs:
		oks.append(bool(await f.call(v)))
	return oks


## Aralık özeti: ardışık geçen değerler "lo..hi" parçaları.
func _n_ar(vs: Array, oks: Array) -> String:
	return _b13_aralik_yaz(vs, oks)


## Pencere iddiası: değer listede varsa ve beklenen sonuçla eşleşiyorsa true (yoksa KALDI).
func _n_pen(vs: Array, oks: Array, v: int, beklenen := true) -> bool:
	var i: int = vs.find(v)
	return i >= 0 and bool(oks[i]) == beklenen


## Ok olan değerlerin en büyüğü / en küçüğü (yoksa -1).
func _n_en_buyuk(vs: Array, oks: Array) -> int:
	var m := -1
	for i in range(vs.size()):
		if oks[i]:
			m = maxi(m, int(vs[i]))
	return m


func _n_en_kucuk(vs: Array, oks: Array) -> int:
	var m := 1000000
	for i in range(vs.size()):
		if oks[i]:
			m = mini(m, int(vs[i]))
	return m if m < 1000000 else -1


## Gerçek R yolu: her klon turu bittiğinde R basılır; son tur oyuncu. Etiket/kare/ölüm doğrulanır.
func _n_cozum(ad: String, turlar: Array, oyuncu: Array, kaynak_max: int) -> void:
	_kayitlar().sifirla()
	var bolum: Node = await _bolumu_yukle()
	var kareler: Array = []
	var olumsuz := ""
	for i in range(turlar.size()):
		var sayac := [0]
		bolum.get_node("Oyuncu").oyuncu_oldu.connect(func() -> void: sayac[0] += 1)
		var klon_once: int = _klonlar(bolum).size()
		var s: Dictionary = await _n_kosullu(bolum, turlar[i], sayac)
		kareler.append(s["kare"])
		if s["tamam"].has(false) or s["oldu"] > 0 or s["kare"] > 600 or klon_once != i:
			olumsuz += " tur%d adım karşılanmadı %s oldu=%d kare=%d klon=%d;" % [i + 1, str(s["tamam"]), s["oldu"], s["kare"], klon_once]
		var eski_id := bolum.get_instance_id()
		await _r_bas()
		bolum = await _yeni_sahne_bekle(eski_id)
		if bolum == null:
			_kaydi(ad, false, "tur %d sonrası sahne yüklenmedi;%s" % [i + 1, olumsuz])
			return
	var klon_basta: int = _klonlar(bolum).size()
	var etiket: String = bolum.bilgi.text
	var sayac4 := [0]
	bolum.get_node("Oyuncu").oyuncu_oldu.connect(func() -> void: sayac4[0] += 1)
	var s4: Dictionary = await _n_kosullu(bolum, oyuncu, sayac4)
	var hepsi_600 := true
	for k in kareler:
		hepsi_600 = hepsi_600 and k <= 600
	var gecti: bool = s4["bitti"] and klon_basta == turlar.size() and _kayitlar().turlar.size() == turlar.size() \
		and etiket.contains("Klon: %d/%d" % [turlar.size(), kaynak_max]) and olumsuz == "" and s4["kare"] <= 600 \
		and s4["oldu"] == 0 and hepsi_600 and not s4["tamam"].has(false)
	_kaydi(ad, gecti, "bitti: %s, tur kareleri: %s + %d (%.2f sn), klon: %d, kayıtlı tur: %d, ölüm: %d, etiket: \"%s\"%s" % [
		s4["bitti"], str(kareler), s4["kare"], s4["kare"] / 60.0, klon_basta, _kayitlar().turlar.size(),
		s4["oldu"], etiket, olumsuz])
	_kayitlar().sifirla()
	paused = false


## Klon sınırı: max_klon kadar R klon kaydeder, bir sonraki R kaydetmez.
func _n_klon_siniri(ad: String, beklenen_max: int) -> void:
	_kayitlar().sifirla()
	var bolum: Node = await _bolumu_yukle()
	var maks: int = bolum.max_klon
	var gecti := maks == beklenen_max
	var ayr: Array = []
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
				and yazi.contains("%d/%d" % [maks, maks])
			ayr.append("sınırda etiket: \"%s\"" % yazi)
		ayr.append("R #%d -> kayıtlı klon: %d" % [n + 1, sayi])
	_kaydi(ad, gecti, "max_klon=%d; %s" % [maks, ", ".join(ayr)])
	_kayitlar().sifirla()


## Determinizm: çözüm 100x aynı kayıtla yeniden oynatılır, her karede bütün durumlar karşılaştırılır.
func _n_determinizm(ad: String, kay: Array, oyuncu: Array, tekrar := TEKRAR) -> void:
	var s0: Dictionary = await _n_senaryo(kay, oyuncu)
	var betik: Array = s0["kayit"]
	var ornek := func(b: Node) -> Dictionary: return _n_ornekle(b)
	var referans: Dictionary = {}
	var sapmali := 0
	var bitmeyen := 0
	var maks_sapma := 0.0
	for n in range(tekrar):
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
			for ki in range(kay.size()):
				d = maxf(d, (s["klon_izleri"][ki][f] - referans["klon_izleri"][ki][f]).length())
			if d > 0.0:
				bu = true
				maks_sapma = maxf(maks_sapma, d)
		if bu:
			sapmali += 1
	_kaydi(ad, sapmali == 0 and bitmeyen == 0 and s0["bitti_ham"],
		"%d çalıştırma x %d kare, sapmalı: %d, en büyük sapma: %.4f px, bitirmeyen çalıştırma: %d, kayıt turu bitti: %s" % [
			tekrar, referans["kare"], sapmali, maks_sapma, bitmeyen, s0["bitti_ham"]])
	_kayitlar().sifirla()
	paused = false


## Canlı turun kaydını klon olarak oynatıp en büyük konum farkını (px) ve ilk sapma karesini verir.
func _n_klon_fark(onceki: Array, adim: Array) -> Dictionary:
	var canli: Dictionary = await _n_senaryo(onceki, adim)
	var tekrar: Dictionary = await _n_senaryo(onceki + [canli["kayit"]], [_b13_a(0, Callable(), canli["kare"] + 1)])
	var idx: int = onceki.size()
	var maks := 0.0
	var ilk := -1
	var ilk_x := 0.0
	for f in range(mini(canli["iz"].size(), tekrar["klon_izleri"][idx].size())):
		var fark: float = (canli["iz"][f] - tekrar["klon_izleri"][idx][f]).length()
		if fark > 0.01 and ilk < 0:
			ilk = f
			ilk_x = canli["iz"][f].x
		maks = maxf(maks, fark)
	return {"fark": maks, "ilk": ilk, "ilk_x": ilk_x, "kare": canli["kare"]}


## Plaka tutma süresi: oyuncu plakada 10 kare durur, sonra sağa yürür; fiziksel basış
## bittikten sonra kaç kare daha `basili_mi()` true? (beklenen: tutma_kare; mandalda ölçüm sonuna kadar.)
func _n_tutma_olc(plaka: String, konum: Vector2, kare := 330) -> Dictionary:
	var s: Dictionary = await _n_senaryo([], [_b13_a(0, Callable(), 10), _b13_a(1, _b4_x_ge(konum.x + 150.0), 100),
		_b13_a(0, Callable(), kare)], _n_yerlestir(konum))
	var son_f := -1
	for f in range(s["ozel"].size()):
		if s["ozel"][f].get(plaka + "_f", false):
			son_f = f
	var n := 0
	var f2 := son_f + 1
	while f2 < s["ozel"].size() and s["ozel"][f2].get(plaka, false):
		n += 1
		f2 += 1
	var ilk_basili := -1
	for f in range(s["ozel"].size()):
		if s["ozel"][f].get(plaka, false):
			ilk_basili = f
			break
	return {"kalan": n, "son_fiziksel": son_f, "ilk_basili": ilk_basili, "kare": s["ozel"].size(),
		"sona_kadar": son_f + n >= s["ozel"].size() - 1, "ozel": s["ozel"]}


## Sahnede adı verilen önekle başlayan düğümler (bölümde olmaması gereken mekanikler).
func _n_var_olanlar(b: Node, onekler: Array) -> String:
	var bulunan: Array = []
	for c in b.get_children():
		for o in onekler:
			if str(c.name).begins_with(o):
				bulunan.append(str(c.name))
	return ",".join(bulunan)


# ---------------------------------------------------------------- Bölüm 15 (Fitil)
# C_A: Z1 ile kata çıkar, PlakaA'da kalır. C_B: aynı koşu, G'yi fitil süresinde geçer, PlakaB'de kalır.
# Oyuncu: aynı koşu, rafta S, kuyudan kapıya.
var _n15_onb: Array = []   # [A, B]


## C_A: gec = başta bekleme, z1_kes = Z1 sensörüne girince `sag` bırakma süresi, bekle = plakada bekleme.
func _n15_a(gec := 0, bekle := 15, z1_kes := 0) -> Array:
	var d: Array = []
	if gec > 0:
		d.append(_b13_a(0, Callable(), gec))
	if z1_kes > 0:
		d += [_b13_a(1, _b4_x_ge(477.0), 200), _b13_a(0, Callable(), z1_kes)]
	d += [_b13_a(1, _b4_x_ge(630.0), 300), _b13_a(0, _n_plakada("PlakaA"), 150), _b13_a(0, Callable(), bekle)]
	return d


## Ortak koşu: ZP'den geçilir (zp_dur: ZP'den ayrılınca duraksama), Z1 ile kata çıkılır, x=630'a kadar.
func _n15_kosu(gec := 0, zp_dur := 0, z1_kes := 0) -> Array:
	var d: Array = []
	if gec > 0:
		d.append(_b13_a(0, Callable(), gec))
	if zp_dur > 0:
		d += [_b13_a(1, _b4_x_ge(170.0), 200), _b13_a(0, Callable(), zp_dur)]
	if z1_kes > 0:
		d += [_b13_a(1, _b4_x_ge(477.0), 200), _b13_a(0, Callable(), z1_kes)]
	d.append(_b13_a(1, _b4_x_ge(630.0), 400))
	return d


func _n15_b(gec := 0, zp_dur := 0, bekle := 10, z1_kes := 0) -> Array:
	return _n15_kosu(gec, zp_dur, z1_kes) + [_b13_a(1, _n_plakada("PlakaB"), 400), _b13_a(0, Callable(), bekle)]


## Oyuncu: raf üstünde x >= s_x'te `sag` bırakır, S basar (sag_tut: S sırasında sag basılı), kuyudan kapıya.
func _n15_o(gec := 0, zp_dur := 0, s_x := 1025.0, sag_tut := false, z1_kes := 0) -> Array:
	var d: Array = _n15_kosu(gec, zp_dur, z1_kes)
	d += [_b13_a(1, _b4_x_ge(s_x), 400)]
	if sag_tut:
		d += [_b13_a(1, Callable(), 3, false, true)]
	else:
		d += [_b13_a(0, Callable(), 1), _b13_a(0, Callable(), 3, false, true)]
	d += [_b13_a(0, _n_zemin(), 120), _b13_a(1, _b4_bitti_k(), 150)]
	return d


func _n15_kayitlar() -> Array:
	if _n15_onb.is_empty():
		var s1: Dictionary = await _n_senaryo([], _n15_a())
		var s2: Dictionary = await _n_senaryo([s1["kayit"]], _n15_b())
		_n15_onb = [s1["kayit"], s2["kayit"]]
	return _n15_onb


func _b15_calistir() -> void:
	await _test_b15_cozum()
	await _test_b15_basarisizlik()
	await _test_b15_atlanamaz()
	await _test_b15_kisayol()
	await _test_b15_pencereler()
	await _test_b15_klon_fark()
	await _test_b15_tutma()
	await _test_b15_klon_siniri()
	await _test_b15_kilitlenme()
	await _test_b15_determinizm()


func _test_b15_cozum() -> void:
	await _n_cozum("Bölüm 15 çözümü (3 tur, 2 klon, gerçek R/girdi yolu)", [_n15_a(), _n15_b()], _n15_o(), 3)


func _test_b15_basarisizlik() -> void:
	var kay: Array = await _n15_kayitlar()
	var c_a: Array = kay[0]
	var c_b: Array = kay[1]
	# 1) klonsuz: LazerA'da ölür.
	var s1: Dictionary = await _n_senaryo([], [_b13_a(1, Callable(), 250)])
	var p1: Vector2 = _n_son(s1)
	_kaydi("Bölüm 15 başarısızlık 1: klonsuz -> LazerA'da ölür", s1["oldu"] > 0 and not s1["bitti_ham"] and p1.x > 690.0 and p1.x < 735.0,
		"ölüm=%d, son konum (%.0f,%.0f) (ışın x 737..743, gövde girişi 723)" % [s1["oldu"], p1.x, p1.y])
	# 2) yalnız C_A: oyuncu kuyuda LazerB'de ölür.
	var s2: Dictionary = await _n_senaryo([c_a], _n15_o())
	var p2: Vector2 = _n_son(s2)
	_kaydi("Bölüm 15 başarısızlık 2: yalnız C_A -> kuyuda LazerB'de ölür", s2["oldu"] > 0 and not s2["bitti_ham"] and p2.x > 1000.0 and p2.x < 1060.0,
		"ölüm=%d, son konum (%.0f,%.0f) (ışın x 1057..1063)" % [s2["oldu"], p2.x, p2.y])
	# 3) C_A erken ayrılır (plakaya değip hemen sola yürür): LazerA açık, C_B ölür, kayıt boş.
	var a_gec: Array = (await _n_senaryo([], _n15_a(24)))["kayit"]
	var s3: Dictionary = await _n_senaryo([a_gec], _n15_b())
	_kaydi("Bölüm 15 başarısızlık 3: C_A PlakaA'ya 24 kare geç basar -> C_B LazerA'da ölür (kayıt boş)", s3["oldu"] > 0 and not s3["bitti_ham"],
		"ölüm=%d, son konum (%.0f,%.0f)" % [s3["oldu"], _n_son(s3).x, _n_son(s3).y])
	# 4) Z1'de `sag` uzun süre bırakılır: gövde boşluğa geri düşer / G kaçar (pencere ölçümü pencereler testinde).
	var vs4: Array = [15, 24, 30, 54, 66]
	var ok4 := true
	var ayr4: Array = []
	for k in vs4:
		var s4: Dictionary = await _n_senaryo([c_a], _n15_b(0, 0, 10, k))
		var d: bool = s4["tamam"].has(false) or s4["oldu"] > 0 or s4["kare"] > 600
		ok4 = ok4 and d
		ayr4.append("kes=%d: adım karşılanmadı/ölüm=%s (kare %d)" % [k, str(d), s4["kare"]])
	_kaydi("Bölüm 15 başarısızlık 4: Z1'de `sag` uzun bırakılır -> fitil kaçar, C_B PlakaB'ye varamaz", ok4, "; ".join(ayr4))
	# 5) G'de geç kalma: ZP'den ayrılınca 90 kare durur -> G kapanır, C_B/oyuncu çarpıp durur (ölmez).
	var s5: Dictionary = await _n_senaryo([c_a], _n15_b(0, 90, 10))
	var o5: Dictionary = _n_olc(s5)
	_kaydi("Bölüm 15 başarısızlık 5: G'de geç kalma (ZP'den sonra 90 kare duraksama) -> G kapalı, çarpıp durur", s5["tamam"].has(false) and s5["oldu"] == 0 and o5["xmax"] < 840.0 and o5["xmax"] > 780.0,
		"adımlar=%s, ölüm=%d, en büyük x=%.0f (G sol yüzü 850, gövde 836)" % [str(s5["tamam"]), s5["oldu"], o5["xmax"]])
	# 6) Rafta `sag` basılıyken S: 12 karede sürüklenip ışına iner, ölür.
	var s6: Dictionary = await _n_senaryo([c_a, c_b], _n15_o(0, 0, 1020.0, true))
	# Taslak §9.6: "12 karede +60 px sürükler, ışına inip ölür". Son turda LazerB kapalıdır (C_B PlakaB'de): ölçülen sonuç kaydedilir.
	var f_s6: int = _n_ilk(s6, "zemin", false, 150)
	_kaydi("Bölüm 15 ölçüm 6: rafta `sag` basılıyken S (LazerB kapalı) -> sürüklenme ölçülür, ölüm yok (taslak §9.6 'ölür' iddiası LazerB açıkken geçerli)",
		s6["oldu"] == 0 and s6["bitti_ham"] and _n_olc(s6)["xmax"] > 1030.0,
		"bitti=%s ölüm=%d son (%.0f,%.0f), en büyük x=%.0f (S sırasında sağ basılı)" % [s6["bitti_ham"], s6["oldu"], _n_son(s6).x, _n_son(s6).y, _n_olc(s6)["xmax"]])
	# 7) C_B PlakaB'ye ulaşmadan R: LazerB açık, oyuncu kuyuda ölür (C_B yarım: raf yürüyüşü yok).
	var b_yarim: Array = (await _n_senaryo([c_a], _n15_kosu() + [_b13_a(1, _b4_x_ge(800.0), 200)]))["kayit"]
	var s7: Dictionary = await _n_senaryo([c_a, b_yarim], _n15_o())
	_kaydi("Bölüm 15 başarısızlık 7: C_B PlakaB'ye ulaşmaz -> oyuncu LazerB'de ölür", s7["oldu"] > 0 and not s7["bitti_ham"],
		"ölüm=%d, son (%.0f,%.0f)" % [s7["oldu"], _n_son(s7).x, _n_son(s7).y])
	# 8) S çok erken (x=1005 < 1014): döşeme desteği sürer, S etkisiz.
	var s8: Dictionary = await _n_senaryo([c_a, c_b], _n15_kosu() + [_b13_a(1, _b4_x_ge(1005.0), 400), _b13_a(0, Callable(), 1),
		_b13_a(0, Callable(), 3, false, true), _b13_a(0, Callable(), 60)])
	_kaydi("Bölüm 15 başarısızlık 8: S raf başına çok yakın (x=1005) -> düşmez", _n_son(s8).y < 370.0 and s8["oldu"] == 0,
		"son (%.1f,%.1f) (yüzey y=355.9)" % [_n_son(s8).x, _n_son(s8).y])
	# 9) S fırlatma sonrası havada / ZP başında kalan klon (4. rol) iddiası: C_B yerine ZP'de bekleyen klon G'yi açık tutar ama LazerB'yi tutmaz.
	var z_klon: Array = (await _n_senaryo([c_a], [_b13_a(1, _n_plakada("PlakaZ"), 100), _b13_a(0, Callable(), 300)]))["kayit"]
	var s9: Dictionary = await _n_senaryo([c_a, z_klon], _n15_o())
	_kaydi("Bölüm 15 başarısızlık 9: ZP başında kalan klon LazerB'yi tutmaz -> oyuncu kuyuda ölür", s9["oldu"] > 0 and not s9["bitti_ham"],
		"ölüm=%d, son (%.0f,%.0f)" % [s9["oldu"], _n_son(s9).x, _n_son(s9).y])
	_kayitlar().sifirla()
	paused = false


func _test_b15_atlanamaz() -> void:
	var kay: Array = await _n15_kayitlar()
	var ayr: Array = []
	var hepsi := true
	# Zeminden F2'ye zıplayarak çıkılmaz (döşeme alt kenarı 420, 220 px > 100,9): F1 sol bölgede.
	var sa: Dictionary = await _n_senaryo([], _n_spam(0.0, 8), _n_yerlestir(Vector2(300, 576)))
	var oa: Dictionary = _n_olc(sa)
	var ok: bool = oa["ayak"] > 440.0
	hepsi = hepsi and ok
	ayr.append("F1'den dikey zıplama: en yüksek ayak y=%.1f (döşeme alt kenarı 420, zıplama 100,9: kat 220 px)" % oa["ayak"])
	# GecitG kapalı (ZP hiç basılmadı): F2'de sağ+zıpla spam, sol yüz 850, gövde 836.
	var sg: Dictionary = await _n_senaryo([], _n_spam(1.0, 12), _n_yerlestir(Vector2(790, 356)))
	var og: Dictionary = _n_olc(sg)
	ok = og["xmax"] <= 837.0 and not sg["bitti_ham"]
	hepsi = hepsi and ok
	ayr.append("GecitG kapalı: en büyük x=%.0f (sol yüz 850-14=836), ölüm=%d" % [og["xmax"], sg["oldu"]])
	# LazerA açık: zıplayarak aşılmaz (ölür).
	var sl: Dictionary = await _n_senaryo([], _n_spam(1.0, 10), _n_yerlestir(Vector2(690, 356)))
	var ol: Dictionary = _n_olc(sl)
	ok = sl["oldu"] > 0 and ol["xmax"] < 745.0
	hepsi = hepsi and ok
	ayr.append("LazerA zıplayarak: ölüm=%d, en büyük x=%.0f (ışın sol kenarı 737)" % [sl["oldu"], ol["xmax"]])
	# Z1 uçuşu LazerA'yı aşmaz: Z1'den sağ+zıpla spam (klonsuz): ölür.
	var sz: Dictionary = await _n_senaryo([], [_b13_a(1, _b4_x_ge(477.0), 200)] + _n_spam(1.0, 14))
	var oz: Dictionary = _n_olc(sz)
	ok = sz["oldu"] > 0 and oz["xmax"] < 745.0
	hepsi = hepsi and ok
	ayr.append("Z1 uçuşu + zıpla spam (klonsuz): ölüm=%d, en büyük x=%.0f, tepe ayak y=%.1f (taslak 353)" % [sz["oldu"], oz["xmax"], oz["ayak"]])
	# F1 -> kuyu: DuvarF1 (x 980..1000) F1 koridorunu kapatır.
	var sd: Dictionary = await _n_senaryo([], _n_spam(1.0, 12), _n_yerlestir(Vector2(900, 576)))
	var od: Dictionary = _n_olc(sd)
	ok = od["xmax"] <= 967.0
	hepsi = hepsi and ok
	ayr.append("DuvarF1: en büyük x=%.0f (sol yüz 980-14=966)" % od["xmax"])
	# Kuyudan F2'ye çıkış yok (220 px).
	var sk: Dictionary = await _n_senaryo(kay, _n_spam(0.0, 10), _n_yerlestir(Vector2(1060, 576)))
	var ok_k: Dictionary = _n_olc(sk)
	ok = ok_k["ayak"] > 450.0
	hepsi = hepsi and ok
	ayr.append("kuyu dikey zıplama (LazerB kapalı): en yüksek ayak y=%.1f (zemin 600, raf üstü 380; 220 px > 100,9)" % ok_k["ayak"])
	# LazerB: kapalı değilken (yalnız C_A) raf yürüyüşü ışından geçer -> ölür.
	var sb: Dictionary = await _n_senaryo([kay[0]], _n_spam(1.0, 6), _n_yerlestir(Vector2(1030, 356)))
	ok = sb["oldu"] > 0
	hepsi = hepsi and ok
	ayr.append("LazerB açık: raf üstünde sağ+zıpla -> ölüm=%d" % sb["oldu"])
	# Raf x 1000..1120: kapı yalnız kuyu tabanında: F2 sağ ucunda (SagDuvar) kapıya değilmez.
	_kaydi("Bölüm 15 atlanamazlık hesapları (kat boşluğu, geçit, lazerler, DuvarF1, kuyu çıkışı)", hepsi, "; ".join(ayr))
	_kayitlar().sifirla()
	paused = false


func _test_b15_kisayol() -> void:
	var kay: Array = await _n15_kayitlar()
	var c_a: Array = kay[0]
	var c_b: Array = kay[1]
	var ayr: Array = []
	var hepsi := true
	# Sahnede olmaması gereken mekanikler: kutu/bant/şalter/asansör yok (taslak §1): kutu basamağı, bant dalgalanması uygulanamaz.
	var b0: Node = await _bolumu_yukle()
	var var_olan: String = _n_var_olanlar(b0, ["Kutu", "Bant", "Salter", "Asansor"])
	paused = false
	hepsi = hepsi and var_olan == ""
	ayr.append("sahnede kutu/bant/şalter/asansör: [%s] (yok olmalı)" % var_olan)
	# 1) klonsuz: çeşitli girdiler.
	var kos: Array = [
		["sag sürekli", [_b13_a(1, Callable(), 400)]],
		["sağ+zıpla spam", _n_spam(1.0, 20)],
		["bekle 60 + sag", [_b13_a(0, Callable(), 60), _b13_a(1, Callable(), 400)]],
		["Z1 uçuşu + sag", _n15_kosu() + [_b13_a(1, Callable(), 200)]]]
	for k in kos:
		var s: Dictionary = await _n_senaryo([], k[1])
		hepsi = hepsi and not s["bitti_ham"]
		ayr.append("klonsuz/%s: bitti=%s" % [k[0], s["bitti_ham"]])
	# 2) tek klon: C_A, C_B(kör, kayıt turunda LazerA'da ölür), ZP tutucusu; oyuncu stratejileri.
	var tekler: Array = []
	var c_b_kor: Array = (await _n_senaryo([], _n15_b()))["kayit"]
	var tek_ad: Array = ["C_A", "C_B(kör)", "ZP-bekleyen"]
	var z_klon: Array = (await _n_senaryo([], [_b13_a(1, _n_plakada("PlakaZ"), 100), _b13_a(0, Callable(), 300)]))["kayit"]
	tekler = [c_a, c_b_kor, z_klon]
	var oyuncu_st: Array = [_n15_o(), _n15_o(0, 0, 1010.0), _n15_o(0, 0, 1040.0), [_b13_a(1, Callable(), 400)],
		_n15_kosu() + [_b13_a(1, Callable(), 300)]]
	var biten: Array = []
	for i in range(tekler.size()):
		for st in oyuncu_st:
			if await _n_bitirir([tekler[i]], st):
				biten.append(tek_ad[i])
	hepsi = hepsi and biten.is_empty()
	ayr.append("tek klon (3 rol x 5 oyuncu stratejisi): bitiren=%s" % str(biten))
	# 3) röle: tek klon PlakaA'da T kare bekleyip PlakaB'ye yürür (kör kayıt); oyuncu ışından T içinde geçer.
	var rbit: Array = []
	var rtop := 0
	for t in [0, 20, 40, 80, 120]:
		var r: Dictionary = await _n_senaryo([], _n15_kosu() + [_b13_a(1, _n_plakada("PlakaA"), 100), _b13_a(0, Callable(), t),
			_b13_a(1, _n_plakada("PlakaB"), 300), _b13_a(0, Callable(), 20)])
		var klon_k: Array = r["kayit"]
		rtop += 1
		for st in oyuncu_st:
			if await _n_bitirir([klon_k], st):
				rbit.append(t)
	hepsi = hepsi and rbit.is_empty()
	ayr.append("röle (tek klon A'da T kare bekleyip B'ye gider, T=0/20/40/80/120 x 5 strateji): bitiren=%s" % str(rbit))
	# 4) iki klon, tüm alt kümeler / sıralar.
	var iki: Array = [["A+A", [c_a, c_a]], ["B+A", [c_b, c_a]], ["B+B", [c_b, c_b]], ["A+B", [c_a, c_b]]]
	var biten2: Array = []
	for k in iki:
		var bit: bool = await _n_bitirir(k[1], _n15_o())
		if bit:
			biten2.append(k[0])
	# A+B bitirmeli (taslak çözümü), diğerleri bitirmemeli.
	hepsi = hepsi and biten2 == ["B+A", "A+B"]
	ayr.append("iki klon kümeleri (A+A, B+A, B+B, A+B) bitirenler=%s (B+A ile A+B aynı küme; A+A ve B+B bitirmemeli)" % str(biten2))
	# 5) min klon 2 kanıtı: PlakaA ve PlakaB aynı anda basılı; oyuncu LazerB ışınına bunlardan sonra varır.
	var tam: Dictionary = await _n_senaryo(kay, _n15_o())
	var f_ab := -1
	for f in range(tam["ozel"].size()):
		var o: Dictionary = tam["ozel"][f]
		if o["PlakaA"] and o["PlakaB"] and f_ab < 0:
			f_ab = f
	var f_lb: int = _n_x_kare(tam["iz"], 1043.0)
	var ok5: bool = tam["bitti_ham"] and f_ab >= 0 and f_lb > f_ab
	hepsi = hepsi and ok5
	ayr.append("min klon 2: bitti=%s, PlakaA+PlakaB birlikte basılı ilk kare=%d, oyuncu LazerB ışınına (x>=1043) kare %d'de varır" % [tam["bitti_ham"], f_ab, f_lb])
	# 6) S ile yeni iniş yolu: F2 boyunca x'te S bas, kat değiştirenleri listele.
	var inen: Array = []
	for x in range(40, 1112, 40):
		var ss: Dictionary = await _n_senaryo([], [_b13_a(0, Callable(), 3, false, true), _b13_a(0, Callable(), 45)],
			_n_yerlestir(Vector2(float(x), 356)))
		if _n_son(ss).y > 430.0:
			inen.append(x)
	var inen_ok := true
	for x in inen:
		inen_ok = inen_ok and x >= 1000
	hepsi = hepsi and inen_ok and inen.size() > 0
	ayr.append("S ile F2'den inenler (x, 40 px adım; yalnız raf x>=1000 beklenir): %s" % str(inen))
	# 7) lazeri zıplayarak aşma: atlanamazlık testinde.
	_kaydi("Bölüm 15 kısayol taraması (klonsuz, 1 klon, röle, iki klon kümeleri, min klon 2, S inişleri, yok mekanikler)", hepsi, " || ".join(ayr))
	_kayitlar().sifirla()
	paused = false


func _test_b15_pencereler() -> void:
	var kay: Array = await _n15_kayitlar()
	var c_a: Array = kay[0]
	var c_b: Array = kay[1]
	var ayr: Array = []
	var hepsi := true
	# --- tur başı: gerçek oyuncu koşusunda G açıklık penceresi ve gövdenin geçiş aralığı (kare)
	var tam: Dictionary = await _n_senaryo(kay, _n15_o())
	var g0 := -1
	var g1 := -1
	var zp_son := -1
	for f in range(tam["ozel"].size()):
		var o: Dictionary = tam["ozel"][f]
		if o["GecitG"] <= 232.0:
			if g0 < 0:
				g0 = f
			g1 = f
		if o["PlakaZ_f"]:
			zp_son = f
	var f_in: int = _n_x_kare(tam["iz"], 836.0)
	var f_out: int = _n_x_kare(tam["iz"], 885.0)
	ayr.append("oyuncu: ZP son fiziksel kare=%d, G açıklık>=48 kare %d..%d, gövde G'de kare %d..%d -> G pay: çıkışa göre %d kare, girişe göre %d kare (%.0f px; geçit kapanırken altındaki karakter için durur), açılış payı %d kare" % [
		zp_son, g0, g1, f_in, f_out, g1 - f_out, g1 - f_in, (g1 - f_in) * 5.0, f_in - g0])
	hepsi = hepsi and (g1 - f_out) >= 20 and f_in > g0
	# --- W1: ZP'den ayrılınca duraksama (C_B ve oyuncu)
	var vs: Array = []
	for d in range(0, 91, 3):
		vs.append(d)
	var okb: Array = await _n_sup(vs, func(v: int) -> bool:
		var s: Dictionary = await _n_senaryo([c_a], _n15_b(0, v, 10))
		return not s["tamam"].has(false) and s["oldu"] == 0)
	var oko: Array = await _n_sup(vs, func(v: int) -> bool: return await _n_bitirir(kay, _n15_o(0, v)))
	var w1b := _n_en_buyuk(vs, okb)
	var w1o := _n_en_buyuk(vs, oko)
	ayr.append("W1 ZP sonrası duraksama (kare) C_B başarılı: %s (en çok %d kare = %d px; taslak pay ~51); oyuncu başarılı: %s (en çok %d)" % [_n_ar(vs, okb), w1b, w1b * 5, _n_ar(vs, oko), w1o])
	hepsi = hepsi and _n_pen(vs, okb, 0) and _n_pen(vs, okb, 90, false) and w1b >= 30 and w1b <= 70 and w1o >= 30
	# --- W2: Z1'de `sag` bırakma süresi (C_A için PlakaA'ya varış; C_B için fitil dahil)
	var vz: Array = []
	for d in range(0, 91, 3):
		vz.append(d)
	var oka: Array = await _n_sup(vz, func(v: int) -> bool:
		var s: Dictionary = await _n_senaryo([], _n15_a(0, 10, v))
		return not s["tamam"].has(false) and s["oldu"] == 0)
	var okz: Array = await _n_sup(vz, func(v: int) -> bool:
		var s: Dictionary = await _n_senaryo([c_a], _n15_b(0, 0, 10, v))
		return not s["tamam"].has(false) and s["oldu"] == 0)
	ayr.append("W2 Z1 sensöründe `sag` bırakma (kare) C_A: %s (en çok %d; taslak ~28), C_B (fitil dahil): %s (en çok %d)" % [_n_ar(vz, oka), _n_en_buyuk(vz, oka), _n_ar(vz, okz), _n_en_buyuk(vz, okz)])
	hepsi = hepsi and _n_pen(vz, oka, 0) and _n_pen(vz, okz, 0) and _n_pen(vz, oka, 9) and not _n_pen(vz, oka, 15)
	# --- W3: C_A'nın PlakaA'ya geç basması (başta bekleme): C_B ışına varıştan önce basılmalı
	var vg: Array = []
	for d in range(0, 31, 1):
		vg.append(d)
	var okg: Array = await _n_sup(vg, func(v: int) -> bool:
		var a2: Array = (await _n_senaryo([], _n15_a(v)))["kayit"]
		var s: Dictionary = await _n_senaryo([a2], _n15_b(0, 0, 10))
		return not s["tamam"].has(false) and s["oldu"] == 0)
	var w3 := _n_en_buyuk(vg, okg)
	ayr.append("W3 C_A başta bekleme (kare; C_B bekleme yok): başarılı %s (en çok %d kare = %d px; taslak pay ~25)" % [_n_ar(vg, okg), w3, w3 * 5])
	hepsi = hepsi and _n_pen(vg, okg, 0) and w3 >= 4 and w3 < 30
	# --- W3b: C_A plakaya değer değmez sola yürür (en erken ayrılma): C_B kendi basışıyla yardım eder, pay ölçülür
	var okg2: Array = await _n_sup(vg, func(v: int) -> bool:
		var a3: Array = (await _n_senaryo([], _n15_kosu(v) + [_b13_a(1, _n_plakada("PlakaA"), 100), _b13_a(-1, _b4_x_le(590.0), 100), _b13_a(0, Callable(), 100)]))["kayit"]
		var s: Dictionary = await _n_senaryo([a3], _n15_b(0, 0, 10))
		return not s["tamam"].has(false) and s["oldu"] == 0)
	ayr.append("W3b C_A plakaya değer değmez sola yürür (başta bekleme kare): C_B başarılı %s (C_B plakayı kendisi de basar: sağ kenar 670, ışın 737)" % _n_ar(vg, okg2))
	# --- W4: C_B'nin PlakaB'ye geç basması: oyuncu ışına varmadan önce basılmalı
	var vh: Array = []
	for d in range(0, 121, 4):
		vh.append(d)
	var okh: Array = await _n_sup(vh, func(v: int) -> bool:
		var b2: Array = (await _n_senaryo([c_a], _n15_b(v, 0, 10)))["kayit"]
		return await _n_bitirir([c_a, b2], _n15_o()))
	var w4 := _n_en_buyuk(vh, okh)
	ayr.append("W4 C_B başta bekleme (kare): oyuncu başarılı %s (en çok %d kare = %d px; taslak pay ~70)" % [_n_ar(vh, okh), w4, w4 * 5])
	hepsi = hepsi and _n_pen(vh, okh, 0) and w4 >= 4
	# --- W5: S konumu (merkez x)
	var vx: Array = []
	for x in range(1000, 1081, 3):
		vx.append(x)
	var okx: Array = await _n_sup(vx, func(v: int) -> bool: return await _n_bitirir(kay, _n15_o(0, 0, float(v))))
	ayr.append("W5 S konumu (raf üstü merkez x; gövde ilk eşik x>=v): başarılı %s (taslak 1014..1043: 29 px)" % _n_ar(vx, okx))
	hepsi = hepsi and _n_en_buyuk(vx, okx) > _n_en_kucuk(vx, okx) + 6
	_kaydi("Bölüm 15 zamanlama payları (G açıklığı, W1 ZP duraksama, W2 Z1 sag, W3/W4 klon pay, W5 S konumu)", hepsi, " || ".join(ayr))
	_kayitlar().sifirla()
	paused = false


func _test_b15_klon_fark() -> void:
	var kay: Array = await _n15_kayitlar()
	var ayr: Array = []
	var hepsi := true
	for k in [["C_A", [], _n15_a()], ["C_B", [kay[0]], _n15_b()], ["Oyuncu", kay, _n15_o()]]:
		var r: Dictionary = await _n_klon_fark(k[1], k[2])
		ayr.append("%s canlı/klon en büyük konum farkı %.2f px (ilk sapma kare %d)" % [k[0], r["fark"], r["ilk"]])
		# Üst sınır iddiası: bant/dikiş yok; ölçülen değerin ~%25 payı ile 0,5 px.
		hepsi = hepsi and r["fark"] <= 0.5
	_kaydi("Bölüm 15 ölçüm: canlı kayıt vs klon tekrarı konum farkı (bant/dikiş yok, üst sınır 0,5 px)", hepsi, " || ".join(ayr))
	_kayitlar().sifirla()
	paused = false


func _test_b15_tutma() -> void:
	var ayr: Array = []
	var hepsi := true
	aktif_bolum = BOLUM_15
	var r: Dictionary = await _n_tutma_olc("PlakaZ", Vector2(120, 576), 260)
	ayr.append("ZP: ilk basili kare=%d, son fiziksel kare=%d, sonra basılı kalan=%d kare (beklenen tam 180)" % [r["ilk_basili"], r["son_fiziksel"], r["kalan"]])
	hepsi = hepsi and r["kalan"] == 180
	# Yeniden basış sayacı yeniler: plakada 5 kare, 40 kare dışarıda, 5 kare yeniden, sonra yürü: son basıştan sonra 180.
	var s: Dictionary = await _n_senaryo([], [_b13_a(0, Callable(), 5), _b13_a(1, Callable(), 14), _b13_a(0, Callable(), 3),
		_b13_a(-1, Callable(), 14), _b13_a(0, Callable(), 5), _b13_a(1, _b4_x_ge(300.0), 100), _b13_a(0, Callable(), 260)], _n_yerlestir(Vector2(120, 576)))
	var son_f := -1
	var aralik := 0
	for f in range(s["ozel"].size()):
		if s["ozel"][f]["PlakaZ_f"]:
			son_f = f
	var f2 := son_f + 1
	while f2 < s["ozel"].size() and s["ozel"][f2]["PlakaZ"]:
		aralik += 1
		f2 += 1
	ayr.append("yeniden basış: son fiziksel kare=%d, sonrası basılı=%d (beklenen 180, sayaç yenilenir)" % [son_f, aralik])
	hepsi = hepsi and aralik == 180
	# Tur başı sıfırlama: R sonrası yeni turda ZP basılı değil, G kapalı (y=280), lazerler tur kurallarına göre.
	_kayitlar().sifirla()
	var bolum: Node = await _bolumu_yukle()
	for i in range(30):
		_girdi_uygula({"yon": 1.0, "zipla": false})
		await physics_frame
	_girdi_uygula({"yon": 0.0, "zipla": false})
	var onc: bool = bolum.get_node("PlakaZ").basili_mi()
	var eski_id := bolum.get_instance_id()
	await _r_bas()
	var yeni: Node = await _yeni_sahne_bekle(eski_id)
	var z_yeni: bool = yeni.get_node("PlakaZ").basili_mi()
	var g_y: float = yeni.get_node("GecitG").position.y
	var kalan: int = yeni.get_node("PlakaZ").kalan_kare
	ayr.append("tur başı sıfırlama: R öncesi ZP basılı=%s; yeni turda ZP basılı=%s, kalan_kare=%d, G y=%.0f (kapalı 280)" % [str(onc), str(z_yeni), kalan, g_y])
	hepsi = hepsi and z_yeni == false and kalan == 0 and absf(g_y - 280.0) < 0.5
	_kaydi("Bölüm 15: zamanlı plaka tam 180 kare, yeniden basış sayacı yeniler, tur başı sıfırlama", hepsi, " || ".join(ayr))
	_kayitlar().sifirla()
	paused = false


func _test_b15_klon_siniri() -> void:
	await _n_klon_siniri("Bölüm 15: klon sınırı (dördüncü R klon kaydetmez)", 3)


func _test_b15_kilitlenme() -> void:
	var kay: Array = await _n15_kayitlar()
	var c_a: Array = kay[0]
	var ayr: Array = []
	var hepsi := true
	# (a) kuyuda ölüm: LazerB açıkken kuyuya iner, ışına girer -> tur yeniden başlar, klonlar korunur.
	_kayitlar().sifirla()
	_kayitlar().tur_kaydet(c_a.duplicate(true))
	var bolum: Node = await _bolumu_yukle()
	bolum.get_node("Oyuncu").global_position = Vector2(1030, 356)
	var sayac := [0]
	bolum.get_node("Oyuncu").oyuncu_oldu.connect(func() -> void: sayac[0] += 1)
	var eski_id := bolum.get_instance_id()
	var s: Dictionary = await _n_kosullu(bolum, [_b13_a(0, Callable(), 1), _b13_a(0, Callable(), 3, false, true), _b13_a(0, _n_zemin(), 100),
		_b13_a(1, Callable(), 60)], sayac)
	var yeni: Node = await _yeni_sahne_bekle(eski_id)
	var etiket := ""
	var ok: bool = sayac[0] > 0 and yeni != null and _kayitlar().turlar.size() == 1
	if yeni != null:
		etiket = yeni.bilgi.text
		ok = ok and _klonlar(yeni).size() == 1 and etiket.contains("Tur 2") and etiket.contains("1/3")
	hepsi = hepsi and ok
	ayr.append("kuyuda ölüm: ölüm=%d, kayıtlı tur=%d, etiket=\"%s\"" % [sayac[0], _kayitlar().turlar.size(), etiket])
	# (b) kuyudan F2'ye dönüş yok (ışının solunda kalan oyuncu): zıplama spam, ayak y.
	var sk: Dictionary = await _n_senaryo([c_a], _n_spam(0.0, 12), _n_yerlestir(Vector2(1010, 576)))
	var ok_b: bool = _n_olc(sk)["ayak"] > 450.0 and sk["oldu"] == 0
	hepsi = hepsi and ok_b
	ayr.append("kuyuda ışının solunda: zıplama en yüksek ayak y=%.1f (F2 yüzeyi 380), ölüm=%d -> F2'ye dönüş yok (çıkış: R/Baştan başla)" % [_n_olc(sk)["ayak"], sk["oldu"]])
	# (c) Baştan başla: tüm klonlar silinir.
	_kayitlar().sifirla()
	_kayitlar().tur_kaydet(c_a.duplicate(true))
	var b2: Node = await _bolumu_yukle()
	var eski: Node = current_scene
	b2.get_node("EkranButonlari/Kutu/YenidenDugmesi").pressed.emit()
	var yeni2: Node = await _sahne_degisimini_bekle(eski)
	var ok_c: bool = _kayitlar().turlar.size() == 0 and _klonlar(yeni2).size() == 0 and yeni2.bilgi.text.begins_with("Tur 1 ")
	hepsi = hepsi and ok_c
	ayr.append("Baştan başla: kayıt=%d, klon=%d, etiket=\"%s\"" % [_kayitlar().turlar.size(), _klonlar(yeni2).size(), yeni2.bilgi.text])
	# (d) Klonlar G altında bitmez: tam çözümde klonların son konumu plakada.
	var tam: Dictionary = await _n_senaryo(kay, [_b13_a(0, Callable(), 320)])
	var ki: Array = tam["klon_izleri"]
	var son_a: Vector2 = ki[0][ki[0].size() - 1]
	var son_b: Vector2 = ki[1][ki[1].size() - 1]
	var ok_d: bool = son_a.x > 600.0 and son_a.x < 700.0 and son_b.x > 890.0 and son_b.x < 990.0 and not tam["klon_oldu"][0] and not tam["klon_oldu"][1]
	hepsi = hepsi and ok_d
	ayr.append("klonlar plakada biter: C_A (%.0f,%.0f), C_B (%.0f,%.0f) (G x 850..870 altında değil)" % [son_a.x, son_a.y, son_b.x, son_b.y])
	_kaydi("Bölüm 15 kilitlenme: kuyuda ölüm, kuyudan dönüş yok, Baştan başla, klon konumları", hepsi, " || ".join(ayr))
	_kayitlar().sifirla()
	paused = false


func _test_b15_determinizm() -> void:
	var kay: Array = await _n15_kayitlar()
	await _n_determinizm("Bölüm 15: determinizm (100x çözüm)", kay, _n15_o())







# ---------------------------------------------------------------- Bölüm 17 (Çifte Mühür)
# C_A: Z1, ters bant, PlakaA'da kalır. C_B: LazerA'yı geçer, raf1'de S, cepte MP'ye basar, ZP'ye basar, Z2 ile
# döner, PlakaB'de kalır. C_C: aynı gezi, G_Z'yi fitil süresinde geçer, GecitM'den geçer, PlakaC'de kalır.
# Oyuncu: aynı gezi, raf2'de S, kuyuda LazerC'den (kapalı) geçer, kutu + ledge basamağı, kapı.
var _n17_onb: Array = []   # [A, B, C]


func _n17_a(gec := 0, bekle := 15) -> Array:
	var d: Array = []
	if gec > 0:
		d.append(_b13_a(0, Callable(), gec))
	d += [_b13_a(1, _b4_x_ge(440.0), 400), _b13_a(1, _n_plakada("PlakaA"), 100), _b13_a(0, Callable(), bekle)]
	return d


## Cep gezisi. s_x: raf1 S eşiği; sag_tut: S sırasında sag basılı; z2_bekle: Z2'de sag bırakma (<0: y<=345'e kadar);
## zp_sonra: ZP'den ayrılınca duraksama (fitil payı ölçümü); zp_atla: ZP'ye basmaz (fitil yok).
func _n17_gezi(gec := 0, s_x := 580.0, sag_tut := false, z2_bekle := -1, zp_sonra := 0, zp_atla := false) -> Array:
	var d: Array = []
	if gec > 0:
		d.append(_b13_a(0, Callable(), gec))
	d += [_b13_a(1, _b4_x_ge(150.0), 300), _b13_a(1, _b4_x_ge(s_x), 400)]
	if sag_tut:
		d.append(_b13_a(1, Callable(), 3, false, true))
	else:
		d += [_b13_a(0, Callable(), 1), _b13_a(0, Callable(), 3, false, true)]
	d.append(_b13_a(0, _n_plakada("PlakaM"), 120))
	if not zp_atla:
		d += [_b13_a(-1, _n_plakada("PlakaZ"), 100), _b13_a(0, Callable(), 1), _b13_a(1, _b4_x_ge(546.0), 60)]
		if zp_sonra > 0:
			d.append(_b13_a(0, Callable(), zp_sonra))
	else:
		d.append(_b13_a(0, Callable(), 1))
	d.append(_b13_a(1, _b4_x_ge(610.0), 100))
	if z2_bekle >= 0:
		d.append(_b13_a(0, Callable(), z2_bekle))
	else:
		d.append(_b13_a(0, _n_y_le(345.0), 100))
	d.append(_b13_a(1, _n_zemin(), 80))
	return d


func _n17_b(gec := 0, bekle := 15) -> Array:
	return _n17_gezi(gec) + [_b13_a(1, _n_plakada("PlakaB"), 400), _b13_a(0, Callable(), bekle)]


func _n17_c(gec := 0, bekle := 15, zp_sonra := 0, zp_atla := false) -> Array:
	return _n17_gezi(gec, 580.0, false, -1, zp_sonra, zp_atla) + [_b13_a(1, _n_plakada("PlakaC"), 500), _b13_a(0, Callable(), bekle)]


## Oyuncu: gezi + raf2'de S (s2_x eşiği) + kutuyu it + kutuya zıpla + ledge'e zıpla + kapı.
func _n17_o(gec := 0, s2_x := 985.0, sag_tut2 := false, zp_sonra := 0, z_n := 14) -> Array:
	var d: Array = _n17_gezi(gec, 580.0, false, -1, zp_sonra)
	d.append(_b13_a(1, _b4_x_ge(s2_x), 400))
	if sag_tut2:
		d.append(_b13_a(1, Callable(), 3, false, true))
	else:
		d += [_b13_a(0, Callable(), 1), _b13_a(0, Callable(), 3, false, true)]
	d += [_b13_a(0, _n_zemin(), 120), _b13_a(1, _n_kutu_x_ge(1079.0), 200), _b13_a(1, Callable(), z_n, true),
		_b13_a(0, _n_zemin(), 60), _b13_a(1, Callable(), z_n, true), _b13_a(1, _b4_bitti_k(), 150)]
	return d


func _n17_kayitlar() -> Array:
	if _n17_onb.is_empty():
		var s1: Dictionary = await _n_senaryo([], _n17_a())
		var s2: Dictionary = await _n_senaryo([s1["kayit"]], _n17_b())
		var s3: Dictionary = await _n_senaryo([s1["kayit"], s2["kayit"]], _n17_c())
		_n17_onb = [s1["kayit"], s2["kayit"], s3["kayit"]]
	return _n17_onb


func _b17_calistir() -> void:
	await _test_b17_cozum()
	await _test_b17_basarisizlik()
	await _test_b17_atlanamaz()
	await _test_b17_kisayol()
	await _test_b17_pencereler()
	await _test_b17_dikis()
	await _test_b17_tutma()
	await _test_b17_klon_siniri()
	await _test_b17_kilitlenme()
	await _test_b17_determinizm()


func _test_b17_cozum() -> void:
	await _n_cozum("Bölüm 17 çözümü (4 tur, 3 klon, gerçek R/girdi yolu)", [_n17_a(), _n17_b(), _n17_c()], _n17_o(), 3)


func _test_b17_basarisizlik() -> void:
	var kay: Array = await _n17_kayitlar()
	var c_a: Array = kay[0]
	var c_b: Array = kay[1]
	# 1) klonsuz: LazerA'da ölür.
	var s1: Dictionary = await _n_senaryo([], [_b13_a(1, Callable(), 400)])
	_kaydi("Bölüm 17 başarısızlık 1: klonsuz -> LazerA'da ölür", s1["oldu"] > 0 and not s1["bitti_ham"] and _n_son(s1).x < 515.0 and _n_son(s1).x > 440.0,
		"ölüm=%d, son konum (%.0f,%.0f) (ışın x 512..518, gövde girişi 498)" % [s1["oldu"], _n_son(s1).x, _n_son(s1).y])
	# 2) yalnız C_A: oyuncu cep gezisiyle devam eder, LazerB'de ölür.
	var s2: Dictionary = await _n_senaryo([c_a], _n17_o())
	_kaydi("Bölüm 17 başarısızlık 2: yalnız C_A -> LazerB'de ölür", s2["oldu"] > 0 and not s2["bitti_ham"],
		"ölüm=%d, son (%.0f,%.0f) (ışın x 787..793)" % [s2["oldu"], _n_son(s2).x, _n_son(s2).y])
	# 3) C_A + C_B, C_C yok: oyuncu LazerC'de ölür (raf2/kuyu).
	var s3: Dictionary = await _n_senaryo([c_a, c_b], _n17_o())
	_kaydi("Bölüm 17 başarısızlık 3: C_A + C_B, C_C yok -> LazerC'de ölür", s3["oldu"] > 0 and not s3["bitti_ham"] and _n_son(s3).x > 1000.0,
		"ölüm=%d, son (%.0f,%.0f) (ışın x 1037..1043)" % [s3["oldu"], _n_son(s3).x, _n_son(s3).y])
	# 4) G_Z'de geç kalma: ZP'den ayrılınca 40 kare duraksar (fitil biter) -> G_Z kapalı, çarpıp durur.
	var s4: Dictionary = await _n_senaryo([c_a, c_b], _n17_c(0, 15, 40))
	_kaydi("Bölüm 17 başarısızlık 4: C_C ZP'den sonra 40 kare duraksar -> G_Z kapanır, PlakaC tutulmaz (ölmez)", s4["tamam"].has(false) and s4["oldu"] == 0 and _n_olc(s4)["xmax"] < 840.0,
		"adımlar=%s, ölüm=%d, en büyük x=%.0f (G_Z sol yüzü 820, gövde 806)" % [str(s4["tamam"]), s4["oldu"], _n_olc(s4)["xmax"]])
	# 5) Z2'de `sag` sürekli (bırakılmaz): döşeme köşesine çarpar.
	var s5: Dictionary = await _n_senaryo([c_a], _n17_gezi(0, 580.0, false, 0) + [_b13_a(1, _n_plakada("PlakaB"), 150)])
	_kaydi("Bölüm 17 başarısızlık 5: Z2'de `sag` bırakılmaz -> köşeye çarpar, PlakaB'ye varış gecikir/başarısız", s5["tamam"].has(false) or s5["kare"] > 330,
		"adımlar=%s, kare=%d, ölüm=%d" % [str(s5["tamam"]), s5["kare"], s5["oldu"]])
	# 6) C_B plakadan erken ayrılır: C_C LazerB'de ölür.
	var b_erken: Array = (await _n_senaryo([c_a], _n17_gezi() + [_b13_a(1, _n_plakada("PlakaB"), 400), _b13_a(-1, _b4_x_le(640.0), 100),
		_b13_a(0, Callable(), 100)]))["kayit"]
	var s6: Dictionary = await _n_senaryo([c_a, b_erken], _n17_c())
	_kaydi("Bölüm 17 başarısızlık 6: C_B plakadan erken ayrılır -> C_C LazerB'de ölür", s6["oldu"] > 0 and not s6["bitti_ham"],
		"ölüm=%d, son (%.0f,%.0f)" % [s6["oldu"], _n_son(s6).x, _n_son(s6).y])
	# 7) Raf1'de S çok geç (Z2 sensörü içi, x>=606): cepten hemen fırlar; MP basılmayabilir.
	var s7: Dictionary = await _n_senaryo([c_a], _n17_gezi(0, 640.0) + [_b13_a(1, _n_plakada("PlakaB"), 150)])
	var mp7: bool = _n_ilk(s7, "PlakaM", true) >= 0
	_kaydi("Bölüm 17 ölçüm 7: raf1'de S geç (eşik x>=640, Z2 sensörü üstü) -> ölçülür", true,
		"MP basıldı=%s, adımlar=%s, kare=%d, ölüm=%d" % [str(mp7), str(s7["tamam"]), s7["kare"], s7["oldu"]])
	# 8) Raf2'de `sag` basılıyken S: 12 karede +60 px sürüklenir (LazerC kapalıyken ölmez; C_C yokken ölür).
	var s8: Dictionary = await _n_senaryo([c_a, c_b], _n17_o(0, 985.0, true))
	_kaydi("Bölüm 17 başarısızlık 8: C_C yokken raf2'de `sag` basılı S -> ışına iner, ölür", s8["oldu"] > 0 and not s8["bitti_ham"],
		"ölüm=%d, son (%.0f,%.0f)" % [s8["oldu"], _n_son(s8).x, _n_son(s8).y])
	var s8b: Dictionary = await _n_senaryo(kay, _n17_o(0, 985.0, true))
	_kaydi("Bölüm 17 ölçüm 8b: tam klon setiyle raf2'de `sag` basılı S (LazerC kapalı) -> taslak §9.8 'ölür' iddiası", s8b["oldu"] == 0 and s8b["bitti_ham"],
		"bitti=%s, ölüm=%d, son (%.0f,%.0f), en büyük x=%.0f (LazerC kapalı olduğundan ölüm beklenmez)" % [str(s8b["bitti_ham"]), s8b["oldu"], _n_son(s8b).x, _n_son(s8b).y, _n_olc(s8b)["xmax"]])
	# 9) Kutu kuyuda: ledge ile kutu arası 20 px < gövde 28 px: oyuncu kutunun sağına geçemez, kutu sola itilemez;
	#    kutu yalnız sağa (ledge yüzüne x=1080) itilir.
	var s9: Dictionary = await _n_senaryo(kay, [_b13_a(0, _n_kapali("LazerC"), 500), _b13_a(1, _n_kutu_x_ge(1079.0), 200), _b13_a(1, Callable(), 40)],
		_n_yerlestir(Vector2(1020, 576)))
	var kx: float = s9["ozel"][s9["ozel"].size() - 1]["Kutu"].x
	var px: float = _n_olc(s9)["xmax"]
	_kaydi("Bölüm 17 başarısızlık 9: kutu kuyuda yalnız sağa (ledge yüzüne) itilir; kutunun sağına geçilemez (20 px aralık < 28)", kx > 1078.0 and kx < 1082.0 and px < 1070.0,
		"kutu son x=%.1f (ledge yüzü 1100: kutu 40 px -> 1080), oyuncu en büyük x=%.1f (kutu sol yüzü 1060-14=1046 civarı), ölüm=%d" % [kx, px, s9["oldu"]])
	# 10) ZP'ye basmayan C_C: G_Z kapalı kalır, C_C takılır.
	var s10: Dictionary = await _n_senaryo([c_a, c_b], _n17_c(0, 15, 0, true))
	_kaydi("Bölüm 17 başarısızlık 10: C_C ZP'ye basmaz (fitil yok, ~25 kare erken) -> LazerB'ye C_B plakaya varmadan gelir (ölür) ya da G_Z'de takılır",
		s10["tamam"].has(false) or s10["oldu"] > 0,
		"adımlar=%s, ölüm=%d, en büyük x=%.0f (ışın B x 787..793)" % [str(s10["tamam"]), s10["oldu"], _n_olc(s10)["xmax"]])
	_kayitlar().sifirla()
	paused = false


func _test_b17_atlanamaz() -> void:
	var kay: Array = await _n17_kayitlar()
	var ayr: Array = []
	var hepsi := true
	# F1 dikey zıplama
	var sa: Dictionary = await _n_senaryo([], _n_spam(0.0, 8), _n_yerlestir(Vector2(300, 576)))
	hepsi = hepsi and _n_olc(sa)["ayak"] > 440.0
	ayr.append("F1 dikey zıplama: en yüksek ayak y=%.1f (döşeme alt kenarı 420)" % _n_olc(sa)["ayak"])
	# DuvarW1: F1 sağa geçilmez (x 440..460).
	var sw: Dictionary = await _n_senaryo([], _n_spam(1.0, 14), _n_yerlestir(Vector2(380, 576)))
	hepsi = hepsi and _n_olc(sw)["xmax"] <= 427.0
	ayr.append("DuvarW1: en büyük x=%.0f (sol yüz 440-14=426)" % _n_olc(sw)["xmax"])
	# BlokW2: F1'de cepten kuyuya geçilmez (x 760..960).
	var sb: Dictionary = await _n_senaryo([], _n_spam(1.0, 14), _n_yerlestir(Vector2(700, 576)))
	hepsi = hepsi and _n_olc(sb)["xmax"] <= 747.0
	ayr.append("BlokW2: en büyük x=%.0f (sol yüz 760-14=746)" % _n_olc(sb)["xmax"])
	# GecitZ ve GecitM kapalı (ZP/MP basılmadı): F2'de sağ+zıpla spam.
	var sg: Dictionary = await _n_senaryo([], _n_spam(1.0, 12), _n_yerlestir(Vector2(790, 356)))
	hepsi = hepsi and _n_olc(sg)["xmax"] <= 807.0
	ayr.append("GecitZ kapalı: en büyük x=%.0f (sol yüz 820-14=806)" % _n_olc(sg)["xmax"])
	var sm: Dictionary = await _n_senaryo([], _n_spam(1.0, 12), _n_yerlestir(Vector2(850, 356)))
	hepsi = hepsi and _n_olc(sm)["xmax"] <= 857.0
	ayr.append("GecitM kapalı (GecitZ'den sonra): en büyük x=%.0f (sol yüz 870-14=856)" % _n_olc(sm)["xmax"])
	# Lazerler
	for k in [["LazerA", Vector2(480, 356), 512.0], ["LazerB", Vector2(760, 356), 787.0], ["LazerC", Vector2(1000, 356), 1037.0]]:
		var sl: Dictionary = await _n_senaryo([], _n_spam(1.0, 8), _n_yerlestir(k[1]))
		var ok: bool = sl["oldu"] > 0 and _n_olc(sl)["xmax"] < k[2] + 12.0
		hepsi = hepsi and ok
		ayr.append("%s zıplayarak: ölüm=%d, en büyük x=%.0f (ışın sol kenarı %.0f)" % [k[0], sl["oldu"], _n_olc(sl)["xmax"], k[2]])
	# LazerC kuyuda (kapalı değil): kuyudan kutuya yürürken ölür
	var sk: Dictionary = await _n_senaryo([], [_b13_a(1, Callable(), 60)], _n_yerlestir(Vector2(990, 576), Vector2(1100, 580)))
	hepsi = hepsi and sk["oldu"] > 0
	ayr.append("LazerC kuyu tabanı (açık): ölüm=%d" % sk["oldu"])
	# Z1 uçuşu LazerA'yı aşmaz (klonsuz).
	var sz: Dictionary = await _n_senaryo([], [_b13_a(1, _b4_x_ge(106.0), 200)] + _n_spam(1.0, 14))
	hepsi = hepsi and sz["oldu"] > 0 and _n_olc(sz)["xmax"] < 530.0
	ayr.append("Z1 uçuşu (klonsuz): ölüm=%d, en büyük x=%.0f (LazerA ışını x 512..518)" % [sz["oldu"], _n_olc(sz)["xmax"]])
	# Ledge kutusuz: kutu uzakta; kuyudan ledge'e zıplama (114 px > 100,9).
	var sl2: Dictionary = await _n_senaryo(kay, _n_spam(1.0, 10), _n_yerlestir(Vector2(1080, 576), Vector2(1000, 580)))
	hepsi = hepsi and _n_olc(sl2)["ayak"] > 486.0 and not sl2["bitti_ham"]
	ayr.append("ledge kutusuz: en yüksek ayak y=%.1f (ledge üstü 486; yetmezlik %.1f px), bitti=%s" % [_n_olc(sl2)["ayak"], _n_olc(sl2)["ayak"] - 486.0, str(sl2["bitti_ham"])])
	# Kutu basamağı
	var sbx: Dictionary = await _n_senaryo(kay, [_b13_a(0, _n_kapali("LazerC"), 500), _b13_a(1, _b4_x_ge(1046.0), 60), _b13_a(1, Callable(), 14, true),
		_b13_a(0, _n_zemin(), 80), _b13_a(1, Callable(), 14, true), _b13_a(1, _b4_bitti_k(), 100)], _n_yerlestir(Vector2(1020, 576), Vector2(1080, 580)))
	var f2: int = sbx["baslangic"][3] if sbx["baslangic"].size() > 3 else 0
	var ayak2 := 1.0e9
	var bas2 := 1.0e9
	for f in range(f2, sbx["iz"].size()):
		ayak2 = minf(ayak2, sbx["iz"][f].y + 24.0)
		bas2 = minf(bas2, sbx["iz"][f].y - 24.0)
	hepsi = hepsi and sbx["bitti_ham"] and ayak2 < 486.0
	ayr.append("kutu basamağı: bitti=%s, ikinci zıplamada kapıya varılana dek en küçük ayak y=%.1f (ledge 486; kapıya varış ölçümü keser, tepe değildir: %.1f px üstünde), baş y=%.1f (DosemeP3 alt 420: o anda %.1f px pay; tavan kırpması tepeyi 468'e sınırlar: taslak pay 18)" % [
		str(sbx["bitti_ham"]), ayak2, 486.0 - ayak2, bas2, bas2 - 420.0])
	_kaydi("Bölüm 17 atlanamazlık hesapları (kat, duvarlar, geçitler, lazerler, Z1 uçuşu, ledge, kutu basamağı)", hepsi, "; ".join(ayr))
	_kayitlar().sifirla()
	paused = false


func _test_b17_kisayol() -> void:
	var kay: Array = await _n17_kayitlar()
	var c_a: Array = kay[0]
	var c_b: Array = kay[1]
	var c_c: Array = kay[2]
	var ayr: Array = []
	var hepsi := true
	var b0: Node = await _bolumu_yukle()
	var var_olan: String = _n_var_olanlar(b0, ["Salter", "Asansor"])
	paused = false
	hepsi = hepsi and var_olan == ""
	ayr.append("sahnede şalter/asansör: [%s] (yok olmalı)" % var_olan)
	var oyuncu_st: Array = [_n17_o(), [_b13_a(1, Callable(), 600)], _n17_gezi() + [_b13_a(1, Callable(), 300)],
		_n17_gezi() + [_b13_a(1, _n_plakada("PlakaC"), 400), _b13_a(0, Callable(), 100)], _n17_o(0, 1000.0, true)]
	var klonsuz_bit := false
	for st in oyuncu_st:
		klonsuz_bit = klonsuz_bit or await _n_bitirir([], st)
	hepsi = hepsi and not klonsuz_bit
	ayr.append("klonsuz (5 oyuncu stratejisi): bitti=%s" % str(klonsuz_bit))
	var kume: Array = [["A", [c_a]], ["B", [c_b]], ["C", [c_c]], ["A+B", [c_a, c_b]], ["A+C", [c_a, c_c]], ["B+C", [c_b, c_c]],
		["A+A", [c_a, c_a]], ["B+B", [c_b, c_b]], ["C+C", [c_c, c_c]], ["A+B+C", [c_a, c_b, c_c]]]
	var biten: Array = []
	for k in kume:
		for st in oyuncu_st:
			if await _n_bitirir(k[1], st):
				biten.append(k[0])
				break
	hepsi = hepsi and biten == ["A+B+C"]
	ayr.append("alt kümeler (10 küme x 5 strateji): bitirenler=%s (yalnız A+B+C beklenir)" % str(biten))
	# kör kayıt
	var kor_b: Array = (await _n_senaryo([], _n17_b()))["kayit"]
	var kor_c: Array = (await _n_senaryo([], _n17_c()))["kayit"]
	var kor_bit := false
	for ks in [[c_a, kor_b], [c_a, kor_c], [kor_b, kor_c], [c_a, kor_b, kor_c]]:
		for st in oyuncu_st:
			kor_bit = kor_bit or await _n_bitirir(ks, st)
	hepsi = hepsi and not kor_bit
	ayr.append("kör kayıtlı B/C ile kümeler: bitti=%s" % str(kor_bit))
	# 2 klon + oyuncu PlakaC'de bekler
	var bekle_c: bool = await _n_bitirir([c_a, c_b], _n17_gezi() + [_b13_a(1, _n_plakada("PlakaC"), 400), _b13_a(0, Callable(), 400)])
	hepsi = hepsi and not bekle_c
	ayr.append("2 klon + oyuncu PlakaC'de bekler: bitti=%s" % str(bekle_c))
	# bant dalgalanması: C_A bant üstünde sag/sol dalgalanır, PlakaA'da yine tutulur; bölüm yine 3 klon ister.
	var a_dal: Array = (await _n_senaryo([], [_b13_a(1, _b4_x_ge(200.0), 200), _b13_a(-1, Callable(), 6), _b13_a(1, Callable(), 6), _b13_a(-1, Callable(), 6),
		_b13_a(1, Callable(), 6)] + _n17_a()))["kayit"]
	var dal_bit: bool = await _n_bitirir([a_dal, c_b], _n17_o())
	var dal_bit2: bool = await _n_bitirir([a_dal, c_b, c_c], _n17_o())
	ayr.append("bant dalgalanması: dalgalı C_A + C_B bitti=%s (2 klon: olmamalı), dalgalı C_A + B + C bitti=%s (3 klon)" % [str(dal_bit), str(dal_bit2)])
	hepsi = hepsi and not dal_bit
	# geçit altı park / röle: C_C' ZP'ye basmaz (G_Z'de kapalı kalır), oyuncu cep gezisiyle fitili açar: yine 3 klon.
	var c_park: Array = (await _n_senaryo([c_a, c_b], _n17_c(0, 15, 0, true)))["kayit"]
	var park_bit3: bool = await _n_bitirir([c_a, c_b, c_park], _n17_o())
	var park_bit2: bool = await _n_bitirir([c_a, c_b], _n17_o())
	ayr.append("geçit altı park/röle (C_C ZP'siz kayıtlı, oyuncu ZP'yi açar): 3 klonla bitti=%s (alternatif yol, klon sayısını düşürmez), 2 klonla bitti=%s" % [str(park_bit3), str(park_bit2)])
	hepsi = hepsi and not park_bit2
	# mandalla klon tasarrufu: oyuncu MP'yi basar, B gezisiz (kör): 2 klonla bitmez.
	var b_gezisiz: Array = (await _n_senaryo([c_a], _n17_gezi(0, 580.0, false, -1, 0, true) + [_b13_a(1, _n_plakada("PlakaB"), 200)]))["kayit"]
	var mp_bit: bool = await _n_bitirir([c_a, b_gezisiz], _n17_o())
	hepsi = hepsi and not mp_bit
	ayr.append("mandalla tasarruf (B gezisiz, oyuncu MP'yi basar; 2 klon): bitti=%s" % str(mp_bit))
	# kutu: kuyu tabanından çıkmaz, plaka tutamaz.
	var tam: Dictionary = await _n_senaryo(kay, _n17_o())
	var ky: float = 0.0
	for o in tam["ozel"]:
		ky = maxf(ky, 0.0)
	var kutu_min_y := 1.0e9
	for o in tam["ozel"]:
		kutu_min_y = minf(kutu_min_y, o["Kutu"].y)
	hepsi = hepsi and kutu_min_y > 500.0
	ayr.append("kutu: tam çözümde en yüksek konumu y=%.0f (kuyu tabanı 580; F2'ye çıkamaz)" % kutu_min_y)
	# S ile yeni iniş: F2 boyunca x'te S, kat değiştirenler.
	var inen: Array = []
	for x in range(120, 1060, 40):
		var ss: Dictionary = await _n_senaryo([], [_b13_a(0, Callable(), 3, false, true), _b13_a(0, Callable(), 45)],
			_n_yerlestir(Vector2(float(x), 356)))
		if _n_son(ss).y > 430.0:
			inen.append(x)
	var inen_ok := true
	for x in inen:
		inen_ok = inen_ok and ((x >= 560 and x <= 680) or (x >= 960 and x <= 1080))
	hepsi = hepsi and inen_ok and inen.size() > 0
	ayr.append("S ile F2'den inenler (x, 40 px adım; yalnız raf1 560..680 / raf2 960..1080 beklenir): %s" % str(inen))
	# min klon 3 kanıtı
	var f3 := -1
	for f in range(tam["ozel"].size()):
		var o: Dictionary = tam["ozel"][f]
		if o["PlakaA"] and o["PlakaB"] and o["PlakaC"] and f3 < 0:
			f3 = f
	var f_lc: int = _n_x_kare(tam["iz"], 1020.0)
	var ok3: bool = tam["bitti_ham"] and f3 >= 0 and f_lc > f3
	hepsi = hepsi and ok3
	ayr.append("min klon 3: bitti=%s, PlakaA+B+C birlikte basılı ilk kare=%d, oyuncu LazerC'ye yakın (x>=1020) kare %d'de varır" % [str(tam["bitti_ham"]), f3, f_lc])
	_kaydi("Bölüm 17 kısayol taraması (klonsuz, alt kümeler, kör kayıt, bant, park/röle, mandal, kutu, S inişleri, min klon 3)", hepsi, " || ".join(ayr))
	_kayitlar().sifirla()
	paused = false


func _test_b17_pencereler() -> void:
	var kay: Array = await _n17_kayitlar()
	var c_a: Array = kay[0]
	var c_b: Array = kay[1]
	var c_c: Array = kay[2]
	var ayr: Array = []
	var hepsi := true
	# --- referans: oyuncu turunda fitil / GecitZ / GecitM pencereleri
	var tam: Dictionary = await _n_senaryo(kay, _n17_o())
	var zp_son := -1
	var gz0 := -1
	var gz1 := -1
	var gm0 := -1
	var mp0: int = _n_ilk(tam, "PlakaM", true)
	for f in range(tam["ozel"].size()):
		var o: Dictionary = tam["ozel"][f]
		if o["PlakaZ_f"]:
			zp_son = f
		if o["GecitZ"] <= 232.0:
			if gz0 < 0:
				gz0 = f
			gz1 = f
		if o["GecitM"] <= 232.0 and gm0 < 0:
			gm0 = f
	var g_in: int = _n_x_kare(tam["iz"], 806.0)
	var g_out: int = _n_x_kare(tam["iz"], 855.0)
	ayr.append("oyuncu turu: ZP son fiziksel kare=%d, GecitZ >=48 px açık kare %d..%d, gövde GecitZ'de kare %d..%d -> W4 fitil payı: çıkışa göre %d kare, girişe göre %d kare (%d px; taslak ~21; geçit altındaki karakter için kapanmayı durdurur), açılış payı %d kare" % [
		zp_son, gz0, gz1, g_in, g_out, gz1 - g_out, gz1 - g_in, (gz1 - g_in) * 5, g_in - gz0])
	ayr.append("MP basışı kare %d, GecitM >=48 px açık kare %d (W6 pay: oyuncunun GecitM'ye (x>=856) varışı kare %d)" % [mp0, gm0, _n_x_kare(tam["iz"], 856.0)])
	hepsi = hepsi and (gz1 - g_out) >= 0
	# --- W1: C_A başta bekleme
	var vg: Array = []
	for d in range(0, 41, 1):
		vg.append(d)
	var okg: Array = await _n_sup(vg, func(v: int) -> bool:
		var a2: Array = (await _n_senaryo([], _n17_a(v)))["kayit"]
		var s: Dictionary = await _n_senaryo([a2], _n17_b())
		return not s["tamam"].has(false) and s["oldu"] == 0)
	var w1 := _n_en_buyuk(vg, okg)
	ayr.append("W1 C_A başta bekleme (kare): C_B başarılı %s (en çok %d kare = %d px; taslak pay ~20)" % [_n_ar(vg, okg), w1, w1 * 5])
	hepsi = hepsi and _n_pen(vg, okg, 0) and w1 >= 1
	# --- W2: raf1 S eşiği; canlı kayıt başarısı ve klon tekrarı (C_B kaydı klon olarak: PlakaB + PlakaM tutulur, klon ölmez)
	var vx: Array = []
	for x in range(560, 641, 3):
		vx.append(x)
	var canli_ok: Array = []
	var klon_ok: Array = []
	for v in vx:
		var s: Dictionary = await _n_senaryo([c_a], _n17_gezi(0, float(v)) + [_b13_a(1, _n_plakada("PlakaB"), 400), _b13_a(0, Callable(), 10)])
		var ok_c: bool = not s["tamam"].has(false) and s["oldu"] == 0
		canli_ok.append(ok_c)
		var ok_k := false
		if ok_c:
			var r: Dictionary = await _n_senaryo([c_a, s["kayit"]], [_b13_a(0, Callable(), 330)])
			var son: Dictionary = r["ozel"][r["ozel"].size() - 1]
			ok_k = son["PlakaB"] and son["PlakaM"] and not r["klon_oldu"][1]
		klon_ok.append(ok_k)
	ayr.append("W2 raf1 S eşiği (merkez x>=v): canlı kayıt %s | klon tekrarı %s (taslak 574..605: 32 px, ayrışma düşülünce 20 px)" % [_n_ar(vx, canli_ok), _n_ar(vx, klon_ok)])
	hepsi = hepsi and _n_en_buyuk(vx, klon_ok) > _n_en_kucuk(vx, klon_ok)
	# --- W3: Z2'de `sag` bırakma süresi
	var vz: Array = [0, 1, 2, 3, 4, 6, 8, 10, 15, 20, 30, 45, 60, 80, 100]
	var okz: Array = await _n_sup(vz, func(v: int) -> bool:
		var s: Dictionary = await _n_senaryo([c_a], _n17_gezi(0, 580.0, false, v) + [_b13_a(1, _n_plakada("PlakaB"), 300)])
		return not s["tamam"].has(false) and s["oldu"] == 0 and s["kare"] <= 600)
	ayr.append("W3 Z2'de `sag` bırakma süresi (kare; değerler %s): C_B başarılı %s (taslak 'en geç ~28' pay)" % [str(vz), _n_ar(vz, okz)])
	# --- W4: ZP'den ayrılınca duraksama (fitil payı): C_C ve oyuncu
	var vf: Array = []
	for d in range(0, 61, 2):
		vf.append(d)
	var okc: Array = await _n_sup(vf, func(v: int) -> bool:
		var s: Dictionary = await _n_senaryo([c_a, c_b], _n17_c(0, 15, v))
		return not s["tamam"].has(false) and s["oldu"] == 0)
	var oko: Array = await _n_sup(vf, func(v: int) -> bool: return await _n_bitirir(kay, _n17_o(0, 985.0, false, v)))
	var w4c := _n_en_buyuk(vf, okc)
	var w4o := _n_en_buyuk(vf, oko)
	ayr.append("W4 ZP'den sonra duraksama (kare): C_C başarılı %s (en çok %d kare = %d px), oyuncu başarılı %s (en çok %d kare = %d px); taslak pay ~21" % [
		_n_ar(vf, okc), w4c, w4c * 5, _n_ar(vf, oko), w4o, w4o * 5])
	hepsi = hepsi and _n_pen(vf, okc, 0) and _n_pen(vf, okc, 60, false)
	# --- W5: C_B başta bekleme -> C_C
	var vh: Array = []
	for d in range(0, 41, 2):
		vh.append(d)
	var okh: Array = await _n_sup(vh, func(v: int) -> bool:
		var b2: Array = (await _n_senaryo([c_a], _n17_b(v)))["kayit"]
		var s: Dictionary = await _n_senaryo([c_a, b2], _n17_c())
		return not s["tamam"].has(false) and s["oldu"] == 0)
	var w5 := _n_en_buyuk(vh, okh)
	ayr.append("W5 C_B başta bekleme (kare): C_C başarılı %s (en çok %d kare = %d px; taslak pay ~16)" % [_n_ar(vh, okh), w5, w5 * 5])
	hepsi = hepsi and _n_pen(vh, okh, 0)
	# --- W7: raf2 S eşiği (oyuncu)
	var vy: Array = []
	for x in range(960, 1081, 3):
		vy.append(x)
	var oky: Array = await _n_sup(vy, func(v: int) -> bool: return await _n_bitirir(kay, _n17_o(0, float(v))))
	ayr.append("W7 raf2 S eşiği (merkez x>=v): oyuncu başarılı %s (taslak 974..1023: 49 px, ayrışma düşülünce 37 px)" % _n_ar(vy, oky))
	hepsi = hepsi and _n_en_buyuk(vy, oky) > _n_en_kucuk(vy, oky)
	# --- W8: C_C başta bekleme -> oyuncu
	var vk: Array = []
	for d in range(0, 61, 3):
		vk.append(d)
	var okk: Array = await _n_sup(vk, func(v: int) -> bool:
		var c2: Array = (await _n_senaryo([c_a, c_b], _n17_c(v)))["kayit"]
		return await _n_bitirir([c_a, c_b, c2], _n17_o()))
	var w8 := _n_en_buyuk(vk, okk)
	ayr.append("W8 C_C başta bekleme (kare): oyuncu başarılı %s (en çok %d kare = %d px; taslak pay ~59)" % [_n_ar(vk, okk), w8, w8 * 5])
	hepsi = hepsi and _n_pen(vk, okk, 0)
	# --- W9: kutu itme hedefi
	var vb: Array = []
	for x in range(1060, 1081, 2):
		vb.append(x)
	var okb: Array = await _n_sup(vb, func(v: int) -> bool:
		var o2: Array = _n17_gezi() + [_b13_a(1, _b4_x_ge(985.0), 400), _b13_a(0, Callable(), 1), _b13_a(0, Callable(), 3, false, true),
			_b13_a(0, _n_zemin(), 120), _b13_a(1, _n_kutu_x_ge(float(v)), 200), _b13_a(1, Callable(), 14, true),
			_b13_a(0, _n_zemin(), 60), _b13_a(1, Callable(), 14, true), _b13_a(1, _b4_bitti_k(), 150)]
		return await _n_bitirir(kay, o2))
	ayr.append("W9 kutu itme hedefi (kutu merkez x>=v'de dur; ledge yüzü kutu 1080): bitiren %s" % _n_ar(vb, okb))
	_kaydi("Bölüm 17 zamanlama payları (fitil, W1..W9)", hepsi, " || ".join(ayr))
	_kayitlar().sifirla()
	paused = false


## Bant/dikiş: canlı kayıt vs klon tekrarı konum farkı (px) ve üst sınır iddiası; bant hızları.
func _test_b17_dikis() -> void:
	var kay: Array = await _n17_kayitlar()
	var ayr: Array = []
	var hepsi := true
	var olc: Array = []
	for k in [["C_A", [], _n17_a()], ["C_B", [kay[0]], _n17_b()], ["C_C", [kay[0], kay[1]], _n17_c()], ["Oyuncu", kay, _n17_o()]]:
		var r: Dictionary = await _n_klon_fark(k[1], k[2])
		olc.append(r["fark"])
		ayr.append("%s canlı/klon en büyük konum farkı %.2f px (ilk sapma kare %d, x=%.0f)" % [k[0], r["fark"], r["ilk"], r["ilk_x"]])
	# Üst sınır iddiası: ölçülen en büyük fark + ~%25 pay; mutlak üst sınır dikiş ayrışması 11,67 px (+%25 = 14,6).
	var en_buyuk := 0.0
	for f in olc:
		en_buyuk = maxf(en_buyuk, f)
	hepsi = hepsi and en_buyuk <= 0.5
	ayr.append("en büyük fark %.2f px (üst sınır iddiası 0,5 px; taslak ayrışma 11,67 px öngörüyordu, bu bölümde çözüm turlarında 0 ölçüldü)" % en_buyuk)
	# Dikiş taraması: bant uçlarında (x=240, 400) durup bekleyen canlı kayıt klon olarak aynı oynar mı?
	var dikis_maks := 0.0
	var dikis_x := 0.0
	var dik_ad: Array = []
	for xs in [226, 232, 236, 240, 244, 250, 256, 388, 394, 398, 402, 406, 412]:
		var adim: Array = [_b13_a(1, _b4_x_ge(float(xs)), 200), _b13_a(0, Callable(), 30), _b13_a(1, _b4_x_ge(440.0), 200)]
		for onceki in [[], [kay[0]]]:
			var rr: Dictionary = await _n_klon_fark(onceki, adim)
			if rr["fark"] > dikis_maks:
				dikis_maks = rr["fark"]
				dikis_x = float(xs)
	# Üst sınır iddiası: ölçülen 3,33 px (bir bant adımı) + ~%25 pay = 4,2 px (taslak ayrışması 11,67 px'e göre çok daha küçük).
	hepsi = hepsi and dikis_maks <= 4.2
	ayr.append("dikiş taraması (x=240 ve 400 çevresinde 13 durma noktası x {klonsuz, C_A'lı}): en büyük canlı/klon farkı %.2f px (durma x>=%.0f; üst sınır iddiası 4,2 px)" % [dikis_maks, dikis_x])
	# Bant hızları: girdisiz 1,667; girdili (sag) ters yön net 3,33 px/kare.
	var sb: Dictionary = await _n_senaryo([], [_b13_a(0, Callable(), 30)], _n_yerlestir(Vector2(320, 356)))
	var hiz0: float = (sb["iz"][29].x - sb["iz"][9].x) / 20.0
	var sg: Dictionary = await _n_senaryo([], [_b13_a(1, Callable(), 30)], _n_yerlestir(Vector2(260, 356)))
	var hiz1: float = (sg["iz"][29].x - sg["iz"][9].x) / 20.0
	ayr.append("bant hızı: girdisiz %.3f px/kare (taslak -1,667), sag basılı %.3f px/kare (taslak +3,33)" % [hiz0, hiz1])
	hepsi = hepsi and absf(hiz0 + 1.667) < 0.1 and absf(hiz1 - 3.333) < 0.1
	# Yürüyüş uzaması: bant 160 px: 160/3,33 = 48 kare, düz 160/5 = 32 kare (taslak ~16 kare uzar).
	var sy: Dictionary = await _n_senaryo([], [_b13_a(1, _b4_x_ge(240.0), 200), _b13_a(1, _b4_x_ge(400.0), 200)], _n_yerlestir(Vector2(200, 356)))
	var f_b: int = sy["baslangic"][1]
	var f_e: int = sy["iz"].size()
	ayr.append("bant geçişi (x 240 -> 400) %d kare (düz zeminde 32; taslak ~48)" % (f_e - f_b))
	_kaydi("Bölüm 17 ölçüm: bant/dikiş, canlı kayıt vs klon tekrarı farkı (üst sınır 0,5 px; dikiş taraması 4,2 px), bant hızları", hepsi, " || ".join(ayr))
	_kayitlar().sifirla()
	paused = false


func _test_b17_tutma() -> void:
	var ayr: Array = []
	var hepsi := true
	aktif_bolum = BOLUM_17
	var r: Dictionary = await _n_tutma_olc("PlakaZ", Vector2(500, 576), 260)
	ayr.append("ZP: ilk basili kare=%d, son fiziksel kare=%d, sonra basılı kalan=%d kare (beklenen tam 70)" % [r["ilk_basili"], r["son_fiziksel"], r["kalan"]])
	hepsi = hepsi and r["kalan"] == 70
	var m: Dictionary = await _n_tutma_olc("PlakaM", Vector2(570, 576), 300)
	ayr.append("MP (mandal): son fiziksel kare=%d, sonra basılı=%d kare (ölçüm sonuna kadar=%s)" % [m["son_fiziksel"], m["kalan"], str(m["sona_kadar"])])
	hepsi = hepsi and m["sona_kadar"]
	# Tur başı sıfırlama
	_kayitlar().sifirla()
	var bolum: Node = await _bolumu_yukle()
	for i in range(30):
		_girdi_uygula({"yon": 0.0, "zipla": false})
		await physics_frame
	var eski_id := bolum.get_instance_id()
	await _r_bas()
	var yeni: Node = await _yeni_sahne_bekle(eski_id)
	var ok: bool = yeni != null and not yeni.get_node("PlakaZ").basili_mi() and yeni.get_node("PlakaZ").kalan_kare == 0 \
		and not yeni.get_node("PlakaM").kilitli and absf(yeni.get_node("GecitZ").position.y - 280.0) < 0.5 \
		and absf(yeni.get_node("GecitM").position.y - 280.0) < 0.5
	hepsi = hepsi and ok
	ayr.append("tur başı sıfırlama: ZP kalan=%d, MP kilitli=%s, GecitZ y=%.0f, GecitM y=%.0f (kapalı 280)" % [
		yeni.get_node("PlakaZ").kalan_kare if yeni != null else -1, str(yeni.get_node("PlakaM").kilitli if yeni != null else "?"),
		yeni.get_node("GecitZ").position.y if yeni != null else -1.0, yeni.get_node("GecitM").position.y if yeni != null else -1.0])
	_kaydi("Bölüm 17: ZP tam 70 kare (tutma_kare=70), MP kalıcı, tur başı sıfırlama", hepsi, " || ".join(ayr))
	_kayitlar().sifirla()
	paused = false


func _test_b17_klon_siniri() -> void:
	await _n_klon_siniri("Bölüm 17: klon sınırı (dördüncü R klon kaydetmez)", 3)


func _test_b17_kilitlenme() -> void:
	var kay: Array = await _n17_kayitlar()
	var ayr: Array = []
	var hepsi := true
	# (a) Kuyuda ölüm: LazerC açıkken kuyuya inen oyuncu ışına girer, tur yeniden başlar, klonlar korunur.
	_kayitlar().sifirla()
	_kayitlar().tur_kaydet(kay[0].duplicate(true))
	var bolum: Node = await _bolumu_yukle()
	bolum.get_node("Oyuncu").global_position = Vector2(1000, 356)
	var sayac := [0]
	bolum.get_node("Oyuncu").oyuncu_oldu.connect(func() -> void: sayac[0] += 1)
	var eski_id := bolum.get_instance_id()
	var s: Dictionary = await _n_kosullu(bolum, [_b13_a(0, Callable(), 1), _b13_a(0, Callable(), 3, false, true), _b13_a(0, _n_zemin(), 100),
		_b13_a(1, Callable(), 60)], sayac)
	var yeni: Node = await _yeni_sahne_bekle(eski_id)
	var etiket := ""
	var ok: bool = sayac[0] > 0 and yeni != null and _kayitlar().turlar.size() == 1
	if yeni != null:
		etiket = yeni.bilgi.text
		ok = ok and _klonlar(yeni).size() == 1 and etiket.contains("Tur 2") and etiket.contains("1/3")
	hepsi = hepsi and ok
	ayr.append("kuyuda ölüm: ölüm=%d, kayıtlı tur=%d, etiket=\"%s\"" % [sayac[0], _kayitlar().turlar.size(), etiket])
	# (b) Kuyudan F2'ye dönüş yok.
	var sk: Dictionary = await _n_senaryo(kay, _n_spam(0.0, 12), _n_yerlestir(Vector2(1010, 576), Vector2(975, 580)))
	hepsi = hepsi and _n_olc(sk)["ayak"] > 450.0 and sk["oldu"] == 0
	ayr.append("kuyuda ışının solunda: zıplama en yüksek ayak y=%.1f (F2 yüzeyi 380), ölüm=%d" % [_n_olc(sk)["ayak"], sk["oldu"]])
	# (c) Baştan başla: kutu başlangıçta.
	_kayitlar().sifirla()
	_kayitlar().tur_kaydet(kay[0].duplicate(true))
	var b2: Node = await _bolumu_yukle()
	var eski: Node = current_scene
	b2.get_node("EkranButonlari/Kutu/YenidenDugmesi").pressed.emit()
	var yeni2: Node = await _sahne_degisimini_bekle(eski)
	var kutu_bas: Vector2 = yeni2.get_node("Kutu").global_position
	var ok_c: bool = _kayitlar().turlar.size() == 0 and _klonlar(yeni2).size() == 0 and yeni2.bilgi.text.begins_with("Tur 1 ") and absf(kutu_bas.x - 1060.0) < 1.0
	hepsi = hepsi and ok_c
	ayr.append("Baştan başla: kayıt=%d, klon=%d, etiket=\"%s\", kutu x=%.0f" % [_kayitlar().turlar.size(), _klonlar(yeni2).size(), yeni2.bilgi.text, kutu_bas.x])
	# (d) G_Z altında park / cep: G_Z solunda takılan oyuncu raf1'e dönüp tekrar deneyebilir (MP kalıcı).
	var sg: Dictionary = await _n_senaryo([kay[0], kay[1]], _n17_c(0, 15, 60) + [_b13_a(0, Callable(), 5)])
	hepsi = hepsi and sg["oldu"] == 0
	ayr.append("G_Z'de geç kalma: ölüm=%d, kilit yok (oyuncu geri dönebilir), son (%.0f,%.0f)" % [sg["oldu"], _n_son(sg).x, _n_son(sg).y])
	# (e) klonlar plakada biter
	var tam: Dictionary = await _n_senaryo(kay, [_b13_a(0, Callable(), 390)])
	var ki: Array = tam["klon_izleri"]
	var sa: Vector2 = ki[0][ki[0].size() - 1]
	var sb: Vector2 = ki[1][ki[1].size() - 1]
	var sc: Vector2 = ki[2][ki[2].size() - 1]
	var ok_e: bool = not tam["klon_oldu"][0] and not tam["klon_oldu"][1] and not tam["klon_oldu"][2] \
		and sa.x > 395.0 and sa.x < 480.0 and sb.x > 690.0 and sb.x < 790.0 and sc.x > 880.0 and sc.x < 980.0
	hepsi = hepsi and ok_e
	ayr.append("klonlar plakada biter: A (%.0f,%.0f), B (%.0f,%.0f), C (%.0f,%.0f); geçit altında değil" % [sa.x, sa.y, sb.x, sb.y, sc.x, sc.y])
	# (f) ölü klon yerinde donar.
	var sd: Dictionary = await _n_senaryo([kay[1]], [_b13_a(0, Callable(), 250)])
	var kz: Array = sd["klon_izleri"][0]
	var donuk: bool = sd["klon_oldu"][0] and kz[kz.size() - 1] == kz[kz.size() - 40] and kz[kz.size() - 1].x < 520.0
	hepsi = hepsi and donuk
	ayr.append("ölü klon: öldü=%s, son (%.0f,%.0f), sabit=%s" % [str(sd["klon_oldu"][0]), kz[kz.size() - 1].x, kz[kz.size() - 1].y, str(donuk)])
	_kaydi("Bölüm 17 kilitlenme: kuyuda ölüm, kuyudan dönüş yok, Baştan başla, G_Z, klon konumları, ölü klon", hepsi, " || ".join(ayr))
	_kayitlar().sifirla()
	paused = false


func _test_b17_determinizm() -> void:
	var kay: Array = await _n17_kayitlar()
	await _n_determinizm("Bölüm 17: determinizm (100x çözüm)", kay, _n17_o())




# ---------------------------------------------------------------- Bölüm 16 (Mandal)
# C_A: Z1 ile kata çıkar, PlakaA'da kalır. C_B: LazerA'yı geçer, rafta S, cepte MP (mandal), Z2 ile döner,
# G'yi geçer, PlakaB'de kalır. C_C: aynı gezi, PlakaC'de kalır. Oyuncu: gezi + kutuyu iter + kutu/Sehpa basamağı.
var _n16_onb: Array = []   # [A, B, C]


func _n16_a(gec := 0, bekle := 15) -> Array:
	var d: Array = []
	if gec > 0:
		d.append(_b13_a(0, Callable(), gec))
	d += [_b13_a(1, _b4_x_ge(250.0), 300), _b13_a(0, _n_plakada("PlakaA"), 100), _b13_a(0, Callable(), bekle)]
	return d


## Cep gezisi: Z1, raf üstünde S (s_x eşiği; sag_tut: S sırasında sag basılı), MP, Z2 sensörüne gir,
## `sag` bırak (z2_bekle>=0: o kadar kare; <0: ayak y<=z2_y olana kadar), sonra `sag`.
## atla: cep gezisini atlayıp yalnız F2 koşusu. gec: başta bekleme.
func _n16_gezi(gec := 0, s_x := 440.0, sag_tut := false, z2_x := 472.0, z2_bekle := -1, atla := false) -> Array:
	var d: Array = []
	if gec > 0:
		d.append(_b13_a(0, Callable(), gec))
	d.append(_b13_a(1, _b4_x_ge(150.0), 300))
	if atla:
		d.append(_b13_a(1, _b4_x_ge(560.0), 300))
		return d
	d.append(_b13_a(1, _b4_x_ge(s_x), 300))
	if sag_tut:
		d.append(_b13_a(1, Callable(), 3, false, true))
	else:
		d += [_b13_a(0, Callable(), 1), _b13_a(0, Callable(), 3, false, true)]
	d += [_b13_a(0, _n_plakada("MP"), 120), _b13_a(0, Callable(), 2), _b13_a(1, _b4_x_ge(z2_x), 100)]
	if z2_bekle >= 0:
		d.append(_b13_a(0, Callable(), z2_bekle))
	else:
		d.append(_b13_a(0, _n_y_le(345.0), 100))
	d.append(_b13_a(1, _n_zemin(), 80))
	return d


func _n16_b(gec := 0, bekle := 15) -> Array:
	return _n16_gezi(gec) + [_b13_a(1, _n_plakada("PlakaB"), 400), _b13_a(0, Callable(), bekle)]


func _n16_c(gec := 0, bekle := 15, atla := false) -> Array:
	return _n16_gezi(gec, 440.0, false, 472.0, -1, atla) + [_b13_a(1, _n_plakada("PlakaC"), 500), _b13_a(0, Callable(), bekle)]


## Oyuncu: gezi + (kutu hedefe kadar it) + kutuya zıpla + Sehpa'ya zıpla + kapı.
func _n16_o(gec := 0, kutu_x := 959.0, z_n := 14) -> Array:
	return _n16_gezi(gec) + [_b13_a(1, _n_kutu_x_ge(kutu_x), 400), _b13_a(1, Callable(), z_n, true), _b13_a(0, _n_zemin(), 80),
		_b13_a(1, Callable(), z_n, true), _b13_a(1, _b4_bitti_k(), 150)]


func _n16_kayitlar() -> Array:
	if _n16_onb.is_empty():
		var s1: Dictionary = await _n_senaryo([], _n16_a())
		var s2: Dictionary = await _n_senaryo([s1["kayit"]], _n16_b())
		var s3: Dictionary = await _n_senaryo([s1["kayit"], s2["kayit"]], _n16_c())
		_n16_onb = [s1["kayit"], s2["kayit"], s3["kayit"]]
	return _n16_onb


func _b16_calistir() -> void:
	await _test_b16_cozum()
	await _test_b16_basarisizlik()
	await _test_b16_atlanamaz()
	await _test_b16_kisayol()
	await _test_b16_pencereler()
	await _test_b16_klon_fark()
	await _test_b16_mandal()
	await _test_b16_klon_siniri()
	await _test_b16_kilitlenme()
	await _test_b16_determinizm()


func _test_b16_cozum() -> void:
	await _n_cozum("Bölüm 16 çözümü (4 tur, 3 klon, gerçek R/girdi yolu)", [_n16_a(), _n16_b(), _n16_c()], _n16_o(), 3)


func _test_b16_basarisizlik() -> void:
	var kay: Array = await _n16_kayitlar()
	var c_a: Array = kay[0]
	var c_b: Array = kay[1]
	# 1) klonsuz: LazerA'da ölür.
	var s1: Dictionary = await _n_senaryo([], _n16_gezi() + [_b13_a(1, Callable(), 100)])
	var p1: Vector2 = _n_son(s1)
	var s1b: Dictionary = await _n_senaryo([], [_b13_a(1, Callable(), 300)])
	_kaydi("Bölüm 16 başarısızlık 1: klonsuz -> LazerA'da ölür", s1b["oldu"] > 0 and not s1b["bitti_ham"] and _n_son(s1b).x < 330.0,
		"ölüm=%d, son konum (%.0f,%.0f) (ışın x 327..333, gövde girişi 313)" % [s1b["oldu"], _n_son(s1b).x, _n_son(s1b).y])
	# 2) yalnız C_A: oyuncu G'de takılır/LazerB'de ölür (MP basılmadıysa G kapalı).
	var s2: Dictionary = await _n_senaryo([c_a], [_b13_a(1, Callable(), 300)])
	_kaydi("Bölüm 16 başarısızlık 2: yalnız C_A, oyuncu doğrudan yürür -> F2 koşusunda G kapalı, çarpıp durur (ölmez)", s2["oldu"] == 0 and not s2["bitti_ham"] and _n_olc(s2)["xmax"] < 590.0,
		"en büyük x=%.0f (G sol yüzü 590, gövde 576), ölüm=%d" % [_n_olc(s2)["xmax"], s2["oldu"]])
	var s2b: Dictionary = await _n_senaryo([c_a], _n16_o())
	_kaydi("Bölüm 16 başarısızlık 2b: yalnız C_A, oyuncu cep gezisiyle G'yi açar -> LazerB'de ölür", s2b["oldu"] > 0 and not s2b["bitti_ham"],
		"ölüm=%d, son (%.0f,%.0f) (LazerB ışını x 737..743)" % [s2b["oldu"], _n_son(s2b).x, _n_son(s2b).y])
	# 3) C_A + C_B (C_C yok): oyuncu LazerC'de ölür.
	var s3: Dictionary = await _n_senaryo([c_a, c_b], _n16_o())
	_kaydi("Bölüm 16 başarısızlık 3: C_A + C_B, C_C yok -> LazerC'de ölür", s3["oldu"] > 0 and not s3["bitti_ham"] and _n_son(s3).x > 800.0 and _n_son(s3).x < 860.0,
		"ölüm=%d, son (%.0f,%.0f) (ışın x 857..863)" % [s3["oldu"], _n_son(s3).x, _n_son(s3).y])
	# 4) C_B cep gezisi olmadan (G kapalı): kayıt turunda G'ye çarpıp bekler; PlakaB tutulmaz, oyuncu LazerB'de ölür.
	var b_gezisiz: Array = (await _n_senaryo([c_a], _n16_c(0, 15, true)))["kayit"]
	var s4: Dictionary = await _n_senaryo([c_a, b_gezisiz], _n16_o())
	_kaydi("Bölüm 16 başarısızlık 4: C_B cep gezisi yapmaz (G kapalı) -> PlakaB tutulmaz, oyuncu LazerB'de ölür", s4["oldu"] > 0 and not s4["bitti_ham"],
		"ölüm=%d, son (%.0f,%.0f)" % [s4["oldu"], _n_son(s4).x, _n_son(s4).y])
	# 5) Rafta `sag` basılıyken S: sürüklenip Z2 sensörüne iner (merkez > 465), MP basılmaz.
	var s5: Dictionary = await _n_senaryo([c_a], _n16_gezi(0, 440.0, true) + [_b13_a(0, Callable(), 10)])
	var mp_basildi: bool = _n_ilk(s5, "MP", true) >= 0
	var g_min: float = 1.0e9
	for o in s5["ozel"]:
		g_min = minf(g_min, o["G"])
	# Taslak §9.5: "cebe sürüklenip Z2'den hemen fırlar, MP basılmaz". Ölçülen: MP yine basılır (gövde MP kenarına iner), G açılır.
	_kaydi("Bölüm 16 ölçüm 5: rafta `sag` basılıyken S -> MP yine basılır, G açılır (taslak §9.5 'MP basılmaz' iddiası yanlış)", mp_basildi and g_min <= 181.0 and s5["oldu"] == 0,
		"MP basıldı=%s, G en yüksek (küçük y) = %.0f (kapalı 280), kare %d, ölüm=%d, son (%.0f,%.0f)" % [str(mp_basildi), g_min, s5["kare"], s5["oldu"], _n_son(s5).x, _n_son(s5).y])
	# 6) Z2'de `sag` hiç bırakılmazsa: (bırakılmadan sürekli sag) tavan/döşeme köşesine çarpıp geri düşer.
	var s6: Dictionary = await _n_senaryo([c_a], _n16_gezi(0, 440.0, false, 472.0, 0) + [_b13_a(1, _n_plakada("PlakaB"), 120)])
	_kaydi("Bölüm 16 başarısızlık 6: Z2'de `sag` bırakılmaz (sürekli sag) -> köşeye çarpıp cebe geri düşer (taslak: gövde x=526'da yaslanır)", s6["tamam"].has(false) or s6["kare"] > 200,
		"adımlar=%s, kare=%d, ölüm=%d" % [str(s6["tamam"]), s6["kare"], s6["oldu"]])
	# 7) C_B plakadan erken ayrılır (PlakaB'den geri dönüp cebe iner): LazerB açılır, C_C ve oyuncu ölür.
	var b_erken: Array = (await _n_senaryo([c_a], _n16_gezi() + [_b13_a(1, _n_plakada("PlakaB"), 400), _b13_a(-1, _b4_x_le(600.0), 100),
		_b13_a(0, Callable(), 100)]))["kayit"]
	var s7: Dictionary = await _n_senaryo([c_a, b_erken], _n16_c())
	_kaydi("Bölüm 16 başarısızlık 7: C_B plakadan erken ayrılır -> C_C LazerB'de ölür", s7["oldu"] > 0 and not s7["bitti_ham"],
		"ölüm=%d, son (%.0f,%.0f)" % [s7["oldu"], _n_son(s7).x, _n_son(s7).y])
	# 8) Kutu sola itilirse: basamak kaybolur (bölüm kilitlenir).
	var s8: Dictionary = await _n_senaryo(kay, [_b13_a(-1, _b4_x_le(700.0), 400), _b13_a(0, Callable(), 3)], _n_yerlestir(Vector2(960, 356)))
	var kutu_x: float = s8["ozel"][s8["ozel"].size() - 1]["Kutu"].x
	_kaydi("Bölüm 16 başarısızlık 8: kutu sağdan sola itilir -> Sehpa yüzünden uzaklaşır", kutu_x < 760.0,
		"kutu son x=%.0f (başlangıç 920, Sehpa yüzü 980)" % kutu_x)
	# 9) S çok erken (x=400 .. raf başı 420): düşmez.
	var s9: Dictionary = await _n_senaryo([c_a], _n16_gezi(0, 425.0) + [_b13_a(1, _n_plakada("PlakaB"), 100)])
	_kaydi("Bölüm 16 başarısızlık 9: raf başında (x~425) S -> döşeme desteği sürer, cebe inilmez, G açılmaz (C_B PlakaB'ye varamaz, ölmez)", s9["tamam"].has(false) and s9["oldu"] == 0,
		"adımlar=%s, ölüm=%d, en büyük y=%.1f (cep ~576; yüzey 355.9)" % [str(s9["tamam"]), s9["oldu"], _n_olc(s9)["ymax"]])
	_kayitlar().sifirla()
	paused = false


func _test_b16_atlanamaz() -> void:
	var kay: Array = await _n16_kayitlar()
	var ayr: Array = []
	var hepsi := true
	# F1 -> F2: zıplayarak çıkılmaz (kat 220 px).
	var sa: Dictionary = await _n_senaryo([], _n_spam(0.0, 8), _n_yerlestir(Vector2(300, 576)))
	var ok: bool = _n_olc(sa)["ayak"] > 440.0
	hepsi = hepsi and ok
	ayr.append("F1 dikey zıplama: en yüksek ayak y=%.1f (döşeme alt kenarı 420)" % _n_olc(sa)["ayak"])
	# DuvarW: F1 sağa geçilmez.
	var sw: Dictionary = await _n_senaryo([], _n_spam(1.0, 14), _n_yerlestir(Vector2(300, 576)))
	ok = _n_olc(sw)["xmax"] <= 367.0
	hepsi = hepsi and ok
	ayr.append("DuvarW: en büyük x=%.0f (sol yüz 380-14=366)" % _n_olc(sw)["xmax"])
	# Cep dikey zıplama: raf altından çıkılmaz (kat 220 px); cep sağ duvarı.
	var sc: Dictionary = await _n_senaryo([], _n_spam(0.0, 8), _n_yerlestir(Vector2(430, 576)))
	ok = _n_olc(sc)["ayak"] > 450.0
	hepsi = hepsi and ok
	ayr.append("cep dikey zıplama (Z2 dışı x=430): en yüksek ayak y=%.1f (raf üstü 380)" % _n_olc(sc)["ayak"])
	var sd: Dictionary = await _n_senaryo([], _n_spam(1.0, 10), _n_yerlestir(Vector2(560, 576)))
	ok = _n_olc(sd)["xmax"] <= 587.0
	hepsi = hepsi and ok
	ayr.append("DuvarCep: en büyük x=%.0f (sol yüz 600-14=586), kayıtsız Z2 sensörü içinden geçse bile" % _n_olc(sd)["xmax"])
	# G kapalı (MP basılmadı): F2'de sağ+zıpla spam.
	var sg: Dictionary = await _n_senaryo([kay[0]], _n_spam(1.0, 12), _n_yerlestir(Vector2(560, 356)))
	ok = _n_olc(sg)["xmax"] <= 577.0 or _n_olc(sg)["xmax"] <= 587.0
	hepsi = hepsi and ok
	ayr.append("G kapalı: en büyük x=%.0f (sol yüz 590-14=576)" % _n_olc(sg)["xmax"])
	# Lazerler (kapalı değil): zıplayarak aşılmaz.
	for k in [["LazerA", Vector2(300, 356), 327.0], ["LazerB", Vector2(700, 356), 737.0], ["LazerC", Vector2(820, 356), 857.0]]:
		var sl: Dictionary = await _n_senaryo([], _n_spam(1.0, 8), _n_yerlestir(k[1], Vector2(100, 360)))
		ok = sl["oldu"] > 0 and _n_olc(sl)["xmax"] < k[2] + 12.0
		hepsi = hepsi and ok
		ayr.append("%s zıplayarak: ölüm=%d, en büyük x=%.0f (ışın sol kenarı %.0f)" % [k[0], sl["oldu"], _n_olc(sl)["xmax"], k[2]])
	# Z1/Z2 uçuşu lazer bandına girer: Z1 uçuşu (klonsuz) sağ+zıpla: LazerA'da ölür.
	var sz: Dictionary = await _n_senaryo([], [_b13_a(1, _b4_x_ge(106.0), 200)] + _n_spam(1.0, 14))
	ok = sz["oldu"] > 0 and _n_olc(sz)["xmax"] < 345.0
	hepsi = hepsi and ok
	ayr.append("Z1 uçuşu (klonsuz): ölüm=%d, en büyük x=%.0f, uçuş tepesi ayak y=%.1f (taslak 353)" % [sz["oldu"], _n_olc(sz)["xmax"], _n_olc(sz)["ayak"]])
	# Sehpa kutusuz: oyuncu Sehpa yüzünde (kutu uzakta) sağ+zıpla spam: çıkılmaz (120 px > 100,9).
	var sk: Dictionary = await _n_senaryo(kay, _n_spam(1.0, 10), _n_yerlestir(Vector2(950, 356), Vector2(100, 360)))
	ok = _n_olc(sk)["ayak"] > 260.0 and not sk["bitti_ham"]
	hepsi = hepsi and ok
	ayr.append("Sehpa kutusuz: en yüksek ayak y=%.1f (Sehpa üstü 260; yetmezlik %.1f px), bitti=%s" % [_n_olc(sk)["ayak"], _n_olc(sk)["ayak"] - 260.0, str(sk["bitti_ham"])])
	# Kutu basamağı: kutu Sehpa yüzünde: kutuya, Sehpa'ya çıkış payı + tavan baş payı.
	var sb: Dictionary = await _n_senaryo(kay, [_b13_a(1, Callable(), 14, true), _b13_a(0, _n_zemin(), 80), _b13_a(1, Callable(), 14, true),
		_b13_a(1, _b4_bitti_k(), 100)], _n_yerlestir(Vector2(926, 356), Vector2(960, 360)))
	var f2: int = sb["baslangic"][2] if sb["baslangic"].size() > 2 else 0
	var ayak2 := 1.0e9
	var bas2 := 1.0e9
	for f in range(f2, sb["iz"].size()):
		ayak2 = minf(ayak2, sb["iz"][f].y + 24.0)
		bas2 = minf(bas2, sb["iz"][f].y - 24.0)
	ok = sb["bitti_ham"] and ayak2 < 260.0 and bas2 > 180.0
	hepsi = hepsi and ok
	ayr.append("kutu basamağı: bitti=%s, ikinci zıplama tepe ayak y=%.1f (Sehpa 260: pay %.1f px; taslak 20,9), baş y=%.1f (tavan 180: pay %.1f px; taslak 11)" % [
		str(sb["bitti_ham"]), ayak2, 260.0 - ayak2, bas2, bas2 - 180.0])
	_kaydi("Bölüm 16 atlanamazlık hesapları (kat, DuvarW, cep, DuvarCep, G, lazerler, Z1 uçuşu, Sehpa, kutu basamağı)", hepsi, "; ".join(ayr))
	_kayitlar().sifirla()
	paused = false


func _test_b16_kisayol() -> void:
	var kay: Array = await _n16_kayitlar()
	var c_a: Array = kay[0]
	var c_b: Array = kay[1]
	var c_c: Array = kay[2]
	var ayr: Array = []
	var hepsi := true
	var b0: Node = await _bolumu_yukle()
	var var_olan: String = _n_var_olanlar(b0, ["Bant", "Salter", "Asansor", "Zamanli", "PlakaZ"])
	paused = false
	hepsi = hepsi and var_olan == ""
	ayr.append("sahnede bant/şalter/asansör/zamanlı plaka: [%s] (yok olmalı)" % var_olan)
	var oyuncu_st: Array = [_n16_o(), [_b13_a(1, Callable(), 500)], _n16_gezi() + [_b13_a(1, Callable(), 300)],
		_n16_gezi() + [_b13_a(1, _n_plakada("PlakaC"), 400), _b13_a(0, Callable(), 100)]]
	# klonsuz
	var klonsuz_bit := false
	for st in oyuncu_st:
		klonsuz_bit = klonsuz_bit or await _n_bitirir([], st)
	hepsi = hepsi and not klonsuz_bit
	ayr.append("klonsuz (4 oyuncu stratejisi): bitti=%s" % str(klonsuz_bit))
	# tüm alt kümeler (taslak kayıtlarıyla) ve oyuncu stratejileri
	var kume: Array = [["A", [c_a]], ["B", [c_b]], ["C", [c_c]], ["A+B", [c_a, c_b]], ["A+C", [c_a, c_c]], ["B+C", [c_b, c_c]],
		["A+A", [c_a, c_a]], ["B+B", [c_b, c_b]], ["C+C", [c_c, c_c]], ["A+B+C", [c_a, c_b, c_c]]]
	var biten: Array = []
	for k in kume:
		for st in oyuncu_st:
			if await _n_bitirir(k[1], st):
				biten.append(k[0])
				break
	hepsi = hepsi and biten == ["A+B+C"]
	ayr.append("alt kümeler (10 küme x 4 strateji): bitirenler=%s (yalnız A+B+C beklenir)" % str(biten))
	# kör kayıt: klonlar gerçek dünyada önceki klonlar olmadan kaydedilir (kayıt turunda ölüm -> boş)
	var kor_b: Array = (await _n_senaryo([], _n16_b()))["kayit"]
	var kor_c: Array = (await _n_senaryo([], _n16_c()))["kayit"]
	var kor_bit := false
	for ks in [[c_a, kor_b], [c_a, kor_c], [kor_b, kor_c], [c_a, kor_b, kor_c]]:
		for st in oyuncu_st:
			kor_bit = kor_bit or await _n_bitirir(ks, st)
	hepsi = hepsi and not kor_bit
	ayr.append("kör kayıtlı (önceki klonsuz kaydedilen) B/C ile kümeler: bitti=%s" % str(kor_bit))
	# min klon-1 = 2 klon + oyuncunun PlakaC'yi tutması: kapıya gidemez.
	var c_oyuncu_bekle: bool = await _n_bitirir([c_a, c_b], _n16_gezi() + [_b13_a(1, _n_plakada("PlakaC"), 400), _b13_a(0, Callable(), 400)])
	hepsi = hepsi and not c_oyuncu_bekle
	ayr.append("2 klon + oyuncu PlakaC'de bekler: bitti=%s" % str(c_oyuncu_bekle))
	# mandal ile klon tasarrufu: MP'yi oyuncunun kendisi basması (B', C' cep gezisi atlar; kör kayıtlı): yine A, B', C' = 3 klon.
	var b_atla: Array = (await _n_senaryo([c_a], _n16_c(0, 15, true)))["kayit"]
	var c_atla: Array = (await _n_senaryo([c_a, b_atla], _n16_c(0, 15, true)))["kayit"]
	var s_mp: Dictionary = await _n_senaryo([c_a, b_atla, c_atla], _n16_o())
	ayr.append("MP'yi oyuncu basar (C_B, C_C gezisiz; 3 klon): bitti=%s, ölüm=%d (klon sayısını düşürmez: yine A + 2 plaka tutucu)" % [str(s_mp["bitti_ham"]), s_mp["oldu"]])
	var s_mp2: Dictionary = await _n_senaryo([c_a, b_atla], _n16_o())
	hepsi = hepsi and not s_mp2["bitti_ham"]
	ayr.append("MP'yi oyuncu basar, 2 klon (A + gezisiz B): bitti=%s" % str(s_mp2["bitti_ham"]))
	# röle: oyuncu PlakaA'da kalır, tek klon... oyuncu plakada bekleyip kapıya gidemez; strateji A.
	# kutuyla plaka tutma: kutu sola PlakaC üstüne itilir (LazerC kapalı kalır) - oyuncu LazerC'yi geçmiş olmalı (C_C ile).
	var s_k: Dictionary = await _n_senaryo([c_a, c_b], _n16_gezi() + [_b13_a(1, _n_plakada("PlakaC"), 400), _b13_a(0, Callable(), 30)])
	hepsi = hepsi and not s_k["bitti_ham"]
	ayr.append("kutu PlakaC'ye itmek için LazerC (x=860) geçilmeli: C_C yokken oyuncu PlakaC'ye yürüyebilir ama ışının sağına geçemez; bitti=%s, ölüm=%d" % [str(s_k["bitti_ham"]), s_k["oldu"]])
	# S ile yeni iniş: F2 boyunca; kutu uzakta.
	var inen: Array = []
	for x in range(120, 961, 40):
		var ss: Dictionary = await _n_senaryo([], [_b13_a(0, Callable(), 3, false, true), _b13_a(0, Callable(), 45)],
			_n_yerlestir(Vector2(float(x), 356), Vector2(50, 360)))
		if _n_son(ss).y > 430.0:
			inen.append(x)
	var inen_ok := true
	for x in inen:
		inen_ok = inen_ok and x >= 400 and x <= 560
	hepsi = hepsi and inen_ok and inen.size() > 0
	ayr.append("S ile F2'den inenler (x, 40 px adım; yalnız raf 420..540 + kenar boşluk beklenir): %s" % str(inen))
	# min klon 3 kanıtı: üç plaka birlikte basılı, oyuncu LazerC'den sonra.
	var tam: Dictionary = await _n_senaryo(kay, _n16_o())
	var f3 := -1
	for f in range(tam["ozel"].size()):
		var o: Dictionary = tam["ozel"][f]
		if o["PlakaA"] and o["PlakaB"] and o["PlakaC"] and f3 < 0:
			f3 = f
	var f_lc: int = _n_x_kare(tam["iz"], 870.0)
	var ok3: bool = tam["bitti_ham"] and f3 >= 0 and f_lc > f3
	hepsi = hepsi and ok3
	ayr.append("min klon 3: bitti=%s, PlakaA+B+C birlikte basılı ilk kare=%d, oyuncu LazerC ışınına (x>=870) kare %d'de varır" % [str(tam["bitti_ham"]), f3, f_lc])
	_kaydi("Bölüm 16 kısayol taraması (klonsuz, alt kümeler, kör kayıt, mandal tasarrufu, kutu, S inişleri, min klon 3)", hepsi, " || ".join(ayr))
	_kayitlar().sifirla()
	paused = false


func _test_b16_pencereler() -> void:
	var kay: Array = await _n16_kayitlar()
	var c_a: Array = kay[0]
	var c_b: Array = kay[1]
	var c_c: Array = kay[2]
	var ayr: Array = []
	var hepsi := true
	# --- referans zamanlar (C_C turu, klonlar A, B)
	var rc: Dictionary = await _n_senaryo([c_a, c_b], _n16_c())
	var f_mp: int = _n_ilk(rc, "MP", true)
	var f_g48 := -1
	for f in range(rc["ozel"].size()):
		if rc["ozel"][f]["G"] <= 232.0:
			f_g48 = f
			break
	var f_gx: int = _n_x_kare(rc["iz"], 576.0)
	ayr.append("referans (C_C turu): MP basışı kare %d, G >=48 px açık kare %d, C_C'nin G'ye (x>=576) varışı kare %d, G önünde bekleme %d kare" % [f_mp, f_g48, f_gx, maxi(0, f_g48 - f_gx)])
	var rb: Dictionary = await _n_senaryo([c_a], _n16_b())
	var f_mpb: int = _n_ilk(rb, "MP", true)
	var f_g48b := -1
	for f in range(rb["ozel"].size()):
		if rb["ozel"][f]["G"] <= 232.0:
			f_g48b = f
			break
	var f_gxb: int = _n_x_kare(rb["iz"], 576.0)
	ayr.append("C_B turu: MP kare %d, G>=48 kare %d, C_B G'ye varış kare %d -> W3 pay %d kare (taslak ~16)" % [f_mpb, f_g48b, f_gxb, f_gxb - f_g48b])
	hepsi = hepsi and f_gxb - f_g48b >= 8
	# --- W1: C_A başta bekleme (C_B LazerA'ya geç basmaya karşı)
	var vg: Array = []
	for d in range(0, 41, 1):
		vg.append(d)
	var okg: Array = await _n_sup(vg, func(v: int) -> bool:
		var a2: Array = (await _n_senaryo([], _n16_a(v)))["kayit"]
		var s: Dictionary = await _n_senaryo([a2], _n16_b())
		return not s["tamam"].has(false) and s["oldu"] == 0)
	var w1 := _n_en_buyuk(vg, okg)
	ayr.append("W1 C_A başta bekleme (kare): C_B başarılı %s (en çok %d kare = %d px; taslak pay ~19)" % [_n_ar(vg, okg), w1, w1 * 5])
	hepsi = hepsi and _n_pen(vg, okg, 0) and w1 >= 3 and w1 < 40
	# --- W2: S konumu eşiği (C_B başarılı mı)
	var vx: Array = []
	for x in range(425, 481, 3):
		vx.append(x)
	var okx: Array = await _n_sup(vx, func(v: int) -> bool:
		var s: Dictionary = await _n_senaryo([c_a], _n16_gezi(0, float(v)) + [_b13_a(1, _n_plakada("PlakaB"), 400)])
		return not s["tamam"].has(false) and s["oldu"] == 0)
	ayr.append("W2 S konumu eşiği (raf üstü merkez x>=v): C_B başarılı %s (taslak 434..465: 31 px)" % _n_ar(vx, okx))
	hepsi = hepsi and _n_en_buyuk(vx, okx) > _n_en_kucuk(vx, okx)
	# --- W4: Z2 sensöründe `sag` bırakma süresi (z2_bekle), 0..70
	var vz: Array = [0, 1, 2, 3, 4, 6, 8, 10, 15, 20, 30, 45, 60, 80, 100]
	var okz: Array = await _n_sup(vz, func(v: int) -> bool:
		var s: Dictionary = await _n_senaryo([c_a], _n16_gezi(0, 440.0, false, 472.0, v) + [_b13_a(1, _n_plakada("PlakaB"), 300)])
		return not s["tamam"].has(false) and s["oldu"] == 0 and s["kare"] <= 600)
	ayr.append("W4 Z2'de `sag` bırakma süresi (kare; değerler %s): C_B başarılı %s (taslak: sag sürekli basılı + 'en geç ~28 kare' pay; ölçülen: sürekli sag BAŞARISIZ, bırakma alt sınırı var, üst sınır yok: geri düşen raf üstüne iner)" % [str(vz), _n_ar(vz, okz)])
	hepsi = hepsi and _n_pen(vz, okz, 0, false) and _n_pen(vz, okz, 10)
	# --- W5: C_B başta bekleme -> C_C LazerB'ye varışı
	var vh: Array = []
	for d in range(0, 61, 2):
		vh.append(d)
	var okh: Array = await _n_sup(vh, func(v: int) -> bool:
		var b2: Array = (await _n_senaryo([c_a], _n16_b(v)))["kayit"]
		var s: Dictionary = await _n_senaryo([c_a, b2], _n16_c())
		return not s["tamam"].has(false) and s["oldu"] == 0)
	var w5 := _n_en_buyuk(vh, okh)
	ayr.append("W5 C_B başta bekleme (kare): C_C başarılı %s (en çok %d kare = %d px; taslak pay ~25)" % [_n_ar(vh, okh), w5, w5 * 5])
	hepsi = hepsi and _n_pen(vh, okh, 0) and w5 >= 2
	# --- W6: C_C başta bekleme -> oyuncu LazerC'ye varışı
	var vk: Array = []
	for d in range(0, 61, 2):
		vk.append(d)
	var okk: Array = await _n_sup(vk, func(v: int) -> bool:
		var c2: Array = (await _n_senaryo([c_a, c_b], _n16_c(v)))["kayit"]
		return await _n_bitirir([c_a, c_b, c2], _n16_o()))
	var w6 := _n_en_buyuk(vk, okk)
	ayr.append("W6 C_C başta bekleme (kare): oyuncu başarılı %s (en çok %d kare = %d px; taslak pay >= 8)" % [_n_ar(vk, okk), w6, w6 * 5])
	hepsi = hepsi and _n_pen(vk, okk, 0) and w6 >= 2
	# --- W8: kutu itme yeri (kutu_x hedefi): kutu Sehpa yüzüne ne kadar yakın olmalı
	var vb: Array = []
	for x in range(920, 961, 4):
		vb.append(x)
	var okb: Array = await _n_sup(vb, func(v: int) -> bool: return await _n_bitirir(kay, _n16_o(0, float(v))))
	ayr.append("W8 kutu itme hedefi (kutu merkez x>=v'de dur; Sehpa yüzü kutu 960): bitiren %s" % _n_ar(vb, okb))
	# --- zıplayış sayıları: Z1 uçuş tepesi (C_A kaydı)
	var sa: Dictionary = await _n_senaryo([], _n16_a())
	ayr.append("Z1 uçuş tepesi: ayak y=%.1f (taslak 353, F2 yüzeyi 380: pay %.1f px)" % [_n_olc(sa)["ayak"], 380.0 - _n_olc(sa)["ayak"]])
	_kaydi("Bölüm 16 zamanlama payları (W1 LazerA, W2 S konumu, W3 G, W4 Z2 sag, W5/W6 klon payları, W8 kutu)", hepsi, " || ".join(ayr))
	_kayitlar().sifirla()
	paused = false


func _test_b16_klon_fark() -> void:
	var kay: Array = await _n16_kayitlar()
	var ayr: Array = []
	var hepsi := true
	for k in [["C_A", [], _n16_a()], ["C_B", [kay[0]], _n16_b()], ["C_C", [kay[0], kay[1]], _n16_c()], ["Oyuncu", kay, _n16_o()]]:
		var r: Dictionary = await _n_klon_fark(k[1], k[2])
		ayr.append("%s canlı/klon en büyük konum farkı %.2f px (ilk sapma kare %d)" % [k[0], r["fark"], r["ilk"]])
		hepsi = hepsi and r["fark"] <= 0.5
	_kaydi("Bölüm 16 ölçüm: canlı kayıt vs klon tekrarı konum farkı (bant/dikiş yok, üst sınır 0,5 px)", hepsi, " || ".join(ayr))
	_kayitlar().sifirla()
	paused = false


func _test_b16_mandal() -> void:
	var ayr: Array = []
	var hepsi := true
	aktif_bolum = BOLUM_16
	var r: Dictionary = await _n_tutma_olc("MP", Vector2(450, 576), 330)
	ayr.append("MP: ilk basili kare=%d, son fiziksel kare=%d, sonra basılı kalan=%d kare (ölçüm sonuna kadar=%s)" % [r["ilk_basili"], r["son_fiziksel"], r["kalan"], str(r["sona_kadar"])])
	hepsi = hepsi and r["sona_kadar"] and r["kalan"] >= 300
	# G mandal sayesinde açık kalır: MP'den ayrıldıktan 300 kare sonra G hâlâ açık (y<=180+1).
	var son_g: float = r["ozel"][r["ozel"].size() - 1]["G"]
	ayr.append("MP'den ayrıldıktan ~%d kare sonra G y=%.0f (açık 180)" % [r["kalan"], son_g])
	hepsi = hepsi and son_g <= 181.0
	# Kutu da mandalı kilitler mi (kutu MP üstüne düşer)? Kutu cepe giremez (raf yürünür): ölçülür.
	_kayitlar().sifirla()
	var bolum: Node = await _bolumu_yukle()
	for i in range(30):
		_girdi_uygula({"yon": 0.0, "zipla": false})
		await physics_frame
	var kilitli0: bool = bolum.get_node("MP").kilitli
	var eski_id := bolum.get_instance_id()
	await _r_bas()
	var yeni: Node = await _yeni_sahne_bekle(eski_id)
	var ok_t: bool = yeni != null and yeni.get_node("MP").kilitli == false and yeni.get_node("MP").basili_mi() == false \
		and absf(yeni.get_node("G").position.y - 280.0) < 0.5
	hepsi = hepsi and ok_t and not kilitli0
	ayr.append("tur başı sıfırlama: ilk turda MP kilitli=%s; R sonrası yeni turda MP kilitli=%s, G y=%.0f (kapalı 280)" % [str(kilitli0), str(yeni.get_node("MP").kilitli if yeni != null else "?"), yeni.get_node("G").position.y if yeni != null else -1.0])
	# Tur sonuna kadar kalıcı: klon replay'inde de aynı (MP'ye basan C_B klonu sonrası C_B plakada değilken bile).
	_kaydi("Bölüm 16: mandal plaka kalıcı (tur sonuna kadar), tur başı sıfırlama", hepsi, " || ".join(ayr))
	_kayitlar().sifirla()
	paused = false


func _test_b16_klon_siniri() -> void:
	await _n_klon_siniri("Bölüm 16: klon sınırı (dördüncü R klon kaydetmez)", 3)


func _test_b16_kilitlenme() -> void:
	var kay: Array = await _n16_kayitlar()
	var ayr: Array = []
	var hepsi := true
	# (a) kutu sola itilirse bölüm bitmez (Sehpa basamağı kaybolur).
	var sk: Dictionary = await _n_senaryo(kay, [_b13_a(-1, _b4_x_le(760.0), 400), _b13_a(0, Callable(), 3), _b13_a(1, Callable(), 60),
		_b13_a(1, Callable(), 14, true), _b13_a(0, _n_zemin(), 80), _b13_a(1, Callable(), 14, true), _b13_a(1, _b4_bitti_k(), 100)],
		_n_yerlestir(Vector2(960, 356)))
	var kx: float = sk["ozel"][sk["ozel"].size() - 1]["Kutu"].x
	var ok: bool = not sk["bitti_ham"] and kx < 800.0
	hepsi = hepsi and ok
	ayr.append("kutu sola itilir: kutu x=%.0f, bölüm bitti=%s (kilitlenme: Baştan başla gerekir)" % [kx, str(sk["bitti_ham"])])
	# (b) Baştan başla: kutu başlangıç konumunda (920), klonlar silinir.
	_kayitlar().sifirla()
	_kayitlar().tur_kaydet(kay[0].duplicate(true))
	var b2: Node = await _bolumu_yukle()
	var eski: Node = current_scene
	b2.get_node("EkranButonlari/Kutu/YenidenDugmesi").pressed.emit()
	var yeni2: Node = await _sahne_degisimini_bekle(eski)
	var kutu_bas: Vector2 = yeni2.get_node("Kutu").global_position
	var ok_b: bool = _kayitlar().turlar.size() == 0 and _klonlar(yeni2).size() == 0 and yeni2.bilgi.text.begins_with("Tur 1 ") and absf(kutu_bas.x - 920.0) < 1.0
	hepsi = hepsi and ok_b
	ayr.append("Baştan başla: kayıt=%d, klon=%d, etiket=\"%s\", kutu x=%.0f" % [_kayitlar().turlar.size(), _klonlar(yeni2).size(), yeni2.bilgi.text, kutu_bas.x])
	# (c) cepte ölüm yok (cepte lazer yok); cepten çıkış yalnız Z2: cepte sola yürü, sağa yürü, kare/ölüm.
	var sc: Dictionary = await _n_senaryo([], [_b13_a(-1, Callable(), 30), _b13_a(1, Callable(), 40), _b13_a(0, Callable(), 100)], _n_yerlestir(Vector2(450, 576)))
	ok = sc["oldu"] == 0
	hepsi = hepsi and ok
	ayr.append("cepte yürüme: ölüm=%d, son (%.0f,%.0f); Z2 sensörü cepten tek çıkış (DuvarW/DuvarCep)" % [sc["oldu"], _n_son(sc).x, _n_son(sc).y])
	# (d) klonlar G altında bitmez: C_B ve C_C plakada.
	var tam: Dictionary = await _n_senaryo(kay, [_b13_a(0, Callable(), 330)])
	var ki: Array = tam["klon_izleri"]
	var sb: Vector2 = ki[1][ki[1].size() - 1]
	var sc2: Vector2 = ki[2][ki[2].size() - 1]
	var ok_d: bool = sb.x > 620.0 and sb.x < 720.0 and sc2.x > 750.0 and sc2.x < 850.0 and not tam["klon_oldu"][0] and not tam["klon_oldu"][1] and not tam["klon_oldu"][2]
	hepsi = hepsi and ok_d
	ayr.append("klonlar plakada biter: C_B (%.0f,%.0f), C_C (%.0f,%.0f); G x 590..610 altında değil" % [sb.x, sb.y, sc2.x, sc2.y])
	# (e) ölü klon yerinde donar: C_B kaydı C_A'sız oynatılır (LazerA'da ölür).
	var sd: Dictionary = await _n_senaryo([kay[1]], [_b13_a(0, Callable(), 250)])
	var kz: Array = sd["klon_izleri"][0]
	var donuk: bool = sd["klon_oldu"][0] and kz[kz.size() - 1] == kz[kz.size() - 40] and kz[kz.size() - 1].x < 345.0
	hepsi = hepsi and donuk
	ayr.append("ölü klon: öldü=%s, son (%.0f,%.0f), sabit=%s" % [str(sd["klon_oldu"][0]), kz[kz.size() - 1].x, kz[kz.size() - 1].y, str(donuk)])
	_kaydi("Bölüm 16 kilitlenme: kutu sola itme, Baştan başla, cep, klon konumları, ölü klon", hepsi, " || ".join(ayr))
	_kayitlar().sifirla()
	paused = false


func _test_b16_determinizm() -> void:
	var kay: Array = await _n16_kayitlar()
	await _n_determinizm("Bölüm 16: determinizm (100x çözüm)", kay, _n16_o())


# ##CHUNKS##
# ================================================================ Bölüm 18 (Vardiya)
# Taslak: docs/devir/bolum_18_taslak.md. C_A: zamanlı plakalı asansörle F2'ye çıkar, PlakaA'da kalır.
# C_B: aynı yol, PlakaB'de kalır. Oyuncu: aynı yol, rafta S, cepten sola, LazerB/LazerA2/kapı.
const BOLUM_18 := "res://scenes/bolumler/bolum_18.tscn"
var _n18_onb: Array = []   # [A, B]


## Ortak giriş: gec kare bekle, ZP'den geçip x>=birak_x'te `sag` bırak, asansör tepeye çıkana kadar bekle.
func _n18_yuk(gec := 0, birak_x := 230.0, tepe_bekle := 250, tepe_dur := 0) -> Array:
	var d: Array = []
	if gec > 0:
		d.append(_b13_a(0, Callable(), gec))
	d.append(_b13_a(1, _b4_x_ge(birak_x), 150))
	d.append(_b13_a(0, _n_gecit_ust("Asansor", 390.5), tepe_bekle))
	if tepe_dur > 0:
		d.append(_b13_a(0, Callable(), tepe_dur))
	return d


func _n18_a(gec := 0, bekle := 15, birak_x := 230.0, tepe_dur := 0) -> Array:
	return _n18_yuk(gec, birak_x, 250, tepe_dur) + [_b13_a(1, _n_plakada("PlakaA"), 200), _b13_a(0, Callable(), bekle)]


func _n18_b(gec := 0, bekle := 15, birak_x := 230.0, tepe_dur := 0) -> Array:
	return _n18_yuk(gec, birak_x, 250, tepe_dur) + [_b13_a(1, _n_plakada("PlakaB"), 300), _b13_a(0, Callable(), bekle)]


## Oyuncu: rafta s_x'te `sag` bırakır, S basar (sag_tut: S sırasında sag basılı), cepten sola kapıya.
func _n18_o(gec := 0, s_x := 780.0, sag_tut := false, birak_x := 230.0) -> Array:
	var d: Array = _n18_yuk(gec, birak_x) + [_b13_a(1, _b4_x_ge(s_x), 400)]
	if sag_tut:
		d += [_b13_a(1, Callable(), 3, false, true)]
	else:
		d += [_b13_a(0, Callable(), 1), _b13_a(0, Callable(), 3, false, true)]
	d += [_b13_a(0, _n_zemin(), 120), _b13_a(-1, _b4_bitti_k(), 300)]
	return d


func _n18_kayitlar() -> Array:
	if _n18_onb.is_empty():
		var s1: Dictionary = await _n_senaryo([], _n18_a())
		var s2: Dictionary = await _n_senaryo([s1["kayit"]], _n18_b())
		_n18_onb = [s1["kayit"], s2["kayit"]]
	return _n18_onb


func _n_ge_y(ad: String, y: float) -> Callable:
	return func(b: Node) -> bool: return b.get_node(ad).position.y >= y


## Klon i'nin son karedeki konumu.
func _n_klon_son(s: Dictionary, i: int) -> Vector2:
	var a: Array = s["klon_izleri"][i]
	return a[a.size() - 1]


func _b18_calistir() -> void:
	await _test_b18_cozum()
	await _test_b18_basarisizlik()
	await _test_b18_atlanamaz()
	await _test_b18_kisayol()
	await _test_b18_pencereler()
	await _test_b18_klon_fark()
	await _test_b18_tutma()
	await _test_b18_klon_siniri()
	await _test_b18_kilitlenme()
	await _test_b18_determinizm()


func _test_b18_cozum() -> void:
	await _n_cozum("Bölüm 18 çözümü (3 tur, 2 klon, gerçek R/girdi yolu; max_klon 2)", [_n18_a(), _n18_b()], _n18_o(), 2)


func _test_b18_basarisizlik() -> void:
	var kay: Array = await _n18_kayitlar()
	var c_a: Array = kay[0]
	# 1) klonsuz: LazerA'da ölür.
	var s1: Dictionary = await _n_senaryo([], _n18_o())
	var p1: Vector2 = _n_son(s1)
	_kaydi("Bölüm 18 başarısızlık 1: klonsuz -> LazerA'da ölür", s1["oldu"] > 0 and not s1["bitti_ham"],
		"ölüm=%d, son konum (%.0f,%.0f) (ışın x 467..473)" % [s1["oldu"], p1.x, p1.y])
	# 2) yalnız C_A: oyuncu cepte LazerB'de ölür.
	var s2: Dictionary = await _n_senaryo([c_a], _n18_o())
	var p2: Vector2 = _n_son(s2)
	_kaydi("Bölüm 18 başarısızlık 2: yalnız C_A -> cepte LazerB'de ölür", s2["oldu"] > 0 and not s2["bitti_ham"] and p2.x > 640.0 and p2.x < 700.0,
		"ölüm=%d, son konum (%.0f,%.0f) (ışın x 637..643)" % [s2["oldu"], p2.x, p2.y])
	# 3) C_A plakaya 60 kare geç basar -> C_B LazerA'da ölür.
	var a_gec: Array = (await _n_senaryo([], _n18_a(60)))["kayit"]
	var s3: Dictionary = await _n_senaryo([a_gec], _n18_b())
	_kaydi("Bölüm 18 başarısızlık 3: C_A 60 kare geç basar -> C_B LazerA'da ölür", s3["oldu"] > 0 and not s3["bitti_ham"],
		"ölüm=%d, son (%.0f,%.0f)" % [s3["oldu"], _n_son(s3).x, _n_son(s3).y])
	# 4) C_A plakaya değer değmez sola yürür -> LazerA açık; C_B ölür.
	var a_erken: Array = (await _n_senaryo([], _n18_yuk() + [_b13_a(1, _n_plakada("PlakaA"), 200), _b13_a(-1, _b4_x_le(330.0), 100), _b13_a(0, Callable(), 100)]))["kayit"]
	var s4: Dictionary = await _n_senaryo([a_erken], _n18_b())
	_kaydi("Bölüm 18 başarısızlık 4: C_A plakadan hemen ayrılır -> C_B LazerA'da ölür", s4["oldu"] > 0 and not s4["bitti_ham"],
		"ölüm=%d, son (%.0f,%.0f)" % [s4["oldu"], _n_son(s4).x, _n_son(s4).y])
	# 5) C_B PlakaB'den ayrılır -> oyuncu cepte LazerB'de ölür.
	var b_erken: Array = (await _n_senaryo([c_a], _n18_yuk() + [_b13_a(1, _n_plakada("PlakaB"), 300), _b13_a(-1, _b4_x_le(450.0), 100), _b13_a(0, Callable(), 150)]))["kayit"]
	var s5: Dictionary = await _n_senaryo([c_a, b_erken], _n18_o())
	_kaydi("Bölüm 18 başarısızlık 5: C_B PlakaB'den ayrılır -> oyuncu LazerB'de ölür", s5["oldu"] > 0 and not s5["bitti_ham"],
		"ölüm=%d, son (%.0f,%.0f)" % [s5["oldu"], _n_son(s5).x, _n_son(s5).y])
	# 6) asansörde `sag` bırakılmaz: tepeye yürünürken kenardan F1'e düşer, F2'ye çıkılmaz.
	var s6: Dictionary = await _n_senaryo([c_a], [_b13_a(1, Callable(), 400)])
	_kaydi("Bölüm 18 başarısızlık 6: asansörde `sag` bırakılmaz -> F2'ye çıkılmaz", not s6["bitti_ham"] and _n_olc(s6)["ymax"] > 500.0,
		"en büyük y=%.1f (F1 merkez 576), ölüm=%d, son (%.0f,%.0f)" % [_n_olc(s6)["ymax"], s6["oldu"], _n_son(s6).x, _n_son(s6).y])
	# 7) rafta çok erken S (x=700 < 720): DosemeA destekler, etkisiz.
	var s7: Dictionary = await _n_senaryo([c_a, kay[1]], _n18_yuk() + [_b13_a(1, _b4_x_ge(700.0), 400), _b13_a(0, Callable(), 1),
		_b13_a(0, Callable(), 3, false, true), _b13_a(0, Callable(), 60)])
	_kaydi("Bölüm 18 başarısızlık 7: raf başından çok önce S (x=700) -> düşmez", _n_son(s7).y < 370.0 and s7["oldu"] == 0,
		"son (%.1f,%.1f) (F2 yüzeyi 380 -> merkez 356)" % [_n_son(s7).x, _n_son(s7).y])
	# 8) rafta `sag` basılı S: sürüklenir, BlokR'ye yaslanır, yine cebe iner (taslak: zarar yok).
	var s8: Dictionary = await _n_senaryo(kay, _n18_o(0, 780.0, true))
	_kaydi("Bölüm 18 ölçüm 8: rafta `sag` basılı S -> cebe iner, yine biter (taslak §9.7)", s8["bitti_ham"] and s8["oldu"] == 0,
		"bitti=%s ölüm=%d en büyük x=%.0f" % [s8["bitti_ham"], s8["oldu"], _n_olc(s8)["xmax"]])
	# 9) ZP'ye basıp asansöre binmeden yürür: asansör boş çıkar ve geri iner; kilit yok.
	var s9: Dictionary = await _n_senaryo([], [_b13_a(1, _b4_x_ge(330.0), 150), _b13_a(0, _n_gecit_ust("Asansor", 390.5), 250),
		_b13_a(0, _n_ge_y("Asansor", 609.5), 450)])
	_kaydi("Bölüm 18 başarısızlık 9: ZP'ye basıp binmeden yürür -> asansör boş çıkar ve geri iner (kilit yok)", not s9["tamam"].has(false) and s9["oldu"] == 0,
		"adımlar=%s, toplam kare=%d" % [str(s9["tamam"]), s9["ozel"].size()])
	_kayitlar().sifirla()
	paused = false


func _test_b18_atlanamaz() -> void:
	var kay: Array = await _n18_kayitlar()
	var ayr: Array = []
	var hepsi := true
	for x in [180.0, 320.0, 100.0]:
		var sa: Dictionary = await _n_senaryo([], _n_spam(0.0, 8), _n_yerlestir(Vector2(x, 576)))
		var oa: Dictionary = _n_olc(sa)
		hepsi = hepsi and oa["ayak"] > 440.0
		ayr.append("F1 x=%.0f dikey zıplama: en yüksek ayak y=%.1f (F2 yüzeyi 380, 220 px > 100,9)" % [x, oa["ayak"]])
	var sd: Dictionary = await _n_senaryo([], _n_spam(1.0, 12), _n_yerlestir(Vector2(320, 576)))
	var od: Dictionary = _n_olc(sd)
	hepsi = hepsi and od["xmax"] <= 337.0
	ayr.append("DuvarWK sol alan: en büyük x=%.0f (sol yüz 350-14=336)" % od["xmax"])
	var sl: Dictionary = await _n_senaryo([], _n_spam(1.0, 10), _n_yerlestir(Vector2(420, 356)))
	hepsi = hepsi and sl["oldu"] > 0 and _n_olc(sl)["xmax"] < 480.0
	ayr.append("LazerA zıplayarak: ölüm=%d, en büyük x=%.0f (ışın 467..473)" % [sl["oldu"], _n_olc(sl)["xmax"]])
	var s2: Dictionary = await _n_senaryo([], _n_spam(-1.0, 10), _n_yerlestir(Vector2(600, 576)))
	hepsi = hepsi and s2["oldu"] > 0 and _n_olc(s2)["xmin"] > 530.0
	ayr.append("LazerA2 zıplayarak: ölüm=%d, en küçük x=%.0f (ışın 537..543)" % [s2["oldu"], _n_olc(s2)["xmin"]])
	var sb: Dictionary = await _n_senaryo([], _n_spam(-1.0, 10), _n_yerlestir(Vector2(760, 576)))
	hepsi = hepsi and sb["oldu"] > 0 and _n_olc(sb)["xmin"] > 625.0
	ayr.append("LazerB zıplayarak: ölüm=%d, en küçük x=%.0f (ışın 637..643)" % [sb["oldu"], _n_olc(sb)["xmin"]])
	var sc: Dictionary = await _n_senaryo(kay, _n_spam(0.0, 10), _n_yerlestir(Vector2(790, 576)))
	hepsi = hepsi and _n_olc(sc)["ayak"] > 450.0
	ayr.append("cepten dikey zıplama: en yüksek ayak y=%.1f (raf üstü 380)" % _n_olc(sc)["ayak"])
	var st: Dictionary = await _n_senaryo([], _n_spam(0.0, 6), _n_yerlestir(Vector2(500, 356)))
	hepsi = hepsi and _n_olc(st)["ayak"] - 48.0 >= 180.0
	ayr.append("F2 tavan: en yüksek baş y=%.1f (tavan alt kenarı 180)" % (_n_olc(st)["ayak"] - 48.0))
	var sk: Dictionary = await _n_senaryo([], _n_spam(1.0, 10), _n_yerlestir(Vector2(296, 576)))
	hepsi = hepsi and _n_olc(sk)["ayak"] > 440.0
	ayr.append("kuyu sağı sağ+zıpla: en yüksek ayak y=%.1f" % _n_olc(sk)["ayak"])
	_kaydi("Bölüm 18 atlanamazlık (kat boşluğu, DuvarWK, üç lazer zıplayarak, cep dönüşü, tavan)", hepsi, "; ".join(ayr))
	_kayitlar().sifirla()
	paused = false


func _test_b18_kisayol() -> void:
	var kay: Array = await _n18_kayitlar()
	var c_a: Array = kay[0]
	var c_b: Array = kay[1]
	var ayr: Array = []
	var hepsi := true
	var b0: Node = await _bolumu_yukle()
	var var_olan: String = _n_var_olanlar(b0, ["Kutu", "Bant", "Salter", "Gecit", "Z1", "Mandal", "Ziplatici"])
	paused = false
	hepsi = hepsi and var_olan == ""
	ayr.append("sahnede kutu/bant/şalter/geçit/zıplatıcı/mandal: [%s] (yok olmalı)" % var_olan)
	var oyuncu_st: Array = [_n18_o(), _n18_o(0, 735.0), _n18_o(0, 825.0), _n18_o(0, 780.0, true), [_b13_a(1, Callable(), 500)],
		_n18_yuk() + [_b13_a(1, Callable(), 400)], _n18_yuk() + [_b13_a(1, _b4_x_ge(700.0), 300), _b13_a(0, Callable(), 3, false, true),
		_b13_a(-1, Callable(), 300)]]
	var kb: Array = []
	for st in oyuncu_st:
		if await _n_bitirir([], st):
			kb.append(1)
	hepsi = hepsi and kb.is_empty()
	ayr.append("klonsuz x 7 strateji: bitiren=%d" % kb.size())
	var c_b_kor: Array = (await _n_senaryo([], _n18_b()))["kayit"]
	var z_klon: Array = (await _n_senaryo([], [_b13_a(1, _n_plakada("PlakaZ"), 100), _b13_a(0, Callable(), 300)]))["kayit"]
	var park: Array = (await _n_senaryo([], [_b13_a(1, _b4_x_ge(330.0), 150), _b13_a(0, Callable(), 500)]))["kayit"]
	var tek_ad: Array = ["C_A", "C_B(kör)", "ZP-bekleyen", "F1 park"]
	var tekler: Array = [c_a, c_b_kor, z_klon, park]
	var biten: Array = []
	for i in range(tekler.size()):
		for st in oyuncu_st:
			if await _n_bitirir([tekler[i]], st):
				biten.append(tek_ad[i])
	hepsi = hepsi and biten.is_empty()
	ayr.append("tek klon (4 rol x 7 strateji): bitiren=%s" % str(biten))
	var rbit: Array = []
	for t in [0, 20, 40, 80, 120, 160]:
		var r: Dictionary = await _n_senaryo([], _n18_yuk() + [_b13_a(1, _n_plakada("PlakaA"), 100), _b13_a(0, Callable(), t),
			_b13_a(1, _n_plakada("PlakaB"), 300), _b13_a(0, Callable(), 20)])
		for st in oyuncu_st:
			if await _n_bitirir([r["kayit"]], st):
				rbit.append(t)
	hepsi = hepsi and rbit.is_empty()
	ayr.append("röle (A'dan B'ye, T=0..160 x 7 strateji): bitiren=%s" % str(rbit))
	var iki: Array = [["A+A", [c_a, c_a]], ["B+B", [c_b, c_b]], ["A+B", [c_a, c_b]], ["B+A", [c_b, c_a]], ["A+ZP", [c_a, z_klon]],
		["Bkör+A", [c_b_kor, c_a]]]
	var biten2: Array = []
	for k in iki:
		if await _n_bitirir(k[1], _n18_o()):
			biten2.append(k[0])
	hepsi = hepsi and biten2 == ["A+B", "B+A"]
	ayr.append("iki klon kümeleri bitirenler=%s (yalnız A+B / B+A beklenir)" % str(biten2))
	var tam: Dictionary = await _n_senaryo(kay, _n18_o())
	var f_ab := -1
	for f in range(tam["ozel"].size()):
		var o: Dictionary = tam["ozel"][f]
		if o["PlakaA"] and o["PlakaB"] and f_ab < 0:
			f_ab = f
	var f_b := -1
	var f_a2 := -1
	var f_raf: int = _n_x_kare(tam["iz"], 734.0)
	for f in range(f_raf, tam["iz"].size()):
		if tam["iz"][f].y > 500.0 and tam["iz"][f].x <= 657.0 and f_b < 0:
			f_b = f
		if tam["iz"][f].y > 500.0 and tam["iz"][f].x <= 557.0 and f_a2 < 0:
			f_a2 = f
	var ok5: bool = tam["bitti_ham"] and f_ab >= 0 and f_b > f_ab and f_a2 > f_b
	hepsi = hepsi and ok5
	ayr.append("min klon 2: bitti=%s, A+B birlikte basılı ilk kare=%d, LazerB ışınına kare %d, LazerA2 kare %d (taslak ~309/~329)" % [tam["bitti_ham"], f_ab, f_b, f_a2])
	var inen: Array = []
	for x in range(310, 840, 20):
		var ss: Dictionary = await _n_senaryo([], [_b13_a(0, Callable(), 3, false, true), _b13_a(0, Callable(), 45)],
			_n_yerlestir(Vector2(float(x), 356)))
		if _n_son(ss).y > 430.0:
			inen.append(x)
	var inen_ok := true
	for x in inen:
		inen_ok = inen_ok and x >= 730
	hepsi = hepsi and inen_ok and inen.size() > 0
	ayr.append("S ile DosemeA/raf üstünden inenler (x 310..830, 20 px adım): %s (yalnız raf, x>=730 beklenir)" % str(inen))
	_kaydi("Bölüm 18 kısayol taraması (klonsuz, 1 klon, röle, park, ZP, iki klon, min klon 2, S inişleri)", hepsi, " || ".join(ayr))
	_kayitlar().sifirla()
	paused = false


func _test_b18_pencereler() -> void:
	var kay: Array = await _n18_kayitlar()
	var c_a: Array = kay[0]
	var ayr: Array = []
	var hepsi := true
	var tam: Dictionary = await _n_senaryo(kay, _n18_o())
	var zp_son := -1
	var f_tepe := -1
	var f_cik := -1
	for f in range(tam["ozel"].size()):
		if tam["ozel"][f]["PlakaZ_f"]:
			zp_son = f
		if f_tepe < 0 and tam["iz"][f].y <= 356.5:
			f_tepe = f
		if f_cik < 0 and tam["iz"][f].x >= 304.0 and tam["iz"][f].y <= 360.0:
			f_cik = f
	var fitil_pay: int = zp_son + 180 - f_cik
	ayr.append("ZP son fiziksel kare=%d, tepeye varış kare=%d, F2'ye çıkış (x>=304) kare=%d -> fitil payı %d kare (fitil sonu %d; taslak ~78)" % [zp_son, f_tepe, f_cik, fitil_pay, zp_son + 180])
	hepsi = hepsi and fitil_pay >= 30
	var vs: Array = []
	for x in range(166, 306, 4):
		vs.append(x)
	var ok1: Array = await _n_sup(vs, func(v: int) -> bool:
		var s: Dictionary = await _n_senaryo([], _n18_a(0, 10, float(v)))
		return not s["tamam"].has(false) and s["oldu"] == 0)
	var lo := _n_en_kucuk(vs, ok1)
	var hi := _n_en_buyuk(vs, ok1)
	ayr.append("W1 biniş `sag` bırakma x (4 px adım): başarılı %s -> %d..%d (~%d px; taslak 196..264 = 68 px; asansör x 170..290)" % [_n_ar(vs, ok1), lo, hi, hi - lo + 4])
	hepsi = hepsi and lo > 0 and hi - lo >= 40
	var vd: Array = []
	for d in range(0, 161, 8):
		vd.append(d)
	var okd: Array = await _n_sup(vd, func(v: int) -> bool:
		var s: Dictionary = await _n_senaryo([], _n18_yuk() + [_b13_a(0, Callable(), v), _b13_a(1, _n_plakada("PlakaA"), 200), _b13_a(0, Callable(), 10)])
		return not s["tamam"].has(false) and s["oldu"] == 0)
	ayr.append("W2 tepede duraksama (kare): başarılı %s (en çok %d)" % [_n_ar(vd, okd), _n_en_buyuk(vd, okd)])
	hepsi = hepsi and _n_pen(vd, okd, 0)
	var vg: Array = []
	for d in range(0, 61, 2):
		vg.append(d)
	var okg: Array = await _n_sup(vg, func(v: int) -> bool:
		var a2: Array = (await _n_senaryo([], _n18_a(0, 15, 230.0, v)))["kayit"]
		var s: Dictionary = await _n_senaryo([a2], _n18_b(0, 10))
		return not s["tamam"].has(false) and s["oldu"] == 0)
	var w3 := _n_en_buyuk(vg, okg)
	ayr.append("W3 C_A tepede bekleme (kare; asansör fitili 64 ile sınırlı): C_B başarılı %s (en çok %d kare = %d px; taslak pay ~23)" % [_n_ar(vg, okg), w3, w3 * 5])
	hepsi = hepsi and _n_pen(vg, okg, 0) and w3 >= 4
	var vh: Array = []
	for d in range(0, 201, 8):
		vh.append(d)
	var okh: Array = await _n_sup(vh, func(v: int) -> bool:
		var b2: Array = (await _n_senaryo([c_a], _n18_b(0, 10, 230.0, v)))["kayit"]
		return await _n_bitirir([c_a, b2], _n18_o()))
	var w5 := _n_en_buyuk(vh, okh)
	ayr.append("W5 C_B tepede bekleme (kare): oyuncu başarılı %s (en çok %d kare = %d px; taslak pay ~99)" % [_n_ar(vh, okh), w5, w5 * 5])
	hepsi = hepsi and _n_pen(vh, okh, 0) and w5 >= 16
	var vx: Array = []
	for x in range(700, 846, 3):
		vx.append(x)
	var okx: Array = await _n_sup(vx, func(v: int) -> bool: return await _n_bitirir(kay, _n18_o(0, float(v))))
	var xlo := _n_en_kucuk(vx, okx)
	var xhi := _n_en_buyuk(vx, okx)
	ayr.append("W4 raf S konumu (`sag` bırakma merkez x; 826 üstü BlokR duvarı = aynı): başarılı %s -> %d..%d (~%d px; taslak 734..826 = 92 px)" % [_n_ar(vx, okx), xlo, xhi, xhi - xlo + 3])
	hepsi = hepsi and xhi - xlo >= 30
	ayr.append("oyuncu turu %d kare (<=600, pay %d)" % [tam["kare"], 600 - tam["kare"]])
	hepsi = hepsi and tam["kare"] <= 600
	_kaydi("Bölüm 18 zamanlama payları (fitil, W1 biniş, W2 tepe, W3/W5 klon payları, W4 raf S)", hepsi, " || ".join(ayr))
	_kayitlar().sifirla()
	paused = false


func _test_b18_klon_fark() -> void:
	var kay: Array = await _n18_kayitlar()
	var ayr: Array = []
	var hepsi := true
	for k in [["C_A", [], _n18_a()], ["C_B", [kay[0]], _n18_b()], ["Oyuncu", kay, _n18_o()]]:
		var r: Dictionary = await _n_klon_fark(k[1], k[2])
		ayr.append("%s canlı/klon en büyük konum farkı %.2f px (ilk sapma kare %d)" % [k[0], r["fark"], r["ilk"]])
		hepsi = hepsi and r["fark"] <= 0.5
	_kaydi("Bölüm 18 ölçüm: canlı kayıt vs klon tekrarı konum farkı (üst sınır 0,5 px)", hepsi, " || ".join(ayr))
	_kayitlar().sifirla()
	paused = false


func _test_b18_tutma() -> void:
	var ayr: Array = []
	var hepsi := true
	aktif_bolum = BOLUM_18
	var r: Dictionary = await _n_tutma_olc("PlakaZ", Vector2(120, 576), 260)
	ayr.append("ZP: ilk basılı kare=%d, son fiziksel kare=%d, sonra basılı kalan=%d kare (beklenen tam 180)" % [r["ilk_basili"], r["son_fiziksel"], r["kalan"]])
	hepsi = hepsi and r["kalan"] == 180
	_kayitlar().sifirla()
	var bolum: Node = await _bolumu_yukle()
	for i in range(40):
		_girdi_uygula({"yon": 1.0, "zipla": false})
		await physics_frame
	_girdi_uygula({"yon": 0.0, "zipla": false})
	var onc: bool = bolum.get_node("PlakaZ").basili_mi()
	var eski_id := bolum.get_instance_id()
	await _r_bas()
	var yeni: Node = await _yeni_sahne_bekle(eski_id)
	var z_yeni: bool = yeni.get_node("PlakaZ").basili_mi()
	var a_y: float = yeni.get_node("Asansor").position.y
	var kalan: int = yeni.get_node("PlakaZ").kalan_kare
	ayr.append("tur başı sıfırlama: R öncesi ZP basılı=%s; yeni turda ZP basılı=%s, kalan_kare=%d, asansör y=%.0f (alt 610)" % [str(onc), str(z_yeni), kalan, a_y])
	hepsi = hepsi and z_yeni == false and kalan == 0 and absf(a_y - 610.0) < 0.5
	_kaydi("Bölüm 18: zamanlı plaka tam 180 kare, tur başı sıfırlama", hepsi, " || ".join(ayr))
	_kayitlar().sifirla()
	paused = false


func _test_b18_klon_siniri() -> void:
	await _n_klon_siniri("Bölüm 18: klon sınırı (üçüncü R klon kaydetmez)", 2)


func _test_b18_kilitlenme() -> void:
	var kay: Array = await _n18_kayitlar()
	var c_a: Array = kay[0]
	var ayr: Array = []
	var hepsi := true
	# (a) cepte ölüm: yalnız C_A varken cepten sola: LazerB öldürür, tur yeniden başlar, klon korunur.
	_kayitlar().sifirla()
	_kayitlar().tur_kaydet(c_a.duplicate(true))
	var bolum: Node = await _bolumu_yukle()
	bolum.get_node("Oyuncu").global_position = Vector2(760, 576)
	var sayac := [0]
	bolum.get_node("Oyuncu").oyuncu_oldu.connect(func() -> void: sayac[0] += 1)
	var eski_id := bolum.get_instance_id()
	await _n_kosullu(bolum, [_b13_a(-1, Callable(), 80)], sayac)
	var yeni: Node = await _yeni_sahne_bekle(eski_id)
	var etiket := ""
	var ok: bool = sayac[0] > 0 and yeni != null and _kayitlar().turlar.size() == 1
	if yeni != null:
		etiket = yeni.bilgi.text
		ok = ok and _klonlar(yeni).size() == 1 and etiket.contains("Tur 2") and etiket.contains("1/2")
	hepsi = hepsi and ok
	ayr.append("cepte ölüm: ölüm=%d, kayıtlı tur=%d, etiket=\"%s\"" % [sayac[0], _kayitlar().turlar.size(), etiket])
	# (b) asansöre geç binen: ZP'ye basıp binmeden ayrılır, asansör iner; geri dönüp biner, F2'ye çıkar.
	var sg: Dictionary = await _n_senaryo([], [_b13_a(1, _b4_x_ge(330.0), 150), _b13_a(0, _n_gecit_ust("Asansor", 390.5), 250),
		_b13_a(0, _n_ge_y("Asansor", 609.5), 450), _b13_a(-1, _b4_x_le(225.0), 100), _b13_a(0, _n_gecit_ust("Asansor", 390.5), 250),
		_b13_a(1, _b4_x_ge(320.0), 100), _b13_a(0, Callable(), 10)])
	var son: Vector2 = _n_son(sg)
	var ok_b: bool = not sg["tamam"].has(false) and sg["oldu"] == 0 and son.y < 370.0 and son.x >= 300.0
	hepsi = hepsi and ok_b
	ayr.append("geç binen: adımlar=%s, son (%.0f,%.0f), ölüm=%d (F2'ye çıkabildi)" % [str(sg["tamam"]), son.x, son.y, sg["oldu"]])
	# (c) cepten dönüş yok.
	var sk: Dictionary = await _n_senaryo([c_a], _n_spam(0.0, 12), _n_yerlestir(Vector2(790, 576)))
	var ok_c: bool = _n_olc(sk)["ayak"] > 450.0 and sk["oldu"] == 0
	hepsi = hepsi and ok_c
	ayr.append("cepte zıplama en yüksek ayak y=%.1f (F2 yüzeyi 380): F2'ye dönüş yok (çıkış: R/Baştan başla)" % _n_olc(sk)["ayak"])
	# (d) Baştan başla.
	_kayitlar().sifirla()
	_kayitlar().tur_kaydet(c_a.duplicate(true))
	var b2: Node = await _bolumu_yukle()
	var eski: Node = current_scene
	b2.get_node("EkranButonlari/Kutu/YenidenDugmesi").pressed.emit()
	var yeni2: Node = await _sahne_degisimini_bekle(eski)
	var ok_d: bool = _kayitlar().turlar.size() == 0 and _klonlar(yeni2).size() == 0 and yeni2.bilgi.text.begins_with("Tur 1 ")
	hepsi = hepsi and ok_d
	ayr.append("Baştan başla: kayıt=%d, klon=%d, etiket=\"%s\"" % [_kayitlar().turlar.size(), _klonlar(yeni2).size(), yeni2.bilgi.text])
	# (e) klonlar plakada biter ve ölmez.
	var tam: Dictionary = await _n_senaryo(kay, [_b13_a(0, Callable(), 320)])
	var sa: Vector2 = _n_klon_son(tam, 0)
	var sb: Vector2 = _n_klon_son(tam, 1)
	var ok_e: bool = sa.x > 335.0 and sa.x < 410.0 and sb.x > 555.0 and sb.x < 630.0 and not tam["klon_oldu"][0] and not tam["klon_oldu"][1]
	hepsi = hepsi and ok_e
	ayr.append("klonlar plakada biter: C_A (%.0f,%.0f), C_B (%.0f,%.0f)" % [sa.x, sa.y, sb.x, sb.y])
	_kaydi("Bölüm 18 kilitlenme: cepte ölüm, asansöre geç binen, cepten dönüş yok, Baştan başla, klon konumları", hepsi, " || ".join(ayr))
	_kayitlar().sifirla()
	paused = false


func _test_b18_determinizm() -> void:
	var kay: Array = await _n18_kayitlar()
	await _n_determinizm("Bölüm 18: determinizm (100x çözüm)", kay, _n18_o())


# ================================================================ Bölüm 19 (Karşı Ağırlık) — ARŞİVLENDİ
# Bölüm 19 (Karşı Ağırlık) kullanıcı kararıyla oyundan kaldırıldı (eski Bölüm 20, yeni Bölüm 19 "Büyük Saat" ile çok benziyordu); sahnesi
# scenes/bolumler/arsiv/bolum_19_arsiv.tscn altında, testleri kaldırıldı. Eski 20/21/22 -> yeni 19/20/21 (docs/devir/numara_esleme.md).


# ================================================================ Bölüm 19 (Büyük Saat)
# Taslak: docs/devir/bolum_19_taslak.md. C_A: Z1 ile F2, PlakaA'da kalır. C_H: Z1, LazerA, PlakaL'de ~150 kare durur
# (asansör yukarıda), sonra PlakaX'e geçer (DEVİR) ve orada kalır. C_B: Z1, LazerA, asansöre biner, F3, bant, G, rafta S,
# odada PlakaB'de kalır. Oyuncu: C_B yolu, LazerB, şalter "geri bas", LazerS, kapı.
const BOLUM_19 := "res://scenes/bolumler/bolum_19.tscn"
var _n19_onb: Array = []   # [A, H, B]


## Z1 uçuşu: gec kare bekle, Z1 sensörüne (x>=z_x) girince `sag` z_kes kare bırak, F2'ye çıkana kadar (y<=360) sağa.
func _n19_f2(gec := 0, z_kes := 0) -> Array:
	var d: Array = []
	if gec > 0:
		d.append(_b13_a(0, Callable(), gec))
	d.append(_b13_a(1, _b4_x_ge(125.0), 200))
	if z_kes > 0:
		d.append(_b13_a(0, Callable(), z_kes))
	d.append(_b13_a(1, _n_y_le(360.0), 200))
	return d


func _n19_a(gec := 0, bekle := 15, z_kes := 0) -> Array:
	return _n19_f2(gec, z_kes) + [_b13_a(1, _n_plakada("PlakaA"), 200), _b13_a(0, Callable(), bekle)]


## C_H: PlakaL'de l_dur kare durur, sonra PlakaX'e geçer ve orada kalır.
func _n19_h(gec := 0, l_dur := 150, bekle := 15, z_kes := 0) -> Array:
	return _n19_f2(gec, z_kes) + [_b13_a(1, _n_plakada("PlakaL"), 300), _b13_a(0, Callable(), l_dur),
		_b13_a(1, _n_plakada("PlakaX"), 100), _b13_a(0, Callable(), bekle)]


## C_B / oyuncu ortak yolu: asansöre biner (bin_x'te `sag` bırakır), tepede çıkar, bantı/G'yi geçer, rafta s_x'te S.
func _n19_yol(gec := 0, bin_x := 470.0, s_x := 870.0, sag_tut := false, tepe_dur := 0, z_kes := 0) -> Array:
	var d: Array = _n19_f2(gec, z_kes)
	d.append(_b13_a(1, _b4_x_ge(bin_x), 300))
	d.append(_b13_a(0, _n_gecit_ust("Asansor", 170.5), 400))
	if tepe_dur > 0:
		d.append(_b13_a(0, Callable(), tepe_dur))
	d.append(_b13_a(1, _b4_x_ge(s_x), 500))
	if sag_tut:
		d.append(_b13_a(1, Callable(), 3, false, true))
	else:
		d += [_b13_a(0, Callable(), 1), _b13_a(0, Callable(), 3, false, true)]
	d.append(_b13_a(0, _n_zemin(), 120))
	return d


func _n19_b(gec := 0, bekle := 15, bin_x := 470.0, s_x := 870.0, tepe_dur := 0) -> Array:
	return _n19_yol(gec, bin_x, s_x, false, tepe_dur) + [_b13_a(1, _n_plakada("PlakaB"), 100), _b13_a(0, Callable(), bekle)]


## Oyuncu: odada LazerB'yi geçer, sol_x'te `sol` bir kare (şalter geri bas), sonra kapıya.
func _n19_o(gec := 0, bin_x := 470.0, s_x := 870.0, sag_tut := false, sol_x := 1030.0, geri_bas := true, tepe_dur := 0) -> Array:
	var d: Array = _n19_yol(gec, bin_x, s_x, sag_tut, tepe_dur)
	if geri_bas:
		d += [_b13_a(1, _b4_x_ge(sol_x), 300), _b13_a(-1, Callable(), 1)]
	d.append(_b13_a(1, _b4_bitti_k(), 300))
	return d


func _n19_kayitlar() -> Array:
	if _n19_onb.is_empty():
		var s1: Dictionary = await _n_senaryo([], _n19_a())
		var s2: Dictionary = await _n_senaryo([s1["kayit"]], _n19_h())
		var s3: Dictionary = await _n_senaryo([s1["kayit"], s2["kayit"]], _n19_b())
		_n19_onb = [s1["kayit"], s2["kayit"], s3["kayit"]]
	return _n19_onb


func _b19_calistir() -> void:
	await _test_b19_cozum()
	await _test_b19_basarisizlik()
	await _test_b19_atlanamaz()
	await _test_b19_kisayol()
	await _test_b19_pencereler()
	await _test_b19_klon_fark()
	await _test_b19_tutma()
	await _test_b19_klon_siniri()
	await _test_b19_kilitlenme()
	await _test_b19_determinizm()


func _test_b19_cozum() -> void:
	await _n_cozum("Bölüm 19 çözümü (4 tur, 3 klon, gerçek R/girdi yolu)", [_n19_a(), _n19_h(), _n19_b()], _n19_o(), 3)


func _test_b19_basarisizlik() -> void:
	var kay: Array = await _n19_kayitlar()
	var c_a: Array = kay[0]
	var c_h: Array = kay[1]
	var c_b: Array = kay[2]
	# 1) klonsuz: LazerA'da ölür.
	var s1: Dictionary = await _n_senaryo([], _n19_o())
	_kaydi("Bölüm 19 başarısızlık 1: klonsuz -> LazerA'da ölür", s1["oldu"] > 0 and not s1["bitti_ham"] and _n_son(s1).x > 300.0 and _n_son(s1).x < 345.0,
		"ölüm=%d, son (%.0f,%.0f) (ışın 337..343)" % [s1["oldu"], _n_son(s1).x, _n_son(s1).y])
	# 2) yalnız C_A: asansör kalkmaz, oyuncu çıkamaz.
	var s2: Dictionary = await _n_senaryo([c_a], _n19_o())
	_kaydi("Bölüm 19 başarısızlık 2: yalnız C_A -> asansör yükselmez, oyuncu F3'e çıkamaz", not s2["bitti_ham"] and s2["tamam"].has(false) and s2["oldu"] == 0,
		"adımlar=%s, ölüm=%d, son (%.0f,%.0f)" % [str(s2["tamam"]), s2["oldu"], _n_son(s2).x, _n_son(s2).y])
	# 3) C_A + C_H, C_B yok: oyuncu odada LazerB'de ölür.
	var s3: Dictionary = await _n_senaryo([c_a, c_h], _n19_o())
	_kaydi("Bölüm 19 başarısızlık 3: C_B yok -> oyuncu odada LazerB'de ölür", s3["oldu"] > 0 and not s3["bitti_ham"] and _n_son(s3).x > 900.0 and _n_son(s3).x < 945.0,
		"ölüm=%d, son (%.0f,%.0f) (ışın 942..948)" % [s3["oldu"], _n_son(s3).x, _n_son(s3).y])
	# 4) C_H devir yapmaz (PlakaL'de kalır): G kapalı, binenler G'de takılır.
	var h_devirsiz: Array = (await _n_senaryo([c_a], _n19_f2() + [_b13_a(1, _n_plakada("PlakaL"), 300), _b13_a(0, Callable(), 400)]))["kayit"]
	var s4: Dictionary = await _n_senaryo([c_a, h_devirsiz, c_b], _n19_o())
	_kaydi("Bölüm 19 başarısızlık 4: C_H devir yapmaz -> G kapalı kalır, oyuncu G'de takılır, bölüm bitmez", not s4["bitti_ham"] and s4["oldu"] == 0 and _n_olc(s4)["xmax"] < 770.0,
		"adımlar=%s, ölüm=%d, en büyük x=%.0f (G sol yüz 780-14=766)" % [str(s4["tamam"]), s4["oldu"], _n_olc(s4)["xmax"]])
	# 5) C_H PlakaL'den erken (60 kare sonra) devreder: asansör iner, binenler çıkamaz.
	var h_erken: Array = (await _n_senaryo([c_a], _n19_h(0, 60)))["kayit"]
	var s5: Dictionary = await _n_senaryo([c_a, h_erken, c_b], _n19_o())
	_kaydi("Bölüm 19 başarısızlık 5: C_H 60 kare sonra devreder -> asansör iner, oyuncu F3'e çıkamaz", not s5["bitti_ham"] and s5["oldu"] == 0,
		"adımlar=%s, ölüm=%d, son (%.0f,%.0f)" % [str(s5["tamam"]), s5["oldu"], _n_son(s5).x, _n_son(s5).y])
	# 6) asansöre geç biniş (40 kare bekleme): çıkış yok.
	var s6: Dictionary = await _n_senaryo(kay, _n19_o(40))
	_kaydi("Bölüm 19 başarısızlık 6: asansöre geç biniş (başlangıçta 40 kare bekleme) -> asansör yukarıda, oyuncu çıkamaz", not s6["bitti_ham"] and s6["oldu"] == 0,
		"adımlar=%s, ölüm=%d, son (%.0f,%.0f)" % [str(s6["tamam"]), s6["oldu"], _n_son(s6).x, _n_son(s6).y])
	# 7) rafta erken S (x=800 < 810): DosemeF3b destekler.
	var s7: Dictionary = await _n_senaryo(kay, _n19_yol(0, 470.0, 800.0) + [_b13_a(0, Callable(), 40)])
	_kaydi("Bölüm 19 başarısızlık 7: raf başından önce S (x=800) -> düşmez", _n_son(s7).y < 180.0 and s7["oldu"] == 0,
		"son (%.1f,%.1f) (F3 yüzeyi 160 -> merkez 136)" % [_n_son(s7).x, _n_son(s7).y])
	# 8) rafta `sag` basılı S: sürüklenme, BlokF3R'ye yaslanır, yine iner ve biter.
	var s8: Dictionary = await _n_senaryo(kay, _n19_o(0, 470.0, 870.0, true))
	_kaydi("Bölüm 19 ölçüm 8: rafta `sag` basılı S -> iner, yine biter (taslak §9.7)", s8["bitti_ham"] and s8["oldu"] == 0,
		"bitti=%s ölüm=%d" % [s8["bitti_ham"], s8["oldu"]])
	# 9) C_B 60 kare gecikir: oyuncu odaya önce iner -> LazerB'de ölür.
	var b_gec: Array = (await _n_senaryo([c_a, c_h], _n19_b(0, 15, 470.0, 870.0, 60)))["kayit"]
	var s9: Dictionary = await _n_senaryo([c_a, c_h, b_gec], _n19_o())
	_kaydi("Bölüm 19 başarısızlık 9: C_B 60 kare gecikir -> oyuncu LazerB'de ölür", s9["oldu"] > 0 and not s9["bitti_ham"],
		"ölüm=%d, son (%.0f,%.0f)" % [s9["oldu"], _n_son(s9).x, _n_son(s9).y])
	# 10) şalter geri bas yok: LazerS öldürücü kalır.
	var s10: Dictionary = await _n_senaryo(kay, _n19_o(0, 470.0, 870.0, false, 1030.0, false))
	_kaydi("Bölüm 19 başarısızlık 10: şalter geri basılmaz -> LazerS'de ölür", s10["oldu"] > 0 and not s10["bitti_ham"] and _n_son(s10).x > 1040.0,
		"ölüm=%d, son (%.0f,%.0f) (ışın 1072..1078)" % [s10["oldu"], _n_son(s10).x, _n_son(s10).y])
	# 11) şalter geri bas çok erken (SolAlan içinde): şalter geri sağa döner -> ölür.
	var s11: Dictionary = await _n_senaryo(kay, _n19_o(0, 470.0, 870.0, false, 1005.0, true))
	_kaydi("Bölüm 19 başarısızlık 11: şalter erken geri basılır (x=1005) -> tekrar sağa döner, LazerS'de ölür", s11["oldu"] > 0 and not s11["bitti_ham"],
		"ölüm=%d, son (%.0f,%.0f)" % [s11["oldu"], _n_son(s11).x, _n_son(s11).y])
	# 12) Z1 uçuşunda `sag` uzun bırakılır: F2'ye çıkış/plaka alınamaz (ölçüm).
	var s12: Dictionary = await _n_senaryo([], _n19_a(0, 15, 40))
	_kaydi("Bölüm 19 başarısızlık 12: Z1 uçuşunda `sag` 40 kare bırakılır -> C_A plakaya varamaz (ölçüm)", s12["tamam"].has(false) or s12["oldu"] > 0 or s12["kare"] > 600,
		"adımlar=%s, ölüm=%d, kare=%d, son (%.0f,%.0f)" % [str(s12["tamam"]), s12["oldu"], s12["kare"], _n_son(s12).x, _n_son(s12).y])
	_kayitlar().sifirla()
	paused = false


func _test_b19_atlanamaz() -> void:
	var kay: Array = await _n19_kayitlar()
	var ayr: Array = []
	var hepsi := true
	for x in [90.0, 320.0]:
		var sa: Dictionary = await _n_senaryo([], _n_spam(0.0, 8), _n_yerlestir(Vector2(x, 576)))
		hepsi = hepsi and _n_olc(sa)["ayak"] > 440.0
		ayr.append("F1 x=%.0f dikey zıplama: en yüksek ayak y=%.1f (F2 yüzeyi 380)" % [x, _n_olc(sa)["ayak"]])
	# klonsuz sağ+zıpla spam (Z1 dahil): LazerA'yı aşamaz.
	var sz: Dictionary = await _n_senaryo([], _n19_f2() + _n_spam(1.0, 16))
	hepsi = hepsi and sz["oldu"] > 0 and not sz["bitti_ham"] and _n_olc(sz)["xmax"] < 350.0 and _n_olc(sz)["ayak"] > 300.0
	ayr.append("klonsuz Z1 uçuşu + sağ+zıpla spam: ölüm=%d, en büyük x=%.0f, tepe ayak y=%.1f (Z1 tepe 247 -> ayak 353)" % [sz["oldu"], _n_olc(sz)["xmax"], _n_olc(sz)["ayak"]])
	# F2 -> F3: asansör aşağıdayken zıplayarak F3'e çıkılmaz.
	var sf: Dictionary = await _n_senaryo([], _n_spam(0.0, 8), _n_yerlestir(Vector2(470, 356)))
	hepsi = hepsi and _n_olc(sf)["ayak"] > 270.0
	ayr.append("asansör üstünde dikey zıplama: en yüksek ayak y=%.1f (F3 yüzeyi 160)" % _n_olc(sf)["ayak"])
	# F2 sağ ucu / DuvarW2.
	var sw: Dictionary = await _n_senaryo([], _n_spam(1.0, 12), _n_yerlestir(Vector2(700, 356)))
	hepsi = hepsi and _n_olc(sw)["xmax"] <= 707.0
	ayr.append("DuvarW2 (F2 sağ ucu): en büyük x=%.0f (sol yüz 720-14=706)" % _n_olc(sw)["xmax"])
	# GecitG kapalı: F3'te DosemeF3b üstünde sağ+zıpla (sol yüz 780 -> gövde 766).
	var sg: Dictionary = await _n_senaryo([], _n_spam(1.0, 12), _n_yerlestir(Vector2(745, 136)))
	hepsi = hepsi and _n_olc(sg)["xmax"] <= 767.0 and not sg["bitti_ham"]
	ayr.append("GecitG kapalı (F3b): en büyük x=%.0f (766), tavan baş y=%.1f" % [_n_olc(sg)["xmax"], _n_olc(sg)["ayak"] - 48.0])
	hepsi = hepsi and _n_olc(sg)["ayak"] - 48.0 >= 0.0
	# LazerB zıplayarak (odada, PlakaB'nin sağında).
	var sb: Dictionary = await _n_senaryo([], _n_spam(1.0, 10), _n_yerlestir(Vector2(925, 356)))
	hepsi = hepsi and sb["oldu"] > 0 and _n_olc(sb)["xmax"] < 960.0
	ayr.append("LazerB zıplayarak: ölüm=%d, en büyük x=%.0f (ışın 942..948)" % [sb["oldu"], _n_olc(sb)["xmax"]])
	# LazerS zıplayarak (şalter sağda).
	var ss: Dictionary = await _n_senaryo([], _n_spam(1.0, 10), _n_yerlestir(Vector2(1045, 356)))
	hepsi = hepsi and ss["oldu"] > 0 and _n_olc(ss)["xmax"] < 1085.0
	ayr.append("LazerS zıplayarak (şalter sağda): ölüm=%d, en büyük x=%.0f (ışın 1072..1078)" % [ss["oldu"], _n_olc(ss)["xmax"]])
	# Odadan F3'e dönüş yok.
	var so: Dictionary = await _n_senaryo(kay, _n_spam(0.0, 10), _n_yerlestir(Vector2(1050, 356)))
	hepsi = hepsi and _n_olc(so)["ayak"] > 270.0
	ayr.append("odadan dikey zıplama (x=1050): en yüksek ayak y=%.1f" % _n_olc(so)["ayak"])
	# F2 tavan (200..380).
	var st: Dictionary = await _n_senaryo([], _n_spam(0.0, 6), _n_yerlestir(Vector2(250, 356)))
	hepsi = hepsi and _n_olc(st)["ayak"] - 48.0 >= 200.0
	ayr.append("F2 tavan: en yüksek baş y=%.1f (alt kenar 200)" % (_n_olc(st)["ayak"] - 48.0))
	# BlokF1 (F1 sağ ucu).
	var sd: Dictionary = await _n_senaryo([], _n_spam(1.0, 12), _n_yerlestir(Vector2(330, 576)))
	hepsi = hepsi and _n_olc(sd)["xmax"] <= 387.0
	ayr.append("BlokF1 (F1 sağ ucu): en büyük x=%.0f (sol yüz 400-14=386)" % _n_olc(sd)["xmax"])
	_kaydi("Bölüm 19 atlanamazlık (kat boşluğu, Z1 uçuşu, asansör, G, 3 lazer, DuvarW2, oda dönüşü, tavan)", hepsi, "; ".join(ayr))
	_kayitlar().sifirla()
	paused = false


func _test_b19_kisayol() -> void:
	var kay: Array = await _n19_kayitlar()
	var c_a: Array = kay[0]
	var c_h: Array = kay[1]
	var c_b: Array = kay[2]
	var ayr: Array = []
	var hepsi := true
	var b0: Node = await _bolumu_yukle()
	var var_olan: String = _n_var_olanlar(b0, ["Kutu", "Mandal", "PlakaZ", "Zamanli"])
	paused = false
	hepsi = hepsi and var_olan == ""
	ayr.append("sahnede kutu/zamanlı/mandal plaka: [%s] (yok olmalı)" % var_olan)
	var oyuncu_st: Array = [_n19_o(), _n19_o(0, 440.0), _n19_o(0, 500.0), _n19_o(0, 470.0, 830.0), _n19_o(0, 470.0, 910.0, true),
		_n19_o(0, 470.0, 870.0, false, 1030.0, false), [_b13_a(1, Callable(), 600)],
		_n19_f2() + [_b13_a(1, _n_plakada("PlakaL"), 300), _b13_a(0, Callable(), 300)],
		_n19_f2() + [_b13_a(1, Callable(), 500)]]
	var kb: Array = []
	for st in oyuncu_st:
		if await _n_bitirir([], st):
			kb.append(1)
	hepsi = hepsi and kb.is_empty()
	ayr.append("klonsuz x %d strateji: bitiren=%d" % [oyuncu_st.size(), kb.size()])
	var c_b_kor: Array = (await _n_senaryo([], _n19_b()))["kayit"]
	var c_h_kor: Array = (await _n_senaryo([], _n19_h()))["kayit"]
	var z_klon: Array = (await _n_senaryo([], [_b13_a(1, _b4_x_ge(140.0), 100), _b13_a(0, Callable(), 400)]))["kayit"]
	var park: Array = (await _n_senaryo([], [_b13_a(1, _b4_x_ge(330.0), 150), _b13_a(0, Callable(), 500)]))["kayit"]
	var tek_ad: Array = ["C_A", "C_H(kör)", "C_B(kör)", "Z1-bekleyen", "F1 park"]
	var tekler: Array = [c_a, c_h_kor, c_b_kor, z_klon, park]
	var biten: Array = []
	for i in range(tekler.size()):
		for st in oyuncu_st:
			if await _n_bitirir([tekler[i]], st):
				biten.append(tek_ad[i])
	hepsi = hepsi and biten.is_empty()
	ayr.append("tek klon (5 rol x %d strateji): bitiren=%s" % [oyuncu_st.size(), str(biten)])
	# geçit altı park / asansör altı çukur park klonları ve H erken devir.
	var g_park: Array = (await _n_senaryo([c_a, c_h], _n19_yol(0, 470.0, 740.0) + [_b13_a(1, _b4_x_ge(770.0), 100), _b13_a(0, Callable(), 500)]))["kayit"]
	var h_kisa: Array = (await _n_senaryo([c_a], _n19_h(0, 60)))["kayit"]
	var cukur: Array = (await _n_senaryo([c_a, c_h], _n19_f2(0) + [_b13_a(1, _b4_x_ge(430.0), 200), _b13_a(0, Callable(), 500)]))["kayit"]
	var havuz: Array = [["A", c_a], ["H", c_h], ["B", c_b], ["Z", z_klon], ["P", park], ["Hk", c_h_kor], ["Bk", c_b_kor], ["G", g_park],
		["Hs", h_kisa], ["Cukur", cukur]]
	var biten2: Array = []
	var n2 := 0
	for i in range(havuz.size()):
		for j in range(havuz.size()):
			n2 += 1
			for st in [_n19_o(), _n19_o(0, 470.0, 870.0, false, 1030.0, false)]:
				if await _n_bitirir([havuz[i][1], havuz[j][1]], st):
					biten2.append(havuz[i][0] + "+" + havuz[j][0])
	hepsi = hepsi and biten2.is_empty()
	ayr.append("iki klon (%d sıralı çift x 2 strateji): bitiren=%s" % [n2, str(biten2)])
	# röle (A -> L -> X tek klon), 1-2 klon kümeleri.
	var rbit: Array = []
	for t in [0, 20, 40, 80, 120]:
		var r: Dictionary = await _n_senaryo([], _n19_f2() + [_b13_a(1, _n_plakada("PlakaA"), 100), _b13_a(0, Callable(), t),
			_b13_a(1, _n_plakada("PlakaL"), 300), _b13_a(0, Callable(), 150), _b13_a(1, _n_plakada("PlakaX"), 100), _b13_a(0, Callable(), 20)])
		var rk: Array = r["kayit"]
		for kume in [[rk], [rk, c_b_kor], [rk, c_b], [rk, c_a]]:
			if await _n_bitirir(kume, _n19_o()):
				rbit.append("T%d/%d" % [t, kume.size()])
	hepsi = hepsi and rbit.is_empty()
	ayr.append("röle (A->L->X tek klon, T=0..120; 1-2 klon kümeleri): bitiren=%s" % str(rbit))
	var tbit: Array = []
	for kume in [[c_a, c_h, g_park], [c_a, c_h, cukur], [c_a, h_kisa, cukur], [c_a, c_h, park], [c_a, c_h, z_klon], [c_a, h_kisa, c_b]]:
		if await _n_bitirir(kume, _n19_o()):
			tbit.append(kume.size())
	hepsi = hepsi and tbit.is_empty()
	ayr.append("3 klon ama B rolü yok / H erken (G park, çukur park, F1 park, Z1 park): bitiren=%s" % str(tbit))
	# min klon 3 kanıtı ve plaka aralıkları.
	var tam: Dictionary = await _n_senaryo(kay, _n19_o())
	var aralik := {}
	for ad in ["PlakaA", "PlakaL", "PlakaX", "PlakaB"]:
		var f0 := -1
		var f1 := -1
		for f in range(tam["ozel"].size()):
			if tam["ozel"][f][ad]:
				if f0 < 0:
					f0 = f
				f1 = f
		aralik[ad] = Vector2i(f0, f1)
	var f_la: int = _n_x_kare(tam["iz"], 323.0)
	var f_lb: int = _n_x_kare(tam["iz"], 928.0, f_la)
	var f_ls: int = _n_x_kare(tam["iz"], 1058.0, f_la)
	var ok5: bool = tam["bitti_ham"] and aralik["PlakaA"].x >= 0 and aralik["PlakaA"].x < f_la and aralik["PlakaB"].x >= 0 and aralik["PlakaB"].x < f_lb
	ok5 = ok5 and aralik["PlakaX"].x >= aralik["PlakaL"].x and aralik["PlakaX"].x <= aralik["PlakaL"].y + 1
	hepsi = hepsi and ok5
	ayr.append("min klon 3: bitti=%s, A %s (LazerA kare %d), L %s, X %s (devir: X başlangıcı L bitişinden <=1 kare sonra), B %s (LazerB kare %d), LazerS kare %d" % [
		tam["bitti_ham"], str(aralik["PlakaA"]), f_la, str(aralik["PlakaL"]), str(aralik["PlakaX"]), str(aralik["PlakaB"]), f_lb, f_ls])
	# S inişleri: F2 üstü (x 210..710) ve F3 (x 540..930).
	var inen2: Array = []
	for x in range(210, 711, 20):
		var s2: Dictionary = await _n_senaryo([], [_b13_a(0, Callable(), 3, false, true), _b13_a(0, Callable(), 45)], _n_yerlestir(Vector2(float(x), 356)))
		if _n_son(s2).y > 430.0:
			inen2.append(x)
	var inen3: Array = []
	for x in range(540, 931, 20):
		var s3: Dictionary = await _n_senaryo([], [_b13_a(0, Callable(), 3, false, true), _b13_a(0, Callable(), 45)], _n_yerlestir(Vector2(float(x), 136)))
		if _n_son(s3).y > 250.0:
			inen3.append(x)
	var inen_ok := inen3.size() > 0
	for x in inen3:
		inen_ok = inen_ok and x >= 810
	inen_ok = inen_ok and inen2.is_empty()
	hepsi = hepsi and inen_ok
	ayr.append("S inişleri: F2 üstü (x 210..710, 20 px) = %s (boş beklenir: asansör aşağıdayken katı), F3 (x 540..930) = %s (yalnız raf x>=810)" % [str(inen2), str(inen3)])
	_kaydi("Bölüm 19 kısayol taraması (klonsuz, 1/2/3 klon, röle, geçit/çukur park, Z1/F1 park, min klon 3, şalter, S inişleri)", hepsi, " || ".join(ayr))
	_kayitlar().sifirla()
	paused = false


func _test_b19_pencereler() -> void:
	var kay: Array = await _n19_kayitlar()
	var c_a: Array = kay[0]
	var c_h: Array = kay[1]
	var ayr: Array = []
	var hepsi := true
	var tam: Dictionary = await _n_senaryo(kay, _n19_o())
	var f_l := -1
	var f_x := -1
	var f_tepe := -1
	var f_bin := -1
	var f_in := -1
	var f_g := -1
	for f in range(tam["ozel"].size()):
		var o: Dictionary = tam["ozel"][f]
		if f_l < 0 and o["PlakaL"]:
			f_l = f
		if f_x < 0 and o["PlakaX"]:
			f_x = f
		if f_g < 0 and o["GecitG"] <= 12.0:
			f_g = f
		if f_bin < 0 and tam["iz"][f].x >= 456.0 and tam["iz"][f].y <= 360.0:
			f_bin = f
		if f_tepe < 0 and tam["iz"][f].y <= 136.5 and tam["iz"][f].x > 400.0:
			f_tepe = f
		if f_in < 0 and tam["iz"][f].x >= 766.0 and tam["iz"][f].y < 140.0:
			f_in = f
	ayr.append("oyuncu asansörde kare=%d, L basış kare=%d, F3'e varış kare=%d, X ilk basış kare=%d, G açıklık>=48 kare=%d, oyuncu G önüne (x>=766) kare=%d (bekleme %d)" % [
		f_bin, f_l, f_tepe, f_x, f_g, f_in, f_g - f_in])
	hepsi = hepsi and f_l >= 0 and f_x > f_l and f_g > f_x and f_in >= 0
	# Z1: uçuşta `sag` bırakma süresi (C_A için).
	var vz: Array = []
	for d in range(0, 61, 2):
		vz.append(d)
	var okz: Array = await _n_sup(vz, func(v: int) -> bool:
		var s: Dictionary = await _n_senaryo([], _n19_a(0, 10, v))
		return not s["tamam"].has(false) and s["oldu"] == 0)
	ayr.append("W-Z1 uçuşta `sag` bırakma (kare): C_A başarılı %s (en çok %d)" % [_n_ar(vz, okz), _n_en_buyuk(vz, okz)])
	hepsi = hepsi and _n_pen(vz, okz, 0)
	# W1: C_A geç basış (C_H ışına varmadan).
	var vg: Array = []
	for d in range(0, 41, 1):
		vg.append(d)
	var okg: Array = await _n_sup(vg, func(v: int) -> bool:
		var a2: Array = (await _n_senaryo([], _n19_a(v)))["kayit"]
		var s: Dictionary = await _n_senaryo([a2], _n19_h(0, 150, 15))
		return not s["tamam"].has(false) and s["oldu"] == 0)
	ayr.append("W1 C_A başta bekleme (kare): C_H başarılı %s (en çok %d kare = %d px; taslak pay ~19)" % [_n_ar(vg, okg), _n_en_buyuk(vg, okg), _n_en_buyuk(vg, okg) * 5])
	hepsi = hepsi and _n_pen(vg, okg, 0) and _n_en_buyuk(vg, okg) >= 4
	# W2: asansör biniş x.
	var vb: Array = []
	for x in range(396, 548, 4):
		vb.append(x)
	var okb: Array = await _n_sup(vb, func(v: int) -> bool: return await _n_bitirir(kay, _n19_o(0, float(v))))
	ayr.append("W2 asansör biniş `sag` bırakma x (oyuncu): başarılı %s -> %d..%d (~%d px; taslak 436..504 = 68 px; asansör x 410..530)" % [_n_ar(vb, okb), _n_en_kucuk(vb, okb), _n_en_buyuk(vb, okb), _n_en_buyuk(vb, okb) - _n_en_kucuk(vb, okb) + 4])
	hepsi = hepsi and _n_en_buyuk(vb, okb) - _n_en_kucuk(vb, okb) >= 40
	# W2b: oyuncunun F2'de bekleme süresi (C_H'nin PlakaL basışından sonra asansöre varma).
	var vt: Array = []
	for d in range(0, 61, 2):
		vt.append(d)
	var okt: Array = await _n_sup(vt, func(v: int) -> bool: return await _n_bitirir(kay, _n19_o(v)))
	ayr.append("W2b oyuncu başlangıç gecikmesi (kare; asansöre geç varış): başarılı %s (en çok %d; taslak ~+9)" % [_n_ar(vt, okt), _n_en_buyuk(vt, okt)])
	hepsi = hepsi and _n_pen(vt, okt, 0)
	# W3: C_H'nin PlakaL'de kalma süresi.
	var vh: Array = []
	for d in range(80, 241, 4):
		vh.append(d)
	var okh: Array = await _n_sup(vh, func(v: int) -> bool:
		var h2: Array = (await _n_senaryo([c_a], _n19_h(0, v)))["kayit"]
		return await _n_bitirir([c_a, h2, kay[2]], _n19_o()))
	ayr.append("W3 C_H PlakaL'de kalma süresi (kare; çözüm 150, 4 kare adım; B ve oyuncu sabit kayıt): başarılı %s (taslak devir payı >=26 kare)" % _n_ar(vh, okh))
	hepsi = hepsi and _n_pen(vh, okh, 148) and _n_en_buyuk(vh, okh) - _n_en_kucuk(vh, okh) >= 8
	# W7: raf S konumu.
	var vx: Array = []
	for x in range(800, 945, 3):
		vx.append(x)
	var okx: Array = await _n_sup(vx, func(v: int) -> bool: return await _n_bitirir(kay, _n19_o(0, 470.0, float(v))))
	ayr.append("W7 raf S konumu (`sag` bırakma merkez x; 916 üstü BlokF3R yaslanma = aynı): başarılı %s -> %d..%d (~%d px; taslak 824..916 = 92 px)" % [_n_ar(vx, okx), _n_en_kucuk(vx, okx), _n_en_buyuk(vx, okx), _n_en_buyuk(vx, okx) - _n_en_kucuk(vx, okx) + 3])
	hepsi = hepsi and _n_en_buyuk(vx, okx) - _n_en_kucuk(vx, okx) >= 30
	# W8: C_B'nin PlakaB'ye geç basışı.
	var vp: Array = []
	for d in range(0, 61, 2):
		vp.append(d)
	var okp: Array = await _n_sup(vp, func(v: int) -> bool:
		var b2: Array = (await _n_senaryo([c_a, c_h], _n19_b(0, 10, 470.0, 870.0, v)))["kayit"]
		return await _n_bitirir([c_a, c_h, b2], _n19_o()))
	ayr.append("W8 C_B tepede bekleme (kare): oyuncu başarılı %s (en çok %d kare = %d px; taslak pay ~11)" % [_n_ar(vp, okp), _n_en_buyuk(vp, okp), _n_en_buyuk(vp, okp) * 5])
	hepsi = hepsi and _n_pen(vp, okp, 0)
	# W9: şalter geri bas konumu.
	var vs: Array = []
	for x in range(996, 1070, 2):
		vs.append(x)
	var oks: Array = await _n_sup(vs, func(v: int) -> bool: return await _n_bitirir(kay, _n19_o(0, 470.0, 870.0, false, float(v))))
	ayr.append("W9 şalter geri bas (`sol` 1 kare, merkez x): başarılı %s -> %d..%d (~%d px; taslak 1019..1053 = 35 px)" % [_n_ar(vs, oks), _n_en_kucuk(vs, oks), _n_en_buyuk(vs, oks), _n_en_buyuk(vs, oks) - _n_en_kucuk(vs, oks) + 2])
	hepsi = hepsi and _n_en_buyuk(vs, oks) > _n_en_kucuk(vs, oks)
	ayr.append("oyuncu turu %d kare (<=600, pay %d)" % [tam["kare"], 600 - tam["kare"]])
	hepsi = hepsi and tam["kare"] <= 600
	_kaydi("Bölüm 19 zamanlama payları (Z1, W1 klon, W2 biniş, W3 devir, G, W7 raf S, W8 B basışı, W9 şalter)", hepsi, " || ".join(ayr))
	_kayitlar().sifirla()
	paused = false


func _test_b19_klon_fark() -> void:
	var kay: Array = await _n19_kayitlar()
	var ayr: Array = []
	var hepsi := true
	for k in [["C_A", [], _n19_a()], ["C_H", [kay[0]], _n19_h()], ["C_B", [kay[0], kay[1]], _n19_b()], ["Oyuncu", kay, _n19_o()]]:
		var r: Dictionary = await _n_klon_fark(k[1], k[2])
		ayr.append("%s canlı/klon en büyük konum farkı %.2f px (ilk sapma kare %d, x=%.0f)" % [k[0], r["fark"], r["ilk"], r["ilk_x"]])
		hepsi = hepsi and r["fark"] <= 0.5
	_kaydi("Bölüm 19 ölçüm: canlı kayıt vs klon tekrarı konum farkı (bant var; üst sınır 0,5 px)", hepsi, " || ".join(ayr))
	_kayitlar().sifirla()
	paused = false


func _test_b19_tutma() -> void:
	var ayr: Array = []
	var hepsi := true
	aktif_bolum = BOLUM_19
	var r: Dictionary = await _n_tutma_olc("PlakaL", Vector2(590, 356), 140)
	ayr.append("PlakaL (normal): basılı kalan=%d kare (beklenen 0; tutma_kare yok)" % r["kalan"])
	hepsi = hepsi and r["kalan"] == 0 and r["ilk_basili"] >= 0
	_kayitlar().sifirla()
	var bolum: Node = await _bolumu_yukle()
	var tutma: Array = []
	for n in ["PlakaA", "PlakaL", "PlakaX", "PlakaB"]:
		tutma.append(str(bolum.get_node(n).get("tutma_kare")) + "/" + str(bolum.get_node(n).get("mandal")))
	hepsi = hepsi and tutma == ["0/false", "0/false", "0/false", "0/false"]
	ayr.append("plaka tutma_kare/mandal alanları: %s (tümü 0/false)" % str(tutma))
	for i in range(25):
		_girdi_uygula({"yon": 1.0, "zipla": false})
		await physics_frame
	_girdi_uygula({"yon": 0.0, "zipla": false})
	var eski_id := bolum.get_instance_id()
	await _r_bas()
	var yeni: Node = await _yeni_sahne_bekle(eski_id)
	var a_y: float = yeni.get_node("Asansor").position.y
	var g_y: float = yeni.get_node("GecitG").position.y
	var s_sag: bool = yeni.get_node("Salter").sagda
	ayr.append("tur başı sıfırlama: asansör y=%.0f (390), G y=%.0f (60), şalter sağda=%s (true), PlakaX basılı=%s" % [a_y, g_y, str(s_sag), str(yeni.get_node("PlakaX").basili_mi())])
	hepsi = hepsi and absf(a_y - 390.0) < 0.5 and absf(g_y - 60.0) < 0.5 and s_sag and not yeni.get_node("PlakaX").basili_mi()
	_kaydi("Bölüm 19: plaka tutma yok (0 kare), tur başı sıfırlama (asansör, G, şalter)", hepsi, " || ".join(ayr))
	_kayitlar().sifirla()
	paused = false


func _test_b19_klon_siniri() -> void:
	await _n_klon_siniri("Bölüm 19: klon sınırı (dördüncü R klon kaydetmez)", 3)


func _test_b19_kilitlenme() -> void:
	var kay: Array = await _n19_kayitlar()
	var ayr: Array = []
	var hepsi := true
	# (a) odada ölüm: A+H varken C_B yok.
	_kayitlar().sifirla()
	_kayitlar().tur_kaydet(kay[0].duplicate(true))
	_kayitlar().tur_kaydet(kay[1].duplicate(true))
	var bolum: Node = await _bolumu_yukle()
	bolum.get_node("Oyuncu").global_position = Vector2(925, 356)
	var sayac := [0]
	bolum.get_node("Oyuncu").oyuncu_oldu.connect(func() -> void: sayac[0] += 1)
	var eski_id := bolum.get_instance_id()
	await _n_kosullu(bolum, [_b13_a(1, Callable(), 80)], sayac)
	var yeni: Node = await _yeni_sahne_bekle(eski_id)
	var etiket := ""
	var ok: bool = sayac[0] > 0 and yeni != null and _kayitlar().turlar.size() == 2
	if yeni != null:
		etiket = yeni.bilgi.text
		ok = ok and _klonlar(yeni).size() == 2 and etiket.contains("Tur 3") and etiket.contains("2/3")
	hepsi = hepsi and ok
	ayr.append("odada ölüm: ölüm=%d, kayıtlı tur=%d, etiket=\"%s\"" % [sayac[0], _kayitlar().turlar.size(), etiket])
	# (b) asansöre geç biniş: çıkış yok.
	var sg: Dictionary = await _n_senaryo(kay, _n19_o(50) + [_b13_a(0, Callable(), 10)])
	var ok_b: bool = not sg["bitti_ham"] and sg["oldu"] == 0
	hepsi = hepsi and ok_b
	ayr.append("geç biniş: bitti=%s, ölüm=%d, son (%.0f,%.0f)" % [sg["bitti_ham"], sg["oldu"], _n_son(sg).x, _n_son(sg).y])
	# (c) kuyu çukuru: asansör yukarıdayken kuyuya düşen çukurdan zıplayarak çıkar.
	var sk: Dictionary = await _n_senaryo([kay[0], kay[1]], [_b13_a(0, Callable(), 260)] + _n_spam(1.0, 16, 25), _n_yerlestir(Vector2(380, 356)))
	var son: Vector2 = _n_son(sk)
	var ok_k: bool = sk["oldu"] == 0 and son.x > 545.0 and son.y < 370.0
	hepsi = hepsi and ok_k
	ayr.append("kuyu çukuru (asansör yukarıda, 40 px): sağ+zıpla spam sonunda (%.0f,%.0f) ölüm=%d" % [son.x, son.y, sk["oldu"]])
	# (d) oda dönüşsüz.
	var so: Dictionary = await _n_senaryo(kay, _n_spam(0.0, 12), _n_yerlestir(Vector2(870, 356)))
	hepsi = hepsi and _n_olc(so)["ayak"] > 270.0 and so["oldu"] == 0
	ayr.append("odada zıplama en yüksek ayak y=%.1f (F3 yüzeyi 160 erişilmez)" % _n_olc(so)["ayak"])
	# (e) Baştan başla.
	_kayitlar().sifirla()
	_kayitlar().tur_kaydet(kay[0].duplicate(true))
	var b2: Node = await _bolumu_yukle()
	var eski: Node = current_scene
	b2.get_node("EkranButonlari/Kutu/YenidenDugmesi").pressed.emit()
	var yeni2: Node = await _sahne_degisimini_bekle(eski)
	var ok_e: bool = _kayitlar().turlar.size() == 0 and _klonlar(yeni2).size() == 0 and yeni2.bilgi.text.begins_with("Tur 1 ")
	hepsi = hepsi and ok_e
	ayr.append("Baştan başla: kayıt=%d, klon=%d, etiket=\"%s\"" % [_kayitlar().turlar.size(), _klonlar(yeni2).size(), yeni2.bilgi.text])
	# (f) klon son konumları.
	var tam: Dictionary = await _n_senaryo(kay, [_b13_a(0, Callable(), 460)])
	var pa: Vector2 = _n_klon_son(tam, 0)
	var ph: Vector2 = _n_klon_son(tam, 1)
	var pb: Vector2 = _n_klon_son(tam, 2)
	var ok_f: bool = pa.x > 225.0 and pa.x < 312.0 and ph.x > 620.0 and ph.x < 720.0 and pb.x > 835.0 and pb.x < 905.0 \
		and not tam["klon_oldu"][0] and not tam["klon_oldu"][1] and not tam["klon_oldu"][2]
	hepsi = hepsi and ok_f
	ayr.append("klonlar plakada biter: C_A (%.0f,%.0f), C_H (%.0f,%.0f), C_B (%.0f,%.0f); G x 780..800 ve asansör x 410..530 altında değil" % [pa.x, pa.y, ph.x, ph.y, pb.x, pb.y])
	# (g) şalter geri bas tekrar denenir: ilk deneme erken, ikincisi doğru yerde, kilit yok.
	var sh: Dictionary = await _n_senaryo(kay, _n19_yol(0, 470.0, 870.0) + [_b13_a(1, _b4_x_ge(1005.0), 200), _b13_a(-1, Callable(), 1),
		_b13_a(1, Callable(), 10), _b13_a(0, Callable(), 5), _b13_a(1, _b4_x_ge(1030.0), 100), _b13_a(-1, Callable(), 1), _b13_a(1, _b4_bitti_k(), 300)])
	hepsi = hepsi and sh["bitti_ham"] and sh["oldu"] == 0
	ayr.append("şalter ilk denemede erken, ikinci denemede doğru: bitti=%s, ölüm=%d (kilit yok)" % [sh["bitti_ham"], sh["oldu"]])
	# (h) ölü klon: C_B tek başına LazerA'da ölür ve donar.
	var sd: Dictionary = await _n_senaryo([kay[2]], [_b13_a(0, Callable(), 300)])
	var kz: Array = sd["klon_izleri"][0]
	var donuk: bool = sd["klon_oldu"][0] and kz[kz.size() - 1] == kz[kz.size() - 40]
	hepsi = hepsi and donuk
	ayr.append("C_B kaydı tek başına: öldü=%s, son (%.0f,%.0f), sabit=%s" % [str(sd["klon_oldu"][0]), kz[kz.size() - 1].x, kz[kz.size() - 1].y, str(donuk)])
	_kaydi("Bölüm 19 kilitlenme: odada ölüm, geç biniş, kuyu çukuru, oda dönüşü yok, Baştan başla, klon konumları, şalter tekrar, ölü klon", hepsi, " || ".join(ayr))
	_kayitlar().sifirla()
	paused = false


func _test_b19_determinizm() -> void:
	var kay: Array = await _n19_kayitlar()
	await _n_determinizm("Bölüm 19: determinizm (100x çözüm)", kay, _n19_o())


# ================================================================ Bölüm 20 (Mandal)
# Taslak: docs/devir/bolum_20_taslak.md (kare/px sayıları tahmindi, burada ölçülür).
# A: PlakaA'da kalır. B: rafın altında zıplayıp mandala dokunur, rafa iner, LazerA/G'yi geçer, boşluktan F1'e düşer,
# PlakaB'de kalır. Oyuncu: B yolu (mandala dokunmadan), LazerB'de B'yi bekler, kapı.
const BOLUM_20 := "res://scenes/bolumler/bolum_20.tscn"
var _n20_onb: Array = []   # [A, B]


## A: gec kare bekler, PlakaA'ya yürür, bekle kare durur.
func _n20_a(gec := 0, bekle := 15) -> Array:
	var d: Array = []
	if gec > 0:
		d.append(_b13_a(0, Callable(), gec))
	d.append(_b13_a(1, _n_plakada("PlakaA"), 200))
	d.append(_b13_a(0, Callable(), bekle))
	return d


## F2 sağ kenarından düşüp F1'e iner (sağ basılı), sonra `sol` ile PlakaB'ye gider.
func _n20_dusus(bekle := 15) -> Array:
	return [_b13_a(1, _b4_x_ge(1030.0), 400), _b13_a(1, _n_ve(_n_zemin(), _n_y_ge(570.0)), 100),
		_b13_a(-1, _n_plakada("PlakaB"), 200), _b13_a(0, Callable(), bekle)]


## B: zip_x'te durup zıplar (mandala dokunur, rafa iner), rafın sağ ucundan F2'ye, kenardan F1'e, PlakaB.
func _n20_b(gec := 0, bekle := 15, zip_x := 200.0) -> Array:
	var d: Array = []
	if gec > 0:
		d.append(_b13_a(0, Callable(), gec))
	d.append(_b13_a(1, _b4_x_ge(zip_x), 150))
	d.append(_b13_a(0, _n_ve(_n_zemin(), _n_y_le(290.0)), 80, true))
	return d + _n20_dusus(bekle)


## B'nin mandalsız yürüyüşü (zıplamaz): G'de takılır.
func _n20_b_zipsiz() -> Array:
	return [_b13_a(1, _b4_x_ge(1030.0), 250)]


## A'nın mandal sürümü: mandala zıplar, rafa iner, PlakaA'ya yürür ve orada kalır (taslak §4 eşdeğer yol).
func _n20_a_mandal(zip_x := 200.0) -> Array:
	return [_b13_a(1, _b4_x_ge(zip_x), 150), _b13_a(0, _n_ve(_n_zemin(), _n_y_le(290.0)), 80, true),
		_b13_a(1, _n_plakada("PlakaA"), 300), _b13_a(0, Callable(), 15)]


## Yalnız PlakaB'ye giden klon (mandal sürümüyle eşleşir): PlakaA basılınca yürür.
func _n20_b_sade(kosullu := true) -> Array:
	var d: Array = []
	if kosullu:
		d.append(_b13_a(0, _n_p("PlakaA"), 300))
	return d + _n20_dusus()


## Naif A: mandala dokunup rafta mandalın üstünde bekler.
func _n20_naif(bekle := 400) -> Array:
	return [_b13_a(1, _b4_x_ge(200.0), 150), _b13_a(0, _n_ve(_n_zemin(), _n_y_le(290.0)), 80, true), _b13_a(0, Callable(), bekle)]


## Oyuncu: mandala dokunmaz, G'den geçer, düşer, LazerB önünde (x<=bekle_x) B'yi bekler (bekle_lb), kapıya.
func _n20_o(bekle_lb := true, bekle_x := 830.0) -> Array:
	var d: Array = [_b13_a(1, _b4_x_ge(1030.0), 500), _b13_a(1, _n_ve(_n_zemin(), _n_y_ge(570.0)), 100),
		_b13_a(-1, _b4_x_le(bekle_x), 200)]
	if bekle_lb:
		d.append(_b13_a(0, _n_kapali("LazerB"), 400))
	d.append(_b13_a(-1, _b4_bitti_k(), 300))
	return d


func _n20_kayitlar() -> Array:
	if _n20_onb.is_empty():
		var s1: Dictionary = await _n_senaryo([], _n20_a())
		var s2: Dictionary = await _n_senaryo([s1["kayit"]], _n20_b())
		_n20_onb = [s1["kayit"], s2["kayit"]]
	return _n20_onb


func _b20_calistir() -> void:
	await _test_b20_cozum()
	await _test_b20_basarisizlik()
	await _test_b20_atlanamaz()
	await _test_b20_kisayol()
	await _test_b20_pencereler()
	await _test_b20_klon_fark()
	await _test_b20_mandal()
	await _test_b20_klon_siniri()
	await _test_b20_kilitlenme()
	await _test_b20_determinizm()


func _test_b20_cozum() -> void:
	await _n_cozum("Bölüm 20 çözümü (3 tur, 2 klon, gerçek R/girdi yolu)", [_n20_a(), _n20_b()], _n20_o(), 2)


## Örnekte ozel[f][anahtar] bir karede true oldu mu.
func _n_var_mi(s: Dictionary, anahtar: String) -> bool:
	return _n_ilk(s, anahtar, true) >= 0


func _test_b20_basarisizlik() -> void:
	var kay: Array = await _n20_kayitlar()
	var c_a: Array = kay[0]
	var c_b: Array = kay[1]
	# 1) klonsuz: LazerA'da ölür.
	var s1: Dictionary = await _n_senaryo([], _n20_o())
	_kaydi("Bölüm 20 başarısızlık 1: klonsuz -> LazerA'da ölür", s1["oldu"] > 0 and not s1["bitti_ham"] and _n_son(s1).x > 480.0 and _n_son(s1).x < 520.0,
		"ölüm=%d, son (%.0f,%.0f) (ışın x 520..526, gövde girişi 506)" % [s1["oldu"], _n_son(s1).x, _n_son(s1).y])
	# 2) mandal yok: B zıplamadan yürür, G kapalı kalır, durur (ölmez).
	var s2: Dictionary = await _n_senaryo([c_a], _n20_b_zipsiz())
	_kaydi("Bölüm 20 başarısızlık 2: mandala dokunulmaz -> GecitG kapalı kalır, yürüyen karakter G'de durur (ölüm yok)",
		not s2["bitti_ham"] and s2["oldu"] == 0 and _n_olc(s2)["xmax"] < 627.0 and _n_olc(s2)["xmax"] > 600.0 and s2["tamam"].has(false),
		"adımlar=%s, ölüm=%d, en büyük x=%.0f (G sol yüz 640-14=626)" % [str(s2["tamam"]), s2["oldu"], _n_olc(s2)["xmax"]])
	# 3) A yok: B LazerA'da ölür.
	var s3: Dictionary = await _n_senaryo([], _n20_b())
	_kaydi("Bölüm 20 başarısızlık 3: PlakaA'da kimse yok (yalnız B yolu) -> LazerA'da ölür", s3["oldu"] > 0 and not s3["bitti_ham"] and _n_son(s3).x > 480.0 and _n_son(s3).x < 520.0,
		"ölüm=%d, son (%.0f,%.0f)" % [s3["oldu"], _n_son(s3).x, _n_son(s3).y])
	# 4) A çok geç basar (klon geç): B ışına varınca LazerA açık.
	var a_gec: Array = (await _n_senaryo([], _n20_a(120)))["kayit"]
	var s4: Dictionary = await _n_senaryo([a_gec], _n20_b())
	_kaydi("Bölüm 20 başarısızlık 4: A PlakaA'ya 120 kare geç basar -> B LazerA'da ölür", s4["oldu"] > 0 and not s4["bitti_ham"],
		"ölüm=%d, son (%.0f,%.0f)" % [s4["oldu"], _n_son(s4).x, _n_son(s4).y])
	# 5) naif yol: A mandalda kalır, B PlakaA'ya gider -> LazerB açık, oyuncu F1'de bekler (çözülmez).
	var naif: Array = (await _n_senaryo([], _n20_naif()))["kayit"]
	var b_a: Array = (await _n_senaryo([naif], _n20_a()))["kayit"]
	var s5: Dictionary = await _n_senaryo([naif, b_a], _n20_o().slice(0, 4))
	var f5_bekle := -1
	for f in range(s5["iz"].size()):
		if s5["iz"][f].x <= 830.0 and s5["iz"][f].y > 500.0:
			f5_bekle = f
			break
	var lb_kapandi5 := f5_bekle >= 0 and _n_ilk(s5, "LazerB", false, f5_bekle) >= 0
	var xmin5 := 1.0e9
	for f in range(maxi(f5_bekle, 0), s5["iz"].size()):
		xmin5 = minf(xmin5, s5["iz"][f].x)
	_kaydi("Bölüm 20 başarısızlık 5: naif yol (A mandalın üstünde kalır, B PlakaA'da) -> LazerB hiç kapanmaz, oyuncu bekleyip bitiremez",
		not s5["bitti_ham"] and s5["oldu"] == 0 and s5["tamam"].size() == 4 and not s5["tamam"][3] and f5_bekle >= 0 and not lb_kapandi5 and xmin5 > 810.0,
		"adımlar=%s, ölüm=%d, LazerB önüne varış kare=%d, sonra kapandı=%s, en küçük x=%.0f (ışın 797..803; gövde girişi 817)" % [str(s5["tamam"]), s5["oldu"], f5_bekle, str(lb_kapandi5), xmin5])
	# 6) naif yol, oyuncu beklemeden yürür: LazerB'de ölür.
	var s6: Dictionary = await _n_senaryo([naif, b_a], _n20_o(false))
	_kaydi("Bölüm 20 başarısızlık 6: naif yol + oyuncu beklemeden yürür -> LazerB'de ölür", s6["oldu"] > 0 and not s6["bitti_ham"] and _n_son(s6).x > 770.0 and _n_son(s6).x < 825.0,
		"ölüm=%d, son (%.0f,%.0f)" % [s6["oldu"], _n_son(s6).x, _n_son(s6).y])
	# 7) doğru klonlar ama oyuncu F1'de B'yi beklemeden sürekli yürür: LazerB açık (B daha gelmemiş) -> ölür.
	var s7: Dictionary = await _n_senaryo(kay, _n20_o(false))
	_kaydi("Bölüm 20 başarısızlık 7: B gelmeden oyuncu LazerB'ye sürekli yürür -> ölür (ışın görünür, bekleyince geçer)",
		s7["oldu"] > 0 and not s7["bitti_ham"] and _n_son(s7).x > 770.0 and _n_son(s7).x < 825.0,
		"ölüm=%d, son (%.0f,%.0f)" % [s7["oldu"], _n_son(s7).x, _n_son(s7).y])
	# 8) B PlakaB'den hemen ayrılır (kayıt hatası): oyuncu bekler, ışın tekrar yanar -> bitmez.
	var b_erken: Array = (await _n_senaryo([c_a], _n20_b(0, 0) + [_b13_a(1, Callable(), 40)]))["kayit"]
	var s8: Dictionary = await _n_senaryo([c_a, b_erken], _n20_o())
	_kaydi("Bölüm 20 başarısızlık 8: B PlakaB'den hemen ayrılır -> LazerB tekrar yanar, oyuncu bitiremez (ölüm ya da kapanmayan ışın)",
		not s8["bitti_ham"],
		"bitti=%s, ölüm=%d, adımlar=%s, son (%.0f,%.0f)" % [s8["bitti_ham"], s8["oldu"], str(s8["tamam"]), _n_son(s8).x, _n_son(s8).y])
	# 9) mandala yanlış yerden zıplama (c=110 ve c=300, alan 156..244 dışı): mandal basılmaz, G kapalı.
	var yanlis: Array = []
	var hepsi9 := true
	for zx in [110.0, 300.0]:
		var s9: Dictionary = await _n_senaryo([c_a], _n20_b(0, 15, zx))
		var yanlis_ok: bool = not s9["bitti_ham"] and s9["oldu"] == 0 and not _n_var_mi(s9, "PlakaM") and _n_olc(s9)["xmax"] < 627.0
		hepsi9 = hepsi9 and yanlis_ok
		yanlis.append("zip_x=%.0f: mandal basıldı=%s, en büyük x=%.0f, ölüm=%d" % [zx, str(_n_var_mi(s9, "PlakaM")), _n_olc(s9)["xmax"], s9["oldu"]])
	_kaydi("Bölüm 20 başarısızlık 9: mandalın altı dışından zıplama (c=110 / c=300) -> mandal basılmaz, G kapalı kalır", hepsi9, "; ".join(yanlis))
	_kayitlar().sifirla()
	paused = false


func _test_b20_atlanamaz() -> void:
	var ayr: Array = []
	var hepsi := true
	# F1'den F2'ye çıkış yok (220 px).
	for x in [600.0, 700.0, 1100.0]:
		var sa: Dictionary = await _n_senaryo([], _n_spam(0.0, 8), _n_yerlestir(Vector2(x, 576)))
		hepsi = hepsi and _n_olc(sa)["ayak"] > 440.0
		ayr.append("F1 x=%.0f dikey zıplama: en yüksek ayak y=%.1f (DosemeF2 alt kenarı 420)" % [x, _n_olc(sa)["ayak"]])
	# LazerB zıplayarak aşılmaz (sol+zıpla spam).
	var sb: Dictionary = await _n_senaryo([], _n_spam(-1.0, 12), _n_yerlestir(Vector2(850, 576)))
	hepsi = hepsi and sb["oldu"] > 0 and _n_olc(sb)["xmin"] > 780.0 and not sb["bitti_ham"]
	ayr.append("LazerB zıplayarak (sol+zıpla spam): ölüm=%d, en küçük x=%.0f (ışın 797..803, gövde girişi 817)" % [sb["oldu"], _n_olc(sb)["xmin"]])
	# LazerA zıplayarak (F2'de, A yokken).
	var sl: Dictionary = await _n_senaryo([], _n_spam(1.0, 10), _n_yerlestir(Vector2(470, 356)))
	hepsi = hepsi and sl["oldu"] > 0 and _n_olc(sl)["xmax"] < 520.0 and not sl["bitti_ham"]
	ayr.append("LazerA zıplayarak: ölüm=%d, en büyük x=%.0f (ışın 520..526, gövde girişi 506)" % [sl["oldu"], _n_olc(sl)["xmax"]])
	# Raf üstünden LazerA aşılmaz (raftan sağ+zıpla spam).
	var sr: Dictionary = await _n_senaryo([], _n_spam(1.0, 14), _n_yerlestir(Vector2(200, 281)))
	hepsi = hepsi and sr["oldu"] > 0 and _n_olc(sr)["xmax"] < 520.0 and not sr["bitti_ham"]
	ayr.append("raf üstünden sağ+zıpla spam (A yok): ölüm=%d, en büyük x=%.0f, en yüksek ayak y=%.1f" % [sr["oldu"], _n_olc(sr)["xmax"], _n_olc(sr)["ayak"]])
	# Raftan zıplama tavana çarpar.
	var sr2: Dictionary = await _n_senaryo([], _n_spam(0.0, 6), _n_yerlestir(Vector2(200, 281)))
	hepsi = hepsi and _n_olc(sr2)["ayak"] - 48.0 >= 180.0
	ayr.append("raftan dikey zıplama: en yüksek baş y=%.1f (tavan alt kenarı 180)" % (_n_olc(sr2)["ayak"] - 48.0))
	# G kapalıyken (mandal yok): G'nin önünden sağ+zıpla spam: geçilmez.
	var sg: Dictionary = await _n_senaryo([], _n_spam(1.0, 12), _n_yerlestir(Vector2(590, 356)))
	hepsi = hepsi and _n_olc(sg)["xmax"] <= 627.0 and not sg["bitti_ham"] and sg["oldu"] == 0
	ayr.append("GecitG kapalı: en büyük x=%.0f (sol yüz 640-14=626), tavan baş y=%.1f" % [_n_olc(sg)["xmax"], _n_olc(sg)["ayak"] - 48.0])
	# F2 tavanı: dikey zıplama başı tavana (180) ulaşmaz.
	var st: Dictionary = await _n_senaryo([], _n_spam(0.0, 6), _n_yerlestir(Vector2(800, 356)))
	hepsi = hepsi and _n_olc(st)["ayak"] - 48.0 > 180.0
	ayr.append("F2 dikey zıplama (x=800): en yüksek baş y=%.1f (tavan 180)" % (_n_olc(st)["ayak"] - 48.0))
	# Mandala kazara basılmaz: raf altından yürüyen karakter.
	var sk: Dictionary = await _n_senaryo([], [_b13_a(1, _b4_x_ge(330.0), 150), _b13_a(0, Callable(), 5)])
	hepsi = hepsi and not _n_var_mi(sk, "PlakaM")
	ayr.append("raf altından yürüme: mandal basıldı=%s (basılmamalı)" % str(_n_var_mi(sk, "PlakaM")))
	_kaydi("Bölüm 20 atlanamazlık (F1->F2 dönüşü, LazerA/LazerB zıplayarak, raf üstünden, GecitG kapalı, tavan, mandal kazara)", hepsi, "; ".join(ayr))
	_kayitlar().sifirla()
	paused = false


func _test_b20_kisayol() -> void:
	var kay: Array = await _n20_kayitlar()
	var c_a: Array = kay[0]
	var c_b: Array = kay[1]
	var ayr: Array = []
	var hepsi := true
	var b0: Node = await _bolumu_yukle()
	var var_olan: String = _n_var_olanlar(b0, ["Kutu", "Bant", "Salter", "Asansor", "Ziplatici", "PlakaZ", "Zamanli"])
	paused = false
	hepsi = hepsi and var_olan == ""
	ayr.append("sahnede kutu/bant/şalter/asansör/zıplatıcı/zamanlı plaka: [%s] (yok olmalı)" % var_olan)
	# Oyuncu stratejileri.
	var mandal_oyuncu: Array = _n20_b(0, 0) + [_b13_a(-1, _b4_bitti_k(), 300)]
	var st: Array = [_n20_o(), _n20_o(false), _n20_o(true, 880.0), [_b13_a(1, Callable(), 600)], _n_spam(1.0, 20),
		[_b13_a(0, Callable(), 60), _b13_a(1, Callable(), 400)], mandal_oyuncu, _n20_a_mandal() + _n20_dusus(0) + [_b13_a(-1, _b4_bitti_k(), 200)]]
	# 1) klonsuz
	var kb: Array = []
	for i in range(st.size()):
		if await _n_bitirir([], st[i]):
			kb.append(i)
	hepsi = hepsi and kb.is_empty()
	ayr.append("klonsuz x %d strateji (kendisi mandal+plaka dahil): bitiren=%s" % [st.size(), str(kb)])
	# 2) tek klon: A, B(kör: kayıt turunda LazerA'da ölür), naif, A_mandal (kör), B_sade (kör), A ile kaydedilmiş B.
	var b_kor: Array = (await _n_senaryo([], _n20_b()))["kayit"]
	var a_m_kor: Array = (await _n_senaryo([], _n20_a_mandal()))["kayit"]
	var b_sade_kor: Array = (await _n_senaryo([], _n20_b_sade(false)))["kayit"]
	var naif: Array = (await _n_senaryo([], _n20_naif()))["kayit"]
	var tekler: Array = [c_a, b_kor, naif, a_m_kor, b_sade_kor, c_b]
	var tek_ad: Array = ["A", "B(kör)", "naif", "A_mandal", "B_sade(kör)", "B(A ile kaydedilmiş)"]
	var biten: Array = []
	for i in range(tekler.size()):
		for j in range(st.size()):
			if await _n_bitirir([tekler[i]], st[j]):
				biten.append("%s/%d" % [tek_ad[i], j])
	hepsi = hepsi and biten.is_empty()
	ayr.append("tek klon (%d rol x %d oyuncu stratejisi): bitiren=%s" % [tekler.size(), st.size(), str(biten)])
	# 3) röle: tek klon PlakaA'da T kare bekleyip PlakaB'ye yürür (kayıt turunda LazerA'da ölür).
	var rbit: Array = []
	for t in [0, 20, 60]:
		var r: Dictionary = await _n_senaryo([], [_b13_a(1, _n_plakada("PlakaA"), 200), _b13_a(0, Callable(), t)] + _n20_dusus(20))
		for j in range(st.size()):
			if await _n_bitirir([r["kayit"]], st[j]):
				rbit.append("T%d/%d" % [t, j])
	hepsi = hepsi and rbit.is_empty()
	ayr.append("röle (A'da T=0/20/60 kare bekleyip PlakaB'ye): bitiren=%s" % str(rbit))
	# 4) iki klon: çözüm ve alternatif bitirir; naif / aynı rol / eksik rol bitirmez.
	var b_a_nai: Array = (await _n_senaryo([naif], _n20_a()))["kayit"]
	var b_sade: Array = (await _n_senaryo([a_m_kor], _n20_b_sade()))["kayit"]
	var iki: Array = [["A+B", [c_a, c_b], true], ["B+A", [c_b, c_a], true], ["A_m+B_sade (eşdeğer yol)", [a_m_kor, b_sade], true],
		["A+A", [c_a, c_a], false], ["B+B", [c_b, c_b], false], ["naif+A", [naif, b_a_nai], false], ["naif+B", [naif, c_b], false],
		["A+naif", [c_a, naif], false], ["A+B_sade(kör)", [c_a, b_sade_kor], false]]
	var iki_bozuk: Array = []
	var o_alt: Array = [_b13_a(1, _b4_x_ge(480.0), 200), _b13_a(0, _n_kapali("LazerA"), 300)] + _n20_o()   # LazerA'yı da bekler
	for k in iki:
		var bit: bool = await _n_bitirir(k[1], o_alt if str(k[0]).begins_with("A_m") else _n20_o())
		if bit != k[2]:
			iki_bozuk.append("%s bitti=%s (beklenen %s)" % [k[0], str(bit), str(k[2])])
	hepsi = hepsi and iki_bozuk.is_empty()
	ayr.append("iki klon kümeleri (%d): beklentiyle uyuşmayan=%s" % [iki.size(), str(iki_bozuk)])
	# 5) min klon 2 kanıtı: PlakaA ve PlakaB aynı anda basılı iken oyuncu LazerB'yi geçer.
	var tam: Dictionary = await _n_senaryo(kay, _n20_o())
	var f_ab := -1
	for f in range(tam["ozel"].size()):
		var o: Dictionary = tam["ozel"][f]
		if o["PlakaA"] and o["PlakaB"] and f_ab < 0:
			f_ab = f
	var f_lb := -1
	for f in range(tam["iz"].size()):
		if tam["iz"][f].x <= 790.0 and tam["iz"][f].y > 500.0 and f_lb < 0:
			f_lb = f
	var ok5: bool = tam["bitti_ham"] and f_ab >= 0 and f_lb > f_ab
	hepsi = hepsi and ok5
	ayr.append("min klon 2: bitti=%s, PlakaA+PlakaB birlikte basılı ilk kare=%d, oyuncu LazerB ışınını (x<=790) kare %d'de geçer" % [tam["bitti_ham"], f_ab, f_lb])
	# 6) S ile yeni iniş: F2 zeminde S -> kat değiştirmez (tek yönlü yalnız raf).
	var inen: Array = []
	for x in range(40, 1000, 40):
		var ss: Dictionary = await _n_senaryo([], [_b13_a(0, Callable(), 3, false, true), _b13_a(0, Callable(), 45)], _n_yerlestir(Vector2(float(x), 356)))
		if _n_son(ss).y > 430.0:
			inen.append(x)
	hepsi = hepsi and inen.is_empty()
	ayr.append("F2 zeminde S (x=40..960, 40 px): kat değiştiren=%s (boş beklenir)" % str(inen))
	_kaydi("Bölüm 20 kısayol taraması (klonsuz, 1 klon x 6 rol, röle, 2 klon kümeleri, min klon 2, S inişleri)", hepsi, " || ".join(ayr))
	_kayitlar().sifirla()
	paused = false


## Raf altından zıplama yeri taraması için: kilit + rafa iniş (A'sız, tek başına).
func _n20_zip_deneme(zip_x: float) -> Dictionary:
	var s: Dictionary = await _n_senaryo([], [_b13_a(1, _b4_x_ge(zip_x), 150), _b13_a(0, _n_ve(_n_zemin(), _n_y_le(290.0)), 80, true), _b13_a(0, Callable(), 3)])
	return {"kilit": _n_var_mi(s, "PlakaM"), "raf": not s["tamam"].has(false), "ayak": _n_olc(s)["ayak"], "oldu": s["oldu"]}


func _test_b20_pencereler() -> void:
	var kay: Array = await _n20_kayitlar()
	var ayr: Array = []
	var hepsi := true
	var tam: Dictionary = await _n_senaryo(kay, _n20_o())
	var s_a: Dictionary = await _n_senaryo([], _n20_a())
	var s_b: Dictionary = await _n_senaryo([kay[0]], _n20_b())
	ayr.append("tur kareleri: A %d, B %d, oyuncu %d (<=600, pay %d)" % [s_a["kare"], s_b["kare"], tam["kare"], 600 - maxi(tam["kare"], s_b["kare"])])
	hepsi = hepsi and tam["bitti_ham"] and s_a["kare"] <= 600 and s_b["kare"] <= 600 and tam["kare"] <= 600
	# W3: rafa çıkış yüksekliği (dikey zıplamada en yüksek ayak y, raf üstü y=305).
	var s3: Dictionary = await _n_senaryo([], _n_spam(0.0, 1, 40), _n_yerlestir(Vector2(200, 356)))
	var ayak3: float = _n_olc(s3)["ayak"]
	ayr.append("W3 dikey zıplama en yüksek ayak y=%.1f (raf üstü 305: pay %.1f px; taslak 21,5)" % [ayak3, 305.0 - ayak3])
	hepsi = hepsi and 305.0 - ayak3 >= 12.0
	# W2: mandala zıplama x taraması (kilit + rafa iniş).
	var vx: Array = []
	for x in range(120, 301, 4):
		vx.append(x)
	var kilit_ar: Array = []
	var okx: Array = []
	for v in vx:
		var d: Dictionary = await _n20_zip_deneme(float(v))
		kilit_ar.append(d["kilit"])
		okx.append(d["kilit"] and d["raf"] and d["oldu"] == 0)
	ayr.append("W2 zıplama c (dur-zıpla x): kilit+rafa iniş %s -> %d..%d (~%d px; taslak 156..244 = 88 px); yalnız kilit %s" % [_n_ar(vx, okx), _n_en_kucuk(vx, okx), _n_en_buyuk(vx, okx), _n_en_buyuk(vx, okx) - _n_en_kucuk(vx, okx) + 4, _n_ar(vx, kilit_ar)])
	hepsi = hepsi and _n_en_buyuk(vx, okx) - _n_en_kucuk(vx, okx) >= 60
	# W4: mandal kilit -> G açıklığı >= 48 px (y<=232) / tam açık (y<=180.5); B'nin G'ye varışı.
	var f_kilit := -1
	var f_g48 := -1
	var f_gtam := -1
	for f in range(s_b["ozel"].size()):
		var o: Dictionary = s_b["ozel"][f]
		if f_kilit < 0 and o["PlakaM"]:
			f_kilit = f
		if f_g48 < 0 and o["GecitG"] <= 232.0:
			f_g48 = f
		if f_gtam < 0 and o["GecitG"] <= 180.5:
			f_gtam = f
	var f_bg: int = _n_x_kare(s_b["iz"], 612.0)
	var f_la: int = _n_x_kare(s_b["iz"], 500.0)
	var f_a_basis := -1
	for f in range(s_a["ozel"].size()):
		if s_a["ozel"][f]["PlakaA"]:
			f_a_basis = f
			break
	ayr.append("W4 B turunda: mandal kilit kare=%d, G>=48 px açık kare=%d (+%d), G tam açık kare=%d, B G önüne (x>=612) kare=%d => pay %d kare" % [f_kilit, f_g48, f_g48 - f_kilit, f_gtam, f_bg, f_bg - f_g48])
	hepsi = hepsi and f_kilit >= 0 and f_g48 > f_kilit and f_bg - f_g48 >= 10
	# W1: A'nın PlakaA'ya basışı -> B'nin LazerA'ya varışı.
	ayr.append("W1 A PlakaA'ya ilk basış kare=%d, B LazerA'ya (x>=500) varış kare=%d => pay %d kare (taslak ~78)" % [f_a_basis, f_la, f_la - f_a_basis])
	hepsi = hepsi and f_a_basis >= 0 and f_la - f_a_basis >= 10
	var vg: Array = []
	for d in range(0, 161, 4):
		vg.append(d)
	var okg: Array = []
	for v in vg:
		var a2: Array = (await _n_senaryo([], _n20_a(v)))["kayit"]
		var sg2: Dictionary = await _n_senaryo([a2], _n20_b())
		okg.append(not sg2["tamam"].has(false) and sg2["oldu"] == 0)
	ayr.append("W1 A başta bekleme (kare): B başarılı %s (en çok %d kare = pay)" % [_n_ar(vg, okg), _n_en_buyuk(vg, okg)])
	hepsi = hepsi and _n_pen(vg, okg, 0) and _n_en_buyuk(vg, okg) >= 10
	# W1b: B gecikmesi (oyuncu bekler): çözülür mü, tur kare sınırı 600.
	var vb: Array = []
	for d in range(0, 201, 10):
		vb.append(d)
	var okb: Array = []
	for v in vb:
		var b2: Array = (await _n_senaryo([kay[0]], _n20_b(v)))["kayit"]
		var sb2: Dictionary = await _n_senaryo([kay[0], b2], _n20_o())
		okb.append(sb2["bitti_ham"] and sb2["oldu"] == 0 and sb2["kare"] <= 600)
	ayr.append("W1b B başta bekleme (kare; oyuncu LazerB önünde bekler, tur<=600): başarılı %s (alt sınır yok, üst sınır tur kare sınırı)" % _n_ar(vb, okb))
	hepsi = hepsi and _n_pen(vb, okb, 0) and _n_pen(vb, okb, 50)
	# W5: oyuncunun LazerB önünde bekleme süresi.
	var f_o_bekle := -1
	for f in range(tam["iz"].size()):
		if tam["iz"][f].x <= 830.0 and tam["iz"][f].y > 500.0:
			f_o_bekle = f
			break
	var f_lb_kapali := _n_ilk(tam, "LazerB", false, maxi(f_o_bekle, 0))
	var f_b_plaka := -1
	for f in range(maxi(f_o_bekle, 0), tam["ozel"].size()):
		if tam["ozel"][f].get("PlakaB_f", false):
			f_b_plaka = f
			break
	var f_o_gecis := -1
	for f in range(maxi(f_o_bekle, 0), tam["iz"].size()):
		if tam["iz"][f].x <= 790.0:
			f_o_gecis = f
			break
	var f_o_plaka := -1
	for f in range(tam["ozel"].size()):
		if tam["ozel"][f].get("PlakaB_f", false):
			f_o_plaka = f
			break
	ayr.append("W5 oyuncu F1'e iner, PlakaB üstünden geçerken ışını kısa süre kendisi kapatır (kare %d, B değil); oyuncu LazerB önüne (x<=830) kare=%d, B'nin PlakaB'ye basışı/LazerB kapanışı kare=%d/%d => oyuncu bekleme %d kare (ışın görünür), ışın geçişi (x<=790) kare=%d" % [f_o_plaka, f_o_bekle, f_b_plaka, f_lb_kapali, f_lb_kapali - f_o_bekle, f_o_gecis])
	hepsi = hepsi and f_o_bekle >= 0 and f_lb_kapali > f_o_bekle and f_o_gecis > f_lb_kapali
	var vw: Array = []
	for x in range(790, 1000, 10):
		vw.append(x)
	var okw: Array = []
	for v in vw:
		okw.append(await _n_bitirir(kay, _n20_o(true, float(v))))
	ayr.append("W5b oyuncu bekleme x (LazerB önü): başarılı %s (gövde girişi 817 altında ölür)" % _n_ar(vw, okw))
	hepsi = hepsi and _n_pen(vw, okw, 830)
	# W6: A'nın PlakaA'dan sağa ayrılması -> LazerA'da ölme (tutucu kaçışı).
	var w6: Array = []
	var w6_ok := true
	for ek in [0, 1, 2, 3]:
		var st6: Array = [_b13_a(1, _n_plakada("PlakaA"), 200), _b13_a(0, Callable(), ek), _b13_a(1, Callable(), 80)]
		var s6: Dictionary = await _n_senaryo([], st6)
		var son_f := -1
		for f in range(s6["ozel"].size()):
			if s6["ozel"][f].get("PlakaA_f", false):
				son_f = f
		w6.append("duraksama %d: ölüm=%d, plakadan ayrılış->ölüm %d kare" % [ek, s6["oldu"], s6["iz"].size() - son_f])
		w6_ok = w6_ok and s6["oldu"] > 0
	var s6b: Dictionary = await _n_senaryo([], [_b13_a(1, _n_plakada("PlakaA"), 200), _b13_a(1, Callable(), 4), _b13_a(0, Callable(), 2), _b13_a(1, Callable(), 80)])
	w6.append("kesik (4 kare yürü, 2 dur, devam): ölüm=%d" % s6b["oldu"])
	w6_ok = w6_ok and s6b["oldu"] > 0
	hepsi = hepsi and w6_ok
	ayr.append("W6 PlakaA tutucusu sağa ayrılırsa LazerA'da ölür: %s" % "; ".join(w6))
	# W7: PlakaB'den sola ayrılma -> LazerB'de ölme.
	var w7: Array = []
	var w7_ok := true
	for ek in [0, 1, 2, 3]:
		var s7: Dictionary = await _n_senaryo([], [_b13_a(0, Callable(), ek), _b13_a(-1, Callable(), 80)], _n_yerlestir(Vector2(930, 576)))
		var son_f7 := -1
		for f in range(s7["ozel"].size()):
			if s7["ozel"][f].get("PlakaB_f", false):
				son_f7 = f
		w7.append("duraksama %d: ölüm=%d, plakadan ayrılış->ölüm %d kare" % [ek, s7["oldu"], s7["iz"].size() - son_f7])
		w7_ok = w7_ok and s7["oldu"] > 0
	hepsi = hepsi and w7_ok
	ayr.append("W7 PlakaB tutucusu sola ayrılırsa LazerB'de ölür: %s" % "; ".join(w7))
	_kaydi("Bölüm 20 zamanlama payları (W1 A/B, W2 mandal zıplama, W3 raf, W4 geçit, W5 oyuncu bekleme, W6/W7 tutucu kaçışı, tur kareleri)", hepsi, " || ".join(ayr))
	_kayitlar().sifirla()
	paused = false


func _test_b20_klon_fark() -> void:
	var kay: Array = await _n20_kayitlar()
	var ayr: Array = []
	var hepsi := true
	for k in [["A", [], _n20_a()], ["B", [kay[0]], _n20_b()], ["Oyuncu", kay, _n20_o()]]:
		var r: Dictionary = await _n_klon_fark(k[1], k[2])
		ayr.append("%s canlı/klon en büyük konum farkı %.2f px (ilk sapma kare %d, x=%.0f)" % [k[0], r["fark"], r["ilk"], r["ilk_x"]])
		hepsi = hepsi and r["fark"] <= 0.5
	_kaydi("Bölüm 20 ölçüm: canlı kayıt vs klon tekrarı konum farkı (bant yok; üst sınır 0,5 px, taslak beklentisi 0)", hepsi, " || ".join(ayr))
	_kayitlar().sifirla()
	paused = false


func _test_b20_mandal() -> void:
	var ayr: Array = []
	var hepsi := true
	aktif_bolum = BOLUM_20
	# Rafın üstünde basılı, sonra rafın sağ ucundan ayrılır: mandal tur sonuna kadar basılı kalır.
	var r: Dictionary = await _n_tutma_olc("PlakaM", Vector2(200, 281), 330)
	ayr.append("PlakaM: ilk basılı kare=%d, son fiziksel kare=%d, sonra basılı kalan=%d kare (ölçüm sonuna kadar=%s)" % [r["ilk_basili"], r["son_fiziksel"], r["kalan"], str(r["sona_kadar"])])
	hepsi = hepsi and r["ilk_basili"] >= 0 and r["sona_kadar"] and r["kalan"] >= 300
	var son_g: float = r["ozel"][r["ozel"].size() - 1]["GecitG"]
	ayr.append("mandaldan ayrıldıktan ~%d kare sonra GecitG y=%.0f (açık 180, kapalı 280)" % [r["kalan"], son_g])
	hepsi = hepsi and son_g <= 181.0
	var f_acik := -1
	var tekrar_kapandi := false
	for f in range(r["ozel"].size()):
		var y: float = r["ozel"][f]["GecitG"]
		if f_acik < 0 and y <= 180.5:
			f_acik = f
		elif f_acik >= 0 and y > 180.5:
			tekrar_kapandi = true
	ayr.append("G tam açık kare=%d, sonradan kapanma=%s" % [f_acik, str(tekrar_kapandi)])
	hepsi = hepsi and f_acik >= 0 and not tekrar_kapandi
	# Çözüm turunda (B klonu mandalı bir kez basıyor): oyuncu turu boyunca basılı, G hiç kapanmaz.
	var kay: Array = await _n20_kayitlar()
	var tam: Dictionary = await _n_senaryo(kay, _n20_o())
	var f_m := _n_ilk(tam, "PlakaM", true)
	var m_kesinti := 0
	var g_kapandi := false
	var f_gtam := -1
	for f in range(maxi(f_m, 0), tam["ozel"].size()):
		if not tam["ozel"][f]["PlakaM"]:
			m_kesinti += 1
		var gy: float = tam["ozel"][f]["GecitG"]
		if f_gtam < 0 and gy <= 180.5:
			f_gtam = f
		elif f_gtam >= 0 and gy > 180.5:
			g_kapandi = true
	var b_fiz := -1
	var b_son_fiz := -1
	for f in range(tam["ozel"].size()):
		if tam["ozel"][f].get("PlakaM_f", false):
			if b_fiz < 0:
				b_fiz = f
			b_son_fiz = f
	ayr.append("çözüm turu: mandal ilk basılı kare=%d, fiziksel basış %d..%d (yalnız B klonu), sonrasında basılı olmayan kare=%d, G tam açık kare=%d, G tekrar kapandı=%s, tur %d kare" % [f_m, b_fiz, b_son_fiz, m_kesinti, f_gtam, str(g_kapandi), tam["kare"]])
	hepsi = hepsi and f_m >= 0 and m_kesinti == 0 and not g_kapandi and tam["bitti_ham"] and b_son_fiz < tam["ozel"].size() - 30
	# Tur başı sıfırlama.
	_kayitlar().sifirla()
	var bolum: Node = await _bolumu_yukle()
	var plaka_m: BasincPlakasi = bolum.get_node("PlakaM")
	var kilitli0: bool = plaka_m.kilitli
	var mandal_tur: bool = plaka_m.mandal and plaka_m.tutma_kare == 0
	bolum.get_node("Oyuncu").global_position = Vector2(200, 281)
	for i in range(12):
		_girdi_uygula({"yon": 0.0, "zipla": false})
		await physics_frame
	var kilitli1: bool = plaka_m.kilitli
	var eski_id := bolum.get_instance_id()
	await _r_bas()
	var yeni: Node = await _yeni_sahne_bekle(eski_id)
	var ok_t: bool = yeni != null and yeni.get_node("PlakaM").kilitli == false and yeni.get_node("PlakaM").basili_mi() == false \
		and absf(yeni.get_node("GecitG").position.y - 280.0) < 0.5
	hepsi = hepsi and ok_t and not kilitli0 and kilitli1 and mandal_tur
	ayr.append("tur başı: ilk açılışta kilitli=%s, mandala basınca kilitli=%s, mandal kipi=%s; R sonrası yeni turda kilitli=%s, G y=%.0f (kapalı 280)" % [
		str(kilitli0), str(kilitli1), str(mandal_tur), str(yeni.get_node("PlakaM").kilitli if yeni != null else "?"), yeni.get_node("GecitG").position.y if yeni != null else -1.0])
	_kaydi("Bölüm 20: mandal bir kez basınca tur sonuna kadar basılı kalır (G hiç kapanmaz), tur başı sıfırlama", hepsi, " || ".join(ayr))
	_kayitlar().sifirla()
	paused = false


func _test_b20_klon_siniri() -> void:
	await _n_klon_siniri("Bölüm 20: klon sınırı (üçüncü R klon kaydetmez)", 2)


func _test_b20_kilitlenme() -> void:
	var kay: Array = await _n20_kayitlar()
	var ayr: Array = []
	var hepsi := true
	# (a) klon hakkı bitmiş (naif yol, 2/2): R klon kaydetmez, etiket "Klon hakkı bitti".
	var naif: Array = (await _n_senaryo([], _n20_naif()))["kayit"]
	var b_a: Array = (await _n_senaryo([naif], _n20_a()))["kayit"]
	_kayitlar().sifirla()
	_kayitlar().tur_kaydet(naif.duplicate(true))
	_kayitlar().tur_kaydet(b_a.duplicate(true))
	var bolum: Node = await _bolumu_yukle()
	var eski_id := bolum.get_instance_id()
	for i in range(5):
		_girdi_uygula({"yon": 0.0, "zipla": false})
		await physics_frame
	await _r_bas()
	var yeni: Node = await _yeni_sahne_bekle(eski_id)
	var etiket: String = bolum.bilgi.text if is_instance_valid(bolum) else ""
	var ok_a: bool = yeni == null and _kayitlar().turlar.size() == 2 and etiket.contains("Klon hakkı bitti") and etiket.contains("2/2")
	hepsi = hepsi and ok_a
	ayr.append("naif 2/2: R sonrası yeni sahne=%s, kayıtlı tur=%d, etiket=\"%s\"" % [str(yeni != null), _kayitlar().turlar.size(), etiket])
	# (b) T tuşu (bastan) o durumdan çıkarır: klonlar silinir, tur 1.
	var eski2: Node = current_scene
	await _t_bas()
	var yeni2: Node = await _sahne_degisimini_bekle(eski2)
	var ok_b: bool = yeni2 != null and _kayitlar().turlar.size() == 0 and _klonlar(yeni2).size() == 0 and yeni2.bilgi.text.begins_with("Tur 1 ")
	hepsi = hepsi and ok_b
	ayr.append("T tuşu: kayıt=%d, klon=%d, etiket=\"%s\"" % [_kayitlar().turlar.size(), _klonlar(yeni2).size() if yeni2 != null else -1, yeni2.bilgi.text if yeni2 != null else ""])
	# (c) Baştan başla düğmesi.
	_kayitlar().sifirla()
	_kayitlar().tur_kaydet(naif.duplicate(true))
	_kayitlar().tur_kaydet(b_a.duplicate(true))
	var b2: Node = await _bolumu_yukle()
	var eski3: Node = current_scene
	b2.get_node("EkranButonlari/Kutu/YenidenDugmesi").pressed.emit()
	var yeni3: Node = await _sahne_degisimini_bekle(eski3)
	var ok_c: bool = yeni3 != null and _kayitlar().turlar.size() == 0 and _klonlar(yeni3).size() == 0 and yeni3.bilgi.text.begins_with("Tur 1 ")
	hepsi = hepsi and ok_c
	ayr.append("Baştan başla: kayıt=%d, klon=%d" % [_kayitlar().turlar.size(), _klonlar(yeni3).size() if yeni3 != null else -1])
	# (d) hak varken F1'e erken düşen oyuncu R ile turu bitirip yeni klon kaydeder (çıkış yolu).
	_kayitlar().sifirla()
	var b3: Node = await _bolumu_yukle()
	b3.get_node("Oyuncu").global_position = Vector2(900, 576)
	for i in range(5):
		_girdi_uygula({"yon": 0.0, "zipla": false})
		await physics_frame
	var eski4 := b3.get_instance_id()
	await _r_bas()
	var yeni4: Node = await _yeni_sahne_bekle(eski4)
	var ok_d: bool = yeni4 != null and _kayitlar().turlar.size() == 1 and _klonlar(yeni4).size() == 1
	hepsi = hepsi and ok_d
	ayr.append("hak varken F1'de R: yeni tur=%s, kayıtlı tur=%d" % [str(yeni4 != null), _kayitlar().turlar.size()])
	# (e) F1'de LazerB'ye giren oyuncu ölür, klonlar korunur, tur sayısı artmaz.
	_kayitlar().sifirla()
	_kayitlar().tur_kaydet(kay[0].duplicate(true))
	var b4: Node = await _bolumu_yukle()
	b4.get_node("Oyuncu").global_position = Vector2(850, 576)
	var sayac := [0]
	b4.get_node("Oyuncu").oyuncu_oldu.connect(func() -> void: sayac[0] += 1)
	var eski5 := b4.get_instance_id()
	await _n_kosullu(b4, [_b13_a(-1, Callable(), 60)], sayac)
	var yeni5: Node = await _yeni_sahne_bekle(eski5)
	var ok_e: bool = sayac[0] > 0 and yeni5 != null and _kayitlar().turlar.size() == 1 and _klonlar(yeni5).size() == 1 and yeni5.bilgi.text.begins_with("Tur 2 ")
	hepsi = hepsi and ok_e
	ayr.append("F1'de LazerB ölümü: ölüm=%d, kayıtlı tur=%d, klon=%d, etiket=\"%s\"" % [sayac[0], _kayitlar().turlar.size(), _klonlar(yeni5).size() if yeni5 != null else -1, yeni5.bilgi.text if yeni5 != null else ""])
	# (f) klonlar plakada biter.
	var son: Dictionary = await _n_senaryo(kay, [_b13_a(0, Callable(), 420)])
	var pa: Vector2 = _n_klon_son(son, 0)
	var pb: Vector2 = _n_klon_son(son, 1)
	var ok_f: bool = pa.x > 366.0 and pa.x < 454.0 and pa.y > 340.0 and pb.x > 872.0 and pb.x < 960.0 and pb.y > 560.0 \
		and not son["klon_oldu"][0] and not son["klon_oldu"][1]
	hepsi = hepsi and ok_f
	ayr.append("klonlar plakada biter: A (%.0f,%.0f) [PlakaA 380..440], B (%.0f,%.0f) [PlakaB 886..946]" % [pa.x, pa.y, pb.x, pb.y])
	# (g) çözüm turunda ölüm yok, bölüm biter.
	var tam: Dictionary = await _n_senaryo(kay, _n20_o())
	hepsi = hepsi and tam["bitti_ham"] and tam["oldu"] == 0
	ayr.append("çözüm turu: bitti=%s, ölüm=%d" % [str(tam["bitti_ham"]), tam["oldu"]])
	_kaydi("Bölüm 20 kilitlenme/çıkış: klon hakkı bitince T ve Baştan başla çıkışı, hak varken R, F1 ölümü, klon konumları", hepsi, " || ".join(ayr))
	_kayitlar().sifirla()
	paused = false


func _test_b20_determinizm() -> void:
	var kay: Array = await _n20_kayitlar()
	await _n_determinizm("Bölüm 20: determinizm (20x çözüm)", kay, _n20_o(), 20)


# ================================================================ Bölüm 21 (Fitil ve Mühür)
# Taslak: docs/devir/bolum_21_taslak.md (kare/px sayıları tahmindi, burada ölçülür).
# A (fitilci): raftan S ile kuyuya iner, ZP'ye basar (fitil), PlakaA'da kalır. B (mühürcü): G'nin önünde bekler, G
# açılınca odaya girip mühre basar, LazerA/GM'yi geçip PlakaB'de kalır. Oyuncu: LazerA, GM, LazerB, kapı.
const BOLUM_21 := "res://scenes/bolumler/bolum_21.tscn"
var _n21_onb: Array = []   # [A, B]


## A: gec kare bekler, raf ortasından S ile kuyuya iner; zp ise ZP'ye basar; PlakaA'da bekle kare kalır.
func _n21_a(gec := 0, bekle := 15, zp := true) -> Array:
	var d: Array = []
	if gec > 0:
		d.append(_b13_a(0, Callable(), gec))
	d.append(_b13_a(1, _b4_x_ge(380.0), 100))
	d.append(_b13_a(0, _n_ve(_n_zemin(), _n_y_ge(570.0)), 100, false, true))
	if zp:
		d.append(_b13_a(-1, _n_p("PlakaZ"), 100))
	d.append(_b13_a(1, _n_plakada("PlakaA"), 200))
	d.append(_b13_a(0, Callable(), bekle))
	return d


## Fitilde kalan naif A: ZP'ye basar ve orada bekler (PlakaA boş kalır).
func _n21_a_naif(bekle := 420) -> Array:
	return [_b13_a(1, _b4_x_ge(380.0), 100), _b13_a(0, _n_ve(_n_zemin(), _n_y_ge(570.0)), 100, false, true),
		_b13_a(-1, _n_p("PlakaZ"), 100), _b13_a(0, Callable(), bekle)]


## B: gec kare bekler, G'nin önünde (c<=196) G açılana (>=48 px) dek bekler. mehur: odaya girip mühre basar;
## değilse odada yalnız c<=140'a (mühre değmeden) girer. Sonra PlakaB'ye yürür ve bekle kare kalır.
func _n21_b(gec := 0, bekle := 15, mehur := true) -> Array:
	var d: Array = []
	if gec > 0:
		d.append(_b13_a(0, Callable(), gec))
	d.append(_b13_a(-1, _b4_x_le(196.0), 120))
	d.append(_b13_a(0, _n_gecit_ust("GecitG", 232.0), 500))
	if mehur:
		d.append(_b13_a(-1, _n_p("PlakaM"), 100))
	else:
		d.append(_b13_a(-1, _b4_x_le(140.0), 100))
	d.append(_b13_a(1, _n_plakada("PlakaB"), 400))
	d.append(_b13_a(0, Callable(), bekle))
	return d


## G tam kapalı mı (y>=279.5).
func _n21_g_kapali() -> Callable:
	return func(b: Node) -> bool: return b.get_node("GecitG").position.y >= 279.5


## Oyuncu: LazerA önünde ışın sönene dek bekler, sonra LazerB önünde bekler, kapıya.
func _n21_o(bekle_la := true, bekle_lb := true) -> Array:
	var d: Array = [_b13_a(1, _b4_x_ge(480.0), 200)]
	if bekle_la:
		d.append(_b13_a(0, _n_kapali("LazerA"), 400))
	d.append(_b13_a(1, _b4_x_ge(850.0), 300))
	if bekle_lb:
		d.append(_b13_a(0, _n_kapali("LazerB"), 400))
	d.append(_b13_a(1, _b4_bitti_k(), 300))
	return d


## Kör eşdeğer A' (taslak §8 iddiası): G önünde sabit süre bekler, odaya girip mühre basar, PlakaB'ye gider.
## ÖLÇÜM: kayıt turunda G kapalı ve PlakaA boş olduğundan A' LazerA'da ölür; kayıt ölüm anında kesilir, yol tamamlanamaz.
func _n21_a_kor() -> Array:
	return [_b13_a(-1, _b4_x_le(196.0), 120), _b13_a(0, Callable(), 125), _b13_a(-1, Callable(), 22),
		_b13_a(1, Callable(), 170), _b13_a(0, Callable(), 15)]


func _n21_kayitlar() -> Array:
	if _n21_onb.is_empty():
		var s1: Dictionary = await _n_senaryo([], _n21_a())
		var s2: Dictionary = await _n_senaryo([s1["kayit"]], _n21_b())
		_n21_onb = [s1["kayit"], s2["kayit"]]
	return _n21_onb


func _b21_calistir() -> void:
	aktif_bolum = BOLUM_21
	_n21_onb = []
	await _test_b21_cozum()
	await _test_b21_yapi_kablo()
	await _test_b21_basarisizlik()
	await _test_b21_atlanamaz()
	await _test_b21_kisayol()
	await _test_b21_pencereler()
	await _test_b21_klon_fark()
	await _test_b21_plakalar()
	await _test_b21_oda_tuzagi()
	await _test_b21_klon_siniri()
	await _test_b21_kilitlenme()
	await _test_b21_gorunurluk()
	await _test_b21_determinizm()


func _test_b21_cozum() -> void:
	aktif_bolum = BOLUM_21
	await _n_cozum("Bölüm 21 çözümü (3 tur, 2 klon, gerçek R/girdi yolu)", [_n21_a(), _n21_b()], _n21_o(), 2)


func _test_b21_yapi_kablo() -> void:
	aktif_bolum = BOLUM_21
	_kayitlar().sifirla()
	var b: Node = await _bolumu_yukle()
	var ayr: Array = []
	var hepsi := true
	# Sahne parametreleri (taslak §3).
	var pz: BasincPlakasi = b.get_node("PlakaZ")
	var pm: BasincPlakasi = b.get_node("PlakaM")
	var par: bool = b.max_klon == 2 and b.ipucu_klon == 0 and pz.tutma_kare == 180 and not pz.mandal and pm.mandal and pm.tutma_kare == 0
	hepsi = hepsi and par
	ayr.append("max_klon=%d, ipucu_klon=%d, ZP tutma_kare=%d mandal=%s, M mandal=%s tutma_kare=%d" % [b.max_klon, b.ipucu_klon, pz.tutma_kare, str(pz.mandal), str(pm.mandal), pm.tutma_kare])
	var yasak: String = _n_var_olanlar(b, ["Kutu", "Bant", "Salter", "Asansor", "Ziplatici"])
	hepsi = hepsi and yasak == ""
	ayr.append("sahnede kutu/bant/şalter/asansör/zıplatıcı: [%s] (yok olmalı)" % yasak)
	# Ağaç sırası: plaka/geçit/lazer karakterlerden ÖNCE.
	var sira_ok := true
	var son := -1
	for ad in ["PlakaM", "PlakaZ", "PlakaA", "PlakaB", "GecitG", "GecitM", "LazerA", "LazerB", "Kapi", "Oyuncu"]:
		var i: int = b.get_node(ad).get_index()
		sira_ok = sira_ok and i > son
		son = i
	hepsi = hepsi and sira_ok
	ayr.append("ağaç sırası taslakla aynı: %s" % str(sira_ok))
	var g: Node = b.get_node("GecitG")
	var gm: Node = b.get_node("GecitM")
	var tg: Array = []
	for p in g.tetikleyici_yollari:
		tg.append(str(p))
	var tgm: Array = []
	for p in gm.tetikleyici_yollari:
		tgm.append(str(p))
	var tetik_ok: bool = tg == ["../PlakaZ", "../PlakaM"] and tgm == ["../PlakaM"] \
		and b.get_node("LazerA").tetikleyici_yollari.size() == 1 and b.get_node("LazerB").tetikleyici_yollari.size() == 1 \
		and b.get_node("LazerA").tetik_aktifken_kapali and b.get_node("LazerB").tetik_aktifken_kapali
	hepsi = hepsi and tetik_ok
	ayr.append("tetikleyiciler: G=%s, GM=%s" % [str(tg), str(tgm)])
	# Kablo meta'ları: var, çoklu çizgi, başlangıç tetikleyici plakada, bitiş hedefte.
	var kablo_say := 0
	var kablo_sorun: Array = []
	var plaka_yer := {"PlakaZ": Vector2(180, 592), "PlakaM": Vector2(80, 372), "PlakaA": Vector2(520, 592), "PlakaB": Vector2(790, 372)}
	var beklenen: Array = [["GecitG", "kablo", "PlakaZ"], ["GecitG", "kablo_2", "PlakaM"], ["GecitM", "kablo", "PlakaM"],
		["LazerA", "kablo", "PlakaA"], ["LazerB", "kablo", "PlakaB"]]
	for e in beklenen:
		var hedef: Node = b.get_node(e[0])
		if not hedef.has_meta(e[1]):
			kablo_sorun.append("%s.%s yok" % [e[0], e[1]])
			continue
		var pts: PackedVector2Array = hedef.get_meta(e[1])
		kablo_say += 1
		if pts.size() < 2:
			kablo_sorun.append("%s.%s nokta<2" % [e[0], e[1]])
			continue
		var bas: Vector2 = pts[0]
		var bit: Vector2 = pts[pts.size() - 1]
		var plaka_p: Vector2 = plaka_yer[e[2]]
		if absf(bas.x - plaka_p.x) > 45.0 or absf(bas.y - plaka_p.y) > 30.0:
			kablo_sorun.append("%s.%s başı %s, %s plakasından uzak (%s)" % [e[0], e[1], str(bas), e[2], str(plaka_p)])
		var hp: Vector2 = hedef.position
		var hedefte := false
		if str(e[0]).begins_with("Gecit"):
			hedefte = bit.x >= hp.x - 16.0 and bit.x <= hp.x + 16.0 and bit.y >= hp.y - 106.0 and bit.y <= hp.y + 106.0
		else:
			hedefte = absf(bit.x - hp.x) <= 8.0 and bit.y >= hp.y and bit.y <= hp.y + 200.0
		if not hedefte:
			kablo_sorun.append("%s.%s sonu %s hedefte değil (%s)" % [e[0], e[1], str(bit), str(hp)])
		for p in pts:
			if p.x < 0.0 or p.x > 1152.0 or p.y < 0.0 or p.y > 648.0:
				kablo_sorun.append("%s.%s ekran dışı nokta %s" % [e[0], e[1], str(p)])
	hepsi = hepsi and kablo_sorun.is_empty() and kablo_say == 5
	ayr.append("kablo meta'ları: %d/5 var, sorun=%s" % [kablo_say, str(kablo_sorun)])
	_kaydi("Bölüm 21 sahne yapısı (parametreler, ağaç sırası, tetikleyiciler, yasak mekanik yok) ve plaka-geçit/lazer kablo meta'ları", hepsi, " || ".join(ayr))
	_kayitlar().sifirla()
	paused = false


func _test_b21_basarisizlik() -> void:
	aktif_bolum = BOLUM_21
	var kay: Array = await _n21_kayitlar()
	var c_a: Array = kay[0]
	# 1) klonsuz: LazerA'da ölür.
	var s1: Dictionary = await _n_senaryo([], _n21_o(false))
	_kaydi("Bölüm 21 başarısızlık 1: klonsuz -> LazerA'da ölür", s1["oldu"] > 0 and not s1["bitti_ham"] and _n_son(s1).x > 480.0 and _n_son(s1).x < 520.0,
		"ölüm=%d, son (%.0f,%.0f) (ışın x 517..523, gövde girişi 503)" % [s1["oldu"], _n_son(s1).x, _n_son(s1).y])
	# 2) tek başına fitil: oyuncu kuyuya iner, ZP'ye basar, G açılır ama çıkamaz.
	var s2: Dictionary = await _n_senaryo([], _n21_a())
	var g_min := 1.0e9
	for o in s2["ozel"]:
		g_min = minf(g_min, o["GecitG"])
	_kaydi("Bölüm 21 başarısızlık 2: tek başına fitil (oyuncu kuyuya iner) -> G açılır ama oyuncu kuyuda kalır, bölüm bitmez",
		not s2["bitti_ham"] and s2["oldu"] == 0 and g_min <= 181.0 and _n_son(s2).y > 540.0 and not s2["tamam"].has(false),
		"G en yüksek y=%.0f (açık 180), son (%.0f,%.0f), adımlar=%s" % [g_min, _n_son(s2).x, _n_son(s2).y, str(s2["tamam"])])
	# 3) A ZP'ye basmadan PlakaA'da kalır: G hiç açılmaz, B G önünde bekler (şerit hiç dolmaz).
	var a_zpsiz: Array = (await _n_senaryo([], _n21_a(0, 15, false)))["kayit"]
	var s3: Dictionary = await _n_senaryo([a_zpsiz], _n21_b())
	var g_min3 := 1.0e9
	for o in s3["ozel"]:
		g_min3 = minf(g_min3, o["GecitG"])
	_kaydi("Bölüm 21 başarısızlık 3: A ZP'ye basmadan PlakaA'da kalır -> G hiç açılmaz, B önce G önünde sonra GM önünde takılır (odaya giremez, ölmez)",
		not s3["bitti_ham"] and s3["oldu"] == 0 and g_min3 > 279.0 and s3["tamam"].has(false) and not _n_var_mi(s3, "PlakaM_f") and _n_olc(s3)["xmax"] < 627.0 and not _n_var_mi(s3, "PlakaZ"),
		"G en küçük y=%.0f (kapalı 280), adımlar=%s, B en büyük x=%.0f, ölüm=%d" % [g_min3, str(s3["tamam"]), _n_olc(s3)["xmax"], s3["oldu"]])
	# 4) B mührü basmadan odadan çıkar: GM kapalı kalır, B GM'de takılır (ölmez).
	var s4: Dictionary = await _n_senaryo([c_a], _n21_b(0, 15, false))
	var gm4 := 1.0e9
	for o in s4["ozel"]:
		gm4 = minf(gm4, o["GecitM"])
	_kaydi("Bölüm 21 başarısızlık 4: B mühre basmadan çıkar -> GM kapalı kalır, B GM önünde durur (ölüm yok), bölüm bitmez",
		not s4["bitti_ham"] and s4["oldu"] == 0 and gm4 > 279.0 and not _n_var_mi(s4, "PlakaM_f") and _n_olc(s4)["xmax"] > 600.0 and _n_olc(s4)["xmax"] < 627.0,
		"GM en küçük y=%.0f (kapalı 280), mühür fiziksel basıldı=%s, B en büyük x=%.0f (GM sol yüz 640-14=626), adımlar=%s" % [gm4, str(_n_var_mi(s4, "PlakaM_f")), _n_olc(s4)["xmax"], str(s4["tamam"])])
	# 5) B çok geç gelir (fitil bitmiş, G kapalı): B G önünde takılır, mühre ulaşamaz (T gerekir).
	var s5: Dictionary = await _n_senaryo([c_a], _n21_b(340))
	_kaydi("Bölüm 21 başarısızlık 5: B fitil bittikten sonra (340 kare geç) gelir -> G kapalı, B odaya giremez, mühür basılmaz",
		not s5["bitti_ham"] and s5["oldu"] == 0 and not _n_var_mi(s5, "PlakaM_f") and s5["tamam"].has(false),
		"adımlar=%s, ölüm=%d, mühür basıldı=%s, B en büyük x=%.0f" % [str(s5["tamam"]), s5["oldu"], str(_n_var_mi(s5, "PlakaM_f")), _n_olc(s5)["xmax"]])
	# 6) doğru klonlar ama oyuncu LazerA'ya beklemeden yürür: ölür.
	var s6: Dictionary = await _n_senaryo(kay, _n21_o(false))
	_kaydi("Bölüm 21 başarısızlık 6: A PlakaA'ya varmadan oyuncu LazerA'ya yürür -> ölür (ışın görünür, bekleyince geçer)",
		s6["oldu"] > 0 and not s6["bitti_ham"] and _n_son(s6).x > 480.0 and _n_son(s6).x < 520.0,
		"ölüm=%d, son (%.0f,%.0f)" % [s6["oldu"], _n_son(s6).x, _n_son(s6).y])
	# 7) B geç PlakaB'ye varır, oyuncu LazerB'de beklemeden yürür: ölür.
	var b_gec: Array = (await _n_senaryo([c_a], _n21_b(260)))["kayit"]
	var s7: Dictionary = await _n_senaryo([c_a, b_gec], _n21_o(true, false))
	_kaydi("Bölüm 21 başarısızlık 7: B 260 kare geç PlakaB'ye varır, oyuncu LazerB'de beklemeden yürür -> ölür",
		s7["oldu"] > 0 and not s7["bitti_ham"], "ölüm=%d, son (%.0f,%.0f)" % [s7["oldu"], _n_son(s7).x, _n_son(s7).y])
	# 8) B PlakaB'den hemen ayrılır: ışın yeniden yanar, oyuncu LazerB'de bekler, bitiremez.
	var b_erken: Array = (await _n_senaryo([c_a], _n21_b(0, 0) + [_b13_a(1, Callable(), 20)]))["kayit"]
	# Oyuncu LazerB önüne geldikten 80 kare sonra bakar (B çoktan ayrılmış): ışın açık kalır. (Hemen önünde bekleyen oyuncu
	# B'nin ~16 karelik basışında 8 karede geçebilir; bu kayıt hatası değil, ışını izleyen oyuncunun hakkıdır.)
	var o_gec: Array = [_b13_a(1, _b4_x_ge(480.0), 200), _b13_a(0, _n_kapali("LazerA"), 400), _b13_a(1, _b4_x_ge(850.0), 300),
		_b13_a(0, Callable(), 80), _b13_a(0, _n_kapali("LazerB"), 200), _b13_a(1, _b4_bitti_k(), 300)]
	var s8: Dictionary = await _n_senaryo([c_a, b_erken], o_gec)
	_kaydi("Bölüm 21 başarısızlık 8: B PlakaB'den hemen ayrılır -> LazerB tekrar yanar, oyuncu bitiremez (ışın hiç sönmez; sabırsız oyuncu ölür)",
		not s8["bitti_ham"] and s8["tamam"].has(false),
		"bitti=%s, ölüm=%d, adımlar=%s, son (%.0f,%.0f), B klon son (%.0f,%.0f)" % [s8["bitti_ham"], s8["oldu"], str(s8["tamam"]), _n_son(s8).x, _n_son(s8).y, _n_klon_son(s8, 1).x, _n_klon_son(s8, 1).y])
	# 9) A PlakaA'dan erken ayrılır: oyuncu LazerA'da bekler, bitiremez.
	var a_erken: Array = (await _n_senaryo([], _n21_a(0, 0) + [_b13_a(-1, Callable(), 6)]))["kayit"]
	var b_a: Array = (await _n_senaryo([a_erken], _n21_b()))["kayit"]
	var s9: Dictionary = await _n_senaryo([a_erken, b_a], _n21_o())
	_kaydi("Bölüm 21 başarısızlık 9: A PlakaA'yı hemen bırakır (sola kayar) -> LazerA yeniden yanar, oyuncu bitiremez (ölür ya da bekler)",
		not s9["bitti_ham"], "bitti=%s, ölüm=%d, adımlar=%s, son (%.0f,%.0f)" % [s9["bitti_ham"], s9["oldu"], str(s9["tamam"]), _n_son(s9).x, _n_son(s9).y])
	# 10) rafta yanlışlıkla S (B kuyuya düşer, dönüş yok).
	var b_s: Array = [_b13_a(-1, _b4_x_le(196.0), 120), _b13_a(0, _n_gecit_ust("GecitG", 232.0), 500), _b13_a(1, _b4_x_ge(380.0), 100),
		_b13_a(0, Callable(), 60, false, true)]
	var s10: Dictionary = await _n_senaryo([c_a], b_s)
	_kaydi("Bölüm 21 başarısızlık 10: B rafta S'ye basar -> kuyuya düşer, geri çıkamaz (dönüşsüz)",
		not s10["bitti_ham"] and s10["oldu"] == 0 and _n_son(s10).y > 560.0, "son (%.0f,%.0f)" % [_n_son(s10).x, _n_son(s10).y])
	_kayitlar().sifirla()
	paused = false


func _test_b21_atlanamaz() -> void:
	aktif_bolum = BOLUM_21
	var ayr: Array = []
	var hepsi := true
	# Kuyudan çıkış yok (220 px): kuyu içinde beş x'te dikey zıplama.
	for x in [150.0, 250.0, 380.0, 500.0, 580.0]:
		var sa: Dictionary = await _n_senaryo([], _n_spam(0.0, 8), _n_yerlestir(Vector2(x, 576)))
		hepsi = hepsi and _n_olc(sa)["ayak"] > 440.0
		ayr.append("kuyu x=%.0f dikey zıplama: en yüksek ayak y=%.1f (F2 yüzeyi 380, kuyu tavanı 420)" % [x, _n_olc(sa)["ayak"]])
	# Kuyudan yana zıplayarak çıkış denemesi (rafın altı).
	for yon in [-1.0, 1.0]:
		var sk: Dictionary = await _n_senaryo([], _n_spam(yon, 14), _n_yerlestir(Vector2(380, 576)))
		hepsi = hepsi and _n_olc(sk)["ayak"] > 440.0 and _n_olc(sk)["ymax"] > 560.0
		ayr.append("kuyuda yön=%.0f + zıpla spam: en yüksek ayak y=%.1f" % [yon, _n_olc(sk)["ayak"]])
	# ZP'ye basan oyuncu (A yolu) kuyudan çıkamaz, G'ye dönemez.
	var sz: Dictionary = await _n_senaryo([], _n21_a(0, 0) + _n_spam(-1.0, 10))
	hepsi = hepsi and _n_son(sz).y > 540.0 and not sz["bitti_ham"]
	ayr.append("fitil koşusu tek başına: A yolundan sonra sol+zıpla spam, son (%.0f,%.0f) (kuyuda)" % [_n_son(sz).x, _n_son(sz).y])
	# G kapalıyken (ZP/M basılı değil): başlangıçtan sol+zıpla spam odaya girmez.
	var sg: Dictionary = await _n_senaryo([], _n_spam(-1.0, 14))
	hepsi = hepsi and _n_olc(sg)["xmin"] >= 192.0 and sg["oldu"] == 0 and not sg["bitti_ham"] and not _n_var_mi(sg, "PlakaM_f")
	ayr.append("G kapalı, sol+zıpla spam: en küçük x=%.0f (G sağ yüz 180+14=194), baş y=%.1f (tavan 180), mühür basıldı=%s" % [_n_olc(sg)["xmin"], _n_olc(sg)["ayak"] - 48.0, str(_n_var_mi(sg, "PlakaM_f"))])
	# GM kapalı (mühür yok): GM önünden sağ+zıpla spam geçilmez.
	var sm: Dictionary = await _n_senaryo([], _n_spam(1.0, 12), _n_yerlestir(Vector2(590, 356)))
	hepsi = hepsi and _n_olc(sm)["xmax"] <= 627.0 and not sm["bitti_ham"] and sm["oldu"] == 0
	ayr.append("GM kapalı: en büyük x=%.0f (sol yüz 640-14=626), baş y=%.1f" % [_n_olc(sm)["xmax"], _n_olc(sm)["ayak"] - 48.0])
	# LazerA zıplayarak (A yokken).
	var sl: Dictionary = await _n_senaryo([], _n_spam(1.0, 10), _n_yerlestir(Vector2(440, 356)))
	hepsi = hepsi and sl["oldu"] > 0 and _n_olc(sl)["xmax"] < 520.0 and not sl["bitti_ham"]
	ayr.append("LazerA zıplayarak: ölüm=%d, en büyük x=%.0f (ışın 517..523, gövde girişi 503)" % [sl["oldu"], _n_olc(sl)["xmax"]])
	# LazerB zıplayarak.
	var sb: Dictionary = await _n_senaryo([], _n_spam(1.0, 12), _n_yerlestir(Vector2(850, 356)))
	hepsi = hepsi and sb["oldu"] > 0 and _n_olc(sb)["xmax"] < 900.0 and not sb["bitti_ham"]
	ayr.append("LazerB zıplayarak: ölüm=%d, en büyük x=%.0f (ışın 900..906, gövde girişi 886)" % [sb["oldu"], _n_olc(sb)["xmax"]])
	# Tavan: F2 dikey zıplama başı tavana (180) ulaşmaz.
	var st: Dictionary = await _n_senaryo([], _n_spam(0.0, 6), _n_yerlestir(Vector2(800, 356)))
	hepsi = hepsi and _n_olc(st)["ayak"] - 48.0 > 180.0
	ayr.append("F2 dikey zıplama (x=800): en yüksek baş y=%.1f (tavan 180)" % (_n_olc(st)["ayak"] - 48.0))
	# Mühür/fitil kazara basılmaz: G önüne gidip raf üstünden sağa yürüyüş.
	var sy: Dictionary = await _n_senaryo([], [_b13_a(-1, _b4_x_le(196.0), 100), _b13_a(0, Callable(), 10), _b13_a(1, _b4_x_ge(500.0), 200), _b13_a(0, Callable(), 5)])
	hepsi = hepsi and not _n_var_mi(sy, "PlakaM_f") and not _n_var_mi(sy, "PlakaZ_f")
	ayr.append("F2 yürüyüşü (G önüne, raf üstünden sağa): mühür/fitil kazara basıldı=%s/%s (basılmamalı)" % [str(_n_var_mi(sy, "PlakaM_f")), str(_n_var_mi(sy, "PlakaZ_f"))])
	# Raf dışında S etkisiz: DosemeSol ve DosemeSag üstünde.
	var dis: Array = []
	for x in [60.0, 200.0, 300.0, 460.0, 560.0, 800.0, 1000.0]:
		var ss: Dictionary = await _n_senaryo([], [_b13_a(0, Callable(), 3, false, true), _b13_a(0, Callable(), 45)], _n_yerlestir(Vector2(x, 356)))
		if _n_son(ss).y > 400.0:
			dis.append(int(x))
	hepsi = hepsi and dis.is_empty()
	ayr.append("rafın dışında S (x=60,200,300,460,560,800,1000): kuyuya inen=%s (boş beklenir)" % str(dis))
	_kaydi("Bölüm 21 atlanamazlık (kuyudan çıkış, odaya G'siz giriş, GM, LazerA/LazerB zıplayarak, tavan, S raf dışı, kazara plaka)", hepsi, "; ".join(ayr))
	_kayitlar().sifirla()
	paused = false


func _test_b21_kisayol() -> void:
	aktif_bolum = BOLUM_21
	var kay: Array = await _n21_kayitlar()
	var c_a: Array = kay[0]
	var c_b: Array = kay[1]
	var ayr: Array = []
	var hepsi := true
	# Oyuncu stratejileri (fitilci / mühürcü olarak kendisi dahil).
	var a_oyuncu: Array = _n21_a(0, 0) + [_b13_a(1, Callable(), 100)]
	var b_oyuncu: Array = _n21_b(0, 0) + [_b13_a(1, Callable(), 200)]
	var st: Array = [_n21_o(), _n21_o(false), _n21_o(true, false), [_b13_a(1, Callable(), 600)], _n_spam(1.0, 20),
		[_b13_a(0, Callable(), 60), _b13_a(1, Callable(), 400)], a_oyuncu, b_oyuncu]
	# 1) klonsuz
	var kb: Array = []
	for i in range(st.size()):
		if await _n_bitirir([], st[i]):
			kb.append(i)
	hepsi = hepsi and kb.is_empty()
	ayr.append("klonsuz x %d strateji (oyuncu fitilci/mühürcü dahil): bitiren=%s" % [st.size(), str(kb)])
	# 2) tek klon rolleri.
	var b_kor: Array = (await _n_senaryo([], _n21_b()))["kayit"]
	var naif: Array = (await _n_senaryo([], _n21_a_naif()))["kayit"]
	var a_zpsiz: Array = (await _n_senaryo([], _n21_a(0, 15, false)))["kayit"]
	var a_kor: Array = (await _n_senaryo([], _n21_a_kor()))["kayit"]
	var tekler: Array = [c_a, b_kor, naif, a_zpsiz, a_kor, c_b]
	var tek_ad: Array = ["A", "B(kör)", "naif(ZP'de kalan)", "A(ZP'siz)", "A'(kör mühürcü)", "B(A ile kaydedilmiş)"]
	var biten: Array = []
	for i in range(tekler.size()):
		for j in range(st.size()):
			if await _n_bitirir([tekler[i]], st[j]):
				biten.append("%s/%d" % [tek_ad[i], j])
	hepsi = hepsi and biten.is_empty()
	ayr.append("tek klon (%d rol x %d oyuncu stratejisi): bitiren=%s" % [tekler.size(), st.size(), str(biten)])
	# 3) iki klon: çözüm ve kör eşdeğer bitirir; naif / aynı rol / eksik rol bitirmez.
	var b_naif: Array = (await _n_senaryo([naif], _n21_b()))["kayit"]
	var b_fitilci: Array = (await _n_senaryo([a_kor], _n21_a()))["kayit"]
	var iki: Array = [["A+B", [c_a, c_b], true], ["B+A", [c_b, c_a], true], ["A'(kör mühürcü, LazerA'da ölerek kaydedilir)+B_fitilci", [a_kor, b_fitilci], false],
		["A+A", [c_a, c_a], false], ["B+B", [c_b, c_b], false], ["naif+B", [naif, b_naif], false], ["naif+A", [naif, c_a], false],
		["A(ZP'siz)+B", [a_zpsiz, c_b], false], ["A+B(kör)", [c_a, b_kor], false]]
	var iki_bozuk: Array = []
	for k in iki:
		var bit: bool = await _n_bitirir(k[1], _n21_o())
		if bit != k[2]:
			iki_bozuk.append("%s bitti=%s (beklenen %s)" % [k[0], str(bit), str(k[2])])
	hepsi = hepsi and iki_bozuk.is_empty()
	ayr.append("iki klon kümeleri (%d): beklentiyle uyuşmayan=%s" % [iki.size(), str(iki_bozuk)])
	# 4) min klon 2 kanıtı: PlakaA ve PlakaB aynı anda basılı iken oyuncu LazerB'yi geçer.
	var tam: Dictionary = await _n_senaryo(kay, _n21_o())
	var f_ab := -1
	for f in range(tam["ozel"].size()):
		var o: Dictionary = tam["ozel"][f]
		if o["PlakaA"] and o["PlakaB"] and f_ab < 0:
			f_ab = f
	var f_lb := -1
	for f in range(tam["iz"].size()):
		if tam["iz"][f].x >= 886.0 and f_lb < 0:
			f_lb = f
	var ok4: bool = tam["bitti_ham"] and f_ab >= 0 and f_lb > f_ab
	hepsi = hepsi and ok4
	ayr.append("min klon 2: bitti=%s, PlakaA+PlakaB birlikte basılı ilk kare=%d, oyuncu LazerB ışınına (x>=886) kare %d'de varır" % [tam["bitti_ham"], f_ab, f_lb])
	# 5) S ile yeni iniş: F2 zemininde S -> yalnız raf bölgesinde kuyuya iner.
	var inen: Array = []
	for x in range(40, 1100, 40):
		var ss: Dictionary = await _n_senaryo([], [_b13_a(0, Callable(), 3, false, true), _b13_a(0, Callable(), 45)], _n_yerlestir(Vector2(float(x), 356)))
		if _n_son(ss).y > 430.0:
			inen.append(x)
	var inen_ok := not inen.is_empty()
	for x in inen:
		inen_ok = inen_ok and x >= 320 and x <= 440
	hepsi = hepsi and inen_ok
	ayr.append("F2 zeminde S (x=40..1080, 40 px): kuyuya inen=%s (yalnız raf 320..440 içinde olmalı)" % str(inen))
	_kaydi("Bölüm 21 kısayol taraması (klonsuz, 1 klon x 6 rol, 2 klon kümeleri, min klon 2, S inişleri)", hepsi, " || ".join(ayr))
	_kayitlar().sifirla()
	paused = false


func _test_b21_pencereler() -> void:
	aktif_bolum = BOLUM_21
	var kay: Array = await _n21_kayitlar()
	var ayr: Array = []
	var hepsi := true
	var tam: Dictionary = await _n_senaryo(kay, _n21_o())
	var s_a: Dictionary = await _n_senaryo([], _n21_a())
	var s_b: Dictionary = await _n_senaryo([kay[0]], _n21_b())
	ayr.append("tur kareleri: A %d, B %d, oyuncu %d (<=600, pay %d; taslak ~180/285/295)" % [s_a["kare"], s_b["kare"], tam["kare"], 600 - maxi(maxi(s_a["kare"], s_b["kare"]), tam["kare"])])
	hepsi = hepsi and tam["bitti_ham"] and s_a["kare"] <= 600 and s_b["kare"] <= 600 and tam["kare"] <= 600
	# A turu: kuyuya düşüş ve iniş x'i (adım 1 = S ile iniş), ZP/PlakaA kareleri.
	var f_s0: int = s_a["baslangic"][1]
	var f_s1: int = s_a["baslangic"][2]
	var f_a_zp := _n_ilk(s_a, "PlakaZ", true)
	var f_a_pa := _n_ilk(s_a, "PlakaA", true)
	ayr.append("A: raf ortası (S başı) kare=%d x=%.0f, kuyu zeminine iniş %d kare sonra x=%.0f (taslak ~34), ZP basış kare=%d (~96), PlakaA basış kare=%d (~157)" % [
		f_s0, s_a["iz"][f_s0].x, f_s1 - f_s0, s_a["iz"][mini(f_s1, s_a["iz"].size() - 1)].x, f_a_zp, f_a_pa])
	hepsi = hepsi and f_a_zp > f_s1 and f_a_pa > f_a_zp and f_s1 - f_s0 > 20
	# B turu (A klon): W1 G açıklığı, B'nin G önünde bekleme süresi, mühür, GM, LazerA varışı.
	var f_zp_b := _n_ilk(s_b, "PlakaZ", true)
	var f_g48 := -1
	var f_gtam := -1
	for f in range(s_b["ozel"].size()):
		var gy: float = s_b["ozel"][f]["GecitG"]
		if f_g48 < 0 and gy <= 232.0:
			f_g48 = f
		if f_gtam < 0 and gy <= 180.5:
			f_gtam = f
	var f_b_g: int = -1
	for f in range(s_b["iz"].size()):
		if s_b["iz"][f].x <= 196.0:
			f_b_g = f
			break
	var f_m := _n_ilk(s_b, "PlakaM", true)
	var f_gm48 := -1
	for f in range(s_b["ozel"].size()):
		if s_b["ozel"][f]["GecitM"] <= 232.0:
			f_gm48 = f
			break
	var f_b_la: int = _n_x_kare(s_b["iz"], 500.0)
	var f_a_pa_b := _n_ilk(s_b, "PlakaA", true)
	var f_b_gm: int = _n_x_kare(s_b["iz"], 612.0)
	var f_b_pb := _n_ilk(s_b, "PlakaB", true)
	ayr.append("W1 B G önüne (x<=196) kare=%d, ZP basılı kare=%d, G>=48 px açık kare=%d (+%d), G tam açık=%d => B bekleme %d kare (taslak ~110)" % [f_b_g, f_zp_b, f_g48, f_g48 - f_zp_b, f_gtam, f_g48 - f_b_g])
	hepsi = hepsi and f_b_g >= 0 and f_zp_b >= 0 and f_g48 > f_zp_b and f_g48 >= f_b_g
	ayr.append("W5 mühür kilit kare=%d, GM>=48 px açık kare=%d (+%d), B GM'yi geçer (x>=612) kare=%d => GM payı %d kare (taslak ~78)" % [f_m, f_gm48, f_gm48 - f_m, f_b_gm, f_b_gm - f_gm48])
	hepsi = hepsi and f_m > f_g48 and f_gm48 > f_m and f_b_gm - f_gm48 >= 10
	ayr.append("W4 A PlakaA'ya basış kare=%d, B LazerA'ya (x>=500) varış kare=%d => pay %d kare (taslak ~54); B PlakaB kare=%d" % [f_a_pa_b, f_b_la, f_b_la - f_a_pa_b, f_b_pb])
	hepsi = hepsi and f_a_pa_b >= 0 and f_b_la - f_a_pa_b >= 10 and f_b_pb > f_b_la
	# Oyuncu turu: LazerA ve LazerB önünde bekleme.
	var f_o_la: int = _n_x_kare(tam["iz"], 480.0)
	var f_la_kapali := _n_ilk(tam, "LazerA", false, maxi(f_o_la, 0))
	var f_o_lb: int = _n_x_kare(tam["iz"], 850.0)
	var f_lb_kapali := _n_ilk(tam, "LazerB", false, maxi(f_o_lb, 0))
	var f_o_gm: int = _n_x_kare(tam["iz"], 612.0)
	ayr.append("W6 oyuncu LazerA önüne (x>=480) kare=%d, ışın söner kare=%d => bekleme %d (taslak ~100); GM önüne kare=%d (GM açılalı %d kare); LazerB önüne (x>=850) kare=%d, ışın söner kare=%d => bekleme %d" % [
		f_o_la, f_la_kapali, f_la_kapali - f_o_la, f_o_gm, f_o_gm - f_gm48, f_o_lb, f_lb_kapali, f_lb_kapali - f_o_lb])
	hepsi = hepsi and f_o_la >= 0 and f_la_kapali > f_o_la and f_lb_kapali >= f_o_lb and f_o_gm > f_gm48
	# W1 taraması: B başta bekleme (G önünde bekler; fitil süresi dolmadan gelmeli) -> başarılı aralık.
	var vb: Array = []
	for d in range(0, 361, 30):
		vb.append(d)
	var okb: Array = []
	for v in vb:
		var b2: Array = (await _n_senaryo([kay[0]], _n21_b(v)))["kayit"]
		var sb2: Dictionary = await _n_senaryo([kay[0], b2], _n21_o())
		okb.append(sb2["bitti_ham"] and sb2["oldu"] == 0 and sb2["kare"] <= 600)
	ayr.append("W1b B başta bekleme (kare): başarılı %s (üst sınır fitil süresi: G kapanmadan gelmeli)" % _n_ar(vb, okb))
	hepsi = hepsi and _n_pen(vb, okb, 0) and _n_pen(vb, okb, 90) and _n_pen(vb, okb, 360, false)
	# W2 taraması: A başta bekleme (B G önünde daha uzun bekler).
	var vg: Array = []
	for d in range(0, 241, 30):
		vg.append(d)
	var okg: Array = []
	for v in vg:
		var a2: Array = (await _n_senaryo([], _n21_a(v)))["kayit"]
		var sg2: Dictionary = await _n_senaryo([a2], _n21_b())
		var so2: Dictionary = await _n_senaryo([a2, sg2["kayit"]], _n21_o())
		okg.append(not sg2["tamam"].has(false) and sg2["oldu"] == 0 and sg2["kare"] <= 600 and so2["bitti_ham"] and so2["oldu"] == 0)
	ayr.append("W2 A başta bekleme (kare): çözüm bitti %s (alt/üst sınır tur kare sınırı)" % _n_ar(vg, okg))
	hepsi = hepsi and _n_pen(vg, okg, 0) and _n_pen(vg, okg, 60)
	# W3: S penceresi (raf üstünde kuyuya iner) ve dikişler.
	var vs: Array = []
	for x in range(316, 453, 4):
		vs.append(x)
	var oks: Array = []
	for v in vs:
		var ss: Dictionary = await _n_senaryo([], [_b13_a(0, Callable(), 3, false, true), _b13_a(0, Callable(), 48)], _n_yerlestir(Vector2(float(v), 356)))
		oks.append(_n_son(ss).y > 430.0)
	ayr.append("W3 S ile kuyuya iniş c aralığı: %s (taslak 346..414 güvenli; tam raf 334..426); genişlik ~%d px" % [_n_ar(vs, oks), _n_en_buyuk(vs, oks) - _n_en_kucuk(vs, oks) + 4])
	hepsi = hepsi and _n_pen(vs, oks, 380) and _n_pen(vs, oks, 316, false) and _n_pen(vs, oks, 452, false) and _n_en_buyuk(vs, oks) - _n_en_kucuk(vs, oks) >= 60
	# W7: PlakaB tutucusu sağa ayrılırsa LazerB'de ölür (kaçış); PlakaA tutucusu kuyuda sola/sağa.
	var w7: Array = []
	var w7_ok := true
	for ek in [0, 1, 2, 3]:
		var s7: Dictionary = await _n_senaryo([], [_b13_a(0, Callable(), ek), _b13_a(1, Callable(), 80)], _n_yerlestir(Vector2(790, 356)))
		var son_f7 := -1
		for f in range(s7["ozel"].size()):
			if s7["ozel"][f].get("PlakaB_f", false):
				son_f7 = f
		w7.append("duraksama %d: ölüm=%d, plakadan ayrılış->ölüm %d kare" % [ek, s7["oldu"], s7["iz"].size() - son_f7])
		w7_ok = w7_ok and s7["oldu"] > 0
	hepsi = hepsi and w7_ok
	ayr.append("W7 PlakaB tutucusu sağa ayrılırsa LazerB'de ölür (taslak ~10 kare): %s" % "; ".join(w7))
	var s8: Dictionary = await _n_senaryo([], [_b13_a(1, Callable(), 12)], _n_yerlestir(Vector2(500, 576)))
	var s8b: Dictionary = await _n_senaryo([], [_b13_a(1, Callable(), 20)], _n_yerlestir(Vector2(500, 576)))
	ayr.append("W8 PlakaA kuyuda: PlakaA'dan ayrılan kuyuda kalır (ölüm %d/%d, y=%.0f/%.0f; kaçış yolu yok)" % [s8["oldu"], s8b["oldu"], _n_son(s8).y, _n_son(s8b).y])
	hepsi = hepsi and _n_son(s8).y > 560.0 and _n_son(s8b).y > 560.0
	_kaydi("Bölüm 21 zamanlama payları (tur kareleri, kuyu inişi, W1 G/B bekleme+tarama, W2 A gecikmesi, W3 S penceresi, W4 LazerA, W5 mühür/GM, W6 oyuncu bekleme, W7 tutucu kaçışı)", hepsi, " || ".join(ayr))
	_kayitlar().sifirla()
	paused = false


func _test_b21_klon_fark() -> void:
	aktif_bolum = BOLUM_21
	var kay: Array = await _n21_kayitlar()
	var ayr: Array = []
	var hepsi := true
	for k in [["A", [], _n21_a()], ["B", [kay[0]], _n21_b()], ["Oyuncu", kay, _n21_o()]]:
		var r: Dictionary = await _n_klon_fark(k[1], k[2])
		ayr.append("%s canlı/klon en büyük konum farkı %.2f px (ilk sapma kare %d, x=%.0f)" % [k[0], r["fark"], r["ilk"], r["ilk_x"]])
		hepsi = hepsi and r["fark"] <= 0.5
	_kaydi("Bölüm 21 ölçüm: canlı kayıt vs klon tekrarı konum farkı (bant yok; üst sınır 0,5 px, taslak beklentisi 0)", hepsi, " || ".join(ayr))
	_kayitlar().sifirla()
	paused = false


func _test_b21_plakalar() -> void:
	aktif_bolum = BOLUM_21
	var ayr: Array = []
	var hepsi := true
	# Fitil (ZP): bırakıldıktan sonra tam 180 kare basılı kalır.
	var rz: Dictionary = await _n_tutma_olc("PlakaZ", Vector2(200, 576), 330)
	ayr.append("ZP: ilk basılı kare=%d, son fiziksel kare=%d, sonra basılı kalan=%d kare (tutma_kare 180)" % [rz["ilk_basili"], rz["son_fiziksel"], rz["kalan"]])
	hepsi = hepsi and rz["ilk_basili"] >= 0 and rz["kalan"] == 180 and not rz["sona_kadar"]
	var f_g48 := -1
	var f_kapan := -1
	for f in range(rz["ozel"].size()):
		var gy: float = rz["ozel"][f]["GecitG"]
		if f_g48 < 0 and gy <= 232.0:
			f_g48 = f
		if f_g48 >= 0 and f_kapan < 0 and gy > 232.0:
			f_kapan = f
	ayr.append("ZP: G>=48 px açık kare=%d (ZP basıştan +%d; taslak ~24), mühürsüz kapanma (G<48 px) kare=%d (bırakıştan +%d; taslak ~206)" % [f_g48, f_g48 - rz["ilk_basili"], f_kapan, f_kapan - rz["son_fiziksel"]])
	hepsi = hepsi and f_g48 >= 0 and f_kapan > f_g48
	# Mühür (M): bir kez basılınca tur sonuna kadar basılı, G ve GM hiç kapanmaz.
	var rm: Dictionary = await _n_tutma_olc("PlakaM", Vector2(80, 356), 330)
	ayr.append("M: ilk basılı kare=%d, son fiziksel kare=%d, sonra basılı kalan=%d kare (ölçüm sonuna kadar=%s)" % [rm["ilk_basili"], rm["son_fiziksel"], rm["kalan"], str(rm["sona_kadar"])])
	hepsi = hepsi and rm["ilk_basili"] >= 0 and rm["sona_kadar"] and rm["kalan"] >= 300
	var son_g: float = rm["ozel"][rm["ozel"].size() - 1]["GecitG"]
	var son_gm: float = rm["ozel"][rm["ozel"].size() - 1]["GecitM"]
	var f_acik := -1
	var tekrar := false
	for f in range(rm["ozel"].size()):
		var y: float = rm["ozel"][f]["GecitG"]
		if f_acik < 0 and y <= 180.5:
			f_acik = f
		elif f_acik >= 0 and y > 180.5:
			tekrar = true
	ayr.append("M sonrası: G y=%.0f, GM y=%.0f (açık 180), G tam açık kare=%d, G sonradan kapandı=%s" % [son_g, son_gm, f_acik, str(tekrar)])
	hepsi = hepsi and son_g <= 181.0 and son_gm <= 181.0 and f_acik >= 0 and not tekrar
	# Çözüm turunda mührü yalnız B basar; fitil bittikten sonra (k > ZP bırakış + 180 + 26) G hâlâ açık.
	var kay: Array = await _n21_kayitlar()
	var tam: Dictionary = await _n_senaryo(kay, _n21_o())
	var f_zp_son := -1
	for f in range(tam["ozel"].size()):
		if tam["ozel"][f].get("PlakaZ_f", false):
			f_zp_son = f
	var f_m := _n_ilk(tam, "PlakaM", true)
	var m_kesinti := 0
	var g_kapandi := false
	var f_gtam := -1
	for f in range(maxi(f_m, 0), tam["ozel"].size()):
		if not tam["ozel"][f]["PlakaM"]:
			m_kesinti += 1
	for f in range(tam["ozel"].size()):
		var gy2: float = tam["ozel"][f]["GecitG"]
		if f_gtam < 0 and gy2 <= 180.5:
			f_gtam = f
		elif f_gtam >= 0 and gy2 > 180.5:
			g_kapandi = true
	var fitil_bitis: int = f_zp_son + 180 + 26
	var g_fitil_sonrasi: float = tam["ozel"][mini(fitil_bitis + 20, tam["ozel"].size() - 1)]["GecitG"]
	ayr.append("çözüm turu: ZP son fiziksel kare=%d (fitil bitişi ~%d), mühür basılı kare=%d, sonra basılı olmayan=%d, G tam açık=%d, G tekrar kapandı=%s, fitil bittikten 20 kare sonra G y=%.0f, tur %d kare" % [f_zp_son, fitil_bitis, f_m, m_kesinti, f_gtam, str(g_kapandi), g_fitil_sonrasi, tam["kare"]])
	hepsi = hepsi and f_m >= 0 and m_kesinti == 0 and not g_kapandi and tam["bitti_ham"] and (tam["kare"] <= fitil_bitis or g_fitil_sonrasi <= 181.0)
	# Tur başı sıfırlama: mühür kilidi, G konumu, ZP.
	_kayitlar().sifirla()
	var bolum: Node = await _bolumu_yukle()
	var plaka_m: BasincPlakasi = bolum.get_node("PlakaM")
	var kilitli0: bool = plaka_m.kilitli
	bolum.get_node("Oyuncu").global_position = Vector2(80, 356)
	for i in range(12):
		_girdi_uygula({"yon": 0.0, "zipla": false})
		await physics_frame
	var kilitli1: bool = plaka_m.kilitli
	var eski_id := bolum.get_instance_id()
	await _r_bas()
	var yeni: Node = await _yeni_sahne_bekle(eski_id)
	var ok_t: bool = yeni != null and yeni.get_node("PlakaM").kilitli == false and yeni.get_node("PlakaM").basili_mi() == false \
		and yeni.get_node("PlakaZ").basili_mi() == false and absf(yeni.get_node("GecitG").position.y - 280.0) < 0.5 \
		and absf(yeni.get_node("GecitM").position.y - 280.0) < 0.5
	hepsi = hepsi and ok_t and not kilitli0 and kilitli1
	ayr.append("tur başı: ilk açılışta kilitli=%s, mühre basınca=%s; R sonrası yeni turda mühür kilitli=%s, G y=%.0f, GM y=%.0f (kapalı 280)" % [
		str(kilitli0), str(kilitli1), str(yeni.get_node("PlakaM").kilitli if yeni != null else "?"),
		yeni.get_node("GecitG").position.y if yeni != null else -1.0, yeni.get_node("GecitM").position.y if yeni != null else -1.0])
	_kaydi("Bölüm 21: fitil tam 180 kare, mühür tur sonuna kadar kalıcı (G ve GM kapanmaz), tur başı sıfırlama", hepsi, " || ".join(ayr))
	_kayitlar().sifirla()
	paused = false


## Oda tuzak değildir: mühre basmadan fitil bitip G kapansa da mühre basınca G yeniden açılır (VEYA) ve B çıkabilir.
func _test_b21_oda_tuzagi() -> void:
	aktif_bolum = BOLUM_21
	var kay: Array = await _n21_kayitlar()
	var tuzak: Array = [_b13_a(-1, _b4_x_le(196.0), 120), _b13_a(0, _n_gecit_ust("GecitG", 232.0), 500),
		_b13_a(-1, _b4_x_le(140.0), 60), _b13_a(0, _n21_g_kapali(), 500),
		_b13_a(-1, _n_p("PlakaM"), 100), _b13_a(0, _n_gecit_ust("GecitG", 181.0), 200),
		_b13_a(1, _b4_x_ge(330.0), 120), _b13_a(0, Callable(), 3)]
	var s: Dictionary = await _n_senaryo([kay[0]], tuzak)
	var f_acik := -1
	var f_kapali := -1
	var f_yeniden := -1
	for f in range(s["ozel"].size()):
		var gy: float = s["ozel"][f]["GecitG"]
		if f_acik < 0 and gy <= 232.0:
			f_acik = f
		elif f_acik >= 0 and f_kapali < 0 and gy >= 279.5:
			f_kapali = f
		elif f_kapali >= 0 and f_yeniden < 0 and gy <= 232.0:
			f_yeniden = f
	var cikti: bool = _n_son(s).x >= 330.0
	_kaydi("Bölüm 21 oda tuzak değil: mühre basmadan G kapanır, sonra mühre basınca G yeniden açılır ve B odadan çıkar",
		not s["tamam"].has(false) and s["oldu"] == 0 and f_acik >= 0 and f_kapali > f_acik and f_yeniden > f_kapali and cikti,
		"adımlar=%s, ölüm=%d, G>=48 px açık kare=%d, tam kapalı kare=%d (açıklıktan +%d), mühürle yeniden açık kare=%d, çıkış x=%.0f" % [
			str(s["tamam"]), s["oldu"], f_acik, f_kapali, f_kapali - f_acik, f_yeniden, _n_son(s).x])
	_kayitlar().sifirla()
	paused = false


func _test_b21_klon_siniri() -> void:
	aktif_bolum = BOLUM_21
	await _n_klon_siniri("Bölüm 21: klon sınırı (üçüncü R klon kaydetmez)", 2)


func _test_b21_kilitlenme() -> void:
	aktif_bolum = BOLUM_21
	var kay: Array = await _n21_kayitlar()
	var ayr: Array = []
	var hepsi := true
	# (a) klon hakkı bitmiş (naif: ZP'de kalan A + eksik B, 2/2): R klon kaydetmez, etiket "Klon hakkı bitti".
	var naif: Array = (await _n_senaryo([], _n21_a_naif()))["kayit"]
	var b_naif: Array = (await _n_senaryo([naif], _n21_b()))["kayit"]
	_kayitlar().sifirla()
	_kayitlar().tur_kaydet(naif.duplicate(true))
	_kayitlar().tur_kaydet(b_naif.duplicate(true))
	var bolum: Node = await _bolumu_yukle()
	var eski_id := bolum.get_instance_id()
	for i in range(5):
		_girdi_uygula({"yon": 0.0, "zipla": false})
		await physics_frame
	await _r_bas()
	var yeni: Node = await _yeni_sahne_bekle(eski_id)
	var etiket: String = bolum.bilgi.text if is_instance_valid(bolum) else ""
	var ok_a: bool = yeni == null and _kayitlar().turlar.size() == 2 and etiket.contains("Klon hakkı bitti") and etiket.contains("2/2")
	hepsi = hepsi and ok_a
	ayr.append("naif 2/2: R sonrası yeni sahne=%s, kayıtlı tur=%d, etiket=\"%s\"" % [str(yeni != null), _kayitlar().turlar.size(), etiket])
	# (b) T tuşu o durumdan çıkarır.
	var eski2: Node = current_scene
	await _t_bas()
	var yeni2: Node = await _sahne_degisimini_bekle(eski2)
	var ok_b: bool = yeni2 != null and _kayitlar().turlar.size() == 0 and _klonlar(yeni2).size() == 0 and yeni2.bilgi.text.begins_with("Tur 1 ")
	hepsi = hepsi and ok_b
	ayr.append("T tuşu: kayıt=%d, klon=%d, etiket=\"%s\"" % [_kayitlar().turlar.size(), _klonlar(yeni2).size() if yeni2 != null else -1, yeni2.bilgi.text if yeni2 != null else ""])
	# (c) Baştan başla düğmesi.
	_kayitlar().sifirla()
	_kayitlar().tur_kaydet(naif.duplicate(true))
	_kayitlar().tur_kaydet(b_naif.duplicate(true))
	var b2: Node = await _bolumu_yukle()
	var eski3: Node = current_scene
	b2.get_node("EkranButonlari/Kutu/YenidenDugmesi").pressed.emit()
	var yeni3: Node = await _sahne_degisimini_bekle(eski3)
	var ok_c: bool = yeni3 != null and _kayitlar().turlar.size() == 0 and _klonlar(yeni3).size() == 0 and yeni3.bilgi.text.begins_with("Tur 1 ")
	hepsi = hepsi and ok_c
	ayr.append("Baştan başla: kayıt=%d, klon=%d" % [_kayitlar().turlar.size(), _klonlar(yeni3).size() if yeni3 != null else -1])
	# (d) hak varken kuyuya düşen oyuncu R ile turu bitirip yeni klon kaydeder (dönüşsüz bölgeden çıkış yolu).
	_kayitlar().sifirla()
	var b3: Node = await _bolumu_yukle()
	b3.get_node("Oyuncu").global_position = Vector2(300, 576)
	for i in range(5):
		_girdi_uygula({"yon": 0.0, "zipla": false})
		await physics_frame
	var eski4 := b3.get_instance_id()
	await _r_bas()
	var yeni4: Node = await _yeni_sahne_bekle(eski4)
	var ok_d: bool = yeni4 != null and _kayitlar().turlar.size() == 1 and _klonlar(yeni4).size() == 1
	hepsi = hepsi and ok_d
	ayr.append("hak varken kuyuda R: yeni tur=%s, kayıtlı tur=%d" % [str(yeni4 != null), _kayitlar().turlar.size()])
	# (e) LazerA'ya giren oyuncu ölür, klonlar korunur, tur sayısı artmaz.
	_kayitlar().sifirla()
	_kayitlar().tur_kaydet(kay[0].duplicate(true))
	var b4: Node = await _bolumu_yukle()
	b4.get_node("Oyuncu").global_position = Vector2(440, 356)
	var sayac := [0]
	b4.get_node("Oyuncu").oyuncu_oldu.connect(func() -> void: sayac[0] += 1)
	var eski5 := b4.get_instance_id()
	await _n_kosullu(b4, [_b13_a(1, Callable(), 40)], sayac)
	var yeni5: Node = await _yeni_sahne_bekle(eski5)
	var ok_e: bool = sayac[0] > 0 and yeni5 != null and _kayitlar().turlar.size() == 1 and _klonlar(yeni5).size() == 1 and yeni5.bilgi.text.begins_with("Tur 2 ")
	hepsi = hepsi and ok_e
	ayr.append("LazerA ölümü: ölüm=%d, kayıtlı tur=%d, klon=%d, etiket=\"%s\"" % [sayac[0], _kayitlar().turlar.size(), _klonlar(yeni5).size() if yeni5 != null else -1, yeni5.bilgi.text if yeni5 != null else ""])
	# (f) klonlar plakada biter: A PlakaA'da (kuyu), B PlakaB'de (F2).
	var son: Dictionary = await _n_senaryo(kay, [_b13_a(0, Callable(), 420)])
	var pa: Vector2 = _n_klon_son(son, 0)
	var pb: Vector2 = _n_klon_son(son, 1)
	var ok_f: bool = pa.x > 476.0 and pa.x < 564.0 and pa.y > 540.0 and pb.x > 746.0 and pb.x < 834.0 and pb.y > 330.0 and pb.y < 380.0 \
		and not son["klon_oldu"][0] and not son["klon_oldu"][1]
	hepsi = hepsi and ok_f
	ayr.append("klonlar plakada biter: A (%.0f,%.0f) [PlakaA 490..550], B (%.0f,%.0f) [PlakaB 760..820]" % [pa.x, pa.y, pb.x, pb.y])
	# (g) çözüm turunda ölüm yok, bölüm biter.
	var tam: Dictionary = await _n_senaryo(kay, _n21_o())
	hepsi = hepsi and tam["bitti_ham"] and tam["oldu"] == 0
	ayr.append("çözüm turu: bitti=%s, ölüm=%d" % [str(tam["bitti_ham"]), tam["oldu"]])
	_kaydi("Bölüm 21 kilitlenme/çıkış: klon hakkı bitince T ve Baştan başla çıkışı, kuyuda R, LazerA ölümü, klon konumları", hepsi, " || ".join(ayr))
	_kayitlar().sifirla()
	paused = false


## Görünürlük: çizimsiz çarpışma/tetikleyici yok + bu bölüme özgü türler doğru nesnede.
func _test_b21_gorunurluk() -> void:
	aktif_bolum = BOLUM_21
	var r: Dictionary = await _gr_bolum_tara(BOLUM_21, 22)
	_kaydi("Bölüm 21 görünürlük: çarpışma/tetikleyici nesnelerinin hepsinin çizimi var (çizimsiz yok)",
		r["cizimsiz"].is_empty() and r["sorun"].is_empty() and r["sayi"] >= 15,
		"nesne: %d, çizimsiz: %s, sorun: %s" % [r["sayi"], str(r["cizimsiz"]), str(r["sorun"])])
	_kayitlar().sifirla()
	var b: Node = await _bolumu_yukle()
	var beklenen := {"Raf": Gorunum.Tur.TEK_YONLU, "PlakaM": Gorunum.Tur.PLAKA_MANDAL, "PlakaZ": Gorunum.Tur.PLAKA_ZAMANLI,
		"PlakaA": Gorunum.Tur.PLAKA, "PlakaB": Gorunum.Tur.PLAKA, "GecitG": Gorunum.Tur.GECIT, "GecitM": Gorunum.Tur.GECIT,
		"LazerA": Gorunum.Tur.LAZER, "LazerB": Gorunum.Tur.LAZER, "Kapi": Gorunum.Tur.KAPI,
		"Zemin": Gorunum.Tur.DUVAR, "Tavan": Gorunum.Tur.DUVAR, "DosemeSol": Gorunum.Tur.DUVAR, "DosemeSag": Gorunum.Tur.DUVAR,
		"BlokF1Sol": Gorunum.Tur.DUVAR, "BlokF1Sag": Gorunum.Tur.DUVAR}
	var sorun: Array = []
	for ad in beklenen:
		var d: Node = b.get_node_or_null(ad)
		var g: Gorunum = _gr_gorunum_bul(d) if d != null else null
		if g == null:
			sorun.append("%s: Gorunum yok" % ad)
		elif g.tur != beklenen[ad]:
			sorun.append("%s: tür %d (beklenen %d)" % [ad, int(g.tur), int(beklenen[ad])])
	_kaydi("Bölüm 21 görünürlük: her nesnenin Gorunum türü taslak §13 ile aynı (DUVAR/TEK_YONLU/PLAKA_MANDAL/PLAKA_ZAMANLI/GECIT/LAZER/KAPI)",
		sorun.is_empty(), "sorunlar: %s" % str(sorun))
	_kayitlar().sifirla()
	paused = false


func _test_b21_determinizm() -> void:
	aktif_bolum = BOLUM_21
	var kay: Array = await _n21_kayitlar()
	await _n_determinizm("Bölüm 21: determinizm (20x çözüm)", kay, _n21_o(), 20)




# ---------------------------------------------------------------- T tuşu (baştan başla) testleri

## T (bastan eylemi) tuşunu bir fizik karesi basılı tutar.
func _t_bas() -> void:
	Input.action_press("bastan")
	await physics_frame
	Input.action_release("bastan")


func _tustu_testleri() -> void:
	paused = false
	aktif_bolum = BOLUM
	# 1) T = baştan başla: klonlar silinir, tur 1; kayıt formatı değişmez.
	_kayitlar().sifirla()
	var b: Node = await _bolumu_yukle()
	for i in range(5):
		_girdi_uygula({"yon": 1.0, "zipla": false})
		await physics_frame
	_girdi_uygula({"yon": 0.0, "zipla": false})
	var eski: Node = current_scene
	await _r_bas()
	b = await _sahne_degisimini_bekle(eski)
	var once_sayi: int = _kayitlar().turlar.size()
	var klon_once: int = _klonlar(b).size()
	var oyuncu: CharacterBody2D = b.get_node("Oyuncu")
	for i in range(8):
		_girdi_uygula({"yon": 1.0, "zipla": i == 2})
		await physics_frame
	_girdi_uygula({"yon": 0.0, "zipla": false})
	var kayit_once: Array = oyuncu.kayit_girdileri.duplicate(true)
	eski = current_scene
	await _t_bas()
	# T'nin bastığı karede oyuncu hâlâ ağaçtaysa: kayıt formatı aynı ve T girdisi eklenmemiş.
	var kayit_sonra: Array = oyuncu.kayit_girdileri.duplicate(true) if is_instance_valid(oyuncu) else kayit_once
	var yeni: Node = await _sahne_degisimini_bekle(eski)
	var bos: bool = _kayitlar().turlar.size() == 0
	var klon_say: int = _klonlar(yeni).size() if yeni != null else -1
	var yazi: String = yeni.bilgi.text if yeni != null else ""
	var etiket_ok: bool = yazi.begins_with("Tur 1 ") and yazi.contains("Klon: 0/") and yazi.contains("T: baştan başla")
	_kaydi("T tuşu: baştan başla (klonlar silinir, tur 1)",
		once_sayi == 1 and klon_once == 1 and yeni != null and bos and klon_say == 0 and etiket_ok,
		"öncesi: kayıt %d, klon %d; sonrası: Kayitlar boş: %s, klon: %d, etiket: \"%s\"" % [once_sayi, klon_once, bos, klon_say, yazi])
	# 2) Kayıt formatı {yon, zipla, asagi}; T girdisi kayda girmez.
	var format_ok := not kayit_once.is_empty() and kayit_sonra.size() <= kayit_once.size() + 1
	for g in kayit_sonra:
		format_ok = format_ok and g is Dictionary and g.size() == 3 and g.has("yon") and g.has("zipla") and g.has("asagi")
	_kaydi("T tuşu: kayıt formatı değişmez, T girdisi kayda girmez", format_ok,
		"önceki kayıt: %d kare, T karesinden sonra: %d kare, örnek: %s" % [kayit_once.size(), kayit_sonra.size(), str(kayit_sonra[0]) if not kayit_sonra.is_empty() else "-"])
	# 3) Sonuç ekranı açıkken T etkisizdir (kayıtlar ve sahne korunur).
	var r: Dictionary = await _ar_bitir(BOLUM, [30])
	var bolum: Node = r["bolum"]
	var sonuc_var: bool = r["sonuc"] != null and r["bitti"]
	var sahne_once: Node = current_scene
	await _t_bas()
	for i in range(6):
		await physics_frame
	var etkisiz: bool = current_scene == sahne_once and is_instance_valid(bolum) and _kayitlar().turlar.size() == 1 and is_instance_valid(r["sonuc"])
	_kaydi("T tuşu: sonuç ekranı açıkken etkisiz", sonuc_var and etkisiz,
		"sonuç ekranı: %s, sahne aynı: %s, Kayitlar: %d klon" % [sonuc_var, current_scene == sahne_once, _kayitlar().turlar.size()])
	paused = false
	_kayitlar().sifirla()



# ---------------------------------------------------------------- görünürlük testleri (--gorunurluk)
# Genel tarama: sabit koordinat/nesne adı yok; her bölümün tüm CollisionShape2D'leri gezilir.
# Gorunum düğümü headless'ta da kurulur (_ready); çizim yapılmaz, bu yüzden düğümün VARLIĞI,
# `tur` ve `alan` değerleri doğrulanır.

## Çarpışma şekli oyuncuya/klona ya da çalışma anında kurulan SinirDuvarlari'na mı ait?
func _gr_haric_mi(d: Node, kok: Node) -> bool:
	var n: Node = d
	while n != null and n != kok:
		if n.name == "SinirDuvarlari" or n.name == "Oyuncu" or n.get("klon") != null:
			return true
		n = n.get_parent()
	return false


## Düğümün altında çizim yapan bir Gorunum var mı? (ilk bulunan; yoksa null)
func _gr_gorunum_bul(d: Node) -> Gorunum:
	for c in d.get_children():
		if c is Gorunum and c.name == "Gorunum":
			return c
	return null


## Nesnenin kendi görünür çizimi (Polygon2D/ColorRect/Sprite2D, visible=true) var mı?
func _gr_kendi_cizim(d: Node) -> bool:
	for c in d.get_children():
		if (c is Polygon2D or c is ColorRect or c is Sprite2D) and c.visible:
			return true
	return false


func _gr_dikdortgen(sekil: CollisionShape2D) -> Rect2:
	if sekil.shape is RectangleShape2D:
		var b: Vector2 = sekil.shape.size
		return Rect2(sekil.position - b / 2.0, b)
	return Rect2()


## Tek bir bölümü tarar; {sayi, cizimsiz: [], sorun: []} döner.
func _gr_bolum_tara(yol: String, no: int) -> Dictionary:
	var sonuc := {"sayi": 0, "cizimsiz": [], "sorun": []}
	_kayitlar().sifirla()
	var sahne: Node = (load(yol) as PackedScene).instantiate()
	root.add_child(sahne)
	await process_frame
	await physics_frame
	var sekiller: Array = sahne.find_children("*", "CollisionShape2D", true, false)
	for s in sekiller:
		var sekil: CollisionShape2D = s
		var sahip: Node = sekil.get_parent()
		if not (sahip is CollisionObject2D):
			continue
		if _gr_haric_mi(sahip, sahne):
			continue
		sonuc["sayi"] += 1
		var ad: String = "B%d/%s" % [no, str(sahne.get_path_to(sahip))]
		# Önce şeklin sahibinde, sonra (Salter/SolAlan gibi alt alanlar için) atalarında Gorunum ara.
		var gorunum: Gorunum = null
		var gsahip: Node = sahip
		while gsahip != null and gsahip != sahne:
			gorunum = _gr_gorunum_bul(gsahip)
			if gorunum != null:
				break
			gsahip = gsahip.get_parent()
		if gorunum != null:
			# Tür geçerli bir Gorunum.Tur üyesi olmalı.
			if not Gorunum.Tur.values().has(int(gorunum.tur)):
				sonuc["sorun"].append(ad + " (geçersiz tür)")
			# Alan verilmişse çarpışma şeklini kapsamalı (boş alan = türün varsayılan çizimi).
			if gorunum.alan.size != Vector2.ZERO:
				var r := _gr_dikdortgen(sekil)
				if r.size != Vector2.ZERO:
					# Şekli Gorunum'un yerel uzayına çevir (aynı düğümse doğrudan).
					var a: Vector2 = gorunum.to_local(sekil.global_position) - r.size / 2.0
					var r2 := Rect2(a, r.size)
					if not gorunum.alan.grow(1.0).encloses(r2):
						sonuc["sorun"].append("%s (alan şekli kapsamıyor: alan %s, şekil %s)" % [ad, str(gorunum.alan), str(r2)])
			# Plaka kipi ile Gorunum türü uyumlu olmalı.
			if gsahip is BasincPlakasi:
				var bp: BasincPlakasi = gsahip
				var beklenen := Gorunum.Tur.PLAKA
				if bp.mandal:
					beklenen = Gorunum.Tur.PLAKA_MANDAL
				elif bp.tutma_kare > 0:
					beklenen = Gorunum.Tur.PLAKA_ZAMANLI
				if gorunum.tur != beklenen:
					sonuc["sorun"].append("%s (plaka türü uyumsuz)" % ad)
			continue
		# Gorunum yok: nesnenin (veya atalarının) kendi görünür çizimi var mı?
		var kendi := false
		var n: Node = sahip
		while n != null and n != sahne:
			if _gr_kendi_cizim(n):
				kendi = true
				break
			n = n.get_parent()
		if not kendi:
			sonuc["cizimsiz"].append(ad)
	sahne.queue_free()
	await process_frame
	return sonuc


func _gorunurluk_testleri() -> void:
	paused = false
	var kayitlar: Array = BolumListesi.liste()
	var n: int = kayitlar.size()

	# --- 1) Her bölümde çizimsiz çarpışma/tetikleyici yok
	var toplam := 0
	var tum_cizimsiz: Array = []
	var tum_sorun: Array = []
	for i in range(n):
		var yol: String = kayitlar[i]["yol"]
		if not ResourceLoader.exists(yol):
			tum_sorun.append("B%d: sahne yok (%s)" % [i + 1, yol])
			continue
		var r: Dictionary = await _gr_bolum_tara(yol, i + 1)
		toplam += r["sayi"]
		tum_cizimsiz.append_array(r["cizimsiz"])
		tum_sorun.append_array(r["sorun"])
		_kaydi("Görünürlük: %s çarpışma/tetikleyici nesnelerinin hepsinin çizimi var" % yol.get_file().get_basename(),
			r["cizimsiz"].is_empty() and r["sorun"].is_empty() and r["sayi"] > 0,
			"nesne: %d, çizimsiz: %s, sorun: %s" % [r["sayi"], str(r["cizimsiz"]), str(r["sorun"])])
	_kaydi("Görünürlük: tüm bölümlerde çizimsiz çarpışma/tetikleyici yok",
		tum_cizimsiz.is_empty() and tum_sorun.is_empty() and toplam > 0,
		"taranan nesne: %d, ÇİZİMSİZ: %s, sorun: %s" % [toplam, str(tum_cizimsiz), str(tum_sorun)])
	_kayitlar().sifirla()

	# --- 2) Gorunum.Tur'ların her biri için _draw match'inde kol var
	var kaynak := FileAccess.get_file_as_string("res://scripts/gorunum.gd")
	var bas := kaynak.find("func _draw()")
	var son := kaynak.find("# ----------", bas)
	var govde := kaynak.substr(bas, (son if son > bas else kaynak.length()) - bas)
	var eksik_kol: Array = []
	for ad in Gorunum.Tur.keys():
		if govde.find("Tur.%s:" % ad) < 0:
			eksik_kol.append(ad)
	_kaydi("Gorunum._draw match'inde her Tur üyesi için kol var (%d tür)" % Gorunum.Tur.size(),
		bas >= 0 and eksik_kol.is_empty(), "kolu olmayan türler: %s" % str(eksik_kol))

	# --- 3) Bölüm kayıtları: benzersiz, sıralı, yüklenebilir, ad dolu, onceki zinciri
	var yollar: Array = _liste_yollari()
	var benzersiz := {}
	for y in yollar:
		benzersiz[y] = true
	var dosya_say := 0
	var resmi_kayit := 0
	for k in kayitlar:
		if k["kaynak"] == "resmi":
			resmi_kayit += 1
	var dizin := DirAccess.open("res://scenes/bolumler")
	if dizin != null:
		for f in dizin.get_files():
			if f.begins_with("bolum_") and f.ends_with(".tscn"):
				dosya_say += 1
	_kaydi("Bölüm listesi: resmî kayıt sayısı = scenes/bolumler/bolum_*.tscn dosya sayısı ve hepsi farklı sahne dosyası",
		resmi_kayit == dosya_say and dosya_say >= 21 and benzersiz.size() == n,
		"kayıt: %d (resmî %d), bolum_*.tscn dosyası: %d, farklı yol: %d" % [n, resmi_kayit, dosya_say, benzersiz.size()])
	var sorunlar: Array = []
	var resmi_sira := 0
	for i in range(n):
		var k: Dictionary = kayitlar[i]
		if k["kaynak"] == "resmi":
			resmi_sira += 1
			var beklenen := "res://scenes/bolumler/bolum_%d.tscn" % resmi_sira
			if k["yol"] != beklenen:
				sorunlar.append("resmî kayıt %d yolu %s (beklenen %s)" % [resmi_sira, k["yol"], beklenen])
		if not ResourceLoader.exists(k["yol"]):
			sorunlar.append("kayıt %d dosya yok" % (i + 1))
		else:
			var ps = load(k["yol"])
			if not (ps is PackedScene and ps.can_instantiate()):
				sorunlar.append("kayıt %d yüklenemez" % (i + 1))
		if str(k.get("ad", "")).strip_edges() == "":
			sorunlar.append("kayıt %d adı boş" % (i + 1))
		var onc_bek: String = "" if i == 0 else str(kayitlar[i - 1]["yol"])
		if str(k.get("onceki", "")) != onc_bek:
			sorunlar.append("kayıt %d onceki '%s' (beklenen '%s')" % [i + 1, str(k.get("onceki", "")), onc_bek])
	_kaydi("Bölüm listesi: resmî kayıtlar göreli sırayla bolum_N.tscn, dosya var/yüklenir, ad dolu, onceki = listedeki bir önceki yol",
		sorunlar.is_empty(), "sorunlar: %s" % str(sorunlar))


# ================================================================ HUD bölüm etiketi (Parça 3)
## Her bölümde HUD'da "Bölüm N · Ad" (adı yoksa "Bölüm N") görünür; numara ve ad BolumListesi'nden okunur,
## Bilgi satırının (Tur | Klon | R) hemen üstündedir, ekran içindedir, fareyi yutmaz.
func _ar_hud_bolum_etiketi() -> void:
	# Sabit adlar sahne yoluna bağlıdır; numara listedeki sıradan türer (araya canlı bölüm girse de doğru kalır).
	var beklenen_ad := {
		"res://scenes/bolumler/bolum_1.tscn": "Giriş", "res://scenes/bolumler/bolum_2.tscn": "İkiz",
		"res://scenes/bolumler/bolum_4.tscn": "Kule", "res://scenes/bolumler/bolum_14.tscn": "Çekirdek",
		"res://scenes/bolumler/bolum_18.tscn": "Vardiya", "res://scenes/bolumler/bolum_19.tscn": "Büyük Saat",
		"res://scenes/bolumler/bolum_20.tscn": "Mandal", "res://scenes/bolumler/bolum_21.tscn": "Fitil ve Mühür"}
	var viewport_alan := Rect2(Vector2.ZERO, Vector2(
		ProjectSettings.get_setting("display/window/size/viewport_width", 1152),
		ProjectSettings.get_setting("display/window/size/viewport_height", 648)))
	var kayitlar: Array = BolumListesi.liste()
	var sorun := ""
	var ornek := ""
	for i in range(kayitlar.size()):
		aktif_bolum = kayitlar[i]["yol"]
		_kayitlar().sifirla()
		var b: Node = await _bolumu_yukle()
		await physics_frame
		var et: Label = b.find_child("BolumEtiketi", true, false) as Label
		if et == null:
			sorun += " %d(etiket yok)" % (i + 1)
			continue
		var bek: String = "Bölüm %d · %s" % [i + 1, kayitlar[i]["ad"]] if str(kayitlar[i].get("ad", "")) != "" else "Bölüm %d" % (i + 1)
		var rect := Rect2(et.position, et.get_minimum_size())
		var ust_ok: bool = et.position.y + et.get_minimum_size().y <= b.bilgi.position.y + 0.5 and et.position.x == b.bilgi.position.x
		var ekran_ok: bool = viewport_alan.encloses(rect) and viewport_alan.has_point(b.bilgi.position)
		var bilgi_ok: bool = b.bilgi.text.begins_with("Tur 1 ") and b.bilgi.visible and et.visible
		if et.text != bek or not ust_ok or not ekran_ok or not bilgi_ok or et.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			sorun += " %d(\"%s\" bekl. \"%s\", üstte:%s, ekranda:%s, bilgi:%s)" % [i + 1, et.text, bek, ust_ok, ekran_ok, bilgi_ok]
		if beklenen_ad.has(kayitlar[i]["yol"]):
			var sabit: String = "Bölüm %d · %s" % [BolumListesi.indeks(kayitlar[i]["yol"]) + 1, beklenen_ad[kayitlar[i]["yol"]]]
			if et.text != sabit:
				sorun += " %d(sabit beklenen \"%s\", bulunan \"%s\")" % [i + 1, sabit, et.text]
			ornek += "%s; " % et.text
	_kaydi("HUD bölüm etiketi: her bölümde \"Bölüm N · Ad\" (numara/ad BolumListesi'nden), Bilgi satırının üstünde, ekranda (%d bölüm)" % kayitlar.size(),
		sorun == "" and kayitlar.size() >= 21, "sorunlar:%s | örnekler: %s" % [sorun if sorun != "" else " yok", ornek])
	# Ad yoksa yalnız "Bölüm N"; listede olmayan sahnede (test sahnesi) etiket kurulmaz.
	aktif_bolum = GECIT_TEST
	_kayitlar().sifirla()
	var gt: Node = await _bolumu_yukle()
	await physics_frame
	var yok_ok: bool = BolumListesi.baslik_metni(5, "") == "Bölüm 5" and BolumListesi.baslik_metni(14, "Çekirdek") == "Bölüm 14 · Çekirdek" \
		and BolumListesi.baslik("res://olmayan.tscn") == "" and gt.find_child("BolumEtiketi", true, false) == null
	_kaydi("HUD bölüm etiketi: adı yoksa yalnız \"Bölüm N\", listede olmayan sahnede etiket yok", yok_ok,
		"baslik_metni(5,\"\")=\"%s\", test sahnesinde etiket: %s" % [BolumListesi.baslik_metni(5, ""), gt.find_child("BolumEtiketi", true, false) != null])
	_kayitlar().sifirla()
	paused = false
