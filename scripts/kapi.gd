extends Area2D
## Kapı = bölüm hedefi. Yalnızca canlı oyuncu (katman 2) değince açılır ve
## bölüm biter; klonlar (katman 3) kapıdan geçse de bir şey olmaz.

signal hedefe_ulasildi

const KAPALI_RENK := Color(0.45, 0.25, 0.1)
const ACIK_RENK := Color(0.3, 0.85, 0.4)

var acik := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 << 1
	$Gorsel.color = KAPALI_RENK
	$Gorsel.visible = false
	Gorunum.ekle(self, Gorunum.Tur.KAPI)
	body_entered.connect(_on_body_entered)


func _on_body_entered(_govde: Node2D) -> void:
	if acik:
		return
	acik = true
	$Gorsel.color = ACIK_RENK
	hedefe_ulasildi.emit()
