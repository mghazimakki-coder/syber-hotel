create or replace function public.get_inventory_availability(
  p_hotel_id uuid,
  p_check_in date,
  p_check_out date,
  p_inventory_type text default null,
  p_inventory_id uuid default null
)
returns table (
  inventory_type text,
  inventory_id uuid,
  available boolean
)
language plpgsql
stable
security definer
set search_path = pg_catalog, public, auth
as $$
declare
  actor_role text;
begin
  if auth.uid() is null then
    raise exception using errcode = '42501', message = 'booking_availability_requires_authentication';
  end if;

  actor_role := coalesce(public.get_my_role()::text, '');
  if actor_role not in ('customer', 'manager', 'receptionist') then
    raise exception using errcode = '42501', message = 'booking_availability_role_not_permitted';
  end if;
  if actor_role in ('manager', 'receptionist')
    and p_hotel_id is distinct from public.get_my_hotel() then
    raise exception using errcode = '42501', message = 'booking_availability_hotel_not_permitted';
  end if;

  if p_check_in is null or p_check_out is null or p_check_out <= p_check_in then
    raise exception using errcode = '23514', message = 'booking_dates_are_invalid';
  end if;
  if (p_inventory_type is null) <> (p_inventory_id is null)
    or p_inventory_type not in ('room', 'apartment') then
    raise exception using errcode = '23514', message = 'booking_inventory_filter_is_invalid';
  end if;

  return query
  select
    'room'::text,
    r.id,
    coalesce(r.status::text, 'maintenance') <> 'maintenance'
      and not exists (
        select 1
        from public.bookings b
        where b.hotel_id = r.hotel_id
          and b.room_id = r.id
          and b.status::text in ('pending', 'confirmed', 'checked_in')
          and b.check_in < p_check_out
          and b.check_out > p_check_in
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
        where b.hotel_id = a.hotel_id
          and b.apartment_id = a.id
          and b.status::text in ('pending', 'confirmed', 'checked_in')
          and b.check_in < p_check_out
          and b.check_out > p_check_in
      )
  from public.apartments a
  where a.hotel_id = p_hotel_id
    and (p_inventory_type is null or p_inventory_type = 'apartment')
    and (p_inventory_id is null or p_inventory_id = a.id);
end;
$$;

revoke all on function public.get_inventory_availability(uuid, date, date, text, uuid)
  from public, anon;
grant execute on function public.get_inventory_availability(uuid, date, date, text, uuid)
  to authenticated;

-- Keep the existing transactional guard active for every booking insert/update.
drop trigger if exists bookings_enforce_lifecycle on public.bookings;
create trigger bookings_enforce_lifecycle
  before insert or update on public.bookings
  for each row execute function public.enforce_booking_lifecycle();
