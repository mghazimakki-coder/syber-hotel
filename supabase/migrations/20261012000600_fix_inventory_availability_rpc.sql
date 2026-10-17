-- Recreate the availability RPC with the exact argument names/order used by
-- the customer app. SECURITY DEFINER is required to check bookings hidden by
-- customer RLS; role and hotel scope are validated explicitly below.
drop function if exists public.get_inventory_availability(uuid, date, date, text, uuid);
drop function if exists public.get_inventory_availability(date, date, uuid, uuid, text);

create function public.get_inventory_availability(
  p_check_in date,
  p_check_out date,
  p_hotel_id uuid,
  p_inventory_id uuid default null,
  p_inventory_type text default null
)
returns table (
  inventory_type text,
  inventory_id uuid,
  available boolean
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  actor_role text;
begin
  if auth.uid() is null then
    raise exception using
      errcode = '42501',
      message = 'booking_availability_requires_authentication';
  end if;

  actor_role := coalesce(public.get_my_role()::text, '');
  if actor_role not in ('customer', 'manager', 'receptionist') then
    raise exception using
      errcode = '42501',
      message = 'booking_availability_role_not_permitted';
  end if;

  if p_hotel_id is null then
    raise exception using
      errcode = '23514',
      message = 'booking_hotel_is_invalid';
  end if;

  if actor_role in ('manager', 'receptionist')
    and p_hotel_id is distinct from public.get_my_hotel() then
    raise exception using
      errcode = '42501',
      message = 'booking_availability_hotel_not_permitted';
  end if;

  if p_check_in is null or p_check_out is null or p_check_out <= p_check_in then
    raise exception using
      errcode = '23514',
      message = 'booking_dates_are_invalid';
  end if;

  if (p_inventory_type is null) <> (p_inventory_id is null)
    or (p_inventory_type is not null
      and p_inventory_type not in ('room', 'apartment')) then
    raise exception using
      errcode = '23514',
      message = 'booking_inventory_filter_is_invalid';
  end if;

  if p_inventory_type = 'room' and not exists (
    select 1
    from public.rooms r
    where r.id = p_inventory_id
      and r.hotel_id = p_hotel_id
  ) then
    raise exception using
      errcode = 'P0002',
      message = 'booking_inventory_not_found_in_hotel';
  end if;

  if p_inventory_type = 'apartment' and not exists (
    select 1
    from public.apartments a
    where a.id = p_inventory_id
      and a.hotel_id = p_hotel_id
  ) then
    raise exception using
      errcode = 'P0002',
      message = 'booking_inventory_not_found_in_hotel';
  end if;

  return query
  select
    'room'::text,
    r.id,
    coalesce(r.status::text, 'maintenance') <> 'maintenance'
      and not exists (
        select 1
        from public.bookings b
        where b.hotel_id = p_hotel_id
          and b.room_id = r.id
          and b.status::text in ('pending', 'confirmed', 'checked_in')
          and p_check_in < b.check_out
          and p_check_out > b.check_in
      )
  from public.rooms r
  where r.hotel_id = p_hotel_id
    and (p_inventory_type is null or p_inventory_type = 'room')
    and (p_inventory_id is null or p_inventory_id = r.id)

  union all

  select
    'apartment'::text,
    a.id,
    coalesce(a.status::text, 'maintenance') <> 'maintenance'
      and not exists (
        select 1
        from public.bookings b
        where b.hotel_id = p_hotel_id
          and b.apartment_id = a.id
          and b.status::text in ('pending', 'confirmed', 'checked_in')
          and p_check_in < b.check_out
          and p_check_out > b.check_in
      )
  from public.apartments a
  where a.hotel_id = p_hotel_id
    and (p_inventory_type is null or p_inventory_type = 'apartment')
    and (p_inventory_id is null or p_inventory_id = a.id);
end;
$$;

revoke all on function public.get_inventory_availability(date, date, uuid, uuid, text)
  from public, anon;
grant execute on function public.get_inventory_availability(date, date, uuid, uuid, text)
  to authenticated;

notify pgrst, 'reload schema';
