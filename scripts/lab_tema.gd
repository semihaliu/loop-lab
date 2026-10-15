class_name LabTema
extends RefCounted
## Menü, sonuç ve ekran butonları için ortak Theme (koddan; yalnızca görünüm).


static func _stil(dolgu: Color, kenar: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = dolgu
	s.border_color = kenar
	s.set_border_width_all(2)
	s.set_corner_radius_all(6)
	s.content_margin_left = 14.0
	s.content_margin_right = 14.0
	s.content_margin_top = 8.0
	s.content_margin_bottom = 8.0
	return s


static func olustur() -> Theme:
	var t := Theme.new()
	t.set_stylebox("normal", "Button", _stil(LabPaleti.PANEL, LabPaleti.CAM_SOLUK))
	t.set_stylebox("hover", "Button", _stil(LabPaleti.PANEL_ACIK, LabPaleti.CAMGOBEGI))
	t.set_stylebox("pressed", "Button", _stil(LabPaleti.DUVAR, LabPaleti.AMBER))
	t.set_stylebox("disabled", "Button", _stil(LabPaleti.DUVAR, LabPaleti.KENAR))
	t.set_stylebox("focus", "Button", _stil(Color(0, 0, 0, 0), LabPaleti.AMBER))
	t.set_color("font_color", "Button", Color("dce8e8"))
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", LabPaleti.AMBER)
	t.set_color("font_focus_color", "Button", Color.WHITE)
	t.set_color("icon_normal_color", "Button", Color("dce8e8"))
	t.set_color("icon_hover_color", "Button", Color.WHITE)
	t.set_color("icon_pressed_color", "Button", LabPaleti.AMBER)
	t.set_color("font_color", "Label", Color("dce8e8"))
	t.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.6))
	t.set_constant("shadow_offset_x", "Label", 2)
	t.set_constant("shadow_offset_y", "Label", 2)
	return t


## Sonuç kutusunun arkasındaki panel için stil.
static func panel_stili() -> StyleBoxFlat:
	var s := _stil(Color(LabPaleti.DUVAR, 0.96), LabPaleti.CAM_SOLUK)
	s.set_border_width_all(3)
	s.set_corner_radius_all(10)
	s.shadow_color = Color(0, 0, 0, 0.5)
	s.shadow_size = 12
	return s
