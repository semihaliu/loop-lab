class_name EditorOturumu
extends RefCounted
## Editörden Dene'ye giderken sahne değişse de kaybolmaması gereken durum (yalnız statik veri).
## Dene'ye hiç girilmeden açılan editör `donus` false görür, `temizle()` çağırır ve boş başlar.

## Dene'den editöre dönülüyor mu (editör `_ready`'de durumu geri yükler, sonra false yapar).
static var donus: bool = false
## Düzenlenen bölüm (BolumVerisi biçimi).
static var veri: Dictionary = {}
## Geri al yığını ve indeksi.
static var gecmis: Array = []
static var gecmis_i: int = -1
static var kimlik_kilitli: bool = false
static var kilit_kimlik: String = ""
static var son_yol: String = ""
static var secili: String = ""
## Son Kaydet/Aç/Yeni anındaki kanonik metin (kirlilik karşılaştırması için).
static var temiz_goruntu: String = ""
## Dene'den gelen açık kayıt: {"turlar": [kayıt, ...], "oyuncu": [kare, ...]}; boşsa çözüm yok.
static var cozum: Dictionary = {}
## Doğrulama sonucu (EditorDogrulama yazar, editör dönüşte işler); boşsa yok.
## {"iptal": bool} ya da {"iptal": false, "durum", "hata", "uyari", "bitis_kare", "sorunlar"}.
static var dogrulama: Dictionary = {}
## Bölümlerim'den "Aç": editörün ilk açılışta yükleyeceği JSON yolu ("" = yok) ve dosya kökü.
static var ac_yolu: String = ""
static var kok: String = ""


static func temizle() -> void:
	donus = false
	veri = {}
	gecmis = []
	gecmis_i = -1
	kimlik_kilitli = false
	kilit_kimlik = ""
	son_yol = ""
	secili = ""
	temiz_goruntu = ""
	cozum = {}
	dogrulama = {}
	ac_yolu = ""
	kok = ""
