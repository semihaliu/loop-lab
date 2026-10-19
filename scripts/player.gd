extends CharacterBody2D
## Oyuncu karakteri: sağ, sol, zıpla.
## Aynı betik hem canlı oyuncuyu hem klonu çalıştırır; tek fark girdi kaynağıdır
## (klavye / kayıt). Böylece klon gerçek karakter gibi davranır.

const HIZ := 300.0
const ZIPLAMA_HIZI := -520.0
const YER_CEKIMI := 1400.0  # sabit değer: ProjectSettings'e bağlı kalmasın
const BOS_GIRDI := {"yon": 0.0, "zipla": false, "asagi": false}
## Aşağı tuşuyla tek yönlü platformun yok sayılacağı sabit fizik karesi sayısı.
const ASAGI_DUSME_KARE := 12

## true ise girdi klavyeden değil kayit_girdileri'nden okunur.
var klon := false
## Canlı oyuncuda: kare kare kaydedilen girdiler. Klonda: oynatılacak kayıt.
var kayit_girdileri: Array = []
## Bu turda geçen fizik karesi sayısı (kayıt indeksi).
var kare := 0
## Öldü mü? Klonda yerinde donar, canlı oyuncuda sinyal bir kez yayılır.
var oldu := false
## Ölümün gerçekleştiği kare (klonda kayıt dışı bilgi; deterministik).
var oldu_kare := -1
## Aşağı düşmek için geçici yok sayılan tek yönlü platform ve kalan kare sayısı.
var _yok_sayilan: PhysicsBody2D = null
var _yok_sayma_kare := 0

## Canlı oyuncu öldüğünde bir kez yayılır (bolum.gd turu yeniden başlatır).
signal oyuncu_oldu


func _ready() -> void:
	# Katmanlar (bkz. docs/kararlar.md): 1 = dünya, 2 = oyuncu, 3 = klon.
	# Oyuncu ve klonlar yalnızca dünyayla (zemin, asansör, kapı) çarpışır, birbirleriyle çarpışmaz.
	collision_mask = 1
	# Görünüm: eski renkli kutu gizlenir, insan çizimi eklenir (yalnızca görsel).
	$Gorsel.visible = false
	add_child(OyuncuGorunum.new())
	if klon:
		collision_layer = 1 << 2
		$Gorsel.color = Color(0.4, 0.7, 1.0, 0.7)
	else:
		collision_layer = 1 << 1


## O anki klavye girdisini döndürür: yön (-1, 0, 1) ve zıplama isteği.
func klavye_girdisi() -> Dictionary:
	return {
		"yon": Input.get_axis("sol", "sag"),
		"zipla": Input.is_action_just_pressed("zipla"),
		"asagi": Input.is_action_pressed("asagi"),
	}


## Bu kare için girdiyi verir: klonda kayıttan, oyuncuda klavyeden.
## Kayıt bittiyse klon boş girdiyle yerinde bekler.
func girdi_al() -> Dictionary:
	if klon:
		if kare < kayit_girdileri.size():
			return kayit_girdileri[kare]
		return BOS_GIRDI
	return klavye_girdisi()


## Verilen girdiyle bir fizik karesi hareket uygular.
func hareket_uygula(girdi: Dictionary, delta: float) -> void:
	_asagi_dusmeyi_guncelle(girdi.get("asagi", false))
	if not is_on_floor():
		velocity.y += YER_CEKIMI * delta

	if girdi["zipla"] and is_on_floor():
		# Zıplatıcı aynı karede daha güçlü fırlattıysa onu ezme (yerdeyken velocity.y >= 0)
		velocity.y = minf(velocity.y, ZIPLAMA_HIZI)

	velocity.x = girdi["yon"] * HIZ
	move_and_slide()
	_it_kutuyu(girdi["yon"], delta)


## Aşağı tuşu: üstünde durulan tek yönlü platform bu karakter için ASAGI_DUSME_KARE kare
## çarpışma istisnasına alınır (kutu ve diğer karakterler etkilenmez), sonra tekrar katı olur.
## Karakterin hemen altı test_only hareketle yoklanır; deterministiktir (gerçek saat yok).
func _asagi_dusmeyi_guncelle(asagi: bool) -> void:
	if _yok_sayilan != null:
		_yok_sayma_kare -= 1
		if _yok_sayma_kare <= 0:
			if is_instance_valid(_yok_sayilan):
				remove_collision_exception_with(_yok_sayilan)
			_yok_sayilan = null
		return
	if not asagi:
		return
	# Duvara yaslıyken kayma listesi zemini vermeyebilir: hemen altı test_only ile yoklanır.
	var c := move_and_collide(Vector2(0, 4), true)
	if c == null or c.get_normal().y > -0.7:
		return
	var govde := c.get_collider() as PhysicsBody2D
	if govde == null:
		return
	var sahip := govde.shape_find_owner(c.get_collider_shape_index())
	if govde.is_shape_owner_one_way_collision_enabled(sahip):
		_yok_sayilan = govde
		_yok_sayma_kare = ASAGI_DUSME_KARE
		add_collision_exception_with(_yok_sayilan)


## Yatayda itilen bir nesne (kutu: `it` metodu var) varsa o kare için itme isteği gönderir.
## Kutusuz bölümlerde hiçbir çarpışma `it`e sahip olmadığından etkisizdir.
func _it_kutuyu(yon: float, delta: float) -> void:
	if yon == 0.0:
		return
	for i in range(get_slide_collision_count()):
		var c := get_slide_collision(i)
		if absf(c.get_normal().x) > 0.9 and signf(c.get_normal().x) == -signf(yon):
			var k := c.get_collider()
			if k != null and k.has_method("it"):
				k.it(yon * HIZ * delta)


## Öldürür (lazer vb.). Klon: yerinde donar, katmanları kapanır. Canlı oyuncu: sinyal yayar.
func oldur() -> void:
	if oldu:
		return
	oldu = true
	oldu_kare = kare
	velocity = Vector2.ZERO
	if klon:
		# Plakayı basılı tutmaz, asansörü durdurmaz, kapıya/geçide etkisizdir.
		# Fizik işlemesi _physics_process başında oldu bayrağıyla durur.
		# Çarpışma değişikliği fizik sorgusu sırasında olabileceği için ertelenir.
		set_deferred("collision_layer", 0)
		set_deferred("collision_mask", 0)
		$Gorsel.color = Color(0.2, 0.3, 0.45, 0.4)
	else:
		oyuncu_oldu.emit()


func _physics_process(delta: float) -> void:
	if oldu:
		return
	var girdi := girdi_al()
	if not klon:
		kayit_girdileri.append(girdi)
	hareket_uygula(girdi, delta)
	kare += 1
