extends AnimatableBody2D
## Geçit: hedef kapısı olan Kapi'dan ayrı, katı (katman 1) kayar engel.
## Bağlı tetikleyicilerden HERHANGİ BİRİ aktifse açılır (VEYA), hiçbiri aktif değilse kapanır.
## Plaka aktif = basılı. Şalter aktif = `acik_taraf_sag` konumunda.
## Sabit hızla hareket eder (move_toward, ışınlanma yok). Kapanırken kapanacağı bölgede
## oyuncu/klon varsa durur (asansördeki kural), karakter çıkınca kapanmaya devam eder.
## Sahne ağacında plaka/şalterden sonra, karakterlerden önce durmalıdır (sabit sıra).

## Kapalı konumdan açık konuma kayma yönü (normalize edilir).
@export var kayma_yonu := Vector2.UP
## Açılırken kat edilen mesafe (piksel). Kapı boyutu koridoru kapatacak şekilde sahnede ayarlanır.
@export var kayma_mesafe := 100.0
## Hareket hızı (piksel/saniye).
@export var hiz := 120.0
## Bağlı plaka ve şalterler (bu düğümden göreli yollar).
@export var tetikleyici_yollari: Array[NodePath] = []
## Şalter için "açık" sayılan taraf: true = sağ.
@export var acik_taraf_sag := true

const KARAKTER_KATMANLARI := (1 << 1) | (1 << 2) | (1 << 3)  # 2 = oyuncu, 3 = klon, 4 = kutu

var kapali_konum: Vector2
var acik_konum: Vector2
var tetikleyiciler: Array = []


func _ready() -> void:
	collision_layer = 1
	# Görünüm (yalnızca görsel): kayarken zemin/tavan içinde örtülür (z_index -1).
	var eski := get_node_or_null("Gorsel")
	if eski != null:
		eski.visible = false
	Gorunum.ekle(self, Gorunum.Tur.GECIT, Gorunum.sekil_alani(self))
	# Sahnede yerleştirildiği konum "kapalı" konumdur.
	kapali_konum = position
	acik_konum = position + kayma_yonu.normalized() * kayma_mesafe
	var dugumler: Array = []
	for yol in tetikleyici_yollari:
		dugumler.append(get_node(yol))
	tetikleyicileri_ayarla(dugumler)


## Tetikleyici listesini değiştirir (plaka: basili_mi(), şalter: sagda).
func tetikleyicileri_ayarla(dugumler: Array) -> void:
	tetikleyiciler = dugumler.duplicate()


func aktif_mi() -> bool:
	for t in tetikleyiciler:
		if t is BasincPlakasi:
			if t.basili_mi():
				return true
		elif t.get("sagda") != null:
			if t.sagda == acik_taraf_sag:
				return true
	return false


func _physics_process(delta: float) -> void:
	var kapaniyor := not aktif_mi()
	var hedef := kapali_konum if kapaniyor else acik_konum
	var sonraki := position.move_toward(hedef, hiz * delta)
	if kapaniyor and sonraki != position and _bolgede_karakter_var_mi(sonraki):
		return
	position = sonraki


## Geçit bir sonraki konuma gelirse kaplayacağı bölgede oyuncu/klon var mı?
func _bolgede_karakter_var_mi(sonraki: Vector2) -> bool:
	var sorgu := PhysicsShapeQueryParameters2D.new()
	sorgu.shape = $CollisionShape2D.shape
	sorgu.collision_mask = KARAKTER_KATMANLARI
	sorgu.collide_with_bodies = true
	sorgu.collide_with_areas = false
	sorgu.transform = Transform2D(0.0, global_position + (sonraki - position))
	return not get_world_2d().direct_space_state.intersect_shape(sorgu, 1).is_empty()
