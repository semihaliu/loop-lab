class_name BolumYollari
extends RefCounted
## Kullanıcı bölümlerinin dizinleri ve bir sahne yolunun "kipi" (resmî, dene, özel, canlı).
## Çekirdek dosyadır: editör betiklerine bağımlı değildir; çekirdek betikler (bölüm listesi,
## sonuç ekranı, ekran butonları) yalnızca bunu kullanır. Dosya yazmaz, sahne kurmaz.
##
## Kök dizin (`kok`) varsayılan olarak "user://"dır; testlerde "user://test_editor/" verilir.

const VARSAYILAN_KOK := "user://"
## Ev butonu ve sonuç ekranı "Menü" dönüş sahneleri (yalnızca yol: editör sınıflarına başvurulmaz).
const MENU_SAHNESI := "res://scenes/ana_menu.tscn"
const EDITOR_SAHNESI := "res://scenes/editor.tscn"
const BOLUMLERIM_SAHNESI := "res://scenes/bolumlerim.tscn"


## Kök dizinin sonuna gerekirse "/" ekler.
static func _kok(kok: String) -> String:
	if kok != "" and not kok.ends_with("/"):
		return kok + "/"
	return kok


## Bölümlerim (düzenlenen JSON kopyaları) dizini.
static func bolumler_dizini(kok: String = VARSAYILAN_KOK) -> String:
	return _kok(kok) + "bolumler/"


## Dene ve doğrulama için geçici sahne dizini.
static func editor_dizini(kok: String = VARSAYILAN_KOK) -> String:
	return _kok(kok) + "editor/"


## Bölümlerim'den "Oyna" ile açılan geçici sahne dizini.
static func oyna_dizini(kok: String = VARSAYILAN_KOK) -> String:
	return _kok(kok) + "oyna/"


## Canlıya alınan bölümlerin dizini.
static func canli_dizini(kok: String = VARSAYILAN_KOK) -> String:
	return _kok(kok) + "canli/"


## Sahne yolundan kip: &"resmi" | &"dene" | &"ozel" | &"canli" | &"".
## "user://" ile başlamayan her yol resmîdir. Başlıyorsa yolun bulunduğu dizinin adına ve
## dosya adına bakılır; kök dizinden bağımsızdır.
static func kip(yol: String) -> StringName:
	if not yol.begins_with("user://"):
		return &"resmi"
	var d := yol.get_base_dir().get_file()
	var f := yol.get_file()
	if d == "editor" and f.begins_with("dene_"):
		return &"dene"
	if d == "oyna" and f.begins_with("oyna_"):
		return &"ozel"
	if d == "canli" and f.ends_with(".tscn"):
		return &"canli"
	return &""


static func dene_mi(yol: String) -> bool:
	return kip(yol) == &"dene"


static func ozel_mi(yol: String) -> bool:
	return kip(yol) == &"ozel"


static func canli_mi(yol: String) -> bool:
	return kip(yol) == &"canli"


## Ev butonu ve sonuç ekranı "Menü" dönüşü (taslak §5.3): dene → editör, özel → Bölümlerim, aksi ana menü.
static func ev_sahnesi(yol: String) -> String:
	match kip(yol):
		&"dene":
			return EDITOR_SAHNESI
		&"ozel":
			return BOLUMLERIM_SAHNESI
	return MENU_SAHNESI
