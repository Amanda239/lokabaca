# LokaBaca — Penting: Supabase Setup

Aplikasi sudah terhubung ke project Supabase yang sama untuk role **user** dan **admin**
(konfigurasi terpusat di `lib/core/config/supabase_config.dart`).

## 1. Jalankan migrasi database

Buka **Supabase Dashboard → SQL Editor → New query**, salin seluruh isi file:

```
supabase/migrations/20261123000000_lokabaca_fixes.sql
```

lalu klik **Run**. Migrasi ini:

- menambah kolom `books.publisher` (Penerbit di form Tambah Buku),
- membuat denda otomatis `Rp1.000/hari` saat peminjaman terlambat,
- membuat notifikasi: persetujuan/penolakan peminjaman, denda, pengingat H-1,
  dan permintaan konfirmasi pembayaran denda,
- menambah RLS policy agar user hanya melihat data sendiri dan admin melihat semua,
- menambah trigger sinkronisasi saat data peminjaman berubah.

> Migrasi aman dijalankan berulang (idempoten).

## 2. Storage buckets

Pastikan bucket berikut ada (atau buat di **Storage → New bucket**):

| Bucket | Dipakai untuk | Akses |
| --- | --- | --- |
| `book-covers` | Cover buku dari form admin | Public |
| `profile-avatars` | Foto profil user/admin | Public |

## 3. Alur yang sudah tersambung

- **User** mengajukan pinjam → status `Menunggu` → notifikasi masuk ke admin.
- **Admin** menyetujui/menolak → notifikasi masuk ke user.
- **Lewat jatuh tempo** → denda otomatis tercatat + notifikasi denda (juga dijaga
  sinkronisasi dari aplikasi setiap 30 menit melalui `NotificationService`).
- **User bayar denda lewat QRIS** → kirim bukti → status *menunggu konfirmasi admin*
  → admin menyetujui di menu **Denda** → `fine_paid = true`.
- **Wishlist** tersimpan di tabel `wishlists`, terpisah dari **Koleksi** (riwayat
  peminjaman di `borrowings`).

## 4. Build

```bash
flutter pub get
flutter analyze
flutter build apk --debug
```
