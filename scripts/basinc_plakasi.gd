class_name BasincPlakasi
extends Area2D
## Basınç plakası: üstünde oyuncu veya klon varsa basılı sayılır.
## Varsayılan durumda kendi başına durum tutmaz; her karede çakışmalardan okunur,
## böylece dünya her turda baştan ve deterministik simüle edilir.
## İsteğe bağlı iki kip (kullanıcı kararı, docs/kararlar.md): zamanlı (`tutma_kare`)
## ve mandal (`mandal`). İkisi de yalnızca fizik karesi sayacına dayanır; sahne her
## turda yeniden kurulduğu için sayaç/mandal tur başında sıfırlanır.

const BASILI_RENK := Color(0.9, 0.3, 0.2)
const BOSTA_RENK := Color(0.6, 0.55, 0.25)

## >0 ise fiziksel basış bittikten sonra bu kadar fizik karesi daha basılı sayılır.
## Tekrar basılırsa sayaç yenilenir.
@export var tutma_kare: int = 0
## true ise bir kez basılınca tur sonuna kadar basılı kalır.
@export var mandal: bool = false

## Zamanlı kipte kalan kare (görünüm de okur).
var kalan_kare: int = 0
## Mandal kilitlendi mi (görünüm de okur).
var kilitli: bool = false
var _son_kare: int = -1
var _etkin: bool = false


func _ready() -> void:
	# Katmanlar: 2 = oyuncu, 3 = klon. Plaka ikisini de algılar, kendisi çarpışma yaratmaz.
	collision_layer = 0
	collision_mask = (1 << 1) | (1 << 2) | (1 << 3)  # 4 = kutu
	# Görünüm: eski kutu gizlenir, ortak Gorunum çizer (yalnızca görsel).
	var eski := get_node_or_null("Gorsel")
	if eski != null:
		eski.visible = false
	var tur := Gorunum.Tur.PLAKA
	if mandal:
		tur = Gorunum.Tur.PLAKA_MANDAL
	elif tutma_kare > 0:
		tur = Gorunum.Tur.PLAKA_ZAMANLI
	Gorunum.ekle(self, tur)


## Plaka şu an etkin ("basılı") mı? Fiziksel basış, zamanlı tutma veya mandal.
## Durum fizik karesi başına bir kez ilerler (çok kez çağrılması sayacı etkilemez).
func basili_mi() -> bool:
	if tutma_kare <= 0 and not mandal:
		return has_overlapping_bodies()
	var kare := Engine.get_physics_frames()
	if kare != _son_kare:
		_son_kare = kare
		var fiziksel := has_overlapping_bodies()
		if fiziksel:
			kalan_kare = tutma_kare + 1  # bırakıldıktan sonra tam tutma_kare kare etkin
			if mandal:
				kilitli = true
		elif kalan_kare > 0:
			kalan_kare -= 1
		_etkin = fiziksel or kalan_kare > 0 or kilitli
	return _etkin


func _physics_process(_delta: float) -> void:
	var etkin := basili_mi()
	var eski := get_node_or_null("Gorsel")
	if eski != null:
		eski.color = BASILI_RENK if etkin else BOSTA_RENK
