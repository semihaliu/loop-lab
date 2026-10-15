extends CanvasLayer
## Sağ üst ekran butonları: ana menüye dön ve baştan başla (tam sıfırlama).
## Bölüm betiği (bolum.gd) bunu her bölüme otomatik ekler; yeni bölüm = yeni sahne kalır.

const MENU_SAHNESI := "res://scenes/ana_menu.tscn"

@onready var ev_dugmesi: Button = $Kutu/EvDugmesi
@onready var yeniden_dugmesi: Button = $Kutu/YenidenDugmesi


func _ready() -> void:
	$Kutu.theme = LabTema.olustur()  # görünüm (yalnızca görsel)
	ev_dugmesi.pressed.connect(_on_ev)
	yeniden_dugmesi.pressed.connect(_on_yeniden)


## Ana menüye dön: tüm klon kayıtları silinir (yeni oyun temiz başlar).
func _on_ev() -> void:
	Kayitlar.sifirla()
	get_tree().change_scene_to_file(MENU_SAHNESI)


## Baştan başla: tüm klon kayıtları silinir (tur sayısı 1'e döner), bölüm yeniden yüklenir.
func _on_yeniden() -> void:
	Kayitlar.sifirla()
	get_tree().reload_current_scene()


## Sonuç ekranı açıkken butonlar görünmez ve devre dışıdır.
func gizle() -> void:
	visible = false
	ev_dugmesi.disabled = true
	yeniden_dugmesi.disabled = true
