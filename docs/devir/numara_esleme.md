# Bölüm numara eşlemesi (2026-10-19)

Bölüm 19 "Karşı Ağırlık" (Bölüm 20 "Büyük Saat" ile çok benzediği için) kullanıcı kararıyla oyundan kaldırıldı;
yerine yenisi yapılmadı. Numaralar bölüm listesindeki (`scripts/bolumler_listesi.gd`) sıradan gelir; sahne
dosya adları da yeni numaralara göre yeniden adlandırıldı (disk ve liste tutarlı).

| Eski no | Yeni no | Ad | Eski sahne | Yeni sahne |
|---|---|---|---|---|
| 1–18 | 1–18 | (değişmedi) | `bolum_N.tscn` | `bolum_N.tscn` |
| 19 | — (arşiv) | Karşı Ağırlık | `scenes/bolumler/bolum_19.tscn` | `scenes/bolumler/arsiv/bolum_19_arsiv.tscn` (listede/haritada yok) |
| 20 | 19 | Büyük Saat | `bolum_20.tscn` | `bolum_19.tscn` |
| 21 | 20 | Mandal | `bolum_21.tscn` | `bolum_20.tscn` |
| 22 | 21 | Fitil ve Mühür | `bolum_22.tscn` | `bolum_21.tscn` |

- Toplam: 21 bölüm. Harita zinciri 18 → 19 → 20 → 21 (konumlar: 19 @ (1040, 510), 20 @ (860, 510), 21 @ (680, 510)).
- Test işlevleri/sabitleri de aynı eşlemeyle yeniden adlandırıldı (`_b20_calistir` → `_b19_calistir`, `BOLUM_21` → `BOLUM_20`, `--b22` → `--b21` vb.).
  Eski Bölüm 19'un testleri kaldırıldı (arşivlendi).
- Taslak dosyaları: `bolum_19_taslak.md` → `docs/devir/arsiv/`; `bolum_20/21/22_taslak.md` → `bolum_19/20/21_taslak.md`.
- Tarihli eski günlükler (`kararlar.md`, `gece_notlari.md`, eski `sabah_raporu.md` bölümleri, `sorunlar.md` eski girişleri, `testler.md` eski koşular)
  eski numaralarla yazılmıştır; tarihsel kayıt olarak bırakıldı, bu tabloyla okunur.
