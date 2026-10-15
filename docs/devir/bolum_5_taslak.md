# Bölüm 5 taslağı: "Uzaktan Anahtar" (`scenes/bolumler/bolum_5.tscn`)
(Tasarımcı çıktısı; Aşama 2'de onaysız uygulama kullanıcı kararı.)

Öğretilen fikir: ŞALTER + LAZER. İki lazer zıt şalter konumlarında kapanır (L1 şalter SAĞDA iken, L2 şalter SOLDA iken). Şalter sahanlıkta durur; oyuncu iki lazeri geçmek için şalterin tur içinde iki kez (sağa, sonra sola) çevrilmesine ihtiyaç duyar; bunu klon yapar. Şalter kalıcıdır. Hiçbir klon ışına yaklaşmaz. Nesneler: plaka, asansör, şalter, lazer, kapı (geçit ve tek yönlü platform yok).
Sabitler: 28x48, HIZ 300 (5 px/kare), zıplama tepesi 96,5/~100,9, asansör 120 px/sn, zemin yüzeyi y=600, oyuncu (100,570). Şalter alanı: SolAlan x -40..0, SagAlan x 0..40, y -48..0 (düğüme göre). Asansör position.y merkezdir, üst yüzey 10 px yukarıda.

## Kat planı
Tek koridor y 400..600 (Tavan y 100..400). Plaka başlangıcın SOLUNDA ölü uçta. Asansör x 330..450 (yüzey 600→470). Sahanlık x 450..650 yüzeyi y=470 (alt kenar 510, altı yürünebilir). Işınlar x 717..723 ve 897..903, y 400..600. Kapı x 1042..1078.

## Nesneler (merkez)
| Düğüm | Tür | Konum | Ayrıntı |
|---|---|---|---|
| Zemin | StaticBody2D | (576,620) | 1152x40 |
| Tavan | StaticBody2D | (576,250) | 1152x300 (y 100..400) |
| Sahanlik | StaticBody2D | (550,490) | 200x40 (x 450..650, y 470..510); takılma olursa sol kenar 452 |
| Plaka | basinc_plakasi | (40,592) | 60x16 |
| Salter | scenes/salter.tscn | (560,470) | baslangic_sagda=false; alan x 520..600, y 422..470 |
| Asansor | asansor.gd | (390,610) | 120x20, plaka=../Plaka, yukseklik=130 (üst yüzey 470), x 330..450 |
| Lazer1 | scenes/lazer.tscn | (720,400) | yon=(0,1), uzunluk=200, tetikleyici_yollari=[../Salter], acik_taraf_sag=true, tetik_aktifken_kapali=true |
| Lazer2 | scenes/lazer.tscn | (900,400) | yon=(0,1), uzunluk=200, tetikleyici_yollari=[../Salter], acik_taraf_sag=false, tetik_aktifken_kapali=true |
| Kapi | kapi.gd Area2D | (1060,576) | 36x48 |
| Oyuncu | oyuncu.tscn | (100,570) | |
| Bilgi | Label | (16,12)-(600,40) | |

`max_klon = 2`. Ağaç sırası: Zemin, Tavan, Sahanlik, Plaka, Salter, Asansor, Lazer1, Lazer2, Kapi, Oyuncu, Bilgi. Başlangıç: şalter SOL → L1 AÇIK, L2 KAPALI. Şalter/asansör export adları scenes/salter.tscn, scripts/salter.gd ve bolum_2.tscn'den okunur.

## Çözüm (kare; testler koşula kadar bekler)
- Tur 1 → klon A (Plaka'yı tutar): 90 kare bekle, sol 12 kare (x→40), ~10 bekle, R (~1,9 sn).
- Tur 2 → klon B (şalteri iki kez çevirir): A ~94'te plakaya basar, asansör ~160'ta y=470. Oyuncu sağ 58 kare (x=390, asansöre biner), asansör üstteyken bekle (taşınır), sağ 40 kare (şalter alanına girince SAĞA, ~188), x=590'da dur, ~60 kare bekle, sol 3 kare (şalter SOLA, ~266), R (~4,6 sn).
- Tur 3 (R kapalı "Klon: 2/2"): oyuncu sağa yürür, L1 önünde x≈660'ta bekler (Lazer1 kapanana kadar ~189), geçer, x≈850'ye yürür, Lazer2 kapanana kadar (~267) bekler, kapıya ~310. karede (~5,2 sn).
Hiç zıplama yok.

## Atlanamazlık / 2 klon gereği
Sahanlığa zeminden 130 px > 100,9, asansörsüz çıkılamaz. Işınlar tavandan zemine tam. Şalteri tur içinde iki kez çevirebilecek kimse yoksa (oyuncu L1'i geçtikten sonra dönemez), asansörü kaldıran A plakadan ayrılamaz, B ayrıca gerekir → 2 klon.

## Klon asansör altı / kilitlenme
A plakada (x=40), B sahanlıkta (x≈585) veya asansör üstünde; asansör hiç inmez. Yanlış kayıtta "Baştan başla".

## Başarısızlık senaryoları
1. Klonsuz sağa yürüyüş: L1'de ölür, tur yeniden başlar, bölüm bitmez.
2. Yalnız A (B yok): L2'de ölür veya bitmez.
3. Yalnız B benzeri kayıt, A yok: asansör kalkmaz, şalter dönmez, L1'de ölür.
4. B yalnız sağa iter, sola geri dönmez: L2 açık kalır, bölüm bitmez.
5. L1'e şalter sağa dönmeden girmek: ölüm.

## Riskler
Asansör-sahanlık bitişik kenar takılması (sahanlık sol kenarı 452'ye). L2 önü bekleme payı dar (x≤860). A'nın 90 kare gecikmesi şart.

## Harita
`yol = res://scenes/bolumler/bolum_5.tscn`, `konum = Vector2(450, 520)`, `onceki = res://scenes/bolumler/bolum_4.tscn`.
