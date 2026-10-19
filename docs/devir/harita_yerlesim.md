# Harita yerleşimi (21 bölüm)

Ekran 1152x648. Düğüm altıgen yarıçapı 34 (kutu 80x80). Başlık ve ayraç y < 105; Geri düğmesi x 24..164, y 576..624.

## Yöntem: yılan (boustrophedon) ızgara
- 6 sütun: x = 140, 320, 500, 680, 860, 1040 (aralık 180).
- 4 satır: y = 165, 280, 395, 510 (aralık 115).
- Satır 1 (bölüm 1-6) soldan sağa, satır 2 (7-12) sağdan sola, satır 3 (13-18) soldan sağa, satır 4 (19-21) sağdan sola; satır geçişleri dikey kısa bağlantı (1040 veya 140 sütununda: 6-7, 12-13, 18-19).
- Bağlantılar yalnızca yatay ve dikey: komşu olmayan çizgiler arası en az 115 px, kesişim yok; bir çizgiye komşu olmayan en yakın düğüm 115 px uzakta (> 34 yarıçap).
- En yakın iki düğüm mesafesi 115 px (>= 100). Tüm düğüm kutuları ekran içinde (en sağ kutu bitişi 1040+40 = 1080 < 1152; en alt kutu bitişi 510+40 = 550 < 576). Geri düğmesi (x 24..164, y 576..624) hiçbir düğüm kutusuyla çakışmaz.
- Hover etiketi düğümün altında (y + 48..78); sonraki satırın düğüm üstü y + 81 olduğundan komşuya binmez. Etiket x'i ekrana kenetlenir.

## Konumlar
| # | konum | satır |
|---|---|---|
| 1 | Vector2(140, 165) | 1 (soldan sağa) |
| 2 | Vector2(320, 165) | 1 (soldan sağa) |
| 3 | Vector2(500, 165) | 1 (soldan sağa) |
| 4 | Vector2(680, 165) | 1 (soldan sağa) |
| 5 | Vector2(860, 165) | 1 (soldan sağa) |
| 6 | Vector2(1040, 165) | 1 (soldan sağa) |
| 7 | Vector2(1040, 280) | 2 (sağdan sola) |
| 8 | Vector2(860, 280) | 2 (sağdan sola) |
| 9 | Vector2(680, 280) | 2 (sağdan sola) |
| 10 | Vector2(500, 280) | 2 (sağdan sola) |
| 11 | Vector2(320, 280) | 2 (sağdan sola) |
| 12 | Vector2(140, 280) | 2 (sağdan sola) |
| 13 | Vector2(140, 395) | 3 (soldan sağa) |
| 14 | Vector2(320, 395) | 3 (soldan sağa) |
| 15 | Vector2(500, 395) | 3 (soldan sağa) |
| 16 | Vector2(680, 395) | 3 (soldan sağa) |
| 17 | Vector2(860, 395) | 3 (soldan sağa) |
| 18 | Vector2(1040, 395) | 3 (soldan sağa) |
| 19 | Vector2(1040, 510) | 4 (sağdan sola) |
| 20 | Vector2(860, 510) | 4 (sağdan sola) |
| 21 | Vector2(680, 510) | 4 (sağdan sola) |

Bölüm 19 (Karşı Ağırlık) kaldırıldığı için (2026-10-19) kayıt sayısı 22 -> 21; eski 22. konum (500, 510) boşaltıldı, eski 20/21/22 -> yeni 19/20/21 aynı ızgara sırasıyla kaydı (19@1040, 20@860, 21@680). Zincir 18 -> 19 -> 20 -> 21. Önceki not: 6x4 ızgara (2026-10-16, 20 -> 22 düğüm, 5x4 -> 6x4).
