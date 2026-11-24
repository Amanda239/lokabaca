-- LokaBaca: alur approval admin untuk peminjaman buku.
-- Jalankan di Supabase Dashboard -> SQL Editor -> New query -> Run.
-- Jalankan SETELAH 20261123000000_lokabaca_fixes.sql. Aman dijalankan berulang.
--
-- Alur status:
--   user ajukan   -> 'Menunggu'
--   admin setuju  -> 'Dipinjam'  (stok -1, tanggal pinjam & jatuh tempo dihitung ulang)
--   admin tolak   -> 'Ditolak'   (stok tidak berubah)
--   admin terima pengembalian -> 'Selesai' (stok +1, returned_at terisi)

-- ---------------------------------------------------------------------------
-- 0. Bersihkan versi lama fungsi (hindari bentrok overload text/uuid/bigint)
--    dan lengkapi daftar status yang diizinkan di tabel borrowings.
-- ---------------------------------------------------------------------------
drop function if exists public.process_borrowing(text, text);
drop function if exists public.process_borrowing(uuid, text);
drop function if exists public.process_borrowing(bigint, text);

alter table public.borrowings drop constraint if exists borrowings_status_check;
alter table public.borrowings
  add constraint borrowings_status_check
  check (status in (
    'Menunggu',
    'Dipinjam',
    'Terlambat',
    'Menunggu Pengembalian',
    'Selesai',
    'Ditolak'
  ));

-- ---------------------------------------------------------------------------
-- 1. RPC process_borrowing(p_borrowing_id, p_action)
--    p_action: 'approve' | 'reject' | 'confirm_return'
--    Hanya admin. Baris dikunci agar dua admin tidak memproses bersamaan.
--    borrowings.id bertipe bigint.
-- ---------------------------------------------------------------------------
create or replace function public.process_borrowing(
  p_borrowing_id bigint,
  p_action text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_loan public.borrowings%rowtype;
  v_status text;
  v_days integer;
  v_today date := (now() at time zone 'Asia/Jakarta')::date;
  v_updated integer;
begin
  if auth.uid() is null or not public.is_admin() then
    raise exception 'Hanya admin yang boleh memproses peminjaman.'
      using errcode = '42501';
  end if;

  select * into v_loan
  from public.borrowings
  where id = p_borrowing_id
  for update;

  if not found then
    raise exception 'Data peminjaman tidak ditemukan.';
  end if;

  v_status := lower(trim(coalesce(v_loan.status, '')));

  if p_action = 'approve' then
    if v_status not in ('menunggu', 'menunggu konfirmasi', 'pending', 'waiting') then
      raise exception 'Pengajuan ini sudah diproses (status: %).', v_loan.status;
    end if;

    -- Kurangi stok hanya jika masih ada. Satu statement = atomik.
    update public.books
       set stock = stock - 1
     where id = v_loan.book_id
       and coalesce(stock, 0) > 0;
    get diagnostics v_updated = row_count;
    if v_updated = 0 then
      raise exception 'Stok buku habis, pengajuan tidak bisa disetujui.';
    end if;

    -- Pertahankan durasi yang dipilih user, tapi hitung dari hari persetujuan.
    v_days := greatest(
      1,
      coalesce(v_loan.due_date::date - v_loan.borrowed_at::date, 7)
    );

    update public.borrowings
       set status = 'Dipinjam',
           borrowed_at = now(),
           due_date = v_today + v_days
     where id = v_loan.id;

  elsif p_action = 'reject' then
    if v_status not in ('menunggu', 'menunggu konfirmasi', 'pending', 'waiting') then
      raise exception 'Pengajuan ini sudah diproses (status: %).', v_loan.status;
    end if;

    update public.borrowings
       set status = 'Ditolak'
     where id = v_loan.id;

  elsif p_action = 'confirm_return' then
    if v_status not in (
      'dipinjam', 'borrowed', 'aktif', 'terlambat', 'menunggu pengembalian'
    ) then
      raise exception 'Buku ini tidak sedang dipinjam (status: %).', v_loan.status;
    end if;

    update public.books
       set stock = coalesce(stock, 0) + 1
     where id = v_loan.book_id;

    update public.borrowings
       set status = 'Selesai',
           returned_at = now()
     where id = v_loan.id;

  else
    raise exception 'Aksi tidak dikenal: %', p_action;
  end if;
end;
$$;

revoke all on function public.process_borrowing(bigint, text) from public, anon;
grant execute on function public.process_borrowing(bigint, text) to authenticated;

-- ---------------------------------------------------------------------------
-- 2. Penjaga data: user TIDAK boleh menyetujui pinjamannya sendiri.
--    Policy "borrowings owner update/insert" memberi user akses tulis ke baris
--    miliknya, jadi tanpa guard ini user bisa set status = 'Dipinjam' sendiri.
--    Admin, SQL Editor, dan service role (auth.uid() null) tidak dibatasi.
-- ---------------------------------------------------------------------------
create or replace function public.guard_borrowing_changes()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_old text;
begin
  if auth.uid() is null or public.is_admin() then
    return new;
  end if;

  if tg_op = 'INSERT' then
    -- Pengajuan baru selalu masuk antrean approval.
    new.status := 'Menunggu';
    new.returned_at := null;

    if exists (
      select 1 from public.borrowings b
      where b.user_id = new.user_id
        and b.book_id = new.book_id
        and lower(coalesce(b.status, '')) in (
          'menunggu', 'menunggu konfirmasi', 'pending', 'dipinjam',
          'borrowed', 'aktif', 'terlambat', 'menunggu pengembalian'
        )
    ) then
      raise exception 'Kamu masih punya pengajuan atau pinjaman aktif untuk buku ini.';
    end if;

    return new;
  end if;

  -- UPDATE oleh user biasa
  if new.user_id is distinct from old.user_id
     or new.book_id is distinct from old.book_id
     or new.returned_at is distinct from old.returned_at then
    raise exception 'Data peminjaman ini hanya bisa diubah admin.';
  end if;

  if new.status is distinct from old.status then
    v_old := lower(coalesce(old.status, ''));
    -- Satu-satunya perubahan status yang diizinkan dari sisi user:
    -- sinkronisasi denda (Dipinjam -> Terlambat).
    if not (
      v_old in ('dipinjam', 'borrowed', 'aktif')
      and lower(coalesce(new.status, '')) = 'terlambat'
    ) then
      raise exception 'Status peminjaman hanya bisa diubah oleh admin.';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_guard_borrowing_changes on public.borrowings;
create trigger trg_guard_borrowing_changes
before insert or update on public.borrowings
for each row execute function public.guard_borrowing_changes();

-- ---------------------------------------------------------------------------
-- 3. Denda & pengingat hanya untuk buku yang benar-benar sedang dipinjam.
--    Sebelumnya pengajuan 'Menunggu' / 'Ditolak' yang due_date-nya lewat ikut
--    terkena denda.
-- ---------------------------------------------------------------------------
create or replace function public.sync_overdue_fines()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count integer := 0;
  v_loan record;
  v_days integer;
  v_amount integer;
begin
  for v_loan in
    select id, user_id, book_id, due_date, fine_amount
    from public.borrowings
    where due_date is not null
      and due_date < now()
      and returned_at is null
      and coalesce(fine_amount, 0) <= 0
      and lower(coalesce(status, '')) in (
        'dipinjam', 'borrowed', 'aktif', 'terlambat', 'menunggu pengembalian'
      )
  loop
    v_days := greatest(1, ceil(extract(epoch from (now() - v_loan.due_date)) / 86400)::integer);
    v_amount := v_days * 1000;

    update public.borrowings
       set fine_amount = v_amount,
           status = case
             when lower(coalesce(status, '')) in ('dipinjam', 'borrowed', 'aktif') then 'Terlambat'
             else status
           end
     where id = v_loan.id;

    insert into public.notifications (user_id, title, message, type, is_read, created_at)
    values (
      v_loan.user_id,
      'Denda keterlambatan',
      'Buku peminjaman Anda sudah melewati batas waktu. Denda Rp' ||
        to_char(v_amount, 'FM999G999G999') || ' otomatis tercatat (' ||
        v_days || ' hari keterlambatan).',
      'denda',
      false,
      now()
    );

    v_count := v_count + 1;
  end loop;

  return v_count;
end;
$$;

-- ---------------------------------------------------------------------------
-- 4. Notifikasi penolakan memakai type 'peminjaman_ditolak' agar tampil merah
--    di layar notifikasi user (sesuai notifikasi_screen.dart).
-- ---------------------------------------------------------------------------
create or replace function public.notify_borrowing_status(
  p_borrowing_id bigint,
  p_status text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_title text;
  v_message text;
  v_type text;
begin
  select user_id into v_user_id from public.borrowings where id = p_borrowing_id;
  if v_user_id is null then return; end if;

  case lower(coalesce(p_status, ''))
    when 'dipinjam', 'disetujui', 'approved' then
      v_title := 'Peminjaman disetujui';
      v_message := 'Pengajuan peminjaman #' || p_borrowing_id::text || ' telah disetujui admin.';
      v_type := 'peminjaman';
    when 'ditolak', 'rejected' then
      v_title := 'Peminjaman ditolak';
      v_message := 'Pengajuan peminjaman #' || p_borrowing_id::text || ' ditolak. Silakan ajukan lagi.';
      v_type := 'peminjaman_ditolak';
    when 'selesai', 'returned' then
      v_title := 'Pengembalian dikonfirmasi';
      v_message := 'Pengembalian buku #' || p_borrowing_id::text || ' telah dikonfirmasi admin.';
      v_type := 'pengembalian';
    else
      return;
  end case;

  insert into public.notifications (user_id, title, message, type, is_read, created_at)
  values (v_user_id, v_title, v_message, v_type, false, now());
end;
$$;
