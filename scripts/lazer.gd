extends Area2D
## Lazer: sabit yayıcı + ışın alanı. Açıkken ışına giren oyuncu/klon ölür (oldur()).
## Tetikleyicisiz lazer hep açıktır. Tetikleyiciler VEYA mantığıyla çalışır (Gecit gibi):
## plaka aktif = basılı, şalter aktif = `acik_taraf_sag` konumunda.
## Işın duvarlarda kesilmez (raycast yok). Ağaçta karakterlerden ÖNCE durmalıdır.

## Işının yayıcıdan gittiği yön (normalize edilir; yatay/dikey kullanılır).
@export var yon := Vector2.RIGHT
## Işın uzunluğu (piksel).
@export var uzunluk := 200.0
## Bağlı plaka ve şalterler (bu düğümden göreli yollar).
@export var tetikleyici_yollari: Array[NodePath] = []
## Şalter için "aktif" taraf: true = sağ.
@export var acik_taraf_sag := true
## true: tetikleyici aktifken lazer KAPANIR; false: tetikleyici aktifken AÇILIR.
@export var tetik_aktifken_kapali := true

const KALINLIK := 6.0
const KARAKTER_KATMANLARI := (1 << 1) | (1 << 2)  # 2 = oyuncu, 3 = klon

var tetikleyiciler: Array = []
var _acik := true


func _ready() -> void:
	collision_layer = 0
	collision_mask = KARAKTER_KATMANLARI
	var d := yon.normalized()
	if d == Vector2.ZERO:
		d = Vector2.RIGHT
	# Işın alanı yayıcıdan yön boyunca uzanır.
	var boyut := Vector2(absf(d.x) * uzunluk + absf(d.y) * KALINLIK, absf(d.y) * uzunluk + absf(d.x) * KALINLIK)
	var sekil := RectangleShape2D.new()
	sekil.size = boyut
	$Isin.shape = sekil
	$Isin.position = d * uzunluk / 2.0
	$IsinGorsel.position = $Isin.position - boyut / 2.0
	$IsinGorsel.size = boyut
	# Görünüm: ışın kutusu görünmez kalır (visible durumu açık/kapalıyı izler), çizimi Gorunum yapar.
	$IsinGorsel.color = Color(1, 0.15, 0.15, 0.0)
	$Govde.visible = false
	Gorunum.ekle(self, Gorunum.Tur.LAZER)
	var dugumler: Array = []
	for yol in tetikleyici_yollari:
		dugumler.append(get_node(yol))
	tetikleyicileri_ayarla(dugumler)
	_durumu_uygula(_hesapla_acik())


## Tetikleyici listesini değiştirir (plaka: basili_mi(), şalter: sagda).
func tetikleyicileri_ayarla(dugumler: Array) -> void:
	tetikleyiciler = dugumler.duplicate()


## Bağlı tetikleyicilerden biri aktif mi? (tetikleyici yoksa false)
func aktif_mi() -> bool:
	for t in tetikleyiciler:
		if t is BasincPlakasi:
			if t.basili_mi():
				return true
		elif t.get("sagda") != null:
			if t.sagda == acik_taraf_sag:
				return true
	return false


## Lazer şu an açık (öldürücü) mü?
func acik_mi() -> bool:
	return _acik


func _hesapla_acik() -> bool:
	if tetikleyiciler.is_empty():
		return true
	return aktif_mi() != tetik_aktifken_kapali


func _durumu_uygula(acik: bool) -> void:
	_acik = acik
	$IsinGorsel.visible = acik
	set_deferred("monitoring", acik)


func _physics_process(_delta: float) -> void:
	var acik := _hesapla_acik()
	if acik != _acik:
		_durumu_uygula(acik)
	if not _acik or not monitoring:
		return
	for govde in get_overlapping_bodies():
		if govde.has_method("oldur"):
			govde.oldur()
