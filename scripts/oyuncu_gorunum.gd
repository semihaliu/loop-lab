class_name OyuncuGorunum
extends Node2D
## Oyuncu ve klonun insan görünümü (yalnızca çizim; 28x48 çarpışma kutusuna sığar).
## Poz yalnızca üst düğümün velocity, is_on_floor() ve kare sayacından türetilir;
## hiçbir oyun durumunu değiştirmez, rastgelelik yoktur.
## Oyuncu: açık laboratuvar önlüğü, amber şerit. Klon: mavi-camsı hologram, tarama çizgili.
## Ölü klon: gri-koyu, soluk, hareketsiz.

var _bakis := 1.0


func _process(_delta: float) -> void:
	if LabPaleti.ekransiz():
		return
	var ust: CharacterBody2D = get_parent()
	if not ust.oldu and absf(ust.velocity.x) > 1.0:
		_bakis = signf(ust.velocity.x)
	queue_redraw()


func _draw() -> void:
	if LabPaleti.ekransiz():
		return
	var ust: CharacterBody2D = get_parent()
	var klon: bool = ust.klon
	var olu: bool = ust.oldu
	var yerde: bool = ust.is_on_floor()
	var vx: float = ust.velocity.x
	var vy: float = ust.velocity.y
	# Poz: 0 bekleme, 1 koşma (4 kare döngü), 2 yükseliş, 3 düşüş
	var poz := 0
	var adim := 0
	if olu:
		poz = 0
	elif not yerde:
		poz = 2 if vy < 0.0 else 3
	elif absf(vx) > 1.0:
		poz = 1
		adim = int(ust.kare / 5) % 4
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(_bakis, 1.0))

	# Renkler
	var onluk := LabPaleti.ONLUK
	var pantolon := LabPaleti.PANTOLON
	var deri := LabPaleti.DERI
	var sac := LabPaleti.SAC
	var seri := LabPaleti.AMBER
	var hat := LabPaleti.KENAR
	var alfa := 1.0
	if klon:
		onluk = LabPaleti.KLON_ACIK
		pantolon = LabPaleti.KLON.darkened(0.2)
		deri = LabPaleti.KLON_ACIK
		sac = LabPaleti.KLON
		seri = LabPaleti.CAMGOBEGI
		hat = Color("1a4f7a")
		alfa = 0.68
	if olu:
		onluk = LabPaleti.OLU.lightened(0.15)
		pantolon = LabPaleti.OLU.darkened(0.2)
		deri = LabPaleti.OLU
		sac = LabPaleti.OLU.darkened(0.3)
		seri = LabPaleti.OLU
		hat = Color("1b2228")
		alfa = 0.45
	var mod := Color(1, 1, 1, alfa)

	# Uzuv konumları (ayak y = +24, kafa tepesi y = -24)
	var kalca := Vector2(0, 7)
	var omuz := Vector2(0, -8)
	var sol_ayak := Vector2(-4, 24)
	var sag_ayak := Vector2(4, 24)
	var sol_el := Vector2(-8, 4)
	var sag_el := Vector2(8, 4)
	match poz:
		1:
			match adim:
				0:
					sol_ayak = Vector2(-9, 24)
					sag_ayak = Vector2(8, 20)
					sol_el = Vector2(6, 2)
					sag_el = Vector2(-7, 3)
				1:
					sol_ayak = Vector2(-2, 24)
					sag_ayak = Vector2(2, 24)
					sol_el = Vector2(0, 4)
					sag_el = Vector2(0, 4)
				2:
					sol_ayak = Vector2(-8, 20)
					sag_ayak = Vector2(9, 24)
					sol_el = Vector2(-7, 3)
					sag_el = Vector2(6, 2)
				3:
					sol_ayak = Vector2(-2, 24)
					sag_ayak = Vector2(2, 24)
					sol_el = Vector2(0, 4)
					sag_el = Vector2(0, 4)
		2:
			# Yükseliş: kollar yukarı, bacaklar toplanmış
			sol_ayak = Vector2(-5, 19)
			sag_ayak = Vector2(5, 21)
			sol_el = Vector2(-9, -15)
			sag_el = Vector2(9, -15)
		3:
			# Düşüş: kollar yana açık, bacaklar hafif açık
			sol_ayak = Vector2(-8, 24)
			sag_ayak = Vector2(8, 24)
			sol_el = Vector2(-12, -3)
			sag_el = Vector2(12, -3)

	# Arkadaki kol ve bacak (hafif koyu), önce
	var koyu := Color(0.75, 0.75, 0.75, 1.0) * mod
	draw_line(kalca + Vector2(-3, 0), sol_ayak, hat * mod, 6.0)
	draw_line(kalca + Vector2(-3, 0), sol_ayak, pantolon.darkened(0.2) * mod, 4.0)
	draw_line(omuz + Vector2(-5, 0), sol_el, hat * mod, 5.0)
	draw_line(omuz + Vector2(-5, 0), sol_el, onluk * koyu, 3.0)
	# Önlük gövdesi: omuzdan kalçaya, etek hafif geniş
	var govde := PackedVector2Array([Vector2(-7, -9), Vector2(7, -9), Vector2(8, 11), Vector2(-8, 11)])
	draw_colored_polygon(PackedVector2Array([Vector2(-8, -10), Vector2(8, -10), Vector2(9, 12), Vector2(-9, 12)]), hat * mod)
	draw_colored_polygon(govde, onluk * mod)
	# Önlük ön yırtmacı, yaka ve göğüs cebi/şeridi
	draw_line(Vector2(0, -9), Vector2(0, 11), Color(0, 0, 0, 0.25 * alfa), 1.0)
	draw_rect(Rect2(2, -3, 4, 3), seri * mod)
	draw_colored_polygon(PackedVector2Array([Vector2(-4, -9), Vector2(4, -9), Vector2(0, -4)]), pantolon.lightened(0.1) * mod)
	# Önde bacak
	draw_line(kalca + Vector2(3, 0), sag_ayak, hat * mod, 6.0)
	draw_line(kalca + Vector2(3, 0), sag_ayak, pantolon * mod, 4.0)
	# Ayaklar
	draw_rect(Rect2(sol_ayak.x - 3, sol_ayak.y - 2, 7, 3), hat * mod)
	draw_rect(Rect2(sag_ayak.x - 3, sag_ayak.y - 2, 7, 3), hat * mod)
	# Önde kol
	draw_line(omuz + Vector2(5, 0), sag_el, hat * mod, 5.0)
	draw_line(omuz + Vector2(5, 0), sag_el, onluk * mod, 3.0)
	draw_circle(sol_el, 2.0, deri * mod)
	draw_circle(sag_el, 2.0, deri * mod)
	# Kafa
	var kafa := Vector2(0, -17)
	draw_circle(kafa, 8.0, hat * mod)
	draw_circle(kafa, 6.5, deri * mod)
	# Saç (üst yarı) ve göz (bakış yönünde)
	draw_arc(kafa, 6.6, PI * 1.05, PI * 1.95, 12, sac * mod, 4.0)
	if olu:
		draw_line(Vector2(1, -19), Vector2(5, -15), hat * mod, 1.5)
		draw_line(Vector2(5, -19), Vector2(1, -15), hat * mod, 1.5)
	else:
		draw_circle(Vector2(3, -17), 1.3, hat * mod)
	# Klon: tarama çizgileri ve dış parıltı
	if klon and not olu:
		var y := -24.0
		while y < 24.0:
			draw_line(Vector2(-12, y), Vector2(12, y), Color(LabPaleti.KLON_ACIK, 0.25), 1.0)
			y += 6.0
		draw_arc(kafa, 9.5, 0.0, TAU, 20, Color(LabPaleti.KLON, 0.35), 1.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
