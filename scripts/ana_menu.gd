extends Control
## Ana menü: Oyna (ilerleme haritasını açar), Editör, Kontroller, Çıkış.

const HARITA_SAHNESI := "res://scenes/harita.tscn"
# Yalnızca yol: editör/kurucu sınıflarına burada başvurulmaz (13 betik preload eder, fizik sırasını kaydırabilir).
const EDITOR_SAHNESI := "res://scenes/editor.tscn"
const KONTROLLER_SAHNESI := "res://scenes/kontroller.tscn"

@onready var oyna_dugmesi: Button = %OynaDugmesi
@onready var editor_dugmesi: Button = %EditorDugmesi
@onready var kontroller_dugmesi: Button = %KontrollerDugmesi
@onready var cik_dugmesi: Button = %CikDugmesi


func _ready() -> void:
	# Görünüm (yalnızca görsel): laboratuvar arka planı ve ortak tema.
	theme = LabTema.olustur()
	var arka := LabArkaplani.new()
	arka.name = "LabArkaplani"
	add_child(arka)
	move_child(arka, 0)
	var anim := Control.new()
	anim.set_script(load("res://scripts/menu_animasyon.gd"))
	anim.name = "Animasyon"
	add_child(anim)
	move_child(anim, 1)
	var baslik: Label = $Ortala/Kutu/Baslik
	baslik.add_theme_color_override("font_color", LabPaleti.CAMGOBEGI.lightened(0.45))
	baslik.add_theme_color_override("font_outline_color", LabPaleti.KENAR)
	baslik.add_theme_constant_override("outline_size", 8)
	baslik.add_theme_font_size_override("font_size", 64)
	var ayrac := ColorRect.new()
	ayrac.color = Color(LabPaleti.CAMGOBEGI, 0.55)
	ayrac.custom_minimum_size = Vector2(0, 3)
	ayrac.mouse_filter = Control.MOUSE_FILTER_IGNORE
	baslik.get_parent().add_child(ayrac)
	baslik.get_parent().move_child(ayrac, baslik.get_index() + 1)
	for d in [oyna_dugmesi, editor_dugmesi, kontroller_dugmesi, cik_dugmesi]:
		d.custom_minimum_size = Vector2(0, 48)
		d.add_theme_font_size_override("font_size", 24)
		d.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	oyna_dugmesi.pressed.connect(_on_oyna)
	editor_dugmesi.pressed.connect(_on_editor)
	kontroller_dugmesi.pressed.connect(_on_kontroller)
	cik_dugmesi.pressed.connect(get_tree().quit)
	oyna_dugmesi.grab_focus()


func _on_editor() -> void:
	get_tree().change_scene_to_file(EDITOR_SAHNESI)


func _on_kontroller() -> void:
	get_tree().change_scene_to_file(KONTROLLER_SAHNESI)


func _on_oyna() -> void:
	get_tree().change_scene_to_file(HARITA_SAHNESI)
