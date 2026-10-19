extends Node2D
## Tur yönetimi: sahne her turda baştan yüklenir, önceki turlar klon olarak oynar.
## Bölüm sahneleri (scenes/bolumler/) bu betiği paylaşır; yeni bölüm = yeni sahne.

const OYUNCU_SAHNESI := preload("res://scenes/oyuncu.tscn")
const SONUC_SAHNESI := preload("res://scenes/sonuc_ekrani.tscn")
const BUTON_SAHNESI := preload("res://scenes/ekran_butonlari.tscn")

@onready var oyuncu: CharacterBody2D = $Oyuncu
@onready var bilgi: Label = $Bilgi
@onready var kapi: Area2D = $Kapi

## Bu bölümde en fazla kaç klon kaydedilebilir (sahnede bölüm başına ayarlanır).
@export var max_klon: int = 2

## Sınır duvarlarının kalınlığı (görünmez; ekran dışında kalır).
const DUVAR_KALINLIGI := 100.0

## HUD bölüm etiketinin yüksekliği; Bilgi satırı bu kadar aşağı kayar.
const BOLUM_ETIKETI_YUKSEKLIK := 28.0

## İpucu ikonu (yalnızca HUD): 0 ise ikon hiç görünmez; doluysa "?" ikonunun
## üstüne gelince "N klonla çözülebilir" yazar. Oyun mantığına karışmaz.
@export var ipucu_klon: int = 0

var bitti := false
var butonlar: CanvasLayer
var ipucu_ikonu: Label
var ipucu_metni: Label
var bolum_etiketi: Label


func _ready() -> void:
	_gorunumu_kur()
	_sinir_duvarlari_kur()
	butonlar = BUTON_SAHNESI.instantiate()
	add_child(butonlar)
	# Klonlar tur sırasıyla eklenir; ağaç sırası sabit olduğu için simülasyon deterministiktir.
	for kayit in Kayitlar.turlar:
		var klon := OYUNCU_SAHNESI.instantiate()
		klon.klon = true
		klon.kayit_girdileri = kayit
		klon.position = oyuncu.position
		add_child(klon)
	_bilgiyi_guncelle()
	_bolum_etiketi_kur()
	_ipucu_kur()
	_klon_gostergesi_kur()
	_gecis_perdesi_kur()
	kapi.hedefe_ulasildi.connect(_on_hedefe_ulasildi)
	oyuncu.oyuncu_oldu.connect(_on_oyuncu_oldu)


## Ortak görünüm (yalnızca görsel): laboratuvar arka planı en alt katmana eklenir,
## zemin/duvar/tavan/kat ve tek yönlü platformların renkli kutuları gizlenip yerine
## ortak çizim konur. Çarpışma, konum ve boyutlara dokunulmaz.
func _gorunumu_kur() -> void:
	var katman := CanvasLayer.new()
	katman.name = "ArkaPlanKatmani"
	katman.layer = -10
	var arka := LabArkaplani.new()
	arka.name = "LabArkaplani"
	katman.add_child(arka)
	add_child(katman)
	for c in get_children():
		# AnimatableBody2D (asansör, geçit) StaticBody2D'den türer; kendi görünümünü kendisi ekler.
		if not (c is StaticBody2D) or c is AnimatableBody2D:
			continue
		# Kendi çizimi olan gövde (taşıma bandı vb.) ikinci kez çizilmez: üstünü örter.
		if c.get_node_or_null("Gorunum") != null:
			continue
		var kutu := c.get_node_or_null("Gorsel") as ColorRect
		if kutu == null:
			continue
		var tek_yonlu := false
		for k in c.get_children():
			if k is CollisionShape2D and k.one_way_collision:
				tek_yonlu = true
		kutu.visible = false
		var alan := Rect2(kutu.position, kutu.size)
		Gorunum.ekle(c, Gorunum.Tur.TEK_YONLU if tek_yonlu else Gorunum.Tur.DUVAR, alan)
	# Bilgi yazısı koyu arka planda okunur olsun
	bilgi.add_theme_color_override("font_color", LabPaleti.CAMGOBEGI.lightened(0.4))
	bilgi.add_theme_color_override("font_outline_color", LabPaleti.KENAR)
	bilgi.add_theme_constant_override("outline_size", 4)


## Sol, sağ ve üst görünmez duvarları viewport'un gerçek boyutuna göre kurar.
## Alt sınır bölümün zemini. Duvarlar katman 1'dedir (dünya), oyuncu ve klonlar çarpışır.
func _sinir_duvarlari_kur() -> void:
	var boyut := get_viewport_rect().size
	var k := DUVAR_KALINLIGI
	var govde := StaticBody2D.new()
	govde.name = "SinirDuvarlari"
	govde.collision_layer = 1
	govde.collision_mask = 0
	# Sol ve sağ duvarlar tavan köşelerini de kapatacak kadar yukarı uzanır.
	var parcalar := {
		"Sol": [Vector2(-k / 2.0, boyut.y / 2.0), Vector2(k, boyut.y + 2.0 * k)],
		"Sag": [Vector2(boyut.x + k / 2.0, boyut.y / 2.0), Vector2(k, boyut.y + 2.0 * k)],
		"Ust": [Vector2(boyut.x / 2.0, -k / 2.0), Vector2(boyut.x + 2.0 * k, k)],
	}
	for ad in parcalar:
		var sekil := CollisionShape2D.new()
		sekil.name = ad
		var dikdortgen := RectangleShape2D.new()
		dikdortgen.size = parcalar[ad][1]
		sekil.shape = dikdortgen
		sekil.position = parcalar[ad][0]
		govde.add_child(sekil)
	add_child(govde)


## Klon hakkı kaldı mı? Sınıra ulaşınca R (turu bitir) çalışmaz.
func klon_hakki_var_mi() -> bool:
	return Kayitlar.turlar.size() < max_klon


func _bilgiyi_guncelle() -> void:
	var klon_sayisi := Kayitlar.turlar.size()
	var ipucu := ("R: turu bitir" if klon_hakki_var_mi() else "Klon hakkı bitti") + "  |  T: baştan başla"
	bilgi.text = "Tur %d  |  Klon: %d/%d  |  %s" % [klon_sayisi + 1, klon_sayisi, max_klon, ipucu]


## Bölüm numarası ve adı (yalnızca HUD): "Bölüm 14 · Çekirdek" (adı yoksa "Bölüm 14"), Bilgi
## satırının hemen üstünde. Numara ve ad BolumListesi'nden okunur, yeni bölümde otomatik doğrudur;
## bölüm listede yoksa (ör. test sahnesi) etiket kurulmaz. Bilgi satırı etiket yüksekliği kadar aşağı
## kayar (klon yuvaları ve ipucu ikonu Bilgi'ye göre dizildiği için birlikte kayar). Oyun durumunu okumaz/yazmaz.
func _bolum_etiketi_kur() -> void:
	var metin := BolumListesi.baslik(scene_file_path)
	if metin == "":
		return
	var katman := CanvasLayer.new()
	katman.name = "BolumKatmani"
	katman.layer = 8
	add_child(katman)
	bolum_etiketi = Label.new()
	bolum_etiketi.name = "BolumEtiketi"
	bolum_etiketi.text = metin
	bolum_etiketi.position = bilgi.position
	bolum_etiketi.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bolum_etiketi.add_theme_font_size_override("font_size", 20)
	bolum_etiketi.add_theme_color_override("font_color", LabPaleti.ONLUK)
	bolum_etiketi.add_theme_color_override("font_outline_color", LabPaleti.KENAR)
	bolum_etiketi.add_theme_constant_override("outline_size", 5)
	katman.add_child(bolum_etiketi)
	bilgi.position.y += BOLUM_ETIKETI_YUKSEKLIK


## İpucu ikonu ve hover metni. Fare etkileşimi yalnızca ikonun kendisindedir;
## klavye girdisini etkilemez. Metin yalnızca üstüne gelince görünür.
func _ipucu_kur() -> void:
	if ipucu_klon <= 0:
		return
	var katman := CanvasLayer.new()
	katman.name = "IpucuKatmani"
	katman.layer = 9
	add_child(katman)
	var x := bilgi.position.x + bilgi.get_minimum_size().x + 12.0
	var y := bilgi.position.y + 2.0
	ipucu_ikonu = Label.new()
	ipucu_ikonu.name = "IpucuIkonu"
	ipucu_ikonu.text = "?"
	ipucu_ikonu.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ipucu_ikonu.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ipucu_ikonu.position = Vector2(x, y)
	ipucu_ikonu.size = Vector2(24, 24)
	ipucu_ikonu.mouse_filter = Control.MOUSE_FILTER_STOP
	ipucu_ikonu.add_theme_color_override("font_color", LabPaleti.CAMGOBEGI.lightened(0.4))
	var kutu := StyleBoxFlat.new()
	kutu.bg_color = LabPaleti.KENAR
	kutu.border_color = LabPaleti.CAMGOBEGI
	kutu.set_border_width_all(2)
	kutu.set_corner_radius_all(12)
	ipucu_ikonu.add_theme_stylebox_override("normal", kutu)
	katman.add_child(ipucu_ikonu)
	ipucu_metni = Label.new()
	ipucu_metni.name = "IpucuMetni"
	ipucu_metni.text = "%d klonla çözülebilir" % ipucu_klon
	ipucu_metni.position = Vector2(x, y + 28.0)
	ipucu_metni.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ipucu_metni.visible = false
	ipucu_metni.add_theme_color_override("font_color", LabPaleti.CAMGOBEGI.lightened(0.4))
	ipucu_metni.add_theme_color_override("font_outline_color", LabPaleti.KENAR)
	ipucu_metni.add_theme_constant_override("outline_size", 4)
	katman.add_child(ipucu_metni)
	ipucu_ikonu.mouse_entered.connect(func() -> void: ipucu_metni.visible = true)
	ipucu_ikonu.mouse_exited.connect(func() -> void: ipucu_metni.visible = false)


## Klon yuvaları (yalnızca HUD): kullanılan klon dolu, kalan boş; "R" tuş rozeti
## hak varken görünür. Metin etiketi (Bilgi) korunur; oyun durumunu yalnızca okur.
func _klon_gostergesi_kur() -> void:
	if LabPaleti.ekransiz():
		return
	var katman := CanvasLayer.new()
	katman.name = "KlonGostergesi"
	katman.layer = 8
	add_child(katman)
	var kullanilan := Kayitlar.turlar.size()
	var x0 := bilgi.position.x
	var y0 := bilgi.position.y + 30.0
	for i in max_klon:
		var yuva := Panel.new()
		yuva.name = "Yuva%d" % (i + 1)
		yuva.position = Vector2(x0 + i * 26.0, y0)
		yuva.size = Vector2(20, 20)
		yuva.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var st := StyleBoxFlat.new()
		st.set_corner_radius_all(10)
		st.set_border_width_all(2)
		st.border_color = LabPaleti.KLON
		st.bg_color = LabPaleti.KLON if i < kullanilan else LabPaleti.KENAR
		yuva.add_theme_stylebox_override("panel", st)
		katman.add_child(yuva)
	if klon_hakki_var_mi():
		var rozet := Label.new()
		rozet.name = "TusRozeti"
		rozet.text = "R"
		rozet.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rozet.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		rozet.position = Vector2(x0 + max_klon * 26.0 + 8.0, y0 - 2.0)
		rozet.size = Vector2(24, 24)
		rozet.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rozet.add_theme_color_override("font_color", LabPaleti.AMBER)
		var kutu := StyleBoxFlat.new()
		kutu.bg_color = LabPaleti.PANEL
		kutu.border_color = LabPaleti.AMBER
		kutu.set_border_width_all(2)
		kutu.border_width_bottom = 4
		kutu.set_corner_radius_all(4)
		rozet.add_theme_stylebox_override("normal", kutu)
		katman.add_child(rozet)


## Bölüm/tur yüklenince koyu perde 0,25 sn'de solar (yalnızca görsel; girdiyi yutmaz,
## fizik karesine karışmaz). Headless'ta atlanır.
func _gecis_perdesi_kur() -> void:
	if LabPaleti.ekransiz():
		return
	var katman := CanvasLayer.new()
	katman.name = "GecisKatmani"
	katman.layer = 20
	add_child(katman)
	var perde := ColorRect.new()
	perde.name = "Perde"
	perde.color = LabPaleti.ARKA_UST
	perde.set_anchors_preset(Control.PRESET_FULL_RECT)
	perde.mouse_filter = Control.MOUSE_FILTER_IGNORE
	katman.add_child(perde)
	var tw := create_tween()
	tw.tween_property(perde, "modulate:a", 0.0, 0.25).from(1.0)
	tw.tween_callback(katman.queue_free)


func _physics_process(_delta: float) -> void:
	if bitti:
		return
	# T = baştan başla (sistem tuşu: kayda girmez; sonuç ekranında/ölümde bitti=true olduğu için çalışmaz).
	if Input.is_action_just_pressed("bastan"):
		bitti = true
		butonlar.bastan_basla()
		return
	if Input.is_action_just_pressed("tur_bitir") and klon_hakki_var_mi():
		Kayitlar.tur_kaydet(oyuncu.kayit_girdileri)
		get_tree().reload_current_scene()


## Canlı oyuncu öldü: turu yeniden başlatır. Kayitlar.turlar değişmez, tur sayısı artmaz,
## bu turun girdisi atılır (tur_kaydet çağrılmaz). Sinyal fizik sırasında gelir, deferred yüklenir.
func _on_oyuncu_oldu() -> void:
	if bitti:
		return
	bitti = true
	get_tree().reload_current_scene.call_deferred()


func _on_hedefe_ulasildi() -> void:
	if bitti:
		return
	bitti = true
	butonlar.gizle()
	# Sinyal fizik sorgusu sırasında geldiği için sonucu bir sonraki boşta ana işle.
	_bolumu_bitir.call_deferred()


func _bolumu_bitir() -> void:
	# Süre gerçek saatten değil, bu turda geçen fizik karesinden hesaplanır.
	var sonuc := SONUC_SAHNESI.instantiate()
	add_child(sonuc)
	# Toplam süre: önceki turların kayıt uzunluğu (kare sayısı) + bu turun karesi.
	var toplam: int = oyuncu.kare
	for kayit in Kayitlar.turlar:
		toplam += kayit.size()
	sonuc.goster(oyuncu.kare, Kayitlar.turlar.size() + 1, toplam, Kayitlar.turlar.size(), ipucu_klon)
	get_tree().paused = true
