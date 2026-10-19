extends CharacterBody2D
## Kutu: itilebilen kinematik nesne. Katmanlar: dünya (1) + kutu (4).
## Karakterlerle çarpışmaz; onların itmesi `it()` ile gelir (player.gd). Zincirleme itme yok.
## Durum tutmaz: sahne her turda yeniden yüklenir, kutu başlangıç konumunda başlar.

const YER_CEKIMI := 1400.0  # player.gd ile aynı sabit değer


func _ready() -> void:
	collision_layer = 1 | (1 << 3)
	collision_mask = 1
	# Görünüm: düz kutu gizlenir, laboratuvar kasası Gorunum çizer (yalnızca görsel).
	var eski := get_node_or_null("Gorsel")
	if eski != null:
		eski.visible = false
	Gorunum.ekle(self, Gorunum.Tur.KUTU, Gorunum.sekil_alani(self))


## O kare için yatay yer değiştirme isteği; dünyaya çarparsa durur.
func it(dx: float) -> void:
	var hareket := Vector2(dx, 0.0)
	var sorgu := move_and_collide(hareket, true)
	if sorgu != null and sorgu.get_collider() is CharacterBody2D \
			and sorgu.get_collider() != self:
		# Başka kutuya dayandı: zincirleme itme yok. Güvenli aralığı koruyarak
		# yalnızca temasa kadar ilerle; temas halindeyse istek iptal.
		var yol: float = sorgu.get_travel().length() - safe_margin - 0.01
		if yol <= 0.0:
			return
		move_and_collide(hareket.normalized() * yol)
		return
	move_and_collide(hareket)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += YER_CEKIMI * delta
	velocity.x = 0.0
	move_and_slide()
