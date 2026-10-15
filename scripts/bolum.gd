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

var bitti := false
var butonlar: CanvasLayer


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
	var ipucu := "R: turu bitir" if klon_hakki_var_mi() else "Klon hakkı bitti"
	bilgi.text = "Tur %d  |  Klon: %d/%d  |  %s" % [klon_sayisi + 1, klon_sayisi, max_klon, ipucu]


func _physics_process(_delta: float) -> void:
	if bitti:
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
	sonuc.goster(oyuncu.kare, Kayitlar.turlar.size() + 1)
	get_tree().paused = true
