class_name EditorHud
extends CanvasLayer
## Editör/özel bölümler için yalnızca görsel HUD katmanı. Bölüm kökünün
## `metadata/cozum_yok` değeri doğruysa "Bu bölümün doğrulanmış çözümü yok" uyarısını
## (amber, `Uyari` etiketi) Bilgi satırının altında gösterir. Fizik ve oyun durumunu
## okumaz ya da yazmaz; fareyi yutmaz. Headless'ta da düğüm kurulur.

const UYARI_METNI := "Bu bölümün doğrulanmış çözümü yok"
## Uyarı, Bilgi satırının (ve klon yuvalarının) altına bu kadar aşağıda durur.
const UYARI_KAYMASI := Vector2(0, 56)

var uyari: Label


func _ready() -> void:
	layer = 8
	var kok := get_parent()
	if kok == null or not bool(kok.get_meta("cozum_yok", false)):
		return
	uyari = Label.new()
	uyari.name = "Uyari"
	uyari.text = UYARI_METNI
	uyari.mouse_filter = Control.MOUSE_FILTER_IGNORE
	uyari.add_theme_color_override("font_color", LabPaleti.AMBER)
	uyari.add_theme_color_override("font_outline_color", LabPaleti.KENAR)
	uyari.add_theme_constant_override("outline_size", 4)
	add_child(uyari)
	# bolum.gd Bilgi satırını kendi _ready'sinde (HUD etiketi varsa) aşağı kaydırır; çocuk
	# _ready'si ondan önce çalışır. Bu yüzden son konum kök hazır olunca yeniden hesaplanır.
	_konumla()
	if not kok.is_node_ready():
		kok.ready.connect(_konumla, CONNECT_ONE_SHOT)


func _konumla() -> void:
	if uyari == null:
		return
	var bilgi := get_parent().get_node_or_null("Bilgi") as Control
	var temel := bilgi.position if bilgi != null else Vector2(16, 12)
	uyari.position = temel + UYARI_KAYMASI
