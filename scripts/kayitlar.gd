extends Node
## Autoload: biten turların girdi kayıtlarını sahne yeniden yüklense de saklar.
## Her tur, kare başına bir girdi sözlüğü içeren dizidir (indeks = fizik karesi).

var turlar: Array = []


func tur_kaydet(kayit: Array) -> void:
	turlar.append(kayit)


## Tüm kayıtları siler (bölüm bitince / menüye dönünce yeni oyun için).
func sifirla() -> void:
	turlar.clear()
