extends Node2D
## Şalter: yere sabit, iki konumlu (sol / sağ), itilerek çalışır, etkileşim tuşu yoktur.
## Konum kalıcıdır (basınç plakası gibi üstünde durmak gerekmez). Sahne her turda
## yeniden yüklendiği için her tur başlangıç konumunda başlar; klonlar tekrar iter.
##
## Kural: şalter SOLDA iken sol yarıdaki bir karakter SAĞA yön girdisi (yon > 0) verirse
## SAĞA geçer; SAĞDA iken sağ yarıdaki bir karakter SOLA yön girdisi (yon < 0) verirse
## SOLA geçer. Bakılan şey hız değil, karakterin o karede uygulanacak girdisidir
## (oyuncuda klavye, klonda kayıt: aynı `girdi_al()` kod yolu).
##
## Güncelleme sırası: şalter sahne ağacında karakterlerden önce durur; kendi karesinde
## karakterlerin `girdi_al()` değerini okur (bu o karede uygulanacak girdidir, çünkü
## karakterler `kare` indeksini şalterden sonra artırır). Çakışma bilgisi bir önceki
## fizik adımından gelir. Bu sıra sabit olduğu için sonuç deterministiktir.

const KARAKTER_KATMANLARI := (1 << 1) | (1 << 2)  # 2 = oyuncu, 3 = klon
const KOL_ACISI := 0.7  # radyan

## Başlangıç konumu (varsayılan sol).
@export var baslangic_sagda := false

## true ise şalter sağ konumdadır.
var sagda := false

@onready var sol_alan: Area2D = $SolAlan
@onready var sag_alan: Area2D = $SagAlan
@onready var kol: ColorRect = $Kol


func _ready() -> void:
	sagda = baslangic_sagda
	for alan in [sol_alan, sag_alan]:
		alan.collision_layer = 0
		alan.collision_mask = KARAKTER_KATMANLARI
	$Taban.visible = false
	kol.visible = false
	Gorunum.ekle(self, Gorunum.Tur.SALTER)
	_gorseli_guncelle()


func _physics_process(_delta: float) -> void:
	# Sağdaysa sağ yarı ve sola yön, soldaysa sol yarı ve sağa yön tetikler.
	var alan := sag_alan if sagda else sol_alan
	var gerekli_yon := -1.0 if sagda else 1.0
	# Birden fazla karakter varsa "herhangi biri tetiklerse bir kez geçer" (sıradan bağımsız).
	for govde in alan.get_overlapping_bodies():
		if not govde.has_method("girdi_al"):
			continue
		var yon: float = govde.girdi_al()["yon"]
		if yon * gerekli_yon > 0.0:
			sagda = not sagda
			_gorseli_guncelle()
			return


func _gorseli_guncelle() -> void:
	kol.rotation = KOL_ACISI if sagda else -KOL_ACISI
	kol.color = Color(0.3, 0.8, 0.4) if sagda else Color(0.85, 0.35, 0.3)
