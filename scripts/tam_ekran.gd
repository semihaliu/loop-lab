extends Node
## Autoload: F11 ile tam ekran / pencere geçişi. Oyun durumuna dokunmaz, yalnızca pencere kipini değiştirir.


func _input(olay: InputEvent) -> void:
	if olay is InputEventKey and olay.pressed and not olay.echo and olay.physical_keycode == KEY_F11:
		_gecis_yap()
		get_viewport().set_input_as_handled()


func _gecis_yap() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var pencere := get_window()
	if pencere.mode == Window.MODE_FULLSCREEN or pencere.mode == Window.MODE_EXCLUSIVE_FULLSCREEN:
		pencere.mode = Window.MODE_WINDOWED
	else:
		pencere.mode = Window.MODE_FULLSCREEN
