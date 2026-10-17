-- Enforce booking lifecycle and inventory synchronization transactionally.
-- This migration adds triggers only; it does not change the existing schema.

create or replace function public.enforce_booking_lifecycle()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public, auth
as $$
declare
  actor_role text;
  resource_id uuid;
  resource_column text;
  resource_key text;
  resource_status text;
  overlapping_booking boolean;
begin
  actor_role := coalesce(public.get_my_role()::text, '');

  if tg_op = 'INSERT' then
    if auth.uid() is null or new.user_id is distinct from auth.uid() then
      raise exception using errcode = '42501', message = 'booking_user_must_match_authenticated_user';
    end if;
    if new.status is distinct from 'pending' then
      raise exception using errcode = '42501', message = 'customer_booking_must_start_pending';
    end if;
  elsif new.status is distinct from old.status then
    if actor_role not in ('manager', 'receptionist')
      or new.hotel_id is distinct from public.get_my_hotel() then
      raise exception using errcode = '42501', message = 'booking_transition_not_permitted';
    end if;

    if not (
      (old.status = 'pending' and new.status in ('confirmed', 'cancelled'))
      or (old.status = 'confirmed' and new.status in ('checked_in', 'cancelled'))
      or (old.status = 'checked_in' and new.status in ('checked_out', 'cancelled'))
    ) then
      raise exception using errcode = 'P0001', message = 'invalid_booking_transition';
    end if;

    if new.user_id is distinct from old.user_id
      or new.hotel_id is distinct from old.hotel_id
      or new.room_id is distinct from old.room_id
      or new.apartment_id is distinct from old.apartment_id
      or new.check_in is distinct from old.check_in
      or new.check_out is distinct from old.check_out then
      raise exception using errcode = '42501', message = 'booking_identity_and_dates_are_immutable';
    end if;
  elsif new.user_id is distinct from old.user_id
    or new.hotel_id is distinct from old.hotel_id
    or new.room_id is distinct from old.room_id
    or new.apartment_id is distinct from old.apartment_id
    or new.check_in is distinct from old.check_in
    or new.check_out is distinct from old.check_out
    or new.status is distinct from old.status then
    raise exception using errcode = '42501', message = 'booking_identity_and_dates_are_immutable';
  end if;

  if (new.room_id is null) = (new.apartment_id is null) then
    raise exception using errcode = '23514', message = 'booking_requires_exactly_one_inventory_item';
  end if;
  if new.check_out <= new.check_in then
    raise exception using errcode = '23514', message = 'booking_dates_are_invalid';
  end if;

  if new.room_id is not null then
    resource_id := new.room_id;
    resource_column := 'room_id';
    resource_key := 'room:' || new.room_id::text;
    select status::text into resource_status
      from public.rooms
      where id = resource_id and hotel_id = new.hotel_id
      for update;
  else
    resource_id := new.apartment_id;
    resource_column := 'apartment_id';
    resource_key := 'apartment:' || new.apartment_id::text;
    select status::text into resource_status
      from public.apartments
      where id = resource_id and hotel_id = new.hotel_id
      for update;
  end if;

  if not found then
    raise exception using errcode = '23503', message = 'booking_inventory_item_not_found';
  end if;

  if tg_op = 'INSERT' and resource_status = 'maintenance' then
    raise exception using errcode = 'P0001', message = 'booking_inventory_under_maintenance';
  end if;

  if new.status in ('pending', 'confirmed', 'checked_in') then
    perform pg_advisory_xact_lock(hashtextextended(resource_key, 0));

    if resource_status = 'maintenance' then
      raise exception using errcode = 'P0001', message = 'booking_inventory_under_maintenance';
    end if;

    if tg_op = 'INSERT' then
      execute format(
        'select exists (select 1 from public.bookings b where b.hotel_id = $1 and b.%I = $2 and b.status in (''pending'', ''confirmed'', ''checked_in'') and b.check_in < $4 and b.check_out > $3)',
        resource_column
      ) into overlapping_booking using new.hotel_id, resource_id, new.check_in, new.check_out;
    else
      execute format(
        'select exists (select 1 from public.bookings b where b.hotel_id = $1 and b.%I = $2 and b.id <> $5 and b.status in (''pending'', ''confirmed'', ''checked_in'') and b.check_in < $4 and b.check_out > $3)',
        resource_column
      ) into overlapping_booking using new.hotel_id, resource_id, new.check_in, new.check_out, new.id;
    end if;

    if overlapping_booking then
      raise exception using errcode = '23P01', message = 'booking_period_overlaps_existing_booking';
    end if;
  elsif tg_op = 'UPDATE' and new.status in ('checked_out', 'cancelled') then
    perform pg_advisory_xact_lock(hashtextextended(resource_key, 0));
  end if;

  return new;
end;
$$;

create or replace function public.sync_booking_inventory_status()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public, auth
as $$
declare
  resource_id uuid;
  resource_key text;
  resource_status text;
  another_checked_in boolean;
begin
  if new.status = old.status then
    return new;
  end if;

  if new.room_id is not null then
    resource_id := new.room_id;
    resource_key := 'room:' || new.room_id::text;
    select status::text into resource_status
      from public.rooms
      where id = resource_id and hotel_id = new.hotel_id
      for update;
  elsif new.apartment_id is not null then
    resource_id := new.apartment_id;
    resource_key := 'apartment:' || new.apartment_id::text;
    select status::text into resource_status
      from public.apartments
      where id = resource_id and hotel_id = new.hotel_id
      for update;
  else
    return new;
  end if;

  if not found then
    raise exception using errcode = '23503', message = 'booking_inventory_item_not_found';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(resource_key, 0));

  if new.status = 'checked_in' then
    if resource_status = 'maintenance' then
      raise exception using errcode = 'P0001', message = 'booking_inventory_under_maintenance';
    end if;

    if new.room_id is not null then
      update public.rooms set status = 'occupied'
        where id = resource_id and hotel_id = new.hotel_id and status <> 'maintenance';
    else
      update public.apartments set status = 'occupied'
        where id = resource_id and hotel_id = new.hotel_id and status <> 'maintenance';
    end if;
  elsif new.status in ('checked_out', 'cancelled') then
    if resource_status = 'maintenance' then
      return new;
    end if;

    if new.room_id is not null then
      select exists (
        select 1 from public.bookings b
        where b.hotel_id = new.hotel_id
          and b.room_id = resource_id
          and b.status = 'checked_in'
          and b.id <> new.id
      ) into another_checked_in;
      if another_checked_in then
        update public.rooms set status = 'occupied'
          where id = resource_id and hotel_id = new.hotel_id and status <> 'maintenance';
      else
        update public.rooms set status = 'available'
          where id = resource_id and hotel_id = new.hotel_id and status <> 'maintenance';
      end if;
    else
      select exists (
        select 1 from public.bookings b
        where b.hotel_id = new.hotel_id
          and b.apartment_id = resource_id
          and b.status = 'checked_in'
          and b.id <> new.id
      ) into another_checked_in;
      if another_checked_in then
        update public.apartments set status = 'occupied'
          where id = resource_id and hotel_id = new.hotel_id and status <> 'maintenance';
      else
        update public.apartments set status = 'available'
          where id = resource_id and hotel_id = new.hotel_id and status <> 'maintenance';
      end if;
    end if;
  end if;

  return new;
end;
$$;

revoke all on function public.enforce_booking_lifecycle() from public, anon, authenticated;
revoke all on function public.sync_booking_inventory_status() from public, anon, authenticated;

drop trigger if exists bookings_enforce_lifecycle on public.bookings;
create trigger bookings_enforce_lifecycle
  before insert or update on public.bookings
  for each row execute function public.enforce_booking_lifecycle();

drop trigger if exists bookings_sync_inventory_status on public.bookings;
create trigger bookings_sync_inventory_status
  after update of status on public.bookings
  for each row execute function public.sync_booking_inventory_status();

-- Reconcile inventory for bookings that were already checked in before this
-- trigger was installed, without overriding maintenance status.
update public.rooms r
set status = 'occupied'
where r.status <> 'maintenance'
  and exists (
    select 1
    from public.bookings b
    where b.room_id = r.id
      and b.hotel_id = r.hotel_id
      and b.status = 'checked_in'
  );

update public.apartments a
set status = 'occupied'
where a.status <> 'maintenance'
  and exists (
    select 1
    from public.bookings b
    where b.apartment_id = a.id
      and b.hotel_id = a.hotel_id
      and b.status = 'checked_in'
  );
