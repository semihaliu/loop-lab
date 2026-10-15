extends AnimatableBody2D
## Asansör: plaka basılıyken yukarı çıkar, değilken iner. Sabit hızla hareket eder.
## İnerken altında karakter varsa durur (ezmez, içinden geçmez).
## Dünya nesnesidir (katman 1); oyuncu ve klonlar üstüne binebilir, yukarıdaysa
## aşağıdaki klon binemez. Ağaçta karakterlerden önce durmalı ki her karede
## önce asansör, sonra karakterler güncellensin (sıra sabit = deterministik).

## Asansörü kontrol eden plaka.
@export var plaka: BasincPlakasi
## Aşağı konumdan yukarı konuma mesafe (piksel).
@export var yukseklik := 180.0
## Hareket hızı (piksel/saniye).
@export var hiz := 120.0

## Altında durup inişi engelleyen karakterlerin katmanları: 2 = oyuncu, 3 = klon.
const KARAKTER_KATMANLARI := (1 << 1) | (1 << 2) | (1 << 3)  # 4 = kutu

var alt_y: float
var ust_y: float


func _ready() -> void:
	# Sahnede yerleştirildiği konum "aşağı" konumdur.
	alt_y = position.y
	ust_y = alt_y - yukseklik
	# Görünüm (yalnızca görsel): çarpışma şeklinden alan alınır, asansör zemin/kat içine gömülürse örtülür.
	$Gorsel.visible = false
	Gorunum.ekle(self, Gorunum.Tur.ASANSOR, Gorunum.sekil_alani(self))


func _physics_process(delta: float) -> void:
	var hedef_y := ust_y if plaka.basili_mi() else alt_y
	var adim := hiz * delta
	# Aşağı inerken altında oyuncu/klon varsa dur; karakter çekilince iner. Üstünde
	# duran karakter bu sorguya girmez, normal taşınır.
	if hedef_y > position.y and _altinda_karakter_var_mi(adim):
		return
	position.y = move_toward(position.y, hedef_y, adim)


## Asansörün hemen altında, bu karede kat edeceği mesafe (+ 2 px pay) kadar bir bölgede
## oyuncu veya klon var mı? Sorgu sabit fizik karesinde yapılır, rastgelelik yoktur.
func _altinda_karakter_var_mi(adim: float) -> bool:
	var asansor_sekli: RectangleShape2D = $CollisionShape2D.shape
	var bolge := RectangleShape2D.new()
	bolge.size = Vector2(asansor_sekli.size.x - 2.0, adim + 2.0)
	var sorgu := PhysicsShapeQueryParameters2D.new()
	sorgu.shape = bolge
	sorgu.collision_mask = KARAKTER_KATMANLARI
	sorgu.collide_with_bodies = true
	sorgu.collide_with_areas = false
	var alt_kenar := global_position.y + asansor_sekli.size.y / 2.0
	sorgu.transform = Transform2D(0.0, Vector2(global_position.x, alt_kenar + bolge.size.y / 2.0))
	return not get_world_2d().direct_space_state.intersect_shape(sorgu, 1).is_empty()
