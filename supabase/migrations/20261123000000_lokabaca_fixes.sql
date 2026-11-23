-- LokaBaca: database-side fixes for fines, notifications and book metadata.
-- Jalankan file ini di Supabase Dashboard -> SQL Editor -> New query -> Run.
-- Semua statement bersifat idempoten (aman dijalankan lebih dari satu kali).

-- ---------------------------------------------------------------------------
-- 1. Metadata buku: penerbit
-- ---------------------------------------------------------------------------
alter table public.books add column if not exists publisher text;

-- ---------------------------------------------------------------------------
-- 2. Indeks untuk pencarian denda / pengingat jatuh tempo
-- ---------------------------------------------------------------------------
create index if not exists borrowings_due_date_idx on public.borrowings (due_date);
create index if not exists notifications_user_created_idx
  on public.notifications (user_id, created_at desc);

-- ---------------------------------------------------------------------------
-- 3. Denda otomatis untuk peminjaman yang terlambat
--    Tarif: Rp1.000 / hari (sesuai kebijakan peminjaman di aplikasi).
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
  loop
    v_days := greatest(1, ceil(extract(epoch from (now() - v_loan.due_date)) / 86400)::integer);
    v_amount := v_days * 1000;

    update public.borrowings
       set fine_amount = v_amount,
           status = case
             when lower(coalesce(status, '')) in ('dipinjam', 'borrowed') then 'Terlambat'
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
-- 5. Pengingat 1 hari sebelum jatuh tempo (dijalankan rutin dari aplikasi)
-- ---------------------------------------------------------------------------
create or replace function public.queue_due_reminders()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count integer := 0;
  v_loan record;
begin
  for v_loan in
    select id, user_id, book_id, due_date
    from public.borrowings
    where due_date is not null
      and returned_at is null
      and due_date > now()
      and due_date <= now() + interval '24 hours'
      and lower(coalesce(status, '')) in ('dipinjam', 'borrowed', 'terlambat')
  loop
    if not exists (
      select 1 from public.notifications n
      where n.user_id = v_loan.user_id
        and n.type = 'pengingat'
        and n.created_at::date = current_date
        and n.message like '%' || v_loan.id::text || '%'
    ) then
      insert into public.notifications (user_id, title, message, type, is_read, created_at)
      values (
        v_loan.user_id,
        'Pengingat peminjaman',
        'Peminjaman #' || v_loan.id::text ||
          ' jatuh tempo besok. Kembalikan buku tepat waktu agar tidak kena denda.',
        'pengingat',
        false,
        now()
      );
      v_count := v_count + 1;
    end if;
  end loop;

  return v_count;
end;
$$;

-- ---------------------------------------------------------------------------
-- 6. Notifikasi saat status peminjaman disetujui / ditolak / selesai
--    (dipanggil dari aplikasi maupun dari RPC process_borrowing)
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
      v_type := 'peminjaman';
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

-- ---------------------------------------------------------------------------
-- 7. Trigger: jalankan sinkronisasi otomatis setiap ada peminjaman berubah
-- ---------------------------------------------------------------------------
create or replace function public.trg_borrowings_after_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.sync_overdue_fines();
  perform public.queue_due_reminders();
  if new.status is distinct from old.status then
    perform public.notify_borrowing_status(new.id, new.status);
  end if;
  return new;
end;
$$;

drop trigger if exists trg_borrowings_after_change on public.borrowings;
create trigger trg_borrowings_after_change
after insert or update on public.borrowings
for each row execute function public.trg_borrowings_after_change();

-- ---------------------------------------------------------------------------
-- 8. Izin RPC untuk klien (anon & authenticated)
-- ---------------------------------------------------------------------------
grant execute on function public.sync_overdue_fines() to anon, authenticated;
grant execute on function public.queue_due_reminders() to anon, authenticated;
grant execute on function public.notify_borrowing_status(bigint, text) to anon, authenticated;

-- ---------------------------------------------------------------------------
-- 9. Row Level Security: pastikan user & admin tersambung ke data yang benar.
--    Kebijakan bersifat tambahan (permissive) sehingga tidak menimpa policy
--    yang sudah ada di project.
-- ---------------------------------------------------------------------------
create or replace function public.is_admin()
returns boolean
language sql stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and lower(coalesce(role, '')) = 'admin'
  );
$$;

drop policy if exists "notifications owner or admin read" on public.notifications;
create policy "notifications owner or admin read"
  on public.notifications for select to authenticated
  using (user_id = auth.uid() or public.is_admin());

drop policy if exists "notifications owner or admin insert" on public.notifications;
create policy "notifications owner or admin insert"
  on public.notifications for insert to authenticated
  with check (user_id = auth.uid() or public.is_admin());

drop policy if exists "notifications owner or admin update" on public.notifications;
create policy "notifications owner or admin update"
  on public.notifications for update to authenticated
  using (user_id = auth.uid() or public.is_admin())
  with check (user_id = auth.uid() or public.is_admin());

drop policy if exists "wishlists owner read" on public.wishlists;
create policy "wishlists owner read"
  on public.wishlists for select to authenticated
  using (user_id = auth.uid() or public.is_admin());

drop policy if exists "wishlists owner insert" on public.wishlists;
create policy "wishlists owner insert"
  on public.wishlists for insert to authenticated
  with check (user_id = auth.uid());

drop policy if exists "wishlists owner delete" on public.wishlists;
create policy "wishlists owner delete"
  on public.wishlists for delete to authenticated
  using (user_id = auth.uid());

drop policy if exists "borrowings owner read" on public.borrowings;
create policy "borrowings owner read"
  on public.borrowings for select to authenticated
  using (user_id = auth.uid() or public.is_admin());

drop policy if exists "borrowings owner insert" on public.borrowings;
create policy "borrowings owner insert"
  on public.borrowings for insert to authenticated
  with check (user_id = auth.uid() or public.is_admin());

-- Sinkronisasi denda dari klien user perlu mengupdate fine_amount miliknya
-- sendiri. Trigger server (bagian 4) melakukan hal yang sama bila dipasang.
drop policy if exists "borrowings owner update" on public.borrowings;
create policy "borrowings owner update"
  on public.borrowings for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "borrowings admin update" on public.borrowings;
create policy "borrowings admin update"
  on public.borrowings for update to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "profiles owner read" on public.profiles;
create policy "profiles owner read"
  on public.profiles for select to authenticated
  using (id = auth.uid() or public.is_admin());

drop policy if exists "profiles owner insert" on public.profiles;
create policy "profiles owner insert"
  on public.profiles for insert to authenticated
  with check (id = auth.uid());

drop policy if exists "profiles owner update" on public.profiles;
create policy "profiles owner update"
  on public.profiles for update to authenticated
  using (id = auth.uid() or public.is_admin())
  with check (id = auth.uid() or public.is_admin());

grant execute on function public.is_admin() to anon, authenticated;
