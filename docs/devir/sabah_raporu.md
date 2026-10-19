# Sabah raporu (2026-10-19)

## ÖZET (10 satır)
1. Bölüm 19 "Karşı Ağırlık" kaldırıldı (sahne: scenes/bolumler/arsiv/bolum_19_arsiv.tscn); eski 20/21/22 -> 19/20/21, sahne dosyaları da yeniden adlandırıldı (karar: gece_notlari.md, kararlar.md; tablo: numara_esleme.md). Toplam 21 bölüm.
2. Harita zinciri 18 -> 19 -> 20 -> 21; 19@(1040,510), 20@(860,510), 21@(680,510); harita_yerlesim.md 21 satır.
3. Bölüm 18: max_klon = 2, "?" ikonu kaldırıldı; çözüm 2 klonla doğrulandı (sorunlar.md'ye yazılacak bir şey çıkmadı). İkon yalnızca Bölüm 4 ve 6'da.
4. HUD: her bölümde "Bölüm N · Ad" (BolumEtiketi, BolumListesi.baslik; Bilgi satırının üstünde, Bilgi 28 px aşağı kaydı). Bölüm 1/2 adları tahmin, olduğu gibi.
5. Commit'ler: Parça 1 (585 GEÇTİ), Parça 2 (581 GEÇTİ), Parça 3 (583 GEÇTİ) + kapanış. Push YOK.
6. Son tam koşu: 583 GEÇTİ / 0 KALDI.
7. Denetim (opus gozden-gecirici): KABUL. Fizik/kayıt formatı/determinizm değişmedi, çizimsiz çarpışma yok, yerel yol/e-posta sızıntısı yok, sahne yeniden adlandırmaları içerik olarak birebir.
8. Denetim uyarısı giderildi: sahne kök düğüm adları (Bolum20/21/22) yeni numaralara çevrildi.
9. Açık uyarı: sol üst HUD'un bölüm nesneleriyle örtüşmesi 21 bölümde gözle kontrol edilmedi (yalnız B4 ve B21 ekran görüntüsü alındı, temiz).
10. Açık kararlar değişmedi: canlı/klon dikiş sapması (A/C), B14 PlakaR / B10 PlakaPG.

## Elle kontrol listesi
1. HUD yazısı: her bölümde sol üstte "Bölüm N · Ad", altında Tur | Klon | R satırı; okunaklı mı, sol üstteki nesnelerle (tavan, lazer, geçit) çakışıyor mu.
2. Harita: 21 düğüm, zincir 18 -> 19 -> 20 -> 21, çizgi kesişimi/üst üste binme yok; hover'da doğru ad.
3. Bölüm 4 ve 6'da "?" ikonu duruyor mu (hover: "2 klonla" / "1 klonla çözülebilir").
4. Bölüm 18'de "?" ikonu yok, klon sınırı 2 (2 klonla çözülüyor mu).
5. Bölüm 19, 20, 21 doğru sahneyi açıyor mu (Büyük Saat, Mandal, Fitil ve Mühür); "Sonraki bölüm" 21'de bitiyor mu.

---
## Önceki rapor (2026-10-16, üçüncü gece; numaralar eskidir)

## ÖZET (10 satır)
1. YENİ: Bölüm 21 "Mandal" ve Bölüm 22 "Fitil ve Mühür" (ikisi de max_klon 2, çözüm tam 2 klon); eski B16/B17 aynen kaldı. Harita 22 düğüm (6x4 yılan ızgara), 20 -> 21 -> 22.
2. Kablo çizimi (yalnız görünüm): plaka-geçit/lazer arası ince kablo, etkinken camgöbeği (`kablo`, B22'de `kablo_2`); çarpışma/mekanik yok.
3. BÖLÜM 9: değişiklik yok (kullanıcı kabul etti), sorunlar.md'de kapatıldı.
4. PLAKALAR: B10 PlakaP1 tam bandın üstüne alındı. B14 PlakaR ve B10 PlakaPG ölçüldü, testler kırıldığı/bölüm bozulduğu için geri alındı (gece_notlari.md, sorunlar.md: kalan seçenekler orada).
5. BÖLÜM 18: ipucu_klon = 2 ("?" ikonu, "2 klonla çözülebilir"), ikon görünürlük testi eklendi.
6. TEST: tam koşu 606 GEÇTİ / 0 KALDI (423 sn). B22 için 23 test (çözüm, 10 başarısızlık, atlanamazlık, kısayol, determinizm, görünürlük, kablo).
7. DENETİM (opus gozden-gecirici): B22 KABUL; fizik/kayıt/determinizm değişmedi, rastgelelik yok, çizimsiz çarpışma yok, kişisel iz yok. Taslak §8 "kör kayıt" satırı ölçümle düzeltildi (bitmez).
8. Ölçülen en dar zorunlu pay B22'de 41 kare (oyuncunun LazerB önünde beklemesi); B21/B22 hiçbir pencere 50 karenin çok altında değil.
9. Push YOK (GitHub'a gönderilmedi). Kararlar: gece_notlari.md, kararlar.md.
10. AÇIK: canlı/klon dikiş sapması kararı (A/C) hâlâ bekliyor (durum.md); B14/B10 plaka seçenekleri.

## Elle kontrol listesi (görsel)
1. Yeni Bölüm 21 ve 22: kablolar doğru plaka/geçit/lazeri bağlıyor mu; B22'de LazerA kablosu (x=508) ışının 9 px solunda, ışıkla karışıyor mu.
2. Bölüm 14 ve 10 plakaları: B14 PlakaR hâlâ bandın 20 px solunda (geri alındı), B10 PlakaP1 tam bandın üstünde, B10 PlakaPG yerinde.
3. Bölüm 18: "?" ikonu ve hover metni "2 klonla çözülebilir"; başka bölümde (4 ve 6 dışında) yok.
4. Harita: 22 düğüm, çizgi kesişimi/üst üste binme yok; 21 ve 22 doğru bölüme açılıyor.
5. Oynanış: B21/B22 zamanlama hissi ve fitil/mühür görselleri.

---
## Önceki rapor (ikinci gece)
# Sabah raporu (ikinci gece, 2026-10-16)

## ÖZET (10 satır)
1. YAPILDI: ajan modelleri (tasarimci, gozden-gecirici = opus), kalıcı görünürlük/okunabilirlik kuralları (CLAUDE.md, kararlar.md, tüm ajan dosyaları); T tuşu + Türkçe Kontroller ekranı; görünürlük taraması ve düzeltmeleri; bant animasyonu; Bölüm 9 ayarı; Bölüm 16/17 v2 taslakları.
2. TEST: son tam koşu 554 GEÇTİ / 0 KALDI (464 sn). 5 commit, GitHub'a push YOK.
3. GÖRÜNÜRLÜK: 330 nesne tarandı; 24 çizimsiz bulundu (12 zıplatıcı, 6 kutu, 4 zamanlı, 2 mandal plaka). Tek kök neden: `gorunum.gd` `_draw` match'inde 4 tür eksikti; eklendi. Bildirilen B13 zıplatma zemini, B15 görünmez plaka (PlakaZ), B16/17 nesneleri ve "görünmez blok" (kutu) hep buydu. Bant 7 yerde çift çizimle örtülüyordu; düzeltildi, bant animasyonu yenilendi (akan oklar, makaralar, yüksek kontrast).
4. YENİ TESTLER: T (3), görünürlük + bölüm listesi (24), B9 pencere payları (1).
5. ATLANAN: B14 `PlakaR` +20 px sağa alma — 520'de 10 test kırıldı, 510'da 3 test + bölüm kolaylaşıyor; kural gereği geri alındı (docs/sorunlar.md, seçenekler orada). B10 `PlakaPG`/`PlakaP1` kasıtlı olabilir, dokunulmadı.
6. KULLANICI KARARI BEKLEYEN: Bölüm 9 hâlâ "k2 çok erken basmamalı (~1 sn bekle), ekranda ipucu yok" taşıyor; seçenekler (a) bırak (b) yeniden tasarla (c) tur sırası (sorunlar.md).
7. BÖLÜM 16/17 v2 TASLAK ONAYI BEKLİYOR (kodlanmadı): B16 "Mandal" (2 klon; raf altından zıplayarak mandal), B17 "Fitil ve Mühür" (2 klon; kuyudaki zamanlı plaka + odadaki mandal). Tasarımcının 5 sorusu taslak dosyalarında + aşağıda. Eski B16/B17 hâlâ oyunda ve görünür (çizimli) ama haksız bulduğun hâliyle.
8. B18/19/20: görünürlük taramasında görünmez işlev ÇIKMADI; yeniden yazma gerekmiyor.
9. GECE KARARLARI: docs/devir/gece_notlari.md (Kontroller iki sütun, kontroller testi 1 satır güncellendi, B9 ayarı, T geçiş perdesi).
10. DENETİM (opus gozden-gecirici): fizik/kayıt formatı/determinizm değişmedi, rastgelelik yok, kişisel iz yok; küçük uyarılar düzeltildi, kalanlar sorunlar.md'de.

## Onay bekleyenler
- docs/devir/bolum_16_taslak_v2.md, bolum_17_taslak_v2.md. Sorular: B16 max_klon 2 mi 3 mü; B16 geçit yeri; B17 max_klon; B17 adı; B17 oda geçidi (zamanlı VEYA mandal); plaka-geçit arası kablo çizimi eklensin mi (yalnız görünüm).
- Bölüm 9 seçeneği (a/b/c). Canlı/klon dikiş sapması kararı (A/C) hâlâ açık (durum.md).

## Elle kontrol listesi (headless'ta çizim yok)
1. Kutu (B9,10,12,14,16,17), zıplatıcı (B11-17,20) ve zamanlı/mandal plaka (B15-19: sayaç şeridi, kilit lambası) ekranda görünüyor mu, zeminden ayrışıyor mu.
2. Bantlar (B10,13,14,17,20): oklar bandın yönünde akıyor mu (ters bantlar dahil), makaralar dönüyor mu, zeminden ayrışıyor mu.
3. B13 zıplatıcı, B15 sol alttaki zamanlı plaka, B14 plaka/kutu ve bant yanı: eski "görünmez" şikayetleri kalktı mı. B14 PlakaR hâlâ bandın 20 px solunda (geri alındı); hâlâ rahatsız ediyorsa söyle.
4. T tuşu: bölümde, sonuç ekranında (etkisiz olmalı), Kontroller ekranı Türkçe adlar; HUD'da "T: baştan başla".
5. Bölüm 9: yeni F2 yüksekliği (430), plaka/kapı/ışın düzeni okunur mu; oynanış hissi.
