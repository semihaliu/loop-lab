# Durum (üretim dalı: `uretim`) — 2026-10-15

## Nerede kaldık
- Bölüm 11 tamam (zorlaştırıldı, 21 test, bağımsız denetlendi). Bölüm 12–13 sırada.

## Aşama özeti
- **Aşama 1–4:** tamam (lazer/tek yönlü platform, Bölüm 3–8, görsel tema, son denetim).
- **Aşama A (Bölüm 8 max_klon=2):** tamam, kararlar.md'de.
- **Aşama B (kutu, zıplatıcı, taşıma bandı):** tamam, testli, denetli (commit 65e2981, 6e0cce4, 2d5e4f6).
- **Aşama C (Bölüm 9–14):** yarım. 9 ve 10 tamam (uygulama + test + bağımsız denetim, commit'li). 11 sahnesi kuruldu, commit'siz, testsiz. 12, 13, 14 hiç başlamadı (taslak bile yok).
- **Aşama D (grafik):** başlamadı. `scripts/gorunum.gd` kutu/zıplatıcı/bantı bilmiyor; bu nesneler düz ColorRect.

## Commit'lenmemiş değişiklikler
- `docs/kararlar.md` (Bölüm 11 uygulandı notu)
- `scripts/bolumler_listesi.gd` (Bölüm 11 kaydı; girinti tek fazla tab, düzeltilebilir)
- `scenes/bolumler/bolum_11.tscn` (yeni)

## Sıradaki adım (onay bekliyor)
1. Bölüm 11 değişikliklerini commit'le.
2. Bölüm 11 çözülebilirlik + kısayol testlerini yazdır (test-yazari), gozden-gecirici ile denetle. Taslak notu: "belirgin zor" ölçütüne tam uymuyor, tanıtım düzeyinde.
3. Bölüm 12, 13, 14 (taslak → uygulama → test → denetim); sıra `asamaC_yol_haritasi.md`'de.
4. Aşama D (grafik): kutu, zıplatıcı, bant görünümü.

## Açık noktalar
- Bölüm 9–10 bekleyen test işleri aşağıda; hâlâ yapılmadı.
- Bölüm 5 asansör-plaka-zıplama hilesi Godot `platform_on_leave` varsayılanına bağlı kapalı; `_test_bolum5_erken_ayrilma` sürüm değişirse yakalar.

## Bekleyen küçük test işleri
- Bölüm 9: G sınır testi (PlakaKutu sağ ucundan ayrılıp G'ye sprint → geçilemez), "asansör kutuda takılıp basamak olur" ölçümü (2 klonla bitmez), kutu asansörle F2'ye çıkıp platforma itilme ölçümü.
- Harita: bağlantı çizgilerinin birbirini ve düğümleri kesmediğini ölçen test (liste geneli).
- Bölüm 10 (denetim): (1) G'ye ZIPLAYARAK sprint testi (PG'den ayrılıp zıpla+sağ: x≥1041 iken G y≥292 → geçemez; ölçülen 33. kare x=1040,99, pay ~17 px) yok; (2) atlanamaz (b) zeminden F2'ye ve (c) kutu basamak testleri L2'de ölümle "boş geçiyor": L2 kapalıyken (P2'ye basan klonla) tekrar kurulmalı; (3) atlanamaz (e) adı yanıltıcı; (4) taslak bolum_10_taslak.md "kalkış penceresi" iddiaları (satır 42, 59(5), 62) geçersiz, kararlar.md'de düzeltildi.
