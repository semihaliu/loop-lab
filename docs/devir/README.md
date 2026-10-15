# Devir klasörü

Ajanlar bağlamı sıfırdan başlatır; bilgi bu klasördeki dosyalarla aktarılır.

## Akış

`tasarimci` → (kullanıcı onayı) → `uygulayici` ve `test-yazari` → `gozden-gecirici` → `grafik`

1. **tasarimci** taslağı yanıt olarak döndürür; ana oturum `bolum_N_taslak.md` olarak buraya kaydeder.
2. Kullanıcı taslağı onaylar (onaysız uygulamaya geçilmez).
3. **uygulayici** sahneyi/kodu yazar, **test-yazari** testleri taslağa göre bağımsız yazar.
4. **gozden-gecirici** denetler; raporunu ana oturum buraya kaydeder.
5. **grafik** mekanik sabitlendikten sonra yalnızca görünümü yapar.

## Dosya adları

- `bolum_N_taslak.md` — tasarımcı taslağı
- `bolum_N_inceleme.md` — gözden geçirici raporu (isteğe bağlı)

Salt okunur ajanların (tasarimci, gozden-gecirici) çıktısını ana oturum bu klasöre kaydeder.
