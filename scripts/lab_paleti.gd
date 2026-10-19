class_name LabPaleti
extends RefCounted
## "Terk edilmiş zaman laboratuvarı" teması: tek ortak renk paleti (bkz. docs/stil.md).
## Yalnızca görünüm içindir; oyun mantığı bu renklere bakmaz.

## Ekran yoksa (--headless testler) çizim yapılmaz: hiçbir şey görünmediği için çizim
## betikleri boşuna çalışmasın (test süresi). Oyun mantığına etkisi yoktur.
static func ekransiz() -> bool:
	return DisplayServer.get_name() == "headless"


# Arka plan ve yüzeyler
const ARKA_UST := Color("0b1014")
const ARKA_ALT := Color("16222a")
const DUVAR := Color("1c282e")
const PANEL := Color("26353c")
const PANEL_ACIK := Color("33464f")
const KENAR := Color("070b0e")
# Metaller
const PASLI := Color("4b4038")
const PAS := Color("8a5230")
const METAL := Color("6b7a82")
const METAL_ACIK := Color("a3b4ba")
# Işıklar
const CAMGOBEGI := Color("5fe0cf")
const CAM_SOLUK := Color("2f7f78")
const YESIL := Color("7dff9b")
const AMBER := Color("e3a53c")
const UYARI := Color("ff4a38")
const UYARI_KOYU := Color("7a1d16")
const MOR := Color("8a6fc9")
const MOR_KOYU := Color("3e3360")
# Karakterler
const ONLUK := Color("eef1ea")
const DERI := Color("e2b392")
const SAC := Color("4a3326")
const PANTOLON := Color("3d566b")
const KLON := Color("6cc8ff")
const KLON_ACIK := Color("c8f0ff")
const OLU := Color("5a6670")
# Taşıma bandı (zeminden ayrışsın: koyu kehribar kemer + parlak amber ok)
const BANT_ZEMIN := Color("3a2610")
const BANT_OK := Color("ffc94d")
const BANT_OLUK := Color("120b04")
