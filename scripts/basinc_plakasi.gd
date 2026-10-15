class_name BasincPlakasi
extends Area2D
## Basınç plakası: üstünde oyuncu veya klon varsa basılı sayılır.
## Durum her karede çakışmalardan okunur, kendi başına bir durum tutmaz;
## böylece dünya her turda baştan ve deterministik simüle edilir.

const BASILI_RENK := Color(0.9, 0.3, 0.2)
const BOSTA_RENK := Color(0.6, 0.55, 0.25)


func _ready() -> void:
	# Katmanlar: 2 = oyuncu, 3 = klon. Plaka ikisini de algılar, kendisi çarpışma yaratmaz.
	collision_layer = 0
	collision_mask = (1 << 1) | (1 << 2) | (1 << 3)  # 4 = kutu
	# Görünüm: eski kutu gizlenir, ortak Gorunum çizer (yalnızca görsel).
	var eski := get_node_or_null("Gorsel")
	if eski != null:
		eski.visible = false
	Gorunum.ekle(self, Gorunum.Tur.PLAKA)


## Plakanın üstünde en az bir oyuncu/klon var mı?
func basili_mi() -> bool:
	return has_overlapping_bodies()


func _physics_process(_delta: float) -> void:
	var eski := get_node_or_null("Gorsel")
	if eski != null:
		eski.color = BASILI_RENK if basili_mi() else BOSTA_RENK
