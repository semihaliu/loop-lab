# Görünürlük taraması raporu (Parça 1 / madde 1)

Tarih: 2026-10-16. Yalnızca rapor; fizik, konum, sahne ve kod dosyalarına dokunulmadı. Tarama betikleri geçici (scratchpad): sahneleri okuyan GDScript + çizim/örtme analizi yapan Python.

## Özet

1. 20 bölümde 330 çarpışma/tetikleyici nesnesi tarandı (12 şalter alanı = 6 şalter dahil; 20 oyuncu ve çalışma anında kurulan görünmez `SinirDuvarlari` hariç); **24 tanesinin ekranda çizimi yok**.
2. Tek kök neden: `scripts/gorunum.gd` `_draw()` içindeki `match` dört türü içermiyor (`KUTU`, `ZIPLATICI`, `PLAKA_ZAMANLI`, `PLAKA_MANDAL`); çizim fonksiyonları yazılı ama çağrılmıyor ve eski düz `Gorsel` kutuları betiklerde gizleniyor. Etkilenen: 12 zıplatıcı (B11 x2, 12, 13, 14 x2, 15, 16 x2, 17 x2, 20), 6 kutu (B9, 10, 12, 14, 16, 17), 4 zamanlı plaka (B15, 17, 18, 19), 2 mandal plaka (B16, 17).
3. Bölüm 13 zıplatıcısı (x490..550, y588..600) ve Bölüm 15 `PlakaZ` (x90..150, y584..600, oyuncunun doğduğu yer) aynı nedenle görünmez; z_index/gömülme sorunu YOK. Bölüm 15 sonunda çizimsiz çarpışma bulunamadı (madde 2b).
4. İkinci sorun: 7 taşıma bandında (B10 x2, B13 x2, B14, B17, B20) `bolum.gd` bandın üstüne ikinci bir `DUVAR` çizimi ekliyor; bant görünür ama kemer/ok/yön çizimi örtülüyor (okunabilirlik).
5. Konum değişimi adayları az: B14 `PlakaR` (+20 px sağa), B10 `PlakaPG` (tasarım kararı); görünmez blok = kutu (B14 ve B10 adayları), yalnız görünümle çözülür. B18/19/20'de başka görünmez işlev yok.

## Ortak kök neden ve önerilen düzeltme (yalnız görünüm)

`scripts/gorunum.gd` `_draw()` match'ine eklenecek kollar (fonksiyonlar dosyada hazır):

```
Tur.KUTU: _kutu()
Tur.ZIPLATICI: _ziplatici()
Tur.PLAKA_ZAMANLI: _plaka(); _plaka_sayac()
Tur.PLAKA_MANDAL: _plaka(); _plaka_mandal()
```

Z-sırası doğrulaması: kutu/zıplatıcı/plaka `z_index=0` ve bölüm sahnelerinde zemin/kat gövdelerinden SONRA geldikleri (ağaç sırası) için üstte çizilirler; çizilecek dikdörtgenler çarpışma şeklinden türüyor (`Gorunum.sekil_alani`) ve kapsıyor. Zamanlı/mandal plakanın sayaç/kilit simgesi plakanın 14 px üstüne çizilir, tavanla çakışmıyor. Hiçbir çarpışma başka nesnenin çizimi altında kalmıyor (tarama: 0 örtme; asansör/geçit z=-1 tasarım gereği hariç).

## Madde 2 ayrıntıları

**(a) Bölüm 13 zıplatıcı.** `Ziplatici` konumu (520,594), alan 60x12 -> x490..550, y588..600; `ZeminSag` (y600..640) hemen altında. Gömülü/arkada değil: çizimi hiç yok (`Tur.ZIPLATICI` kolu eksik). Aynı bölümde `Kapak`, bantlar, plakalar, şalter, lazerler ve kapı çizili.

**(b) Bölüm 15.** Sol alttaki görünmez plaka = `PlakaZ` (zamanlı, x90..150, y584..600; oyuncu x=60). "Bölüm sonuna doğru görünmez blok": x>900 bölgesinde çizimsiz çarpışma YOK. Çizimsizler yalnız `PlakaZ` ve `Z1` zıplatıcı (x490..550). Sonda `GecitG` (x850..870, y180..380; kapalıyken görünür, açılınca tavana gömülür), `Raf` (tek yönlü, x1000..1120, y380..392, yalnız ince yeşil çizgi) ve `LazerB` (kapalıyken sönük noktalı kılavuz) var. Olası algı: açık geçidin tavana gömülüp yok olması ya da sönük kapalı lazer. Koddan kesinleştirilemedi, ekran görüntüsüyle doğrulanmalı; kural ihlali (çizimsiz çarpışma) değil.

**(c) Bölüm 16 ve 17 (Parça 3'te baştan yazılacak, yine de liste).** B16: `MP` mandal plaka (x420..480,y584..600), `Z1` (x120..180,y588..600), `Z2` (x480..540,y588..600), `Kutu` (x900..940,y340..380). B17: `PlakaZ` zamanlı (x470..530,y584..600), `PlakaM` mandal (x540..600,y584..600), `Z1` (x120..180), `Z2` (x620..680), `Kutu` (x1040..1080,y560..600); ayrıca B17 `Bant` çift çizim. Hepsi aynı kök neden.

**(d) Bant bölümleri (10, 13, 14, 17, 20) koordinat taraması.** Bantlar: B10 `Bant1` x270..430 y600..616 (->), `Bant2` x890..1050 y440..456 (<-); B13 `BantA` x100..260 y600..616, `BantC` x780..940 y400..416 (->); B14 `Bant` x490..650 y400..416 (->); B17 `Bant` x240..400 y380..396 (<-); B20 `Bant` x560..720 y160..176 (<-).

(i) Bandın hemen SOLUNDAki plaka adayları:

- **B14 `PlakaR`**: x470..530, y384..400; `Bant` sol ucu x=490: plakanın 20 px'i bandın SOLUNDA (`UL1` üstünde), 40 px'i bantta. Merkez x=500 -> 520 (+20 px) olursa tamamen bandın üstüne gelir. "Biraz sağa alınıp tam bandın üstüne" tarifine en iyi uyan aday (konum değişimi; Bölüm 14 ölçüm/testleri etkilenir, bkz. `docs/sorunlar.md` UL1/Bant dikişi bulgusu).
- **B10 `PlakaPG`**: x820..880, y424..440; `Bant2` sol ucu x=890 (10 px boşluk), plaka `Kat2Sol` (x812..890, üstü y=440) üstünde. Bant sola aktığı için plaka bandın çıkışında; büyük olasılıkla kasıtlı. Sağa almak çözümü değiştirir: tasarımcı/kullanıcı kararı.
- B10 `PlakaP1`: x380..440, `Bant1` sağ ucu x=430; plaka bandın SAĞ ucunu 10 px aşıp `Duvar` (x430..450) ile örtüşüyor. Sol değil, küçük kusur.
- B13 `PlakaA`/`PlakaC` tamamen bandın üstünde; B17 `PlakaA` (x410..470) bandın SAĞINDA; B20 bandında plaka yok. Aday değil.

(ii) Duvar kenarında, bantlı platformun yanında görünmeyen blok: çizimsiz ve çarpışması olan "blok" yalnızca **kutu** (6 adet). Bant bölümlerindeki kutular:

- **B14 `Kutu`**: x655..695, y360..400, `UL2` üstünde, bandın sağ ucundan (x=650) 5 px sağda, hemen yanında `GecitR` (x700..720). En güçlü aday.
- **B10 `Kutu`**: x160..200, y560..600; oyuncu x=50'de doğuyor, sol duvar kenarı; `Bant1` 70 px ötesinde. İkinci aday.
- B17 `Kutu` (x1040..1080 y560..600, `Ledge` yanı) bantlı platformla (y380) ilgisiz; B16 `Kutu` (x900..940 y340..380) bantsız bölümde.
Hepsi `Tur.KUTU` koluyla görünür olur; konum değişimi gerekmez.

**(e) Bölüm 18, 19, 20.** Görünmez işlev: B18 `PlakaZ` (zamanlı, x200..260 y584..600; altında asansör dinlenme konumu), B19 `PlakaZ` (aynı yer), B20 `Z1` zıplatıcı (x120..180 y588..600). Başka çizimsiz çarpışma/tetikleyici yok; asansör işaretleri zeminle örtülmüyor, geçitler kapalıyken tam görünür.

## Konum değişimi gerekenler / adaylar (hiçbiri uygulanmadı)

| bölüm | nesne | şimdiki konum | sorun | öneri |
|---|---|---|---|---|
| 14 | PlakaR | x470..530 (merkez 500) | Plaka bandın 20 px solunda taşıyor, UL1 üstünde yarım basıyor | merkezi ~x=520'ye al; Bölüm 14 testleri/çözüm ölçülmeli |
| 10 | PlakaPG | x820..880 (merkez 850) | Bant2'nin 10 px solunda, Kat2Sol üstünde | muhtemelen tasarım gereği; değişiklik çözümü etkiler, karar gerekir |
| 10 | PlakaP1 | x380..440 | Bant1 sağ ucu ve Duvar ile 10 px örtüşüyor | isteğe bağlı: ~10 px sola |

Bölüm numarası bilinmeyen durum (i) için kullanıcıdan hangi bölüm olduğu teyit edilmeli. Görünmez blok (ii) için konum değişimi gerekmez.

## Diğer bulgular (kural ihlali değil)

- Zemin/duvar/tavan/tek yönlü çizimleri çarpışma şekliyle birebir örtüşüyor (fark 0).
- Hiçbir plaka, kapı, lazer, şalter veya diğer nesne başka çizimin altında kalmıyor. B14 `UR` (x920..1000) ile `Kapak2` (tek yönlü) çarpışmaları çakışıyor; çizimde tek yönlü üstte.
- Asansör/geçit `z=-1` olduğundan zemin/tavan içinde örtülmeleri tasarımdır; her asansörün amber dinlenme işareti zeminin üstünde (örtülme 0%).
- `SinirDuvarlari` (sol/sağ/üst) çalışma anında kurulur, ekran dışındadır (x<0, x>1152, y<0) ve kullanıcı kararıyla görünmezdir; bu raporda hariç.
- Şalter algılama alanı (40x48 x2) taban çiziminden her yanda ~10 px taşar; sorun sayılmadı.

## Tüm nesneler (330 satır)

Görünür çizim: E = ekranda var, H = yok. Düzeltme "-" ise gerek yok.

| bölüm | nesne | tür | konum | görünür | sorun/gerekçe | önerilen düzeltme |
|---|---|---|---|---|---|---|
| 1 | Zemin | zemin/duvar/tavan | x0..1152 y600..640 | E | - | - |
| 1 | Cikinti | zemin/duvar/tavan | x680..1152 y420..460 | E | - | - |
| 1 | Plaka | basınç plakası | x320..380 y584..600 | E | - | - |
| 1 | Asansor | asansör | x560..680 y600..620 | E | z=-1: dinlenme konumunda zemine gömülü; üstte amber işaret şeridi çizili ve zeminle örtülmüyor (doğrulandı). Yükselince tam görünür. | - |
| 1 | Kapi | hedef kapı | x1032..1068 y372..420 | E | - | - |
| 2 | Zemin | zemin/duvar/tavan | x0..1152 y600..640 | E | - | - |
| 2 | F2Sol | zemin/duvar/tavan | x0..900 y440..500 | E | - | - |
| 2 | F2Sag | zemin/duvar/tavan | x1020..1152 y440..500 | E | - | - |
| 2 | CepDuvari | zemin/duvar/tavan | x1040..1050 y340..440 | E | - | - |
| 2 | F3Sol | zemin/duvar/tavan | x0..300 y280..340 | E | - | - |
| 2 | F3Orta | zemin/duvar/tavan | x420..1050 y280..340 | E | - | - |
| 2 | F3Sag | zemin/duvar/tavan | x1130..1152 y280..340 | E | - | - |
| 2 | Tavan | zemin/duvar/tavan | x0..1152 y110..180 | E | - | - |
| 2 | Plaka1 | basınç plakası | x270..330 y584..600 | E | - | - |
| 2 | Plaka2 | basınç plakası | x100..160 y424..440 | E | - | - |
| 2 | Asansor1 | asansör | x900..1020 y600..620 | E | z=-1: dinlenme konumunda zemine gömülü; üstte amber işaret şeridi çizili ve zeminle örtülmüyor (doğrulandı). Yükselince tam görünür. | - |
| 2 | Asansor2 | asansör | x300..420 y440..460 | E | z=-1: dinlenme konumunda zemine gömülü; üstte amber işaret şeridi çizili ve zeminle örtülmüyor (doğrulandı). Yükselince tam görünür. | - |
| 2 | Salter/SolAlan | şalter alanı | x520..560 y232..280 | E | Algılama alanı 40x48, taban çizimi 60 geniş; kapsıyor. | - |
| 2 | Salter/SagAlan | şalter alanı | x560..600 y232..280 | E | Algılama alanı 40x48, taban çizimi 60 geniş; kapsıyor. | - |
| 2 | Gecit | geçit | x790..810 y180..280 | E | z=-1: açık konumda tavan/kat içine gömülür (tasarım gereği); kapalıyken tam görünür. | - |
| 2 | Kapi | hedef kapı | x1072..1108 y392..440 | E | - | - |
| 3 | Zemin | zemin/duvar/tavan | x0..1152 y600..640 | E | - | - |
| 3 | Tavan | zemin/duvar/tavan | x0..1152 y100..400 | E | - | - |
| 3 | Plaka1 | basınç plakası | x230..290 y584..600 | E | - | - |
| 3 | Plaka2 | basınç plakası | x610..670 y584..600 | E | - | - |
| 3 | Lazer1 | lazer | x477..483 y400..600 | E | - | - |
| 3 | Lazer2 | lazer | x857..863 y400..600 | E | - | - |
| 3 | Kapi | hedef kapı | x1042..1078 y552..600 | E | - | - |
| 4 | Zemin | zemin/duvar/tavan | x0..1152 y600..640 | E | - | - |
| 4 | F2 | zemin/duvar/tavan | x400..960 y330..370 | E | - | - |
| 4 | F3Sol | zemin/duvar/tavan | x0..700 y200..240 | E | - | - |
| 4 | F3Sag | zemin/duvar/tavan | x820..1152 y200..240 | E | - | - |
| 4 | Tavan | zemin/duvar/tavan | x0..1152 y0..40 | E | - | - |
| 4 | PA | tek yönlü platform | x600..720 y445..457 | E | - | - |
| 4 | K | tek yönlü platform | x1010..1130 y445..457 | E | - | - |
| 4 | Plaka0 | basınç plakası | x170..230 y584..600 | E | - | - |
| 4 | PlakaA | basınç plakası | x650..710 y429..445 | E | - | - |
| 4 | PlakaC | basınç plakası | x1040..1100 y429..445 | E | - | - |
| 4 | Asansor0 | asansör | x520..640 y600..620 | E | z=-1: dinlenme konumunda zemine gömülü; üstte amber işaret şeridi çizili ve zeminle örtülmüyor (doğrulandı). Yükselince tam görünür. | - |
| 4 | Asansor1 | asansör | x280..400 y600..620 | E | z=-1: dinlenme konumunda zemine gömülü; üstte amber işaret şeridi çizili ve zeminle örtülmüyor (doğrulandı). Yükselince tam görünür. | - |
| 4 | Asansor2 | asansör | x700..820 y330..350 | E | z=-1: dinlenme konumunda zemine gömülü; üstte amber işaret şeridi çizili ve zeminle örtülmüyor (doğrulandı). Yükselince tam görünür. | - |
| 4 | Kapi | hedef kapı | x942..978 y152..200 | E | - | - |
| 5 | Zemin | zemin/duvar/tavan | x0..1152 y600..640 | E | - | - |
| 5 | Tavan | zemin/duvar/tavan | x0..1152 y100..400 | E | - | - |
| 5 | Sahanlik | zemin/duvar/tavan | x450..650 y470..510 | E | - | - |
| 5 | Plaka | basınç plakası | x10..70 y584..600 | E | - | - |
| 5 | Salter/SolAlan | şalter alanı | x520..560 y422..470 | E | Algılama alanı 40x48, taban çizimi 60 geniş; kapsıyor. | - |
| 5 | Salter/SagAlan | şalter alanı | x560..600 y422..470 | E | Algılama alanı 40x48, taban çizimi 60 geniş; kapsıyor. | - |
| 5 | Asansor | asansör | x330..450 y600..620 | E | z=-1: dinlenme konumunda zemine gömülü; üstte amber işaret şeridi çizili ve zeminle örtülmüyor (doğrulandı). Yükselince tam görünür. | - |
| 5 | Lazer1 | lazer | x717..723 y400..600 | E | - | - |
| 5 | Lazer2 | lazer | x897..903 y400..600 | E | - | - |
| 5 | Kapi | hedef kapı | x1042..1078 y552..600 | E | - | - |
| 6 | Zemin | zemin/duvar/tavan | x0..1152 y600..640 | E | - | - |
| 6 | Tavan1 | zemin/duvar/tavan | x0..590 y100..400 | E | - | - |
| 6 | Tavan2 | zemin/duvar/tavan | x590..1152 y100..300 | E | - | - |
| 6 | Seki | zemin/duvar/tavan | x952..1152 y450..490 | E | - | - |
| 6 | PlakaA | basınç plakası | x10..70 y584..600 | E | - | - |
| 6 | PlakaL | basınç plakası | x630..690 y584..600 | E | - | - |
| 6 | Asansor | asansör | x830..950 y600..620 | E | z=-1: dinlenme konumunda zemine gömülü; üstte amber işaret şeridi çizili ve zeminle örtülmüyor (doğrulandı). Yükselince tam görünür. | - |
| 6 | Gecit | geçit | x570..590 y400..600 | E | z=-1: açık konumda tavan/kat içine gömülür (tasarım gereği); kapalıyken tam görünür. | - |
| 6 | Lazer | lazer | x757..763 y300..600 | E | - | - |
| 6 | Kapi | hedef kapı | x1072..1108 y402..450 | E | - | - |
| 7 | Zemin | zemin/duvar/tavan | x0..1152 y600..640 | E | - | - |
| 7 | Kat2 | zemin/duvar/tavan | x0..838 y340..400 | E | - | - |
| 7 | Tavan | zemin/duvar/tavan | x0..1152 y100..180 | E | - | - |
| 7 | Duvar | zemin/duvar/tavan | x962..1152 y180..600 | E | - | - |
| 7 | PlakaA | basınç plakası | x10..70 y584..600 | E | - | - |
| 7 | PlakaB | basınç plakası | x670..730 y324..340 | E | - | - |
| 7 | PlakaC | basınç plakası | x470..530 y324..340 | E | - | - |
| 7 | Salter/SolAlan | şalter alanı | x220..260 y552..600 | E | Algılama alanı 40x48, taban çizimi 60 geniş; kapsıyor. | - |
| 7 | Salter/SagAlan | şalter alanı | x260..300 y552..600 | E | Algılama alanı 40x48, taban çizimi 60 geniş; kapsıyor. | - |
| 7 | Asansor | asansör | x840..960 y600..620 | E | z=-1: dinlenme konumunda zemine gömülü; üstte amber işaret şeridi çizili ve zeminle örtülmüyor (doğrulandı). Yükselince tam görünür. | - |
| 7 | Gecit | geçit | x430..450 y400..600 | E | z=-1: açık konumda tavan/kat içine gömülür (tasarım gereği); kapalıyken tam görünür. | - |
| 7 | Lazer1 | lazer | x597..603 y180..340 | E | - | - |
| 7 | Lazer2 | lazer | x377..383 y180..340 | E | - | - |
| 7 | Kapi | hedef kapı | x102..138 y292..340 | E | - | - |
| 8 | Zemin | zemin/duvar/tavan | x0..1152 y600..640 | E | - | - |
| 8 | K2 | zemin/duvar/tavan | x162..1152 y400..440 | E | - | - |
| 8 | K3 | zemin/duvar/tavan | x0..700 y200..240 | E | - | - |
| 8 | Tavan | zemin/duvar/tavan | x0..1152 y0..40 | E | - | - |
| 8 | Basamak1 | tek yönlü platform | x780..900 y330..342 | E | - | - |
| 8 | Basamak2 | tek yönlü platform | x700..820 y260..272 | E | - | - |
| 8 | Sekme | tek yönlü platform | x390..510 y120..132 | E | - | - |
| 8 | PlakaA | basınç plakası | x230..290 y584..600 | E | - | - |
| 8 | PlakaC | basınç plakası | x870..930 y584..600 | E | - | - |
| 8 | Salter/SolAlan | şalter alanı | x410..450 y72..120 | E | Algılama alanı 40x48, taban çizimi 60 geniş; kapsıyor. | - |
| 8 | Salter/SagAlan | şalter alanı | x450..490 y72..120 | E | Algılama alanı 40x48, taban çizimi 60 geniş; kapsıyor. | - |
| 8 | Asansor | asansör | x40..160 y600..620 | E | z=-1: dinlenme konumunda zemine gömülü; üstte amber işaret şeridi çizili ve zeminle örtülmüyor (doğrulandı). Yükselince tam görünür. | - |
| 8 | Gecit | geçit | x310..330 y40..240 | E | z=-1: açık konumda tavan/kat içine gömülür (tasarım gereği); kapalıyken tam görünür. | - |
| 8 | Lazer1 | lazer | x557..563 y240..400 | E | - | - |
| 8 | Lazer2 | lazer | x247..253 y40..200 | E | - | - |
| 8 | Lazer3 | lazer | x187..193 y40..200 | E | - | - |
| 8 | Kapi | hedef kapı | x62..98 y152..200 | E | - | - |
| 9 | Zemin | zemin/duvar/tavan | x0..1152 y600..640 | E | - | - |
| 9 | Kat2 | zemin/duvar/tavan | x702..1152 y440..600 | E | - | - |
| 9 | Tavan | zemin/duvar/tavan | x0..1152 y0..300 | E | - | - |
| 9 | Platform | tek yönlü platform | x340..460 y530..542 | E | - | - |
| 9 | Plaka1 | basınç plakası | x140..200 y584..600 | E | - | - |
| 9 | Plaka2 | basınç plakası | x370..430 y514..530 | E | - | - |
| 9 | Plaka3 | basınç plakası | x730..790 y424..440 | E | - | - |
| 9 | PlakaKutu | basınç plakası | x900..960 y424..440 | E | - | - |
| 9 | Asansor | asansör | x580..700 y600..620 | E | z=-1: dinlenme konumunda zemine gömülü; üstte amber işaret şeridi çizili ve zeminle örtülmüyor (doğrulandı). Yükselince tam görünür. | - |
| 9 | Gecit | geçit | x1060..1080 y240..440 | E | z=-1: açık konumda tavan/kat içine gömülür (tasarım gereği); kapalıyken tam görünür. | - |
| 9 | Lazer1 | lazer | x287..293 y300..600 | E | - | - |
| 9 | Lazer2 | lazer | x857..863 y300..440 | E | - | - |
| 9 | Kapi | hedef kapı | x1102..1138 y392..440 | E | - | - |
| 9 | Kutu | kutu | x480..520 y560..600 | H | `Gorunum._draw` match'inde `Tur.KUTU` kolu yok; `_kutu()` yazılı ama çağrılmıyor, düz `Gorsel` de gizli (kutu.gd). | yalnız görünüm: `gorunum.gd` `_draw` match'ine kol ekle (bkz. Ortak kök neden) |
| 10 | ZeminSol | zemin/duvar/tavan | x0..270 y600..640 | E | - | - |
| 10 | ZeminDolgu | zemin/duvar/tavan | x270..430 y616..640 | E | - | - |
| 10 | ZeminSag | zemin/duvar/tavan | x430..1152 y600..640 | E | - | - |
| 10 | Tavan | zemin/duvar/tavan | x0..1152 y0..300 | E | - | - |
| 10 | Kat2Sol | zemin/duvar/tavan | x812..890 y440..600 | E | - | - |
| 10 | Kat2Dolgu | zemin/duvar/tavan | x890..1050 y456..600 | E | - | - |
| 10 | Kat2Sag | zemin/duvar/tavan | x1050..1152 y440..600 | E | - | - |
| 10 | Duvar | zemin/duvar/tavan | x430..450 y560..600 | E | - | - |
| 10 | Bant1 | taşıma bandı | x270..430 y600..616 | E (kısmen) | Bant betiği kendi `BANT` çizimini ekliyor; ardından `bolum.gd:_gorunumu_kur` aynı gövdeye ikinci bir `DUVAR` çizimi ekliyor (aynı z, sonraki çocuk = üstte). Kemer, ok ve makara DUVAR panelinin altında kalıyor; bant düz tahta gibi görünür, yönü okunmaz. | yalnız görünüm: `bolum.gd` zaten `Gorunum` çocuğu olan gövdeyi atlasın |
| 10 | Bant2 | taşıma bandı | x890..1050 y440..456 | E (kısmen) | Bant betiği kendi `BANT` çizimini ekliyor; ardından `bolum.gd:_gorunumu_kur` aynı gövdeye ikinci bir `DUVAR` çizimi ekliyor (aynı z, sonraki çocuk = üstte). Kemer, ok ve makara DUVAR panelinin altında kalıyor; bant düz tahta gibi görünür, yönü okunmaz. | yalnız görünüm: `bolum.gd` zaten `Gorunum` çocuğu olan gövdeyi atlasın |
| 10 | PlakaP1 | basınç plakası | x380..440 y584..600 | E | Plaka (x380..440) Duvar (x430..450) ile 10 px örtüşüyor; plaka duvarın üstünde çizilir, okunur. | isteğe bağlı: konum (~10 px sola) |
| 10 | PlakaP2 | basınç plakası | x480..540 y584..600 | E | - | - |
| 10 | PlakaPE | basınç plakası | x580..640 y584..600 | E | - | - |
| 10 | PlakaPG | basınç plakası | x820..880 y424..440 | E | - | - |
| 10 | Asansor | asansör | x690..810 y600..620 | E | z=-1: dinlenme konumunda zemine gömülü; üstte amber işaret şeridi çizili ve zeminle örtülmüyor (doğrulandı). Yükselince tam görünür. | - |
| 10 | Gecit | geçit | x1055..1075 y240..440 | E | z=-1: açık konumda tavan/kat içine gömülür (tasarım gereği); kapalıyken tam görünür. | - |
| 10 | Lazer1 | lazer | x347..353 y300..600 | E | - | - |
| 10 | Lazer2 | lazer | x690..810 y507..513 | E | - | - |
| 10 | Kapi | hedef kapı | x1092..1128 y392..440 | E | - | - |
| 10 | Kutu | kutu | x160..200 y560..600 | H | `Gorunum._draw` match'inde `Tur.KUTU` kolu yok; `_kutu()` yazılı ama çağrılmıyor, düz `Gorsel` de gizli (kutu.gd). | yalnız görünüm: `gorunum.gd` `_draw` match'ine kol ekle (bkz. Ortak kök neden) |
| 11 | Zemin | zemin/duvar/tavan | x0..1152 y600..640 | E | - | - |
| 11 | Tavan | zemin/duvar/tavan | x0..1152 y0..60 | E | - | - |
| 11 | Kat2 | zemin/duvar/tavan | x420..1152 y380..600 | E | - | - |
| 11 | Kat3 | zemin/duvar/tavan | x760..1152 y160..280 | E | - | - |
| 11 | Raf | tek yönlü platform | x120..240 y420..432 | E | - | - |
| 11 | PlakaPA | basınç plakası | x150..210 y404..420 | E | - | - |
| 11 | PlakaPB | basınç plakası (kalın) | x668..728 y144..176 | E | - | - |
| 11 | Ziplatici1 | yaylı zıplatıcı | x310..370 y588..600 | H | `match`te `Tur.ZIPLATICI` kolu yok; `_ziplatici()` yazılı ama çağrılmıyor, düz `Gorsel` gizli (yayli_ziplatici.gd). | yalnız görünüm: `gorunum.gd` `_draw` match'ine kol ekle (bkz. Ortak kök neden) |
| 11 | Ziplatici2 | yaylı zıplatıcı | x610..670 y368..380 | H | `match`te `Tur.ZIPLATICI` kolu yok; `_ziplatici()` yazılı ama çağrılmıyor, düz `Gorsel` gizli (yayli_ziplatici.gd). | yalnız görünüm: `gorunum.gd` `_draw` match'ine kol ekle (bkz. Ortak kök neden) |
| 11 | Lazer1 | lazer | x877..883 y280..380 | E | - | - |
| 11 | Lazer2 | lazer | x883..889 y280..380 | E | - | - |
| 11 | Kapi | hedef kapı | x1082..1118 y332..380 | E | - | - |
| 12 | Zemin | zemin/duvar/tavan | x0..1152 y600..640 | E | - | - |
| 12 | Tavan | zemin/duvar/tavan | x0..1152 y0..140 | E | - | - |
| 12 | TavanSol | zemin/duvar/tavan | x0..480 y140..400 | E | - | - |
| 12 | Blok | zemin/duvar/tavan | x600..1152 y290..600 | E | - | - |
| 12 | Raf1 | tek yönlü platform | x480..600 y420..432 | E | - | - |
| 12 | Raf2 | tek yönlü platform | x480..600 y290..302 | E | - | - |
| 12 | PlakaK | basınç plakası | x170..230 y584..600 | E | - | - |
| 12 | PlakaA | basınç plakası | x10..70 y584..600 | E | - | - |
| 12 | PlakaB | basınç plakası | x710..770 y274..290 | E | - | - |
| 12 | Ziplatici | yaylı zıplatıcı | x530..590 y588..600 | H | `match`te `Tur.ZIPLATICI` kolu yok; `_ziplatici()` yazılı ama çağrılmıyor, düz `Gorsel` gizli (yayli_ziplatici.gd). | yalnız görünüm: `gorunum.gd` `_draw` match'ine kol ekle (bkz. Ortak kök neden) |
| 12 | GecitK | geçit | x370..390 y400..600 | E | z=-1: açık konumda tavan/kat içine gömülür (tasarım gereği); kapalıyken tam görünür. | - |
| 12 | GecitA1 | geçit | x690..710 y90..290 | E | z=-1: açık konumda tavan/kat içine gömülür (tasarım gereği); kapalıyken tam görünür. | - |
| 12 | GecitB | geçit | x970..990 y90..290 | E | z=-1: açık konumda tavan/kat içine gömülür (tasarım gereği); kapalıyken tam görünür. | - |
| 12 | GecitA2 | geçit | x1050..1070 y90..290 | E | z=-1: açık konumda tavan/kat içine gömülür (tasarım gereği); kapalıyken tam görünür. | - |
| 12 | Kapi | hedef kapı | x1094..1130 y242..290 | E | - | - |
| 12 | Kutu | kutu | x180..220 y560..600 | H | `Gorunum._draw` match'inde `Tur.KUTU` kolu yok; `_kutu()` yazılı ama çağrılmıyor, düz `Gorsel` de gizli (kutu.gd). | yalnız görünüm: `gorunum.gd` `_draw` match'ine kol ekle (bkz. Ortak kök neden) |
| 13 | ZeminSol | zemin/duvar/tavan | x0..100 y600..640 | E | - | - |
| 13 | BantAlti | zemin/duvar/tavan | x100..260 y616..640 | E | - | - |
| 13 | ZeminSag | zemin/duvar/tavan | x260..1152 y600..640 | E | - | - |
| 13 | Tavan | zemin/duvar/tavan | x0..1152 y0..150 | E | - | - |
| 13 | KatA | zemin/duvar/tavan | x640..780 y400..600 | E | - | - |
| 13 | BantDolgu | zemin/duvar/tavan | x780..940 y416..600 | E | - | - |
| 13 | KatB | zemin/duvar/tavan | x940..960 y400..600 | E | - | - |
| 13 | KatC | zemin/duvar/tavan | x1080..1152 y400..600 | E | - | - |
| 13 | Kapak | tek yönlü platform | x960..1080 y400..412 | E | - | - |
| 13 | BantA | taşıma bandı | x100..260 y600..616 | E (kısmen) | Bant betiği kendi `BANT` çizimini ekliyor; ardından `bolum.gd:_gorunumu_kur` aynı gövdeye ikinci bir `DUVAR` çizimi ekliyor (aynı z, sonraki çocuk = üstte). Kemer, ok ve makara DUVAR panelinin altında kalıyor; bant düz tahta gibi görünür, yönü okunmaz. | yalnız görünüm: `bolum.gd` zaten `Gorunum` çocuğu olan gövdeyi atlasın |
| 13 | BantC | taşıma bandı | x780..940 y400..416 | E (kısmen) | Bant betiği kendi `BANT` çizimini ekliyor; ardından `bolum.gd:_gorunumu_kur` aynı gövdeye ikinci bir `DUVAR` çizimi ekliyor (aynı z, sonraki çocuk = üstte). Kemer, ok ve makara DUVAR panelinin altında kalıyor; bant düz tahta gibi görünür, yönü okunmaz. | yalnız görünüm: `bolum.gd` zaten `Gorunum` çocuğu olan gövdeyi atlasın |
| 13 | PlakaA | basınç plakası | x150..210 y584..600 | E | - | - |
| 13 | PlakaB | basınç plakası | x650..710 y384..400 | E | - | - |
| 13 | PlakaC | basınç plakası | x810..870 y384..400 | E | - | - |
| 13 | Salter/SolAlan | şalter alanı | x875..915 y352..400 | E | Algılama alanı 40x48, taban çizimi 60 geniş; kapsıyor. | - |
| 13 | Salter/SagAlan | şalter alanı | x915..955 y352..400 | E | Algılama alanı 40x48, taban çizimi 60 geniş; kapsıyor. | - |
| 13 | LazerA | lazer | x317..323 y150..600 | E | - | - |
| 13 | LazerB | lazer | x757..763 y150..400 | E | - | - |
| 13 | LazerC | lazer | x960..1080 y467..473 | E | - | - |
| 13 | LazerD | lazer | x960..1080 y537..543 | E | - | - |
| 13 | Ziplatici | yaylı zıplatıcı | x490..550 y588..600 | H | `match`te `Tur.ZIPLATICI` kolu yok; `_ziplatici()` yazılı ama çağrılmıyor, düz `Gorsel` gizli (yayli_ziplatici.gd). | yalnız görünüm: `gorunum.gd` `_draw` match'ine kol ekle (bkz. Ortak kök neden) |
| 13 | Kapi | hedef kapı | x1002..1038 y552..600 | E | - | - |
| 14 | Zemin | zemin/duvar/tavan | x0..1152 y600..640 | E | - | - |
| 14 | Tavan | zemin/duvar/tavan | x0..1152 y0..140 | E | - | - |
| 14 | TavanD | zemin/duvar/tavan | x400..1152 y140..200 | E | - | - |
| 14 | UL1 | zemin/duvar/tavan | x400..490 y400..600 | E | - | - |
| 14 | BantAlti | zemin/duvar/tavan | x490..650 y416..600 | E | - | - |
| 14 | UL2 | zemin/duvar/tavan | x650..760 y400..600 | E | - | - |
| 14 | UR | zemin/duvar/tavan | x920..1000 y400..600 | E | - | - |
| 14 | Cikinti | zemin/duvar/tavan | x1000..1152 y270..600 | E | - | - |
| 14 | Raf | tek yönlü platform | x280..400 y400..412 | E | - | - |
| 14 | Kapak1 | tek yönlü platform | x760..880 y400..412 | E | - | - |
| 14 | Kapak2 | tek yönlü platform | x880..1000 y400..412 | E | - | - |
| 14 | Bant | taşıma bandı | x490..650 y400..416 | E (kısmen) | Bant betiği kendi `BANT` çizimini ekliyor; ardından `bolum.gd:_gorunumu_kur` aynı gövdeye ikinci bir `DUVAR` çizimi ekliyor (aynı z, sonraki çocuk = üstte). Kemer, ok ve makara DUVAR panelinin altında kalıyor; bant düz tahta gibi görünür, yönü okunmaz. | yalnız görünüm: `bolum.gd` zaten `Gorunum` çocuğu olan gövdeyi atlasın |
| 14 | PlakaA | basınç plakası | x57..117 y584..600 | E | - | - |
| 14 | PlakaM | basınç plakası | x300..360 y384..400 | E | - | - |
| 14 | PlakaR | basınç plakası | x470..530 y384..400 | E | - | - |
| 14 | PlakaP | basınç plakası | x850..910 y584..600 | E | - | - |
| 14 | PlakaU | basınç plakası | x1000..1060 y254..270 | E | - | - |
| 14 | Z1 | yaylı zıplatıcı | x340..400 y588..600 | H | `match`te `Tur.ZIPLATICI` kolu yok; `_ziplatici()` yazılı ama çağrılmıyor, düz `Gorsel` gizli (yayli_ziplatici.gd). | yalnız görünüm: `gorunum.gd` `_draw` match'ine kol ekle (bkz. Ortak kök neden) |
| 14 | Z2 | yaylı zıplatıcı | x760..820 y588..600 | H | `match`te `Tur.ZIPLATICI` kolu yok; `_ziplatici()` yazılı ama çağrılmıyor, düz `Gorsel` gizli (yayli_ziplatici.gd). | yalnız görünüm: `gorunum.gd` `_draw` match'ine kol ekle (bkz. Ortak kök neden) |
| 14 | GecitA | geçit | x255..275 y400..600 | E | - | - |
| 14 | GecitR | geçit | x700..720 y200..400 | E | z=-1: açık konumda tavan/kat içine gömülür (tasarım gereği); kapalıyken tam görünür. | - |
| 14 | Lazer2 | lazer | x447..453 y200..400 | E | - | - |
| 14 | Lazer1 | lazer | x912..918 y200..400 | E | - | - |
| 14 | Lazer3 | lazer | x1087..1093 y200..270 | E | - | - |
| 14 | Kapi | hedef kapı | x1110..1146 y222..270 | E | - | - |
| 14 | Kutu | kutu | x655..695 y360..400 | H | `Gorunum._draw` match'inde `Tur.KUTU` kolu yok; `_kutu()` yazılı ama çağrılmıyor, düz `Gorsel` de gizli (kutu.gd). | yalnız görünüm: `gorunum.gd` `_draw` match'ine kol ekle (bkz. Ortak kök neden) |
| 15 | Zemin | zemin/duvar/tavan | x0..1152 y600..640 | E | - | - |
| 15 | Tavan | zemin/duvar/tavan | x0..1152 y0..180 | E | - | - |
| 15 | DosemeSol | zemin/duvar/tavan | x0..470 y380..420 | E | - | - |
| 15 | DosemeOrta | zemin/duvar/tavan | x570..1000 y380..420 | E | - | - |
| 15 | DuvarF1 | zemin/duvar/tavan | x980..1000 y420..600 | E | - | - |
| 15 | SagDuvar | zemin/duvar/tavan | x1120..1152 y180..600 | E | - | - |
| 15 | Raf | tek yönlü platform | x1000..1120 y380..392 | E | - | - |
| 15 | PlakaZ | zamanlı plaka | x90..150 y584..600 | H | `match`te `Tur.PLAKA_ZAMANLI` kolu yok (`_plaka`/`_plaka_sayac` çağrılmıyor); `zamanli_plaka.tscn`te `Gorsel` yok. Plaka tetikliyor ama hiçbir şey çizilmiyor. | yalnız görünüm: `gorunum.gd` `_draw` match'ine kol ekle (bkz. Ortak kök neden) |
| 15 | PlakaA | basınç plakası | x610..670 y364..380 | E | - | - |
| 15 | PlakaB | basınç plakası | x910..970 y364..380 | E | - | - |
| 15 | Z1 | yaylı zıplatıcı | x490..550 y588..600 | H | `match`te `Tur.ZIPLATICI` kolu yok; `_ziplatici()` yazılı ama çağrılmıyor, düz `Gorsel` gizli (yayli_ziplatici.gd). | yalnız görünüm: `gorunum.gd` `_draw` match'ine kol ekle (bkz. Ortak kök neden) |
| 15 | GecitG | geçit | x850..870 y180..380 | E | z=-1: açık konumda tavan/kat içine gömülür (tasarım gereği); kapalıyken tam görünür. | - |
| 15 | LazerA | lazer | x737..743 y180..380 | E | - | - |
| 15 | LazerB | lazer | x1057..1063 y180..600 | E | - | - |
| 15 | Kapi | hedef kapı | x1082..1118 y552..600 | E | - | - |
| 16 | Zemin | zemin/duvar/tavan | x0..1152 y600..640 | E | - | - |
| 16 | Tavan | zemin/duvar/tavan | x0..1152 y0..180 | E | - | - |
| 16 | DosemeSol | zemin/duvar/tavan | x0..100 y380..420 | E | - | - |
| 16 | DosemeOrtaSol | zemin/duvar/tavan | x200..420 y380..420 | E | - | - |
| 16 | DosemeOrtaSag | zemin/duvar/tavan | x540..980 y380..420 | E | - | - |
| 16 | DuvarW | zemin/duvar/tavan | x380..400 y420..600 | E | - | - |
| 16 | DuvarCep | zemin/duvar/tavan | x600..1000 y420..600 | E | - | - |
| 16 | Sehpa | zemin/duvar/tavan | x980..1152 y260..380 | E | - | - |
| 16 | Raf | tek yönlü platform | x420..540 y380..392 | E | - | - |
| 16 | PlakaA | basınç plakası | x230..290 y364..380 | E | - | - |
| 16 | PlakaB | basınç plakası | x640..700 y364..380 | E | - | - |
| 16 | PlakaC | basınç plakası | x770..830 y364..380 | E | - | - |
| 16 | MP | mandal plaka | x420..480 y584..600 | H | `match`te `Tur.PLAKA_MANDAL` kolu yok (`_plaka`/`_plaka_mandal` çağrılmıyor); `mandal_plaka.tscn`te `Gorsel` yok. | yalnız görünüm: `gorunum.gd` `_draw` match'ine kol ekle (bkz. Ortak kök neden) |
| 16 | Z1 | yaylı zıplatıcı | x120..180 y588..600 | H | `match`te `Tur.ZIPLATICI` kolu yok; `_ziplatici()` yazılı ama çağrılmıyor, düz `Gorsel` gizli (yayli_ziplatici.gd). | yalnız görünüm: `gorunum.gd` `_draw` match'ine kol ekle (bkz. Ortak kök neden) |
| 16 | Z2 | yaylı zıplatıcı | x480..540 y588..600 | H | `match`te `Tur.ZIPLATICI` kolu yok; `_ziplatici()` yazılı ama çağrılmıyor, düz `Gorsel` gizli (yayli_ziplatici.gd). | yalnız görünüm: `gorunum.gd` `_draw` match'ine kol ekle (bkz. Ortak kök neden) |
| 16 | G | geçit | x590..610 y180..380 | E | z=-1: açık konumda tavan/kat içine gömülür (tasarım gereği); kapalıyken tam görünür. | - |
| 16 | LazerA | lazer | x327..333 y180..380 | E | - | - |
| 16 | LazerB | lazer | x737..743 y180..380 | E | - | - |
| 16 | LazerC | lazer | x857..863 y180..380 | E | - | - |
| 16 | Kapi | hedef kapı | x1052..1088 y212..260 | E | - | - |
| 16 | Kutu | kutu | x900..940 y340..380 | H | `Gorunum._draw` match'inde `Tur.KUTU` kolu yok; `_kutu()` yazılı ama çağrılmıyor, düz `Gorsel` de gizli (kutu.gd). | yalnız görünüm: `gorunum.gd` `_draw` match'ine kol ekle (bkz. Ortak kök neden) |
| 17 | Zemin | zemin/duvar/tavan | x0..1152 y600..640 | E | - | - |
| 17 | Tavan | zemin/duvar/tavan | x0..1152 y0..180 | E | - | - |
| 17 | DosemeSol | zemin/duvar/tavan | x0..100 y380..420 | E | - | - |
| 17 | DosemeA1 | zemin/duvar/tavan | x200..240 y380..420 | E | - | - |
| 17 | BantTaban | zemin/duvar/tavan | x240..400 y396..420 | E | - | - |
| 17 | Bant | taşıma bandı | x240..400 y380..396 | E (kısmen) | Bant betiği kendi `BANT` çizimini ekliyor; ardından `bolum.gd:_gorunumu_kur` aynı gövdeye ikinci bir `DUVAR` çizimi ekliyor (aynı z, sonraki çocuk = üstte). Kemer, ok ve makara DUVAR panelinin altında kalıyor; bant düz tahta gibi görünür, yönü okunmaz. | yalnız görünüm: `bolum.gd` zaten `Gorunum` çocuğu olan gövdeyi atlasın |
| 17 | DosemeA2 | zemin/duvar/tavan | x400..560 y380..420 | E | - | - |
| 17 | Raf1 | tek yönlü platform | x560..680 y380..392 | E | - | - |
| 17 | DosemeB | zemin/duvar/tavan | x680..960 y380..420 | E | - | - |
| 17 | Raf2 | tek yönlü platform | x960..1080 y380..392 | E | - | - |
| 17 | DosemeP3 | zemin/duvar/tavan | x1080..1152 y380..420 | E | - | - |
| 17 | DuvarW1 | zemin/duvar/tavan | x440..460 y420..600 | E | - | - |
| 17 | BlokW2 | zemin/duvar/tavan | x760..960 y420..600 | E | - | - |
| 17 | Ledge | zemin/duvar/tavan | x1100..1152 y486..600 | E | - | - |
| 17 | PlakaA | basınç plakası | x410..470 y364..380 | E | - | - |
| 17 | PlakaB | basınç plakası | x705..765 y364..380 | E | - | - |
| 17 | PlakaC | basınç plakası | x895..955 y364..380 | E | - | - |
| 17 | PlakaZ | zamanlı plaka | x470..530 y584..600 | H | `match`te `Tur.PLAKA_ZAMANLI` kolu yok (`_plaka`/`_plaka_sayac` çağrılmıyor); `zamanli_plaka.tscn`te `Gorsel` yok. Plaka tetikliyor ama hiçbir şey çizilmiyor. | yalnız görünüm: `gorunum.gd` `_draw` match'ine kol ekle (bkz. Ortak kök neden) |
| 17 | PlakaM | mandal plaka | x540..600 y584..600 | H | `match`te `Tur.PLAKA_MANDAL` kolu yok (`_plaka`/`_plaka_mandal` çağrılmıyor); `mandal_plaka.tscn`te `Gorsel` yok. | yalnız görünüm: `gorunum.gd` `_draw` match'ine kol ekle (bkz. Ortak kök neden) |
| 17 | Z1 | yaylı zıplatıcı | x120..180 y588..600 | H | `match`te `Tur.ZIPLATICI` kolu yok; `_ziplatici()` yazılı ama çağrılmıyor, düz `Gorsel` gizli (yayli_ziplatici.gd). | yalnız görünüm: `gorunum.gd` `_draw` match'ine kol ekle (bkz. Ortak kök neden) |
| 17 | Z2 | yaylı zıplatıcı | x620..680 y588..600 | H | `match`te `Tur.ZIPLATICI` kolu yok; `_ziplatici()` yazılı ama çağrılmıyor, düz `Gorsel` gizli (yayli_ziplatici.gd). | yalnız görünüm: `gorunum.gd` `_draw` match'ine kol ekle (bkz. Ortak kök neden) |
| 17 | GecitZ | geçit | x820..840 y180..380 | E | z=-1: açık konumda tavan/kat içine gömülür (tasarım gereği); kapalıyken tam görünür. | - |
| 17 | GecitM | geçit | x870..890 y180..380 | E | z=-1: açık konumda tavan/kat içine gömülür (tasarım gereği); kapalıyken tam görünür. | - |
| 17 | LazerA | lazer | x512..518 y180..380 | E | - | - |
| 17 | LazerB | lazer | x787..793 y180..380 | E | - | - |
| 17 | LazerC | lazer | x1037..1043 y180..600 | E | - | - |
| 17 | Kapi | hedef kapı | x1108..1144 y438..486 | E | - | - |
| 17 | Kutu | kutu | x1040..1080 y560..600 | H | `Gorunum._draw` match'inde `Tur.KUTU` kolu yok; `_kutu()` yazılı ama çağrılmıyor, düz `Gorsel` de gizli (kutu.gd). | yalnız görünüm: `gorunum.gd` `_draw` match'ine kol ekle (bkz. Ortak kök neden) |
| 18 | Zemin | zemin/duvar/tavan | x0..1152 y600..640 | E | - | - |
| 18 | Tavan | zemin/duvar/tavan | x0..1152 y0..180 | E | - | - |
| 18 | DosemeSol | zemin/duvar/tavan | x0..160 y380..420 | E | - | - |
| 18 | DosemeA | zemin/duvar/tavan | x300..720 y380..420 | E | - | - |
| 18 | Raf | tek yönlü platform | x720..840 y380..392 | E | - | - |
| 18 | BlokR | zemin/duvar/tavan | x840..1152 y180..600 | E | - | - |
| 18 | DuvarWK | zemin/duvar/tavan | x350..370 y420..600 | E | - | - |
| 18 | PlakaZ | zamanlı plaka | x200..260 y584..600 | H | `match`te `Tur.PLAKA_ZAMANLI` kolu yok (`_plaka`/`_plaka_sayac` çağrılmıyor); `zamanli_plaka.tscn`te `Gorsel` yok. Plaka tetikliyor ama hiçbir şey çizilmiyor. | yalnız görünüm: `gorunum.gd` `_draw` match'ine kol ekle (bkz. Ortak kök neden) |
| 18 | PlakaA | basınç plakası | x350..410 y364..380 | E | - | - |
| 18 | PlakaB | basınç plakası | x570..630 y364..380 | E | - | - |
| 18 | Asansor | asansör | x170..290 y600..620 | E | z=-1: dinlenme konumunda zemine gömülü; üstte amber işaret şeridi çizili ve zeminle örtülmüyor (doğrulandı). Yükselince tam görünür. | - |
| 18 | LazerA | lazer | x467..473 y180..380 | E | - | - |
| 18 | LazerA2 | lazer | x537..543 y420..600 | E | - | - |
| 18 | LazerB | lazer | x637..643 y420..600 | E | - | - |
| 18 | Kapi | hedef kapı | x402..438 y552..600 | E | - | - |
| 19 | Zemin | zemin/duvar/tavan | x0..1152 y600..640 | E | - | - |
| 19 | BlokF1 | zemin/duvar/tavan | x350..1152 y420..600 | E | - | - |
| 19 | DosemeSol | zemin/duvar/tavan | x0..160 y380..420 | E | - | - |
| 19 | DosemeA | zemin/duvar/tavan | x300..540 y380..420 | E | - | - |
| 19 | DosemeB | zemin/duvar/tavan | x680..800 y380..420 | E | - | - |
| 19 | DuvarW2 | zemin/duvar/tavan | x800..820 y200..420 | E | - | - |
| 19 | DosemeR | zemin/duvar/tavan | x820..1152 y380..420 | E | - | - |
| 19 | BlokF3L | zemin/duvar/tavan | x0..540 y0..200 | E | - | - |
| 19 | DosemeF3 | zemin/duvar/tavan | x680..860 y160..200 | E | - | - |
| 19 | BlokF3R | zemin/duvar/tavan | x980..1152 y0..200 | E | - | - |
| 19 | Raf | tek yönlü platform | x860..980 y160..172 | E | - | - |
| 19 | PlakaZ | zamanlı plaka | x200..260 y584..600 | H | `match`te `Tur.PLAKA_ZAMANLI` kolu yok (`_plaka`/`_plaka_sayac` çağrılmıyor); `zamanli_plaka.tscn`te `Gorsel` yok. Plaka tetikliyor ama hiçbir şey çizilmiyor. | yalnız görünüm: `gorunum.gd` `_draw` match'ine kol ekle (bkz. Ortak kök neden) |
| 19 | PlakaA | basınç plakası | x350..410 y364..380 | E | - | - |
| 19 | PlakaL | basınç plakası | x700..760 y364..380 | E | - | - |
| 19 | PlakaB | basınç plakası | x890..950 y364..380 | E | - | - |
| 19 | Asansor1 | asansör | x170..290 y600..620 | E | z=-1: dinlenme konumunda zemine gömülü; üstte amber işaret şeridi çizili ve zeminle örtülmüyor (doğrulandı). Yükselince tam görünür. | - |
| 19 | Asansor2 | asansör | x550..670 y380..400 | E | z=-1: dinlenme konumunda zemine gömülü; üstte amber işaret şeridi çizili ve zeminle örtülmüyor (doğrulandı). Yükselince tam görünür. | - |
| 19 | GecitG | geçit | x750..770 y-40..160 | E | - | - |
| 19 | LazerA | lazer | x467..473 y200..380 | E | - | - |
| 19 | LazerB | lazer | x1007..1013 y200..380 | E | - | - |
| 19 | Kapi | hedef kapı | x1072..1108 y332..380 | E | - | - |
| 20 | Zemin | zemin/duvar/tavan | x0..1152 y600..640 | E | - | - |
| 20 | BlokF1 | zemin/duvar/tavan | x400..1152 y420..600 | E | - | - |
| 20 | DosemeSol | zemin/duvar/tavan | x0..100 y380..420 | E | - | - |
| 20 | DosemeA | zemin/duvar/tavan | x200..400 y380..420 | E | - | - |
| 20 | DosemeB | zemin/duvar/tavan | x540..720 y380..420 | E | - | - |
| 20 | DuvarW2 | zemin/duvar/tavan | x720..740 y200..420 | E | - | - |
| 20 | DosemeR | zemin/duvar/tavan | x740..1152 y380..420 | E | - | - |
| 20 | BlokF3L | zemin/duvar/tavan | x0..400 y0..200 | E | - | - |
| 20 | DosemeF3a | zemin/duvar/tavan | x540..560 y160..200 | E | - | - |
| 20 | BantTaban | zemin/duvar/tavan | x560..720 y176..200 | E | - | - |
| 20 | DosemeF3b | zemin/duvar/tavan | x720..810 y160..200 | E | - | - |
| 20 | BlokF3R | zemin/duvar/tavan | x930..1152 y0..200 | E | - | - |
| 20 | Raf | tek yönlü platform | x810..930 y160..172 | E | - | - |
| 20 | Bant | taşıma bandı | x560..720 y160..176 | E (kısmen) | Bant betiği kendi `BANT` çizimini ekliyor; ardından `bolum.gd:_gorunumu_kur` aynı gövdeye ikinci bir `DUVAR` çizimi ekliyor (aynı z, sonraki çocuk = üstte). Kemer, ok ve makara DUVAR panelinin altında kalıyor; bant düz tahta gibi görünür, yönü okunmaz. | yalnız görünüm: `bolum.gd` zaten `Gorunum` çocuğu olan gövdeyi atlasın |
| 20 | PlakaA | basınç plakası | x235..295 y364..380 | E | - | - |
| 20 | PlakaL | basınç plakası | x560..620 y364..380 | E | - | - |
| 20 | PlakaX | basınç plakası | x640..700 y364..380 | E | - | - |
| 20 | PlakaB | basınç plakası | x840..900 y364..380 | E | - | - |
| 20 | Salter/SolAlan | şalter alanı | x960..1000 y332..380 | E | Algılama alanı 40x48, taban çizimi 60 geniş; kapsıyor. | - |
| 20 | Salter/SagAlan | şalter alanı | x1000..1040 y332..380 | E | Algılama alanı 40x48, taban çizimi 60 geniş; kapsıyor. | - |
| 20 | Z1 | yaylı zıplatıcı | x120..180 y588..600 | H | `match`te `Tur.ZIPLATICI` kolu yok; `_ziplatici()` yazılı ama çağrılmıyor, düz `Gorsel` gizli (yayli_ziplatici.gd). | yalnız görünüm: `gorunum.gd` `_draw` match'ine kol ekle (bkz. Ortak kök neden) |
| 20 | Asansor | asansör | x410..530 y380..400 | E | z=-1: dinlenme konumunda zemine gömülü; üstte amber işaret şeridi çizili ve zeminle örtülmüyor (doğrulandı). Yükselince tam görünür. | - |
| 20 | GecitG | geçit | x780..800 y-40..160 | E | - | - |
| 20 | LazerA | lazer | x337..343 y200..380 | E | - | - |
| 20 | LazerB | lazer | x942..948 y200..380 | E | - | - |
| 20 | LazerS | lazer | x1072..1078 y200..380 | E | - | - |
| 20 | Kapi | hedef kapı | x1097..1133 y332..380 | E | - | - |

## Düzeltme durumu (2026-10-16, grafik)

| bulgu | durum |
|---|---|
| Kök neden: `_draw` match'inde KUTU/ZIPLATICI/PLAKA_ZAMANLI/PLAKA_MANDAL yok (24 nesne: 12 zıplatıcı, 6 kutu, 4 zamanlı, 2 mandal plaka) | düzeltildi (4 kol eklendi, `scripts/gorunum.gd`) |
| B13 zıplatıcı, B15 `PlakaZ`/`Z1`, B16, B17, B18, B19, B20 `Z1` çizimsizliği | düzeltildi (aynı kök neden) |
| Bant çift çizim (B10 x2, B13 x2, B14, B17, B20): ikinci DUVAR kemeri örtüyor | düzeltildi (`bolum.gd` kendi `Gorunum`'u olan gövdeyi atlar) |
| Bant animasyonu zayıf/okunmaz | düzeltildi (yenilenen `_bant`: sürekli akan amber oklar, dönen makaralar, `yon`/`hiz`'dan yön; yeni palet renkleri) |
| Mandal plaka kilit lambası zeminde seçilmiyor | düzeltildi (açıkken kırmızı `UYARI`) |
| B14 `PlakaR` bandın 20 px solunda | BEKLİYOR (+20 px denemesi testleri kırdı, geri alındı; bkz. `docs/sorunlar.md`) |
| B10 `PlakaPG` (Bant2 solunda 10 px) | bekliyor (kasıtlı olabilir, dokunulmadı, karar notu `docs/sorunlar.md`) |
| B10 `PlakaP1` (Bant1 sağ ucu/Duvar ile 10 px örtüşme) | bekliyor (isteğe bağlı, dokunulmadı) |
| B15 sonunda algılanan "görünmez blok" (açık geçidin tavana gömülmesi / sönük lazer kılavuzu) | bekliyor (kural ihlali değil; ekran görüntüsüyle doğrulanmalı) |
| Şalter alanı taban çiziminden ~10 px taşar | bekliyor (sorun sayılmadı) |

