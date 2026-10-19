# Durum (üretim dalı: `uretim`) — 2026-10-19

## 2026-10-19 özeti (güncel)
- **Oyunda 21 bölüm var.** Bölüm 19 "Karşı Ağırlık" kaldırıldı (arşiv: `scenes/bolumler/arsiv/bolum_19_arsiv.tscn`), eski 20/21/22 -> 19/20/21 (sahne dosyaları da yeniden adlandırıldı; tablo `docs/devir/numara_esleme.md`). Harita zinciri 18 -> 19 -> 20 -> 21.
- **Bölüm 18:** `max_klon = 2`, "?" ikonu yok (2 klonla çözüm doğrulandı). İkon yalnızca Bölüm 4 ve 6'da.
- **HUD:** her bölümde "Bölüm N · Ad" (`BolumEtiketi`, `BolumListesi.baslik`), Bilgi satırının üstünde.
- Son tam koşu: 583 GEÇTİ / 0 KALDI; denetim KABUL (`docs/devir/sabah_raporu.md`). GitHub'a push YAPILMADI.
- **Hâlâ açık:** canlı/klon dikiş sapması kararı (A/C, aşağıda), B14 `PlakaR` / B10 `PlakaPG` plaka seçenekleri (`docs/sorunlar.md`).
- Aşağıdaki eski bölümlerdeki bölüm numaraları (15–22, "22 bölüm") yazıldıkları günkü numaralardır; `numara_esleme.md` ile oku.

---
(Aşağısı 2026-10-16 tarihli önceki durumdur; numaralar eskidir.)


## 2026-10-16 (ikinci gece) özeti
Görünürlük/okunabilirlik kuralları kalıcı; T tuşu; görünürlük düzeltmeleri (kutu/zıplatıcı/zamanlı-mandal plaka çizimi, bant); B9 ayarı. 554 GEÇTİ / 0 KALDI. **Bekleyen:** B16/B17 v2 taslak onayı (`bolum_16_taslak_v2.md`, `bolum_17_taslak_v2.md`), B9 seçeneği (a/b/c), B14 PlakaR konumu. Ayrıntı: `docs/devir/sabah_raporu.md`.

## Nerede kaldık
- Gece planı tamamlandı: Bölüm 15–20, zamanlı/mandal plaka, arayüz iyileştirmeleri, son denetim. Son tam koşu: 526 GEÇTİ / 0 KALDI. Ayrıntı: `docs/devir/sabah_raporu.md`, kararlar `docs/devir/gece_notlari.md`.
- GitHub'a push YAPILMADI (`origin/main` = `87614a2`); push için geçmişsiz ekleme yöntemi kullanılacak.
- Sıradaki: elle kontrol (sabah_raporu.md listesi), açık kararlar (canlı/klon dikiş sapması: şimdilik A), isteğe bağlı sertleştirmeler (B20 şalter/C_A payları).

## Aşama özeti
- **Gece (2026-10-16):** Bölüm 15 Fitil, 16 Mandal, 17 Çifte Mühür, 18 Vardiya, 19 Karşı Ağırlık, 20 Büyük Saat; zamanlı + mandal plaka; ana menü/Kontroller/harita/sonuç/HUD/geçiş arayüzü.
- **Aşama 1–4, A, B:** tamam.
- **Aşama C (Bölüm 9–14):** tamam. Her biri: tasarımcı taslağı → uygulayıcı → bağımsız test → gözden geçirici → commit.
  - 9, 10 (kutu, bant), 11 (zıplatıcı + havada plaka, zorlaştırıldı), 12 "Kargo" (kutu fırlatma, min 2 klon), 13 "Kuyu" (bant darbesi + S düşme, min 3 klon), 14 "Çekirdek" (final, min 3 klon).
- **Yeni mekanik (kullanıcı onaylı):** S/Aşağı ile tek yönlü platformdan düşme (12 kare, kayıt `{yon, zipla, asagi}`); Bölüm 4 ve 6'da "?" ipucu ikonu (`ipucu_klon`).
- **Aşama 3 görsel:** taşıma bandı animasyonu, Bölüm 11 plaka askısı, oyun adı "Loop Lab". **Aşama D:** kutu ve zıplatıcı görünümü.
- **Hazırlık:** gerçek Godot yolu `CLAUDE.local.md`'de (git'e girmez); GitHub `main` geçmişsiz, kişisel iz yok.

## KULLANICI KARARI BEKLİYOR
**Canlı/klon ayrışması (eş düzlemli zemin seçimi).** Canlı kayıt turu ile klon tekrarı, eş düzlemli bant/zemin (ve asansör-zemin) dikişlerinde motorun platform seçimi yüzünden en çok 11,67 px ayrışıyor (B14 UL1|Bant x≈490; B13 BantA|ZeminSag x=260; B10 ZeminSol|Bant1 x=270). Kök neden `player.gd` değil, fizik geniş-faz sırası (dünyada boşta klon sayısına bağlı). Etki: B14'te S penceresinin ~8 px'i "canlıda çalışır, klonda çukura inmez" tuzağı; çözümler yine de geçiyor. Seçenekler: **A)** kabul (şu anki durum; üst sınır testle izleniyor, fark büyürse KALDI), **C)** bant etkisini motor platform hızından ayırıp deterministik uygulamak (player/kutu/bant fiziği değişir, bant pencereleri yeniden ölçülür). Ayrıntı: `docs/sorunlar.md`, `docs/kararlar.md`.

## Bekleyen sorun listesi (düşük)
- **Bölüm 6 geçit altı park/röle:** oyuncu geçit altında parkederek tek klonu geçirebiliyor, Bölüm 6 1 klonla bitiyor (`ipucu_klon=1` bu yüzden doğru). Bölüm 7, 9, 10, 12, 13, 14'te çalışmıyor (ölçüldü). Karar: kabul / geçit kuralı değişsin / bölüm yeniden ayarlansın (şu an kabul).
- **Bölüm 8 Basamak2 x≈714:** S sonrası ~27 kare yavaş iniş (+1 px/kare), kozmetik.
- **Bölüm 9:** asansör kutuda takılıp basamak olunca F2'ye çıkış payı ~0,5 px; bölüm yine bitmiyor.
- **Bölüm 5:** asansör-plaka-zıplama hilesi Godot `platform_on_leave` varsayılanına bağlı; `_test_bolum5_erken_ayrilma` yakalar.
- **Bölüm 14:** `max_klon = 3` = asgari 3, hata payı yok; son tur 556/600 kare. Kutu sola itilirse kilit (Baştan başla).
- **Test hijyeni:** `--rapor` her koşuda `docs/testler.md`'ye ek bölüm yazar; gözden geçirici ajanlar kullanmamalı. Test sabit koordinatlara bağlı (sahne değişirse güncelle).
- **Çıktı yolları:** tam koşu ~2,5 dk.

## Elle kontrol (görsel, headless'ta çizim atlanıyor)
1. Ana menü başlığı ve pencere başlığı "Loop Lab".
2. Bölüm 10, 13, 14: taşıma bandı (makaralar, kayan oklar, yön ve hız).
3. Bölüm 11: PlakaPB tavan halatları ve duvar kolu, plaka kalın blok; zıplatıcı yörüngesini kapatmıyor mu.
4. Kutu (ahşap/metal) ve zıplatıcı (yay, sıkışma animasyonu, oklar) Bölüm 9–14'te.
5. Bölüm 4 ve 6: "?" ikonu, hover'da "2 klonla çözülebilir" / "1 klonla çözülebilir"; diğer bölümlerde yok.
6. S tuşu: Bölüm 4, 8, 9, 11, 12, 13'te tek yönlü platformdan düşüş; duvara yaslıyken de çalışmalı (Bölüm 12 kovuk).
7. Bölüm 12–14 oynanış hissi (zamanlama pencereleri dar; test geçse de insan için zor olabilir).

## Sıradaki adım
1. Kullanıcı: yukarıdaki kararı (A/C) ver, elle kontrolleri yap.
2. İstenirse GitHub'a yeni geçmişsiz/ekli commit (parent `87614a2`) gönder.
