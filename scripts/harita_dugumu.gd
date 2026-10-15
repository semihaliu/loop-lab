class_name HaritaDugumu
extends Button
## Haritadaki bölüm düğümü: altıgen, koyu dış kenar, renkli iç dolgu, gölge, bölüm numarası.
## Hover'da hafif büyür ve parlar. Çizim koddan yapılır; numara Button metnidir.

const YARICAP := 34.0
const BOYUT := Vector2(80, 80)
const BUYUME := 1.12

var renk := Color(0.2, 0.5, 0.9)
var vurgulu := false
var _tween: Tween


func kur(numara: int, ana_renk: Color) -> void:
	text = str(numara)
	renk = ana_renk
	size = BOYUT
	custom_minimum_size = BOYUT
	pivot_offset = BOYUT / 2.0
	focus_mode = Control.FOCUS_NONE
	flat = true
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var bos := StyleBoxEmpty.new()
	for ad in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		add_theme_stylebox_override(ad, bos)
	# Düğme metni (test ve erişilebilirlik için numara) Button tarafından çizilmez;
	# numara _draw içinde altıgenin üstüne elle çizilir (Button metni altıgenin altında kalıyordu).
	for ad in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		add_theme_color_override(ad, Color(1, 1, 1, 0))
	mouse_entered.connect(_hover_ayarla.bind(true))
	mouse_exited.connect(_hover_ayarla.bind(false))


func _hover_ayarla(acik: bool) -> void:
	vurgulu = acik
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2.ONE * (BUYUME if acik else 1.0), 0.12)
	queue_redraw()


## Düz tepeli altıgenin köşeleri.
static func altigen(merkez: Vector2, yaricap: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(6):
		var a := deg_to_rad(60.0 * i)
		pts.append(merkez + Vector2(cos(a), sin(a)) * yaricap)
	return pts


func _draw() -> void:
	var c := BOYUT / 2.0
	draw_colored_polygon(altigen(c + Vector2(0, 5), YARICAP + 1.0), Color(0, 0, 0, 0.35))   # gölge
	if vurgulu:
		draw_colored_polygon(altigen(c, YARICAP + 9.0), Color(renk.lightened(0.5), 0.35))   # parlama
	draw_colored_polygon(altigen(c, YARICAP), renk.darkened(0.55))                          # koyu dış kenar
	draw_colored_polygon(altigen(c, YARICAP - 5.0), renk.lightened(0.18) if vurgulu else renk)
	var ic := altigen(c, YARICAP - 5.0)
	# Üst yarıda hafif parlak şerit (köşe 3, 4, 5, 0 = sol, sol-üst, sağ-üst, sağ).
	draw_colored_polygon(PackedVector2Array([ic[3], ic[4], ic[5], ic[0]]), Color(1, 1, 1, 0.14))
	# Kadran işaretleri: iç altıgenin içinde 12 küçük çizgi (zaman teması)
	for i in range(12):
		var a := TAU * i / 12.0
		var d := Vector2(cos(a), sin(a))
		draw_line(c + d * (YARICAP - 11.0), c + d * (YARICAP - 8.0), Color(1, 1, 1, 0.35), 2.0)
	# Bölüm numarası: büyük, koyu dış hatlı.
	var yazi_tipi := get_theme_default_font()
	var boyut := 34
	var genislik := yazi_tipi.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, boyut).x
	var taban := Vector2(c.x - genislik / 2.0, c.y + (yazi_tipi.get_ascent(boyut) - yazi_tipi.get_descent(boyut)) / 2.0)
	draw_string_outline(yazi_tipi, taban, text, HORIZONTAL_ALIGNMENT_LEFT, -1, boyut, 8, renk.darkened(0.7))
	draw_string(yazi_tipi, taban, text, HORIZONTAL_ALIGNMENT_LEFT, -1, boyut, Color.WHITE)
