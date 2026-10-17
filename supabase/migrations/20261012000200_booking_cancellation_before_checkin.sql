-- Cancellation is allowed before check-in only. Keep the existing trigger
-- function's authorization, immutable fields, maintenance, and overlap guards.
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
      or (old.status = 'checked_in' and new.status = 'checked_out')
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

revoke all on function public.enforce_booking_lifecycle()
  from public, anon, authenticated;

-- Keep status transitions narrowly scoped without broadening table UPDATE RLS.
create or replace function public.transition_booking_status(
  p_booking_id uuid,
  p_next_status text
)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public, auth
as $$
declare
  actor_role text;
  assigned_hotel uuid;
  current_status text;
begin
  actor_role := coalesce(public.get_my_role()::text, '');
  if auth.uid() is null or actor_role not in ('manager', 'receptionist') then
    raise exception using errcode = '42501', message = 'booking_transition_not_permitted';
  end if;

  assigned_hotel := public.get_my_hotel();
  if assigned_hotel is null then
    raise exception using errcode = '42501', message = 'booking_transition_not_permitted';
  end if;

  select status::text into current_status
    from public.bookings
    where id = p_booking_id
      and hotel_id = assigned_hotel
    for update;

  if not found then
    raise exception using errcode = 'P0001', message = 'booking_not_found';
  end if;

  update public.bookings
    set status = p_next_status
    where id = p_booking_id
      and hotel_id = assigned_hotel
      and status = current_status;

  if not found then
    raise exception using errcode = 'P0001', message = 'booking_status_changed';
  end if;
end;
$$;

revoke all on function public.transition_booking_status(uuid, text)
  from public, anon;
grant execute on function public.transition_booking_status(uuid, text)
  to authenticated;
